#define GL_GLEXT_PROTOTYPES
#include "../include/stroke_renderer.h"
#include "../include/brush_engine.h"
#include <QColor>
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QMatrix4x4>
#include <QStringList>
#include <QVector2D>
#include <QVector3D>
#include <cmath>
#include <cstdint>

namespace artflow {

StrokeRenderer::StrokeRenderer()
    : m_program(nullptr), m_vbo(QOpenGLBuffer::VertexBuffer) {
  m_projection.setToIdentity();
}

void StrokeRenderer::beginFrame(int width, int height) {
  if (width <= 0 || height <= 0)
    return;

  m_viewportWidth = width;
  m_viewportHeight = height;

  m_projection.setToIdentity();
  m_projection.ortho(0, width, height, 0, -1, 1);

  // Ensure we are in the correct context if possible, but usually handled by
  // caller initializeOpenGLFunctions() is called in initialize()
}

void StrokeRenderer::endFrame() {
  // Cleanup if needed
}

void StrokeRenderer::drawDab(float x, float y, float size, float rotation,
                             float r, float g, float b, float a, float hardness,
                             float pressure, int mode, int brushType,
                             float wetness) {
  // Delegate to renderStroke
  QColor color;
  color.setRgbF(r, g, b, a);

  // Basic dab drawing - no advanced texture maps passed here
  // We use internal m_brushTextureId if available
  uint32_t brushTex = m_brushTextureId;
  bool useTex = (brushTex != 0);

  bool isEraser = (brushType == 7);
  renderStroke(x, y, size, pressure, hardness, color, brushType,
               m_viewportWidth, m_viewportHeight, brushTex, useTex, 1.0f, 1.0f,
               0.0f, 0.0f, 0, wetness, 0.0f, 0.0f, isEraser);
}

void StrokeRenderer::drawDabPingPong(float x, float y, float size,
                                     float rotation, float r, float g, float b,
                                     float a, float hardness, float pressure,
                                     int mode, int brushType, float wetness,
                                     unsigned int canvasTex,
                                     unsigned int wetMap) {
  QColor color;
  color.setRgbF(r, g, b, a);

  uint32_t brushTex = m_brushTextureId;
  bool useTex = (brushTex != 0);

  // For ping pong, we might be using the wet map as the "texture" or similar
  // specialized logic. For now, we map it to renderStroke's parameters via the
  // existing "canvasTexId" (which was intended for mixing)

  // Note: renderStroke's signature might need adjustment or we map carefully
  // renderStroke(..., canvasTexId, wetness, ...)

  // We pass 1.0 for texture scale/intensity as defaults
  bool isEraser = (brushType == 7);
  renderStroke(x, y, size, pressure, hardness, color, brushType,
               m_viewportWidth, m_viewportHeight, brushTex, useTex, 1.0f, 1.0f,
               0.0f, 0.0f, canvasTex, wetness, 0.0f, 0.0f, isEraser);
}

void StrokeRenderer::setBrushTip(const unsigned char *data, int width,
                                 int height) {
  if (!data || width <= 0 || height <= 0)
    return;

  if (m_brushTextureId == 0) {
    glGenTextures(1, &m_brushTextureId);
  }

  glBindTexture(GL_TEXTURE_2D, m_brushTextureId);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, data);
}

void StrokeRenderer::setPaperTexture(const unsigned char *data, int width,
                                     int height) {
  if (!data || width <= 0 || height <= 0)
    return;

  if (m_paperTextureId == 0) {
    glGenTextures(1, &m_paperTextureId);
  }

  glBindTexture(GL_TEXTURE_2D, m_paperTextureId);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  // Assuming paper is single channel (grayscale) or RGBA?
  // Python usually sends RGBA or Gray. Let's assume RGBA for safety or check
  // size. The previous implementation used GL_RGBA
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, data);
}

StrokeRenderer::~StrokeRenderer() {
  if (m_program)
    delete m_program;
}

void StrokeRenderer::initialize() {
  initializeOpenGLFunctions();

  // 1. Compilar Shaders
  m_program = new QOpenGLShaderProgram();

  // Search for shaders in common paths
  QStringList vertPaths, fragPaths;
  vertPaths << QCoreApplication::applicationDirPath() + "/shaders/brush.vert"
            << QCoreApplication::applicationDirPath() +
                   "/../src/core/shaders/brush.vert"
            << "e:/app_dibujo_proyecto-main/src/core/shaders/brush.vert"
            << "d:/app_dibujo_proyecto-main/src/core/shaders/brush.vert"
            << ":/shaders/brush.vert";

  fragPaths << QCoreApplication::applicationDirPath() + "/shaders/brush.frag"
            << QCoreApplication::applicationDirPath() +
                   "/../src/core/shaders/brush.frag"
            << "e:/app_dibujo_proyecto-main/src/core/shaders/brush.frag"
            << "d:/app_dibujo_proyecto-main/src/core/shaders/brush.frag"
            << ":/shaders/brush.frag";

  bool vertLoaded = false;
  for (const QString &p : vertPaths) {
    if (QFile::exists(p) &&
        m_program->addShaderFromSourceFile(QOpenGLShader::Vertex, p)) {
      vertLoaded = true;
      break;
    }
  }

  bool fragLoaded = false;
  for (const QString &p : fragPaths) {
    if (QFile::exists(p) &&
        m_program->addShaderFromSourceFile(QOpenGLShader::Fragment, p)) {
      fragLoaded = true;
      break;
    }
  }

  if (!vertLoaded || !fragLoaded || !m_program->link())
    qDebug() << "Error Link Shader:" << m_program->log();

  // 2. Crear Quad Estándar (0.0 a 1.0)
  float vertices[] = {// PosX, PosY, TexU, TexV
                      0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f,
                      0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f,
                      1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f};

  m_vao.create();
  m_vao.bind();

  m_vbo.create();
  m_vbo.bind();
  m_vbo.allocate(vertices, sizeof(vertices));

  // Atributos (layout del shader)
  glEnableVertexAttribArray(0); // Position
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void *)0);

  glEnableVertexAttribArray(1); // TexCoords
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                        (void *)(2 * sizeof(float)));

  m_vao.release();
  m_vbo.release();
}

void StrokeRenderer::renderStroke(float x, float y, float size, float pressure,
                                  float hardness, const QColor &color, int type,
                                  int width, int height, uint32_t grainTexId,
                                  bool useTex, float texScale,
                                  float texIntensity, float tilt,
                                  float velocity, uint32_t canvasTexId,
                                  float wetness, float dilution, float smudge,
                                  bool isEraser) {
  if (!m_program)
    return;

  m_program->bind();
  m_vao.bind();

  // Force isEraser if type is 7 (Safety)
  if (type == 7)
    isEraser = true;

  // --- MATRICES DE POSICIONAMIENTO ---
  QMatrix4x4 projection;
  projection.ortho(0, width, height, 0, -1, 1);

  QMatrix4x4 model;
  model.translate(x - size / 2, y - size / 2, 0);
  model.scale(size, size, 1);

  m_program->setUniformValue("projectionMatrix", projection);
  m_program->setUniformValue("modelMatrix", model);
  m_program->setUniformValue("color", color);
  m_program->setUniformValue("pressure", pressure);
  m_program->setUniformValue("hardness", hardness);
  m_program->setUniformValue("uDabPos", QVector2D(x, y));
  m_program->setUniformValue("uDabSize", size);

  // -- PREMIUM UNIFORMS --
  m_program->setUniformValue("u_impastoStrength", 5.0f);
  m_program->setUniformValue("u_lightDir", QVector3D(-0.5f, -0.5f, 1.0f));

  // Configurar Texturas Premium
  if (useTex) {
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, grainTexId);
    m_program->setUniformValue("brushTexture", 1);
    m_program->setUniformValue("uHasTexture", 1);
    m_program->setUniformValue("textureScale", texScale);
    m_program->setUniformValue("textureIntensity", texIntensity);
    m_program->setUniformValue("tilt", tilt);
    m_program->setUniformValue("velocity", velocity);

    // Pilar 3: Mezcla Húmeda y Smudge
    m_program->setUniformValue("wetness", wetness);
    m_program->setUniformValue("dilution", dilution);
    m_program->setUniformValue("smudge", smudge);
    m_program->setUniformValue("canvasSize", QVector2D(width, height));

    if (wetness > 0.01f || smudge > 0.01f) {
      glActiveTexture(GL_TEXTURE2);
      glBindTexture(GL_TEXTURE_2D, canvasTexId);
      m_program->setUniformValue("canvasTexture", 2);
    }
  } else {
    m_program->setUniformValue("uHasTexture", 0);
    m_program->setUniformValue("tilt", 0.0f);
    m_program->setUniformValue("velocity", 0.0f);
    m_program->setUniformValue("wetness", 0.0f);
    m_program->setUniformValue("dilution", 0.0f);
    m_program->setUniformValue("smudge", 0.0f);
  }

  // --- CONFIGURACIÓN DE MEZCLA DEFINITIVA ---
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glBlendEquation(GL_FUNC_ADD);

  if (isEraser) {
    // MODO BORRADOR: Dest = Dest * (1 - SourceAlpha)
    glBlendFuncSeparate(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA, GL_ZERO,
                        GL_ONE_MINUS_SRC_ALPHA);
    m_program->setUniformValue("color", QColor(0, 0, 0, 255));
  } else {
    // MODO PINTAR NORMAL - PREMULTIPLIED
    glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE,
                        GL_ONE_MINUS_SRC_ALPHA);
    m_program->setUniformValue("color", color);
  }

  // Dibujamos el Quad pre-cargado
  m_vao.bind();
  glDrawArrays(GL_TRIANGLES, 0, 6);
  m_vao.release();

  m_program->release();
}

} // namespace artflow
