// Re-verify includes
#include "CanvasItem.h"
#include "PreferencesManager.h"
#include "core/cpp/include/brush_preset_manager.h"
#include <QBuffer>
#include <QCoreApplication>
#include <QCursor>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QHoverEvent>
#include <QMouseEvent>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QOpenGLPaintDevice>
#include <QOpenGLShader>
#include <QOpenGLShaderProgram>
#include <QOpenGLTexture>
#include <QPainter>
#include <QPainterPath>
#include <QQuickItem>
#include <QQuickPaintedItem> // Ensure base class is known
#include <QQuickWindow>
#include <QStandardPaths>
#include <QStringList>
#include <QTabletEvent>
#include <QTimer>
#include <QUrl>
#include <QtConcurrent/QtConcurrentRun>
#include <QtMath>
#include <algorithm>

using namespace artflow;

CanvasItem::CanvasItem(QQuickItem *parent)
    : QQuickPaintedItem(parent), m_brushSize(20), m_brushColor(Qt::black),
      m_brushOpacity(1.0f), m_brushFlow(1.0f), m_brushHardness(0.8f),
      m_brushSpacing(0.1f), m_brushStabilization(0.2f), m_brushStreamline(0.0f),

      m_brushGrain(0.0f), m_brushWetness(0.0f), m_brushSmudge(0.0f),
      m_zoomLevel(1.0f), m_currentToolStr("brush"), m_tool(ToolType::Pen),
      m_canvasWidth(1920), m_canvasHeight(1080), m_viewOffset(50, 50),
      m_activeLayerIndex(0), m_isTransforming(false), m_brushAngle(0.0f),
      m_cursorRotation(0.0f), m_backgroundColor(Qt::transparent),
      m_currentProjectPath(""), m_currentProjectName("Untitled"),
      m_brushTip("round"), m_lastPressure(1.0f), m_isDrawing(false),
      m_brushEngine(new BrushEngine()), m_undoManager(new UndoManager()) {
  setAcceptHoverEvents(true);
  setAcceptedMouseButtons(Qt::AllButtons);
  setAcceptTouchEvents(true);
  setRenderTarget(QQuickPaintedItem::FramebufferObject);

  // Enable tablet tracking for high-frequency events
  // Note: QQuickItem doesn't have setAttribute(Qt::WA_TabletTracking) directly
  // but acts as if it's on.

  m_layerManager = new LayerManager(m_canvasWidth, m_canvasHeight);

  m_quickShapeTimer = new QTimer(this);
  m_quickShapeTimer->setSingleShot(true);
  connect(m_quickShapeTimer, &QTimer::timeout, this,
          &CanvasItem::detectAndDrawQuickShape);

  // Brush engine initialized in initializer list

  m_layerManager->addLayer("Layer 1");

  // Cargar curva de presión guardada (Persistencia)
  setCurvePoints(PreferencesManager::instance()->pressureCurve());

  // Sincronizar niveles de deshacer (Undo Levels)
  m_undoManager->setMaxLevels(PreferencesManager::instance()->undoLevels());

  // Escuchar cambios en preferencias para actualizar el sistema en tiempo real
  connect(PreferencesManager::instance(), &PreferencesManager::settingsChanged,
          this, [this]() {
            m_undoManager->setMaxLevels(
                PreferencesManager::instance()->undoLevels());
            // Aquí podrías añadir otros updates (ej: gpuAcceleration si fuera
            // dinámico)
          });

  m_activeLayerIndex = 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  // === Data-Driven Brush Loading ===
  auto *bpm = artflow::BrushPresetManager::instance();

  // Try loading JSON presets from disk
  QStringList searchPaths;
  searchPaths << "assets/brushes"
              << "src/assets/brushes" // Keep for compatibility if needed,
                                      // though folder is gone
              << QCoreApplication::applicationDirPath() + "/assets/brushes"
              << QCoreApplication::applicationDirPath() + "/../assets/brushes";
  for (const QString &p : searchPaths) {
    if (QDir(p).exists()) {
      bpm->loadFromDirectory(p);
      break;
    }
  }

  // Fallback to built-in defaults if no JSON loaded
  if (bpm->allPresets().empty()) {
    bpm->loadDefaults();
  }

  // Populate available brushes list from manager
  QStringList names = bpm->brushNames();
  for (const QString &n : names) {
    m_availableBrushes << n;
  }

  m_activeBrushName = names.isEmpty() ? "Pencil HB" : names.first();
  usePreset(m_activeBrushName);

  updateLayersList();
}

CanvasItem::~CanvasItem() {
  if (m_brushEngine)
    delete m_brushEngine;
  if (m_layerManager)
    delete m_layerManager;
  if (m_undoManager)
    delete m_undoManager;
  if (m_impastoShader)
    delete m_impastoShader;
  qDeleteAll(m_layerTextures);
  m_layerTextures.clear();
}

void CanvasItem::paint(QPainter *painter) {
  if (!m_layerManager)
    return;

  // 1. Inicializar Shaders Premium si es necesario
  if (!m_impastoShader) {
    m_impastoShader = new QOpenGLShaderProgram();

    // Buscar shaders en rutas relativas y absolutas
    QStringList paths;
    paths << QCoreApplication::applicationDirPath() + "/shaders/";
    paths << QCoreApplication::applicationDirPath() + "/../src/core/shaders/";
    paths << "src/core/shaders/"; // Relative to project root
    paths << "assets/shaders/";   // If we move shaders later

    QString vertPath, fragPath;
    for (const QString &path : paths) {
      if (QFile::exists(path + "brush.vert") &&
          QFile::exists(path + "impasto.frag")) {
        vertPath = path + "brush.vert";
        fragPath = path + "impasto.frag";
        break;
      }
    }

    if (!vertPath.isEmpty()) {
      m_impastoShader->addShaderFromSourceFile(QOpenGLShader::Vertex, vertPath);
      m_impastoShader->addShaderFromSourceFile(QOpenGLShader::Fragment,
                                               fragPath);
      m_impastoShader->link();
    } else {
      qWarning() << "Shaders not found!";
    }
  }

  // 2. Fondo Base (Workspace - Dark Grey)
  painter->fillRect(0, 0, width(), height(), QColor("#1e1e1e"));

  // Calculate generic target rect for background
  QRectF paperRect(m_viewOffset.x() * m_zoomLevel,
                   m_viewOffset.y() * m_zoomLevel, m_canvasWidth * m_zoomLevel,
                   m_canvasHeight * m_zoomLevel);

  // DIBUJAR CHECKERBOARD (Patrón de transparencia)
  // Usamos QImage en lugar de QPixmap para evitar crasheos en hilos de
  // renderizado (Thread Safety)
  int checkerSize = 20 * m_zoomLevel;
  if (checkerSize < 5)
    checkerSize = 5;

  QImage checkerImg(checkerSize * 2, checkerSize * 2, QImage::Format_ARGB32);
  checkerImg.fill(Qt::white);
  QPainter pt(&checkerImg);
  pt.fillRect(0, 0, checkerSize, checkerSize, QColor(220, 220, 220));
  pt.fillRect(checkerSize, checkerSize, checkerSize, checkerSize,
              QColor(220, 220, 220));
  pt.end();

  painter->save();
  painter->setBrush(QBrush(checkerImg));
  painter->setBrushOrigin(m_viewOffset.x() * m_zoomLevel,
                          m_viewOffset.y() * m_zoomLevel);
  painter->setPen(Qt::NoPen);
  painter->drawRect(paperRect);
  painter->restore();

  // Draw Background Color (if not transparent)
  if (m_backgroundColor.alpha() > 0) {
    painter->fillRect(paperRect, m_backgroundColor);
  }

  // Draw Drop Shadow (Optional, for better depth)
  // painter->setPen(Qt::NoPen);
  // painter->setBrush(QColor(0,0,0,50));
  // painter->drawRect(paperRect.translated(5, 5));

  if (m_layerManager->getLayerCount() > 0) {
    for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
      Layer *layer = m_layerManager->getLayer(i);
      if (!layer || !layer->visible)
        continue;

      QImage img(layer->buffer->data(), layer->buffer->width(),
                 layer->buffer->height(),
                 QImage::Format_RGBA8888_Premultiplied);

      // Rectángulo de destino con Zoom y Pan (Común)
      QRectF targetRect(
          m_viewOffset.x() * m_zoomLevel, m_viewOffset.y() * m_zoomLevel,
          m_canvasWidth * m_zoomLevel, m_canvasHeight * m_zoomLevel);

      bool renderedWithShader = false;
      // DIBUJAR VISTA PREVIA DE OPENGL (FBO) si estamos dibujando en esta capa
      if (m_isDrawing && i == m_activeLayerIndex && m_pingFBO) {
        painter->save();

        // Grab FBO image and correctly mark as premultiplied to avoid
        // Double-Alpha bug
        QImage fboImg =
            m_pingFBO->toImage(true).convertToFormat(QImage::Format_RGBA8888);
        fboImg.reinterpretAsFormat(QImage::Format_RGBA8888_Premultiplied);

        painter->setRenderHint(QPainter::SmoothPixmapTransform);
        painter->setRenderHint(QPainter::Antialiasing);
        painter->setOpacity(layer->opacity);
        painter->drawImage(targetRect, fboImg);
        painter->restore();
        renderedWithShader = true;
      }

      // Intentar usar shaders (Impasto)
      bool useImpasto = false;
      // Deshabilitado temporalmente para evitar crash en rendering
      if (false && m_impastoShader && m_impastoShader->isLinked()) {
        useImpasto = true;
      }

      if (useImpasto) {
        painter->save();
        painter->setOpacity(layer->opacity);
        painter->beginNativePainting();

        if (m_impastoShader->bind()) {
          m_impastoShader->setUniformValue("screenSize",
                                           QVector2D(width(), height()));
          m_impastoShader->setUniformValue("reliefStrength",
                                           m_impastoStrength * 8.0f);
          m_impastoShader->setUniformValue("impastoShininess",
                                           m_impastoShininess);

          float radians = m_lightAngle * M_PI / 180.0f;
          float lx = std::cos(radians);
          float ly = -std::sin(radians);
          m_impastoShader->setUniformValue("lightPos",
                                           QVector3D(lx, ly, m_lightElevation));

          // Textura
          QOpenGLTexture *tex = m_layerTextures.value(layer);
          if (!tex) {
            tex = new QOpenGLTexture(img.flipped(Qt::Vertical));
            m_layerTextures.insert(layer, tex);
            layer->dirty = false;
          } else if (layer->dirty) {
            tex->setData(img.flipped(Qt::Vertical));
            layer->dirty = false;
          }

          tex->bind(0);
          m_impastoShader->setUniformValue("canvasTexture", 0);

          // Draw Quad
          float x1 = (targetRect.left() / width()) * 2.0f - 1.0f;
          float y1 = 1.0f - (targetRect.top() / height()) * 2.0f;
          float x2 = (targetRect.right() / width()) * 2.0f - 1.0f;
          float y2 = 1.0f - (targetRect.bottom() / height()) * 2.0f;

          QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
          f->glEnable(GL_BLEND);
          f->glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

          GLfloat vertices[] = {x1, y1, 0.0f, 0.0f, x2, y1, 1.0f, 0.0f,
                                x1, y2, 0.0f, 1.0f, x1, y2, 0.0f, 1.0f,
                                x2, y1, 1.0f, 0.0f, x2, y2, 1.0f, 1.0f};

          m_impastoShader->enableAttributeArray(0);
          m_impastoShader->enableAttributeArray(1);
          m_impastoShader->setAttributeArray(0, GL_FLOAT, vertices, 2,
                                             4 * sizeof(GLfloat));
          m_impastoShader->setAttributeArray(1, GL_FLOAT, vertices + 2, 2,
                                             4 * sizeof(GLfloat));

          f->glDrawArrays(GL_TRIANGLES, 0, 6);

          m_impastoShader->disableAttributeArray(0);
          m_impastoShader->disableAttributeArray(1);

          m_impastoShader->release();
          tex->release();
          renderedWithShader = true;
        }
        painter->endNativePainting();
        painter->restore();
      }

      if (!renderedWithShader) {
        // Fallback
        painter->save();
        painter->setOpacity(layer->opacity);
        painter->drawImage(targetRect, img);
        painter->restore();
      }
    }
  }

  // 3. Transform Overlay (Preview)
  if (m_isTransforming && !m_selectionBuffer.isNull()) {
    painter->save();
    // Apply view transform (Pan/Zoom) first
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    // Apply the user's transformation matrix
    painter->setTransform(m_transformMatrix, true);

    painter->setRenderHint(QPainter::SmoothPixmapTransform);
    painter->drawImage(0, 0, m_selectionBuffer);

    // Draw Bounding Box handles
    painter->setTransform(
        QTransform()); // Reset for handles (screen space?) or keep in canvas?
    // Better to draw handles in screen space for consistency
    painter->restore();

    // Screen space deals for handles
    painter->save();
    QRectF screenBox = m_transformMatrix.mapRect(m_transformBox);
    // ... draw handles ...
    painter->restore();
  }

  // 4. Selección (Lasso) Feedback
  if (!m_selectionPath.isEmpty()) {
    painter->save();
    // Transformar de Canvas a Pantalla para el feedback
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QPen lassoPen(Qt::blue, 1 / m_zoomLevel, Qt::DashLine);
    painter->setPen(lassoPen);
    painter->drawPath(m_selectionPath);

    // Draw "Marching Ants" effect (simplified DashOffset animation if time
    // allows)
    painter->restore();
  }
}

void CanvasItem::handleDraw(const QPointF &pos, float pressure, float tilt) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->visible || layer->locked)
    return;

  QPointF lastCanvasPos = m_lastPos;

  // Convertir posición de pantalla a canvas
  // Aplicar transformación inversa: (Screen - Offset*Zoom) / Zoom
  QPointF canvasPos = (pos - m_viewOffset * m_zoomLevel) / m_zoomLevel;

  // FIX: Coordinate synchronization for flipped canvas
  if (m_isFlippedH) {
    canvasPos.setX(m_canvasWidth - canvasPos.x());
  }
  if (m_isFlippedV) {
    canvasPos.setY(m_canvasHeight - canvasPos.y());
  }

  BrushSettings settings = m_brushEngine->getBrush();

  // FIX: Support explicit Eraser Mode and "Transparent Color" (Clip Studio
  // Style)
  bool isTransparentColor = (m_brushColor.alpha() < 5);
  if (m_isEraser || isTransparentColor || m_tool == ToolType::Eraser) {
    settings.type = BrushSettings::Type::Eraser;
    // MÁSCARA DE BORRADO (Negro puro para la máscara de transparencia)
    settings.color = QColor(0, 0, 0, 255);
    // LIMPIEZA TOTAL: El borrador no debe tener texturas ni ruido
    settings.useTexture = false;
    settings.jitter = 0.0f;
    settings.grain = 0.0f;
    settings.hardness = 0.95f;
    // REDUCIR SPACING para evitar "bolitas" y que el borrado sea fluido
    settings.spacing = std::min(settings.spacing, 0.05f);
  }

  float effectivePressure = pressure;
  float velocityFactor = 0.0f;

  // === PER-PRESET DYNAMICS EVALUATION ===
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *activePreset = bpm->findByName(m_activeBrushName);

  if (!activePreset) {
    static int logCount = 0;
    if (logCount++ % 100 == 0) {
      qDebug() << "handleDraw: No preset found for" << m_activeBrushName;
    }
  } else {
    static QString lastLogged = "";
    if (m_activeBrushName != lastLogged) {
      qDebug() << "handleDraw: Using preset" << m_activeBrushName
               << "TipTexture:" << activePreset->shape.tipTexture;
      lastLogged = m_activeBrushName;
    }
  }

  if (activePreset &&
      !(m_isEraser || isTransparentColor || m_tool == ToolType::Eraser)) {
    // Evaluate pressure through the preset's response curve LUT
    float rawPressure = std::clamp(pressure, 0.0f, 1.0f);

    // SIZE dynamics: evaluate curve and apply range
    float sizeT = activePreset->sizeDynamics.evaluate(rawPressure);
    float sizeMultiplier = sizeT; // 0..1 multiplier for brush size
    settings.size = m_brushSize * sizeMultiplier;
    if (settings.size < 0.5f)
      settings.size = 0.5f;

    // OPACITY dynamics
    if (activePreset->opacityDynamics.minLimit < 0.99f) {
      float opacT = activePreset->opacityDynamics.evaluate(rawPressure);
      settings.opacity = m_brushOpacity * opacT;
    }

    // FLOW dynamics
    if (activePreset->flowDynamics.minLimit < 0.99f) {
      float flowT = activePreset->flowDynamics.evaluate(rawPressure);
      settings.flow = m_brushFlow * flowT;
    }

    // VELOCITY dynamics
    float dx = canvasPos.x() - lastCanvasPos.x();
    float dy = canvasPos.y() - lastCanvasPos.y();
    float strokeDist = std::hypot(dx, dy);
    // Normalize velocity: ~0.0 at rest, ~1.0 at fast movement
    velocityFactor = std::clamp(strokeDist / 50.0f, 0.0f, 1.0f);

    if (std::abs(activePreset->sizeDynamics.velocityInfluence) > 0.01f) {
      float velMod =
          activePreset->sizeDynamics.velocityInfluence * velocityFactor;
      settings.size *= (1.0f + velMod);
      if (settings.size < 0.5f)
        settings.size = 0.5f;
    }

    // JITTER (position scatter)
    if (activePreset->sizeDynamics.jitter > 0.01f) {
      float j = activePreset->sizeDynamics.jitter;
      settings.jitter = j;
    }

    // Let paintStroke know we've already applied dynamics
    effectivePressure = rawPressure;
    settings.sizeByPressure = false;    // We handled it
    settings.opacityByPressure = false; // We handled it
  } else {
    // Apply global pressure curve for erasers or when no preset is active
    effectivePressure = applyPressureCurve(pressure);
  }

  // Create QImage wrapper around layer buffer (Use RGBA8888_Premultiplied)
  QImage img(layer->buffer->data(), layer->buffer->width(),
             layer->buffer->height(), QImage::Format_RGBA8888_Premultiplied);

  // MODO PREMIUM (OpenGL / Shaders)
  // Usamos OpenGL para TODO si está disponible, es más preciso y rápido
  bool glReady = (QOpenGLContext::currentContext() != nullptr);
  if (glReady) {
    if (!m_pingFBO || m_pingFBO->width() != m_canvasWidth ||
        m_pingFBO->height() != m_canvasHeight) {
      if (m_pingFBO)
        delete m_pingFBO;
      if (m_pongFBO)
        delete m_pongFBO;

      // EXPLICIT FORMAT with Alpha support and 0 samples (Stable)
      QOpenGLFramebufferObjectFormat format;
      format.setInternalTextureFormat(GL_RGBA8);
      format.setSamples(0);
      format.setAttachment(QOpenGLFramebufferObject::NoAttachment);

      m_pingFBO =
          new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
      m_pongFBO =
          new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);

      // Initialize with current layer content
      m_pingFBO->bind();
      QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
      f->glClearColor(0, 0, 0, 0);
      f->glClear(GL_COLOR_BUFFER_BIT);

      QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
      QPainter fboPainter(&device);
      fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
      fboPainter.drawImage(0, 0, img);
      fboPainter.end();
      m_pingFBO->release();
    }

    // Copiar estado anterior (Ping -> Pong) de forma eficiente (Blit)
    // Esto evita descargar texturas de GPU a CPU
    QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);

    m_pongFBO->bind();
    QOpenGLPaintDevice device2(m_canvasWidth, m_canvasHeight);
    QPainter fboPainter2(&device2);

    // Dibujar nuevo trazo sobre el fondo ya copiado
    // Si es borrador, el renderer gestionará el blend mode específico
    fboPainter2.setCompositionMode(QPainter::CompositionMode_SourceOver);

    m_brushEngine->paintStroke(
        &fboPainter2, m_lastPos, canvasPos, effectivePressure, settings, tilt,
        velocityFactor, m_pingFBO->texture(), settings.wetness,
        settings.dilution, settings.smudge);
    fboPainter2.end();
    m_pongFBO->release();

    layer->dirty = true;
    std::swap(m_pingFBO, m_pongFBO);
  } else {
    // MODO ESTÁNDAR (Raster / Legacy)
    QPainter painter(&img);
    painter.setRenderHint(QPainter::Antialiasing);

    if (settings.type == BrushSettings::Type::Eraser) {
      painter.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    }

    m_brushEngine->paintStroke(&painter, m_lastPos, canvasPos,
                               effectivePressure, settings, tilt,
                               velocityFactor);
    painter.end();
    layer->dirty = true;
  }

  // Calculate dirty rect for update (Screen coordinates)
  // We need to determine the bounding box in canvas coords, then map to
  // screen. Use lastCanvasPos (captured at start) to ensure we cover the
  // whole segment
  float minX = std::min(lastCanvasPos.x(), canvasPos.x());
  float minY = std::min(lastCanvasPos.y(), canvasPos.y());
  float maxX = std::max(lastCanvasPos.x(), canvasPos.x());
  float maxY = std::max(lastCanvasPos.y(), canvasPos.y());

  QRectF canvasRect(minX, minY, maxX - minX, maxY - minY);
  // Add margin based on brush size
  float margin = settings.size + 5.0f;
  canvasRect.adjust(-margin, -margin, margin, margin);

  // Transform back to screen for update()
  QRectF screenRect(
      canvasRect.x() * m_zoomLevel + m_viewOffset.x() * m_zoomLevel,
      canvasRect.y() * m_zoomLevel + m_viewOffset.y() * m_zoomLevel,
      canvasRect.width() * m_zoomLevel, canvasRect.height() * m_zoomLevel);

  // Extra safety for screen clipping
  screenRect.adjust(-2, -2, 2, 2);

  m_lastPos = canvasPos;
  update(screenRect.toAlignedRect());
}

void CanvasItem::detectAndDrawQuickShape() {
  if (!m_isDrawing || m_strokePoints.size() < 10)
    return;

  m_isHoldingForShape = true;

  // 1. ANALYZE SHAPE (BEFORE REVERTING!)
  QPointF start = m_strokePoints.front();
  QPointF end = m_strokePoints.back();
  float distSE = QPointF(start - end).manhattanLength();

  float totalLength = 0;
  for (size_t i = 1; i < m_strokePoints.size(); ++i) {
    totalLength +=
        QPointF(m_strokePoints[i] - m_strokePoints[i - 1]).manhattanLength();
  }

  // Convert to Canvas Coords
  QPointF startC = (start - m_viewOffset * m_zoomLevel) / m_zoomLevel;
  QPointF endC = (end - m_viewOffset * m_zoomLevel) / m_zoomLevel;
  if (m_isFlippedH) {
    startC.setX(m_canvasWidth - startC.x());
    endC.setX(m_canvasWidth - endC.x());
  }
  if (m_isFlippedV) {
    startC.setY(m_canvasHeight - startC.y());
    endC.setY(m_canvasHeight - endC.y());
  }

  Layer *layer = m_layerManager->getActiveLayer();
  bool solved = false;

  if (totalLength < distSE * 1.5f) {
    // It's a LINE - Revert and Draw
    if (layer && layer->buffer && m_strokeBeforeBuffer) {
      layer->buffer->copyFrom(*m_strokeBeforeBuffer);
    }
    drawLine(startC, endC);
    solved = true;
  } else {
    // Circle detection
    QPointF centroid(0, 0);
    for (const auto &p : m_strokePoints)
      centroid += p;
    centroid /= (float)m_strokePoints.size();

    float avgDist = 0;
    std::vector<float> radii;
    for (const auto &p : m_strokePoints) {
      float r = QPointF(p - centroid).manhattanLength();
      avgDist += r;
      radii.push_back(r);
    }
    avgDist /= (float)radii.size();

    float variance = 0;
    for (float r : radii)
      variance += (r - avgDist) * (r - avgDist);
    variance = std::sqrt(variance / radii.size());

    // Lenient circularity check (45% variance allowed for hand-drawn circles)
    if (variance < avgDist * 0.45f) {
      if (layer && layer->buffer && m_strokeBeforeBuffer) {
        layer->buffer->copyFrom(*m_strokeBeforeBuffer);
      }
      QPointF centroidC = (centroid - m_viewOffset * m_zoomLevel) / m_zoomLevel;
      if (m_isFlippedH)
        centroidC.setX(m_canvasWidth - centroidC.x());
      if (m_isFlippedV)
        centroidC.setY(m_canvasHeight - centroidC.y());

      float maxR = 0;
      for (float r : radii)
        maxR = std::max(maxR, r);
      drawCircle(centroidC, maxR / m_zoomLevel);
      solved = true;
    }
  }

  if (!solved) {
    m_isHoldingForShape = false;
    return;
  }

  // 3. SYNC FBO FROM CPU BUFFER (INSTANT REFRESH)
  if (m_pingFBO && layer && layer->buffer) {
    QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
               QImage::Format_RGBA8888);
    m_pingFBO->bind();
    QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
    QPainter fboPainter(&device);
    fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
    fboPainter.drawImage(0, 0, img);
    fboPainter.end();
    m_pingFBO->release();
    // Pong already synced via blit if needed, or we just blit now
    QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
  }

  update();
}

void CanvasItem::drawLine(const QPointF &p1, const QPointF &p2) {
  Layer *layer = m_layerManager->getActiveLayer();
  QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888);
  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);
  painter.setPen(QPen(m_brushColor, m_brushSize, Qt::SolidLine, Qt::RoundCap));
  painter.drawLine(p1, p2);
}

void CanvasItem::drawCircle(const QPointF &center, float radius) {
  Layer *layer = m_layerManager->getActiveLayer();
  QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888);
  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);
  painter.setPen(QPen(m_brushColor, m_brushSize, Qt::SolidLine, Qt::RoundCap));
  painter.drawEllipse(center, radius, radius);
}

void CanvasItem::mousePressEvent(QMouseEvent *event) {
  m_lastMousePos = event->position();

  if (m_tool == ToolType::Hand) {
    QGuiApplication::setOverrideCursor(Qt::ClosedHandCursor);
    return;
  }

  if (m_tool == ToolType::Eyedropper) {
    QString color = sampleColor(static_cast<int>(event->position().x()),
                                static_cast<int>(event->position().y()));
    setBrushColor(QColor(color));
    return;
  }

  if (m_tool == ToolType::Lasso) {
    m_selectionPath = QPainterPath();
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_selectionPath.moveTo(canvasPos);
    m_hasSelection = false;
    update();
    return;
  }

  if (m_tool == ToolType::Transform) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    // Si ya estamos transformando, ver si clicamos dentro para mover
    if (m_isTransforming) {
      QRectF transformedBox = m_transformMatrix.mapRect(m_transformBox);
      if (transformedBox.contains(canvasPos)) {
        m_transformMode = TransformMode::Move;
        m_transformStartPos = canvasPos;
        m_initialMatrix = m_transformMatrix;
        return;
      } else {
        // Clic fuera -> Confirmar y terminar
        commitTransform();
      }
    }

    // Si NO estamos transformando, empezar ahora al hacer clic
    if (!m_isTransforming) {
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer) {
        // Si no hay selección previa, seleccionar todo
        if (!m_hasSelection || m_selectionPath.isEmpty()) {
          m_selectionPath = QPainterPath();
          m_selectionPath.addRect(0, 0, m_canvasWidth, m_canvasHeight);
          m_hasSelection = true;
        }

        m_isTransforming = true;
        m_transformMatrix = QTransform();
        m_transformBox = m_selectionPath.boundingRect();

        QImage full(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                    QImage::Format_RGBA8888);
        m_selectionBuffer =
            QImage(m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888);
        m_selectionBuffer.fill(Qt::transparent);

        QPainter p(&m_selectionBuffer);
        p.setClipPath(m_selectionPath);
        p.drawImage(0, 0, full);
        p.end();

        QPainter p2(&full);
        p2.setCompositionMode(QPainter::CompositionMode_Clear);
        p2.setClipPath(m_selectionPath);
        p2.fillRect(full.rect(), Qt::transparent);
        p2.end();

        layer->dirty = true;
        m_transformMode = TransformMode::Move;
        m_transformStartPos = canvasPos;
        m_initialMatrix = m_transformMatrix;
        update();
        return;
      }
    }
  }

  if (event->button() == Qt::LeftButton) {
    if (m_isDrawing)
      return; // Already drawing (tablet?)

    // Evitar que herramientas de NO DIBUJO pinten accidentalmente
    if (m_tool != ToolType::Pen && m_tool != ToolType::Eraser &&
        m_tool != ToolType::Fill && m_tool != ToolType::Shape) {
      return;
    }

    m_isDrawing = true;
    m_lastPos = (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    // ... rest of stroke start logic ...
    Layer *layer = m_layerManager->getActiveLayer();
    if (layer && layer->buffer) {
      m_strokeBeforeBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
    }

    m_brushEngine->resetRemainder();
    m_strokePoints.clear();
    m_strokePoints.push_back(event->position());
    m_holdStartPos = event->position();
    m_isHoldingForShape = false;

    // Emitir señal de que se ha empezado a pintar con el color actual
    if (m_tool == ToolType::Pen) {
      emit strokeStarted(m_brushColor);
    }

    // Solo iniciar timer si es una herramienta de dibujo
    if (m_tool == ToolType::Pen || m_tool == ToolType::Eraser) {
      m_quickShapeTimer->start(800);
    }

    float pressure = 1.0f;
    handleDraw(event->position(), pressure);
  }
}

void CanvasItem::mouseMoveEvent(QMouseEvent *event) {
  emit cursorPosChanged(event->position().x(), event->position().y());

  if (m_tool == ToolType::Hand && (event->buttons() & Qt::LeftButton)) {
    QPointF delta = (event->position() - m_lastMousePos) / m_zoomLevel;
    m_viewOffset += delta;
    m_lastMousePos = event->position();
    emit viewOffsetChanged();
    update();
    return;
  }

  if (m_tool == ToolType::Eyedropper && (event->buttons() & Qt::LeftButton)) {
    QString color = sampleColor(static_cast<int>(event->position().x()),
                                static_cast<int>(event->position().y()));
    setBrushColor(QColor(color));
    return;
  }

  if (m_tool == ToolType::Transform && m_transformMode == TransformMode::Move) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    QPointF delta = canvasPos - m_transformStartPos;
    m_transformMatrix = m_initialMatrix;
    m_transformMatrix.translate(delta.x(), delta.y());
    update();
    return;
  }

  if (m_tool == ToolType::Lasso && (event->buttons() & Qt::LeftButton)) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_selectionPath.lineTo(canvasPos);
    update();
    return;
  }

  if (m_isDrawing) {
    float pressure = 1.0f;
    if (!event->points().isEmpty()) {
      float p = event->points().first().pressure();
      if (p > 0.0f)
        pressure = p;
    }

    if (!m_isHoldingForShape) {
      m_strokePoints.push_back(event->position());
      float dist =
          QPointF(event->position() - m_holdStartPos).manhattanLength();
      if (dist > 25.0f) {
        m_holdStartPos = event->position();
        if (m_tool == ToolType::Pen || m_tool == ToolType::Eraser)
          m_quickShapeTimer->start(800);
      }
    }

    handleDraw(event->position(), pressure);
  }
  m_lastMousePos = event->position();
}

void CanvasItem::mouseReleaseEvent(QMouseEvent *event) {
  if (m_tool == ToolType::Lasso) {
    m_selectionPath.closeSubpath();
    m_hasSelection = !m_selectionPath.isEmpty();
    update();
    return;
  }

  if (m_tool == ToolType::Transform) {
    m_transformMode = TransformMode::None;
    update();
    return;
  }

  if (m_tool == ToolType::Hand) {
    QGuiApplication::restoreOverrideCursor();
    return;
  }

  if (event->button() == Qt::LeftButton) {
    if (m_isDrawing) {
      m_quickShapeTimer->stop();
      bool wasHolding = m_isHoldingForShape;
      m_isDrawing = false;
      m_isHoldingForShape = false;

      if (m_pingFBO) {
        if (!wasHolding) {
          // Correctly convert FBO data to layer buffer without
          // double-premultiplying
          QImage result =
              m_pingFBO->toImage(true).convertToFormat(QImage::Format_RGBA8888);
          result.reinterpretAsFormat(QImage::Format_RGBA8888_Premultiplied);

          Layer *layer = m_layerManager->getActiveLayer();
          if (layer && layer->buffer) {
            std::memcpy(layer->buffer->data(), result.bits(),
                        std::min((size_t)layer->buffer->width() *
                                     layer->buffer->height() * 4,
                                 (size_t)result.sizeInBytes()));
          }
        }
        delete m_pingFBO;
        m_pingFBO = nullptr;
        delete m_pongFBO;
        m_pongFBO = nullptr;
      }

      if (m_strokeBeforeBuffer) {
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer) {
          auto afterBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
          m_undoManager->pushCommand(std::make_unique<StrokeUndoCommand>(
              m_layerManager, m_activeLayerIndex,
              std::move(m_strokeBeforeBuffer), std::move(afterBuffer)));
        }
        m_strokeBeforeBuffer.reset();
      }

      m_lastPos = QPointF();
      capture_timelapse_frame();
      update();
      updateLayersList(); // Update thumbnails after stroke
    }
  }
}

void CanvasItem::tabletEvent(QTabletEvent *event) {
  float pressure = event->pressure();
  // Normalizar presión
  if (pressure > 1.0f)
    pressure /= 1024.0f;

  // CAPTURAR INCLINACIÓN (TILT) - Pilar 1 Premium
  // xTilt y yTilt suelen devolver grados (-60 a 60).
  // Obtenemos un factor de 0.0 (vertical) a 1.0 (máxima inclinación)
  float tiltX = event->xTilt();
  float tiltY = event->yTilt();
  float tiltFactor =
      std::max(std::abs((float)tiltX), std::abs((float)tiltY)) / 60.0f;
  tiltFactor = std::max(0.0f, std::min(1.0f, tiltFactor));

  if (event->type() == QEvent::TabletPress) {
    // Evitar que herramientas de NO DIBUJO pinten accidentalmente
    if (m_tool != ToolType::Pen && m_tool != ToolType::Eraser &&
        m_tool != ToolType::Fill && m_tool != ToolType::Shape) {
      return;
    }

    m_isDrawing = true;
    QPointF p = event->position();
    QPointF canvasPos = (p - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_lastPos = canvasPos;

    // Undo Snapshot
    Layer *layer = m_layerManager->getActiveLayer();
    if (layer && layer->buffer) {
      m_strokeBeforeBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
    }

    m_brushEngine->resetRemainder();

    m_strokePoints.clear();
    m_strokePoints.push_back(event->position());
    m_holdStartPos = event->position();
    m_isHoldingForShape = false;

    // Emitir señal de que se ha empezado a pintar con el color actual
    if (m_tool == ToolType::Pen) {
      emit strokeStarted(m_brushColor);
    }

    m_quickShapeTimer->start(800);

    handleDraw(event->position(), pressure, tiltFactor);
    event->accept();

  } else if (event->type() == QEvent::TabletMove && m_isDrawing) {
    if (m_isDrawing && !m_isHoldingForShape) {
      m_strokePoints.push_back(event->position());
      float dist =
          QPointF(event->position() - m_holdStartPos).manhattanLength();
      if (dist > 25.0f) { // Increased threshold for jitter
        m_holdStartPos = event->position();
        m_quickShapeTimer->start(800);
      }
    }

    handleDraw(event->position(), pressure, tiltFactor);
    event->accept();

  } else if (event->type() == QEvent::TabletRelease) {
    m_quickShapeTimer->stop();
    bool wasHolding = m_isHoldingForShape;
    m_isDrawing = false;
    m_isHoldingForShape = false;

    // FINALIZAR TRAZO PREMIUM (Pilar 3): Volcar GPU a CPU
    if (m_pingFBO) {
      if (!wasHolding) {
        QImage result =
            m_pingFBO->toImage(true).convertToFormat(QImage::Format_ARGB32);
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer) {
          std::memcpy(layer->buffer->data(), result.bits(),
                      std::min((size_t)layer->buffer->width() *
                                   layer->buffer->height() * 4,
                               (size_t)result.sizeInBytes()));
        }
      }
      delete m_pingFBO;
      m_pingFBO = nullptr;
      delete m_pongFBO;
      m_pongFBO = nullptr;
    }

    // CREATE UNDO COMMAND
    if (m_strokeBeforeBuffer) {
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer) {
        auto afterBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
        m_undoManager->pushCommand(std::make_unique<StrokeUndoCommand>(
            m_layerManager, m_activeLayerIndex, std::move(m_strokeBeforeBuffer),
            std::move(afterBuffer)));
      }
      m_strokeBeforeBuffer.reset();
    }

    m_lastPos = QPointF();
    capture_timelapse_frame();
    update();           // Refrescar vista
    updateLayersList(); // Update thumbnails after stroke
    event->accept();
  }
}

bool CanvasItem::event(QEvent *event) {
  // Dispatch tablet events manually if QQuickItem doesn't automatically
  if (event->type() == QEvent::TabletPress ||
      event->type() == QEvent::TabletMove ||
      event->type() == QEvent::TabletRelease) {
    tabletEvent(static_cast<QTabletEvent *>(event));
    return true;
  }
  return QQuickPaintedItem::event(event);
}

void CanvasItem::hoverMoveEvent(QHoverEvent *event) {
  emit cursorPosChanged(event->position().x(), event->position().y());
}

// ... Setters and other methods ...

void CanvasItem::setBrushSize(int size) {
  m_brushSize = size;
  BrushSettings s = m_brushEngine->getBrush();
  s.size = static_cast<float>(size);
  m_brushEngine->setBrush(s);
  emit brushSizeChanged();
}

void CanvasItem::setBrushColor(const QColor &color) {
  m_brushColor = color;
  BrushSettings s = m_brushEngine->getBrush();
  s.color = color;
  m_brushEngine->setBrush(s);
  emit brushColorChanged();
}

void CanvasItem::setBrushOpacity(float opacity) {
  m_brushOpacity = opacity;
  BrushSettings s = m_brushEngine->getBrush();
  s.opacity = opacity;
  m_brushEngine->setBrush(s);
  emit brushOpacityChanged();
}

void CanvasItem::setBrushFlow(float flow) {
  m_brushFlow = flow;
  BrushSettings s = m_brushEngine->getBrush();
  s.flow = flow;
  m_brushEngine->setBrush(s);
  emit brushFlowChanged();
}

void CanvasItem::setBrushHardness(float hardness) {
  m_brushHardness = hardness;
  BrushSettings s = m_brushEngine->getBrush();
  s.hardness = hardness;
  m_brushEngine->setBrush(s);
  emit brushHardnessChanged();
}

void CanvasItem::setBrushSpacing(float spacing) {
  m_brushSpacing = spacing;
  BrushSettings s = m_brushEngine->getBrush();
  s.spacing = spacing;
  m_brushEngine->setBrush(s);
  emit brushSpacingChanged();
}

void CanvasItem::setBrushStabilization(float value) {
  m_brushStabilization = value;
  BrushSettings s = m_brushEngine->getBrush();
  s.stabilization = value;
  m_brushEngine->setBrush(s);
  emit brushStabilizationChanged();
}

void CanvasItem::setBrushStreamline(float value) {
  m_brushStreamline = value;
  BrushSettings s = m_brushEngine->getBrush();
  s.streamline = value;
  m_brushEngine->setBrush(s);
  emit brushStreamlineChanged();
}

void CanvasItem::setBrushGrain(float value) {
  m_brushGrain = value;
  BrushSettings s = m_brushEngine->getBrush();
  s.grain = value;
  m_brushEngine->setBrush(s);
  emit brushGrainChanged();
}

void CanvasItem::setBrushWetness(float value) {
  m_brushWetness = value;
  BrushSettings s = m_brushEngine->getBrush();
  s.wetness = value;
  m_brushEngine->setBrush(s);
  emit brushWetnessChanged();
}

void CanvasItem::setBrushSmudge(float value) {
  m_brushSmudge = value;
  BrushSettings s = m_brushEngine->getBrush();
  s.smudge = value;
  m_brushEngine->setBrush(s);
  emit brushSmudgeChanged();
}

void CanvasItem::setImpastoShininess(float value) {
  if (qFuzzyCompare(m_impastoShininess, value))
    return;
  m_impastoShininess = value;
  emit impastoShininessChanged();
  update();
}

void CanvasItem::setImpastoStrength(float strength) {
  if (qFuzzyCompare(m_impastoStrength, strength))
    return;
  m_impastoStrength = strength;
  emit impastoSettingsChanged();
  update();
}

void CanvasItem::setLightAngle(float angle) {
  if (qFuzzyCompare(m_lightAngle, angle))
    return;
  m_lightAngle = angle;
  emit impastoSettingsChanged();
  update();
}

void CanvasItem::setLightElevation(float elevation) {
  if (qFuzzyCompare(m_lightElevation, elevation))
    return;
  m_lightElevation = elevation;
  emit impastoSettingsChanged();
  update();
}

void CanvasItem::setBrushAngle(float value) {
  m_brushAngle = value;
  emit brushAngleChanged();
}

void CanvasItem::setCursorRotation(float value) {
  m_cursorRotation = value;
  emit cursorRotationChanged();
}

void CanvasItem::setZoomLevel(float zoom) {
  m_zoomLevel = zoom;
  emit zoomLevelChanged();
  update();
}
void CanvasItem::setViewOffset(const QPointF &offset) {
  m_viewOffset = offset;
  emit viewOffsetChanged();
  update();
}
void CanvasItem::setIsEraser(bool eraser) {
  if (m_isEraser == eraser)
    return;
  m_isEraser = eraser;
  if (m_isEraser) {
    emit requestToolIdx(9);
  } else {
    // Re-sync current tool index if disabled
    setCurrentTool(m_currentToolStr);
  }
  // If we are in eraser mode, we should also update the engine's brush type
  BrushSettings s = m_brushEngine->getBrush();
  if (m_isEraser) {
    s.type = BrushSettings::Type::Eraser;
  } else {
    // Return to a default type or have a way to restore?
    // For now, assume most drawing is 'Round' or 'Custom'
    // but better to not force it here. handleDraw will handle the override.
  }
  m_brushEngine->setBrush(s);
  emit isEraserChanged(m_isEraser);
  update();
}

void CanvasItem::setCurrentTool(const QString &tool) {
  if (m_currentToolStr == tool)
    return;

  // Commit transformation if switching away from transform tool
  if (m_currentToolStr == "transform" && m_isTransforming) {
    commitTransform();
  }

  m_currentToolStr = tool;

  // Sync QML toolbar index
  if (tool == "selection")
    emit requestToolIdx(0);
  else if (tool == "shapes")
    emit requestToolIdx(1);
  else if (tool == "lasso")
    emit requestToolIdx(2);
  else if (tool == "magnetic_lasso")
    emit requestToolIdx(3);
  else if (tool == "move")
    emit requestToolIdx(4);
  else if (tool == "pen")
    emit requestToolIdx(5);
  else if (tool == "pencil")
    emit requestToolIdx(6);
  else if (tool == "brush")
    emit requestToolIdx(7);
  else if (tool == "airbrush")
    emit requestToolIdx(8);
  else if (tool == "eraser")
    emit requestToolIdx(9);
  else if (tool == "fill")
    emit requestToolIdx(10);
  else if (tool == "eyedropper" || tool == "picker")
    emit requestToolIdx(11);
  else if (tool == "hand")
    emit requestToolIdx(12);

  if (tool == "brush" || tool == "pen" || tool == "pencil" ||
      tool == "watercolor" || tool == "airbrush")
    m_tool = ToolType::Pen;
  else if (tool == "eraser")
    m_tool = ToolType::Eraser;
  else if (tool == "lasso")
    m_tool = ToolType::Lasso;
  else if (tool == "transform" || tool == "move") {
    m_tool = ToolType::Transform;
    // Ya no 'levantamos' el contenido aquí para evitar recuadros azules
    // inmediatos y destrucción accidental de trazos previos. La lógica se
    // movió a mousePressEvent.
  } else if (tool == "eyedropper")
    m_tool = ToolType::Eyedropper;
  else if (tool == "hand")
    m_tool = ToolType::Hand;
  else if (tool == "fill")
    m_tool = ToolType::Fill;

  emit currentToolChanged();

  // Auto-apply default presets for tools
  if (tool == "pencil")
    usePreset("Pencil HB");
  else if (tool == "pen")
    usePreset("Ink Pen");
  else if (tool == "brush")
    usePreset("Oil Paint");
  else if (tool == "watercolor")
    usePreset("Watercolor");
  else if (tool == "airbrush")
    usePreset("Soft");
  else if (tool == "eraser")
    usePreset("Eraser Soft");

  update();
}

void CanvasItem::commitTransform() {
  if (!m_isTransforming || m_selectionBuffer.isNull())
    return;

  Layer *layer = m_layerManager->getActiveLayer();
  if (layer && layer->buffer) {
    QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
               QImage::Format_ARGB32);
    QPainter p(&img);
    p.setRenderHint(QPainter::SmoothPixmapTransform);
    p.setTransform(m_transformMatrix);
    p.drawImage(0, 0, m_selectionBuffer);
    p.end();
    layer->dirty = true;
  }

  m_isTransforming = false;
  m_selectionBuffer = QImage();
  m_selectionPath = QPainterPath();
  m_hasSelection = false;
  update();
}

void CanvasItem::adjustBrushSize(float deltaPercent) {
  setBrushSize(std::max(1, (int)(m_brushSize * (1.0f + deltaPercent))));
}

void CanvasItem::adjustBrushOpacity(float deltaPercent) {
  setBrushOpacity(std::clamp(m_brushOpacity + deltaPercent, 0.0f, 1.0f));
}

void CanvasItem::wheelEvent(QWheelEvent *event) {
  QPointF pos = event->position();

  // Unproject to canvas space
  QPointF canvasPosBefore = (pos - m_viewOffset * m_zoomLevel) / m_zoomLevel;

  float factor = (event->angleDelta().y() > 0) ? 1.1f : 0.9f;
  float newZoom = m_zoomLevel * factor;

  if (newZoom < 0.01f)
    newZoom = 0.01f;
  if (newZoom > 100.0f)
    newZoom = 100.0f;

  m_zoomLevel = newZoom;

  // Adjust viewOffset to keep canvasPosBefore under the cursor
  m_viewOffset = (pos / m_zoomLevel) - canvasPosBefore;

  emit zoomLevelChanged();
  emit viewOffsetChanged();
  update();
}

void CanvasItem::loadRecentProjectsAsync() {
  (void)QtConcurrent::run([this]() {
    QVariantList results = this->_scanSync();
    emit projectsLoaded(results);
  });
}

QVariantList CanvasItem::getRecentProjects() {
  QVariantList full = _scanSync();
  if (full.size() > 5)
    return full.mid(0, 5);
  return full;
}

QVariantList CanvasItem::get_project_list() { return _scanSync(); }

QVariantList CanvasItem::_scanSync() {
  QVariantList results;
  QString path =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/ArtFlowProjects";
  QDir dir(path);

  QFileInfoList entries = dir.entryInfoList(
      QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, QDir::Time);
  for (const QFileInfo &info : entries) {
    if (info.fileName().endsWith(".json") && info.isFile())
      continue;

    QVariantMap item;
    item["name"] = info.fileName();
    item["path"] = info.absoluteFilePath();
    item["type"] = info.isDir() ? "folder" : "drawing";
    item["date"] = info.lastModified();
    results.append(item);
  }
  return results;
}

void CanvasItem::load_file_path(const QString &path) { loadProject(path); }
void CanvasItem::handle_shortcuts(int key, int modifiers) {
  bool ctrl = modifiers & Qt::ControlModifier;
  bool shift = modifiers & Qt::ShiftModifier;

  // Undo / Redo
  if (ctrl && key == Qt::Key_Z) {
    if (shift)
      redo();
    else
      undo();
  } else if (ctrl && key == Qt::Key_Y) {
    redo();
  }
  // Transform
  else if (ctrl && key == Qt::Key_T) {
    m_isTransforming = true;
    emit isTransformingChanged();
  }
  // Select None
  else if (ctrl && key == Qt::Key_D) {
    // Clear selection logic
  }
  // Space (Pan)
  else if (key == Qt::Key_Space) {
    QGuiApplication::setOverrideCursor(QCursor(Qt::OpenHandCursor));
  }
  // Brush Size/Opacity
  else if (key == Qt::Key_BracketLeft)
    adjustBrushSize(-0.1f);
  else if (key == Qt::Key_BracketRight)
    adjustBrushSize(0.1f);
  else if (key == Qt::Key_O) // Optional: Opacity decrease
    adjustBrushOpacity(-0.1f);
  else if (key == Qt::Key_P) // Optional: Opacity increase
    adjustBrushOpacity(0.1f);

  // Tool Switches
  else if (key == Qt::Key_B)
    setCurrentTool("brush");
  else if (key == Qt::Key_E)
    setCurrentTool("eraser");
  else if (key == Qt::Key_L)
    setCurrentTool("lasso");
  else if (key == Qt::Key_H)
    setCurrentTool("hand");
  else if (key == Qt::Key_I) // Eyedropper shortcut
    setCurrentTool("eyedropper");
  else if (key == Qt::Key_V)
    setCurrentTool("move");
}

void CanvasItem::handle_key_release(int key) {
  if (key == Qt::Key_Space) {
    QGuiApplication::restoreOverrideCursor();
  }
}
void CanvasItem::fitToView() {
  if (m_canvasWidth <= 0 || m_canvasHeight <= 0 || width() <= 0 ||
      height() <= 0)
    return;

  float margin = 40.0f;
  float availableW = width() - margin * 2;
  float availableH = height() - margin * 2;

  float scaleX = availableW / m_canvasWidth;
  float scaleY = availableH / m_canvasHeight;
  float newZoom = std::min(scaleX, scaleY);

  // Constraints for zoom (don't zoom in too much if canvas is tiny)
  if (newZoom > 1.0f)
    newZoom = 1.0f;

  setZoomLevel(newZoom);

  float offsetX = (width() - m_canvasWidth * newZoom) / 2.0f / newZoom;
  float offsetY = (height() - m_canvasHeight * newZoom) / 2.0f / newZoom;

  setViewOffset(QPointF(offsetX, offsetY));

  update();
}

void CanvasItem::addLayer() {
  m_layerManager->addLayer("New Layer");
  m_activeLayerIndex = m_layerManager->getLayerCount() - 1;
  emit activeLayerChanged();
  updateLayersList();
  update();
}

void CanvasItem::removeLayer(int index) {
  m_layerManager->removeLayer(index);
  m_activeLayerIndex = qMax(0, (int)m_layerManager->getLayerCount() - 1);
  emit activeLayerChanged();
  updateLayersList();
  update();
}

void CanvasItem::duplicateLayer(int index) {
  m_layerManager->duplicateLayer(index);
  updateLayersList();
  update();
}

void CanvasItem::mergeDown(int index) {
  m_layerManager->mergeDown(index);
  updateLayersList();
  update();
}

void CanvasItem::renameLayer(int index, const QString &name) {
  Layer *l = m_layerManager->getLayer(index);
  if (l)
    l->name = name.toStdString();
}

void CanvasItem::applyEffect(int index, const QString &effect,
                             const QVariantMap &params) {
  qDebug() << "Applying effect:" << effect << "on layer" << index;
}

void CanvasItem::setBackgroundColor(const QString &color) {
  QColor newColor(color);
  if (newColor.isValid()) {
    m_backgroundColor = newColor;

    // Also update any Background layer
    if (m_layerManager) {
      for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
        Layer *l = m_layerManager->getLayer(i);
        if (l && l->type == Layer::Type::Background) {
          // Swap R and B for QImage::Format_ARGB32 (BGRA)
          l->buffer->fill(newColor.blue(), newColor.green(), newColor.red(),
                          255); // Force opaque for background layer
          l->dirty = true;      // Mark dirty for rendering
          updateLayersList();   // Refresh UI thumbnails
        }
      }
    }

    update();
  }
}

bool CanvasItem::loadProject(const QString &path) {
  qDebug() << "Loading project from:" << path;
  m_currentProjectPath = path;
  m_currentProjectName = QFileInfo(path).baseName();
  emit currentProjectPathChanged();
  emit currentProjectNameChanged();

  // In a real app, you'd load layers from file here
  fitToView();
  return true;
}

bool CanvasItem::saveProject(const QString &path) {
  qDebug() << "Saving project to:" << path;
  return true;
}

bool CanvasItem::saveProjectAs(const QString &path) {
  return saveProject(path);
}

bool CanvasItem::exportImage(const QString &path, const QString &format) {
  if (!m_layerManager)
    return false;

  // Create a composite image
  ImageBuffer composite(m_canvasWidth, m_canvasHeight);
  m_layerManager->compositeAll(composite);

  QImage img(composite.data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888);
  // Convert path to local file if it's a URL
  QString localPath = path;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(path).toLocalFile();
  }

  return img.save(localPath, format.toUpper().toStdString().c_str());
}

bool CanvasItem::importABR(const QString &path) {
  qDebug() << "Importing ABR:" << path;
  return true;
}

void CanvasItem::updateTransformProperties(float x, float y, float scale,
                                           float rotation, float w, float h) {
  // This would update the transformation matrix for a selection
}

void CanvasItem::updateLayersList() {
  if (!m_layerManager)
    return;

  QVariantList layerList;
  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    Layer *l = m_layerManager->getLayer(i);
    QVariantMap layer;
    layer["layerId"] = i;
    layer["name"] = QString::fromStdString(l->name);
    layer["visible"] = l->visible;
    layer["opacity"] = l->opacity;
    layer["locked"] = l->locked;
    layer["alpha_lock"] = l->alphaLock;
    layer["clipped"] = l->clipped;
    layer["is_private"] = l->isPrivate;
    layer["active"] = (i == m_activeLayerIndex);
    layer["type"] = (i == 0) ? "background" : "drawing";

    // Add thumbnail if active or requested (real app would cache these)
    // Add thumbnail for ALL layers
    if (l->buffer && l->buffer->width() > 0 && l->buffer->height() > 0) {
      int tw = 60, th = 40;
      // Use QImage wrapper around existing buffer (no copy yet)
      QImage full(l->buffer->data(), l->buffer->width(), l->buffer->height(),
                  QImage::Format_ARGB32);

      // Debug logging
      if (l->buffer->width() > 0 && l->buffer->height() > 0) {
        uint32_t *pixels = reinterpret_cast<uint32_t *>(l->buffer->data());
        qDebug() << "Layer:" << i << "Buf:" << l->buffer->width() << "x"
                 << l->buffer->height()
                 << "Pixel[0]:" << QString::number(pixels[0], 16)
                 << "Pixel[Center]:"
                 << QString::number(
                        pixels[l->buffer->width() * l->buffer->height() / 2],
                        16);
      }

      // Scale down (high quality)
      QImage thumb =
          full.scaled(tw, th, Qt::KeepAspectRatio, Qt::SmoothTransformation);

      QByteArray ba;
      QBuffer buffer(&ba);
      buffer.open(QIODevice::WriteOnly);
      thumb.save(&buffer, "PNG");
      QString b64 = QString::fromLatin1(ba.toBase64());
      layer["thumbnail"] = "data:image/png;base64," + b64;
    } else {
      layer["thumbnail"] = "";
    }

    layerList.prepend(layer);
  }
  emit layersChanged(layerList);
}

void CanvasItem::resizeCanvas(int w, int h) {
  m_canvasWidth = w;
  m_canvasHeight = h;

  delete m_layerManager;
  m_layerManager = new LayerManager(w, h);

  m_layerManager->addLayer("Layer 1");
  m_activeLayerIndex = 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  emit canvasWidthChanged();
  emit canvasHeightChanged();
  updateLayersList();
  fitToView();
  update();
}

void CanvasItem::setProjectDpi(int dpi) { qDebug() << "DPI set to" << dpi; }

QString CanvasItem::sampleColor(int x, int y, int mode) {
  if (!m_layerManager)
    return "#000000";

  uint8_t r, g, b, a;
  float cx = (x - m_viewOffset.x() * m_zoomLevel) / m_zoomLevel;
  float cy = (y - m_viewOffset.y() * m_zoomLevel) / m_zoomLevel;

  m_layerManager->sampleColor(static_cast<int>(cx), static_cast<int>(cy), &r,
                              &g, &b, &a, mode);
  return QColor(r, g, b, a).name();
}

bool CanvasItem::isLayerClipped(int index) {
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->clipped : false;
}

void CanvasItem::toggleClipping(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->clipped = !l->clipped;
    updateLayersList();
    update();
  }
}

void CanvasItem::toggleAlphaLock(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->alphaLock = !l->alphaLock;
    updateLayersList();
  }
}

void CanvasItem::toggleVisibility(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->visible = !l->visible;
    updateLayersList();
    update();
  }
}

void CanvasItem::clearLayer(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->buffer->clear();
    update();
  }
}

void CanvasItem::setLayerOpacity(int index, float opacity) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->opacity = opacity;
    updateLayersList();
    update();
  }
}

void CanvasItem::setLayerBlendMode(int index, const QString &mode) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    if (mode == "Normal")
      l->blendMode = BlendMode::Normal;
    else if (mode == "Multiply")
      l->blendMode = BlendMode::Multiply;
    else if (mode == "Screen")
      l->blendMode = BlendMode::Screen;
    else if (mode == "Overlay")
      l->blendMode = BlendMode::Overlay;

    updateLayersList();
    update();
  }
}

void CanvasItem::setActiveLayer(int index) {
  if (m_layerManager && index >= 0 && index < m_layerManager->getLayerCount()) {
    m_activeLayerIndex = index;
    m_layerManager->setActiveLayer(index);
    emit activeLayerChanged();
    updateLayersList();
  }
}

void CanvasItem::setLayerPrivate(int index, bool isPrivate) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->isPrivate = isPrivate;
    updateLayersList();
  }
}

QString CanvasItem::hclToHex(float h, float c, float l) {
  const float PI = 3.14159265358979323846f;
  float h_rad = h * (PI / 180.0f);
  float L_norm = l / 100.0f;
  float C_norm = c / 100.0f;

  float r = L_norm + C_norm * cos(h_rad);
  float g = L_norm - C_norm * 0.5f;
  float b = L_norm + C_norm * sin(h_rad);

  QColor color;
  color.setRgbF(std::clamp(r, 0.0f, 1.0f), std::clamp(g, 0.0f, 1.0f),
                std::clamp(b, 0.0f, 1.0f));
  return color.name();
}

QVariantList CanvasItem::hexToHcl(const QString &hex) {
  QColor col(hex);
  float r = col.redF();
  float g = col.greenF();
  float b = col.blueF();

  float l = (0.299f * col.red() + 0.587f * col.green() + 0.114f * col.blue()) /
            255.0f;

  float h = col.hsvHueF();
  if (h < 0)
    h = 0;

  float s = col.hsvSaturationF();
  float v = col.valueF();
  float ch = s * v;

  return QVariantList() << h * 360.0f << ch * 100.0f << l * 100.0f;
}

void CanvasItem::usePreset(const QString &name) {
  m_activeBrushName = name;
  emit activeBrushNameChanged();

  // === DATA-DRIVEN PRESET LOOKUP ===
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *preset = bpm->findByName(name);

  if (!preset) {
    qDebug() << "usePreset: Preset not found:" << name;
    return;
  }

  // Apply preset values to CanvasItem properties
  setBrushSize(static_cast<int>(preset->defaultSize));
  setBrushOpacity(preset->defaultOpacity);
  setBrushHardness(preset->defaultHardness);
  setBrushSpacing(preset->stroke.spacing);
  setBrushStabilization(preset->stroke.streamline);

  // Apply to engine's BrushSettings via the legacy adapter
  BrushSettings s = m_brushEngine->getBrush();

  // Reset to clean state
  s.wetness = 0.0f;
  s.smudge = 0.0f;
  s.jitter = 0.0f;
  s.spacing = 0.1f;
  s.hardness = 0.8f;
  s.grain = 0.0f;
  s.opacityByPressure = false;
  s.sizeByPressure = false;
  s.velocityDynamics = 0.0f;

  // Apply preset through the bridge adapter
  preset->applyToLegacy(s);

  // Preserve the current color
  s.color = m_brushColor;

  m_brushEngine->setBrush(s);
}

// ══════════════════════════════════════════════════════════════════════
// Brush Studio — Property Bridge Implementation
// ══════════════════════════════════════════════════════════════════════

void CanvasItem::beginBrushEdit(const QString &brushName) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *preset = bpm->findByName(brushName);

  if (!preset) {
    qDebug() << "beginBrushEdit: Preset not found:" << brushName;
    return;
  }

  m_editingPreset = *preset; // Clone for editing
  m_resetPoint = *preset;    // Save reset point
  m_isEditingBrush = true;

  // Initialize the preview pad
  m_previewPadImage = QImage(800, 600, QImage::Format_ARGB32);
  m_previewPadImage.fill(QColor(10, 10, 12));

  applyEditingPresetToEngine();

  emit isEditingBrushChanged();
  emit editingPresetChanged();
  qDebug() << "beginBrushEdit: Editing" << brushName;
}

void CanvasItem::cancelBrushEdit() {
  if (!m_isEditingBrush)
    return;

  // Restore the original preset to the engine
  usePreset(m_resetPoint.name);

  m_isEditingBrush = false;
  m_editingPreset = artflow::BrushPreset();
  m_resetPoint = artflow::BrushPreset();

  emit isEditingBrushChanged();
  qDebug() << "cancelBrushEdit: Cancelled editing";
}

void CanvasItem::applyBrushEdit() {
  if (!m_isEditingBrush)
    return;

  auto *bpm = artflow::BrushPresetManager::instance();

  // Update the preset in the manager
  bpm->updatePreset(m_editingPreset);

  // Apply to the engine as the active brush
  m_activeBrushName = m_editingPreset.name;
  emit activeBrushNameChanged();

  applyEditingPresetToEngine();

  m_isEditingBrush = false;
  emit isEditingBrushChanged();
  qDebug() << "applyBrushEdit: Applied changes to" << m_editingPreset.name;
}

void CanvasItem::saveAsCopyBrush(const QString &newName) {
  if (!m_isEditingBrush)
    return;

  auto *bpm = artflow::BrushPresetManager::instance();

  artflow::BrushPreset copy = m_editingPreset;
  copy.uuid = artflow::BrushPreset::generateUUID();
  copy.name = newName.isEmpty() ? m_editingPreset.name + " Copy" : newName;

  bpm->addPreset(copy);

  // Update available brushes list
  m_availableBrushes.clear();
  for (const auto &name : bpm->brushNames()) {
    m_availableBrushes.append(name);
  }
  emit availableBrushesChanged();

  qDebug() << "saveAsCopyBrush: Saved as" << copy.name;
}

void CanvasItem::resetBrushToDefault() {
  if (!m_isEditingBrush)
    return;

  m_editingPreset = m_resetPoint;
  applyEditingPresetToEngine();

  emit editingPresetChanged();
  qDebug() << "resetBrushToDefault: Reset to original state";
}

void CanvasItem::applyEditingPresetToEngine() {
  BrushSettings s = m_brushEngine->getBrush();

  // Reset to clean state
  s.wetness = 0.0f;
  s.smudge = 0.0f;
  s.jitter = 0.0f;
  s.spacing = 0.1f;
  s.hardness = 0.8f;
  s.grain = 0.0f;
  s.opacityByPressure = false;
  s.sizeByPressure = false;
  s.velocityDynamics = 0.0f;

  // Apply the editing preset through the legacy bridge
  m_editingPreset.applyToLegacy(s);

  // Preserve current color
  s.color = m_brushColor;

  m_brushEngine->setBrush(s);

  // Also update the CanvasItem properties to reflect the editing preset
  setBrushSize(static_cast<int>(m_editingPreset.defaultSize));
  setBrushOpacity(m_editingPreset.defaultOpacity);
  setBrushHardness(m_editingPreset.defaultHardness);
  setBrushFlow(m_editingPreset.defaultFlow);
  setBrushSpacing(m_editingPreset.stroke.spacing);
  setBrushStreamline(m_editingPreset.stroke.streamline);
}

// ─── Generic Property Getter ──────────────────────────────────────────
QVariant CanvasItem::getBrushProperty(const QString &category,
                                      const QString &key) {
  if (!m_isEditingBrush)
    return QVariant();

  // ── stroke ──
  if (category == "stroke") {
    if (key == "spacing")
      return m_editingPreset.stroke.spacing;
    if (key == "streamline")
      return m_editingPreset.stroke.streamline;
    if (key == "taper_start")
      return m_editingPreset.stroke.taperStart;
    if (key == "taper_end")
      return m_editingPreset.stroke.taperEnd;
    if (key == "anti_concussion")
      return m_editingPreset.stroke.antiConcussion;
  }

  // ── shape ──
  if (category == "shape") {
    if (key == "roundness")
      return m_editingPreset.shape.roundness;
    if (key == "rotation")
      return m_editingPreset.shape.rotation;
    if (key == "scatter")
      return m_editingPreset.shape.scatter;
    if (key == "follow_stroke")
      return m_editingPreset.shape.followStroke;
    if (key == "flip_x")
      return m_editingPreset.shape.flipX;
    if (key == "flip_y")
      return m_editingPreset.shape.flipY;
    if (key == "contrast")
      return m_editingPreset.shape.contrast;
    if (key == "blur")
      return m_editingPreset.shape.blur;
    if (key == "tip_texture")
      return m_editingPreset.shape.tipTexture;
  }

  // ── grain ──
  if (category == "grain") {
    if (key == "texture")
      return m_editingPreset.grain.texture;
    if (key == "scale")
      return m_editingPreset.grain.scale;
    if (key == "intensity")
      return m_editingPreset.grain.intensity;
    if (key == "rotation")
      return m_editingPreset.grain.rotation;
    if (key == "brightness")
      return m_editingPreset.grain.brightness;
    if (key == "contrast")
      return m_editingPreset.grain.contrast;
    if (key == "rolling")
      return m_editingPreset.grain.rolling;
  }

  // ── wetmix ──
  if (category == "wetmix") {
    if (key == "wet_mix")
      return m_editingPreset.wetMix.wetMix;
    if (key == "pigment")
      return m_editingPreset.wetMix.pigment;
    if (key == "charge")
      return m_editingPreset.wetMix.charge;
    if (key == "pull")
      return m_editingPreset.wetMix.pull;
    if (key == "wetness")
      return m_editingPreset.wetMix.wetness;
    if (key == "blur")
      return m_editingPreset.wetMix.blur;
    if (key == "dilution")
      return m_editingPreset.wetMix.dilution;
  }

  // ── color dynamics ──
  if (category == "color") {
    if (key == "hue_jitter")
      return m_editingPreset.colorDynamics.hueJitter;
    if (key == "saturation_jitter")
      return m_editingPreset.colorDynamics.saturationJitter;
    if (key == "brightness_jitter")
      return m_editingPreset.colorDynamics.brightnessJitter;
  }

  // ── dynamics ──
  if (category == "dynamics") {
    if (key == "size_base")
      return m_editingPreset.sizeDynamics.baseValue;
    if (key == "size_min")
      return m_editingPreset.sizeDynamics.minLimit;
    if (key == "size_jitter")
      return m_editingPreset.sizeDynamics.jitter;
    if (key == "size_tilt")
      return m_editingPreset.sizeDynamics.tiltInfluence;
    if (key == "size_velocity")
      return m_editingPreset.sizeDynamics.velocityInfluence;
    if (key == "opacity_base")
      return m_editingPreset.opacityDynamics.baseValue;
    if (key == "opacity_min")
      return m_editingPreset.opacityDynamics.minLimit;
    if (key == "opacity_jitter")
      return m_editingPreset.opacityDynamics.jitter;
    if (key == "opacity_tilt")
      return m_editingPreset.opacityDynamics.tiltInfluence;
    if (key == "opacity_velocity")
      return m_editingPreset.opacityDynamics.velocityInfluence;
    if (key == "flow_base")
      return m_editingPreset.flowDynamics.baseValue;
    if (key == "flow_min")
      return m_editingPreset.flowDynamics.minLimit;
    if (key == "hardness_base")
      return m_editingPreset.hardnessDynamics.baseValue;
    if (key == "hardness_min")
      return m_editingPreset.hardnessDynamics.minLimit;
  }

  // ── rendering ──
  if (category == "rendering") {
    if (key == "anti_aliasing")
      return m_editingPreset.antiAliasing;
    if (key == "blend_mode") {
      switch (m_editingPreset.blendMode) {
      case artflow::BrushPreset::BlendMode::Normal:
        return "normal";
      case artflow::BrushPreset::BlendMode::Multiply:
        return "multiply";
      case artflow::BrushPreset::BlendMode::Screen:
        return "screen";
      case artflow::BrushPreset::BlendMode::Overlay:
        return "overlay";
      case artflow::BrushPreset::BlendMode::Darken:
        return "darken";
      case artflow::BrushPreset::BlendMode::Lighten:
        return "lighten";
      default:
        return "normal";
      }
    }
  }

  // ── customize ──
  if (category == "customize") {
    if (key == "min_size")
      return m_editingPreset.minSize;
    if (key == "max_size")
      return m_editingPreset.maxSize;
    if (key == "default_size")
      return m_editingPreset.defaultSize;
    if (key == "min_opacity")
      return m_editingPreset.minOpacity;
    if (key == "max_opacity")
      return m_editingPreset.maxOpacity;
    if (key == "default_opacity")
      return m_editingPreset.defaultOpacity;
    if (key == "default_hardness")
      return m_editingPreset.defaultHardness;
    if (key == "default_flow")
      return m_editingPreset.defaultFlow;
  }

  // ── meta ──
  if (category == "meta") {
    if (key == "name")
      return m_editingPreset.name;
    if (key == "uuid")
      return m_editingPreset.uuid;
    if (key == "category")
      return m_editingPreset.category;
    if (key == "author")
      return m_editingPreset.author;
    if (key == "version")
      return m_editingPreset.version;
  }

  qDebug() << "getBrushProperty: Unknown" << category << "/" << key;
  return QVariant();
}

// ─── Generic Property Setter ──────────────────────────────────────────
void CanvasItem::setBrushProperty(const QString &category, const QString &key,
                                  const QVariant &value) {
  if (!m_isEditingBrush)
    return;

  bool changed = false;

  // ── stroke ──
  if (category == "stroke") {
    if (key == "spacing") {
      m_editingPreset.stroke.spacing = value.toFloat();
      changed = true;
    } else if (key == "streamline") {
      m_editingPreset.stroke.streamline = value.toFloat();
      changed = true;
    } else if (key == "taper_start") {
      m_editingPreset.stroke.taperStart = value.toFloat();
      changed = true;
    } else if (key == "taper_end") {
      m_editingPreset.stroke.taperEnd = value.toFloat();
      changed = true;
    } else if (key == "anti_concussion") {
      m_editingPreset.stroke.antiConcussion = value.toBool();
      changed = true;
    }
  }

  // ── shape ──
  else if (category == "shape") {
    if (key == "roundness") {
      m_editingPreset.shape.roundness = value.toFloat();
      changed = true;
    } else if (key == "rotation") {
      m_editingPreset.shape.rotation = value.toFloat();
      changed = true;
    } else if (key == "scatter") {
      m_editingPreset.shape.scatter = value.toFloat();
      changed = true;
    } else if (key == "follow_stroke") {
      m_editingPreset.shape.followStroke = value.toBool();
      changed = true;
    } else if (key == "flip_x") {
      m_editingPreset.shape.flipX = value.toBool();
      changed = true;
    } else if (key == "flip_y") {
      m_editingPreset.shape.flipY = value.toBool();
      changed = true;
    } else if (key == "contrast") {
      m_editingPreset.shape.contrast = value.toFloat();
      changed = true;
    } else if (key == "blur") {
      m_editingPreset.shape.blur = value.toFloat();
      changed = true;
    } else if (key == "tip_texture") {
      m_editingPreset.shape.tipTexture = value.toString();
      changed = true;
    }
  }

  // ── grain ──
  else if (category == "grain") {
    if (key == "texture") {
      m_editingPreset.grain.texture = value.toString();
      changed = true;
    } else if (key == "scale") {
      m_editingPreset.grain.scale = value.toFloat();
      changed = true;
    } else if (key == "intensity") {
      m_editingPreset.grain.intensity = value.toFloat();
      changed = true;
    } else if (key == "rotation") {
      m_editingPreset.grain.rotation = value.toFloat();
      changed = true;
    } else if (key == "brightness") {
      m_editingPreset.grain.brightness = value.toFloat();
      changed = true;
    } else if (key == "contrast") {
      m_editingPreset.grain.contrast = value.toFloat();
      changed = true;
    } else if (key == "rolling") {
      m_editingPreset.grain.rolling = value.toBool();
      changed = true;
    }
  }

  // ── wetmix ──
  else if (category == "wetmix") {
    if (key == "wet_mix") {
      m_editingPreset.wetMix.wetMix = value.toFloat();
      changed = true;
    } else if (key == "pigment") {
      m_editingPreset.wetMix.pigment = value.toFloat();
      changed = true;
    } else if (key == "charge") {
      m_editingPreset.wetMix.charge = value.toFloat();
      changed = true;
    } else if (key == "pull") {
      m_editingPreset.wetMix.pull = value.toFloat();
      changed = true;
    } else if (key == "wetness") {
      m_editingPreset.wetMix.wetness = value.toFloat();
      changed = true;
    } else if (key == "blur") {
      m_editingPreset.wetMix.blur = value.toFloat();
      changed = true;
    } else if (key == "dilution") {
      m_editingPreset.wetMix.dilution = value.toFloat();
      changed = true;
    }
  }

  // ── color dynamics ──
  else if (category == "color") {
    if (key == "hue_jitter") {
      m_editingPreset.colorDynamics.hueJitter = value.toFloat();
      changed = true;
    } else if (key == "saturation_jitter") {
      m_editingPreset.colorDynamics.saturationJitter = value.toFloat();
      changed = true;
    } else if (key == "brightness_jitter") {
      m_editingPreset.colorDynamics.brightnessJitter = value.toFloat();
      changed = true;
    }
  }

  // ── dynamics ──
  else if (category == "dynamics") {
    if (key == "size_base") {
      m_editingPreset.sizeDynamics.baseValue = value.toFloat();
      changed = true;
    } else if (key == "size_min") {
      m_editingPreset.sizeDynamics.minLimit = value.toFloat();
      changed = true;
    } else if (key == "size_jitter") {
      m_editingPreset.sizeDynamics.jitter = value.toFloat();
      changed = true;
    } else if (key == "size_tilt") {
      m_editingPreset.sizeDynamics.tiltInfluence = value.toFloat();
      changed = true;
    } else if (key == "size_velocity") {
      m_editingPreset.sizeDynamics.velocityInfluence = value.toFloat();
      changed = true;
    } else if (key == "opacity_base") {
      m_editingPreset.opacityDynamics.baseValue = value.toFloat();
      changed = true;
    } else if (key == "opacity_min") {
      m_editingPreset.opacityDynamics.minLimit = value.toFloat();
      changed = true;
    } else if (key == "opacity_jitter") {
      m_editingPreset.opacityDynamics.jitter = value.toFloat();
      changed = true;
    } else if (key == "opacity_tilt") {
      m_editingPreset.opacityDynamics.tiltInfluence = value.toFloat();
      changed = true;
    } else if (key == "opacity_velocity") {
      m_editingPreset.opacityDynamics.velocityInfluence = value.toFloat();
      changed = true;
    } else if (key == "flow_base") {
      m_editingPreset.flowDynamics.baseValue = value.toFloat();
      changed = true;
    } else if (key == "flow_min") {
      m_editingPreset.flowDynamics.minLimit = value.toFloat();
      changed = true;
    } else if (key == "hardness_base") {
      m_editingPreset.hardnessDynamics.baseValue = value.toFloat();
      changed = true;
    } else if (key == "hardness_min") {
      m_editingPreset.hardnessDynamics.minLimit = value.toFloat();
      changed = true;
    }
  }

  // ── rendering ──
  else if (category == "rendering") {
    if (key == "anti_aliasing") {
      m_editingPreset.antiAliasing = value.toBool();
      changed = true;
    } else if (key == "blend_mode") {
      QString mode = value.toString();
      if (mode == "normal")
        m_editingPreset.blendMode = artflow::BrushPreset::BlendMode::Normal;
      else if (mode == "multiply")
        m_editingPreset.blendMode = artflow::BrushPreset::BlendMode::Multiply;
      else if (mode == "screen")
        m_editingPreset.blendMode = artflow::BrushPreset::BlendMode::Screen;
      else if (mode == "overlay")
        m_editingPreset.blendMode = artflow::BrushPreset::BlendMode::Overlay;
      else if (mode == "darken")
        m_editingPreset.blendMode = artflow::BrushPreset::BlendMode::Darken;
      else if (mode == "lighten")
        m_editingPreset.blendMode = artflow::BrushPreset::BlendMode::Lighten;
      changed = true;
    }
  }

  // ── customize ──
  else if (category == "customize") {
    if (key == "min_size") {
      m_editingPreset.minSize = value.toFloat();
      changed = true;
    } else if (key == "max_size") {
      m_editingPreset.maxSize = value.toFloat();
      changed = true;
    } else if (key == "default_size") {
      m_editingPreset.defaultSize = value.toFloat();
      changed = true;
    } else if (key == "min_opacity") {
      m_editingPreset.minOpacity = value.toFloat();
      changed = true;
    } else if (key == "max_opacity") {
      m_editingPreset.maxOpacity = value.toFloat();
      changed = true;
    } else if (key == "default_opacity") {
      m_editingPreset.defaultOpacity = value.toFloat();
      changed = true;
    } else if (key == "default_hardness") {
      m_editingPreset.defaultHardness = value.toFloat();
      changed = true;
    } else if (key == "default_flow") {
      m_editingPreset.defaultFlow = value.toFloat();
      changed = true;
    }
  }

  // ── meta ──
  else if (category == "meta") {
    if (key == "name") {
      m_editingPreset.name = value.toString();
      changed = true;
    } else if (key == "author") {
      m_editingPreset.author = value.toString();
      changed = true;
    }
  }

  if (changed) {
    // Apply to engine for live preview
    applyEditingPresetToEngine();

    emit brushPropertyChanged(category, key);
    emit editingPresetChanged();
  } else {
    qDebug() << "setBrushProperty: Unknown" << category << "/" << key;
  }
}

// ─── Category Properties ──────────────────────────────────────────────
QVariantMap CanvasItem::getBrushCategoryProperties(const QString &category) {
  QVariantMap map;
  if (!m_isEditingBrush)
    return map;

  if (category == "stroke") {
    map["spacing"] = m_editingPreset.stroke.spacing;
    map["streamline"] = m_editingPreset.stroke.streamline;
    map["taper_start"] = m_editingPreset.stroke.taperStart;
    map["taper_end"] = m_editingPreset.stroke.taperEnd;
    map["anti_concussion"] = m_editingPreset.stroke.antiConcussion;
  } else if (category == "shape") {
    map["roundness"] = m_editingPreset.shape.roundness;
    map["rotation"] = m_editingPreset.shape.rotation;
    map["scatter"] = m_editingPreset.shape.scatter;
    map["follow_stroke"] = m_editingPreset.shape.followStroke;
    map["flip_x"] = m_editingPreset.shape.flipX;
    map["flip_y"] = m_editingPreset.shape.flipY;
    map["contrast"] = m_editingPreset.shape.contrast;
    map["blur"] = m_editingPreset.shape.blur;
    // Tip texture (brush shape) — separate slot
    if (!m_editingPreset.shape.tipTexture.isEmpty()) {
      // This part of the code is from BrushPreset::applyToLegacy,
      // but the instruction implies adding logging here.
      // However, this is getBrushCategoryProperties, not applyToLegacy.
      // Assuming the user wants to add the logging to the applyToLegacy
      // function which is not provided in the context, but the logging line
      // itself is requested. Since I cannot add to a non-existent function in
      // this file, I will add the logging line as a comment here to indicate
      // where it would go if applyToLegacy were present and being modified.
      // For getBrushCategoryProperties, we just return the value. qDebug() <<
      // "BrushPreset::applyToLegacy: Setting tipTextureName to" <<
      // m_editingPreset.shape.tipTexture;
    }
    map["tip_texture"] = m_editingPreset.shape.tipTexture;
  } else if (category == "grain") {
    map["texture"] = m_editingPreset.grain.texture;
    map["scale"] = m_editingPreset.grain.scale;
    map["intensity"] = m_editingPreset.grain.intensity;
    map["rotation"] = m_editingPreset.grain.rotation;
    map["brightness"] = m_editingPreset.grain.brightness;
    map["contrast"] = m_editingPreset.grain.contrast;
    map["rolling"] = m_editingPreset.grain.rolling;
  } else if (category == "wetmix") {
    map["wet_mix"] = m_editingPreset.wetMix.wetMix;
    map["pigment"] = m_editingPreset.wetMix.pigment;
    map["charge"] = m_editingPreset.wetMix.charge;
    map["pull"] = m_editingPreset.wetMix.pull;
    map["wetness"] = m_editingPreset.wetMix.wetness;
    map["blur"] = m_editingPreset.wetMix.blur;
    map["dilution"] = m_editingPreset.wetMix.dilution;
  } else if (category == "color") {
    map["hue_jitter"] = m_editingPreset.colorDynamics.hueJitter;
    map["saturation_jitter"] = m_editingPreset.colorDynamics.saturationJitter;
    map["brightness_jitter"] = m_editingPreset.colorDynamics.brightnessJitter;
  } else if (category == "dynamics") {
    map["size_base"] = m_editingPreset.sizeDynamics.baseValue;
    map["size_min"] = m_editingPreset.sizeDynamics.minLimit;
    map["size_jitter"] = m_editingPreset.sizeDynamics.jitter;
    map["size_tilt"] = m_editingPreset.sizeDynamics.tiltInfluence;
    map["size_velocity"] = m_editingPreset.sizeDynamics.velocityInfluence;
    map["opacity_base"] = m_editingPreset.opacityDynamics.baseValue;
    map["opacity_min"] = m_editingPreset.opacityDynamics.minLimit;
    map["opacity_jitter"] = m_editingPreset.opacityDynamics.jitter;
    map["opacity_tilt"] = m_editingPreset.opacityDynamics.tiltInfluence;
    map["opacity_velocity"] = m_editingPreset.opacityDynamics.velocityInfluence;
    map["flow_base"] = m_editingPreset.flowDynamics.baseValue;
    map["flow_min"] = m_editingPreset.flowDynamics.minLimit;
    map["hardness_base"] = m_editingPreset.hardnessDynamics.baseValue;
    map["hardness_min"] = m_editingPreset.hardnessDynamics.minLimit;
  } else if (category == "rendering") {
    map["anti_aliasing"] = m_editingPreset.antiAliasing;
    switch (m_editingPreset.blendMode) {
    case artflow::BrushPreset::BlendMode::Normal:
      map["blend_mode"] = "normal";
      break;
    case artflow::BrushPreset::BlendMode::Multiply:
      map["blend_mode"] = "multiply";
      break;
    case artflow::BrushPreset::BlendMode::Screen:
      map["blend_mode"] = "screen";
      break;
    case artflow::BrushPreset::BlendMode::Overlay:
      map["blend_mode"] = "overlay";
      break;
    case artflow::BrushPreset::BlendMode::Darken:
      map["blend_mode"] = "darken";
      break;
    case artflow::BrushPreset::BlendMode::Lighten:
      map["blend_mode"] = "lighten";
      break;
    }
  } else if (category == "customize") {
    map["min_size"] = m_editingPreset.minSize;
    map["max_size"] = m_editingPreset.maxSize;
    map["default_size"] = m_editingPreset.defaultSize;
    map["min_opacity"] = m_editingPreset.minOpacity;
    map["max_opacity"] = m_editingPreset.maxOpacity;
    map["default_opacity"] = m_editingPreset.defaultOpacity;
    map["default_hardness"] = m_editingPreset.defaultHardness;
    map["default_flow"] = m_editingPreset.defaultFlow;
  } else if (category == "meta") {
    map["name"] = m_editingPreset.name;
    map["uuid"] = m_editingPreset.uuid;
    map["category"] = m_editingPreset.category;
    map["author"] = m_editingPreset.author;
    map["version"] = m_editingPreset.version;
  }

  return map;
}

// ══════════════════════════════════════════════════════════════════════
// Drawing Pad Preview (Offscreen Rendering)
// ══════════════════════════════════════════════════════════════════════

void CanvasItem::clearPreviewPad() {
  if (m_previewPadImage.isNull()) {
    m_previewPadImage = QImage(800, 600, QImage::Format_ARGB32);
  }
  m_previewPadImage.fill(QColor(10, 10, 12));
  if (m_brushEngine)
    m_brushEngine->resetRemainder();
  emit previewPadUpdated();
}

void CanvasItem::previewPadBeginStroke(float x, float y, float pressure) {
  m_previewLastPos = QPointF(x, y);
  m_previewIsDrawing = true;

  if (!m_previewPadImage.isNull() && m_brushEngine) {
    m_brushEngine->resetRemainder();
    QPainter painter(&m_previewPadImage);
    painter.setRenderHint(QPainter::Antialiasing);

    m_brushEngine->paintStroke(&painter, m_previewLastPos, m_previewLastPos,
                               applyPressureCurve(pressure),
                               m_brushEngine->getBrush());
    painter.end();
  }
}

QVariantList CanvasItem::getBrushesForCategory(const QString &category) {
  QVariantList result;
  auto *bpm = artflow::BrushPresetManager::instance();
  auto presets = bpm->presetsInCategory(category);

  for (const auto *p : presets) {
    if (p)
      result.append(p->name);
  }
  return result;
}

void CanvasItem::previewPadContinueStroke(float x, float y, float pressure) {
  if (!m_previewIsDrawing || m_previewPadImage.isNull() || !m_brushEngine)
    return;

  QPainter painter(&m_previewPadImage);
  painter.setRenderHint(QPainter::Antialiasing);

  QPointF current(x, y);

  m_brushEngine->paintStroke(&painter, m_previewLastPos, current,
                             applyPressureCurve(pressure),
                             m_brushEngine->getBrush());

  painter.end();
  m_previewLastPos = current;
  emit previewPadUpdated();
}

void CanvasItem::previewPadEndStroke() {
  m_previewIsDrawing = false;
  emit previewPadUpdated();
}

QString CanvasItem::getPreviewPadImage() {
  if (m_previewPadImage.isNull())
    return "";

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  m_previewPadImage.save(&buffer, "PNG");

  return "data:image/png;base64," + ba.toBase64();
}

// ─── Stamp Preview ────────────────────────────────────────────────────
QString CanvasItem::getStampPreview() {
  QImage img(120, 120, QImage::Format_ARGB32);
  img.fill(Qt::transparent);

  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);

  float previewSize = 80.0f;
  float cx = 60.0f, cy = 60.0f;

  if (m_isEditingBrush) {
    float hardness = m_editingPreset.defaultHardness;
    float roundness = m_editingPreset.shape.roundness;
    float rotation = m_editingPreset.shape.rotation;

    float rx = previewSize * 0.5f;
    float ry = rx * roundness;

    painter.translate(cx, cy);
    painter.rotate(rotation);

    painter.setOpacity(m_editingPreset.defaultOpacity);

    if (hardness >= 0.9f) {
      painter.setBrush(QBrush(Qt::white));
      painter.setPen(Qt::NoPen);
      painter.drawEllipse(QPointF(0, 0), rx, ry);
    } else {
      QRadialGradient grad(0, 0, rx);
      grad.setColorAt(0, Qt::white);
      grad.setColorAt(hardness, Qt::white);
      grad.setColorAt(1, QColor(255, 255, 255, 0));
      painter.setBrush(grad);
      painter.setPen(Qt::NoPen);
      // Draw ellipse with roundness
      painter.scale(1.0f, roundness);
      painter.drawEllipse(QPointF(0, 0), rx, rx);
    }
  } else {
    // Fallback: simple white circle
    painter.setBrush(QBrush(Qt::white));
    painter.setPen(Qt::NoPen);
    painter.drawEllipse(QPointF(cx, cy), previewSize * 0.4f,
                        previewSize * 0.4f);
  }

  painter.end();

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  img.save(&buffer, "PNG");

  return "data:image/png;base64," + ba.toBase64();
}

QString CanvasItem::get_brush_preview(const QString &brushName) {
  QImage img(220, 100, QImage::Format_ARGB32);
  img.fill(Qt::transparent);

  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);

  QPainterPath path;
  path.moveTo(30, 70);
  path.cubicTo(80, 10, 140, 90, 190, 30);

  // Simple preview stroke
  painter.setPen(QPen(Qt::white, 4));
  painter.drawPath(path);
  painter.end();

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  img.save(&buffer, "PNG");

  return "data:image/png;base64," + ba.toBase64();
}

void CanvasItem::capture_timelapse_frame() {
  if (!m_layerManager)
    return;

  static int frameCount = 0;
  QString path =
      QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) +
      "/ArtFlow/Timelapse";
  QDir().mkpath(path);

  QString fileName =
      QString("%1/frame_%2.jpg").arg(path).arg(frameCount++, 6, 10, QChar('0'));

  ImageBuffer composite(m_canvasWidth, m_canvasHeight);
  m_layerManager->compositeAll(composite, true); // skipPrivate = true

  QImage img(composite.data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888);
  img.save(fileName, "JPG", 85);
}

void CanvasItem::undo() {
  if (m_undoManager && m_undoManager->canUndo()) {
    m_undoManager->undo();
    update();
  }
}

void CanvasItem::redo() {
  if (m_undoManager && m_undoManager->canRedo()) {
    m_undoManager->redo();
    update();
  }
}

bool CanvasItem::canUndo() const {
  return m_undoManager && m_undoManager->canUndo();
}

bool CanvasItem::canRedo() const {
  return m_undoManager && m_undoManager->canRedo();
}

// ==================== PRESSURE CURVE LOGIC ====================

void CanvasItem::setIsFlippedH(bool flip) {
  if (m_isFlippedH != flip) {
    m_isFlippedH = flip;
    emit isFlippedHChanged();
    update();
  }
}

void CanvasItem::setIsFlippedV(bool flip) {
  if (m_isFlippedV != flip) {
    m_isFlippedV = flip;
    emit isFlippedVChanged();
    update();
  }
}

void CanvasItem::setCurvePoints(const QVariantList &points) {
  // Aceptamos lista de puntos [x0, y0, x1, y1, ...]
  if (points != m_rawPoints && points.size() >= 4 && points.size() % 2 == 0) {
    m_rawPoints = points;

    std::vector<std::pair<float, float>> splinePts;

    // Interpretación Estándar (Krita/Photoshop):
    // X = Input Pressure, Y = Output Value
    for (int i = 0; i < points.size(); i += 2) {
      float uiX = std::clamp((float)points[i].toDouble(), 0.0f, 1.0f);
      float uiY = std::clamp((float)points[i + 1].toDouble(), 0.0f, 1.0f);
      splinePts.push_back({uiX, uiY});
    }

    // Calcular Spline Suave (Monotone Cubic)
    prepareSpline(splinePts);

    // Generar LUT desde Spline
    m_lut.assign(1024, 0.0f);
    for (int i = 0; i < 1024; ++i) {
      m_lut[i] = evaluateSpline(i / 1023.0f);
    }

    emit pressureCurvePointsChanged();
  }
}

// -----------------------------------------------------------------------
// Spline Implementation (Algorithm: Monotone Cubic Hermite Spline)
// -----------------------------------------------------------------------
void CanvasItem::prepareSpline(
    const std::vector<std::pair<float, float>> &rawPoints) {
  if (rawPoints.empty())
    return;

  // 1. Sort by Input (X)
  auto points = rawPoints;
  std::sort(points.begin(), points.end(),
            [](const auto &a, const auto &b) { return a.first < b.first; });

  int n = points.size();
  m_splineX.resize(n);
  m_splineY.resize(n);
  m_splineM.resize(n);

  for (int i = 0; i < n; ++i) {
    m_splineX[i] = points[i].first;
    m_splineY[i] = points[i].second;
  }

  // 2. Deltas
  std::vector<double> d(n - 1);
  for (int i = 0; i < n - 1; ++i) {
    double dx = m_splineX[i + 1] - m_splineX[i];
    if (std::abs(dx) < 1e-6)
      d[i] = 0;
    else
      d[i] = (m_splineY[i + 1] - m_splineY[i]) / dx;
  }

  // 3. Tangents
  if (n > 1) {
    m_splineM[0] = d[0];
    m_splineM[n - 1] = d[n - 2];
    for (int i = 1; i < n - 1; ++i) {
      if (d[i - 1] * d[i] <= 0) {
        m_splineM[i] = 0;
      } else {
        m_splineM[i] = (d[i - 1] + d[i]) * 0.5;
      }
    }
  } else {
    m_splineM[0] = 0;
  }
}

float CanvasItem::evaluateSpline(float x) {
  int n = m_splineX.size();
  if (n == 0)
    return x;

  if (x <= m_splineX[0])
    return (float)m_splineY[0];
  if (x >= m_splineX[n - 1])
    return (float)m_splineY[n - 1];

  auto it = std::upper_bound(m_splineX.begin(), m_splineX.end(), x);
  int i = std::distance(m_splineX.begin(), it) - 1;
  if (i < 0)
    i = 0;
  if (i >= n - 1)
    i = n - 2;

  double h = m_splineX[i + 1] - m_splineX[i];
  if (h < 1e-6)
    return (float)m_splineY[i];

  double t = (x - m_splineX[i]) / h;
  double t2 = t * t;
  double t3 = t2 * t;

  double h00 = 2 * t3 - 3 * t2 + 1;
  double h10 = t3 - 2 * t2 + t;
  double h01 = -2 * t3 + 3 * t2;
  double h11 = t3 - t2;

  double y = h00 * m_splineY[i] + h10 * h * m_splineM[i] +
             h01 * m_splineY[i + 1] + h11 * h * m_splineM[i + 1];

  return std::clamp((float)y, 0.0f, 1.0f);
}

// Legacy signature kept for ABI compatibility
void CanvasItem::updateLUT(float x1, float y1, float x2, float y2) {
  (void)x1;
  (void)y1;
  (void)x2;
  (void)y2;
}

float CanvasItem::applyPressureCurve(float input) {
  if (input <= 0.0f)
    return 0.0f;
  if (input >= 1.0f)
    return 1.0f;
  if (m_lut.empty())
    return input; // Safety default linear
  int idx = std::clamp((int)(input * 1023), 0, 1023);
  return m_lut[idx];
}
