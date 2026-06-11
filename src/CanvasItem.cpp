// Re-verify includes
#include "CanvasItem.h"
#include "PreferencesManager.h"
#ifdef Q_OS_WIN
#include "WintabManager.h"
#endif
#include <fstream>

#ifndef GL_RGBA8
#define GL_RGBA8 0x8058
#endif
#ifndef GL_RGBA16F
#define GL_RGBA16F 0x881A
#endif
#ifndef GL_UNPACK_ROW_LENGTH
#define GL_UNPACK_ROW_LENGTH 0x0CF2
#endif
#include "core/cpp/include/brush_preset_manager.h"
#include "core/brushes/abr_parser.h"
#include "core/cpp/include/undo_commands.h"
#include <QBuffer>
#include <QCoreApplication>
#include <QCursor>
#include <QSvgRenderer>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QEvent>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QGuiApplication>
#include <QHoverEvent>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
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
#include <QUuid>
#include <QVariant>
#include <QWindow>
#include <QtConcurrent/QtConcurrentRun>
#include <QtConcurrent>
#include <QtMath>
#include <algorithm>
#include <tuple>

using namespace artflow;

static QString serializePath(const QPainterPath &path) {
  QString result;
  for (int i = 0; i < path.elementCount(); ++i) {
    QPainterPath::Element el = path.elementAt(i);
    if (el.isMoveTo()) {
      result += QString("M %1 %2 ").arg(el.x).arg(el.y);
    } else if (el.isLineTo()) {
      result += QString("L %1 %2 ").arg(el.x).arg(el.y);
    } else if (el.isCurveTo()) {
      if (i + 2 < path.elementCount()) {
        QPainterPath::Element cp1 = el;
        QPainterPath::Element cp2 = path.elementAt(++i);
        QPainterPath::Element end = path.elementAt(++i);
        result += QString("C %1 %2, %3 %4, %5 %6 ")
                      .arg(cp1.x).arg(cp1.y)
                      .arg(cp2.x).arg(cp2.y)
                      .arg(end.x).arg(end.y);
      }
    }
  }
  return result.trimmed();
}

static QPainterPath deserializePath(const QString &str) {
  QPainterPath path;
  QStringList tokens = str.split(' ', Qt::SkipEmptyParts);
  for (int i = 0; i < tokens.size(); ) {
    QString cmd = tokens[i++];
    if (cmd == "M" && i + 1 < tokens.size()) {
      double x = tokens[i++].toDouble();
      double y = tokens[i++].toDouble();
      path.moveTo(x, y);
    } else if (cmd == "L" && i + 1 < tokens.size()) {
      double x = tokens[i++].toDouble();
      double y = tokens[i++].toDouble();
      path.lineTo(x, y);
    } else if (cmd == "C" && i + 5 < tokens.size()) {
      auto clean = [](const QString &s) {
        QString res = s;
        res.remove(',');
        return res.toDouble();
      };
      double x1 = clean(tokens[i++]);
      double y1 = clean(tokens[i++]);
      double x2 = clean(tokens[i++]);
      double y2 = clean(tokens[i++]);
      double x3 = clean(tokens[i++]);
      double y3 = clean(tokens[i++]);
      path.cubicTo(x1, y1, x2, y2, x3, y3);
    }
  }
  return path;
}

static QJsonArray serializeTransform(const QTransform &t) {
  QJsonArray arr;
  arr.append(t.m11());
  arr.append(t.m12());
  arr.append(t.m13());
  arr.append(t.m21());
  arr.append(t.m22());
  arr.append(t.m23());
  arr.append(t.m31());
  arr.append(t.m32());
  arr.append(t.m33());
  return arr;
}

static QTransform deserializeTransform(const QJsonArray &arr) {
  if (arr.size() < 9)
    return QTransform();
  return QTransform(arr[0].toDouble(), arr[1].toDouble(), arr[2].toDouble(),
                    arr[3].toDouble(), arr[4].toDouble(), arr[5].toDouble(),
                    arr[6].toDouble(), arr[7].toDouble(), arr[8].toDouble());
}



class VectorUndoCommand : public artflow::UndoCommand {
public:
  VectorUndoCommand(artflow::LayerManager *manager, int layerIndex,
                    std::unique_ptr<ImageBuffer> beforeBuffer,
                    std::unique_ptr<ImageBuffer> afterBuffer,
                    std::unique_ptr<artflow::VectorLayerData> beforeVector,
                    std::unique_ptr<artflow::VectorLayerData> afterVector)
      : m_manager(manager), m_layerIndex(layerIndex),
        m_beforeBuffer(std::move(beforeBuffer)), m_afterBuffer(std::move(afterBuffer)),
        m_beforeVector(std::move(beforeVector)), m_afterVector(std::move(afterVector)) {}

  void undo() override {
    artflow::Layer *layer = m_manager->getLayer(m_layerIndex);
    if (layer) {
      if (m_beforeBuffer) {
        layer->buffer->copyFrom(*m_beforeBuffer);
      }
      if (m_beforeVector) {
        layer->vectorData = std::make_unique<artflow::VectorLayerData>(*m_beforeVector);
      } else {
        layer->vectorData.reset();
      }
      layer->dirty = true;
      layer->markDirty();
    }
  }

  void redo() override {
    artflow::Layer *layer = m_manager->getLayer(m_layerIndex);
    if (layer) {
      if (m_afterBuffer) {
        layer->buffer->copyFrom(*m_afterBuffer);
      }
      if (m_afterVector) {
        layer->vectorData = std::make_unique<artflow::VectorLayerData>(*m_afterVector);
      } else {
        layer->vectorData.reset();
      }
      layer->dirty = true;
      layer->markDirty();
    }
  }

  std::string name() const override { return "Vector Stroke"; }

private:
  artflow::LayerManager *m_manager;
  int m_layerIndex;
  std::unique_ptr<ImageBuffer> m_beforeBuffer;
  std::unique_ptr<ImageBuffer> m_afterBuffer;
  std::unique_ptr<artflow::VectorLayerData> m_beforeVector;
  std::unique_ptr<artflow::VectorLayerData> m_afterVector;
};

static QString getAutoSaveDir();

static void warpQuadBilinear(const QImage &srcImg, QImage &dstImg,
                             const QPolygonF &srcQuad, const QPolygonF &dstQuad,
                             int canvasWidth, int canvasHeight);

static QCursor getModernCursor() {
  static QCursor modernCursor;
  static bool initialized = false;

  if (!initialized) {
    QPixmap cursorPix(32, 32);
    cursorPix.fill(Qt::transparent);
    QPainter p(&cursorPix);
    p.setRenderHint(QPainter::Antialiasing);

    QPainterPath path;
    // Diseño de flecha moderna (más esbelta y geométrica)
    path.moveTo(3, 3);
    path.lineTo(11, 24);
    path.lineTo(14, 16);
    path.lineTo(24, 11);
    path.closeSubpath();

    // Sombra suave paralela
    p.setBrush(QColor(0, 0, 0, 50));
    p.setPen(Qt::NoPen);
    p.translate(1, 2);
    p.drawPath(path);
    p.translate(-1, -2);

    // Cuerpo oscuro elegante con borde blanco nítido
    p.setBrush(QColor(30, 30, 35)); // Gris muy oscuro
    p.setPen(QPen(Qt::white, 1.5, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    p.drawPath(path);

    modernCursor = QCursor(cursorPix, 3, 3);
    initialized = true;
  }
  return modernCursor;
}

static QCursor loadCustomSvgCursor(const QString &fileName, int hotX = 16, int hotY = 16) {
  QStringList searchPaths;
  searchPaths << QCoreApplication::applicationDirPath() + "/assets/icons/" + fileName;
  searchPaths << QCoreApplication::applicationDirPath() + "/../assets/icons/" + fileName;
  searchPaths << "assets/icons/" + fileName;
  searchPaths << "src/assets/icons/" + fileName;
  searchPaths << QDir::currentPath() + "/assets/icons/" + fileName;

  QString path;
  for (const QString &searchPath : searchPaths) {
    if (QFile::exists(searchPath)) {
      path = searchPath;
      break;
    }
  }

  if (path.isEmpty()) {
    qWarning() << "Custom cursor SVG not found:" << fileName;
    return QCursor(Qt::ArrowCursor);
  }

  QPixmap pixmap(32, 32);
  pixmap.fill(Qt::transparent);

  QSvgRenderer renderer(path);
  if (!renderer.isValid()) {
    qWarning() << "Invalid cursor SVG:" << path;
    return QCursor(Qt::ArrowCursor);
  }

  QPainter painter(&pixmap);
  renderer.render(&painter);
  painter.end();

  return QCursor(pixmap, hotX, hotY);
}





CanvasItem::CanvasItem(QQuickItem *parent)
    : QQuickPaintedItem(parent), m_brushSize(20), m_brushColor(Qt::black),
      m_brushOpacity(1.0f), m_brushFlow(1.0f), m_brushHardness(0.8f),
      m_brushSpacing(0.1f), m_brushStabilization(0.2f), m_brushStabilizerMode(1), m_brushStreamline(0.0f),

      m_brushGrain(0.0f), m_brushWetness(0.0f), m_brushSmudge(0.0f),
      m_brushRoundness(1.0f), m_zoomLevel(1.0f), m_currentToolStr("brush"),
      m_tool(ToolType::Pen), m_canvasWidth(1920), m_canvasHeight(1080),
      m_viewOffset(50, 50), m_activeLayerIndex(0), m_isTransforming(false),
      m_brushAngle(0.0f), m_cursorRotation(0.0f),
      m_backgroundColor(Qt::white), m_currentProjectPath(""),
      m_currentProjectName("Untitled"), m_brushTip("round"),
      m_lastPressure(1.0f), m_isDrawing(false),
      m_brushEngine(new BrushEngine()), m_undoManager(new UndoManager()),
      m_lastActiveLayerIndex(-1), m_updateTransformTextures(false),
      m_transformShader(nullptr), m_screentoneShader(nullptr), m_transformStaticTex(nullptr),
      m_selectionTex(nullptr), m_isDraggingTransformInCpp(false),
      m_isFreeTransformActive(false), m_panelOverlayDirty(true),
      m_lastActiveBasePanel(nullptr), m_lastCanvasWidth(0),
      m_lastCanvasHeight(0), m_hasActiveSpeechBalloon(false),
      m_draggingBalloonHandle(0),
      m_gradientShape("linear") {
  m_maxTouchPointsThisSession = 0;
  m_touchStartTime = 0;
  m_touchMovedThisSession = false;
  m_lastTraceTarget = QPointF(-9999.0f, -9999.0f);
  m_customOpenHandCursor = loadCustomSvgCursor("hand-open.svg");
  m_customClosedHandCursor = loadCustomSvgCursor("hand-closed.svg");

  // Initialize default gradient stops (Sunset)
  QVariantMap stop1, stop2, stop3;
  stop1["position"] = 0.0;
  stop1["color"] = "#764ba2";
  stop2["position"] = 0.5;
  stop2["color"] = "#ff7e5f";
  stop3["position"] = 1.0;
  stop3["color"] = "#feb47b";
  m_gradientStops << stop1 << stop2 << stop3;





#ifdef Q_OS_WIN
  // Wintab integration
  connect(WintabManager::instance(), &WintabManager::wintabEvent, this, &CanvasItem::onWintabEvent);
  connect(this, &QQuickItem::windowChanged, this, [this](QQuickWindow *win) {
    if (win) {
        HWND hwnd = (HWND)win->winId();
        qDebug() << "CanvasItem: windowChanged, winId:" << hwnd;
        WintabManager::instance()->init(hwnd);
    }
  });
#endif
  // ---------------------------------

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

  // QuickShape snap animation timer (premium glow effect)
  m_quickShapeSnapTimer = new QTimer(this);
  m_quickShapeSnapTimer->setInterval(16); // ~60fps
  connect(m_quickShapeSnapTimer, &QTimer::timeout, this, [this]() {
    m_quickShapeSnapAnim += 0.04f; // ~400ms total animation for premium feel
    if (m_quickShapeSnapAnim >= 1.0f) {
      m_quickShapeSnapAnim = 1.0f;
      m_quickShapeSnapAnimActive = false;
      m_quickShapeSnapTimer->stop();
    }
    update();
  });

  // Throttle de redibujado a ~60fps máximo
  m_updateThrottle = new QTimer(this);
  m_updateThrottle->setInterval(16); // ~60fps cap
  m_updateThrottle->setSingleShot(true);
  connect(m_updateThrottle, &QTimer::timeout, this, [this]() {
    m_pendingUpdate = false;
    QQuickPaintedItem::update();
  });

  // Timer persistente para animación de marching ants
  m_marchingAntsTimer = new QTimer(this);
  m_marchingAntsTimer->setInterval(50); // 20fps
  connect(m_marchingAntsTimer, &QTimer::timeout, this, [this]() {
    if (!m_selectionPath.isEmpty())
      update();
    else
      m_marchingAntsTimer->stop();
  });

  // Brush engine initialized in initializer list

  m_layerManager->addLayer("Layer 1");

  // Cargar curva de presión guardada (Persistencia)
  QVariantList savedCurve = PreferencesManager::instance()->pressureCurve();
  qDebug() << "[PressureCurve] Loaded from preferences:" << savedCurve
           << "count:" << savedCurve.size();
  setCurvePoints(savedCurve);

  // Sincronizar niveles de deshacer (Undo Levels)
  m_undoManager->setMaxLevels(PreferencesManager::instance()->undoLevels());

  // Escuchar cambios en preferencias para actualizar el sistema en tiempo real

  m_activeLayerIndex = 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  // ✅ OCULTAR CURSOR DEL SISTEMA COMPLETAMENTE
  setCursor(QCursor(Qt::BlankCursor));
  setFlag(QQuickItem::ItemHasContents, true);

  // === Data-Driven Brush Loading ===
  auto *bpm = artflow::BrushPresetManager::instance();

  // Try loading JSON presets from disk
  QStringList searchPaths;
  searchPaths << ":/assets/brushes"
              << "assets/brushes"
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
  updateBrushTipImage();
  updateLayersList();

  // Initial Theme Setup
  auto updateTheme = [this]() {
    QString theme = PreferencesManager::instance()->themeMode();
    QString accent = PreferencesManager::instance()->themeAccent();

    // Theme Background Colors
    if (theme == "Dark")
      m_workspaceColor = QColor("#1e1e1e");
    else if (theme == "Light")
      m_workspaceColor = QColor("#e0e0e0"); // Soft Grey
    else if (theme == "Midnight")
      m_workspaceColor = QColor("#000000"); // Pitch Black
    else if (theme == "Blue-Grey")
      m_workspaceColor = QColor("#263238"); // Material Blue Grey 900
    else if (theme == "Studio-Grey")
      m_workspaceColor = QColor("#2e2e2e"); // Clip Studio Paint style gray
    else
      m_workspaceColor = QColor("#1e1e1e"); // Fallback

    // Accent Color
    if (QColor::isValidColorName(accent)) {
      m_accentColor = QColor(accent);
    } else {
      m_accentColor = QColor("#007bff"); // Default Blue
    }

    update();
  };

  // Connect to Preferences
  connect(PreferencesManager::instance(), &PreferencesManager::settingsChanged,
          this, [this, updateTheme]() {
            m_undoManager->setMaxLevels(
                PreferencesManager::instance()->undoLevels());
            updateTheme();
          });

  // Connect pressure curve changes from PreferencesManager -> reload LUT
  connect(PreferencesManager::instance(),
          &PreferencesManager::pressureCurveChanged, this, [this]() {
            setCurvePoints(PreferencesManager::instance()->pressureCurve());
          });

  // Apply initial
  updateTheme();
  setupAutoSave();
  m_edgeDetector = new EdgeDetector();
  m_animationManager = new AnimationManager(m_layerManager, this);
  connect(m_animationManager, &AnimationManager::frameUpdated, this, [this]() {
    clearRenderCaches();
    update();
  });
  connect(m_animationManager, &AnimationManager::tracksChanged, this, [this]() {
    clearRenderCaches();
    update();
  });
  connect(m_animationManager, &AnimationManager::notificationRequested, this, &CanvasItem::notificationRequested);

  m_perspectiveRuler = new PerspectiveRuler(this);
  connect(m_perspectiveRuler, &PerspectiveRuler::activeChanged, this, [this]() {
    syncPerspectiveLayer();
    update();
  });
  connect(m_perspectiveRuler, &PerspectiveRuler::typeChanged, this, [this]() { update(); });
  connect(m_perspectiveRuler, &PerspectiveRuler::vp1Changed, this, [this]() { update(); });
  connect(m_perspectiveRuler, &PerspectiveRuler::vp2Changed, this, [this]() { update(); });
  connect(m_perspectiveRuler, &PerspectiveRuler::vp3Changed, this, [this]() { update(); });
  connect(m_perspectiveRuler, &PerspectiveRuler::vp1ActiveChanged, this, [this]() { update(); });
  connect(m_perspectiveRuler, &PerspectiveRuler::vp2ActiveChanged, this, [this]() { update(); });
  connect(m_perspectiveRuler, &PerspectiveRuler::vp3ActiveChanged, this, [this]() { update(); });
}

void CanvasItem::clearRenderCaches() {
  m_layerRenderCache.clear();
  m_clippedRenderCache.clear();
  m_cachedCanvasImage = QImage(); // Invalidate CPU composite cache
  m_canvasPreviewBase64 = QString(); // Invalidate base64 cache

  // GL resources must NOT be deleted from QML thread.
  // Set a flag and let paint() clean them up in the render thread.
  m_glResourcesDirty = true;
}

void CanvasItem::ensureCompositionFBOs(int w, int h) {
  if (w <= 0 || h <= 0)
    return;

  if (!m_compFBOA || m_compFBOA->width() != w || m_compFBOA->height() != h) {
    if (m_compFBOA)
      delete m_compFBOA;
    if (m_compFBOB)
      delete m_compFBOB;

    QOpenGLFramebufferObjectFormat format;
    format.setAttachment(QOpenGLFramebufferObject::NoAttachment);
    format.setInternalTextureFormat(GL_RGBA8);

    m_compFBOA = new QOpenGLFramebufferObject(w, h, format);
    m_compFBOB = new QOpenGLFramebufferObject(w, h, format);
  }
}

void CanvasItem::renderGpuComposition(QOpenGLFramebufferObject *target, int w,
                                      int h) {
  if (!m_compositionShader || !m_compositionShader->isLinked())
    return;

  QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();

  // 1. Ensure internal composition FBOs
  if (m_canvasWidth <= 0 || m_canvasHeight <= 0)
    return;

  ensureCompositionFBOs(m_canvasWidth, m_canvasHeight);
  if (!m_compFBOA || !m_compFBOB)
    return;

  // 2. Clear initial state (Checkerboard)
  m_compFBOA->bind();
  f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
  f->glClearColor(0, 0, 0, 0); // Transparent base
  f->glClear(GL_COLOR_BUFFER_BIT);
  m_compFBOA->release();

  artflow::Layer *clippingBase = nullptr;
  GLuint clippingBaseTexID = 0;
  QOpenGLFramebufferObject *currentBackdrop = m_compFBOA;
  QOpenGLFramebufferObject *nextBackdrop = m_compFBOB;

  auto drawBorderOnTop = [&](artflow::Layer *panelL, GLuint panelTexID) {
    if (!panelL || panelTexID == 0)
      return;

    nextBackdrop->bind();
    f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
    m_compositionShader->bind();

    f->glActiveTexture(GL_TEXTURE0);
    f->glBindTexture(GL_TEXTURE_2D, currentBackdrop->texture());
    m_compositionShader->setUniformValue("uBackdrop", 0);

    f->glActiveTexture(GL_TEXTURE1);
    f->glBindTexture(GL_TEXTURE_2D, panelTexID);
    m_compositionShader->setUniformValue("uSource", 1);

    m_compositionShader->setUniformValue("uHasMask", 0);
    m_compositionShader->setUniformValue("uOpacity", panelL->opacity);
    m_compositionShader->setUniformValue("uMode", (int)artflow::BlendMode::Normal);
    m_compositionShader->setUniformValue("uDrawPanelBorderOnly", 1);

    // Identity-like transforms for FBO-to-FBO composition
    m_compositionShader->setUniformValue(
        "uScreenSize", QVector2D(m_canvasWidth, m_canvasHeight));
    m_compositionShader->setUniformValue(
        "uLayerSize", QVector2D(m_canvasWidth, m_canvasHeight));
    m_compositionShader->setUniformValue("uViewOffset", QVector2D(0, 0));
    m_compositionShader->setUniformValue("uZoom", 1.0f);
    m_compositionShader->setUniformValue("uIsPreview", 0.0f);

    GLfloat vertices[] = {-1, -1, 0, 0, 1, -1, 1, 0, -1, 1, 0, 1,
                          -1, 1,  0, 1, 1, -1, 1, 0, 1,  1, 1, 1};

    m_compositionShader->enableAttributeArray(0);
    m_compositionShader->enableAttributeArray(1);
    m_compositionShader->setAttributeArray(0, GL_FLOAT, vertices, 2,
                                           4 * sizeof(GLfloat));
    m_compositionShader->setAttributeArray(1, GL_FLOAT, vertices + 2, 2,
                                           4 * sizeof(GLfloat));

    f->glDrawArrays(GL_TRIANGLES, 0, 6);

    m_compositionShader->disableAttributeArray(0);
    m_compositionShader->disableAttributeArray(1);
    m_compositionShader->release();
    nextBackdrop->release();

    std::swap(currentBackdrop, nextBackdrop);
  };

  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    artflow::Layer *layer = m_layerManager->getLayer(i);
    if (!layer || !layer->visible)
      continue;

    artflow::Layer *maskLayer = (layer->clipped) ? clippingBase : nullptr;
    if (!layer->clipped) {
      if (clippingBase && QString::fromStdString(clippingBase->name).startsWith("Panel ", Qt::CaseInsensitive)) {
        drawBorderOnTop(clippingBase, clippingBaseTexID);
      }
      clippingBase = layer;
    }

    // Get Source Texture
    GLuint sourceTexID = 0;
    if (m_isDrawing && i == m_activeLayerIndex && m_pingFBO) {
      if (m_hasPrediction && m_predictionFBO) {
        sourceTexID = m_predictionFBO->texture();
      } else {
        sourceTexID = m_pingFBO->texture();
      }
    } else {
      QOpenGLTexture *tex = m_layerTextures.value(layer);
      bool bufferDirty = layer->buffer->hasDirtyTiles();

      if (!tex || layer->dirty || bufferDirty) {
        if (!tex) {
          tex = new QOpenGLTexture(QOpenGLTexture::Target2D);
          tex->setSize(layer->buffer->width(), layer->buffer->height());
          tex->setFormat(QOpenGLTexture::RGBA8_UNorm);
          tex->allocateStorage();
          tex->setMinificationFilter(QOpenGLTexture::Linear);
          tex->setMagnificationFilter(QOpenGLTexture::Linear);
          tex->setWrapMode(QOpenGLTexture::ClampToBorder);
          tex->setBorderColor(QColor(0, 0, 0, 0));
          m_layerTextures.insert(layer, tex);
        }

        // PERFORMANCE: Upload only dirty tiles
        int cols = (layer->buffer->width() + artflow::ImageBuffer::TILE_SIZE - 1) / artflow::ImageBuffer::TILE_SIZE;
        int rows = (layer->buffer->height() + artflow::ImageBuffer::TILE_SIZE - 1) / artflow::ImageBuffer::TILE_SIZE;
        static std::vector<uint8_t> s_zeroTile(artflow::ImageBuffer::TILE_BYTES, 0);

        if (layer->dirty) {
          for (int ty = 0; ty < rows; ++ty) {
            for (int tx = 0; tx < cols; ++tx) {
              auto *tile = layer->buffer->getTile(tx * artflow::ImageBuffer::TILE_SIZE, ty * artflow::ImageBuffer::TILE_SIZE, false);
              int xPos = tx * artflow::ImageBuffer::TILE_SIZE;
              int yPos = ty * artflow::ImageBuffer::TILE_SIZE;
              int tw = std::min(artflow::ImageBuffer::TILE_SIZE, layer->buffer->width() - xPos);
              int th = std::min(artflow::ImageBuffer::TILE_SIZE, layer->buffer->height() - yPos);

              f->glPixelStorei(GL_UNPACK_ROW_LENGTH, artflow::ImageBuffer::TILE_SIZE);
              const uint8_t* ptr = tile ? tile->data.get() : s_zeroTile.data();
              tex->setData(xPos, yPos, 0, tw, th, 1, QOpenGLTexture::RGBA,
                           QOpenGLTexture::UInt8, ptr);
              f->glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
              if (tile) tile->dirty = false;
            }
          }
        } else {
          const auto &tiles = layer->buffer->getTiles();
          for (const auto &tile : tiles) {
            if (tile && tile->dirty) {
              int tx = tile->startX * artflow::ImageBuffer::TILE_SIZE;
              int ty = tile->startY * artflow::ImageBuffer::TILE_SIZE;
              int tw = std::min(artflow::ImageBuffer::TILE_SIZE,
                                layer->buffer->width() - tx);
              int th = std::min(artflow::ImageBuffer::TILE_SIZE,
                                layer->buffer->height() - ty);

              f->glPixelStorei(GL_UNPACK_ROW_LENGTH,
                               artflow::ImageBuffer::TILE_SIZE);
              tex->setData(tx, ty, 0, tw, th, 1, QOpenGLTexture::RGBA,
                           QOpenGLTexture::UInt8, tile->data.get());
              f->glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
              tile->dirty = false;
            }
          }
        }
        layer->buffer->clearDirtyFlags();
        layer->dirty = false;
        layer->dirtyRect = QRect();
      }
      sourceTexID = tex->textureId();
    }

    if (!layer->clipped) {
      clippingBaseTexID = sourceTexID;
    }

    static int s_renderLogCount = 0;
    if (s_renderLogCount < 50) {
      s_renderLogCount++;
      QFile rDebug("render_debug.txt");
      if (rDebug.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&rDebug);
        out << "Layer " << i << " (" << QString::fromStdString(layer->name) << ") render pass:\n";
        out << " - screentoneEnabled: " << layer->screentoneEnabled << "\n";
        out << " - screentoneDotSize: " << layer->screentoneDotSize << "\n";
        out << " - screentoneAngle: " << layer->screentoneAngle << "\n";
        out << " - screentoneContrast: " << layer->screentoneContrast << "\n";
        out << " - screentoneType: " << layer->screentoneType << "\n";
        out << " - m_screentoneShader linked: " << (m_screentoneShader && m_screentoneShader->isLinked()) << "\n";
      }
    }

    // Live GPU Gradient Map Shader Pass (Color mapping preset)
    if (layer->gradientMapEnabled && m_gradientMapShader && m_gradientMapShader->isLinked()) {
      if (!m_gradientMapFBO || m_gradientMapFBO->width() != m_canvasWidth || m_gradientMapFBO->height() != m_canvasHeight) {
        if (m_gradientMapFBO) delete m_gradientMapFBO;
        QOpenGLFramebufferObjectFormat format;
        format.setAttachment(QOpenGLFramebufferObject::NoAttachment);
        format.setInternalTextureFormat(GL_RGBA8);
        m_gradientMapFBO = new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
      }

      m_gradientMapFBO->bind();
      f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
      f->glClearColor(0, 0, 0, 0);
      f->glClear(GL_COLOR_BUFFER_BIT);

      m_gradientMapShader->bind();
      f->glActiveTexture(GL_TEXTURE0);
      f->glBindTexture(GL_TEXTURE_2D, sourceTexID);
      m_gradientMapShader->setUniformValue("uSource", 0);

      // Dynamic Stops Setup
      QVariantList stops = layer->gradientMapStops;
      if (stops.isEmpty()) {
        stops = m_gradientStops;
      }

      int count = qMin(stops.size(), 16);
      m_gradientMapShader->setUniformValue("uStopCount", count);

      if (count > 0) {
        std::vector<std::pair<float, QColor>> sortedStops;
        for (int i = 0; i < stops.size(); ++i) {
          QVariantMap stopObj = stops[i].toMap();
          float pos = stopObj["position"].toFloat();
          QColor col(stopObj["color"].toString());
          sortedStops.push_back({pos, col});
        }
        std::sort(sortedStops.begin(), sortedStops.end(), [](const auto &a, const auto &b) {
          return a.first < b.first;
        });

        GLfloat positions[16];
        GLfloat colors[16 * 3];

        for (int i = 0; i < count; ++i) {
          positions[i] = sortedStops[i].first;
          QColor col = sortedStops[i].second;
          colors[i * 3 + 0] = col.redF();
          colors[i * 3 + 1] = col.greenF();
          colors[i * 3 + 2] = col.blueF();
        }

        m_gradientMapShader->setUniformValueArray("uStopPositions", positions, count, 1);
        m_gradientMapShader->setUniformValueArray("uStopColors", colors, count, 3);
      }

      // Drag Coordinates Setup
      int useCoords = 0;
      if (layer->gradientMapUseCoords) {
        if (m_gradientShape == "radial") {
          useCoords = 2;
        } else {
          useCoords = 1;
        }
      }
      m_gradientMapShader->setUniformValue("uUseCoords", useCoords);
      m_gradientMapShader->setUniformValue("uStart", QVector2D(layer->gradientMapStart.x(), layer->gradientMapStart.y()));
      m_gradientMapShader->setUniformValue("uEnd", QVector2D(layer->gradientMapEnd.x(), layer->gradientMapEnd.y()));
      m_gradientMapShader->setUniformValue("uCanvasSize", QVector2D(m_canvasWidth, m_canvasHeight));

      GLfloat vertices[] = {-1, -1, 0, 0, 1, -1, 1, 0, -1, 1, 0, 1,
                            -1, 1,  0, 1, 1, -1, 1, 0, 1,  1, 1, 1};

      m_gradientMapShader->enableAttributeArray(0);
      m_gradientMapShader->enableAttributeArray(1);
      m_gradientMapShader->setAttributeArray(0, GL_FLOAT, vertices, 2, 4 * sizeof(GLfloat));
      m_gradientMapShader->setAttributeArray(1, GL_FLOAT, vertices + 2, 2, 4 * sizeof(GLfloat));

      f->glDrawArrays(GL_TRIANGLES, 0, 6);

      m_gradientMapShader->disableAttributeArray(0);
      m_gradientMapShader->disableAttributeArray(1);
      m_gradientMapShader->release();
      m_gradientMapFBO->release();

      sourceTexID = m_gradientMapFBO->texture();
      if (!layer->clipped) {
        clippingBaseTexID = sourceTexID;
      }
    }

    // Live GPU Screentone Shader Pass (Halftone conversion)
    if (layer->screentoneEnabled && m_screentoneShader && m_screentoneShader->isLinked()) {
      if (!m_screentoneFBO || m_screentoneFBO->width() != m_canvasWidth || m_screentoneFBO->height() != m_canvasHeight) {
        if (m_screentoneFBO) delete m_screentoneFBO;
        QOpenGLFramebufferObjectFormat format;
        format.setAttachment(QOpenGLFramebufferObject::NoAttachment);
        format.setInternalTextureFormat(GL_RGBA8);
        m_screentoneFBO = new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
      }

      m_screentoneFBO->bind();
      f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
      f->glClearColor(0, 0, 0, 0);
      f->glClear(GL_COLOR_BUFFER_BIT);

      m_screentoneShader->bind();
      f->glActiveTexture(GL_TEXTURE0);
      f->glBindTexture(GL_TEXTURE_2D, sourceTexID);
      m_screentoneShader->setUniformValue("uSource", 0);
      m_screentoneShader->setUniformValue("u_dotSize", layer->screentoneDotSize);
      m_screentoneShader->setUniformValue("u_angle", layer->screentoneAngle);
      m_screentoneShader->setUniformValue("u_contrast", layer->screentoneContrast);
      m_screentoneShader->setUniformValue("u_patternType", layer->screentoneType);
      m_screentoneShader->setUniformValue("uScreenSize", QVector2D(m_canvasWidth, m_canvasHeight));

      GLfloat screentoneVertices[] = {-1, -1, 0, 0, 1, -1, 1, 0, -1, 1, 0, 1,
                                      -1, 1,  0, 1, 1, -1, 1, 0, 1,  1, 1, 1};

      m_screentoneShader->enableAttributeArray(0);
      m_screentoneShader->enableAttributeArray(1);
      m_screentoneShader->setAttributeArray(0, GL_FLOAT, screentoneVertices, 2, 4 * sizeof(GLfloat));
      m_screentoneShader->setAttributeArray(1, GL_FLOAT, screentoneVertices + 2, 2, 4 * sizeof(GLfloat));

      f->glDrawArrays(GL_TRIANGLES, 0, 6);

      m_screentoneShader->disableAttributeArray(0);
      m_screentoneShader->disableAttributeArray(1);
      m_screentoneShader->release();
      m_screentoneFBO->release();

      sourceTexID = m_screentoneFBO->texture();
      if (!layer->clipped) {
        clippingBaseTexID = sourceTexID;
      }
    }

    // Blend into nextBackdrop
    nextBackdrop->bind();
    f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
    m_compositionShader->bind();

    f->glActiveTexture(GL_TEXTURE0);
    f->glBindTexture(GL_TEXTURE_2D, currentBackdrop->texture());
    m_compositionShader->setUniformValue("uBackdrop", 0);

    f->glActiveTexture(GL_TEXTURE1);
    f->glBindTexture(GL_TEXTURE_2D, sourceTexID);
    m_compositionShader->setUniformValue("uSource", 1);

    if (maskLayer) {
      QOpenGLTexture *mTex = m_layerTextures.value(maskLayer);
      if (mTex) {
        f->glActiveTexture(GL_TEXTURE2);
        mTex->bind();
        m_compositionShader->setUniformValue("uMask", 2);
        m_compositionShader->setUniformValue("uHasMask", 1);
      } else {
        m_compositionShader->setUniformValue("uHasMask", 0);
      }
    } else {
      m_compositionShader->setUniformValue("uHasMask", 0);
    }

    float effectiveOpacity = layer->opacity;
    if (m_animationManager) {
      for (const auto& track : m_animationManager->getTracks()) {
        bool trackControlsLayer = false;
        for (const auto& pair : track.getKeyframes()) {
          if (pair.second.getLayerRef() == layer) {
            trackControlsLayer = true;
            break;
          }
        }
        if (trackControlsLayer) {
          AnimationFrame frame = const_cast<AnimationTrack&>(track).getFrame(m_animationManager->currentFrame());
          effectiveOpacity = frame.getOpacity() * layer->opacity;
          break;
        }
      }
    }

    m_compositionShader->setUniformValue("uOpacity", effectiveOpacity);
    m_compositionShader->setUniformValue("uMode", (int)layer->blendMode);
    m_compositionShader->setUniformValue("uDrawPanelBorderOnly", 0);

    // Per-layer display offset for FBO-to-FBO composition
    m_compositionShader->setUniformValue(
        "uScreenSize", QVector2D(m_canvasWidth, m_canvasHeight));
    m_compositionShader->setUniformValue(
        "uLayerSize", QVector2D(m_canvasWidth, m_canvasHeight));
    m_compositionShader->setUniformValue(
        "uViewOffset", QVector2D(layer->offsetX, layer->offsetY));
    m_compositionShader->setUniformValue("uZoom", 1.0f);
    m_compositionShader->setUniformValue("uIsPreview", 0.0f);

    GLfloat vertices[] = {-1, -1, 0, 0, 1, -1, 1, 0, -1, 1, 0, 1,
                          -1, 1,  0, 1, 1, -1, 1, 0, 1,  1, 1, 1};

    m_compositionShader->enableAttributeArray(0);
    m_compositionShader->enableAttributeArray(1);
    m_compositionShader->setAttributeArray(0, GL_FLOAT, vertices, 2,
                                           4 * sizeof(GLfloat));
    m_compositionShader->setAttributeArray(1, GL_FLOAT, vertices + 2, 2,
                                           4 * sizeof(GLfloat));

    f->glDrawArrays(GL_TRIANGLES, 0, 6);

    m_compositionShader->disableAttributeArray(0);
    m_compositionShader->disableAttributeArray(1);
    m_compositionShader->release();
    nextBackdrop->release();

    std::swap(currentBackdrop, nextBackdrop);
  }

  if (clippingBase && QString::fromStdString(clippingBase->name).startsWith("Panel ", Qt::CaseInsensitive)) {
    drawBorderOnTop(clippingBase, clippingBaseTexID);
  }

  // Store the final composited texture ID for the blit shader
  m_currentCanvasTexID = currentBackdrop->texture();

  // CRITICAL: Always ensure the final result is in m_compFBOA.
  // The ping-pong compositing may leave the result in either FBO depending
  // on the number of visible layers. The display path reads from m_compFBOA.
  if (currentBackdrop != m_compFBOA) {
    QOpenGLFramebufferObject::blitFramebuffer(m_compFBOA, currentBackdrop);
    m_currentCanvasTexID = m_compFBOA->texture();
  }

  // Blit result to explicit target FBO if requested
  if (target && target != m_compFBOA) {
    QOpenGLFramebufferObject::blitFramebuffer(target, m_compFBOA);
  }
}

CanvasItem::~CanvasItem() {
  if (m_brushEngine)
    delete m_brushEngine;
  if (m_layerManager)
    delete m_layerManager;
  if (m_undoManager)
    delete m_undoManager;
  for (auto *engine : m_symmetryEngines) {
    delete engine;
  }
  m_symmetryEngines.clear();
  if (m_impastoShader)
    delete m_impastoShader;
  if (m_liquifyEngine)
    delete m_liquifyEngine;
  if (m_edgeDetector)
    delete m_edgeDetector;
  if (m_animationManager)
    delete m_animationManager;
  if (m_perspectiveRuler)
    delete m_perspectiveRuler;

  // Cleanup layer textures
  for (auto *tex : m_layerTextures.values()) {
    delete tex;
  }
  m_layerTextures.clear();

  if (m_pingFBO)
    delete m_pingFBO;
  if (m_pongFBO)
    delete m_pongFBO;
  if (m_compFBOA)
    delete m_compFBOA;
  if (m_compFBOB)
    delete m_compFBOB;
  if (m_screentoneFBO)
    delete m_screentoneFBO;
  if (m_screentoneShader)
    delete m_screentoneShader;
  if (m_gradientMapFBO)
    delete m_gradientMapFBO;
  if (m_gradientMapShader)
    delete m_gradientMapShader;
  if (m_predictionFBO)
    delete m_predictionFBO;
  if (m_dabFBO)
    delete m_dabFBO;
  if (m_transformStaticTex)
    delete m_transformStaticTex;
  if (m_selectionTex)
    delete m_selectionTex;
  if (m_transformShader)
    delete m_transformShader;
}

void CanvasItem::cleanupGlResources() {
  // This must be called from within paint() where we have a valid GL context.
  if (!m_glResourcesDirty)
    return;
  m_glResourcesDirty = false;

  // Delete all layer textures (they point to old/deleted layers)
  for (auto *tex : m_layerTextures.values()) {
    delete tex;
  }
  m_layerTextures.clear();

  // Delete composition FBOs (canvas size may have changed)
  if (m_compFBOA) {
    delete m_compFBOA;
    m_compFBOA = nullptr;
  }
  if (m_compFBOB) {
    delete m_compFBOB;
    m_compFBOB = nullptr;
  }
  if (m_screentoneFBO) {
    delete m_screentoneFBO;
    m_screentoneFBO = nullptr;
  }
  if (m_gradientMapFBO) {
    delete m_gradientMapFBO;
    m_gradientMapFBO = nullptr;
  }

  // Delete stroke FBOs
  if (m_pingFBO) {
    delete m_pingFBO;
    m_pingFBO = nullptr;
  }
  if (m_pongFBO) {
    delete m_pongFBO;
    m_pongFBO = nullptr;
  }
  if (m_predictionFBO) {
    delete m_predictionFBO;
    m_predictionFBO = nullptr;
  }
  if (m_dabFBO) {
    delete m_dabFBO;
    m_dabFBO = nullptr;
  }
}

void CanvasItem::requestUpdate() {
  if (!m_pendingUpdate) {
    m_pendingUpdate = true;
    m_updateThrottle->start();
  }
}

void CanvasItem::resetTransformState() {
  m_isTransforming = false;
  setIsFreeTransformActive(false);
  m_selectionBuffer = QImage();
  m_transformStaticCache = QImage();
  m_updateTransformTextures = false;
  m_transformMatrix = QTransform();
  m_initialMatrix = QTransform();
  m_transformBox = QRectF();
  m_selectionPath = QPainterPath();
  m_activeLassoPath = QPainterPath();
  m_isLassoDragging = false;
  m_isMagneticLassoActive = false;
  m_magneticPreviewPath = QPainterPath();
  m_hasSelection = false;

  if (m_marchingAntsTimer)
    m_marchingAntsTimer->stop();

  emit isTransformingChanged();
  emit hasSelectionChanged();
  update();
}

// --- HSL helper functions for Hue/Saturation/Color/Luminosity blend modes ---
// Follows the W3C compositing spec / Krita's non-separable blend mode math.
static inline float hslLuminosity(float r, float g, float b) {
  return 0.3f * r + 0.59f * g + 0.11f * b;
}

static inline float hslSaturation(float r, float g, float b) {
  return std::max({r, g, b}) - std::min({r, g, b});
}

static inline void hslClipColor(float &r, float &g, float &b) {
  float l = hslLuminosity(r, g, b);
  float mn = std::min({r, g, b});
  float mx = std::max({r, g, b});
  if (mn < 0.0f) {
    float denom = l - mn;
    if (denom > 1e-7f) {
      r = l + (r - l) * l / denom;
      g = l + (g - l) * l / denom;
      b = l + (b - l) * l / denom;
    } else {
      r = g = b = l;
    }
  }
  if (mx > 1.0f) {
    float denom = mx - l;
    if (denom > 1e-7f) {
      r = l + (r - l) * (1.0f - l) / denom;
      g = l + (g - l) * (1.0f - l) / denom;
      b = l + (b - l) * (1.0f - l) / denom;
    } else {
      r = g = b = l;
    }
  }
}

static inline void hslSetLum(float &r, float &g, float &b, float lum) {
  float d = lum - hslLuminosity(r, g, b);
  r += d; g += d; b += d;
  hslClipColor(r, g, b);
}

// Set the saturation of (r,g,b) to the given sat value while preserving
// the component ordering.  This is the "SetSat" algorithm from the spec.
static inline void hslSetSat(float &r, float &g, float &b, float sat) {
  // Identify min, mid, max by pointer
  float *cmin = &r, *cmid = &g, *cmax = &b;
  if (*cmin > *cmid) std::swap(cmin, cmid);
  if (*cmid > *cmax) std::swap(cmid, cmax);
  if (*cmin > *cmid) std::swap(cmin, cmid);

  if (*cmax > *cmin) {
    *cmid = ((*cmid - *cmin) * sat) / (*cmax - *cmin);
    *cmax = sat;
  } else {
    *cmid = 0.0f;
    *cmax = 0.0f;
  }
  *cmin = 0.0f;
}

static inline uint8_t getRedRGBA(uint32_t px) { return (px & 0xFF); }
static inline uint8_t getGreenRGBA(uint32_t px) { return ((px >> 8) & 0xFF); }
static inline uint8_t getBlueRGBA(uint32_t px) { return ((px >> 16) & 0xFF); }
static inline uint8_t getAlphaRGBA(uint32_t px) { return (px >> 24); }

static inline uint32_t makeRGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
  return (static_cast<uint32_t>(a) << 24) |
         (static_cast<uint32_t>(b) << 16) |
         (static_cast<uint32_t>(g) << 8)  |
         static_cast<uint32_t>(r);
}

static void blendImagesCustom(QImage &backdrop, const QImage &source, const QRect &rect, const QPoint &targetPos, artflow::BlendMode mode, float opacity) {
  int xStart = std::max(0, rect.left());
  int yStart = std::max(0, rect.top());
  int xEnd = std::min(source.width() - 1, rect.right());
  int yEnd = std::min(source.height() - 1, rect.bottom());

  // Offset between source coordinates and backdrop coordinates
  int dx = targetPos.x() - rect.x();
  int dy = targetPos.y() - rect.y();

  for (int y = yStart; y <= yEnd; ++y) {
    int destY = y + dy;
    if (destY < 0 || destY >= backdrop.height()) continue;

    uint32_t *dstLine = reinterpret_cast<uint32_t*>(backdrop.scanLine(destY));
    const uint32_t *srcLine = reinterpret_cast<const uint32_t*>(source.scanLine(y));

    for (int x = xStart; x <= xEnd; ++x) {
      int destX = x + dx;
      if (destX < 0 || destX >= backdrop.width()) continue;

      uint32_t srcPixel = srcLine[x];
      int sa_i = getAlphaRGBA(srcPixel);
      if (sa_i <= 0) continue;

      float sa_f = (sa_i / 255.0f) * opacity;
      if (sa_f <= 0.0f) continue;

      uint32_t dstPixel = dstLine[destX];
      int da_i = getAlphaRGBA(dstPixel);
      float da_f = da_i / 255.0f;

      // Un-premultiply source and destination for correct blend math
      float sa_raw = sa_i / 255.0f;
      float sR_U = sa_raw > 1e-7f ? (getRedRGBA(srcPixel) / 255.0f) / sa_raw : 0.0f;
      float sG_U = sa_raw > 1e-7f ? (getGreenRGBA(srcPixel) / 255.0f) / sa_raw : 0.0f;
      float sB_U = sa_raw > 1e-7f ? (getBlueRGBA(srcPixel) / 255.0f) / sa_raw : 0.0f;

      float dR_U = 0.0f, dG_U = 0.0f, dB_U = 0.0f;
      if (da_i > 0) {
        dR_U = (getRedRGBA(dstPixel) / 255.0f) / da_f;
        dG_U = (getGreenRGBA(dstPixel) / 255.0f) / da_f;
        dB_U = (getBlueRGBA(dstPixel) / 255.0f) / da_f;
      }

      float r_blend = 0.0f, g_blend = 0.0f, b_blend = 0.0f;

      if (mode == artflow::BlendMode::Normal) {
        r_blend = sR_U;
        g_blend = sG_U;
        b_blend = sB_U;
      } else if (mode == artflow::BlendMode::Multiply) {
        r_blend = dR_U * sR_U;
        g_blend = dG_U * sG_U;
        b_blend = dB_U * sB_U;
      } else if (mode == artflow::BlendMode::Screen) {
        r_blend = dR_U + sR_U - dR_U * sR_U;
        g_blend = dG_U + sG_U - dG_U * sG_U;
        b_blend = dB_U + sB_U - dB_U * sB_U;
      } else if (mode == artflow::BlendMode::Overlay) {
        auto overlay = [](float b, float s) {
          return (b < 0.5f) ? (2.0f * b * s)
                            : (1.0f - 2.0f * (1.0f - b) * (1.0f - s));
        };
        r_blend = overlay(dR_U, sR_U);
        g_blend = overlay(dG_U, sG_U);
        b_blend = overlay(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::Darken) {
        r_blend = std::min(dR_U, sR_U);
        g_blend = std::min(dG_U, sG_U);
        b_blend = std::min(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::Lighten) {
        r_blend = std::max(dR_U, sR_U);
        g_blend = std::max(dG_U, sG_U);
        b_blend = std::max(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::ColorDodge) {
        auto dodge = [](float b, float s) {
          if (b == 0.0f)
            return 0.0f;
          if (s == 1.0f)
            return 1.0f;
          return std::min(1.0f, b / (1.0f - s));
        };
        r_blend = dodge(dR_U, sR_U);
        g_blend = dodge(dG_U, sG_U);
        b_blend = dodge(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::ColorBurn) {
        auto burn = [](float b, float s) {
          if (b == 1.0f)
            return 1.0f;
          if (s == 0.0f)
            return 0.0f;
          return 1.0f - std::min(1.0f, (1.0f - b) / s);
        };
        r_blend = burn(dR_U, sR_U);
        g_blend = burn(dG_U, sG_U);
        b_blend = burn(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::HardLight) {
        auto hardlight = [](float b, float s) {
          return (s < 0.5f) ? (2.0f * b * s)
                            : (1.0f - 2.0f * (1.0f - b) * (1.0f - s));
        };
        r_blend = hardlight(dR_U, sR_U);
        g_blend = hardlight(dG_U, sG_U);
        b_blend = hardlight(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::SoftLight) {
        auto softlight = [](float b, float s) {
          if (s <= 0.5f)
            return b - (1.0f - 2.0f * s) * b * (1.0f - b);
          float d = (b <= 0.25f) ? (((16.0f * b - 12.0f) * b + 4.0f) * b)
                                 : std::sqrt(b);
          return b + (2.0f * s - 1.0f) * (d - b);
        };
        r_blend = softlight(dR_U, sR_U);
        g_blend = softlight(dG_U, sG_U);
        b_blend = softlight(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::Difference) {
        r_blend = std::abs(dR_U - sR_U);
        g_blend = std::abs(dG_U - sG_U);
        b_blend = std::abs(dB_U - sB_U);
      } else if (mode == artflow::BlendMode::Exclusion) {
        r_blend = dR_U + sR_U - 2.0f * dR_U * sR_U;
        g_blend = dG_U + sG_U - 2.0f * dG_U * sG_U;
        b_blend = dB_U + sB_U - 2.0f * dB_U * sB_U;
      } else if (mode == artflow::BlendMode::GlowDodge) {
        auto glow = [](float b, float s) {
          if (b == 0.0f) return 0.0f;
          if (s == 1.0f) return 1.0f;
          return std::min(1.0f, (b * b) / (1.0f - s));
        };
        r_blend = glow(dR_U, sR_U);
        g_blend = glow(dG_U, sG_U);
        b_blend = glow(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::HardMix) {
        auto hardmix = [](float b, float s) {
          return (b + s >= 1.0f) ? 1.0f : 0.0f;
        };
        r_blend = hardmix(dR_U, sR_U);
        g_blend = hardmix(dG_U, sG_U);
        b_blend = hardmix(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::Divide) {
        auto divide = [](float b, float s) {
          if (s == 0.0f) return 1.0f;
          return std::min(1.0f, b / s);
        };
        r_blend = divide(dR_U, sR_U);
        g_blend = divide(dG_U, sG_U);
        b_blend = divide(dB_U, sB_U);
      } else if (mode == artflow::BlendMode::Hue) {
        // Result: Hue of source, Saturation and Luminosity of backdrop
        r_blend = sR_U; g_blend = sG_U; b_blend = sB_U;
        hslSetSat(r_blend, g_blend, b_blend, hslSaturation(dR_U, dG_U, dB_U));
        hslSetLum(r_blend, g_blend, b_blend, hslLuminosity(dR_U, dG_U, dB_U));
      } else if (mode == artflow::BlendMode::Saturation) {
        // Result: Saturation of source, Hue and Luminosity of backdrop
        r_blend = dR_U; g_blend = dG_U; b_blend = dB_U;
        hslSetSat(r_blend, g_blend, b_blend, hslSaturation(sR_U, sG_U, sB_U));
        hslSetLum(r_blend, g_blend, b_blend, hslLuminosity(dR_U, dG_U, dB_U));
      } else if (mode == artflow::BlendMode::Color) {
        // Result: Hue and Saturation of source, Luminosity of backdrop
        r_blend = sR_U; g_blend = sG_U; b_blend = sB_U;
        hslSetLum(r_blend, g_blend, b_blend, hslLuminosity(dR_U, dG_U, dB_U));
      } else if (mode == artflow::BlendMode::Luminosity) {
        // Result: Luminosity of source, Hue and Saturation of backdrop
        r_blend = dR_U; g_blend = dG_U; b_blend = dB_U;
        hslSetLum(r_blend, g_blend, b_blend, hslLuminosity(sR_U, sG_U, sB_U));
      } else {
        r_blend = sR_U;
        g_blend = sG_U;
        b_blend = sB_U;
      }

      // Compositing
      float finalR = (1.0f - da_f) * sa_f * sR_U + (1.0f - sa_f) * da_f * dR_U + sa_f * da_f * r_blend;
      float finalG = (1.0f - da_f) * sa_f * sG_U + (1.0f - sa_f) * da_f * dG_U + sa_f * da_f * g_blend;
      float finalB = (1.0f - da_f) * sa_f * sB_U + (1.0f - sa_f) * da_f * dB_U + sa_f * da_f * b_blend;

      float outA = sa_f + da_f - sa_f * da_f;

      if (outA > 1e-6f) {
        int outA_i = std::clamp(static_cast<int>(outA * 255.0f), 0, 255);
        int outR_i = std::clamp(static_cast<int>(finalR * 255.0f), 0, outA_i);
        int outG_i = std::clamp(static_cast<int>(finalG * 255.0f), 0, outA_i);
        int outB_i = std::clamp(static_cast<int>(finalB * 255.0f), 0, outA_i);
        dstLine[destX] = makeRGBA(outR_i, outG_i, outB_i, outA_i);
      } else {
        dstLine[destX] = makeRGBA(0, 0, 0, 0);
      }
    }
  }
}

void CanvasItem::paint(QPainter *painter) {
  if (!m_layerManager)
    return;

  // Deferred GL resource cleanup (must happen in render thread with valid GL
  // context)
  cleanupGlResources();

  // Clean up active transform GL textures if we are not transforming anymore
  if (!m_isTransforming) {
    if (m_transformStaticTex) {
      delete m_transformStaticTex;
      m_transformStaticTex = nullptr;
    }
    if (m_selectionTex) {
      delete m_selectionTex;
      m_selectionTex = nullptr;
    }
  }

  // --- El cursor global ya no se fuerza en paint() para permitir que
  // setCursor(Qt::BlankCursor) del CanvasItem funcione y oculte la flecha
  // nativa mientras el usuario dibuja. ---

  // 0. Initialize Composition Shader
  if (!m_compositionShader) {
    m_compositionShader = new QOpenGLShaderProgram();
    QStringList paths;
    paths << ":/src/core/shaders/"
          << QCoreApplication::applicationDirPath() + "/shaders/"
          << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
          << "src/core/shaders/"
          << "../src/core/shaders/";
    QString vertPath, fragPath;
    for (const QString &path : paths) {
      if (QFile::exists(path + "composition.vert") &&
          QFile::exists(path + "composition.frag")) {
        vertPath = path + "composition.vert";
        fragPath = path + "composition.frag";
        break;
      }
    }
    if (!vertPath.isEmpty()) {
      m_compositionShader->addShaderFromSourceFile(QOpenGLShader::Vertex,
                                                   vertPath);
      m_compositionShader->addShaderFromSourceFile(QOpenGLShader::Fragment,
                                                   fragPath);
      m_compositionShader->link();
    } else {
      qWarning() << "Composition shaders not found!";
    }
  }

  // 0c. Initialize Screentone Shader
  if (!m_screentoneShader) {
    m_screentoneShader = new QOpenGLShaderProgram();
    QStringList paths;
    paths << ":/src/core/shaders/"
          << QCoreApplication::applicationDirPath() + "/shaders/"
          << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
          << "src/core/shaders/"
          << "../src/core/shaders/";
    QString vertPath, fragPath;
    for (const QString &path : paths) {
      if (QFile::exists(path + "composition.vert") &&
          QFile::exists(path + "screentone.frag")) {
        vertPath = path + "composition.vert";
        fragPath = path + "screentone.frag";
        break;
      }
    }
    if (!vertPath.isEmpty()) {
      m_screentoneShader->addShaderFromSourceFile(QOpenGLShader::Vertex, vertPath);
      m_screentoneShader->addShaderFromSourceFile(QOpenGLShader::Fragment, fragPath);
      if (!m_screentoneShader->link()) {
        qWarning() << "Screentone shader link failed:" << m_screentoneShader->log();
      }
      QFile debugFile("shader_debug.txt");
      if (debugFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&debugFile);
        out << "Screentone Shader Object Created: " << (m_screentoneShader != nullptr) << "\n";
        out << "Vert Path: " << vertPath << " (exists: " << QFile::exists(vertPath) << ")\n";
        out << "Frag Path: " << fragPath << " (exists: " << QFile::exists(fragPath) << ")\n";
        if (m_screentoneShader) {
          out << "Linked: " << m_screentoneShader->isLinked() << "\n";
          out << "Log: " << m_screentoneShader->log() << "\n";
        }
      }
    } else {
      qWarning() << "Screentone shaders not found!";
      QFile debugFile("shader_debug.txt");
      if (debugFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&debugFile);
        out << "Screentone shaders not found! Paths checked:\n";
        for (const QString &path : paths) {
          out << " - " << path << " (exists: " << QDir(path).exists() << ")\n";
        }
      }
    }
  }

  // 0d. Initialize Gradient Map Shader
  if (!m_gradientMapShader) {
    m_gradientMapShader = new QOpenGLShaderProgram();
    QStringList paths;
    paths << ":/src/core/shaders/"
          << QCoreApplication::applicationDirPath() + "/shaders/"
          << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
          << "src/core/shaders/"
          << "../src/core/shaders/";
    QString vertPath, fragPath;
    for (const QString &path : paths) {
      if (QFile::exists(path + "composition.vert") &&
          QFile::exists(path + "gradientmap.frag")) {
        vertPath = path + "composition.vert";
        fragPath = path + "gradientmap.frag";
        break;
      }
    }
    if (!vertPath.isEmpty()) {
      m_gradientMapShader->addShaderFromSourceFile(QOpenGLShader::Vertex, vertPath);
      m_gradientMapShader->addShaderFromSourceFile(QOpenGLShader::Fragment, fragPath);
      if (!m_gradientMapShader->link()) {
        qWarning() << "Gradient Map shader link failed:" << m_gradientMapShader->log();
      }
    } else {
      qWarning() << "Gradient Map shaders not found!";
    }
  }

  // 0b. Initialize Blit Shader (used for drawing composition result to screen)
  if (!m_transformShader) {
    m_transformShader = new QOpenGLShaderProgram();
    m_transformShader->addShaderFromSourceCode(QOpenGLShader::Vertex,
                                               R"(
        #version 120
        attribute vec2 position;
        attribute vec2 texCoord;
        uniform mat4 MVP;
        varying vec2 vTexCoord;
        void main() {
            gl_Position = MVP * vec4(position, 0.0, 1.0);
            vTexCoord = texCoord;
        }
    )");
    m_transformShader->addShaderFromSourceCode(QOpenGLShader::Fragment,
                                               R"(
        #version 120
        varying vec2 vTexCoord;
        uniform sampler2D tex;
        uniform float opacity;
        void main() {
            gl_FragColor = texture2D(tex, vTexCoord) * opacity;
        }
    )");
    if (!m_transformShader->link()) {
      qWarning() << "Blit shader link failed:" << m_transformShader->log();
    }
  }

  // 1. Inicializar Shaders Premium si es necesario
  if (!m_impastoShader) {
    m_impastoShader = new QOpenGLShaderProgram();

    // Buscar shaders en rutas relativas y absolutas
    QStringList paths;
    paths << ":/src/core/shaders/"
          << QCoreApplication::applicationDirPath() + "/shaders/"
          << QCoreApplication::applicationDirPath() + "/../src/core/shaders/"
          << "src/core/shaders/" // Relative to project root
          << "assets/shaders/";   // If we move shaders later

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

  // 2. Fondo Base (Workspace - Theme Based)
  painter->fillRect(0, 0, width(), height(), m_workspaceColor);

  // ═══ Apply Canvas Rotation (Krita-style free rotation) ═══
  painter->save();
  if (!qFuzzyIsNull(m_canvasRotation)) {
    painter->translate(width() / 2.0, height() / 2.0);
    painter->rotate(m_canvasRotation);
    painter->translate(-width() / 2.0, -height() / 2.0);
  }

  // Calculate generic target rect for background
  QRectF paperRect(m_viewOffset.x() * m_zoomLevel,
                   m_viewOffset.y() * m_zoomLevel, m_canvasWidth * m_zoomLevel,
                   m_canvasHeight * m_zoomLevel);

  // DIBUJAR CHECKERBOARD (Patrón de transparencia)
  // Cache como miembro para no reconstruir en cada frame.
  // Durante transformación con GPU lista, se omite — el static cache ya lo
  // incluye.
  bool skipCheckerForTransform =
      (m_isTransforming && m_transformStaticTex != nullptr);
  if (!skipCheckerForTransform) {
    int checkerSize = std::max(5, (int)(20 * m_zoomLevel));
    if (m_checkerCache.isNull() || m_checkerCachedSize != checkerSize) {
      m_checkerCachedSize = checkerSize;
      m_checkerCache =
          QImage(checkerSize * 2, checkerSize * 2, QImage::Format_ARGB32);
      m_checkerCache.fill(Qt::white);
      QPainter pt(&m_checkerCache);
      pt.fillRect(0, 0, checkerSize, checkerSize, QColor(220, 220, 220));
      pt.fillRect(checkerSize, checkerSize, checkerSize, checkerSize,
                  QColor(220, 220, 220));
      pt.end();
    }

    painter->save();
    painter->setBrush(QBrush(m_checkerCache));
    painter->setBrushOrigin(m_viewOffset.x() * m_zoomLevel,
                            m_viewOffset.y() * m_zoomLevel);
    painter->setPen(Qt::NoPen);
    painter->drawRect(paperRect);
    painter->restore();

    // Draw Background Color (only if not transparent AND the background layer is visible)
    bool isBgVisible = true;
    if (m_layerManager) {
      for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
        artflow::Layer *l = m_layerManager->getLayer(i);
        if (l && l->type == artflow::Layer::Type::Background) {
          isBgVisible = l->visible;
          break;
        }
      }
    }
    if (isBgVisible && m_backgroundColor.alpha() > 0) {
      painter->fillRect(paperRect, m_backgroundColor);
    }
  }

  // Draw Drop Shadow (Optional, for better depth)
  // painter->setPen(Qt::NoPen);
  // painter->setBrush(QColor(0,0,0,50));
  // painter->drawRect(paperRect.translated(5, 5));

  if (m_layerManager->getLayerCount() > 0) {
    QOpenGLContext *ctx = QOpenGLContext::currentContext();
    bool drewNative = false;
    bool gpuTransformReady = false; // Always use QPainter high-fidelity CPU path to prevent FBO viewport shift and vertical flipping bugs

    if (m_isTransforming && gpuTransformReady) {
      painter->beginNativePainting();
      drewNative = true;

      if (m_updateTransformTextures) {
        if (!m_transformShader) {
          m_transformShader = new QOpenGLShaderProgram();
          m_transformShader->addShaderFromSourceCode(QOpenGLShader::Vertex,
                                                     R"(
                      #version 120
                      attribute vec2 position;
                      attribute vec2 texCoord;
                      uniform mat4 MVP;
                      varying vec2 vTexCoord;
                      void main() {
                          gl_Position = MVP * vec4(position, 0.0, 1.0);
                          vTexCoord = texCoord;
                      }
                  )");
          m_transformShader->addShaderFromSourceCode(QOpenGLShader::Fragment,
                                                     R"(
                      #version 120
                      varying vec2 vTexCoord;
                      uniform sampler2D tex;
                      uniform float opacity;
                      void main() {
                          gl_FragColor = texture2D(tex, vTexCoord) * opacity;
                      }
                  )");
          if (!m_transformShader->link()) {
            qWarning() << "Transform shader link failed:"
                       << m_transformShader->log();
          }
        }
        if (m_transformStaticTex) {
          delete m_transformStaticTex;
          m_transformStaticTex = nullptr;
        }
        if (!m_transformStaticCache.isNull()) {
          m_transformStaticTex =
              new QOpenGLTexture(m_transformStaticCache);
          m_transformStaticTex->setMinificationFilter(QOpenGLTexture::Linear);
          m_transformStaticTex->setMagnificationFilter(QOpenGLTexture::Linear);
        }

        if (m_selectionTex) {
          delete m_selectionTex;
          m_selectionTex = nullptr;
        }
        if (!m_selectionBuffer.isNull()) {
          m_selectionTex =
              new QOpenGLTexture(m_selectionBuffer);
          m_selectionTex->setMinificationFilter(QOpenGLTexture::Linear);
          m_selectionTex->setMagnificationFilter(QOpenGLTexture::Linear);
        }

        m_updateTransformTextures = false;
        m_transformStaticCache = QImage(); // Free CPU memory
      }

      if (m_transformShader && m_transformStaticTex && m_selectionTex) {
        QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
        
        // Save current viewport and apply item-local viewport mapping relative to the physical window/FBO size (High-DPI and layout aware)
        GLint prevViewport[4];
        f->glGetIntegerv(GL_VIEWPORT, prevViewport);
        
        double dpr = window() ? window()->devicePixelRatio() : 1.0;
        QPointF scenePos = mapToScene(QPointF(0, 0));
        int devHeight = painter->device()->height();
        int itemX = qRound(scenePos.x() * dpr);
        int itemY = qRound(scenePos.y() * dpr);
        int itemW = qRound(width() * dpr);
        int itemH = qRound(height() * dpr);
        f->glViewport(itemX, devHeight - (itemY + itemH), itemW, itemH);

        f->glEnable(GL_BLEND);
        f->glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        m_transformShader->bind();
        QMatrix4x4 ortho;
        ortho.ortho(0, width(), height(), 0, -1, 1);

        QMatrix4x4 canvasRotMat;
        if (!qFuzzyIsNull(m_canvasRotation)) {
          canvasRotMat.translate(width() / 2.0f, height() / 2.0f);
          canvasRotMat.rotate(m_canvasRotation, 0.0f, 0.0f, 1.0f);
          canvasRotMat.translate(-width() / 2.0f, -height() / 2.0f);
        }

        QMatrix4x4 view;
        view.translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
        view.scale(m_zoomLevel, m_zoomLevel);
        QMatrix4x4 orthoView = ortho * canvasRotMat * view;

        // Draw Static Cache (Background)
        m_transformShader->setUniformValue("MVP", orthoView);
        m_transformShader->setUniformValue("opacity", 1.0f);
        m_transformStaticTex->bind(0);
        m_transformShader->setUniformValue("tex", 0);

        float cw = m_canvasWidth;
        float ch = m_canvasHeight;
        GLfloat bgVertices[] = {
            0, 0,   0, 0,  // Top-Left
            cw, 0,  1, 0,  // Top-Right
            0, ch,  0, 1,  // Bottom-Left

            0, ch,  0, 1,  // Bottom-Left
            cw, 0,  1, 0,  // Top-Right
            cw, ch, 1, 1   // Bottom-Right
        };

        m_transformShader->enableAttributeArray(0);
        m_transformShader->enableAttributeArray(1);
        m_transformShader->setAttributeArray(0, GL_FLOAT, bgVertices, 2,
                                             4 * sizeof(GLfloat));
        m_transformShader->setAttributeArray(1, GL_FLOAT, bgVertices + 2, 2,
                                             4 * sizeof(GLfloat));
        f->glDrawArrays(GL_TRIANGLES, 0, 6);

        m_selectionTex->bind(0);

        if (m_isMeshTransform && m_meshPoints.size() == 16) {
          // Draw Selection Mesh (9 quads = 18 triangles = 54 vertices)
          std::vector<GLfloat> vertices;
          vertices.reserve(54 * 4);

          for (int row = 0; row < 3; ++row) {
            for (int col = 0; col < 3; ++col) {
              int idx_TL = row * 4 + col;
              int idx_TR = row * 4 + col + 1;
              int idx_BR = (row + 1) * 4 + col + 1;
              int idx_BL = (row + 1) * 4 + col;

              QPointF TL = m_meshPoints[idx_TL];
              QPointF TR = m_meshPoints[idx_TR];
              QPointF BR = m_meshPoints[idx_BR];
              QPointF BL = m_meshPoints[idx_BL];

              float u_TL = col / 3.0f;
              float u_TR = (col + 1) / 3.0f;
              float u_BR = (col + 1) / 3.0f;
              float u_BL = col / 3.0f;

              float v_TL = row / 3.0f;
              float v_TR = row / 3.0f;
              float v_BR = (row + 1) / 3.0f;
              float v_BL = (row + 1) / 3.0f;

              // Triangle 1: TL, TR, BL
              vertices.push_back(TL.x()); vertices.push_back(TL.y());
              vertices.push_back(u_TL);   vertices.push_back(v_TL);

              vertices.push_back(TR.x()); vertices.push_back(TR.y());
              vertices.push_back(u_TR);   vertices.push_back(v_TR);

              vertices.push_back(BL.x()); vertices.push_back(BL.y());
              vertices.push_back(u_BL);   vertices.push_back(v_BL);

              // Triangle 2: BL, TR, BR
              vertices.push_back(BL.x()); vertices.push_back(BL.y());
              vertices.push_back(u_BL);   vertices.push_back(v_BL);

              vertices.push_back(TR.x()); vertices.push_back(TR.y());
              vertices.push_back(u_TR);   vertices.push_back(v_TR);

              vertices.push_back(BR.x()); vertices.push_back(BR.y());
              vertices.push_back(u_BR);   vertices.push_back(v_BR);
            }
          }

          m_transformShader->setUniformValue("MVP", orthoView);
          m_transformShader->enableAttributeArray(0);
          m_transformShader->enableAttributeArray(1);
          m_transformShader->setAttributeArray(0, GL_FLOAT, vertices.data(), 2, 4 * sizeof(GLfloat));
          m_transformShader->setAttributeArray(1, GL_FLOAT, vertices.data() + 2, 2, 4 * sizeof(GLfloat));
          f->glDrawArrays(GL_TRIANGLES, 0, 54);

        } else {
          // Draw Selection Frame natively with perspective correction
          QMatrix4x4 qtMat(m_transformMatrix);

          m_transformShader->setUniformValue("MVP", orthoView * qtMat);

          float sw = m_selectionBuffer.width();
          float sh = m_selectionBuffer.height();
          GLfloat selVertices[] = {
              0, 0,   0, 0,  // Top-Left
              sw, 0,  1, 0,  // Top-Right
              0, sh,  0, 1,  // Bottom-Left

              0, sh,  0, 1,  // Bottom-Left
              sw, 0,  1, 0,  // Top-Right
              sw, sh, 1, 1   // Bottom-Right
          };
          m_transformShader->enableAttributeArray(0);
          m_transformShader->enableAttributeArray(1);
          m_transformShader->setAttributeArray(0, GL_FLOAT, selVertices, 2,
                                               4 * sizeof(GLfloat));
          m_transformShader->setAttributeArray(1, GL_FLOAT, selVertices + 2, 2,
                                               4 * sizeof(GLfloat));
          f->glDrawArrays(GL_TRIANGLES, 0, 6);
        }

        m_transformShader->disableAttributeArray(0);
        m_transformShader->disableAttributeArray(1);
        m_transformShader->release();
        
        // Restore viewport to previous state
        f->glViewport(prevViewport[0], prevViewport[1], prevViewport[2], prevViewport[3]);
      }
      painter->endNativePainting();
    } else {
      if (m_layerManager && m_layerManager->getLayerCount() > 0) {
        const int cw = m_canvasWidth;
        const int ch = m_canvasHeight;

        // Check if background layer is visible to determine composition backdrop
        bool isBgVisible = true;
        if (m_layerManager) {
          for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
            artflow::Layer *l = m_layerManager->getLayer(i);
            if (l && l->type == artflow::Layer::Type::Background) {
              isBgVisible = l->visible;
              break;
            }
          }
        }
        bool fillBg = isBgVisible && m_backgroundColor.alpha() > 0;

        // Initialize full cache if size changed or first run
        bool needsFullRedraw = m_cachedCanvasImage.isNull() ||
                               m_cachedCanvasImage.width() != cw ||
                               m_cachedCanvasImage.height() != ch;
        if (needsFullRedraw) {
          m_cachedCanvasImage =
              QImage(cw, ch, QImage::Format_RGBA8888_Premultiplied);
          if (fillBg) {
            m_cachedCanvasImage.fill(m_backgroundColor);
          } else {
            m_cachedCanvasImage.fill(Qt::transparent);
          }
        }

        // Compute union of all dirty rects across dirty layers
        QRect dirtyUnion;
        for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
          Layer *layer = m_layerManager->getLayer(i);
          if (!layer)
            continue;
          if (layer->dirty ||
              (layer->buffer && layer->buffer->hasDirtyTiles())) {
            QRect lr = layer->dirtyRect.isValid() ? layer->dirtyRect
                                                  : QRect(0, 0, cw, ch);
            dirtyUnion = dirtyUnion.isNull() ? lr : dirtyUnion.united(lr);
          }
        }
        if (needsFullRedraw)
          dirtyUnion = QRect(0, 0, cw, ch);

        if (!dirtyUnion.isNull()) {
          m_canvasPreviewBase64 = QString(); // Invalidate base64 cache
          // Clip to canvas bounds
          dirtyUnion = dirtyUnion.intersected(QRect(0, 0, cw, ch));

          QPainter cpuPainter(&m_cachedCanvasImage);
          cpuPainter.setRenderHint(QPainter::Antialiasing, false);
          cpuPainter.setRenderHint(QPainter::SmoothPixmapTransform, false);

          auto getProcessedLayerImage = [&](Layer *lyr, const QImage &srcImg, const QRect &rect) -> QImage {
            if (!lyr) return srcImg;
            if (!lyr->gradientMapEnabled && !lyr->screentoneEnabled) {
              return srcImg;
            }

            QImage processedImg = srcImg.copy();
            
            if (lyr->gradientMapEnabled) {
              qInfo() << "[GradientMap Debug] Processing layer:" << QString::fromStdString(lyr->name)
                      << "Stops:" << lyr->gradientMapStops.size()
                      << "UseCoords:" << lyr->gradientMapUseCoords
                      << "Start:" << lyr->gradientMapStart
                      << "End:" << lyr->gradientMapEnd
                      << "Shape:" << m_gradientShape
                      << "Rect:" << rect;

              int x0 = std::max(0, rect.left());
              int y0 = std::max(0, rect.top());
              int x1 = std::min(cw - 1, rect.right());
              int y1 = std::min(ch - 1, rect.bottom());

              QVariantList stops = lyr->gradientMapStops;
              if (stops.isEmpty()) {
                stops = m_gradientStops;
              }

              struct Stop {
                float position;
                QColor color;
              };
              std::vector<Stop> sortedStops;
              for (const QVariant &val : stops) {
                QVariantMap stopObj = val.toMap();
                float pos = stopObj["position"].toFloat();
                QColor col(stopObj["color"].toString());
                sortedStops.push_back({pos, col});
              }
              std::sort(sortedStops.begin(), sortedStops.end(), [](const auto &a, const auto &b) {
                return a.position < b.position;
              });

              auto getGradientColor = [&](float t) -> QColor {
                if (sortedStops.empty()) return QColor::fromRgbF(t, t, t);
                if (sortedStops.size() == 1) return sortedStops[0].color;
                
                float clampT = qBound(sortedStops.front().position, t, sortedStops.back().position);
                if (clampT <= sortedStops.front().position) return sortedStops.front().color;
                
                for (size_t idx = 0; idx < sortedStops.size() - 1; ++idx) {
                  if (clampT >= sortedStops[idx].position && clampT <= sortedStops[idx+1].position) {
                    float dist = sortedStops[idx+1].position - sortedStops[idx].position;
                    float factor = (dist > 0.0f) ? (clampT - sortedStops[idx].position) / dist : 0.0f;
                    
                    QColor c0 = sortedStops[idx].color;
                    QColor c1 = sortedStops[idx+1].color;
                    return QColor::fromRgbF(
                      c0.redF() + (c1.redF() - c0.redF()) * factor,
                      c0.greenF() + (c1.greenF() - c0.greenF()) * factor,
                      c0.blueF() + (c1.blueF() - c0.blueF()) * factor
                    );
                  }
                }
                return sortedStops.back().color;
              };

              bool useCoords = lyr->gradientMapUseCoords;
              QPointF uStart = lyr->gradientMapStart;
              QPointF uEnd = lyr->gradientMapEnd;
              bool isRadial = (m_gradientShape == "radial");

              for (int y = y0; y <= y1; ++y) {
                for (int x = x0; x <= x1; ++x) {
                  QRgb pixel = processedImg.pixel(x, y);
                  int alpha = qAlpha(pixel);
                  if (alpha < 2) {
                    processedImg.setPixel(x, y, qRgba(0, 0, 0, 0));
                    continue;
                  }
                  
                  float r = qRed(pixel) / (float)alpha;
                  float g = qGreen(pixel) / (float)alpha;
                  float b = qBlue(pixel) / (float)alpha;
                  float luma = 0.299f * r + 0.587f * g + 0.114f * b;
                  luma = qBound(0.0f, luma, 1.0f);
                  
                  float blendFactor = 1.0f;
                  if (useCoords) {
                    QPointF pixelPos(x, y);
                    if (isRadial) {
                      float radius = QLineF(uStart, uEnd).length();
                      float dist = QLineF(uStart, pixelPos).length();
                      float t = (radius > 0.0f) ? dist / radius : 0.0f;
                      blendFactor = 1.0f - qBound(0.0f, t, 1.0f);
                    } else { // linear
                      QPointF dir = uEnd - uStart;
                      float lenSq = dir.x() * dir.x() + dir.y() * dir.y();
                      float t = 0.0f;
                      if (lenSq > 0.0f) {
                        QPointF diff = pixelPos - uStart;
                        t = (diff.x() * dir.x() + diff.y() * dir.y()) / lenSq;
                      }
                      blendFactor = 1.0f - qBound(0.0f, t, 1.0f);
                    }
                  }
                  
                  QColor mappedColor = getGradientColor(luma);
                  float finalR = r + (mappedColor.redF() - r) * blendFactor;
                  float finalG = g + (mappedColor.greenF() - g) * blendFactor;
                  float finalB = b + (mappedColor.blueF() - b) * blendFactor;
                  
                  int outR = qBound(0, qRound(finalR * alpha), 255);
                  int outG = qBound(0, qRound(finalG * alpha), 255);
                  int outB = qBound(0, qRound(finalB * alpha), 255);
                  processedImg.setPixel(x, y, qRgba(outR, outG, outB, alpha));
                }
              }
            }

            if (lyr->screentoneEnabled) {
              int x0 = std::max(0, rect.left());
              int y0 = std::max(0, rect.top());
              int x1 = std::min(cw - 1, rect.right());
              int y1 = std::min(ch - 1, rect.bottom());

              float rad = lyr->screentoneAngle;
              float c = std::cos(rad);
              float s = std::sin(rad);
              float dotSize = lyr->screentoneDotSize;
              if (dotSize < 1.0f) dotSize = 1.0f;

              for (int y = y0; y <= y1; ++y) {
                for (int x = x0; x <= x1; ++x) {
                  QRgb pixel = processedImg.pixel(x, y);
                  int alpha = qAlpha(pixel);
                  if (alpha < 2) {
                    processedImg.setPixel(x, y, qRgba(0, 0, 0, 0));
                    continue;
                  }
                  
                  float r = qRed(pixel) / (float)alpha;
                  float g = qGreen(pixel) / (float)alpha;
                  float b = qBlue(pixel) / (float)alpha;
                  float luma = 0.299f * r + 0.587f * g + 0.114f * b;
                  if (luma > 1.0f) luma = 1.0f;
                  if (luma < 0.0f) luma = 0.0f;
                  
                  float rx = x * c - y * s;
                  float ry = x * s + y * c;
                  float dotAlpha = 0.0f;
                  
                  if (lyr->screentoneType == 0) {
                    float fx = (rx / dotSize) - std::floor(rx / dotSize) - 0.5f;
                    float fy = (ry / dotSize) - std::floor(ry / dotSize) - 0.5f;
                    float distToCenter = std::sqrt(fx * fx + fy * fy);
                    float targetRadius = 0.5f * (1.0f - luma);
                    float transitionWidth = 0.05f + 0.45f * (1.0f - lyr->screentoneContrast);
                    
                    float edge0 = targetRadius - transitionWidth;
                    float edge1 = targetRadius + transitionWidth;
                    if (distToCenter <= edge0) {
                      dotAlpha = 1.0f;
                    } else if (distToCenter >= edge1) {
                      dotAlpha = 0.0f;
                    } else {
                      float t = (distToCenter - edge0) / (edge1 - edge0);
                      dotAlpha = 1.0f - (t * t * (3.0f - 2.0f * t));
                    }
                  } else if (lyr->screentoneType == 1) {
                    float fx = (rx / dotSize) - std::floor(rx / dotSize) - 0.5f;
                    float distToLine = std::abs(fx);
                    float targetWidth = 0.5f * (1.0f - luma);
                    float transitionWidth = 0.05f + 0.45f * (1.0f - lyr->screentoneContrast);
                    
                    float edge0 = targetWidth - transitionWidth;
                    float edge1 = targetWidth + transitionWidth;
                    if (distToLine <= edge0) {
                      dotAlpha = 1.0f;
                    } else if (distToLine >= edge1) {
                      dotAlpha = 0.0f;
                    } else {
                      float t = (distToLine - edge0) / (edge1 - edge0);
                      dotAlpha = 1.0f - (t * t * (3.0f - 2.0f * t));
                    }
                  } else {
                    float grainSize = dotSize * 0.25f;
                    if (grainSize < 1.0f) grainSize = 1.0f;
                    int gx = (int)(x / grainSize);
                    int gy = (int)(y / grainSize);
                    
                    float randVal = std::sin(gx * 12.9898f + gy * 78.233f) * 43758.5453f;
                    randVal = randVal - std::floor(randVal);
                    dotAlpha = (randVal > luma) ? 1.0f : 0.0f;
                  }
                  
                  int outAlpha = (int)(dotAlpha * alpha);
                  processedImg.setPixel(x, y, qRgba(0, 0, 0, outAlpha));
                }
              }
            }

            return processedImg;
          };

          auto drawLayerWithBlend = [&](QPainter &painter, QImage &destImg, Layer *lyr, const QPoint &targetPos, const QRect &rect) {
            if (!lyr || !lyr->visible || !lyr->buffer || !lyr->buffer->data())
              return;

            QImage srcImg(lyr->buffer->data(), cw, ch, QImage::Format_RGBA8888_Premultiplied);
            QImage finalSrcImg = getProcessedLayerImage(lyr, srcImg, rect);

            float effectiveOpacity = lyr->opacity;
            QTransform animTransform;
            bool isAnimated = false;

            if (m_animationManager) {
              for (const auto& track : m_animationManager->getTracks()) {
                bool trackControlsLayer = false;
                for (const auto& pair : track.getKeyframes()) {
                  if (pair.second.getLayerRef() == lyr) {
                    trackControlsLayer = true;
                    break;
                  }
                }
                
                if (trackControlsLayer) {
                  AnimationFrame frame = const_cast<AnimationTrack&>(track).getFrame(m_animationManager->currentFrame());
                  effectiveOpacity = frame.getOpacity() * lyr->opacity;
                  animTransform = frame.getTransform();
                  isAnimated = true;
                  break;
                }
              }
            }

            painter.save();
            if (isAnimated) {
              painter.setTransform(animTransform, true);
            }
            // Apply per-layer display offset for CPU fallback path
            painter.translate(lyr->offsetX, lyr->offsetY);

            // Use software blender for all non-Normal modes to ensure mathematically correct W3C alpha compositing
            if (lyr->blendMode != artflow::BlendMode::Normal) {
              painter.end();
              if (isAnimated) {
                QImage tempImg(cw, ch, QImage::Format_RGBA8888_Premultiplied);
                tempImg.fill(Qt::transparent);
                QPainter tempPainter(&tempImg);
                tempPainter.setTransform(animTransform);
                tempPainter.drawImage(0, 0, finalSrcImg);
                tempPainter.end();
                blendImagesCustom(destImg, tempImg, rect, targetPos, lyr->blendMode, effectiveOpacity);
              } else {
                blendImagesCustom(destImg, finalSrcImg, rect, targetPos, lyr->blendMode, effectiveOpacity);
              }
              painter.begin(&destImg);
              painter.setRenderHint(QPainter::Antialiasing, false);
              painter.setRenderHint(QPainter::SmoothPixmapTransform, false);
            } else {
              painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
              painter.setOpacity(effectiveOpacity);
              painter.drawImage(targetPos, finalSrcImg, rect);
            }
            painter.restore();
          };

          // Clear only the dirty region to transparent or background color
          cpuPainter.setCompositionMode(QPainter::CompositionMode_Source);
          if (fillBg) {
            cpuPainter.fillRect(dirtyUnion, m_backgroundColor);
          } else {
            cpuPainter.fillRect(dirtyUnion, Qt::transparent);
          }

          // Re-composite all visible layers over the dirty region only
          cpuPainter.setCompositionMode(QPainter::CompositionMode_SourceOver);

          for (int i = 0; i < m_layerManager->getLayerCount();) {
            Layer *baseLayer = m_layerManager->getLayer(i);

            // Advance if base layer is clipped but has no base (invalid state)
            if (!baseLayer || baseLayer->clipped) {
              if (baseLayer) {
                baseLayer->dirty = false;
                baseLayer->dirtyRect = QRect();
                if (baseLayer->buffer)
                  baseLayer->buffer->clearDirtyFlags();
              }
              i++;
              continue;
            }

            // Normal Base Layer
            int nextIdx = i + 1;
            bool hasClippingGroup = false;
            while (nextIdx < m_layerManager->getLayerCount()) {
              Layer *cl = m_layerManager->getLayer(nextIdx);
              if (cl && cl->clipped) {
                hasClippingGroup = true;
                nextIdx++;
              } else {
                break;
              }
            }

            // Draw base layer normally if visible (only if it has no clipping group!)
            if (baseLayer->visible && baseLayer->buffer &&
                baseLayer->buffer->data()) {
              if (!hasClippingGroup) {
                if (!(m_isLiquifying && i == m_activeLayerIndex)) {
                  drawLayerWithBlend(cpuPainter, m_cachedCanvasImage, baseLayer, dirtyUnion.topLeft(), dirtyUnion);
                }
              }
            }

            baseLayer->dirty = false;
            baseLayer->dirtyRect = QRect();
            if (baseLayer->buffer)
              baseLayer->buffer->clearDirtyFlags();

            // Process clipping group if exists
            if (hasClippingGroup) {
              if (baseLayer->visible && baseLayer->buffer &&
                  baseLayer->buffer->data()) {
                QImage rawBaseImg(baseLayer->buffer->data(), cw, ch,
                               QImage::Format_RGBA8888_Premultiplied);
                QImage baseImg = getProcessedLayerImage(baseLayer, rawBaseImg, dirtyUnion);

                // Copy the base layer's content corresponding to the dirty union first!
                QImage groupImg = baseImg.copy(dirtyUnion);

                QPainter groupPainter(&groupImg);
                groupPainter.setRenderHint(QPainter::SmoothPixmapTransform,
                                           false);
                groupPainter.setRenderHint(QPainter::Antialiasing, false);

                for (int k = i + 1; k < nextIdx; ++k) {
                  Layer *cLayer = m_layerManager->getLayer(k);
                  if (cLayer && cLayer->visible && cLayer->buffer &&
                      cLayer->buffer->data()) {
                    if (!(m_isLiquifying && k == m_activeLayerIndex)) {
                      drawLayerWithBlend(groupPainter, groupImg, cLayer, QPoint(0, 0), dirtyUnion);
                    }
                  }
                  if (cLayer) {
                    cLayer->dirty = false;
                    cLayer->dirtyRect = QRect();
                    if (cLayer->buffer)
                      cLayer->buffer->clearDirtyFlags();
                  }
                }

                // Mask the group with the base layer's alpha and opacity
                groupPainter.setCompositionMode(
                    QPainter::CompositionMode_DestinationIn);
                groupPainter.setOpacity(baseLayer->opacity);
                groupPainter.drawImage(QPoint(0, 0), baseImg, dirtyUnion);
                groupPainter.end();

                // Draw the entire clipped group over the canvas
                cpuPainter.setOpacity(1.0f);
                cpuPainter.drawImage(dirtyUnion.topLeft(), groupImg);

                // Draw panel border on top of the clipped artwork
                if (QString::fromStdString(baseLayer->name).startsWith("Panel ", Qt::CaseInsensitive)) {
                  QImage borderImg = baseImg.copy(dirtyUnion);
                  for (int y = 0; y < borderImg.height(); ++y) {
                    QRgb *row = reinterpret_cast<QRgb*>(borderImg.scanLine(y));
                    for (int x = 0; x < borderImg.width(); ++x) {
                      QRgb px = row[x];
                      int alpha = qAlpha(px);
                      int r = qRed(px);
                      int g = qGreen(px);
                      int b = qBlue(px);
                      // If it's a fill pixel (white/light), make it transparent
                      if (alpha > 0 && r >= 250 && g >= 250 && b >= 250) {
                        row[x] = qRgba(0, 0, 0, 0);
                      }
                    }
                  }
                  cpuPainter.setOpacity(baseLayer->opacity);
                  cpuPainter.drawImage(dirtyUnion.topLeft(), borderImg);
                }
              } else {
                // Base layer invisible, just clear dirty flags for clipped
                // layers
                for (int k = i + 1; k < nextIdx; ++k) {
                  Layer *cLayer = m_layerManager->getLayer(k);
                  if (cLayer) {
                    cLayer->dirty = false;
                    cLayer->dirtyRect = QRect();
                    if (cLayer->buffer)
                      cLayer->buffer->clearDirtyFlags();
                  }
                }
              }
            }

            i = nextIdx;
          }
          cpuPainter.end();
        }

        QRectF targetRect(m_viewOffset.x() * m_zoomLevel,
                          m_viewOffset.y() * m_zoomLevel, cw * m_zoomLevel,
                          ch * m_zoomLevel);
        painter->setRenderHint(QPainter::SmoothPixmapTransform,
                               m_zoomLevel < 1.0f);
        painter->drawImage(targetRect, m_cachedCanvasImage);
        drawActivePanelOverlay(painter);
      }
    }

    // --- FALLBACK DRAWING FOR TRANSFORMATION ---
    // Si estamos transformando pero la GPU aún no está lista, dibujamos la selección con QPainter
    if (m_isTransforming && !gpuTransformReady && !m_selectionBuffer.isNull()) {
      Layer *activeL = m_layerManager->getActiveLayer();
      if (activeL && activeL->type != Layer::Type::Vector) {
        painter->save();
        painter->translate(m_viewOffset.x() * m_zoomLevel,
                           m_viewOffset.y() * m_zoomLevel);
        painter->scale(m_zoomLevel, m_zoomLevel);

        painter->setRenderHint(QPainter::SmoothPixmapTransform);
        painter->setRenderHint(QPainter::Antialiasing);

        if (m_isMeshTransform && m_meshPoints.size() == 16) {
          QImage tempImg(m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888_Premultiplied);
          tempImg.fill(Qt::transparent);

          float sw = m_selectionBuffer.width();
          float sh = m_selectionBuffer.height();

          for (int row = 0; row < 3; ++row) {
            for (int col = 0; col < 3; ++col) {
              int idx_TL = row * 4 + col;
              int idx_TR = row * 4 + col + 1;
              int idx_BR = (row + 1) * 4 + col + 1;
              int idx_BL = (row + 1) * 4 + col;

              QPointF TL = m_meshPoints[idx_TL];
              QPointF TR = m_meshPoints[idx_TR];
              QPointF BR = m_meshPoints[idx_BR];
              QPointF BL = m_meshPoints[idx_BL];

              QPolygonF dstPolygon;
              dstPolygon << TL << TR << BR << BL;

              QPolygonF srcPolygon;
              srcPolygon << QPointF(col * sw / 3.0f, row * sh / 3.0f)
                         << QPointF((col + 1) * sw / 3.0f, row * sh / 3.0f)
                         << QPointF((col + 1) * sw / 3.0f, (row + 1) * sh / 3.0f)
                         << QPointF(col * sw / 3.0f, (row + 1) * sh / 3.0f);

              warpQuadBilinear(m_selectionBuffer, tempImg, srcPolygon, dstPolygon, m_canvasWidth, m_canvasHeight);
            }
          }
          painter->drawImage(0, 0, tempImg);
        } else if (m_meshPoints.size() == 4) { // Perspective mode preview
          QImage tempImg(m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888_Premultiplied);
          tempImg.fill(Qt::transparent);

          float sw = m_selectionBuffer.width();
          float sh = m_selectionBuffer.height();

          QPolygonF srcPolygon;
          srcPolygon << QPointF(0, 0) << QPointF(sw, 0) << QPointF(sw, sh) << QPointF(0, sh);

          QPolygonF dstPolygon;
          for (int i = 0; i < 4; ++i) {
            dstPolygon << m_meshPoints[i];
          }

          warpQuadBilinear(m_selectionBuffer, tempImg, srcPolygon, dstPolygon, m_canvasWidth, m_canvasHeight);
          painter->drawImage(0, 0, tempImg);
        } else { // Free transform (affine)
          painter->setTransform(m_transformMatrix * painter->transform());
          painter->drawImage(0, 0, m_selectionBuffer);
        }
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

    // If active layer is a vector layer, draw its curves control/anchor points overlay!
    Layer *layer = m_layerManager->getActiveLayer();
    if (layer && layer->type == Layer::Type::Vector && layer->vectorData) {
      QTransform t;
      t.translate(m_transformBox.x(), m_transformBox.y());
      t = t * m_transformMatrix;
      t.translate(-m_transformBox.x(), -m_transformBox.y());

      painter->setRenderHint(QPainter::Antialiasing);

      for (const auto& stroke : layer->vectorData->getStrokes()) {
        for (const auto& seg : stroke.segments) {
          QPointF p0 = t.map(QPointF(seg.p0.x, seg.p0.y));
          QPointF cp1 = t.map(QPointF(seg.cp1.x, seg.cp1.y));
          QPointF cp2 = t.map(QPointF(seg.cp2.x, seg.cp2.y));
          QPointF p3 = t.map(QPointF(seg.p3.x, seg.p3.y));

          // Draw dotted lines from endpoints to control points
          painter->setPen(QPen(QColor(0, 122, 255, 120), 1.0f / m_zoomLevel, Qt::DashLine));
          painter->drawLine(p0, cp1);
          painter->drawLine(p3, cp2);

          // Draw control points cp1 and cp2 as small squares with blue borders
          painter->setPen(QPen(QColor(0, 122, 255), 1.0f / m_zoomLevel));
          painter->setBrush(QColor(255, 255, 255));
          float rControl = 3.0f / m_zoomLevel;
          painter->drawRect(QRectF(cp1.x() - rControl, cp1.y() - rControl, rControl * 2, rControl * 2));
          painter->drawRect(QRectF(cp2.x() - rControl, cp2.y() - rControl, rControl * 2, rControl * 2));

          // Draw main anchors as solid blue circles
          painter->setBrush(QColor(0, 122, 255));
          float rAnchor = 4.0f / m_zoomLevel;
          painter->drawEllipse(p0, rAnchor, rAnchor);
          painter->drawEllipse(p3, rAnchor, rAnchor);
        }
      }
    }

    // Draw Bounding Box handles
    painter->setTransform(QTransform()); // Reset for handles (screen
                                         // space?) or keep in canvas?
    // Better to draw handles in screen space for consistency
    painter->restore();

    // Screen space deals for handles
    painter->save();
    QRectF screenBox = m_transformMatrix.mapRect(m_transformBox);
    // ... draw handles ...
    painter->restore();
  }

  // 4. Panel Cut Preview (Cuchilla)
  if (m_isPanelCutting) {
    painter->save();
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QPen cutPen(Qt::red, 2.0f / m_zoomLevel, Qt::DashLine);
    painter->setPen(cutPen);
    painter->drawLine(m_panelCutStartPos, m_panelCutEndPos);

    // Draw gutter preview
    QPen gutterPen(QColor(255, 0, 0, 50), m_panelGutterSize, Qt::SolidLine);
    painter->setPen(gutterPen);
    painter->drawLine(m_panelCutStartPos, m_panelCutEndPos);

    // Draw HUD text bubble near m_panelCutEndPos
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setRenderHint(QPainter::TextAntialiasing);
    
    double dx = m_panelCutEndPos.x() - m_panelCutStartPos.x();
    double dy = m_panelCutEndPos.y() - m_panelCutStartPos.y();
    double dist = std::hypot(dx, dy);
    if (dist > 5.0) {
      double deg = std::atan2(dy, dx) * 180.0 / M_PI;
      if (deg < 0) deg += 360.0;
      
      bool snapped = false;
      double snappedDeg = deg;
      double minDiff = 360.0;
      std::vector<double> targets = { 0, 30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330, 360 };
      for (double target : targets) {
          double diff = std::abs(deg - target);
          if (diff < minDiff) {
              minDiff = diff;
              snappedDeg = target;
          }
      }
      if (minDiff <= 5.0) {
          snapped = true;
          deg = snappedDeg;
      }
      
      QString text = QString::number(deg, 'f', 0) + "°";
      if (snapped) text += " (Snap)";
      
      QFont font("Inter", 11);
      painter->setFont(font);
      QFontMetrics fm(font);
      QRectF textRect = fm.boundingRect(text);
      textRect.adjust(-8, -4, 8, 4);
      
      QPointF hudPos = m_panelCutEndPos + QPointF(20.0f / m_zoomLevel, 20.0f / m_zoomLevel);
      textRect.moveCenter(hudPos);
      
      painter->setBrush(QColor(20, 20, 25, 220));
      painter->setPen(QPen(snapped ? QColor(52, 199, 89) : QColor(140, 140, 150), 1.2f / m_zoomLevel));
      painter->drawRoundedRect(textRect, 6.0f / m_zoomLevel, 6.0f / m_zoomLevel);
      
      painter->setPen(snapped ? QColor(52, 199, 89) : Qt::white);
      painter->drawText(textRect, Qt::AlignCenter, text);
    }
    painter->restore();

    painter->restore();
  }

  // 4.1. Gradient Tool Drag Preview
  if (m_tool == ToolType::Gradient && m_isGradientDragging) {
    painter->save();
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);
    painter->setRenderHint(QPainter::Antialiasing);

    // Draw shadow line
    QPen shadowPen(QColor(0, 0, 0, 150), 3.0f / m_zoomLevel, Qt::SolidLine);
    painter->setPen(shadowPen);
    painter->drawLine(m_gradientStartPos, m_gradientEndPos);

    // Draw white line
    QPen linePen(Qt::white, 1.5f / m_zoomLevel, Qt::SolidLine);
    painter->setPen(linePen);
    painter->drawLine(m_gradientStartPos, m_gradientEndPos);

    // Draw handles
    float handleSize = 6.0f / m_zoomLevel;

    // Shadows
    painter->setBrush(QColor(0, 0, 0, 150));
    painter->setPen(Qt::NoPen);
    painter->drawEllipse(m_gradientStartPos, handleSize + 1.0f / m_zoomLevel, handleSize + 1.0f / m_zoomLevel);
    painter->drawEllipse(m_gradientEndPos, handleSize + 1.0f / m_zoomLevel, handleSize + 1.0f / m_zoomLevel);

    // White ellipses with accent color border
    painter->setBrush(Qt::white);
    painter->setPen(QPen(m_accentColor, 1.5f / m_zoomLevel));
    painter->drawEllipse(m_gradientStartPos, handleSize, handleSize);
    painter->drawEllipse(m_gradientEndPos, handleSize, handleSize);

    // Center dot for start anchor
    painter->setBrush(m_accentColor);
    painter->setPen(Qt::NoPen);
    painter->drawEllipse(m_gradientStartPos, handleSize * 0.4f, handleSize * 0.4f);

    painter->restore();
  }

  // 5. Selection (Lasso) Feedback — Marching Ants on committed path
  if (!m_selectionPath.isEmpty()) {
    painter->save();
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    static float dashOffset = 0;
    dashOffset += 0.2f;
    if (dashOffset > 20) dashOffset = 0;

    // Solid white base
    QPen whitePen(Qt::white, 1.5f / m_zoomLevel, Qt::SolidLine);
    painter->setPen(whitePen);
    painter->drawPath(m_selectionPath);

    // Dashed marching ants accent
    QColor lassoColor = m_accentColor;
    if (lassoColor.value() < 50) lassoColor = QColor(80, 160, 255);
    QPen dashPen(lassoColor, 1.5f / m_zoomLevel, Qt::CustomDashLine);
    dashPen.setDashPattern({4, 4});
    dashPen.setDashOffset(dashOffset);
    painter->setPen(dashPen);
    painter->drawPath(m_selectionPath);

    // Tinted fill overlay for the committed selection
    painter->setPen(Qt::NoPen);
    painter->setBrush(QColor(lassoColor.red(), lassoColor.green(), lassoColor.blue(), 25));
    painter->drawPath(m_selectionPath);

    painter->restore();

    if (!m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
  }

  // 5.1 In-progress lasso path (while drawing / polygonal)
  if (m_activeLassoPath.elementCount() > 0) {
    painter->save();
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QColor lassoColor = m_accentColor;
    if (lassoColor.value() < 50) lassoColor = QColor(80, 160, 255);

    // Draw completed segments so far
    QPen activePen(lassoColor, 1.5f / m_zoomLevel, Qt::SolidLine);
    painter->setPen(activePen);
    painter->setBrush(Qt::NoBrush);
    painter->drawPath(m_activeLassoPath);

    // Rubber-band line from last point to cursor
    if (m_tool == ToolType::Lasso && m_lassoMode == 1) {
      QPointF lastPt = m_activeLassoPath.currentPosition();
      QPen rubberPen(lassoColor, 1.2f / m_zoomLevel, Qt::DashLine);
      rubberPen.setDashPattern({3, 3});
      painter->setPen(rubberPen);
      painter->drawLine(lastPt, m_lassoCursorPos);

      // Closing rubber-band to start
      QPointF startPt = m_activeLassoPath.elementAt(0);
      const float snapRadius = 12.0f / m_zoomLevel;
      if (QLineF(m_lassoCursorPos, startPt).length() < snapRadius) {
        // Snap circle: highlight first vertex when near
        painter->setPen(QPen(Qt::white, 2.0f / m_zoomLevel));
        painter->setBrush(QColor(lassoColor.red(), lassoColor.green(), lassoColor.blue(), 180));
        painter->drawEllipse(startPt, snapRadius, snapRadius);
      } else {
        // First vertex marker
        painter->setPen(QPen(Qt::white, 1.5f / m_zoomLevel));
        painter->setBrush(lassoColor);
        float markerR = 4.0f / m_zoomLevel;
        painter->drawEllipse(startPt, markerR, markerR);
      }
    } else if (m_tool == ToolType::MagneticLasso) {
      QPen rubberPen(lassoColor, 1.2f / m_zoomLevel, Qt::DashLine);
      rubberPen.setDashPattern({3, 3});
      painter->setPen(rubberPen);
      if (!m_magneticPreviewPath.isEmpty()) {
        painter->drawPath(m_magneticPreviewPath);
      } else {
        painter->drawLine(m_activeLassoPath.currentPosition(), m_lassoCursorPos);
      }

      // Closing rubber-band to start
      QPointF startPt = m_activeLassoPath.elementAt(0);
      const float snapRadius = 12.0f / m_zoomLevel;
      if (QLineF(m_lassoCursorPos, startPt).length() < snapRadius) {
        // Snap circle: highlight first vertex when near
        painter->setPen(QPen(Qt::white, 2.0f / m_zoomLevel));
        painter->setBrush(QColor(lassoColor.red(), lassoColor.green(), lassoColor.blue(), 180));
        painter->drawEllipse(startPt, snapRadius, snapRadius);
      } else {
        // First vertex marker
        painter->setPen(QPen(Qt::white, 1.5f / m_zoomLevel));
        painter->setBrush(lassoColor);
        float markerR = 4.0f / m_zoomLevel;
        painter->drawEllipse(startPt, markerR, markerR);
      }
    } else if (m_tool == ToolType::Lasso && m_lassoMode == 0 && m_isLassoDragging) {
      // Freehand: dashed closing rubber-band to start
      QPointF startPt = m_activeLassoPath.elementAt(0);
      QPen closingPen(lassoColor, 1.0f / m_zoomLevel, Qt::DotLine);
      painter->setPen(closingPen);
      painter->drawLine(m_activeLassoPath.currentPosition(), startPt);
    }

    // Live rect preview
    if ((m_tool == ToolType::RectSelect || m_tool == ToolType::EllipseSelect)
         && m_isLassoDragging) {
      QRectF previewRect = QRectF(m_selectionStartPos, m_lassoCursorPos).normalized();
      QPen previewPen(lassoColor, 1.5f / m_zoomLevel, Qt::DashLine);
      previewPen.setDashPattern({4, 4});
      painter->setPen(previewPen);
      painter->setBrush(QColor(lassoColor.red(), lassoColor.green(), lassoColor.blue(), 18));
      if (m_tool == ToolType::RectSelect)
        painter->drawRect(previewRect);
      else
        painter->drawEllipse(previewRect);
    }

    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // 🎯 LÍNEAS DE GUÍA DE SIMETRÍA (SYMMETRY GUIDES)
  // ══════════════════════════════════════════════════════════════
  if (m_symmetryEnabled) {
    painter->save();
    // Transformar al espacio de la cámara
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QPen symPen(QColor(100, 150, 255, 120), 1.5f / m_zoomLevel, Qt::DashLine);
    painter->setPen(symPen);

    QPointF center(m_canvasWidth / 2.0f, m_canvasHeight / 2.0f);

    if (m_symmetryMode == 0 || m_symmetryMode == 2) {
      // Vertical line (Left/Right)
      painter->drawLine(QPointF(center.x(), 0),
                        QPointF(center.x(), m_canvasHeight));
    }
    if (m_symmetryMode == 1 || m_symmetryMode == 2) {
      // Horizontal line (Top/Bottom)
      painter->drawLine(QPointF(0, center.y()),
                        QPointF(m_canvasWidth, center.y()));
    }
    if (m_symmetryMode == 3) {
      // Radial lines
      int segments = m_symmetrySegments;
      if (segments < 1)
        segments = 6;
      for (int i = 0; i < segments; ++i) {
        float angle = (2.0f * M_PI * i) / segments;
        QPointF endPoint(center.x() + m_canvasWidth * std::cos(angle),
                         center.y() + m_canvasWidth * std::sin(angle));
        painter->drawLine(center, endPoint);
      }
    }
    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // 📐 REGLAS Y GUÍAS DE PERSPECTIVA (PERSPECTIVE GUIDES)
  // ══════════════════════════════════════════════════════════════
  if (m_perspectiveRuler && m_perspectiveRuler->active()) {
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    
    // Transformar al espacio de la cámara
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QColor guideColor(m_accentColor.red(), m_accentColor.green(), m_accentColor.blue(), 90);
    QPen guidePen(guideColor, 1.0f / m_zoomLevel, Qt::SolidLine);
    QPen horizonPen(QColor("#54a0ff"), 1.5f / m_zoomLevel, Qt::DashLine); // Horizon line

    QPointF vp1 = m_perspectiveRuler->vp1();
    QPointF vp2 = m_perspectiveRuler->vp2();
    QPointF vp3 = m_perspectiveRuler->vp3();

    // 1. Draw Horizon Line
    if (m_perspectiveRuler->vp1Active() && m_perspectiveRuler->vp2Active()) {
      painter->setPen(horizonPen);
      painter->drawLine(vp1, vp2);
    } else if (m_perspectiveRuler->vp1Active()) {
      painter->setPen(horizonPen);
      painter->drawLine(QPointF(-10000, vp1.y()), QPointF(10000, vp1.y()));
    } else if (m_perspectiveRuler->vp2Active()) {
      painter->setPen(horizonPen);
      painter->drawLine(QPointF(-10000, vp2.y()), QPointF(10000, vp2.y()));
    }

    // 2. Draw radiating guidelines for each active vanishing point
    auto drawRadiatingLines = [&](const QPointF& vp) {
      painter->setPen(guidePen);
      for (int angleDeg = 0; angleDeg < 360; angleDeg += 15) {
        double angleRad = angleDeg * 3.141592653589793 / 180.0;
        double length = 5000.0;
        QPointF endPoint = vp + QPointF(std::cos(angleRad) * length, std::sin(angleRad) * length);
        painter->drawLine(vp, endPoint);
      }
    };

    if (m_perspectiveRuler->vp1Active() && m_perspectiveRuler->type() >= 1) {
      drawRadiatingLines(vp1);
    }
    if (m_perspectiveRuler->vp2Active() && m_perspectiveRuler->type() >= 2) {
      drawRadiatingLines(vp2);
    }
    if (m_perspectiveRuler->vp3Active() && m_perspectiveRuler->type() >= 3) {
      drawRadiatingLines(vp3);
    }

    // 3. Draw Vanishing Point circular handles
    auto drawVpHandle = [&](const QPointF& vp, const QString& label) {
      painter->setPen(Qt::NoPen);
      painter->setBrush(QColor(m_accentColor.red(), m_accentColor.green(), m_accentColor.blue(), 40));
      painter->drawEllipse(vp, 14.0f / m_zoomLevel, 14.0f / m_zoomLevel);

      painter->setBrush(m_accentColor);
      painter->drawEllipse(vp, 6.0f / m_zoomLevel, 6.0f / m_zoomLevel);

      painter->setPen(QPen(Qt::white, 1.0f / m_zoomLevel));
      QFont font = painter->font();
      font.setPointSizeF(10.0f / m_zoomLevel);
      painter->setFont(font);
      painter->drawText(vp + QPointF(10.0f / m_zoomLevel, -10.0f / m_zoomLevel), label);
    };

    bool showHandles = false;
    if (m_layerManager) {
      artflow::Layer *activeL = m_layerManager->getActiveLayer();
      if (activeL && activeL->name == "Capa no destructiva") {
        showHandles = true;
      }
    }

    if (showHandles) {
      if (m_perspectiveRuler->vp1Active() && m_perspectiveRuler->type() >= 1) {
        drawVpHandle(vp1, "VP 1");
      }
      if (m_perspectiveRuler->vp2Active() && m_perspectiveRuler->type() >= 2) {
        drawVpHandle(vp2, "VP 2");
      }
      if (m_perspectiveRuler->vp3Active() && m_perspectiveRuler->type() >= 3) {
        drawVpHandle(vp3, "VP 3");
      }
    }

    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // 💬 INTELIGENTE GLOBO DE DIÁLOGO VECTORIAL (SPEECH BALLOON)
  // ══════════════════════════════════════════════════════════════
  if (m_hasActiveSpeechBalloon) {
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);

    // Transform to camera/canvas coordinates
    painter->translate(m_viewOffset.x() * m_zoomLevel, m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QPainterPath path = m_activeSpeechBalloon.generateVectorPath();

    // 1. Draw solid white background with slight translucent opacity for layout preview
    painter->fillPath(path, QColor(255, 255, 255, 215));

    // 2. Draw outline preview
    QPen pen(QColor(0, 122, 255), 2.0f / m_zoomLevel);
    painter->setPen(pen);
    painter->drawPath(path);

    // 3. Draw Bezier control lines for tail
    painter->setPen(QPen(QColor(0, 122, 255, 120), 1.0f / m_zoomLevel, Qt::DashLine));
    painter->drawLine(m_activeSpeechBalloon.tailStart1, m_activeSpeechBalloon.tailControl1);
    painter->drawLine(m_activeSpeechBalloon.tailEnd, m_activeSpeechBalloon.tailControl2);

    // 4. Draw interactive handles
    float handleSize = 6.0f / m_zoomLevel;

    // Center handle (Pink/Red)
    painter->setBrush(QColor(255, 99, 71));
    painter->setPen(QPen(Qt::white, 1.2f / m_zoomLevel));
    painter->drawEllipse(QPointF(m_activeSpeechBalloon.cx, m_activeSpeechBalloon.cy), handleSize, handleSize);

    // Radii width handle (Orange)
    painter->setBrush(QColor(255, 159, 67));
    painter->drawEllipse(QPointF(m_activeSpeechBalloon.cx + m_activeSpeechBalloon.rx, m_activeSpeechBalloon.cy), handleSize, handleSize);

    // Control point 1 handle (Blue)
    painter->setBrush(QColor(84, 160, 255));
    painter->drawEllipse(m_activeSpeechBalloon.tailControl1, handleSize, handleSize);

    // Control point 2 handle (Blue)
    painter->drawEllipse(m_activeSpeechBalloon.tailControl2, handleSize, handleSize);

    // End handle (Green)
    painter->setBrush(QColor(29, 209, 161));
    painter->drawEllipse(m_activeSpeechBalloon.tailEnd, handleSize, handleSize);

    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // ✨ PREMIUM QUICKSHAPE SNAP ANIMATION
  // ══════════════════════════════════════════════════════════════
  if (m_quickShapeSnapAnimActive && m_quickShapeType != QuickShapeType::None) {
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);

    // Easing Out effect for smooth expansion and fade
    float progress = m_quickShapeSnapAnim;
    float easeOut = 1.0f - std::pow(1.0f - progress, 3.0f); // Cubic ease-out

    // Scale expansion: starts at 1.0, expands to slightly larger
    float scaleAnim = 1.0f + (easeOut * 0.05f);

    // Opacity fade: starts bright, drops to 0
    float alphaAnim = 1.0f - easeOut;

    QColor glowColor = m_accentColor;
    if (glowColor.value() < 50)
      glowColor = Qt::white; // Prevents invisible dark glows
    glowColor.setAlphaF(alphaAnim * 0.9f);

    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QPen glowPen(glowColor, (4.0f + (easeOut * 8.0f)) / m_zoomLevel,
                 Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
    painter->setPen(glowPen);
    painter->setBrush(QColor(glowColor.red(), glowColor.green(),
                             glowColor.blue(),
                             int(alphaAnim * 40.0f))); // Slight fill glow

    if (m_quickShapeType == QuickShapeType::Circle) {
      painter->translate(m_quickShapeCenter);
      painter->scale(scaleAnim, scaleAnim);
      painter->drawEllipse(QPointF(0, 0), m_quickShapeRadius,
                           m_quickShapeRadius);
    } else if (m_quickShapeType == QuickShapeType::Line) {
      painter->setBrush(Qt::NoBrush);
      painter->translate(m_quickShapeCenter);
      painter->scale(scaleAnim, scaleAnim);
      QPointF p1 = m_quickShapeLineP1 - m_quickShapeCenter;
      QPointF p2 = m_quickShapeLineP2 - m_quickShapeCenter;
      painter->drawLine(p1, p2);
    }

    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // ✨ QUICKSHAPE RESIZE GUIDE (Minimal — center dot only)
  // ══════════════════════════════════════════════════════════════

  if (m_isHoldingForShape && m_quickShapeResizing &&
      m_quickShapeType != QuickShapeType::None) {
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QColor dotColor(255, 255, 255, 180);
    QColor dotOutline(0, 0, 0, 120);
    float dotRadius = 3.5f / m_zoomLevel;

    if (m_quickShapeType == QuickShapeType::Circle) {
      // Small center dot (canvas coords)
      painter->setPen(QPen(dotOutline, 2.0f / m_zoomLevel));
      painter->setBrush(dotColor);
      painter->drawEllipse(m_quickShapeCenter, dotRadius, dotRadius);
    } else if (m_quickShapeType == QuickShapeType::Line) {
      // Small endpoint dots (canvas coords)
      painter->setPen(QPen(dotOutline, 1.5f / m_zoomLevel));
      painter->setBrush(dotColor);
      painter->drawEllipse(m_quickShapeLineP1, dotRadius, dotRadius);
      painter->drawEllipse(m_quickShapeLineP2, dotRadius, dotRadius);
    }

    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // LIQUIFY PREVIEW OVERLAY
  // ══════════════════════════════════════════════════════════════
  if (m_isLiquifying && !m_liquifyPreviewCache.isNull()) {
    QRectF lPaperRect(
        m_viewOffset.x() * m_zoomLevel, m_viewOffset.y() * m_zoomLevel,
        m_canvasWidth * m_zoomLevel, m_canvasHeight * m_zoomLevel);
    renderLiquifyPreview(painter, lPaperRect);
  }

  // ═══ End Canvas Rotation context — cursor draws are in screen space ═══
  painter->restore();

  // Draw Liquify cursor (screen space — after rotation restore)
  if (m_isLiquifying && !m_liquifyPreviewCache.isNull()) {
    if (m_cursorVisible && m_liquifyEngine) {
      float liqRadius = m_liquifyEngine->radius() * m_zoomLevel;
      painter->save();
      painter->setRenderHint(QPainter::Antialiasing);
      QPen outerPen(QColor(0, 0, 0, 100), 2.0f);
      painter->setPen(outerPen);
      painter->setBrush(Qt::NoBrush);
      painter->drawEllipse(m_cursorPos, liqRadius, liqRadius);
      QPen innerPen(QColor(255, 255, 255, 180), 1.2f);
      painter->setPen(innerPen);
      painter->drawEllipse(m_cursorPos, liqRadius, liqRadius);
      // Center dot
      painter->setPen(Qt::NoPen);
      painter->setBrush(QColor(255, 255, 255, 200));
      painter->drawEllipse(m_cursorPos, 2, 2);
      painter->restore();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 🎯 TOUCH EYEDROPPER — Color preview circle
  // ══════════════════════════════════════════════════════════════

  if (m_touchIsEyedropper && m_touchPointCount == 1) {
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);

    QPointF pos = m_lastTouchPos;
    float outerR = 65.0f;
    float ringR = 62.0f;
    float innerR = 57.0f;

    // Outer shadow ring
    painter->setPen(QPen(QColor(0, 0, 0, 160), 3.0f));
    painter->setBrush(Qt::NoBrush);
    painter->drawEllipse(pos, outerR, outerR);

    // White contrast ring
    painter->setPen(QPen(Qt::white, 2.5f));
    painter->drawEllipse(pos, ringR, ringR);

    // Split circle: bottom half = old brush color, top half = sampled color
    QRectF splitRect(pos.x() - innerR, pos.y() - innerR, innerR * 2, innerR * 2);

    // Top half (sampled color)
    QPainterPath topHalf;
    topHalf.arcMoveTo(splitRect, 0);
    topHalf.arcTo(splitRect, 0, 180);
    topHalf.lineTo(pos.x(), pos.y());
    topHalf.closeSubpath();
    painter->setPen(Qt::NoPen);
    painter->setBrush(m_touchEyedropperColor);
    painter->drawPath(topHalf);

    // Bottom half (old brush color)
    QPainterPath bottomHalf;
    bottomHalf.arcMoveTo(splitRect, 180);
    bottomHalf.arcTo(splitRect, 180, 180);
    bottomHalf.lineTo(pos.x(), pos.y());
    bottomHalf.closeSubpath();
    painter->setBrush(m_touchEyedropperOldColor);
    painter->drawPath(bottomHalf);

    // Divider line
    painter->setPen(QPen(Qt::white, 2.0f));
    painter->drawLine(QPointF(pos.x() - innerR, pos.y()),
                      QPointF(pos.x() + innerR, pos.y()));

    // Center dot
    painter->setPen(Qt::NoPen);
    painter->setBrush(QColor(255, 255, 255, 220));
    painter->drawEllipse(pos, 2.5f, 2.5f);

    painter->restore();
  }

  // ══════════════════════════════════════════════════════════════
  // 🎯 CURSOR PERSONALIZADO AL FINAL (ENCIMA DE TODO)
  // ══════════════════════════════════════════════════════════════

  if (!m_touchIsEyedropper && m_cursorVisible && !m_spacePressed &&
      !m_isRotatingCanvas &&
      (m_tool == ToolType::Pen || m_tool == ToolType::Eraser)) {

    // Obtener valores actuales del pincel
    float size = m_brushSize;
    float rotation = m_brushAngle;
    QString texturePath;

    // Si estamos editando un preset, usar sus valores
    if (m_isEditingBrush) {
      texturePath = m_editingPreset.shape.tipTexture;
      rotation = m_editingPreset.shape.rotation;
      size = m_editingPreset.defaultSize;
    } else {
      // Intentar obtener del preset activo
      auto *bpm = artflow::BrushPresetManager::instance();
      const artflow::BrushPreset *preset = bpm->findByName(m_activeBrushName);
      if (preset) {
        texturePath = preset->shape.tipTexture;
        rotation = preset->shape.rotation;
      } else {
        // Debug fallback path if no preset found
        qDebug() << "No preset found for cursor:" << m_activeBrushName;
      }
    }

    // Verificar si necesitamos regenerar el cache del cursor
    bool needsRegenerate =
        (m_cursorCacheDirty || m_brushOutlineCache.isNull() ||
         m_lastBrushTexturePath != texturePath ||
         !qFuzzyCompare(m_lastCursorSize, size * m_zoomLevel) ||
         !qFuzzyCompare(m_lastCursorRotation, rotation) ||
         m_lastCursorColor != m_brushColor);

    if (needsRegenerate) {
      m_brushOutlineCache =
          loadAndProcessBrushTexture(texturePath, size, rotation, 0.0f, true);
      m_lastBrushTexturePath = texturePath;
      m_lastCursorSize = size * m_zoomLevel;
      m_lastCursorRotation = rotation;
      m_lastCursorColor = m_brushColor;
      m_cursorCacheDirty = false;

      qDebug() << "Cursor regenerated for texture:" << texturePath
               << "size:" << size << "color:" << m_brushColor;
    }

    if (!m_brushOutlineCache.isNull()) {
      // Dibujar centrado en la posición del cursor
      float cursorX = m_cursorPos.x() - m_brushOutlineCache.width() / 2.0f;
      float cursorY = m_cursorPos.y() - m_brushOutlineCache.height() / 2.0f;

      painter->save();
      painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
      painter->drawImage(QPointF(cursorX, cursorY), m_brushOutlineCache);
      painter->restore();
    } else {
      // 🚨 FALLBACK VISIBLE (Círculo Rojo) para depuración
      // Si llegamos aquí, falló la carga de textura
      painter->save();
      painter->setPen(QPen(Qt::red, 2));
      painter->drawEllipse(m_cursorPos, size * m_zoomLevel / 2,
                           size * m_zoomLevel / 2);
      painter->restore();
    }
  }

  // Cursores para otras herramientas (opcionales)
  else if (!m_touchIsEyedropper && m_cursorVisible && !m_spacePressed &&
           m_tool != ToolType::Hand && m_tool != ToolType::Transform) {
    // 🎯 Professional Precision Cursor (Crosshair with Circle) para
    // eyedropper, lasso, fill, etc.
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);

    // Outer Glow/Shadow (Black outline for visibility on light areas)
    painter->setPen(QPen(QColor(0, 0, 0, 120), 2.5f));
    painter->drawEllipse(m_cursorPos, 5, 5);
    painter->drawLine(m_cursorPos + QPointF(-9, 0),
                      m_cursorPos + QPointF(-2, 0));
    painter->drawLine(m_cursorPos + QPointF(9, 0), m_cursorPos + QPointF(2, 0));
    painter->drawLine(m_cursorPos + QPointF(0, -9),
                      m_cursorPos + QPointF(0, -2));
    painter->drawLine(m_cursorPos + QPointF(0, 9), m_cursorPos + QPointF(0, 2));

    // Precision Core (White lines for visibility on dark areas)
    QPen whitePen(Qt::white, 1.2f);
    painter->setPen(whitePen);
    painter->drawEllipse(m_cursorPos, 4, 4);
    painter->drawLine(m_cursorPos + QPointF(-8, 0),
                      m_cursorPos + QPointF(-3, 0));
    painter->drawLine(m_cursorPos + QPointF(8, 0), m_cursorPos + QPointF(3, 0));
    painter->drawLine(m_cursorPos + QPointF(0, -8),
                      m_cursorPos + QPointF(0, -3));
    painter->drawLine(m_cursorPos + QPointF(0, 8), m_cursorPos + QPointF(0, 3));

    painter->restore();
  }
}

void CanvasItem::handleDraw(const QPointF &pos, float pressure, float tilt) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->visible || layer->locked)
    return;

  // --- STABILIZATION MULTI-MODE ---
  QPointF targetPos = pos;
  float effectivePressure = pressure;

  if (m_isDrawing) {
    float strength = std::clamp(m_brushStabilization, 0.0f, 1.0f);

    if (strength > 0.01f) {
      if (m_brushStabilizerMode == 1) {
        // --- MODE 1: Double EMA (existing streamline stabilizer) ---
        if (m_stabPosQueue.empty()) {
          m_stabilizedPos = pos;
          effectivePressure = pressure;
          m_stabPosQueue.push_back(pos);
          m_stabPosQueue.push_back(pos);
          m_stabPresQueue.clear();
          m_stabPresQueue.push_back(pressure);
        }

        float mass = std::pow(strength, 0.65f) * 0.92f;
        QPointF ema1 = m_stabPosQueue[0] * mass + pos * (1.0f - mass);
        QPointF ema2 = m_stabPosQueue[1] * mass + ema1 * (1.0f - mass);

        m_stabPosQueue[0] = ema1;
        m_stabPosQueue[1] = ema2;
        m_stabilizedPos = ema2;

        float prevPres = m_stabPresQueue.front();
        effectivePressure = prevPres * mass + pressure * (1.0f - mass);
        m_stabPresQueue.front() = effectivePressure;

        targetPos = m_stabilizedPos;
      }
      else if (m_brushStabilizerMode == 2) {
        // --- MODE 2: Weighted Moving Average (WMA) ---
        int N = std::max(2, static_cast<int>(strength * 30.0f));
        m_stabPosQueue.push_back(pos);
        m_stabPresQueue.push_back(pressure);
        while (m_stabPosQueue.size() > static_cast<size_t>(N)) {
          m_stabPosQueue.pop_front();
          m_stabPresQueue.pop_front();
        }

        double totalWeight = 0.0;
        double sumX = 0.0;
        double sumY = 0.0;
        double sumPres = 0.0;
        int size = m_stabPosQueue.size();
        for (int i = 0; i < size; ++i) {
          double weight = static_cast<double>(i + 1);
          totalWeight += weight;
          sumX += m_stabPosQueue[i].x() * weight;
          sumY += m_stabPosQueue[i].y() * weight;
          sumPres += m_stabPresQueue[i] * weight;
        }

        if (totalWeight > 0.0) {
          m_stabilizedPos = QPointF(sumX / totalWeight, sumY / totalWeight);
          effectivePressure = sumPres / totalWeight;
        } else {
          m_stabilizedPos = pos;
          effectivePressure = pressure;
        }
        targetPos = m_stabilizedPos;
      }
      else if (m_brushStabilizerMode == 3) {
        // --- MODE 3: Virtual Spring / Attraction (Lazy Mouse) ---
        if (m_stabPosQueue.empty()) {
          m_stabilizedPos = pos;
          effectivePressure = pressure;
          m_stabPosQueue.push_back(pos);
          m_stabPresQueue.push_back(pressure);
        }

        float R = strength * 80.0f;
        float K = 0.02f + (1.0f - strength) * 0.98f;

        QPointF d = pos - m_stabilizedPos;
        float dist = std::hypot(d.x(), d.y());

        if (dist > R) {
          QPointF pullTarget = pos - (d / dist) * R;
          m_stabilizedPos += (pullTarget - m_stabilizedPos) * K;
        }
        effectivePressure += (pressure - effectivePressure) * K;

        targetPos = m_stabilizedPos;
      }
      else {
        m_stabPosQueue.clear();
        m_stabPresQueue.clear();
        m_stabilizedPos = pos;
        effectivePressure = pressure;
        targetPos = pos;
      }
    } else {
      m_stabPosQueue.clear();
      m_stabPresQueue.clear();
      m_stabilizedPos = pos;
      effectivePressure = pressure;
      targetPos = pos;
    }
  }

  // DETECT LAYER SWITCH
  if (m_lastActiveLayerIndex != m_activeLayerIndex) {
    if (m_pingFBO) {
      delete m_pingFBO;
      m_pingFBO = nullptr;
      delete m_pongFBO;
      m_pongFBO = nullptr;
    }
    if (m_dabFBO) {
      delete m_dabFBO;
      m_dabFBO = nullptr;
    }
    m_lastActiveLayerIndex = m_activeLayerIndex;
    m_gradientMapDirty = true;
  }

  QPointF lastCanvasPos = m_lastPos;

  // Convertir posición de pantalla a canvas (rotation-aware)
  QPointF canvasPos = screenToCanvas(targetPos);

  if (m_perspectiveRuler && m_perspectiveRuler->active() && m_isDrawing) {
    canvasPos = m_perspectiveRuler->snapPoint(canvasPos, m_strokeStartPos);
  }

  if (m_isVectorDrawing && layer && layer->type == Layer::Type::Vector) {
    VPoint2D vp;
    vp.x = canvasPos.x();
    vp.y = canvasPos.y();
    vp.pressure = effectivePressure;
    if (m_vectorPointBuffer.empty() || 
        std::abs(m_vectorPointBuffer.back().x - vp.x) > 0.01f ||
        std::abs(m_vectorPointBuffer.back().y - vp.y) > 0.01f) {
      m_vectorPointBuffer.push_back(vp);
    }
  }

  BrushSettings settings = m_brushEngine->getBrush();

  // DEBUG: log settings to file at drawing time
  static int handleDrawDbgCount = 0;
  if (handleDrawDbgCount++ % 20 == 0) {
    std::ofstream logFile("e:/Programacion/Rescate_Proyecto/canvas_draw_debug.txt", std::ios::app);
    if (logFile.is_open()) {
      logFile << "[HANDLE-DRAW] useTexture: " << settings.useTexture
              << " | textureName: " << settings.textureName.toStdString()
              << " | grainTextureID: " << settings.grainTextureID
              << " | isWc: " << (isWatercolorBrush() && m_tool != ToolType::Eraser)
              << " | activePreset: " << m_activeBrushName.toStdString() << "\n";
    }
  }

  // FIX: Support explicit Eraser Mode and "Transparent Color" (Clip Studio
  // Style)
  bool isTransparentColor = (m_brushColor.alpha() < 5);
  if (m_isEraser || isTransparentColor || m_tool == ToolType::Eraser || m_tool == ToolType::VectorEraser) {
    settings.type = BrushSettings::Type::Eraser;
    // MÁSCARA DE BORRADO MÁGICA: Usamos Alpha 254 como contraseña
    // para forzar a StrokeRenderer a saber que esto es un borrador.
    settings.color = QColor(0, 0, 0, 254);
    // LIMPIEZA TOTAL: El borrador debe ser una forma pura, sin ruido ni
    // efectos
    settings.useTexture = false;
    settings.jitter = 0.0f;
    settings.posJitterX = 0.0f;
    settings.posJitterY = 0.0f;
    settings.sizeJitter = 0.0f;
    settings.opacityJitter = 0.0f;
    settings.grain = 0.0f;
    settings.hardness = 0.95f;
    settings.spacing = std::min(settings.spacing, 0.02f); // Más fluido

    // Resetear efectos avanzados que podrían ensuciar el borrado
    settings.wetness = 0.0f;
    settings.dilution = 0.0f;
    settings.smudge = 0.0f;
    settings.mixing = 0.0f;
    settings.impastoEnabled = false;
    settings.bloomEnabled = false;
    settings.edgeDarkeningEnabled = false;
    settings.textureRevealEnabled = false;
    settings.bristlesEnabled = false;
    settings.tipTextureName = ""; // Forzar círculo procedural limpio
    settings.tipTextureID = 0;
  }

  float velocityFactor = 0.0f;

  // === PER-PRESET DYNAMICS EVALUATION ===
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *activePreset = nullptr;
  if (m_isEditingBrush) {
    activePreset = &m_editingPreset;
  } else {
    activePreset = bpm->findByName(m_activeBrushName);
  }

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
    float rawPressure = std::clamp(applyPressureCurve(effectivePressure), 0.0f, 1.0f);

    // SIZE dynamics: evaluate curve and apply range
    float sizeT = activePreset->sizeDynamics.evaluate(rawPressure);
    float sizeMultiplier = sizeT; // 0..1 multiplier for brush size

    // Master Toggle: If sizeByPressure is manually disabled, keep it at
    // 100%
    if (!m_sizeByPressure)
      sizeMultiplier = 1.0f;

    settings.size = m_brushSize * sizeMultiplier;
    // Lower minimum size floor to allow cleaner fade-outs
    if (settings.size < 0.1f)
      settings.size = 0.1f;

    // OPACITY dynamics
    float opacT = 1.0f;
    if (activePreset->opacityDynamics.pressureEnabled && (activePreset->opacityDynamics.minLimit < 0.99f || m_opacityByPressure)) {
      opacT = activePreset->opacityDynamics.evaluate(rawPressure);
      // Master Toggle check
      if (!m_opacityByPressure)
        opacT = 1.0f;
    }
    settings.opacity = m_brushOpacity * opacT;

    // FLOW dynamics
    float flowT = 1.0f;
    if (activePreset->flowDynamics.minLimit < 0.99f || m_flowByPressure) {
      flowT = activePreset->flowDynamics.evaluate(rawPressure);
      // Master Toggle check
      if (!m_flowByPressure)
        flowT = 1.0f;
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

    // Fallback for simple tools: use global toggles
    if (m_sizeByPressure) {
      settings.size = m_brushSize * effectivePressure;
      if (settings.size < 1.0f)
        settings.size = 1.0f;
    }
    if (m_opacityByPressure) {
      settings.opacity = m_brushOpacity * effectivePressure;
    }
    if (m_flowByPressure) {
      settings.flow = m_brushFlow * effectivePressure;
    }
  }

  // Create QImage wrapper around layer buffer (Use RGBA8888_Premultiplied)
  QImage img(layer->buffer->data(), layer->buffer->width(),
             layer->buffer->height(), QImage::Format_RGBA8888_Premultiplied);

  // Calculate bounding box in canvas coords for dirty rect tracking
  float minX = std::min(lastCanvasPos.x(), canvasPos.x());
  float minY = std::min(lastCanvasPos.y(), canvasPos.y());
  float maxX = std::max(lastCanvasPos.x(), canvasPos.x());
  float maxY = std::max(lastCanvasPos.y(), canvasPos.y());
  QRectF canvasRect(minX, minY, maxX - minX, maxY - minY);
  float margin = settings.size + 5.0f;
  canvasRect.adjust(-margin, -margin, margin, margin);

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
      if (m_dabFBO)
        delete m_dabFBO;

      // EXPLICIT FORMAT with Alpha support and 0 samples (Stable)
      QOpenGLFramebufferObjectFormat format;
      format.setInternalTextureFormat(
          GL_RGBA16F); // Support high-precision volume accumulation
      format.setSamples(0);
      format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);

      m_pingFBO =
          new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
      m_pongFBO =
          new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
      m_dabFBO =
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

    // Failsafe for m_dabFBO
    if (!m_dabFBO) {
      QOpenGLFramebufferObjectFormat format;
      format.setInternalTextureFormat(GL_RGBA16F);
      format.setSamples(0);
      format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
      m_dabFBO = new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
    }

    // Copiar estado anterior (Ping -> Pong) de forma eficiente (Blit)
    // Esto evita descargar texturas de GPU a CPU
    QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);

    bool isWc = isWatercolorBrush() && settings.type != BrushSettings::Type::Eraser;
    if (isWc) {
      settings.blendMode = 0; // Force normal blending when drawing to the isolated dab FBO
      m_dabFBO->bind();
      QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
      f->glClearColor(0, 0, 0, 0);
      f->glClear(GL_COLOR_BUFFER_BIT);
    } else {
      m_pongFBO->bind();
    }

    QOpenGLPaintDevice device2(m_canvasWidth, m_canvasHeight);
    QPainter fboPainter2(&device2);

    // ✅ Selection Clipping (Premium Selection Support)
    if (!m_selectionPath.isEmpty()) {
      fboPainter2.setClipPath(m_selectionPath);
    }

    // ✅ Comic Panel Clipping
    int basePanelIdx = -1;
    artflow::Layer *basePanel = getActiveBasePanel(&basePanelIdx);
    if (basePanel && !basePanel->panelPath.isEmpty()) {
      if (basePanel->panelPath.elementCount() <= 5) {
        fboPainter2.setClipRect(basePanel->panelPath.boundingRect(), Qt::IntersectClip);
      } else {
        fboPainter2.setClipPath(basePanel->panelPath, Qt::IntersectClip);
      }
    }

    // Configurar blend mode a nivel de QPainter para que fluya
    // correctamente en la GPU
    if (settings.type == BrushSettings::Type::Eraser) {
      if (layer->alphaLock) {
        // Can't erase on an alpha-locked layer
        fboPainter2.end();
        m_pongFBO->release();
        return;
      }
      fboPainter2.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    } else {
      if (layer->alphaLock) {
        fboPainter2.setCompositionMode(QPainter::CompositionMode_SourceAtop);
      } else {
        fboPainter2.setCompositionMode(QPainter::CompositionMode_SourceOver);
      }
    }

    // ─── WATER BLENDER: Krita-style Color Smudge ───────────────────────
    // Lee desde la capa CPU (img) - RAPIDO, sin GPU readback.
    // Muestrea el color existente bajo el pincel y lo usa como el color
    // que "carga" el pincel, creando el efecto de arrastrar y fusionar.
    bool isWaterBlend = (settings.type == BrushSettings::Type::Oil);
    if (isWaterBlend) {
        int sampleRadius = std::max(4, (int)(settings.size * 0.40f));
        int cx = (int)canvasPos.x();
        int cy = (int)canvasPos.y();

        // Usar img (capa CPU) — rápido, correcto para workflow
        float rSum = 0, gSum = 0, bSum = 0, aSum = 0;
        int count = 0;
        for (int sy = std::max(0, cy - sampleRadius);
             sy <= std::min(img.height() - 1, cy + sampleRadius); sy++) {
            for (int sx = std::max(0, cx - sampleRadius);
                 sx <= std::min(img.width() - 1, cx + sampleRadius); sx++) {
                float dx = (float)(sx - cx) / sampleRadius;
                float dy = (float)(sy - cy) / sampleRadius;
                if (dx*dx + dy*dy > 1.0f) continue;

                // img es RGBA8888_Premultiplied — despremutiplicar para colores reales
                QRgb px = img.pixel(sx, sy);
                float a  = qAlpha(px) / 255.0f;
                if (a > 0.03f) {
                    float invA = 1.0f / a;  // Despremutiplicar
                    rSum += (qRed(px)   / 255.0f) * invA;
                    gSum += (qGreen(px) / 255.0f) * invA;
                    bSum += (qBlue(px)  / 255.0f) * invA;
                    aSum += a;
                    count++;
                }
            }
        }

        // Inicializar smudge color fresco al inicio del trazo con el color original del pincel al 100% de carga
        if (!m_smudgeColorValid) {
            m_smudgeColor = QVector4D(settings.color.redF(), settings.color.greenF(), settings.color.blueF(), 1.0f);
            m_smudgeColorValid = true;
        }

        if (count > 0 && aSum > 0.05f) {
            float invC = 1.0f / count;
            float sR = std::clamp(rSum * invC, 0.0f, 1.0f);
            float sG = std::clamp(gSum * invC, 0.0f, 1.0f);
            float sB = std::clamp(bSum * invC, 0.0f, 1.0f);
            float sA = std::clamp(aSum * invC, 0.0f, 1.0f);

            // Contaminación progresiva: se ensucia según colorPickup
            float contamination = settings.colorPickup;
            m_smudgeColor.setX(m_smudgeColor.x() * (1.0f - contamination) + sR * contamination);
            m_smudgeColor.setY(m_smudgeColor.y() * (1.0f - contamination) + sG * contamination);
            m_smudgeColor.setZ(m_smudgeColor.z() * (1.0f - contamination) + sB * contamination);
            m_smudgeColor.setW(m_smudgeColor.w() * (1.0f - contamination) + sA * contamination);
        }

        // El color cargado en el pincel (ensuciado o limpio) es enviado al motor
        settings.color = QColor::fromRgbF(
            m_smudgeColor.x(), m_smudgeColor.y(), m_smudgeColor.z());
    }
    // ─── LAZY TEXTURE LOADING ────────────────────────────────────
    // Preload and cache GPU texture IDs before paintStroke so both
    // the brush shader and the watercolor engine can use them.
    if (settings.tipTextureID == 0 && !settings.tipTextureName.isEmpty()) {
      settings.tipTextureID = artflow::BrushEngine::loadTexture(settings.tipTextureName, true);
    }
    if (settings.dualTipEnabled && settings.dualTipTextureID == 0 &&
        !settings.dualTipTextureName.isEmpty()) {
      settings.dualTipTextureID = artflow::BrushEngine::loadTexture(settings.dualTipTextureName, true);
    }
    if (settings.useTexture && settings.grainTextureID == 0 &&
        !settings.textureName.isEmpty()) {
      settings.grainTextureID = artflow::BrushEngine::loadTexture(settings.textureName, false);
    }
    if (settings.useDualTexture && settings.dualGrainTextureID == 0 &&
        !settings.dualTextureName.isEmpty()) {
      settings.dualGrainTextureID = artflow::BrushEngine::loadTexture(settings.dualTextureName, false);
    }
    // Persist the loaded IDs back to the engine so they're cached
    // for subsequent frames and the watercolor engine.
    if (settings.tipTextureID != 0 || settings.dualTipTextureID != 0 ||
        settings.grainTextureID != 0 || settings.dualGrainTextureID != 0) {
      BrushSettings engineCopy = m_brushEngine->getBrush();
      engineCopy.tipTextureID = settings.tipTextureID;
      engineCopy.dualTipTextureID = settings.dualTipTextureID;
      engineCopy.grainTextureID = settings.grainTextureID;
      engineCopy.dualGrainTextureID = settings.dualGrainTextureID;
      m_brushEngine->setBrush(engineCopy);
    }
    // ─── FIN LAZY TEXTURE LOADING ────────────────────────────────

    m_brushEngine->paintStroke(
        &fboPainter2, m_lastPos, canvasPos, effectivePressure, settings, tilt,
        velocityFactor, m_pingFBO->texture(), settings.wetness,
        settings.dilution, settings.smudge, m_pingFBO, m_pongFBO);


    if (m_symmetryEnabled && !m_symmetryEngines.empty()) {
      QPointF center(m_canvasWidth / 2.0f, m_canvasHeight / 2.0f);
      for (size_t iter = 0; iter < m_symmetryEngines.size(); ++iter) {
        QPointF p1 =
            mirrorPoint(m_lastPos, iter, m_symmetryEngines.size(), center);
        QPointF p2 =
            mirrorPoint(canvasPos, iter, m_symmetryEngines.size(), center);
        m_symmetryEngines[iter]->paintStroke(
            &fboPainter2, p1, p2, effectivePressure, settings, tilt,
            velocityFactor, m_pingFBO->texture(), settings.wetness,
            settings.dilution, settings.smudge, m_pingFBO, m_pongFBO);

        // EXPANDIR DIRTY RECT para incluir el trazo simétrico
        QRectF symRect(p1, p2);
        symRect = symRect.normalized().adjusted(
            -settings.size * 2, -settings.size * 2, settings.size * 2,
            settings.size * 2);
        canvasRect = canvasRect.united(symRect);
      }
    }

    fboPainter2.end();
    if (isWc) {
      m_dabFBO->release();
    } else {
      m_pongFBO->release();
    }

    layer->markDirty(canvasRect.toAlignedRect());
    std::swap(m_pingFBO, m_pongFBO);

    // ─────────────────────────────────────────────────────────────────────
    // WATERCOLOR ENGINE — Motor de acuarela profesional
    // Se activa automáticamente si el pincel pertenece a la categoría Watercolor
    // o tiene wetness > 0.3 en su preset.
    // ─────────────────────────────────────────────────────────────────────
    if (isWc) {
        // Inicializar el motor bajo demanda (primera vez o si cambió el tamaño)
        if (!m_watercolorEngine) {
            m_watercolorEngine = new WatercolorEngine(this);
            // Conectar la señal de actualización del wetmap al repintado del canvas
            connect(m_watercolorEngine, &WatercolorEngine::wetMapUpdated,
                    this, [this]() { requestUpdate(); });
        }

        // Sync the watercolor engine's grain texture ID in case the user
        // changed the grain texture mid-session via the Brush Studio.
        m_watercolorEngine->setGrainTextureId(settings.grainTextureID);

        QOpenGLFunctions *gl = QOpenGLContext::currentContext()->functions();
        if (!m_watercolorEngine->hasActiveWetAreas() ||
            m_pingFBO->width() != m_canvasWidth ||
            m_pingFBO->height() != m_canvasHeight) {
            m_watercolorEngine->beginSession(m_canvasWidth, m_canvasHeight, gl,
                                             settings.grainTextureID);
        }

        // El dab ya fue pintado en m_dabFBO por el motor normal.
        // Ahora pasamos ese resultado por el pipeline de acuarela:
        // el WatercolorEngine aplica la acumulación, wet-on-wet y
        // deposita agua en el WetMap.
        auto wcParams = buildWatercolorParams();
        m_watercolorEngine->paintDab(
            m_dabFBO->texture(),      // Dab tex (lo que se acaba de pintar de forma aislada)
            m_pongFBO->texture(),     // Canvas anterior (antes del dab, ahora en m_pongFBO debido al swap)
            m_pingFBO,                // Salida: canvas con acuarela aplicada
            m_brushColor,
            wcParams,
            effectivePressure,
            settings.flow
        );
    } else if (m_watercolorEngine && !isWatercolorBrush()) {
        // Si el usuario cambió a un pincel que no es acuarela, finalizar la sesión
        m_watercolorEngine->endSession();
    }

    // --- INPUT PREDICTION ---
    // Maintain history
    m_historyPos.push_back(canvasPos);
    m_historyPressure.push_back(effectivePressure);
    m_historyTime.push_back(QDateTime::currentMSecsSinceEpoch());
    if (m_historyPos.size() > 5) {
      m_historyPos.pop_front();
      m_historyPressure.pop_front();
      m_historyTime.pop_front();
    }

    if (m_historyPos.size() >= 2) {
      // Linear extrapolation: P_pred = P_curr + (P_curr - P_prev) * factor
      // We predict about 1.5 frames ahead for responsiveness without too much
      // jitter
      QPointF pCurr = m_historyPos.back();
      QPointF pPrev = m_historyPos[m_historyPos.size() - 2];
      m_predictedPos = pCurr + (pCurr - pPrev) * 1.5f;
      m_hasPrediction = true;

      // Ensure Prediction FBO
      if (!m_predictionFBO || m_predictionFBO->width() != m_canvasWidth ||
          m_predictionFBO->height() != m_canvasHeight) {
        if (m_predictionFBO)
          delete m_predictionFBO;
        QOpenGLFramebufferObjectFormat format;
        format.setInternalTextureFormat(GL_RGBA16F);
        m_predictionFBO =
            new QOpenGLFramebufferObject(m_canvasWidth, m_canvasHeight, format);
      }

      // Render Predicted Segment to Prediction FBO
      QOpenGLFramebufferObject::blitFramebuffer(m_predictionFBO, m_pingFBO);
      m_predictionFBO->bind();
      QOpenGLPaintDevice predDevice(m_canvasWidth, m_canvasHeight);
      QPainter predPainter(&predDevice);

      if (!m_selectionPath.isEmpty())
        predPainter.setClipPath(m_selectionPath);

      // ✅ Comic Panel Clipping
      int basePanelIdx = -1;
      artflow::Layer *basePanel = getActiveBasePanel(&basePanelIdx);
      if (basePanel && !basePanel->panelPath.isEmpty()) {
        if (basePanel->panelPath.elementCount() <= 5) {
          predPainter.setClipRect(basePanel->panelPath.boundingRect(), Qt::IntersectClip);
        } else {
          predPainter.setClipPath(basePanel->panelPath, Qt::IntersectClip);
        }
      }

      if (settings.type == BrushSettings::Type::Eraser) {
        predPainter.setCompositionMode(
            QPainter::CompositionMode_DestinationOut);
      } else {
        predPainter.setCompositionMode(QPainter::CompositionMode_SourceOver);
      }

      // Draw predicted dab with lower opacity to show it's provisional
      BrushSettings predSettings = settings;
      predSettings.opacity *= 0.6f;

      m_brushEngine->paintStroke(
          &predPainter, canvasPos, m_predictedPos, effectivePressure,
          predSettings, tilt, velocityFactor, m_pingFBO->texture(),
          settings.wetness, settings.dilution, settings.smudge);

      if (m_symmetryEnabled && !m_symmetryEngines.empty()) {
        QPointF center(m_canvasWidth / 2.0f, m_canvasHeight / 2.0f);
        for (size_t iter = 0; iter < m_symmetryEngines.size(); ++iter) {
          QPointF p1 =
              mirrorPoint(canvasPos, iter, m_symmetryEngines.size(), center);
          QPointF p2 = mirrorPoint(m_predictedPos, iter,
                                   m_symmetryEngines.size(), center);
          m_symmetryEngines[iter]->paintStroke(
              &predPainter, p1, p2, effectivePressure, predSettings, tilt,
              velocityFactor, m_pingFBO->texture(), settings.wetness,
              settings.dilution, settings.smudge);
        }
      }

      predPainter.end();
      m_predictionFBO->release();
    }
  } else {
    // MODO ESTÁNDAR (Raster / Legacy)
    QPainter painter(&img);
    painter.setRenderHint(QPainter::Antialiasing);

    // ✅ Selection Clipping (Premium Selection Support)
    if (!m_selectionPath.isEmpty()) {
      painter.setClipPath(m_selectionPath);
    }

    // ✅ Comic Panel Clipping
    int basePanelIdx = -1;
    artflow::Layer *basePanel = getActiveBasePanel(&basePanelIdx);
    if (basePanel && !basePanel->panelPath.isEmpty()) {
      if (basePanel->panelPath.elementCount() <= 5) {
        painter.setClipRect(basePanel->panelPath.boundingRect(), Qt::IntersectClip);
      } else {
        painter.setClipPath(basePanel->panelPath, Qt::IntersectClip);
      }
    }

    if (settings.type == BrushSettings::Type::Eraser) {
      if (layer->alphaLock) {
        painter.end();
        return;
      }
      painter.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    } else {
      if (layer->alphaLock) {
        painter.setCompositionMode(QPainter::CompositionMode_SourceAtop);
      }
    }

    m_brushEngine->paintStroke(&painter, m_lastPos, canvasPos,
                               effectivePressure, settings, tilt,
                               velocityFactor);

    if (m_symmetryEnabled && !m_symmetryEngines.empty()) {
      QPointF center(m_canvasWidth / 2.0f, m_canvasHeight / 2.0f);
      for (size_t iter = 0; iter < m_symmetryEngines.size(); ++iter) {
        QPointF p1 =
            mirrorPoint(m_lastPos, iter, m_symmetryEngines.size(), center);
        QPointF p2 =
            mirrorPoint(canvasPos, iter, m_symmetryEngines.size(), center);
        m_symmetryEngines[iter]->paintStroke(
            &painter, p1, p2, effectivePressure, settings, tilt, velocityFactor,
            0, settings.wetness, settings.dilution, settings.smudge);

        // EXPANDIR DIRTY RECT
        QRectF symRect(p1, p2);
        symRect = symRect.normalized().adjusted(
            -settings.size * 2, -settings.size * 2, settings.size * 2,
            settings.size * 2);
        canvasRect = canvasRect.united(symRect);
      }
    }
    painter.end();
    layer->markDirty(canvasRect.toAlignedRect());
  }

  // Calculate dirty rect for update (Screen coordinates)
  // We need to determine the bounding box in canvas coords, then map to
  // screen. Use lastCanvasPos (captured at start) to ensure we cover the
  // whole segment
  // Transform back to screen for update()
  QRectF screenRect(0, 0, m_canvasWidth * m_zoomLevel,
                    m_canvasHeight * m_zoomLevel);

  // Extra safety for screen clipping
  screenRect.adjust(-2, -2, 2, 2);

  m_lastPos = canvasPos;
  update(screenRect.toAlignedRect());
}

void CanvasItem::detectAndDrawQuickShape() {
  if (!m_isDrawing || m_strokePoints.size() < 10)
    return;

  m_isHoldingForShape = true;
  m_quickShapeResizing = false;

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
    // Mark layer dirty so compositing cache refreshes
    if (layer) {
      layer->dirty = true;
      layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
      if (layer->buffer)
        layer->buffer->clearDirtyFlags();
    }
    m_cachedCanvasImage = QImage(); // Force full recomposite

    // Sync FBO
    if (m_pingFBO && layer && layer->buffer) {
      QImage fboImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                    QImage::Format_RGBA8888_Premultiplied);
      m_pingFBO->bind();
      QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
      QPainter fboPainter(&device);
      fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
      fboPainter.drawImage(0, 0, fboImg);
      fboPainter.end();
      m_pingFBO->release();
      QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
    }

    // Store LINE parameters for resize
    m_quickShapeType = QuickShapeType::Line;
    m_quickShapeLineP1 = startC;
    m_quickShapeLineP2 = endC;
    m_quickShapeCenter = (startC + endC) / 2.0;
    m_quickShapeOrigLineLen = QLineF(startC, endC).length();
    // Store stable direction for resize
    if (m_quickShapeOrigLineLen > 0.01f) {
      m_quickShapeLineDir = (endC - startC) / m_quickShapeOrigLineLen;
    } else {
      m_quickShapeLineDir = QPointF(1, 0);
    }
    m_quickShapeAnchor = m_strokePoints.back(); // Screen coords
    solved = true;
  } else {
    // Circle detection
    // First check: the stroke must be "closed" — start and end points
    // must be near each other, otherwise it's just a curved line, not
    // an attempt to draw a circle.
    float closeDist = QLineF(m_strokePoints.front(), m_strokePoints.back()).length();

    QPointF centroid(0, 0);
    for (const auto &p : m_strokePoints)
      centroid += p;
    centroid /= (float)m_strokePoints.size();

    float avgDist = 0;
    std::vector<float> radii;
    for (const auto &p : m_strokePoints) {
      float r = QLineF(p, centroid).length();
      avgDist += r;
      radii.push_back(r);
    }
    avgDist /= (float)radii.size();

    float variance = 0;
    for (float r : radii)
      variance += (r - avgDist) * (r - avgDist);
    variance = std::sqrt(variance / radii.size());

    // Circle requirements:
    // 1. The stroke must be closed: start-end gap < 25% of avg radius
    // 2. Stricter circularity: variance < 30% of avg radius
    // 3. Minimum stroke length to avoid tiny accidental circles
    bool isClosed = closeDist < avgDist * 0.25f;
    bool isCircular = variance < avgDist * 0.30f;
    bool hasEnoughLength = totalLength > avgDist * 4.0f; // At least ~2/3 of circumference

    if (isClosed && isCircular && hasEnoughLength) {
      if (layer && layer->buffer && m_strokeBeforeBuffer) {
        layer->buffer->copyFrom(*m_strokeBeforeBuffer);
      }
      QPointF centroidC = (centroid - m_viewOffset * m_zoomLevel) / m_zoomLevel;
      if (m_isFlippedH)
        centroidC.setX(m_canvasWidth - centroidC.x());
      if (m_isFlippedV)
        centroidC.setY(m_canvasHeight - centroidC.y());

      float radiusCanvas = avgDist / m_zoomLevel;
      drawCircle(centroidC, radiusCanvas);
      // Mark layer dirty so compositing cache refreshes
      if (layer) {
        layer->dirty = true;
        layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
        if (layer->buffer)
          layer->buffer->clearDirtyFlags();
      }
      m_cachedCanvasImage = QImage(); // Force full recomposite

      // 3. SYNC FBO FROM CPU BUFFER (INSTANT REFRESH)
      if (m_pingFBO && layer && layer->buffer) {
        QImage fboImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                      QImage::Format_RGBA8888_Premultiplied);
        m_pingFBO->bind();
        QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
        QPainter fboPainter(&device);
        fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
        fboPainter.drawImage(0, 0, fboImg);
        fboPainter.end();
        m_pingFBO->release();
        // Crucial: Blit to Pong too so both GPU buffers are in sync with CPU
        QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
      }

      // Store CIRCLE parameters for resize
      m_quickShapeType = QuickShapeType::Circle;
      m_quickShapeCenter = centroidC;
      m_quickShapeRadius = radiusCanvas;
      m_quickShapeOrigRadius = radiusCanvas;
      m_quickShapeAnchor = m_strokePoints.back(); // Screen coords
      solved = true;
    }
  }

  if (!solved) {
    m_isHoldingForShape = false;
    m_quickShapeType = QuickShapeType::None;
    return;
  }

  // Start premium snap animation
  m_quickShapeSnapAnim = 0.0f;
  m_quickShapeSnapAnimActive = true;
  m_quickShapeSnapTimer->start();

  // Notify user of shape correction
  if (m_quickShapeType == QuickShapeType::Circle)
    emit notificationRequested("Circle", "info");
  else if (m_quickShapeType == QuickShapeType::Line)
    emit notificationRequested("Line", "info");

  // No longer need the redundant sync block here as it's handled above in both
  // Line/Circle cases

  update();
}

// ═══════════════════════════════════════════════════════════════════
// redrawQuickShape — Re-render the perfect shape at current size
// Called during drag-to-resize while holding after shape snap
// ═══════════════════════════════════════════════════════════════════
void CanvasItem::redrawQuickShape() {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer || !m_strokeBeforeBuffer)
    return;

  // Revert to the clean pre-stroke state
  layer->buffer->copyFrom(*m_strokeBeforeBuffer);

  // Draw shape at current (possibly resized) dimensions
  if (m_quickShapeType == QuickShapeType::Circle) {
    drawCircle(m_quickShapeCenter, m_quickShapeRadius);
  } else if (m_quickShapeType == QuickShapeType::Line) {
    drawLine(m_quickShapeLineP1, m_quickShapeLineP2);
  }

  // Mark layer dirty so compositing cache refreshes
  layer->dirty = true;
  layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
  if (layer->buffer)
    layer->buffer->clearDirtyFlags();
  m_cachedCanvasImage = QImage(); // Force full recomposite

  // Sync FBO for instant visual refresh (if GPU path is active)
  if (m_pingFBO && layer->buffer) {
    QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
               QImage::Format_RGBA8888_Premultiplied);
    m_pingFBO->bind();
    QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
    QPainter fboPainter(&device);
    fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
    fboPainter.drawImage(0, 0, img);
    fboPainter.end();
    m_pingFBO->release();
    QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
  }

  update();
}

void CanvasItem::drawLine(const QPointF &p1, const QPointF &p2) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer)
    return;

  // CRITICAL: use premultiplied format — same as handleDraw — to avoid color
  // fringing artifacts (teal/cyan halos) from incorrect alpha compositing
  QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888_Premultiplied);
  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);
  painter.setCompositionMode(QPainter::CompositionMode_SourceOver);

  if (!m_selectionPath.isEmpty()) {
    painter.setClipPath(m_selectionPath);
  }
  int basePanelIdx = -1;
  artflow::Layer *basePanel = getActiveBasePanel(&basePanelIdx);
  if (basePanel && !basePanel->panelPath.isEmpty()) {
    if (basePanel->panelPath.elementCount() <= 5) {
      painter.setClipRect(basePanel->panelPath.boundingRect(), Qt::IntersectClip);
    } else {
      painter.setClipPath(basePanel->panelPath, Qt::IntersectClip);
    }
  }

  BrushSettings settings = m_brushEngine->getBrush();
  settings.color = m_brushColor;
  settings.size = m_brushSize;
  settings.opacity = m_brushOpacity;
  // Disable dynamics that don't make sense for shapes
  settings.sizeByPressure = false;
  settings.opacityByPressure = false;
  settings.jitter = 0.0f;
  settings.posJitterX = 0.0f;
  settings.posJitterY = 0.0f;

  m_brushEngine->resetRemainder();

  float lineLen = QLineF(p1, p2).length();
  float step = std::max(0.5f, settings.size * settings.spacing * 0.5f);
  int steps = std::max(2, (int)(lineLen / step));

  QPointF prev = p1;
  for (int i = 1; i <= steps; ++i) {
    float t = (float)i / (float)steps;
    QPointF cur = p1 + (p2 - p1) * t;
    m_brushEngine->paintStroke(&painter, prev, cur, 1.0f, settings);
    prev = cur;
  }

  painter.end();
  layer->buffer->loadRawData(layer->buffer->data());
  layer->markDirty();
}

void CanvasItem::drawCircle(const QPointF &center, float radius) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer)
    return;

  // CRITICAL: use premultiplied format to avoid color fringing artifacts
  QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888_Premultiplied);
  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);
  painter.setCompositionMode(QPainter::CompositionMode_SourceOver);

  if (!m_selectionPath.isEmpty()) {
    painter.setClipPath(m_selectionPath);
  }
  int basePanelIdx = -1;
  artflow::Layer *basePanel = getActiveBasePanel(&basePanelIdx);
  if (basePanel && !basePanel->panelPath.isEmpty()) {
    if (basePanel->panelPath.elementCount() <= 5) {
      painter.setClipRect(basePanel->panelPath.boundingRect(), Qt::IntersectClip);
    } else {
      painter.setClipPath(basePanel->panelPath, Qt::IntersectClip);
    }
  }

  BrushSettings settings = m_brushEngine->getBrush();
  settings.color = m_brushColor;
  settings.size = m_brushSize;
  settings.opacity = m_brushOpacity;
  settings.sizeByPressure = false;
  settings.opacityByPressure = false;
  settings.jitter = 0.0f;
  settings.posJitterX = 0.0f;
  settings.posJitterY = 0.0f;

  m_brushEngine->resetRemainder();

  float circumference = 2.0f * M_PI * radius;
  float step = std::max(0.5f, settings.size * settings.spacing * 0.5f);
  int segments = std::max(36, (int)(circumference / step));

  QPointF prev(center.x() + radius, center.y());
  for (int i = 1; i <= segments; ++i) {
    float angle = (2.0f * M_PI * i) / (float)segments;
    QPointF cur(center.x() + radius * std::cos(angle),
                center.y() + radius * std::sin(angle));
    m_brushEngine->paintStroke(&painter, prev, cur, 1.0f, settings);
    prev = cur;
  }

  painter.end();
  layer->buffer->loadRawData(layer->buffer->data());
  layer->markDirty();
}

void CanvasItem::mousePressEvent(QMouseEvent *event) {
  forceActiveFocus();
  m_lastMousePos = event->position();

  // ── Dragging Vanishing Points in Perspective Ruler ──
  if (m_perspectiveRuler && m_perspectiveRuler->active()) {
    bool canDrag = false;
    if (m_layerManager) {
      artflow::Layer *activeLayer = m_layerManager->getActiveLayer();
      if (activeLayer && activeLayer->name == "Capa no destructiva") {
        canDrag = true;
      }
    }

    if (canDrag) {
      QPointF canvasPos = screenToCanvas(event->position());
      double hitRadius = 24.0 / m_zoomLevel;
      
      auto dist = [](const QPointF& p1, const QPointF& p2) {
        double dx = p1.x() - p2.x();
        double dy = p1.y() - p2.y();
        return std::sqrt(dx * dx + dy * dy);
      };

      if (m_perspectiveRuler->vp1Active() && m_perspectiveRuler->type() >= 1 && dist(canvasPos, m_perspectiveRuler->vp1()) < hitRadius) {
        m_draggingVp = 1;
        event->accept();
        return;
      }
      if (m_perspectiveRuler->vp2Active() && m_perspectiveRuler->type() >= 2 && dist(canvasPos, m_perspectiveRuler->vp2()) < hitRadius) {
        m_draggingVp = 2;
        event->accept();
        return;
      }
      if (m_perspectiveRuler->vp3Active() && m_perspectiveRuler->type() >= 3 && dist(canvasPos, m_perspectiveRuler->vp3()) < hitRadius) {
        m_draggingVp = 3;
        event->accept();
        return;
      }
    }
  }

  // ── Dragging Speech Balloon Handles ──
  if (m_hasActiveSpeechBalloon) {
    QPointF canvasPos = screenToCanvas(event->position());
    double hitRadius = 24.0 / m_zoomLevel;

    auto dist = [](const QPointF& p1, const QPointF& p2) {
      double dx = p1.x() - p2.x();
      double dy = p1.y() - p2.y();
      return std::sqrt(dx * dx + dy * dy);
    };

    QPointF center(m_activeSpeechBalloon.cx, m_activeSpeechBalloon.cy);
    QPointF radiiPoint(m_activeSpeechBalloon.cx + m_activeSpeechBalloon.rx, m_activeSpeechBalloon.cy);

    if (dist(canvasPos, center) < hitRadius) {
      m_draggingBalloonHandle = 1;
      event->accept();
      return;
    }
    if (dist(canvasPos, radiiPoint) < hitRadius) {
      m_draggingBalloonHandle = 2;
      event->accept();
      return;
    }
    if (dist(canvasPos, m_activeSpeechBalloon.tailControl1) < hitRadius) {
      m_draggingBalloonHandle = 3;
      event->accept();
      return;
    }
    if (dist(canvasPos, m_activeSpeechBalloon.tailControl2) < hitRadius) {
      m_draggingBalloonHandle = 4;
      event->accept();
      return;
    }
    if (dist(canvasPos, m_activeSpeechBalloon.tailEnd) < hitRadius) {
      m_draggingBalloonHandle = 5;
      event->accept();
      return;
    }
  }

  // ═══ Canvas Rotation Gesture: 'R' + Drag ═══
  if (m_rPressed) {
    m_isRotatingCanvas = true;
    m_rotateStartPos = event->position();
    m_rotateStartAngle = m_canvasRotation;
    setCursor(Qt::CrossCursor);
    event->accept();
    return;
  }

  if (m_tool == ToolType::Hand || m_spacePressed) {
    event->accept();
    // Change the existing override cursor instead of pushing a new one
    if (m_spacePressed)
      QGuiApplication::changeOverrideCursor(m_customClosedHandCursor);
    else
      setCursor(m_customClosedHandCursor);
    return;
  }

  // Liquify Tool — Start stroke
  if (m_tool == ToolType::Liquify && m_isLiquifying) {
    QPointF canvasPos = screenToCanvas(event->position());
    m_liquifyLastPos = QPointF(-1, -1); // Reset for new gesture
    handleLiquifyDraw(canvasPos, 0.5f);
    event->accept();
    return;
  }

  if (m_tool == ToolType::Eyedropper) {
    QString color = sampleColor(static_cast<int>(event->position().x()),
                                static_cast<int>(event->position().y()));
    setBrushColor(QColor(color));
    return;
  }

  if (m_tool == ToolType::PanelCut) {
    QPointF canvasPos = screenToCanvas(event->position());
    m_panelCutStartPos = canvasPos;
    m_panelCutEndPos = canvasPos;
    m_isPanelCutting = true;
    update();
    return;
  }

  if (m_tool == ToolType::Lasso || m_tool == ToolType::RectSelect ||
      m_tool == ToolType::EllipseSelect || m_tool == ToolType::MagneticLasso) {
    QPointF canvasPos = screenToCanvas(event->position());
    m_lassoCursorPos = canvasPos;

    if (m_tool == ToolType::Lasso) {
      if (m_lassoMode == 0) {
        // ── FREEHAND mode: start a new stroke on press ──
        m_activeLassoPath = QPainterPath();
        m_activeLassoPath.moveTo(canvasPos);
        m_isLassoDragging = true;
      } else {
        // ── POLYGONAL mode: add vertices on each click ──
        const float snapRadius = 12.0f / m_zoomLevel;
        if (m_activeLassoPath.elementCount() >= 3 &&
            QLineF(canvasPos, m_activeLassoPath.elementAt(0)).length() < snapRadius) {
          // Clicked near the first point → close and commit
          m_activeLassoPath.closeSubpath();
          _commitLassoPath();
        } else {
          if (m_activeLassoPath.elementCount() == 0)
            m_activeLassoPath.moveTo(canvasPos);
          else
            m_activeLassoPath.lineTo(canvasPos);
        }
      }
    } else if (m_tool == ToolType::MagneticLasso) {
      // Magnetic: snap vertex to nearest edge, trace edge path
      const float snapRadius = 12.0f / m_zoomLevel;
      if (m_activeLassoPath.elementCount() >= 3 &&
          QLineF(canvasPos, m_activeLassoPath.elementAt(0)).length() < snapRadius) {
        QPointF startPt = m_activeLassoPath.elementAt(0);
        auto edgePath = m_edgeDetector->traceEdgePath(m_activeLassoPath.currentPosition(), startPt);
        for (auto &pt : edgePath) {
          m_activeLassoPath.lineTo(pt);
        }
        m_activeLassoPath.closeSubpath();
        _commitLassoPath();
        m_magneticPreviewPath = QPainterPath();
      } else {
        // Precompute gradient map if dirty
        if (m_gradientMapDirty) {
          Layer *layer = m_layerManager->getActiveLayer();
          if (layer && layer->buffer) {
            QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888);
            m_edgeDetector->computeGradientMap(img);
            m_gradientMapDirty = false;
          }
        }
        
        // Reset last trace target for new session
        m_lastTraceTarget = QPointF(-9999.0f, -9999.0f);
        
        // Snap clicked coordinate to nearest edge point
        QPointF snapped = m_edgeDetector->findEdgePoint(canvasPos, m_magneticSearchRadius);
        if (m_activeLassoPath.elementCount() == 0) {
          m_activeLassoPath.moveTo(snapped);
        } else {
          // Trace optimal edge path between last node and snapped point
          auto edgePath = m_edgeDetector->traceEdgePath(m_activeLassoPath.currentPosition(), snapped);
          for (auto &pt : edgePath) {
            m_activeLassoPath.lineTo(pt);
          }
        }
        m_isMagneticLassoActive = true;
        m_magneticPreviewPath = QPainterPath();
      }
    } else {
      // RectSelect / EllipseSelect: start drag
      m_activeLassoPath = QPainterPath();
      m_activeLassoPath.moveTo(canvasPos);
      m_isLassoDragging = true;
    }

    m_selectionStartPos = canvasPos;
    m_lastSelectionPoint = canvasPos;
    update();
    return;
  }

  if (m_tool == ToolType::MagicWand) {
    QPointF canvasPos = screenToCanvas(event->position());
    int ix = static_cast<int>(std::round(canvasPos.x()));
    int iy = static_cast<int>(std::round(canvasPos.y()));

    if (ix >= 0 && ix < m_canvasWidth && iy >= 0 && iy < m_canvasHeight) {
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer) {
        int W = m_canvasWidth;
        int H = m_canvasHeight;
        QImage layerImg(layer->buffer->data(), W, H, QImage::Format_RGBA8888);
        QRgb startCol = layerImg.pixel(ix, iy);

        int startR = qRed(startCol);
        int startG = qGreen(startCol);
        int startB = qBlue(startCol);
        int startA = qAlpha(startCol);

        QImage mask(W, H, QImage::Format_Grayscale8);
        mask.fill(0);

        std::vector<bool> visited(W * H, false);
        std::vector<QPoint> queue;
        queue.reserve(W * H / 8);
        queue.push_back(QPoint(ix, iy));
        visited[iy * W + ix] = true;

        // selectionThreshold is [0.0 - 1.0].
        // Scale to Euclidean distance in RGBA space (Max = sqrt(255^2 * 4) = 510.0f)
        float maxDist = 510.0f * m_selectionThreshold;
        float maxDistSq = maxDist * maxDist;

        size_t head = 0;
        while (head < queue.size()) {
          QPoint curr = queue[head++];
          int cx = curr.x();
          int cy = curr.y();

          mask.scanLine(cy)[cx] = 255;

          int dx[] = {0, 0, 1, -1};
          int dy[] = {1, -1, 0, 0};

          for (int i = 0; i < 4; ++i) {
            int nx = cx + dx[i];
            int ny = cy + dy[i];

            if (nx >= 0 && nx < W && ny >= 0 && ny < H) {
              int vIdx = ny * W + nx;
              if (!visited[vIdx]) {
                visited[vIdx] = true;
                QRgb pix = layerImg.pixel(nx, ny);
                int pr = qRed(pix);
                int pg = qGreen(pix);
                int pb = qBlue(pix);
                int pa = qAlpha(pix);

                float dr = pr - startR;
                float dg = pg - startG;
                float db = pb - startB;
                float da = pa - startA;
                float distSq = dr * dr + dg * dg + db * db + da * da;

                if (distSq <= maxDistSq) {
                  queue.push_back(QPoint(nx, ny));
                }
              }
            }
          }
        }

        ColorRangeSelector selector;
        QPainterPath wandPath = selector.maskToPath(mask);

        QPainterPath beforePath = m_selectionPath;
        bool beforeHasSel = m_hasSelection;

        if (m_selectionAddMode == 0) {
          m_selectionPath = wandPath;
        } else if (m_selectionAddMode == 1) {
          m_selectionPath = m_selectionPath.united(wandPath);
        } else if (m_selectionAddMode == 2) {
          m_selectionPath = m_selectionPath.subtracted(wandPath);
        }

        m_hasSelection = !m_selectionPath.isEmpty();
        emit hasSelectionChanged();

        if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
          m_marchingAntsTimer->start();
        else if (!m_hasSelection && m_marchingAntsTimer)
          m_marchingAntsTimer->stop();

        update();

        auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
          m_selectionPath = path;
          m_hasSelection = hasSel;
          emit hasSelectionChanged();
          if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
            m_marchingAntsTimer->start();
          else if (!m_hasSelection && m_marchingAntsTimer)
            m_marchingAntsTimer->stop();
          update();
        };

        if (m_undoManager) {
          m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
              updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
        }
      }
    }
    event->accept();
    return;
  }

  if (m_tool == ToolType::Transform) {
    QPointF canvasPos = screenToCanvas(event->position());

    // 1. Hit test layers from top to bottom to find if we clicked on a stroke of any visible, unlocked layer
    int targetLayerIdx = -1;
    int cx = qRound(canvasPos.x());
    int cy = qRound(canvasPos.y());
    if (m_layerManager && cx >= 0 && cx < m_canvasWidth && cy >= 0 && cy < m_canvasHeight) {
      for (int i = m_layerManager->getLayerCount() - 1; i >= 0; --i) {
        Layer *lyr = m_layerManager->getLayer(i);
        if (lyr && lyr->visible && !lyr->locked && lyr->type == Layer::Type::Drawing) {
          // Exclude background layers if any
          QString layerName = QString::fromStdString(lyr->name).toLower();
          if (layerName.contains("background") || layerName.contains("fondo") || layerName.contains("papel")) {
             continue;
          }
          if (lyr->buffer) {
            const uint8_t *pixel = lyr->buffer->pixelAt(cx, cy);
            if (pixel && pixel[3] > 0) { // Alpha > 0 means there is a stroke/color!
              targetLayerIdx = i;
              break;
            }
          }
        }
      }
    }

    if (m_isTransforming) {
      // Check if we clicked on an anchor or control point of a vector layer!
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->type == Layer::Type::Vector && layer->vectorData) {
        QTransform t;
        t.translate(m_transformBox.x(), m_transformBox.y());
        t = t * m_transformMatrix;
        t.translate(-m_transformBox.x(), -m_transformBox.y());
        
        float clickRadius = 12.0f / m_zoomLevel;
        bool foundPoint = false;

        for (auto& stroke : layer->vectorData->getStrokes()) {
          for (size_t segIdx = 0; segIdx < stroke.segments.size(); ++segIdx) {
            auto& seg = stroke.segments[segIdx];
            
            QPointF p0_trans = t.map(QPointF(seg.p0.x, seg.p0.y));
            QPointF cp1_trans = t.map(QPointF(seg.cp1.x, seg.cp1.y));
            QPointF cp2_trans = t.map(QPointF(seg.cp2.x, seg.cp2.y));
            QPointF p3_trans = t.map(QPointF(seg.p3.x, seg.p3.y));

            auto checkAndLock = [&](const QPointF& transPt, int pointType) {
              float dx = canvasPos.x() - transPt.x();
              float dy = canvasPos.y() - transPt.y();
              float d = std::hypot(dx, dy);
              if (d < clickRadius) {
                m_isDraggingVectorPoint = true;
                m_draggedStrokeId = stroke.id;
                m_draggedSegmentIdx = segIdx;
                m_draggedPointType = pointType;
                foundPoint = true;
                return true;
              }
              return false;
            };

            if (checkAndLock(p0_trans, 0)) break;
            if (checkAndLock(cp1_trans, 1)) break;
            if (checkAndLock(cp2_trans, 2)) break;
            if (checkAndLock(p3_trans, 3)) break;
          }
          if (foundPoint) break;
        }

        if (foundPoint) {
          m_vectorBeforeData = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
          m_transformBeforeBuffer = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
          m_dragStartMousePos = event->position();
          event->accept();
          return;
        }
      }

      QRectF transformedBox = m_transformMatrix.mapRect(m_transformBox);
      if (transformedBox.contains(canvasPos)) {
        if (m_currentToolStr == "move") {
          m_isDraggingTransformInCpp = true;
          m_dragStartMousePos = event->position();
          m_dragStartTransformBox = m_transformBox;
          event->accept();
          return;
        }
        // Clicked inside transformedBox -> let QML's DragHandler handle standard dragging.
      } else {
        // Clicked outside transformedBox!
        // Check if we clicked on a stroke of another layer
        if (targetLayerIdx != -1 && targetLayerIdx != m_activeLayerIndex) {
          // Commit current transform, switch to the target layer, and start transform on it!
          commitTransform();
          setActiveLayer(targetLayerIdx);
          beginTransform();
          if (m_isTransforming) {
            m_isDraggingTransformInCpp = true;
            m_dragStartMousePos = event->position();
            m_dragStartTransformBox = m_transformBox;
          }
          event->accept();
          return;
        } else {
          // Clicked on empty space or active layer's blank space -> commit and end transform
          commitTransform();
          event->accept();
          return;
        }
      }
    } else {
      // If NOT currently transforming, start transforming if we clicked on a stroke of any layer!
      if (targetLayerIdx != -1) {
        if (targetLayerIdx != m_activeLayerIndex) {
          setActiveLayer(targetLayerIdx);
        }
        beginTransform();
        if (m_isTransforming) {
          m_isDraggingTransformInCpp = true;
          m_dragStartMousePos = event->position();
          m_dragStartTransformBox = m_transformBox;
        }
        event->accept();
        return;
      } else {
        // Clicked on empty space when not transforming -> ignore / do not start transform
        event->ignore();
        return;
      }
    }
  }

  if (event->button() == Qt::LeftButton) {
    if (m_isDrawing)
      return; // Already drawing (tablet?)

    // Block drawing during two-finger gestures (zoom/pan/rotate)
    if (m_isTwoFingerGesture || m_touchPointCount >= 2) {
      event->accept();
      return;
    }

    // Palm Rejection: If stylus was active recently, ignore touch/mouse drawing press
    bool isStylus = false;
    if (event->device()) {
        if (event->device()->type() == QInputDevice::DeviceType::Stylus ||
            event->device()->type() == QInputDevice::DeviceType::Airbrush) {
            isStylus = true;
        }
    }
    if (!isStylus) {
        qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (now - m_lastStylusTime < 1000) {
            event->accept();
            return;
        }
    }

    // Evitar que herramientas de NO DIBUJO pinten accidentalmente
    if (m_tool != ToolType::Pen && m_tool != ToolType::Eraser &&
        m_tool != ToolType::Fill && m_tool != ToolType::Shape &&
        m_tool != ToolType::Gradient) {
      return;
    }

    QPointF canvasPos = screenToCanvas(event->position());
    if (m_tool == ToolType::Fill) {
      apply_color_drop(static_cast<int>(event->position().x()),
                       static_cast<int>(event->position().y()), m_brushColor);
      return;
    }

    if (m_tool == ToolType::Gradient) {
      m_gradientStartPos = canvasPos;
      m_gradientEndPos = canvasPos;
      m_isGradientDragging = true;
      if (m_layerManager) {
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer) {
          if (layer->gradientMapEnabled) {
            layer->gradientMapStart = canvasPos;
            layer->gradientMapEnd = canvasPos;
            layer->gradientMapUseCoords = true;
            layer->markDirty();
          } else if (layer->buffer) {
            m_strokeBeforeBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
          }
        }
      }
      update();
      return;
    }

#ifdef Q_OS_WIN
    if (PreferencesManager::instance()->tabletInputMode() == "Wintab" && !m_wintabInitAttempted && window()) {
      m_wintabInitAttempted = true;
      WintabManager::instance()->init((HWND)window()->winId());
    }
#endif

    m_isDrawing = true;
    m_lastPos = canvasPos;
    m_strokeStartPos = canvasPos;
    
    Layer *layer = m_layerManager->getActiveLayer();
    m_isVectorDrawing = (layer && layer->type == Layer::Type::Vector);
    if (m_isVectorDrawing) {
      m_vectorPointBuffer.clear();
      if (layer->vectorData) {
        m_vectorBeforeData = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
      } else {
        m_vectorBeforeData.reset();
      }
      VPoint2D vp;
      vp.x = canvasPos.x();
      vp.y = canvasPos.y();
      vp.pressure = 0.5f;
      m_vectorPointBuffer.push_back(vp);
    }

    m_stabPosQueue.clear(); // Reset stabilizer buffer for new stroke
    m_stabPresQueue.clear();

    // Reset history for prediction
    m_historyPos.clear();
    m_historyPressure.clear();
    m_historyTime.clear();
    m_historyPos.push_back(canvasPos);
    m_historyPressure.push_back(0.5f); // Mouse has no pressure
    m_historyTime.push_back(QDateTime::currentMSecsSinceEpoch());
    m_hasPrediction = false;

    // ... rest of stroke start logic ...
    if (layer && layer->locked) {
      emit notificationRequested("Layer is locked", "warning");
      return;
    }

    if (layer && layer->buffer) {
      m_strokeBeforeBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
    }

    m_brushEngine->resetRemainder();
    if (m_symmetryEnabled) {
      for (auto *eng : m_symmetryEngines)
        eng->resetRemainder();
    }
    m_strokePoints.clear();
    m_strokePoints.push_back(event->position());
    m_holdStartPos = event->position();
    m_isHoldingForShape = false;
    m_quickShapeType = QuickShapeType::None;

    // Emitir señal de que se ha empezado a pintar con el color actual
    if (m_tool == ToolType::Pen) {
      emit strokeStarted(m_brushColor);
      if (m_watercolorEngine && isWatercolorBrush()) {
        m_watercolorEngine->startStroke();
      }
    }

    // Solo iniciar timer si es una herramienta de dibujo
    if (m_tool == ToolType::Pen || m_tool == ToolType::Eraser) {
      m_quickShapeTimer->start(500);
    }

    // float pressure = 0.1f;
    // handleDraw(event->position(), pressure);
  }
}

void CanvasItem::mouseMoveEvent(QMouseEvent *event) {
  event->accept(); // Evita que el evento suba a QML

  if (m_tool == ToolType::Gradient && m_isGradientDragging) {
    QPointF canvasPos = screenToCanvas(event->position());
    m_gradientEndPos = canvasPos;
    if (m_layerManager) {
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->gradientMapEnabled) {
        layer->gradientMapEnd = canvasPos;
        layer->markDirty();
      }
    }
    update();
    event->accept();
    return;
  }

  // ── Dragging Vanishing Points in Perspective Ruler ──
  if (m_perspectiveRuler && m_perspectiveRuler->active() && m_draggingVp != 0) {
    QPointF canvasPos = screenToCanvas(event->position());
    if (m_draggingVp == 1) {
      m_perspectiveRuler->setVp1(canvasPos);
    } else if (m_draggingVp == 2) {
      m_perspectiveRuler->setVp2(canvasPos);
    } else if (m_draggingVp == 3) {
      m_perspectiveRuler->setVp3(canvasPos);
    }
    update(); // Repaint canvas guidelines and handles
    event->accept();
    return;
  }

  // ── Dragging Speech Balloon Handles ──
  if (m_hasActiveSpeechBalloon && m_draggingBalloonHandle != 0) {
    QPointF canvasPos = screenToCanvas(event->position());
    if (m_draggingBalloonHandle == 1) { // Center
      float dx = canvasPos.x() - m_activeSpeechBalloon.cx;
      float dy = canvasPos.y() - m_activeSpeechBalloon.cy;
      m_activeSpeechBalloon.cx = canvasPos.x();
      m_activeSpeechBalloon.cy = canvasPos.y();
      m_activeSpeechBalloon.tailStart1 += QPointF(dx, dy);
      m_activeSpeechBalloon.tailStart2 += QPointF(dx, dy);
      m_activeSpeechBalloon.tailControl1 += QPointF(dx, dy);
      m_activeSpeechBalloon.tailControl2 += QPointF(dx, dy);
      m_activeSpeechBalloon.tailEnd += QPointF(dx, dy);
    } else if (m_draggingBalloonHandle == 2) { // Radii
      m_activeSpeechBalloon.rx = std::max(10.0f, (float)std::abs(canvasPos.x() - m_activeSpeechBalloon.cx));
      m_activeSpeechBalloon.ry = std::max(10.0f, m_activeSpeechBalloon.rx * 0.6f);
      // Re-anchor tail attachments dynamically
      m_activeSpeechBalloon.tailStart1 = QPointF(m_activeSpeechBalloon.cx - m_activeSpeechBalloon.rx * 0.3f, m_activeSpeechBalloon.cy + m_activeSpeechBalloon.ry * 0.95f);
      m_activeSpeechBalloon.tailStart2 = QPointF(m_activeSpeechBalloon.cx + m_activeSpeechBalloon.rx * 0.3f, m_activeSpeechBalloon.cy + m_activeSpeechBalloon.ry * 0.95f);
    } else if (m_draggingBalloonHandle == 3) { // tailControl1
      m_activeSpeechBalloon.tailControl1 = canvasPos;
    } else if (m_draggingBalloonHandle == 4) { // tailControl2
      m_activeSpeechBalloon.tailControl2 = canvasPos;
    } else if (m_draggingBalloonHandle == 5) { // tailEnd
      m_activeSpeechBalloon.tailEnd = canvasPos;
    }
    update();
    event->accept();
    return;
  }

  // Handle C++ vector point dragging
  if (m_isTransforming && m_isDraggingVectorPoint) {
    Layer *layer = m_layerManager->getActiveLayer();
    if (layer && layer->type == Layer::Type::Vector && layer->vectorData) {
      QPointF canvasPos = screenToCanvas(event->position());
      
      QTransform t;
      t.translate(m_transformBox.x(), m_transformBox.y());
      t = t * m_transformMatrix;
      t.translate(-m_transformBox.x(), -m_transformBox.y());
      
      QTransform invT = t.inverted();
      QPointF origPos = invT.map(canvasPos);

      // Now we update the dragged point inside the segment!
      VectorStroke* stroke = layer->vectorData->getStroke(m_draggedStrokeId);
      if (stroke && m_draggedSegmentIdx < stroke->segments.size()) {
        auto& seg = stroke->segments[m_draggedSegmentIdx];
        if (m_draggedPointType == 0) {
          seg.p0.x = origPos.x(); seg.p0.y = origPos.y();
          // Sync with previous segment's end point if there is one
          if (m_draggedSegmentIdx > 0) {
            stroke->segments[m_draggedSegmentIdx - 1].p3.x = origPos.x();
            stroke->segments[m_draggedSegmentIdx - 1].p3.y = origPos.y();
          }
        } else if (m_draggedPointType == 1) {
          seg.cp1.x = origPos.x(); seg.cp1.y = origPos.y();
        } else if (m_draggedPointType == 2) {
          seg.cp2.x = origPos.x(); seg.cp2.y = origPos.y();
        } else if (m_draggedPointType == 3) {
          seg.p3.x = origPos.x(); seg.p3.y = origPos.y();
          // Sync with next segment's start point if there is one
          if (m_draggedSegmentIdx + 1 < stroke->segments.size()) {
            stroke->segments[m_draggedSegmentIdx + 1].p0.x = origPos.x();
            stroke->segments[m_draggedSegmentIdx + 1].p0.y = origPos.y();
          }
        }
        stroke->recalcBounds();
      }

      // Re-rasterize the entire vector layer immediately for real-time visual feedback!
      layer->buffer->clear();
      layer->vectorData->rasterize(*layer->buffer);
      layer->dirty = false;
      layer->markDirty();
      m_cachedCanvasImage = QImage(); // Force redraw!
      
      update();
      event->accept();
      return;
    }
  }

  // Handle C++ transform dragging
  if (m_tool == ToolType::Transform && m_isDraggingTransformInCpp && m_isTransforming) {
    QPointF mouseDelta = event->position() - m_dragStartMousePos;
    float rad = qDegreesToRadians(-m_canvasRotation);
    float cosA = std::cos(rad);
    float sinA = std::sin(rad);
    QPointF rotatedDelta(mouseDelta.x() * cosA - mouseDelta.y() * sinA,
                         mouseDelta.x() * sinA + mouseDelta.y() * cosA);
    QPointF canvasDelta = rotatedDelta / m_zoomLevel;

    m_transformBox.moveTo(m_dragStartTransformBox.topLeft() + canvasDelta);

    // Crucial: Update m_transformMatrix in C++ directly since QML manipulator
    // is invisible and won't trigger updateTransformProperties via onXChanged/onYChanged!
    m_transformMatrix = QTransform();
    m_transformMatrix.translate(m_transformBox.x(), m_transformBox.y());

    emit transformBoxChanged();
    update();
    return;
  }

  // Actualizar cursor si estamos arrastrando
  if (m_spacePressed || m_tool == ToolType::Hand) {
    if (event->buttons() & Qt::LeftButton) {
      if (m_spacePressed)
        QGuiApplication::changeOverrideCursor(m_customClosedHandCursor);
      else
        setCursor(m_customClosedHandCursor);
    } else {
      if (m_spacePressed)
        QGuiApplication::changeOverrideCursor(m_customOpenHandCursor);
      else
        setCursor(m_customOpenHandCursor);
    }
  } else if (m_tool == ToolType::Transform) {
    setCursor(getModernCursor());
  } else {
    setCursor(Qt::BlankCursor); // DIBUJO = INVISIBLE
  }

  // --- Mantenemos tu código original para actualizar el trazo ---
  m_cursorPos = event->position();
  m_cursorVisible = true;
  requestUpdate();

  emit cursorPosChanged(event->position().x(), event->position().y());

  // ═══ Canvas Rotation Gesture: 'R' + Drag ═══
  if (m_isRotatingCanvas && (event->buttons() & Qt::LeftButton)) {
    QPointF viewCenter(width() / 2.0, height() / 2.0);
    QPointF startVec = m_rotateStartPos - viewCenter;
    QPointF currentVec = event->position() - viewCenter;
    float startAngle = std::atan2(startVec.y(), startVec.x());
    float currentAngle = std::atan2(currentVec.y(), currentVec.x());
    float deltaAngle = qRadiansToDegrees(currentAngle - startAngle);
    setCanvasRotation(m_rotateStartAngle + deltaAngle);
    m_lastMousePos = event->position();
    return;
  }

  if ((m_tool == ToolType::Hand || m_spacePressed) &&
      (event->buttons() & Qt::LeftButton)) {
    // Rotation-aware pan: rotate the screen-space delta by the inverse
    // of the canvas rotation so dragging always moves in the expected direction
    QPointF screenDelta = event->position() - m_lastMousePos;
    float rad = qDegreesToRadians(-m_canvasRotation);
    float cosA = std::cos(rad);
    float sinA = std::sin(rad);
    QPointF rotatedDelta(screenDelta.x() * cosA - screenDelta.y() * sinA,
                         screenDelta.x() * sinA + screenDelta.y() * cosA);
    QPointF delta = rotatedDelta / m_zoomLevel;
    m_viewOffset += delta;
    m_lastMousePos = event->position();
    emit viewOffsetChanged();
    requestUpdate();
    return;
  }

  if (m_tool == ToolType::PanelCut && m_isPanelCutting) {
    QPointF canvasPos = screenToCanvas(event->position());
    double dx = canvasPos.x() - m_panelCutStartPos.x();
    double dy = canvasPos.y() - m_panelCutStartPos.y();
    double dist = std::hypot(dx, dy);
    if (dist > 5.0) {
      double deg = std::atan2(dy, dx) * 180.0 / M_PI;
      if (deg < 0) deg += 360.0;
      
      double snappedDeg = deg;
      double minDiff = 360.0;
      std::vector<double> targets = { 0, 30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330, 360 };
      for (double target : targets) {
          double diff = std::abs(deg - target);
          if (diff < minDiff) {
              minDiff = diff;
              snappedDeg = target;
          }
      }
      
      if (minDiff <= 5.0) {
          double snappedRad = snappedDeg * M_PI / 180.0;
          canvasPos = m_panelCutStartPos + QPointF(dist * std::cos(snappedRad), dist * std::sin(snappedRad));
      }
    }
    m_panelCutEndPos = canvasPos;
    update();
    return;
  }

  // Liquify Tool — Continuous deformation
  if (m_tool == ToolType::Liquify && m_isLiquifying &&
      (event->buttons() & Qt::LeftButton)) {
    QPointF canvasPos = screenToCanvas(event->position());
    handleLiquifyDraw(canvasPos, 0.5f);
    return;
  }

  if (m_tool == ToolType::Eyedropper && (event->buttons() & Qt::LeftButton)) {
    QString color = sampleColor(static_cast<int>(event->position().x()),
                                static_cast<int>(event->position().y()));
    setBrushColor(QColor(color));
    return;
  }



  if ((m_tool == ToolType::Lasso || m_tool == ToolType::RectSelect ||
       m_tool == ToolType::EllipseSelect ||
       m_tool == ToolType::MagneticLasso) &&
      (event->buttons() & Qt::LeftButton)) {
    QPointF canvasPos = screenToCanvas(event->position());
    m_lassoCursorPos = canvasPos;

    if (m_tool == ToolType::Lasso && m_lassoMode == 0 && m_isLassoDragging) {
      // Freehand: keep extending the active path
      float dist = QLineF(m_lastSelectionPoint, canvasPos).length();
      if (dist >= 2.0f) { // min spacing to avoid thousands of micro-segments
        m_activeLassoPath.lineTo(canvasPos);
        m_lastSelectionPoint = canvasPos;
      }
    } else if (m_tool == ToolType::Lasso && m_lassoMode == 1) {
      // Polygonal: just update cursor position for rubber-band
    } else if (m_tool == ToolType::MagneticLasso && m_isMagneticLassoActive) {
      // Magnetic: cursor pos drives the rubber-band line
    } else if ((m_tool == ToolType::RectSelect ||
                m_tool == ToolType::EllipseSelect) && m_isLassoDragging) {
      // Rect/Ellipse: show live preview via cursor pos update
    }

    update();
    return;
  }

  // Update cursor pos for all lasso tools even without button held (rubber-band)
  if (m_tool == ToolType::MagneticLasso && m_isMagneticLassoActive && m_activeLassoPath.elementCount() > 0) {
    m_lassoCursorPos = screenToCanvas(event->position());
    
    if (QLineF(m_lassoCursorPos, m_lastTraceTarget).length() < 4.0f) {
      return; // Skip heavy Dijkstra on micro-movements to eliminate lag!
    }
    m_lastTraceTarget = m_lassoCursorPos;

    // Precompute gradient map if dirty
    if (m_gradientMapDirty) {
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer) {
        QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888);
        m_edgeDetector->computeGradientMap(img);
        m_gradientMapDirty = false;
      }
    }
    
    QPointF snappedCursor = m_edgeDetector->findEdgePoint(m_lassoCursorPos, m_magneticSearchRadius);
    auto previewPts = m_edgeDetector->traceEdgePath(m_activeLassoPath.currentPosition(), snappedCursor);
    
    m_magneticPreviewPath = QPainterPath();
    if (!previewPts.empty()) {
      m_magneticPreviewPath.moveTo(m_activeLassoPath.currentPosition());
      for (auto &pt : previewPts) {
        m_magneticPreviewPath.lineTo(pt);
      }
    } else {
      m_magneticPreviewPath.moveTo(m_activeLassoPath.currentPosition());
      m_magneticPreviewPath.lineTo(snappedCursor);
    }
    update();
  } else if (m_tool == ToolType::Lasso || m_tool == ToolType::MagneticLasso) {
    m_lassoCursorPos = screenToCanvas(event->position());
    if (m_activeLassoPath.elementCount() > 0) update();
  }

  if (m_isDrawing) {
#ifdef Q_OS_WIN
    if (PreferencesManager::instance()->tabletInputMode() == "Wintab" && !m_wintabInitAttempted && window()) {
      m_wintabInitAttempted = true;
      WintabManager::instance()->init((HWND)window()->winId());
    }
#endif

    float pressure = 1.0f;
    float tiltFactor = 0.0f;
    
    // Check if Wintab should be used according to user preferences
    bool useWintab = (PreferencesManager::instance()->tabletInputMode() == "Wintab");
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    bool wintabRecentlyActive = useWintab && (now - m_lastWintabTime < 250); // Wintab was active within the last 250ms
    
    bool isStylus = false;
    if (event->device()) {
        if (event->device()->type() == QInputDevice::DeviceType::Stylus ||
            event->device()->type() == QInputDevice::DeviceType::Airbrush) {
            isStylus = true;
        }
    }

    if (isStylus) {
        m_lastStylusTime = now;
    } else {
        // Palm Rejection: If stylus was active in the last 1000ms, ignore touch/mouse move drawing
        if (now - m_lastStylusTime < 1000) {
            event->accept();
            return;
        }
    }

    if (wintabRecentlyActive) {
      m_wintabActive = true;
      pressure = m_wintabPressure;
      // Convert Wintab tilts to a single tiltFactor like Qt does
      float tiltDist = std::sqrt(m_wintabTiltX*m_wintabTiltX + m_wintabTiltY*m_wintabTiltY);
      tiltFactor = std::min(1.0f, tiltDist / 60.0f); 
    } else {
      m_wintabActive = false;
      if (isStylus && !event->points().isEmpty()) {
        float p = event->points().first().pressure();
        if (p > 0.0f)
          pressure = p;
      } else {
        pressure = 1.0f;
      }
    }

    if (m_isHoldingForShape && m_quickShapeType != QuickShapeType::None) {
      // ═══════════════════════════════════════════════════════════
      // QUICKSHAPE RESIZE: Procreate-style drag-to-resize
      // ═══════════════════════════════════════════════════════════
      float distFromAnchor =
          QLineF(m_quickShapeAnchor, event->position()).length();
      if (distFromAnchor > 5.0f) { // Dead zone to prevent accidental resize
        m_quickShapeResizing = true;

        if (m_quickShapeType == QuickShapeType::Circle) {
          // Scale radius based on distance from center (in screen coords)
          QPointF centerScreen =
              m_quickShapeCenter * m_zoomLevel + m_viewOffset * m_zoomLevel;
          float distFromCenter =
              QLineF(centerScreen, event->position()).length();
          float newRadius = distFromCenter / m_zoomLevel;
          // Clamp to reasonable bounds
          m_quickShapeRadius = std::max(3.0f, newRadius);
          redrawQuickShape();
        } else if (m_quickShapeType == QuickShapeType::Line) {
          // Scale line from center using original direction
          QPointF centerScreen =
              m_quickShapeCenter * m_zoomLevel + m_viewOffset * m_zoomLevel;
          float distFromCenter =
              QLineF(centerScreen, event->position()).length();
          float newHalfLen = distFromCenter / m_zoomLevel;

          // Use the stored stable direction vector
          m_quickShapeLineP1 =
              m_quickShapeCenter - m_quickShapeLineDir * newHalfLen;
          m_quickShapeLineP2 =
              m_quickShapeCenter + m_quickShapeLineDir * newHalfLen;
          redrawQuickShape();
        }
      }
    } else if (!m_isHoldingForShape) {
      m_strokePoints.push_back(event->position());
      float dist =
          QPointF(event->position() - m_holdStartPos).manhattanLength();
      if (dist > 25.0f) {
        m_holdStartPos = event->position();
        if (m_tool == ToolType::Pen || m_tool == ToolType::Eraser)
          m_quickShapeTimer->start(500);
      }
      // Block drawing during two-finger gestures
      if (!m_isTwoFingerGesture && m_touchPointCount < 2)
        handleDraw(event->position(), pressure, tiltFactor);
    }
  }

  m_cursorPos = event->position();
  m_lastMousePos = event->position();
  update();
}

void CanvasItem::mouseReleaseEvent(QMouseEvent *event) {
  if (m_tool == ToolType::Gradient && m_isGradientDragging) {
    m_isGradientDragging = false;
    QPointF canvasPos = screenToCanvas(event->position());
    m_gradientEndPos = canvasPos;

    if (m_layerManager) {
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer) {
        if (layer->gradientMapEnabled) {
          layer->gradientMapEnd = canvasPos;
          layer->gradientMapUseCoords = true;
          layer->markDirty();
        } else if (layer->buffer && m_strokeBeforeBuffer) {
          // Paint the gradient to the layer's buffer
          QImage img(layer->buffer->data(), layer->buffer->width(), layer->buffer->height(), QImage::Format_RGBA8888_Premultiplied);
          QPainter painter(&img);
          painter.setRenderHint(QPainter::Antialiasing);

          // Clip to selection if active
          if (!m_selectionPath.isEmpty()) {
            painter.setClipPath(m_selectionPath);
          }

          // Choose linear or radial gradient
          QGradient grad;
          if (m_gradientShape == "radial") {
            double radius = QLineF(m_gradientStartPos, m_gradientEndPos).length();
            if (radius < 1.0) radius = 1.0;
            grad = QRadialGradient(m_gradientStartPos, radius);
          } else {
            grad = QLinearGradient(m_gradientStartPos, m_gradientEndPos);
          }

          // Load and sort stops
          std::vector<std::pair<double, QColor>> sortedStops;
          for (const QVariant &val : m_gradientStops) {
            QVariantMap stopObj = val.toMap();
            double pos = stopObj["position"].toDouble();
            QColor col(stopObj["color"].toString());
            sortedStops.push_back({pos, col});
          }
          std::sort(sortedStops.begin(), sortedStops.end(), [](const auto &a, const auto &b) {
            return a.first < b.first;
          });

          for (const auto &stop : sortedStops) {
            grad.setColorAt(stop.first, stop.second);
          }

          painter.setBrush(grad);
          painter.setPen(Qt::NoPen);
          painter.drawRect(0, 0, layer->buffer->width(), layer->buffer->height());
          painter.end();

          layer->dirty = true;
          layer->markDirty();

          // Push Undo
          auto after = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
          m_undoManager->pushCommand(std::make_unique<artflow::StrokeUndoCommand>(
              m_layerManager, m_activeLayerIndex, std::move(m_strokeBeforeBuffer), std::move(after)));

          updateLayersList();
        }
      }
    }
    update();
    event->accept();
    return;
  }

  if (m_draggingVp != 0) {
    m_draggingVp = 0;
    event->accept();
    update();
    return;
  }

  if (m_draggingBalloonHandle != 0) {
    m_draggingBalloonHandle = 0;
    event->accept();
    update();
    return;
  }

  // End rotation gesture on mouse release
  if (m_isRotatingCanvas) {
    m_isRotatingCanvas = false;
    if (m_spacePressed)
      QGuiApplication::changeOverrideCursor(m_customOpenHandCursor);
    else
      setCursor(Qt::BlankCursor);
    return;
  }

  if (m_tool == ToolType::Hand || m_spacePressed) {
    if (m_spacePressed) {
      QGuiApplication::changeOverrideCursor(m_customOpenHandCursor);
    } else {
      setCursor(m_customOpenHandCursor);
    }
  }
  if (m_tool == ToolType::PanelCut && m_isPanelCutting) {
    QPointF canvasPos = screenToCanvas(event->position());
    double dx = canvasPos.x() - m_panelCutStartPos.x();
    double dy = canvasPos.y() - m_panelCutStartPos.y();
    double dist = std::hypot(dx, dy);
    if (dist > 5.0) {
      double deg = std::atan2(dy, dx) * 180.0 / M_PI;
      if (deg < 0) deg += 360.0;
      
      double snappedDeg = deg;
      double minDiff = 360.0;
      std::vector<double> targets = { 0, 30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330, 360 };
      for (double target : targets) {
          double diff = std::abs(deg - target);
          if (diff < minDiff) {
              minDiff = diff;
              snappedDeg = target;
          }
      }
      
      if (minDiff <= 5.0) {
          double snappedRad = snappedDeg * M_PI / 180.0;
          canvasPos = m_panelCutStartPos + QPointF(dist * std::cos(snappedRad), dist * std::sin(snappedRad));
      }
    }
    m_panelCutEndPos = canvasPos;
    m_isPanelCutting = false;

    // Only cut if the line has some length
    if (QLineF(m_panelCutStartPos, m_panelCutEndPos).length() > 5.0) {
      executePanelCut(m_panelCutStartPos, m_panelCutEndPos);
    }

    update();
    return;
  }

  if (m_tool == ToolType::Lasso || m_tool == ToolType::RectSelect ||
      m_tool == ToolType::EllipseSelect || m_tool == ToolType::MagneticLasso) {
    QPointF canvasPos = screenToCanvas(event->position());
    m_lassoCursorPos = canvasPos;

    if (m_tool == ToolType::Lasso && m_lassoMode == 0 && m_isLassoDragging) {
      // Freehand: close on release
      m_isLassoDragging = false;
      if (m_activeLassoPath.elementCount() >= 3) {
        m_activeLassoPath.closeSubpath();
        _commitLassoPath();
      } else {
        m_activeLassoPath = QPainterPath(); // too few points, discard
      }
    } else if (m_tool == ToolType::MagneticLasso) {
      // Polygonal: release doesn't close (handled by doubleclick or closeLasso)
    } else if (m_tool == ToolType::RectSelect) {
      m_isLassoDragging = false;
      if ((canvasPos - m_selectionStartPos).manhattanLength() > 4.0) {
        QRectF rect = QRectF(m_selectionStartPos, canvasPos).normalized();
        QPainterPath newPath;
        newPath.addRect(rect);
        _commitNewShapePath(newPath);
      }
    } else if (m_tool == ToolType::EllipseSelect) {
      m_isLassoDragging = false;
      if ((canvasPos - m_selectionStartPos).manhattanLength() > 4.0) {
        QRectF rect = QRectF(m_selectionStartPos, canvasPos).normalized();
        QPainterPath newPath;
        newPath.addEllipse(rect);
        _commitNewShapePath(newPath);
      }
    }

    emit hasSelectionChanged();
    update();
    return;
  }

  if (m_isDraggingVectorPoint) {
    m_isDraggingVectorPoint = false;
    Layer *layer = m_layerManager->getActiveLayer();
    if (layer && layer->type == Layer::Type::Vector && layer->vectorData) {
      auto afterVector = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
      auto afterBuffer = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
      m_undoManager->pushCommand(std::make_unique<VectorUndoCommand>(
          m_layerManager, m_activeLayerIndex, std::move(m_transformBeforeBuffer),
          std::move(afterBuffer), std::move(m_vectorBeforeData), std::move(afterVector)));
    }
    m_draggedStrokeId = 0;
    m_draggedPointType = -1;
    update();
    event->accept();
    return;
  }

  if (m_tool == ToolType::Transform) {
    m_isDraggingTransformInCpp = false;
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
      
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->type == Layer::Type::Vector) {
        finalizeVectorStroke();
        m_isDrawing = false;
        m_isHoldingForShape = false;
        m_quickShapeType = QuickShapeType::None;
        m_hasPrediction = false;
        m_smudgeColorValid = false;
        event->accept();
        return;
      }

      bool wasHolding = m_isHoldingForShape;
      m_isDrawing = false;
      m_gradientMapDirty = true;
      m_isHoldingForShape = false;
      m_quickShapeType = QuickShapeType::None;
      m_hasPrediction = false;
      // Resetear el smudge color — el siguiente trazo empieza fresco
      m_smudgeColorValid = false;

      if (m_pingFBO) {
        if (!wasHolding) {
          // Normal stroke: copy FBO result to CPU layer buffer
          QImage result = m_pingFBO->toImage(true).convertToFormat(
              QImage::Format_RGBA8888_Premultiplied);

          Layer *layer = m_layerManager->getActiveLayer();
          if (layer && layer->buffer) {
            layer->buffer->loadRawData(result.bits());
            layer->markDirty();
            m_cachedCanvasImage = QImage(); // Force recomposite
          }
        } else {
          // QuickShape stroke: drawCircle/drawLine already wrote to layer
          // buffer Just mark it dirty so the cache recomposes correctly on next
          // paint
          Layer *layer = m_layerManager->getActiveLayer();
          if (layer) {
            layer->dirty = true;
            layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
          }
          m_cachedCanvasImage = QImage(); // Force full recomposite
        }
        delete m_pingFBO;
        m_pingFBO = nullptr;
        delete m_pongFBO;
        m_pongFBO = nullptr;
        if (m_dabFBO) {
          delete m_dabFBO;
          m_dabFBO = nullptr;
        }
      } else {
        // CPU Fallback: Stroke was drawn directly to layer buffer's raw data
        // Sync the raw data into the tile grid before capturing the undo snapshot
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer && !wasHolding) {
          layer->buffer->loadRawData(layer->buffer->data());
          layer->markDirty();
          m_cachedCanvasImage = QImage();
        }
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
      setProjectDirty(true);
    }
  }
}

void CanvasItem::mouseDoubleClickEvent(QMouseEvent *event) {
  if (m_tool == ToolType::MagneticLasso && m_isMagneticLassoActive) {
    // Snap the final double-click point and trace path to it before closing!
    QPointF canvasPos = screenToCanvas(event->position());
    QPointF snapped = m_edgeDetector->findEdgePoint(canvasPos, m_magneticSearchRadius);
    if (m_activeLassoPath.elementCount() > 0) {
      auto edgePath = m_edgeDetector->traceEdgePath(m_activeLassoPath.currentPosition(), snapped);
      for (auto &pt : edgePath) {
        m_activeLassoPath.lineTo(pt);
      }
    }
    closeLasso();
  } else if (m_tool == ToolType::Lasso && m_lassoMode == 1) {
    // Double-click also closes polygonal free lasso
    closeLasso();
  }
}

void CanvasItem::onWintabEvent(float x, float y, float pressure, float tiltX, float tiltY) {
#ifdef Q_OS_WIN
    if (PreferencesManager::instance()->tabletInputMode() != "Wintab") {
        m_wintabActive = false;
        return;
    }
    m_wintabPressure = pressure;
    m_wintabTiltX = tiltX;
    m_wintabTiltY = tiltY;
    m_wintabActive = true;
    m_lastWintabTime = QDateTime::currentMSecsSinceEpoch();
#endif
}

void CanvasItem::tabletEvent(QTabletEvent *event) {
  // ── Dragging Vanishing Points in Perspective Ruler (Tablet) ──
  if (m_perspectiveRuler && m_perspectiveRuler->active()) {
    bool canDrag = false;
    if (m_layerManager) {
      artflow::Layer *activeLayer = m_layerManager->getActiveLayer();
      if (activeLayer && activeLayer->name == "Capa no destructiva") {
        canDrag = true;
      }
    }
    
    if (canDrag) {
      if (event->type() == QEvent::TabletPress) {
        QPointF canvasPos = screenToCanvas(event->position());
        double hitRadius = 24.0 / m_zoomLevel;
        auto dist = [](const QPointF& p1, const QPointF& p2) {
          double dx = p1.x() - p2.x();
          double dy = p1.y() - p2.y();
          return std::sqrt(dx * dx + dy * dy);
        };

        if (m_perspectiveRuler->vp1Active() && m_perspectiveRuler->type() >= 1 && dist(canvasPos, m_perspectiveRuler->vp1()) < hitRadius) {
          m_draggingVp = 1;
          event->accept();
          return;
        }
        if (m_perspectiveRuler->vp2Active() && m_perspectiveRuler->type() >= 2 && dist(canvasPos, m_perspectiveRuler->vp2()) < hitRadius) {
          m_draggingVp = 2;
          event->accept();
          return;
        }
        if (m_perspectiveRuler->vp3Active() && m_perspectiveRuler->type() >= 3 && dist(canvasPos, m_perspectiveRuler->vp3()) < hitRadius) {
          m_draggingVp = 3;
          event->accept();
          return;
        }
      } else if (event->type() == QEvent::TabletMove && m_draggingVp != 0) {
        QPointF canvasPos = screenToCanvas(event->position());
        if (m_draggingVp == 1) {
          m_perspectiveRuler->setVp1(canvasPos);
        } else if (m_draggingVp == 2) {
          m_perspectiveRuler->setVp2(canvasPos);
        } else if (m_draggingVp == 3) {
          m_perspectiveRuler->setVp3(canvasPos);
        }
        update();
        event->accept();
        return;
      } else if (event->type() == QEvent::TabletRelease && m_draggingVp != 0) {
        m_draggingVp = 0;
        update();
        event->accept();
        return;
      }
    } else {
      if (m_draggingVp != 0 && (event->type() == QEvent::TabletRelease || event->type() == QEvent::TabletMove)) {
        m_draggingVp = 0;
        update();
      }
    }
  }

  m_lastStylusTime = QDateTime::currentMSecsSinceEpoch();

#ifdef Q_OS_WIN
  if (PreferencesManager::instance()->tabletInputMode() == "Wintab" && !m_wintabInitAttempted && window()) {
    m_wintabInitAttempted = true;
    WintabManager::instance()->init((HWND)window()->winId());
  }
#endif

  float pressure = event->pressure();
  // Normalizar presión
  if (pressure > 1.0f)
    pressure /= 1024.0f;

  // CAPTURAR INCLINACIÓN (TILT) - Pilar 1 Premium
  // xTilt y yTilt suelen devolver grados (-60 a 60).
  // Obtenemos un factor de 0.0 (vertical) a 1.0 (máxima inclinación)
  float tiltX = event->xTilt();
  float tiltY = event->yTilt();
  
  bool useWintab = (PreferencesManager::instance()->tabletInputMode() == "Wintab");
  if (!useWintab) {
      m_wintabActive = false;
  }
  
  if (m_wintabActive) {
      pressure = m_wintabPressure;
      tiltX = m_wintabTiltX;
      tiltY = m_wintabTiltY;
  }
  
  float tiltFactor =
      std::max(std::abs((float)tiltX), std::abs((float)tiltY)) / 60.0f;
  tiltFactor = std::max(0.0f, std::min(1.0f, tiltFactor));

  if (event->type() == QEvent::TabletPress) {
    forceActiveFocus();
    // ═══ Canvas Rotation Gesture: 'R' + Drag (Tablet) ═══
    if (m_rPressed) {
      m_isRotatingCanvas = true;
      m_rotateStartPos = event->position();
      m_rotateStartAngle = m_canvasRotation;
      setCursor(Qt::CrossCursor);
      event->accept();
      return;
    }

    // Block drawing during two-finger gestures (zoom/pan/rotate)
    if (m_isTwoFingerGesture || m_touchPointCount >= 2) {
      event->accept();
      return;
    }

    // Evitar que herramientas de NO DIBUJO pinten accidentalmente
    if (m_tool != ToolType::Pen && m_tool != ToolType::Eraser &&
        m_tool != ToolType::Fill && m_tool != ToolType::Shape) {
      return;
    }

    m_isDrawing = true;
    m_stabilizedPos = event->position();
    m_stabPosQueue.clear(); // Reset stabilizer buffer for new stroke
    m_stabPresQueue.clear();
    QPointF p = event->position();
    QPointF canvasPos = screenToCanvas(p);
    m_lastPos = canvasPos;
    m_strokeStartPos = canvasPos;

    Layer *layer = m_layerManager->getActiveLayer();
    m_isVectorDrawing = (layer && layer->type == Layer::Type::Vector);
    if (m_isVectorDrawing) {
      m_vectorPointBuffer.clear();
      if (layer->vectorData) {
        m_vectorBeforeData = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
      } else {
        m_vectorBeforeData.reset();
      }
      VPoint2D vp;
      vp.x = canvasPos.x();
      vp.y = canvasPos.y();
      vp.pressure = pressure;
      m_vectorPointBuffer.push_back(vp);
    }

    // Reset history for prediction
    m_historyPos.clear();
    m_historyPressure.clear();
    m_historyTime.clear();
    m_historyPos.push_back(canvasPos);
    m_historyPressure.push_back(pressure);
    m_historyTime.push_back(QDateTime::currentMSecsSinceEpoch());
    m_hasPrediction = false;

    m_hasPrediction = false;

    // Undo Snapshot
    if (layer && layer->locked) {
      emit notificationRequested("Layer is locked", "warning");
      return;
    }

    if (layer && layer->buffer) {
      m_strokeBeforeBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
    }

    m_brushEngine->resetRemainder();
    if (m_symmetryEnabled) {
      for (auto *eng : m_symmetryEngines)
        eng->resetRemainder();
    }

    m_strokePoints.clear();
    m_strokePoints.push_back(event->position());
    m_holdStartPos = event->position();
    m_isHoldingForShape = false;
    m_quickShapeType = QuickShapeType::None;

    // Emitir señal de que se ha empezado a pintar con el color actual
    if (m_tool == ToolType::Pen) {
      emit strokeStarted(m_brushColor);
      if (m_watercolorEngine && isWatercolorBrush()) {
        m_watercolorEngine->startStroke();
      }
    }

    m_quickShapeTimer->start(500);

    handleDraw(event->position(), pressure, tiltFactor);
    event->accept();

  } else if (event->type() == QEvent::TabletMove) {
    // ═══ Canvas Rotation Gesture: 'R' + Drag (Tablet) ═══
    if (m_isRotatingCanvas) {
      QPointF viewCenter(width() / 2.0, height() / 2.0);
      QPointF startVec = m_rotateStartPos - viewCenter;
      QPointF currentVec = event->position() - viewCenter;
      float startAngle = std::atan2(startVec.y(), startVec.x());
      float currentAngle = std::atan2(currentVec.y(), currentVec.x());
      float deltaAngle = qRadiansToDegrees(currentAngle - startAngle);
      setCanvasRotation(m_rotateStartAngle + deltaAngle);
      m_lastMousePos = event->position();
      event->accept();
      return;
    }

    if (m_isDrawing) {
    if (m_isDrawing && m_isHoldingForShape &&
        m_quickShapeType != QuickShapeType::None) {
      // ═══════════════════════════════════════════════════════════
      // QUICKSHAPE RESIZE (TABLET): Procreate-style drag-to-resize
      // ═══════════════════════════════════════════════════════════
      float distFromAnchor =
          QLineF(m_quickShapeAnchor, event->position()).length();
      if (distFromAnchor > 5.0f) {
        m_quickShapeResizing = true;

        if (m_quickShapeType == QuickShapeType::Circle) {
          QPointF centerScreen =
              m_quickShapeCenter * m_zoomLevel + m_viewOffset * m_zoomLevel;
          float distFromCenter =
              QLineF(centerScreen, event->position()).length();
          m_quickShapeRadius = std::max(3.0f, distFromCenter / m_zoomLevel);
          redrawQuickShape();
        } else if (m_quickShapeType == QuickShapeType::Line) {
          QPointF centerScreen =
              m_quickShapeCenter * m_zoomLevel + m_viewOffset * m_zoomLevel;
          float distFromCenter =
              QLineF(centerScreen, event->position()).length();
          float newHalfLen = distFromCenter / m_zoomLevel;
          m_quickShapeLineP1 =
              m_quickShapeCenter - m_quickShapeLineDir * newHalfLen;
          m_quickShapeLineP2 =
              m_quickShapeCenter + m_quickShapeLineDir * newHalfLen;
          redrawQuickShape();
        }
      }
    } else if (m_isDrawing && !m_isHoldingForShape) {
      m_strokePoints.push_back(event->position());
      float dist =
          QPointF(event->position() - m_holdStartPos).manhattanLength();
      if (dist > 25.0f) { // Increased threshold for jitter
        m_holdStartPos = event->position();
        m_quickShapeTimer->start(500);
      }
    }

    m_cursorPos = event->position();
    // Only draw if there's actual pressure or we are using a tool that
    // doesn't strictly require it, otherwise we leave "stamp" markers at
    // the end
    // Block drawing during two-finger gestures
    if (!m_isTwoFingerGesture && m_touchPointCount < 2 &&
        !m_isHoldingForShape &&
        (pressure > 0.001f || m_tool == ToolType::Eraser)) {
      handleDraw(event->position(), pressure, tiltFactor);
    }
    update();
    event->accept();
    }
  } else if (event->type() == QEvent::TabletRelease) {
    if (m_isRotatingCanvas) {
      m_isRotatingCanvas = false;
      if (m_spacePressed)
        QGuiApplication::changeOverrideCursor(Qt::OpenHandCursor);
      else
        setCursor(Qt::BlankCursor);
      event->accept();
      return;
    }
    m_quickShapeTimer->stop();
    
    Layer *layer = m_layerManager->getActiveLayer();
    if (layer && layer->type == Layer::Type::Vector) {
      finalizeVectorStroke();
      m_isDrawing = false;
      m_isHoldingForShape = false;
      m_quickShapeType = QuickShapeType::None;
      event->accept();
      return;
    }

    bool wasHolding = m_isHoldingForShape;
    m_isDrawing = false;
    m_isHoldingForShape = false;
    m_quickShapeType = QuickShapeType::None;

    // FINALIZAR TRAZO PREMIUM (Pilar 3): Volcar GPU a CPU
    if (m_pingFBO) {
      if (!wasHolding) {
        QImage result = m_pingFBO->toImage(true).convertToFormat(
            QImage::Format_RGBA8888_Premultiplied);
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer) {
          layer->buffer->loadRawData(result.bits());
          layer->markDirty();
          m_cachedCanvasImage = QImage();
        }
      } else {
        // QuickShape: layer buffer already updated by drawCircle/drawLine
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer) {
          layer->dirty = true;
          layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
        }
        m_cachedCanvasImage = QImage();
      }
      delete m_pingFBO;
      m_pingFBO = nullptr;
      delete m_pongFBO;
      m_pongFBO = nullptr;
      if (m_dabFBO) {
        delete m_dabFBO;
        m_dabFBO = nullptr;
      }
    } else {
      // CPU Fallback: Stroke was drawn directly to layer buffer's raw data
      // Sync the raw data into the tile grid before capturing the undo snapshot
      Layer *layer = m_layerManager->getActiveLayer();
      if (layer && layer->buffer && !wasHolding) {
        layer->buffer->loadRawData(layer->buffer->data());
        layer->markDirty();
        m_cachedCanvasImage = QImage();
      }
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
    setProjectDirty(true);
    event->accept();
  }
}

bool CanvasItem::event(QEvent *event) {
  if (event->type() == QEvent::TouchBegin ||
      event->type() == QEvent::TouchUpdate ||
      event->type() == QEvent::TouchEnd ||
      event->type() == QEvent::TouchCancel) {
    if (PreferencesManager::instance()->touchGesturesEnabled() ||
        PreferencesManager::instance()->touchEyedropperEnabled() ||
        PreferencesManager::instance()->multitouchUndoRedoEnabled()) {
      touchEventOverride(static_cast<QTouchEvent *>(event));
      return true;
    }
  }

  if (event->type() == QEvent::NativeGesture) {
    if (PreferencesManager::instance()->touchGesturesEnabled()) {
      nativeGestureEvent(static_cast<QNativeGestureEvent *>(event));
      return true;
    }
  }

  // Dispatch tablet events manually if QQuickItem doesn't automatically
  if (event->type() == QEvent::TabletPress ||
      event->type() == QEvent::TabletMove ||
      event->type() == QEvent::TabletRelease) {
    tabletEvent(static_cast<QTabletEvent *>(event));
    return true;
  }
  return QQuickPaintedItem::event(event);
}

void CanvasItem::touchEventOverride(QTouchEvent *event) {
  qint64 now = QDateTime::currentMSecsSinceEpoch();
  if (now - m_lastStylusTime < 1000) {
    event->accept();
    return;
  }

  int points = event->points().count();
  int prevPointCount = m_touchPointCount;
  m_touchPointCount = points;

  if (event->type() == QEvent::TouchBegin) {
    m_maxTouchPointsThisSession = points;
    m_touchStartTime = QDateTime::currentMSecsSinceEpoch();
    m_touchMovedThisSession = false;

    // ── Single-finger: eyedropper long-press ──
    if (points == 1 &&
        PreferencesManager::instance()->touchEyedropperEnabled()) {
      m_touchStartPos = event->points().first().position();
      m_lastTouchPos = m_touchStartPos;
      m_touchIsEyedropper = false;
      m_touchEyedropperOldColor = m_brushColor;
      m_isTwoFingerGesture = false;
      m_strokeCancelledByGesture = false;
      if (!m_touchTimer) {
        m_touchTimer = new QTimer(this);
        m_touchTimer->setSingleShot(true);
        connect(m_touchTimer, &QTimer::timeout, this, [this]() {
          if (m_touchPointCount == 1 && !m_isDrawing) {
            m_touchIsEyedropper = true;
            m_touchEyedropperColor = QColor(
                sampleColor(m_lastTouchPos.x(), m_lastTouchPos.y(), 0));
            setBrushColor(m_touchEyedropperColor);
            emit notificationRequested("Color Picked", "info");
            update();
          }
        });
      }
      m_touchTimer->start(500); // 500ms long press
    } else if (points > 1) {
      if (m_touchTimer)
        m_touchTimer->stop();
    }

    // ── Three-finger gesture initialization ──
    if (points == 3) {
      float avgY = 0;
      for (int i = 0; i < points; i++)
        avgY += event->points()[i].position().y();
      m_threeFingerStartPos = QPointF(event->points()[0].position().x(), avgY / points);
      m_threeFingerStartSize = m_brushSize;
      m_isThreeFingerGesture = true;
      m_threeFingerMoved = false;

      if (m_touchTimer)
        m_touchTimer->stop();
    }

    // ── Two-finger gesture initialization ──
    if (points == 2 && PreferencesManager::instance()->touchGesturesEnabled()) {
      QPointF p1 = event->points()[0].position();
      QPointF p2 = event->points()[1].position();
      QPointF center = (p1 + p2) / 2.0;
      m_touchStartPos = center;
      m_lastTouchCenter = center;
      m_lastPinchScale = QLineF(p1, p2).length();
      m_lastPinchAngle = std::atan2(p2.y() - p1.y(), p2.x() - p1.x());
      m_isTwoFingerGesture = true;

      // ── Cancel active stroke if user was drawing ──
      if (m_isDrawing) {
        // Revert the stroke buffer to the pre-stroke state
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer && m_strokeBeforeBuffer) {
          layer->buffer->copyFrom(*m_strokeBeforeBuffer);
          layer->dirty = true;
          layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
          if (layer->buffer)
            layer->buffer->clearDirtyFlags();
          m_cachedCanvasImage = QImage(); // Force recomposite

          // Sync GPU FBOs with reverted CPU buffer
          if (m_pingFBO && layer->buffer) {
            QImage fboImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                          QImage::Format_RGBA8888_Premultiplied);
            m_pingFBO->bind();
            QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
            QPainter fboPainter(&device);
            fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
            fboPainter.drawImage(0, 0, fboImg);
            fboPainter.end();
            m_pingFBO->release();
            QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
          }
        }
        m_isDrawing = false;
        m_isHoldingForShape = false;
        m_quickShapeType = QuickShapeType::None;
        m_quickShapeTimer->stop();
        m_hasPrediction = false;
        m_smudgeColorValid = false;
        m_strokeCancelledByGesture = true;
        m_strokeBeforeBuffer.reset();
        update();
      }
    }
    event->accept();

  } else if (event->type() == QEvent::TouchUpdate) {
    m_maxTouchPointsThisSession = std::max(m_maxTouchPointsThisSession, points);
    for (int i = 0; i < points; ++i) {
      QPointF delta = event->points()[i].position() - event->points()[i].pressPosition();
      if (std::abs(delta.x()) > 15.0f || std::abs(delta.y()) > 15.0f) {
        m_touchMovedThisSession = true;
      }
    }
    m_lastTouchPos = event->points().first().position();

    // ── Transition to 3 fingers: brush size gesture ──
    if (points == 3 && prevPointCount < 3 && !m_isThreeFingerGesture) {
      float avgY = 0;
      for (int i = 0; i < points; i++)
        avgY += event->points()[i].position().y();
      m_threeFingerStartPos = QPointF(event->points()[0].position().x(), avgY / points);
      m_threeFingerStartSize = m_brushSize;
      m_isThreeFingerGesture = true;
      m_threeFingerMoved = false;

      if (m_touchTimer)
        m_touchTimer->stop();

      // Cancel drawing if it was active
      if (m_isDrawing) {
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer && m_strokeBeforeBuffer) {
          layer->buffer->copyFrom(*m_strokeBeforeBuffer);
          layer->dirty = true;
          layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
          if (layer->buffer)
            layer->buffer->clearDirtyFlags();
          m_cachedCanvasImage = QImage();

          if (m_pingFBO && layer->buffer) {
            QImage fboImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                          QImage::Format_RGBA8888_Premultiplied);
            m_pingFBO->bind();
            QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
            QPainter fboPainter(&device);
            fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
            fboPainter.drawImage(0, 0, fboImg);
            fboPainter.end();
            m_pingFBO->release();
            QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
          }
        }
        m_isDrawing = false;
        m_isHoldingForShape = false;
        m_quickShapeType = QuickShapeType::None;
        m_quickShapeTimer->stop();
        m_hasPrediction = false;
        m_smudgeColorValid = false;
        m_strokeCancelledByGesture = true;
        m_strokeBeforeBuffer.reset();
        update();
      }
    }

    // ── Single-finger: eyedropper while dragging ──
    if (points == 1 && m_touchIsEyedropper) {
      m_touchEyedropperColor = QColor(
          sampleColor(m_lastTouchPos.x(), m_lastTouchPos.y(), 0));
      setBrushColor(m_touchEyedropperColor);
      update();
      event->accept();
      return;
    }

    // ── Three-finger gesture: brush size ──
    if (points == 3 && m_isThreeFingerGesture) {
      float avgY = 0;
      for (int i = 0; i < points; i++)
        avgY += event->points()[i].position().y();
      avgY /= points;

      float deltaY = m_threeFingerStartPos.y() - avgY;
      float newSize = std::clamp(m_threeFingerStartSize + deltaY * 0.3f, 1.0f, 1000.0f);
      int intSize = static_cast<int>(newSize);
      if (intSize != m_brushSize) {
        setBrushSize(intSize);
        m_threeFingerMoved = true;
        emit notificationRequested("Brush Size: " + QString::number(intSize), "info");
      }
      event->accept();
      return;
    }

    // ── Transition from 1→2 fingers during drawing ──
    if (points == 2 && prevPointCount < 2 && !m_isTwoFingerGesture &&
        PreferencesManager::instance()->touchGesturesEnabled()) {
      QPointF p1 = event->points()[0].position();
      QPointF p2 = event->points()[1].position();
      QPointF center = (p1 + p2) / 2.0;
      m_touchStartPos = center;
      m_lastTouchCenter = center;
      m_lastPinchScale = QLineF(p1, p2).length();
      m_lastPinchAngle = std::atan2(p2.y() - p1.y(), p2.x() - p1.x());
      m_isTwoFingerGesture = true;

      if (m_touchTimer)
        m_touchTimer->stop();

      // Cancel active stroke on 1→2 transition
      if (m_isDrawing) {
        Layer *layer = m_layerManager->getActiveLayer();
        if (layer && layer->buffer && m_strokeBeforeBuffer) {
          layer->buffer->copyFrom(*m_strokeBeforeBuffer);
          layer->dirty = true;
          layer->dirtyRect = QRect(0, 0, m_canvasWidth, m_canvasHeight);
          if (layer->buffer)
            layer->buffer->clearDirtyFlags();
          m_cachedCanvasImage = QImage();

          if (m_pingFBO && layer->buffer) {
            QImage fboImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                          QImage::Format_RGBA8888_Premultiplied);
            m_pingFBO->bind();
            QOpenGLPaintDevice device(m_canvasWidth, m_canvasHeight);
            QPainter fboPainter(&device);
            fboPainter.setCompositionMode(QPainter::CompositionMode_Source);
            fboPainter.drawImage(0, 0, fboImg);
            fboPainter.end();
            m_pingFBO->release();
            QOpenGLFramebufferObject::blitFramebuffer(m_pongFBO, m_pingFBO);
          }
        }
        m_isDrawing = false;
        m_isHoldingForShape = false;
        m_quickShapeType = QuickShapeType::None;
        m_quickShapeTimer->stop();
        m_hasPrediction = false;
        m_smudgeColorValid = false;
        m_strokeCancelledByGesture = true;
        m_strokeBeforeBuffer.reset();
        update();
      }
    }

    // ── Transition from 3→2 fingers: reset references to avoid jump ──
    if (points == 2 && prevPointCount == 3 && m_isTwoFingerGesture &&
        PreferencesManager::instance()->touchGesturesEnabled()) {
      QPointF p1 = event->points()[0].position();
      QPointF p2 = event->points()[1].position();
      QPointF center = (p1 + p2) / 2.0;
      m_lastTouchCenter = center;
      m_lastPinchScale = QLineF(p1, p2).length();
      m_lastPinchAngle = std::atan2(p2.y() - p1.y(), p2.x() - p1.x());
    }

    // ── Two-finger gesture: Pan + Zoom + Rotation (Unified rotation-aware focal-point) ──
    if (points == 2 && m_isTwoFingerGesture &&
        PreferencesManager::instance()->touchGesturesEnabled()) {
      QPointF p1 = event->points()[0].position();
      QPointF p2 = event->points()[1].position();
      QPointF center = (p1 + p2) / 2.0;

      // Calculate the canvas focal point corresponding to the previous frame's screen center
      QPointF canvasFocalPt = screenToCanvas(m_lastTouchCenter);
      QPointF flippedCanvasFocal = canvasFocalPt;
      if (m_isFlippedH) {
        flippedCanvasFocal.setX(m_canvasWidth - flippedCanvasFocal.x());
      }
      if (m_isFlippedV) {
        flippedCanvasFocal.setY(m_canvasHeight - flippedCanvasFocal.y());
      }

      // ── Zoom calculation ──
      float currentDist = QLineF(p1, p2).length();
      float newZoom = m_zoomLevel;
      if (m_lastPinchScale > 10.0f && currentDist > 10.0f) {
        float scaleFactor = currentDist / m_lastPinchScale;
        newZoom = std::clamp((float)(m_zoomLevel * scaleFactor), 0.05f, 64.0f);
      }

      // ── Rotation calculation ──
      float currentAngle = std::atan2(p2.y() - p1.y(), p2.x() - p1.x());
      float angleDelta = currentAngle - m_lastPinchAngle;
      if (angleDelta > M_PI) angleDelta -= 2.0f * M_PI;
      if (angleDelta < -M_PI) angleDelta += 2.0f * M_PI;
      float angleDeltaDeg = qRadiansToDegrees(angleDelta);
      float newRotation = m_canvasRotation + angleDeltaDeg;

      // ── Calculate the new ViewOffset to anchor focal point under the new screen 'center' ──
      QPointF viewCenter(width() / 2.0, height() / 2.0);
      float rad = qDegreesToRadians(-newRotation);
      float cosA = std::cos(rad);
      float sinA = std::sin(rad);
      QPointF p = center - viewCenter;
      QPointF unrotated(p.x() * cosA - p.y() * sinA,
                        p.x() * sinA + p.y() * cosA);
      QPointF S_unrot = unrotated + viewCenter;

      QPointF newViewOffset = S_unrot / newZoom - flippedCanvasFocal;

      // Apply transformations
      setZoomLevel(newZoom);
      setCanvasRotation(newRotation);
      setViewOffset(newViewOffset);

      // Update tracking variables for the next event
      m_lastTouchCenter = center;
      m_lastPinchScale = currentDist;
      m_lastPinchAngle = currentAngle;

      event->accept();
      return;
    }

  } else if (event->type() == QEvent::TouchEnd ||
             event->type() == QEvent::TouchCancel) {
    if (m_touchTimer)
      m_touchTimer->stop();
    m_touchIsEyedropper = false;

    // ── Multi-touch Undo/Redo ──
    if (PreferencesManager::instance()->multitouchUndoRedoEnabled()) {
      qint64 duration = QDateTime::currentMSecsSinceEpoch() - m_touchStartTime;
      if (duration < 350 && !m_touchMovedThisSession && !m_isDrawing && !m_strokeCancelledByGesture) {
        if (m_maxTouchPointsThisSession == 2) {
          undo();
          emit notificationRequested("Deshacer", "info");
        } else if (m_maxTouchPointsThisSession == 3) {
          redo();
          emit notificationRequested("Rehacer", "info");
        }
      }
    }

    // Reset gesture state
    m_isTwoFingerGesture = false;
    m_isThreeFingerGesture = false;
    m_threeFingerMoved = false;
    m_strokeCancelledByGesture = false;
    m_touchPointCount = 0;
    m_maxTouchPointsThisSession = 0;
    m_touchStartTime = 0;
    m_touchMovedThisSession = false;
  }
}

void CanvasItem::nativeGestureEvent(QNativeGestureEvent *event) {
  if (event->gestureType() == Qt::ZoomNativeGesture) {
    float scaleDelta = event->value();
    float newZoom = std::clamp(m_zoomLevel * (1.0f + scaleDelta), 0.05f, 64.0f);

    QPointF screenFocalPt = event->position();
    QPointF canvasFocalPt = screenToCanvas(screenFocalPt);
    QPointF flippedCanvasFocal = canvasFocalPt;
    if (m_isFlippedH) {
      flippedCanvasFocal.setX(m_canvasWidth - flippedCanvasFocal.x());
    }
    if (m_isFlippedV) {
      flippedCanvasFocal.setY(m_canvasHeight - flippedCanvasFocal.y());
    }

    QPointF viewCenter(width() / 2.0, height() / 2.0);
    float rad = qDegreesToRadians(-m_canvasRotation);
    float cosA = std::cos(rad);
    float sinA = std::sin(rad);
    QPointF p = screenFocalPt - viewCenter;
    QPointF unrotated(p.x() * cosA - p.y() * sinA,
                      p.x() * sinA + p.y() * cosA);
    QPointF S_unrot = unrotated + viewCenter;

    QPointF newViewOffset = S_unrot / newZoom - flippedCanvasFocal;
    setZoomLevel(newZoom);
    setViewOffset(newViewOffset);
  } else if (event->gestureType() == Qt::RotateNativeGesture) {
    // Native trackpad rotation (macOS / Windows Precision Touchpad)
    float rotDelta = event->value();
    float newRotation = m_canvasRotation + rotDelta;

    QPointF screenFocalPt = event->position();
    QPointF canvasFocalPt = screenToCanvas(screenFocalPt);
    QPointF flippedCanvasFocal = canvasFocalPt;
    if (m_isFlippedH) {
      flippedCanvasFocal.setX(m_canvasWidth - flippedCanvasFocal.x());
    }
    if (m_isFlippedV) {
      flippedCanvasFocal.setY(m_canvasHeight - flippedCanvasFocal.y());
    }

    QPointF viewCenter(width() / 2.0, height() / 2.0);
    float rad = qDegreesToRadians(-newRotation);
    float cosA = std::cos(rad);
    float sinA = std::sin(rad);
    QPointF p = screenFocalPt - viewCenter;
    QPointF unrotated(p.x() * cosA - p.y() * sinA,
                      p.x() * sinA + p.y() * cosA);
    QPointF S_unrot = unrotated + viewCenter;

    QPointF newViewOffset = S_unrot / m_zoomLevel - flippedCanvasFocal;
    setCanvasRotation(newRotation);
    setViewOffset(newViewOffset);
  }
}


// ... Setters and other methods ...

void CanvasItem::setSymmetryEnabled(bool v) {
  if (m_symmetryEnabled != v) {
    m_symmetryEnabled = v;
    emit symmetryEnabledChanged();
    updateSymmetryEngines();
    update();
  }
}

void CanvasItem::setSymmetryMode(int v) {
  if (m_symmetryMode != v) {
    m_symmetryMode = v;
    emit symmetryModeChanged();
    updateSymmetryEngines();
    update();
  }
}

void CanvasItem::setSymmetrySegments(int v) {
  if (m_symmetrySegments != v) {
    m_symmetrySegments = v;
    emit symmetrySegmentsChanged();
    updateSymmetryEngines();
    update();
  }
}

void CanvasItem::updateSymmetryEngines() {
  for (auto *engine : m_symmetryEngines) {
    delete engine;
  }
  m_symmetryEngines.clear();

  if (!m_symmetryEnabled)
    return;

  int totalMirrors = 0;
  if (m_symmetryMode == 0)
    totalMirrors = 1; // Vertical (1 mirror)
  else if (m_symmetryMode == 1)
    totalMirrors = 1; // Horizontal (1 mirror)
  else if (m_symmetryMode == 2)
    totalMirrors = 3; // Quad (3 mirrors + 1 primary = 4)
  else if (m_symmetryMode == 3)
    totalMirrors = std::max(1, m_symmetrySegments - 1); // Radial

  for (int i = 0; i < totalMirrors; ++i) {
    auto *eng = new artflow::BrushEngine();
    eng->setBrush(m_brushEngine->getBrush());
    m_symmetryEngines.push_back(eng);
  }
}

QPointF CanvasItem::mirrorPoint(const QPointF &pt, int mirrorIndex,
                                int totalMirrors, const QPointF &center) {
  if (m_symmetryMode == 0) { // Vertical Mirror (Left/Right)
    return QPointF(center.x() - (pt.x() - center.x()), pt.y());
  } else if (m_symmetryMode == 1) { // Horizontal Mirror (Top/Bottom)
    return QPointF(pt.x(), center.y() - (pt.y() - center.y()));
  } else if (m_symmetryMode == 2) { // Quad Mirror
    if (mirrorIndex == 0)
      return QPointF(center.x() - (pt.x() - center.x()), pt.y()); // V
    if (mirrorIndex == 1)
      return QPointF(pt.x(), center.y() - (pt.y() - center.y())); // H
    if (mirrorIndex == 2)
      return QPointF(center.x() - (pt.x() - center.x()),
                     center.y() - (pt.y() - center.y())); // HV
  } else if (m_symmetryMode == 3) {                       // Radial
    // Radial calculation: rotate around center
    int totalSegments = totalMirrors + 1;
    float angle = 2.0f * M_PI * (mirrorIndex + 1) / totalSegments;
    float dx = pt.x() - center.x();
    float dy = pt.y() - center.y();
    float nx = dx * std::cos(angle) - dy * std::sin(angle);
    float ny = dx * std::sin(angle) + dy * std::cos(angle);
    return QPointF(center.x() + nx, center.y() + ny);
  }
  return pt;
}

void CanvasItem::setPanelGutterSize(float size) {
  if (m_panelGutterSize == size) return;
  m_panelGutterSize = size;
  emit panelGutterSizeChanged();
  dirtyPanelOverlay();
}

void CanvasItem::setPanelBorderStyle(const QString &style) {
  if (m_panelBorderStyle == style) return;
  m_panelBorderStyle = style;
  emit panelBorderStyleChanged();
  update();
}

void CanvasItem::setPanelBorderWidth(float width) {
  if (m_panelBorderWidth == width) return;
  m_panelBorderWidth = width;
  emit panelBorderWidthChanged();
  update();
}

void CanvasItem::drawStylizedBorder(QPainter &painter, const QPointF &p1, const QPointF &p2, const QString &style, float width) {
  if (style == "invisible") {
    return;
  }

  painter.save();
  painter.setRenderHint(QPainter::Antialiasing);

  QPen pen(Qt::black, width, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);

  if (style == "dotted") {
    pen.setStyle(Qt::DashLine);
    painter.setPen(pen);
    painter.drawLine(p1, p2);
  } else if (style == "double") {
    QLineF line(p1, p2);
    float len = line.length();
    if (len > 0) {
      float nx = -line.dy() / len;
      float ny = line.dx() / len;
      QPointF shift(nx * (width * 0.6f + 1.5f), ny * (width * 0.6f + 1.5f));

      pen.setWidthF(width * 0.7f);
      painter.setPen(pen);
      painter.drawLine(p1 + shift, p2 + shift);
      painter.drawLine(p1 - shift, p2 - shift);
    }
  } else if (style == "blurry") {
    QLineF line(p1, p2);
    for (int w = static_cast<int>(width * 2.5f); w >= 1; w -= 2) {
      float opacity = (1.0f - static_cast<float>(w) / (width * 2.5f)) * 0.4f;
      QPen softPen(QColor(0, 0, 0, static_cast<int>(opacity * 255)), w, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
      painter.setPen(softPen);
      painter.drawLine(p1, p2);
    }
    pen.setWidthF(width * 0.8f);
    painter.setPen(pen);
    painter.drawLine(p1, p2);
  } else if (style == "sketchy") {
    QLineF line(p1, p2);
    float length = line.length();
    if (length > 0) {
      int segments = std::max(5, static_cast<int>(length / 12.0f));

      auto getNoise = [](int seed) -> double {
        return static_cast<double>((seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff - 0.5;
      };

      QPainterPath path1;
      path1.moveTo(p1);
      for (int i = 1; i <= segments; ++i) {
        double t = static_cast<double>(i) / segments;
        QPointF pt = line.pointAt(t);
        if (i < segments) {
          double noise = getNoise(i * 13) * (width * 0.4f);
          QPointF normal(-line.dy() / length, line.dx() / length);
          pt += normal * noise;
        }
        path1.lineTo(pt);
      }

      QPainterPath path2;
      path2.moveTo(p1);
      for (int i = 1; i <= segments; ++i) {
        double t = static_cast<double>(i) / segments;
        QPointF pt = line.pointAt(t);
        if (i < segments) {
          double noise = getNoise(i * 37) * (width * 0.5f);
          QPointF normal(-line.dy() / length, line.dx() / length);
          pt += normal * noise;
        }
        path2.lineTo(pt);
      }

      QPen pen1(Qt::black, width * 0.8f, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
      painter.setPen(pen1);
      painter.drawPath(path1);

      QPen pen2(QColor(40, 40, 40, 180), width * 0.4f, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
      painter.setPen(pen2);
      painter.drawPath(path2);
    }
  } else {
    pen.setWidthF(width);
    painter.setPen(pen);
    painter.drawLine(p1, p2);
  }

  painter.restore();
}

void CanvasItem::setBrushSize(int size) {
  m_brushSize = size;
  BrushSettings s = m_brushEngine->getBrush();
  s.size = static_cast<float>(size);
  m_brushEngine->setBrush(s);
  invalidateCursorCache();
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
  update();
  emit brushHardnessChanged();
  updateBrushTipImage();
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

void CanvasItem::setBrushStabilizerMode(int mode) {
  if (m_brushStabilizerMode == mode)
    return;
  m_brushStabilizerMode = mode;
  emit brushStabilizerModeChanged();
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

void CanvasItem::_commitLassoPath() {
  QPainterPath closed = m_activeLassoPath;
  m_activeLassoPath = QPainterPath();
  m_isMagneticLassoActive = false;
  m_isLassoDragging = false;
  m_magneticPreviewPath = QPainterPath();

  if (closed.elementCount() < 3)
    return;

  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  if (m_selectionAddMode == 0) {
    m_selectionPath = closed;
  } else if (m_selectionAddMode == 1) {
    m_selectionPath = m_selectionPath.united(closed);
  } else if (m_selectionAddMode == 2) {
    m_selectionPath = m_selectionPath.subtracted(closed);
  }

  m_hasSelection = !m_selectionPath.isEmpty();
  emit hasSelectionChanged();

  if (m_hasSelection && !m_marchingAntsTimer->isActive())
    m_marchingAntsTimer->start();

  update();

  auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
    m_selectionPath = path;
    m_hasSelection = hasSel;
    emit hasSelectionChanged();
    if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
    else if (!m_hasSelection && m_marchingAntsTimer)
      m_marchingAntsTimer->stop();
    update();
  };
  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
        updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
  }
}

void CanvasItem::_commitNewShapePath(const QPainterPath &newPath) {
  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  if (m_selectionAddMode == 0) {
    m_selectionPath = newPath;
  } else if (m_selectionAddMode == 1) {
    m_selectionPath = m_selectionPath.united(newPath);
  } else if (m_selectionAddMode == 2) {
    m_selectionPath = m_selectionPath.subtracted(newPath);
  }

  m_hasSelection = !m_selectionPath.isEmpty();
  emit hasSelectionChanged();

  if (m_hasSelection && !m_marchingAntsTimer->isActive())
    m_marchingAntsTimer->start();

  update();

  auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
    m_selectionPath = path;
    m_hasSelection = hasSel;
    emit hasSelectionChanged();
    if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
    else if (!m_hasSelection && m_marchingAntsTimer)
      m_marchingAntsTimer->stop();
    update();
  };
  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
        updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
  }
}

void CanvasItem::invertSelection() {
  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  QPainterPath full;
  full.addRect(0, 0, m_canvasWidth, m_canvasHeight);
  m_selectionPath = full.subtracted(m_selectionPath);
  m_hasSelection = !m_selectionPath.isEmpty();

  emit hasSelectionChanged();
  if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
    m_marchingAntsTimer->start();
  else if (!m_hasSelection && m_marchingAntsTimer)
    m_marchingAntsTimer->stop();
  update();

  auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
    m_selectionPath = path;
    m_hasSelection = hasSel;
    emit hasSelectionChanged();
    if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
    else if (!m_hasSelection && m_marchingAntsTimer)
      m_marchingAntsTimer->stop();
    update();
  };
  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
        updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
  }
}

void CanvasItem::setBrushSmudge(float value) {
  m_brushSmudge = value;
  BrushSettings s = m_brushEngine->getBrush();
  s.smudge = value;
  m_brushEngine->setBrush(s);
  emit brushSmudgeChanged();
}

void CanvasItem::setSizeByPressure(bool v) {
  if (m_sizeByPressure != v) {
    m_sizeByPressure = v;
    emit sizeByPressureChanged();
    update();
  }
}

void CanvasItem::setOpacityByPressure(bool v) {
  if (m_opacityByPressure != v) {
    m_opacityByPressure = v;
    emit opacityByPressureChanged();
    update();
  }
}

void CanvasItem::setFlowByPressure(bool v) {
  if (m_flowByPressure != v) {
    m_flowByPressure = v;
    emit flowByPressureChanged();
    update();
  }
}

void CanvasItem::setImpastoShininess(float value) {
  if (qFuzzyCompare(m_impastoShininess, value))
    return;
  m_impastoShininess = value;
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

void CanvasItem::setSelectionAddMode(int mode) {
  if (m_selectionAddMode == mode)
    return;
  m_selectionAddMode = mode;
  emit selectionAddModeChanged();
}

void CanvasItem::setSelectionThreshold(float threshold) {
  if (qFuzzyCompare(m_selectionThreshold, threshold))
    return;
  m_selectionThreshold = threshold;
  emit selectionThresholdChanged();
}

void CanvasItem::setIsSelectionModeActive(bool active) {
  if (m_isSelectionModeActive == active)
    return;
  m_isSelectionModeActive = active;
  emit isSelectionModeActiveChanged();

  if (active) {
    emit notificationRequested("Selection Mode Active", "info");
  } else {
    emit notificationRequested("Selection Mode Deactivated", "info");
  }
}

void CanvasItem::setLassoMode(int mode) {
  if (m_lassoMode == mode)
    return;
  // Cancel current in-progress selection when switching modes
  m_activeLassoPath = QPainterPath();
  m_isLassoDragging = false;
  m_isMagneticLassoActive = false;
  m_lassoMode = mode;
  emit lassoModeChanged();
  update();
}

void CanvasItem::closeLasso() {
  if (m_activeLassoPath.elementCount() < 3)
    return;
  m_activeLassoPath.closeSubpath();
  _commitLassoPath();
}



void CanvasItem::apply_color_drop(int x, int y, const QColor &color) {
  // 1. Transform Visual/Screen coordinates to Logical Canvas coordinates
  // Qt's coordinate system mapping (including flipped Scale transform in
  // QML) already handles the flip for us in the event position and
  // mapToItem.
  float lx =
      (static_cast<float>(x) - m_viewOffset.x() * m_zoomLevel) / m_zoomLevel;
  float ly =
      (static_cast<float>(y) - m_viewOffset.y() * m_zoomLevel) / m_zoomLevel;

  int ix = static_cast<int>(std::round(lx));
  int iy = static_cast<int>(std::round(ly));

  // 2. Bound check
  if (ix < 0 || ix >= m_canvasWidth || iy < 0 || iy >= m_canvasHeight)
    return;

  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer || layer->locked)
    return;

  // 3. Handle Selection Mask / Panel Mask
  std::unique_ptr<artflow::ImageBuffer> selectionMask;
  int basePanelIdx = -1;
  artflow::Layer *basePanel = getActiveBasePanel(&basePanelIdx);
  bool hasSelection = m_hasSelection && !m_selectionPath.isEmpty();
  bool hasPanelPath = basePanel && !basePanel->panelPath.isEmpty();

  if (hasSelection || hasPanelPath) {
    selectionMask =
        std::make_unique<artflow::ImageBuffer>(m_canvasWidth, m_canvasHeight);
    QImage maskImg(selectionMask->data(), m_canvasWidth, m_canvasHeight,
                   QImage::Format_RGBA8888_Premultiplied);
    maskImg.fill(Qt::transparent);

    QPainter p(&maskImg);
    p.setRenderHint(QPainter::Antialiasing);
    if (hasSelection && hasPanelPath) {
      QPainterPath intersected = m_selectionPath.intersected(basePanel->panelPath);
      p.fillPath(intersected, Qt::white);
    } else if (hasSelection) {
      p.fillPath(m_selectionPath, Qt::white);
    } else if (hasPanelPath) {
      p.fillPath(basePanel->panelPath, Qt::white);
    }
    p.end();
  }

  // Snapshot for undo
  auto before = std::make_unique<artflow::ImageBuffer>(*layer->buffer);

  // Flood fill
  layer->buffer->floodFill(ix, iy, color.red(), color.green(), color.blue(),
                           color.alpha(), m_selectionThreshold,
                           selectionMask.get(), layer->alphaLock);
  layer->dirty = true;

  // Snapshot after for undo
  auto after = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
  m_undoManager->pushCommand(std::make_unique<artflow::StrokeUndoCommand>(
      m_layerManager, m_activeLayerIndex, std::move(before), std::move(after)));

  emit notificationRequested(
      m_hasSelection ? "Filled selection" : "Area filled", "info");
  update();
  updateLayersList();
}

void CanvasItem::featherSelection(float radius) {
  // Raster implementation of feathering using a blurred mask
  if (m_selectionPath.isEmpty())
    return;

  // This is complex for a vector path, usually done by converting to bitmap
  // mask, blurring, and using that alpha. For now, we'll keep the vector
  // path and just store the feather value if we had a multi-mode selection
  // buffer. Simplifying: Just notification of feathering applied.
  emit notificationRequested("Feathering applied: " + QString::number(radius),
                             "info");
}

void CanvasItem::duplicateSelection() {
  if (!m_hasSelection || m_selectionPath.isEmpty())
    return;

  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer)
    return;

  // Create mask from path
  QImage mask(m_canvasWidth, m_canvasHeight, QImage::Format_Alpha8);
  mask.fill(0);
  QPainter p(&mask);
  p.fillPath(m_selectionPath, Qt::white);
  p.end();

  // Extract content
  QImage srcImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                QImage::Format_RGBA8888_Premultiplied);
  QImage result(m_canvasWidth, m_canvasHeight,
                QImage::Format_RGBA8888_Premultiplied);
  result.fill(0);

  QPainter p2(&result);
  p2.setClipPath(m_selectionPath);
  p2.drawImage(0, 0, srcImg);
  p2.end();

  // Create new layer
  addLayer();
  Layer *newLayer = m_layerManager->getActiveLayer();
  if (newLayer && newLayer->buffer) {
    newLayer->buffer->loadRawData(result.bits());
    newLayer->dirty = true;
  }
  update();
}

void CanvasItem::maskSelection() {
  // Implement layer mask logic (requires LayerManager support for masks)
  emit notificationRequested("Mask created (Simulation)", "info");
}

void CanvasItem::colorSelection(const QColor &color) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer || m_selectionPath.isEmpty())
    return;

  QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888_Premultiplied);
  QPainter p(&img);
  p.setClipPath(m_selectionPath);
  p.setCompositionMode(QPainter::CompositionMode_Source);
  p.fillRect(img.rect(), color);
  p.end();

  layer->dirty = true;
  update();
}

void CanvasItem::clearSelectionContent() {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer || m_selectionPath.isEmpty())
    return;

  QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
             QImage::Format_RGBA8888_Premultiplied);
  QPainter p(&img);
  p.setClipPath(m_selectionPath);
  p.setCompositionMode(QPainter::CompositionMode_Clear);
  p.fillRect(img.rect(), Qt::transparent);
  p.end();

  layer->dirty = true;
  update();
}

void CanvasItem::deselect() {
  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  m_selectionPath = QPainterPath();
  m_activeLassoPath = QPainterPath();
  m_isLassoDragging = false;
  m_isMagneticLassoActive = false;
  m_hasSelection = false;

  emit hasSelectionChanged();
  if (m_marchingAntsTimer) m_marchingAntsTimer->stop();
  update();

  if (beforeHasSel) {
    auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
      m_selectionPath = path;
      m_hasSelection = hasSel;
      emit hasSelectionChanged();
      if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
        m_marchingAntsTimer->start();
      else if (!m_hasSelection && m_marchingAntsTimer)
        m_marchingAntsTimer->stop();
      update();
    };
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
          updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
    }
  }
}

void CanvasItem::selectAll() {
  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  m_selectionPath = QPainterPath();
  m_selectionPath.addRect(0, 0, m_canvasWidth, m_canvasHeight);
  m_hasSelection = true;

  emit hasSelectionChanged();
  update();

  if (beforePath != m_selectionPath || beforeHasSel != m_hasSelection) {
    auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
      m_selectionPath = path;
      m_hasSelection = hasSel;
      emit hasSelectionChanged();
      if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
        m_marchingAntsTimer->start();
      else if (!m_hasSelection && m_marchingAntsTimer)
        m_marchingAntsTimer->stop();
      update();
    };
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
          updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
    }
  }
}

void CanvasItem::setBrushRoundness(float value) {
  if (!qFuzzyCompare(m_brushRoundness, value)) {
    m_brushRoundness = value;
    BrushSettings s = m_brushEngine->getBrush();
    s.roundness = value;
    m_brushEngine->setBrush(s);
    emit brushRoundnessChanged();
    update();
    updateBrushTipImage();
  }
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
  invalidateCursorCache();
  update();
  emit brushAngleChanged();
  updateBrushTipImage();
}

void CanvasItem::setCursorRotation(float value) {
  m_cursorRotation = value;
  emit cursorRotationChanged();
}

void CanvasItem::setZoomLevel(float zoom) {
  m_zoomLevel = zoom;
  invalidateCursorCache();
  emit zoomLevelChanged();
  update();
}
void CanvasItem::setViewOffset(const QPointF &offset) {
  m_viewOffset = offset;
  emit viewOffsetChanged();
  update();
}

// ══════════════════════════════════════════════════════════════
// Canvas Rotation — Krita-style free rotation
// ══════════════════════════════════════════════════════════════

void CanvasItem::setCanvasRotation(float degrees) {
  // Normalize to -180..180
  while (degrees > 180.0f) degrees -= 360.0f;
  while (degrees < -180.0f) degrees += 360.0f;
  if (qFuzzyCompare(m_canvasRotation, degrees))
    return;
  m_canvasRotation = degrees;
  invalidateCursorCache();
  emit canvasRotationChanged();
  update();
}

void CanvasItem::resetCanvasRotation() {
  setCanvasRotation(0.0f);
}

void CanvasItem::rotateCanvasBy(float deltaDegrees) {
  setCanvasRotation(m_canvasRotation + deltaDegrees);
}

QPointF CanvasItem::screenToCanvas(const QPointF &screenPos) const {
  // Full inverse transform: Screen → Canvas
  // Forward transform chain (canvas → screen):
  //   1. Translate by viewOffset
  //   2. Scale by zoomLevel
  //   3. Rotate around view center by canvasRotation
  //
  // Inverse (screen → canvas):
  //   1. Un-rotate around view center
  //   2. Un-scale
  //   3. Un-translate

  QPointF viewCenter(width() / 2.0, height() / 2.0);

  // Step 1: Un-rotate around view center
  float rad = qDegreesToRadians(-m_canvasRotation);
  float cosA = std::cos(rad);
  float sinA = std::sin(rad);
  QPointF p = screenPos - viewCenter;
  QPointF unrotated(p.x() * cosA - p.y() * sinA,
                    p.x() * sinA + p.y() * cosA);
  QPointF afterRotation = unrotated + viewCenter;

  // Step 2: Un-scale and un-translate (standard zoom/pan inverse)
  QPointF canvasPos = (afterRotation - m_viewOffset * m_zoomLevel) / m_zoomLevel;

  // Step 3: Apply flip corrections
  if (m_isFlippedH) {
    canvasPos.setX(m_canvasWidth - canvasPos.x());
  }
  if (m_isFlippedV) {
    canvasPos.setY(m_canvasHeight - canvasPos.y());
  }

  return canvasPos;
}

QPointF CanvasItem::canvasToScreen(const QPointF &canvasPos) const {
  // Forward transform: Canvas → Screen
  QPointF pos = canvasPos;

  // Apply flip
  if (m_isFlippedH) {
    pos.setX(m_canvasWidth - pos.x());
  }
  if (m_isFlippedV) {
    pos.setY(m_canvasHeight - pos.y());
  }

  // Scale and translate
  QPointF screenPos = pos * m_zoomLevel + m_viewOffset * m_zoomLevel;

  // Rotate around view center
  QPointF viewCenter(width() / 2.0, height() / 2.0);
  float rad = qDegreesToRadians(m_canvasRotation);
  float cosA = std::cos(rad);
  float sinA = std::sin(rad);
  QPointF p = screenPos - viewCenter;
  QPointF rotated(p.x() * cosA - p.y() * sinA,
                  p.x() * sinA + p.y() * cosA);

  return rotated + viewCenter;
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
  update();
  emit isEraserChanged(m_isEraser);
}

void CanvasItem::setCurrentTool(const QString &tool) {
  if (m_currentToolStr == tool) {
    if (tool == "liquify" && !m_isLiquifying) {
      beginLiquify();
    }
    return;
  }

  // Commit transformation if switching away from transform/move tool
  if (m_isTransforming) {
    commitTransform();
  }

  if (tool == "liquify") {
    m_previousToolStr = m_currentToolStr;
  }

  m_currentToolStr = tool;
  setIsSelectionModeActive(false); // Reset selection mode active flag by default

  // Sync QML toolbar index
  if (tool == "selection" || tool == "select_rect" || tool == "select_ellipse" || tool == "select_wand")
    emit requestToolIdx(0);
  else if (tool == "shapes")
    emit requestToolIdx(1);
  else if (tool == "lasso" || tool == "magnetic_lasso")
    emit requestToolIdx(2);
  else if (tool == "move")
    emit requestToolIdx(3);
  else if (tool == "pen")
    emit requestToolIdx(4);
  else if (tool == "pencil")
    emit requestToolIdx(5);
  else if (tool == "brush")
    emit requestToolIdx(6);
  else if (tool == "airbrush")
    emit requestToolIdx(7);
  else if (tool == "eraser")
    emit requestToolIdx(8);
  else if (tool == "fill")
    emit requestToolIdx(9);
  else if (tool == "eyedropper" || tool == "picker")
    emit requestToolIdx(10);
  else if (tool == "hand")
    emit requestToolIdx(11);
  else if (tool == "panel_cut")
    emit requestToolIdx(12);

  if (tool == "brush" || tool == "pen" || tool == "pencil" ||
      tool == "watercolor" || tool == "airbrush") {
    m_tool = ToolType::Pen;
    setCursor(QCursor(Qt::BlankCursor));
    setIsSelectionModeActive(false);
  } else if (tool == "eraser") {
    m_tool = ToolType::Eraser;
    setCursor(QCursor(Qt::BlankCursor));
    setIsSelectionModeActive(false);
  } else if (tool == "lasso" || tool == "magnetic_lasso" ||
             tool == "select_rect" || tool == "select_ellipse" ||
             tool == "select_wand") {
    setIsSelectionModeActive(true);
    if (tool == "lasso") {
      m_tool = ToolType::Lasso;
    } else if (tool == "magnetic_lasso") {
      m_tool = ToolType::MagneticLasso;
      m_gradientMapDirty = true;
    } else if (tool == "select_rect") {
      m_tool = ToolType::RectSelect;
    } else if (tool == "select_ellipse") {
      m_tool = ToolType::EllipseSelect;
    } else if (tool == "select_wand") {
      m_tool = ToolType::MagicWand;
    }
    setCursor(QCursor(Qt::BlankCursor));
  } else if (tool == "transform" || tool == "move") {
    m_tool = ToolType::Transform;
    setCursor(getModernCursor());
    beginTransform();
  } else if (tool == "eyedropper") {
    m_tool = ToolType::Eyedropper;
    setCursor(QCursor(Qt::BlankCursor));
  } else if (tool == "hand") {
    m_tool = ToolType::Hand;
    setCursor(m_customOpenHandCursor);
  } else if (tool == "fill" || tool == "BUCKET") {
    m_tool = ToolType::Fill;
    setCursor(QCursor(Qt::BlankCursor));
  } else if (tool == "GRAD") {
    m_tool = ToolType::Gradient;
    setCursor(QCursor(Qt::CrossCursor));
  } else if (tool == "panel_cut") {
    m_tool = ToolType::PanelCut;
    setCursor(QCursor(Qt::BlankCursor));
  } else if (tool == "liquify") {
    m_tool = ToolType::Liquify;
    setCursor(QCursor(Qt::BlankCursor));
    beginLiquify();
  }

  invalidateCursorCache();
  emit currentToolChanged();
  // emit notificationRequested("Tool: " + tool, "info");
  qInfo() << "SetCurrentTool:" << tool
          << "ModeActive:" << m_isSelectionModeActive;

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

void CanvasItem::beginTransform() {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer || layer->locked)
    return;

  if (m_isTransforming)
    return;

  // 0. Save state for UNDO
  m_transformBeforeBuffer =
      std::make_unique<artflow::ImageBuffer>(*layer->buffer);

  if (layer->type == Layer::Type::Vector && layer->vectorData) {
    m_vectorBeforeData = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
  } else {
    m_vectorBeforeData.reset();
  }

  // 1. Extract content safely in cropped box
  if (m_hasSelection && !m_selectionPath.isEmpty()) {
    QRectF boundOriginal = m_selectionPath.boundingRect();
    m_transformBox =
        boundOriginal.intersected(QRectF(0, 0, m_canvasWidth, m_canvasHeight));
    QRect bbox = m_transformBox.toRect();
    m_transformBox = bbox;

    if (bbox.isEmpty() || bbox.width() <= 0 || bbox.height() <= 0) {
      resetTransformState();
      return;
    }

    m_selectionBuffer = QImage(bbox.width(), bbox.height(),
                               QImage::Format_ARGB32_Premultiplied);
    m_selectionBuffer.fill(Qt::transparent);

    QImage srcImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                  QImage::Format_RGBA8888_Premultiplied);
    QPainter p(&m_selectionBuffer);
    p.translate(-bbox.x(), -bbox.y());
    p.setClipPath(m_selectionPath);
    p.drawImage(0, 0, srcImg);
    p.end();

    // Clear area in original layer
    if (layer->type != Layer::Type::Vector) {
      QImage layerImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                      QImage::Format_RGBA8888_Premultiplied);
      QPainter p2(&layerImg);
      p2.setCompositionMode(QPainter::CompositionMode_Clear);
      p2.setClipPath(m_selectionPath);
      p2.fillRect(bbox, Qt::transparent);
      p2.end();

      // Clear real tiles in original layer buffer
      for (int y = bbox.top(); y <= bbox.bottom(); ++y) {
        for (int x = bbox.left(); x <= bbox.right(); ++x) {
          if (m_selectionPath.contains(QPointF(x, y))) {
            layer->buffer->setPixel(x, y, 0, 0, 0, 0);
          }
        }
      }
    }
  } else {
    // Use the content bounds instead of full canvas
    int bx, by, bw, bh;
    if (!layer->buffer->getContentBounds(bx, by, bw, bh)) {
      m_transformBox = QRectF(0, 0, m_canvasWidth, m_canvasHeight);
    } else {
      QRect bounds(bx, by, bw, bh);
      m_transformBox =
          bounds.intersected(QRect(0, 0, m_canvasWidth, m_canvasHeight));
    }

    QRect bbox = m_transformBox.toRect();
    if (bbox.isEmpty() || bbox.width() <= 0 || bbox.height() <= 0) {
      resetTransformState();
      emit notificationRequested("La capa activa está vacía", "warning");
      return;
    }

    QImage fullImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                   QImage::Format_RGBA8888_Premultiplied);
    m_selectionBuffer = fullImg.copy(bbox);

    // Clear area in original layer
    if (layer->type != Layer::Type::Vector) {
      QPainter p2(&fullImg);
      p2.setCompositionMode(QPainter::CompositionMode_Clear);
      p2.fillRect(bbox, Qt::transparent);
      p2.end();

      // Clear real tiles in original layer buffer
      for (int y = bbox.top(); y <= bbox.bottom(); ++y) {
        for (int x = bbox.left(); x <= bbox.right(); ++x) {
          layer->buffer->setPixel(x, y, 0, 0, 0, 0);
        }
      }
    }
  }

  m_initialMatrix = QTransform();
  m_transformMatrix = QTransform();
  m_transformMatrix.translate(m_transformBox.x(), m_transformBox.y());
  m_isTransforming = true;
  m_isMeshTransform = false;
  m_meshPoints.clear();
  layer->dirty = true;

  // PRECOMPUTE en hilo secundario — no bloquear la UI
  // Mostramos la transformación en cuanto tengamos el cache listo
  m_updateTransformTextures = false; // aún no está listo
  emit isTransformingChanged();
  update(); // primer frame: mostrará el canvas sin el static cache
            // (acceptable)

  // Capturar lo que necesita el hilo secundario antes de lanzarlo
  int cw = m_canvasWidth;
  int ch = m_canvasHeight;

  QFuture<QImage> future = QtConcurrent::run([this, cw, ch]() -> QImage {
    artflow::ImageBuffer tempBuffer(cw, ch);
    m_layerManager->compositeAll(tempBuffer, false);
    return QImage(tempBuffer.data(), cw, ch,
                  QImage::Format_RGBA8888_Premultiplied)
        .copy();
  });

  // Watcher para cuando termine — volver al hilo principal
  auto *watcher = new QFutureWatcher<QImage>(this);
  connect(watcher, &QFutureWatcher<QImage>::finished, this, [this, watcher]() {
    m_transformStaticCache = watcher->result();
    m_updateTransformTextures = true;
    watcher->deleteLater();
    update(); // ahora sí redibujar con el static cache en GPU
  });
  watcher->setFuture(future);

  emit notificationRequested("Transform Mode: " + (m_hasSelection
                                                       ? QString("Selection")
                                                       : QString("Layer")),
                             "info");
  emit transformBoxChanged();
  return;
}

void CanvasItem::executePanelCut(const QPointF &p1, const QPointF &p2) {
  Layer *activeLayer = m_layerManager->getActiveLayer();
  if (!activeLayer || !activeLayer->buffer)
    return;

  int activeIdx = m_layerManager->getActiveLayerIndex();
  int basePanelIdx = -1;

  // Escaneo dinámico de arriba a abajo de todos los paneles para encontrar el intersecado
  QLineF cutLine(p1, p2);
  for (int i = m_layerManager->getLayerCount() - 1; i >= 0; --i) {
    Layer *layer = m_layerManager->getLayer(i);
    if (!layer || layer->clipped || layer->type != Layer::Type::Drawing)
      continue;

    // Ignorar capas de fondo/papel
    QString name = QString::fromStdString(layer->name).toLower();
    if (name.contains("background") || name.contains("fondo") || name.contains("papel"))
      continue;

    QRectF bounds = getLayerBoundingRect(layer);
    if (bounds.isValid() && !bounds.isEmpty()) {
      if (lineIntersectsRect(cutLine, bounds)) {
        basePanelIdx = i;
        break;
      }
    }
  }

  // Fallback al panel base de la capa activa si no se detectó intersección
  if (basePanelIdx == -1) {
    basePanelIdx = activeIdx;
    while (basePanelIdx >= 0 && m_layerManager->getLayer(basePanelIdx)->clipped) {
      basePanelIdx--;
    }
    if (basePanelIdx < 0) {
      basePanelIdx = activeIdx;
    }
  }

  Layer *basePanelLayer = m_layerManager->getLayer(basePanelIdx);
  if (!basePanelLayer || !basePanelLayer->buffer)
    return;

  // Si el panel base está en blanco, lo inicializamos primero
  bool isBlank = true;
  const uint8_t *ptr = basePanelLayer->buffer->data();
  size_t bytes = m_canvasWidth * m_canvasHeight * 4;
  for (size_t i = 3; i < bytes; i += 4) {
    if (ptr[i] > 0) {
      isBlank = false;
      break;
    }
  }

  QImage baseImg(m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
  if (isBlank) {
    baseImg.fill(Qt::transparent);
    QPainter p(&baseImg);
    p.setRenderHint(QPainter::Antialiasing);
    p.fillRect(50, 50, m_canvasWidth - 100, m_canvasHeight - 100, Qt::white);
    
    QPointF topLeft(50, 50);
    QPointF topRight(m_canvasWidth - 50, 50);
    QPointF bottomRight(m_canvasWidth - 50, m_canvasHeight - 50);
    QPointF bottomLeft(50, m_canvasHeight - 50);

    drawStylizedBorder(p, topLeft, topRight, m_panelBorderStyle, m_panelBorderWidth);
    drawStylizedBorder(p, topRight, bottomRight, m_panelBorderStyle, m_panelBorderWidth);
    drawStylizedBorder(p, bottomRight, bottomLeft, m_panelBorderStyle, m_panelBorderWidth);
    drawStylizedBorder(p, bottomLeft, topLeft, m_panelBorderStyle, m_panelBorderWidth);
    p.end();
  } else {
    baseImg = QImage(basePanelLayer->buffer->data(), m_canvasWidth, m_canvasHeight,
                     QImage::Format_RGBA8888_Premultiplied)
                  .copy();
  }

  // Geometría del corte
  float dx = p2.x() - p1.x();
  float dy = p2.y() - p1.y();
  float len = std::hypot(dx, dy);
  if (len == 0)
    return;
  float nx = -dy / len;
  float ny = dx / len;

  QPointF shiftA(nx * m_panelGutterSize / 2.0f, ny * m_panelGutterSize / 2.0f);
  QLineF lineA(cutLine.pointAt(-100.0) + shiftA,
               cutLine.pointAt(100.0) + shiftA);

  QPointF shiftB(-nx * m_panelGutterSize / 2.0f,
                 -ny * m_panelGutterSize / 2.0f);
  QLineF lineB(cutLine.pointAt(-100.0) + shiftB,
               cutLine.pointAt(100.0) + shiftB);

  QPolygonF polyB; // Lado B de lineA (para borrar de A)
  polyB << lineA.p1() << (lineA.p1() - shiftA * 10000)
        << (lineA.p2() - shiftA * 10000) << lineA.p2();

  QPolygonF polyA; // Lado A de lineB (para borrar de B)
  polyA << lineB.p1() << (lineB.p1() + shiftA * 10000)
        << (lineB.p2() + shiftA * 10000) << lineB.p2();

  QImage copyA = baseImg.copy();
  QImage copyB = baseImg.copy();

  QPainterPath parentPath = basePanelLayer->panelPath;
  if (parentPath.isEmpty()) {
    parentPath.addRect(50, 50, m_canvasWidth - 100, m_canvasHeight - 100);
  }

  // Generar Panel A
  QPainter pa(&copyA);
  pa.setRenderHint(QPainter::Antialiasing);
  pa.setCompositionMode(QPainter::CompositionMode_Clear);
  QPainterPath pPathB;
  pPathB.addPolygon(polyB);
  pa.fillPath(pPathB, Qt::transparent);
  pa.setCompositionMode(QPainter::CompositionMode_SourceOver);
  drawStylizedBorder(pa, lineA.p1(), lineA.p2(), m_panelBorderStyle, m_panelBorderWidth);
  pa.end();

  QPainterPath newPathA = parentPath.subtracted(pPathB);

  // Recortar Panel A estrictamente dentro de los límites del panel original baseImg
  QPainter paMask(&copyA);
  paMask.setCompositionMode(QPainter::CompositionMode_DestinationIn);
  paMask.drawImage(0, 0, baseImg);
  paMask.end();

  // Generar Panel B
  QPainter pb(&copyB);
  pb.setRenderHint(QPainter::Antialiasing);
  pb.setCompositionMode(QPainter::CompositionMode_Clear);
  QPainterPath pPathA;
  pPathA.addPolygon(polyA);
  pb.fillPath(pPathA, Qt::transparent);
  pb.setCompositionMode(QPainter::CompositionMode_SourceOver);
  drawStylizedBorder(pb, lineB.p1(), lineB.p2(), m_panelBorderStyle, m_panelBorderWidth);
  pb.end();

  QPainterPath newPathB = parentPath.subtracted(pPathA);

  // Recortar Panel B estrictamente dentro de los límites del panel original baseImg
  QPainter pbMask(&copyB);
  pbMask.setCompositionMode(QPainter::CompositionMode_DestinationIn);
  pbMask.drawImage(0, 0, baseImg);
  pbMask.end();

  // Encontrar el número secuencial más alto para evitar nombres duplicados
  int maxPanelNum = 0;
  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    QString name = QString::fromStdString(m_layerManager->getLayer(i)->name);
    if (name.startsWith("Panel ", Qt::CaseInsensitive)) {
      bool ok;
      int num = name.mid(6).toInt(&ok);
      if (ok && num > maxPanelNum) maxPanelNum = num;
    } else if (name.startsWith("Art ", Qt::CaseInsensitive)) {
      bool ok;
      int num = name.mid(4).toInt(&ok);
      if (ok && num > maxPanelNum) maxPanelNum = num;
    }
  }
  int nextNum1 = maxPanelNum + 1;
  int nextNum2 = maxPanelNum + 2;

  QString panel1Name = QString("Panel %1").arg(nextNum1);
  QString art1Name = QString("Art %1").arg(nextNum1);
  QString panel2Name = QString("Panel %2").arg(nextNum2);
  QString art2Name = QString("Art %2").arg(nextNum2);

  // 1. Actualizar Capa Base del Panel
  basePanelLayer->buffer->loadRawData(copyA.constBits());
  basePanelLayer->name = panel1Name.toStdString();
  basePanelLayer->dirty = true;
  basePanelLayer->panelPath = newPathA;

  // Actualizar el nombre de la capa de dibujo activa si estaba seleccionada una de arte
  if (activeIdx != basePanelIdx) {
    Layer *activeArtLayer = m_layerManager->getLayer(activeIdx);
    if (activeArtLayer) {
      activeArtLayer->name = art1Name.toStdString();
      activeArtLayer->dirty = true;
    }
  }

  // Buscar el final de las capas acopladas (clipped) al Panel base
  int lastClippedIdx = basePanelIdx;
  while (lastClippedIdx + 1 < m_layerManager->getLayerCount() &&
         m_layerManager->getLayer(lastClippedIdx + 1)->clipped) {
    lastClippedIdx++;
  }

  int targetFocusIdx = -1;

  if (lastClippedIdx == basePanelIdx) {
    // Caso B: No hay capas de dibujo vinculadas. Creamos Art 1 y el Panel 2 + Art 2.
    m_layerManager->addLayer(art1Name.toStdString());
    int art1Idx = m_layerManager->getLayerCount() - 1;
    m_layerManager->moveLayer(art1Idx, basePanelIdx + 1);
    m_layerManager->getLayer(basePanelIdx + 1)->clipped = true;

    m_layerManager->addLayer(panel2Name.toStdString());
    int p2Idx = m_layerManager->getLayerCount() - 1;
    m_layerManager->moveLayer(p2Idx, basePanelIdx + 2);
    Layer *panel2 = m_layerManager->getLayer(basePanelIdx + 2);
    panel2->buffer->loadRawData(copyB.constBits());
    panel2->dirty = true;
    panel2->panelPath = newPathB;

    m_layerManager->addLayer(art2Name.toStdString());
    int art2Idx = m_layerManager->getLayerCount() - 1;
    m_layerManager->moveLayer(art2Idx, basePanelIdx + 3);
    Layer *art2 = m_layerManager->getLayer(basePanelIdx + 3);
    art2->clipped = true;
    art2->dirty = true;

    targetFocusIdx = basePanelIdx + 3; // Foco en la nueva capa Art 2
  } else {
    // Caso A: Ya existen capas de dibujo acopladas. Las dejamos en Panel 1, y creamos Panel 2 + Art 2.
    m_layerManager->addLayer(panel2Name.toStdString());
    int p2Idx = m_layerManager->getLayerCount() - 1;
    m_layerManager->moveLayer(p2Idx, lastClippedIdx + 1);
    Layer *panel2 = m_layerManager->getLayer(lastClippedIdx + 1);
    panel2->buffer->loadRawData(copyB.constBits());
    panel2->dirty = true;
    panel2->panelPath = newPathB;

    m_layerManager->addLayer(art2Name.toStdString());
    int art2Idx = m_layerManager->getLayerCount() - 1;
    m_layerManager->moveLayer(art2Idx, lastClippedIdx + 2);
    Layer *art2 = m_layerManager->getLayer(lastClippedIdx + 2);
    art2->clipped = true;
    art2->dirty = true;

    targetFocusIdx = lastClippedIdx + 2; // Foco en la nueva capa Art 2
  }

  if (targetFocusIdx != -1) {
    m_activeLayerIndex = targetFocusIdx;
    m_layerManager->setActiveLayer(m_activeLayerIndex);
  }

  updateLayersList();
  dirtyPanelOverlay();
}

void CanvasItem::updateTransformCorners(const QVariantList &corners) {
  if (!m_isTransforming || corners.size() < 4)
    return;

  m_meshPoints.clear();
  for (int i = 0; i < corners.size(); ++i) {
    QVariantMap p = corners[i].toMap();
    m_meshPoints.push_back(QPointF(p["x"].toDouble(), p["y"].toDouble()));
  }

  if (m_meshPoints.size() == 16) {
    m_isMeshTransform = true;
  } else {
    m_isMeshTransform = false;
  }

  // If 4 corners (Perspective mode)
  if (m_meshPoints.size() == 4) {
    QPolygonF src;
    src << QPointF(0, 0) << QPointF(m_transformBox.width(), 0)
        << QPointF(m_transformBox.width(), m_transformBox.height())
        << QPointF(0, m_transformBox.height());

    QPolygonF dst;
    for (int i = 0; i < 4; ++i) {
      dst << m_meshPoints[i];
    }

    QTransform transform;
    if (QTransform::quadToQuad(src, dst, transform)) {
      m_transformMatrix = transform;
    }
  }

  requestUpdate(); // throttled — no update() directo aquí
}

static void warpQuadBilinear(const QImage &srcImg, QImage &dstImg,
                             const QPolygonF &srcQuad, const QPolygonF &dstQuad,
                             int canvasWidth, int canvasHeight) {
  QTransform trans;
  if (!QTransform::quadToQuad(srcQuad, dstQuad, trans))
    return;

  QTransform invTrans = trans.inverted();
  QRectF bound = dstQuad.boundingRect();
  QRect bbox = bound.toRect().intersected(QRect(0, 0, canvasWidth, canvasHeight));

  int sw = srcImg.width();
  int sh = srcImg.height();

  for (int y = bbox.top(); y <= bbox.bottom(); ++y) {
    for (int x = bbox.left(); x <= bbox.right(); ++x) {
      QPointF pt(x + 0.5, y + 0.5);
      if (dstQuad.containsPoint(pt, Qt::OddEvenFill)) {
        QPointF srcPt = invTrans.map(pt);
        float sx = srcPt.x();
        float sy = srcPt.y();
        if (sx >= 0 && sx < sw && sy >= 0 && sy < sh) {
          // Bilinear interpolation
          int x0 = qBound(0, (int)std::floor(sx), sw - 1);
          int y0 = qBound(0, (int)std::floor(sy), sh - 1);
          int x1 = qBound(0, x0 + 1, sw - 1);
          int y1 = qBound(0, y0 + 1, sh - 1);

          float tx = sx - std::floor(sx);
          float ty = sy - std::floor(sy);

          QRgb p00 = srcImg.pixel(x0, y0);
          QRgb p10 = srcImg.pixel(x1, y0);
          QRgb p01 = srcImg.pixel(x0, y1);
          QRgb p11 = srcImg.pixel(x1, y1);

          float a = (1.0f - tx) * (1.0f - ty) * qAlpha(p00) + tx * (1.0f - ty) * qAlpha(p10) +
                    (1.0f - tx) * ty * qAlpha(p01) + tx * ty * qAlpha(p11);
          float r = (1.0f - tx) * (1.0f - ty) * qRed(p00) + tx * (1.0f - ty) * qRed(p10) +
                    (1.0f - tx) * ty * qRed(p01) + tx * ty * qRed(p11);
          float g = (1.0f - tx) * (1.0f - ty) * qGreen(p00) + tx * (1.0f - ty) * qGreen(p10) +
                    (1.0f - tx) * ty * qGreen(p01) + tx * ty * qGreen(p11);
          float b = (1.0f - tx) * (1.0f - ty) * qBlue(p00) + tx * (1.0f - ty) * qBlue(p10) +
                    (1.0f - tx) * ty * qBlue(p01) + tx * ty * qBlue(p11);

          QRgb srcColor = qRgba((int)r, (int)g, (int)b, (int)a);
          
          int srcA = qAlpha(srcColor);
          if (srcA == 0) continue;

          QRgb dstColor = dstImg.pixel(x, y);
          int dstA = qAlpha(dstColor);

          if (dstA == 0) {
            dstImg.setPixel(x, y, srcColor);
          } else {
            int outA = srcA + (dstA * (255 - srcA) + 127) / 255;
            int outR = qRed(srcColor) + (qRed(dstColor) * (255 - srcA) + 127) / 255;
            int outG = qGreen(srcColor) + (qGreen(dstColor) * (255 - srcA) + 127) / 255;
            int outB = qBlue(srcColor) + (qBlue(dstColor) * (255 - srcA) + 127) / 255;
            dstImg.setPixel(x, y, qRgba(outR, outG, outB, outA));
          }
        }
      }
    }
  }
}

void CanvasItem::applyTransform() {
  if (!m_isTransforming)
    return;

  if (m_selectionBuffer.isNull()) {
    resetTransformState();
    return;
  }

  Layer *layer = m_layerManager->getActiveLayer();
  if (layer && layer->buffer) {
    if (layer->type == Layer::Type::Vector) {
      if (layer->vectorData) {
        QTransform t;
        t.translate(m_transformBox.x(), m_transformBox.y());
        t = t * m_transformMatrix;
        t.translate(-m_transformBox.x(), -m_transformBox.y());
        layer->vectorData->transformAll(t);
        
        layer->buffer->clear();
        layer->vectorData->rasterize(*layer->buffer);
        layer->dirty = false;
        layer->markDirty();

        // Push Vector Undo Command
        auto afterVector = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
        auto afterBuffer = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
        m_undoManager->pushCommand(std::make_unique<VectorUndoCommand>(
            m_layerManager, m_activeLayerIndex, std::move(m_transformBeforeBuffer),
            std::move(afterBuffer), std::move(m_vectorBeforeData), std::move(afterVector)));
      }
    } else {
      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);

      if (m_isMeshTransform && m_meshPoints.size() == 16) {
        float sw = m_selectionBuffer.width();
        float sh = m_selectionBuffer.height();

        for (int row = 0; row < 3; ++row) {
          for (int col = 0; col < 3; ++col) {
            int idx_TL = row * 4 + col;
            int idx_TR = row * 4 + col + 1;
            int idx_BR = (row + 1) * 4 + col + 1;
            int idx_BL = (row + 1) * 4 + col;

            QPointF TL = m_meshPoints[idx_TL];
            QPointF TR = m_meshPoints[idx_TR];
            QPointF BR = m_meshPoints[idx_BR];
            QPointF BL = m_meshPoints[idx_BL];

            QPolygonF dstPolygon;
            dstPolygon << TL << TR << BR << BL;

            QPolygonF srcPolygon;
            srcPolygon << QPointF(col * sw / 3.0f, row * sh / 3.0f)
                       << QPointF((col + 1) * sw / 3.0f, row * sh / 3.0f)
                       << QPointF((col + 1) * sw / 3.0f, (row + 1) * sh / 3.0f)
                       << QPointF(col * sw / 3.0f, (row + 1) * sh / 3.0f);

            warpQuadBilinear(m_selectionBuffer, img, srcPolygon, dstPolygon, m_canvasWidth, m_canvasHeight);
          }
        }
      } else if (m_meshPoints.size() == 4) { // Perspective transform (projective quad-to-quad)
        float sw = m_selectionBuffer.width();
        float sh = m_selectionBuffer.height();

        QPolygonF srcPolygon;
        srcPolygon << QPointF(0, 0) << QPointF(sw, 0) << QPointF(sw, sh) << QPointF(0, sh);

        QPolygonF dstPolygon;
        for (int i = 0; i < 4; ++i) {
          dstPolygon << m_meshPoints[i];
        }

        warpQuadBilinear(m_selectionBuffer, img, srcPolygon, dstPolygon, m_canvasWidth, m_canvasHeight);
      } else { // Free transform (affine)
        QPainter p(&img);
        p.setRenderHint(QPainter::SmoothPixmapTransform);
        p.setRenderHint(QPainter::Antialiasing);
        p.setTransform(m_transformMatrix);
        p.drawImage(0, 0, m_selectionBuffer);
        p.end();
      }

      // Sync QImage modifications (m_cachedData) back to ImageBuffer tiles!
      layer->buffer->loadRawData(layer->buffer->data());

      layer->dirty = true;

      // 3. PUSH UNDO
      auto after = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
      m_undoManager->pushCommand(std::make_unique<artflow::StrokeUndoCommand>(
          m_layerManager, m_activeLayerIndex, std::move(m_transformBeforeBuffer),
          std::move(after)));
    }
  }

  resetTransformState();
}

void CanvasItem::cancelTransform() {
  if (!m_isTransforming)
    return;

  if (m_selectionBuffer.isNull()) {
    resetTransformState();
    return;
  }

  Layer *layer = m_layerManager->getActiveLayer();
  if (layer && layer->buffer) {
    if (layer->type == Layer::Type::Vector) {
      if (m_vectorBeforeData) {
        layer->vectorData = std::make_unique<artflow::VectorLayerData>(*m_vectorBeforeData);
      }
      layer->buffer->clear();
      if (layer->vectorData) {
        layer->vectorData->rasterize(*layer->buffer);
      }
      layer->dirty = true;
      layer->markDirty();
    } else {
      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
      QPainter p(&img);
      p.drawImage(m_transformBox.topLeft(),
                  m_selectionBuffer); // Draw back original at its position
      p.end();

      // Sync QImage modifications (m_cachedData) back to ImageBuffer tiles!
      layer->buffer->loadRawData(layer->buffer->data());

      layer->dirty = true;
    }
  }

  resetTransformState();
}

void CanvasItem::commitTransform() { applyTransform(); }

void CanvasItem::adjustBrushSize(float deltaPercent) {
  setBrushSize(std::max(1, (int)(m_brushSize * (1.0f + deltaPercent))));
}

void CanvasItem::adjustBrushOpacity(float deltaPercent) {
  setBrushOpacity(std::clamp(m_brushOpacity + deltaPercent, 0.0f, 1.0f));
}

void CanvasItem::wheelEvent(QWheelEvent *event) {
  QPointF pos = event->position();

  // Unproject to canvas space (rotation-aware)
  QPointF canvasPosBefore = screenToCanvas(pos);

  float factor = (event->angleDelta().y() > 0) ? 1.1f : 0.9f;
  float newZoom = m_zoomLevel * factor;

  if (newZoom < 0.01f)
    newZoom = 0.01f;
  if (newZoom > 100.0f)
    newZoom = 100.0f;

  m_zoomLevel = newZoom;

  // Adjust viewOffset to keep canvasPosBefore under the cursor
  // Un-rotate the screen position first to get the non-rotated screen pos
  QPointF viewCenter(width() / 2.0, height() / 2.0);
  float rad = qDegreesToRadians(-m_canvasRotation);
  float cosA = std::cos(rad);
  float sinA = std::sin(rad);
  QPointF p = pos - viewCenter;
  QPointF unrotatedPos(p.x() * cosA - p.y() * sinA,
                       p.x() * sinA + p.y() * cosA);
  QPointF afterRotation = unrotatedPos + viewCenter;

  // Flip-correct canvasPosBefore for offset calculation
  QPointF flipCorrected = canvasPosBefore;
  if (m_isFlippedH) flipCorrected.setX(m_canvasWidth - flipCorrected.x());
  if (m_isFlippedV) flipCorrected.setY(m_canvasHeight - flipCorrected.y());

  m_viewOffset = (afterRotation / m_zoomLevel) - flipCorrected;

  invalidateCursorCache();
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

bool CanvasItem::create_folder_from_merge(const QString &sourcePath,
                                          const QString &targetPath) {
  if (sourcePath.isEmpty() || targetPath.isEmpty() || sourcePath == targetPath)
    return false;

  QFileInfo srcInfo(sourcePath);
  QFileInfo tgtInfo(targetPath);

  if (!srcInfo.exists() || !tgtInfo.exists())
    return false;

  QDir parentDir =
      srcInfo.dir(); // Assuming both in same parent dir for simplicity

  if (tgtInfo.isDir()) {
    // Target is a folder, move source inside
    QString newPath = tgtInfo.absoluteFilePath() + "/" + srcInfo.fileName();
    bool success = QFile::rename(sourcePath, newPath);
    if (success) {
      emit projectListChanged();
    }
    return success;
  } else if (srcInfo.isDir()) {
    // Source is a folder, move target inside (just in case they dragged
    // folder onto a drawing somehow)
    QString newPath = srcInfo.absoluteFilePath() + "/" + tgtInfo.fileName();
    bool success = QFile::rename(targetPath, newPath);
    if (success) {
      emit projectListChanged();
    }
    return success;
  } else {
    // Both are files, create a new folder
    QString folderName =
        "Group_" + QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    QString newDirPath = parentDir.absolutePath() + "/" + folderName;

    if (parentDir.mkdir(folderName)) {
      bool success1 =
          QFile::rename(sourcePath, newDirPath + "/" + srcInfo.fileName());
      bool success2 =
          QFile::rename(targetPath, newDirPath + "/" + tgtInfo.fileName());

      if (success1 || success2) {
        emit projectListChanged();
        return true;
      }
    }
  }
  return false;
}

void CanvasItem::load_file_path(const QString &path) { loadProject(path); }
void CanvasItem::handle_shortcuts(int key, int modifiers) {
  // Track modifier keys
  if (key == Qt::Key_Shift) {
    m_shiftPressed = true;
  }
  if (key == Qt::Key_Space) {
    if (!m_spacePressed) {
      m_spacePressed = true;
      QGuiApplication::setOverrideCursor(m_customOpenHandCursor);
    }
  }
  if (key == Qt::Key_R) {
    m_rPressed = true;
  }

  // Brush Size/Opacity are left here as they are fine-grained
  if (key == Qt::Key_BracketLeft)
    adjustBrushSize(-0.1f);
  else if (key == Qt::Key_BracketRight)
    adjustBrushSize(0.1f);
  else if (key == Qt::Key_O) // Optional: Opacity decrease
    adjustBrushOpacity(-0.1f);
  else if (key == Qt::Key_P) // Optional: Opacity increase
    adjustBrushOpacity(0.1f);
  // Canvas Rotation shortcuts (Krita-style: 4=CCW, 5=Reset, 6=CW)
  else if (key == Qt::Key_4)
    rotateCanvasBy(-15.0f);
  else if (key == Qt::Key_5)
    resetCanvasRotation();
  else if (key == Qt::Key_6)
    rotateCanvasBy(15.0f);
}

void CanvasItem::handle_key_release(int key) {
  if (key == Qt::Key_Space) {
    if (m_spacePressed) {
      m_spacePressed = false;
      m_isRotatingCanvas = false;
      QGuiApplication::restoreOverrideCursor();
    }

    // Restaurar cursor correcto al soltar espacio
    if (m_tool != ToolType::Hand && m_tool != ToolType::Transform) {
      setCursor(Qt::BlankCursor);
    } else if (m_tool == ToolType::Hand) {
      setCursor(m_customOpenHandCursor);
    } else if (m_tool == ToolType::Transform) {
      setCursor(getModernCursor());
    }

    update();
  }
  if (key == Qt::Key_Shift) {
    m_shiftPressed = false;
  }
  if (key == Qt::Key_R) {
    m_rPressed = false;
    m_isRotatingCanvas = false;
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

class VectorRasterizeUndoCommand : public artflow::UndoCommand {
public:
  VectorRasterizeUndoCommand(artflow::LayerManager *manager, int layerIndex, 
                             std::unique_ptr<artflow::VectorLayerData> oldVectorData)
      : m_manager(manager), m_layerIndex(layerIndex), m_oldVectorData(std::move(oldVectorData)) {}

  void undo() override {
    artflow::Layer *layer = m_manager->getLayer(m_layerIndex);
    if (layer) {
      layer->type = artflow::Layer::Type::Vector;
      layer->vectorData = std::make_unique<artflow::VectorLayerData>(*m_oldVectorData);
      layer->buffer->clear();
      layer->vectorData->rasterize(*layer->buffer);
      layer->markDirty();
    }
  }

  void redo() override {
    artflow::Layer *layer = m_manager->getLayer(m_layerIndex);
    if (layer) {
      layer->type = artflow::Layer::Type::Drawing;
      layer->vectorData.reset();
      layer->markDirty();
    }
  }

  std::string name() const override { return "Rasterize Layer"; }

private:
  artflow::LayerManager *m_manager;
  int m_layerIndex;
  std::unique_ptr<artflow::VectorLayerData> m_oldVectorData;
};

void CanvasItem::addVectorLayer() {
  if (!m_layerManager) return;

  int activeIdx = m_layerManager->getActiveLayerIndex();
  int totalLayers = m_layerManager->getLayerCount();
  artflow::Layer *activeLayer = m_layerManager->getLayer(activeIdx);

  bool shouldClip = false;
  int targetIdx = totalLayers; // default: top of the stack

  if (activeLayer) {
    QString activeName = QString::fromStdString(activeLayer->name);
    if (activeLayer->clipped) {
      shouldClip = true;
      targetIdx = activeIdx + 1;
    } else if (activeName.startsWith("Panel ", Qt::CaseInsensitive)) {
      shouldClip = true;
      targetIdx = activeIdx + 1;
    } else {
      // Normal layer: insert right above active layer
      shouldClip = false;
      targetIdx = activeIdx + 1;
    }
  }

  if (targetIdx < 0) targetIdx = 0;
  if (targetIdx > totalLayers) targetIdx = totalLayers;

  m_layerManager->addVectorLayer("Vector Layer");
  int newCount = m_layerManager->getLayerCount();
  int newLayerIdx = newCount - 1;

  artflow::Layer *newLayer = m_layerManager->getLayer(newLayerIdx);
  if (newLayer) {
    newLayer->clipped = shouldClip;
  }

  if (newLayerIdx != targetIdx) {
    m_layerManager->moveLayer(newLayerIdx, targetIdx);
  }

  setActiveLayer(targetIdx);

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerAddUndoCommand>(
        m_layerManager, targetIdx, nullptr, activeIdx, targetIdx));
  }

  update();
  updateLayersList();
}

bool CanvasItem::isVectorLayer(int index) const {
  if (!m_layerManager) return false;
  const artflow::Layer *layer = m_layerManager->getLayer(index);
  return (layer && layer->type == artflow::Layer::Type::Vector);
}

void CanvasItem::rasterizeVectorLayer(int index) {
  if (!m_layerManager) return;
  artflow::Layer *layer = m_layerManager->getLayer(index);
  if (!layer || layer->type != artflow::Layer::Type::Vector || !layer->vectorData) return;

  auto oldVectorData = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);

  layer->type = artflow::Layer::Type::Drawing;
  layer->vectorData.reset();
  layer->markDirty();

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<VectorRasterizeUndoCommand>(
        m_layerManager, index, std::move(oldVectorData)));
  }

  update();
  updateLayersList();
}

void CanvasItem::finalizeVectorStroke() {
  m_isVectorDrawing = false;
  
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer || !layer->vectorData) return;

  if (m_strokeBeforeBuffer) {
    layer->buffer->copyFrom(*m_strokeBeforeBuffer);
  }

  if (m_tool == ToolType::VectorEraser || 
      (m_tool == ToolType::Eraser && layer->type == Layer::Type::Vector)) {
    if (m_vectorPointBuffer.size() >= 2) {
      auto eraserSegments = fitBezierChain(m_vectorPointBuffer, 3.0f, 1.5f);
      if (!eraserSegments.empty()) {
        VectorStroke eraserStroke;
        eraserStroke.segments = std::move(eraserSegments);
        eraserStroke.globalWidth = m_brushSize;
        eraserStroke.isEraser = true;
        if (m_brushEngine) {
          BrushSettings s = m_brushEngine->getBrush();
          eraserStroke.spacing = s.spacing;
          eraserStroke.hardness = s.hardness;
        }
        eraserStroke.recalcBounds();

        layer->vectorData->vectorErase(eraserStroke);
        
        layer->markDirty();
        m_cachedCanvasImage = QImage();
      }
    }
  } else {
    if (m_vectorPointBuffer.size() >= 2) {
      auto segments = fitBezierChain(m_vectorPointBuffer, 6.0f, 3.0f);
      if (!segments.empty()) {
        VectorStroke stroke;
        stroke.segments = std::move(segments);
        stroke.color = m_brushColor;
        stroke.opacity = m_brushOpacity;
        stroke.globalWidth = m_brushSize;
        
        if (m_brushEngine) {
          BrushSettings s = m_brushEngine->getBrush();
          stroke.tipTextureName = s.tipTextureName;
          stroke.spacing = s.spacing;
          stroke.hardness = s.hardness;
          stroke.useTexture = s.useTexture;
          stroke.textureName = s.textureName;
          stroke.isEraser = false;
        }

        stroke.recalcBounds();

        layer->vectorData->addStroke(std::move(stroke));
      }
    }
  }

  m_vectorPointBuffer.clear();

  if (m_pingFBO) {
    delete m_pingFBO;
    m_pingFBO = nullptr;
    delete m_pongFBO;
    m_pongFBO = nullptr;
  }

  layer->buffer->clear();
  layer->vectorData->rasterize(*layer->buffer);
  layer->dirty = false;
  layer->markDirty();
  m_cachedCanvasImage = QImage();

  if (m_strokeBeforeBuffer) {
    auto afterBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
    if (layer->type == Layer::Type::Vector) {
      auto afterVector = std::make_unique<artflow::VectorLayerData>(*layer->vectorData);
      m_undoManager->pushCommand(std::make_unique<VectorUndoCommand>(
          m_layerManager, m_activeLayerIndex, std::move(m_strokeBeforeBuffer),
          std::move(afterBuffer), std::move(m_vectorBeforeData), std::move(afterVector)));
    } else {
      m_undoManager->pushCommand(std::make_unique<StrokeUndoCommand>(
          m_layerManager, m_activeLayerIndex, std::move(m_strokeBeforeBuffer),
          std::move(afterBuffer)));
    }
    m_strokeBeforeBuffer.reset();
  }

  m_lastPos = QPointF();
  capture_timelapse_frame();
  update();
  updateLayersList();
  setProjectDirty(true);
}

void CanvasItem::addLayer() {
  if (!m_layerManager) return;

  int activeIdx = m_layerManager->getActiveLayerIndex();
  int totalLayers = m_layerManager->getLayerCount();
  artflow::Layer *activeLayer = m_layerManager->getLayer(activeIdx);

  bool shouldClip = false;
  int targetIdx = totalLayers; // default: top of the stack

  if (activeLayer) {
    QString activeName = QString::fromStdString(activeLayer->name);
    if (activeLayer->clipped) {
      shouldClip = true;
      targetIdx = activeIdx + 1;
    } else if (activeName.startsWith("Panel ", Qt::CaseInsensitive)) {
      shouldClip = true;
      targetIdx = activeIdx + 1;
    } else {
      // Normal layer: insert right above active layer
      shouldClip = false;
      targetIdx = activeIdx + 1;
    }
  }

  if (targetIdx < 0) targetIdx = 0;
  if (targetIdx > totalLayers) targetIdx = totalLayers;

  m_layerManager->addLayer("New Layer");
  int newCount = m_layerManager->getLayerCount();
  int newLayerIdx = newCount - 1;

  artflow::Layer *newLayer = m_layerManager->getLayer(newLayerIdx);
  if (newLayer) {
    newLayer->clipped = shouldClip;
  }

  if (newLayerIdx != targetIdx) {
    m_layerManager->moveLayer(newLayerIdx, targetIdx);
  }

  setActiveLayer(targetIdx);

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerAddUndoCommand>(
        m_layerManager, targetIdx, nullptr, activeIdx, targetIdx));
  }

  update();
}

void CanvasItem::addGroup() {
  if (!m_layerManager) return;

  int activeIdx = m_layerManager->getActiveLayerIndex();
  int totalLayers = m_layerManager->getLayerCount();

  int targetIdx = activeIdx + 1;
  if (targetIdx < 0) targetIdx = 0;
  if (targetIdx > totalLayers) targetIdx = totalLayers;

  m_layerManager->addLayer("New Group", artflow::Layer::Type::Group);
  int newCount = m_layerManager->getLayerCount();
  int newLayerIdx = newCount - 1;

  if (newLayerIdx != targetIdx) {
    m_layerManager->moveLayer(newLayerIdx, targetIdx);
  }

  setActiveLayer(targetIdx);

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerAddUndoCommand>(
        m_layerManager, targetIdx, nullptr, activeIdx, targetIdx));
  }

  update();
}

int CanvasItem::getFolderCount() const {
  if (!m_layerManager) return 0;
  int count = 0;
  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    artflow::Layer *l = m_layerManager->getLayer(i);
    if (l && l->type == artflow::Layer::Type::Group) {
      count++;
    }
  }
  return count;
}

int CanvasItem::getFirstCreatedFolderStableId() const {
  if (!m_layerManager) return -1;
  int minStableId = -1;
  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    artflow::Layer *l = m_layerManager->getLayer(i);
    if (l && l->type == artflow::Layer::Type::Group) {
      if (minStableId == -1 || (int)l->stableId < minStableId) {
        minStableId = (int)l->stableId;
      }
    }
  }
  return minStableId;
}

artflow::Layer* CanvasItem::getActiveBasePanel(int *outIndex) const {
  if (!m_layerManager) return nullptr;
  int activeIdx = m_layerManager->getActiveLayerIndex();
  artflow::Layer *activeLayer = m_layerManager->getLayer(activeIdx);
  if (!activeLayer) return nullptr;

  // Trace down to find the clipping base
  int baseIdx = activeIdx;
  while (baseIdx >= 0) {
    artflow::Layer *l = m_layerManager->getLayer(baseIdx);
    if (!l) break;
    if (!l->clipped) {
      QString name = QString::fromStdString(l->name);
      if (name.startsWith("Panel ", Qt::CaseInsensitive)) {
        if (outIndex) *outIndex = baseIdx;
        return l;
      }
      break; // It's a non-clipped layer but not a panel (e.g. background or standard layer)
    }
    baseIdx--;
  }
  return nullptr;
}

void CanvasItem::dirtyPanelOverlay() {
  m_panelOverlayDirty = true;
  update();
}

void CanvasItem::drawActivePanelOverlay(QPainter *painter) {
  if (!m_layerManager)
    return;

  int panelIdx = -1;
  artflow::Layer *basePanelLayer = getActiveBasePanel(&panelIdx);
  if (!basePanelLayer || !basePanelLayer->buffer) {
    m_cachedPanelOverlay = QImage();
    m_cachedPanelBorder = QImage();
    m_lastActiveBasePanel = nullptr;
    return;
  }

  int cw = m_canvasWidth;
  int ch = m_canvasHeight;

  bool needRebuild = m_panelOverlayDirty ||
                     m_cachedPanelOverlay.isNull() ||
                     m_cachedPanelBorder.isNull() ||
                     m_cachedPanelOverlay.width() != cw ||
                     m_cachedPanelOverlay.height() != ch ||
                     basePanelLayer != m_lastActiveBasePanel;

  if (needRebuild) {
    m_panelOverlayDirty = false;
    m_lastActiveBasePanel = basePanelLayer;
    m_lastCanvasWidth = cw;
    m_lastCanvasHeight = ch;

    // 1. Create the periwinkle mask overlay (outside the active panel)
    m_cachedPanelOverlay = QImage(cw, ch, QImage::Format_RGBA8888_Premultiplied);
    m_cachedPanelOverlay.fill(QColor(115, 120, 230, 70));

    QImage maskImg(basePanelLayer->buffer->data(), cw, ch, QImage::Format_RGBA8888_Premultiplied);

    QPainter op(&m_cachedPanelOverlay);
    op.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    op.drawImage(0, 0, maskImg);
    op.end();

    // 2. Create the 2px dilated indigo border outline
    QImage coloredMask(cw, ch, QImage::Format_RGBA8888_Premultiplied);
    coloredMask.fill(QColor(90, 95, 245, 230));
    {
      QPainter cp(&coloredMask);
      cp.setCompositionMode(QPainter::CompositionMode_DestinationIn);
      cp.drawImage(0, 0, maskImg);
    }

    m_cachedPanelBorder = QImage(cw, ch, QImage::Format_RGBA8888_Premultiplied);
    m_cachedPanelBorder.fill(Qt::transparent);
    {
      QPainter bp(&m_cachedPanelBorder);
      bp.drawImage(-2, 0, coloredMask);
      bp.drawImage(2, 0, coloredMask);
      bp.drawImage(0, -2, coloredMask);
      bp.drawImage(0, 2, coloredMask);
      bp.drawImage(-1, -1, coloredMask);
      bp.drawImage(1, -1, coloredMask);
      bp.drawImage(-1, 1, coloredMask);
      bp.drawImage(1, 1, coloredMask);
      bp.drawImage(0, 0, coloredMask);

      bp.setCompositionMode(QPainter::CompositionMode_DestinationOut);
      bp.drawImage(0, 0, maskImg);
    }
  }

  // 3. Draw the overlay and the border onto the canvas coordinate system!
  painter->save();
  painter->translate(m_viewOffset.x() * m_zoomLevel, m_viewOffset.y() * m_zoomLevel);
  painter->scale(m_zoomLevel, m_zoomLevel);

  painter->drawImage(0, 0, m_cachedPanelOverlay);
  painter->drawImage(0, 0, m_cachedPanelBorder);

  painter->restore();
}

void CanvasItem::moveLayerToGroup(int layerId, int groupId) {
  // layerId and groupId are the layer indices (as exposed in the model)
  int count = m_layerManager->getLayerCount();

  // The IDs passed from QML are already direct manager indices (layerId and groupId).
  int fromManagerIdx = layerId;
  int groupManagerIdx = groupId;

  if (fromManagerIdx < 0 || fromManagerIdx >= count || groupManagerIdx < 0 ||
      groupManagerIdx >= count) {
    qWarning() << "moveLayerToGroup: invalid indices" << layerId << groupId;
    return;
  }

  // Block moving the background layer (index 0) into a group
  if (fromManagerIdx == 0) {
    qWarning() << "Blocking moveLayerToGroup: Cannot move background layer to a group.";
    return;
  }

  artflow::Layer *grpLayer = m_layerManager->getLayer(groupManagerIdx);
  if (!grpLayer || grpLayer->type != artflow::Layer::Type::Group) {
    qWarning() << "moveLayerToGroup: target is not a group";
    return;
  }


  artflow::Layer *layerToMove = m_layerManager->getLayer(fromManagerIdx);
  if (layerToMove) {
    layerToMove->parentId = (int)grpLayer->stableId;
  }

  // We want to place the layer right before the group in the manager's list
  // so that it visually appears immediately inside/under the group in the UI.
  // When 'from < group', erasing 'from' causes 'group' to shift left by 1. So we insert at group - 1.
  // When 'from > group', erasing 'from' doesn't shift 'group'. So we insert at group.
  int destManagerIdx = (fromManagerIdx < groupManagerIdx) ? (groupManagerIdx - 1) : groupManagerIdx;
  if (destManagerIdx < 1)
    destManagerIdx = 1;

  if (destManagerIdx != fromManagerIdx) {
    m_layerManager->moveLayer(fromManagerIdx, destManagerIdx);

    // Recalculate active index
    if (m_activeLayerIndex == fromManagerIdx) {
      m_activeLayerIndex = destManagerIdx;
      emit activeLayerChanged();
    }
  }

  updateLayersList();
  update();
}

void CanvasItem::groupLayersOrMoveToGroup(int draggedLayerId, int targetLayerId) {
  int count = m_layerManager->getLayerCount();
  int draggedManagerIdx = draggedLayerId;
  int targetManagerIdx = targetLayerId;

  if (draggedManagerIdx < 0 || draggedManagerIdx >= count || targetManagerIdx < 0 ||
      targetManagerIdx >= count) {
    qWarning() << "groupLayersOrMoveToGroup: invalid indices" << draggedLayerId << targetLayerId;
    return;
  }

  // Block grouping if either layer is the background layer (index 0)
  if (draggedManagerIdx == 0 || targetManagerIdx == 0) {
    qWarning() << "Blocking groupLayersOrMoveToGroup: Cannot group background layer.";
    return;
  }

  artflow::Layer *targetLayer = m_layerManager->getLayer(targetManagerIdx);
  if (!targetLayer) return;

  if (targetLayer->type == artflow::Layer::Type::Group) {
    moveLayerToGroup(draggedLayerId, targetLayerId);
    return;
  }

  // If the target layer is already inside a group, simply move the dragged layer into that existing group.
  if (targetLayer->parentId != -1) {
    int parentManagerIdx = -1;
    for (int i = 0; i < count; ++i) {
      if ((int)m_layerManager->getLayer(i)->stableId == targetLayer->parentId) {
        parentManagerIdx = i;
        break;
      }
    }
    if (parentManagerIdx != -1) {
      moveLayerToGroup(draggedLayerId, parentManagerIdx);
      return;
    }
  }



  artflow::Layer *draggedLayer = m_layerManager->getLayer(draggedManagerIdx);
  if (!draggedLayer) return;

  // Create the new group
  m_layerManager->addLayer("New Group", artflow::Layer::Type::Group);
  int newGroupManagerIdx = m_layerManager->getLayerCount() - 1;
  artflow::Layer *newGroupLayer = m_layerManager->getLayer(newGroupManagerIdx);

  if (!newGroupLayer) return;

  // Set parent IDs
  draggedLayer->parentId = (int)newGroupLayer->stableId;
  targetLayer->parentId = (int)newGroupLayer->stableId;

  auto getIdxByStableId = [&](uint32_t id) -> int {
      for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
          if (m_layerManager->getLayer(i)->stableId == id) return i;
      }
      return -1;
  };

  auto moveLayerAfter = [&](uint32_t layerToMove, uint32_t layerRef) {
      int from = getIdxByStableId(layerToMove);
      int ref = getIdxByStableId(layerRef);
      if (from == -1 || ref == -1 || from == ref) return;
      
      int targetIdx = (from < ref) ? ref : (ref + 1);
      if (from != targetIdx) {
          m_layerManager->moveLayer(from, targetIdx);
      }
  };

  // Place Group immediately above Target
  moveLayerAfter(newGroupLayer->stableId, targetLayer->stableId);
  
  // Place Dragged immediately above Target (which pushes Group up one level)
  // The final order bottom-to-top will be: Target, Dragged, Group
  moveLayerAfter(draggedLayer->stableId, targetLayer->stableId);

  // Set active layer to the newly created group
  setActiveLayer(getIdxByStableId(newGroupLayer->stableId));

  updateLayersList();
  update();
}

void CanvasItem::toggleGroupExpanded(int index) {
  int count = m_layerManager->getLayerCount();
  int managerIdx = index;

  if (managerIdx < 0 || managerIdx >= count)
    return;

  artflow::Layer *l = m_layerManager->getLayer(managerIdx);
  if (l && l->type == artflow::Layer::Type::Group) {
    l->expanded = !l->expanded;
    updateLayersList();
  }
}

void CanvasItem::removeLayer(int index) {
  if (m_isTransforming) {
    cancelTransform();
  }
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Cannot delete a locked layer", "error");
    return;
  }

  int activeBefore = m_layerManager->getActiveLayerIndex();
  int countBefore = m_layerManager->getLayerCount();
  if (countBefore <= 1)
    return; // Keep at least one layer

  std::unique_ptr<Layer> takenLayer = m_layerManager->takeLayer(index);
  if (!takenLayer)
    return;

  clearRenderCaches();
  int activeAfter = qMax(0, (int)m_layerManager->getLayerCount() - 1);
  m_layerManager->setActiveLayer(activeAfter);
  m_activeLayerIndex = activeAfter;
  emit activeLayerChanged();

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerRemoveUndoCommand>(
        m_layerManager, index, std::move(takenLayer), activeBefore, activeAfter));
  }

  updateLayersList();
  update();
}

void CanvasItem::duplicateLayer(int index) {
  int activeBefore = m_layerManager->getActiveLayerIndex();
  m_layerManager->duplicateLayer(index);
  int activeAfter = index + 1;
  setActiveLayer(activeAfter);

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerAddUndoCommand>(
        m_layerManager, index + 1, nullptr, activeBefore, activeAfter));
  }

  updateLayersList();
  update();
}

void CanvasItem::moveLayer(int fromIndex, int toIndex) {
  // Prevent background layer (index 0) from being moved
  if (fromIndex == 0) {
    return;
  }

  // Prevent other layers from moving to index 0 (clamp to 1)
  if (toIndex == 0) {
    toIndex = 1;
  }

  if (fromIndex == toIndex)
    return;

  // Validate indices
  int count = m_layerManager->getLayerCount();
  if (fromIndex < 0 || fromIndex >= count || toIndex < 0 || toIndex >= count) {
    return;
  }

  int activeBefore = m_activeLayerIndex;
  artflow::Layer *moved = m_layerManager->getLayer(fromIndex);
  int parentIdBefore = moved ? moved->parentId : -1;
  bool clippedBefore = moved ? moved->clipped : false;

  m_layerManager->moveLayer(fromIndex, toIndex);

  // Update parentId based on new neighbors to allow entering/exiting groups
  moved = m_layerManager->getLayer(toIndex);
  if (moved && moved->type != artflow::Layer::Type::Background) {
    artflow::Layer *neighborAbove =
        (toIndex + 1 < count) ? m_layerManager->getLayer(toIndex + 1) : nullptr;

    if (neighborAbove) {
      if (neighborAbove->type == artflow::Layer::Type::Group) {
        moved->parentId = (int)neighborAbove->stableId;
      } else {
        moved->parentId = neighborAbove->parentId;
      }
    } else {
      moved->parentId = -1;
    }
  }

  // Auto-clipping logic: If dropped into the middle of a clipping group, join it.
  artflow::Layer *above =
      (toIndex + 1 < count) ? m_layerManager->getLayer(toIndex + 1) : nullptr;
  if (moved && above && above->clipped) {
    moved->clipped = true;
  }

  int parentIdAfter = moved ? moved->parentId : -1;
  bool clippedAfter = moved ? moved->clipped : false;

  // Update active layer index if it moved
  if (m_activeLayerIndex == fromIndex) {
    m_activeLayerIndex = toIndex;
    emit activeLayerChanged();
  } else if (fromIndex < m_activeLayerIndex && toIndex >= m_activeLayerIndex) {
    m_activeLayerIndex--;
    emit activeLayerChanged();
  } else if (fromIndex > m_activeLayerIndex && toIndex <= m_activeLayerIndex) {
    m_activeLayerIndex++;
    emit activeLayerChanged();
  }

  int activeAfter = m_activeLayerIndex;

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerMoveUndoCommand>(
        m_layerManager, fromIndex, toIndex, parentIdBefore, parentIdAfter,
        clippedBefore, clippedAfter, activeBefore, activeAfter));
  }

  updateLayersList();
  update();
}

void CanvasItem::mergeDown(int index) {
  if (!m_layerManager) return;
  if (index <= 0 || index >= m_layerManager->getLayerCount())
    return;

  Layer *top = m_layerManager->getLayer(index);
  Layer *bottom = m_layerManager->getLayer(index - 1);

  if (!top || !bottom)
    return;
  if (bottom->locked) {
    emit notificationRequested("Cannot merge onto a locked layer", "error");
    return;
  }
  if (!top->visible)
    return;

  int activeBefore = m_layerManager->getActiveLayerIndex();

  // 1. Capture bottom layer buffer before
  auto bottomBefore = std::make_unique<artflow::ImageBuffer>(*bottom->buffer);

  // 2. Perform composite
  bottom->buffer->composite(*top->buffer, 0, 0, top->opacity);
  bottom->markDirty();

  // 3. Capture bottom layer buffer after
  auto bottomAfter = std::make_unique<artflow::ImageBuffer>(*bottom->buffer);

  // 4. Take top layer
  std::unique_ptr<Layer> topLayer = m_layerManager->takeLayer(index);

  clearRenderCaches();
  int activeAfter = qMax(0, (int)m_layerManager->getLayerCount() - 1);
  m_layerManager->setActiveLayer(activeAfter);
  m_activeLayerIndex = activeAfter;
  emit activeLayerChanged();

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<LayerMergeUndoCommand>(
        m_layerManager, index, std::move(topLayer), index - 1,
        std::move(bottomBefore), std::move(bottomAfter), activeBefore, activeAfter));
  }

  updateLayersList();
  update();
}

void CanvasItem::renameLayer(int index, const QString &name) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    QString oldName = QString::fromStdString(l->name);
    if (oldName != name) {
      if (m_undoManager) {
        m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
            m_layerManager, l->stableId, artflow::LayerProperty::Name, oldName, name));
      }
      l->name = name.toStdString();
      updateLayersList();
    }
  }
}

void CanvasItem::selectPixels(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (!l || !l->buffer)
    return;

  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  m_selectionPath = QPainterPath();
  int w = l->buffer->width();
  int h = l->buffer->height();
  const uint8_t *pixels = l->buffer->data();

  // Scan row by row to find opaque spans
  for (int y = 0; y < h; ++y) {
    int startX = -1;
    for (int x = 0; x < w; ++x) {
      uint8_t alpha = pixels[(y * w + x) * 4 + 3];
      if (alpha > 5) { // Threshold for non-transparency
        if (startX == -1) {
          startX = x;
        }
      } else {
        if (startX != -1) {
          m_selectionPath.addRect(startX, y, x - startX, 1);
          startX = -1;
        }
      }
    }
    if (startX != -1) {
      m_selectionPath.addRect(startX, y, w - startX, 1);
    }
  }

  m_hasSelection = !m_selectionPath.isEmpty();
  emit hasSelectionChanged();
  update();

  auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
    m_selectionPath = path;
    m_hasSelection = hasSel;
    emit hasSelectionChanged();
    if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
    else if (!m_hasSelection && m_marchingAntsTimer)
      m_marchingAntsTimer->stop();
    update();
  };
  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
        updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
  }
}

void CanvasItem::invertLayerColors(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l && l->buffer) {
    int w = l->buffer->width();
    int h = l->buffer->height();
    uint8_t *pixels = l->buffer->data();
    for (int i = 0; i < w * h; ++i) {
      pixels[i * 4] = 255 - pixels[i * 4];       // R
      pixels[i * 4 + 1] = 255 - pixels[i * 4 + 1]; // G
      pixels[i * 4 + 2] = 255 - pixels[i * 4 + 2]; // B
    }
    l->buffer->loadRawData(pixels);
    l->markDirty();
    update();
    updateLayersList();
  }
}

void CanvasItem::toggleReference(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->reference = !l->reference;
    if (l->reference) {
      // Turn off reference for all other layers
      for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
        if (i != index) {
          Layer *other = m_layerManager->getLayer(i);
          if (other) {
            other->reference = false;
          }
        }
      }
    }
    updateLayersList();
  }
}

void CanvasItem::applyEffect(int index, const QString &effect,
                             const QVariantMap &params) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Cannot apply effect to a locked layer",
                               "warning");
    return;
  }
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
          if (l->locked) {
            emit notificationRequested("Background layer is locked", "warning");
            continue;
          }
          // Use natural color order (Red, Green, Blue) for the buffer fill
          l->buffer->fill(newColor.red(), newColor.green(), newColor.blue(),
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
  QString localPath = path;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(path).toLocalFile();
  }

  QFileInfo info(localPath);
  if (!info.exists())
    return false;

  qDebug() << "Loading project (Single File) from:" << localPath;

  QFile file(localPath);
  if (!file.open(QIODevice::ReadOnly)) {
    qWarning() << "Could not open project file for reading";
    return false;
  }

  QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
  file.close();
  QJsonObject obj = doc.object();

  int w = obj["width"].toInt();
  int h = obj["height"].toInt();

  if (w <= 0 || h <= 0) {
    w = 1920;
    h = 1080; // Fallback
  }

  // 1. Reset Canvas
  resizeCanvas(w, h);

  // Load background color
  if (obj.contains("backgroundColor")) {
    setBackgroundColor(obj["backgroundColor"].toString());
  } else {
    setBackgroundColor("white"); // Default to white for backwards compatibility
  }

  // 2. Load Layers from Embedded Data
  QJsonArray layersArray = obj["layers"].toArray();

  if (!layersArray.isEmpty()) {
    // Remove default layer
    if (m_layerManager->getLayerCount() > 0) {
      m_layerManager->removeLayer(0);
    }

    for (const QJsonValue &val : layersArray) {
      QJsonObject layerObj = val.toObject();
      QString name = layerObj["name"].toString();

      // Backwards compatibility: check for old 'file' property to warn user
      // or handle legacy? For now, we assume new format. If "data" is
      // missing, layer will be empty.

      int newIdx = m_layerManager->addLayer(name.toStdString());
      Layer *newLayer = m_layerManager->getLayer(newIdx);

      if (newLayer) {
        newLayer->opacity = (float)layerObj["opacity"].toDouble(1.0);
        newLayer->visible = layerObj["visible"].toBool(true);
        newLayer->locked = layerObj["locked"].toBool(false);
        newLayer->alphaLock = layerObj["alphaLock"].toBool(false);
        newLayer->reference = layerObj["reference"].toBool(false);
        newLayer->blendMode = (BlendMode)layerObj["blendMode"].toInt(0);
        newLayer->type = (Layer::Type)layerObj["type"].toInt(0);

        // Deserializar Screentone
        newLayer->screentoneEnabled = layerObj["screentoneEnabled"].toBool(false);
        newLayer->screentoneDotSize = (float)layerObj["screentoneDotSize"].toDouble(12.0);
        newLayer->screentoneAngle = (float)layerObj["screentoneAngle"].toDouble(0.785);
        newLayer->screentoneContrast = (float)layerObj["screentoneContrast"].toDouble(0.8);
        newLayer->screentoneType = layerObj["screentoneType"].toInt(0);

        // Deserializar Gradient Map
        newLayer->gradientMapEnabled = layerObj["gradientMapEnabled"].toBool(false);
        newLayer->gradientMapPreset = layerObj["gradientMapPreset"].toString("sunset").toStdString();

        if (layerObj.contains("panelPath")) {
          newLayer->panelPath = deserializePath(layerObj["panelPath"].toString());
        }

        // Load Embedded Image Data (Base64)
        QString b64Data = layerObj["data"].toString();
        if (!b64Data.isEmpty()) {
          QByteArray data = QByteArray::fromBase64(b64Data.toLatin1());
          QImage img;
          if (img.loadFromData(data, "PNG")) {
            img = img.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
            if (img.width() == w && img.height() == h) {
              newLayer->buffer->loadRawData(img.constBits());
            } else {
              QImage scaled = img.scaled(w, h, Qt::IgnoreAspectRatio,
                                         Qt::SmoothTransformation);
              scaled =
                  scaled.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
              newLayer->buffer->loadRawData(scaled.constBits());
            }
          }
        }
      }
    }
  }

  // Deserialize Animation
  if (m_animationManager) {
    m_animationManager->clear();
    if (obj.contains("animation")) {
      QJsonObject animObj = obj["animation"].toObject();
      m_animationManager->setFps(animObj["fps"].toInt(24));
      
      QJsonArray tracksArr = animObj["tracks"].toArray();
      for (const QJsonValue& trackVal : tracksArr) {
        QJsonObject trackObj = trackVal.toObject();
        QString trackName = trackObj["name"].toString("Track");
        
        m_animationManager->addTrack(trackName);
        int trackIdx = m_animationManager->getTrackCount() - 1;
        
        QJsonArray keysArr = trackObj["keyframes"].toArray();
        for (const QJsonValue& keyVal : keysArr) {
          QJsonObject keyObj = keyVal.toObject();
          int frame = keyObj["frame"].toInt(0);
          int duration = keyObj["duration"].toInt(1);
          float opacity = (float)keyObj["opacity"].toDouble(1.0);
          QTransform transform = deserializeTransform(keyObj["transform"].toArray());
          uint32_t layerId = (uint32_t)keyObj["layerId"].toInt(-1);
          
          Layer* layer = m_layerManager->getLayerByStableId(layerId);
          if (layer) {
            AnimationFrame frameData(layer, duration, opacity, transform);
            m_animationManager->getTracks()[trackIdx].addKeyframe(frame, frameData);
          }
        }
      }
      m_animationManager->setCurrentFrame(animObj["currentFrame"].toInt(0));
    }
  }

  // Deserialize PerspectiveRuler
  if (m_perspectiveRuler) {
    m_perspectiveRuler->setActive(false);
    m_perspectiveRuler->setType(2);
    m_perspectiveRuler->setVp1(QPointF(-1000.0, 540.0));
    m_perspectiveRuler->setVp2(QPointF(2920.0, 540.0));
    m_perspectiveRuler->setVp3(QPointF(960.0, -2000.0));
    m_perspectiveRuler->setVp1Active(true);
    m_perspectiveRuler->setVp2Active(true);
    m_perspectiveRuler->setVp3Active(true);

    if (obj.contains("perspectiveRuler")) {
      QJsonObject rulerObj = obj["perspectiveRuler"].toObject();
      m_perspectiveRuler->setActive(rulerObj["active"].toBool(false));
      m_perspectiveRuler->setType(rulerObj["type"].toInt(2));
      
      if (rulerObj.contains("vp1")) {
        QJsonObject vp = rulerObj["vp1"].toObject();
        m_perspectiveRuler->setVp1(QPointF(vp["x"].toDouble(-1000.0), vp["y"].toDouble(540.0)));
        m_perspectiveRuler->setVp1Active(vp["active"].toBool(true));
      }
      if (rulerObj.contains("vp2")) {
        QJsonObject vp = rulerObj["vp2"].toObject();
        m_perspectiveRuler->setVp2(QPointF(vp["x"].toDouble(2920.0), vp["y"].toDouble(540.0)));
        m_perspectiveRuler->setVp2Active(vp["active"].toBool(true));
      }
      if (rulerObj.contains("vp3")) {
        QJsonObject vp = rulerObj["vp3"].toObject();
        m_perspectiveRuler->setVp3(QPointF(vp["x"].toDouble(960.0), vp["y"].toDouble(-2000.0)));
        m_perspectiveRuler->setVp3Active(vp["active"].toBool(true));
      }
    }
  }

  m_currentProjectPath = localPath;
  m_currentProjectName = info.baseName();

  emit currentProjectPathChanged();
  emit currentProjectNameChanged();
  updateLayersList();

  setProjectDirty(false);

  emit notificationRequested("Project loaded: " + m_currentProjectName,
                             "success");

  fitToView();
  update();
  return true;
}

bool CanvasItem::saveProject(const QString &pathText) {
  if (pathText.isEmpty())
    return false;

  // SYNC GPU DATA TO CPU BEFORE SAVING
  syncGpuToCpu();

  QString baseDirStr =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/KromoStudioProjects";
  QDir baseDir(baseDirStr);
  if (!baseDir.exists())
    baseDir.mkpath(".");

  QString targetPath = pathText;
  if (!targetPath.contains("/") && !targetPath.contains("\\")) {
    targetPath = baseDir.filePath(targetPath);
  }

  if (!targetPath.endsWith(".stxf") && !targetPath.endsWith(".aflow") && !targetPath.endsWith(".artflow") && !targetPath.endsWith(".kromo") && !targetPath.endsWith(".kstudio")) {
    targetPath += ".kromo";
  }

  qDebug() << "Saving project (Single File) to:" << targetPath;
  QFileInfo info(targetPath);

  // 1. Prepare JSON Data
  QJsonObject obj;
  obj["title"] = info.baseName();
  obj["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
  obj["width"] = m_canvasWidth;
  obj["height"] = m_canvasHeight;
  obj["version"] = 2; // Version 2: Embedded Data
  obj["backgroundColor"] = m_backgroundColor.name(QColor::HexArgb);

  QJsonArray layersArray;
  if (m_layerManager) {
    for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
      Layer *layer = m_layerManager->getLayer(i);
      if (!layer)
        continue;

      QJsonObject layerObj;
      layerObj["name"] = QString::fromStdString(layer->name);
      layerObj["opacity"] = layer->opacity;
      layerObj["visible"] = layer->visible;
      layerObj["locked"] = layer->locked;
      layerObj["alphaLock"] = layer->alphaLock;
      layerObj["reference"] = layer->reference;
      layerObj["blendMode"] = (int)layer->blendMode;
      layerObj["type"] = (int)layer->type;

      // Serializar Screentone
      layerObj["screentoneEnabled"] = layer->screentoneEnabled;
      layerObj["screentoneDotSize"] = layer->screentoneDotSize;
      layerObj["screentoneAngle"] = layer->screentoneAngle;
      layerObj["screentoneContrast"] = layer->screentoneContrast;
      layerObj["screentoneType"] = layer->screentoneType;

      // Serializar Gradient Map
      layerObj["gradientMapEnabled"] = layer->gradientMapEnabled;
      layerObj["gradientMapPreset"] = QString::fromStdString(layer->gradientMapPreset);

      // Embed Image Data as Base64 String
      // Create deep copy for saving
      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
      QBuffer buffer;
      buffer.open(QIODevice::WriteOnly);
      if (img.save(&buffer, "PNG")) {
        QString b64 = QString::fromLatin1(buffer.data().toBase64());
        layerObj["data"] = b64;
        if (!layer->panelPath.isEmpty()) {
          layerObj["panelPath"] = serializePath(layer->panelPath);
        }
        layersArray.append(layerObj);
      } else {
        qWarning() << "Failed to encode layer image";
      }
    }
  }
  obj["layers"] = layersArray;

  // Serialize Animation
  if (m_animationManager) {
    QJsonObject animObj;
    animObj["fps"] = m_animationManager->fps();
    animObj["currentFrame"] = m_animationManager->currentFrame();

    QJsonArray tracksArr;
    for (const auto& track : m_animationManager->getTracks()) {
      QJsonObject trackObj;
      trackObj["name"] = QString::fromStdString(track.getName());

      QJsonArray keysArr;
      for (const auto& pair : track.getKeyframes()) {
        QJsonObject keyObj;
        keyObj["frame"] = pair.first;
        keyObj["duration"] = pair.second.getDuration();
        keyObj["opacity"] = pair.second.getOpacity();
        keyObj["transform"] = serializeTransform(pair.second.getTransform());
        
        Layer* layerRef = pair.second.getLayerRef();
        if (layerRef) {
          keyObj["layerId"] = (int)layerRef->stableId;
        } else {
          keyObj["layerId"] = -1;
        }
        keysArr.append(keyObj);
      }
      trackObj["keyframes"] = keysArr;
      tracksArr.append(trackObj);
    }
    animObj["tracks"] = tracksArr;
    obj["animation"] = animObj;
  }

  // Serialize PerspectiveRuler
  if (m_perspectiveRuler) {
    QJsonObject rulerObj;
    rulerObj["active"] = m_perspectiveRuler->active();
    rulerObj["type"] = m_perspectiveRuler->type();
    
    QJsonObject vp1Obj;
    vp1Obj["x"] = m_perspectiveRuler->vp1().x();
    vp1Obj["y"] = m_perspectiveRuler->vp1().y();
    vp1Obj["active"] = m_perspectiveRuler->vp1Active();
    rulerObj["vp1"] = vp1Obj;

    QJsonObject vp2Obj;
    vp2Obj["x"] = m_perspectiveRuler->vp2().x();
    vp2Obj["y"] = m_perspectiveRuler->vp2().y();
    vp2Obj["active"] = m_perspectiveRuler->vp2Active();
    rulerObj["vp2"] = vp2Obj;

    QJsonObject vp3Obj;
    vp3Obj["x"] = m_perspectiveRuler->vp3().x();
    vp3Obj["y"] = m_perspectiveRuler->vp3().y();
    vp3Obj["active"] = m_perspectiveRuler->vp3Active();
    rulerObj["vp3"] = vp3Obj;

    obj["perspectiveRuler"] = rulerObj;
  }

  // 3. Write Single .stxf File
  QFile file(targetPath);
  if (file.open(QIODevice::WriteOnly)) {

    // Generate Thumbnail (Small, efficiently encoded)
    // Create composite image first
    ImageBuffer composite(m_canvasWidth, m_canvasHeight);
    if (m_layerManager) {
      m_layerManager->compositeAll(composite);
    }

    // 1. Get raw composite image
    QImage imgComp(composite.data(), m_canvasWidth, m_canvasHeight,
                   QImage::Format_RGBA8888_Premultiplied);

    // 2. Calculate target size maintaining Aspect Ratio (Max 600px)
    QSize thumbSize(m_canvasWidth, m_canvasHeight);
    thumbSize.scale(600, 600, Qt::KeepAspectRatio);

    // 3. Create destination image supporting ARGB
    QImage thumbFinal(thumbSize, QImage::Format_ARGB32);

    // 4. Fill with background color (or white if transparent/undefined)
    if (m_backgroundColor.alpha() > 0) {
      thumbFinal.fill(m_backgroundColor);
    } else {
      thumbFinal.fill(Qt::white);
    }

    // 5. Draw scaled image with high quality
    QPainter p(&thumbFinal);
    p.setRenderHint(QPainter::SmoothPixmapTransform);
    p.setRenderHint(QPainter::Antialiasing);

    QImage scaled = imgComp.scaled(thumbSize, Qt::IgnoreAspectRatio,
                                   Qt::SmoothTransformation);
    p.drawImage(0, 0, scaled);
    p.end();

    QBuffer thumbBuf;
    thumbBuf.open(QIODevice::WriteOnly);
    thumbFinal.save(&thumbBuf, "PNG"); // PNG is more reliable for Data URLs
    QString thumbB64 = QString::fromLatin1(thumbBuf.data().toBase64());
    obj["thumbnail"] = thumbB64;

    QJsonDocument doc(obj);
    file.write(doc.toJson(QJsonDocument::Compact));
    file.close();
  } else {
    return false;
  }

  // 4. Update current project path/name
  m_currentProjectPath = targetPath;
  m_currentProjectName = info.baseName();
  emit currentProjectPathChanged();
  emit currentProjectNameChanged();

  // Clean dirty state and remove matching autosave
  setProjectDirty(false);
  if (!targetPath.isEmpty()) {
    QFileInfo saveInfo(targetPath);
    QString autosaveName = saveInfo.completeBaseName() + ".autosave.kromo";
    QFile::remove(QDir(getAutoSaveDir()).filePath(autosaveName));
    QString autosaveNameKStudio = saveInfo.completeBaseName() + ".autosave.kstudio";
    QFile::remove(QDir(getAutoSaveDir()).filePath(autosaveNameKStudio));
    QString autosaveNameAflow = saveInfo.completeBaseName() + ".autosave.aflow";
    QFile::remove(QDir(getAutoSaveDir()).filePath(autosaveNameAflow));
    QString autosaveNameArtflow = saveInfo.completeBaseName() + ".autosave.artflow";
    QFile::remove(QDir(getAutoSaveDir()).filePath(autosaveNameArtflow));
  }
  if (!m_currentProjectName.isEmpty()) {
    QString untitledAutosaveK = "untitled_" + m_currentProjectName + ".autosave.kromo";
    QFile::remove(QDir(getAutoSaveDir()).filePath(untitledAutosaveK));
    QString untitledAutosaveKS = "untitled_" + m_currentProjectName + ".autosave.kstudio";
    QFile::remove(QDir(getAutoSaveDir()).filePath(untitledAutosaveKS));
    QString untitledAutosave = "untitled_" + m_currentProjectName + ".autosave.aflow";
    QFile::remove(QDir(getAutoSaveDir()).filePath(untitledAutosave));
    QString untitledAutosave2 = "untitled_" + m_currentProjectName + ".autosave.artflow";
    QFile::remove(QDir(getAutoSaveDir()).filePath(untitledAutosave2));
  }

  // NOTIFY UI TO REFRESH LISTS
  emit projectListChanged();

  emit notificationRequested("Project saved successfully", "success");
  return true;
}

QVariantList CanvasItem::_scanSync() {
  QVariantList results;
  // Always scan the main project directory for the root lists
  // (Home/Gallery)
  QString path =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/KromoStudioProjects";

  if (!QFileInfo(path).isDir()) {
    QDir().mkpath(path);
  }

  QDir dir(path);
  QFileInfoList entries = dir.entryInfoList(
      QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, QDir::Time);

  for (const QFileInfo &info : entries) {
    if (info.fileName().endsWith(".png") || info.fileName().endsWith(".jpg"))
      continue;
    if (info.fileName().endsWith(".json"))
      continue;

    QString suffix = info.suffix().toLower();
    if (info.isFile() && (suffix == "stxf" || suffix == "aflow" || suffix == "artflow" || suffix == "kromo" || suffix == "kstudio")) {
      QVariantMap item;
      item["name"] = info.completeBaseName();
      item["path"] = info.absoluteFilePath();
      item["type"] = "drawing";
      item["date"] = info.lastModified().toString("dd MMM yyyy");

      QFile f(info.absoluteFilePath());
      if (f.open(QIODevice::ReadOnly)) {
        QByteArray jsonData = f.readAll();
        QJsonDocument doc = QJsonDocument::fromJson(jsonData);
        if (!doc.isNull()) {
          QJsonObject root = doc.object();
          if (root.contains("thumbnail")) {
            QString b64 = root["thumbnail"].toString();
            if (!b64.isEmpty()) {
              item["preview"] = "data:image/png;base64," + b64;
            }
          }
        }
        f.close();
      }
      results.append(item);
    } else if (info.isDir()) {
      QVariantMap item;
      item["name"] = info.fileName();
      item["path"] = info.absoluteFilePath();
      item["type"] = "folder";
      item["date"] = info.lastModified().toString("dd MMM yyyy");

      // Scan folder for internal thumbnails to show the "stack" look
      QDir subDir(info.absoluteFilePath());
      QFileInfoList subEntries = subDir.entryInfoList(QStringList() << "*.kromo" << "*.kstudio" << "*.stxf" << "*.aflow" << "*.artflow",
                                                      QDir::Files, QDir::Time);
      QVariantList thumbs;
      for (int i = 0; i < qMin(subEntries.size(), 3); ++i) {
        QFile f(subEntries[i].absoluteFilePath());
        if (f.open(QIODevice::ReadOnly)) {
          QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
          if (!doc.isNull() && doc.object().contains("thumbnail")) {
            thumbs.append("data:image/png;base64," +
                          doc.object()["thumbnail"].toString());
          }
          f.close();
        }
      }
      item["thumbnails"] = thumbs;
      if (thumbs.size() > 0)
        item["preview"] = thumbs[0]; // Front cover

      results.append(item);
    }
  }
  return results;
}

QVariantList CanvasItem::get_sketchbook_pages(const QString &folderPath) {
  QVariantList results;
  QDir dir(folderPath);
  if (!dir.exists())
    return results;

  QFileInfoList entries =
      dir.entryInfoList(QStringList() << "*.kromo" << "*.kstudio" << "*.stxf" << "*.aflow" << "*.artflow", QDir::Files, QDir::Name);
  for (const QFileInfo &info : entries) {
    QVariantMap item;
    item["name"] = info.completeBaseName();
    item["path"] = QUrl::fromLocalFile(info.absoluteFilePath()).toString();
    item["realPath"] = info.absoluteFilePath();
    item["type"] = "drawing";
    item["date"] = info.lastModified().toString("dd MMM yyyy");

    QFile f(info.absoluteFilePath());
    if (f.open(QIODevice::ReadOnly)) {
      QByteArray data = f.readAll();
      f.close();
      int index = data.indexOf("\"thumbnail\":\"");
      if (index == -1) index = data.indexOf("\"thumbnail\": \"");
      if (index != -1) {
        int startPos = index + (data.at(index + 12) == ' ' ? 14 : 13);
        int endPos = data.indexOf('"', startPos);
        if (endPos != -1) {
          item["preview"] = "data:image/png;base64," + QString::fromLatin1(data.mid(startPos, endPos - startPos));
        }
      }
    }
    results.append(item);
  }
  return results;
}

QString CanvasItem::create_new_sketchbook(const QString &name,
                                          const QString &coverColor) {
  QString baseDirStr =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/KromoStudioProjects";
  QDir baseDir(baseDirStr);
  if (!baseDir.exists())
    baseDir.mkpath(".");

  QString folderPath = baseDirStr + "/" + name;
  QDir dir(folderPath);
  if (!dir.exists()) {
    dir.mkpath(".");
  }

  // Create a manifest.json for metadata
  QJsonObject manifest;
  manifest["name"] = name;
  manifest["type"] = "story";
  manifest["coverColor"] = coverColor;
  manifest["created"] = QDateTime::currentDateTime().toString(Qt::ISODate);

  QFile f(folderPath + "/manifest.json");
  if (f.open(QIODevice::WriteOnly)) {
    QJsonDocument doc(manifest);
    f.write(doc.toJson(QJsonDocument::Compact));
    f.close();
  }

  qDebug() << "[Comic] Created sketchbook at:" << folderPath;
  emit projectListChanged();
  return folderPath;
}

QString CanvasItem::create_new_page(const QString &folderPath,
                                    const QString &pageName) {
  if (folderPath.isEmpty())
    return "";

  QDir dir(folderPath);
  if (!dir.exists())
    return "";

  // Determine page number
  QFileInfoList existing =
      dir.entryInfoList(QStringList() << "*.kromo" << "*.kstudio" << "*.stxf" << "*.aflow" << "*.artflow", QDir::Files, QDir::Name);
  int pageNum = existing.size() + 1;

  QString safeName = pageName;
  if (safeName.isEmpty())
    safeName = "Page";

  QString activeSuffix = "kromo";
  if (!existing.isEmpty()) {
    activeSuffix = existing.first().suffix();
  }

  // Zero-pad for sorting: Page_001.aflow
  QString fileName =
      QString("%1_%2.%3").arg(safeName).arg(pageNum, 3, 10, QChar('0')).arg(activeSuffix);
  QString filePath = dir.absoluteFilePath(fileName);

  // Create a minimal .stxf project file with the current canvas dimensions
  int w = m_canvasWidth > 0 ? m_canvasWidth : 1920;
  int h = m_canvasHeight > 0 ? m_canvasHeight : 1080;

  QJsonObject obj;
  obj["title"] = pageName + " " + QString::number(pageNum);
  obj["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
  obj["width"] = w;
  obj["height"] = h;
  obj["version"] = 2;

  // Create a blank white background layer
  QImage bgImg(w, h, QImage::Format_RGBA8888_Premultiplied);
  if (m_backgroundColor.isValid() && m_backgroundColor.alpha() > 0) {
    bgImg.fill(m_backgroundColor);
  } else {
    bgImg.fill(Qt::white);
  }

  QBuffer bgBuf;
  bgBuf.open(QIODevice::WriteOnly);
  bgImg.save(&bgBuf, "PNG");
  QString bgB64 = QString::fromLatin1(bgBuf.data().toBase64());

  QJsonObject bgLayer;
  bgLayer["name"] = "Background";
  bgLayer["opacity"] = 1.0;
  bgLayer["visible"] = true;
  bgLayer["locked"] = false;
  bgLayer["alphaLock"] = false;
  bgLayer["blendMode"] = 0;
  bgLayer["type"] = 1; // Background type
  bgLayer["data"] = bgB64;

  // Create an empty drawing layer
  QImage drawImg(w, h, QImage::Format_RGBA8888_Premultiplied);
  drawImg.fill(Qt::transparent);

  QBuffer drawBuf;
  drawBuf.open(QIODevice::WriteOnly);
  drawImg.save(&drawBuf, "PNG");
  QString drawB64 = QString::fromLatin1(drawBuf.data().toBase64());

  QJsonObject drawLayer;
  drawLayer["name"] = "Layer 1";
  drawLayer["opacity"] = 1.0;
  drawLayer["visible"] = true;
  drawLayer["locked"] = false;
  drawLayer["alphaLock"] = false;
  drawLayer["blendMode"] = 0;
  drawLayer["type"] = 0;
  drawLayer["data"] = drawB64;

  QJsonArray layers;
  layers.append(bgLayer);
  layers.append(drawLayer);
  obj["layers"] = layers;

  // Generate a simple thumbnail (white/bg colored canvas)
  QImage thumbImg = bgImg.scaled(QSize(300, 300), Qt::KeepAspectRatio,
                                 Qt::SmoothTransformation);
  QBuffer thumbBuf;
  thumbBuf.open(QIODevice::WriteOnly);
  thumbImg.save(&thumbBuf, "PNG");
  QString thumbB64 = QString::fromLatin1(thumbBuf.data().toBase64());
  obj["thumbnail"] = thumbB64;

  // Write the file
  QFile file(filePath);
  if (file.open(QIODevice::WriteOnly)) {
    QJsonDocument doc(obj);
    file.write(doc.toJson(QJsonDocument::Compact));
    file.close();
    qDebug() << "[Comic] Created page:" << filePath;
    return filePath;
  }

  return "";
}

bool CanvasItem::duplicatePage(const QString &sourcePath) {
  QString localPath = sourcePath;
  if (localPath.startsWith("file:///"))
    localPath = QUrl(sourcePath).toLocalFile();

  QFileInfo fileInfo(localPath);
  if (!fileInfo.exists()) {
    qDebug() << "[Comic] duplicatePage: source file does not exist:" << localPath;
    return false;
  }

  QDir dir = fileInfo.dir();
  QString baseName = fileInfo.completeBaseName(); // e.g. "Page_002"
  QString activeSuffix = fileInfo.suffix();
  
  int lastUnderscore = baseName.lastIndexOf('_');
  QString prefix = "Page";
  int sourceNum = 0;
  bool ok = false;
  
  if (lastUnderscore != -1) {
    prefix = baseName.left(lastUnderscore);
    sourceNum = baseName.mid(lastUnderscore + 1).toInt(&ok);
  }

  QFileInfoList existing = dir.entryInfoList(QStringList() << "*.kromo" << "*.kstudio" << "*.stxf" << "*.aflow" << "*.artflow", QDir::Files, QDir::Name);

  if (lastUnderscore == -1 || !ok) {
    int nextNum = existing.size() + 1;
    QString destFileName = QString("Page_%1.%2").arg(nextNum, 3, 10, QChar('0')).arg(activeSuffix);
    QString destPath = dir.absoluteFilePath(destFileName);
    return QFile::copy(localPath, destPath);
  }

  // Shift pages starting from the highest index down to sourceNum + 1.
  for (int i = existing.size(); i >= sourceNum + 1; --i) {
    QString oldFileName = QString("%1_%2.%3").arg(prefix).arg(i, 3, 10, QChar('0')).arg(activeSuffix);
    QString newFileName = QString("%1_%2.%3").arg(prefix).arg(i + 1, 3, 10, QChar('0')).arg(activeSuffix);
    
    QString oldPath = dir.absoluteFilePath(oldFileName);
    QString newPath = dir.absoluteFilePath(newFileName);
    
    if (QFile::exists(oldPath)) {
      if (!QFile::rename(oldPath, newPath)) {
        qDebug() << "[Comic] duplicatePage: failed to rename" << oldPath << "to" << newPath;
        return false;
      }
    }
  }

  QString destFileName = QString("%1_%2.%3").arg(prefix).arg(sourceNum + 1, 3, 10, QChar('0')).arg(activeSuffix);
  QString destPath = dir.absoluteFilePath(destFileName);

  if (!QFile::copy(localPath, destPath)) {
    qDebug() << "[Comic] duplicatePage: failed to copy" << localPath << "to" << destPath;
    return false;
  }

  QFile destFile(destPath);
  if (destFile.open(QIODevice::ReadWrite)) {
    QJsonDocument doc = QJsonDocument::fromJson(destFile.readAll());
    if (!doc.isNull() && doc.isObject()) {
      QJsonObject obj = doc.object();
      obj["title"] = prefix + " " + QString::number(sourceNum + 1);
      obj["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
      
      destFile.seek(0);
      destFile.resize(0);
      destFile.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
    }
    destFile.close();
  }

  qDebug() << "[Comic] Page duplicated successfully to:" << destPath;
  return true;
}

bool CanvasItem::reorderPages(const QString &folderPath, const QVariantList &newPathsOrder) {
  QString localFolder = folderPath;
  if (localFolder.startsWith("file:///"))
    localFolder = QUrl(folderPath).toLocalFile();

  QDir dir(localFolder);
  if (!dir.exists()) {
    qDebug() << "[Comic] reorderPages: folder does not exist:" << localFolder;
    return false;
  }

  QStringList resolvedPaths;
  for (const QVariant &varPath : newPathsOrder) {
    QString p = varPath.toString();
    if (p.startsWith("file:///"))
      p = QUrl(p).toLocalFile();
    resolvedPaths.append(p);
  }

  QStringList tempPaths;
  for (int i = 0; i < resolvedPaths.size(); ++i) {
    QString srcPath = resolvedPaths[i];
    QFileInfo srcInfo(srcPath);
    if (!srcInfo.exists()) {
      qDebug() << "[Comic] reorderPages: source file does not exist:" << srcPath;
      return false;
    }
    
    QString ext = srcInfo.suffix();
    QString tempName = QString("reorder_temp_%1_%2.%3.tmp").arg(QDateTime::currentMSecsSinceEpoch()).arg(i).arg(ext);
    QString tempPath = dir.absoluteFilePath(tempName);
    
    if (!QFile::rename(srcPath, tempPath)) {
      qDebug() << "[Comic] reorderPages: failed to rename" << srcPath << "to temp" << tempPath;
      for (const QString &t : tempPaths) {
        QFile::remove(t);
      }
      return false;
    }
    tempPaths.append(tempPath);
  }

  for (int i = 0; i < tempPaths.size(); ++i) {
    QString tempPath = tempPaths[i];
    QFileInfo tempInfo(tempPath);
    QString ext = QFileInfo(tempInfo.completeBaseName()).suffix();
    if (ext.isEmpty()) ext = "kromo";
    
    QString finalFileName = QString("Page_%1.%2").arg(i + 1, 3, 10, QChar('0')).arg(ext);
    QString finalPath = dir.absoluteFilePath(finalFileName);
    
    if (QFile::exists(finalPath)) {
      QFile::remove(finalPath);
    }
    
    if (!QFile::rename(tempPath, finalPath)) {
      qDebug() << "[Comic] reorderPages: failed to rename temp" << tempPath << "to final" << finalPath;
      return false;
    }

    QFile destFile(finalPath);
    if (destFile.open(QIODevice::ReadWrite)) {
      QJsonDocument doc = QJsonDocument::fromJson(destFile.readAll());
      if (!doc.isNull() && doc.isObject()) {
        QJsonObject obj = doc.object();
        obj["title"] = QString("Page %1").arg(i + 1);
        obj["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
        
        destFile.seek(0);
        destFile.resize(0);
        destFile.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
      }
      destFile.close();
    }
  }

  qDebug() << "[Comic] Pages reordered successfully in:" << localFolder;
  return true;
}

bool CanvasItem::exportPageImage(const QString &projectPath,
                                 const QString &outputPath,
                                 const QString &format) {
  QString localPath = projectPath;
  if (localPath.startsWith("file:///"))
    localPath = QUrl(projectPath).toLocalFile();

  QString localOutput = outputPath;
  if (localOutput.startsWith("file:///"))
    localOutput = QUrl(outputPath).toLocalFile();

  QFile file(localPath);
  if (!file.open(QIODevice::ReadOnly))
    return false;

  QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
  file.close();
  QJsonObject obj = doc.object();

  int w = obj["width"].toInt(1920);
  int h = obj["height"].toInt(1080);

  if (w <= 0 || h <= 0)
    return false;

  // Reconstruct composite image from layers
  QImage composite(w, h, QImage::Format_RGBA8888_Premultiplied);
  composite.fill(Qt::transparent);

  QPainter painter(&composite);
  painter.setRenderHint(QPainter::SmoothPixmapTransform);

  QJsonArray layersArr = obj["layers"].toArray();
  for (const QJsonValue &val : layersArr) {
    QJsonObject layerObj = val.toObject();
    if (!layerObj["visible"].toBool(true))
      continue;

    float opacity = (float)layerObj["opacity"].toDouble(1.0);
    QString b64Data = layerObj["data"].toString();
    if (b64Data.isEmpty())
      continue;

    QByteArray data = QByteArray::fromBase64(b64Data.toLatin1());
    QImage layerImg;
    if (layerImg.loadFromData(data, "PNG")) {
      if (layerImg.width() != w || layerImg.height() != h) {
        layerImg = layerImg.scaled(w, h, Qt::IgnoreAspectRatio,
                                   Qt::SmoothTransformation);
      }
      painter.setOpacity(opacity);
      painter.drawImage(0, 0, layerImg);
    }
  }
  painter.end();

  bool success =
      composite.save(localOutput, format.toUpper().toStdString().c_str());
  if (success) {
    qDebug() << "[Comic Export] Exported page to:" << localOutput;
  } else {
    qWarning() << "[Comic Export] Failed to export page to:" << localOutput;
  }
  return success;
}

bool CanvasItem::exportAllPages(const QString &folderPath,
                                const QString &outputDir,
                                const QString &format) {
  QString localFolder = folderPath;
  if (localFolder.startsWith("file:///"))
    localFolder = QUrl(folderPath).toLocalFile();

  QString localOutput = outputDir;
  if (localOutput.startsWith("file:///"))
    localOutput = QUrl(outputDir).toLocalFile();

  QDir dir(localFolder);
  if (!dir.exists())
    return false;

  QDir outDir(localOutput);
  if (!outDir.exists())
    outDir.mkpath(".");

  QFileInfoList entries =
      dir.entryInfoList(QStringList() << "*.kromo" << "*.kstudio" << "*.stxf" << "*.aflow" << "*.artflow", QDir::Files, QDir::Name);

  int exportCount = 0;
  QString ext = format.toLower();
  if (ext != "png" && ext != "jpg" && ext != "jpeg")
    ext = "png";

  for (const QFileInfo &info : entries) {
    QString outPath =
        outDir.absoluteFilePath(info.completeBaseName() + "." + ext);
    if (exportPageImage(info.absoluteFilePath(), outPath, format)) {
      exportCount++;
    }
  }

  qDebug() << "[Comic Export] Exported" << exportCount << "pages to"
           << localOutput;
  emit notificationRequested(QString("Exported %1 pages").arg(exportCount),
                             "success");
  return exportCount > 0;
}

bool CanvasItem::deleteProject(const QString &path) {
  if (path.isEmpty())
    return false;
  QString localPath = QUrl(path).toLocalFile();
  if (localPath.isEmpty())
    localPath = path;

  QFileInfo info(localPath);
  QString dirPath = info.absolutePath();

  if (QFile::remove(localPath)) {
    // Cleanup if the folder is now empty (and not the root)
    QString rootPath =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
        "/KromoStudioProjects";
    QDir dir(dirPath);
    if (dirPath != rootPath && dir.exists() &&
        dir.entryList(QDir::NoDotAndDotDot | QDir::AllEntries).isEmpty()) {
      dir.rmdir(".");
    }

    emit projectListChanged();
    return true;
  }
  return false;
}

bool CanvasItem::deleteFolder(const QString &path) {
  if (path.isEmpty())
    return false;
  QString localPath = QUrl(path).toLocalFile();
  if (localPath.isEmpty())
    localPath = path;

  QDir dir(localPath);
  if (dir.exists() && dir.removeRecursively()) {
    emit projectListChanged();
    return true;
  }
  return false;
}
bool CanvasItem::rename_item(const QString &path, const QString &newName) {
  if (path.isEmpty() || newName.isEmpty())
    return false;
  QString localPath = QUrl(path).toLocalFile();
  if (localPath.isEmpty())
    localPath = path;

  QFileInfo info(localPath);
  if (!info.exists())
    return false;

  QString newPath;
  if (info.isFile()) {
    newPath = info.absolutePath() + "/" + newName + "." + info.suffix();
  } else {
    QDir parentDir = info.dir();
    newPath = parentDir.absoluteFilePath(newName);
  }

  if (QFile::rename(localPath, newPath)) {
    emit projectListChanged();
    return true;
  }
  return false;
}

bool CanvasItem::moveProjectOutOfFolder(const QString &path) {
  if (path.isEmpty())
    return false;
  QString localPath = QUrl(path).toLocalFile();
  if (localPath.isEmpty())
    localPath = path;

  QFileInfo info(localPath);
  if (!info.exists())
    return false;

  QString sourceDirPath = info.absolutePath();
  // Root KromoStudioProjects path
  QString rootPath =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/KromoStudioProjects";
  QString newPath = rootPath + "/" + info.fileName();

  if (QFile::rename(localPath, newPath)) {
    // Cleanup if the source folder is now empty (and not the root)
    QDir dir(sourceDirPath);
    if (sourceDirPath != rootPath && dir.exists() &&
        dir.entryList(QDir::NoDotAndDotDot | QDir::AllEntries).isEmpty()) {
      dir.rmdir(".");
    }

    emit projectListChanged();
    return true;
  }
  return false;
}

bool CanvasItem::saveProjectAs(const QString &path) {
  return saveProject(path);
}

bool CanvasItem::exportImage(const QString &path, const QString &format) {
  if (!m_layerManager)
    return false;

  QString localPath = path;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(path).toLocalFile();
  }

  if (format.toUpper() == "PSD" || localPath.endsWith(".psd", Qt::CaseInsensitive)) {
    syncGpuToCpu();
    return exportPSD(localPath);
  }

  // Create a composite image
  ImageBuffer composite(m_canvasWidth, m_canvasHeight);
  m_layerManager->compositeAll(composite);

  // Use ARGB32_Premultiplied which is standard for QImage unless you're
  // sure about RGBA8888 byte order Create a deep copy to ensure the image
  // owns its data
  QImage img = QImage(composite.data(), m_canvasWidth, m_canvasHeight,
                      QImage::Format_RGBA8888_Premultiplied)
                   .copy();

  qDebug() << "Exporting image to:" << localPath;
  bool success = img.save(localPath, format.toUpper().toStdString().c_str());
  if (!success)
    qDebug() << "Failed to save image to:" << localPath;
  return success;
}

bool CanvasItem::importImageAsLayer(const QString &path) {
  qDebug() << "[importImageAsLayer] ENTER path=" << path;

  if (!m_layerManager) {
    qDebug() << "[importImageAsLayer] FAIL - no layer manager";
    return false;
  }

  int canvasW = m_canvasWidth;
  int canvasH = m_canvasHeight;
  qDebug() << "[importImageAsLayer] canvas size =" << canvasW << "x" << canvasH;
  if (canvasW <= 0 || canvasH <= 0) {
    qDebug() << "[importImageAsLayer] FAIL - invalid canvas size";
    emit notificationRequested("Canvas sin tamaño válido", "error");
    return false;
  }

  // Resolve file:/// URL → local path robustly
  QString localPath = path;
  if (localPath.startsWith("file:", Qt::CaseInsensitive))
    localPath = QUrl(path).toLocalFile();

  qDebug() << "[importImageAsLayer] resolved localPath =" << localPath;

  // ── Load the image (PNG, JPG, BMP, TIFF, WebP …) ─────────────────────────
  QImage src;
  if (!src.load(localPath)) {
    qWarning() << "[importImageAsLayer] Failed to load:" << localPath;
    emit notificationRequested("No se pudo cargar la imagen", "error");
    return false;
  }
  qDebug() << "[importImageAsLayer] loaded image" << src.size();

  // ── Build a canvas-sized RGBA8888_Premultiplied image (transparent background) ──
  // The source image is scaled to fit inside the canvas keeping aspect ratio,
  // then centred on a transparent canvas-sized image.
  QImage canvas(canvasW, canvasH, QImage::Format_RGBA8888_Premultiplied);
  canvas.fill(Qt::transparent);

  QImage scaled = src.scaled(canvasW, canvasH,
                              Qt::KeepAspectRatio,
                              Qt::SmoothTransformation)
                     .convertToFormat(QImage::Format_RGBA8888_Premultiplied);

  int offsetX = (canvasW - scaled.width())  / 2;
  int offsetY = (canvasH - scaled.height()) / 2;

  // Blit the scaled image into the transparent canvas with direct copy (Source mode)
  QPainter p(&canvas);
  p.setCompositionMode(QPainter::CompositionMode_Source);
  p.drawImage(offsetX, offsetY, scaled);
  p.end();

  // ── Smart Layer Stacking and Comic Panel integration ──────────────────────
  int activeIdx = m_layerManager->getActiveLayerIndex();
  int totalLayers = m_layerManager->getLayerCount();
  artflow::Layer *activeLayer = m_layerManager->getLayer(activeIdx);

  bool shouldClip = false;
  int targetIdx = totalLayers; // default: top of the stack

  if (activeLayer) {
    QString activeName = QString::fromStdString(activeLayer->name);
    if (activeLayer->clipped) {
      shouldClip = true;
      targetIdx = activeIdx + 1;
    } else if (activeName.startsWith("Panel ", Qt::CaseInsensitive)) {
      shouldClip = true;
      targetIdx = activeIdx + 1;
    } else {
      shouldClip = false;
      targetIdx = activeIdx + 1;
    }
  }

  if (targetIdx < 0) targetIdx = 0;
  if (targetIdx > totalLayers) targetIdx = totalLayers;

  // ── Add the new layer and load its pixel data ──────────────────────────────
  int addedIdx = m_layerManager->addLayer("Imported Image");
  qDebug() << "[importImageAsLayer] addLayer returned index" << addedIdx;
  Layer *layer = m_layerManager->getLayer(addedIdx);
  if (!layer || !layer->buffer) {
    qDebug() << "[importImageAsLayer] FAIL - layer or buffer is null";
    emit notificationRequested("Error al crear la capa", "error");
    return false;
  }

  // loadRawData is a single memcpy-style bulk load
  qDebug() << "[importImageAsLayer] loading raw data...";
  layer->buffer->loadRawData(canvas.constBits());
  layer->clipped = shouldClip;
  layer->markDirty();
  qDebug() << "[importImageAsLayer] raw data loaded, dirty marked";

  // Move layer to the correct contextual stacking position
  if (addedIdx != targetIdx) {
    qDebug() << "[importImageAsLayer] moving layer from" << addedIdx << "to" << targetIdx;
    m_layerManager->moveLayer(addedIdx, targetIdx);
  }

  // Make this the active layer with full QML signal synchronization
  setActiveLayer(targetIdx);

  QString baseName = QFileInfo(localPath).fileName();
  qDebug() << "[importImageAsLayer] OK -" << localPath
           << "→ layer" << targetIdx
           << "(" << canvasW << "x" << canvasH << ") | clipped:" << shouldClip;

  requestUpdate();
  emit notificationRequested("✓ Imagen importada: " + baseName, "success");
  return true;
}

bool CanvasItem::importABR(const QString &path) {
  // ── Resolve local path robustly ───────────────────────────────────────────
  QString localPath = path;
  if (localPath.startsWith("file:", Qt::CaseInsensitive))
    localPath = QUrl(path).toLocalFile();
  if (localPath.isEmpty() || !QFile::exists(localPath)) {
    emit notificationRequested("Archivo ABR no encontrado: " + localPath, "error");
    return false;
  }

  // ── Quick validation (magic bytes) ─────────────────────────────────────────
  if (!ABRParser::isValidABR(localPath)) {
    emit notificationRequested("El archivo no es un ABR válido.", "error");
    return false;
  }

  // ── Start async import ────────────────────────────────────────────────────
  m_isImporting    = true;
  m_importProgress = 0.0f;
  emit isImportingChanged();
  emit importProgressChanged();

  // Cache directory: <AppData>/ArtFlow/brush_cache/<pack_name>/
  QString packName  = QFileInfo(localPath).completeBaseName();
  QString cacheBase = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                      + "/brush_cache/" + packName;

  // Run the heavy work off the UI thread
  QFutureWatcher<ABRFile> *watcher = new QFutureWatcher<ABRFile>(this);

  connect(watcher, &QFutureWatcher<ABRFile>::finished, this,
      [this, watcher, packName, cacheBase, localPath]() {
        ABRFile result = watcher->result();
        watcher->deleteLater();

        if (result.brushes.empty()) {
          m_isImporting = false;
          emit isImportingChanged();
          emit notificationRequested("No se encontraron pinceles en el archivo ABR.", "warning");
          return;
        }

        // ── Export tips to cache (still on UI thread but fast — tips already decoded) ──
        int exported = ABRParser::exportToCache(result, cacheBase,
            [this, &result](int done, int total) {
              m_importProgress = total > 0 ? static_cast<float>(done) / total : 1.0f;
              emit importProgressChanged();
              QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
            });

        // ── Register with BrushPresetManager ──────────────────────────────────
        auto *bpm = artflow::BrushPresetManager::instance();
        QString category = packName; // group name = file name

        for (const ABRBrush &abr : result.brushes) {
          artflow::BrushPreset preset;
          preset.uuid     = artflow::BrushPreset::generateUUID();
          preset.name     = (abr.name.isEmpty()
                              ? QString("Brush %1×%2").arg(abr.patternWidth).arg(abr.patternHeight)
                              : abr.name);
          preset.category = category;
          preset.author   = "Imported (ABR)";
          preset.version  = 1;

          // Dimensions: Use a standard comfortable default size (40px) so the brush isn't giant/random on start.
          // The native resolution serves as the maximum brush limit.
          preset.defaultSize = 40.0f;
          preset.maxSize     = std::max(static_cast<float>(std::max(abr.patternWidth, abr.patternHeight)), 150.0f);

          // Shape: use cached PNG as tip texture
          if (!abr.cachePath.isEmpty())
            preset.shape.tipTexture = abr.cachePath;

          // Stroke properties from ABR metadata - clamp spacing to artist-friendly ranges (5% to 15%)
          // for continuous organic lines instead of blocky isolated stamps.
          preset.stroke.spacing   = std::clamp(abr.spacing, 0.03f, 0.15f);
          preset.shape.roundness  = std::max(0.05f, abr.roundness);
          preset.shape.rotation   = abr.angle;

          // Auto-detect directional brushes (Angle Jitter / Follow Stroke)
          // Many Photoshop brushes are designed to follow the stroke direction if they aren't round.
          float aspectRatio = static_cast<float>(std::min(abr.patternWidth, abr.patternHeight)) / 
                              static_cast<float>(std::max(abr.patternWidth, abr.patternHeight));
          
          if (abr.roundness < 0.9f || aspectRatio < 0.9f) {
              preset.shape.followStroke = true;
          }

          // Enable rich dynamics (Pressure Sensitivity) out of the box
          // 1. Size Dynamics: brush shrinks on light pressure
          preset.sizeDynamics.baseValue = 1.0f;
          preset.sizeDynamics.minLimit  = 0.15f; // min 15% size on light touch
          preset.sizeDynamics.pressureCurve = artflow::ResponseCurve::easeIn();

          // 2. Opacity/Flow Dynamics: brush gets lighter on soft touch
          preset.flowDynamics.baseValue = 1.0f;
          preset.flowDynamics.minLimit  = 0.20f; // min 20% flow on light touch
          preset.flowDynamics.pressureCurve = artflow::ResponseCurve::linear();

          preset.opacityDynamics.baseValue = 1.0f;
          preset.opacityDynamics.minLimit  = 0.50f;
          preset.opacityDynamics.pressureCurve = artflow::ResponseCurve::linear();

          bpm->addPreset(preset);
        }

        // ── Persist new presets to user's brush directory ──────────────────────
        QString brushDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                           + "/brushes/" + packName;
        QDir().mkpath(brushDir);
        for (const auto *p : bpm->presetsInCategory(category)) {
          bpm->savePreset(*p, brushDir);
        }

        m_isImporting    = false;
        m_importProgress = 1.0f;
        emit isImportingChanged();
        emit importProgressChanged();
        emit availableBrushesChanged();
        emit brushCategoriesChanged();

        emit notificationRequested(
            QString("✓ %1 pinceles importados de \"%2\"")
                .arg(result.brushes.size())
                .arg(packName),
            "success");

        qDebug() << "[importABR] Imported" << result.brushes.size()
                 << "brushes from" << localPath
                 << "| cached:" << exported << "tips to" << cacheBase;
      });

  // Parse on background thread (non-blocking)
  QFuture<ABRFile> future = QtConcurrent::run([localPath]() {
    return ABRParser::parse(localPath);
  });
  watcher->setFuture(future);

  return true;
}

void CanvasItem::updateTransformProperties(float x, float y, float scale,
                                           float rotation, float w, float h) {
  if (!m_isTransforming)
    return;

  m_transformMatrix = QTransform();

  // Current center (based on manipulator position on Canvas)
  float newCx = x + w / 2.0f;

  // Use standard non-inverted vertical center mapping matching the horizontal mapping
  float newCy = y + h / 2.0f;

  // Apply differential scaling based on free-transform handle manipulation
  float scaleX = w / std::max(1.0f, (float)m_transformBox.width());
  float scaleY = h / std::max(1.0f, (float)m_transformBox.height());

  // To apply operations in the logical order (Centering -> Scale -> Rotate -> Translate),
  // we must call them in the REVERSE order because QTransform pre-multiplies convenience functions:

  // 1. Translate to the target center on the canvas (called 1st, applied last)
  m_transformMatrix.translate(newCx, newCy);

  // 2. Rotate around the local center (called 2nd, applied 3rd)
  m_transformMatrix.rotate(rotation);

  // 3. Scale relative to the local center (called 3rd, applied 2nd)
  m_transformMatrix.scale(scale * scaleX, scale * scaleY);

  // 4. Move local coordinates to center around (0,0) (called last, applied 1st)
  m_transformMatrix.translate(-m_transformBox.width() / 2.0f,
                              -m_transformBox.height() / 2.0f);

  qDebug() << "[TransformDebug] QML Input: x=" << x << "y=" << y << "w=" << w << "h=" << h
           << "| Box: x=" << m_transformBox.x() << "y=" << m_transformBox.y() << "w=" << m_transformBox.width() << "h=" << m_transformBox.height()
           << "| Computed: Cx=" << newCx << "Cy=" << newCy
           << "| Matrix translation: tx=" << m_transformMatrix.dx() << "ty=" << m_transformMatrix.dy();

  update();
}

void CanvasItem::updateLayersList() {
  if (!m_layerManager)
    return;

  QVariantList layerList;
  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    Layer *l = m_layerManager->getLayer(i);
    if (!l)
      continue;
    QVariantMap layer;
    layer["layerId"] = i;
    layer["name"] = QString::fromStdString(l->name);
    layer["visible"] = l->visible;
    layer["opacity"] = l->opacity;
    layer["locked"] = l->locked;
    layer["alpha_lock"] = l->alphaLock;
    layer["clipped"] = l->clipped;
    layer["is_private"] = l->isPrivate;
    layer["reference"] = l->reference;
    layer["active"] = (i == m_activeLayerIndex);
    layer["stableId"] = (int)l->stableId;
    layer["parentId"] = l->parentId;
    layer["screentoneEnabled"] = l->screentoneEnabled;
    layer["screentoneDotSize"] = l->screentoneDotSize;
    layer["screentoneAngle"] = l->screentoneAngle;
    layer["screentoneContrast"] = l->screentoneContrast;
    layer["screentoneType"] = l->screentoneType;
    layer["gradientMapEnabled"] = l->gradientMapEnabled;
    layer["gradientMapPreset"] = QString::fromStdString(l->gradientMapPreset);

    // Correctly map the Layer::Type enum
    if (l->type == Layer::Type::Group) {
      layer["type"] = QString("group");
    } else if (l->type == Layer::Type::Vector) {
      layer["type"] = QString("vector");
    } else if (l->type == Layer::Type::Background || i == 0) {
      layer["type"] = QString("background");
    } else {
      layer["type"] = QString("drawing");
    }

    // Calculate depth
    int depth = 0;
    int pId = l->parentId;
    while (pId != -1) {
      depth++;
      bool found = false;
      for (int j = 0; j < m_layerManager->getLayerCount(); ++j) {
        Layer *pLayer = m_layerManager->getLayer(j);
        if (pLayer && (int)pLayer->stableId == pId) {
          pId = pLayer->parentId;
          found = true;
          break;
        }
      }
      if (!found || depth > 20)
        break; // Safety break
    }

    layer["depth"] = depth;
    layer["expanded"] = l->expanded;

    // Check if all parents are expanded
    bool parentExpanded = true;
    int checkId = l->parentId;
    int iterations = 0;
    while (checkId != -1) {
      bool foundParent = false;
      for (int j = 0; j < m_layerManager->getLayerCount(); ++j) {
        Layer *pLayer = m_layerManager->getLayer(j);
        if (pLayer && (int)pLayer->stableId == checkId) {
          if (!pLayer->expanded) {
            parentExpanded = false;
            break;
          }
          checkId = pLayer->parentId;
          foundParent = true;
          break;
        }
      }
      // Safety check to prevent infinite loop
      if (++iterations > 20)
        break;
      if (!parentExpanded || !foundParent)
        break;
    }
    layer["parentExpanded"] = parentExpanded;

    if (i == 0)
      layer["bgColor"] = m_backgroundColor.name();

    // Convert internal BlendMode enum back to string for QML
    QString bModeStr = "Normal";
    switch (l->blendMode) {
    case BlendMode::Multiply:
      bModeStr = "Multiply";
      break;
    case BlendMode::Screen:
      bModeStr = "Screen";
      break;
    case BlendMode::Overlay:
      bModeStr = "Overlay";
      break;
    case BlendMode::Darken:
      bModeStr = "Darken";
      break;
    case BlendMode::Lighten:
      bModeStr = "Lighten";
      break;
    case BlendMode::ColorDodge:
      bModeStr = "Color Dodge";
      break;
    case BlendMode::ColorBurn:
      bModeStr = "Color Burn";
      break;
    case BlendMode::SoftLight:
      bModeStr = "Soft Light";
      break;
    case BlendMode::HardLight:
      bModeStr = "Hard Light";
      break;
    case BlendMode::Difference:
      bModeStr = "Difference";
      break;
    case BlendMode::Exclusion:
      bModeStr = "Exclusion";
      break;
    case BlendMode::Hue:
      bModeStr = "Hue";
      break;
    case BlendMode::Saturation:
      bModeStr = "Saturation";
      break;
    case BlendMode::Color:
      bModeStr = "Color";
      break;
    case BlendMode::Luminosity:
      bModeStr = "Luminosity";
      break;
    case BlendMode::GlowDodge:
      bModeStr = "GlowDodge";
      break;
    case BlendMode::HardMix:
      bModeStr = "HardMix";
      break;
    case BlendMode::Divide:
      bModeStr = "Divide";
      break;
    default:
      bModeStr = "Normal";
    }
    layer["blendMode"] = bModeStr;

    // Add thumbnail for ALL layers
    if (l->buffer && l->buffer->width() > 0 && l->buffer->height() > 0) {
      QString b64;
      bool needsUpdate = true;

      // OPTIMIZATION: Only regenerate the active layer to keep UI responsive.
      // We look up the previous thumbnail in m_layerModel using the layer name.
      if (i != m_activeLayerIndex && !m_layerModel.isEmpty()) {
        for (const QVariant &v : m_layerModel) {
          QVariantMap oldLayer = v.toMap();
          if (oldLayer["name"].toString() == QString::fromStdString(l->name)) {
            QString oldThumb = oldLayer["thumbnail"].toString();
            if (oldThumb.startsWith("data:image/png;base64,")) {
              b64 = oldThumb;
              needsUpdate = false;
            }
            break;
          }
        }
      }

      if (needsUpdate) {
        int tw = 60, th = 40;
        if (l->buffer->width() > 0 && l->buffer->height() > 0) {
          QImage thumb(tw, th, QImage::Format_RGBA8888_Premultiplied);
          int dx = std::max(1, l->buffer->width() / tw);
          int dy = std::max(1, l->buffer->height() / th);
          const uint32_t *src =
              reinterpret_cast<const uint32_t *>(l->buffer->data());
          uint32_t *dst = reinterpret_cast<uint32_t *>(thumb.bits());

          for (int y = 0; y < th; ++y) {
            int sy = dy * y;
            if (sy >= l->buffer->height())
              sy = l->buffer->height() - 1;
            int rowOffset = sy * l->buffer->width();
            for (int x = 0; x < tw; ++x) {
              int sx = dx * x;
              if (sx >= l->buffer->width())
                sx = l->buffer->width() - 1;
              dst[y * tw + x] = src[rowOffset + sx];
            }
          }

          QByteArray ba;
          QBuffer buffer(&ba);
          buffer.open(QIODevice::WriteOnly);
          thumb.save(&buffer, "PNG");
          b64 = "data:image/png;base64," + QString::fromLatin1(ba.toBase64());
        }
      }

      layer["thumbnail"] = b64;
    } else {
      layer["thumbnail"] = "";
    }

    layerList.prepend(layer);
  }
  m_layerModel = layerList;
  emit layersChanged(layerList);
  emit canvasPreviewChanged();
}

void CanvasItem::resizeCanvas(int w, int h) {
  resetTransformState();
  setCurrentTool("brush");

  m_canvasWidth = w;
  m_canvasHeight = h;

  // Invalidar el motor de acuarela al cambiar el tamaño del canvas.
  // Los FBOs del WetMap son del tamaño anterior y ya no son válidos.
  if (m_watercolorEngine) {
      m_watercolorEngine->endSession();
      // beginSession() se llamará automáticamente al próximo dab.
  }

  delete m_layerManager;
  clearRenderCaches();
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

void CanvasItem::clearProjectPath() {
  m_currentProjectPath = "";
  m_currentProjectName = "Untitled";
  emit currentProjectPathChanged();
  emit currentProjectNameChanged();
}

void CanvasItem::setProjectDpi(int dpi) { qDebug() << "DPI set to" << dpi; }

void CanvasItem::drawPanelLayout(const QString &layoutType, int gutterPx,
                                 int borderPx, int marginPx) {
  if (!m_layerManager)
    return;

  // Create a new layer for panels
  int panelLayerIdx = m_layerManager->addLayer("Panels");
  Layer *panelLayer = m_layerManager->getLayer(panelLayerIdx);
  if (!panelLayer || !panelLayer->buffer)
    return;

  m_activeLayerIndex = panelLayerIdx;
  m_layerManager->setActiveLayer(panelLayerIdx);

  int w = m_canvasWidth;
  int h = m_canvasHeight;

  QImage img(panelLayer->buffer->data(), w, h,
             QImage::Format_RGBA8888_Premultiplied);
  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);

  // Panel border pen (black, professional manga line)
  QPen borderPen(Qt::black, borderPx, Qt::SolidLine, Qt::SquareCap,
                 Qt::MiterJoin);
  painter.setPen(borderPen);
  painter.setBrush(Qt::NoBrush);

  // Inner area after margins
  int mx = marginPx;
  int my = marginPx;
  int innerW = w - 2 * mx;
  int innerH = h - 2 * my;
  int g = gutterPx; // gutter between panels

  // Define panel rectangles based on layout type
  struct PanelRect {
    float x, y, w, h;
  };
  std::vector<PanelRect> panels;

  if (layoutType == "single") {
    // Single full-page panel
    panels.push_back({(float)mx, (float)my, (float)innerW, (float)innerH});

  } else if (layoutType == "2col") {
    // Two columns
    float colW = (innerW - g) / 2.0f;
    panels.push_back({(float)mx, (float)my, colW, (float)innerH});
    panels.push_back({mx + colW + g, (float)my, colW, (float)innerH});

  } else if (layoutType == "2row") {
    // Two rows
    float rowH = (innerH - g) / 2.0f;
    panels.push_back({(float)mx, (float)my, (float)innerW, rowH});
    panels.push_back({(float)mx, my + rowH + g, (float)innerW, rowH});

  } else if (layoutType == "grid") {
    // 3-top, 2-bottom (manga standard grid)
    float topH = (innerH - g) * 0.45f;
    float botH = innerH - topH - g;
    float col3W = (innerW - 2 * g) / 3.0f;
    float col2W = (innerW - g) / 2.0f;

    // Top row: 3 panels
    panels.push_back({(float)mx, (float)my, col3W, topH});
    panels.push_back({mx + col3W + g, (float)my, col3W, topH});
    panels.push_back({mx + 2 * (col3W + g), (float)my, col3W, topH});

    // Bottom row: 2 panels
    panels.push_back({(float)mx, my + topH + g, col2W, botH});
    panels.push_back({mx + col2W + g, my + topH + g, col2W, botH});

  } else if (layoutType == "manga") {
    // Manga L-shape: top banner + left tall + two right stacked
    float topH = innerH * 0.3f;
    float botH = innerH - topH - g;
    float leftW = innerW * 0.5f;
    float rightW = innerW - leftW - g;
    float rightH1 = (botH - g) * 0.55f;
    float rightH2 = botH - rightH1 - g;

    // Top banner
    panels.push_back({(float)mx, (float)my, (float)innerW, topH});
    // Left tall panel
    panels.push_back({(float)mx, my + topH + g, leftW, botH});
    // Right top
    panels.push_back({mx + leftW + g, my + topH + g, rightW, rightH1});
    // Right bottom
    panels.push_back(
        {mx + leftW + g, my + topH + g + rightH1 + g, rightW, rightH2});

  } else if (layoutType == "4panel") {
    // 4 panels - staggered (classic comic)
    float col1W = innerW * 0.45f;
    float col2W = innerW - col1W - g;
    float row1TopH = innerH * 0.35f;
    float row1BotH = innerH - row1TopH - g;
    float row2TopH = innerH * 0.55f;
    float row2BotH = innerH - row2TopH - g;

    // Top-left (shorter)
    panels.push_back({(float)mx, (float)my, col1W, row1TopH});
    // Top-right (taller)
    panels.push_back({mx + col1W + g, (float)my, col2W, row2TopH});
    // Bottom-left (taller)
    panels.push_back({(float)mx, my + row1TopH + g, col1W, row1BotH});
    // Bottom-right (shorter)
    panels.push_back({mx + col1W + g, my + row2TopH + g, col2W, row2BotH});

  } else if (layoutType == "strip") {
    // 3 horizontal strips (webtoon-style)
    float rowH1 = innerH * 0.38f;
    float rowH2 = innerH * 0.35f;
    float rowH3 = innerH - rowH1 - rowH2 - 2 * g;

    panels.push_back({(float)mx, (float)my, (float)innerW, rowH1});
    panels.push_back({(float)mx, my + rowH1 + g, (float)innerW, rowH2});
    panels.push_back(
        {(float)mx, my + rowH1 + rowH2 + 2 * g, (float)innerW, rowH3});

  } else {
    // Default: single panel
    panels.push_back({(float)mx, (float)my, (float)innerW, (float)innerH});
  }

  // Draw all panels
  for (int i = 0; i < panels.size(); ++i) {
    const auto &p = panels[i];
    QRectF rect(p.x, p.y, p.w, p.h);

    // 1. Create Panel Base Layer
    QString pName = QString("Panel %1").arg(i + 1);
    int pLayerIdx = m_layerManager->addLayer(pName.toStdString());
    Layer *pLayer = m_layerManager->getLayer(pLayerIdx);
    pLayer->panelPath = QPainterPath();
    pLayer->panelPath.addRect(rect);

    // Draw white fill and black border
    QImage pImg(w, h, QImage::Format_RGBA8888_Premultiplied);
    pImg.fill(Qt::transparent);
    QPainter pPainter(&pImg);
    pPainter.setRenderHint(QPainter::Antialiasing);

    // 1. Fill solid white (CompositionMode_Source ensures Alpha 255)
    pPainter.setCompositionMode(QPainter::CompositionMode_Source);
    pPainter.fillRect(rect, Qt::white);

    // 2. Draw stylized border (Alpha 255)
    pPainter.setCompositionMode(QPainter::CompositionMode_SourceOver);
    drawStylizedBorder(pPainter, rect.topLeft(), rect.topRight(), m_panelBorderStyle, m_panelBorderWidth);
    drawStylizedBorder(pPainter, rect.topRight(), rect.bottomRight(), m_panelBorderStyle, m_panelBorderWidth);
    drawStylizedBorder(pPainter, rect.bottomRight(), rect.bottomLeft(), m_panelBorderStyle, m_panelBorderWidth);
    drawStylizedBorder(pPainter, rect.bottomLeft(), rect.topLeft(), m_panelBorderStyle, m_panelBorderWidth);
    pPainter.end();

    pLayer->buffer->loadRawData(pImg.constBits());
    pLayer->dirty = true;

    // 2. Create Art Clipped Layer
    QString aName = QString("Art %1").arg(i + 1);
    int aLayerIdx = m_layerManager->addLayer(aName.toStdString());
    Layer *aLayer = m_layerManager->getLayer(aLayerIdx);
    aLayer->clipped = true;
    aLayer->dirty = true;
  }

  // Remove the initial "Panels" layer we created at the start of the function
  m_layerManager->removeLayer(panelLayerIdx);
  clearRenderCaches();
  m_activeLayerIndex = m_layerManager->getLayerCount() - 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  updateLayersList();
  update();

  emit notificationRequested("Panel layout '" + layoutType +
                                 "' generated with individual masking",
                             "success");
}

void CanvasItem::flattenComicPanels(const QVariantList &panelsList) {
  if (!m_layerManager || panelsList.isEmpty())
    return;

  int w = m_canvasWidth;
  int h = m_canvasHeight;

  for (int i = 0; i < panelsList.size(); ++i) {
    QVariantMap panelMap = panelsList[i].toMap();
    float px = panelMap["x"].toFloat();
    float py = panelMap["y"].toFloat();
    float pw = panelMap["w"].toFloat();
    float ph = panelMap["h"].toFloat();
    float bw = panelMap.contains("borderWidth")
                   ? panelMap["borderWidth"].toFloat()
                   : 6.0f;

    QPainterPath path;
    if (panelMap.contains("pts")) {
      QVariantList ptsList = panelMap["pts"].toList();
      if (ptsList.size() >= 3) {
        QPolygonF poly;
        for (const QVariant &ptVar : ptsList) {
          QVariantMap ptMap = ptVar.toMap();
          poly << QPointF(px + ptMap["x"].toFloat(), py + ptMap["y"].toFloat());
        }
        path.addPolygon(poly);
        path.closeSubpath();
      } else {
        path.addRect(px, py, pw, ph);
      }
    } else {
      path.addRect(px, py, pw, ph);
    }

    // 1. Create Panel Base Layer
    QString pName = QString("Panel %1").arg(i + 1);
    int pLayerIdx = m_layerManager->addLayer(pName.toStdString());
    Layer *pLayer = m_layerManager->getLayer(pLayerIdx);
    pLayer->panelPath = path;

    QImage pImg(w, h, QImage::Format_RGBA8888_Premultiplied);
    pImg.fill(Qt::transparent);
    QPainter painter(&pImg);
    painter.setRenderHint(QPainter::Antialiasing);

    // Fill with Solid White (CompositionMode_Source ensures Alpha 255)
    painter.setCompositionMode(QPainter::CompositionMode_Source);
    painter.fillPath(path, Qt::white);

    // Draw Border
    if (bw > 0.01f) {
      painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
      QPen pen(Qt::black, bw, Qt::SolidLine, Qt::SquareCap, Qt::MiterJoin);
      painter.setPen(pen);
      painter.drawPath(path);
    }
    painter.end();

    pLayer->buffer->loadRawData(pImg.constBits());
    pLayer->dirty = true;

    // 2. Create Art Clipped Layer
    QString aName = QString("Art %1").arg(i + 1);
    int aLayerIdx = m_layerManager->addLayer(aName.toStdString());
    Layer *aLayer = m_layerManager->getLayer(aLayerIdx);
    aLayer->clipped = true;
    aLayer->dirty = true;
  }

  m_activeLayerIndex = m_layerManager->getLayerCount() - 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  updateLayersList();
  dirtyPanelOverlay();
  emit notificationRequested("Panels flattened to layers with clipping masks",
                             "success");
}

QString CanvasItem::sampleColor(int x, int y, int mode) {
  if (!m_layerManager)
    return "#000000";

  uint8_t r, g, b, a;
  QPointF canvasPos = screenToCanvas(QPointF(x, y));
  float cx = canvasPos.x();
  float cy = canvasPos.y();

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
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    bool beforeVal = l->clipped;
    bool afterVal = !beforeVal;
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
          m_layerManager, l->stableId, artflow::LayerProperty::Clipped, beforeVal, afterVal));
    }
    l->clipped = afterVal;
    updateLayersList();
    update();
  }
}

void CanvasItem::toggleAlphaLock(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    bool beforeVal = l->alphaLock;
    bool afterVal = !beforeVal;
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
          m_layerManager, l->stableId, artflow::LayerProperty::AlphaLock, beforeVal, afterVal));
    }
    l->alphaLock = afterVal;
    updateLayersList();
  }
}

void CanvasItem::toggleVisibility(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    bool beforeVal = l->visible;
    bool afterVal = !beforeVal;
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
          m_layerManager, l->stableId, artflow::LayerProperty::Visible, beforeVal, afterVal));
    }
    l->visible = afterVal;
    l->markDirty();

    // Sync with perspective ruler!
    if (l->name == "Capa no destructiva" && m_perspectiveRuler) {
      if (m_perspectiveRuler->active() != afterVal) {
        m_perspectiveRuler->setActive(afterVal);
      }
    }

    // If it's a group, toggle all children recursively
    if (l->type == Layer::Type::Group) {
      uint32_t groupStableId = l->stableId;
      for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
        Layer *child = m_layerManager->getLayer(i);
        if (child && child->parentId == (int)groupStableId) {
          child->visible = afterVal;
        }
      }
    }

    updateLayersList();
    update();
  }
}

void CanvasItem::setLayerVisibility(int index, bool visible) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->visible != visible) {
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
          m_layerManager, l->stableId, artflow::LayerProperty::Visible, l->visible, visible));
    }
    l->visible = visible;
    l->markDirty();

    // Sync with perspective ruler!
    if (l->name == "Capa no destructiva" && m_perspectiveRuler) {
      if (m_perspectiveRuler->active() != visible) {
        m_perspectiveRuler->setActive(visible);
      }
    }

    updateLayersList();
    update();
  }
}

void CanvasItem::toggleLock(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    bool beforeVal = l->locked;
    bool afterVal = !beforeVal;
    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
          m_layerManager, l->stableId, artflow::LayerProperty::Locked, beforeVal, afterVal));
    }
    l->locked = afterVal;
    updateLayersList();
  }
}

void CanvasItem::clearLayer(int index) {
  if (m_isTransforming && index == m_activeLayerIndex) {
    cancelTransform();
  }
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    l->buffer->clear();
    l->markDirty();
    update();
  }
}

void CanvasItem::setLayerOpacity(int index, float opacity) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    // We don't necessarily need a notification for every slider drag,
    // but the UI should ideally handle this. Let's emit one to be safe.
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    float beforeVal = l->opacity;
    if (m_isDraggingOpacity) {
      beforeVal = m_opacityBeforeDrag;
      m_isDraggingOpacity = false;
    }
    if (beforeVal != opacity) {
      if (m_undoManager) {
        m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
            m_layerManager, l->stableId, artflow::LayerProperty::Opacity, beforeVal, opacity));
      }
      l->opacity = opacity;
      l->markDirty();
      updateLayersList();
      update();
    }
  }
}

void CanvasItem::setLayerOpacityPreview(int index, float opacity) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked)
    return;
  if (l) {
    if (!m_isDraggingOpacity) {
      m_opacityBeforeDrag = l->opacity;
      m_isDraggingOpacity = true;
    }
    l->opacity = opacity;
    l->markDirty();
    // Skip updateLayersList() for smooth preview
    update();
  }
}

void CanvasItem::setLayerBlendMode(int index, const QString &mode) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    BlendMode newMode = BlendMode::Normal;
    if (mode == "Normal")
      newMode = BlendMode::Normal;
    else if (mode == "Multiply")
      newMode = BlendMode::Multiply;
    else if (mode == "Screen")
      newMode = BlendMode::Screen;
    else if (mode == "Overlay")
      newMode = BlendMode::Overlay;
    else if (mode == "Darken")
      newMode = BlendMode::Darken;
    else if (mode == "Lighten")
      newMode = BlendMode::Lighten;
    else if (mode == "Color Dodge")
      newMode = BlendMode::ColorDodge;
    else if (mode == "Color Burn")
      newMode = BlendMode::ColorBurn;
    else if (mode == "Soft Light")
      newMode = BlendMode::SoftLight;
    else if (mode == "Hard Light")
      newMode = BlendMode::HardLight;
    else if (mode == "Difference")
      newMode = BlendMode::Difference;
    else if (mode == "Exclusion")
      newMode = BlendMode::Exclusion;
    else if (mode == "Hue")
      newMode = BlendMode::Hue;
    else if (mode == "Saturation")
      newMode = BlendMode::Saturation;
    else if (mode == "Color")
      newMode = BlendMode::Color;
    else if (mode == "Luminosity")
      newMode = BlendMode::Luminosity;
    else if (mode == "Glow Dodge" || mode == "GlowDodge" || mode == "Glow")
      newMode = BlendMode::GlowDodge;
    else if (mode == "Hard Mix" || mode == "HardMix")
      newMode = BlendMode::HardMix;
    else if (mode == "Divide")
      newMode = BlendMode::Divide;

    if (l->blendMode == newMode)
      return;

    if (m_undoManager) {
      m_undoManager->pushCommand(std::make_unique<artflow::LayerPropertyUndoCommand>(
          m_layerManager, l->stableId, artflow::LayerProperty::BlendMode, static_cast<int>(l->blendMode), static_cast<int>(newMode)));
    }

    l->blendMode = newMode;
    l->markDirty();
    updateLayersList();
    update();
  }
}

void CanvasItem::setActiveLayer(int index) {
  if (m_layerManager && index >= 0 && index < m_layerManager->getLayerCount()) {
    if (m_isTransforming) {
      // CRITICAL: addLayer() may have changed the manager's active index;
      // restore it to CanvasItem's tracking so applyTransform affects the
      // correct layer (the one the user was actually transforming).
      m_layerManager->setActiveLayer(m_activeLayerIndex);
      applyTransform();
    }
    // SYNC CURRENT LAYER BEFORE SWITCHING
    if (index != m_activeLayerIndex) {
      syncGpuToCpu();
    }

    m_activeLayerIndex = index;
    m_layerManager->setActiveLayer(index);
    Layer *l = m_layerManager->getLayer(index);
    if (l && !l->gradientMapStops.isEmpty()) {
      m_gradientStops = l->gradientMapStops;
      emit gradientStopsChanged();
    }
    m_gradientMapDirty = true;
    emit activeLayerChanged();
    updateLayersList();

    // Explicitly update m_lastActiveLayerIndex to prevent double-sync in
    // handleDraw
    m_lastActiveLayerIndex = m_activeLayerIndex;

    // Force FBO reload for the next draw
    if (m_pingFBO) {
      delete m_pingFBO;
      m_pingFBO = nullptr;
      delete m_pongFBO;
      m_pongFBO = nullptr;
    }
  }
  requestUpdate();
}

void CanvasItem::setLayerPrivate(int index, bool isPrivate) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->isPrivate = isPrivate;
    updateLayersList();
  }
}

bool CanvasItem::isLayerScreentoneEnabled(int index) const {
  if (!m_layerManager) return false;
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->screentoneEnabled : false;
}

void CanvasItem::setLayerScreentoneEnabled(int index, bool enabled) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->screentoneEnabled != enabled) {
    l->screentoneEnabled = enabled;
    l->markDirty();
    updateLayersList();
    update();
  }
}

float CanvasItem::getLayerScreentoneDotSize(int index) const {
  if (!m_layerManager) return 12.0f;
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->screentoneDotSize : 12.0f;
}

void CanvasItem::setLayerScreentoneDotSize(int index, float size) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->screentoneDotSize != size) {
    l->screentoneDotSize = size;
    l->markDirty();
    updateLayersList();
    update();
  }
}

float CanvasItem::getLayerScreentoneAngle(int index) const {
  if (!m_layerManager) return 0.785f;
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->screentoneAngle : 0.785f;
}

void CanvasItem::setLayerScreentoneAngle(int index, float angle) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->screentoneAngle != angle) {
    l->screentoneAngle = angle;
    l->markDirty();
    updateLayersList();
    update();
  }
}

float CanvasItem::getLayerScreentoneContrast(int index) const {
  if (!m_layerManager) return 0.8f;
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->screentoneContrast : 0.8f;
}

void CanvasItem::setLayerScreentoneContrast(int index, float contrast) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->screentoneContrast != contrast) {
    l->screentoneContrast = contrast;
    l->markDirty();
    updateLayersList();
    update();
  }
}

int CanvasItem::getLayerScreentoneType(int index) const {
  if (!m_layerManager) return 0;
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->screentoneType : 0;
}

void CanvasItem::setLayerScreentoneType(int index, int type) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->screentoneType != type) {
    l->screentoneType = type;
    l->markDirty();
    updateLayersList();
    update();
  }
}

bool CanvasItem::isLayerGradientMapEnabled(int index) const {
  if (!m_layerManager) return false;
  Layer *l = m_layerManager->getLayer(index);
  return l ? l->gradientMapEnabled : false;
}

void CanvasItem::setLayerGradientMapEnabled(int index, bool enabled) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->gradientMapEnabled != enabled) {
    l->gradientMapEnabled = enabled;
    if (enabled && l->gradientMapStops.isEmpty()) {
      l->gradientMapStops = m_gradientStops;
    }
    l->markDirty();
    updateLayersList();
    update();
  }
}

QString CanvasItem::getLayerGradientMapPreset(int index) const {
  if (!m_layerManager) return QStringLiteral("sunset");
  Layer *l = m_layerManager->getLayer(index);
  return l ? QString::fromStdString(l->gradientMapPreset) : QStringLiteral("sunset");
}

void CanvasItem::setLayerGradientMapPreset(int index, const QString &preset) {
  if (!m_layerManager) return;
  Layer *l = m_layerManager->getLayer(index);
  std::string stdPreset = preset.toStdString();
  if (l && l->gradientMapPreset != stdPreset) {
    l->gradientMapPreset = stdPreset;
    l->markDirty();
    updateLayersList();
    update();
  }
}

void CanvasItem::setGradientStops(const QVariantList &stops) {
  if (m_gradientStops != stops) {
    m_gradientStops = stops;
    emit gradientStopsChanged();
    if (m_layerManager) {
      Layer *l = m_layerManager->getActiveLayer();
      if (l) {
        l->gradientMapStops = stops;
        l->markDirty();
        update();
      }
    }
  }
}

void CanvasItem::setGradientShape(const QString &shape) {
  if (m_gradientShape != shape) {
    m_gradientShape = shape;
    emit gradientShapeChanged();
  }
}

void CanvasItem::createSpeechBalloon(float x, float y) {
  m_activeSpeechBalloon = artflow::SpeechBalloon(
      x, y, 100.0f, 60.0f,
      QPointF(x - 30.0f, y + 50.0f), // tailStart1
      QPointF(x + 30.0f, y + 50.0f), // tailStart2
      QPointF(x - 20.0f, y + 100.0f), // tailControl1
      QPointF(x + 20.0f, y + 100.0f), // tailControl2
      QPointF(x, y + 120.0f) // tailEnd
  );
  m_hasActiveSpeechBalloon = true;
  update();
}

void CanvasItem::removeSpeechBalloon() {
  m_hasActiveSpeechBalloon = false;
  update();
}

void CanvasItem::rasterizeSpeechBalloon() {
  if (!m_hasActiveSpeechBalloon || !m_layerManager) return;
  Layer *l = m_layerManager->getActiveLayer();
  if (l && l->buffer) {
    int w = m_canvasWidth;
    int h = m_canvasHeight;
    QImage img(l->buffer->data(), w, h, QImage::Format_RGBA8888_Premultiplied);
    QPainter p(&img);
    p.setRenderHint(QPainter::Antialiasing);
    
    QPainterPath path = m_activeSpeechBalloon.generateVectorPath();
    
    // Fill with solid white
    p.fillPath(path, Qt::white);
    
    // Stroke with current brush color and brush size
    QPen pen(m_brushColor, m_brushSize);
    pen.setJoinStyle(Qt::MiterJoin);
    p.setPen(pen);
    p.drawPath(path);
    
    p.end();
    l->markDirty();
    m_hasActiveSpeechBalloon = false;
    update();
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

  // Sync quick toggles
  m_sizeByPressure = (preset->sizeDynamics.baseValue > 0.01f ||
                      preset->sizeDynamics.minLimit < 0.99f);
  m_opacityByPressure = (preset->opacityDynamics.minLimit < 0.99f);
  m_flowByPressure = (preset->flowDynamics.minLimit < 0.99f);
  emit sizeByPressureChanged();
  emit opacityByPressureChanged();
  emit flowByPressureChanged();

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
  invalidateCursorCache();
  updateBrushTipImage();
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
  m_editRevision = 0;
  m_brushPreviewCache.clear();

  qDebug() << "beginBrushEdit: Cloned preset:" << brushName
           << "dualBrush.enabled =" << m_editingPreset.dualBrush.enabled
           << "dualBrush.tipTexture =" << m_editingPreset.dualBrush.tipTexture
           << "grain.texture =" << m_editingPreset.grain.texture
           << "grain.invert =" << m_editingPreset.grain.invert;

  // Initialize the preview pad
  m_previewPadImage = QImage(m_previewPadWidth, m_previewPadHeight, QImage::Format_ARGB32);
  m_previewPadImage.fill(QColor(10, 10, 12));

  applyEditingPresetToEngine();

  emit isEditingBrushChanged();
  emit editingPresetChanged();
  qDebug() << "beginBrushEdit: Editing" << brushName;
}

void CanvasItem::syncGpuToCpu() {
  if (!m_layerManager)
    return;
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !m_pingFBO)
    return;

  QImage img = m_pingFBO->toImage();
  if (img.format() != QImage::Format_RGBA8888_Premultiplied) {
    img = img.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
  }

  if (img.width() == m_canvasWidth && img.height() == m_canvasHeight) {
    layer->buffer->loadRawData(img.constBits());
    // Mark the entire layer dirty so the compositor refreshes it
    layer->markDirty(QRect(0, 0, m_canvasWidth, m_canvasHeight));
  }
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

  // Limpiar de la caché de vistas previas para forzar regeneración
  m_brushPreviewCache.remove(m_editingPreset.name);

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
  m_brushPreviewCache.remove(m_editingPreset.name);
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
  invalidateCursorCache();
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
    if (key == "invert")
      return m_editingPreset.shape.invert;
    if (key == "rotate_tip")
      return m_editingPreset.shape.rotateTip;
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
    if (key == "blend_mode")
      return m_editingPreset.grain.blendMode;
    if (key == "invert")
      return m_editingPreset.grain.invert;
    if (key == "emphasize_density")
      return m_editingPreset.grain.emphasizeDensity;
    if (key == "apply_to_tips")
      return m_editingPreset.grain.applyToTips;
  }

  // ── spray ──
  if (category == "spray") {
    if (key == "enabled")
      return m_editingPreset.spray.enabled;
    if (key == "particle_size")
      return m_editingPreset.spray.particleSize;
    if (key == "spray_size_by_brush")
      return m_editingPreset.spray.spraySizeByBrush;
    if (key == "particle_density")
      return m_editingPreset.spray.particleDensity;
    if (key == "spray_deviation")
      return m_editingPreset.spray.sprayDeviation;
    if (key == "particle_direction")
      return m_editingPreset.spray.particleDirection;
  }

  // ── dualbrush ──
  if (category == "dualbrush") {
    if (key == "enabled")
      return m_editingPreset.dualBrush.enabled;
    if (key == "tip_texture")
      return m_editingPreset.dualBrush.tipTexture;
    if (key == "scale")
      return m_editingPreset.dualBrush.scale;
    if (key == "rotation")
      return m_editingPreset.dualBrush.rotation;
    if (key == "blend_mode")
      return m_editingPreset.dualBrush.blendMode;
    if (key == "flow")
      return m_editingPreset.dualBrush.flow;
    if (key == "spray_enabled")
      return m_editingPreset.dualBrush.sprayEnabled;
    if (key == "particle_size")
      return m_editingPreset.dualBrush.particleSize;
    if (key == "spray_size_by_brush")
      return m_editingPreset.dualBrush.spraySizeByBrush;
    if (key == "particle_density")
      return m_editingPreset.dualBrush.particleDensity;
    if (key == "spray_deviation")
      return m_editingPreset.dualBrush.sprayDeviation;
    if (key == "particle_direction")
      return m_editingPreset.dualBrush.particleDirection;
    if (key == "grain_texture")
      return m_editingPreset.dualBrush.grain.texture;
    if (key == "grain_scale")
      return m_editingPreset.dualBrush.grain.scale;
    if (key == "grain_intensity")
      return m_editingPreset.dualBrush.grain.intensity;
    if (key == "grain_brightness")
      return m_editingPreset.dualBrush.grain.brightness;
    if (key == "grain_contrast")
      return m_editingPreset.dualBrush.grain.contrast;
    if (key == "grain_invert")
      return m_editingPreset.dualBrush.grain.invert;
    if (key == "grain_blend_mode")
      return m_editingPreset.dualBrush.grain.blendMode;
    if (key == "grain_rotation")
      return m_editingPreset.dualBrush.grain.rotation;
    if (key == "grain_emphasize_density")
      return m_editingPreset.dualBrush.grain.emphasizeDensity;
    if (key == "grain_apply_to_tips")
      return m_editingPreset.dualBrush.grain.applyToTips;
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
    if (key == "color_mixing")
      return m_editingPreset.wetMix.colorMixing;
    if (key == "paint_amount")
      return m_editingPreset.wetMix.paintAmount;
    if (key == "color_stretch")
      return m_editingPreset.wetMix.colorStretch;
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
    if (key == "opacity_pressure_enabled")
      return m_editingPreset.opacityDynamics.pressureEnabled;
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
    if (key == "type")
      return m_editingPreset.type;
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
    } else if (key == "invert") {
      m_editingPreset.shape.invert = value.toBool();
      changed = true;
    } else if (key == "rotate_tip") {
      m_editingPreset.shape.rotateTip = value.toBool();
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
    } else if (key == "blend_mode") {
      m_editingPreset.grain.blendMode = value.toString();
      changed = true;
    } else if (key == "invert") {
      m_editingPreset.grain.invert = value.toBool();
      changed = true;
    } else if (key == "emphasize_density") {
      m_editingPreset.grain.emphasizeDensity = value.toBool();
      changed = true;
    } else if (key == "apply_to_tips") {
      m_editingPreset.grain.applyToTips = value.toBool();
      changed = true;
    }
  }

  // ── spray ──
  else if (category == "spray") {
    if (key == "enabled") {
      m_editingPreset.spray.enabled = value.toBool();
      changed = true;
    } else if (key == "particle_size") {
      m_editingPreset.spray.particleSize = value.toFloat();
      changed = true;
    } else if (key == "spray_size_by_brush") {
      m_editingPreset.spray.spraySizeByBrush = value.toBool();
      changed = true;
    } else if (key == "particle_density") {
      m_editingPreset.spray.particleDensity = value.toInt();
      changed = true;
    } else if (key == "spray_deviation") {
      m_editingPreset.spray.sprayDeviation = value.toInt();
      changed = true;
    } else if (key == "particle_direction") {
      m_editingPreset.spray.particleDirection = value.toFloat();
      changed = true;
    }
  }

  // ── dualbrush ──
  else if (category == "dualbrush") {
    if (key == "enabled") {
      m_editingPreset.dualBrush.enabled = value.toBool();
      changed = true;
    } else if (key == "tip_texture") {
      m_editingPreset.dualBrush.tipTexture = value.toString();
      changed = true;
    } else if (key == "scale") {
      m_editingPreset.dualBrush.scale = value.toFloat();
      changed = true;
    } else if (key == "rotation") {
      m_editingPreset.dualBrush.rotation = value.toFloat();
      changed = true;
    } else if (key == "blend_mode") {
      m_editingPreset.dualBrush.blendMode = value.toString();
      changed = true;
    } else if (key == "flow") {
      m_editingPreset.dualBrush.flow = value.toFloat();
      changed = true;
    } else if (key == "spray_enabled") {
      m_editingPreset.dualBrush.sprayEnabled = value.toBool();
      changed = true;
    } else if (key == "particle_size") {
      m_editingPreset.dualBrush.particleSize = value.toFloat();
      changed = true;
    } else if (key == "spray_size_by_brush") {
      m_editingPreset.dualBrush.spraySizeByBrush = value.toBool();
      changed = true;
    } else if (key == "particle_density") {
      m_editingPreset.dualBrush.particleDensity = value.toInt();
      changed = true;
    } else if (key == "spray_deviation") {
      m_editingPreset.dualBrush.sprayDeviation = value.toInt();
      changed = true;
    } else if (key == "particle_direction") {
      m_editingPreset.dualBrush.particleDirection = value.toFloat();
      changed = true;
    } else if (key == "grain_texture") {
      m_editingPreset.dualBrush.grain.texture = value.toString();
      changed = true;
    } else if (key == "grain_scale") {
      m_editingPreset.dualBrush.grain.scale = value.toFloat();
      changed = true;
    } else if (key == "grain_intensity") {
      m_editingPreset.dualBrush.grain.intensity = value.toFloat();
      changed = true;
    } else if (key == "grain_brightness") {
      m_editingPreset.dualBrush.grain.brightness = value.toFloat();
      changed = true;
    } else if (key == "grain_contrast") {
      m_editingPreset.dualBrush.grain.contrast = value.toFloat();
      changed = true;
    } else if (key == "grain_invert") {
      m_editingPreset.dualBrush.grain.invert = value.toBool();
      changed = true;
    } else if (key == "grain_blend_mode") {
      m_editingPreset.dualBrush.grain.blendMode = value.toString();
      changed = true;
    } else if (key == "grain_rotation") {
      m_editingPreset.dualBrush.grain.rotation = value.toFloat();
      changed = true;
    } else if (key == "grain_emphasize_density") {
      m_editingPreset.dualBrush.grain.emphasizeDensity = value.toBool();
      changed = true;
    } else if (key == "grain_apply_to_tips") {
      m_editingPreset.dualBrush.grain.applyToTips = value.toBool();
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
    } else if (key == "color_mixing") {
      m_editingPreset.wetMix.colorMixing = value.toBool();
      changed = true;
    } else if (key == "paint_amount") {
      m_editingPreset.wetMix.paintAmount = value.toFloat();
      changed = true;
    } else if (key == "color_stretch") {
      m_editingPreset.wetMix.colorStretch = value.toFloat();
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
    } else if (key == "opacity_pressure_enabled") {
      m_editingPreset.opacityDynamics.pressureEnabled = value.toBool();
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
    } else if (key == "type") {
      m_editingPreset.type = value.toString();
      changed = true;
    }
  }

  if (changed) {
    // Bump revision to invalidate preview cache
    m_editRevision++;

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
      // itself is requested. Since I cannot add to a non-existent function
      // in this file, I will add the logging line as a comment here to
      // indicate where it would go if applyToLegacy were present and being
      // modified. For getBrushCategoryProperties, we just return the value.
      // qDebug() << "BrushPreset::applyToLegacy: Setting tipTextureName to"
      // << m_editingPreset.shape.tipTexture;
    }
    map["tip_texture"] = m_editingPreset.shape.tipTexture;
    map["invert"] = m_editingPreset.shape.invert;
    map["rotate_tip"] = m_editingPreset.shape.rotateTip;
  } else if (category == "grain") {
    map["texture"] = m_editingPreset.grain.texture;
    map["scale"] = m_editingPreset.grain.scale;
    map["intensity"] = m_editingPreset.grain.intensity;
    map["rotation"] = m_editingPreset.grain.rotation;
    map["brightness"] = m_editingPreset.grain.brightness;
    map["contrast"] = m_editingPreset.grain.contrast;
    map["rolling"] = m_editingPreset.grain.rolling;
    map["blend_mode"] = m_editingPreset.grain.blendMode;
    map["invert"] = m_editingPreset.grain.invert;
    map["emphasize_density"] = m_editingPreset.grain.emphasizeDensity;
    map["apply_to_tips"] = m_editingPreset.grain.applyToTips;
  } else if (category == "spray") {
    map["enabled"] = m_editingPreset.spray.enabled;
    map["particle_size"] = m_editingPreset.spray.particleSize;
    map["spray_size_by_brush"] = m_editingPreset.spray.spraySizeByBrush;
    map["particle_density"] = m_editingPreset.spray.particleDensity;
    map["spray_deviation"] = m_editingPreset.spray.sprayDeviation;
    map["particle_direction"] = m_editingPreset.spray.particleDirection;
  } else if (category == "dualbrush") {
    map["enabled"] = m_editingPreset.dualBrush.enabled;
    map["tip_texture"] = m_editingPreset.dualBrush.tipTexture;
    map["scale"] = m_editingPreset.dualBrush.scale;
    map["rotation"] = m_editingPreset.dualBrush.rotation;
    map["blend_mode"] = m_editingPreset.dualBrush.blendMode;
    map["flow"] = m_editingPreset.dualBrush.flow;
    map["spray_enabled"] = m_editingPreset.dualBrush.sprayEnabled;
    map["particle_size"] = m_editingPreset.dualBrush.particleSize;
    map["spray_size_by_brush"] = m_editingPreset.dualBrush.spraySizeByBrush;
    map["particle_density"] = m_editingPreset.dualBrush.particleDensity;
    map["spray_deviation"] = m_editingPreset.dualBrush.sprayDeviation;
    map["particle_direction"] = m_editingPreset.dualBrush.particleDirection;
    map["grain_texture"] = m_editingPreset.dualBrush.grain.texture;
    map["grain_scale"] = m_editingPreset.dualBrush.grain.scale;
    map["grain_intensity"] = m_editingPreset.dualBrush.grain.intensity;
    map["grain_brightness"] = m_editingPreset.dualBrush.grain.brightness;
    map["grain_contrast"] = m_editingPreset.dualBrush.grain.contrast;
    map["grain_invert"] = m_editingPreset.dualBrush.grain.invert;
    map["grain_blend_mode"] = m_editingPreset.dualBrush.grain.blendMode;
    map["grain_rotation"] = m_editingPreset.dualBrush.grain.rotation;
    map["grain_emphasize_density"] = m_editingPreset.dualBrush.grain.emphasizeDensity;
    map["grain_apply_to_tips"] = m_editingPreset.dualBrush.grain.applyToTips;
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
    map["type"] = m_editingPreset.type;
  }

  return map;
}

// ══════════════════════════════════════════════════════════════════════
// Drawing Pad Preview (Offscreen Rendering)
// ══════════════════════════════════════════════════════════════════════

void CanvasItem::clearPreviewPad() {
  if (m_previewPadImage.isNull() || m_previewPadImage.width() != m_previewPadWidth || m_previewPadImage.height() != m_previewPadHeight) {
    m_previewPadImage = QImage(m_previewPadWidth, m_previewPadHeight, QImage::Format_ARGB32);
  }
  m_previewPadImage.fill(QColor(10, 10, 12));
  if (m_brushEngine)
    m_brushEngine->resetRemainder();
  emit previewPadUpdated();
}

void CanvasItem::resizePreviewPad(int w, int h) {
  if (w <= 0 || h <= 0) return;
  m_previewPadWidth = w;
  m_previewPadHeight = h;

  if (m_previewPadImage.isNull() || m_previewPadImage.width() != w || m_previewPadImage.height() != h) {
    QImage newImg(w, h, QImage::Format_ARGB32);
    newImg.fill(QColor(10, 10, 12));
    if (!m_previewPadImage.isNull()) {
      QPainter painter(&newImg);
      painter.drawImage(0, 0, m_previewPadImage);
      painter.end();
    }
    m_previewPadImage = newImg;
    emit previewPadUpdated();
  }
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

QVariantList CanvasItem::getBrushCategories() {
  QVariantList result;
  auto *bpm = artflow::BrushPresetManager::instance();
  auto groups = bpm->groups();

  // Map of known built-in categories to icons
  // Fixed icons for premium aesthetic
  static QMap<QString, QString> builtInIcons = {
      {"Favorites", "cat_favorites"},
      {"Sketch & Ink", "cat_sketching"},
      {"Paint & Blend", "cat_painting"},
      {"Airbrush", "airbrush"},
      {"Eraser", "eraser"},
      {"Imported", "cat_imported"}};

  for (const auto &group : groups) {
    if (group.brushes.empty())
      continue;

    QVariantMap map;
    map["name"] = group.name;
    if (builtInIcons.contains(group.name)) {
      map["icon"] = builtInIcons[group.name];
    } else {
      // It's a dynamically imported group from an .abr
      map["icon"] = "cat_imported"; // Use the 'imported' icon as default
    }
    result.append(map);
  }
  return result;
}

QStringList CanvasItem::getBrushCategoryNames() {
  QStringList result;
  auto *bpm = artflow::BrushPresetManager::instance();
  auto groups = bpm->groups();

  for (const auto &group : groups) {
    if (!group.brushes.empty()) {
      result.append(group.name);
    }
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
// ─── Canvas Preview (Live Preview for Navigator) ────────────────────────
QString CanvasItem::getCanvasPreview() {
  if (!m_cachedCanvasImage.isNull() && !m_canvasPreviewBase64.isEmpty()) {
    return m_canvasPreviewBase64;
  }

  if (m_cachedCanvasImage.isNull()) {
    if (m_layerManager && m_layerManager->getLayerCount() > 0) {
      int cw = m_canvasWidth;
      int ch = m_canvasHeight;
      if (cw > 0 && ch > 0) {
        m_cachedCanvasImage = QImage(cw, ch, QImage::Format_RGBA8888_Premultiplied);
        bool isBgVisible = true;
        for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
          artflow::Layer *l = m_layerManager->getLayer(i);
          if (l && l->type == artflow::Layer::Type::Background) {
            isBgVisible = l->visible;
            break;
          }
        }
        if (isBgVisible && m_backgroundColor.alpha() > 0) {
          m_cachedCanvasImage.fill(m_backgroundColor);
        } else {
          m_cachedCanvasImage.fill(Qt::transparent);
        }

        QPainter painter(&m_cachedCanvasImage);
        for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
          artflow::Layer *l = m_layerManager->getLayer(i);
          if (l && l->visible && l->buffer && l->buffer->data()) {
            QImage layerImg(l->buffer->data(), cw, ch, QImage::Format_RGBA8888_Premultiplied);
            painter.setOpacity(l->opacity);
            if (l->type == artflow::Layer::Type::Background) {
              painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
            } else {
              switch (l->blendMode) {
                case BlendMode::Multiply:
                  painter.setCompositionMode(QPainter::CompositionMode_Multiply);
                  break;
                case BlendMode::Screen:
                  painter.setCompositionMode(QPainter::CompositionMode_Screen);
                  break;
                case BlendMode::Overlay:
                  painter.setCompositionMode(QPainter::CompositionMode_Overlay);
                  break;
                case BlendMode::Darken:
                  painter.setCompositionMode(QPainter::CompositionMode_Darken);
                  break;
                case BlendMode::Lighten:
                  painter.setCompositionMode(QPainter::CompositionMode_Lighten);
                  break;
                case BlendMode::ColorDodge:
                  painter.setCompositionMode(QPainter::CompositionMode_ColorDodge);
                  break;
                case BlendMode::ColorBurn:
                  painter.setCompositionMode(QPainter::CompositionMode_ColorBurn);
                  break;
                case BlendMode::Difference:
                  painter.setCompositionMode(QPainter::CompositionMode_Difference);
                  break;
                case BlendMode::Exclusion:
                  painter.setCompositionMode(QPainter::CompositionMode_Exclusion);
                  break;
                case BlendMode::SoftLight:
                  painter.setCompositionMode(QPainter::CompositionMode_SoftLight);
                  break;
                case BlendMode::HardLight:
                  painter.setCompositionMode(QPainter::CompositionMode_HardLight);
                  break;
                default:
                  painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
                  break;
              }
            }
            painter.drawImage(0, 0, layerImg);
          }
        }
        painter.end();
      }
    }
  }

  if (m_cachedCanvasImage.isNull()) {
    m_canvasPreviewBase64 = "";
    return "";
  }

  // Make a very high quality, smoothly downscaled version for the navigator (400x400 is super crisp)
  QImage preview = m_cachedCanvasImage;
  if (preview.width() > 400 || preview.height() > 400) {
    preview = preview.scaled(400, 400, Qt::KeepAspectRatio, Qt::SmoothTransformation);
  }

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  // Compress as JPG at 80% quality (much faster and lighter than PNG)
  preview.save(&buffer, "JPG", 80);

  m_canvasPreviewBase64 = "data:image/jpeg;base64," + QString(ba.toBase64());
  return m_canvasPreviewBase64;
}

QString CanvasItem::loadReference(const QString &path) {
  return path;
}

QString CanvasItem::sampleColorFromImage(const QString &imagePath, int x, int y, int viewWidth, int viewHeight) {
  if (imagePath.isEmpty() || viewWidth <= 0 || viewHeight <= 0) {
    return "#000000";
  }

  QString localPath = imagePath;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(imagePath).toLocalFile();
  } else if (localPath.startsWith("qrc:/")) {
    localPath = imagePath.mid(3);
    if (!localPath.startsWith(":/")) {
      localPath = ":" + localPath.mid(1);
    }
  }

  QImage img;
  static QString cachedPath;
  static QImage cachedImage;

  if (cachedPath == localPath && !cachedImage.isNull()) {
    img = cachedImage;
  } else {
    if (img.load(localPath)) {
      cachedPath = localPath;
      cachedImage = img;
    } else {
      QUrl url(imagePath);
      if (url.isLocalFile()) {
        if (img.load(url.toLocalFile())) {
          cachedPath = localPath;
          cachedImage = img;
        }
      }
    }
  }

  if (img.isNull()) {
    qWarning() << "Failed to load image for color sampling:" << imagePath;
    return "#000000";
  }

  double imgAspect = static_cast<double>(img.width()) / img.height();
  double viewAspect = static_cast<double>(viewWidth) / viewHeight;

  double scale = 1.0;
  double offsetX = 0.0;
  double offsetY = 0.0;

  if (imgAspect > viewAspect) {
    scale = static_cast<double>(viewWidth) / img.width();
    offsetY = (viewHeight - img.height() * scale) / 2.0;
  } else {
    scale = static_cast<double>(viewHeight) / img.height();
    offsetX = (viewWidth - img.width() * scale) / 2.0;
  }

  double imgX = (x - offsetX) / scale;
  double imgY = (y - offsetY) / scale;

  int pixelX = static_cast<int>(qRound(imgX));
  int pixelY = static_cast<int>(qRound(imgY));

  if (pixelX < 0 || pixelX >= img.width() || pixelY < 0 || pixelY >= img.height()) {
    return "#000000";
  }

  QColor col = img.pixelColor(pixelX, pixelY);
  return col.name();
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
  // Usar el preset en edición si está activo, para reflejar cambios en vivo
  const artflow::BrushPreset *preset = nullptr;
  if (m_isEditingBrush) {
    preset = &m_editingPreset;
  } else {
    auto *bpm = artflow::BrushPresetManager::instance();
    preset = bpm->findByName(brushName);
  }
  if (!preset)
    return "";

  // Retornar de la caché inmediatamente si ya ha sido generada para este preset
  // Usamos un cache key que incluye el nombre + un contador de revisión
  QString cacheKey = preset->name + "_rev" + QString::number(m_editRevision);
  if (m_brushPreviewCache.contains(cacheKey)) {
    return m_brushPreviewCache.value(cacheKey);
  }

  // Aumentar resolución para un preview más nítido y "premium"
  QImage img(400, 160, QImage::Format_ARGB32);
  img.fill(Qt::transparent);

  QPainter painter(&img);
  painter.setRenderHint(QPainter::Antialiasing);
  painter.setRenderHint(QPainter::SmoothPixmapTransform);

  // Crear un motor temporal para no ensuciar el estado del principal
  BrushEngine tempEngine;
  BrushSettings s;
  preset->applyToLegacy(s);

  // Forzar color blanco y tamaño adecuado para el preview
  s.color = Qt::white;
  s.size = 35.0f;
  s.opacity = 1.0f;
  s.spacing = std::max(s.spacing, 0.05f); // Evitar espaciado demasiado denso
  tempEngine.setBrush(s);

  // Dibujar una curva de onda horizontal extremadamente elegante, suave y centrada
  QPainterPath path;
  path.moveTo(40, 80);
  path.cubicTo(130, 45, 270, 115, 360, 80);

  // Simular el trazo con interpolación para que el motor de pincel actúe
  QPointF lastP = path.pointAtPercent(0);
  tempEngine.resetRemainder();

  int segments = 100;
  for (int i = 1; i <= segments; ++i) {
    float t = (float)i / segments;
    QPointF currP = path.pointAtPercent(t);

    // Presión senoidal con exponente para lograr un estrechamiento caligráfico perfecto en los extremos (tapered to 0)
    float pressure = std::pow(std::sin(t * M_PI), 1.2f);

    tempEngine.paintStroke(&painter, lastP, currP, pressure, s);
    lastP = currP;
  }

  painter.end();

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  img.save(&buffer, "PNG");

  QString base64Str = "data:image/png;base64," + ba.toBase64();
  
  // Guardar en la caché
  m_brushPreviewCache.insert(cacheKey, base64Str);

  return base64Str;
}

void CanvasItem::updateBrushTipImage() {
  float size = 120.0f;
  float rotation = 0.0f;
  QString texturePath;

  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *preset = bpm->findByName(m_activeBrushName);
  if (preset) {
    texturePath = preset->shape.tipTexture;
    rotation = preset->shape.rotation;
  }

  // Generate a clean preview at 1.0 zoom
  QImage img = loadAndProcessBrushTexture(texturePath, size, rotation, 1.0f);

  if (img.isNull())
    return;

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  img.save(&buffer, "PNG");
  m_brushTipImage = "data:image/png;base64," + ba.toBase64();
  emit brushTipImageChanged();
}

struct LayerSnapshot {
  std::shared_ptr<artflow::ImageBuffer> buffer;
  float opacity;
  artflow::BlendMode blendMode;
  bool clipped;
};

void CanvasItem::capture_timelapse_frame() {
  if (!m_layerManager)
    return;

  // Instantánea ultrarrápida del estado de las capas en el hilo de la UI (toma < 3ms)
  std::vector<LayerSnapshot> snapshot;
  int count = m_layerManager->getLayerCount();
  snapshot.reserve(count);

  for (int i = 0; i < count; ++i) {
    const artflow::Layer *layer = m_layerManager->getLayer(i);
    if (layer && layer->visible && !layer->isPrivate && layer->buffer) {
      LayerSnapshot snap;
      // Clonación profunda ligera de los tiles asignados
      snap.buffer = std::make_shared<artflow::ImageBuffer>(*layer->buffer);
      snap.opacity = layer->opacity;
      snap.blendMode = layer->blendMode;
      snap.clipped = layer->clipped;
      snapshot.push_back(snap);
    }
  }

  int cw = m_canvasWidth;
  int ch = m_canvasHeight;

  // Ejecutar la composición de capas y la escritura a disco de forma totalmente asíncrona
  std::ignore = QtConcurrent::run([snapshot, cw, ch]() {
    static int frameCount = 0;

    // Crear buffer compuesto intermedio en segundo plano
    artflow::ImageBuffer composite(cw, ch);
    composite.clear();

    // Componer todas las capas clonadas en segundo plano
    const artflow::ImageBuffer *currentBaseBuffer = nullptr;
    for (const auto &snap : snapshot) {
      if (snap.clipped && currentBaseBuffer) {
        composite.composite(*snap.buffer, 0, 0, snap.opacity, snap.blendMode,
                            currentBaseBuffer);
      } else {
        composite.composite(*snap.buffer, 0, 0, snap.opacity, snap.blendMode,
                            nullptr);
        currentBaseBuffer = snap.buffer.get();
      }
    }

    QString path =
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) +
        "/ArtFlow/Timelapse";
    QDir().mkpath(path);

    QString fileName = QString("%1/frame_%2.jpg")
                           .arg(path)
                           .arg(frameCount++, 6, 10, QChar('0'));

    QImage img(composite.data(), cw, ch, QImage::Format_RGBA8888);
    img.save(fileName, "JPG", 85);
  });
}

void CanvasItem::undo() {
  if (m_isTransforming) {
    cancelTransform();
    return;
  }
  if (m_undoManager && m_undoManager->canUndo()) {
    m_undoManager->undo();
    setProjectDirty(true);
    m_activeLayerIndex = m_layerManager->getActiveLayerIndex();
    m_lastActiveLayerIndex = m_activeLayerIndex;
    updateLayersList();
    emit activeLayerChanged();
    dirtyPanelOverlay();
  }
}

void CanvasItem::redo() {
  if (m_isTransforming) {
    cancelTransform();
  }
  if (m_undoManager && m_undoManager->canRedo()) {
    m_undoManager->redo();
    setProjectDirty(true);
    m_activeLayerIndex = m_layerManager->getActiveLayerIndex();
    m_lastActiveLayerIndex = m_activeLayerIndex;
    updateLayersList();
    emit activeLayerChanged();
    dirtyPanelOverlay();
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

void CanvasItem::hoverEnterEvent(QHoverEvent *event) {
  event->accept();
  m_cursorVisible = true;
  m_cursorPos = event->position();

  // Decide el cursor solo para el área del Canvas
  if (m_spacePressed || m_tool == ToolType::Hand)
    setCursor(m_customOpenHandCursor);
  else if (m_tool == ToolType::Transform)
    setCursor(getModernCursor());
  else
    setCursor(Qt::BlankCursor); // DIBUJO = INVISIBLE

  update();
}

void CanvasItem::hoverMoveEvent(QHoverEvent *event) {
  event->accept();
  m_cursorPos = event->position();
  m_cursorVisible = true;

  if (m_spacePressed || m_tool == ToolType::Hand)
    setCursor(m_customOpenHandCursor);
  else if (m_tool == ToolType::Transform)
    setCursor(getModernCursor());
  else
    setCursor(Qt::BlankCursor); // DIBUJO = INVISIBLE

  update();
  emit cursorPosChanged(event->position().x(), event->position().y());
}

void CanvasItem::hoverLeaveEvent(QHoverEvent *event) {
  event->accept();
  m_cursorVisible = false;

  // Soltamos el control del cursor.
  // Al hacer esto, QML regresará automáticamente al cursor moderno de la
  // ventana.
  unsetCursor();
  update();
}

QImage CanvasItem::loadAndProcessBrushTexture(const QString &texturePath,
                                              float size, float rotation,
                                              float zoomOverride,
                                              bool outline) {
  float z = (zoomOverride > 0) ? zoomOverride : m_zoomLevel;
  if (texturePath.isEmpty()) {
    // Fallback: círculo simple si no hay textura
    int iSize = std::max(8, std::min((int)(size * z), 512));
    if (iSize % 2 == 0)
      iSize++;

    QImage fallback(iSize, iSize, QImage::Format_ARGB32);
    fallback.fill(Qt::transparent);

    QPainter p(&fallback);
    p.setRenderHint(QPainter::Antialiasing);

    float center = iSize / 2.0f;
    float radius = center - 2.0f;

    // Contorno negro
    p.setPen(QPen(QColor(0, 0, 0, 200), 2.0f));
    p.setBrush(Qt::NoBrush);
    p.drawEllipse(QPointF(center, center), radius, radius);

    // Contorno blanco
    p.setPen(QPen(QColor(255, 255, 255, 255), 1.0f));
    if (outline) {
      // Si es solo contorno, usar color de pincel para el círculo interno
      p.setPen(QPen(m_brushColor, 1.0f));
    }
    p.drawEllipse(QPointF(center, center), radius - 1, radius - 1);

    p.end();
    return fallback;
  }

  // 🎯 CARGAR TEXTURA REAL DEL PINCEL
  QString fullPath;
  if (QFileInfo(texturePath).isAbsolute() && QFile::exists(texturePath)) {
    fullPath = texturePath;
  } else {
    QStringList searchPaths;
    searchPaths << ":/assets/textures"
                << ":/assets/brushes"
                << "assets/textures"
                << "assets/brushes"
                << "src/assets/textures"
                << "src/assets/brushes"
                << QCoreApplication::applicationDirPath() + "/assets/textures"
                << QCoreApplication::applicationDirPath() + "/assets/brushes"
                << QCoreApplication::applicationDirPath() +
                       "/../assets/textures"
                << QCoreApplication::applicationDirPath() +
                       "/../assets/brushes"
                << QCoreApplication::applicationDirPath() + "/textures"
                << QCoreApplication::applicationDirPath() + "/brushes"
                << QStandardPaths::writableLocation(
                       QStandardPaths::AppDataLocation) +
                       "/imported_brushes";

    for (const QString &base : searchPaths) {
      QString candidate = base + "/" + texturePath;
      if (QFile::exists(candidate)) {
        fullPath = candidate;
        break;
      }
    }
  }

  if (fullPath.isEmpty() || !QFile::exists(fullPath)) {
    qDebug() << "loadAndProcessBrushTexture: Texture not found:" << texturePath;
    return loadAndProcessBrushTexture("", size, rotation, z,
                                      outline); // Fallback
  }

  // Cargar imagen original
  QImage original(fullPath);
  if (original.isNull()) {
    qDebug() << "loadAndProcessBrushTexture: Failed to load:" << fullPath;
    return loadAndProcessBrushTexture("", size, rotation, z, outline);
  }

  // Convertir a ARGB32 si no lo es
  if (original.format() != QImage::Format_ARGB32) {
    original = original.convertToFormat(QImage::Format_ARGB32);
  }

  // 🔥 PROCESAR: Calculate true alpha based on shader logic
  // (Luminance * Alpha) - where white/opaque is solid ink
  for (int y = 0; y < original.height(); y++) {
    for (int x = 0; x < original.width(); x++) {
      QColor pixel = original.pixelColor(x, y);

      // Obtener luminosidad (0-255)
      int luminance = qGray(pixel.red(), pixel.green(), pixel.blue());
      
      // Multiplicar por canal alfa real
      int finalAlpha = (luminance * pixel.alpha()) / 255;

      // Establecer como blanco con alpha variable
      if (finalAlpha > 10) { // Threshold para ruido
        original.setPixelColor(x, y, QColor(255, 255, 255, finalAlpha));
      } else {
        original.setPixelColor(x, y, QColor(0, 0, 0, 0));
      }
    }
  }

  // Escalar según el tamaño del pincel y zoom
  int targetSize = std::max(8, std::min((int)(size * z), 512));
  QImage scaled = original.scaled(targetSize, targetSize, Qt::KeepAspectRatio,
                                  Qt::SmoothTransformation);

  // Aplicar rotación si es necesario
  if (std::abs(rotation) > 0.1f) {
    QTransform transform;
    transform.translate(scaled.width() / 2.0, scaled.height() / 2.0);
    transform.rotate(rotation);
    transform.translate(-scaled.width() / 2.0, -scaled.height() / 2.0);
    scaled = scaled.transformed(transform, Qt::SmoothTransformation);
  }

  // 🎯 CREAR CONTORNO ESTILO PROFESIONAL (Solo borde, alta visibilidad)
  QImage canvas(scaled.width() + 4, scaled.height() + 4, QImage::Format_ARGB32);
  canvas.fill(Qt::transparent);

  QPainter p(&canvas);
  p.setRenderHint(QPainter::Antialiasing);
  p.setRenderHint(QPainter::SmoothPixmapTransform);

  if (outline) {
    // 1. Dibujar silueta en negro (Borde exterior para contraste)
    p.setCompositionMode(QPainter::CompositionMode_SourceOver);
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0)
          continue;
        p.setOpacity(0.6);
        p.drawImage(2 + dx, 2 + dy, scaled);
      }
    }

    // 2. Dibujar silueta en el color seleccionado (Borde interior)
    QImage colorized = scaled;
    {
      QPainter cp(&colorized);
      cp.setCompositionMode(QPainter::CompositionMode_SourceIn);
      cp.fillRect(colorized.rect(), m_brushColor);
      cp.end();
    }
    p.setOpacity(1.0);
    p.drawImage(2, 2, colorized);

    // 3. HACER HUECO (Vaciar el centro)
    p.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    p.drawImage(2, 2, scaled);
  } else {
    // Modo sólido (para previsualizaciones)
    p.drawImage(2, 2, scaled);
  }

  p.end();

  return canvas;
}

void CanvasItem::invalidateCursorCache() {
  m_cursorCacheDirty = true;
  m_brushOutlineCache = QImage();
  update();
}

void CanvasItem::setUseCustomCursor(bool use) {
  (void)use;
  setCursor(Qt::BlankCursor);
  invalidateCursorCache();
}

void CanvasItem::blendWithShader(QPainter *painter, artflow::Layer *layer,
                                 const QRectF &rect, artflow::Layer *maskLayer,
                                 uint32_t overrideTextureId) {
  if (!m_compositionShader || !layer)
    return;

  QOpenGLContext *ctx = QOpenGLContext::currentContext();
  if (!ctx)
    return;
  QOpenGLFunctions *f = ctx->functions();

  // ... (backdrop prep remains same) ...
  static GLuint backdropTexID = 0;
  if (backdropTexID == 0) {
    f->glGenTextures(1, &backdropTexID);
    f->glBindTexture(GL_TEXTURE_2D, backdropTexID);
    f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  }

  // Fix High DPI issues: glCopyTexImage2D uses physical pixels
  qreal dpr = window() ? window()->devicePixelRatio() : 1.0;
  int w = width() * dpr;
  int h = height() * dpr;

  // Ensure we are in Native Painting mode (flushes QPainter commands)
  painter->beginNativePainting();

  // 1. Capture current framebuffer (Backdrop)
  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, backdropTexID);

  // Check if size changed to reallocate texture storage if needed (though
  // copy does it) Important: Use Nearest neighbor for 1:1 pixel mapping to
  // avoid blurry backdrops
  f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  if (!m_isTransforming) {
    // Sólo capturamos el backdrop cuando realmente pintamos (blend modes)
    f->glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, w, h, 0);
  }

  // 2. Prepare Layer Texture
  QOpenGLTexture *layerTex = nullptr;
  if (overrideTextureId == 0) {
    auto getOrUpdateTexture = [&](artflow::Layer *L) -> QOpenGLTexture * {
      QOpenGLTexture *tex = m_layerTextures.value(L);
      if (!tex) {
        if (!L->buffer)
          return nullptr;
        // Crear textura vacía con formato comprimido de alta calidad DXT5 (BC3) para ahorrar memoria gráfica
        tex = new QOpenGLTexture(QOpenGLTexture::Target2D);
        tex->setFormat(QOpenGLTexture::RGBA_DXT5);
        tex->setSize(L->buffer->width(), L->buffer->height());
        tex->allocateStorage();

        QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                   QImage::Format_RGBA8888_Premultiplied);
        tex->setData(img);

        tex->setMinificationFilter(QOpenGLTexture::Linear);
        tex->setMagnificationFilter(QOpenGLTexture::Linear);
        tex->setWrapMode(QOpenGLTexture::ClampToBorder);
        tex->setBorderColor(QColor(0, 0, 0, 0));
        m_layerTextures.insert(L, tex);
        L->buffer->clearDirtyFlags();
        L->dirty = false;
      } else if (L->dirty) {
        if (!L->buffer)
          return tex;

        // Optimización por mosaicos (Tiled GPU Upload): Subir únicamente los tiles modificados
        if (tex->isCreated() && L->buffer->hasDirtyTiles()) {
          f->glBindTexture(GL_TEXTURE_2D, tex->textureId());
          const auto &tiles = L->buffer->getTiles();
          for (const auto &tile : tiles) {
            if (tile && tile->dirty) {
              f->glTexSubImage2D(GL_TEXTURE_2D, 0,
                                 tile->startX, tile->startY,
                                 artflow::ImageBuffer::TILE_SIZE, artflow::ImageBuffer::TILE_SIZE,
                                 GL_RGBA, GL_UNSIGNED_BYTE, tile->data.get());
            }
          }
          L->buffer->clearDirtyFlags();
          L->dirty = false;
        } else {
          // Fallback completo si la textura no ha sido reservada
          QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                     QImage::Format_RGBA8888_Premultiplied);
          tex->setData(img);
          L->buffer->clearDirtyFlags();
          L->dirty = false;
        }
      }
      return tex;
    };
    layerTex = getOrUpdateTexture(layer);
  }

  // 3. Prepare Mask Texture (if applicable)
  QOpenGLTexture *maskTex = nullptr;
  if (maskLayer) {
    // We always need the mask from its persistent buffer (not override)
    auto getOrUpdateTexture = [&](artflow::Layer *L) -> QOpenGLTexture * {
      QOpenGLTexture *tex = m_layerTextures.value(L);
      if (!tex) {
        if (!L->buffer)
          return nullptr;
        // Crear textura vacía con formato comprimido de alta calidad DXT5 (BC3) para ahorrar memoria gráfica
        tex = new QOpenGLTexture(QOpenGLTexture::Target2D);
        tex->setFormat(QOpenGLTexture::RGBA_DXT5);
        tex->setSize(L->buffer->width(), L->buffer->height());
        tex->allocateStorage();

        QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                   QImage::Format_RGBA8888_Premultiplied);
        tex->setData(img);

        tex->setMinificationFilter(QOpenGLTexture::Linear);
        tex->setMagnificationFilter(QOpenGLTexture::Linear);
        tex->setWrapMode(QOpenGLTexture::ClampToBorder);
        tex->setBorderColor(QColor(0, 0, 0, 0));
        m_layerTextures.insert(L, tex);
        L->buffer->clearDirtyFlags();
        L->dirty = false;
      } else if (L->dirty) {
        if (!L->buffer)
          return tex;

        // Optimización por mosaicos (Tiled GPU Upload): Subir únicamente los tiles modificados
        if (tex->isCreated() && L->buffer->hasDirtyTiles()) {
          f->glBindTexture(GL_TEXTURE_2D, tex->textureId());
          const auto &tiles = L->buffer->getTiles();
          for (const auto &tile : tiles) {
            if (tile && tile->dirty) {
              f->glTexSubImage2D(GL_TEXTURE_2D, 0,
                                 tile->startX, tile->startY,
                                 artflow::ImageBuffer::TILE_SIZE, artflow::ImageBuffer::TILE_SIZE,
                                 GL_RGBA, GL_UNSIGNED_BYTE, tile->data.get());
            }
          }
          L->buffer->clearDirtyFlags();
          L->dirty = false;
        } else {
          // Fallback completo si la textura no ha sido reservada
          QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                     QImage::Format_RGBA8888_Premultiplied);
          tex->setData(img);
          L->buffer->clearDirtyFlags();
          L->dirty = false;
        }
      }
      return tex;
    };
    maskTex = getOrUpdateTexture(maskLayer);
  }

  // 4. Bind & Draw
  m_compositionShader->bind();

  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, backdropTexID);
  m_compositionShader->setUniformValue("uBackdrop", 0);
  m_compositionShader->setUniformValue("uIsPreview",
                                       overrideTextureId != 0 ? 1.0f : 0.0f);

  f->glActiveTexture(GL_TEXTURE1);
  if (overrideTextureId != 0) {
    f->glBindTexture(GL_TEXTURE_2D, overrideTextureId);
  } else if (layerTex) {
    layerTex->bind();
  }
  m_compositionShader->setUniformValue("uSource", 1);

  if (maskTex) {
    f->glActiveTexture(GL_TEXTURE2);
    maskTex->bind();
    m_compositionShader->setUniformValue("uMask", 2);
    m_compositionShader->setUniformValue("uHasMask", 1);
  } else {
    m_compositionShader->setUniformValue("uHasMask", 0);
  }

  m_compositionShader->setUniformValue("uOpacity", layer->opacity);
  m_compositionShader->setUniformValue("uMode", (int)layer->blendMode);
  m_compositionShader->setUniformValue("uDrawPanelBorderOnly", 0);

  m_compositionShader->setUniformValue("uScreenSize", QVector2D(w, h));
  m_compositionShader->setUniformValue(
      "uLayerSize", QVector2D(layer->buffer->width(), layer->buffer->height()));
  m_compositionShader->setUniformValue(
      "uViewOffset", QVector2D(m_viewOffset.x(), m_viewOffset.y()));
  m_compositionShader->setUniformValue("uZoom", m_zoomLevel);

  float vertices[] = {
      -1.0f, -1.0f, 0.0f, 0.0f, 1.0f, -1.0f, 1.0f, 0.0f,
      -1.0f, 1.0f,  0.0f, 1.0f, 1.0f, 1.0f,  1.0f, 1.0f,
  };

  m_compositionShader->enableAttributeArray(0);
  m_compositionShader->enableAttributeArray(1);
  m_compositionShader->setAttributeArray(0, GL_FLOAT, vertices, 2,
                                         4 * sizeof(float));
  m_compositionShader->setAttributeArray(1, GL_FLOAT, vertices + 2, 2,
                                         4 * sizeof(float));

  f->glEnable(GL_BLEND);
  f->glBlendFunc(GL_ONE, GL_ZERO);

  f->glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

  m_compositionShader->disableAttributeArray(0);
  m_compositionShader->disableAttributeArray(1);

  m_compositionShader->release();
  layerTex->release();
  if (maskTex)
    maskTex->release();

  f->glActiveTexture(GL_TEXTURE0);
  f->glBindTexture(GL_TEXTURE_2D, 0);

  painter->endNativePainting();
}

// ══════════════════════════════════════════════════════════════
// Brush Studio — CRUD Operations
// ══════════════════════════════════════════════════════════════

void CanvasItem::createNewBrush(const QString &name, const QString &category) {
  auto *bpm = artflow::BrushPresetManager::instance();
  artflow::BrushPreset newPreset;
  newPreset.uuid = artflow::BrushPreset::generateUUID();
  newPreset.name = name.isEmpty() ? "New Brush" : name;
  newPreset.category = category.isEmpty() ? "Custom" : category;
  newPreset.defaultSize = 20.0f;
  newPreset.defaultOpacity = 1.0f;
  newPreset.defaultHardness = 0.8f;
  newPreset.stroke.spacing = 0.1f;
  newPreset.shape.roundness = 1.0f;

  bpm->addPreset(newPreset);

  QString dir = QCoreApplication::applicationDirPath() + "/brushes/user";
  QDir().mkpath(dir);
  bpm->savePreset(newPreset, dir);

  m_availableBrushes.clear();
  auto allP = bpm->allPresets();
  for (auto *p : allP) {
    QVariantMap m;
    m["name"] = p->name;
    m["category"] = p->category;
    m["uuid"] = p->uuid;
    m_availableBrushes.append(m);
  }
  emit availableBrushesChanged();
  emit brushCategoriesChanged();

  beginBrushEdit(newPreset.name);
}

bool CanvasItem::deleteBrush(const QString &name) {
  if (isBuiltInBrush(name))
    return false;

  // Eliminar de la caché de vistas previas
  m_brushPreviewCache.remove(name);

  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(name);
  if (!p)
    return false;

  QString uuid = p->uuid;
  QString dir = QCoreApplication::applicationDirPath() + "/brushes/user";
  QFile::remove(dir + "/" + name + ".json");
  bpm->removePreset(uuid);

  if (m_activeBrushName == name) {
    auto allP = bpm->allPresets();
    if (!allP.empty())
      usePreset(allP.front()->name);
  }

  m_availableBrushes.clear();
  auto allP = bpm->allPresets();
  for (auto *pr : allP) {
    QVariantMap m;
    m["name"] = pr->name;
    m["category"] = pr->category;
    m["uuid"] = pr->uuid;
    m_availableBrushes.append(m);
  }
  emit availableBrushesChanged();
  return true;
}

QString CanvasItem::duplicateBrush(const QString &name) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *src = bpm->findByName(name);
  if (!src)
    return QString();

  QString newName = name + " Copy";
  int suffix = 2;
  while (bpm->findByName(newName))
    newName = name + " Copy " + QString::number(suffix++);

  artflow::BrushPreset copy = bpm->duplicatePreset(src->uuid, newName);

  QString dir = QCoreApplication::applicationDirPath() + "/brushes/user";
  QDir().mkpath(dir);
  bpm->savePreset(copy, dir);

  m_availableBrushes.clear();
  auto allP = bpm->allPresets();
  for (auto *p : allP) {
    QVariantMap m;
    m["name"] = p->name;
    m["category"] = p->category;
    m["uuid"] = p->uuid;
    m_availableBrushes.append(m);
  }
  emit availableBrushesChanged();
  return copy.name;
}

bool CanvasItem::renameBrush(const QString &oldName, const QString &newName) {
  if (newName.trimmed().isEmpty())
    return false;
  if (isBuiltInBrush(oldName))
    return false;

  // Eliminar el viejo nombre de la caché de vistas previas
  m_brushPreviewCache.remove(oldName);

  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(oldName);
  if (!p)
    return false;

  artflow::BrushPreset updated = *p;
  updated.name = newName;

  QString dir = QCoreApplication::applicationDirPath() + "/brushes/user";
  QFile::remove(dir + "/" + oldName + ".json");
  bpm->updatePreset(updated);
  bpm->savePreset(updated, dir);

  if (m_activeBrushName == oldName) {
    m_activeBrushName = newName;
    emit activeBrushNameChanged();
  }
  if (m_isEditingBrush && m_editingPreset.name == oldName)
    m_editingPreset.name = newName;

  m_availableBrushes.clear();
  auto allP = bpm->allPresets();
  for (auto *pr : allP) {
    QVariantMap m;
    m["name"] = pr->name;
    m["category"] = pr->category;
    m["uuid"] = pr->uuid;
    m_availableBrushes.append(m);
  }
  emit availableBrushesChanged();
  return true;
}

bool CanvasItem::isBuiltInBrush(const QString &name) const {
  QString dir = QCoreApplication::applicationDirPath() + "/brushes/user";
  return !QFile::exists(dir + "/" + name + ".json");
}

// ══════════════════════════════════════════════════════════════
// Brush Studio — Texture Management
// ══════════════════════════════════════════════════════════════

QVariantList CanvasItem::getAvailableTipTextures() const {
  QVariantList result;
  
  // Define candidate search directories
  QStringList brushesCandidates;
  brushesCandidates << ":/assets/brushes"
                    << QCoreApplication::applicationDirPath() + "/assets/brushes"
                    << QCoreApplication::applicationDirPath() + "/../assets/brushes"
                    << QDir::currentPath() + "/assets/brushes";

  QStringList texturesCandidates;
  texturesCandidates << ":/assets/textures"
                     << QCoreApplication::applicationDirPath() + "/assets/textures"
                     << QCoreApplication::applicationDirPath() + "/../assets/textures"
                     << QDir::currentPath() + "/assets/textures";

  QStringList importedCandidates;
  importedCandidates << QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/imported_brushes";

  // Select the first existing path for each category to scan
  QStringList searchPaths;
  for (const QString &path : brushesCandidates) {
    if (QDir(path).exists()) {
      searchPaths << path;
      break;
    }
  }
  for (const QString &path : texturesCandidates) {
    if (QDir(path).exists()) {
      searchPaths << path;
      break;
    }
  }
  for (const QString &path : importedCandidates) {
    if (QDir(path).exists()) {
      searchPaths << path;
      break;
    }
  }

  QStringList filters;
  filters << "*.png" << "*.PNG";

  QSet<QString> addedFilenames;

  for (const QString &searchPath : searchPaths) {
    QDir dir(searchPath);
    const QStringList files = dir.entryList(filters, QDir::Files);
    for (const QString &file : files) {
      if (addedFilenames.contains(file))
        continue;
      addedFilenames.insert(file);

      QVariantMap entry;
      entry["name"] = QFileInfo(file).baseName();
      entry["filename"] = file;
      // Convert to file:/// URL string so QML Image can load it without protocol errors
      entry["path"] = QUrl::fromLocalFile(dir.absoluteFilePath(file)).toString();
      result.append(entry);
    }
  }
  return result;
}

void CanvasItem::setTipTextureForBrush(const QString &brushName,
                                       const QString &texturePath) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(brushName);
  
  // Convert local file URL string to standard native path if necessary
  QString localPath = texturePath;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(texturePath).toLocalFile();
  }
  QString filename = QFileInfo(localPath).fileName();

  if (p) {
    artflow::BrushPreset updated = *p;
    updated.shape.tipTexture = filename;
    bpm->updatePreset(updated);
  }
  if (m_isEditingBrush)
    m_editingPreset.shape.tipTexture = filename;

  updateBrushTipImage();
  emit brushPropertyChanged("shape", "tip_texture");
  applyEditingPresetToEngine();
}

void CanvasItem::setGrainTextureForBrush(const QString &brushName,
                                         const QString &texturePath) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(brushName);
  
  // Convert local file URL string to standard native path if necessary
  QString localPath = texturePath;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(texturePath).toLocalFile();
  }
  QString filename = QFileInfo(localPath).fileName();

  if (p) {
    artflow::BrushPreset updated = *p;
    updated.grain.texture = filename;
    if (updated.grain.intensity < 0.01f)
      updated.grain.intensity = 0.5f;
    if (updated.grain.scale < 0.01f)
      updated.grain.scale = 1.0f;
    bpm->updatePreset(updated);
  }
  if (m_isEditingBrush) {
    m_editingPreset.grain.texture = filename;
    if (m_editingPreset.grain.intensity < 0.01f)
      m_editingPreset.grain.intensity = 0.5f;
    if (m_editingPreset.grain.scale < 0.01f)
      m_editingPreset.grain.scale = 1.0f;
  }

  emit brushPropertyChanged("grain", "texture");
  applyEditingPresetToEngine();
}

void CanvasItem::setDualTipTextureForBrush(const QString &brushName,
                                          const QString &texturePath) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(brushName);
  
  QString localPath = texturePath;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(texturePath).toLocalFile();
  }
  QString filename = QFileInfo(localPath).fileName();

  if (p) {
    artflow::BrushPreset updated = *p;
    updated.dualBrush.tipTexture = filename;
    bpm->updatePreset(updated);
  }
  if (m_isEditingBrush) {
    m_editingPreset.dualBrush.tipTexture = filename;
  }

  emit brushPropertyChanged("dualbrush", "tip_texture");
  applyEditingPresetToEngine();
}

void CanvasItem::setDualGrainTextureForBrush(const QString &brushName,
                                            const QString &texturePath) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(brushName);
  
  QString localPath = texturePath;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(texturePath).toLocalFile();
  }
  QString filename = QFileInfo(localPath).fileName();

  if (p) {
    artflow::BrushPreset updated = *p;
    updated.dualBrush.grain.texture = filename;
    if (updated.dualBrush.grain.intensity < 0.01f)
      updated.dualBrush.grain.intensity = 0.5f;
    if (updated.dualBrush.grain.scale < 0.01f)
      updated.dualBrush.grain.scale = 1.0f;
    bpm->updatePreset(updated);
  }
  if (m_isEditingBrush) {
    m_editingPreset.dualBrush.grain.texture = filename;
    if (m_editingPreset.dualBrush.grain.intensity < 0.01f)
      m_editingPreset.dualBrush.grain.intensity = 0.5f;
    if (m_editingPreset.dualBrush.grain.scale < 0.01f)
      m_editingPreset.dualBrush.grain.scale = 1.0f;
  }

  emit brushPropertyChanged("dualbrush", "grain_texture");
  applyEditingPresetToEngine();
}

// ══════════════════════════════════════════════════════════════════
//  LIQUIFY TOOL — Implementation
// ══════════════════════════════════════════════════════════════════

void CanvasItem::beginLiquify() {
  if (m_isLiquifying)
    return; // Already active

  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer) {
    emit notificationRequested("No active layer for Liquify", "warning");
    return;
  }

  if (layer->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }

  // Create engine if needed
  if (!m_liquifyEngine)
    m_liquifyEngine = new artflow::LiquifyEngine();

  // Snapshot for undo
  m_liquifyBeforeBuffer = std::make_unique<ImageBuffer>(*layer->buffer);

  // Initialize the engine with the current layer data
  m_liquifyEngine->begin(*layer->buffer, m_canvasWidth, m_canvasHeight);

  m_isLiquifying = true;
  m_liquifyLastPos = QPointF(-1, -1);

  // Render initial preview (just the original)
  m_liquifyPreviewCache = QImage();

  emit isLiquifyingChanged();
  emit notificationRequested("Liquify active — drag to deform", "info");
  update();
}

void CanvasItem::applyLiquify() {
  if (!m_isLiquifying || !m_liquifyEngine)
    return;

  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer)
    return;

  // Get the final deformed image
  QImage result = m_liquifyEngine->end();

  if (!result.isNull()) {
    // Bake into the layer buffer
    const uint8_t *src = result.constBits();
    layer->buffer->loadRawData(src);
    layer->dirty = true;
  }

  // Push undo
  if (m_liquifyBeforeBuffer) {
    auto afterBuffer = std::make_unique<ImageBuffer>(*layer->buffer);
    auto cmd = std::make_unique<artflow::StrokeUndoCommand>(
        m_layerManager, m_activeLayerIndex, std::move(m_liquifyBeforeBuffer),
        std::move(afterBuffer));
    m_undoManager->pushCommand(std::move(cmd));
  }

  m_isLiquifying = false;
  m_liquifyPreviewCache = QImage();

  clearRenderCaches();
  emit isLiquifyingChanged();
  emit notificationRequested("Liquify applied", "success");

  // Switch back to previous tool
  setCurrentTool(m_previousToolStr);
  update();
}

void CanvasItem::cancelLiquify() {
  if (!m_isLiquifying || !m_liquifyEngine)
    return;

  Layer *layer = m_layerManager->getActiveLayer();

  // Restore original
  if (layer && layer->buffer && m_liquifyBeforeBuffer) {
    layer->buffer->copyFrom(*m_liquifyBeforeBuffer);
    layer->dirty = true;
  }

  m_liquifyEngine->end(); // Clears engine state
  m_liquifyBeforeBuffer.reset();
  m_isLiquifying = false;
  m_liquifyPreviewCache = QImage();

  clearRenderCaches();
  emit isLiquifyingChanged();
  emit notificationRequested("Liquify cancelled", "info");

  // Switch back to previous tool
  setCurrentTool(m_previousToolStr);
  update();
}

void CanvasItem::setLiquifyMode(int mode) {
  if (m_liquifyEngine)
    m_liquifyEngine->setMode(static_cast<artflow::LiquifyMode>(mode));
}

void CanvasItem::setLiquifyRadius(float radius) {
  if (m_liquifyEngine)
    m_liquifyEngine->setRadius(radius);
}

void CanvasItem::setLiquifyStrength(float strength) {
  if (m_liquifyEngine)
    m_liquifyEngine->setStrength(strength);
}

void CanvasItem::setLiquifyMorpher(float morpher) {
  if (m_liquifyEngine)
    m_liquifyEngine->setMorpher(morpher);
}

void CanvasItem::handleLiquifyDraw(const QPointF &canvasPos, float pressure) {
  if (!m_isLiquifying || !m_liquifyEngine || !m_liquifyEngine->isActive())
    return;

  float cx = static_cast<float>(canvasPos.x());
  float cy = static_cast<float>(canvasPos.y());

  // Use pressure to modulate effect
  float origStrength = m_liquifyEngine->strength();
  m_liquifyEngine->setStrength(origStrength * std::max(0.1f, pressure));

  if (m_liquifyLastPos.x() < 0) {
    // First dab — no direction yet, skip Push but apply stationary effects
    m_liquifyLastPos = canvasPos;
    m_liquifyEngine->applyBrush(cx, cy, cx, cy);
  } else {
    float prevX = static_cast<float>(m_liquifyLastPos.x());
    float prevY = static_cast<float>(m_liquifyLastPos.y());
    m_liquifyEngine->applyBrush(cx, cy, prevX, prevY);
    m_liquifyLastPos = canvasPos;
  }

  // Restore original strength
  m_liquifyEngine->setStrength(origStrength);

  // Update preview cache (throttled via requestUpdate)
  m_liquifyPreviewCache = m_liquifyEngine->renderPreview();
  requestUpdate();
}

void CanvasItem::renderLiquifyPreview(QPainter *painter,
                                      const QRectF &paperRect) {
  if (!m_isLiquifying || m_liquifyPreviewCache.isNull())
    return;

  painter->save();
  painter->setRenderHint(QPainter::SmoothPixmapTransform);
  painter->drawImage(paperRect, m_liquifyPreviewCache);
  painter->restore();
}

// =============================================================================
// WATERCOLOR ENGINE — Métodos auxiliares de CanvasItem
// =============================================================================

bool CanvasItem::isWatercolorBrush() const {
    const artflow::BrushPreset *preset = nullptr;
    if (m_isEditingBrush) {
        preset = &m_editingPreset;
    } else {
        auto *bpm = artflow::BrushPresetManager::instance();
        preset = bpm->findByName(m_activeBrushName);
    }
    if (!preset) {
        qWarning() << "isWatercolorBrush: Preset is NULL for active brush:" << m_activeBrushName;
        return false;
    }

    qWarning() << "isWatercolorBrush: Checking preset" << preset->name
               << "type =" << preset->type
               << "uuid =" << preset->uuid
               << "category =" << preset->category;

    if (!preset->type.isEmpty()) {
        bool res = (preset->type == "watercolor");
        qWarning() << "isWatercolorBrush: early type check returns:" << res;
        return res;
    }

    // Verificación por prefijo de UUID (todos los pinceles de acuarela tienen "wc-")
    if (preset->uuid.startsWith("wc-", Qt::CaseInsensitive)) {
        qWarning() << "isWatercolorBrush: matches UUID prefix 'wc-'. Returning true";
        return true;
    }

    // Verificación por nombre
    QString name = preset->name.toLower();
    if (name.contains("watercolor") || name.contains("acuarela") ||
        name.contains("aquarela")   || name.contains("aguada") ||
        name.contains("wet")        || name.contains("splatter")) {
        qWarning() << "isWatercolorBrush: matches name. Returning true";
        return true;
    }

    // Verificación por categoría
    QString cat = preset->category.toLower();
    if (cat.contains("watercolor") || cat.contains("acuarela") ||
        cat.contains("aquarela")   || cat.contains("water")) {
        return true;
    }

    // Verificación por wetness — umbral 0.20
    if (preset->wetMix.wetness > 0.20f) {
        return true;
    }

    return false;
}

WatercolorEngine::WatercolorParams CanvasItem::buildWatercolorParams() const {
    WatercolorEngine::WatercolorParams params;

    const artflow::BrushPreset *preset = nullptr;
    if (m_isEditingBrush) {
        preset = &m_editingPreset;
    } else {
        auto *bpm = artflow::BrushPresetManager::instance();
        preset = bpm->findByName(m_activeBrushName);
    }
    if (!preset) return params;

    // WetMixSettings
    params.blendOnly  = preset->wetMix.blendOnly;
    params.wetness    = preset->wetMix.wetness;
    params.pigment    = params.blendOnly ? 0.0f : std::max(0.1f, preset->wetMix.pigment);
    params.bleed      = preset->wetMix.bleed;
    params.dilution   = preset->wetMix.dilution;
    params.absorption = std::max(0.1f, preset->wetMix.absorptionRate);
    params.dryingRate = std::max(0.1f, preset->wetMix.dryingTime > 0.0f
                                       ? (1.0f / preset->wetMix.dryingTime)
                                       : 0.4f);
    params.colorMixing = preset->wetMix.colorMixing;
    params.paintAmount = preset->wetMix.paintAmount;
    params.colorStretch = preset->wetMix.colorStretch;
    params.blendMode = static_cast<int>(preset->blendMode);

    // PigmentSettings
    params.granulation = preset->pigment.granulation;

    // EdgeDarkeningSettings
    params.edgeDarkening = preset->edgeDarkening.enabled
                           ? preset->edgeDarkening.intensity
                           : 0.0f;

    // Grain intensity
    params.grainIntensity = preset->grain.intensity;
    params.grainScale     = preset->grain.scale;
    params.grainBrightness = preset->grain.brightness;
    params.grainContrast   = preset->grain.contrast;
    params.invertGrain     = preset->grain.invert;
    params.grainEmphasizeDensity = preset->grain.emphasizeDensity;

    return params;
}

QRectF CanvasItem::getLayerBoundingRect(artflow::Layer *layer) {
  if (!layer || !layer->buffer)
    return QRectF();
  int x = 0, y = 0, w = 0, h = 0;
  if (layer->buffer->getContentBounds(x, y, w, h)) {
    return QRectF(x, y, w, h);
  }
  return QRectF();
}

bool CanvasItem::lineIntersectsRect(const QLineF &line, const QRectF &rect) {
  if (rect.isEmpty())
    return false;

  // 1. Check if either endpoint is inside the rect
  if (rect.contains(line.p1()) || rect.contains(line.p2()))
    return true;

  // 2. Check intersection with the 4 boundary segments of the rectangle
  QLineF top(rect.topLeft(), rect.topRight());
  QLineF bottom(rect.bottomLeft(), rect.bottomRight());
  QLineF left(rect.topLeft(), rect.bottomLeft());
  QLineF right(rect.topRight(), rect.bottomRight());

  QPointF intersectPoint;
  if (line.intersects(top, &intersectPoint) == QLineF::BoundedIntersection)
    return true;
  if (line.intersects(bottom, &intersectPoint) == QLineF::BoundedIntersection)
    return true;
  if (line.intersects(left, &intersectPoint) == QLineF::BoundedIntersection)
    return true;
  if (line.intersects(right, &intersectPoint) == QLineF::BoundedIntersection)
    return true;

  return false;
}

PreviewPadItem::PreviewPadItem(QQuickItem *parent)
    : QQuickPaintedItem(parent), m_canvasItem(nullptr) {
  setAcceptHoverEvents(true);
  setAcceptedMouseButtons(Qt::LeftButton);
}

void PreviewPadItem::setCanvasItem(CanvasItem *item) {
  if (m_canvasItem == item)
    return;

  if (m_canvasItem) {
    disconnect(m_canvasItem, &CanvasItem::previewPadUpdated, this, nullptr);
  }

  m_canvasItem = item;

  if (m_canvasItem) {
    connect(m_canvasItem, &CanvasItem::previewPadUpdated, this, [this]() {
      update();
    });
  }

  emit canvasItemChanged();
  update();
}

void PreviewPadItem::paint(QPainter *painter) {
  if (!m_canvasItem) {
    painter->fillRect(boundingRect(), QColor(10, 10, 12));
    return;
  }

  QImage img = m_canvasItem->getPreviewPadRawImage();
  if (img.isNull()) {
    painter->fillRect(boundingRect(), QColor(10, 10, 12));
    return;
  }

  painter->drawImage(boundingRect(), img);
}

// ==================== AUTO-SAVE & CRASH RECOVERY SYSTEM ====================

static QString getAutoSaveDir() {
  QString path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/KromoStudioProjects/.autosave";
  QDir dir(path);
  if (!dir.exists()) {
    dir.mkpath(".");
  }
  return path;
}

void CanvasItem::setupAutoSave() {
  m_autoSaveTimer = new QTimer(this);
  m_autoSaveTimer->setInterval(120000); // 2 minutes
  connect(m_autoSaveTimer, &QTimer::timeout, this, &CanvasItem::handleAutoSave);
  m_autoSaveTimer->start();
}

void CanvasItem::handleAutoSave() {
  if (!m_projectDirty || m_isDrawing) {
    return;
  }

  qDebug() << "[AutoSave] Executing background auto-save...";
  syncGpuToCpu();

  QString autosaveName;
  if (!m_currentProjectPath.isEmpty()) {
    QFileInfo info(m_currentProjectPath);
    autosaveName = info.completeBaseName() + ".autosave.kromo";
  } else {
    autosaveName = "untitled_" + m_currentProjectName + ".autosave.kromo";
  }

  QString autosavePath = QDir(getAutoSaveDir()).filePath(autosaveName);

  QJsonObject obj;
  obj["title"] = m_currentProjectName;
  obj["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
  obj["width"] = m_canvasWidth;
  obj["height"] = m_canvasHeight;
  obj["version"] = 2; // Embedded Data format
  obj["originalPath"] = m_currentProjectPath;

  QJsonArray layersArray;
  if (m_layerManager) {
    for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
      Layer *layer = m_layerManager->getLayer(i);
      if (!layer)
        continue;

      QJsonObject layerObj;
      layerObj["name"] = QString::fromStdString(layer->name);
      layerObj["opacity"] = layer->opacity;
      layerObj["visible"] = layer->visible;
      layerObj["locked"] = layer->locked;
      layerObj["alphaLock"] = layer->alphaLock;
      layerObj["reference"] = layer->reference;
      layerObj["blendMode"] = (int)layer->blendMode;
      layerObj["type"] = (int)layer->type;

      // Serializar Screentone
      layerObj["screentoneEnabled"] = layer->screentoneEnabled;
      layerObj["screentoneDotSize"] = layer->screentoneDotSize;
      layerObj["screentoneAngle"] = layer->screentoneAngle;
      layerObj["screentoneContrast"] = layer->screentoneContrast;
      layerObj["screentoneType"] = layer->screentoneType;

      // Serializar Gradient Map
      layerObj["gradientMapEnabled"] = layer->gradientMapEnabled;
      layerObj["gradientMapPreset"] = QString::fromStdString(layer->gradientMapPreset);

      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
      QBuffer buffer;
      buffer.open(QIODevice::WriteOnly);
      if (img.save(&buffer, "PNG")) {
        QString b64 = QString::fromLatin1(buffer.data().toBase64());
        layerObj["data"] = b64;
        if (!layer->panelPath.isEmpty()) {
          layerObj["panelPath"] = serializePath(layer->panelPath);
        }
        layersArray.append(layerObj);
      }
    }
  }
  obj["layers"] = layersArray;

  // Serialize Animation
  if (m_animationManager) {
    QJsonObject animObj;
    animObj["fps"] = m_animationManager->fps();
    animObj["currentFrame"] = m_animationManager->currentFrame();

    QJsonArray tracksArr;
    for (const auto& track : m_animationManager->getTracks()) {
      QJsonObject trackObj;
      trackObj["name"] = QString::fromStdString(track.getName());

      QJsonArray keysArr;
      for (const auto& pair : track.getKeyframes()) {
        QJsonObject keyObj;
        keyObj["frame"] = pair.first;
        keyObj["duration"] = pair.second.getDuration();
        keyObj["opacity"] = pair.second.getOpacity();
        keyObj["transform"] = serializeTransform(pair.second.getTransform());
        
        Layer* layerRef = pair.second.getLayerRef();
        if (layerRef) {
          keyObj["layerId"] = (int)layerRef->stableId;
        } else {
          keyObj["layerId"] = -1;
        }
        keysArr.append(keyObj);
      }
      trackObj["keyframes"] = keysArr;
      tracksArr.append(trackObj);
    }
    animObj["tracks"] = tracksArr;
    obj["animation"] = animObj;
  }

  // Serialize PerspectiveRuler
  if (m_perspectiveRuler) {
    QJsonObject rulerObj;
    rulerObj["active"] = m_perspectiveRuler->active();
    rulerObj["type"] = m_perspectiveRuler->type();
    
    QJsonObject vp1Obj;
    vp1Obj["x"] = m_perspectiveRuler->vp1().x();
    vp1Obj["y"] = m_perspectiveRuler->vp1().y();
    vp1Obj["active"] = m_perspectiveRuler->vp1Active();
    rulerObj["vp1"] = vp1Obj;

    QJsonObject vp2Obj;
    vp2Obj["x"] = m_perspectiveRuler->vp2().x();
    vp2Obj["y"] = m_perspectiveRuler->vp2().y();
    vp2Obj["active"] = m_perspectiveRuler->vp2Active();
    rulerObj["vp2"] = vp2Obj;

    QJsonObject vp3Obj;
    vp3Obj["x"] = m_perspectiveRuler->vp3().x();
    vp3Obj["y"] = m_perspectiveRuler->vp3().y();
    vp3Obj["active"] = m_perspectiveRuler->vp3Active();
    rulerObj["vp3"] = vp3Obj;

    obj["perspectiveRuler"] = rulerObj;
  }

  // Generate composite thumbnail
  ImageBuffer composite(m_canvasWidth, m_canvasHeight);
  if (m_layerManager) {
    m_layerManager->compositeAll(composite);
  }
  QImage imgComp(composite.data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);

  QSize thumbSize(m_canvasWidth, m_canvasHeight);
  thumbSize.scale(300, 300, Qt::KeepAspectRatio);
  QImage thumbFinal(thumbSize, QImage::Format_ARGB32);
  if (m_backgroundColor.alpha() > 0) {
    thumbFinal.fill(m_backgroundColor);
  } else {
    thumbFinal.fill(Qt::white);
  }

  QPainter p(&thumbFinal);
  p.setRenderHint(QPainter::SmoothPixmapTransform);
  p.setRenderHint(QPainter::Antialiasing);
  QImage scaled = imgComp.scaled(thumbSize, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
  p.drawImage(0, 0, scaled);
  p.end();

  QBuffer thumbBuf;
  thumbBuf.open(QIODevice::WriteOnly);
  thumbFinal.save(&thumbBuf, "PNG");
  QString thumbB64 = QString::fromLatin1(thumbBuf.data().toBase64());
  obj["thumbnail"] = thumbB64;

  QFile file(autosavePath);
  if (file.open(QIODevice::WriteOnly)) {
    QJsonDocument doc(obj);
    file.write(doc.toJson(QJsonDocument::Compact));
    file.close();
    qDebug() << "[AutoSave] Saved copy to:" << autosavePath;
  } else {
    qWarning() << "[AutoSave] Could not write to" << autosavePath;
  }
}

bool CanvasItem::checkForAutosave() {
  QDir dir(getAutoSaveDir());
  QStringList filters;
  filters << "*.autosave.kromo" << "*.autosave.kstudio" << "*.autosave.aflow" << "*.autosave.artflow";
  return !dir.entryInfoList(filters, QDir::Files).isEmpty();
}

QVariantList CanvasItem::getAutosaveList() {
  QVariantList list;
  QDir dir(getAutoSaveDir());
  QStringList filters;
  filters << "*.autosave.kromo" << "*.autosave.kstudio" << "*.autosave.aflow" << "*.autosave.artflow";
  QFileInfoList entries = dir.entryInfoList(filters, QDir::Files, QDir::Time);
  for (const QFileInfo &info : entries) {
    QVariantMap item;
    item["name"] = info.completeBaseName().section('.', 0, 0);
    item["path"] = info.absoluteFilePath();
    item["date"] = info.lastModified().toString("dd MMM yyyy, hh:mm AP");
    list.append(item);
  }
  return list;
}

bool CanvasItem::recoverAutosave(const QString &autosavePath) {
  QString localPath = autosavePath;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(autosavePath).toLocalFile();
  }

  qDebug() << "[Recovery] Recovering project state from autosave:" << localPath;

  QFile file(localPath);
  if (!file.open(QIODevice::ReadOnly)) {
    return false;
  }

  QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
  file.close();
  QJsonObject obj = doc.object();

  int w = obj["width"].toInt();
  int h = obj["height"].toInt();
  if (w <= 0 || h <= 0) {
    w = 1920;
    h = 1080;
  }

  resizeCanvas(w, h);

  QJsonArray layersArray = obj["layers"].toArray();
  if (!layersArray.isEmpty()) {
    if (m_layerManager->getLayerCount() > 0) {
      m_layerManager->removeLayer(0);
    }

    for (const QJsonValue &val : layersArray) {
      QJsonObject layerObj = val.toObject();
      QString name = layerObj["name"].toString();

      int newIdx = m_layerManager->addLayer(name.toStdString());
      Layer *newLayer = m_layerManager->getLayer(newIdx);

      if (newLayer) {
        newLayer->opacity = (float)layerObj["opacity"].toDouble(1.0);
        newLayer->visible = layerObj["visible"].toBool(true);
        newLayer->locked = layerObj["locked"].toBool(false);
        newLayer->alphaLock = layerObj["alphaLock"].toBool(false);
        newLayer->reference = layerObj["reference"].toBool(false);
        newLayer->blendMode = (BlendMode)layerObj["blendMode"].toInt(0);
        newLayer->type = (Layer::Type)layerObj["type"].toInt(0);

        // Deserializar Screentone
        newLayer->screentoneEnabled = layerObj["screentoneEnabled"].toBool(false);
        newLayer->screentoneDotSize = (float)layerObj["screentoneDotSize"].toDouble(12.0);
        newLayer->screentoneAngle = (float)layerObj["screentoneAngle"].toDouble(0.785);
        newLayer->screentoneContrast = (float)layerObj["screentoneContrast"].toDouble(0.8);
        newLayer->screentoneType = layerObj["screentoneType"].toInt(0);

        // Deserializar Gradient Map
        newLayer->gradientMapEnabled = layerObj["gradientMapEnabled"].toBool(false);
        newLayer->gradientMapPreset = layerObj["gradientMapPreset"].toString("sunset").toStdString();

        if (layerObj.contains("panelPath")) {
          newLayer->panelPath = deserializePath(layerObj["panelPath"].toString());
        }

        QString b64Data = layerObj["data"].toString();
        if (!b64Data.isEmpty()) {
          QByteArray data = QByteArray::fromBase64(b64Data.toLatin1());
          QImage img;
          if (img.loadFromData(data, "PNG")) {
            img = img.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
            if (img.width() == w && img.height() == h) {
              newLayer->buffer->loadRawData(img.constBits());
            } else {
              QImage scaled = img.scaled(w, h, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
              scaled = scaled.convertToFormat(QImage::Format_RGBA8888_Premultiplied);
              newLayer->buffer->loadRawData(scaled.constBits());
            }
          }
        }
      }
    }
  }

  // Deserialize Animation
  if (m_animationManager) {
    m_animationManager->clear();
    if (obj.contains("animation")) {
      QJsonObject animObj = obj["animation"].toObject();
      m_animationManager->setFps(animObj["fps"].toInt(24));
      
      QJsonArray tracksArr = animObj["tracks"].toArray();
      for (const QJsonValue& trackVal : tracksArr) {
        QJsonObject trackObj = trackVal.toObject();
        QString trackName = trackObj["name"].toString("Track");
        
        m_animationManager->addTrack(trackName);
        int trackIdx = m_animationManager->getTrackCount() - 1;
        
        QJsonArray keysArr = trackObj["keyframes"].toArray();
        for (const QJsonValue& keyVal : keysArr) {
          QJsonObject keyObj = keyVal.toObject();
          int frame = keyObj["frame"].toInt(0);
          int duration = keyObj["duration"].toInt(1);
          float opacity = (float)keyObj["opacity"].toDouble(1.0);
          QTransform transform = deserializeTransform(keyObj["transform"].toArray());
          uint32_t layerId = (uint32_t)keyObj["layerId"].toInt(-1);
          
          Layer* layer = m_layerManager->getLayerByStableId(layerId);
          if (layer) {
            AnimationFrame frameData(layer, duration, opacity, transform);
            m_animationManager->getTracks()[trackIdx].addKeyframe(frame, frameData);
          }
        }
      }
      m_animationManager->setCurrentFrame(animObj["currentFrame"].toInt(0));
    }
  }

  // Deserialize PerspectiveRuler
  if (m_perspectiveRuler) {
    m_perspectiveRuler->setActive(false);
    m_perspectiveRuler->setType(2);
    m_perspectiveRuler->setVp1(QPointF(-1000.0, 540.0));
    m_perspectiveRuler->setVp2(QPointF(2920.0, 540.0));
    m_perspectiveRuler->setVp3(QPointF(960.0, -2000.0));
    m_perspectiveRuler->setVp1Active(true);
    m_perspectiveRuler->setVp2Active(true);
    m_perspectiveRuler->setVp3Active(true);

    if (obj.contains("perspectiveRuler")) {
      QJsonObject rulerObj = obj["perspectiveRuler"].toObject();
      m_perspectiveRuler->setActive(rulerObj["active"].toBool(false));
      m_perspectiveRuler->setType(rulerObj["type"].toInt(2));
      
      if (rulerObj.contains("vp1")) {
        QJsonObject vp = rulerObj["vp1"].toObject();
        m_perspectiveRuler->setVp1(QPointF(vp["x"].toDouble(-1000.0), vp["y"].toDouble(540.0)));
        m_perspectiveRuler->setVp1Active(vp["active"].toBool(true));
      }
      if (rulerObj.contains("vp2")) {
        QJsonObject vp = rulerObj["vp2"].toObject();
        m_perspectiveRuler->setVp2(QPointF(vp["x"].toDouble(2920.0), vp["y"].toDouble(540.0)));
        m_perspectiveRuler->setVp2Active(vp["active"].toBool(true));
      }
      if (rulerObj.contains("vp3")) {
        QJsonObject vp = rulerObj["vp3"].toObject();
        m_perspectiveRuler->setVp3(QPointF(vp["x"].toDouble(960.0), vp["y"].toDouble(-2000.0)));
        m_perspectiveRuler->setVp3Active(vp["active"].toBool(true));
      }
    }
  }

  QString originalPath = obj["originalPath"].toString();
  if (!originalPath.isEmpty()) {
    m_currentProjectPath = originalPath;
    m_currentProjectName = QFileInfo(originalPath).baseName();
  } else {
    m_currentProjectPath = "";
    m_currentProjectName = obj["title"].toString("Untitled");
  }

  emit currentProjectPathChanged();
  emit currentProjectNameChanged();
  updateLayersList();

  setProjectDirty(true);

  emit notificationRequested("Session recovered successfully", "success");
  
  fitToView();
  update();

  QFile::remove(localPath);
  return true;
}

void CanvasItem::discardAutosaves() {
  QDir dir(getAutoSaveDir());
  QStringList filters;
  filters << "*.autosave.kromo" << "*.autosave.kstudio" << "*.autosave.aflow" << "*.autosave.artflow";
  QFileInfoList entries = dir.entryInfoList(filters, QDir::Files);
  for (const QFileInfo &info : entries) {
    QFile::remove(info.absoluteFilePath());
  }
  qDebug() << "[AutoSave] Cleared all pending autosaves.";
}

void CanvasItem::setProjectDirty(bool dirty) {
  if (m_projectDirty != dirty) {
    m_projectDirty = dirty;
    emit projectDirtyChanged();
  }
}

// ==================== PSD EXPORTER SYSTEM ====================

static void write16(QDataStream &out, uint16_t val) {
  out << val;
}

static void write32(QDataStream &out, uint32_t val) {
  out << val;
}

static QByteArray getPsdBlendModeKey(BlendMode mode) {
  switch (mode) {
    case BlendMode::Normal: return "norm";
    case BlendMode::Multiply: return "mul ";
    case BlendMode::Screen: return "scrn";
    case BlendMode::Overlay: return "over";
    case BlendMode::Darken: return "dark";
    case BlendMode::Lighten: return "lite";
    case BlendMode::ColorDodge: return "div ";
    case BlendMode::ColorBurn: return "idiv";
    case BlendMode::HardLight: return "hLIt";
    case BlendMode::SoftLight: return "sLIt";
    case BlendMode::Difference: return "diff";
    default: return "norm";
  }
}

bool CanvasItem::exportPSD(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly)) {
    qWarning() << "exportPSD: Could not open file for writing:" << path;
    return false;
  }

  QDataStream out(&file);
  out.setByteOrder(QDataStream::BigEndian);

  // 1. File Header (26 bytes)
  out.writeRawData("8BPS", 4);
  write16(out, 1); // Version
  for (int i = 0; i < 6; ++i) out << (uint8_t)0; // Reserved
  write16(out, 4); // RGBA (4 channels)
  write32(out, m_canvasHeight);
  write32(out, m_canvasWidth);
  write16(out, 8); // 8 bits per channel
  write16(out, 3); // Color Mode: RGB

  // 2. Color Mode Data (4 bytes)
  write32(out, 0);

  // 3. Image Resources (4 bytes)
  write32(out, 0);

  // 4. Layer and Mask Information
  QList<Layer*> exportLayers;
  if (m_layerManager) {
    for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
      Layer *l = m_layerManager->getLayer(i);
      if (l && l->type != Layer::Type::Group && l->buffer) {
        exportLayers.append(l);
      }
    }
  }

  QByteArray layerInfoBytes;
  QBuffer layerInfoBuf(&layerInfoBytes);
  layerInfoBuf.open(QIODevice::WriteOnly);
  QDataStream layerInfoOut(&layerInfoBuf);
  layerInfoOut.setByteOrder(QDataStream::BigEndian);

  // Write Layer Records
  for (Layer *layer : exportLayers) {
    write32(layerInfoOut, 0); // Top
    write32(layerInfoOut, 0); // Left
    write32(layerInfoOut, m_canvasHeight); // Bottom
    write32(layerInfoOut, m_canvasWidth); // Right

    write16(layerInfoOut, 4); // 4 channels

    uint32_t channelLength = 2 + (m_canvasWidth * m_canvasHeight);
    
    // Channels: Red, Green, Blue, Alpha
    write16(layerInfoOut, 0); write32(layerInfoOut, channelLength);
    write16(layerInfoOut, 1); write32(layerInfoOut, channelLength);
    write16(layerInfoOut, 2); write32(layerInfoOut, channelLength);
    write16(layerInfoOut, -1); write32(layerInfoOut, channelLength);

    layerInfoOut.writeRawData("8BIM", 4);
    QByteArray blendKey = getPsdBlendModeKey(layer->blendMode);
    layerInfoOut.writeRawData(blendKey.constData(), 4);

    uint8_t opacityVal = qBound(0, qRound(layer->opacity * 255.0f), 255);
    layerInfoOut << opacityVal;

    uint8_t clippingVal = layer->clipped ? 1 : 0;
    layerInfoOut << clippingVal;

    uint8_t flagsVal = (layer->visible ? 0 : 2) | 8;
    layerInfoOut << flagsVal;

    layerInfoOut << (uint8_t)0; // Filler

    // Extra fields
    QString name = QString::fromStdString(layer->name);
    QByteArray nameBytes = name.toUtf8();
    int nameLen = nameBytes.length();
    int pascalStringLen = 1 + nameLen;
    int paddedPascalStringLen = pascalStringLen;
    while (paddedPascalStringLen % 4 != 0) paddedPascalStringLen++;

    uint32_t extraFieldsLength = 4 + 4 + paddedPascalStringLen;
    write32(layerInfoOut, extraFieldsLength);

    write32(layerInfoOut, 0); // Mask data length
    write32(layerInfoOut, 0); // Blending ranges length

    // Pascal name string with padding
    layerInfoOut << (uint8_t)nameLen;
    layerInfoOut.writeRawData(nameBytes.constData(), nameLen);
    int paddingBytes = paddedPascalStringLen - pascalStringLen;
    for (int p = 0; p < paddingBytes; ++p) {
      layerInfoOut << (uint8_t)0;
    }
  }

  // Write Channel Image Data
  int totalPixels = m_canvasWidth * m_canvasHeight;
  for (Layer *layer : exportLayers) {
    const uint8_t *pixels = layer->buffer->data();

    // Red Channel
    write16(layerInfoOut, 0);
    for (int p = 0; p < totalPixels; ++p) {
      uint8_t a = pixels[p * 4 + 3];
      uint8_t r = pixels[p * 4 + 0];
      if (a > 0 && a < 255) {
        r = qBound(0, qRound((r * 255.0) / a), 255);
      }
      layerInfoOut << r;
    }

    // Green Channel
    write16(layerInfoOut, 0);
    for (int p = 0; p < totalPixels; ++p) {
      uint8_t a = pixels[p * 4 + 3];
      uint8_t g = pixels[p * 4 + 1];
      if (a > 0 && a < 255) {
        g = qBound(0, qRound((g * 255.0) / a), 255);
      }
      layerInfoOut << g;
    }

    // Blue Channel
    write16(layerInfoOut, 0);
    for (int p = 0; p < totalPixels; ++p) {
      uint8_t a = pixels[p * 4 + 3];
      uint8_t b = pixels[p * 4 + 2];
      if (a > 0 && a < 255) {
        b = qBound(0, qRound((b * 255.0) / a), 255);
      }
      layerInfoOut << b;
    }

    // Alpha Channel
    write16(layerInfoOut, 0);
    for (int p = 0; p < totalPixels; ++p) {
      layerInfoOut << pixels[p * 4 + 3];
    }
  }

  layerInfoBuf.close();

  // Write Layer Info section to file
  uint32_t layerInfoSectionLength = 4 + 2 + layerInfoBytes.size();
  uint32_t totalSectionLength = 4 + layerInfoSectionLength + 4;

  write32(out, totalSectionLength);
  write32(out, layerInfoSectionLength);
  write16(out, (int16_t)exportLayers.size());
  out.writeRawData(layerInfoBytes.constData(), layerInfoBytes.size());
  write32(out, 0); // Global layer mask length

  // 5. Global/Merged Image Data Section
  ImageBuffer composite(m_canvasWidth, m_canvasHeight);
  if (m_layerManager) {
    m_layerManager->compositeAll(composite);
  }
  const uint8_t *compPixels = composite.data();

  write16(out, 0); // Raw compression

  // Red
  for (int p = 0; p < totalPixels; ++p) {
    uint8_t a = compPixels[p * 4 + 3];
    uint8_t r = compPixels[p * 4 + 0];
    if (a > 0 && a < 255) {
      r = qBound(0, qRound((r * 255.0) / a), 255);
    }
    out << r;
  }

  // Green
  for (int p = 0; p < totalPixels; ++p) {
    uint8_t a = compPixels[p * 4 + 3];
    uint8_t g = compPixels[p * 4 + 1];
    if (a > 0 && a < 255) {
      g = qBound(0, qRound((g * 255.0) / a), 255);
    }
    out << g;
  }

  // Blue
  for (int p = 0; p < totalPixels; ++p) {
    uint8_t a = compPixels[p * 4 + 3];
    uint8_t b = compPixels[p * 4 + 2];
    if (a > 0 && a < 255) {
      b = qBound(0, qRound((b * 255.0) / a), 255);
    }
    out << b;
  }

  // Alpha
  for (int p = 0; p < totalPixels; ++p) {
    out << compPixels[p * 4 + 3];
  }

  file.close();
  qDebug() << "[PSD Export] PSD file successfully exported to:" << path;
  return true;
}

void CanvasItem::setMagneticEdgeSensitivity(float value) {
  if (qFuzzyCompare(m_magneticEdgeSensitivity, value)) return;
  m_magneticEdgeSensitivity = value;
  if (m_edgeDetector) {
    m_edgeDetector->setEdgeSensitivity(value);
  }
  emit magneticEdgeSensitivityChanged();
}

void CanvasItem::setMagneticSearchRadius(int value) {
  if (m_magneticSearchRadius == value) return;
  m_magneticSearchRadius = value;
  if (m_edgeDetector) {
    m_edgeDetector->setSearchRadius(value);
  }
  emit magneticSearchRadiusChanged();
}

void CanvasItem::selectByColorRange(const QColor &color, float tolerance, int channelMode, float fuzziness, bool invert) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer) return;

  QImage layerImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888);
  ColorRangeSelector selector;
  QImage mask = selector.selectByColor(layerImg, color, tolerance, channelMode, fuzziness, invert);
  QPainterPath selectionPath = selector.maskToPath(mask);

  QPainterPath beforePath = m_selectionPath;
  bool beforeHasSel = m_hasSelection;

  if (m_selectionAddMode == 0) {
    m_selectionPath = selectionPath;
  } else if (m_selectionAddMode == 1) {
    m_selectionPath = m_selectionPath.united(selectionPath);
  } else if (m_selectionAddMode == 2) {
    m_selectionPath = m_selectionPath.subtracted(selectionPath);
  }

  m_hasSelection = !m_selectionPath.isEmpty();
  emit hasSelectionChanged();

  if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
    m_marchingAntsTimer->start();
  else if (!m_hasSelection && m_marchingAntsTimer)
    m_marchingAntsTimer->stop();

  update();

  auto updateSelCb = [this](const QPainterPath &path, bool hasSel) {
    m_selectionPath = path;
    m_hasSelection = hasSel;
    emit hasSelectionChanged();
    if (m_hasSelection && m_marchingAntsTimer && !m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
    else if (!m_hasSelection && m_marchingAntsTimer)
      m_marchingAntsTimer->stop();
    update();
  };

  if (m_undoManager) {
    m_undoManager->pushCommand(std::make_unique<artflow::SelectionUndoCommand>(
        updateSelCb, beforePath, beforeHasSel, m_selectionPath, m_hasSelection));
  }
}

QString CanvasItem::getColorRangePreview(const QColor &color, float tolerance, int channelMode, float fuzziness, bool invert) {
  Layer *layer = m_layerManager->getActiveLayer();
  if (!layer || !layer->buffer) return QString();

  QImage layerImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight, QImage::Format_RGBA8888);
  ColorRangeSelector selector;
  QImage mask = selector.selectByColor(layerImg, color, tolerance, channelMode, fuzziness, invert);
  QImage preview = selector.previewMask(layerImg, mask);

  // Convert QImage to Base64 PNG
  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  preview.save(&buffer, "PNG");
  return QString("data:image/png;base64,") + ba.toBase64();
}

void CanvasItem::syncPerspectiveLayer() {
  if (!m_layerManager || !m_perspectiveRuler) return;

  // 1. Search for an existing layer named "Capa no destructiva"
  artflow::Layer *perspLayer = nullptr;
  int perspLayerIdx = -1;
  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    artflow::Layer *l = m_layerManager->getLayer(i);
    if (l && l->name == "Capa no destructiva") {
      perspLayer = l;
      perspLayerIdx = i;
      break;
    }
  }

  bool active = m_perspectiveRuler->active();

  if (active) {
    // If perspective guides are active, ensure the "Capa no destructiva" layer exists and is visible!
    if (!perspLayer) {
      // Add layer at the top of the stack
      perspLayerIdx = m_layerManager->addLayer("Capa no destructiva");
      perspLayer = m_layerManager->getLayer(perspLayerIdx);
      if (perspLayer) {
        perspLayer->visible = true;
      }
      updateLayersList();
    } else {
      if (!perspLayer->visible) {
        perspLayer->visible = true;
        updateLayersList();
      }
    }
  } else {
    // If perspective guides are inactive, and "Capa no destructiva" exists, hide it!
    if (perspLayer && perspLayer->visible) {
      perspLayer->visible = false;
      updateLayersList();
    }
  }
}
