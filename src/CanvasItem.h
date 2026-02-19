#ifndef CANVASITEM_H
#define CANVASITEM_H

#include "core/cpp/include/brush_engine.h"
#include "core/cpp/include/brush_preset.h"
#include "core/cpp/include/layer_manager.h"
#include "core/cpp/include/stroke_renderer.h"
#include "core/cpp/include/stroke_undo_command.h"
#include "core/cpp/include/undo_manager.h"
#include <QColor>
#include <QImage>
#include <QMap>
#include <QOpenGLFramebufferObject>
#include <QOpenGLTexture>
#include <QPainterPath>
#include <QPointF>
#include <QQuickPaintedItem>
#include <QRectF>
#include <QTabletEvent>
#include <QTimer>
#include <QVariantList>
#include <deque>
#include <vector>

class CanvasItem : public QQuickPaintedItem {
  Q_OBJECT

public:
  enum class ToolType {
    Pen,
    Eraser,
    Lasso,
    MagneticLasso,
    RectSelect,
    EllipseSelect,
    MagicWand,
    Transform,
    Eyedropper,
    Hand,
    Fill,
    Shape
  };
  Q_ENUM(ToolType)

  // Properties for QML compatibility
  Q_PROPERTY(
      int brushSize READ brushSize WRITE setBrushSize NOTIFY brushSizeChanged)
  Q_PROPERTY(QColor brushColor READ brushColor WRITE setBrushColor NOTIFY
                 brushColorChanged)
  Q_PROPERTY(float brushOpacity READ brushOpacity WRITE setBrushOpacity NOTIFY
                 brushOpacityChanged)
  Q_PROPERTY(
      float brushFlow READ brushFlow WRITE setBrushFlow NOTIFY brushFlowChanged)
  Q_PROPERTY(float brushHardness READ brushHardness WRITE setBrushHardness
                 NOTIFY brushHardnessChanged)
  Q_PROPERTY(float brushSpacing READ brushSpacing WRITE setBrushSpacing NOTIFY
                 brushSpacingChanged)
  Q_PROPERTY(float brushStabilization READ brushStabilization WRITE
                 setBrushStabilization NOTIFY brushStabilizationChanged)
  Q_PROPERTY(float brushStreamline READ brushStreamline WRITE setBrushStreamline
                 NOTIFY brushStreamlineChanged)
  Q_PROPERTY(float brushGrain READ brushGrain WRITE setBrushGrain NOTIFY
                 brushGrainChanged)
  Q_PROPERTY(float brushWetness READ brushWetness WRITE setBrushWetness NOTIFY
                 brushWetnessChanged)
  Q_PROPERTY(float brushSmudge READ brushSmudge WRITE setBrushSmudge NOTIFY
                 brushSmudgeChanged)
  Q_PROPERTY(float impastoShininess READ impastoShininess WRITE
                 setImpastoShininess NOTIFY impastoShininessChanged)
  Q_PROPERTY(float impastoStrength READ impastoStrength WRITE setImpastoStrength
                 NOTIFY impastoSettingsChanged)
  Q_PROPERTY(float lightAngle READ lightAngle WRITE setLightAngle NOTIFY
                 impastoSettingsChanged)
  Q_PROPERTY(float lightElevation READ lightElevation WRITE setLightElevation
                 NOTIFY impastoSettingsChanged)
  Q_PROPERTY(float brushRoundness READ brushRoundness WRITE setBrushRoundness
                 NOTIFY brushRoundnessChanged)

  Q_PROPERTY(
      float zoomLevel READ zoomLevel WRITE setZoomLevel NOTIFY zoomLevelChanged)
  Q_PROPERTY(QString currentTool READ currentTool WRITE setCurrentTool NOTIFY
                 currentToolChanged)
  Q_PROPERTY(int canvasWidth READ canvasWidth NOTIFY canvasWidthChanged)
  Q_PROPERTY(int canvasHeight READ canvasHeight NOTIFY canvasHeightChanged)
  Q_PROPERTY(QPointF viewOffset READ viewOffset NOTIFY viewOffsetChanged)
  Q_PROPERTY(
      int activeLayerIndex READ activeLayerIndex NOTIFY activeLayerChanged)
  Q_PROPERTY(
      bool isTransforming READ isTransforming NOTIFY isTransformingChanged)
  Q_PROPERTY(float brushAngle READ brushAngle WRITE setBrushAngle NOTIFY
                 brushAngleChanged)
  Q_PROPERTY(float cursorRotation READ cursorRotation WRITE setCursorRotation
                 NOTIFY cursorRotationChanged)
  Q_PROPERTY(QString currentProjectPath READ currentProjectPath NOTIFY
                 currentProjectPathChanged)
  Q_PROPERTY(QString currentProjectName READ currentProjectName NOTIFY
                 currentProjectNameChanged)
  Q_PROPERTY(QString brushTip READ brushTip NOTIFY brushTipChanged)
  Q_PROPERTY(
      bool isEraser READ isEraser WRITE setIsEraser NOTIFY isEraserChanged)
  Q_PROPERTY(bool isFlippedH READ isFlippedH WRITE setIsFlippedH NOTIFY
                 isFlippedHChanged)
  Q_PROPERTY(bool isFlippedV READ isFlippedV WRITE setIsFlippedV NOTIFY
                 isFlippedVChanged)

  // Aliases for QML compatibility
  Q_PROPERTY(float canvasScale READ zoomLevel WRITE setZoomLevel NOTIFY
                 zoomLevelChanged)
  Q_PROPERTY(QPointF canvasOffset READ viewOffset WRITE setViewOffset NOTIFY
                 viewOffsetChanged)
  Q_PROPERTY(QRectF transformBox READ transformBox NOTIFY transformBoxChanged)

  // Curva de Presión Bezier (P1x, P1y, P2x, P2y)
  Q_PROPERTY(QVariantList pressureCurvePoints READ pressureCurvePoints WRITE
                 setCurvePoints NOTIFY pressureCurvePointsChanged)
  Q_PROPERTY(QVariantList availableBrushes READ availableBrushes NOTIFY
                 availableBrushesChanged)
  Q_PROPERTY(QString activeBrushName READ activeBrushName NOTIFY
                 activeBrushNameChanged)
  Q_PROPERTY(
      QString brushTipImage READ brushTipImage NOTIFY brushTipImageChanged)

  // ── Brush Studio editing state ──
  Q_PROPERTY(
      bool isEditingBrush READ isEditingBrush NOTIFY isEditingBrushChanged)
  Q_PROPERTY(bool hasSelection READ hasSelection NOTIFY hasSelectionChanged)
  Q_PROPERTY(int selectionAddMode READ selectionAddMode WRITE setSelectionAddMode NOTIFY selectionAddModeChanged)
  Q_PROPERTY(float selectionThreshold READ selectionThreshold WRITE setSelectionThreshold NOTIFY selectionThresholdChanged)
  Q_PROPERTY(bool isSelectionModeActive READ isSelectionModeActive WRITE setIsSelectionModeActive NOTIFY isSelectionModeActiveChanged)

  Q_PROPERTY(int transformMode READ transformMode WRITE setTransformMode NOTIFY transformModeChanged)

  enum TransformSubMode { Free, Perspective, Warp, Mesh };
  Q_ENUM(TransformSubMode)

public:
  int transformMode() const { return (int)m_transformSubMode; }
  void setTransformMode(int mode) {
      if ((int)m_transformSubMode == mode) return;
      m_transformSubMode = (TransformSubMode)mode;
      emit transformModeChanged();
      update();
  }

  Q_INVOKABLE void applyTransform();
  Q_INVOKABLE void cancelTransform();

  explicit CanvasItem(QQuickItem *parent = nullptr);
  ~CanvasItem() override;

  void paint(QPainter *painter) override;

  // Getters
  int brushSize() const { return m_brushSize; }
  QColor brushColor() const { return m_brushColor; }
  float brushOpacity() const { return m_brushOpacity; }
  float brushFlow() const { return m_brushFlow; }
  float brushHardness() const { return m_brushHardness; }
  float brushSpacing() const { return m_brushSpacing; }
  float brushStabilization() const { return m_brushStabilization; }
  float brushStreamline() const { return m_brushStreamline; }
  float brushGrain() const { return m_brushGrain; }
  float brushWetness() const { return m_brushWetness; }
  float brushSmudge() const { return m_brushSmudge; }
  float impastoShininess() const { return m_impastoShininess; }
  float impastoStrength() const { return m_impastoStrength; }
  float lightAngle() const { return m_lightAngle; }
  float lightElevation() const { return m_lightElevation; }
  float brushRoundness() const { return m_brushRoundness; }

  float zoomLevel() const { return m_zoomLevel; }
  QString currentTool() const { return m_currentToolStr; }
  int canvasWidth() const { return m_canvasWidth; }
  int canvasHeight() const { return m_canvasHeight; }
  QPointF viewOffset() const { return m_viewOffset; }
  int activeLayerIndex() const { return m_activeLayerIndex; }
  bool isTransforming() const { return m_isTransforming; }
  float brushAngle() const { return m_brushAngle; }
  float cursorRotation() const { return m_cursorRotation; }
  QString currentProjectPath() const { return m_currentProjectPath; }
  QString currentProjectName() const { return m_currentProjectName; }
  QString brushTip() const { return m_brushTip; }
  bool isFlippedH() const { return m_isFlippedH; }
  bool isFlippedV() const { return m_isFlippedV; }
  bool isEraser() const { return m_isEraser; }
  QVariantList availableBrushes() const { return m_availableBrushes; }
  QString activeBrushName() const { return m_activeBrushName; }
  QString brushTipImage() const { return m_brushTipImage; }
  bool isEditingBrush() const { return m_isEditingBrush; }
  bool hasSelection() const { return m_hasSelection; }
  int selectionAddMode() const { return m_selectionAddMode; }
  float selectionThreshold() const { return m_selectionThreshold; }
  bool isSelectionModeActive() const { return m_isSelectionModeActive; }

  // Setters
  void setBrushSize(int size);
  void setBrushColor(const QColor &color);
  void setBrushOpacity(float opacity);
  void setBrushFlow(float flow);
  void setBrushHardness(float hardness);
  void setBrushSpacing(float spacing);
  void setBrushStabilization(float value);
  void setBrushStreamline(float value);
  void setBrushGrain(float value);
  void setBrushWetness(float value);
  void setBrushSmudge(float value);
  void setImpastoShininess(float value);
  void setImpastoStrength(float strength);
  void setLightAngle(float angle);
  void setLightElevation(float elevation);
  void setBrushRoundness(float value);
  void setBrushAngle(float value);
  void setCursorRotation(float value);
  void setZoomLevel(float zoom);
  void setViewOffset(const QPointF &offset);
  void setCurrentTool(const QString &tool);
  void commitTransform();
  void beginTransform();
  void setIsFlippedH(bool flip);
  void setIsFlippedV(bool flip);
  void setIsEraser(bool eraser);
  Q_INVOKABLE void setBackgroundColor(const QString &color);
  Q_INVOKABLE void setUseCustomCursor(bool use);
  Q_INVOKABLE void usePreset(const QString &name);
  Q_INVOKABLE bool loadProject(const QString &path);
  Q_INVOKABLE bool saveProject(const QString &path);
  Q_INVOKABLE bool saveProjectAs(const QString &path);
  Q_INVOKABLE bool exportImage(const QString &path, const QString &format);
  Q_INVOKABLE bool importABR(const QString &path);
  Q_INVOKABLE void updateTransformProperties(float x, float y, float scale,
                                             float rotation, float w, float h);

  Q_INVOKABLE void resizeCanvas(int w, int h);
  Q_INVOKABLE void setProjectDpi(int dpi);
  Q_INVOKABLE QString sampleColor(int x, int y, int mode = 0);
  Q_INVOKABLE void adjustBrushSize(float deltaPercent);
  Q_INVOKABLE void adjustBrushOpacity(float deltaPercent);
  Q_INVOKABLE bool isLayerClipped(int index);
  Q_INVOKABLE void toggleClipping(int index);
  Q_INVOKABLE void toggleAlphaLock(int index);
  Q_INVOKABLE void toggleVisibility(int index);
  Q_INVOKABLE void toggleLock(int index);
  Q_INVOKABLE void clearLayer(int index);
  Q_INVOKABLE void setLayerOpacity(int index, float opacity);
  Q_INVOKABLE void setLayerOpacityPreview(int index, float opacity); // Fast update without model refresh
  Q_INVOKABLE void setLayerBlendMode(int index, const QString &mode);
  Q_INVOKABLE void setLayerPrivate(int index, bool isPrivate);
  Q_INVOKABLE void setActiveLayer(int index);

  // Selection Manipulation
  Q_INVOKABLE void invertSelection();
  Q_INVOKABLE void featherSelection(float radius);
  Q_INVOKABLE void duplicateSelection();
  Q_INVOKABLE void maskSelection();
  Q_INVOKABLE void colorSelection(const QColor &color);
  Q_INVOKABLE void clearSelectionContent();
  Q_INVOKABLE void deselect();
  Q_INVOKABLE void selectAll();
  Q_INVOKABLE void apply_color_drop(int x, int y, const QColor &color);
  
  void setSelectionAddMode(int mode);
  void setSelectionThreshold(float threshold);
  void setIsSelectionModeActive(bool active);

  // Color Utilities (HCL support for Pro Sliders)
  Q_INVOKABLE QString hclToHex(float h, float c, float l);
  Q_INVOKABLE QVariantList hexToHcl(const QString &hex);

  // Undo/Redo
  Q_INVOKABLE void undo();
  Q_INVOKABLE void redo();
  Q_INVOKABLE bool canUndo() const;
  Q_INVOKABLE bool canRedo() const;

  // Q_INVOKABLE methods for Python compatibility
  Q_INVOKABLE void loadRecentProjectsAsync();
  Q_INVOKABLE QVariantList getRecentProjects(); // RE-ADDED
  QRectF transformBox() const { return m_transformBox; }
  Q_INVOKABLE QVariantList get_project_list();  // RE-ADDED
  Q_INVOKABLE void load_file_path(const QString &path);
  Q_INVOKABLE void handle_shortcuts(int key, int modifiers);
  Q_INVOKABLE void handle_key_release(int key);
  Q_INVOKABLE void fitToView();
  Q_INVOKABLE void addLayer();
  Q_INVOKABLE void removeLayer(int index);
  Q_INVOKABLE void duplicateLayer(int index);
  Q_INVOKABLE void moveLayer(int fromIndex, int toIndex);
  Q_INVOKABLE void mergeDown(int index);
  Q_INVOKABLE void renameLayer(int index, const QString &name);
  Q_INVOKABLE void applyEffect(int index, const QString &effect,
                               const QVariantMap &params);
  Q_INVOKABLE QString get_brush_preview(const QString &brushName);
  Q_INVOKABLE QVariantList getBrushesForCategory(const QString &category);

  // ══════════════════════════════════════════════════════════════
  // Brush Studio — Property Bridge API
  // ══════════════════════════════════════════════════════════════
  // Editing lifecycle
  Q_INVOKABLE void beginBrushEdit(const QString &brushName);
  Q_INVOKABLE void cancelBrushEdit();
  Q_INVOKABLE void applyBrushEdit();
  Q_INVOKABLE void saveAsCopyBrush(const QString &newName);
  Q_INVOKABLE void resetBrushToDefault();

  // Generic property getter/setter for ALL brush studio properties
  // category: "stroke", "shape", "grain", "wetmix", "color", "dynamics",
  // "rendering", "customize", "meta"
  Q_INVOKABLE QVariant getBrushProperty(const QString &category,
                                        const QString &key);
  Q_INVOKABLE void setBrushProperty(const QString &category, const QString &key,
                                    const QVariant &value);

  // Get all properties for a category as a JS object (for initializing QML
  // controls)
  Q_INVOKABLE QVariantMap getBrushCategoryProperties(const QString &category);

  // Drawing Pad preview
  Q_INVOKABLE void clearPreviewPad();
  Q_INVOKABLE void previewPadBeginStroke(float x, float y, float pressure);
  Q_INVOKABLE void previewPadContinueStroke(float x, float y, float pressure);
  Q_INVOKABLE void previewPadEndStroke();
  Q_INVOKABLE QString getPreviewPadImage();

  // Stamp preview (single brush stamp for sidebar thumbnail)
  Q_INVOKABLE QString getStampPreview();

  QVariantList pressureCurvePoints() const { return m_rawPoints; }
  Q_INVOKABLE void setCurvePoints(const QVariantList &points);

signals:
  void brushSizeChanged();
  void brushColorChanged();
  void brushOpacityChanged();
  void brushFlowChanged();
  void brushHardnessChanged();
  void brushSpacingChanged();
  void brushStabilizationChanged();
  void brushStreamlineChanged();
  void brushGrainChanged();
  void brushWetnessChanged();
  void brushSmudgeChanged();
  void impastoShininessChanged();
  void impastoSettingsChanged();
  void brushRoundnessChanged();

  void zoomLevelChanged();
  void currentToolChanged();
  void canvasWidthChanged();
  void canvasHeightChanged();
  void viewOffsetChanged();
  void activeLayerChanged();
  void isTransformingChanged();
  void transformModeChanged();
  void brushAngleChanged();
  void cursorRotationChanged();
  void currentProjectPathChanged();
  void currentProjectNameChanged();
  void brushTipChanged();
  void cursorPosChanged(float x, float y);
  void projectsLoaded(const QVariantList &projects);
  void isEraserChanged(bool eraser);
  void layersChanged(const QVariantList &layers);
  void availableBrushesChanged();
  void activeBrushNameChanged();
  void brushTipImageChanged();
  void isFlippedHChanged();
  void isFlippedVChanged();

  void hasSelectionChanged();
  void selectionAddModeChanged();
  void selectionThresholdChanged();
  void isSelectionModeActiveChanged();

  void pressureCurvePointsChanged(); // SEÑAL AÑADIDA
  void strokeStarted(const QColor &color);
  void notificationRequested(const QString &message, const QString &type);
  void transformBoxChanged();

  // Brush Studio signals
  void isEditingBrushChanged();
  void editingPresetChanged();
  void brushPropertyChanged(const QString &category, const QString &key);
  void previewPadUpdated();
  void requestToolIdx(int index);

protected:
  void mousePressEvent(QMouseEvent *event) override;
  void mouseMoveEvent(QMouseEvent *event) override;
  void mouseReleaseEvent(QMouseEvent *event) override;
  void mouseDoubleClickEvent(QMouseEvent *event) override;
  void wheelEvent(QWheelEvent *event) override;
  void hoverMoveEvent(QHoverEvent *event) override;
  void hoverEnterEvent(QHoverEvent *event) override;
  void hoverLeaveEvent(QHoverEvent *event) override;
  void tabletEvent(QTabletEvent *event);
  bool event(QEvent *event) override;

private:
  artflow::BrushEngine *m_brushEngine;
  artflow::LayerManager *m_layerManager;
  artflow::UndoManager *m_undoManager;
  std::unique_ptr<artflow::ImageBuffer> m_strokeBeforeBuffer;
  std::unique_ptr<artflow::ImageBuffer> m_transformBeforeBuffer;

  // Pressure Logic
  // Pressure Logic
  std::vector<float> m_lut;
  QVariantList m_rawPoints;

  // Spline Calculation Members
  std::vector<double> m_splineX;
  std::vector<double> m_splineY;
  std::vector<double> m_splineM;
  void prepareSpline(const std::vector<std::pair<float, float>> &points);
  float evaluateSpline(float x);

  void updateLUT(float x1, float y1, float x2, float y2);
  float applyPressureCurve(float input);

  int m_brushSize;
  QColor m_brushColor;
  float m_brushOpacity;
  float m_brushFlow;
  float m_brushHardness;
  float m_brushSpacing;
  float m_brushStabilization;
  float m_brushStreamline;
  float m_brushGrain;
  float m_brushWetness;
  float m_brushSmudge;
  float m_brushRoundness = 1.0f;

  float m_zoomLevel;
  QString m_currentToolStr; // QML compatibility
  ToolType m_tool = ToolType::Pen;
  int m_canvasWidth;
  int m_canvasHeight;
  QPointF m_viewOffset;
  int m_activeLayerIndex;
  float m_brushAngle;
  float m_cursorRotation;

  QColor m_backgroundColor; // Paper/Layer Background (e.g. Transparent/White)
  QColor m_workspaceColor;  // App Workspace Background (Theme based)
  QColor m_accentColor;     // UI Elements Accent (Theme based)
  bool m_isFlippedH = false;
  bool m_isFlippedV = false;
  bool m_isEraser = false;
  QString m_currentProjectPath;
  QString m_currentProjectName;
  QString m_brushTip;
  QVariantList m_availableBrushes;
  QString m_activeBrushName;
  QString m_brushTipImage;

  // ── Brush Studio editing state ──
  bool m_isEditingBrush = false;
  artflow::BrushPreset m_editingPreset; // Working copy being edited
  artflow::BrushPreset m_resetPoint;    // Original state for "Reset"
  QImage m_previewPadImage;             // Offscreen drawing pad
  QPointF m_previewLastPos;
  bool m_previewIsDrawing = false;

  // Internal helper: apply editing preset to brush engine for live preview
  void applyEditingPresetToEngine();

  QPointF m_lastPos;
  QPointF m_lastMousePos; // For Pan delta
  float m_lastPressure;
  bool m_isDrawing;
  bool m_isHoldingForShape = false;
  std::vector<QPointF> m_strokePoints;
  QTimer *m_quickShapeTimer = nullptr;
  QPointF m_holdStartPos;

  // Premium Rendering (Ping-Pong FBOs)
  QOpenGLFramebufferObject *m_pingFBO = nullptr;
  QOpenGLFramebufferObject *m_pongFBO = nullptr;
  uint32_t m_currentCanvasTexID = 0;
  QOpenGLShaderProgram *m_impastoShader = nullptr;
  float m_impastoShininess = 64.0f;
  float m_impastoStrength = 1.0f;
  float m_lightAngle = 45.0f;
  float m_lightElevation = 0.5f;
  QMap<void *, QOpenGLTexture *> m_layerTextures;

  // Renderizado por software / OpenGL Engine
  void handleDraw(const QPointF &pos, float pressure, float tilt = 0.0f);

  // QuickShape
  void detectAndDrawQuickShape();
  void drawLine(const QPointF &p1, const QPointF &p2);
  void drawCircle(const QPointF &center, float radius);

  QVariantList _scanSync();
  void updateLayersList();
  // Selection and Transform state
  QPainterPath m_selectionPath;
  bool m_hasSelection = false;
  QImage m_selectionBuffer;
  QTransform m_transformMatrix;
  QRectF m_transformBox;
  bool m_isTransforming = false;
  
  int m_selectionAddMode = 0; // 0=New, 1=Add, 2=Subtract
  float m_selectionThreshold = 0.5f;
  bool m_isSelectionModeActive = false;
  QString m_previousToolStr = "brush";
  
  // Advanced Selection State
  QPointF m_lastSelectionPoint;
  QPointF m_selectionStartPos;
  bool m_isLassoDragging = false;
  bool m_isMagneticLassoActive = false;
  
  enum class TransformMode { None, Move, Scale, Rotate };
  TransformMode m_transformMode = TransformMode::None;
  TransformSubMode m_transformSubMode = Free;
  QPointF m_transformStartPos;
  QTransform m_initialMatrix;

  // Krita-style Brush Cursor
  QPointF m_cursorPos;
  bool m_cursorVisible = false;

  // Composition Shader
  QOpenGLShaderProgram *m_compositionShader = nullptr;
  void blendWithShader(QPainter *painter, artflow::Layer *layer, const QRectF &rect, artflow::Layer *maskLayer = nullptr, uint32_t overrideTextureId = 0);
  QImage m_brushOutlineCache;
  QString m_lastBrushTexturePath;
  float m_lastCursorSize = -1;
  float m_lastCursorRotation = -1;
  QColor m_lastCursorColor;
  bool m_cursorCacheDirty = true;

  QImage loadAndProcessBrushTexture(const QString &texturePath, float size,
                                    float rotation, float zoomOverride = 0.0f,
                                    bool outline = false);
  void invalidateCursorCache();
  void updateBrushTipImage();

  void capture_timelapse_frame();
};

#endif // CANVASITEM_H
