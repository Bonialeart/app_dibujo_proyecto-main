/****************************************************************************
** Meta object code from reading C++ file 'PreferencesManager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/PreferencesManager.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'PreferencesManager.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN18PreferencesManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto PreferencesManager::qt_create_metaobjectdata<qt_meta_tag_ZN18PreferencesManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "PreferencesManager",
        "settingsChanged",
        "",
        "pressureCurveChanged",
        "shortcutsChanged",
        "setThemeMode",
        "mode",
        "setThemeAccent",
        "accent",
        "setLanguage",
        "lang",
        "setGpuAcceleration",
        "enabled",
        "setUndoLevels",
        "levels",
        "setMemoryUsageLimit",
        "limit",
        "setCursorShowOutline",
        "show",
        "setCursorShowCrosshair",
        "setTabletInputMode",
        "setToolSwitchDelay",
        "delay",
        "setDragDistance",
        "distance",
        "setAutoSaveEnabled",
        "setUiScale",
        "scale",
        "setTouchGesturesEnabled",
        "setTouchEyedropperEnabled",
        "setMultitouchUndoRedoEnabled",
        "setPressureCurve",
        "QVariantList",
        "curve",
        "setShortcuts",
        "QVariantMap",
        "map",
        "setShortcut",
        "name",
        "seq",
        "resetDefaults",
        "getShortcut",
        "themeMode",
        "themeAccent",
        "language",
        "gpuAcceleration",
        "undoLevels",
        "memoryUsageLimit",
        "cursorShowOutline",
        "cursorShowCrosshair",
        "tabletInputMode",
        "toolSwitchDelay",
        "dragDistance",
        "autoSaveEnabled",
        "uiScale",
        "touchGesturesEnabled",
        "touchEyedropperEnabled",
        "multitouchUndoRedoEnabled",
        "pressureCurve",
        "shortcuts"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'settingsChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurveChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'shortcutsChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'setThemeMode'
        QtMocHelpers::SlotData<void(const QString &)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Slot 'setThemeAccent'
        QtMocHelpers::SlotData<void(const QString &)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 8 },
        }}),
        // Slot 'setLanguage'
        QtMocHelpers::SlotData<void(const QString &)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 10 },
        }}),
        // Slot 'setGpuAcceleration'
        QtMocHelpers::SlotData<void(bool)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 12 },
        }}),
        // Slot 'setUndoLevels'
        QtMocHelpers::SlotData<void(int)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 14 },
        }}),
        // Slot 'setMemoryUsageLimit'
        QtMocHelpers::SlotData<void(int)>(15, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 16 },
        }}),
        // Slot 'setCursorShowOutline'
        QtMocHelpers::SlotData<void(bool)>(17, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 18 },
        }}),
        // Slot 'setCursorShowCrosshair'
        QtMocHelpers::SlotData<void(bool)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 18 },
        }}),
        // Slot 'setTabletInputMode'
        QtMocHelpers::SlotData<void(const QString &)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Slot 'setToolSwitchDelay'
        QtMocHelpers::SlotData<void(int)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 22 },
        }}),
        // Slot 'setDragDistance'
        QtMocHelpers::SlotData<void(int)>(23, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 24 },
        }}),
        // Slot 'setAutoSaveEnabled'
        QtMocHelpers::SlotData<void(bool)>(25, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 12 },
        }}),
        // Slot 'setUiScale'
        QtMocHelpers::SlotData<void(double)>(26, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Double, 27 },
        }}),
        // Slot 'setTouchGesturesEnabled'
        QtMocHelpers::SlotData<void(bool)>(28, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 12 },
        }}),
        // Slot 'setTouchEyedropperEnabled'
        QtMocHelpers::SlotData<void(bool)>(29, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 12 },
        }}),
        // Slot 'setMultitouchUndoRedoEnabled'
        QtMocHelpers::SlotData<void(bool)>(30, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 12 },
        }}),
        // Slot 'setPressureCurve'
        QtMocHelpers::SlotData<void(const QVariantList &)>(31, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 32, 33 },
        }}),
        // Slot 'setShortcuts'
        QtMocHelpers::SlotData<void(const QVariantMap &)>(34, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 35, 36 },
        }}),
        // Slot 'setShortcut'
        QtMocHelpers::SlotData<void(const QString &, const QString &)>(37, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 38 }, { QMetaType::QString, 39 },
        }}),
        // Slot 'resetDefaults'
        QtMocHelpers::SlotData<void()>(40, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'getShortcut'
        QtMocHelpers::MethodData<QString(const QString &) const>(41, 2, QMC::AccessPublic, QMetaType::QString, {{
            { QMetaType::QString, 38 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'themeMode'
        QtMocHelpers::PropertyData<QString>(42, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'themeAccent'
        QtMocHelpers::PropertyData<QString>(43, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'language'
        QtMocHelpers::PropertyData<QString>(44, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'gpuAcceleration'
        QtMocHelpers::PropertyData<bool>(45, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'undoLevels'
        QtMocHelpers::PropertyData<int>(46, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'memoryUsageLimit'
        QtMocHelpers::PropertyData<int>(47, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'cursorShowOutline'
        QtMocHelpers::PropertyData<bool>(48, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'cursorShowCrosshair'
        QtMocHelpers::PropertyData<bool>(49, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'tabletInputMode'
        QtMocHelpers::PropertyData<QString>(50, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'toolSwitchDelay'
        QtMocHelpers::PropertyData<int>(51, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'dragDistance'
        QtMocHelpers::PropertyData<int>(52, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'autoSaveEnabled'
        QtMocHelpers::PropertyData<bool>(53, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'uiScale'
        QtMocHelpers::PropertyData<double>(54, QMetaType::Double, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'touchGesturesEnabled'
        QtMocHelpers::PropertyData<bool>(55, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'touchEyedropperEnabled'
        QtMocHelpers::PropertyData<bool>(56, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'multitouchUndoRedoEnabled'
        QtMocHelpers::PropertyData<bool>(57, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'pressureCurve'
        QtMocHelpers::PropertyData<QVariantList>(58, 0x80000000 | 32, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'shortcuts'
        QtMocHelpers::PropertyData<QVariantMap>(59, 0x80000000 | 35, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 2),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<PreferencesManager, qt_meta_tag_ZN18PreferencesManagerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject PreferencesManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18PreferencesManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18PreferencesManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN18PreferencesManagerE_t>.metaTypes,
    nullptr
} };

void PreferencesManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<PreferencesManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->settingsChanged(); break;
        case 1: _t->pressureCurveChanged(); break;
        case 2: _t->shortcutsChanged(); break;
        case 3: _t->setThemeMode((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 4: _t->setThemeAccent((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->setLanguage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->setGpuAcceleration((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 7: _t->setUndoLevels((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 8: _t->setMemoryUsageLimit((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 9: _t->setCursorShowOutline((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 10: _t->setCursorShowCrosshair((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 11: _t->setTabletInputMode((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 12: _t->setToolSwitchDelay((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 13: _t->setDragDistance((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 14: _t->setAutoSaveEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 15: _t->setUiScale((*reinterpret_cast<std::add_pointer_t<double>>(_a[1]))); break;
        case 16: _t->setTouchGesturesEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 17: _t->setTouchEyedropperEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 18: _t->setMultitouchUndoRedoEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 19: _t->setPressureCurve((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 20: _t->setShortcuts((*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[1]))); break;
        case 21: _t->setShortcut((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 22: _t->resetDefaults(); break;
        case 23: { QString _r = _t->getShortcut((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (PreferencesManager::*)()>(_a, &PreferencesManager::settingsChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (PreferencesManager::*)()>(_a, &PreferencesManager::pressureCurveChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (PreferencesManager::*)()>(_a, &PreferencesManager::shortcutsChanged, 2))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QString*>(_v) = _t->themeMode(); break;
        case 1: *reinterpret_cast<QString*>(_v) = _t->themeAccent(); break;
        case 2: *reinterpret_cast<QString*>(_v) = _t->language(); break;
        case 3: *reinterpret_cast<bool*>(_v) = _t->gpuAcceleration(); break;
        case 4: *reinterpret_cast<int*>(_v) = _t->undoLevels(); break;
        case 5: *reinterpret_cast<int*>(_v) = _t->memoryUsageLimit(); break;
        case 6: *reinterpret_cast<bool*>(_v) = _t->cursorShowOutline(); break;
        case 7: *reinterpret_cast<bool*>(_v) = _t->cursorShowCrosshair(); break;
        case 8: *reinterpret_cast<QString*>(_v) = _t->tabletInputMode(); break;
        case 9: *reinterpret_cast<int*>(_v) = _t->toolSwitchDelay(); break;
        case 10: *reinterpret_cast<int*>(_v) = _t->dragDistance(); break;
        case 11: *reinterpret_cast<bool*>(_v) = _t->autoSaveEnabled(); break;
        case 12: *reinterpret_cast<double*>(_v) = _t->uiScale(); break;
        case 13: *reinterpret_cast<bool*>(_v) = _t->touchGesturesEnabled(); break;
        case 14: *reinterpret_cast<bool*>(_v) = _t->touchEyedropperEnabled(); break;
        case 15: *reinterpret_cast<bool*>(_v) = _t->multitouchUndoRedoEnabled(); break;
        case 16: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurve(); break;
        case 17: *reinterpret_cast<QVariantMap*>(_v) = _t->shortcuts(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setThemeMode(*reinterpret_cast<QString*>(_v)); break;
        case 1: _t->setThemeAccent(*reinterpret_cast<QString*>(_v)); break;
        case 2: _t->setLanguage(*reinterpret_cast<QString*>(_v)); break;
        case 3: _t->setGpuAcceleration(*reinterpret_cast<bool*>(_v)); break;
        case 4: _t->setUndoLevels(*reinterpret_cast<int*>(_v)); break;
        case 5: _t->setMemoryUsageLimit(*reinterpret_cast<int*>(_v)); break;
        case 6: _t->setCursorShowOutline(*reinterpret_cast<bool*>(_v)); break;
        case 7: _t->setCursorShowCrosshair(*reinterpret_cast<bool*>(_v)); break;
        case 8: _t->setTabletInputMode(*reinterpret_cast<QString*>(_v)); break;
        case 9: _t->setToolSwitchDelay(*reinterpret_cast<int*>(_v)); break;
        case 10: _t->setDragDistance(*reinterpret_cast<int*>(_v)); break;
        case 11: _t->setAutoSaveEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 12: _t->setUiScale(*reinterpret_cast<double*>(_v)); break;
        case 13: _t->setTouchGesturesEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 14: _t->setTouchEyedropperEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 15: _t->setMultitouchUndoRedoEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 16: _t->setPressureCurve(*reinterpret_cast<QVariantList*>(_v)); break;
        case 17: _t->setShortcuts(*reinterpret_cast<QVariantMap*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *PreferencesManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *PreferencesManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18PreferencesManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int PreferencesManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 24)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 24;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 24)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 24;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 18;
    }
    return _id;
}

// SIGNAL 0
void PreferencesManager::settingsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void PreferencesManager::pressureCurveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void PreferencesManager::shortcutsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}
QT_WARNING_POP
