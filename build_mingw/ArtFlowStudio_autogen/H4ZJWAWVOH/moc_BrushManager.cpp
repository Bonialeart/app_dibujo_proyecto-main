/****************************************************************************
** Meta object code from reading C++ file 'BrushManager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/core/cpp/include/BrushManager.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'BrushManager.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN12BrushManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto BrushManager::qt_create_metaobjectdata<qt_meta_tag_ZN12BrushManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "BrushManager",
        "sizeChanged",
        "",
        "opacityChanged",
        "colorChanged",
        "spacingChanged",
        "jitterChanged",
        "streamlineChanged",
        "brushSettingsChanged",
        "setSize",
        "size",
        "setOpacity",
        "opacity",
        "setColor",
        "QColor",
        "color",
        "setSpacing",
        "spacing",
        "setJitter",
        "jitter",
        "setStreamline",
        "streamline",
        "setSizePressure",
        "enable",
        "sizePressure"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'sizeChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'opacityChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'colorChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'spacingChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'jitterChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'streamlineChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'brushSettingsChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'setSize'
        QtMocHelpers::SlotData<void(float)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 10 },
        }}),
        // Slot 'setOpacity'
        QtMocHelpers::SlotData<void(float)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 12 },
        }}),
        // Slot 'setColor'
        QtMocHelpers::SlotData<void(QColor)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 14, 15 },
        }}),
        // Slot 'setSpacing'
        QtMocHelpers::SlotData<void(float)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 17 },
        }}),
        // Slot 'setJitter'
        QtMocHelpers::SlotData<void(float)>(18, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 19 },
        }}),
        // Slot 'setStreamline'
        QtMocHelpers::SlotData<void(float)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Float, 21 },
        }}),
        // Slot 'setSizePressure'
        QtMocHelpers::SlotData<void(bool)>(22, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 23 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'size'
        QtMocHelpers::PropertyData<float>(10, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'opacity'
        QtMocHelpers::PropertyData<float>(12, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'color'
        QtMocHelpers::PropertyData<QColor>(15, 0x80000000 | 14, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 2),
        // property 'spacing'
        QtMocHelpers::PropertyData<float>(17, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 3),
        // property 'jitter'
        QtMocHelpers::PropertyData<float>(19, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 4),
        // property 'streamline'
        QtMocHelpers::PropertyData<float>(21, QMetaType::Float, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 5),
        // property 'sizePressure'
        QtMocHelpers::PropertyData<bool>(24, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 6),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<BrushManager, qt_meta_tag_ZN12BrushManagerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject BrushManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN12BrushManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN12BrushManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN12BrushManagerE_t>.metaTypes,
    nullptr
} };

void BrushManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<BrushManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->sizeChanged(); break;
        case 1: _t->opacityChanged(); break;
        case 2: _t->colorChanged(); break;
        case 3: _t->spacingChanged(); break;
        case 4: _t->jitterChanged(); break;
        case 5: _t->streamlineChanged(); break;
        case 6: _t->brushSettingsChanged(); break;
        case 7: _t->setSize((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 8: _t->setOpacity((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 9: _t->setColor((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 10: _t->setSpacing((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 11: _t->setJitter((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 12: _t->setStreamline((*reinterpret_cast<std::add_pointer_t<float>>(_a[1]))); break;
        case 13: _t->setSizePressure((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::sizeChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::opacityChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::colorChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::spacingChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::jitterChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::streamlineChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrushManager::*)()>(_a, &BrushManager::brushSettingsChanged, 6))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<float*>(_v) = _t->size(); break;
        case 1: *reinterpret_cast<float*>(_v) = _t->opacity(); break;
        case 2: *reinterpret_cast<QColor*>(_v) = _t->color(); break;
        case 3: *reinterpret_cast<float*>(_v) = _t->spacing(); break;
        case 4: *reinterpret_cast<float*>(_v) = _t->jitter(); break;
        case 5: *reinterpret_cast<float*>(_v) = _t->streamline(); break;
        case 6: *reinterpret_cast<bool*>(_v) = _t->sizePressure(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setSize(*reinterpret_cast<float*>(_v)); break;
        case 1: _t->setOpacity(*reinterpret_cast<float*>(_v)); break;
        case 2: _t->setColor(*reinterpret_cast<QColor*>(_v)); break;
        case 3: _t->setSpacing(*reinterpret_cast<float*>(_v)); break;
        case 4: _t->setJitter(*reinterpret_cast<float*>(_v)); break;
        case 5: _t->setStreamline(*reinterpret_cast<float*>(_v)); break;
        case 6: _t->setSizePressure(*reinterpret_cast<bool*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *BrushManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *BrushManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN12BrushManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int BrushManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 14)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 14;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 14)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 14;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 7;
    }
    return _id;
}

// SIGNAL 0
void BrushManager::sizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void BrushManager::opacityChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void BrushManager::colorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void BrushManager::spacingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void BrushManager::jitterChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void BrushManager::streamlineChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void BrushManager::brushSettingsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}
QT_WARNING_POP
