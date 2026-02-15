// ============================================================================
// STUDIO PANEL MANAGER
// Sistema de gestión de paneles para Modo Studio
// ============================================================================

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: panelManager
    
    // ============================================================================
    // PROPERTIES
    // ============================================================================
    
    property var panels: ({}) // Panel configurations
    property var dockAreas: ({
        "left": { x: 0, y: 0, width: 320, height: 800, panels: [] },
        "right": { x: 1600, y: 0, width: 300, height: 800, panels: [] },
        "bottom": { x: 320, y: 600, width: 1280, height: 200, panels: [] }
    })
    
    property color colorAccent: "#4A90FF"
    property bool isReordering: false
    
    signal panelMoved(string panelId, string dockArea, int index)
    signal panelClosed(string panelId)
    signal panelResized(string panelId, real width, real height)
    
    // ============================================================================
    // PANEL REGISTRY
    // ============================================================================
    
    function registerPanel(id, config) {
        panels[id] = {
            id: id,
            title: config.title || id,
            visible: config.visible !== undefined ? config.visible : true,
            docked: config.docked || "none", // "left", "right", "bottom", "none"
            x: config.x || 0,
            y: config.y || 0,
            width: config.width || 280,
            height: config.height || 400,
            minWidth: config.minWidth || 200,
            minHeight: config.minHeight || 150,
            content: config.content || null,
            icon: config.icon || "📄"
        }
        panelsChanged()
    }
    
    function unregisterPanel(id) {
        delete panels[id]
        panelsChanged()
    }
    
    function togglePanel(id) {
        if (panels[id]) {
            panels[id].visible = !panels[id].visible
            panelsChanged()
        }
    }
    
    function dockPanel(id, area) {
        if (panels[id]) {
            panels[id].docked = area
            panelsChanged()
        }
    }
    
    function floatPanel(id) {
        if (panels[id]) {
            panels[id].docked = "none"
            panelsChanged()
        }
    }
    
    // ============================================================================
    // PERSISTENCE
    // ============================================================================
    
    function savePanelLayout() {
        return JSON.stringify(panels)
    }
    
    function loadPanelLayout(jsonString) {
        try {
            panels = JSON.parse(jsonString)
            panelsChanged()
        } catch (e) {
            console.error("Failed to load panel layout:", e)
        }
    }
    
    // ============================================================================
    // DOCK AREA COMPONENT
    // ============================================================================
    
    component DockArea: Rectangle {
        id: dockArea
        
        property string areaId: ""
        property bool isVertical: areaId === "left" || areaId === "right"
        property var dockedPanels: []
        
        color: "#0f0f12"
        border.color: "#1a1a1e"
        border.width: 1
        
        // Drop Zone Indicator
        Rectangle {
            id: dropIndicator
            anchors.fill: parent
            color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.2)
            border.color: colorAccent
            border.width: 2
            radius: 4
            visible: false
        }
        
        DropArea {
            anchors.fill: parent
            
            onEntered: {
                dropIndicator.visible = true
            }
            
            onExited: {
                dropIndicator.visible = false
            }
            
            onDropped: (drop) => {
                dropIndicator.visible = false
                var panelId = drop.getDataAsString("application/x-studiopanel")
                if (panelId) {
                    dockPanel(panelId, areaId)
                }
            }
        }
        
        // Docked Panels Container
        Column {
            anchors.fill: parent
            spacing: 0
            
            Repeater {
                model: dockedPanels
                
                DockedPanelItem {
                    panelConfig: modelData
                    areaId: dockArea.areaId
                }
            }
        }
    }
    
    // ============================================================================
    // DOCKED PANEL ITEM
    // ============================================================================
    
    component DockedPanelItem: Item {
        id: dockedItem
        
        property var panelConfig: null
        property string areaId: ""
        
        width: parent.width
        height: panelConfig ? panelConfig.height : 300
        
        Rectangle {
            anchors.fill: parent
            color: "#141416"
            border.color: "#1a1a1e"
            border.width: 1
            
            Column {
                anchors.fill: parent
                spacing: 0
                
                // Panel Header with Tabs
                Rectangle {
                    id: panelHeader
                    width: parent.width
                    height: 32
                    color: "#1a1a1e"
                    
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        
                        // Tab
                        Rectangle {
                            width: 140
                            height: parent.height
                            color: "#222226"
                            
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 8
                                
                                Text {
                                    text: panelConfig ? panelConfig.icon : "📄"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: panelConfig ? panelConfig.title : ""
                                    color: "#fff"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: 80
                                }
                            }
                            
                            MouseArea {
                                id: tabDragArea
                                anchors.fill: parent
                                
                                property point dragStartPos
                                
                                drag.target: dragProxy
                                
                                onPressed: {
                                    dragStartPos = Qt.point(mouseX, mouseY)
                                }
                                
                                Item {
                                    id: dragProxy
                                    visible: Drag.active
                                    
                                    Drag.active: tabDragArea.drag.active
                                    Drag.hotSpot.x: 70
                                    Drag.hotSpot.y: 16
                                    Drag.mimeData: {
                                        "application/x-studiopanel": panelConfig ? panelConfig.id : ""
                                    }
                                    
                                    Rectangle {
                                        width: 140
                                        height: 32
                                        color: "#2a2a2e"
                                        radius: 6
                                        border.color: colorAccent
                                        border.width: 2
                                        
                                        Text {
                                            text: panelConfig ? panelConfig.title : ""
                                            color: "#fff"
                                            font.pixelSize: 11
                                            anchors.centerIn: parent
                                        }
                                    }
                                }
                            }
                        }
                        
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        
                        // Panel Controls
                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 8
                            
                            // Float Button
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: floatBtnMouse.containsMouse ? "#333" : "transparent"
                                
                                Text {
                                    text: "⇱"
                                    color: "#888"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: floatBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (panelConfig) {
                                            floatPanel(panelConfig.id)
                                        }
                                    }
                                }
                            }
                            
                            // Close Button
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 4
                                color: closeBtnMouse.containsMouse ? "#ff3b30" : "transparent"
                                
                                Text {
                                    text: "×"
                                    color: closeBtnMouse.containsMouse ? "#fff" : "#888"
                                    font.pixelSize: 14
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: closeBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (panelConfig) {
                                            togglePanel(panelConfig.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Panel Content Area
                Rectangle {
                    width: parent.width
                    height: parent.height - panelHeader.height - resizeHandle.height
                    color: "#0f0f12"
                    clip: true
                    
                    // Content placeholder (should be replaced with actual panel content)
                    Item {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        // This would be replaced with the actual panel content component
                        Text {
                            text: panelConfig ? "Content: " + panelConfig.title : ""
                            color: "#555"
                            font.pixelSize: 12
                            anchors.centerIn: parent
                        }
                    }
                }
                
                // Resize Handle
                Rectangle {
                    id: resizeHandle
                    width: parent.width
                    height: 8
                    color: resizeHandleMouse.containsMouse ? "#2a2a2e" : "transparent"
                    
                    Rectangle {
                        width: 40
                        height: 3
                        radius: 1.5
                        color: "#3a3a3e"
                        anchors.centerIn: parent
                    }
                    
                    MouseArea {
                        id: resizeHandleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeVerCursor
                        
                        property real startY
                        property real startHeight
                        
                        onPressed: {
                            startY = mouseY
                            startHeight = dockedItem.height
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouseY - startY
                                var newHeight = startHeight + delta
                                
                                if (panelConfig) {
                                    newHeight = Math.max(panelConfig.minHeight, newHeight)
                                    dockedItem.height = newHeight
                                    panelConfig.height = newHeight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ============================================================================
    // FLOATING PANEL
    // ============================================================================
    
    component FloatingPanel: Rectangle {
        id: floatingPanel
        
        property var panelConfig: null
        
        x: panelConfig ? panelConfig.x : 100
        y: panelConfig ? panelConfig.y : 100
        width: panelConfig ? panelConfig.width : 280
        height: panelConfig ? panelConfig.height : 400
        
        visible: panelConfig ? (panelConfig.visible && panelConfig.docked === "none") : false
        z: 2000
        
        color: "#141416"
        radius: 8
        border.color: "#2a2a2e"
        border.width: 1
        
        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -10
            z: -1
            radius: 18
            color: "black"
            opacity: 0.5
        }
        
        Column {
            anchors.fill: parent
            spacing: 0
            
            // Draggable Title Bar
            Rectangle {
                id: titleBar
                width: parent.width
                height: 36
                color: "#1a1a1e"
                radius: 8
                
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    
                    Text {
                        text: panelConfig ? panelConfig.icon + " " + panelConfig.title : ""
                        color: "#fff"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Item { width: 1; height: 1; Layout.fillWidth: true }
                    
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        
                        // Dock Button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: dockBtnMouse.containsMouse ? "#333" : "transparent"
                            
                            Text {
                                text: "⊞"
                                color: "#888"
                                font.pixelSize: 14
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                id: dockBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Show dock options menu
                                    dockMenu.popup()
                                }
                            }
                            
                            Menu {
                                id: dockMenu
                                
                                MenuItem {
                                    text: "Dock Left"
                                    onTriggered: {
                                        if (panelConfig) {
                                            dockPanel(panelConfig.id, "left")
                                        }
                                    }
                                }
                                MenuItem {
                                    text: "Dock Right"
                                    onTriggered: {
                                        if (panelConfig) {
                                            dockPanel(panelConfig.id, "right")
                                        }
                                    }
                                }
                                MenuItem {
                                    text: "Dock Bottom"
                                    onTriggered: {
                                        if (panelConfig) {
                                            dockPanel(panelConfig.id, "bottom")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Close Button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: closeFltBtnMouse.containsMouse ? "#ff3b30" : "transparent"
                            
                            Text {
                                text: "×"
                                color: closeFltBtnMouse.containsMouse ? "#fff" : "#888"
                                font.pixelSize: 16
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                id: closeFltBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (panelConfig) {
                                        togglePanel(panelConfig.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 60
                    drag.target: floatingPanel
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    
                    onPositionChanged: {
                        if (drag.active && panelConfig) {
                            panelConfig.x = floatingPanel.x
                            panelConfig.y = floatingPanel.y
                        }
                    }
                }
            }
            
            // Content Area
            Rectangle {
                width: parent.width
                height: parent.height - titleBar.height
                color: "#0f0f12"
                radius: 8
                clip: true
                
                Item {
                    anchors.fill: parent
                    anchors.margins: 8
                    
                    Text {
                        text: panelConfig ? "Floating: " + panelConfig.title : ""
                        color: "#555"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }
                }
            }
        }
        
        // Resize Handles
        // Bottom-Right
        Rectangle {
            width: 16
            height: 16
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: "transparent"
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeFDiagCursor
                
                property point startPos
                property size startSize
                
                onPressed: {
                    startPos = Qt.point(mouseX, mouseY)
                    startSize = Qt.size(floatingPanel.width, floatingPanel.height)
                }
                
                onPositionChanged: {
                    if (pressed && panelConfig) {
                        var newWidth = Math.max(panelConfig.minWidth, startSize.width + mouseX - startPos.x)
                        var newHeight = Math.max(panelConfig.minHeight, startSize.height + mouseY - startPos.y)
                        
                        floatingPanel.width = newWidth
                        floatingPanel.height = newHeight
                        panelConfig.width = newWidth
                        panelConfig.height = newHeight
                    }
                }
            }
        }
    }
}
