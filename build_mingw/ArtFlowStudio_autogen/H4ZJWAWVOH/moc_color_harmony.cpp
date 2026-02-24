/****************************************************************************
** Meta object code from reading C++ file 'color_harmony.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/core/cpp/include/color_harmony.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'color_harmony.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN7artflow12ColorHarmonyE_t {};
} // unnamed namespace

template <> constexpr inline auto artflow::ColorHarmony::qt_create_metaobjectdata<qt_meta_tag_ZN7artflow12ColorHarmonyE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "artflow::ColorHarmony",
        "rgbToCMYK",
        "QVariantMap",
        "",
        "QColor",
        "color",
        "cmykToRGB",
        "c",
        "m",
        "y",
        "k",
        "getHarmonyColors",
        "QVariantList",
        "hue",
        "sat",
        "val",
        "mode",
        "colorsEqual",
        "c1",
        "c2",
        "toHex6",
        "isInList",
        "list"
    };

    QtMocHelpers::UintData qt_methods {
        // Method 'rgbToCMYK'
        QtMocHelpers::MethodData<QVariantMap(const QColor &) const>(1, 3, QMC::AccessPublic, 0x80000000 | 2, {{
            { 0x80000000 | 4, 5 },
        }}),
        // Method 'cmykToRGB'
        QtMocHelpers::MethodData<QColor(qreal, qreal, qreal, qreal) const>(6, 3, QMC::AccessPublic, 0x80000000 | 4, {{
            { QMetaType::QReal, 7 }, { QMetaType::QReal, 8 }, { QMetaType::QReal, 9 }, { QMetaType::QReal, 10 },
        }}),
        // Method 'getHarmonyColors'
        QtMocHelpers::MethodData<QVariantList(qreal, qreal, qreal, const QString &) const>(11, 3, QMC::AccessPublic, 0x80000000 | 12, {{
            { QMetaType::QReal, 13 }, { QMetaType::QReal, 14 }, { QMetaType::QReal, 15 }, { QMetaType::QString, 16 },
        }}),
        // Method 'colorsEqual'
        QtMocHelpers::MethodData<bool(const QColor &, const QColor &) const>(17, 3, QMC::AccessPublic, QMetaType::Bool, {{
            { 0x80000000 | 4, 18 }, { 0x80000000 | 4, 19 },
        }}),
        // Method 'toHex6'
        QtMocHelpers::MethodData<QString(const QColor &) const>(20, 3, QMC::AccessPublic, QMetaType::QString, {{
            { 0x80000000 | 4, 5 },
        }}),
        // Method 'isInList'
        QtMocHelpers::MethodData<bool(const QColor &, const QVariantList &) const>(21, 3, QMC::AccessPublic, QMetaType::Bool, {{
            { 0x80000000 | 4, 5 }, { 0x80000000 | 12, 22 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<ColorHarmony, qt_meta_tag_ZN7artflow12ColorHarmonyE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject artflow::ColorHarmony::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow12ColorHarmonyE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow12ColorHarmonyE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN7artflow12ColorHarmonyE_t>.metaTypes,
    nullptr
} };

void artflow::ColorHarmony::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<ColorHarmony *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: { QVariantMap _r = _t->rgbToCMYK((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 1: { QColor _r = _t->cmykToRGB((*reinterpret_cast<std::add_pointer_t<qreal>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[4])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 2: { QVariantList _r = _t->getHarmonyColors((*reinterpret_cast<std::add_pointer_t<qreal>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[4])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 3: { bool _r = _t->colorsEqual((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 4: { QString _r = _t->toHex6((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 5: { bool _r = _t->isInList((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[2])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
}

const QMetaObject *artflow::ColorHarmony::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *artflow::ColorHarmony::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow12ColorHarmonyE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int artflow::ColorHarmony::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 6)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 6)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 6;
    }
    return _id;
}
QT_WARNING_POP
