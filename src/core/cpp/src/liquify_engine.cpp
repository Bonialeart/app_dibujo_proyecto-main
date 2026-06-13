/**
 * ArtFlow Studio — Liquify Engine Implementation
 * ────────────────────────────────────────────────
 * Ruta principal: deformación 100% en GPU (OpenGL ES 2.0/3.0).
 *   - El mapa de desplazamiento vive en un par de FBOs ping-pong
 *     (RGBA16F si el hardware lo soporta, RGBA8 codificado si no).
 *   - Cada dab del pincel es un pase de fragmento (liquify_brush.frag)
 *     que lee el desplazamiento acumulado de un FBO y escribe al otro.
 *   - El preview se dibuja directamente desde texturas GPU (liquify.frag),
 *     sin descargas por dab a la CPU.
 * Ruta de respaldo: la librería Rust (FFI) cuando no hay contexto GL.
 */

#include "../include/liquify_engine.h"
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLTexture>
#include <QVector2D>
#include <algorithm>
#include <cmath>
#include <cstring>

#ifndef GL_RGBA16F
#define GL_RGBA16F 0x881A
#endif

// ─── Declaraciones FFI de la librería en Rust ─────────────────────
extern "C" {
    void* liquify_create();
    void liquify_destroy(void* engine);
    void liquify_begin(void* engine, const uint8_t* source_pixels, int32_t width, int32_t height);
    void liquify_end(void* engine);
    void liquify_set_parameters(void* engine, int32_t mode, float radius, float strength, float morpher);
    void liquify_apply_brush(void* engine, float cx, float cy, float prev_cx, float prev_cy);
    void liquify_render_preview(void* engine, uint8_t* out_pixels);
    bool liquify_is_active(void* engine);
    void liquify_get_displacement(void* engine, float* out_dx, float* out_dy, int32_t max_len);
}

namespace artflow {

// Rango máximo de desplazamiento en píxeles que cabe en la codificación
// [-1,1] del mapa (debe coincidir con el decode de los shaders).
static const float kMaxDisplacement = 500.0f;

// Vertex shader compartido (GLSL portable: 1.10 escritorio / ES 1.00)
static const char *kLiquifyVertexSrc = R"(
attribute vec2 position;
attribute vec2 texCoord;
varying vec2 vTexCoord;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    vTexCoord = texCoord;
}
)";

// Misma convención de búsqueda de shaders que CanvasItem::paint()
static QString findShaderFile(const QString &name) {
  QStringList paths;
  paths << ":/src/core/shaders/"
        << QCoreApplication::applicationDirPath() + "/shaders/"
        << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
        << "src/core/shaders/"
        << "../src/core/shaders/";
  for (const QString &p : paths) {
    if (QFile::exists(p + name))
      return p + name;
  }
  return QString();
}

// Quad como triangle-strip: cada vértice es {x, y, u, v}
static void drawQuad(QOpenGLShaderProgram *prog, QOpenGLFunctions *f,
                     const float *verts) {
  prog->enableAttributeArray(0);
  prog->enableAttributeArray(1);
  prog->setAttributeArray(0, GL_FLOAT, verts, 2, 4 * sizeof(float));
  prog->setAttributeArray(1, GL_FLOAT, verts + 2, 2, 4 * sizeof(float));
  f->glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  prog->disableAttributeArray(0);
  prog->disableAttributeArray(1);
}

// Quad de pantalla completa con v=0 en la fila 0 de memoria del FBO
// (convención "v=0 = parte superior del lienzo" de todo el pipeline liquify).
static const float kFullscreenQuad[16] = {
    -1.0f, -1.0f, 0.0f, 0.0f, //
    1.0f,  -1.0f, 1.0f, 0.0f, //
    -1.0f, 1.0f,  0.0f, 1.0f, //
    1.0f,  1.0f,  1.0f, 1.0f, //
};

static QOpenGLShaderProgram *buildProgram(const QString &fragName) {
  const QString fragPath = findShaderFile(fragName);
  if (fragPath.isEmpty()) {
    qWarning() << "Liquify shader not found:" << fragName;
    return nullptr;
  }
  auto *prog = new QOpenGLShaderProgram();
  prog->bindAttributeLocation("position", 0);
  prog->bindAttributeLocation("texCoord", 1);
  bool ok =
      prog->addShaderFromSourceCode(QOpenGLShader::Vertex, kLiquifyVertexSrc) &&
      prog->addShaderFromSourceFile(QOpenGLShader::Fragment, fragPath) &&
      prog->link();
  if (!ok) {
    qWarning() << "Liquify shader build failed (" << fragName
               << "):" << prog->log();
    delete prog;
    return nullptr;
  }
  return prog;
}

// ══════════════════════════════════════════════════════════════════
//  DisplacementMap
// ══════════════════════════════════════════════════════════════════

void DisplacementMap::resize(int w, int h) {
  width = w;
  height = h;
  dx.assign(static_cast<size_t>(w) * h, 0.0f);
  dy.assign(static_cast<size_t>(w) * h, 0.0f);
}

void DisplacementMap::clear() {
  std::fill(dx.begin(), dx.end(), 0.0f);
  std::fill(dy.begin(), dy.end(), 0.0f);
}

void DisplacementMap::sampleAt(float x, float y, float &outDx,
                               float &outDy) const {
  // Interpolación bilineal de desplazamientos
  int x0 = static_cast<int>(std::floor(x));
  int y0 = static_cast<int>(std::floor(y));
  int x1 = x0 + 1;
  int y1 = y0 + 1;
  float fx = x - x0;
  float fy = y - y0;

  auto safeDx = [&](int px, int py) -> float {
    int i = idx(px, py);
    return (i >= 0) ? dx[i] : 0.0f;
  };
  auto safeDy = [&](int px, int py) -> float {
    int i = idx(px, py);
    return (i >= 0) ? dy[i] : 0.0f;
  };

  float dx00 = safeDx(x0, y0), dx10 = safeDx(x1, y0);
  float dx01 = safeDx(x0, y1), dx11 = safeDx(x1, y1);
  float dy00 = safeDy(x0, y0), dy10 = safeDy(x1, y0);
  float dy01 = safeDy(x0, y1), dy11 = safeDy(x1, y1);

  outDx = dx00 * (1 - fx) * (1 - fy) + dx10 * fx * (1 - fy) +
          dx01 * (1 - fx) * fy + dx11 * fx * fy;
  outDy = dy00 * (1 - fx) * (1 - fy) + dy10 * fx * (1 - fy) +
          dy01 * (1 - fx) * fy + dy11 * fx * fy;
}

// ══════════════════════════════════════════════════════════════════
//  LiquifyEngine
// ══════════════════════════════════════════════════════════════════

LiquifyEngine::LiquifyEngine() {
  m_rustEngine = liquify_create();
}

LiquifyEngine::~LiquifyEngine() {
  if (QOpenGLContext::currentContext())
    releaseGpuResources();
  if (m_rustEngine) {
    liquify_destroy(m_rustEngine);
    m_rustEngine = nullptr;
  }
}

void LiquifyEngine::begin(const ImageBuffer &sourceLayer, int width,
                          int height) {
  m_width = width;
  m_height = height;
  m_active = true;
  m_gpuSession = false;

  m_dispMap.resize(width, height);

  const uint8_t *src = sourceLayer.data();
  if (src) {
    // Snapshot para la ruta GPU (textura fuente del preview)
    m_sourceImage = QImage(src, width, height,
                           QImage::Format_RGBA8888_Premultiplied)
                        .copy();
    m_sourceDirty = true;
    m_dispClearPending = true;

    // Mantener la ruta Rust inicializada como respaldo sin contexto GL
    if (m_rustEngine)
      liquify_begin(m_rustEngine, src, width, height);
  }
}

QImage LiquifyEngine::end() {
  QImage result;
  if (m_gpuSession) {
    if (QOpenGLContext::currentContext()) {
      result = bakeGpu();
    } else {
      qWarning() << "Liquify: no GL context at end(); GPU result lost";
    }
    m_gpuSession = false;
  }

  m_active = false;
  if (m_rustEngine)
    liquify_end(m_rustEngine);

  if (result.isNull())
    result = renderPreview(); // ruta Rust (o vacío si tampoco hay motor)
  return result;
}

void LiquifyEngine::abort() {
  m_gpuSession = false;
  m_active = false;
  if (m_rustEngine)
    liquify_end(m_rustEngine);
}

void LiquifyEngine::applyBrush(float cx, float cy, float prevCx, float prevCy) {
  if (!m_active)
    return;

  // Ruta GPU: un pase de fragmento por dab sobre el mapa de desplazamiento
  if (QOpenGLContext::currentContext() && primeGpu()) {
    applyBrushGpu(cx, cy, prevCx, prevCy);
    return;
  }
  if (m_gpuSession)
    return; // sesión GPU activa pero sin contexto ahora: no mezclar rutas

  if (!m_rustEngine)
    return;

  // Respaldo CPU (Rust): sincronizar parámetros y aplicar el dab
  liquify_set_parameters(m_rustEngine, static_cast<int32_t>(m_mode), m_radius, m_strength, m_morpher);
  liquify_apply_brush(m_rustEngine, cx, cy, prevCx, prevCy);
}

QImage LiquifyEngine::renderPreview() const {
  if (m_width <= 0 || m_height <= 0)
    return QImage();

  if (m_gpuSession) {
    if (QOpenGLContext::currentContext())
      return bakeGpu();
    return QImage();
  }

  if (!m_rustEngine)
    return QImage();

  QImage result(m_width, m_height, QImage::Format_RGBA8888_Premultiplied);
  uint8_t *dst = result.bits();

  // Renderizar la previsualización en paralelo con Rayon
  liquify_render_preview(m_rustEngine, dst);

  // Sincronizar el mapa de desplazamiento a m_dispMap para mantener compatibilidad externa
  int totalPixels = m_width * m_height;
  liquify_get_displacement(m_rustEngine, m_dispMap.dx.data(), m_dispMap.dy.data(), totalPixels);

  return result;
}

// ══════════════════════════════════════════════════════════════════
//  GPU path
// ══════════════════════════════════════════════════════════════════

bool LiquifyEngine::primeGpu() {
  if (!m_active)
    return false;
  if (m_gpuSession)
    return true;
  if (!QOpenGLContext::currentContext())
    return false;
  if (!ensureGpuResources())
    return false;
  m_gpuSession = true;
  return true;
}

bool LiquifyEngine::ensureGpuResources() {
  QOpenGLContext *ctx = QOpenGLContext::currentContext();
  if (!ctx || m_width <= 0 || m_height <= 0)
    return false;
  QOpenGLFunctions *f = ctx->functions();

  // 1. Shaders
  if (!m_brushProgram) {
    m_brushProgram = buildProgram("liquify_brush.frag");
    if (!m_brushProgram)
      return false;
  }
  if (!m_previewProgram) {
    m_previewProgram = buildProgram("liquify.frag");
    if (!m_previewProgram)
      return false;
  }

  // 2. FBOs de desplazamiento (ping-pong)
  if (!m_dispPing || m_dispPing->width() != m_width ||
      m_dispPing->height() != m_height) {
    delete m_dispPing;
    delete m_dispPong;
    delete m_bakeFBO;
    m_dispPing = m_dispPong = m_bakeFBO = nullptr;

    // 16-bit flotante para precisión sub-píxel; sin multisampling
    QOpenGLFramebufferObjectFormat fmt;
    fmt.setInternalTextureFormat(GL_RGBA16F);
    fmt.setSamples(0);

    m_dispPing = new QOpenGLFramebufferObject(m_width, m_height, fmt);
    m_dispZero = 0.5f;
    if (!m_dispPing->isValid()) {
      // Fallback ES 2.0 sin color-buffer-float: RGBA8 con codificación
      // [-1,1]; el punto cero pasa a 128/255 para que sea exacto en 8-bit.
      delete m_dispPing;
      QOpenGLFramebufferObjectFormat fmt8;
      fmt8.setSamples(0);
      m_dispPing = new QOpenGLFramebufferObject(m_width, m_height, fmt8);
      m_dispPong = new QOpenGLFramebufferObject(m_width, m_height, fmt8);
      m_dispZero = 128.0f / 255.0f;
    } else {
      m_dispPong = new QOpenGLFramebufferObject(m_width, m_height, fmt);
    }
    if (!m_dispPing->isValid() || !m_dispPong->isValid()) {
      qWarning() << "Liquify: displacement FBO creation failed";
      delete m_dispPing;
      delete m_dispPong;
      m_dispPing = m_dispPong = nullptr;
      return false;
    }

    // Interpolación de hardware GL_LINEAR para deformaciones sin pixelado
    for (QOpenGLFramebufferObject *fbo : {m_dispPing, m_dispPong}) {
      f->glBindTexture(GL_TEXTURE_2D, fbo->texture());
      f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    f->glBindTexture(GL_TEXTURE_2D, 0);
    m_dispClearPending = true;
  }

  // 3. Limpiar el mapa de desplazamiento al punto cero (sin deformación)
  if (m_dispClearPending) {
    GLint prevFbo = 0;
    f->glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
    for (QOpenGLFramebufferObject *fbo : {m_dispPing, m_dispPong}) {
      fbo->bind();
      f->glClearColor(m_dispZero, m_dispZero, 0.0f, 1.0f);
      f->glClear(GL_COLOR_BUFFER_BIT);
    }
    f->glBindFramebuffer(GL_FRAMEBUFFER, prevFbo);
    m_dispClearPending = false;
  }

  // 4. Textura fuente (snapshot de la capa)
  if (m_sourceDirty || !m_sourceTex) {
    if (m_sourceTex && (m_sourceTex->width() != m_width ||
                        m_sourceTex->height() != m_height)) {
      delete m_sourceTex;
      m_sourceTex = nullptr;
    }
    if (m_sourceImage.isNull())
      return false;
    if (!m_sourceTex) {
      m_sourceTex = new QOpenGLTexture(QOpenGLTexture::Target2D);
      m_sourceTex->setSize(m_width, m_height);
      m_sourceTex->setFormat(QOpenGLTexture::RGBA8_UNorm);
      m_sourceTex->allocateStorage();
      m_sourceTex->setMinificationFilter(QOpenGLTexture::Linear);
      m_sourceTex->setMagnificationFilter(QOpenGLTexture::Linear);
      m_sourceTex->setWrapMode(QOpenGLTexture::ClampToEdge);
    }
    m_sourceTex->setData(QOpenGLTexture::RGBA, QOpenGLTexture::UInt8,
                         m_sourceImage.constBits());
    m_sourceDirty = false;
  }

  return true;
}

void LiquifyEngine::applyBrushGpu(float cx, float cy, float prevCx,
                                  float prevCy) {
  QOpenGLContext *ctx = QOpenGLContext::currentContext();
  if (!ctx || !m_dispPing || !m_dispPong || !m_brushProgram)
    return;
  QOpenGLFunctions *f = ctx->functions();

  // Guardar estado GL del llamador (puede ser un manejador de eventos o
  // un pase de pintura de Qt Quick)
  GLint prevFbo = 0;
  GLint prevViewport[4];
  f->glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
  f->glGetIntegerv(GL_VIEWPORT, prevViewport);
  GLboolean blendOn = f->glIsEnabled(GL_BLEND);
  GLboolean scissorOn = f->glIsEnabled(GL_SCISSOR_TEST);
  GLboolean depthOn = f->glIsEnabled(GL_DEPTH_TEST);

  f->glDisable(GL_BLEND);
  f->glDisable(GL_SCISSOR_TEST);
  f->glDisable(GL_DEPTH_TEST);

  // Ping-pong: leer del acumulado (ping) y escribir al otro FBO (pong).
  // Nunca se lee y escribe la misma textura en el mismo pase
  // (comportamiento indefinido en OpenGL ES).
  m_dispPong->bind();
  f->glViewport(0, 0, m_width, m_height);

  m_brushProgram->bind();
  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, m_dispPing->texture());
  m_brushProgram->setUniformValue("uPrevDisp", 0);
  m_brushProgram->setUniformValue("uCanvasSize",
                                  QVector2D(m_width, m_height));
  m_brushProgram->setUniformValue("uCenter", QVector2D(cx, cy));
  m_brushProgram->setUniformValue("uPrevCenter", QVector2D(prevCx, prevCy));
  m_brushProgram->setUniformValue("uRadius", m_radius);
  m_brushProgram->setUniformValue("uStrength", m_strength);
  m_brushProgram->setUniformValue("uMorpher", m_morpher);
  m_brushProgram->setUniformValue("uMaxDisp", kMaxDisplacement);
  m_brushProgram->setUniformValue("uDispZero", m_dispZero);
  m_brushProgram->setUniformValue("uMode", static_cast<int>(m_mode));

  drawQuad(m_brushProgram, f, kFullscreenQuad);
  m_brushProgram->release();

  std::swap(m_dispPing, m_dispPong);

  // Restaurar estado del llamador
  f->glBindFramebuffer(GL_FRAMEBUFFER, static_cast<GLuint>(prevFbo));
  f->glViewport(prevViewport[0], prevViewport[1], prevViewport[2],
                prevViewport[3]);
  if (blendOn)
    f->glEnable(GL_BLEND);
  if (scissorOn)
    f->glEnable(GL_SCISSOR_TEST);
  if (depthOn)
    f->glEnable(GL_DEPTH_TEST);
  f->glBindTexture(GL_TEXTURE_2D, 0);
}

void LiquifyEngine::drawPreview(const QPointF ndcCorners[4], float opacity) {
  QOpenGLContext *ctx = QOpenGLContext::currentContext();
  if (!ctx || !m_gpuSession || !m_previewProgram || !m_dispPing ||
      !m_sourceTex)
    return;
  QOpenGLFunctions *f = ctx->functions();

  // Quad en NDC del viewport actual: TL, TR, BL, BR con UV (0,0)=arriba-izq.
  float verts[16];
  const float uvs[8] = {0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f};
  for (int i = 0; i < 4; ++i) {
    verts[i * 4 + 0] = static_cast<float>(ndcCorners[i].x());
    verts[i * 4 + 1] = static_cast<float>(ndcCorners[i].y());
    verts[i * 4 + 2] = uvs[i * 2 + 0];
    verts[i * 4 + 3] = uvs[i * 2 + 1];
  }

  m_previewProgram->bind();
  f->glActiveTexture(GL_TEXTURE0);
  m_sourceTex->bind();
  m_previewProgram->setUniformValue("uSource", 0);
  f->glActiveTexture(GL_TEXTURE1);
  f->glBindTexture(GL_TEXTURE_2D, m_dispPing->texture());
  m_previewProgram->setUniformValue("uDisplacement", 1);
  m_previewProgram->setUniformValue("uCanvasSize",
                                    QVector2D(m_width, m_height));
  m_previewProgram->setUniformValue("uOpacity", opacity);
  m_previewProgram->setUniformValue("uMaxDisp", kMaxDisplacement);
  m_previewProgram->setUniformValue("uDispZero", m_dispZero);

  // Alpha premultiplicado sobre el backdrop ya compuesto
  f->glEnable(GL_BLEND);
  f->glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

  drawQuad(m_previewProgram, f, verts);

  m_previewProgram->release();
  f->glActiveTexture(GL_TEXTURE1);
  f->glBindTexture(GL_TEXTURE_2D, 0);
  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, 0);
}

QImage LiquifyEngine::bakeGpu() const {
  QOpenGLContext *ctx = QOpenGLContext::currentContext();
  if (!ctx || !m_previewProgram || !m_dispPing || !m_sourceTex)
    return QImage();
  QOpenGLFunctions *f = ctx->functions();

  if (!m_bakeFBO || m_bakeFBO->width() != m_width ||
      m_bakeFBO->height() != m_height) {
    delete m_bakeFBO;
    QOpenGLFramebufferObjectFormat fmt;
    fmt.setSamples(0);
    m_bakeFBO = new QOpenGLFramebufferObject(m_width, m_height, fmt);
    if (!m_bakeFBO->isValid()) {
      delete m_bakeFBO;
      m_bakeFBO = nullptr;
      return QImage();
    }
  }

  GLint prevFbo = 0;
  GLint prevViewport[4];
  f->glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
  f->glGetIntegerv(GL_VIEWPORT, prevViewport);
  GLboolean blendOn = f->glIsEnabled(GL_BLEND);

  m_bakeFBO->bind();
  f->glViewport(0, 0, m_width, m_height);
  f->glDisable(GL_BLEND);
  f->glClearColor(0, 0, 0, 0);
  f->glClear(GL_COLOR_BUFFER_BIT);

  m_previewProgram->bind();
  f->glActiveTexture(GL_TEXTURE0);
  m_sourceTex->bind();
  m_previewProgram->setUniformValue("uSource", 0);
  f->glActiveTexture(GL_TEXTURE1);
  f->glBindTexture(GL_TEXTURE_2D, m_dispPing->texture());
  m_previewProgram->setUniformValue("uDisplacement", 1);
  m_previewProgram->setUniformValue("uCanvasSize",
                                    QVector2D(m_width, m_height));
  m_previewProgram->setUniformValue("uOpacity", 1.0f);
  m_previewProgram->setUniformValue("uMaxDisp", kMaxDisplacement);
  m_previewProgram->setUniformValue("uDispZero", m_dispZero);

  drawQuad(m_previewProgram, f, kFullscreenQuad);
  m_previewProgram->release();

  f->glActiveTexture(GL_TEXTURE1);
  f->glBindTexture(GL_TEXTURE_2D, 0);
  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, 0);

  // El quad se renderizó con la fila superior del lienzo en la fila 0 de
  // memoria del FBO, así que se lee sin flip vertical.
  QImage result = m_bakeFBO->toImage(false).convertToFormat(
      QImage::Format_RGBA8888_Premultiplied);

  f->glBindFramebuffer(GL_FRAMEBUFFER, static_cast<GLuint>(prevFbo));
  f->glViewport(prevViewport[0], prevViewport[1], prevViewport[2],
                prevViewport[3]);
  if (blendOn)
    f->glEnable(GL_BLEND);

  return result;
}

void LiquifyEngine::releaseGpuResources() {
  delete m_brushProgram;
  delete m_previewProgram;
  delete m_dispPing;
  delete m_dispPong;
  delete m_bakeFBO;
  delete m_sourceTex;
  m_brushProgram = nullptr;
  m_previewProgram = nullptr;
  m_dispPing = nullptr;
  m_dispPong = nullptr;
  m_bakeFBO = nullptr;
  m_sourceTex = nullptr;
  m_gpuSession = false;
}

} // namespace artflow
