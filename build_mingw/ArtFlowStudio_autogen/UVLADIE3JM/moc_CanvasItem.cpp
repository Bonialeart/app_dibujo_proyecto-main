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
        "index",
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
        "key",
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
        "isFlippedH",
        "isFlippedV",
        "canvasScale",
        "canvasOffset",
        "pressureCurvePoints",
        "availableBrushes",
        "activeBrushName",
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
        // Signal 'layersChanged'
        QtMocHelpers::SignalData<void(const QVariantList &)>(33, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 31, 34 },
        }}),
        // Signal 'availableBrushesChanged'
        QtMocHelpers::SignalData<void()>(35, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeBrushNameChanged'
        QtMocHelpers::SignalData<void()>(36, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedHChanged'
        QtMocHelpers::SignalData<void()>(37, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isFlippedVChanged'
        QtMocHelpers::SignalData<void()>(38, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurvePointsChanged'
        QtMocHelpers::SignalData<void()>(39, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'strokeStarted'
        QtMocHelpers::SignalData<void(const QColor &)>(40, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 41, 42 },
        }}),
        // Method 'setBackgroundColor'
        QtMocHelpers::MethodData<void(const QString &)>(43, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 42 },
        }}),
        // Method 'usePreset'
        QtMocHelpers::MethodData<void(const QString &)>(44, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 45 },
        }}),
        // Method 'loadProject'
        QtMocHelpers::MethodData<bool(const QString &)>(46, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 47 },
        }}),
        // Method 'saveProject'
        QtMocHelpers::MethodData<bool(const QString &)>(48, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 47 },
        }}),
        // Method 'saveProjectAs'
        QtMocHelpers::MethodData<bool(const QString &)>(49, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 47 },
        }}),
        // Method 'exportImage'
        QtMocHelpers::MethodData<bool(const QString &, const QString &)>(50, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 47 }, { QMetaType::QString, 51 },
        }}),
        // Method 'importABR'
        QtMocHelpers::MethodData<bool(const QString &)>(52, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::QString, 47 },
        }}),
        // Method 'updateTransformProperties'
        QtMocHelpers::MethodData<void(float, float, float, float, float, float)>(53, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 28 }, { QMetaType::Float, 29 }, { QMetaType::Float, 54 }, { QMetaType::Float, 55 },
            { QMetaType::Float, 56 }, { QMetaType::Float, 57 },
        }}),
        // Method 'resizeCanvas'
        QtMocHelpers::MethodData<void(int, int)>(58, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 56 }, { QMetaType::Int, 57 },
        }}),
        // Method 'setProjectDpi'
        QtMocHelpers::MethodData<void(int)>(59, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 60 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int, int)>(61, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Int, 28 }, { QMetaType::Int, 29 }, { QMetaType::Int, 62 },
        }}),
        // Method 'sampleColor'
        QtMocHelpers::MethodData<QString(int, int)>(61, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::QString, {{
            { QMetaType::Int, 28 }, { QMetaType::Int, 29 },
        }}),
        // Method 'adjustBrushSize'
        QtMocHelpers::MethodData<void(float)>(63, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 64 },
        }}),
        // Method 'adjustBrushOpacity'
        QtMocHelpers::MethodData<void(float)>(65, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 64 },
        }}),
        // Method 'isLayerClipped'
        QtMocHelpers::MethodData<bool(int)>(66, 2, QMC::AccessPublic, QMetaType::Bool, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'toggleClipping'
        QtMocHelpers::MethodData<void(int)>(68, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'toggleAlphaLock'
        QtMocHelpers::MethodData<void(int)>(69, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'toggleVisibility'
        QtMocHelpers::MethodData<void(int)>(70, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'clearLayer'
        QtMocHelpers::MethodData<void(int)>(71, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'setLayerOpacity'
        QtMocHelpers::MethodData<void(int, float)>(72, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 }, { QMetaType::Float, 73 },
        }}),
        // Method 'setLayerBlendMode'
        QtMocHelpers::MethodData<void(int, const QString &)>(74, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 }, { QMetaType::QString, 62 },
        }}),
        // Method 'setLayerPrivate'
        QtMocHelpers::MethodData<void(int, bool)>(75, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 }, { QMetaType::Bool, 76 },
        }}),
        // Method 'setActiveLayer'
        QtMocHelpers::MethodData<void(int)>(77, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'hclToHex'
        QtMocHelpers::MethodData<QString(float, float, float)>(78, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::Float, 57 }, { QMetaType::Float, 79 }, { QMetaType::Float, 80 },
        }}),
        // Method 'hexToHcl'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(81, 2, QMC::AccessPublic, 0x80000000 | 31, {{
            { QMetaType::QString, 82 },
        }}),
        // Method 'undo'
        QtMocHelpers::MethodData<void()>(83, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'redo'
        QtMocHelpers::MethodData<void()>(84, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'canUndo'
        QtMocHelpers::MethodData<bool() const>(85, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'canRedo'
        QtMocHelpers::MethodData<bool() const>(86, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'loadRecentProjectsAsync'
        QtMocHelpers::MethodData<void()>(87, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getRecentProjects'
        QtMocHelpers::MethodData<QVariantList()>(88, 2, QMC::AccessPublic, 0x80000000 | 31),
        // Method 'get_project_list'
        QtMocHelpers::MethodData<QVariantList()>(89, 2, QMC::AccessPublic, 0x80000000 | 31),
        // Method 'load_file_path'
        QtMocHelpers::MethodData<void(const QString &)>(90, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 47 },
        }}),
        // Method 'handle_shortcuts'
        QtMocHelpers::MethodData<void(int, int)>(91, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 92 }, { QMetaType::Int, 93 },
        }}),
        // Method 'handle_key_release'
        QtMocHelpers::MethodData<void(int)>(94, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 92 },
        }}),
        // Method 'fitToView'
        QtMocHelpers::MethodData<void()>(95, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addLayer'
        QtMocHelpers::MethodData<void()>(96, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'removeLayer'
        QtMocHelpers::MethodData<void(int)>(97, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'duplicateLayer'
        QtMocHelpers::MethodData<void(int)>(98, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'mergeDown'
        QtMocHelpers::MethodData<void(int)>(99, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 },
        }}),
        // Method 'renameLayer'
        QtMocHelpers::MethodData<void(int, const QString &)>(100, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 }, { QMetaType::QString, 45 },
        }}),
        // Method 'applyEffect'
        QtMocHelpers::MethodData<void(int, const QString &, const QVariantMap &)>(101, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 67 }, { QMetaType::QString, 102 }, { 0x80000000 | 103, 104 },
        }}),
        // Method 'get_brush_preview'
        QtMocHelpers::MethodData<QString(const QString &)>(105, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 106 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'brushSize'
        QtMocHelpers::PropertyData<int>(107, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'brushColor'
        QtMocHelpers::PropertyData<QColor>(108, 0x80000000 | 41, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'brushOpacity'
        QtMocHelpers::PropertyData<float>(109, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'brushFlow'
        QtMocHelpers::PropertyData<float>(110, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'brushHardness'
        QtMocHelpers::PropertyData<float>(111, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'brushSpacing'
        QtMocHelpers::PropertyData<float>(112, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'brushStabilization'
        QtMocHelpers::PropertyData<float>(113, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
        // property 'brushStreamline'
        QtMocHelpers::PropertyData<float>(114, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 7),
        // property 'brushGrain'
        QtMocHelpers::PropertyData<float>(115, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 8),
        // property 'brushWetness'
        QtMocHelpers::PropertyData<float>(116, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 9),
        // property 'brushSmudge'
        QtMocHelpers::PropertyData<float>(117, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 10),
        // property 'impastoShininess'
        QtMocHelpers::PropertyData<float>(118, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 11),
        // property 'impastoStrength'
        QtMocHelpers::PropertyData<float>(119, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightAngle'
        QtMocHelpers::PropertyData<float>(120, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'lightElevation'
        QtMocHelpers::PropertyData<float>(121, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 12),
        // property 'zoomLevel'
        QtMocHelpers::PropertyData<float>(122, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 13),
        // property 'currentTool'
        QtMocHelpers::PropertyData<QString>(123, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 14),
        // property 'canvasWidth'
        QtMocHelpers::PropertyData<int>(124, QMetaType::Int, QMC::DefaultPropertyFlags, 15),
        // property 'canvasHeight'
        QtMocHelpers::PropertyData<int>(125, QMetaType::Int, QMC::DefaultPropertyFlags, 16),
        // property 'viewOffset'
        QtMocHelpers::PropertyData<QPointF>(126, 0x80000000 | 127, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 17),
        // property 'activeLayerIndex'
        QtMocHelpers::PropertyData<int>(128, QMetaType::Int, QMC::DefaultPropertyFlags, 18),
        // property 'isTransforming'
        QtMocHelpers::PropertyData<bool>(129, QMetaType::Bool, QMC::DefaultPropertyFlags, 19),
        // property 'brushAngle'
        QtMocHelpers::PropertyData<float>(130, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 20),
        // property 'cursorRotation'
        QtMocHelpers::PropertyData<float>(131, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 21),
        // property 'currentProjectPath'
        QtMocHelpers::PropertyData<QString>(132, QMetaType::QString, QMC::DefaultPropertyFlags, 22),
        // property 'currentProjectName'
        QtMocHelpers::PropertyData<QString>(133, QMetaType::QString, QMC::DefaultPropertyFlags, 23),
        // property 'brushTip'
        QtMocHelpers::PropertyData<QString>(134, QMetaType::QString, QMC::DefaultPropertyFlags, 24),
        // property 'isFlippedH'
        QtMocHelpers::PropertyData<bool>(135, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 30),
        // property 'isFlippedV'
        QtMocHelpers::PropertyData<bool>(136, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 31),
        // property 'canvasScale'
        QtMocHelpers::PropertyData<float>(137, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable, 13),
        // property 'canvasOffset'
        QtMocHelpers::PropertyData<QPointF>(138, 0x80000000 | 127, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 17),
        // property 'pressureCurvePoints'
        QtMocHelpers::PropertyData<QVariantList>(139, 0x80000000 | 31, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag, 32),
        // property 'availableBrushes'
        QtMocHelpers::PropertyData<QVariantList>(140, 0x80000000 | 31, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 28),
        // property 'activeBrushName'
        QtMocHelpers::PropertyData<QString>(141, QMetaType::QString, QMC::DefaultPropertyFlags, 29),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'ToolType'
        QtMocHelpers::EnumData<enum ToolType>(142, 142, QMC::EnumIsScoped).add({
            {  143, ToolType::Pen },
            {  144, ToolType::Eraser },
            {  145, ToolType::Lasso },
            {  146, ToolType::Transform },
            {  147, ToolType::Eyedropper },
            {  148, ToolType::Hand },
            {  149, ToolType::Fill },
            {  150, ToolType::Shape },
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
        case 27: _t->layersChanged((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 28: _t->availableBrushesChanged(); break;
        case 29: _t->activeBrushNameChanged(); break;
        case 30: _t->isFlippedHChanged(); break;
        case 31: _t->isFlippedVChanged(); break;
        case 32: _t->pressureCurvePointsChanged(); break;
        case 33: _t->strokeStarted((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 34: _t->setBackgroundColor((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 35: _t->usePreset((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 36: { bool _r = _t->loadProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 37: { bool _r = _t->saveProject((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 38: { bool _r = _t->saveProjectAs((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 39: { bool _r = _t->exportImage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 40: { bool _r = _t->importABR((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 41: _t->updateTransformProperties((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[5])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[6]))); break;
        case 42: _t->resizeCanvas((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 43: _t->setProjectDpi((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 44: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 45: { QString _r = _t->sampleColor((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 46: _t->adjustBrushSize((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 47: _t->adjustBrushOpacity((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 48: { bool _r = _t->isLayerClipped((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 49: _t->toggleClipping((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 50: _t->toggleAlphaLock((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 51: _t->toggleVisibility((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 52: _t->clearLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 53: _t->setLayerOpacity((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2]))); break;
        case 54: _t->setLayerBlendMode((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 55: _t->setLayerPrivate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 56: _t->setActiveLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 57: { QString _r = _t->hclToHex((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 58: { QVariantList _r = _t->hexToHcl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 59: _t->undo(); break;
        case 60: _t->redo(); break;
        case 61: { bool _r = _t->canUndo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 62: { bool _r = _t->canRedo();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 63: _t->loadRecentProjectsAsync(); break;
        case 64: { QVariantList _r = _t->getRecentProjects();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 65: { QVariantList _r = _t->get_project_list();
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 66: _t->load_file_path((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 67: _t->handle_shortcuts((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 68: _t->handle_key_release((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 69: _t->fitToView(); break;
        case 70: _t->addLayer(); break;
        case 71: _t->removeLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 72: _t->duplicateLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 73: _t->mergeDown((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 74: _t->renameLayer((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 75: _t->applyEffect((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[3]))); break;
        case 76: { QString _r = _t->get_brush_preview((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
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
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QVariantList & )>(_a, &CanvasItem::layersChanged, 27))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::availableBrushesChanged, 28))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::activeBrushNameChanged, 29))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedHChanged, 30))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::isFlippedVChanged, 31))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)()>(_a, &CanvasItem::pressureCurvePointsChanged, 32))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanvasItem::*)(const QColor & )>(_a, &CanvasItem::strokeStarted, 33))
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
        case 27: *reinterpret_cast<bool*>(_v) = _t->isFlippedH(); break;
        case 28: *reinterpret_cast<bool*>(_v) = _t->isFlippedV(); break;
        case 29: *reinterpret_cast<float*>(_v) = _t->zoomLevel(); break;
        case 30: *reinterpret_cast<QPointF*>(_v) = _t->viewOffset(); break;
        case 31: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurvePoints(); break;
        case 32: *reinterpret_cast<QVariantList*>(_v) = _t->availableBrushes(); break;
        case 33: *reinterpret_cast<QString*>(_v) = _t->activeBrushName(); break;
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
        case 27: _t->setIsFlippedH(*reinterpret_cast<bool*>(_v)); break;
        case 28: _t->setIsFlippedV(*reinterpret_cast<bool*>(_v)); break;
        case 29: _t->setZoomLevel(*reinterpret_cast<float*>(_v)); break;
        case 30: _t->setViewOffset(*reinterpret_cast<QPointF*>(_v)); break;
        case 31: _t->setCurvePoints(*reinterpret_cast<QVariantList*>(_v)); break;
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
        if (_id < 77)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 77;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 77)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 77;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 34;
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
void CanvasItem::layersChanged(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 27, nullptr, _t1);
}

// SIGNAL 28
void CanvasItem::availableBrushesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 28, nullptr);
}

// SIGNAL 29
void CanvasItem::activeBrushNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 29, nullptr);
}

// SIGNAL 30
void CanvasItem::isFlippedHChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 30, nullptr);
}

// SIGNAL 31
void CanvasItem::isFlippedVChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 31, nullptr);
}

// SIGNAL 32
void CanvasItem::pressureCurvePointsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 32, nullptr);
}

// SIGNAL 33
void CanvasItem::strokeStarted(const QColor & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 33, nullptr, _t1);
}
QT_WARNING_POP
