/****************************************************************************
** Meta object code from reading C++ file 'ColorPicker.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/core/cpp/include/ColorPicker.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'ColorPicker.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN11ColorPickerE_t {};
} // unnamed namespace

template <> constexpr inline auto ColorPicker::qt_create_metaobjectdata<qt_meta_tag_ZN11ColorPickerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "ColorPicker",
        "activeColorChanged",
        "",
        "secondaryColorChanged",
        "historyChanged",
        "palettesChanged",
        "addToHistory",
        "QColor",
        "color",
        "clearHistory",
        "generateShades",
        "QVariantList",
        "count",
        "type",
        "addPalette",
        "name",
        "colors",
        "removePalette",
        "colorToHSB",
        "colorToCMYK",
        "colorFromHSB",
        "h",
        "s",
        "b",
        "colorFromCMYK",
        "c",
        "m",
        "y",
        "k",
        "activeColor",
        "secondaryColor",
        "history",
        "palettes",
        "ShadeType",
        "SHADE",
        "TINT",
        "TONE",
        "WARMER",
        "COOLER",
        "COMPLEMENTARY_TINT",
        "COMPLEMENTARY_SHADE",
        "ANALOGOUS"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'activeColorChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'secondaryColorChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'historyChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'palettesChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addToHistory'
        QtMocHelpers::MethodData<void(const QColor &)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 7, 8 },
        }}),
        // Method 'clearHistory'
        QtMocHelpers::MethodData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'generateShades'
        QtMocHelpers::MethodData<QVariantList(int, int, const QColor &)>(10, 2, QMC::AccessPublic, 0x80000000 | 11, {{
            { QMetaType::Int, 12 }, { QMetaType::Int, 13 }, { 0x80000000 | 7, 8 },
        }}),
        // Method 'addPalette'
        QtMocHelpers::MethodData<void(const QString &, const QVariantList &)>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 15 }, { 0x80000000 | 11, 16 },
        }}),
        // Method 'removePalette'
        QtMocHelpers::MethodData<void(const QString &)>(17, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 15 },
        }}),
        // Method 'colorToHSB'
        QtMocHelpers::MethodData<QVariantList(const QColor &)>(18, 2, QMC::AccessPublic, 0x80000000 | 11, {{
            { 0x80000000 | 7, 8 },
        }}),
        // Method 'colorToCMYK'
        QtMocHelpers::MethodData<QVariantList(const QColor &)>(19, 2, QMC::AccessPublic, 0x80000000 | 11, {{
            { 0x80000000 | 7, 8 },
        }}),
        // Method 'colorFromHSB'
        QtMocHelpers::MethodData<QColor(float, float, float)>(20, 2, QMC::AccessPublic, 0x80000000 | 7, {{
            { QMetaType::Float, 21 }, { QMetaType::Float, 22 }, { QMetaType::Float, 23 },
        }}),
        // Method 'colorFromCMYK'
        QtMocHelpers::MethodData<QColor(float, float, float, float)>(24, 2, QMC::AccessPublic, 0x80000000 | 7, {{
            { QMetaType::Float, 25 }, { QMetaType::Float, 26 }, { QMetaType::Float, 27 }, { QMetaType::Float, 28 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'activeColor'
        QtMocHelpers::PropertyData<QColor>(29, 0x80000000 | 7, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 0),
        // property 'secondaryColor'
        QtMocHelpers::PropertyData<QColor>(30, 0x80000000 | 7, QMC::DefaultPropertyFlags | QMC::Writable | QMC::EnumOrFlag | QMC::StdCppSet, 1),
        // property 'history'
        QtMocHelpers::PropertyData<QVariantList>(31, 0x80000000 | 11, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 2),
        // property 'palettes'
        QtMocHelpers::PropertyData<QVariantList>(32, 0x80000000 | 11, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 3),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'ShadeType'
        QtMocHelpers::EnumData<enum ShadeType>(33, 33, QMC::EnumFlags{}).add({
            {   34, ShadeType::SHADE },
            {   35, ShadeType::TINT },
            {   36, ShadeType::TONE },
            {   37, ShadeType::WARMER },
            {   38, ShadeType::COOLER },
            {   39, ShadeType::COMPLEMENTARY_TINT },
            {   40, ShadeType::COMPLEMENTARY_SHADE },
            {   41, ShadeType::ANALOGOUS },
        }),
    };
    return QtMocHelpers::metaObjectData<ColorPicker, qt_meta_tag_ZN11ColorPickerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject ColorPicker::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN11ColorPickerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN11ColorPickerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN11ColorPickerE_t>.metaTypes,
    nullptr
} };

void ColorPicker::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<ColorPicker *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->activeColorChanged(); break;
        case 1: _t->secondaryColorChanged(); break;
        case 2: _t->historyChanged(); break;
        case 3: _t->palettesChanged(); break;
        case 4: _t->addToHistory((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1]))); break;
        case 5: _t->clearHistory(); break;
        case 6: { QVariantList _r = _t->generateShades((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 7: _t->addPalette((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[2]))); break;
        case 8: _t->removePalette((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 9: { QVariantList _r = _t->colorToHSB((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 10: { QVariantList _r = _t->colorToCMYK((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 11: { QColor _r = _t->colorFromHSB((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 12: { QColor _r = _t->colorFromCMYK((*reinterpret_cast<std::add_pointer_t<float>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<float>>(_a[4])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (ColorPicker::*)()>(_a, &ColorPicker::activeColorChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (ColorPicker::*)()>(_a, &ColorPicker::secondaryColorChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (ColorPicker::*)()>(_a, &ColorPicker::historyChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (ColorPicker::*)()>(_a, &ColorPicker::palettesChanged, 3))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QColor*>(_v) = _t->activeColor(); break;
        case 1: *reinterpret_cast<QColor*>(_v) = _t->secondaryColor(); break;
        case 2: *reinterpret_cast<QVariantList*>(_v) = _t->history(); break;
        case 3: *reinterpret_cast<QVariantList*>(_v) = _t->palettes(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setActiveColor(*reinterpret_cast<QColor*>(_v)); break;
        case 1: _t->setSecondaryColor(*reinterpret_cast<QColor*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *ColorPicker::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *ColorPicker::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN11ColorPickerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int ColorPicker::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 13)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 13)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 13;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void ColorPicker::activeColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void ColorPicker::secondaryColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void ColorPicker::historyChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void ColorPicker::palettesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}
QT_WARNING_POP
