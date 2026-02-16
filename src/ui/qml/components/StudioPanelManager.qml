import QtQuick 2.15

Item {
    id: manager

    // --- MODELS ---
    property alias leftDockModel: leftModel
    property alias rightDockModel: rightModel
    property alias floatingModel: floatModel

    // --- STATE ---
    property string activeLeftPanel: ""
    property string activeRightPanel: ""
    property bool leftCollapsed: true
    property bool rightCollapsed: true

    // --- INTERNAL STORAGE ---
    ListModel {
        id: leftModel
        // Each item: { panelId, name, icon, source, visible }
        // Default Left Panels: Tool Options (Settings), Brushes?
        ListElement {
            panelId: "brushes"
            name: "Brushes"
            icon: "brush.svg"
            source: "BrushLibraryPanel.qml"
            visible: true
        }
        ListElement {
            panelId: "settings"
            name: "Settings" 
            icon: "sliders.svg" 
            source: "BrushSettingsPanel.qml" 
            visible: true 
        }
    }

    ListModel {
        id: rightModel
        // Default Right Panels: Color, Layers, Navigator
        ListElement {
            panelId: "color"
            name: "Color"
            icon: "palette.svg"
            source: "ColorPanel.qml" // TBD
            visible: true
        }
        ListElement {
            panelId: "layers"
            name: "Layers"
            icon: "layers.svg"
            source: "LayerPanel.qml" // TBD wrapper
            visible: true
        }
        ListElement {
            panelId: "navigator"
            name: "Navigator"
            icon: "compass.svg"
            source: "NavigatorPanel.qml" // TBD wrapper
            visible: true
        }
    }

    ListModel {
        id: floatModel
        // Panels that are floating
    }

    // --- ACTIONS ---

    function toggleLeftPanel(panelId) {
        if (activeLeftPanel === panelId) {
            // If clicking active, toggle collapse
            leftCollapsed = !leftCollapsed
            if (leftCollapsed) activeLeftPanel = "" // Clear active if collapsed? Or keep it? keeping it is better state.
            // Actually, usually clicking the icon of an open panel closes it.
            if (leftCollapsed) activeLeftPanel = "" 
        } else {
            activeLeftPanel = panelId
            leftCollapsed = false
        }
    }

    function toggleRightPanel(panelId) {
        if (activeRightPanel === panelId) {
            rightCollapsed = !rightCollapsed
            if (rightCollapsed) activeRightPanel = ""
        } else {
            activeRightPanel = panelId
            rightCollapsed = false
        }
    }

    function movePanel(panelId, targetDock) {
        // Logic to move between models
        // 1. Find panel in current model (left/right/float)
        // 2. Remove
        // 3. Add to target
        var sourceModel = findPanelModel(panelId)
        if (!sourceModel) return

        var item = null
        for(var i=0; i<sourceModel.count; i++) {
            if (sourceModel.get(i).panelId === panelId) {
                item = sourceModel.get(i)
                sourceModel.remove(i)
                break
            }
        }

        if (item) {
            if (targetDock === "left") {
                leftModel.append(item)
                activeLeftPanel = panelId
                leftCollapsed = false
            }
            else if (targetDock === "right") {
                rightModel.append(item)
                activeRightPanel = panelId
                rightCollapsed = false
            }
            else if (targetDock === "float") {
                 // item needs x,y props if not present, but ListModel elements are static?
                 // We can set properties on the item after appending if we pass them.
                 // But ListElement structure is strict.
                 // We need to ensure floatModel has x,y roles or we use a parallel object?
                 // ListModel supports dynamic roles if not defined in ListElement initially?
                 // Better to just append and let the FloatingPanel wrapper handle position via an external map or just standard properties if we can.
                 // Let's assume we can add x,y to the item copy.
                 item.x = 300 // default or passed
                 item.y = 200
                 floatModel.append(item)
            }
        }
    }

    function movePanelToFloat(panelId, x, y) {
        var sourceModel = findPanelModel(panelId)
        if (!sourceModel) return

        var item = null
        for(var i=0; i<sourceModel.count; i++) {
            if (sourceModel.get(i).panelId === panelId) {
                item = sourceModel.get(i)
                sourceModel.remove(i)
                break
            }
        }
        
        if (item) {
             // We need to inject x and y
             var obj = {
                 "panelId": item.panelId,
                 "name": item.name,
                 "icon": item.icon,
                 "source": item.source,
                 "visible": true,
                 "x": x,
                 "y": y
             }
             floatModel.append(obj)
             
             // Clear active state if it was docked
             if (activeLeftPanel === panelId) activeLeftPanel = ""
             if (activeRightPanel === panelId) activeRightPanel = ""
        }
    }

    function findPanelModel(panelId) {
        for(var i=0; i<leftModel.count; i++) if (leftModel.get(i).panelId === panelId) return leftModel
        for(var i=0; i<rightModel.count; i++) if (rightModel.get(i).panelId === panelId) return rightModel
        for(var i=0; i<floatModel.count; i++) if (floatModel.get(i).panelId === panelId) return floatModel
        return null
    }
}
