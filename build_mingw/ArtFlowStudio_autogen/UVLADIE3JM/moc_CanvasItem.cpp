/****************************************************************************
** Meta object code from reading C++ file 'CanvasItem.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/CanvasItem.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'CanvasItem.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN10CanvasItemE_t {};
} // unnamed namespace

template <> constexpr inline auto CanvasItem::qt_create_metaobjectdata<qt_meta_tag_ZN10CanvasItemE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "CanvasItem",
        "brushSizeChanged",
        "",
        "brushColorChanged",
        "brushOpacityChanged",
        "brushFlowChanged",
        "brushHardnessChanged",
        "brushSpacingChanged",
        "brushStabilizationChanged",
        "brushStreamlineChanged",
        "brushGrainChanged",
        "brushWetnessChanged",
        "brushSmudgeChanged",
        "impastoShininessChanged",
        "impastoSettingsChanged",
        "brushRoundnessChanged",
        "zoomLevelChanged",
        "currentToolChanged",
        "canvasWidthChanged",
        "canvasHeightChanged",
        "viewOffsetChanged",
        "activeLayerChanged",
        "isTransformingChanged",
        "transformModeChanged",
        "brushAngleChanged",
        "cursorRotationChanged",
        "currentProjectPathChanged",
        "currentProjectNameChanged",
        "brushTipChanged",
        "cursorPosChanged",
        "x",
        "y",
        "projectsLoaded",
        "QVariantList",
        "projects",
        "isEraserChanged",
        "eraser",
        "layersChanged",
        "layers",
        "availableBrushesChanged",
        "activeBrushNameChanged",
        "brushTipImageChanged",
        "isFlippedHChanged",
        "isFlippedVChanged",
        "hasSelectionChanged",
        "selectionAddModeChanged",
        "selectionThresholdChanged",
        "isSelectionModeActiveChanged",
        "projectListChanged",
        "brushCategoriesChanged",
        "isImportingChanged",
        "importProgressChanged",
        "sizeByPressureChanged",
        "opacityByPressureChanged",
        "flowByPressureChanged",
        "pressureCurvePointsChanged",
        "strokeStarted",
        "QColor",
        "color",
        "notificationRequested",
        "message",
        "type",
        "transformBoxChanged",
        "isEditingBrushChanged",
        "editingPresetChanged",
        "brushPropertyChanged",
        "category",
        "key",
        "previewPadUpdated",
        "requestToolIdx",
        "index",
        "applyTransform",
        "cancelTransform",
        "setBackgroundColor",
        "setUseCustomCursor",
        "use",
        "flattenComicPanels",
        "panels",
        "usePreset",
        "name",
        "loadProject",
        "path",
        "saveProject",
        "saveProjectAs",
        "exportImage",
        "format",
        "importABR",
        "updateTransformProperties",
        "scale",
        "rotation",
        "w",
        "h",
        "updateTransformCorners",
        "corners",
        "resizeCanvas",
        "setProjectDpi",
        "dpi",
        "drawPanelLayout",
        "layoutType",
        "gutterPx",
        "borderPx",
        "marginPx",
        "sampleColor",
        "mode",
        "adjustBrushSize",
        "deltaPercent",
        "adjustBrushOpacity",
        "isLayerClipped",
        "toggleClipping",
        "toggleAlphaLock",
        "toggleVisibility",
        "toggleLock",
        "clearLayer",
        "setLayerOpacity",
        "opacity",
        "setLayerOpacityPreview",
        "setLayerBlendMode",
        "setLayerPrivate",
        "isPrivate",
        "setActiveLayer",
        "invertSelection",
        "featherSelection",
        "radius",
        "duplicateSelection",
        "maskSelection",
        "colorSelection",
        "clearSelectionContent",
        "deselect",
        "selectAll",
        "apply_color_drop",
        "hclToHex",
        "c",
        "l",
        "hexToHcl",
        "hex",
        "undo",
        "redo",
        "canUndo",
        "canRedo",
        "loadRecentProjectsAsync",
        "getRecentProjects",
        "create_folder_from_merge",
        "sourcePath",
        "targetPath",
        "get_project_list",
        "get_sketchbook_pages",
        "folderPath",
        "create_new_sketchbook",
        "coverColor",
        "create_new_page",
        "pageName",
        "exportPageImage",
        "projectPath",
        "outputPath",
        "exportAllPages",
        "outputDir",
        "load_file_path",
        "deleteProject",
        "deleteFolder",
        "rename_item",
        "newName",
        "moveProjectOutOfFolder",
        "handle_shortcuts",
        "modifiers",
        "handle_key_release",
        "fitToView",
        "addLayer",
        "addGroup",
        "removeLayer",
        "duplicateLayer",
        "moveLayer",
        "fromIndex",
        "toIndex",
        "mergeDown",
        "renameLayer",
        "applyEffect",
        "effect",
        "QVariantMap",
        "params",
        "get_brush_preview",
        "brushName",
        "getBrushesForCategory",
        "getBrushCategories",
        "getBrushCategoryNames",
        "beginBrushEdit",
        "cancelBrushEdit",
        "applyBrushEdit",
        "saveAsCopyBrush",
        "resetBrushToDefault",
        "getBrushProperty",
        "QVariant",
        "setBrushProperty",
        "value",
        "getBrushCategoryProperties",
        "clearPreviewPad",
        "previewPadBeginStroke",
        "pressure",
        "previewPadContinueStroke",
        "previewPadEndStroke",
        "getPreviewPadImage",
        "getStampPreview",
        "setCurvePoints",
        "points",
        "brushSize",
        "brushColor",
        "brushOpacity",
        "brushFlow",
        "brushHardness",
        "brushSpacing",
        "brushStabilization",
        "brushStreamline",
        "brushGrain",
        "brushWetness",
        "brushSmudge",
        "impastoShininess",
        "impastoStrength",
        "lightAngle",
        "lightElevation",
        "brushRoundness",
        "zoomLevel",
        "layerModel",
        "currentTool",
        "canvasWidth",
        "canvasHeight",
        "viewOffset",
        "QPointF",
        "activeLayerIndex",
        "isTransforming",
        "brushAngle",
        "cursorRotation",
        "currentProjectPath",
        "currentProjectName",
        "brushTip",
        "isEraser",
        "isFlippedH",
        "isFlippedV",
        "canvasScale",
        "canvasOffset",
        "transformBox",
        "QRectF",
        "pressureCurvePoints",
        "availableBrushes",
        "activeBrushName",
        "brushTipImage",
        "brushCategories",
        "isEditingBrush",
        "hasSelection",
        "selectionAddMode",
        "selectionThreshold",
        "isSelectionModeActive",
        "isImporting",
        "importProgress",
        "transformMode",
        "sizeByPressure",
        "opacityByPressure",
        "flowByPressure",
        "ToolType",
        "Pen",
        "Eraser",
        "Lasso",
        "MagneticLasso",
        "RectSelect",
        "EllipseSelect",
        "MagicWand",
        "Transform",
        "Eyedropper",
        "Hand",
        "Fill",
        "Shape",
        "PanelCut",
        "TransformSubMode",
        "Free",
        "Perspective",
        "Warp",
        "Mesh"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'brushSizeChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushColorChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushOpacityChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushFlowChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushHardnessChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushSpacingChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushStabilizationChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushStreamlineChanged'
        QtMocHelpers::SignalData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushGrainChanged'
        QtMocHelpers::SignalData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushWetnessChanged'
        QtMocHelpers::SignalData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushSmudgeChanged'
        QtMocHelpers::SignalData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'impastoShininessChanged'
        QtMocHelpers::SignalData<void()>(13, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'impastoSettingsChanged'
        QtMocHelpers::SignalData<void()>(14, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushRoundnessChanged'
        QtMocHelpers::SignalData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'zoomLevelChanged'
        QtMocHelpers::SignalData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentToolChanged'
        QtMocHelpers::SignalData<void()>(17, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'canvasWidthChanged'
        QtMocHelpers::SignalData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'canvasHeightChanged'
        QtMocHelpers::SignalData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'viewOffsetChanged'
        QtMocHelpers::SignalData<void()>(20, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeLayerChanged'
        QtMocHelpers::SignalData<void()>(21, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isTransformingChanged'
        QtMocHelpers::SignalData<void()>(22, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'transformModeChanged'
        QtMocHelpers::SignalData<void()>(23, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushAngleChanged'
        QtMocHelpers::SignalData<void()>(24, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cursorRotationChanged'
        QtMocHelpers::SignalData<void()>(25, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentProjectPathChanged'
        QtMocHelpers::SignalData<void()>(26, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentProjectNameChanged'
        QtMocHelpers::SignalData<void()>(27, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushTipChanged'
        QtMocHelpers::SignalData<void()>(28, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cursorPosChanged'
        QtMocHelpers::SignalData<void(float, float)>(29, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 },
        }}),
        // Signal 'projectsLoaded'
        QtMocHelpers::SignalData<void(const QVariantList &)>(32, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 34 },
        }}),
        // Signal 'isEraserChanged'
        QtMocHelpers::SignalData<void(bool)>(35, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 36 },
        }}),
        // Signal 'layersChanged'
        QtMocHelpers::SignalData<void(const QVariantList &)>(37, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 38 },
        }}),
        // Signal 'availableBrushesChanged'
        QtMocHelpers::SignalData<void()>(39, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeBrushNameChanged'
        QtMocHelpers::SignalData<void()>(40, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushTipImageChanged'
        QtMocHelpers::SignalData<void()>(41, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedHChanged'
        QtMocHelpers::SignalData<void()>(42, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedVChanged'
        QtMocHelpers::SignalData<void()>(43, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'hasSelectionChanged'
        QtMocHelpers::SignalData<void()>(44, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'selectionAddModeChanged'
        QtMocHelpers::SignalData<void()>(45, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'selectionThresholdChanged'
        QtMocHelpers::SignalData<void()>(46, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isSelectionModeActiveChanged'
        QtMocHelpers::SignalData<void()>(47, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'projectListChanged'
        QtMocHelpers::SignalData<void()>(48, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushCategoriesChanged'
        QtMocHelpers::SignalData<void()>(49, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isImportingChanged'
        QtMocHelpers::SignalData<void()>(50, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'importProgressChanged'
        QtMocHelpers::SignalData<void()>(51, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'sizeByPressureChanged'
        QtMocHelpers::SignalData<void()>(52, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'opacityByPressureChanged'
        QtMocHelpers::SignalData<void()>(53, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'flowByPressureChanged'
        QtMocHelpers::SignalData<void()>(54, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurvePointsChanged'
        QtMocHelpers::SignalData<void()>(55, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'strokeStarted'
        QtMocHelpers::SignalData<void(const QColor &)>(56, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 57, 58 },
        }}),
        // Signal 'notificationRequested'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(59, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 60 }, { QMetaType::QString, 61 },
        }}),
        // Signal 'transformBoxChanged'
        QtMocHelpers::SignalData<void()>(62, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isEditingBrushChanged'
        QtMocHelpers::SignalData<void()>(63, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'editingPresetChanged'
        QtMocHelpers::SignalData<void()>(64, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushPropertyChanged'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(65, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 66 }, { QMetaType::QString, 67 },
        }}),
        // Signal 'previewPadUpdated'
        QtMocHelpers::SignalData<void()>(68, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'requestToolIdx'
        QtMocHelpers::SignalData<void(int)>(69, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'applyTransform'
        QtMocHelpers::MethodData<void()>(71, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'cancelTransform'
        QtMocHelpers::MethodData<void()>(72, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'setBackgroundColor'
        QtMocHelpers::MethodData<void(const QString &)>(73, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 58 },
        }}),
        // Method 'setUseCustomCursor'
        QtMocHelpers::MethodData<void(bool)>(74, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 75 },
        }}),
        // Method 'flattenComicPanels'
        QtMocHelpers::MethodData<void(const QVariantList &)>(76, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 77 },
        }}),
        // Method 'usePreset'
        QtMocHelpers::MethodData<void(const QString &)>(78, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 79 },
        }}),
        // Method 'loadProject'
        QtMocHelpers::MethodData<bool(const QString &)>(80, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'saveProject'
        QtMocHelpers::MethodData<bool(const QString &)>(82, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'saveProjectAs'
        QtMocHelpers::MethodData<bool(const QString &)>(83, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'exportImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(84, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 }, { QMetaType::QString, 85 },
        }}),
        // Method 'importABR'
        QtMocHelpers::MethodData<bool(const QString &)>(86, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'updateTransformProperties'
        QtMocHelpers::MethodData<void(float, float, float, float, float, float)>(87, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 }, { QMetaType::Float, 88 }, { QMetaType::Float, 89 },
            { QMetaType::Float, 90 }, { QMetaType::Float, 91 },
        }}),
        // Method 'updateTransformCorners'
        QtMocHelpers::MethodData<void(const QVariantList &)>(92, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 93 },
        }}),
        // Method 'resizeCanvas'
        QtMocHelpers::MethodData<void(int, int)>(94, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 90 }, { QMetaType::Int, 91 },
        }}),
        // Method 'setProjectDpi'
        QtMocHelpers::MethodData<void(int)>(95, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 96 },
        }}),
        // Method 'drawPanelLayout'
        QtMocHelpers::MethodData<void(const QString &, int, int, int)>(97, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 98 }, { QMetaType::Int, 99 }, { QMetaType::Int, 100 }, { QMetaType::Int, 101 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int, int)>(102, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Int, 30 }, { QMetaType::Int, 31 }, { QMetaType::Int, 103 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int)>(102, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::QString, {{
            { QMetaType::Int, 30 }, { QMetaType::Int, 31 },
        }}),
        // Method 'adjustBrushSize'
        QtMocHelpers::MethodData<void(float)>(104, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 105 },
        }}),
        // Method 'adjustBrushOpacity'
        QtMocHelpers::MethodData<void(float)>(106, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 105 },
        }}),
        // Method 'isLayerClipped'
        QtMocHelpers::MethodData<bool(int)>(107, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'toggleClipping'
        QtMocHelpers::MethodData<void(int)>(108, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'toggleAlphaLock'
        QtMocHelpers::MethodData<void(int)>(109, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'toggleVisibility'
        QtMocHelpers::MethodData<void(int)>(110, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'toggleLock'
        QtMocHelpers::MethodData<void(int)>(111, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'clearLayer'
        QtMocHelpers::MethodData<void(int)>(112, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'setLayerOpacity'
        QtMocHelpers::MethodData<void(int, float)>(113, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::Float, 114 },
        }}),
        // Method 'setLayerOpacityPreview'
        QtMocHelpers::MethodData<void(int, float)>(115, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::Float, 114 },
        }}),
        // Method 'setLayerBlendMode'
        QtMocHelpers::MethodData<void(int, const QString &)>(116, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::QString, 103 },
        }}),
        // Method 'setLayerPrivate'
        QtMocHelpers::MethodData<void(int, bool)>(117, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::Bool, 118 },
        }}),
        // Method 'setActiveLayer'
        QtMocHelpers::MethodData<void(int)>(119, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'invertSelection'
        QtMocHelpers::MethodData<void()>(120, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'featherSelection'
        QtMocHelpers::MethodData<void(float)>(121, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 122 },
        }}),
        // Method 'duplicateSelection'
        QtMocHelpers::MethodData<void()>(123, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'maskSelection'
        QtMocHelpers::MethodData<void()>(124, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'colorSelection'
        QtMocHelpers::MethodData<void(const QColor &)>(125, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 57, 58 },
        }}),
        // Method 'clearSelectionContent'
        QtMocHelpers::MethodData<void()>(126, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'deselect'
        QtMocHelpers::MethodData<void()>(127, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'selectAll'
        QtMocHelpers::MethodData<void()>(128, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'apply_color_drop'
        QtMocHelpers::MethodData<void(int, int, const QColor &)>(129, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 30 }, { QMetaType::Int, 31 }, { 0x80000000 | 57, 58 },
        }}),
        // Method 'hclToHex'
        QtMocHelpers::MethodData<QString(float, float, float)>(130, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Float, 91 }, { QMetaType::Float, 131 }, { QMetaType::Float, 132 },
        }}),
        // Method 'hexToHcl'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(133, 2, QMC::AccessPublic, 0x80000000 | 33, {{
            { QMetaType::QString, 134 },
        }}),
        // Method 'undo'
        QtMocHelpers::MethodData<void()>(135, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'redo'
        QtMocHelpers::MethodData<void()>(136, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'canUndo'
        QtMocHelpers::MethodData<bool() const>(137, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'canRedo'
        QtMocHelpers::MethodData<bool() const>(138, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'loadRecentProjectsAsync'
        QtMocHelpers::MethodData<void()>(139, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getRecentProjects'
        QtMocHelpers::MethodData<QVariantList()>(140, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'create_folder_from_merge'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(141, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 142 }, { QMetaType::QString, 143 },
        }}),
        // Method 'get_project_list'
        QtMocHelpers::MethodData<QVariantList()>(144, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'get_sketchbook_pages'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(145, 2, QMC::AccessPublic, 0x80000000 | 33, {{
            { QMetaType::QString, 146 },
        }}),
        // Method 'create_new_sketchbook'
        QtMocHelpers::MethodData<QString(const QString &, const QString &)>(147, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 79 }, { QMetaType::QString, 148 },
        }}),
        // Method 'create_new_page'
        QtMocHelpers::MethodData<QString(const QString &, const QString &)>(149, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 146 }, { QMetaType::QString, 150 },
        }}),
        // Method 'exportPageImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &, const QString &)>(151, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 152 }, { QMetaType::QString, 153 }, { QMetaType::QString, 85 },
        }}),
        // Method 'exportAllPages'
        QtMocHelpers::MethodData<bool(const QString &, const QString &, const QString &)>(154, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 146 }, { QMetaType::QString, 155 }, { QMetaType::QString, 85 },
        }}),
        // Method 'load_file_path'
        QtMocHelpers::MethodData<void(const QString &)>(156, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'deleteProject'
        QtMocHelpers::MethodData<bool(const QString &)>(157, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'deleteFolder'
        QtMocHelpers::MethodData<bool(const QString &)>(158, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'rename_item'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(159, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 }, { QMetaType::QString, 160 },
        }}),
        // Method 'moveProjectOutOfFolder'
        QtMocHelpers::MethodData<bool(const QString &)>(161, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 81 },
        }}),
        // Method 'handle_shortcuts'
        QtMocHelpers::MethodData<void(int, int)>(162, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 }, { QMetaType::Int, 163 },
        }}),
        // Method 'handle_key_release'
        QtMocHelpers::MethodData<void(int)>(164, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'fitToView'
        QtMocHelpers::MethodData<void()>(165, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addLayer'
        QtMocHelpers::MethodData<void()>(166, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addGroup'
        QtMocHelpers::MethodData<void()>(167, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'removeLayer'
        QtMocHelpers::MethodData<void(int)>(168, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'duplicateLayer'
        QtMocHelpers::MethodData<void(int)>(169, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'moveLayer'
        QtMocHelpers::MethodData<void(int, int)>(170, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 171 }, { QMetaType::Int, 172 },
        }}),
        // Method 'mergeDown'
        QtMocHelpers::MethodData<void(int)>(173, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'renameLayer'
        QtMocHelpers::MethodData<void(int, const QString &)>(174, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::QString, 79 },
        }}),
        // Method 'applyEffect'
        QtMocHelpers::MethodData<void(int, const QString &, const QVariantMap &)>(175, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::QString, 176 }, { 0x80000000 | 177, 178 },
        }}),
        // Method 'get_brush_preview'
        QtMocHelpers::MethodData<QString(const QString &)>(179, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 180 },
        }}),
        // Method 'getBrushesForCategory'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(181, 2, QMC::AccessPublic, 0x80000000 | 33, {{
            { QMetaType::QString, 66 },
        }}),
        // Method 'getBrushCategories'
        QtMocHelpers::MethodData<QVariantList()>(182, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'getBrushCategoryNames'
        QtMocHelpers::MethodData<QStringList()>(183, 2, QMC::AccessPublic, QMetaType::QStringList),
        // Method 'beginBrushEdit'
        QtMocHelpers::MethodData<void(const QString &)>(184, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 180 },
        }}),
        // Method 'cancelBrushEdit'
        QtMocHelpers::MethodData<void()>(185, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'applyBrushEdit'
        QtMocHelpers::MethodData<void()>(186, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'saveAsCopyBrush'
        QtMocHelpers::MethodData<void(const QString &)>(187, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 160 },
        }}),
        // Method 'resetBrushToDefault'
        QtMocHelpers::MethodData<void()>(188, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getBrushProperty'
        QtMocHelpers::MethodData<QVariant(const QString &, const QString &)>(189, 2, QMC::AccessPublic, 0x80000000 | 190, {{
            { QMetaType::QString, 66 }, { QMetaType::QString, 67 },
        }}),
        // Method 'setBrushProperty'
        QtMocHelpers::MethodData<void(const QString &, const QString &, const QVariant &)>(191, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 66 }, { QMetaType::QString, 67 }, { 0x80000000 | 190, 192 },
        }}),
        // Method 'getBrushCategoryProperties'
        QtMocHelpers::MethodData<QVariantMap(const QString &)>(193, 2, QMC::AccessPublic, 0x80000000 | 177, {{
            { QMetaType::QString, 66 },
        }}),
        // Method 'clearPreviewPad'
        QtMocHelpers::MethodData<void()>(194, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'previewPadBeginStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(195, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 }, { QMetaType::Float, 196 },
        }}),
        // Method 'previewPadContinueStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(197, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 }, { QMetaType::Float, 196 },
        }}),
        // Method 'previewPadEndStroke'
        QtMocHelpers::MethodData<void()>(198, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getPreviewPadImage'
        QtMocHelpers::MethodData<QString()>(199, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'getStampPreview'
        QtMocHelpers::MethodData<QString()>(200, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'setCurvePoints'
        QtMocHelpers::MethodData<void(const QVariantList &)>(201, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 202 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'brushSize'
        QtMocHelpers::PropertyData<int>(203, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'brushColor'
        QtMocHelpers::PropertyData<QColor>(204, 0x80000000 | 57, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'brushOpacity'
        QtMocHelpers::PropertyData<float>(205, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'brushFlow'
        QtMocHelpers::PropertyData<float>(206, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'brushHardness'
        QtMocHelpers::PropertyData<float>(207, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'brushSpacing'
        QtMocHelpers::PropertyData<float>(208, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'brushStabilization'
        QtMocHelpers::PropertyData<float>(209, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'brushStreamline'
        QtMocHelpers::PropertyData<float>(210, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'brushGrain'
        QtMocHelpers::PropertyData<float>(211, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'brushWetness'
        QtMocHelpers::PropertyData<float>(212, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'brushSmudge'
        QtMocHelpers::PropertyData<float>(213, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'impastoShininess'
        QtMocHelpers::PropertyData<float>(214, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'impastoStrength'
        QtMocHelpers::PropertyData<float>(215, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightAngle'
        QtMocHelpers::PropertyData<float>(216, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightElevation'
        QtMocHelpers::PropertyData<float>(217, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'brushRoundness'
        QtMocHelpers::PropertyData<float>(218, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 13),
        // property 'zoomLevel'
        QtMocHelpers::PropertyData<float>(219, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 14),
        // property 'layerModel'
        QtMocHelpers::PropertyData<QVariantList>(220, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 30),
        // property 'currentTool'
        QtMocHelpers::PropertyData<QString>(221, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 15),
        // property 'canvasWidth'
        QtMocHelpers::PropertyData<int>(222, QMetaType::Int, QMC::DefaultPropertyFlags, 16),
        // property 'canvasHeight'
        QtMocHelpers::PropertyData<int>(223, QMetaType::Int, QMC::DefaultPropertyFlags, 17),
        // property 'viewOffset'
        QtMocHelpers::PropertyData<QPointF>(224, 0x80000000 | 225, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 18),
        // property 'activeLayerIndex'
        QtMocHelpers::PropertyData<int>(226, QMetaType::Int, QMC::DefaultPropertyFlags, 19),
        // property 'isTransforming'
        QtMocHelpers::PropertyData<bool>(227, QMetaType::Bool, QMC::DefaultPropertyFlags, 20),
        // property 'brushAngle'
        QtMocHelpers::PropertyData<float>(228, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 22),
        // property 'cursorRotation'
        QtMocHelpers::PropertyData<float>(229, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 23),
        // property 'currentProjectPath'
        QtMocHelpers::PropertyData<QString>(230, QMetaType::QString, QMC::DefaultPropertyFlags, 24),
        // property 'currentProjectName'
        QtMocHelpers::PropertyData<QString>(231, QMetaType::QString, QMC::DefaultPropertyFlags, 25),
        // property 'brushTip'
        QtMocHelpers::PropertyData<QString>(232, QMetaType::QString, QMC::DefaultPropertyFlags, 26),
        // property 'isEraser'
        QtMocHelpers::PropertyData<bool>(233, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 29),
        // property 'isFlippedH'
        QtMocHelpers::PropertyData<bool>(234, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 34),
        // property 'isFlippedV'
        QtMocHelpers::PropertyData<bool>(235, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 35),
        // property 'canvasScale'
        QtMocHelpers::PropertyData<float>(236, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable, 14),
        // property 'canvasOffset'
        QtMocHelpers::PropertyData<QPointF>(237, 0x80000000 | 225, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 18),
        // property 'transformBox'
        QtMocHelpers::PropertyData<QRectF>(238, 0x80000000 | 239, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 50),
        // property 'pressureCurvePoints'
        QtMocHelpers::PropertyData<QVariantList>(240, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 47),
        // property 'availableBrushes'
        QtMocHelpers::PropertyData<QVariantList>(241, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 31),
        // property 'activeBrushName'
        QtMocHelpers::PropertyData<QString>(242, QMetaType::QString, QMC::DefaultPropertyFlags, 32),
        // property 'brushTipImage'
        QtMocHelpers::PropertyData<QString>(243, QMetaType::QString, QMC::DefaultPropertyFlags, 33),
        // property 'brushCategories'
        QtMocHelpers::PropertyData<QVariantList>(244, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 41),
        // property 'isEditingBrush'
        QtMocHelpers::PropertyData<bool>(245, QMetaType::Bool, QMC::DefaultPropertyFlags, 51),
        // property 'hasSelection'
        QtMocHelpers::PropertyData<bool>(246, QMetaType::Bool, QMC::DefaultPropertyFlags, 36),
        // property 'selectionAddMode'
        QtMocHelpers::PropertyData<int>(247, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 37),
        // property 'selectionThreshold'
        QtMocHelpers::PropertyData<float>(248, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 38),
        // property 'isSelectionModeActive'
        QtMocHelpers::PropertyData<bool>(249, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 39),
        // property 'isImporting'
        QtMocHelpers::PropertyData<bool>(250, QMetaType::Bool, QMC::DefaultPropertyFlags, 42),
        // property 'importProgress'
        QtMocHelpers::PropertyData<float>(251, QMetaType::Float, QMC::DefaultPropertyFlags, 43),
        // property 'transformMode'
        QtMocHelpers::PropertyData<int>(252, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 21),
        // property 'sizeByPressure'
        QtMocHelpers::PropertyData<bool>(253, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 44),
        // property 'opacityByPressure'
        QtMocHelpers::PropertyData<bool>(254, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 45),
        // property 'flowByPressure'
        QtMocHelpers::PropertyData<bool>(255, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 46),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'ToolType'
        QtMocHelpers::EnumData<enum ToolType>(256, 256, QMC::EnumIsScoped).add({
            {  257, ToolType::Pen },
            {  258, ToolType::Eraser },
            {  259, ToolType::Lasso },
            {  260, ToolType::MagneticLasso },
            {  261, ToolType::RectSelect },
            {  262, ToolType::EllipseSelect },
            {  263, ToolType::MagicWand },
            {  264, ToolType::Transform },
            {  265, ToolType::Eyedropper },
            {  266, ToolType::Hand },
            {  267, ToolType::Fill },
            {  268, ToolType::Shape },
            {  269, ToolType::PanelCut },
        }),
        // enum 'TransformSubMode'
        QtMocHelpers::EnumData<enum TransformSubMode>(270, 270, QMC::EnumFlags{}).add({
            {  271, TransformSubMode::Free },
            {  272, TransformSubMode::Perspective },
            {  273, TransformSubMode::Warp },
            {  274, TransformSubMode::Mesh },
        }),
    };
    return QtMocHelpers::metaObjectData<CanvasItem, qt_meta_tag_ZN10CanvasItemE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject CanvasItem::staticMetaObject = { {
    QMetaObject::SuperData::link<QQuickPaintedItem::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10CanvasItemE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10CanvasItemE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN10CanvasItemE_t>.metaTypes,
    nullptr
} };

void CanvasItem::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<CanvasItem *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->brushSizeChanged(); break;
        case 1: _t->brushColorChanged(); break;
        case 2: _t->brushOpacityChanged(); break;
        case 3: _t->brushFlowChanged(); break;
        case 4: _t->brushHardnessChanged(); break;
        case 5: _t->brushSpacingChanged(); break;
        case 6: _t->brushStabilizationChanged(); break;
        case 7: _t->brushStreamlineChanged(); break;
        case 8: _t->brushGrainChanged(); break;
        case 9: _t->brushWetnessChanged(); break;
        case 10: _t->brushSmudgeChanged(); break;
        case 11: _t->impastoShininessChanged(); break;
        case 12: _t->impastoSettingsChanged(); break;
        case 13: _t->brushRoundnessChanged(); break;
        case 14: _t->zoomLevelChanged(); break;
        case 15: _t->currentToolChanged(); break;
        case 16: _t->canvasWidthChanged(); break;
        case 17: _t->canvasHeightChanged(); break;
        case 18: _t->viewOffsetChanged(); break;
        case 19: _t->activeLayerChanged(); break;
        case 20: _t->isTransformingChanged(); break;
        case 21: _t->transformModeChanged(); break;
        case 22: _t->brushAngleChanged(); break;
        case 23: _t->cursorRotationChanged(); break;
        case 24: _t->currentProjectPathChanged(); break;
        case 25: _t->currentProjectNameChanged(); break;
        case 26: _t->brushTipChanged(); break;
        case 27: _t->cursorPosChanged((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 28: _t->projectsLoaded((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 29: _t->isEraserChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 30: _t->layersChanged((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 31: _t->availableBrushesChanged(); break;
        case 32: _t->activeBrushNameChanged(); break;
        case 33: _t->brushTipImageChanged(); break;
        case 34: _t->isFlippedHChanged(); break;
        case 35: _t->isFlippedVChanged(); break;
        case 36: _t->hasSelectionChanged(); break;
        case 37: _t->selectionAddModeChanged(); break;
        case 38: _t->selectionThresholdChanged(); break;
        case 39: _t->isSelectionModeActiveChanged(); break;
        case 40: _t->projectListChanged(); break;
        case 41: _t->brushCategoriesChanged(); break;
        case 42: _t->isImportingChanged(); break;
        case 43: _t->importProgressChanged(); break;
        case 44: _t->sizeByPressureChanged(); break;
        case 45: _t->opacityByPressureChanged(); break;
        case 46: _t->flowByPressureChanged(); break;
        case 47: _t->pressureCurvePointsChanged(); break;
        case 48: _t->strokeStarted((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 49: _t->notificationRequested((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 50: _t->transformBoxChanged(); break;
        case 51: _t->isEditingBrushChanged(); break;
        case 52: _t->editingPresetChanged(); break;
        case 53: _t->brushPropertyChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 54: _t->previewPadUpdated(); break;
        case 55: _t->requestToolIdx((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 56: _t->applyTransform(); break;
        case 57: _t->cancelTransform(); break;
        case 58: _t->setBackgroundColor((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 59: _t->setUseCustomCursor((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 60: _t->flattenComicPanels((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 61: _t->usePreset((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 62: { bool _r = _t->loadProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 63: { bool _r = _t->saveProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 64: { bool _r = _t->saveProjectAs((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 65: { bool _r = _t->exportImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 66: { bool _r = _t->importABR((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 67: _t->updateTransformProperties((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[5])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[6]))); break;
        case 68: _t->updateTransformCorners((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 69: _t->resizeCanvas((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 70: _t->setProjectDpi((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 71: _t->drawPanelLayout((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 72: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 73: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 74: _t->adjustBrushSize((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 75: _t->adjustBrushOpacity((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 76: { bool _r = _t->isLayerClipped((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 77: _t->toggleClipping((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 78: _t->toggleAlphaLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 79: _t->toggleVisibility((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 80: _t->toggleLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 81: _t->clearLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 82: _t->setLayerOpacity((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 83: _t->setLayerOpacityPreview((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 84: _t->setLayerBlendMode((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 85: _t->setLayerPrivate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 86: _t->setActiveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 87: _t->invertSelection(); break;
        case 88: _t->featherSelection((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 89: _t->duplicateSelection(); break;
        case 90: _t->maskSelection(); break;
        case 91: _t->colorSelection((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 92: _t->clearSelectionContent(); break;
        case 93: _t->deselect(); break;
        case 94: _t->selectAll(); break;
        case 95: _t->apply_color_drop((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[3]))); break;
        case 96: { QString _r = _t->hclToHex((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 97: { QVariantList _r = _t->hexToHcl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 98: _t->undo(); break;
        case 99: _t->redo(); break;
        case 100: { bool _r = _t->canUndo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 101: { bool _r = _t->canRedo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 102: _t->loadRecentProjectsAsync(); break;
        case 103: { QVariantList _r = _t->getRecentProjects();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 104: { bool _r = _t->create_folder_from_merge((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 105: { QVariantList _r = _t->get_project_list();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 106: { QVariantList _r = _t->get_sketchbook_pages((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 107: { QString _r = _t->create_new_sketchbook((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 108: { QString _r = _t->create_new_page((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 109: { bool _r = _t->exportPageImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 110: { bool _r = _t->exportAllPages((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 111: _t->load_file_path((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 112: { bool _r = _t->deleteProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 113: { bool _r = _t->deleteFolder((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 114: { bool _r = _t->rename_item((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 115: { bool _r = _t->moveProjectOutOfFolder((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 116: _t->handle_shortcuts((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 117: _t->handle_key_release((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 118: _t->fitToView(); break;
        case 119: _t->addLayer(); break;
        case 120: _t->addGroup(); break;
        case 121: _t->removeLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 122: _t->duplicateLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 123: _t->moveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 124: _t->mergeDown((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 125: _t->renameLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 126: _t->applyEffect((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[3]))); break;
        case 127: { QString _r = _t->get_brush_preview((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 128: { QVariantList _r = _t->getBrushesForCategory((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 129: { QVariantList _r = _t->getBrushCategories();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 130: { QStringList _r = _t->getBrushCategoryNames();
            if (_a[0]) *reinterpret_cast<QStringList*>(_a[0]) = std::move(_r); }  break;
        case 131: _t->beginBrushEdit((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 132: _t->cancelBrushEdit(); break;
        case 133: _t->applyBrushEdit(); break;
        case 134: _t->saveAsCopyBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 135: _t->resetBrushToDefault(); break;
        case 136: { QVariant _r = _t->getBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QVariant*>(_a[0]) = std::move(_r); }  break;
        case 137: _t->setBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariant>>(_a[3]))); break;
        case 138: { QVariantMap _r = _t->getBrushCategoryProperties((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 139: _t->clearPreviewPad(); break;
        case 140: _t->previewPadBeginStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 141: _t->previewPadContinueStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 142: _t->previewPadEndStroke(); break;
        case 143: { QString _r = _t->getPreviewPadImage();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 144: { QString _r = _t->getStampPreview();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 145: _t->setCurvePoints((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushSizeChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushColorChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushOpacityChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushFlowChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushHardnessChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushSpacingChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushStabilizationChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushStreamlineChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushGrainChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushWetnessChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushSmudgeChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::impastoShininessChanged, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::impastoSettingsChanged, 12))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushRoundnessChanged, 13))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::zoomLevelChanged, 14))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentToolChanged, 15))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::canvasWidthChanged, 16))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::canvasHeightChanged, 17))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::viewOffsetChanged, 18))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::activeLayerChanged, 19))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isTransformingChanged, 20))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::transformModeChanged, 21))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushAngleChanged, 22))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::cursorRotationChanged, 23))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentProjectPathChanged, 24))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentProjectNameChanged, 25))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushTipChanged, 26))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(float , float )>(_a, &CanvasItem::cursorPosChanged, 27))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::projectsLoaded, 28))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(bool )>(_a, &CanvasItem::isEraserChanged, 29))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::layersChanged, 30))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::availableBrushesChanged, 31))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::activeBrushNameChanged, 32))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushTipImageChanged, 33))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedHChanged, 34))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedVChanged, 35))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::hasSelectionChanged, 36))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::selectionAddModeChanged, 37))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::selectionThresholdChanged, 38))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isSelectionModeActiveChanged, 39))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::projectListChanged, 40))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushCategoriesChanged, 41))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isImportingChanged, 42))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::importProgressChanged, 43))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::sizeByPressureChanged, 44))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::opacityByPressureChanged, 45))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::flowByPressureChanged, 46))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::pressureCurvePointsChanged, 47))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QColor & )>(_a, &CanvasItem::strokeStarted, 48))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QString & , const QString & )>(_a, &CanvasItem::notificationRequested, 49))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::transformBoxChanged, 50))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isEditingBrushChanged, 51))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::editingPresetChanged, 52))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QString & , const QString & )>(_a, &CanvasItem::brushPropertyChanged, 53))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::previewPadUpdated, 54))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(int )>(_a, &CanvasItem::requestToolIdx, 55))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->brushSize(); break;
        case 1: *reinterpret_cast<QColor*>(_v) = _t->brushColor(); break;
        case 2: *reinterpret_cast<float*>(_v) = _t->brushOpacity(); break;
        case 3: *reinterpret_cast<float*>(_v) = _t->brushFlow(); break;
        case 4: *reinterpret_cast<float*>(_v) = _t->brushHardness(); break;
        case 5: *reinterpret_cast<float*>(_v) = _t->brushSpacing(); break;
        case 6: *reinterpret_cast<float*>(_v) = _t->brushStabilization(); break;
        case 7: *reinterpret_cast<float*>(_v) = _t->brushStreamline(); break;
        case 8: *reinterpret_cast<float*>(_v) = _t->brushGrain(); break;
        case 9: *reinterpret_cast<float*>(_v) = _t->brushWetness(); break;
        case 10: *reinterpret_cast<float*>(_v) = _t->brushSmudge(); break;
        case 11: *reinterpret_cast<float*>(_v) = _t->impastoShininess(); break;
        case 12: *reinterpret_cast<float*>(_v) = _t->impastoStrength(); break;
        case 13: *reinterpret_cast<float*>(_v) = _t->lightAngle(); break;
        case 14: *reinterpret_cast<float*>(_v) = _t->lightElevation(); break;
        case 15: *reinterpret_cast<float*>(_v) = _t->brushRoundness(); break;
        case 16: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 17: *reinterpret_cast<QVariantList*>(_v) = _t->layerModel(); break;
        case 18: *reinterpret_cast<QString*>(_v) = _t->currentTool(); break;
        case 19: *reinterpret_cast<int*>(_v) = _t->canvasWidth(); break;
        case 20: *reinterpret_cast<int*>(_v) = _t->canvasHeight(); break;
        case 21: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 22: *reinterpret_cast<int*>(_v) = _t->activeLayerIndex(); break;
        case 23: *reinterpret_cast<bool*>(_v) = _t->isTransforming(); break;
        case 24: *reinterpret_cast<float*>(_v) = _t->brushAngle(); break;
        case 25: *reinterpret_cast<float*>(_v) = _t->cursorRotation(); break;
        case 26: *reinterpret_cast<QString*>(_v) = _t->currentProjectPath(); break;
        case 27: *reinterpret_cast<QString*>(_v) = _t->currentProjectName(); break;
        case 28: *reinterpret_cast<QString*>(_v) = _t->brushTip(); break;
        case 29: *reinterpret_cast<bool*>(_v) = _t->isEraser(); break;
        case 30: *reinterpret_cast<bool*>(_v) = _t->isFlippedH(); break;
        case 31: *reinterpret_cast<bool*>(_v) = _t->isFlippedV(); break;
        case 32: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 33: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 34: *reinterpret_cast<QRectF*>(_v) = _t->transformBox(); break;
        case 35: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurvePoints(); break;
        case 36: *reinterpret_cast<QVariantList*>(_v) = _t->availableBrushes(); break;
        case 37: *reinterpret_cast<QString*>(_v) = _t->activeBrushName(); break;
        case 38: *reinterpret_cast<QString*>(_v) = _t->brushTipImage(); break;
        case 39: *reinterpret_cast<QVariantList*>(_v) = _t->getBrushCategories(); break;
        case 40: *reinterpret_cast<bool*>(_v) = _t->isEditingBrush(); break;
        case 41: *reinterpret_cast<bool*>(_v) = _t->hasSelection(); break;
        case 42: *reinterpret_cast<int*>(_v) = _t->selectionAddMode(); break;
        case 43: *reinterpret_cast<float*>(_v) = _t->selectionThreshold(); break;
        case 44: *reinterpret_cast<bool*>(_v) = _t->isSelectionModeActive(); break;
        case 45: *reinterpret_cast<bool*>(_v) = _t->isImporting(); break;
        case 46: *reinterpret_cast<float*>(_v) = _t->importProgress(); break;
        case 47: *reinterpret_cast<int*>(_v) = _t->transformMode(); break;
        case 48: *reinterpret_cast<bool*>(_v) = _t->sizeByPressure(); break;
        case 49: *reinterpret_cast<bool*>(_v) = _t->opacityByPressure(); break;
        case 50: *reinterpret_cast<bool*>(_v) = _t->flowByPressure(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setBrushSize(*reinterpret_cast<int*>(_v)); break;
        case 1: _t->setBrushColor(*reinterpret_cast<QColor*>(_v)); break;
        case 2: _t->setBrushOpacity(*reinterpret_cast<float*>(_v)); break;
        case 3: _t->setBrushFlow(*reinterpret_cast<float*>(_v)); break;
        case 4: _t->setBrushHardness(*reinterpret_cast<float*>(_v)); break;
        case 5: _t->setBrushSpacing(*reinterpret_cast<float*>(_v)); break;
        case 6: _t->setBrushStabilization(*reinterpret_cast<float*>(_v)); break;
        case 7: _t->setBrushStreamline(*reinterpret_cast<float*>(_v)); break;
        case 8: _t->setBrushGrain(*reinterpret_cast<float*>(_v)); break;
        case 9: _t->setBrushWetness(*reinterpret_cast<float*>(_v)); break;
        case 10: _t->setBrushSmudge(*reinterpret_cast<float*>(_v)); break;
        case 11: _t->setImpastoShininess(*reinterpret_cast<float*>(_v)); break;
        case 12: _t->setImpastoStrength(*reinterpret_cast<float*>(_v)); break;
        case 13: _t->setLightAngle(*reinterpret_cast<float*>(_v)); break;
        case 14: _t->setLightElevation(*reinterpret_cast<float*>(_v)); break;
        case 15: _t->setBrushRoundness(*reinterpret_cast<float*>(_v)); break;
        case 16: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 18: _t->setCurrentTool(*reinterpret_cast<QString*>(_v)); break;
        case 24: _t->setBrushAngle(*reinterpret_cast<float*>(_v)); break;
        case 25: _t->setCursorRotation(*reinterpret_cast<float*>(_v)); break;
        case 29: _t->setIsEraser(*reinterpret_cast<bool*>(_v)); break;
        case 30: _t->setIsFlippedH(*reinterpret_cast<bool*>(_v)); break;
        case 31: _t->setIsFlippedV(*reinterpret_cast<bool*>(_v)); break;
        case 32: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 33: _t->setViewOffset(*reinterpret_cast<QPointF*>(_v)); break;
        case 35: _t->setCurvePoints(*reinterpret_cast<QVariantList*>(_v)); break;
        case 42: _t->setSelectionAddMode(*reinterpret_cast<int*>(_v)); break;
        case 43: _t->setSelectionThreshold(*reinterpret_cast<float*>(_v)); break;
        case 44: _t->setIsSelectionModeActive(*reinterpret_cast<bool*>(_v)); break;
        case 47: _t->setTransformMode(*reinterpret_cast<int*>(_v)); break;
        case 48: _t->setSizeByPressure(*reinterpret_cast<bool*>(_v)); break;
        case 49: _t->setOpacityByPressure(*reinterpret_cast<bool*>(_v)); break;
        case 50: _t->setFlowByPressure(*reinterpret_cast<bool*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *CanvasItem::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *CanvasItem::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10CanvasItemE_t>.strings))
        return static_cast<void*>(this);
    return QQuickPaintedItem::qt_metacast(_clname);
}

int CanvasItem::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QQuickPaintedItem::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 146)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 146;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 146)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 146;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 51;
    }
    return _id;
}

// SIGNAL 0
void CanvasItem::brushSizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void CanvasItem::brushColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void CanvasItem::brushOpacityChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void CanvasItem::brushFlowChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void CanvasItem::brushHardnessChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void CanvasItem::brushSpacingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void CanvasItem::brushStabilizationChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void CanvasItem::brushStreamlineChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void CanvasItem::brushGrainChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void CanvasItem::brushWetnessChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void CanvasItem::brushSmudgeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void CanvasItem::impastoShininessChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void CanvasItem::impastoSettingsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void CanvasItem::brushRoundnessChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}

// SIGNAL 14
void CanvasItem::zoomLevelChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 14, nullptr);
}

// SIGNAL 15
void CanvasItem::currentToolChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 15, nullptr);
}

// SIGNAL 16
void CanvasItem::canvasWidthChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 16, nullptr);
}

// SIGNAL 17
void CanvasItem::canvasHeightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 17, nullptr);
}

// SIGNAL 18
void CanvasItem::viewOffsetChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 18, nullptr);
}

// SIGNAL 19
void CanvasItem::activeLayerChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 19, nullptr);
}

// SIGNAL 20
void CanvasItem::isTransformingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 20, nullptr);
}

// SIGNAL 21
void CanvasItem::transformModeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 21, nullptr);
}

// SIGNAL 22
void CanvasItem::brushAngleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 22, nullptr);
}

// SIGNAL 23
void CanvasItem::cursorRotationChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 23, nullptr);
}

// SIGNAL 24
void CanvasItem::currentProjectPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 24, nullptr);
}

// SIGNAL 25
void CanvasItem::currentProjectNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 25, nullptr);
}

// SIGNAL 26
void CanvasItem::brushTipChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 26, nullptr);
}

// SIGNAL 27
void CanvasItem::cursorPosChanged(float _t1, float _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 27, nullptr, _t1, _t2);
}

// SIGNAL 28
void CanvasItem::projectsLoaded(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 28, nullptr, _t1);
}

// SIGNAL 29
void CanvasItem::isEraserChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 29, nullptr, _t1);
}

// SIGNAL 30
void CanvasItem::layersChanged(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 30, nullptr, _t1);
}

// SIGNAL 31
void CanvasItem::availableBrushesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 31, nullptr);
}

// SIGNAL 32
void CanvasItem::activeBrushNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 32, nullptr);
}

// SIGNAL 33
void CanvasItem::brushTipImageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 33, nullptr);
}

// SIGNAL 34
void CanvasItem::isFlippedHChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 34, nullptr);
}

// SIGNAL 35
void CanvasItem::isFlippedVChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 35, nullptr);
}

// SIGNAL 36
void CanvasItem::hasSelectionChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 36, nullptr);
}

// SIGNAL 37
void CanvasItem::selectionAddModeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 37, nullptr);
}

// SIGNAL 38
void CanvasItem::selectionThresholdChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 38, nullptr);
}

// SIGNAL 39
void CanvasItem::isSelectionModeActiveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 39, nullptr);
}

// SIGNAL 40
void CanvasItem::projectListChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 40, nullptr);
}

// SIGNAL 41
void CanvasItem::brushCategoriesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 41, nullptr);
}

// SIGNAL 42
void CanvasItem::isImportingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 42, nullptr);
}

// SIGNAL 43
void CanvasItem::importProgressChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 43, nullptr);
}

// SIGNAL 44
void CanvasItem::sizeByPressureChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 44, nullptr);
}

// SIGNAL 45
void CanvasItem::opacityByPressureChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 45, nullptr);
}

// SIGNAL 46
void CanvasItem::flowByPressureChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 46, nullptr);
}

// SIGNAL 47
void CanvasItem::pressureCurvePointsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 47, nullptr);
}

// SIGNAL 48
void CanvasItem::strokeStarted(const QColor & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 48, nullptr, _t1);
}

// SIGNAL 49
void CanvasItem::notificationRequested(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 49, nullptr, _t1, _t2);
}

// SIGNAL 50
void CanvasItem::transformBoxChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 50, nullptr);
}

// SIGNAL 51
void CanvasItem::isEditingBrushChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 51, nullptr);
}

// SIGNAL 52
void CanvasItem::editingPresetChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 52, nullptr);
}

// SIGNAL 53
void CanvasItem::brushPropertyChanged(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 53, nullptr, _t1, _t2);
}

// SIGNAL 54
void CanvasItem::previewPadUpdated()
{
    QMetaObject::activate(this, &staticMetaObject, 54, nullptr);
}

// SIGNAL 55
void CanvasItem::requestToolIdx(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 55, nullptr, _t1);
}
QT_WARNING_POP
