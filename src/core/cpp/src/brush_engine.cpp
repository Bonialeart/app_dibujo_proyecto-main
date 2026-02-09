#include "../include/brush_engine.h"
#include "stroke_renderer.h"
#include <QCoreApplication> // For applicationDirPath
#include <QDebug>
#include <QFile>
#include <QImage>
#include <QMap>
#include <QOpenGLTexture>
#include <QPaintEngine> // Added for type check
#include <algorithm>    // For std::clamp
#include <cmath>        // For sin
#include <cstdlib>      // For rand
#include <vector>       // For std::vector

namespace artflow {

// Global texture cache (Simple implementation)
static QMap<QString, uint32_t> g_textureCache;
static std::vector<QOpenGLTexture *> g_textures; // To manage lifetime

static uint32_t loadTexture(const QString &name) {
  if (g_textureCache.contains(name))
    return g_textureCache[name];

  // Try to load
  // Check local path first (dev mode)
  QString path = "src/assets/textures/" + name;
  if (!QFile::exists(path)) {
    // Check relative to executable
    path = QCoreApplication::applicationDirPath() + "/assets/textures/" + name;
    if (!QFile::exists(path)) {
      // Check QRC
      path = ":/textures/" + name;
    }
  }

  QImage img(path);
  if (img.isNull()) {
    qDebug() << "Texture not found, generating procedural:" << name;
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

  QOpenGLTexture *tex = new QOpenGLTexture(img.mirrored(false, true));
  tex->setMinificationFilter(QOpenGLTexture::LinearMipMapLinear);
  tex->setMagnificationFilter(QOpenGLTexture::Linear);
  tex->setWrapMode(QOpenGLTexture::Repeat);

  uint32_t id = tex->textureId();
  g_textureCache[name] = id;
  g_textures.push_back(tex); // Keep alive
  // ... existing loadTexture ...
  return id;
}

// Helper to get/load texture image for Raster mode
static QImage getTextureImage(const QString &name) {
  static QMap<QString, QImage> s_imageTextureCache;
  if (s_imageTextureCache.contains(name))
    return s_imageTextureCache[name];

  QString path = "src/assets/textures/" + name;
  if (!QFile::exists(path)) {
    path = QCoreApplication::applicationDirPath() + "/assets/textures/" + name;
    if (!QFile::exists(path)) {
      path = ":/textures/" + name;
    }
  }

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

static void paintTexturedRaster(QPainter *painter, const QPointF &point,
                                float size, float opacity, const QColor &color,
                                const QString &texName) {
  QImage tex = getTextureImage(texName);

  painter->setOpacity(opacity);
  painter->setPen(Qt::NoPen);

  QBrush brush(tex);
  QTransform matrix;
  matrix.translate(point.x(), point.y());
  // Fixed scale pattern
  float scale = 0.5f;
  matrix.scale(scale, scale);
  brush.setTransform(matrix);

  painter->setBrush(brush);
  painter->drawEllipse(point, size / 2.0f, size / 2.0f);

  // Color tint
  painter->setBrush(color);
  painter->setCompositionMode(QPainter::CompositionMode_Overlay);
  painter->drawEllipse(point, size / 2.0f, size / 2.0f);
  painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
}

BrushEngine::BrushEngine() {}
BrushEngine::~BrushEngine() {
  if (m_renderer)
    delete m_renderer;
  // Note: textures in g_textures leak until app exit, which is acceptable for
  // this singleton-like usage
}

void BrushEngine::paintStroke(QPainter *painter, const QPointF &lastPoint,
                              const QPointF &currentPoint, float pressure,
                              const BrushSettings &settings, float tilt,
                              float velocity, uint32_t canvasTexId,
                              float wetness, float dilution, float smudge) {
  if (!painter)
    return;

  // 1. Calcular Dinámicas
  float effectivePressure = (pressure > 0.0f) ? pressure : 0.5f;
  if (!settings.dynamicsEnabled) {
    effectivePressure = 1.0f;
  }

  // Resolver Textura si es necesario (Lazy loading)
  // Casting away constness localmente es feo, mejor lo resolvemos antes o
  // usamos el ID local
  uint32_t currentTextureID = settings.grainTextureID;
  bool isOpenGL = (painter->paintEngine()->type() != QPaintEngine::Raster);

  if (isOpenGL && settings.useTexture && currentTextureID == 0 &&
      !settings.textureName.isEmpty()) {
    // Necesitamos cargarla. Pero settings es const.
    // Usamos variable local.
    currentTextureID = loadTexture(settings.textureName);
  }

  // Si usamos texturas (Modo Premium OpenGL) - SOLO si el pintor soporta OpenGL
  // directamente Si estamos pintando en QImage (Raster), usar fallback para
  // evitar crash.
  if (settings.useTexture && isOpenGL) {
    painter->save();
    painter->beginNativePainting();

    if (!m_renderer) {
      m_renderer = new StrokeRenderer();
      m_renderer->initialize();
    }

    int w = painter->device()->width();
    int h = painter->device()->height();

    // Cálculo de tamaño base
    float currentSize =
        settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
    if (currentSize < 1.0f)
      currentSize = 1.0f;

    // Interpolación (Loop)
    float dist = std::hypot(currentPoint.x() - lastPoint.x(),
                            currentPoint.y() - lastPoint.y());
    float stepSize = std::max(1.0f, currentSize * settings.spacing);
    int steps = static_cast<int>(dist / stepSize);

    // Color base con opacidad global (la presión se maneja en el shader)
    QColor c = settings.color;
    c.setAlphaF(c.alphaF() * settings.opacity);

    // Obtener transformación actual (Zoom/Pan) para mapear a píxeles físicos
    QTransform xform = painter->transform();
    float scaleFactor =
        std::sqrt(xform.m11() * xform.m11() + xform.m12() * xform.m12());

    for (int i = 0; i <= steps; ++i) {
      float t = (steps > 0) ? (float)i / steps : 0.0f;
      QPointF pt = lastPoint + (currentPoint - lastPoint) * t;

      // Mapear al espacio del dispositivo (OpenGL usa coords físicas del FBO)
      QPointF devPt = xform.map(pt);
      float devSize = currentSize * scaleFactor;

      m_renderer->renderStroke(
          devPt.x(), devPt.y(), devSize, effectivePressure, settings.hardness,
          c, (int)settings.type, w, h, currentTextureID, true,
          settings.textureScale * scaleFactor, settings.textureIntensity, tilt,
          velocity, canvasTexId, wetness, dilution, smudge);
      // Nota: textureScale también debería considerar el zoom?
      // Si queremos que el grano sea "estático al lienzo" (papel real), el
      // grano debe escalar consigo mismo. texture(tex, vWorldPos /
      // textureScale). vWorldPos viene de brush.vert -> model * aPos. model usa
      // x,y (devPt). Si hacemos zoom, x,y cambian. Pero textureScale es
      // constante en world space? Si el papel es físico, al hacer zoom, el
      // grano se ve más grande. textureScale ajusta la frecuencia. Si pasamos
      // devPt (píxeles pantalla), la textura se desliza si no ajustamos. Pero
      // vWorldPos (en vert shader) se calcula en coords pantalla. Para que la
      // textura esté pegada al CANVAS (y no a la pantalla), necesitamos pasar
      // el offset del canvas al shader? O usar coordenadas lógicas.

      // Por ahora, dejemos el scale simple. Si hacemos zoom, el grano cambia de
      // tamaño visualmente (se pixela) si usamos FBO, pero aquí estamos
      // dibujando trazos. Si usamos SCREEN coords para textura, el grano es
      // "screen space" (como ruido TV). Para "paper space", lo ideal es fixed
      // screen space o fixed canvas space. Si scaleFactor aumenta (zoom in),
      // textureScale debería... Dejémoslo así, el usuario pidió "textura", el
      // refinamiento de "world space texture" es extra.
    }

    painter->endNativePainting();
    painter->restore();
    return; // Salimos, ya dibujamos
  }

  // --- LÓGICA LEGACY (QPAINTER) ---

  if (settings.type == BrushSettings::Type::Eraser) {
    painter->setCompositionMode(QPainter::CompositionMode_Clear);
  } else {
    painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
  }

  // Adaptación: La presión afecta el tamaño (logarítmico o lineal)
  float currentSize =
      settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
  // Evitar tamaños invisibles
  if (currentSize < 1.0f)
    currentSize = 1.0f;

  // Adaptación: La presión afecta la opacidad
  float currentOpacity =
      settings.opacity *
      (settings.opacityByPressure ? effectivePressure : 1.0f);
  // Limitar opacidad máxima
  if (currentOpacity > 1.0f)
    currentOpacity = 1.0f;

  // 2. Renderizado (Rendering)
  // CASO C: Pincel Texturizado en Raster (OIL fallback)
  if (settings.useTexture &&
      painter->paintEngine()->type() == QPaintEngine::Raster) {
    float dist = std::hypot(currentPoint.x() - lastPoint.x(),
                            currentPoint.y() - lastPoint.y());
    // Spacing más denso para textura (evitar huecos)
    float stepSize = std::max(1.0f, currentSize * settings.spacing * 0.25f);
    int steps = static_cast<int>(dist / stepSize);

    for (int i = 0; i <= steps; ++i) {
      float t = (steps > 0) ? (float)i / steps : 0.0f;
      QPointF pt = lastPoint + (currentPoint - lastPoint) * t;
      paintTexturedRaster(painter, pt, currentSize, currentOpacity,
                          settings.color, settings.textureName);
    }
    return;
  }

  // Caso A: Pincel Duro (Hard Brush) CONSTANTE - Usamos QPen para rendimiento.
  // SOLO si el tamaño NO varía por presión. Si varía, usamos interpolación
  // (abajo).
  if (settings.hardness > 0.9f && !settings.sizeByPressure) {
    QPen pen;
    pen.setColor(settings.color);
    pen.setWidthF(currentSize);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);

    painter->setOpacity(currentOpacity);
    painter->setPen(pen);
    painter->drawLine(lastPoint, currentPoint);
  }
  // Caso B: Pincel Suave/Aerógrafo (Soft Brush) - Usamos QRadialGradient
  // interpolado
  else {
    // Necesitamos interpolar pasos entre los dos puntos para que no se vean
    // "bolas" separadas
    float distance = std::hypot(currentPoint.x() - lastPoint.x(),
                                currentPoint.y() - lastPoint.y());
    // El paso (step) debe ser una fracción del tamaño del pincel (ej. 10% del
    // tamaño)
    float stepSize = std::max(1.0f, currentSize * settings.spacing);

    int steps = static_cast<int>(distance / stepSize);

    for (int i = 0; i <= steps; ++i) {
      float t = (steps > 0) ? (float)i / steps : 0.0f;
      QPointF interpolatedPoint = lastPoint + (currentPoint - lastPoint) * t;

      // Renderizamos un "sello" suave en cada paso
      paintSoftStamp(painter, interpolatedPoint, currentSize, currentOpacity,
                     settings.color, settings.hardness);
    }
  }
}

void BrushEngine::paintSoftStamp(QPainter *painter, const QPointF &point,
                                 float size, float opacity, const QColor &color,
                                 float hardness) {
  painter->setPen(Qt::NoPen);
  painter->setOpacity(opacity);

  QRadialGradient gradient(point, size / 2.0);

  // Color central (sólido)
  QColor centerColor = color;
  gradient.setColorAt(0.0, centerColor);

  // Inicio del desvanecimiento (basado en dureza)
  gradient.setColorAt(hardness, centerColor);

  // Borde exterior (transparente)
  QColor outerColor = color;
  outerColor.setAlpha(0);
  gradient.setColorAt(1.0, outerColor);

  QBrush brush(gradient);
  painter->setBrush(brush);

  // Dibujar el círculo del gradiente
  painter->drawEllipse(point, size / 2.0, size / 2.0);
}

} // namespace artflow
