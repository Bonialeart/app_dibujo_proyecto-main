/****************************************************************************
** Meta object code from reading C++ file 'panel_manager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/core/cpp/include/panel_manager.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'panel_manager.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN7artflow12PanelManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto artflow::PanelManager::qt_create_metaobjectdata<qt_meta_tag_ZN7artflow12PanelManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "artflow::PanelManager",
        "dockStateChanged",
        "",
        "workspaceChanged",
        "activeTabChanged",
        "loadWorkspace",
        "name",
        "togglePanel",
        "panelId",
        "collapseDock",
        "dockSide",
        "reorderPanel",
        "sourceIdx",
        "targetIdx",
        "mode",
        "movePanel",
        "targetDock",
        "targetIndex",
        "movePanelToFloat",
        "x",
        "y",
        "setActiveTab",
        "groupId",
        "setDockCollapsedByName",
        "dock",
        "state",
        "leftDockModel",
        "artflow::PanelListModel*",
        "leftDockModel2",
        "rightDockModel",
        "rightDockModel2",
        "bottomDockModel",
        "floatingModel",
        "leftCollapsed",
        "leftCollapsed2",
        "rightCollapsed",
        "rightCollapsed2",
        "bottomCollapsed",
        "activeWorkspace",
        "activeGroupTabs",
        "QVariantMap"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'dockStateChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'workspaceChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'activeTabChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'loadWorkspace'
        QtMocHelpers::MethodData<void(const QString &)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 6 },
        }}),
        // Method 'togglePanel'
        QtMocHelpers::MethodData<void(const QString &)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 8 },
        }}),
        // Method 'collapseDock'
        QtMocHelpers::MethodData<void(const QString &)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 10 },
        }}),
        // Method 'reorderPanel'
        QtMocHelpers::MethodData<void(const QString &, int, int, const QString &)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 10 }, { QMetaType::Int, 12 }, { QMetaType::Int, 13 }, { QMetaType::QString, 14 },
        }}),
        // Method 'movePanel'
        QtMocHelpers::MethodData<void(const QString &, const QString &, int, const QString &)>(15, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 8 }, { QMetaType::QString, 16 }, { QMetaType::Int, 17 }, { QMetaType::QString, 14 },
        }}),
        // Method 'movePanel'
        QtMocHelpers::MethodData<void(const QString &, const QString &, int)>(15, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::QString, 8 }, { QMetaType::QString, 16 }, { QMetaType::Int, 17 },
        }}),
        // Method 'movePanel'
        QtMocHelpers::MethodData<void(const QString &, const QString &)>(15, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::QString, 8 }, { QMetaType::QString, 16 },
        }}),
        // Method 'movePanelToFloat'
        QtMocHelpers::MethodData<void(const QString &, qreal, qreal)>(18, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 8 }, { QMetaType::QReal, 19 }, { QMetaType::QReal, 20 },
        }}),
        // Method 'setActiveTab'
        QtMocHelpers::MethodData<void(const QString &, const QString &)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 22 }, { QMetaType::QString, 8 },
        }}),
        // Method 'setDockCollapsedByName'
        QtMocHelpers::MethodData<void(const QString &, bool)>(23, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 24 }, { QMetaType::Bool, 25 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'leftDockModel'
        QtMocHelpers::PropertyData<artflow::PanelListModel*>(26, 0x80000000 | 27, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
        // property 'leftDockModel2'
        QtMocHelpers::PropertyData<artflow::PanelListModel*>(28, 0x80000000 | 27, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
        // property 'rightDockModel'
        QtMocHelpers::PropertyData<artflow::PanelListModel*>(29, 0x80000000 | 27, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
        // property 'rightDockModel2'
        QtMocHelpers::PropertyData<artflow::PanelListModel*>(30, 0x80000000 | 27, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
        // property 'bottomDockModel'
        QtMocHelpers::PropertyData<artflow::PanelListModel*>(31, 0x80000000 | 27, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
        // property 'floatingModel'
        QtMocHelpers::PropertyData<artflow::PanelListModel*>(32, 0x80000000 | 27, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
        // property 'leftCollapsed'
        QtMocHelpers::PropertyData<bool>(33, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'leftCollapsed2'
        QtMocHelpers::PropertyData<bool>(34, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'rightCollapsed'
        QtMocHelpers::PropertyData<bool>(35, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'rightCollapsed2'
        QtMocHelpers::PropertyData<bool>(36, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'bottomCollapsed'
        QtMocHelpers::PropertyData<bool>(37, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'activeWorkspace'
        QtMocHelpers::PropertyData<QString>(38, QMetaType::QString, QMC::DefaultPropertyFlags, 1),
        // property 'activeGroupTabs'
        QtMocHelpers::PropertyData<QVariantMap>(39, 0x80000000 | 40, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 2),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<PanelManager, qt_meta_tag_ZN7artflow12PanelManagerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject artflow::PanelManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow12PanelManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow12PanelManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN7artflow12PanelManagerE_t>.metaTypes,
    nullptr
} };

void artflow::PanelManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<PanelManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->dockStateChanged(); break;
        case 1: _t->workspaceChanged(); break;
        case 2: _t->activeTabChanged(); break;
        case 3: _t->loadWorkspace((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 4: _t->togglePanel((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->collapseDock((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->reorderPanel((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[4]))); break;
        case 7: _t->movePanel((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[4]))); break;
        case 8: _t->movePanel((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 9: _t->movePanel((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 10: _t->movePanelToFloat((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[3]))); break;
        case 11: _t->setActiveTab((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 12: _t->setDockCollapsedByName((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (PanelManager::*)()>(_a, &PanelManager::dockStateChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (PanelManager::*)()>(_a, &PanelManager::workspaceChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (PanelManager::*)()>(_a, &PanelManager::activeTabChanged, 2))
            return;
    }
    if (_c == QMetaObject::RegisterPropertyMetaType) {
        switch (_id) {
        default: *reinterpret_cast<int*>(_a[0]) = -1; break;
        case 5:
        case 4:
        case 3:
        case 2:
        case 1:
        case 0:
            *reinterpret_cast<int*>(_a[0]) = qRegisterMetaType< artflow::PanelListModel* >(); break;
        }
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<artflow::PanelListModel**>(_v) = _t->leftDockModel(); break;
        case 1: *reinterpret_cast<artflow::PanelListModel**>(_v) = _t->leftDockModel2(); break;
        case 2: *reinterpret_cast<artflow::PanelListModel**>(_v) = _t->rightDockModel(); break;
        case 3: *reinterpret_cast<artflow::PanelListModel**>(_v) = _t->rightDockModel2(); break;
        case 4: *reinterpret_cast<artflow::PanelListModel**>(_v) = _t->bottomDockModel(); break;
        case 5: *reinterpret_cast<artflow::PanelListModel**>(_v) = _t->floatingModel(); break;
        case 6: *reinterpret_cast<bool*>(_v) = _t->leftCollapsed(); break;
        case 7: *reinterpret_cast<bool*>(_v) = _t->leftCollapsed2(); break;
        case 8: *reinterpret_cast<bool*>(_v) = _t->rightCollapsed(); break;
        case 9: *reinterpret_cast<bool*>(_v) = _t->rightCollapsed2(); break;
        case 10: *reinterpret_cast<bool*>(_v) = _t->bottomCollapsed(); break;
        case 11: *reinterpret_cast<QString*>(_v) = _t->activeWorkspace(); break;
        case 12: *reinterpret_cast<QVariantMap*>(_v) = _t->activeGroupTabs(); break;
        default: break;
        }
    }
}

const QMetaObject *artflow::PanelManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *artflow::PanelManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN7artflow12PanelManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int artflow::PanelManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
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
        _id -= 13;
    }
    return _id;
}

// SIGNAL 0
void artflow::PanelManager::dockStateChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void artflow::PanelManager::workspaceChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void artflow::PanelManager::activeTabChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}
QT_WARNING_POP
