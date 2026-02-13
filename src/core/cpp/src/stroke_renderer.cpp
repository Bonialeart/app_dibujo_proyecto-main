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
}

void StrokeRenderer::endFrame() {
  // Cleanup if needed
}

void StrokeRenderer::drawDab(float x, float y, float size, float rotation,
                             float r, float g, float b, float a, float hardness,
                             float pressure, int mode, int brushType,
                             float wetness) {
  QColor color;
  color.setRgbF(r, g, b, a);

  uint32_t brushTex = m_brushTextureId;
  bool hasTip = (brushTex != 0);

  bool isEraser = (brushType == 7);
  renderStroke(x, y, size, pressure, hardness, color, brushType,
               m_viewportWidth, m_viewportHeight, 0, false, 1.0f,
               0.0f,                       // No grain
               brushTex, hasTip, rotation, // Tip
               0.0f, 0.0f, 1.0f,           // No dynamics, flow=1
               0, wetness, 0.0f, 0.0f,     // Wet mix
               isEraser);
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
  bool hasTip = (brushTex != 0);

  bool isEraser = (brushType == 7);
  renderStroke(x, y, size, pressure, hardness, color, brushType,
               m_viewportWidth, m_viewportHeight, 0, false, 1.0f,
               0.0f,                           // No grain
               brushTex, hasTip, 0.0f,         // Tip
               0.0f, 0.0f, 1.0f,               // No dynamics, flow=1
               canvasTex, wetness, 0.0f, 0.0f, // Wet mix
               isEraser);
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

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, data);
}

StrokeRenderer::~StrokeRenderer() {
  if (m_program)
    delete m_program;
}

void StrokeRenderer::initialize() {
  initializeOpenGLFunctions();

  // 1. Compile Shaders
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
      qDebug() << "Vertex shader loaded from:" << p;
      break;
    }
  }

  bool fragLoaded = false;
  for (const QString &p : fragPaths) {
    if (QFile::exists(p) &&
        m_program->addShaderFromSourceFile(QOpenGLShader::Fragment, p)) {
      fragLoaded = true;
      qDebug() << "Fragment shader loaded from:" << p;
      break;
    }
  }

  if (!vertLoaded || !fragLoaded || !m_program->link())
    qDebug() << "Error Link Shader:" << m_program->log();

  // 2. Create Standard Quad (0.0 to 1.0)
  float vertices[] = {// PosX, PosY, TexU, TexV
                      0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f,
                      0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f,
                      1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f};

  m_vao.create();
  m_vao.bind();

  m_vbo.create();
  m_vbo.bind();
  m_vbo.allocate(vertices, sizeof(vertices));

  // Attributes (shader layout)
  glEnableVertexAttribArray(0); // Position
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void *)0);

  glEnableVertexAttribArray(1); // TexCoords
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                        (void *)(2 * sizeof(float)));

  m_vao.release();
  m_vbo.release();
}

void StrokeRenderer::renderStroke(
    float x, float y, float size, float pressure, float hardness,
    const QColor &color, int type, int width, int height,
    // Grain
    uint32_t grainTexId, bool hasGrain, float grainScale, float grainIntensity,
    // Tip
    uint32_t tipTexId, bool hasTip, float tipRotation,
    // Dynamics
    float tilt, float velocity, float flow,
    // Wet Mix
    uint32_t canvasTexId, float wetness, float dilution, float smudge,
    // Mode
    bool isEraser) {

  if (!m_program)
    return;

  m_program->bind();
  m_vao.bind();

  // Force isEraser if type is 7 (Safety)
  if (type == 7)
    isEraser = true;

  // --- POSITIONING MATRICES ---
  QMatrix4x4 projection;
  projection.ortho(0, width, height, 0, -1, 1);

  QMatrix4x4 model;
  model.translate(x - size / 2, y - size / 2, 0);
  model.scale(size, size, 1);

  m_program->setUniformValue("projectionMatrix", projection);
  m_program->setUniformValue("modelMatrix", model);
  m_program->setUniformValue("pressure", pressure);
  m_program->setUniformValue("hardness", hardness);
  m_program->setUniformValue("flow", flow);
  m_program->setUniformValue("brushType", type);
  m_program->setUniformValue("uDabPos", QVector2D(x, y));
  m_program->setUniformValue("uDabSize", size);
  m_program->setUniformValue("tipRotation", tipRotation);

  // === TEXTURE UNIT ALLOCATION ===
  // Unit 0: Tip Texture (brush shape)
  // Unit 1: Grain Texture (paper grain)
  // Unit 2: Canvas Texture (ping-pong for wet mix)

  // --- TIP TEXTURE (Shape) — Local UV mapping in shader ---
  if (hasTip && tipTexId != 0) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tipTexId);
    m_program->setUniformValue("tipTexture", 0);
    m_program->setUniformValue("uHasTip", 1);
  } else {
    m_program->setUniformValue("uHasTip", 0);
  }

  // --- GRAIN TEXTURE (Paper) — Global canvas mapping in shader ---
  if (hasGrain && grainTexId != 0) {
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, grainTexId);
    m_program->setUniformValue("grainTexture", 1);
    m_program->setUniformValue("uHasGrain", 1);
    m_program->setUniformValue("grainScale", grainScale);
    m_program->setUniformValue("grainIntensity", grainIntensity);
  } else {
    m_program->setUniformValue("uHasGrain", 0);
    m_program->setUniformValue("grainScale", 1.0f);
    m_program->setUniformValue("grainIntensity", 0.0f);
  }

  // --- WET MIX ENGINE — Canvas texture for paint mixing ---
  m_program->setUniformValue("wetness", wetness);
  m_program->setUniformValue("dilution", dilution);
  m_program->setUniformValue("smudge", smudge);
  m_program->setUniformValue("canvasSize", QVector2D(width, height));

  if ((wetness > 0.01f || smudge > 0.01f) && canvasTexId != 0) {
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, canvasTexId);
    m_program->setUniformValue("canvasTexture", 2);
  }

  // --- BLEND MODE ---
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glBlendEquation(GL_FUNC_ADD);

  if (isEraser) {
    // ERASER MODE: Dest = Dest * (1 - SourceAlpha)
    glBlendFuncSeparate(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA, GL_ZERO,
                        GL_ONE_MINUS_SRC_ALPHA);
    m_program->setUniformValue("color", QColor(0, 0, 0, 255));
  } else {
    // NORMAL PAINT MODE — PREMULTIPLIED ALPHA
    glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE,
                        GL_ONE_MINUS_SRC_ALPHA);
    m_program->setUniformValue("color", color);
  }

  // Draw the pre-loaded quad
  m_vao.bind();
  glDrawArrays(GL_TRIANGLES, 0, 6);
  m_vao.release();

  m_program->release();
}

} // namespace artflow
