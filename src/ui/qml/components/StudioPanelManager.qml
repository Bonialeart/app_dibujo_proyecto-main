import QtQuick 2.15

// =============================================================================
// StudioPanelManager.qml — Thin QML wrapper over C++ PanelManager
// =============================================================================
// All heavy logic (loadWorkspace, togglePanel, movePanel, reorderPanel, etc.)
// now lives in C++ via the global `panelManager` context property.
// This QML file exists only for backward compatibility with bindings in
// StudioCanvasLayout.qml that reference `panelManager.*` properties.
// =============================================================================

Item {
    id: manager

    // --- MODELS (delegated to C++ panelManager) ---
    readonly property var leftDockModel:   panelManager.leftDockModel
    readonly property var leftDockModel2:  panelManager.leftDockModel2
    readonly property var rightDockModel:  panelManager.rightDockModel
    readonly property var rightDockModel2: panelManager.rightDockModel2
    readonly property var bottomDockModel: panelManager.bottomDockModel
    readonly property var floatingModel:   panelManager.floatingModel

    // --- STATE (delegated to C++ panelManager) ---
    readonly property bool leftCollapsed:   panelManager.leftCollapsed
    readonly property bool leftCollapsed2:  panelManager.leftCollapsed2
    readonly property bool rightCollapsed:  panelManager.rightCollapsed
    readonly property bool rightCollapsed2: panelManager.rightCollapsed2
    readonly property bool bottomCollapsed: panelManager.bottomCollapsed

    readonly property string activeWorkspace: panelManager.activeWorkspace
    readonly property var activeGroupTabs:    panelManager.activeGroupTabs

    // --- FORWARDED ACTIONS (delegate to C++) ---
    function loadWorkspace(name)     { panelManager.loadWorkspace(name) }
    function togglePanel(panelId)    { panelManager.togglePanel(panelId) }
    function collapseDock(dockSide)  { panelManager.collapseDock(dockSide) }

    function reorderPanel(dockSide, sourceIdx, targetIdx, mode) {
        panelManager.reorderPanel(dockSide, sourceIdx, targetIdx, mode)
    }

    function movePanel(panelId, targetDock, targetIndex, mode) {
        if (targetIndex === undefined) targetIndex = -1
        if (mode === undefined) mode = "insert"
        panelManager.movePanel(panelId, targetDock, targetIndex, mode)
    }

    function movePanelToFloat(panelId, x, y) {
        panelManager.movePanelToFloat(panelId, x, y)
    }

    function setActiveTab(groupId, panelId) {
        panelManager.setActiveTab(groupId, panelId)
    }

    function setDockCollapsed(dock, state) {
        // This was used by StudioCanvasLayout — now handled in C++
        // We don't need to replicate this, but keep the API for compat
        if (!state) {
            // Opening a dock is handled internally by movePanel/togglePanel
        }
    }

    function findPanelModel(panelId) {
        // Not needed in QML — C++ handles this internally
        return null
    }

    function findDockModel(side) {
        if (side === "left") return leftDockModel
        if (side === "left2") return leftDockModel2
        if (side === "right") return rightDockModel
        if (side === "right2") return rightDockModel2
        if (side === "bottom") return bottomDockModel
        return null
    }

    function getDockCollapsed(model) {
        if (model === leftDockModel) return leftCollapsed
        if (model === leftDockModel2) return leftCollapsed2
        if (model === rightDockModel) return rightCollapsed
        if (model === rightDockModel2) return rightCollapsed2
        if (model === bottomDockModel) return bottomCollapsed
        return true
    }

    function cleanDocks() {
        // No-op: C++ handles this automatically
    }

    function hasVisible(model) {
        // Kept for backward compatibility but unused
        return false
    }

    function setDockVisibility(model, panelId, groupId, state) {
        // No-op: handled internally by C++ togglePanel
    }
}
