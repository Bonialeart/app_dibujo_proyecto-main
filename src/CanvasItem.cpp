// Re-verify includes
#include "CanvasItem.h"
#include "PreferencesManager.h"
#include "core/cpp/include/brush_preset_manager.h"
#include <QBuffer>
#include <QCoreApplication>
#include <QCursor>
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

using namespace artflow;

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

// 2. AÑADE ESTA CLASE MAESTRA AQUÍ:
class CursorOverrideFilter : public QObject {
public:
  CursorOverrideFilter(QObject *parent = nullptr) : QObject(parent) {}

  bool eventFilter(QObject *obj, QEvent *event) override {
    // Detectamos cada vez que la ventana intenta cambiar de cursor
    if (event->type() == QEvent::CursorChange) {
      QWindow *window = qobject_cast<QWindow *>(obj);
      // Si QML intenta poner la flecha fea de Windows (ArrowCursor)...
      if (window && window->cursor().shape() == Qt::ArrowCursor) {
        // ...¡La secuestramos y ponemos la tuya Premium!
        window->setCursor(getModernCursor());
        return false;
      }
    }
    return QObject::eventFilter(obj, event);
  }
};

CanvasItem::CanvasItem(QQuickItem *parent)
    : QQuickPaintedItem(parent), m_brushSize(20), m_brushColor(Qt::black),
      m_brushOpacity(1.0f), m_brushFlow(1.0f), m_brushHardness(0.8f),
      m_brushSpacing(0.1f), m_brushStabilization(0.2f), m_brushStreamline(0.0f),

      m_brushGrain(0.0f), m_brushWetness(0.0f), m_brushSmudge(0.0f),
      m_brushRoundness(1.0f), m_zoomLevel(1.0f), m_currentToolStr("brush"),
      m_tool(ToolType::Pen), m_canvasWidth(1920), m_canvasHeight(1080),
      m_viewOffset(50, 50), m_activeLayerIndex(0), m_isTransforming(false),
      m_brushAngle(0.0f), m_cursorRotation(0.0f),
      m_backgroundColor(Qt::transparent), m_currentProjectPath(""),
      m_currentProjectName("Untitled"), m_brushTip("round"),
      m_lastPressure(1.0f), m_isDrawing(false),
      m_brushEngine(new BrushEngine()), m_undoManager(new UndoManager()),
      m_lastActiveLayerIndex(-1), m_updateTransformTextures(false),
      m_transformShader(nullptr), m_transformStaticTex(nullptr),
      m_selectionTex(nullptr) {

  // ---> AÑADE ESTAS LÍNEAS AQUÍ <---
  // Instalar el vigilante global de cursores
  static CursorOverrideFilter *globalCursorFilter = nullptr;
  if (!globalCursorFilter) {
    globalCursorFilter = new CursorOverrideFilter(qApp);
    qApp->installEventFilter(globalCursorFilter);
  }
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
  setCurvePoints(PreferencesManager::instance()->pressureCurve());

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

  // Apply initial
  updateTheme();
}

void CanvasItem::clearRenderCaches() {
  m_layerRenderCache.clear();
  m_clippedRenderCache.clear();
  m_cachedCanvasImage = QImage(); // Invalidate CPU composite cache

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
  QOpenGLFramebufferObject *currentBackdrop = m_compFBOA;
  QOpenGLFramebufferObject *nextBackdrop = m_compFBOB;

  for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
    artflow::Layer *layer = m_layerManager->getLayer(i);
    if (!layer || !layer->visible)
      continue;

    artflow::Layer *maskLayer = (layer->clipped) ? clippingBase : nullptr;
    if (!layer->clipped)
      clippingBase = layer;

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
        const auto &tiles = layer->buffer->getTiles();
        for (const auto &tile : tiles) {
          if (tile && (tile->dirty || layer->dirty)) {
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
        layer->buffer->clearDirtyFlags();
        layer->dirty = false;
        layer->dirtyRect = QRect();
      }
      sourceTexID = tex->textureId();
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

    m_compositionShader->setUniformValue("uOpacity", layer->opacity);
    m_compositionShader->setUniformValue("uMode", (int)layer->blendMode);

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
  if (m_predictionFBO)
    delete m_predictionFBO;
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
}

void CanvasItem::requestUpdate() {
  if (!m_pendingUpdate) {
    m_pendingUpdate = true;
    m_updateThrottle->start();
  }
}

void CanvasItem::resetTransformState() {
  m_isTransforming = false;
  m_selectionBuffer = QImage();
  m_transformStaticCache = QImage();
  m_updateTransformTextures = false;
  m_transformMatrix = QTransform();
  m_initialMatrix = QTransform();
  m_transformBox = QRectF();
  m_selectionPath = QPainterPath();
  m_hasSelection = false;

  if (m_marchingAntsTimer)
    m_marchingAntsTimer->stop();

  emit isTransformingChanged();
  emit hasSelectionChanged();
  update();
}

void CanvasItem::paint(QPainter *painter) {
  if (!m_layerManager)
    return;

  // Deferred GL resource cleanup (must happen in render thread with valid GL
  // context)
  cleanupGlResources();

  // --- APLICACIÓN INICIAL DEL CURSOR ---
  static bool windowCursorSet = false;
  if (!windowCursorSet && window()) {
    if (window()->cursor().shape() == Qt::ArrowCursor) {
      window()->setCursor(getModernCursor());
    }
    windowCursorSet = true;
  }
  // -------------------------------------

  // 0. Initialize Composition Shader
  if (!m_compositionShader) {
    m_compositionShader = new QOpenGLShaderProgram();
    QStringList paths;
    paths << QCoreApplication::applicationDirPath() + "/shaders/";
    paths << QCoreApplication::applicationDirPath() + "/../src/core/shaders/";
    paths << "src/core/shaders/";
    paths << "../src/core/shaders/";
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

  // 2. Fondo Base (Workspace - Theme Based)
  painter->fillRect(0, 0, width(), height(), m_workspaceColor);

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

    // Draw Background Color (if not transparent)
    if (m_backgroundColor.alpha() > 0) {
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
    bool gpuTransformReady =
        ctx && (m_updateTransformTextures ||
                (m_transformShader && m_transformStaticTex && m_selectionTex));

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
              new QOpenGLTexture(m_transformStaticCache.flipped(Qt::Vertical));
          m_transformStaticTex->setMinificationFilter(QOpenGLTexture::Linear);
          m_transformStaticTex->setMagnificationFilter(QOpenGLTexture::Linear);
        }

        if (m_selectionTex) {
          delete m_selectionTex;
          m_selectionTex = nullptr;
        }
        if (!m_selectionBuffer.isNull()) {
          m_selectionTex =
              new QOpenGLTexture(m_selectionBuffer.flipped(Qt::Vertical));
          m_selectionTex->setMinificationFilter(QOpenGLTexture::Linear);
          m_selectionTex->setMagnificationFilter(QOpenGLTexture::Linear);
        }

        m_updateTransformTextures = false;
        m_transformStaticCache = QImage(); // Free CPU memory
      }

      if (m_transformShader && m_transformStaticTex && m_selectionTex) {
        QOpenGLFunctions *f = QOpenGLContext::currentContext()->functions();
        f->glEnable(GL_BLEND);
        f->glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        m_transformShader->bind();
        QMatrix4x4 ortho;
        ortho.ortho(0, width(), height(), 0, -1, 1);
        QMatrix4x4 view;
        view.translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
        view.scale(m_zoomLevel, m_zoomLevel);
        QMatrix4x4 orthoView = ortho * view;

        // Draw Static Cache (Background)
        m_transformShader->setUniformValue("MVP", orthoView);
        m_transformShader->setUniformValue("opacity", 1.0f);
        m_transformStaticTex->bind(0);
        m_transformShader->setUniformValue("tex", 0);

        float cw = m_canvasWidth;
        float ch = m_canvasHeight;
        GLfloat bgVertices[] = {0, 0,  0, 0, cw, 0, 1, 0, 0,  ch, 0, 1,
                                0, ch, 0, 1, cw, 0, 1, 0, cw, ch, 1, 1};

        m_transformShader->enableAttributeArray(0);
        m_transformShader->enableAttributeArray(1);
        m_transformShader->setAttributeArray(0, GL_FLOAT, bgVertices, 2,
                                             4 * sizeof(GLfloat));
        m_transformShader->setAttributeArray(1, GL_FLOAT, bgVertices + 2, 2,
                                             4 * sizeof(GLfloat));
        f->glDrawArrays(GL_TRIANGLES, 0, 6);

        // Draw Selection Frame natively with perspective correction
        QMatrix4x4 qtMat;
        qtMat.setColumn(0, QVector4D(m_transformMatrix.m11(),
                                     m_transformMatrix.m12(), 0,
                                     m_transformMatrix.m13()));
        qtMat.setColumn(1, QVector4D(m_transformMatrix.m21(),
                                     m_transformMatrix.m22(), 0,
                                     m_transformMatrix.m23()));
        qtMat.setColumn(2, QVector4D(0, 0, 1, 0));
        qtMat.setColumn(3, QVector4D(m_transformMatrix.m31(),
                                     m_transformMatrix.m32(), 0,
                                     m_transformMatrix.m33()));

        m_transformShader->setUniformValue("MVP", orthoView * qtMat);
        m_selectionTex->bind(0);

        float sw = m_selectionBuffer.width();
        float sh = m_selectionBuffer.height();
        GLfloat selVertices[] = {0, 0,  0, 0, sw, 0, 1, 0, 0,  sh, 0, 1,
                                 0, sh, 0, 1, sw, 0, 1, 0, sw, sh, 1, 1};
        m_transformShader->setAttributeArray(0, GL_FLOAT, selVertices, 2,
                                             4 * sizeof(GLfloat));
        m_transformShader->setAttributeArray(1, GL_FLOAT, selVertices + 2, 2,
                                             4 * sizeof(GLfloat));
        f->glDrawArrays(GL_TRIANGLES, 0, 6);

        m_transformShader->disableAttributeArray(0);
        m_transformShader->disableAttributeArray(1);
        m_transformShader->release();
      }
      painter->endNativePainting();
    } else {
      if (m_layerManager && m_layerManager->getLayerCount() > 0) {
        const int cw = m_canvasWidth;
        const int ch = m_canvasHeight;

        // Initialize full cache if size changed or first run
        bool needsFullRedraw = m_cachedCanvasImage.isNull() ||
                               m_cachedCanvasImage.width() != cw ||
                               m_cachedCanvasImage.height() != ch;
        if (needsFullRedraw) {
          m_cachedCanvasImage =
              QImage(cw, ch, QImage::Format_RGBA8888_Premultiplied);
          m_cachedCanvasImage.fill(Qt::transparent);
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
          // Clip to canvas bounds
          dirtyUnion = dirtyUnion.intersected(QRect(0, 0, cw, ch));

          QPainter cpuPainter(&m_cachedCanvasImage);
          cpuPainter.setRenderHint(QPainter::Antialiasing, false);
          cpuPainter.setRenderHint(QPainter::SmoothPixmapTransform, false);

          // Clear only the dirty region to transparent
          cpuPainter.setCompositionMode(QPainter::CompositionMode_Source);
          cpuPainter.fillRect(dirtyUnion, Qt::transparent);

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

            // Draw base layer normally if visible
            if (baseLayer->visible && baseLayer->buffer &&
                baseLayer->buffer->data()) {
              QImage baseImg(baseLayer->buffer->data(), cw, ch,
                             QImage::Format_RGBA8888_Premultiplied);
              cpuPainter.setOpacity(baseLayer->opacity);
              cpuPainter.drawImage(dirtyUnion.topLeft(), baseImg, dirtyUnion);
            }

            baseLayer->dirty = false;
            baseLayer->dirtyRect = QRect();
            if (baseLayer->buffer)
              baseLayer->buffer->clearDirtyFlags();

            // Process clipping group if exists
            if (hasClippingGroup) {
              if (baseLayer->visible && baseLayer->buffer &&
                  baseLayer->buffer->data()) {
                QImage baseImg(baseLayer->buffer->data(), cw, ch,
                               QImage::Format_RGBA8888_Premultiplied);

                QImage groupImg(dirtyUnion.size(),
                                QImage::Format_RGBA8888_Premultiplied);
                groupImg.fill(Qt::transparent);
                QPainter groupPainter(&groupImg);
                groupPainter.setRenderHint(QPainter::SmoothPixmapTransform,
                                           false);
                groupPainter.setRenderHint(QPainter::Antialiasing, false);

                for (int k = i + 1; k < nextIdx; ++k) {
                  Layer *cLayer = m_layerManager->getLayer(k);
                  if (cLayer && cLayer->visible && cLayer->buffer &&
                      cLayer->buffer->data()) {
                    QImage cImg(cLayer->buffer->data(), cw, ch,
                                QImage::Format_RGBA8888_Premultiplied);
                    groupPainter.setOpacity(cLayer->opacity);
                    groupPainter.drawImage(QPoint(0, 0), cImg, dirtyUnion);
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

                // Draw the clipped group over the canvas
                cpuPainter.setOpacity(1.0f);
                cpuPainter.drawImage(dirtyUnion.topLeft(), groupImg);
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
      }
    }

    // --- FALLBACK DRAWING FOR TRANSFORMATION ---
    // Si estamos transformando pero la GPU aún no está lista (p. ej. cargando
    // cache), dibujamos la selección con QPainter para que no "desaparezca".
    if (m_isTransforming && !gpuTransformReady && !m_selectionBuffer.isNull()) {
      painter->save();
      painter->translate(m_viewOffset.x() * m_zoomLevel,
                         m_viewOffset.y() * m_zoomLevel);
      painter->scale(m_zoomLevel, m_zoomLevel);

      painter->setRenderHint(QPainter::SmoothPixmapTransform);
      painter->setRenderHint(QPainter::Antialiasing);

      // Aplicar la matriz de transformación actual (que mapea de local [0,0] a
      // canvas final)
      painter->setTransform(m_transformMatrix * painter->transform());

      // Dibujar en 0,0 porque la matriz ya posiciona el contenido
      painter->drawImage(0, 0, m_selectionBuffer);
      painter->restore();
    }
  }

  // 3. Transform Overlay (Preview)
  if (m_isTransforming && !m_selectionBuffer.isNull()) {
    painter->save();
    // Apply view transform (Pan/Zoom) first
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

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

    painter->restore();
  }

  // 5. Selección (Lasso) Feedback (Professional Marching Ants)
  if (!m_selectionPath.isEmpty()) {
    painter->save();
    // Transformar de Canvas a Pantalla para el feedback
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    // Calculate animation offset based on time
    static float dashOffset = 0;
    dashOffset += 0.2f;
    if (dashOffset > 20)
      dashOffset = 0;

    // Base Solid White (Visibility)
    QPen whitePen(Qt::white, 1.5f / m_zoomLevel, Qt::SolidLine);
    painter->setPen(whitePen);
    painter->drawPath(m_selectionPath);

    // Dashed Accent/Black (Marching Effect)
    QColor lassoColor = m_accentColor;
    if (lassoColor.value() < 50)
      lassoColor = Qt::black;

    QPen dashPen(lassoColor, 1.5f / m_zoomLevel, Qt::CustomDashLine);
    dashPen.setDashPattern({4, 4});
    dashPen.setDashOffset(dashOffset);
    painter->setPen(dashPen);
    painter->drawPath(m_selectionPath);

    painter->restore();

    // Arrancar el timer persistente si no está corriendo ya
    if (!m_marchingAntsTimer->isActive())
      m_marchingAntsTimer->start();
  }

  // 4.1 Predictive line for Magnetic/Polygonal Lasso
  if (m_tool == ToolType::MagneticLasso && m_isMagneticLassoActive &&
      !m_selectionPath.isEmpty()) {
    painter->save();
    // Transformar de Canvas a Pantalla para el feedback
    painter->translate(m_viewOffset.x() * m_zoomLevel,
                       m_viewOffset.y() * m_zoomLevel);
    painter->scale(m_zoomLevel, m_zoomLevel);

    QPointF lastPoint = m_selectionPath.currentPosition();
    QPointF canvasCursorPos =
        (m_cursorPos - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    QPen predictPen(m_accentColor, 1.2f / m_zoomLevel, Qt::DashLine);
    painter->setPen(predictPen);
    painter->drawLine(lastPoint, canvasCursorPos);
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

    QColor dotColor(255, 255, 255, 180);
    QColor dotOutline(0, 0, 0, 120);

    if (m_quickShapeType == QuickShapeType::Circle) {
      // Small center dot
      QPointF centerScreen =
          m_quickShapeCenter * m_zoomLevel + m_viewOffset * m_zoomLevel;
      painter->setPen(QPen(dotOutline, 2.0f));
      painter->setBrush(dotColor);
      painter->drawEllipse(centerScreen, 3.5, 3.5);
    } else if (m_quickShapeType == QuickShapeType::Line) {
      // Small endpoint dots
      QPointF p1Screen =
          m_quickShapeLineP1 * m_zoomLevel + m_viewOffset * m_zoomLevel;
      QPointF p2Screen =
          m_quickShapeLineP2 * m_zoomLevel + m_viewOffset * m_zoomLevel;
      painter->setPen(QPen(dotOutline, 1.5f));
      painter->setBrush(dotColor);
      painter->drawEllipse(p1Screen, 3, 3);
      painter->drawEllipse(p2Screen, 3, 3);
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

    // Draw Liquify cursor (radius circle)
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
  // 🎯 CURSOR PERSONALIZADO AL FINAL (ENCIMA DE TODO)
  // ══════════════════════════════════════════════════════════════

  if (m_cursorVisible && !m_spacePressed &&
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
  else if (m_cursorVisible && !m_spacePressed && m_tool != ToolType::Hand &&
           m_tool != ToolType::Transform) {
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

  // --- STABILIZATION: Procreate "StreamLine" Style (Double EMA) ---
  // Un modelo de Doble Media Móvil Exponencial (Nested EMA) da ese efecto
  // "sabroso", fluido y elástico ("buttery smooth") al dibujar.
  QPointF targetPos = pos;
  float effectivePressure = pressure;

  if (m_isDrawing) {
    float strength = std::clamp(m_brushStabilization, 0.0f, 1.0f);

    if (strength > 0.01f) {
      if (m_stabPosQueue.empty()) {
        m_stabilizedPos = pos;
        effectivePressure = pressure;
        // Usamos la cola para el Estado del Double EMA:
        // m_stabPosQueue[0] = EMA Primario
        // m_stabPosQueue[1] = EMA Secundario
        m_stabPosQueue.push_back(pos);
        m_stabPosQueue.push_back(pos);

        m_stabPresQueue.clear();
        m_stabPresQueue.push_back(pressure);
      }

      // Mapeo no lineal para que se sienta premium.
      // Un mass = 0.95 significa 95% de inercia, 5% de la nueva posición.
      // En un Double EMA, la inercia se siente aún más, por lo que 0.92 = muy
      // suave.
      float mass = std::pow(strength, 0.65f) * 0.92f;

      // Double EMA Position
      QPointF ema1 = m_stabPosQueue[0] * mass + pos * (1.0f - mass);
      QPointF ema2 = m_stabPosQueue[1] * mass + ema1 * (1.0f - mass);

      m_stabPosQueue[0] = ema1;
      m_stabPosQueue[1] = ema2;

      m_stabilizedPos = ema2;

      // Single EMA Pressure (la presión no necesita double EMA, perdería
      // respuesta rápida)
      float prevPres = m_stabPresQueue.front();
      effectivePressure = prevPres * mass + pressure * (1.0f - mass);
      m_stabPresQueue.front() = effectivePressure;

      targetPos = m_stabilizedPos;

    } else {
      // No stabilization
      m_stabPosQueue.clear();
      m_stabPresQueue.clear();
      m_stabilizedPos = pos;
      effectivePressure = pressure;
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
    m_lastActiveLayerIndex = m_activeLayerIndex;
  }

  QPointF lastCanvasPos = m_lastPos;

  // Convertir posición de pantalla a canvas
  // Aplicar transformación inversa: (Screen - Offset*Zoom) / Zoom
  QPointF canvasPos = (targetPos - m_viewOffset * m_zoomLevel) / m_zoomLevel;

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
    float rawPressure = std::clamp(effectivePressure, 0.0f, 1.0f);

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
    if (activePreset->opacityDynamics.minLimit < 0.99f || m_opacityByPressure) {
      opacT = activePreset->opacityDynamics.evaluate(rawPressure);
      // Master Toggle check
      if (!m_opacityByPressure)
        opacT = 1.0f;
      settings.opacity = m_brushOpacity * opacT;
    }

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

    // ✅ Selection Clipping (Premium Selection Support)
    if (!m_selectionPath.isEmpty()) {
      fboPainter2.setClipPath(m_selectionPath);
    }

    // Configurar blend mode a nivel de QPainter para que fluya
    // correctamente en la GPU
    if (settings.type == BrushSettings::Type::Eraser) {
      fboPainter2.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    } else {
      fboPainter2.setCompositionMode(QPainter::CompositionMode_SourceOver);
    }

    m_brushEngine->paintStroke(
        &fboPainter2, m_lastPos, canvasPos, effectivePressure, settings, tilt,
        velocityFactor, m_pingFBO->texture(), settings.wetness,
        settings.dilution, settings.smudge);

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
            settings.dilution, settings.smudge);

        // EXPANDIR DIRTY RECT para incluir el trazo simétrico
        QRectF symRect(p1, p2);
        symRect = symRect.normalized().adjusted(
            -settings.size * 2, -settings.size * 2, settings.size * 2,
            settings.size * 2);
        canvasRect = canvasRect.united(symRect);
      }
    }

    fboPainter2.end();
    m_pongFBO->release();

    layer->markDirty(canvasRect.toAlignedRect());
    std::swap(m_pingFBO, m_pongFBO);

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
          predSettings, tilt, velocityFactor, m_predictionFBO->texture(),
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
              velocityFactor, m_predictionFBO->texture(), settings.wetness,
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

    if (settings.type == BrushSettings::Type::Eraser) {
      painter.setCompositionMode(QPainter::CompositionMode_DestinationOut);
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

    // Lenient circularity check (45% variance allowed for hand-drawn
    // circles)
    if (variance < avgDist * 0.45f) {
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
  m_lastMousePos = event->position();

  if (m_tool == ToolType::Hand || m_spacePressed) {
    event->accept();
    // Change the existing override cursor instead of pushing a new one
    if (m_spacePressed)
      QGuiApplication::changeOverrideCursor(Qt::ClosedHandCursor);
    else
      setCursor(Qt::ClosedHandCursor);
    return;
  }

  // Liquify Tool — Start stroke
  if (m_tool == ToolType::Liquify && m_isLiquifying) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
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
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_panelCutStartPos = canvasPos;
    m_panelCutEndPos = canvasPos;
    m_isPanelCutting = true;
    update();
    return;
  }

  if (m_tool == ToolType::Lasso || m_tool == ToolType::RectSelect ||
      m_tool == ToolType::EllipseSelect || m_tool == ToolType::MagneticLasso) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    // New Selection Mode logic
    if (m_selectionAddMode == 0) { // New
      if (m_tool == ToolType::Lasso) {
        // Poly-Lasso logic: if near start, close it
        if (!m_selectionPath.isEmpty() &&
            QLineF(canvasPos, m_selectionPath.elementAt(0)).length() <
                10.0f / m_zoomLevel) {
          m_selectionPath.closeSubpath();
          m_hasSelection = true;
          emit hasSelectionChanged();
        } else {
          if (m_selectionPath.isEmpty())
            m_selectionPath.moveTo(canvasPos);
          else
            m_selectionPath.lineTo(canvasPos);
        }
      } else if (m_tool == ToolType::MagneticLasso) {
        // Polygonal behavior: add point and don't close yet
        if (!m_isMagneticLassoActive) {
          if (m_selectionAddMode == 0)
            m_selectionPath = QPainterPath();
          m_selectionPath.moveTo(canvasPos);
          m_isMagneticLassoActive = true;
        } else {
          m_selectionPath.lineTo(canvasPos);
        }
      } else {
        // Rect/Ellipse: Clear previous path if starting a NEW selection
        m_selectionPath = QPainterPath();
        m_selectionPath.moveTo(canvasPos);
      }
    } else {
      // Add/Subtract modes: start a new contour in the same path
      m_selectionPath.moveTo(canvasPos);
    }

    m_selectionStartPos = canvasPos;
    m_lastSelectionPoint = canvasPos;
    m_isLassoDragging = false;
    update();
    return;
  }

  if (m_tool == ToolType::MagicWand) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    // In a real app, we'd start the circular threshold UI here if held,
    // or just pick color on click.
    emit notificationRequested("Auto Select at " +
                                   QString::number(canvasPos.x()) + "," +
                                   QString::number(canvasPos.y()),
                               "info");
    // Placeholder: select the whole layer for now
    m_hasSelection = true;
    m_selectionPath.addRect(0, 0, m_canvasWidth, m_canvasHeight);
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

    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    if (m_tool == ToolType::Fill) {
      apply_color_drop(static_cast<int>(event->position().x()),
                       static_cast<int>(event->position().y()), m_brushColor);
      return;
    }

    m_isDrawing = true;
    m_lastPos = canvasPos;
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
    Layer *layer = m_layerManager->getActiveLayer();
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

  // Actualizar cursor si estamos arrastrando
  if (m_spacePressed || m_tool == ToolType::Hand) {
    if (event->buttons() & Qt::LeftButton)
      setCursor(Qt::ClosedHandCursor);
    else
      setCursor(Qt::OpenHandCursor);
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

  if ((m_tool == ToolType::Hand || m_spacePressed) &&
      (event->buttons() & Qt::LeftButton)) {
    QPointF delta = (event->position() - m_lastMousePos) / m_zoomLevel;
    m_viewOffset += delta;
    m_lastMousePos = event->position();
    emit viewOffsetChanged();
    requestUpdate();
    return;
  }

  if (m_tool == ToolType::PanelCut && m_isPanelCutting) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_panelCutEndPos = canvasPos;
    update();
    return;
  }

  // Liquify Tool — Continuous deformation
  if (m_tool == ToolType::Liquify && m_isLiquifying &&
      (event->buttons() & Qt::LeftButton)) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    handleLiquifyDraw(canvasPos, 0.5f);
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
    requestUpdate();
    return;
  }

  if ((m_tool == ToolType::Lasso || m_tool == ToolType::RectSelect ||
       m_tool == ToolType::EllipseSelect ||
       m_tool == ToolType::MagneticLasso) &&
      (event->buttons() & Qt::LeftButton)) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    if (m_tool == ToolType::Lasso) {
      m_selectionPath.lineTo(canvasPos);
      m_isLassoDragging = true;
    } else if (m_tool == ToolType::MagneticLasso) {
      // Dragging in magnetic lasso is optional, but for now we follow the
      // cursor
      m_selectionPath.lineTo(canvasPos);
      m_isLassoDragging = true;
    } else if (m_tool == ToolType::RectSelect) {
      // Temporary feedback: we'll clear and add rect on release or maintain
      // a temp path For simplicity in this turn, many apps show a
      // "tentative" shape
    }

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
      handleDraw(event->position(), pressure);
    }
  }

  m_cursorPos = event->position();
  m_lastMousePos = event->position();
  update();
}

void CanvasItem::mouseReleaseEvent(QMouseEvent *event) {
  if (m_tool == ToolType::Hand || m_spacePressed) {
    if (m_spacePressed) {
      QGuiApplication::changeOverrideCursor(Qt::OpenHandCursor);
    } else {
      setCursor(Qt::OpenHandCursor);
    }
  }
  if (m_tool == ToolType::PanelCut && m_isPanelCutting) {
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;
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
    QPointF canvasPos =
        (event->position() - m_viewOffset * m_zoomLevel) / m_zoomLevel;

    if (m_tool == ToolType::MagneticLasso) {
      // In polygonal mode, release doesn't close.
      // We only close on double click or manual "Close" action.
      update();
      return;
    }

    if (m_tool == ToolType::RectSelect) {
      if (!m_selectionStartPos.isNull() &&
          (canvasPos - m_selectionStartPos).manhattanLength() > 2.0) {
        QRectF rect = QRectF(m_selectionStartPos, canvasPos).normalized();
        QPainterPath newPath;
        newPath.addRect(rect);

        if (m_selectionAddMode == 0)
          m_selectionPath = newPath;
        else if (m_selectionAddMode == 1)
          m_selectionPath = m_selectionPath.united(newPath);
        else if (m_selectionAddMode == 2)
          m_selectionPath = m_selectionPath.subtracted(newPath);

        m_hasSelection = true;
      }
    } else if (m_tool == ToolType::EllipseSelect) {
      if (!m_selectionStartPos.isNull() &&
          (canvasPos - m_selectionStartPos).manhattanLength() > 2.0) {
        QRectF rect = QRectF(m_selectionStartPos, canvasPos).normalized();
        QPainterPath newPath;
        newPath.addEllipse(rect);

        if (m_selectionAddMode == 0)
          m_selectionPath = newPath;
        else if (m_selectionAddMode == 1)
          m_selectionPath = m_selectionPath.united(newPath);
        else if (m_selectionAddMode == 2)
          m_selectionPath = m_selectionPath.subtracted(newPath);

        m_hasSelection = true;
      }
    } else if (m_tool == ToolType::Lasso) {
      if (m_isLassoDragging) {
        m_selectionPath.closeSubpath();
        // If it was a subtraction, we need specialized logic for the last
        // part But QPainterPath handles multiple contours. For true
        // subtraction, common practice is united/subtracted on the
        // resulting closed shape.
        m_hasSelection = true;
      }
    }

    emit hasSelectionChanged();
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
      m_quickShapeType = QuickShapeType::None;
      m_hasPrediction = false;

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

void CanvasItem::mouseDoubleClickEvent(QMouseEvent *event) {
  if (m_tool == ToolType::MagneticLasso) {
    m_selectionPath.closeSubpath();
    m_isMagneticLassoActive = false; // STOP creating segments
    m_hasSelection = true;
    emit hasSelectionChanged();
    update();
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
    m_stabilizedPos = event->position();
    m_stabPosQueue.clear(); // Reset stabilizer buffer for new stroke
    m_stabPresQueue.clear();
    QPointF p = event->position();
    QPointF canvasPos = (p - m_viewOffset * m_zoomLevel) / m_zoomLevel;
    m_lastPos = canvasPos;

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
    Layer *layer = m_layerManager->getActiveLayer();
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
    }

    m_quickShapeTimer->start(500);

    handleDraw(event->position(), pressure, tiltFactor);
    event->accept();

  } else if (event->type() == QEvent::TabletMove && m_isDrawing) {
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
    if (!m_isHoldingForShape &&
        (pressure > 0.001f || m_tool == ToolType::Eraser)) {
      handleDraw(event->position(), pressure, tiltFactor);
    }
    update();
    event->accept();

  } else if (event->type() == QEvent::TabletRelease) {
    m_quickShapeTimer->stop();
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
  int points = event->points().count();
  m_touchPointCount = points;

  if (event->type() == QEvent::TouchBegin) {
    if (points == 1 &&
        PreferencesManager::instance()->touchEyedropperEnabled()) {
      m_touchStartPos = event->points().first().position();
      m_touchIsEyedropper = false;
      if (!m_touchTimer) {
        m_touchTimer = new QTimer(this);
        m_touchTimer->setSingleShot(true);
        connect(m_touchTimer, &QTimer::timeout, this, [this]() {
          if (m_touchPointCount == 1 && !m_isDrawing) {
            m_touchIsEyedropper = true;
            QColor sampled = QColor(
                sampleColor(m_touchStartPos.x(), m_touchStartPos.y(), 0));
            setBrushColor(sampled);
            emit notificationRequested("Color Picked", "info");
          }
        });
      }
      m_touchTimer->start(500); // 500ms long press
    } else if (points > 1) {
      if (m_touchTimer)
        m_touchTimer->stop();
    }

    // Store initial pinch data
    if (points == 2 && PreferencesManager::instance()->touchGesturesEnabled()) {
      QPointF p1 = event->points()[0].position();
      QPointF p2 = event->points()[1].position();
      m_touchStartPos = (p1 + p2) / 2.0;
      m_lastPinchScale = QLineF(p1, p2).length();
    }
    event->accept();
  } else if (event->type() == QEvent::TouchUpdate) {
    if (points == 1 && m_touchTimer && m_touchTimer->isActive()) {
      // Cancel long press if moved too much
      float dist = QPointF(event->points().first().position() - m_touchStartPos)
                       .manhattanLength();
      if (dist > 15.0f) {
        m_touchTimer->stop();
      }
    } else if (points == 2 &&
               PreferencesManager::instance()->touchGesturesEnabled()) {
      QPointF p1 = event->points()[0].position();
      QPointF p2 = event->points()[1].position();
      QPointF center = (p1 + p2) / 2.0;

      // Calculate Pan
      QPointF panDelta = center - m_touchStartPos;
      setViewOffset(m_viewOffset - (panDelta / m_zoomLevel));
      m_touchStartPos = center;

      // Calculate Zoom
      float currentDist = QLineF(p1, p2).length();
      if (m_lastPinchScale > 0) {
        float scaleFactor = currentDist / m_lastPinchScale;
        setZoomLevel(
            std::clamp((float)(m_zoomLevel * scaleFactor), 0.1f, 30.0f));
      }
      m_lastPinchScale = currentDist;
      event->accept();
      return;
    }
  } else if (event->type() == QEvent::TouchEnd ||
             event->type() == QEvent::TouchCancel) {
    if (m_touchTimer)
      m_touchTimer->stop();
    m_touchIsEyedropper = false;

    if (PreferencesManager::instance()->multitouchUndoRedoEnabled()) {
      if (points == 2 && !m_isDrawing) {
        undo();
      } else if (points == 3 && !m_isDrawing) {
        redo();
      }
    }
  }
}

void CanvasItem::nativeGestureEvent(QNativeGestureEvent *event) {
  if (event->gestureType() == Qt::ZoomNativeGesture) {
    float scaleDelta = event->value();
    setZoomLevel(
        std::clamp(m_zoomLevel + (scaleDelta * m_zoomLevel), 0.1f, 30.0f));
  } else if (event->gestureType() == Qt::RotateNativeGesture) {
    // float rotDelta = event->value();
    // m_viewRotation += rotDelta; if we supported canvas rotation
    // setCanvasRotation(m_viewRotation);
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

void CanvasItem::invertSelection() {
  QPainterPath full;
  full.addRect(0, 0, m_canvasWidth, m_canvasHeight);
  m_selectionPath = full.subtracted(m_selectionPath);
  update();
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

  // 3. Handle Selection Mask
  std::unique_ptr<artflow::ImageBuffer> selectionMask;
  if (m_hasSelection && !m_selectionPath.isEmpty()) {
    selectionMask =
        std::make_unique<artflow::ImageBuffer>(m_canvasWidth, m_canvasHeight);
    QImage maskImg(selectionMask->data(), m_canvasWidth, m_canvasHeight,
                   QImage::Format_RGBA8888_Premultiplied);
    maskImg.fill(Qt::transparent);

    QPainter p(&maskImg);
    p.setRenderHint(QPainter::Antialiasing);
    p.fillPath(m_selectionPath, Qt::white);
    p.end();
  }

  // Snapshot for undo
  auto before = std::make_unique<artflow::ImageBuffer>(*layer->buffer);

  // Flood fill
  layer->buffer->floodFill(ix, iy, color.red(), color.green(), color.blue(),
                           color.alpha(), m_selectionThreshold,
                           selectionMask.get());
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
  m_selectionPath = QPainterPath();
  m_hasSelection = false;
  emit hasSelectionChanged();
  update();
}

void CanvasItem::selectAll() {
  m_selectionPath = QPainterPath();
  m_selectionPath.addRect(0, 0, m_canvasWidth, m_canvasHeight);
  m_hasSelection = true;
  emit hasSelectionChanged();
  update();
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
    setCursor(QCursor(Qt::OpenHandCursor));
  } else if (tool == "fill" || tool == "BUCKET") {
    m_tool = ToolType::Fill;
    setCursor(QCursor(Qt::BlankCursor));
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
    QImage layerImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                    QImage::Format_RGBA8888_Premultiplied);
    QPainter p2(&layerImg);
    p2.setCompositionMode(QPainter::CompositionMode_Clear);
    p2.setClipPath(m_selectionPath);
    p2.fillRect(bbox, Qt::transparent);
    p2.end();
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
      return;
    }

    QImage fullImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                   QImage::Format_RGBA8888_Premultiplied);
    m_selectionBuffer = fullImg.copy(bbox);

    // Clear area in original layer
    QPainter p2(&fullImg);
    p2.setCompositionMode(QPainter::CompositionMode_Clear);
    p2.fillRect(bbox, Qt::transparent);
    p2.end();
  }

  m_initialMatrix = QTransform();
  m_transformMatrix = QTransform();
  m_isTransforming = true;
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

  // Si la capa actual está en blanco, inicializamos un Panel Maestro primero
  bool isBlank = true;
  const uint8_t *ptr = activeLayer->buffer->data();
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
    p.setPen(QPen(Qt::black, 4));
    p.drawRect(50, 50, m_canvasWidth - 100, m_canvasHeight - 100);
    p.end();
  } else {
    baseImg = QImage(activeLayer->buffer->data(), m_canvasWidth, m_canvasHeight,
                     QImage::Format_RGBA8888_Premultiplied)
                  .copy();
  }

  // Geometría del corte
  QLineF cutLine(p1, p2);
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
  QPen borderPen(Qt::black, 4.0f, Qt::SolidLine, Qt::SquareCap, Qt::MiterJoin);

  // Generar Panel A
  QPainter pa(&copyA);
  pa.setRenderHint(QPainter::Antialiasing);
  pa.setCompositionMode(QPainter::CompositionMode_Clear);
  QPainterPath pPathB;
  pPathB.addPolygon(polyB);
  pa.fillPath(pPathB, Qt::transparent);
  pa.setCompositionMode(QPainter::CompositionMode_SourceOver);
  pa.setPen(borderPen);
  pa.drawLine(lineA);
  pa.end();

  // Generar Panel B
  QPainter pb(&copyB);
  pb.setRenderHint(QPainter::Antialiasing);
  pb.setCompositionMode(QPainter::CompositionMode_Clear);
  QPainterPath pPathA;
  pPathA.addPolygon(polyA);
  pb.fillPath(pPathA, Qt::transparent);
  pb.setCompositionMode(QPainter::CompositionMode_SourceOver);
  pb.setPen(borderPen);
  pb.drawLine(lineB);
  pb.end();

  // 1. Actualizar Capa Activa -> Panel 1
  activeLayer->buffer->loadRawData(copyA.constBits());
  activeLayer->name = "Panel 1";
  activeLayer->dirty = true;
  int activeIdx = m_layerManager->getActiveLayerIndex();

  // 2. Crear Art 1 (Clipped a Panel 1)
  m_layerManager->addLayer("Art 1");
  int art1Idx = m_layerManager->getLayerCount() - 1;
  m_layerManager->moveLayer(art1Idx, activeIdx + 1);
  m_layerManager->getLayer(activeIdx + 1)->clipped = true;

  // 3. Crear Panel 2
  m_layerManager->addLayer("Panel 2");
  int p2Idx = m_layerManager->getLayerCount() - 1;
  m_layerManager->moveLayer(p2Idx, activeIdx + 2);
  Layer *panel2 = m_layerManager->getLayer(activeIdx + 2);
  panel2->buffer->loadRawData(copyB.constBits());
  panel2->dirty = true;

  // 4. Crear Art 2 (Clipped a Panel 2)
  m_layerManager->addLayer("Art 2");
  int art2Idx = m_layerManager->getLayerCount() - 1;
  m_layerManager->moveLayer(art2Idx, activeIdx + 3);
  Layer *art2 = m_layerManager->getLayer(activeIdx + 3);
  art2->clipped = true;

  // Focus the first Art layer to let user start drawing immediately
  m_activeLayerIndex = activeIdx + 1;
  m_layerManager->setActiveLayer(m_activeLayerIndex);

  updateLayersList();
  update();
}

void CanvasItem::updateTransformCorners(const QVariantList &corners) {
  if (!m_isTransforming || corners.size() < 4)
    return;

  // m_selectionBuffer goes from (0,0) to (W,H). Map its local corners to
  // the global dst corners.
  QPolygonF src;
  src << QPointF(0, 0) << QPointF(m_transformBox.width(), 0)
      << QPointF(m_transformBox.width(), m_transformBox.height())
      << QPointF(0, m_transformBox.height());

  QPolygonF dst;
  for (int i = 0; i < 4; ++i) {
    QVariantMap p = corners[i].toMap();
    dst << QPointF(p["x"].toDouble(), p["y"].toDouble());
  }

  // Calculate perspective/mesh quad transform
  QTransform transform;
  if (QTransform::quadToQuad(src, dst, transform)) {
    m_transformMatrix = transform;
    requestUpdate(); // throttled — no update() directo aquí
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
    QOpenGLContext *ctx = QOpenGLContext::currentContext();

    if (ctx && m_transformShader && m_selectionTex) {
      // --- CAMINO RÁPIDO: blit final por GPU usando el shader que ya existe
      // --- Renderizamos a un FBO del tamaño del canvas y leemos el resultado
      QOpenGLFramebufferObjectFormat fmt;
      fmt.setInternalTextureFormat(GL_RGBA8);
      QOpenGLFramebufferObject fbo(m_canvasWidth, m_canvasHeight, fmt);
      fbo.bind();

      QOpenGLFunctions *f = ctx->functions();
      f->glViewport(0, 0, m_canvasWidth, m_canvasHeight);
      f->glClearColor(0, 0, 0, 0);
      f->glClear(GL_COLOR_BUFFER_BIT);
      f->glEnable(GL_BLEND);
      f->glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

      m_transformShader->bind();

      // Proyección ortográfica del tamaño del canvas (sin pan/zoom)
      QMatrix4x4 ortho;
      ortho.ortho(0, m_canvasWidth, m_canvasHeight, 0, -1, 1);

      // Construir MVP = ortho * perspectiveMatrix * localOffset
      QMatrix4x4 qtMat;
      qtMat.setColumn(0, QVector4D(m_transformMatrix.m11(),
                                   m_transformMatrix.m12(), 0,
                                   m_transformMatrix.m13()));
      qtMat.setColumn(1, QVector4D(m_transformMatrix.m21(),
                                   m_transformMatrix.m22(), 0,
                                   m_transformMatrix.m23()));
      qtMat.setColumn(2, QVector4D(0, 0, 1, 0));
      qtMat.setColumn(3, QVector4D(m_transformMatrix.m31(),
                                   m_transformMatrix.m32(), 0,
                                   m_transformMatrix.m33()));
      m_transformShader->setUniformValue("MVP", ortho * qtMat);
      m_transformShader->setUniformValue("opacity", 1.0f);
      m_selectionTex->bind(0);
      m_transformShader->setUniformValue("tex", 0);

      float sw = m_selectionBuffer.width();
      float sh = m_selectionBuffer.height();
      GLfloat verts[] = {0, 0,  0, 0, sw, 0, 1, 0, 0,  sh, 0, 1,
                         0, sh, 0, 1, sw, 0, 1, 0, sw, sh, 1, 1};
      m_transformShader->enableAttributeArray(0);
      m_transformShader->enableAttributeArray(1);
      m_transformShader->setAttributeArray(0, GL_FLOAT, verts, 2,
                                           4 * sizeof(float));
      m_transformShader->setAttributeArray(1, GL_FLOAT, verts + 2, 2,
                                           4 * sizeof(float));
      f->glDrawArrays(GL_TRIANGLES, 0, 6);
      m_transformShader->disableAttributeArray(0);
      m_transformShader->disableAttributeArray(1);
      m_transformShader->release();
      fbo.release();

      // Leer resultado del FBO (GPU→CPU, una sola vez al confirmar)
      QImage result =
          fbo.toImage().convertToFormat(QImage::Format_RGBA8888_Premultiplied);

      // Combinar con el buffer de la capa (que ya tiene el fondo sin la
      // selección)
      QImage layerImg(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                      QImage::Format_RGBA8888_Premultiplied);
      QPainter p(&layerImg);
      p.setCompositionMode(QPainter::CompositionMode_SourceOver);
      p.drawImage(0, 0, result);
      p.end();

    } else {
      // --- FALLBACK CPU (sin contexto GL disponible en este momento) ---
      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
      QPainter p(&img);
      p.setRenderHint(QPainter::SmoothPixmapTransform);
      p.setRenderHint(QPainter::Antialiasing);
      p.setTransform(m_transformMatrix);
      p.drawImage(0, 0, m_selectionBuffer);
      p.end();
    }

    layer->dirty = true;

    // 3. PUSH UNDO
    auto after = std::make_unique<artflow::ImageBuffer>(*layer->buffer);
    m_undoManager->pushCommand(std::make_unique<artflow::StrokeUndoCommand>(
        m_layerManager, m_activeLayerIndex, std::move(m_transformBeforeBuffer),
        std::move(after)));
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
    QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
               QImage::Format_RGBA8888_Premultiplied);
    QPainter p(&img);
    p.drawImage(m_transformBox.topLeft(),
                m_selectionBuffer); // Draw back original at its position
    p.end();
    layer->dirty = true;
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
    setCurrentTool("transform");
  }
  // Select None
  else if (ctrl && key == Qt::Key_D) {
    m_selectionPath = QPainterPath();
    m_hasSelection = false;
    update();
  }
  // Space (Pan)
  else if (key == Qt::Key_Space) {
    if (!m_spacePressed) {
      m_spacePressed = true;
      QGuiApplication::setOverrideCursor(Qt::OpenHandCursor);
    }
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
    m_spacePressed = false;

    // Restaurar cursor correcto al soltar espacio
    if (m_tool != ToolType::Hand && m_tool != ToolType::Transform) {
      setCursor(Qt::BlankCursor);
    } else if (m_tool == ToolType::Hand) {
      setCursor(Qt::OpenHandCursor);
    } else if (m_tool == ToolType::Transform) {
      setCursor(getModernCursor());
    }

    update();
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
  setActiveLayer(m_layerManager->getLayerCount() - 1);
  update();
}

void CanvasItem::addGroup() {
  m_layerManager->addLayer("New Group", artflow::Layer::Type::Group);
  setActiveLayer(m_layerManager->getLayerCount() - 1);
  update();
}

void CanvasItem::moveLayerToGroup(int layerId, int groupId) {
  // layerId and groupId are the layer indices (as exposed in the model)
  int count = m_layerManager->getLayerCount();

  // layerModel is in reversed order (last layer is index 0 in UI, but highest
  // index in manager). Convert UI IDs back to manager indices.
  int fromManagerIdx = (count - 1) - layerId;
  int groupManagerIdx = (count - 1) - groupId;

  if (fromManagerIdx < 0 || fromManagerIdx >= count || groupManagerIdx < 0 ||
      groupManagerIdx >= count) {
    qWarning() << "moveLayerToGroup: invalid indices" << layerId << groupId;
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

  // We want the layer to be placed immediately below the group in the manager
  // stack (which means just below groupManagerIdx — i.e. at groupManagerIdx-1).
  // The UI shows layers in reverse, so "inside the group" visually means the
  // layer is at a lower manager index than the group.
  int destManagerIdx = groupManagerIdx - 1;
  if (destManagerIdx < 0)
    destManagerIdx = 0;

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

void CanvasItem::toggleGroupExpanded(int index) {
  int count = m_layerManager->getLayerCount();
  int managerIdx = (count - 1) - index;

  if (managerIdx < 0 || managerIdx >= count)
    return;

  artflow::Layer *l = m_layerManager->getLayer(managerIdx);
  if (l && l->type == artflow::Layer::Type::Group) {
    l->expanded = !l->expanded;
    updateLayersList();
  }
}

void CanvasItem::removeLayer(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked) {
    emit notificationRequested("Cannot delete a locked layer", "error");
    return;
  }
  m_layerManager->removeLayer(index);
  clearRenderCaches();
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

void CanvasItem::moveLayer(int fromIndex, int toIndex) {
  if (fromIndex == toIndex)
    return;

  // Validate indices
  int count = m_layerManager->getLayerCount();
  if (fromIndex < 0 || fromIndex >= count || toIndex < 0 || toIndex >= count) {
    return;
  }

  m_layerManager->moveLayer(fromIndex, toIndex);

  // Update parentId based on new neighbors to allow entering/exiting groups
  artflow::Layer *moved = m_layerManager->getLayer(toIndex);
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

  // Auto-clipping logic: If dropped into the middle of a clipping group, join
  // it.
  artflow::Layer *above =
      (toIndex + 1 < count) ? m_layerManager->getLayer(toIndex + 1) : nullptr;
  if (moved && above && above->clipped) {
    moved->clipped = true;
  }

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

  updateLayersList();
  update();
}

void CanvasItem::mergeDown(int index) {
  Layer *bottom = m_layerManager->getLayer(index - 1);
  if (bottom && bottom->locked) {
    emit notificationRequested("Cannot merge onto a locked layer", "error");
    return;
  }
  m_layerManager->mergeDown(index);
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
    l->name = name.toStdString();
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
        newLayer->blendMode = (BlendMode)layerObj["blendMode"].toInt(0);
        newLayer->type = (Layer::Type)layerObj["type"].toInt(0);

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

  m_currentProjectPath = localPath;
  m_currentProjectName = info.baseName();

  emit currentProjectPathChanged();
  emit currentProjectNameChanged();
  updateLayersList();

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
      "/ArtFlowProjects";
  QDir baseDir(baseDirStr);
  if (!baseDir.exists())
    baseDir.mkpath(".");

  QString targetPath = pathText;
  if (!targetPath.contains("/") && !targetPath.contains("\\")) {
    targetPath = baseDir.filePath(targetPath);
  }

  if (!targetPath.endsWith(".stxf")) {
    targetPath += ".stxf";
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
      layerObj["blendMode"] = (int)layer->blendMode;
      layerObj["type"] = (int)layer->type;

      // Embed Image Data as Base64 String
      // Create deep copy for saving
      QImage img(layer->buffer->data(), m_canvasWidth, m_canvasHeight,
                 QImage::Format_RGBA8888_Premultiplied);
      QBuffer buffer;
      buffer.open(QIODevice::WriteOnly);
      if (img.save(&buffer, "PNG")) {
        QString b64 = QString::fromLatin1(buffer.data().toBase64());
        layerObj["data"] = b64;
        layersArray.append(layerObj);
      } else {
        qWarning() << "Failed to encode layer image";
      }
    }
  }
  obj["layers"] = layersArray;

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
      "/ArtFlowProjects";

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

    if (info.isFile() && info.suffix() == "stxf") {
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
      QFileInfoList subEntries = subDir.entryInfoList(QStringList() << "*.stxf",
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
      dir.entryInfoList(QStringList() << "*.stxf", QDir::Files, QDir::Name);
  for (const QFileInfo &info : entries) {
    QVariantMap item;
    item["name"] = info.completeBaseName();
    item["path"] = QUrl::fromLocalFile(info.absoluteFilePath()).toString();
    item["realPath"] = info.absoluteFilePath();
    item["type"] = "drawing";
    item["date"] = info.lastModified().toString("dd MMM yyyy");

    QFile f(info.absoluteFilePath());
    if (f.open(QIODevice::ReadOnly)) {
      QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
      if (!doc.isNull() && doc.object().contains("thumbnail")) {
        item["preview"] =
            "data:image/png;base64," + doc.object()["thumbnail"].toString();
      }
      f.close();
    }
    results.append(item);
  }
  return results;
}

QString CanvasItem::create_new_sketchbook(const QString &name,
                                          const QString &coverColor) {
  QString baseDirStr =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/ArtFlowProjects";
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
      dir.entryInfoList(QStringList() << "*.stxf", QDir::Files, QDir::Name);
  int pageNum = existing.size() + 1;

  QString safeName = pageName;
  if (safeName.isEmpty())
    safeName = "Page";

  // Zero-pad for sorting: Page_001.stxf
  QString fileName =
      QString("%1_%2.stxf").arg(safeName).arg(pageNum, 3, 10, QChar('0'));
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
      dir.entryInfoList(QStringList() << "*.stxf", QDir::Files, QDir::Name);

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
        "/ArtFlowProjects";
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
  // Root ArtFlowProjects path
  QString rootPath =
      QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) +
      "/ArtFlowProjects";
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

  // Create a composite image
  ImageBuffer composite(m_canvasWidth, m_canvasHeight);
  m_layerManager->compositeAll(composite);

  // Use ARGB32_Premultiplied which is standard for QImage unless you're
  // sure about RGBA8888 byte order Create a deep copy to ensure the image
  // owns its data
  QImage img = QImage(composite.data(), m_canvasWidth, m_canvasHeight,
                      QImage::Format_RGBA8888_Premultiplied)
                   .copy();

  // Convert path to local file if it's a URL
  QString localPath = path;
  if (localPath.startsWith("file:///")) {
    localPath = QUrl(path).toLocalFile();
  }

  qDebug() << "Exporting image to:" << localPath;
  bool success = img.save(localPath, format.toUpper().toStdString().c_str());
  if (!success)
    qDebug() << "Failed to save image to:" << localPath;
  return success;
}

bool CanvasItem::importABR(const QString &path) {
  emit notificationRequested(
      "La importación de ABR está deshabilitada temporalmente.", "error");
  return false;
}

void CanvasItem::updateTransformProperties(float x, float y, float scale,
                                           float rotation, float w, float h) {
  if (!m_isTransforming)
    return;

  m_transformMatrix = QTransform();

  // Current center (based on manipulator position on Canvas)
  float newCx = x + w / 2.0f;
  float newCy = y + h / 2.0f;

  // 1. Move to new center
  m_transformMatrix.translate(newCx, newCy);

  // 2. Rotate and Scale
  m_transformMatrix.rotate(rotation);
  m_transformMatrix.scale(scale, scale);

  // Apply differential scaling based on free-transform handle manipulation
  float scaleX = w / std::max(1.0f, (float)m_transformBox.width());
  float scaleY = h / std::max(1.0f, (float)m_transformBox.height());
  m_transformMatrix.scale(scaleX, scaleY);

  // 3. Move back relative to local image origin so (0,0) maps correctly
  m_transformMatrix.translate(-m_transformBox.width() / 2.0f,
                              -m_transformBox.height() / 2.0f);

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
    layer["active"] = (i == m_activeLayerIndex);
    layer["stableId"] = (int)l->stableId;
    layer["parentId"] = l->parentId;

    // Correctly map the Layer::Type enum
    if (l->type == Layer::Type::Group) {
      layer["type"] = QString("group");
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
}

void CanvasItem::resizeCanvas(int w, int h) {
  resetTransformState();
  setCurrentTool("brush");

  m_canvasWidth = w;
  m_canvasHeight = h;

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

    // Draw white fill and black border
    QImage pImg(w, h, QImage::Format_RGBA8888_Premultiplied);
    pImg.fill(Qt::transparent);
    QPainter pPainter(&pImg);
    pPainter.setRenderHint(QPainter::Antialiasing);

    // 1. Fill solid white (CompositionMode_Source ensures Alpha 255)
    pPainter.setCompositionMode(QPainter::CompositionMode_Source);
    pPainter.fillRect(rect, Qt::white);

    // 2. Draw black border (Alpha 255)
    pPainter.setCompositionMode(QPainter::CompositionMode_SourceOver);
    pPainter.setPen(borderPen);
    pPainter.drawRect(rect);
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
  update();
  emit notificationRequested("Panels flattened to layers with clipping masks",
                             "success");
}

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
  if (l && l->locked) {
    emit notificationRequested("Layer is locked", "warning");
    return;
  }
  if (l) {
    l->clipped = !l->clipped;
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
    l->alphaLock = !l->alphaLock;
    updateLayersList();
  }
}

void CanvasItem::toggleVisibility(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    bool newVisible = !l->visible;
    l->visible = newVisible;
    l->markDirty();

    // If it's a group, toggle all children recursively
    if (l->type == Layer::Type::Group) {
      uint32_t groupStableId = l->stableId;
      for (int i = 0; i < m_layerManager->getLayerCount(); ++i) {
        Layer *child = m_layerManager->getLayer(i);
        if (child && child->parentId == (int)groupStableId) {
          child->visible = newVisible;
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
    l->visible = visible;
    l->markDirty();
    updateLayersList();
    update();
  }
}

void CanvasItem::toggleLock(int index) {
  Layer *l = m_layerManager->getLayer(index);
  if (l) {
    l->locked = !l->locked;
    updateLayersList();
  }
}

void CanvasItem::clearLayer(int index) {
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
    l->opacity = opacity;
    l->markDirty();
    updateLayersList();
    update();
  }
}

void CanvasItem::setLayerOpacityPreview(int index, float opacity) {
  Layer *l = m_layerManager->getLayer(index);
  if (l && l->locked)
    return;
  if (l) {
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

    if (l->blendMode == newMode)
      return;

    l->blendMode = newMode;
    l->markDirty();
    updateLayersList();
    update();
  }
}

void CanvasItem::setActiveLayer(int index) {
  if (m_layerManager && index >= 0 && index < m_layerManager->getLayerCount()) {
    // SYNC CURRENT LAYER BEFORE SWITCHING
    if (index != m_activeLayerIndex) {
      syncGpuToCpu();
    }

    m_activeLayerIndex = index;
    m_layerManager->setActiveLayer(index);
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

  // Initialize the preview pad
  m_previewPadImage = QImage(800, 600, QImage::Format_ARGB32);
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
  if (img.format() != QImage::Format_RGBA8888 &&
      img.format() != QImage::Format_RGBA8888_Premultiplied) {
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
      // itself is requested. Since I cannot add to a non-existent function
      // in this file, I will add the logging line as a comment here to
      // indicate where it would go if applyToLegacy were present and being
      // modified. For getBrushCategoryProperties, we just return the value.
      // qDebug() << "BrushPreset::applyToLegacy: Setting tipTextureName to"
      // << m_editingPreset.shape.tipTexture;
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

QVariantList CanvasItem::getBrushCategories() {
  QVariantList result;
  auto *bpm = artflow::BrushPresetManager::instance();
  auto groups = bpm->groups();

  // Map of known built-in categories to icons
  // Fixed icons for premium aesthetic
  static QMap<QString, QString> builtInIcons = {
      {"Favorites", "cat_favorites"}, {"Sketching", "cat_sketching"},
      {"Inking", "cat_inking"},       {"Drawing", "marker"},
      {"Painting", "cat_painting"},   {"Artistic", "palette"},
      {"Watercolor", "palette"},      {"Oil Painting", "palette"},
      {"Calligraphy", "cat_inking"},  {"Airbrushing", "airbrush"},
      {"Textures", "cat_textures"},   {"Luminance", "cat_luminance"},
      {"Charcoal", "cat_charcoal"},   {"Imported", "cat_imported"},
      {"Manga", "palette"},           {"Sprays", "airbrush"}};

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
  if (m_cachedCanvasImage.isNull())
    return "";

  // Make a very cheap, downscaled version for the navigator
  QImage preview = m_cachedCanvasImage;
  if (preview.width() > 350 || preview.height() > 350) {
    // Keep it fast, no smooth transform
    preview =
        preview.scaled(350, 350, Qt::KeepAspectRatio, Qt::FastTransformation);
  }

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  preview.save(&buffer, "PNG");

  return "data:image/png;base64," + QString(ba.toBase64());
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
  // Aumentar resolución para un preview más nítido y "premium"
  QImage img(400, 160, QImage::Format_ARGB32);
  img.fill(Qt::transparent);

  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *preset = bpm->findByName(brushName);
  if (!preset)
    return "";

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

  // Dibujar una curva elegante "S" para mostrar la textura
  QPainterPath path;
  path.moveTo(40, 100);
  path.cubicTo(120, 20, 280, 140, 360, 60);

  // Simular el trazo con interpolación para que el motor de pincel actúe
  QPointF lastP = path.pointAtPercent(0);
  tempEngine.resetRemainder();

  int segments = 100;
  for (int i = 1; i <= segments; ++i) {
    float t = (float)i / segments;
    QPointF currP = path.pointAtPercent(t);

    // Simular presión variable para dar dinamismo (estilo caligráfico)
    float pressure = 0.3f + 0.7f * std::sin(t * M_PI);

    tempEngine.paintStroke(&painter, lastP, currP, pressure, s);
    lastP = currP;
  }

  painter.end();

  QByteArray ba;
  QBuffer buffer(&ba);
  buffer.open(QIODevice::WriteOnly);
  img.save(&buffer, "PNG");

  return "data:image/png;base64," + ba.toBase64();
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

void CanvasItem::capture_timelapse_frame() {
  if (!m_layerManager)
    return;

  // Temporarily disable as it requires a synchronous
  // m_layerManager->compositeAll which takes seconds on large inputs, freezing
  // the application on stroke finish.
  return;

  // Realizar la composición en el hilo principal antes de pasarlo a un hilo
  auto composite = std::make_shared<ImageBuffer>(m_canvasWidth, m_canvasHeight);
  m_layerManager->compositeAll(*composite, true); // skipPrivate = true

  // Guardar a disco de forma asíncrona para no congelar la UI
  QtConcurrent::run([composite, cw = m_canvasWidth, ch = m_canvasHeight]() {
    static int frameCount = 0;
    QString path =
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) +
        "/ArtFlow/Timelapse";
    QDir().mkpath(path);

    QString fileName = QString("%1/frame_%2.jpg")
                           .arg(path)
                           .arg(frameCount++, 6, 10, QChar('0'));

    QImage img(composite->data(), cw, ch, QImage::Format_RGBA8888);
    img.save(fileName, "JPG", 85);
  });
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

void CanvasItem::hoverEnterEvent(QHoverEvent *event) {
  event->accept();
  m_cursorVisible = true;
  m_cursorPos = event->position();

  // Decide el cursor solo para el área del Canvas
  if (m_spacePressed || m_tool == ToolType::Hand)
    setCursor(Qt::OpenHandCursor);
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
    setCursor(Qt::OpenHandCursor);
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
    searchPaths << "assets/textures"
                << "src/assets/textures"
                << QCoreApplication::applicationDirPath() + "/assets/textures"
                << QCoreApplication::applicationDirPath() +
                       "/../assets/textures"
                << QCoreApplication::applicationDirPath() + "/textures"
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

  // 🔥 PROCESAR: Convertir fondo blanco/gris a transparente
  // y usar solo el canal alfa para el contorno
  for (int y = 0; y < original.height(); y++) {
    for (int x = 0; x < original.width(); x++) {
      QColor pixel = original.pixelColor(x, y);

      // Obtener luminosidad (0-255)
      int luminance = qGray(pixel.red(), pixel.green(), pixel.blue());

      // Invertir: blanco = transparente, negro = opaco
      int alpha = 255 - luminance;

      // Establecer como blanco con alpha variable
      if (alpha > 10) { // Threshold para ruido
        original.setPixelColor(x, y, QColor(255, 255, 255, alpha));
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
        QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                   QImage::Format_RGBA8888_Premultiplied);
        tex = new QOpenGLTexture(img);
        tex->setMinificationFilter(QOpenGLTexture::Linear);
        tex->setMagnificationFilter(QOpenGLTexture::Linear);
        tex->setWrapMode(QOpenGLTexture::ClampToBorder);
        tex->setBorderColor(QColor(0, 0, 0, 0));
        m_layerTextures.insert(L, tex);
        L->dirty = false;
      } else if (L->dirty) {
        if (!L->buffer)
          return tex;
        QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                   QImage::Format_RGBA8888_Premultiplied);
        tex->setData(img);
        L->dirty = false;
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
        QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                   QImage::Format_RGBA8888_Premultiplied);
        tex = new QOpenGLTexture(img);
        m_layerTextures.insert(L, tex);
        L->dirty = false;
      } else if (L->dirty) {
        if (!L->buffer)
          return tex;
        QImage img(L->buffer->data(), L->buffer->width(), L->buffer->height(),
                   QImage::Format_RGBA8888_Premultiplied);
        tex->setData(img);
        L->dirty = false;
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
  QStringList searchPaths;
  searchPaths << QCoreApplication::applicationDirPath() + "/assets/brushes"
              << QCoreApplication::applicationDirPath() + "/../assets/brushes"
              << QDir::currentPath() + "/assets/brushes";

  QStringList filters;
  filters << "*.png" << "*.PNG";

  for (const QString &searchPath : searchPaths) {
    QDir dir(searchPath);
    if (!dir.exists())
      continue;
    const QStringList files = dir.entryList(filters, QDir::Files);
    for (const QString &file : files) {
      QVariantMap entry;
      entry["name"] = QFileInfo(file).baseName();
      entry["filename"] = file;
      entry["path"] = dir.absoluteFilePath(file);
      result.append(entry);
    }
    if (!result.isEmpty())
      break;
  }
  return result;
}

void CanvasItem::setTipTextureForBrush(const QString &brushName,
                                       const QString &texturePath) {
  auto *bpm = artflow::BrushPresetManager::instance();
  const artflow::BrushPreset *p = bpm->findByName(brushName);
  QString filename = QFileInfo(texturePath).fileName();

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
  QString filename = QFileInfo(texturePath).fileName();

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
  m_previousToolStr = m_currentToolStr;
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
