// Re-verify includes
#include "CanvasItem.h"
#include "PreferencesManager.h"
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
      m_cursorRotation(0.0f), m_currentProjectPath(""),
      m_currentProjectName("Untitled"), m_brushTip("round"),
      m_lastPressure(1.0f), m_isDrawing(false),
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
  // Cargar curva de presión guardada (Persistencia)
  setCurvePoints(PreferencesManager::instance()->pressureCurve());
  m_activeLayerIndex = 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  m_availableBrushes << "Pencil HB" << "Pencil 6B" << "Ink Pen" << "Marker"
                     << "G-Pen" << "Maru Pen" << "Watercolor"
                     << "Watercolor Wet"
                     << "Oil Paint" << "Acrylic" << "The Blender"
                     << "Smudge Tool" << "Óleo Classic Flat"
                     << "Óleo Round Bristle"
                     << "Óleo Impasto Knife" << "Óleo Dry Scumble"
                     << "Óleo Wet Blender"
                     << "Soft" << "Hard"
                     << "Mechanical"
                     << "Eraser Soft" << "Eraser Hard";
  m_activeBrushName = "Pencil HB";
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
    paths << "e:/app_dibujo_proyecto-main/src/core/shaders/";

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

  // 2. Fondo Base (Workspace - Dark Gray)
  painter->fillRect(0, 0, width(), height(), QColor("#1e1e1e"));

  // Calculate generic target rect for background
  QRectF paperRect(m_viewOffset.x() * m_zoomLevel,
                   m_viewOffset.y() * m_zoomLevel, m_canvasWidth * m_zoomLevel,
                   m_canvasHeight * m_zoomLevel);

  // Draw Paper Background (White)
  painter->fillRect(paperRect, Qt::white);

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
                 layer->buffer->height(), QImage::Format_RGBA8888);

      // Rectángulo de destino con Zoom y Pan (Común)
      QRectF targetRect(
          m_viewOffset.x() * m_zoomLevel, m_viewOffset.y() * m_zoomLevel,
          m_canvasWidth * m_zoomLevel, m_canvasHeight * m_zoomLevel);

      // Intentar usar shaders (Impasto)
      bool useImpasto = false;
      // Deshabilitado temporalmente para evitar crash en rendering
      if (false && m_impastoShader && m_impastoShader->isLinked()) {
        useImpasto = true;
      }

      bool renderedWithShader = false;
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
                       m_viewOffset.x() * m_zoomLevel);
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
    QPen lassoPen(Qt::blue, 1, Qt::DashLine);
    painter->setPen(lassoPen);
    painter->drawPath(m_selectionPath);

    // Draw "Marching Ants" effect (simplified DashOffset animation if time
    // allows) For now, solid dash is enough for proof of concept
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
  // If the viewport is flipped, we must mirror the coordinate before passing to
  // engine
  if (m_isFlippedH) {
    canvasPos.setX(m_canvasWidth - canvasPos.x());
  }
  if (m_isFlippedV) {
    canvasPos.setY(m_canvasHeight - canvasPos.y());
  }

  BrushSettings settings = m_brushEngine->getBrush();
  float effectivePressure = pressure; // Ajustar con curva si es necesario
  float velocityFactor = 0.0f;        // Calcular velocidad real si es necesario

  // Create QImage wrapper around layer buffer
  QImage img(layer->buffer->data(), layer->buffer->width(),
             layer->buffer->height(), QImage::Format_RGBA8888);

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

      m_pingFBO = new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight);
      m_pongFBO = new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight);

      m_pingFBO->bind();
      QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
      QPainter fboPainter(&device);
      fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
      fboPainter.drawImage(0, 0, img);
      fboPainter.end();
      m_pingFBO->release();
    }

    // Copiar estado anterior (Ping -> Pong) de forma eficiente (Blit)
    // Esto evita descargar texturas de GPU a CPU (toImage estÃ¡ prohibido
    // aquÃ­)
    QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);

    m_pongFBO->bind();
    QOpenGLPaintDevice device2(m_canvasWidth, m_canvasHeight);
    QPainter fboPainter2(&device2);

    // Dibujar nuevo trazo sobre el fondo ya copiado
    fboPainter2.setCompositionMode(QPainter::CompositionMode_SourceOver);
    m_brushEngine->paintStroke(
        &fboPainter2, m_lastPos, canvasPos, effectivePressure, settings, tilt,
        velocityFactor, m_pingFBO->texture(), settings.wetness,
        settings.dilution, settings.smudge);
    fboPainter2.end();
    m_pongFBO->release();

    layer->dirty = true;
    std::swap(m_pingFBO, m_pongFBO);

    // Liberar contexto?? Causa parpadeo si lo hacemos?
    // Dejémoslo current, Qt lo manejará?
    // window()->openglContext()->doneCurrent();
  } else {
    // MODO ESTÁNDAR (Raster / Legacy)
    QPainter painter(&img);
    painter.setRenderHint(QPainter::Antialiasing);

    m_brushEngine->paintStroke(&painter, m_lastPos, canvasPos,
                               effectivePressure, settings, tilt,
                               velocityFactor);
    painter.end();
    layer->dirty = true;
  }

  // Calculate dirty rect for update (Screen coordinates)
  // We need to determine the bounding box in canvas coords, then map to screen.
  // Use lastCanvasPos (captured at start) to ensure we cover the whole segment
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
    m_selectionPath.moveTo(event->position());
    m_hasSelection = false;
    update();
    return;
  }

  if (m_tool == ToolType::Transform && m_isTransforming) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    QRectF transformedBox = m_transformMatrix.mapRect(m_transformBox);

    if (transformedBox.contains(canvasPos)) {
      m_transformMode = TransformMode::Move;
      m_transformStartPos = canvasPos;
      m_initialMatrix = m_transformMatrix;
      return;
    }
  }

  if (event->button() == Qt::LeftButton) {
    if (m_isDrawing)
      return; // Already drawing (tablet?)

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
    m_selectionPath.lineTo(event->position());
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
          QImage result =
              m_pingFBO->toImage().convertToFormat(QImage::Format_RGBA8888);
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
            m_pingFBO->toImage().convertToFormat(QImage::Format_RGBA8888);
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
    update(); // Refrescar vista
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
void CanvasItem::setCurrentTool(const QString &tool) {
  if (m_currentToolStr == tool)
    return;

  // Commit transformation if switching away from transform tool
  if (m_currentToolStr == "transform" && m_isTransforming) {
    commitTransform();
  }

  m_currentToolStr = tool;

  if (tool == "brush" || tool == "pen" || tool == "pencil" ||
      tool == "watercolor" || tool == "airbrush")
    m_tool = ToolType::Pen;
  else if (tool == "eraser")
    m_tool = ToolType::Eraser;
  else if (tool == "lasso")
    m_tool = ToolType::Lasso;
  if (tool == "transform") {
    m_tool = ToolType::Transform;
    if (m_hasSelection && !m_selectionPath.isEmpty()) {
      // Start transformation logic: copy selection to buffer
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer) {
        m_isTransforming = true;
        m_transformMatrix = QTransform();
        m_transformBox = m_selectionPath.boundingRect();

        // Capture selection to image
        QImage full(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                    QImage::Format_RGBA8888);
        m_selectionBuffer =
            QImage(m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888);
        m_selectionBuffer.fill(Qt::transparent);

        QPainter p(&m_selectionBuffer);
        p.setClipPath(m_selectionPath);
        p.drawImage(0, 0, full);
        p.end();

        // Clear selection area in original layer (destructive part for now)
        QPainter p2(&full);
        p2.setCompositionMode(QPainter::CompositionMode_Clear);
        p2.setClipPath(m_selectionPath);
        p2.fillRect(full.rect(), Qt::transparent);
        p2.end();

        layer->dirty = true;
      }
    }
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
               QImage::Format_RGBA8888);
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
  qDebug() << "Setting background color:" << color;
  // In a real app we'd update the bottom layer or a special background property
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
    if (i == m_activeLayerIndex || i == 0) {
      int tw = 60, th = 40;
      QImage full(l->buffer->data(), m_canvasWidth, m_canvasHeight,
                  QImage::Format_RGBA8888);
      QImage thumb =
          full.scaled(tw, th, Qt::KeepAspectRatio, Qt::SmoothTransformation);
      QByteArray ba;
      QBuffer buffer(&ba);
      buffer.open(QIODevice::WriteOnly);
      thumb.save(&buffer, "PNG");
      layer["thumbnail"] = "data:image/png;base64," + ba.toBase64();
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

  BrushSettings s = m_brushEngine->getBrush();
  // Reset all dynamics to defaults
  s.wetness = 0.0f;
  s.smudge = 0.0f;
  s.jitter = 0.0f;
  s.spacing = 0.1f;
  s.hardness = 0.8f;
  s.grain = 0.0f;
  s.opacityByPressure = false;
  s.sizeByPressure = false;
  s.velocityDynamics = 0.0f;

  // ==================== PENCIL PRESETS ====================
  if (name == "Pencil HB") {
    // Classic graphite pencil - medium hardness, subtle grain
    setBrushSize(8); // Slightly bigger default
    setBrushOpacity(0.7f);
    setBrushHardness(0.2f);
    setBrushSpacing(0.05f);
    setBrushStabilization(0.25f);
    s.type = BrushSettings::Type::Pencil;
    s.grain = 0.65f;
    s.opacityByPressure = true;
    s.sizeByPressure = true; // Enable size dynamics for better feel
    s.jitter = 0.08f;

    // Texture Config
    s.useTexture = true;
    s.textureName = "paper_grain.png";
    s.textureScale = 200.0f;
    s.textureIntensity = 0.6f;

  } else if (name == "Pencil 6B") {
    // Soft graphite - darker, more grain, softer edge
    setBrushSize(20);
    setBrushOpacity(0.9f);
    setBrushHardness(0.4f);
    setBrushSpacing(0.04f);
    setBrushStabilization(0.1f);
    s.type = BrushSettings::Type::Pencil;
    s.grain = 0.95f;
    s.opacityByPressure = true;
    s.sizeByPressure = true;
    s.jitter = 0.12f;

    // Texture Config
    s.useTexture = true;
    s.textureName = "paper_grain.png";
    s.textureScale = 200.0f;
    s.textureIntensity = 0.6f;

  } else if (name == "Mechanical") {
    // Precise mechanical pencil - Improved for realism
    setBrushSize(2.5f); // Thinner by default
    setBrushOpacity(0.95f);
    setBrushHardness(0.95f);
    setBrushSpacing(0.008f); // High density for smooth lines
    setBrushStabilization(0.3f);
    s.type = BrushSettings::Type::Pencil;
    s.grain = 0.85f; // High grain visibility
    s.opacityByPressure = true;
    s.sizeByPressure =
        true; // Real mechanical pencils have slight size dynamics
    s.jitter = 0.01f;

    // Texture Config (Paper grain)
    s.useTexture = true;
    s.textureName = "paper_grain.png";
    s.textureScale = 450.0f;    // Very fine grain
    s.textureIntensity = 0.75f; // Stronger interaction with grain
  }

  // ==================== INKING PRESETS ====================
  else if (name == "Ink Pen") {
    // Classic ink pen - smooth, pressure-sensitive size
    setBrushSize(12);
    setBrushOpacity(1.0f);
    setBrushHardness(1.0f);
    setBrushSpacing(0.015f);
    setBrushStabilization(0.75f);
    s.type = BrushSettings::Type::Ink;
    s.sizeByPressure = true;
    s.velocityDynamics = -0.2f; // Slightly thinner when drawing fast
  } else if (name == "G-Pen") {
    // Manga-style G-Pen - dramatic pressure taper
    setBrushSize(18);
    setBrushOpacity(1.0f);
    setBrushHardness(0.98f);
    setBrushSpacing(0.01f);
    setBrushStabilization(0.8f);
    s.type = BrushSettings::Type::Ink;
    s.sizeByPressure = true;
    s.velocityDynamics = -0.15f;
  } else if (name == "Maru Pen") {
    // Fine Maru pen - thin consistent lines
    setBrushSize(6);
    setBrushOpacity(1.0f);
    setBrushHardness(1.0f);
    setBrushSpacing(0.01f);
    setBrushStabilization(0.6f);
    s.type = BrushSettings::Type::Ink;
    s.sizeByPressure = true;
  } else if (name == "Marker") {
    // Alcohol marker - semi-transparent, builds up color
    setBrushSize(28);
    setBrushOpacity(0.35f);
    setBrushHardness(0.95f);
    setBrushSpacing(0.03f);
    setBrushStabilization(0.15f);
    s.type = BrushSettings::Type::Round;
    s.opacityByPressure = true;
  }

  // ==================== WATERCOLOR PRESETS ====================
  else if (name == "Watercolor") {
    // Classic watercolor - soft edges, pigment granulation
    setBrushSize(50);
    setBrushOpacity(0.3f);
    setBrushHardness(0.15f);
    setBrushSpacing(0.08f);
    setBrushStabilization(0.45f);
    s.type = BrushSettings::Type::Watercolor;
    s.wetness = 0.5f; // Medium wet
    s.grain = 0.12f;  // Pigment granulation
    s.jitter = 0.06f; // Organic edge

    // Texture Config
    s.useTexture = true;
    s.textureName = "watercolor_paper.png";
    s.textureScale = 80.0f;
    s.textureIntensity = 0.5f;

  } else if (name == "Watercolor Wet") {
    // Wet-on-wet watercolor - very soft, bleeds
    setBrushSize(60);
    setBrushOpacity(0.25f);
    setBrushHardness(0.05f);
    setBrushSpacing(0.1f);
    setBrushStabilization(0.5f);
    s.type = BrushSettings::Type::Watercolor;
    s.wetness = 0.95f; // Very wet - color spreads
    s.jitter = 0.1f;   // More organic

    // Texture Config
    s.useTexture = true;
    s.textureName = "watercolor_paper.png";
    s.textureScale = 60.0f; // Larger soft variations
    s.textureIntensity = 0.4f;

  }

  // ==================== OIL/PAINTING PRESETS ====================
  else if (name == "Oil Paint") {
    // Thick oil paint - color mixing, textured strokes
    setBrushSize(40);
    setBrushOpacity(0.95f);
    setBrushHardness(0.75f);
    setBrushSpacing(0.015f);
    setBrushStabilization(0.35f);
    s.type = BrushSettings::Type::Oil;
    s.smudge = 0.4f; // Picks up underlying color
    s.grain = 0.6f;  // Canvas texture
    s.sizeByPressure = true;

    // Texture Config
    s.useTexture = true;
    s.textureName = "canvas_weave.png";
    s.textureScale = 150.0f;
    s.textureIntensity = 0.7f; // Strong texture

  } else if (name == "Acrylic") {
    // Acrylic - opaque, less mixing than oil
    setBrushSize(38);
    setBrushOpacity(0.98f);
    setBrushHardness(0.85f);
    setBrushSpacing(0.02f);
    setBrushStabilization(0.25f);
    s.type = BrushSettings::Type::Oil;
    s.smudge = 0.25f; // Less color pickup
    s.grain = 0.5f;   // Canvas texture
    s.sizeByPressure = true;

    // Texture Config
    s.useTexture = true;
    s.textureName = "canvas_weave.png";
    s.textureScale = 150.0f;
    s.textureIntensity = 0.5f;
  } else if (name == "The Blender") {
    // Pro Blender - High wetness, medium smudge for smooth gradients
    setBrushSize(50);
    setBrushOpacity(0.6f);
    setBrushHardness(0.5f);
    setBrushSpacing(0.02f);
    s.type = BrushSettings::Type::Oil;
    s.wetness = 0.8f;
    s.smudge = 0.3f;
    s.sizeByPressure = true;
  } else if (name == "Smudge Tool") {
    // Pure Smudge - High smudge, no new color (wash effect)
    setBrushSize(40);
    setBrushOpacity(1.0f);
    setBrushHardness(0.3f);
    setBrushSpacing(0.01f);
    s.type = BrushSettings::Type::Oil;
    s.wetness = 0.2f;
    s.smudge = 0.95f;
    s.sizeByPressure = true;
  } else if (name == "Óleo Classic Flat") {
    setBrushSize(60);
    setBrushOpacity(1.0f);
    setBrushHardness(0.9f);
    setBrushSpacing(0.04f);
    s.type = BrushSettings::Type::Oil;
    s.flow = 0.35f;
    s.wetness = 0.6f;
    s.smudge = 0.1f;
    // Impasto Logic (Simulated via Flow/Opacity accumulation in shader)

    s.useTexture = true;
    s.textureName = "oil_flat_pro.png"; // Pincel Plano
    s.textureScale = 1.0f;              // 1:1 map to brush tip
    s.textureIntensity = 1.0f;
    s.sizeByPressure = true;
    s.opacityByPressure = false;

  } else if (name == "Óleo Round Bristle") {
    setBrushSize(45);
    setBrushOpacity(0.95f);
    setBrushHardness(0.7f);
    setBrushSpacing(0.05f);
    s.type = BrushSettings::Type::Oil;
    s.flow = 0.4f;
    s.wetness = 0.75f;
    s.smudge = 0.2f;

    s.useTexture = true;
    s.textureName = "oil_filbert_pro.png"; // Pincel Filbert
    s.textureScale = 1.0f;
    s.textureIntensity = 1.0f;
    s.sizeByPressure = true;
    s.opacityByPressure = true;

  } else if (name == "Óleo Impasto Knife") {
    setBrushSize(80);
    setBrushOpacity(1.0f);
    s.flow = 0.8f;
    setBrushSpacing(0.02f); // Super denso
    setBrushHardness(1.0f);
    s.type = BrushSettings::Type::Oil;
    s.wetness = 0.1f; // Casi seco, solo arrastra masa
    s.smudge = 0.8f;  // Arrastre fuerte

    s.useTexture = true;
    s.textureName = "oil_knife_pro.png"; // Espátula
    s.textureScale = 1.0f;
    s.textureIntensity = 1.0f;
    s.sizeByPressure = false;
    s.opacityByPressure = false;

  } else if (name == "Óleo Dry Scumble") {
    setBrushSize(70);
    setBrushOpacity(0.8f);
    s.flow = 0.15f;
    setBrushSpacing(0.08f);
    setBrushHardness(0.5f);
    s.type = BrushSettings::Type::Oil;
    s.wetness = 0.0f;
    s.smudge = 0.1f;

    s.useTexture = true;
    s.textureName = "oil_flat_pro.png";
    s.textureScale = 1.0f;
    s.textureIntensity = 1.0f; // Max textura
    s.opacityByPressure = true;

  } else if (name == "Óleo Wet Blender") {
    setBrushSize(90);
    setBrushOpacity(0.0f); // Invisible, solo mueve
    s.flow = 0.5f;
    setBrushSpacing(0.04f);
    setBrushHardness(0.2f);
    s.type = BrushSettings::Type::Oil;
    s.wetness = 1.0f; // Max humedad
    s.smudge = 0.95f; // Max arrastre

    s.useTexture = true;
    s.textureName = "oil_filbert_pro.png";
    s.textureScale = 1.0f;
    s.textureIntensity = 0.5f;
    s.sizeByPressure = true;
  }

  // ==================== AIRBRUSH PRESETS ====================
  else if (name == "Soft") {
    // Soft airbrush - gradual buildup, very soft edges
    setBrushSize(100);
    setBrushOpacity(0.08f);
    setBrushHardness(0.0f);
    setBrushSpacing(0.15f);
    setBrushStabilization(0.1f);
    s.type = BrushSettings::Type::Airbrush;
    s.opacityByPressure = true;
  } else if (name == "Hard") {
    // Hard airbrush - defined edge, spatter effect
    setBrushSize(45);
    setBrushOpacity(0.2f);
    setBrushHardness(0.8f);
    setBrushSpacing(0.08f);
    setBrushStabilization(0.1f);
    s.type = BrushSettings::Type::Airbrush;
    s.jitter = 0.15f; // Spatter
    s.opacityByPressure = true;
  }

  // ==================== ERASER PRESETS ====================
  else if (name == "Eraser Soft") {
    // Soft eraser - gradual removal
    setBrushSize(45);
    setBrushOpacity(0.85f);
    setBrushHardness(0.15f);
    setBrushSpacing(0.08f);
    s.type = BrushSettings::Type::Eraser;
  } else if (name == "Eraser Hard") {
    // Hard eraser - precise removal
    setBrushSize(22);
    setBrushOpacity(1.0f);
    setBrushHardness(0.98f);
    setBrushSpacing(0.03f);
    s.type = BrushSettings::Type::Eraser;
  }

  m_brushEngine->setBrush(s);
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
