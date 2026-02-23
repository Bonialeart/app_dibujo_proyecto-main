import QtQuick 2.15

Item {
    id: manager

    // --- MODELS ---
    property alias leftDockModel: leftModel
    property alias leftDockModel2: leftModel2
    property alias rightDockModel: rightModel
    property alias rightDockModel2: rightModel2
    property alias floatingModel: floatModel

    // --- STATE ---
    property string activeLeftPanel: ""
    property string activeRightPanel: ""
    property bool leftCollapsed: true
    property bool leftCollapsed2: true
    property bool rightCollapsed: true
    property bool rightCollapsed2: true
    
    // Tracks the currently active panelId for a given groupId
    property var activeGroupTabs: ({})

    function setActiveTab(groupId, panelId) {
        if (!groupId || groupId === "") return;
        var newTabs = Object.assign({}, activeGroupTabs);
        newTabs[groupId] = panelId;
        activeGroupTabs = newTabs;
    }

    // --- INTERNAL STORAGE ---
    ListModel { id: leftModel }
    ListModel { id: leftModel2 }
    ListModel { id: rightModel }
    ListModel { id: rightModel2 }
    ListModel { id: floatModel }
    
    property string activeWorkspace: "Ilustración"

    function loadWorkspace(name) {
        activeWorkspace = name;
        leftModel.clear();
        leftModel2.clear();
        rightModel.clear();
        rightModel2.clear();
        floatModel.clear();
        
        // Dictionaries of all our available panels
        var pBrushes = { panelId: "brushes", name: "Brushes", icon: "brush.svg", source: "BrushLibraryPanel.qml", visible: false, groupId: "" };
        var pSettings = { panelId: "settings", name: "StudioConfig", icon: "sliders.svg", source: "BrushSettingsPanel.qml", visible: false, groupId: "" };
        var pColor = { panelId: "color", name: "Color", icon: "palette.svg", source: "ColorPanel.qml", visible: false, groupId: "" };
        var pLayers = { panelId: "layers", name: "Layers", icon: "layers.svg", source: "LayerPanel.qml", visible: false, groupId: "" };
        var pNavigator = { panelId: "navigator", name: "Navigator", icon: "compass.svg", source: "NavigatorPanel.qml", visible: false, groupId: "" };
        
        if (name === "Manga/Comic") {
            // Manga setup
            pBrushes.visible = true;
            leftModel.append(pBrushes);
            leftModel.append(pSettings); // hidden but accessible below it
            
            pLayers.visible = true; 
            rightModel.append(pLayers);
            rightModel.append(pNavigator);
            
            pColor.visible = true;
            pColor.x = 200; pColor.y = 100;
            floatModel.append(pColor); // Floating color panel
        } else if (name === "Animación") {
            // Animation setup (preparing for future timeline panels)
            pLayers.visible = true;
            leftModel.append(pLayers);
            
            pNavigator.visible = true;
            rightModel.append(pNavigator);
            rightModel.append(pColor);
            
            pBrushes.visible = true;
            pBrushes.x = 250; pBrushes.y = 150;
            floatModel.append(pBrushes);
            
            pSettings.visible = true;
            pSettings.x = 450; pSettings.y = 150;
            floatModel.append(pSettings);
        } else {
            // Default "Ilustración" setup
            leftModel.append(pBrushes);
            leftModel.append(pSettings);
            rightModel.append(pColor);
            rightModel.append(pLayers);
            rightModel.append(pNavigator);
        }
        
        cleanDocks();
    }
    
    Component.onCompleted: {
        loadWorkspace("Ilustración");
    }

    // --- ACTIONS ---

    function togglePanel(panelId) {
        var targetModel = findPanelModel(panelId);
        if (!targetModel || targetModel === floatModel) return;

        var panelIdx = -1;
        var groupId = "";
        var currentlyVisible = false;
        
        for (var i = 0; i < targetModel.count; ++i) {
            if (targetModel.get(i).panelId === panelId) {
                panelIdx = i;
                groupId = targetModel.get(i).groupId || "";
                currentlyVisible = targetModel.get(i).visible;
                break;
            }
        }
        
        if (panelIdx === -1) return;

        var isDockCollapsed = getDockCollapsed(targetModel);
        
        // Logic:
        // 1. If dock is closed, open it with this panel/group.
        // 2. If dock is open and this panel is a tab in the current group, but NOT active -> switch tab.
        // 3. If dock is open and this panel is ALREADY active -> close group.
        // 4. If dock is open and this is a different independent panel -> switch to it.

        if (isDockCollapsed) {
            // Case 1: Open dock
            if (groupId !== "") setActiveTab(groupId, panelId);
            setDockVisibility(targetModel, panelId, groupId, true);
        } else {
            if (groupId !== "") {
                var currentTab = activeGroupTabs[groupId] || "";
                if (currentlyVisible && currentTab !== panelId) {
                    // Case 2: Switch tab
                    setActiveTab(groupId, panelId);
                } else {
                    // Case 3: Toggle current
                    setDockVisibility(targetModel, panelId, groupId, !currentlyVisible);
                }
            } else {
                // Case 4: Independent panel toggle
                setDockVisibility(targetModel, panelId, "", !currentlyVisible);
            }
        }

        if (groupId !== "") {
             // Ensure active tab matches if we just opened/switched
             if (activeGroupTabs[groupId] === undefined) setActiveTab(groupId, panelId);
        }

        cleanDocks();
    }

    function setDockVisibility(model, panelId, groupId, state) {
        if (state) {
            // Hide all others in THIS dock to prevent stacking unless grouped
            for (var i = 0; i < model.count; i++) model.setProperty(i, "visible", false);
        }
        for (var i = 0; i < model.count; i++) {
            var it = model.get(i);
            if (it.panelId === panelId || (groupId !== "" && it.groupId === groupId)) {
                model.setProperty(i, "visible", state);
            }
        }
    }

    function getDockCollapsed(model) {
        if (model === leftModel) return leftCollapsed;
        if (model === leftModel2) return leftCollapsed2;
        if (model === rightModel) return rightCollapsed;
        if (model === rightModel2) return rightCollapsed2;
        return true;
    }

    function collapseDock(dockSide) {
        var m = findDockModel(dockSide);
        if (!m) return;
        for (var i = 0; i < m.count; i++) m.setProperty(i, "visible", false);
        cleanDocks();
    }
    
    function reorderPanel(dockSide, sourceIdx, targetIdx, mode) {
        var m = findDockModel(dockSide);
        if (!m || sourceIdx < 0 || targetIdx < 0 || sourceIdx >= m.count || targetIdx >= m.count) return;
        
        var src = m.get(sourceIdx);
        var tgt = m.get(targetIdx);
        
        var clone = {
            panelId: src.panelId, name: src.name, icon: src.icon,
            source: src.source, visible: src.visible, groupId: src.groupId
        };
        
        if (mode === "group") {
            var gId = tgt.groupId || ("grp_" + tgt.panelId);
            m.setProperty(targetIdx, "groupId", gId);
            clone.groupId = gId;
            
            m.remove(sourceIdx);
            var adjTgt = (sourceIdx < targetIdx) ? (targetIdx - 1) : targetIdx;
            m.insert(adjTgt + 1, clone);
            setActiveTab(gId, clone.panelId);
        } else {
            clone.groupId = "";
            m.remove(sourceIdx);
            var adjTgt = (sourceIdx < targetIdx) ? (targetIdx - 1) : targetIdx;
            if (mode === "before") m.insert(adjTgt, clone);
            else m.insert(adjTgt + 1, clone);
        }
        cleanDocks();
    }

    function movePanel(panelId, targetDock, targetIndex = -1, mode = "insert") {
        var sourceModel = findPanelModel(panelId);
        if (!sourceModel) return;

        var it = null;
        for(var i=0; i<sourceModel.count; i++) {
            if (sourceModel.get(i).panelId === panelId) {
                var el = sourceModel.get(i);
                it = { 
                    panelId: el.panelId, name: el.name, icon: el.icon, 
                    source: el.source, visible: true, groupId: el.groupId || "" 
                };
                sourceModel.remove(i);
                break;
            }
        }

        if (it) {
            var m = findDockModel(targetDock);
            if (m) {
                // If grouping, we find the panel at targetIndex and use its groupId
                if (mode === "group" && targetIndex >= 0 && targetIndex < m.count) {
                    var tgt = m.get(targetIndex);
                    var gId = tgt.groupId || ("grp_" + tgt.panelId);
                    m.setProperty(targetIndex, "groupId", gId);
                    it.groupId = gId;
                    m.insert(targetIndex + 1, it);
                    setActiveTab(gId, it.panelId);
                } else {
                    it.groupId = ""; // Break group when moving to new position as single
                    if (targetIndex >= 0 && targetIndex <= m.count) m.insert(targetIndex, it);
                    else m.append(it);
                }
                setDockCollapsed(targetDock, false);
            }
        }
        cleanDocks();
    }

    function setDockCollapsed(dock, state) {
        if (dock === "left") leftCollapsed = state;
        else if (dock === "left2") leftCollapsed2 = state;
        else if (dock === "right") rightCollapsed = state;
        else if (dock === "right2") rightCollapsed2 = state;
    }

    function movePanelToFloat(panelId, x, y) {
        var sourceModel = findPanelModel(panelId);
        if (!sourceModel) return;

        var it = null;
        for(var i=0; i<sourceModel.count; i++) {
            if (sourceModel.get(i).panelId === panelId) {
                var el = sourceModel.get(i);
                it = { panelId: el.panelId, name: el.name, icon: el.icon, source: el.source, visible: true, groupId: "", x: x, y: y };
                sourceModel.remove(i);
                break;
            }
        }
        if (it) floatModel.append(it);
        cleanDocks();
    }

    function findPanelModel(panelId) {
        var docks = [leftModel, leftModel2, rightModel, rightModel2, floatModel];
        for (var j=0; j<docks.length; j++) {
            for(var i=0; i<docks[j].count; i++) if (docks[j].get(i).panelId === panelId) return docks[j];
        }
        return null;
    }

    function findDockModel(side) {
        if (side === "left") return leftModel;
        if (side === "left2") return leftModel2;
        if (side === "right") return rightModel;
        if (side === "right2") return rightModel2;
        return null;
    }

    function cleanDocks() {
        leftCollapsed = !hasVisible(leftModel);
        leftCollapsed2 = !hasVisible(leftModel2);
        rightCollapsed = !hasVisible(rightModel);
        rightCollapsed2 = !hasVisible(rightModel2);
    }

    function hasVisible(model) {
        for (var i = 0; i < model.count; ++i) if (model.get(i).visible) return true;
        return false;
    }
}
