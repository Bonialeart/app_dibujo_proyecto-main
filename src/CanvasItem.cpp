#include "CanvasItem.h"
#include <QBuffer>
#include <QCursor>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QHoverEvent>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QStandardPaths>
#include <QTabletEvent>
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

  // Enable tablet tracking for high-frequency events
  // Note: QQuickItem doesn't have setAttribute(Qt::WA_TabletTracking) directly
  // but acts as if it's on.

  m_layerManager = new LayerManager(m_canvasWidth, m_canvasHeight);
  // Brush engine initialized in initializer list

  m_layerManager->addLayer("Layer 1");
  // Inicializar curva de presión (Lineal)
  // Inicializar curva de presión (Lineal)
  // [x0, y0, ..., xn, yn]
  setCurvePoints({0.0, 0.0, 0.25, 0.25, 0.75, 0.75, 1.0, 1.0});
  m_activeLayerIndex = 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  m_availableBrushes << "Pencil HB" << "Pencil 6B" << "Ink Pen" << "Marker"
                     << "G-Pen" << "Maru Pen" << "Watercolor"
                     << "Watercolor Wet"
                     << "Oil Paint" << "Acrylic" << "Soft" << "Hard"
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
}

void CanvasItem::paint(QPainter *painter) {
  if (!m_layerManager)
    return;

  // 1. Draw existing layers (Software backing store)
  // We use QPainter to draw the composite image (which handles zoom/pan)
  // Create background
  painter->fillRect(0, 0, width(), height(), Qt::white);

  if (m_layerManager->getLayerCount() > 0) {
    // Draw layers via composite
    for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
      Layer *layer = m_layerManager->getLayer(i);
      if (!layer->visible)
        continue;

      QImage img(layer->buffer->data(), layer->buffer->width(),
                 layer->buffer->height(), QImage::Format_RGBA8888);
      painter->setOpacity(layer->opacity);

      // Apply Zoom and Pan
      QRectF targetRect(
          m_viewOffset.x() * m_zoomLevel, m_viewOffset.y() * m_zoomLevel,
          m_canvasWidth * m_zoomLevel, m_canvasHeight * m_zoomLevel);
      painter->drawImage(targetRect, img);
    }
  }
}

void CanvasItem::handleDraw(const QPointF &pos, float pressure) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->visible || layer->locked)
    return;

  // Create QImage wrapper around layer buffer
  QImage img(layer->buffer->data(), layer->buffer->width(),
             layer->buffer->height(), QImage::Format_RGBA8888);

  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);

  // Transform coordinates from Screen to Canvas
  // Screen = (Canvas - Offset) * Zoom
  // Canvas = (Screen / Zoom) + Offset

  // BUT WAIT: QPainter on 'img' operates in Image coordinates (Canvas pixel
  // coordinates). 'pos' coming from mouse/tablet events is in Screen/Item local
  // coordinates. So we MUST transform 'pos' to 'canvasPos'.

  QPointF canvasPos = (pos - m_viewOffset * m_zoomLevel) / m_zoomLevel;

  // Check if it's the start of a stroke
  if (m_lastPos.isNull()) {
    m_lastPos = canvasPos;
  }

  // Draw stroke
  BrushSettings settings = m_brushEngine->getBrush();
  // Update strict settings from item properties just in case
  // (Optimization: Only update when properties change, but this ensures sync)
  settings.size = m_brushSize;
  settings.opacity = m_brushOpacity;
  settings.color = m_brushColor;
  settings.spacing = m_brushSpacing;
  settings.hardness = m_brushHardness;
  settings.dynamicsEnabled = true; // Always enable dynamics for pressure

  // Aplicar curva de presión personalizada (Gamma)
  // Aplicar curva de presión personalizada (Bezier LUT)
  float effectivePressure = applyPressureCurve(pressure);

  m_brushEngine->paintStroke(&painter, m_lastPos, canvasPos, effectivePressure,
                             settings);

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
  // Normalizar presión si viene rara (algunas tabletas envían 0-1024, otras
  // 0-1)
  if (pressure > 1.0f)
    pressure /= 1024.0f;

  if (event->type() == QEvent::TabletPress) {
    m_isDrawing = true;
    qDebug() << "TABLET START: P=" << pressure;
    QPointF p = event->position();
    QPointF canvasPos = (p - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_lastPos = canvasPos;
    handleDraw(event->position(), pressure);
    event->accept();

  } else if (event->type() == QEvent::TabletMove && m_isDrawing) {
    qDebug() << "TABLET MOVE: P=" << pressure;
    handleDraw(event->position(), pressure);
    event->accept();

  } else if (event->type() == QEvent::TabletRelease) {
    m_isDrawing = false;
    m_lastPos = QPointF();
    capture_timelapse_frame();
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
