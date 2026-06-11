#include "../include/stroke_renderer.h"
#include "../include/brush_engine.h"
#include <QColor>
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QMatrix4x4>
#include <QOpenGLFunctions>
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
               0.0f, 0.0f, 1.0f, false,    // No grain, brightness=0, contrast=1, invert=false
               brushTex, hasTip, rotation, // Tip
               0.0f, 0.0f, 1.0f,           // No dynamics, flow=1
               0, wetness, 0.0f, 0.0f,     // Wet mix
               0.0f);                      // bleed (defaults)
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
               0.0f, 0.0f, 1.0f, false,    // No grain, brightness=0, contrast=1, invert=false
               brushTex, hasTip, 0.0f,         // Tip
               0.0f, 0.0f, 1.0f,               // No dynamics, flow=1
               canvasTex, wetness, 0.0f, 0.0f, // Wet mix
               0.0f);                          // bleed (defaults)
}

void StrokeRenderer::setBrushTip(const unsigned char *data, int width,
                                 int height) {
  if (!data || width <= 0 || height <= 0)
    return;

  if (m_brushTextureId == 0) {
    glGenTextures(1, &m_brushTextureId);
  }

  glBindTexture(GL_TEXTURE_2D, m_brushTextureId);

  // GL_LINEAR_MIPMAP_LINEAR (trilineal) para mejor calidad al reducir el pincel
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  // GL_CLAMP_TO_BORDER con borde TRANSPARENTE:
  // Cuando el tip rota y la UV sale de [0,1] el GPU devuelve alpha=0
  // automaticamente, sin artefactos ni descarte manual en el shader.
#ifdef GL_CLAMP_TO_BORDER
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  float zeroBorder[] = {0.0f, 0.0f, 0.0f, 0.0f};
  glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, zeroBorder);
#else
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
#endif

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, data);
  glGenerateMipmap(GL_TEXTURE_2D); // Genera mipmaps para escalado de alta calidad
}

void StrokeRenderer::setPaperTexture(const unsigned char *data, int width,
                                     int height) {
  if (!data || width <= 0 || height <= 0)
    return;

  if (m_paperTextureId == 0) {
    glGenTextures(1, &m_paperTextureId);
  }

  glBindTexture(GL_TEXTURE_2D, m_paperTextureId);

  // Trilineal para el grano de papel — se ve bien a cualquier zoom
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, data);
  glGenerateMipmap(GL_TEXTURE_2D);
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
  vertPaths << ":/src/core/shaders/brush.vert"
            << QCoreApplication::applicationDirPath() + "/shaders/brush.vert"
            << QCoreApplication::applicationDirPath() +
                   "/../src/core/shaders/brush.vert"
            << "e:/app_dibujo_proyecto-main/src/core/shaders/brush.vert"
            << "d:/app_dibujo_proyecto-main/src/core/shaders/brush.vert"
            << ":/shaders/brush.vert";

  fragPaths << ":/src/core/shaders/brush.frag"
            << QCoreApplication::applicationDirPath() + "/shaders/brush.frag"
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

  // Instance VBO setup
  m_instanceVbo.create();
  m_instanceVbo.setUsagePattern(QOpenGLBuffer::DynamicDraw);
  m_instanceVbo.bind();

  glEnableVertexAttribArray(2); // Inst Pos
  glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 9 * sizeof(float),
                        (void *)(0));
  glVertexAttribDivisor(2, 1);

  glEnableVertexAttribArray(3); // Inst Size
  glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, 9 * sizeof(float),
                        (void *)(2 * sizeof(float)));
  glVertexAttribDivisor(3, 1);

  glEnableVertexAttribArray(4); // Inst Rotation
  glVertexAttribPointer(4, 1, GL_FLOAT, GL_FALSE, 9 * sizeof(float),
                        (void *)(3 * sizeof(float)));
  glVertexAttribDivisor(4, 1);

  glEnableVertexAttribArray(5); // Inst Color
  glVertexAttribPointer(5, 4, GL_FLOAT, GL_FALSE, 9 * sizeof(float),
                        (void *)(4 * sizeof(float)));
  glVertexAttribDivisor(5, 1);

  glEnableVertexAttribArray(6); // Inst Paint Load
  glVertexAttribPointer(6, 1, GL_FLOAT, GL_FALSE, 9 * sizeof(float),
                        (void *)(8 * sizeof(float)));
  glVertexAttribDivisor(6, 1);
  m_instanceVbo.release();

  m_vao.release();
  m_vbo.release();
}

// Premium rendering with dual texture support
void StrokeRenderer::renderStroke(
    float x, float y, float size, float pressure, float hardness,
    const QColor &color, int type, int width, int height,
    // Grain texture
    uint32_t grainTexId, bool hasGrain, float grainScale, float grainIntensity,
    float grainBright, float grainCon, bool invertGrain, float grainRotation,
    // Tip texture
    uint32_t tipTexId, bool hasTip, float tipRotation,
    // Dynamics
    float tilt, float velocity, float flow,
    // Wet Mix Engine
    uint32_t canvasTexId, float wetness, float dilution, float smudge,
    // New parameters
    float bleed, float absorptionRate, float dryingTime,
    float wetOnWetMultiplier, float granulation, float pigmentFlow,
    float staining, float separation, bool bloomEnabled, float bloomIntensity,
    float bloomRadius, float bloomThreshold, bool edgeDarkeningEnabled,
    float edgeDarkeningIntensity, float edgeDarkeningWidth,
    bool textureRevealEnabled, float textureRevealIntensity,
    float textureRevealPressureInfluence,
    // Oil Paint Parameters
    float mixing, float loading, float depletionRate, bool dirtyMixing,
    float colorPickup, bool blendOnly, bool scrapeThrough,
    // Impasto
    bool impastoEnabled, float impastoDepth, float impastoShine,
    float impastoTextureStrength, float impastoEdgeBuildup,
    bool impastoDirectionalRidges, float impastoSmoothing,
    bool impastoPreserveExisting,
    // Bristles
    bool bristlesEnabled, int bristleCount, float bristleStiffness,
    float bristleClumping, float bristleFanSpread,
    float bristleIndividualVariation, bool bristleDryBrushEffect,
    float bristleSoftness, float bristlePointTaper,
    // Smudge (Advanced)
    float smudgeStrength, float smudgePressureInfluence, float smudgeLength,
    float smudgeGaussianBlur, bool smudgeSmear,
    // Canvas Interaction
    float canvasAbsorption, bool canvasSkipValleys, float canvasCatchPeaks,
    // Oil Color Dynamics
    float temperatureShift, float brokenColor,
    // Dual brush and grain modes
    uint32_t dualTipTexId, bool hasDualTip, float dualTipScale, float dualTipRotation, int dualTipBlendMode, float dualTipFlow, int grainBlendMode,
    uint32_t dualGrainTexId, bool hasDualGrain, float dualGrainScale, float dualGrainIntensity, float dualGrainBright, float dualGrainCon, bool invertDualGrain, int dualGrainBlendMode, float dualGrainRotation,
    bool isEraser,
    bool colorMixing, float paintAmount, float colorStretch, int blendMode,
    bool invertShape, bool flipX, bool flipY, float roundness, float shapeContrast, float shapeBlur,
    bool grainEmphasizeDensity, bool dualGrainEmphasizeDensity,
    bool grainApplyToTips, bool dualGrainApplyToTips) {

  if (!m_program)
    return;

  m_program->bind();
  m_vao.bind();

  // Detectar borrador si el tipo es 7 o si recibe la contraseña mágica (Alpha
  // 254)
  int alphaInt = std::round(color.alphaF() * 255.0f);
  if (type == 7 || alphaInt == 254) {
    isEraser = true;
    type = 7; // Forzar tipo 7 para que el shader lo reconozca
  }

  // --- POSITIONING MATRICES ---
  QMatrix4x4 projection;
  projection.ortho(0, width, height, 0, -1, 1);

  QMatrix4x4 model;
  model.translate(x, y, 0);
  if (std::abs(tipRotation) > 0.001f) {
    model.rotate(tipRotation * 180.0f / 3.14159265f, 0.0f, 0.0f, 1.0f);
  }
  model.translate(-size / 2, -size / 2, 0);
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
  m_program->setUniformValue("uInvertShape", invertShape ? 1 : 0);
  m_program->setUniformValue("uFlipX", flipX ? 1 : 0);
  m_program->setUniformValue("uFlipY", flipY ? 1 : 0);
  m_program->setUniformValue("uRoundness", roundness);
  m_program->setUniformValue("uShapeContrast", shapeContrast);
  m_program->setUniformValue("uShapeBlur", shapeBlur);
  m_program->setUniformValue("uGrainEmphasizeDensity", grainEmphasizeDensity ? 1 : 0);
  m_program->setUniformValue("uDualGrainEmphasizeDensity", dualGrainEmphasizeDensity ? 1 : 0);
  m_program->setUniformValue("uGrainApplyToTips", grainApplyToTips ? 1 : 0);
  m_program->setUniformValue("uDualGrainApplyToTips", dualGrainApplyToTips ? 1 : 0);

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
    m_program->setUniformValue("uGrainBrightness", grainBright);
    m_program->setUniformValue("uGrainContrast", grainCon);
    m_program->setUniformValue("uInvertGrain", invertGrain ? 1 : 0);
    m_program->setUniformValue("uGrainRotation", grainRotation);
  } else {
    m_program->setUniformValue("uHasGrain", 0);
    m_program->setUniformValue("grainScale", 1.0f);
    m_program->setUniformValue("grainIntensity", 0.0f);
    m_program->setUniformValue("uGrainBrightness", 0.0f);
    m_program->setUniformValue("uGrainContrast", 1.0f);
    m_program->setUniformValue("uInvertGrain", 0);
    m_program->setUniformValue("uGrainRotation", 0.0f);
  }

  // --- DUAL TIP TEXTURE ---
  if (hasDualTip && dualTipTexId != 0) {
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, dualTipTexId);
    m_program->setUniformValue("dualTipTexture", 3);
    m_program->setUniformValue("uHasDualTip", 1);
    m_program->setUniformValue("dualTipScale", dualTipScale);
    m_program->setUniformValue("dualTipRotation", dualTipRotation);
    m_program->setUniformValue("uDualTipBlendMode", dualTipBlendMode);
    m_program->setUniformValue("uDualTipFlow", dualTipFlow);
  } else {
    m_program->setUniformValue("uHasDualTip", 0);
    m_program->setUniformValue("dualTipScale", 1.0f);
    m_program->setUniformValue("dualTipRotation", 0.0f);
    m_program->setUniformValue("uDualTipBlendMode", 0);
    m_program->setUniformValue("uDualTipFlow", 1.0f);
  }

  // --- DUAL GRAIN TEXTURE ---
  if (hasDualGrain && dualGrainTexId != 0) {
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, dualGrainTexId);
    m_program->setUniformValue("dualGrainTexture", 4);
    m_program->setUniformValue("uHasDualGrain", 1);
    m_program->setUniformValue("dualGrainScale", dualGrainScale);
    m_program->setUniformValue("dualGrainIntensity", dualGrainIntensity);
    m_program->setUniformValue("uDualGrainBrightness", dualGrainBright);
    m_program->setUniformValue("uDualGrainContrast", dualGrainCon);
    m_program->setUniformValue("uInvertDualGrain", invertDualGrain ? 1 : 0);
    m_program->setUniformValue("uDualGrainBlendMode", dualGrainBlendMode);
    m_program->setUniformValue("uDualGrainRotation", dualGrainRotation);
  } else {
    m_program->setUniformValue("uHasDualGrain", 0);
    m_program->setUniformValue("dualGrainScale", 1.0f);
    m_program->setUniformValue("dualGrainIntensity", 0.0f);
    m_program->setUniformValue("uDualGrainBrightness", 0.0f);
    m_program->setUniformValue("uDualGrainContrast", 1.0f);
    m_program->setUniformValue("uInvertDualGrain", 0);
    m_program->setUniformValue("uDualGrainBlendMode", 0);
    m_program->setUniformValue("uDualGrainRotation", 0.0f);
  }

  // --- GRAIN BLEND MODE ---
  m_program->setUniformValue("uGrainBlendMode", grainBlendMode);

  // --- WET MIX ENGINE & WATERCOLOR UNIFORMS ---
  m_program->setUniformValue("wetness", wetness);
  m_program->setUniformValue("dilution", dilution);
  m_program->setUniformValue("smudge", smudge);
  m_program->setUniformValue("canvasSize", QVector2D(width, height));

  // New Watercolor Uniforms
  m_program->setUniformValue("bleed", bleed);
  m_program->setUniformValue("granulation", granulation);

  m_program->setUniformValue("bloomEnabled", bloomEnabled ? 1 : 0);
  m_program->setUniformValue("bloomIntensity", bloomIntensity);
  m_program->setUniformValue("bloomRadius", bloomRadius);
  m_program->setUniformValue("bloomThreshold", bloomThreshold);

  m_program->setUniformValue("edgeDarkeningEnabled",
                             edgeDarkeningEnabled ? 1 : 0);
  m_program->setUniformValue("edgeDarkeningIntensity", edgeDarkeningIntensity);
  m_program->setUniformValue("edgeDarkeningWidth", edgeDarkeningWidth);

  m_program->setUniformValue("textureRevealEnabled",
                             textureRevealEnabled ? 1 : 0);
  m_program->setUniformValue("textureRevealIntensity", textureRevealIntensity);
  m_program->setUniformValue("textureRevealPressureInfluence",
                             textureRevealPressureInfluence);

  // === OIL PAINT UNIFORMS ===
  m_program->setUniformValue("mixing", mixing);
  m_program->setUniformValue("loading", loading);
  m_program->setUniformValue("depletionRate", depletionRate);
  m_program->setUniformValue("dirtyMixing", dirtyMixing ? 1 : 0);
  m_program->setUniformValue("colorPickup", colorPickup);
  m_program->setUniformValue("blendOnly", blendOnly ? 1 : 0);
  m_program->setUniformValue("scrapeThrough", scrapeThrough ? 1 : 0);

  // Impasto
  m_program->setUniformValue("impastoEnabled", impastoEnabled ? 1 : 0);
  m_program->setUniformValue("impastoDepth", impastoDepth);
  m_program->setUniformValue("impastoShine", impastoShine);
  m_program->setUniformValue("impastoTextureStrength", impastoTextureStrength);
  m_program->setUniformValue("impastoEdgeBuildup", impastoEdgeBuildup);
  m_program->setUniformValue("impastoDirectionalRidges",
                             impastoDirectionalRidges ? 1 : 0); // Simplified
  m_program->setUniformValue("impastoSmoothing", impastoSmoothing);
  m_program->setUniformValue("impastoPreserveExisting",
                             impastoPreserveExisting ? 1 : 0);

  // Bristles
  m_program->setUniformValue("bristlesEnabled", bristlesEnabled ? 1 : 0);
  m_program->setUniformValue("bristleCount", bristleCount);
  m_program->setUniformValue("bristleStiffness", bristleStiffness);
  m_program->setUniformValue("bristleClumping", bristleClumping);
  m_program->setUniformValue("bristleFanSpread", bristleFanSpread);
  m_program->setUniformValue("bristleIndividualVariation",
                             bristleIndividualVariation);
  m_program->setUniformValue("bristleDryBrushEffect",
                             bristleDryBrushEffect ? 1 : 0);
  m_program->setUniformValue("bristleSoftness", bristleSoftness);
  m_program->setUniformValue("bristlePointTaper", bristlePointTaper);

  // Smudge
  m_program->setUniformValue("smudgeStrength", smudgeStrength);
  m_program->setUniformValue("smudgePressureInfluence",
                             smudgePressureInfluence);
  m_program->setUniformValue("smudgeLength", smudgeLength);
  m_program->setUniformValue("smudgeGaussianBlur", smudgeGaussianBlur);
  m_program->setUniformValue("smudgeSmear", smudgeSmear ? 1 : 0);

  // Canvas Interaction
  m_program->setUniformValue("canvasAbsorption", canvasAbsorption);
  m_program->setUniformValue("canvasSkipValleys", canvasSkipValleys ? 1 : 0);
  m_program->setUniformValue("canvasCatchPeaks", canvasCatchPeaks);

  // Color Dynamics Oil
  m_program->setUniformValue("temperatureShift", temperatureShift);
  m_program->setUniformValue("brokenColor", brokenColor);

  if ((wetness > 0.01f || smudge > 0.01f || bloomEnabled || mixing > 0.01f ||
       impastoEnabled || type == 5) &&
      canvasTexId != 0) {
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, canvasTexId);
    m_program->setUniformValue("canvasTexture", 2);
  }

  m_program->setUniformValue("uColorMixing", colorMixing ? 1 : 0);
  m_program->setUniformValue("uPaintAmount", paintAmount);
  m_program->setUniformValue("uColorStretch", colorStretch);
  m_program->setUniformValue("uBrushBlendMode", blendMode);

  // --- BLEND MODE ---
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glBlendEquation(GL_FUNC_ADD);

  if (isEraser) {
    // MODO BORRADOR REAL:
    // Forzamos un alpha puro (1.0) al shader para que la resta matemática sea
    // perfecta.
    m_program->setUniformValue("color", QColor(0, 0, 0, 255));
    m_program->setUniformValue("brushType", 7);
    m_program->setUniformValue("impastoEnabled",
                               0); // ¡IMPORTANTE! No generar altura

    // Dest = Dest * (1 - SrcAlpha) -> Limpia tanto RGB como canal de altura
    // (Alpha)
    glBlendFuncSeparate(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA, GL_ZERO,
                        GL_ONE_MINUS_SRC_ALPHA);
  } else {
    // PINTURA NORMAL
    m_program->setUniformValue("color", color);
    if (blendMode == 1) { // Multiply
      glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    } else if (blendMode == 2) { // Screen
      glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);
    } else if (impastoEnabled && type == 5) {
      // IMPASTO: RGB usa composición alfa estándar, pero ALPHA (altura)
      // se acumula aditivamente para que la pasta se construya capa sobre capa
      glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA,
                          GL_ONE, GL_ONE);
    } else { // Normal (alpha-lock se aplica en el shader multiplicando alpha por Dst_A)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
  }

  // Draw the pre-loaded quad
  m_vao.bind();
  glDrawArrays(GL_TRIANGLES, 0, 6);
  m_vao.release();

  m_program->release();
}

void StrokeRenderer::renderStrokeInstanced(
    const std::vector<DabInstance> &dabs, float pressure, float hardness,
    int type, int width, int height,
    // Grain texture
    uint32_t grainTexId, bool hasGrain, float grainScale, float grainIntensity,
    float grainBright, float grainCon, bool invertGrain, float grainRotation,
    // Tip texture
    uint32_t tipTexId, bool hasTip,
    // Dynamics
    float tilt, float velocity, float flow,
    // Wet Mix Engine
    uint32_t canvasTexId, float wetness, float dilution, float smudge,
    // New Watercolor params
    float bleed, float absorptionRate, float dryingTime,
    float wetOnWetMultiplier, float granulation, float pigmentFlow,
    float staining, float separation, bool bloomEnabled, float bloomIntensity,
    float bloomRadius, float bloomThreshold, bool edgeDarkeningEnabled,
    float edgeDarkeningIntensity, float edgeDarkeningWidth,
    bool textureRevealEnabled, float textureRevealIntensity,
    float textureRevealPressureInfluence,
    // Oil Paint Parameters
    float mixing, float loading, float depletionRate, bool dirtyMixing,
    float colorPickup, bool blendOnly, bool scrapeThrough,
    // Impasto
    bool impastoEnabled, float impastoDepth, float impastoShine,
    float impastoTextureStrength, float impastoEdgeBuildup,
    bool impastoDirectionalRidges, float impastoSmoothing,
    bool impastoPreserveExisting,
    // Bristles
    bool bristlesEnabled, int bristleCount, float bristleStiffness,
    float bristleClumping, float bristleFanSpread,
    float bristleIndividualVariation, bool bristleDryBrushEffect,
    float bristleSoftness, float bristlePointTaper,
    // Smudge (Advanced)
    float smudgeStrength, float smudgePressureInfluence, float smudgeLength,
    float smudgeGaussianBlur, bool smudgeSmear,
    // Canvas Interaction
    float canvasAbsorption, bool canvasSkipValleys, float canvasCatchPeaks,
    // Oil Color Dynamics
    float temperatureShift, float brokenColor,
    // Dual brush and grain modes
    uint32_t dualTipTexId, bool hasDualTip, float dualTipScale, float dualTipRotation, int dualTipBlendMode, float dualTipFlow, int grainBlendMode,
    uint32_t dualGrainTexId, bool hasDualGrain, float dualGrainScale, float dualGrainIntensity, float dualGrainBright, float dualGrainCon, bool invertDualGrain, int dualGrainBlendMode, float dualGrainRotation,
    bool isEraser,
    bool colorMixing, float paintAmount, float colorStretch, int blendMode,
    bool invertShape, bool flipX, bool flipY, float roundness, float shapeContrast, float shapeBlur,
    bool grainEmphasizeDensity, bool dualGrainEmphasizeDensity,
    bool grainApplyToTips, bool dualGrainApplyToTips) {

  if (!m_program || dabs.empty())
    return;

  m_program->bind();
  m_vao.bind();

  // Upload instance data — reutiliza la reserva del VBO si cabe para evitar
  // realocar memoria GPU en cada segmento de trazo (reduce latencia del lápiz)
  const int neededBytes = static_cast<int>(dabs.size() * sizeof(DabInstance));
  m_instanceVbo.bind();
  if (neededBytes > m_instanceCapacity) {
    // Crecer con margen para amortiguar trazos rápidos con muchos dabs
    m_instanceCapacity = neededBytes * 2;
    m_instanceVbo.allocate(m_instanceCapacity);
  }
  m_instanceVbo.write(0, dabs.data(), neededBytes);
  m_instanceVbo.release();

  if (type == 7) {
    isEraser = true;
  }

  // --- POSITIONING MATRICES ---
  QMatrix4x4 projection;
  projection.ortho(0, width, height, 0, -1, 1);

  m_program->setUniformValue("projectionMatrix", projection);
  m_program->setUniformValue("pressure", pressure);
  m_program->setUniformValue("hardness", hardness);
  m_program->setUniformValue("flow", flow);
  m_program->setUniformValue("brushType", type);
  m_program->setUniformValue("uInvertShape", invertShape ? 1 : 0);
  m_program->setUniformValue("uFlipX", flipX ? 1 : 0);
  m_program->setUniformValue("uFlipY", flipY ? 1 : 0);
  m_program->setUniformValue("uRoundness", roundness);
  m_program->setUniformValue("uShapeContrast", shapeContrast);
  m_program->setUniformValue("uShapeBlur", shapeBlur);
  m_program->setUniformValue("uGrainEmphasizeDensity", grainEmphasizeDensity ? 1 : 0);
  m_program->setUniformValue("uDualGrainEmphasizeDensity", dualGrainEmphasizeDensity ? 1 : 0);
  m_program->setUniformValue("uGrainApplyToTips", grainApplyToTips ? 1 : 0);
  m_program->setUniformValue("uDualGrainApplyToTips", dualGrainApplyToTips ? 1 : 0);

  // === TEXTURE UNIT ALLOCATION ===
  if (hasTip && tipTexId != 0) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tipTexId);
    m_program->setUniformValue("tipTexture", 0);
    m_program->setUniformValue("uHasTip", 1);
  } else {
    m_program->setUniformValue("uHasTip", 0);
  }

  // --- GRAIN TEXTURE (Paper) ---
  if (hasGrain && grainTexId != 0) {
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, grainTexId);
    m_program->setUniformValue("grainTexture", 1);
    m_program->setUniformValue("uHasGrain", 1);
    m_program->setUniformValue("grainScale", grainScale);
    m_program->setUniformValue("grainIntensity", grainIntensity);
    m_program->setUniformValue("uGrainBrightness", grainBright);
    m_program->setUniformValue("uGrainContrast", grainCon);
    m_program->setUniformValue("uInvertGrain", invertGrain ? 1 : 0);
    m_program->setUniformValue("uGrainRotation", grainRotation);
  } else {
    m_program->setUniformValue("uHasGrain", 0);
    m_program->setUniformValue("grainScale", 1.0f);
    m_program->setUniformValue("grainIntensity", 0.0f);
    m_program->setUniformValue("uGrainBrightness", 0.0f);
    m_program->setUniformValue("uGrainContrast", 1.0f);
    m_program->setUniformValue("uInvertGrain", 0);
    m_program->setUniformValue("uGrainRotation", 0.0f);
  }

  // --- DUAL TIP TEXTURE ---
  if (hasDualTip && dualTipTexId != 0) {
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, dualTipTexId);
    m_program->setUniformValue("dualTipTexture", 3);
    m_program->setUniformValue("uHasDualTip", 1);
    m_program->setUniformValue("dualTipScale", dualTipScale);
    m_program->setUniformValue("dualTipRotation", dualTipRotation);
    m_program->setUniformValue("uDualTipBlendMode", dualTipBlendMode);
    m_program->setUniformValue("uDualTipFlow", dualTipFlow);
  } else {
    m_program->setUniformValue("uHasDualTip", 0);
    m_program->setUniformValue("dualTipScale", 1.0f);
    m_program->setUniformValue("dualTipRotation", 0.0f);
    m_program->setUniformValue("uDualTipBlendMode", 0);
    m_program->setUniformValue("uDualTipFlow", 1.0f);
  }

  // --- DUAL GRAIN TEXTURE ---
  if (hasDualGrain && dualGrainTexId != 0) {
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, dualGrainTexId);
    m_program->setUniformValue("dualGrainTexture", 4);
    m_program->setUniformValue("uHasDualGrain", 1);
    m_program->setUniformValue("dualGrainScale", dualGrainScale);
    m_program->setUniformValue("dualGrainIntensity", dualGrainIntensity);
    m_program->setUniformValue("uDualGrainBrightness", dualGrainBright);
    m_program->setUniformValue("uDualGrainContrast", dualGrainCon);
    m_program->setUniformValue("uInvertDualGrain", invertDualGrain ? 1 : 0);
    m_program->setUniformValue("uDualGrainBlendMode", dualGrainBlendMode);
    m_program->setUniformValue("uDualGrainRotation", dualGrainRotation);
  } else {
    m_program->setUniformValue("uHasDualGrain", 0);
    m_program->setUniformValue("dualGrainScale", 1.0f);
    m_program->setUniformValue("dualGrainIntensity", 0.0f);
    m_program->setUniformValue("uDualGrainBrightness", 0.0f);
    m_program->setUniformValue("uDualGrainContrast", 1.0f);
    m_program->setUniformValue("uInvertDualGrain", 0);
    m_program->setUniformValue("uDualGrainBlendMode", 0);
    m_program->setUniformValue("uDualGrainRotation", 0.0f);
  }

  // --- GRAIN BLEND MODE ---
  m_program->setUniformValue("uGrainBlendMode", grainBlendMode);

  // --- WET MIX ENGINE & WATERCOLOR UNIFORMS ---
  m_program->setUniformValue("wetness", wetness);
  m_program->setUniformValue("dilution", dilution);
  m_program->setUniformValue("smudge", smudge);
  m_program->setUniformValue("canvasSize", QVector2D(width, height));

  m_program->setUniformValue("bleed", bleed);
  m_program->setUniformValue("granulation", granulation);

  m_program->setUniformValue("bloomEnabled", bloomEnabled ? 1 : 0);
  m_program->setUniformValue("bloomIntensity", bloomIntensity);
  m_program->setUniformValue("bloomRadius", bloomRadius);
  m_program->setUniformValue("bloomThreshold", bloomThreshold);

  m_program->setUniformValue("edgeDarkeningEnabled",
                             edgeDarkeningEnabled ? 1 : 0);
  m_program->setUniformValue("edgeDarkeningIntensity", edgeDarkeningIntensity);
  m_program->setUniformValue("edgeDarkeningWidth", edgeDarkeningWidth);

  m_program->setUniformValue("textureRevealEnabled",
                             textureRevealEnabled ? 1 : 0);
  m_program->setUniformValue("textureRevealIntensity", textureRevealIntensity);
  m_program->setUniformValue("textureRevealPressureInfluence",
                             textureRevealPressureInfluence);

  // === OIL PAINT UNIFORMS ===
  m_program->setUniformValue("mixing", mixing);
  m_program->setUniformValue("loading", loading);
  m_program->setUniformValue("depletionRate", depletionRate);
  m_program->setUniformValue("dirtyMixing", dirtyMixing ? 1 : 0);
  m_program->setUniformValue("colorPickup", colorPickup);
  m_program->setUniformValue("blendOnly", blendOnly ? 1 : 0);
  m_program->setUniformValue("scrapeThrough", scrapeThrough ? 1 : 0);

  // Impasto
  m_program->setUniformValue("impastoEnabled", impastoEnabled ? 1 : 0);
  m_program->setUniformValue("impastoDepth", impastoDepth);
  m_program->setUniformValue("impastoShine", impastoShine);
  m_program->setUniformValue("impastoTextureStrength", impastoTextureStrength);
  m_program->setUniformValue("impastoEdgeBuildup", impastoEdgeBuildup);
  m_program->setUniformValue("impastoDirectionalRidges",
                             impastoDirectionalRidges ? 1 : 0);
  m_program->setUniformValue("impastoSmoothing", impastoSmoothing);
  m_program->setUniformValue("impastoPreserveExisting",
                             impastoPreserveExisting ? 1 : 0);

  // Bristles
  m_program->setUniformValue("bristlesEnabled", bristlesEnabled ? 1 : 0);
  m_program->setUniformValue("bristleCount", bristleCount);
  m_program->setUniformValue("bristleStiffness", bristleStiffness);
  m_program->setUniformValue("bristleClumping", bristleClumping);
  m_program->setUniformValue("bristleFanSpread", bristleFanSpread);
  m_program->setUniformValue("bristleIndividualVariation",
                             bristleIndividualVariation);
  m_program->setUniformValue("bristleDryBrushEffect",
                             bristleDryBrushEffect ? 1 : 0);
  m_program->setUniformValue("bristleSoftness", bristleSoftness);
  m_program->setUniformValue("bristlePointTaper", bristlePointTaper);

  // Smudge
  m_program->setUniformValue("smudgeStrength", smudgeStrength);
  m_program->setUniformValue("smudgePressureInfluence",
                             smudgePressureInfluence);
  m_program->setUniformValue("smudgeLength", smudgeLength);
  m_program->setUniformValue("smudgeGaussianBlur", smudgeGaussianBlur);
  m_program->setUniformValue("smudgeSmear", smudgeSmear ? 1 : 0);

  // Canvas Interaction
  m_program->setUniformValue("canvasAbsorption", canvasAbsorption);
  m_program->setUniformValue("canvasSkipValleys", canvasSkipValleys ? 1 : 0);
  m_program->setUniformValue("canvasCatchPeaks", canvasCatchPeaks);

  // Color Dynamics Oil
  m_program->setUniformValue("temperatureShift", temperatureShift);
  m_program->setUniformValue("brokenColor", brokenColor);

  if ((wetness > 0.01f || smudge > 0.01f || bloomEnabled || mixing > 0.01f ||
       impastoEnabled || type == 5) &&
      canvasTexId != 0) {
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, canvasTexId);
    m_program->setUniformValue("canvasTexture", 2);
  }

  m_program->setUniformValue("uColorMixing", colorMixing ? 1 : 0);
  m_program->setUniformValue("uPaintAmount", paintAmount);
  m_program->setUniformValue("uColorStretch", colorStretch);
  m_program->setUniformValue("uBrushBlendMode", blendMode);

  // --- BLEND MODE ---
  glEnable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glBlendEquation(GL_FUNC_ADD);

  if (isEraser) {
    // Eraser mode
    m_program->setUniformValue("brushType", 7);
    m_program->setUniformValue("impastoEnabled", 0);
    glBlendFuncSeparate(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA, GL_ZERO,
                        GL_ONE_MINUS_SRC_ALPHA);
  } else {
    // PINTURA NORMAL
    if (blendMode == 1) { // Multiply
      glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    } else if (blendMode == 2) { // Screen
      glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);
    } else if (impastoEnabled && type == 5) {
      // IMPASTO: RGB composición estándar, ALPHA acumulación aditiva
      glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA,
                          GL_ONE, GL_ONE);
    } else { // Normal (alpha-lock se aplica en el shader multiplicando alpha por Dst_A)
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
  }

  m_program->setUniformValue("instanced", 1);

  // Draw instanced
  m_vao.bind();
  glDrawArraysInstanced(GL_TRIANGLES, 0, 6, dabs.size());
  m_vao.release();

  m_program->setUniformValue("instanced", 0);
  m_program->release();
}

} // namespace artflow
