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
        // Signal 'zoomLevelChanged'
        QtMocHelpers::SignalData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentToolChanged'
        QtMocHelpers::SignalData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'canvasWidthChanged'
        QtMocHelpers::SignalData<void()>(17, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'canvasHeightChanged'
        QtMocHelpers::SignalData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'viewOffsetChanged'
        QtMocHelpers::SignalData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeLayerChanged'
        QtMocHelpers::SignalData<void()>(20, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isTransformingChanged'
        QtMocHelpers::SignalData<void()>(21, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushAngleChanged'
        QtMocHelpers::SignalData<void()>(22, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cursorRotationChanged'
        QtMocHelpers::SignalData<void()>(23, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentProjectPathChanged'
        QtMocHelpers::SignalData<void()>(24, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentProjectNameChanged'
        QtMocHelpers::SignalData<void()>(25, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushTipChanged'
        QtMocHelpers::SignalData<void()>(26, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cursorPosChanged'
        QtMocHelpers::SignalData<void(float, float)>(27, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 28 }, { QMetaType::Float, 29 },
        }}),
        // Signal 'projectsLoaded'
        QtMocHelpers::SignalData<void(const QVariantList &)>(30, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 31, 32 },
        }}),
        // Signal 'isEraserChanged'
        QtMocHelpers::SignalData<void(bool)>(33, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 34 },
        }}),
        // Signal 'layersChanged'
        QtMocHelpers::SignalData<void(const QVariantList &)>(35, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 31, 36 },
        }}),
        // Signal 'availableBrushesChanged'
        QtMocHelpers::SignalData<void()>(37, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeBrushNameChanged'
        QtMocHelpers::SignalData<void()>(38, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedHChanged'
        QtMocHelpers::SignalData<void()>(39, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedVChanged'
        QtMocHelpers::SignalData<void()>(40, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurvePointsChanged'
        QtMocHelpers::SignalData<void()>(41, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'strokeStarted'
        QtMocHelpers::SignalData<void(const QColor &)>(42, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 43, 44 },
        }}),
        // Signal 'isEditingBrushChanged'
        QtMocHelpers::SignalData<void()>(45, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'editingPresetChanged'
        QtMocHelpers::SignalData<void()>(46, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushPropertyChanged'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(47, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 48 }, { QMetaType::QString, 49 },
        }}),
        // Signal 'previewPadUpdated'
        QtMocHelpers::SignalData<void()>(50, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'requestToolIdx'
        QtMocHelpers::SignalData<void(int)>(51, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'setBackgroundColor'
        QtMocHelpers::MethodData<void(const QString &)>(53, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 44 },
        }}),
        // Method 'usePreset'
        QtMocHelpers::MethodData<void(const QString &)>(54, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 55 },
        }}),
        // Method 'loadProject'
        QtMocHelpers::MethodData<bool(const QString &)>(56, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 57 },
        }}),
        // Method 'saveProject'
        QtMocHelpers::MethodData<bool(const QString &)>(58, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 57 },
        }}),
        // Method 'saveProjectAs'
        QtMocHelpers::MethodData<bool(const QString &)>(59, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 57 },
        }}),
        // Method 'exportImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(60, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 57 }, { QMetaType::QString, 61 },
        }}),
        // Method 'importABR'
        QtMocHelpers::MethodData<bool(const QString &)>(62, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 57 },
        }}),
        // Method 'updateTransformProperties'
        QtMocHelpers::MethodData<void(float, float, float, float, float, float)>(63, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 28 }, { QMetaType::Float, 29 }, { QMetaType::Float, 64 }, { QMetaType::Float, 65 },
            { QMetaType::Float, 66 }, { QMetaType::Float, 67 },
        }}),
        // Method 'resizeCanvas'
        QtMocHelpers::MethodData<void(int, int)>(68, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 66 }, { QMetaType::Int, 67 },
        }}),
        // Method 'setProjectDpi'
        QtMocHelpers::MethodData<void(int)>(69, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 70 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int, int)>(71, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Int, 28 }, { QMetaType::Int, 29 }, { QMetaType::Int, 72 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int)>(71, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::QString, {{
            { QMetaType::Int, 28 }, { QMetaType::Int, 29 },
        }}),
        // Method 'adjustBrushSize'
        QtMocHelpers::MethodData<void(float)>(73, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 74 },
        }}),
        // Method 'adjustBrushOpacity'
        QtMocHelpers::MethodData<void(float)>(75, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 74 },
        }}),
        // Method 'isLayerClipped'
        QtMocHelpers::MethodData<bool(int)>(76, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'toggleClipping'
        QtMocHelpers::MethodData<void(int)>(77, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'toggleAlphaLock'
        QtMocHelpers::MethodData<void(int)>(78, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'toggleVisibility'
        QtMocHelpers::MethodData<void(int)>(79, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'clearLayer'
        QtMocHelpers::MethodData<void(int)>(80, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'setLayerOpacity'
        QtMocHelpers::MethodData<void(int, float)>(81, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 }, { QMetaType::Float, 82 },
        }}),
        // Method 'setLayerBlendMode'
        QtMocHelpers::MethodData<void(int, const QString &)>(83, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 }, { QMetaType::QString, 72 },
        }}),
        // Method 'setLayerPrivate'
        QtMocHelpers::MethodData<void(int, bool)>(84, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 }, { QMetaType::Bool, 85 },
        }}),
        // Method 'setActiveLayer'
        QtMocHelpers::MethodData<void(int)>(86, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'hclToHex'
        QtMocHelpers::MethodData<QString(float, float, float)>(87, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Float, 67 }, { QMetaType::Float, 88 }, { QMetaType::Float, 89 },
        }}),
        // Method 'hexToHcl'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(90, 2, QMC::AccessPublic, 0x80000000 | 31, {{
            { QMetaType::QString, 91 },
        }}),
        // Method 'undo'
        QtMocHelpers::MethodData<void()>(92, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'redo'
        QtMocHelpers::MethodData<void()>(93, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'canUndo'
        QtMocHelpers::MethodData<bool() const>(94, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'canRedo'
        QtMocHelpers::MethodData<bool() const>(95, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'loadRecentProjectsAsync'
        QtMocHelpers::MethodData<void()>(96, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getRecentProjects'
        QtMocHelpers::MethodData<QVariantList()>(97, 2, QMC::AccessPublic, 0x80000000 | 31),
        // Method 'get_project_list'
        QtMocHelpers::MethodData<QVariantList()>(98, 2, QMC::AccessPublic, 0x80000000 | 31),
        // Method 'load_file_path'
        QtMocHelpers::MethodData<void(const QString &)>(99, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 57 },
        }}),
        // Method 'handle_shortcuts'
        QtMocHelpers::MethodData<void(int, int)>(100, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 49 }, { QMetaType::Int, 101 },
        }}),
        // Method 'handle_key_release'
        QtMocHelpers::MethodData<void(int)>(102, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 49 },
        }}),
        // Method 'fitToView'
        QtMocHelpers::MethodData<void()>(103, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addLayer'
        QtMocHelpers::MethodData<void()>(104, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'removeLayer'
        QtMocHelpers::MethodData<void(int)>(105, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'duplicateLayer'
        QtMocHelpers::MethodData<void(int)>(106, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'mergeDown'
        QtMocHelpers::MethodData<void(int)>(107, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 },
        }}),
        // Method 'renameLayer'
        QtMocHelpers::MethodData<void(int, const QString &)>(108, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 }, { QMetaType::QString, 55 },
        }}),
        // Method 'applyEffect'
        QtMocHelpers::MethodData<void(int, const QString &, const QVariantMap &)>(109, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 52 }, { QMetaType::QString, 110 }, { 0x80000000 | 111, 112 },
        }}),
        // Method 'get_brush_preview'
        QtMocHelpers::MethodData<QString(const QString &)>(113, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 114 },
        }}),
        // Method 'getBrushesForCategory'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(115, 2, QMC::AccessPublic, 0x80000000 | 31, {{
            { QMetaType::QString, 48 },
        }}),
        // Method 'beginBrushEdit'
        QtMocHelpers::MethodData<void(const QString &)>(116, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 114 },
        }}),
        // Method 'cancelBrushEdit'
        QtMocHelpers::MethodData<void()>(117, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'applyBrushEdit'
        QtMocHelpers::MethodData<void()>(118, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'saveAsCopyBrush'
        QtMocHelpers::MethodData<void(const QString &)>(119, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 120 },
        }}),
        // Method 'resetBrushToDefault'
        QtMocHelpers::MethodData<void()>(121, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getBrushProperty'
        QtMocHelpers::MethodData<QVariant(const QString &, const QString &)>(122, 2, QMC::AccessPublic, 0x80000000 | 123, {{
            { QMetaType::QString, 48 }, { QMetaType::QString, 49 },
        }}),
        // Method 'setBrushProperty'
        QtMocHelpers::MethodData<void(const QString &, const QString &, const QVariant &)>(124, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 48 }, { QMetaType::QString, 49 }, { 0x80000000 | 123, 125 },
        }}),
        // Method 'getBrushCategoryProperties'
        QtMocHelpers::MethodData<QVariantMap(const QString &)>(126, 2, QMC::AccessPublic, 0x80000000 | 111, {{
            { QMetaType::QString, 48 },
        }}),
        // Method 'clearPreviewPad'
        QtMocHelpers::MethodData<void()>(127, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'previewPadBeginStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(128, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 28 }, { QMetaType::Float, 29 }, { QMetaType::Float, 129 },
        }}),
        // Method 'previewPadContinueStroke'
        QtMocHelpers::MethodData<void(float, float, float)>(130, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 28 }, { QMetaType::Float, 29 }, { QMetaType::Float, 129 },
        }}),
        // Method 'previewPadEndStroke'
        QtMocHelpers::MethodData<void()>(131, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getPreviewPadImage'
        QtMocHelpers::MethodData<QString()>(132, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'getStampPreview'
        QtMocHelpers::MethodData<QString()>(133, 2, QMC::AccessPublic, QMetaType::QString),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'brushSize'
        QtMocHelpers::PropertyData<int>(134, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'brushColor'
        QtMocHelpers::PropertyData<QColor>(135, 0x80000000 | 43, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'brushOpacity'
        QtMocHelpers::PropertyData<float>(136, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'brushFlow'
        QtMocHelpers::PropertyData<float>(137, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'brushHardness'
        QtMocHelpers::PropertyData<float>(138, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'brushSpacing'
        QtMocHelpers::PropertyData<float>(139, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'brushStabilization'
        QtMocHelpers::PropertyData<float>(140, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'brushStreamline'
        QtMocHelpers::PropertyData<float>(141, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'brushGrain'
        QtMocHelpers::PropertyData<float>(142, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'brushWetness'
        QtMocHelpers::PropertyData<float>(143, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'brushSmudge'
        QtMocHelpers::PropertyData<float>(144, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'impastoShininess'
        QtMocHelpers::PropertyData<float>(145, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'impastoStrength'
        QtMocHelpers::PropertyData<float>(146, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightAngle'
        QtMocHelpers::PropertyData<float>(147, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightElevation'
        QtMocHelpers::PropertyData<float>(148, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'zoomLevel'
        QtMocHelpers::PropertyData<float>(149, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 13),
        // property 'currentTool'
        QtMocHelpers::PropertyData<QString>(150, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 14),
        // property 'canvasWidth'
        QtMocHelpers::PropertyData<int>(151, QMetaType::Int, QMC::DefaultPropertyFlags, 15),
        // property 'canvasHeight'
        QtMocHelpers::PropertyData<int>(152, QMetaType::Int, QMC::DefaultPropertyFlags, 16),
        // property 'viewOffset'
        QtMocHelpers::PropertyData<QPointF>(153, 0x80000000 | 154, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 17),
        // property 'activeLayerIndex'
        QtMocHelpers::PropertyData<int>(155, QMetaType::Int, QMC::DefaultPropertyFlags, 18),
        // property 'isTransforming'
        QtMocHelpers::PropertyData<bool>(156, QMetaType::Bool, QMC::DefaultPropertyFlags, 19),
        // property 'brushAngle'
        QtMocHelpers::PropertyData<float>(157, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 20),
        // property 'cursorRotation'
        QtMocHelpers::PropertyData<float>(158, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 21),
        // property 'currentProjectPath'
        QtMocHelpers::PropertyData<QString>(159, QMetaType::QString, QMC::DefaultPropertyFlags, 22),
        // property 'currentProjectName'
        QtMocHelpers::PropertyData<QString>(160, QMetaType::QString, QMC::DefaultPropertyFlags, 23),
        // property 'brushTip'
        QtMocHelpers::PropertyData<QString>(161, QMetaType::QString, QMC::DefaultPropertyFlags, 24),
        // property 'isEraser'
        QtMocHelpers::PropertyData<bool>(162, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 27),
        // property 'isFlippedH'
        QtMocHelpers::PropertyData<bool>(163, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 31),
        // property 'isFlippedV'
        QtMocHelpers::PropertyData<bool>(164, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 32),
        // property 'canvasScale'
        QtMocHelpers::PropertyData<float>(165, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable, 13),
        // property 'canvasOffset'
        QtMocHelpers::PropertyData<QPointF>(166, 0x80000000 | 154, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 17),
        // property 'pressureCurvePoints'
        QtMocHelpers::PropertyData<QVariantList>(167, 0x80000000 | 31, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 33),
        // property 'availableBrushes'
        QtMocHelpers::PropertyData<QVariantList>(168, 0x80000000 | 31, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 29),
        // property 'activeBrushName'
        QtMocHelpers::PropertyData<QString>(169, QMetaType::QString, QMC::DefaultPropertyFlags, 30),
        // property 'isEditingBrush'
        QtMocHelpers::PropertyData<bool>(170, QMetaType::Bool, QMC::DefaultPropertyFlags, 35),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'ToolType'
        QtMocHelpers::EnumData<enum ToolType>(171, 171, QMC::EnumIsScoped).add({
            {  172, ToolType::Pen },
            {  173, ToolType::Eraser },
            {  174, ToolType::Lasso },
            {  175, ToolType::Transform },
            {  176, ToolType::Eyedropper },
            {  177, ToolType::Hand },
            {  178, ToolType::Fill },
            {  179, ToolType::Shape },
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
        case 13: _t->zoomLevelChanged(); break;
        case 14: _t->currentToolChanged(); break;
        case 15: _t->canvasWidthChanged(); break;
        case 16: _t->canvasHeightChanged(); break;
        case 17: _t->viewOffsetChanged(); break;
        case 18: _t->activeLayerChanged(); break;
        case 19: _t->isTransformingChanged(); break;
        case 20: _t->brushAngleChanged(); break;
        case 21: _t->cursorRotationChanged(); break;
        case 22: _t->currentProjectPathChanged(); break;
        case 23: _t->currentProjectNameChanged(); break;
        case 24: _t->brushTipChanged(); break;
        case 25: _t->cursorPosChanged((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 26: _t->projectsLoaded((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 27: _t->isEraserChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 28: _t->layersChanged((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 29: _t->availableBrushesChanged(); break;
        case 30: _t->activeBrushNameChanged(); break;
        case 31: _t->isFlippedHChanged(); break;
        case 32: _t->isFlippedVChanged(); break;
        case 33: _t->pressureCurvePointsChanged(); break;
        case 34: _t->strokeStarted((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 35: _t->isEditingBrushChanged(); break;
        case 36: _t->editingPresetChanged(); break;
        case 37: _t->brushPropertyChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 38: _t->previewPadUpdated(); break;
        case 39: _t->requestToolIdx((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 40: _t->setBackgroundColor((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 41: _t->usePreset((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 42: { bool _r = _t->loadProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 43: { bool _r = _t->saveProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 44: { bool _r = _t->saveProjectAs((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 45: { bool _r = _t->exportImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 46: { bool _r = _t->importABR((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 47: _t->updateTransformProperties((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[5])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[6]))); break;
        case 48: _t->resizeCanvas((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 49: _t->setProjectDpi((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 50: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 51: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 52: _t->adjustBrushSize((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 53: _t->adjustBrushOpacity((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 54: { bool _r = _t->isLayerClipped((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 55: _t->toggleClipping((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 56: _t->toggleAlphaLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 57: _t->toggleVisibility((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 58: _t->clearLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 59: _t->setLayerOpacity((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 60: _t->setLayerBlendMode((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 61: _t->setLayerPrivate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 62: _t->setActiveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 63: { QString _r = _t->hclToHex((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 64: { QVariantList _r = _t->hexToHcl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 65: _t->undo(); break;
        case 66: _t->redo(); break;
        case 67: { bool _r = _t->canUndo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 68: { bool _r = _t->canRedo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 69: _t->loadRecentProjectsAsync(); break;
        case 70: { QVariantList _r = _t->getRecentProjects();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 71: { QVariantList _r = _t->get_project_list();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 72: _t->load_file_path((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 73: _t->handle_shortcuts((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 74: _t->handle_key_release((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 75: _t->fitToView(); break;
        case 76: _t->addLayer(); break;
        case 77: _t->removeLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 78: _t->duplicateLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 79: _t->mergeDown((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 80: _t->renameLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 81: _t->applyEffect((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[3]))); break;
        case 82: { QString _r = _t->get_brush_preview((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 83: { QVariantList _r = _t->getBrushesForCategory((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 84: _t->beginBrushEdit((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 85: _t->cancelBrushEdit(); break;
        case 86: _t->applyBrushEdit(); break;
        case 87: _t->saveAsCopyBrush((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 88: _t->resetBrushToDefault(); break;
        case 89: { QVariant _r = _t->getBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QVariant*>(_a[0]) = std::move(_r); }  break;
        case 90: _t->setBrushProperty((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariant>>(_a[3]))); break;
        case 91: { QVariantMap _r = _t->getBrushCategoryProperties((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 92: _t->clearPreviewPad(); break;
        case 93: _t->previewPadBeginStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 94: _t->previewPadContinueStroke((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3]))); break;
        case 95: _t->previewPadEndStroke(); break;
        case 96: { QString _r = _t->getPreviewPadImage();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 97: { QString _r = _t->getStampPreview();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
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
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::zoomLevelChanged, 13))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentToolChanged, 14))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::canvasWidthChanged, 15))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::canvasHeightChanged, 16))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::viewOffsetChanged, 17))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::activeLayerChanged, 18))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isTransformingChanged, 19))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushAngleChanged, 20))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::cursorRotationChanged, 21))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentProjectPathChanged, 22))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::currentProjectNameChanged, 23))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::brushTipChanged, 24))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(float , float )>(_a, &CanvasItem::cursorPosChanged, 25))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::projectsLoaded, 26))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(bool )>(_a, &CanvasItem::isEraserChanged, 27))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::layersChanged, 28))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::availableBrushesChanged, 29))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::activeBrushNameChanged, 30))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedHChanged, 31))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedVChanged, 32))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::pressureCurvePointsChanged, 33))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QColor & )>(_a, &CanvasItem::strokeStarted, 34))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isEditingBrushChanged, 35))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::editingPresetChanged, 36))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QString & , const QString & )>(_a, &CanvasItem::brushPropertyChanged, 37))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::previewPadUpdated, 38))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(int )>(_a, &CanvasItem::requestToolIdx, 39))
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
        case 15: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 16: *reinterpret_cast<QString*>(_v) = _t->currentTool(); break;
        case 17: *reinterpret_cast<int*>(_v) = _t->canvasWidth(); break;
        case 18: *reinterpret_cast<int*>(_v) = _t->canvasHeight(); break;
        case 19: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 20: *reinterpret_cast<int*>(_v) = _t->activeLayerIndex(); break;
        case 21: *reinterpret_cast<bool*>(_v) = _t->isTransforming(); break;
        case 22: *reinterpret_cast<float*>(_v) = _t->brushAngle(); break;
        case 23: *reinterpret_cast<float*>(_v) = _t->cursorRotation(); break;
        case 24: *reinterpret_cast<QString*>(_v) = _t->currentProjectPath(); break;
        case 25: *reinterpret_cast<QString*>(_v) = _t->currentProjectName(); break;
        case 26: *reinterpret_cast<QString*>(_v) = _t->brushTip(); break;
        case 27: *reinterpret_cast<bool*>(_v) = _t->isEraser(); break;
        case 28: *reinterpret_cast<bool*>(_v) = _t->isFlippedH(); break;
        case 29: *reinterpret_cast<bool*>(_v) = _t->isFlippedV(); break;
        case 30: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 31: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 32: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurvePoints(); break;
        case 33: *reinterpret_cast<QVariantList*>(_v) = _t->availableBrushes(); break;
        case 34: *reinterpret_cast<QString*>(_v) = _t->activeBrushName(); break;
        case 35: *reinterpret_cast<bool*>(_v) = _t->isEditingBrush(); break;
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
        case 15: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 16: _t->setCurrentTool(*reinterpret_cast<QString*>(_v)); break;
        case 22: _t->setBrushAngle(*reinterpret_cast<float*>(_v)); break;
        case 23: _t->setCursorRotation(*reinterpret_cast<float*>(_v)); break;
        case 27: _t->setIsEraser(*reinterpret_cast<bool*>(_v)); break;
        case 28: _t->setIsFlippedH(*reinterpret_cast<bool*>(_v)); break;
        case 29: _t->setIsFlippedV(*reinterpret_cast<bool*>(_v)); break;
        case 30: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 31: _t->setViewOffset(*reinterpret_cast<QPointF*>(_v)); break;
        case 32: _t->setCurvePoints(*reinterpret_cast<QVariantList*>(_v)); break;
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
        if (_id < 98)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 98;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 98)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 98;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 36;
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
void CanvasItem::zoomLevelChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}

// SIGNAL 14
void CanvasItem::currentToolChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 14, nullptr);
}

// SIGNAL 15
void CanvasItem::canvasWidthChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 15, nullptr);
}

// SIGNAL 16
void CanvasItem::canvasHeightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 16, nullptr);
}

// SIGNAL 17
void CanvasItem::viewOffsetChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 17, nullptr);
}

// SIGNAL 18
void CanvasItem::activeLayerChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 18, nullptr);
}

// SIGNAL 19
void CanvasItem::isTransformingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 19, nullptr);
}

// SIGNAL 20
void CanvasItem::brushAngleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 20, nullptr);
}

// SIGNAL 21
void CanvasItem::cursorRotationChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 21, nullptr);
}

// SIGNAL 22
void CanvasItem::currentProjectPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 22, nullptr);
}

// SIGNAL 23
void CanvasItem::currentProjectNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 23, nullptr);
}

// SIGNAL 24
void CanvasItem::brushTipChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 24, nullptr);
}

// SIGNAL 25
void CanvasItem::cursorPosChanged(float _t1, float _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 25, nullptr, _t1, _t2);
}

// SIGNAL 26
void CanvasItem::projectsLoaded(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 26, nullptr, _t1);
}

// SIGNAL 27
void CanvasItem::isEraserChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 27, nullptr, _t1);
}

// SIGNAL 28
void CanvasItem::layersChanged(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 28, nullptr, _t1);
}

// SIGNAL 29
void CanvasItem::availableBrushesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 29, nullptr);
}

// SIGNAL 30
void CanvasItem::activeBrushNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 30, nullptr);
}

// SIGNAL 31
void CanvasItem::isFlippedHChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 31, nullptr);
}

// SIGNAL 32
void CanvasItem::isFlippedVChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 32, nullptr);
}

// SIGNAL 33
void CanvasItem::pressureCurvePointsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 33, nullptr);
}

// SIGNAL 34
void CanvasItem::strokeStarted(const QColor & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 34, nullptr, _t1);
}

// SIGNAL 35
void CanvasItem::isEditingBrushChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 35, nullptr);
}

// SIGNAL 36
void CanvasItem::editingPresetChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 36, nullptr);
}

// SIGNAL 37
void CanvasItem::brushPropertyChanged(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 37, nullptr, _t1, _t2);
}

// SIGNAL 38
void CanvasItem::previewPadUpdated()
{
    QMetaObject::activate(this, &staticMetaObject, 38, nullptr);
}

// SIGNAL 39
void CanvasItem::requestToolIdx(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 39, nullptr, _t1);
}
QT_WARNING_POP
