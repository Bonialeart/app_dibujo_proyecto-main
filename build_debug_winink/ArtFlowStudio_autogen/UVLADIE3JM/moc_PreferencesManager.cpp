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
        "setPressureCurve",
        "QVariantList",
        "curve",
        "resetDefaults",
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
        "pressureCurve"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'settingsChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'pressureCurveChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'setThemeMode'
        QtMocHelpers::SlotData<void(const QString &)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 5 },
        }}),
        // Slot 'setThemeAccent'
        QtMocHelpers::SlotData<void(const QString &)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 7 },
        }}),
        // Slot 'setLanguage'
        QtMocHelpers::SlotData<void(const QString &)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 9 },
        }}),
        // Slot 'setGpuAcceleration'
        QtMocHelpers::SlotData<void(bool)>(10, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 11 },
        }}),
        // Slot 'setUndoLevels'
        QtMocHelpers::SlotData<void(int)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 13 },
        }}),
        // Slot 'setMemoryUsageLimit'
        QtMocHelpers::SlotData<void(int)>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 },
        }}),
        // Slot 'setCursorShowOutline'
        QtMocHelpers::SlotData<void(bool)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 17 },
        }}),
        // Slot 'setCursorShowCrosshair'
        QtMocHelpers::SlotData<void(bool)>(18, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 17 },
        }}),
        // Slot 'setTabletInputMode'
        QtMocHelpers::SlotData<void(const QString &)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 5 },
        }}),
        // Slot 'setToolSwitchDelay'
        QtMocHelpers::SlotData<void(int)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 21 },
        }}),
        // Slot 'setDragDistance'
        QtMocHelpers::SlotData<void(int)>(22, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 23 },
        }}),
        // Slot 'setAutoSaveEnabled'
        QtMocHelpers::SlotData<void(bool)>(24, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 11 },
        }}),
        // Slot 'setPressureCurve'
        QtMocHelpers::SlotData<void(const QVariantList &)>(25, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 26, 27 },
        }}),
        // Slot 'resetDefaults'
        QtMocHelpers::SlotData<void()>(28, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'themeMode'
        QtMocHelpers::PropertyData<QString>(29, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'themeAccent'
        QtMocHelpers::PropertyData<QString>(30, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'language'
        QtMocHelpers::PropertyData<QString>(31, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'gpuAcceleration'
        QtMocHelpers::PropertyData<bool>(32, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'undoLevels'
        QtMocHelpers::PropertyData<int>(33, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'memoryUsageLimit'
        QtMocHelpers::PropertyData<int>(34, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'cursorShowOutline'
        QtMocHelpers::PropertyData<bool>(35, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'cursorShowCrosshair'
        QtMocHelpers::PropertyData<bool>(36, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'tabletInputMode'
        QtMocHelpers::PropertyData<QString>(37, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'toolSwitchDelay'
        QtMocHelpers::PropertyData<int>(38, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'dragDistance'
        QtMocHelpers::PropertyData<int>(39, QMetaType::Int, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'autoSaveEnabled'
        QtMocHelpers::PropertyData<bool>(40, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'pressureCurve'
        QtMocHelpers::PropertyData<QVariantList>(41, 0x80000000 | 26, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
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
        case 2: _t->setThemeMode((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 3: _t->setThemeAccent((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 4: _t->setLanguage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->setGpuAcceleration((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 6: _t->setUndoLevels((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 7: _t->setMemoryUsageLimit((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 8: _t->setCursorShowOutline((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 9: _t->setCursorShowCrosshair((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 10: _t->setTabletInputMode((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 11: _t->setToolSwitchDelay((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 12: _t->setDragDistance((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 13: _t->setAutoSaveEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 14: _t->setPressureCurve((*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 15: _t->resetDefaults(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (PreferencesManager::*)()>(_a, &PreferencesManager::settingsChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (PreferencesManager::*)()>(_a, &PreferencesManager::pressureCurveChanged, 1))
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
        case 12: *reinterpret_cast<QVariantList*>(_v) = _t->pressureCurve(); break;
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
        case 12: _t->setPressureCurve(*reinterpret_cast<QVariantList*>(_v)); break;
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
        if (_id < 16)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 16;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 16)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 16;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
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
QT_WARNING_POP
