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
        "symmetryEnabledChanged",
        "symmetryModeChanged",
        "symmetrySegmentsChanged",
        "isLiquifyingChanged",
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
        "beginLiquify",
        "applyLiquify",
        "cancelLiquify",
        "setLiquifyMode",
        "mode",
        "setLiquifyRadius",
        "radius",
        "setLiquifyStrength",
        "strength",
        "setLiquifyMorpher",
        "morpher",
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
        "adjustBrushSize",
        "deltaPercent",
        "adjustBrushOpacity",
        "isLayerClipped",
        "toggleClipping",
        "toggleAlphaLock",
        "toggleVisibility",
        "setLayerVisibility",
        "visible",
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
        "moveLayerToGroup",
        "layerId",
        "groupId",
        "toggleGroupExpanded",
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
        "createNewBrush",
        "deleteBrush",
        "duplicateBrush",
        "renameBrush",
        "oldName",
        "isBuiltInBrush",
        "getAvailableTipTextures",
        "setTipTextureForBrush",
        "texturePath",
        "setGrainTextureForBrush",
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
        "symmetryEnabled",
        "symmetryMode",
        "symmetrySegments",
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
        "isLiquifying",
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
        "Liquify",
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
        // Signal 'symmetryEnabledChanged'
        QtMocHelpers::SignalData<void()>(55, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'symmetryModeChanged'
        QtMocHelpers::SignalData<void()>(56, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'symmetrySegmentsChanged'
        QtMocHelpers::SignalData<void()>(57, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isLiquifyingChanged'
        QtMocHelpers::SignalData<void()>(58, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurvePointsChanged'
        QtMocHelpers::SignalData<void()>(59, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'strokeStarted'
        QtMocHelpers::SignalData<void(const QColor &)>(60, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 61, 62 },
        }}),
        // Signal 'notificationRequested'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(63, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 64 }, { QMetaType::QString, 65 },
        }}),
        // Signal 'transformBoxChanged'
        QtMocHelpers::SignalData<void()>(66, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isEditingBrushChanged'
        QtMocHelpers::SignalData<void()>(67, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'editingPresetChanged'
        QtMocHelpers::SignalData<void()>(68, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushPropertyChanged'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(69, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 70 }, { QMetaType::QString, 71 },
        }}),
        // Signal 'previewPadUpdated'
        QtMocHelpers::SignalData<void()>(72, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'requestToolIdx'
        QtMocHelpers::SignalData<void(int)>(73, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'applyTransform'
        QtMocHelpers::MethodData<void()>(75, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'cancelTransform'
        QtMocHelpers::MethodData<void()>(76, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'setBackgroundColor'
        QtMocHelpers::MethodData<void(const QString &)>(77, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 62 },
        }}),
        // Method 'setUseCustomCursor'
        QtMocHelpers::MethodData<void(bool)>(78, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 79 },
        }}),
        // Method 'flattenComicPanels'
        QtMocHelpers::MethodData<void(const QVariantList &)>(80, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 81 },
        }}),
        // Method 'usePreset'
        QtMocHelpers::MethodData<void(const QString &)>(82, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 83 },
        }}),
        // Method 'beginLiquify'
        QtMocHelpers::MethodData<void()>(84, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'applyLiquify'
        QtMocHelpers::MethodData<void()>(85, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'cancelLiquify'
        QtMocHelpers::MethodData<void()>(86, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'setLiquifyMode'
        QtMocHelpers::MethodData<void(int)>(87, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 88 },
        }}),
        // Method 'setLiquifyRadius'
        QtMocHelpers::MethodData<void(float)>(89, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 90 },
        }}),
        // Method 'setLiquifyStrength'
        QtMocHelpers::MethodData<void(float)>(91, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 92 },
        }}),
        // Method 'setLiquifyMorpher'
        QtMocHelpers::MethodData<void(float)>(93, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 94 },
        }}),
        // Method 'loadProject'
        QtMocHelpers::MethodData<bool(const QString &)>(95, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'saveProject'
        QtMocHelpers::MethodData<bool(const QString &)>(97, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'saveProjectAs'
        QtMocHelpers::MethodData<bool(const QString &)>(98, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'exportImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(99, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 }, { QMetaType::QString, 100 },
        }}),
        // Method 'importABR'
        QtMocHelpers::MethodData<bool(const QString &)>(101, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'updateTransformProperties'
        QtMocHelpers::MethodData<void(float, float, float, float, float, float)>(102, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 }, { QMetaType::Float, 103 }, { QMetaType::Float, 104 },
            { QMetaType::Float, 105 }, { QMetaType::Float, 106 },
        }}),
        // Method 'updateTransformCorners'
        QtMocHelpers::MethodData<void(const QVariantList &)>(107, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 108 },
        }}),
        // Method 'resizeCanvas'
        QtMocHelpers::MethodData<void(int, int)>(109, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 105 }, { QMetaType::Int, 106 },
        }}),
        // Method 'setProjectDpi'
        QtMocHelpers::MethodData<void(int)>(110, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 111 },
        }}),
        // Method 'drawPanelLayout'
        QtMocHelpers::MethodData<void(const QString &, int, int, int)>(112, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 113 }, { QMetaType::Int, 114 }, { QMetaType::Int, 115 }, { QMetaType::Int, 116 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int, int)>(117, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Int, 30 }, { QMetaType::Int, 31 }, { QMetaType::Int, 88 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int)>(117, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::QString, {{
            { QMetaType::Int, 30 }, { QMetaType::Int, 31 },
        }}),
        // Method 'adjustBrushSize'
        QtMocHelpers::MethodData<void(float)>(118, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 119 },
        }}),
        // Method 'adjustBrushOpacity'
        QtMocHelpers::MethodData<void(float)>(120, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 119 },
        }}),
        // Method 'isLayerClipped'
        QtMocHelpers::MethodData<bool(int)>(121, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'toggleClipping'
        QtMocHelpers::MethodData<void(int)>(122, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'toggleAlphaLock'
        QtMocHelpers::MethodData<void(int)>(123, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'toggleVisibility'
        QtMocHelpers::MethodData<void(int)>(124, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'setLayerVisibility'
        QtMocHelpers::MethodData<void(int, bool)>(125, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::Bool, 126 },
        }}),
        // Method 'toggleLock'
        QtMocHelpers::MethodData<void(int)>(127, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'clearLayer'
        QtMocHelpers::MethodData<void(int)>(128, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'setLayerOpacity'
        QtMocHelpers::MethodData<void(int, float)>(129, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::Float, 130 },
        }}),
        // Method 'setLayerOpacityPreview'
        QtMocHelpers::MethodData<void(int, float)>(131, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::Float, 130 },
        }}),
        // Method 'setLayerBlendMode'
        QtMocHelpers::MethodData<void(int, const QString &)>(132, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::QString, 88 },
        }}),
        // Method 'setLayerPrivate'
        QtMocHelpers::MethodData<void(int, bool)>(133, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::Bool, 134 },
        }}),
        // Method 'setActiveLayer'
        QtMocHelpers::MethodData<void(int)>(135, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'invertSelection'
        QtMocHelpers::MethodData<void()>(136, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'featherSelection'
        QtMocHelpers::MethodData<void(float)>(137, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 90 },
        }}),
        // Method 'duplicateSelection'
        QtMocHelpers::MethodData<void()>(138, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'maskSelection'
        QtMocHelpers::MethodData<void()>(139, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'colorSelection'
        QtMocHelpers::MethodData<void(const QColor &)>(140, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 61, 62 },
        }}),
        // Method 'clearSelectionContent'
        QtMocHelpers::MethodData<void()>(141, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'deselect'
        QtMocHelpers::MethodData<void()>(142, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'selectAll'
        QtMocHelpers::MethodData<void()>(143, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'apply_color_drop'
        QtMocHelpers::MethodData<void(int, int, const QColor &)>(144, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 30 }, { QMetaType::Int, 31 }, { 0x80000000 | 61, 62 },
        }}),
        // Method 'hclToHex'
        QtMocHelpers::MethodData<QString(float, float, float)>(145, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Float, 106 }, { QMetaType::Float, 146 }, { QMetaType::Float, 147 },
        }}),
        // Method 'hexToHcl'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(148, 2, QMC::AccessPublic, 0x80000000 | 33, {{
            { QMetaType::QString, 149 },
        }}),
        // Method 'undo'
        QtMocHelpers::MethodData<void()>(150, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'redo'
        QtMocHelpers::MethodData<void()>(151, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'canUndo'
        QtMocHelpers::MethodData<bool() const>(152, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'canRedo'
        QtMocHelpers::MethodData<bool() const>(153, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'loadRecentProjectsAsync'
        QtMocHelpers::MethodData<void()>(154, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getRecentProjects'
        QtMocHelpers::MethodData<QVariantList()>(155, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'create_folder_from_merge'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(156, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 157 }, { QMetaType::QString, 158 },
        }}),
        // Method 'get_project_list'
        QtMocHelpers::MethodData<QVariantList()>(159, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'get_sketchbook_pages'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(160, 2, QMC::AccessPublic, 0x80000000 | 33, {{
            { QMetaType::QString, 161 },
        }}),
        // Method 'create_new_sketchbook'
        QtMocHelpers::MethodData<QString(const QString &, const QString &)>(162, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 83 }, { QMetaType::QString, 163 },
        }}),
        // Method 'create_new_page'
        QtMocHelpers::MethodData<QString(const QString &, const QString &)>(164, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 161 }, { QMetaType::QString, 165 },
        }}),
        // Method 'exportPageImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &, const QString &)>(166, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 167 }, { QMetaType::QString, 168 }, { QMetaType::QString, 100 },
        }}),
        // Method 'exportAllPages'
        QtMocHelpers::MethodData<bool(const QString &, const QString &, const QString &)>(169, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 161 }, { QMetaType::QString, 170 }, { QMetaType::QString, 100 },
        }}),
        // Method 'load_file_path'
        QtMocHelpers::MethodData<void(const QString &)>(171, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'deleteProject'
        QtMocHelpers::MethodData<bool(const QString &)>(172, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'deleteFolder'
        QtMocHelpers::MethodData<bool(const QString &)>(173, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'rename_item'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(174, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 }, { QMetaType::QString, 175 },
        }}),
        // Method 'moveProjectOutOfFolder'
        QtMocHelpers::MethodData<bool(const QString &)>(176, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 96 },
        }}),
        // Method 'handle_shortcuts'
        QtMocHelpers::MethodData<void(int, int)>(177, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 71 }, { QMetaType::Int, 178 },
        }}),
        // Method 'handle_key_release'
        QtMocHelpers::MethodData<void(int)>(179, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 71 },
        }}),
        // Method 'fitToView'
        QtMocHelpers::MethodData<void()>(180, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addLayer'
        QtMocHelpers::MethodData<void()>(181, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addGroup'
        QtMocHelpers::MethodData<void()>(182, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'moveLayerToGroup'
        QtMocHelpers::MethodData<void(int, int)>(183, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 184 }, { QMetaType::Int, 185 },
        }}),
        // Method 'toggleGroupExpanded'
        QtMocHelpers::MethodData<void(int)>(186, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'removeLayer'
        QtMocHelpers::MethodData<void(int)>(187, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'duplicateLayer'
        QtMocHelpers::MethodData<void(int)>(188, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'moveLayer'
        QtMocHelpers::MethodData<void(int, int)>(189, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 190 }, { QMetaType::Int, 191 },
        }}),
        // Method 'mergeDown'
        QtMocHelpers::MethodData<void(int)>(192, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'renameLayer'
        QtMocHelpers::MethodData<void(int, const QString &)>(193, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::QString, 83 },
        }}),
        // Method 'applyEffect'
        QtMocHelpers::MethodData<void(int, const QString &, const QVariantMap &)>(194, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 }, { QMetaType::QString, 195 }, { 0x80000000 | 196, 197 },
        }}),
        // Method 'get_brush_preview'
        QtMocHelpers::MethodData<QString(const QString &)>(198, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 199 },
        }}),
        // Method 'getBrushesForCategory'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(200, 2, QMC::AccessPublic, 0x80000000 | 33, {{
            { QMetaType::QString, 70 },
        }}),
        // Method 'getBrushCategories'
        QtMocHelpers::MethodData<QVariantList()>(201, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'getBrushCategoryNames'
        QtMocHelpers::MethodData<QStringList()>(202, 2, QMC::AccessPublic, QMetaType::QStringList),
        // Method 'beginBrushEdit'
        QtMocHelpers::MethodData<void(const QString &)>(203, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 199 },
        }}),
        // Method 'cancelBrushEdit'
        QtMocHelpers::MethodData<void()>(204, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'applyBrushEdit'
        QtMocHelpers::MethodData<void()>(205, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'saveAsCopyBrush'
        QtMocHelpers::MethodData<void(const QString &)>(206, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 175 },
        }}),
        // Method 'resetBrushToDefault'
        QtMocHelpers::MethodData<void()>(207, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getBrushProperty'
        QtMocHelpers::MethodData<QVariant(const QString &, const QString &)>(208, 2, QMC::AccessPublic, 0x80000000 | 209, {{
            { QMetaType::QString, 70 }, { QMetaType::QString, 71 },
        }}),
        // Method 'setBrushProperty'
        QtMocHelpers::MethodData<void(const QString &, const QString &, const QVariant &)>(210, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 70 }, { QMetaType::QString, 71 }, { 0x80000000 | 209, 211 },
        }}),
        // Method 'getBrushCategoryProperties'
        QtMocHelpers::MethodData<QVariantMap(const QString &)>(212, 2, QMC::AccessPublic, 0x80000000 | 196, {{
            { QMetaType::QString, 70 },
        }}),
        // Method 'clearPreviewPad'
        QtMocHelpers::MethodData<void()>(213, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'previewPadBeginStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(214, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 }, { QMetaType::Float, 215 },
        }}),
        // Method 'previewPadContinueStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(216, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 30 }, { QMetaType::Float, 31 }, { QMetaType::Float, 215 },
        }}),
        // Method 'previewPadEndStroke'
        QtMocHelpers::MethodData<void()>(217, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getPreviewPadImage'
        QtMocHelpers::MethodData<QString()>(218, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'getStampPreview'
        QtMocHelpers::MethodData<QString()>(219, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'createNewBrush'
        QtMocHelpers::MethodData<void(const QString &, const QString &)>(220, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 83 }, { QMetaType::QString, 70 },
        }}),
        // Method 'deleteBrush'
        QtMocHelpers::MethodData<bool(const QString &)>(221, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 83 },
        }}),
        // Method 'duplicateBrush'
        QtMocHelpers::MethodData<QString(const QString &)>(222, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 83 },
        }}),
        // Method 'renameBrush'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(223, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 224 }, { QMetaType::QString, 175 },
        }}),
        // Method 'isBuiltInBrush'
        QtMocHelpers::MethodData<bool(const QString &) const>(225, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 83 },
        }}),
        // Method 'getAvailableTipTextures'
        QtMocHelpers::MethodData<QVariantList() const>(226, 2, QMC::AccessPublic, 0x80000000 | 33),
        // Method 'setTipTextureForBrush'
        QtMocHelpers::MethodData<void(const QString &, const QString &)>(227, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 199 }, { QMetaType::QString, 228 },
        }}),
        // Method 'setGrainTextureForBrush'
        QtMocHelpers::MethodData<void(const QString &, const QString &)>(229, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 199 }, { QMetaType::QString, 228 },
        }}),
        // Method 'setCurvePoints'
        QtMocHelpers::MethodData<void(const QVariantList &)>(230, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 33, 231 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'brushSize'
        QtMocHelpers::PropertyData<int>(232, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'brushColor'
        QtMocHelpers::PropertyData<QColor>(233, 0x80000000 | 61, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'brushOpacity'
        QtMocHelpers::PropertyData<float>(234, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'brushFlow'
        QtMocHelpers::PropertyData<float>(235, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'brushHardness'
        QtMocHelpers::PropertyData<float>(236, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'brushSpacing'
        QtMocHelpers::PropertyData<float>(237, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'brushStabilization'
        QtMocHelpers::PropertyData<float>(238, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'brushStreamline'
        QtMocHelpers::PropertyData<float>(239, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'brushGrain'
        QtMocHelpers::PropertyData<float>(240, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'brushWetness'
        QtMocHelpers::PropertyData<float>(241, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'brushSmudge'
        QtMocHelpers::PropertyData<float>(242, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'impastoShininess'
        QtMocHelpers::PropertyData<float>(243, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'impastoStrength'
        QtMocHelpers::PropertyData<float>(244, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightAngle'
        QtMocHelpers::PropertyData<float>(245, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightElevation'
        QtMocHelpers::PropertyData<float>(246, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'brushRoundness'
        QtMocHelpers::PropertyData<float>(247, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 13),
        // property 'zoomLevel'
        QtMocHelpers::PropertyData<float>(248, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 14),
        // property 'layerModel'
        QtMocHelpers::PropertyData<QVariantList>(249, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 30),
        // property 'currentTool'
        QtMocHelpers::PropertyData<QString>(250, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 15),
        // property 'canvasWidth'
        QtMocHelpers::PropertyData<int>(251, QMetaType::Int, QMC::DefaultPropertyFlags, 16),
        // property 'canvasHeight'
        QtMocHelpers::PropertyData<int>(252, QMetaType::Int, QMC::DefaultPropertyFlags, 17),
        // property 'viewOffset'
        QtMocHelpers::PropertyData<QPointF>(253, 0x80000000 | 254, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 18),
        // property 'activeLayerIndex'
        QtMocHelpers::PropertyData<int>(255, QMetaType::Int, QMC::DefaultPropertyFlags, 19),
        // property 'isTransforming'
        QtMocHelpers::PropertyData<bool>(256, QMetaType::Bool, QMC::DefaultPropertyFlags, 20),
        // property 'brushAngle'
        QtMocHelpers::PropertyData<float>(257, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 22),
        // property 'cursorRotation'
        QtMocHelpers::PropertyData<float>(258, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 23),
        // property 'currentProjectPath'
        QtMocHelpers::PropertyData<QString>(259, QMetaType::QString, QMC::DefaultPropertyFlags, 24),
        // property 'currentProjectName'
        QtMocHelpers::PropertyData<QString>(260, QMetaType::QString, QMC::DefaultPropertyFlags, 25),
        // property 'symmetryEnabled'
        QtMocHelpers::PropertyData<bool>(261, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 47),
        // property 'symmetryMode'
        QtMocHelpers::PropertyData<int>(262, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 48),
        // property 'symmetrySegments'
        QtMocHelpers::PropertyData<int>(263, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 49),
        // property 'brushTip'
        QtMocHelpers::PropertyData<QString>(264, QMetaType::QString, QMC::DefaultPropertyFlags, 26),
        // property 'isEraser'
        QtMocHelpers::PropertyData<bool>(265, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 29),
        // property 'isFlippedH'
        QtMocHelpers::PropertyData<bool>(266, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 34),
        // property 'isFlippedV'
        QtMocHelpers::PropertyData<bool>(267, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 35),
        // property 'canvasScale'
        QtMocHelpers::PropertyData<float>(268, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable, 14),
        // property 'canvasOffset'
        QtMocHelpers::PropertyData<QPointF>(269, 0x80000000 | 254, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 18),
        // property 'transformBox'
        QtMocHelpers::PropertyData<QRectF>(270, 0x80000000 | 271, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 54),
        // property 'pressureCurvePoints'
        QtMocHelpers::PropertyData<QVariantList>(272, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 51),
        // property 'availableBrushes'
        QtMocHelpers::PropertyData<QVariantList>(273, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 31),
        // property 'activeBrushName'
        QtMocHelpers::PropertyData<QString>(274, QMetaType::QString, QMC::DefaultPropertyFlags, 32),
        // property 'brushTipImage'
        QtMocHelpers::PropertyData<QString>(275, QMetaType::QString, QMC::DefaultPropertyFlags, 33),
        // property 'brushCategories'
        QtMocHelpers::PropertyData<QVariantList>(276, 0x80000000 | 33, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 41),
        // property 'isEditingBrush'
        QtMocHelpers::PropertyData<bool>(277, QMetaType::Bool, QMC::DefaultPropertyFlags, 55),
        // property 'hasSelection'
        QtMocHelpers::PropertyData<bool>(278, QMetaType::Bool, QMC::DefaultPropertyFlags, 36),
        // property 'selectionAddMode'
        QtMocHelpers::PropertyData<int>(279, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 37),
        // property 'selectionThreshold'
        QtMocHelpers::PropertyData<float>(280, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 38),
        // property 'isSelectionModeActive'
        QtMocHelpers::PropertyData<bool>(281, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 39),
        // property 'isImporting'
        QtMocHelpers::PropertyData<bool>(282, QMetaType::Bool, QMC::DefaultPropertyFlags, 42),
        // property 'importProgress'
        QtMocHelpers::PropertyData<float>(283, QMetaType::Float, QMC::DefaultPropertyFlags, 43),
        // property 'isLiquifying'
        QtMocHelpers::PropertyData<bool>(284, QMetaType::Bool, QMC::DefaultPropertyFlags, 50),
        // property 'transformMode'
        QtMocHelpers::PropertyData<int>(285, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 21),
        // property 'sizeByPressure'
        QtMocHelpers::PropertyData<bool>(286, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 44),
        // property 'opacityByPressure'
        QtMocHelpers::PropertyData<bool>(287, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 45),
        // property 'flowByPressure'
        QtMocHelpers::PropertyData<bool>(288, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 46),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'ToolType'
        QtMocHelpers::EnumData<enum ToolType>(289, 289, QMC::EnumIsScoped).add({
            {  290, ToolType::Pen },
            {  291, ToolType::Eraser },
            {  292, ToolType::Lasso },
            {  293, ToolType::MagneticLasso },
            {  294, ToolType::RectSelect },
            {  295, ToolType::EllipseSelect },
            {  296, ToolType::MagicWand },
            {  297, ToolType::Transform },
            {  298, ToolType::Eyedropper },
            {  299, ToolType::Hand },
            {  300, ToolType::Fill },
            {  301, ToolType::Shape },
            {  302, ToolType::PanelCut },
            {  303, ToolType::Liquify },
        }),
        // enum 'TransformSubMode'
        QtMocHelpers::EnumData<enum TransformSubMode>(304, 304, QMC::EnumFlags{}).add({
            {  305, TransformSubMode::Free },
            {  306, TransformSubMode::Perspective },
            {  307, TransformSubMode::Warp },
            {  308, TransformSubMode::Mesh },
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
        case 47: _t->symmetryEnabledChanged(); break;
        case 48: _t->symmetryModeChanged(); break;
        case 49: _t->symmetrySegmentsChanged(); break;
        case 50: _t->isLiquifyingChanged(); break;
        case 51: _t->pressureCurvePointsChanged(); break;
        case 52: _t->strokeStarted((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 53: _t->notificationRequested((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 54: _t->transformBoxChanged(); break;
        case 55: _t->isEditingBrushChanged(); break;
        case 56: _t->editingPresetChanged(); break;
        case 57: _t->brushPropertyChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 58: _t->previewPadUpdated(); break;
        case 59: _t->requestToolIdx((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 60: _t->applyTransform(); break;
        case 61: _t->cancelTransform(); break;
        case 62: _t->setBackgroundColor((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 63: _t->setUseCustomCursor((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 64: _t->flattenComicPanels((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 65: _t->usePreset((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 66: _t->beginLiquify(); break;
        case 67: _t->applyLiquify(); break;
        case 68: _t->cancelLiquify(); break;
        case 69: _t->setLiquifyMode((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 70: _t->setLiquifyRadius((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 71: _t->setLiquifyStrength((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 72: _t->setLiquifyMorpher((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 73: { bool _r = _t->loadProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 74: { bool _r = _t->saveProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 75: { bool _r = _t->saveProjectAs((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 76: { bool _r = _t->exportImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 77: { bool _r = _t->importABR((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 78: _t->updateTransformProperties((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[5])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[6]))); break;
        case 79: _t->updateTransformCorners((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 80: _t->resizeCanvas((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 81: _t->setProjectDpi((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 82: _t->drawPanelLayout((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 83: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 84: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 85: _t->adjustBrushSize((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 86: _t->adjustBrushOpacity((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 87: { bool _r = _t->isLayerClipped((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 88: _t->toggleClipping((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 89: _t->toggleAlphaLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 90: _t->toggleVisibility((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 91: _t->setLayerVisibility((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 92: _t->toggleLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 93: _t->clearLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 94: _t->setLayerOpacity((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 95: _t->setLayerOpacityPreview((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 96: _t->setLayerBlendMode((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 97: _t->setLayerPrivate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 98: _t->setActiveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 99: _t->invertSelection(); break;
        case 100: _t->featherSelection((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 101: _t->duplicateSelection(); break;
        case 102: _t->maskSelection(); break;
        case 103: _t->colorSelection((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 104: _t->clearSelectionContent(); break;
        case 105: _t->deselect(); break;
        case 106: _t->selectAll(); break;
        case 107: _t->apply_color_drop((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[3]))); break;
        case 108: { QString _r = _t->hclToHex((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 109: { QVariantList _r = _t->hexToHcl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 110: _t->undo(); break;
        case 111: _t->redo(); break;
        case 112: { bool _r = _t->canUndo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 113: { bool _r = _t->canRedo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 114: _t->loadRecentProjectsAsync(); break;
        case 115: { QVariantList _r = _t->getRecentProjects();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 116: { bool _r = _t->create_folder_from_merge((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 117: { QVariantList _r = _t->get_project_list();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 118: { QVariantList _r = _t->get_sketchbook_pages((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 119: { QString _r = _t->create_new_sketchbook((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 120: { QString _r = _t->create_new_page((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 121: { bool _r = _t->exportPageImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 122: { bool _r = _t->exportAllPages((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 123: _t->load_file_path((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 124: { bool _r = _t->deleteProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 125: { bool _r = _t->deleteFolder((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 126: { bool _r = _t->rename_item((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 127: { bool _r = _t->moveProjectOutOfFolder((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 128: _t->handle_shortcuts((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 129: _t->handle_key_release((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 130: _t->fitToView(); break;
        case 131: _t->addLayer(); break;
        case 132: _t->addGroup(); break;
        case 133: _t->moveLayerToGroup((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 134: _t->toggleGroupExpanded((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 135: _t->removeLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 136: _t->duplicateLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 137: _t->moveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 138: _t->mergeDown((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 139: _t->renameLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 140: _t->applyEffect((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[3]))); break;
        case 141: { QString _r = _t->get_brush_preview((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 142: { QVariantList _r = _t->getBrushesForCategory((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 143: { QVariantList _r = _t->getBrushCategories();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 144: { QStringList _r = _t->getBrushCategoryNames();
            if (_a[0]) *reinterpret_cast<QStringList*>(_a[0]) = std::move(_r); }  break;
        case 145: _t->beginBrushEdit((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 146: _t->cancelBrushEdit(); break;
        case 147: _t->applyBrushEdit(); break;
        case 148: _t->saveAsCopyBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 149: _t->resetBrushToDefault(); break;
        case 150: { QVariant _r = _t->getBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QVariant*>(_a[0]) = std::move(_r); }  break;
        case 151: _t->setBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariant>>(_a[3]))); break;
        case 152: { QVariantMap _r = _t->getBrushCategoryProperties((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 153: _t->clearPreviewPad(); break;
        case 154: _t->previewPadBeginStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 155: _t->previewPadContinueStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 156: _t->previewPadEndStroke(); break;
        case 157: { QString _r = _t->getPreviewPadImage();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 158: { QString _r = _t->getStampPreview();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 159: _t->createNewBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 160: { bool _r = _t->deleteBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 161: { QString _r = _t->duplicateBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 162: { bool _r = _t->renameBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 163: { bool _r = _t->isBuiltInBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 164: { QVariantList _r = _t->getAvailableTipTextures();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 165: _t->setTipTextureForBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 166: _t->setGrainTextureForBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 167: _t->setCurvePoints((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
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
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::symmetryEnabledChanged, 47))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::symmetryModeChanged, 48))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::symmetrySegmentsChanged, 49))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isLiquifyingChanged, 50))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::pressureCurvePointsChanged, 51))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QColor & )>(_a, &CanvasItem::strokeStarted, 52))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QString & , const QString & )>(_a, &CanvasItem::notificationRequested, 53))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::transformBoxChanged, 54))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isEditingBrushChanged, 55))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::editingPresetChanged, 56))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QString & , const QString & )>(_a, &CanvasItem::brushPropertyChanged, 57))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::previewPadUpdated, 58))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(int )>(_a, &CanvasItem::requestToolIdx, 59))
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
        case 28: *reinterpret_cast<bool*>(_v) = _t->symmetryEnabled(); break;
        case 29: *reinterpret_cast<int*>(_v) = _t->symmetryMode(); break;
        case 30: *reinterpret_cast<int*>(_v) = _t->symmetrySegments(); break;
        case 31: *reinterpret_cast<QString*>(_v) = _t->brushTip(); break;
        case 32: *reinterpret_cast<bool*>(_v) = _t->isEraser(); break;
        case 33: *reinterpret_cast<bool*>(_v) = _t->isFlippedH(); break;
        case 34: *reinterpret_cast<bool*>(_v) = _t->isFlippedV(); break;
        case 35: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 36: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 37: *reinterpret_cast<QRectF*>(_v) = _t->transformBox(); break;
        case 38: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurvePoints(); break;
        case 39: *reinterpret_cast<QVariantList*>(_v) = _t->availableBrushes(); break;
        case 40: *reinterpret_cast<QString*>(_v) = _t->activeBrushName(); break;
        case 41: *reinterpret_cast<QString*>(_v) = _t->brushTipImage(); break;
        case 42: *reinterpret_cast<QVariantList*>(_v) = _t->getBrushCategories(); break;
        case 43: *reinterpret_cast<bool*>(_v) = _t->isEditingBrush(); break;
        case 44: *reinterpret_cast<bool*>(_v) = _t->hasSelection(); break;
        case 45: *reinterpret_cast<int*>(_v) = _t->selectionAddMode(); break;
        case 46: *reinterpret_cast<float*>(_v) = _t->selectionThreshold(); break;
        case 47: *reinterpret_cast<bool*>(_v) = _t->isSelectionModeActive(); break;
        case 48: *reinterpret_cast<bool*>(_v) = _t->isImporting(); break;
        case 49: *reinterpret_cast<float*>(_v) = _t->importProgress(); break;
        case 50: *reinterpret_cast<bool*>(_v) = _t->isLiquifying(); break;
        case 51: *reinterpret_cast<int*>(_v) = _t->transformMode(); break;
        case 52: *reinterpret_cast<bool*>(_v) = _t->sizeByPressure(); break;
        case 53: *reinterpret_cast<bool*>(_v) = _t->opacityByPressure(); break;
        case 54: *reinterpret_cast<bool*>(_v) = _t->flowByPressure(); break;
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
        case 28: _t->setSymmetryEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 29: _t->setSymmetryMode(*reinterpret_cast<int*>(_v)); break;
        case 30: _t->setSymmetrySegments(*reinterpret_cast<int*>(_v)); break;
        case 32: _t->setIsEraser(*reinterpret_cast<bool*>(_v)); break;
        case 33: _t->setIsFlippedH(*reinterpret_cast<bool*>(_v)); break;
        case 34: _t->setIsFlippedV(*reinterpret_cast<bool*>(_v)); break;
        case 35: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 36: _t->setViewOffset(*reinterpret_cast<QPointF*>(_v)); break;
        case 38: _t->setCurvePoints(*reinterpret_cast<QVariantList*>(_v)); break;
        case 45: _t->setSelectionAddMode(*reinterpret_cast<int*>(_v)); break;
        case 46: _t->setSelectionThreshold(*reinterpret_cast<float*>(_v)); break;
        case 47: _t->setIsSelectionModeActive(*reinterpret_cast<bool*>(_v)); break;
        case 51: _t->setTransformMode(*reinterpret_cast<int*>(_v)); break;
        case 52: _t->setSizeByPressure(*reinterpret_cast<bool*>(_v)); break;
        case 53: _t->setOpacityByPressure(*reinterpret_cast<bool*>(_v)); break;
        case 54: _t->setFlowByPressure(*reinterpret_cast<bool*>(_v)); break;
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
        if (_id < 168)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 168;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 168)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 168;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 55;
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
void CanvasItem::symmetryEnabledChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 47, nullptr);
}

// SIGNAL 48
void CanvasItem::symmetryModeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 48, nullptr);
}

// SIGNAL 49
void CanvasItem::symmetrySegmentsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 49, nullptr);
}

// SIGNAL 50
void CanvasItem::isLiquifyingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 50, nullptr);
}

// SIGNAL 51
void CanvasItem::pressureCurvePointsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 51, nullptr);
}

// SIGNAL 52
void CanvasItem::strokeStarted(const QColor & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 52, nullptr, _t1);
}

// SIGNAL 53
void CanvasItem::notificationRequested(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 53, nullptr, _t1, _t2);
}

// SIGNAL 54
void CanvasItem::transformBoxChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 54, nullptr);
}

// SIGNAL 55
void CanvasItem::isEditingBrushChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 55, nullptr);
}

// SIGNAL 56
void CanvasItem::editingPresetChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 56, nullptr);
}

// SIGNAL 57
void CanvasItem::brushPropertyChanged(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 57, nullptr, _t1, _t2);
}

// SIGNAL 58
void CanvasItem::previewPadUpdated()
{
    QMetaObject::activate(this, &staticMetaObject, 58, nullptr);
}

// SIGNAL 59
void CanvasItem::requestToolIdx(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 59, nullptr, _t1);
}
QT_WARNING_POP
