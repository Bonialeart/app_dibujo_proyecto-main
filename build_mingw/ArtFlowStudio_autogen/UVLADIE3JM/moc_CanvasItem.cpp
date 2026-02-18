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
        "pressureCurvePointsChanged",
        "strokeStarted",
        "QColor",
        "color",
        "isEditingBrushChanged",
        "editingPresetChanged",
        "brushPropertyChanged",
        "category",
        "key",
        "previewPadUpdated",
        "requestToolIdx",
        "index",
        "setBackgroundColor",
        "setUseCustomCursor",
        "use",
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
        "resizeCanvas",
        "setProjectDpi",
        "dpi",
        "sampleColor",
        "mode",
        "adjustBrushSize",
        "deltaPercent",
        "adjustBrushOpacity",
        "isLayerClipped",
        "toggleClipping",
        "toggleAlphaLock",
        "toggleVisibility",
        "clearLayer",
        "setLayerOpacity",
        "opacity",
        "setLayerBlendMode",
        "setLayerPrivate",
        "isPrivate",
        "setActiveLayer",
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
        "get_project_list",
        "load_file_path",
        "handle_shortcuts",
        "modifiers",
        "handle_key_release",
        "fitToView",
        "addLayer",
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
        "beginBrushEdit",
        "cancelBrushEdit",
        "applyBrushEdit",
        "saveAsCopyBrush",
        "newName",
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
        "pressureCurvePoints",
        "availableBrushes",
        "activeBrushName",
        "brushTipImage",
        "isEditingBrush",
        "ToolType",
        "Pen",
        "Eraser",
        "Lasso",
        "Transform",
        "Eyedropper",
        "Hand",
        "Fill",
        "Shape"
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
        // Signal 'brushAngleChanged'
        QtMocHelpers::SignalData<void()>(23, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cursorRotationChanged'
        QtMocHelpers::SignalData<void()>(24, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentProjectPathChanged'
        QtMocHelpers::SignalData<void()>(25, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentProjectNameChanged'
        QtMocHelpers::SignalData<void()>(26, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushTipChanged'
        QtMocHelpers::SignalData<void()>(27, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cursorPosChanged'
        QtMocHelpers::SignalData<void(float, float)>(28, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 29 }, { QMetaType::Float, 30 },
        }}),
        // Signal 'projectsLoaded'
        QtMocHelpers::SignalData<void(const QVariantList &)>(31, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 32, 33 },
        }}),
        // Signal 'isEraserChanged'
        QtMocHelpers::SignalData<void(bool)>(34, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 35 },
        }}),
        // Signal 'layersChanged'
        QtMocHelpers::SignalData<void(const QVariantList &)>(36, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 32, 37 },
        }}),
        // Signal 'availableBrushesChanged'
        QtMocHelpers::SignalData<void()>(38, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeBrushNameChanged'
        QtMocHelpers::SignalData<void()>(39, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushTipImageChanged'
        QtMocHelpers::SignalData<void()>(40, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedHChanged'
        QtMocHelpers::SignalData<void()>(41, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedVChanged'
        QtMocHelpers::SignalData<void()>(42, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurvePointsChanged'
        QtMocHelpers::SignalData<void()>(43, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'strokeStarted'
        QtMocHelpers::SignalData<void(const QColor &)>(44, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 45, 46 },
        }}),
        // Signal 'isEditingBrushChanged'
        QtMocHelpers::SignalData<void()>(47, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'editingPresetChanged'
        QtMocHelpers::SignalData<void()>(48, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushPropertyChanged'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(49, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 50 }, { QMetaType::QString, 51 },
        }}),
        // Signal 'previewPadUpdated'
        QtMocHelpers::SignalData<void()>(52, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'requestToolIdx'
        QtMocHelpers::SignalData<void(int)>(53, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'setBackgroundColor'
        QtMocHelpers::MethodData<void(const QString &)>(55, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 46 },
        }}),
        // Method 'setUseCustomCursor'
        QtMocHelpers::MethodData<void(bool)>(56, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 57 },
        }}),
        // Method 'usePreset'
        QtMocHelpers::MethodData<void(const QString &)>(58, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 59 },
        }}),
        // Method 'loadProject'
        QtMocHelpers::MethodData<bool(const QString &)>(60, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 61 },
        }}),
        // Method 'saveProject'
        QtMocHelpers::MethodData<bool(const QString &)>(62, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 61 },
        }}),
        // Method 'saveProjectAs'
        QtMocHelpers::MethodData<bool(const QString &)>(63, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 61 },
        }}),
        // Method 'exportImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(64, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 61 }, { QMetaType::QString, 65 },
        }}),
        // Method 'importABR'
        QtMocHelpers::MethodData<bool(const QString &)>(66, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 61 },
        }}),
        // Method 'updateTransformProperties'
        QtMocHelpers::MethodData<void(float, float, float, float, float, float)>(67, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 29 }, { QMetaType::Float, 30 }, { QMetaType::Float, 68 }, { QMetaType::Float, 69 },
            { QMetaType::Float, 70 }, { QMetaType::Float, 71 },
        }}),
        // Method 'resizeCanvas'
        QtMocHelpers::MethodData<void(int, int)>(72, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 }, { QMetaType::Int, 71 },
        }}),
        // Method 'setProjectDpi'
        QtMocHelpers::MethodData<void(int)>(73, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 74 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int, int)>(75, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Int, 29 }, { QMetaType::Int, 30 }, { QMetaType::Int, 76 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int)>(75, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::QString, {{
            { QMetaType::Int, 29 }, { QMetaType::Int, 30 },
        }}),
        // Method 'adjustBrushSize'
        QtMocHelpers::MethodData<void(float)>(77, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 78 },
        }}),
        // Method 'adjustBrushOpacity'
        QtMocHelpers::MethodData<void(float)>(79, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 78 },
        }}),
        // Method 'isLayerClipped'
        QtMocHelpers::MethodData<bool(int)>(80, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'toggleClipping'
        QtMocHelpers::MethodData<void(int)>(81, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'toggleAlphaLock'
        QtMocHelpers::MethodData<void(int)>(82, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'toggleVisibility'
        QtMocHelpers::MethodData<void(int)>(83, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'clearLayer'
        QtMocHelpers::MethodData<void(int)>(84, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'setLayerOpacity'
        QtMocHelpers::MethodData<void(int, float)>(85, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 }, { QMetaType::Float, 86 },
        }}),
        // Method 'setLayerBlendMode'
        QtMocHelpers::MethodData<void(int, const QString &)>(87, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 }, { QMetaType::QString, 76 },
        }}),
        // Method 'setLayerPrivate'
        QtMocHelpers::MethodData<void(int, bool)>(88, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 }, { QMetaType::Bool, 89 },
        }}),
        // Method 'setActiveLayer'
        QtMocHelpers::MethodData<void(int)>(90, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'hclToHex'
        QtMocHelpers::MethodData<QString(float, float, float)>(91, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Float, 71 }, { QMetaType::Float, 92 }, { QMetaType::Float, 93 },
        }}),
        // Method 'hexToHcl'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(94, 2, QMC::AccessPublic, 0x80000000 | 32, {{
            { QMetaType::QString, 95 },
        }}),
        // Method 'undo'
        QtMocHelpers::MethodData<void()>(96, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'redo'
        QtMocHelpers::MethodData<void()>(97, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'canUndo'
        QtMocHelpers::MethodData<bool() const>(98, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'canRedo'
        QtMocHelpers::MethodData<bool() const>(99, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'loadRecentProjectsAsync'
        QtMocHelpers::MethodData<void()>(100, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getRecentProjects'
        QtMocHelpers::MethodData<QVariantList()>(101, 2, QMC::AccessPublic, 0x80000000 | 32),
        // Method 'get_project_list'
        QtMocHelpers::MethodData<QVariantList()>(102, 2, QMC::AccessPublic, 0x80000000 | 32),
        // Method 'load_file_path'
        QtMocHelpers::MethodData<void(const QString &)>(103, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 61 },
        }}),
        // Method 'handle_shortcuts'
        QtMocHelpers::MethodData<void(int, int)>(104, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 51 }, { QMetaType::Int, 105 },
        }}),
        // Method 'handle_key_release'
        QtMocHelpers::MethodData<void(int)>(106, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 51 },
        }}),
        // Method 'fitToView'
        QtMocHelpers::MethodData<void()>(107, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addLayer'
        QtMocHelpers::MethodData<void()>(108, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'removeLayer'
        QtMocHelpers::MethodData<void(int)>(109, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'duplicateLayer'
        QtMocHelpers::MethodData<void(int)>(110, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'moveLayer'
        QtMocHelpers::MethodData<void(int, int)>(111, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 112 }, { QMetaType::Int, 113 },
        }}),
        // Method 'mergeDown'
        QtMocHelpers::MethodData<void(int)>(114, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 },
        }}),
        // Method 'renameLayer'
        QtMocHelpers::MethodData<void(int, const QString &)>(115, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 }, { QMetaType::QString, 59 },
        }}),
        // Method 'applyEffect'
        QtMocHelpers::MethodData<void(int, const QString &, const QVariantMap &)>(116, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 54 }, { QMetaType::QString, 117 }, { 0x80000000 | 118, 119 },
        }}),
        // Method 'get_brush_preview'
        QtMocHelpers::MethodData<QString(const QString &)>(120, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 121 },
        }}),
        // Method 'getBrushesForCategory'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(122, 2, QMC::AccessPublic, 0x80000000 | 32, {{
            { QMetaType::QString, 50 },
        }}),
        // Method 'beginBrushEdit'
        QtMocHelpers::MethodData<void(const QString &)>(123, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 121 },
        }}),
        // Method 'cancelBrushEdit'
        QtMocHelpers::MethodData<void()>(124, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'applyBrushEdit'
        QtMocHelpers::MethodData<void()>(125, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'saveAsCopyBrush'
        QtMocHelpers::MethodData<void(const QString &)>(126, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 127 },
        }}),
        // Method 'resetBrushToDefault'
        QtMocHelpers::MethodData<void()>(128, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getBrushProperty'
        QtMocHelpers::MethodData<QVariant(const QString &, const QString &)>(129, 2, QMC::AccessPublic, 0x80000000 | 130, {{
            { QMetaType::QString, 50 }, { QMetaType::QString, 51 },
        }}),
        // Method 'setBrushProperty'
        QtMocHelpers::MethodData<void(const QString &, const QString &, const QVariant &)>(131, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 50 }, { QMetaType::QString, 51 }, { 0x80000000 | 130, 132 },
        }}),
        // Method 'getBrushCategoryProperties'
        QtMocHelpers::MethodData<QVariantMap(const QString &)>(133, 2, QMC::AccessPublic, 0x80000000 | 118, {{
            { QMetaType::QString, 50 },
        }}),
        // Method 'clearPreviewPad'
        QtMocHelpers::MethodData<void()>(134, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'previewPadBeginStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(135, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 29 }, { QMetaType::Float, 30 }, { QMetaType::Float, 136 },
        }}),
        // Method 'previewPadContinueStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(137, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 29 }, { QMetaType::Float, 30 }, { QMetaType::Float, 136 },
        }}),
        // Method 'previewPadEndStroke'
        QtMocHelpers::MethodData<void()>(138, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getPreviewPadImage'
        QtMocHelpers::MethodData<QString()>(139, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'getStampPreview'
        QtMocHelpers::MethodData<QString()>(140, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'setCurvePoints'
        QtMocHelpers::MethodData<void(const QVariantList &)>(141, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 32, 142 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'brushSize'
        QtMocHelpers::PropertyData<int>(143, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'brushColor'
        QtMocHelpers::PropertyData<QColor>(144, 0x80000000 | 45, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'brushOpacity'
        QtMocHelpers::PropertyData<float>(145, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'brushFlow'
        QtMocHelpers::PropertyData<float>(146, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'brushHardness'
        QtMocHelpers::PropertyData<float>(147, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'brushSpacing'
        QtMocHelpers::PropertyData<float>(148, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'brushStabilization'
        QtMocHelpers::PropertyData<float>(149, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'brushStreamline'
        QtMocHelpers::PropertyData<float>(150, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'brushGrain'
        QtMocHelpers::PropertyData<float>(151, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'brushWetness'
        QtMocHelpers::PropertyData<float>(152, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'brushSmudge'
        QtMocHelpers::PropertyData<float>(153, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'impastoShininess'
        QtMocHelpers::PropertyData<float>(154, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'impastoStrength'
        QtMocHelpers::PropertyData<float>(155, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightAngle'
        QtMocHelpers::PropertyData<float>(156, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightElevation'
        QtMocHelpers::PropertyData<float>(157, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'brushRoundness'
        QtMocHelpers::PropertyData<float>(158, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 13),
        // property 'zoomLevel'
        QtMocHelpers::PropertyData<float>(159, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 14),
        // property 'currentTool'
        QtMocHelpers::PropertyData<QString>(160, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 15),
        // property 'canvasWidth'
        QtMocHelpers::PropertyData<int>(161, QMetaType::Int, QMC::DefaultPropertyFlags, 16),
        // property 'canvasHeight'
        QtMocHelpers::PropertyData<int>(162, QMetaType::Int, QMC::DefaultPropertyFlags, 17),
        // property 'viewOffset'
        QtMocHelpers::PropertyData<QPointF>(163, 0x80000000 | 164, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 18),
        // property 'activeLayerIndex'
        QtMocHelpers::PropertyData<int>(165, QMetaType::Int, QMC::DefaultPropertyFlags, 19),
        // property 'isTransforming'
        QtMocHelpers::PropertyData<bool>(166, QMetaType::Bool, QMC::DefaultPropertyFlags, 20),
        // property 'brushAngle'
        QtMocHelpers::PropertyData<float>(167, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 21),
        // property 'cursorRotation'
        QtMocHelpers::PropertyData<float>(168, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 22),
        // property 'currentProjectPath'
        QtMocHelpers::PropertyData<QString>(169, QMetaType::QString, QMC::DefaultPropertyFlags, 23),
        // property 'currentProjectName'
        QtMocHelpers::PropertyData<QString>(170, QMetaType::QString, QMC::DefaultPropertyFlags, 24),
        // property 'brushTip'
        QtMocHelpers::PropertyData<QString>(171, QMetaType::QString, QMC::DefaultPropertyFlags, 25),
        // property 'isEraser'
        QtMocHelpers::PropertyData<bool>(172, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 28),
        // property 'isFlippedH'
        QtMocHelpers::PropertyData<bool>(173, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 33),
        // property 'isFlippedV'
        QtMocHelpers::PropertyData<bool>(174, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 34),
        // property 'canvasScale'
        QtMocHelpers::PropertyData<float>(175, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable, 14),
        // property 'canvasOffset'
        QtMocHelpers::PropertyData<QPointF>(176, 0x80000000 | 164, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 18),
        // property 'pressureCurvePoints'
        QtMocHelpers::PropertyData<QVariantList>(177, 0x80000000 | 32, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 35),
        // property 'availableBrushes'
        QtMocHelpers::PropertyData<QVariantList>(178, 0x80000000 | 32, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 30),
        // property 'activeBrushName'
        QtMocHelpers::PropertyData<QString>(179, QMetaType::QString, QMC::DefaultPropertyFlags, 31),
        // property 'brushTipImage'
        QtMocHelpers::PropertyData<QString>(180, QMetaType::QString, QMC::DefaultPropertyFlags, 32),
        // property 'isEditingBrush'
        QtMocHelpers::PropertyData<bool>(181, QMetaType::Bool, QMC::DefaultPropertyFlags, 37),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'ToolType'
        QtMocHelpers::EnumData<enum ToolType>(182, 182, QMC::EnumIsScoped).add({
            {  183, ToolType::Pen },
            {  184, ToolType::Eraser },
            {  185, ToolType::Lasso },
            {  186, ToolType::Transform },
            {  187, ToolType::Eyedropper },
            {  188, ToolType::Hand },
            {  189, ToolType::Fill },
            {  190, ToolType::Shape },
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
        case 21: _t->brushAngleChanged(); break;
        case 22: _t->cursorRotationChanged(); break;
        case 23: _t->currentProjectPathChanged(); break;
        case 24: _t->currentProjectNameChanged(); break;
        case 25: _t->brushTipChanged(); break;
        case 26: _t->cursorPosChanged((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 27: _t->projectsLoaded((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 28: _t->isEraserChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 29: _t->layersChanged((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 30: _t->availableBrushesChanged(); break;
        case 31: _t->activeBrushNameChanged(); break;
        case 32: _t->brushTipImageChanged(); break;
        case 33: _t->isFlippedHChanged(); break;
        case 34: _t->isFlippedVChanged(); break;
        case 35: _t->pressureCurvePointsChanged(); break;
        case 36: _t->strokeStarted((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 37: _t->isEditingBrushChanged(); break;
        case 38: _t->editingPresetChanged(); break;
        case 39: _t->brushPropertyChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 40: _t->previewPadUpdated(); break;
        case 41: _t->requestToolIdx((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 42: _t->setBackgroundColor((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 43: _t->setUseCustomCursor((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 44: _t->usePreset((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 45: { bool _r = _t->loadProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 46: { bool _r = _t->saveProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 47: { bool _r = _t->saveProjectAs((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 48: { bool _r = _t->exportImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 49: { bool _r = _t->importABR((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 50: _t->updateTransformProperties((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[5])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[6]))); break;
        case 51: _t->resizeCanvas((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 52: _t->setProjectDpi((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 53: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 54: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 55: _t->adjustBrushSize((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 56: _t->adjustBrushOpacity((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 57: { bool _r = _t->isLayerClipped((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 58: _t->toggleClipping((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 59: _t->toggleAlphaLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 60: _t->toggleVisibility((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 61: _t->clearLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 62: _t->setLayerOpacity((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 63: _t->setLayerBlendMode((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 64: _t->setLayerPrivate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 65: _t->setActiveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 66: { QString _r = _t->hclToHex((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 67: { QVariantList _r = _t->hexToHcl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 68: _t->undo(); break;
        case 69: _t->redo(); break;
        case 70: { bool _r = _t->canUndo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 71: { bool _r = _t->canRedo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 72: _t->loadRecentProjectsAsync(); break;
        case 73: { QVariantList _r = _t->getRecentProjects();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 74: { QVariantList _r = _t->get_project_list();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 75: _t->load_file_path((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 76: _t->handle_shortcuts((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 77: _t->handle_key_release((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 78: _t->fitToView(); break;
        case 79: _t->addLayer(); break;
        case 80: _t->removeLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 81: _t->duplicateLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 82: _t->moveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 83: _t->mergeDown((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 84: _t->renameLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 85: _t->applyEffect((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[3]))); break;
        case 86: { QString _r = _t->get_brush_preview((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 87: { QVariantList _r = _t->getBrushesForCategory((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 88: _t->beginBrushEdit((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 89: _t->cancelBrushEdit(); break;
        case 90: _t->applyBrushEdit(); break;
        case 91: _t->saveAsCopyBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 92: _t->resetBrushToDefault(); break;
        case 93: { QVariant _r = _t->getBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QVariant*>(_a[0]) = std::move(_r); }  break;
        case 94: _t->setBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariant>>(_a[3]))); break;
        case 95: { QVariantMap _r = _t->getBrushCategoryProperties((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 96: _t->clearPreviewPad(); break;
        case 97: _t->previewPadBeginStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 98: _t->previewPadContinueStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 99: _t->previewPadEndStroke(); break;
        case 100: { QString _r = _t->getPreviewPadImage();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 101: { QString _r = _t->getStampPreview();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 102: _t->setCurvePoints((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
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
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushAngleChanged, 21))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::cursorRotationChanged, 22))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentProjectPathChanged, 23))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentProjectNameChanged, 24))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushTipChanged, 25))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(float , float )>(_a, &CanvasItem::cursorPosChanged, 26))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::projectsLoaded, 27))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(bool )>(_a, &CanvasItem::isEraserChanged, 28))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::layersChanged, 29))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::availableBrushesChanged, 30))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::activeBrushNameChanged, 31))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushTipImageChanged, 32))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedHChanged, 33))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedVChanged, 34))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::pressureCurvePointsChanged, 35))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QColor & )>(_a, &CanvasItem::strokeStarted, 36))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isEditingBrushChanged, 37))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::editingPresetChanged, 38))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QString & , const QString & )>(_a, &CanvasItem::brushPropertyChanged, 39))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::previewPadUpdated, 40))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(int )>(_a, &CanvasItem::requestToolIdx, 41))
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
        case 17: *reinterpret_cast<QString*>(_v) = _t->currentTool(); break;
        case 18: *reinterpret_cast<int*>(_v) = _t->canvasWidth(); break;
        case 19: *reinterpret_cast<int*>(_v) = _t->canvasHeight(); break;
        case 20: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 21: *reinterpret_cast<int*>(_v) = _t->activeLayerIndex(); break;
        case 22: *reinterpret_cast<bool*>(_v) = _t->isTransforming(); break;
        case 23: *reinterpret_cast<float*>(_v) = _t->brushAngle(); break;
        case 24: *reinterpret_cast<float*>(_v) = _t->cursorRotation(); break;
        case 25: *reinterpret_cast<QString*>(_v) = _t->currentProjectPath(); break;
        case 26: *reinterpret_cast<QString*>(_v) = _t->currentProjectName(); break;
        case 27: *reinterpret_cast<QString*>(_v) = _t->brushTip(); break;
        case 28: *reinterpret_cast<bool*>(_v) = _t->isEraser(); break;
        case 29: *reinterpret_cast<bool*>(_v) = _t->isFlippedH(); break;
        case 30: *reinterpret_cast<bool*>(_v) = _t->isFlippedV(); break;
        case 31: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 32: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 33: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurvePoints(); break;
        case 34: *reinterpret_cast<QVariantList*>(_v) = _t->availableBrushes(); break;
        case 35: *reinterpret_cast<QString*>(_v) = _t->activeBrushName(); break;
        case 36: *reinterpret_cast<QString*>(_v) = _t->brushTipImage(); break;
        case 37: *reinterpret_cast<bool*>(_v) = _t->isEditingBrush(); break;
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
        case 17: _t->setCurrentTool(*reinterpret_cast<QString*>(_v)); break;
        case 23: _t->setBrushAngle(*reinterpret_cast<float*>(_v)); break;
        case 24: _t->setCursorRotation(*reinterpret_cast<float*>(_v)); break;
        case 28: _t->setIsEraser(*reinterpret_cast<bool*>(_v)); break;
        case 29: _t->setIsFlippedH(*reinterpret_cast<bool*>(_v)); break;
        case 30: _t->setIsFlippedV(*reinterpret_cast<bool*>(_v)); break;
        case 31: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 32: _t->setViewOffset(*reinterpret_cast<QPointF*>(_v)); break;
        case 33: _t->setCurvePoints(*reinterpret_cast<QVariantList*>(_v)); break;
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
        if (_id < 103)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 103;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 103)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 103;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 38;
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
void CanvasItem::brushAngleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 21, nullptr);
}

// SIGNAL 22
void CanvasItem::cursorRotationChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 22, nullptr);
}

// SIGNAL 23
void CanvasItem::currentProjectPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 23, nullptr);
}

// SIGNAL 24
void CanvasItem::currentProjectNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 24, nullptr);
}

// SIGNAL 25
void CanvasItem::brushTipChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 25, nullptr);
}

// SIGNAL 26
void CanvasItem::cursorPosChanged(float _t1, float _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 26, nullptr, _t1, _t2);
}

// SIGNAL 27
void CanvasItem::projectsLoaded(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 27, nullptr, _t1);
}

// SIGNAL 28
void CanvasItem::isEraserChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 28, nullptr, _t1);
}

// SIGNAL 29
void CanvasItem::layersChanged(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 29, nullptr, _t1);
}

// SIGNAL 30
void CanvasItem::availableBrushesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 30, nullptr);
}

// SIGNAL 31
void CanvasItem::activeBrushNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 31, nullptr);
}

// SIGNAL 32
void CanvasItem::brushTipImageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 32, nullptr);
}

// SIGNAL 33
void CanvasItem::isFlippedHChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 33, nullptr);
}

// SIGNAL 34
void CanvasItem::isFlippedVChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 34, nullptr);
}

// SIGNAL 35
void CanvasItem::pressureCurvePointsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 35, nullptr);
}

// SIGNAL 36
void CanvasItem::strokeStarted(const QColor & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 36, nullptr, _t1);
}

// SIGNAL 37
void CanvasItem::isEditingBrushChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 37, nullptr);
}

// SIGNAL 38
void CanvasItem::editingPresetChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 38, nullptr);
}

// SIGNAL 39
void CanvasItem::brushPropertyChanged(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 39, nullptr, _t1, _t2);
}

// SIGNAL 40
void CanvasItem::previewPadUpdated()
{
    QMetaObject::activate(this, &staticMetaObject, 40, nullptr);
}

// SIGNAL 41
void CanvasItem::requestToolIdx(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 41, nullptr, _t1);
}
QT_WARNING_POP
