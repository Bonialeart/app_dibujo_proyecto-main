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
      m_zoomLevel(1.0f), m_currentTool("brush"), m_canvasWidth(1920),
      m_canvasHeight(1080), m_viewOffset(50, 50), m_activeLayerIndex(0),
      m_isTransforming(false), m_brushAngle(0.0f), m_cursorRotation(0.0f),
      m_currentProjectPath(""), m_currentProjectName("Untitled"),
      m_brushTip("round"), m_lastPressure(1.0f), m_isDrawing(false),
      m_brushEngine(new BrushEngine()) {
  setAcceptHoverEvents(true);
  setAcceptedMouseButtons(Qt::AllButtons);
  setAcceptTouchEvents(true);
  setRenderTarget(QQuickPaintedItem::FramebufferObject);

  // Enable tablet tracking for high-frequency events
  // Note: QQuickItem doesn't have setAttribute(Qt::WA_TabletTracking) directly
  // but acts as if it's on.

  m_layerManager = new LayerManager(m_canvasWidth, m_canvasHeight);
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

  // 2. Fondo Base
  painter->fillRect(0, 0, width(), height(), Qt::white);

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
}

void CanvasItem::handleDraw(const QPointF &pos, float pressure, float tilt) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->visible || layer->locked)
    return;

  // Convertir posición de pantalla a canvas
  // Aplicar transformación inversa: (Screen - Offset*Zoom) / Zoom
  QPointF canvasPos = (pos - m_viewOffset * m_zoomLevel) / m_zoomLevel;

  BrushSettings settings = m_brushEngine->getBrush();
  float effectivePressure = pressure; // Ajustar con curva si es necesario
  float velocityFactor = 0.0f;        // Calcular velocidad real si es necesario

  // Create QImage wrapper around layer buffer
  QImage img(layer->buffer->data(), layer->buffer->width(),
             layer->buffer->height(), QImage::Format_RGBA8888);

  // MODO PREMIUM (OpenGL / Shaders)
  // Revisar si tenemos contexto OpenGL disponible
  bool glReady = (QOpenGLContext::currentContext() != nullptr);

  if (glReady && (settings.useTexture || settings.wetness > 0.01f)) {
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

    m_pongFBO->bind();
    QOpenGLPaintDevice device2(m_canvasWidth, m_canvasHeight);
    QPainter fboPainter2(&device2);
    // Copiar estado anterior
    fboPainter2.setCompositionMode(QPainter::CompositionMode_Source);
    fboPainter2.drawImage(0, 0, m_pingFBO->toImage());

    // Dibujar nuevo trazo
    fboPainter2.setCompositionMode(QPainter::CompositionMode_SourceOver);
    m_brushEngine->paintStroke(
        &fboPainter2, m_lastPos, canvasPos, effectivePressure, settings, tilt,
        velocityFactor, m_pingFBO->texture(), settings.wetness,
        settings.dilution, settings.smudge);
    fboPainter2.end();
    m_pongFBO->release();

    layer->dirty = true;
    std::swap(m_pingFBO, m_pongFBO);
    m_lastPos = canvasPos;

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
    m_lastPos = canvasPos;
  }

  // Calculate dirty rect for update (Screen coordinates)
  // We need to determine the bounding box in canvas coords, then map to screen.
  float margin = settings.size + 2;
  float minX = std::min(m_lastPos.x(), canvasPos.x()) - margin;
  float minY = std::min(m_lastPos.y(), canvasPos.y()) - margin;
  float maxX = std::max(m_lastPos.x(), canvasPos.x()) + margin;
  float maxY = std::max(m_lastPos.y(), canvasPos.y()) + margin;

  QRectF canvasRect(minX, minY, maxX - minX, maxY - minY);

  // Transform back to screen for update()
  QRectF screenRect(
      canvasRect.x() * m_zoomLevel + m_viewOffset.x() * m_zoomLevel,
      canvasRect.y() * m_zoomLevel + m_viewOffset.y() * m_zoomLevel,
      canvasRect.width() * m_zoomLevel, canvasRect.height() * m_zoomLevel);

  m_lastPos = canvasPos;
  update(screenRect.toAlignedRect());
}

void CanvasItem::mousePressEvent(QMouseEvent *event) {
  if (event->button() == Qt::LeftButton) {
    if (m_isDrawing)
      return; // Already drawing (tablet?)

    m_isDrawing = true;
    m_lastPos = (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    float pressure = 1.0f;
    if (!event->points().isEmpty()) {
      float p = event->points().first().pressure();
      if (p > 0.0f)
        pressure = p;
    }

    qDebug() << "MOUSE START P:" << pressure;

    handleDraw(event->position(), pressure);
  }
}

void CanvasItem::mouseMoveEvent(QMouseEvent *event) {
  emit cursorPosChanged(event->position().x(), event->position().y());

  if (m_isDrawing) {
    // INTENTO DE RECUPERAR PRESIÓN DE EVENTO DE RATÓN (FALLBACK)
    float pressure = 1.0f;

    // Qt 6.0+ API: points()
    if (!event->points().isEmpty()) {
      float p = event->points().first().pressure();
      if (p > 0.0f) {
        pressure = p;
        static bool once = false;
        if (!once) {
          qDebug() << "PRESSURE RECOVERED FROM MOUSE EVENT!";
          once = true;
        }
      }
    }

    // Log para depuración si sigue siendo 1.0 (ratón puro)
    if (pressure == 1.0f && event->source() == Qt::MouseEventNotSynthesized) {
      // qDebug() << "MOUSE EVENT (No Pressure): 1.0";
      // Comentado para no saturar logs
    }

    handleDraw(event->position(), pressure);
  }
}

void CanvasItem::mouseReleaseEvent(QMouseEvent *event) {
  if (event->button() == Qt::LeftButton &&
      event->source() == Qt::MouseEventNotSynthesized) {
    if (m_isDrawing) {
      // Elimado el "final dab" que causaba el punto.
      m_isDrawing = false;
      m_lastPos = QPointF(); // Reset
      capture_timelapse_frame();
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
    handleDraw(event->position(), pressure, tiltFactor);
    event->accept();

  } else if (event->type() == QEvent::TabletMove && m_isDrawing) {
    handleDraw(event->position(), pressure, tiltFactor);
    event->accept();

  } else if (event->type() == QEvent::TabletRelease) {
    m_isDrawing = false;

    // FINALIZAR TRAZO PREMIUM (Pilar 3): Volcar GPU a CPU
    if (m_pingFBO) {
      QImage result =
          m_pingFBO->toImage().convertToFormat(QImage::Format_RGBA8888);
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer) {
        std::memcpy(layer->buffer->data(), result.bits(),
                    std::min((size_t)layer->buffer->width() *
                                 layer->buffer->height() * 4,
                             (size_t)result.sizeInBytes()));
      }
      delete m_pingFBO;
      m_pingFBO = nullptr;
      delete m_pongFBO;
      m_pongFBO = nullptr;
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
void CanvasItem::setCurrentTool(const QString &tool) {
  if (m_currentTool != tool) {
    m_currentTool = tool;
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
  }
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
      qDebug() << "Redo not implemented yet";
    else
      qDebug() << "Undo not implemented yet";
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
  // Tool Switches
  else if (key == Qt::Key_B)
    setCurrentTool("brush");
  else if (key == Qt::Key_E)
    setCurrentTool("eraser");
  else if (key == Qt::Key_L)
    setCurrentTool("lasso");
  else if (key == Qt::Key_V)
    setCurrentTool("move");
}

void CanvasItem::handle_key_release(int key) {
  if (key == Qt::Key_Space) {
    QGuiApplication::restoreOverrideCursor();
  }
}
void CanvasItem::fitToView() { qDebug() << "Fitting to view"; }

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
    // Precise mechanical pencil
    setBrushSize(4);
    setBrushOpacity(0.9f);
    setBrushHardness(0.9f);
    setBrushSpacing(0.02f);
    setBrushStabilization(0.5f);
    s.type = BrushSettings::Type::Pencil;
    s.grain = 0.15f;
    s.opacityByPressure = true;
    s.sizeByPressure = false; // Mechanical stays consistent size
    s.jitter = 0.02f;

    // Texture Config
    s.useTexture = true;
    s.textureName = "paper_grain.png";
    s.textureScale = 300.0f;   // Finer grain
    s.textureIntensity = 0.3f; // Less intense

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

// ==================== PRESSURE CURVE LOGIC ====================

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
