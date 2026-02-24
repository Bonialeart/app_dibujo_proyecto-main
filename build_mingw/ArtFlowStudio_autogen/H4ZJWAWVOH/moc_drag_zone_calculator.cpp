/****************************************************************************
** Meta object code from reading C++ file 'drag_zone_calculator.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/core/cpp/include/drag_zone_calculator.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'drag_zone_calculator.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t {};
} // unnamed namespace

template <> constexpr inline auto artflow::DragZoneCalculator::qt_create_metaobjectdata<qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "artflow::DragZoneCalculator",
        "calculateHoverIndex",
        "QVariantMap",
        "",
        "localY",
        "dockHeight",
        "PanelListModel*",
        "model",
        "insertZonePx",
        "computeDragZone",
        "gx",
        "layoutWidth",
        "leftBarWidth",
        "leftDockWidth",
        "leftBar2Visible",
        "leftBar2Width",
        "leftDock2Width",
        "rightBarWidth",
        "rightDockWidth",
        "rightBar2Visible",
        "rightBar2Width",
        "rightDock2Width",
        "leftCollapsed",
        "leftCollapsed2",
        "rightCollapsed",
        "rightCollapsed2",
        "leftExpandedW",
        "leftExpanded2W",
        "rightExpandedW",
        "rightExpanded2W"
    };

    QtMocHelpers::UintData qt_methods {
        // Method 'calculateHoverIndex'
        QtMocHelpers::MethodData<QVariantMap(qreal, qreal, PanelListModel *, int) const>(1, 3, QMC::AccessPublic, 0x80000000 | 2, {{
            { QMetaType::QReal, 4 }, { QMetaType::QReal, 5 }, { 0x80000000 | 6, 7 }, { QMetaType::Int, 8 },
        }}),
        // Method 'calculateHoverIndex'
        QtMocHelpers::MethodData<QVariantMap(qreal, qreal, PanelListModel *) const>(1, 3, QMC::AccessPublic | QMC::MethodCloned, 0x80000000 | 2, {{
            { QMetaType::QReal, 4 }, { QMetaType::QReal, 5 }, { 0x80000000 | 6, 7 },
        }}),
        // Method 'computeDragZone'
        QtMocHelpers::MethodData<QVariantMap(qreal, qreal, qreal, qreal, bool, qreal, qreal, qreal, qreal, bool, qreal, qreal, bool, bool, bool, bool, qreal, qreal, qreal, qreal) const>(9, 3, QMC::AccessPublic, 0x80000000 | 2, {{
            { QMetaType::QReal, 10 }, { QMetaType::QReal, 11 }, { QMetaType::QReal, 12 }, { QMetaType::QReal, 13 },
            { QMetaType::Bool, 14 }, { QMetaType::QReal, 15 }, { QMetaType::QReal, 16 }, { QMetaType::QReal, 17 },
            { QMetaType::QReal, 18 }, { QMetaType::Bool, 19 }, { QMetaType::QReal, 20 }, { QMetaType::QReal, 21 },
            { QMetaType::Bool, 22 }, { QMetaType::Bool, 23 }, { QMetaType::Bool, 24 }, { QMetaType::Bool, 25 },
            { QMetaType::QReal, 26 }, { QMetaType::QReal, 27 }, { QMetaType::QReal, 28 }, { QMetaType::QReal, 29 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<DragZoneCalculator, qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject artflow::DragZoneCalculator::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t>.metaTypes,
    nullptr
} };

void artflow::DragZoneCalculator::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<DragZoneCalculator *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: { QVariantMap _r = _t->calculateHoverIndex((*reinterpret_cast<std::add_pointer_t<qreal>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<PanelListModel*>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 1: { QVariantMap _r = _t->calculateHoverIndex((*reinterpret_cast<std::add_pointer_t<qreal>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<PanelListModel*>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 2: { QVariantMap _r = _t->computeDragZone((*reinterpret_cast<std::add_pointer_t<qreal>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[4])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[5])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[6])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[7])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[8])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[9])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[10])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[11])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[12])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[13])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[14])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[15])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[16])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[17])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[18])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[19])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[20])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        switch (_id) {
        default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
        case 0:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 2:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< PanelListModel* >(); break;
            }
            break;
        case 1:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 2:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< PanelListModel* >(); break;
            }
            break;
        }
    }
}

const QMetaObject *artflow::DragZoneCalculator::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *artflow::DragZoneCalculator::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow18DragZoneCalculatorE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int artflow::DragZoneCalculator::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 3)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 3)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 3;
    }
    return _id;
}
QT_WARNING_POP
