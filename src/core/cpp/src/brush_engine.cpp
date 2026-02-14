#include "../include/brush_engine.h"
#include "stroke_renderer.h"
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QImage>
#include <QMap>
#include <QOpenGLTexture>
#include <QPaintEngine>
#include <QPainter>
#include <QPointF>
#include <QString>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <vector>

namespace artflow {

// Global texture cache (Simple implementation)
static QMap<QString, uint32_t> g_textureCache;
static std::vector<QOpenGLTexture *> g_textures; // To manage lifetime

static uint32_t loadTexture(const QString &name) {
  if (g_textureCache.contains(name))
    return g_textureCache[name];

  // Try to load
  // Check local path first (dev mode)
  // Check local path first (dev mode)
  QString path = "src/assets/textures/" + name;
  if (!QFile::exists(path)) {
    path = "../../src/assets/textures/" + name;
    if (!QFile::exists(path)) {
      path = "src/assets/brushes/tips/" + name;
      if (!QFile::exists(path)) {
        path = "../../src/assets/brushes/tips/" + name;
        if (!QFile::exists(path)) {
          // Check relative to executable
          path = QCoreApplication::applicationDirPath() + "/assets/textures/" +
                 name;
          if (!QFile::exists(path)) {
            // Check QRC
            path = ":/textures/" + name;
          }
        }
      }
    }
  }

  qDebug() << "BrushEngine: Loading texture:" << name << "from" << path;

  QImage img(path);
  if (img.isNull()) {
    qDebug() << "Texture not found or failed to load:" << name << "at" << path;
    qDebug() << "Generating procedural fallback for:" << name;
    img = QImage(512, 512, QImage::Format_RGBA8888);
    img.fill(Qt::white);

    // Simple noise gen
    for (int y = 0; y < 512; ++y) {
      for (int x = 0; x < 512; ++x) {
        int v = rand() % 255;
        if (name.contains("canvas")) {
          v = (std::sin(x * 0.1) + std::sin(y * 0.1)) * 50 + 128 +
              (rand() % 40 - 20);
        }
        v = std::max(0, std::min(255, v));
        img.setPixel(x, y, qRgb(v, v, v));
      }
    }
  }

  // CRUCIAL: Convert to format OpenGL understands well (RGBA 8888)
  QImage glImg =
      img.convertToFormat(QImage::Format_RGBA8888).flipped(Qt::Vertical);

  QOpenGLTexture *tex = new QOpenGLTexture(glImg);
  tex->setMinificationFilter(QOpenGLTexture::LinearMipMapLinear);
  tex->setMagnificationFilter(QOpenGLTexture::Linear);
  tex->setWrapMode(QOpenGLTexture::Repeat); // Allow texture tiling
  tex->generateMipMaps(); // CRITICAL: Avoid black/low-res dots

  uint32_t id = tex->textureId();
  g_textureCache[name] = id;
  g_textures.push_back(tex); // Keep alive
  return id;
}

// Helper to get/load texture image for Raster mode
static QImage getTextureImage(const QString &name) {
  static QMap<QString, QImage> s_imageTextureCache;
  if (s_imageTextureCache.contains(name))
    return s_imageTextureCache[name];

  // Try multiple paths (same as loadTexture)
  QString path = "src/assets/textures/" + name;
  if (!QFile::exists(path)) {
    path = "../../src/assets/textures/" + name;
    if (!QFile::exists(path)) {
      path = "src/assets/brushes/tips/" + name;
      if (!QFile::exists(path)) {
        path = "../../src/assets/brushes/tips/" + name;
        if (!QFile::exists(path)) {
          path = QCoreApplication::applicationDirPath() + "/assets/textures/" +
                 name;
          if (!QFile::exists(path)) {
            path = ":/textures/" + name;
          }
        }
      }
    }
  }

  qDebug() << "BrushEngine: getTextureImage Loading:" << name << "from" << path;

  QImage img(path);
  if (img.isNull()) {
    img = QImage(256, 256, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    QPainter p(&img);
    for (int i = 0; i < 1000; i++) {
      p.setPen(QColor(0, 0, 0, rand() % 50 + 20));
      p.drawPoint(rand() % 256, rand() % 256);
    }
  } else {
    img = img.convertToFormat(QImage::Format_ARGB32_Premultiplied);
  }

  s_imageTextureCache[name] = img;
  return img;
}

// Helper to draw a tinted tip in Raster mode
static void paintTipRaster(QPainter *painter, const QPointF &point, float size,
                           float opacity, const QColor &color, float rotation,
                           const QString &texName) {
  QImage tipImg = getTextureImage(texName);
  if (tipImg.isNull())
    return;

  painter->save();
  painter->setOpacity(opacity);
  painter->translate(point);
  painter->rotate(rotation * 180.0f / 3.14159f); // rad to deg

  QRectF rect(-size / 2.0, -size / 2.0, size, size);

  // Tinting: Create a temporary image for the dab
  // This is expensive in Raster but necessary for correct visual
  QImage dab =
      tipImg.scaled(size, size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
  QPainter p(&dab);
  p.setCompositionMode(QPainter::CompositionMode_SourceIn);
  p.fillRect(dab.rect(), color);
  p.end();

  painter->drawImage(rect, dab);
  painter->restore();
}

static void paintTexturedRaster(QPainter *painter, const QPointF &point,
                                float size, float opacity, const QColor &color,
                                const QString &texName) {
  QImage tex = getTextureImage(texName);
  if (tex.isNull())
    return;

  painter->save();
  painter->setOpacity(opacity);
  painter->setPen(Qt::NoPen);

  QBrush brush(tex);
  QTransform matrix;
  matrix.translate(point.x(), point.y());
  float scale = 0.5f;
  matrix.scale(scale, scale);
  brush.setTransform(matrix);

  painter->setBrush(brush);
  painter->drawEllipse(point, size / 2.0f, size / 2.0f);

  // Color tint
  painter->setBrush(color);
  painter->setCompositionMode(QPainter::CompositionMode_Overlay);
  painter->drawEllipse(point, size / 2.0f, size / 2.0f);
  painter->restore();
}

BrushEngine::BrushEngine() {}
BrushEngine::~BrushEngine() {
  if (m_renderer)
    delete m_renderer;
}

void BrushEngine::paintStroke(QPainter *painter, const QPointF &lastPoint,
                              const QPointF &currentPoint, float pressure,
                              const BrushSettings &settings, float tilt,
                              float velocity, uint32_t canvasTexId,
                              float wetness, float dilution, float smudge) {
  if (!painter)
    return;

  m_lastPos = currentPoint;

  // 1. Calculate Dynamics
  float effectivePressure = (pressure > 0.0f) ? pressure : 0.5f;

  // Velocity Influence (Mouse pressure fallback)
  if (settings.velocityDynamics > 0.01f && velocity > 0.1f) {
    // High velocity = lower pressure (thinner stroke)
    // Reference: 1.0 - (velocity / 2000.0)
    float vPressure =
        std::max(0.1f, std::min(1.0f, 1.0f - (velocity / 2000.0f)));
    effectivePressure = effectivePressure + (vPressure - effectivePressure) *
                                                settings.velocityDynamics;
  }

  if (!settings.dynamicsEnabled) {
    effectivePressure = 1.0f;
  }

  bool isOpenGL = (painter->paintEngine()->type() != QPaintEngine::Raster);

  static bool hasLoggedMode = false;
  if (!hasLoggedMode) {
    qDebug() << "BrushEngine: paintStroke mode:"
             << (isOpenGL ? "OpenGL" : "Raster");
    hasLoggedMode = true;
  }

  if (isOpenGL) {
    // === LOAD TEXTURES (lazy, cached) ===
    uint32_t grainTexID = settings.grainTextureID;
    uint32_t tipTexID = settings.tipTextureID;

    // Load grain texture if needed
    if (settings.useTexture && grainTexID == 0 &&
        !settings.textureName.isEmpty()) {
      grainTexID = loadTexture(settings.textureName);
    }

    // Load tip texture if needed
    if (tipTexID == 0 && !settings.tipTextureName.isEmpty()) {
      tipTexID = loadTexture(settings.tipTextureName);
    }

    bool hasGrain = (grainTexID != 0 && settings.useTexture);
    bool hasTip = (tipTexID != 0);

    painter->save();
    painter->beginNativePainting();

    if (!m_renderer) {
      m_renderer = new StrokeRenderer();
      m_renderer->initialize();
    }

    int w = painter->device()->width();
    int h = painter->device()->height();

    float currentSize =
        settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
    if (currentSize < 1.0f)
      currentSize = 1.0f;

    // Robust Interpolation (Cumulative Distance Algorithm)
    float dx = currentPoint.x() - lastPoint.x();
    float dy = currentPoint.y() - lastPoint.y();
    float dist = std::hypot(dx, dy);
    float stepSize = std::max(0.5f, currentSize * settings.spacing);

    if (m_remainder < 0.0f) {
      m_remainder = stepSize; // Force dab at t=0
    }

    float distanceToDab = stepSize - m_remainder;

    QColor c = settings.color;
    c.setAlphaF(c.alphaF() * settings.opacity);

    // Calligraphy effect (Angle-based thickness)
    float calligraphyWidth = 1.0f;
    float strokeAngle = std::atan2(dy, dx);
    if (settings.type == BrushSettings::Type::Ink ||
        settings.type == BrushSettings::Type::Custom) {
      // Horizontal = thicker, Vertical = thinner
      calligraphyWidth = 0.5f + std::abs(std::sin(strokeAngle)) * 0.5f;
    }

    QTransform xform = painter->transform();
    float scaleFactor =
        std::sqrt(xform.m11() * xform.m11() + xform.m12() * xform.m12());

    while (distanceToDab <= dist) {
      float t = (dist > 0.0001f) ? (distanceToDab / dist) : 0.0f;
      QPointF pt = lastPoint + (currentPoint - lastPoint) * t;

      // Progress within stroke
      float totalDist = m_accumulatedDistance + distanceToDab;

      // Taper and Falloff
      float sizeMultiplier = 1.0f;
      float opacityMultiplier = 1.0f;

      if (settings.taperStart > 0.0f && totalDist < settings.taperStart) {
        // Parabolic Taper (smoother)
        // Reference: 1 - x²
        float x = 1.0f - (totalDist / settings.taperStart); // 1.0 to 0.0
        float parabola = 1.0f - (x * x);
        sizeMultiplier = 0.2f + 0.8f * parabola;
      }
      if (settings.fallOff > 0.0f) {
        opacityMultiplier =
            std::max(0.0f, 1.0f - (totalDist / settings.fallOff));
      }

      QPointF devPt = xform.map(pt);
      float devSizeBase =
          currentSize * scaleFactor * sizeMultiplier * calligraphyWidth;
      float opacityBase = c.alphaF() * opacityMultiplier;

      // Loop for Count (Stamp stacking)
      int count = std::max(1, settings.count);
      for (int k = 0; k < count; ++k) {
        // Jitters
        float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
        if (settings.posJitterX > 0)
          jX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX *
               devSizeBase;
        if (settings.posJitterY > 0)
          jY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY *
               devSizeBase;
        if (settings.sizeJitter > 0)
          jSize = 1.0f +
                  ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
        if (settings.rotationJitter > 0)
          jRot = ((std::rand() % 2001 - 1000) / 1000.0f) *
                 settings.rotationJitter * 3.14159f;
        if (settings.opacityJitter > 0)
          jOpac =
              1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

        QColor finalColor = c;
        finalColor.setAlphaF(std::clamp(opacityBase * jOpac, 0.0f, 1.0f));

        // Basic Color Dynamics
        if (settings.hueJitter > 0 || settings.satJitter > 0) {
          float h, s, l, a;
          finalColor.getHslF(&h, &s, &l, &a);
          h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) *
                                settings.hueJitter,
                        1.0f);
          if (h < 0)
            h += 1.0f;
          s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) *
                                 settings.satJitter,
                         0.0f, 1.0f);
          finalColor.setHslF(h, s, l, a);
        }

        bool isEraser = (settings.type == BrushSettings::Type::Eraser);
        m_renderer->renderStroke(
            devPt.x() + jX, devPt.y() + jY, devSizeBase * jSize,
            effectivePressure, settings.hardness, finalColor,
            (int)settings.type, w, h,
            // Grain
            grainTexID, hasGrain, settings.textureScale * scaleFactor,
            settings.textureIntensity,
            // Tip
            tipTexID, hasTip, settings.tipRotation + jRot,
            // Dynamics
            tilt, velocity, settings.flow,
            // Wet Mix
            canvasTexId, wetness, dilution, smudge,
            // Mode
            isEraser);
      }

      distanceToDab += stepSize;
    }

    // Update state
    m_accumulatedDistance += dist;
    m_remainder = dist - (distanceToDab - stepSize);
    if (m_remainder < 0)
      m_remainder = 0;

    painter->endNativePainting();
    painter->restore();
    return;
  }

  // --- LEGACY PATH (QPAINTER) ---

  if (settings.type == BrushSettings::Type::Eraser) {
    painter->setCompositionMode(QPainter::CompositionMode_Source);
  } else {
    painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
  }

  float currentSize =
      settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
  if (currentSize < 1.0f)
    currentSize = 1.0f;

  float currentOpacity =
      settings.opacity *
      (settings.opacityByPressure ? effectivePressure : 1.0f);
  if (currentOpacity > 1.0f)
    currentOpacity = 1.0f;

  float dx = currentPoint.x() - lastPoint.x();
  float dy = currentPoint.y() - lastPoint.y();
  float dist = std::hypot(dx, dy);
  float stepSize = std::max(0.5f, currentSize * settings.spacing);

  if (m_remainder < 0.0f)
    m_remainder = stepSize;
  float distanceToDab = stepSize - m_remainder;

  QColor baseColor = settings.color;

  // Calligraphy effect (Angle-based thickness)
  float calligraphyWidth = 1.0f;
  if (settings.type == BrushSettings::Type::Ink ||
      settings.type == BrushSettings::Type::Custom) {
    calligraphyWidth = 0.5f + std::abs(std::sin(std::atan2(dy, dx))) * 0.5f;
  }

  while (distanceToDab <= dist) {
    float t = (dist > 0.0001f) ? (distanceToDab / dist) : 0.0f;
    QPointF pt = lastPoint + (currentPoint - lastPoint) * t;

    // Progress within stroke
    float totalDist = m_accumulatedDistance + distanceToDab;

    // Taper and Falloff
    float sizeMultiplier = 1.0f;
    float opacityMultiplier = 1.0f;

    if (settings.taperStart > 0.0f && totalDist < settings.taperStart) {
      float x = 1.0f - (totalDist / settings.taperStart);
      float parabola = 1.0f - (x * x);
      sizeMultiplier = 0.2f + 0.8f * parabola;
    }
    if (settings.fallOff > 0.0f) {
      opacityMultiplier = std::max(0.0f, 1.0f - (totalDist / settings.fallOff));
    }

    float dabSize = currentSize * sizeMultiplier * calligraphyWidth;
    float dabOpacity = currentOpacity * opacityMultiplier;

    // Loop for Count (Stamp stacking)
    int count = std::max(1, settings.count);
    for (int k = 0; k < count; ++k) {
      // Jitters
      float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
      if (settings.posJitterX > 0)
        jX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX *
             dabSize;
      if (settings.posJitterY > 0)
        jY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY *
             dabSize;
      if (settings.sizeJitter > 0)
        jSize = 1.0f +
                ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
      if (settings.opacityJitter > 0)
        jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

      QPointF finalPt = pt + QPointF(jX, jY);
      float finalSize = std::max(0.1f, dabSize * jSize);
      float finalOpacity = std::clamp(dabOpacity * jOpac, 0.0f, 1.0f);

      QColor finalColor = baseColor;

      // Basic Color Dynamics
      if (settings.hueJitter > 0 || settings.satJitter > 0) {
        float h, s, l, a;
        finalColor.getHslF(&h, &s, &l, &a);
        h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) *
                              settings.hueJitter,
                      1.0f);
        if (h < 0)
          h += 1.0f;
        s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) *
                               settings.satJitter,
                       0.0f, 1.0f);
        finalColor.setHslF(h, s, l, a);
      }

      if (!settings.tipTextureName.isEmpty()) {
        paintTipRaster(painter, finalPt, finalSize, finalOpacity, finalColor,
                       settings.tipRotation + jRot, settings.tipTextureName);
      } else if (settings.useTexture && !settings.textureName.isEmpty()) {
        paintTexturedRaster(painter, finalPt, finalSize, finalOpacity,
                            finalColor, settings.textureName);
      } else {
        paintSoftStamp(painter, finalPt, finalSize, finalOpacity, finalColor,
                       settings.hardness);
      }
    }

    distanceToDab += stepSize;
  }

  // Update state
  m_accumulatedDistance += dist;
  m_remainder = dist - (distanceToDab - stepSize);
  if (m_remainder < 0)
    m_remainder = 0;
}

// --- Python Bindings Support ---

void BrushEngine::setBrush(const BrushSettings &settings) {
  m_currentSettings = settings;
  // Sync cached color
  m_cachedColor = Color(settings.color.red(), settings.color.green(),
                        settings.color.blue(), settings.color.alpha());
}

void BrushEngine::setColor(const Color &color) {
  m_cachedColor = color;
  m_currentSettings.color = QColor(color.r, color.g, color.b, color.a);
}

const Color &BrushEngine::getColor() const { return m_cachedColor; }

void BrushEngine::beginStroke(const StrokePoint &point) {
  m_lastPos = QPointF(point.x, point.y);
  m_remainder = -1.0f;
  m_accumulatedDistance = 0.0f;
  if (!m_renderer) {
    m_renderer = new StrokeRenderer();
    m_renderer->initialize();
  }
}

void BrushEngine::continueStroke(const StrokePoint &point) {
  if (!m_renderer)
    return;

  QPointF currentPos(point.x, point.y);

  float dx = currentPos.x() - m_lastPos.x();
  float dy = currentPos.y() - m_lastPos.y();
  float dist = std::hypot(dx, dy);

  float size = m_currentSettings.size;
  if (m_currentSettings.sizeByPressure) {
    size *= point.pressure;
  }

  float spacing = std::max(1.0f, size * m_currentSettings.spacing);

  if (m_remainder < 0.0f) {
    m_remainder = spacing;
  }

  float coveredDist = spacing - m_remainder;

  float opacity = m_currentSettings.opacity;
  if (m_currentSettings.opacityByPressure) {
    opacity *= point.pressure;
  }

  // Load textures
  uint32_t grainTexId = m_currentSettings.grainTextureID;
  if (m_currentSettings.useTexture && grainTexId == 0 &&
      !m_currentSettings.textureName.isEmpty()) {
    grainTexId = loadTexture(m_currentSettings.textureName);
  }

  uint32_t tipTexId = m_currentSettings.tipTextureID;
  if (tipTexId == 0 && !m_currentSettings.tipTextureName.isEmpty()) {
    tipTexId = loadTexture(m_currentSettings.tipTextureName);
  }

  bool hasGrain = (grainTexId != 0 && m_currentSettings.useTexture);
  bool hasTip = (tipTexId != 0);

  int w = m_renderer ? m_renderer->viewportWidth() : 2000;
  int h = m_renderer ? m_renderer->viewportHeight() : 2000;

  if (w <= 0)
    w = 2000;
  if (h <= 0)
    h = 2000;

  // Render Loop
  while (coveredDist <= dist) {
    float t = (dist > 0.0001f) ? (coveredDist / dist) : 0.0f;
    QPointF pt = m_lastPos + (currentPos - m_lastPos) * t;

    float totalDist = m_accumulatedDistance + coveredDist;

    // Taper and Falloff
    float sizeMultiplier = 1.0f;
    float opacityMultiplier = 1.0f;

    if (m_currentSettings.taperStart > 0.0f &&
        totalDist < m_currentSettings.taperStart) {
      sizeMultiplier = totalDist / m_currentSettings.taperStart;
    }
    if (m_currentSettings.fallOff > 0.0f) {
      opacityMultiplier =
          std::max(0.0f, 1.0f - (totalDist / m_currentSettings.fallOff));
    }

    float devSizeBase = size * sizeMultiplier;
    float opacityBase = opacity * opacityMultiplier;

    // Loop for Count (Stamp stacking)
    int count = std::max(1, m_currentSettings.count);
    for (int k = 0; k < count; ++k) {
      // Jitters
      float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
      if (m_currentSettings.posJitterX > 0)
        jX = ((std::rand() % 2001 - 1000) / 1000.0f) *
             m_currentSettings.posJitterX * devSizeBase;
      if (m_currentSettings.posJitterY > 0)
        jY = ((std::rand() % 2001 - 1000) / 1000.0f) *
             m_currentSettings.posJitterY * devSizeBase;
      if (m_currentSettings.sizeJitter > 0)
        jSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) *
                           m_currentSettings.sizeJitter;
      if (m_currentSettings.rotationJitter > 0)
        jRot = ((std::rand() % 2001 - 1000) / 1000.0f) *
               m_currentSettings.rotationJitter * 3.14159f;
      if (m_currentSettings.opacityJitter > 0)
        jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) *
                           m_currentSettings.opacityJitter;

      QColor finalColor = m_currentSettings.color;
      finalColor.setAlphaF(std::clamp(opacityBase * jOpac, 0.0f, 1.0f));

      // Basic Color Dynamics
      if (m_currentSettings.hueJitter > 0 || m_currentSettings.satJitter > 0) {
        float h, s, l, a;
        finalColor.getHslF(&h, &s, &l, &a);
        h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) *
                              m_currentSettings.hueJitter,
                      1.0f);
        if (h < 0)
          h += 1.0f;
        s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) *
                               m_currentSettings.satJitter,
                       0.0f, 1.0f);
        finalColor.setHslF(h, s, l, a);
      }

      bool isEraser = (m_currentSettings.type == BrushSettings::Type::Eraser);
      m_renderer->renderStroke(
          pt.x() + jX, pt.y() + jY, devSizeBase * jSize, point.pressure,
          m_currentSettings.hardness, finalColor, (int)m_currentSettings.type,
          w, h,
          // Grain
          grainTexId, hasGrain, m_currentSettings.textureScale,
          m_currentSettings.textureIntensity,
          // Tip
          tipTexId, hasTip, m_currentSettings.tipRotation + jRot,
          // Dynamics
          0.0f, 0.0f, m_currentSettings.flow,
          // Wet Mix
          0, m_currentSettings.wetness, m_currentSettings.dilution,
          m_currentSettings.smudge,
          // Mode
          isEraser);
    }

    coveredDist += spacing;
  }

  // Update State
  m_accumulatedDistance += dist;

  // Update Remainder
  m_remainder = dist - (coveredDist - spacing);
  if (m_remainder < 0)
    m_remainder = 0;

  m_lastPos = currentPos;
}

void BrushEngine::endStroke() {
  // Cleanup or finish
}

void BrushEngine::renderDab(float x, float y, float size, float rotation,
                            const Color &color, float hardness, float pressure,
                            int brushType, float wetness) {
  if (!m_renderer) {
    m_renderer = new StrokeRenderer();
    m_renderer->initialize();
  }

  m_renderer->drawDab(x, y, size, rotation, color.r / 255.0f, color.g / 255.0f,
                      color.b / 255.0f, color.a / 255.0f, hardness, pressure, 0,
                      brushType, wetness);
}

void BrushEngine::renderStrokeSegment(float x1, float y1, float x2, float y2,
                                      float pressure, float tilt,
                                      float velocity, bool useTexture) {
  StrokePoint start(x1, y1, pressure);
  StrokePoint end(x2, y2, pressure);
  beginStroke(start);
  continueStroke(end);
}

void BrushEngine::paintSoftStamp(QPainter *painter, const QPointF &point,
                                 float size, float opacity, const QColor &color,
                                 float hardness) {
  painter->setPen(Qt::NoPen);
  painter->setOpacity(opacity);

  QRadialGradient gradient(point, size / 2.0);
  QColor centerColor = color;
  gradient.setColorAt(0.0, centerColor);
  gradient.setColorAt(hardness, centerColor);

  QColor outerColor = color;
  outerColor.setAlpha(0);
  gradient.setColorAt(1.0, outerColor);

  QBrush brush(gradient);
  painter->setBrush(brush);

  painter->drawEllipse(point, size / 2.0, size / 2.0);
}

} // namespace artflow
