// ============================================================================
// ARTFLOW STUDIO PRO - CANVAS MODES (SIMPLE & STUDIO)
// Sistema dual de interfaz de canvas profesional
// ============================================================================

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: canvasRoot
    anchors.fill: parent
    color: "#0d0d0f"
    
    // ============================================================================
    // PROPERTIES & STATE
    // ============================================================================
    
    property bool isStudioMode: false // false = Simple Mode, true = Studio Mode
    property var mainCanvas // Canvas item reference
    property color colorAccent: "#4A90FF"
    property bool isZenMode: false
    
    // Studio Mode - Panel Configuration
    property var studioPanels: ({
        "layers": { visible: true, x: 0, y: 0, width: 280, height: 400, docked: "right" },
        "colors": { visible: true, x: 0, y: 0, width: 300, height: 450, docked: "right" },
        "brushes": { visible: true, x: 0, y: 0, width: 320, height: 500, docked: "left" },
        "navigator": { visible: true, x: 0, y: 0, width: 260, height: 200, docked: "none" },
        "history": { visible: false, x: 0, y: 0, width: 250, height: 300, docked: "none" },
        "brushSettings": { visible: false, x: 0, y: 0, width: 300, height: 480, docked: "none" }
    })
    
    // Simple Mode State
    property bool showLayers: false
    property bool showColors: false
    property bool showBrushes: false
    property int activeToolIdx: 7
    
    // ============================================================================
    // MODE SWITCHER (Top-Right Corner)
    // ============================================================================
    
    Rectangle {
        id: modeSwitcher
        width: 180
        height: 36
        radius: 18
        color: "#1a1a1e"
        border.color: "#2a2a2e"
        border.width: 1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
        z: 10000
        visible: !isZenMode
        
        Row {
            anchors.fill: parent
            spacing: 0
            
            // Simple Mode
            Rectangle {
                width: parent.width / 2
                height: parent.height
                radius: 18
                color: !isStudioMode ? colorAccent : "transparent"
                
                Text {
                    text: "Simple"
                    color: !isStudioMode ? "white" : "#888"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: canvasRoot.isStudioMode = false
                }
            }
            
            // Studio Mode
            Rectangle {
                width: parent.width / 2
                height: parent.height
                radius: 18
                color: isStudioMode ? colorAccent : "transparent"
                
                Text {
                    text: "Studio"
                    color: isStudioMode ? "white" : "#888"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: canvasRoot.isStudioMode = true
                }
            }
        }
    }
    
    // ============================================================================
    // SIMPLE MODE UI
    // ============================================================================
    
    Item {
        id: simpleModeContainer
        anchors.fill: parent
        visible: !isStudioMode
        
        // TOP BAR - Rediseñada compacta y premium
        Rectangle {
            id: simpleTopBar
            width: parent.width
            height: 48
            color: "#0f111115"
            z: 1000
            visible: !isZenMode
            
            // Glass effect
            Rectangle {
                anchors.fill: parent
                color: "#ffffff"
                opacity: 0.02
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12
                
                // Left Section - Navigation & Actions
                Row {
                    spacing: 10
                    Layout.alignment: Qt.AlignVCenter
                    
                    // Menu Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: menuBtnMouse.containsMouse ? "#22ffffff" : "transparent"
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 16
                                    height: 2
                                    radius: 1
                                    color: "#aaa"
                                }
                            }
                        }
                        
                        MouseArea {
                            id: menuBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                    
                    Rectangle { width: 1; height: 20; color: "#22ffffff" }
                    
                    // Undo/Redo
                    Row {
                        spacing: 6
                        
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: undoBtnMouse.containsMouse ? "#22ffffff" : "transparent"
                            
                            Text {
                                text: "↶"
                                color: "#aaa"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                id: undoBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mainCanvas) mainCanvas.undo()
                            }
                        }
                        
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: redoBtnMouse.containsMouse ? "#22ffffff" : "transparent"
                            
                            Text {
                                text: "↷"
                                color: "#aaa"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                id: redoBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mainCanvas) mainCanvas.redo()
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Center - Project Info
                Column {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    
                    Text {
                        text: "Untitled Canvas"
                        color: "#fff"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    
                    Text {
                        text: "1920 × 1080 • 100%"
                        color: "#666"
                        font.pixelSize: 10
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Right Section - Panel Toggles
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    
                    // Brushes Toggle
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 10
                        color: showBrushes ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.2) : (brushToggleMouse.containsMouse ? "#22ffffff" : "transparent")
                        border.color: showBrushes ? colorAccent : "transparent"
                        border.width: 2
                        
                        Text {
                            text: "🖌️"
                            font.pixelSize: 18
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: brushToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                showBrushes = !showBrushes
                                showLayers = false
                                showColors = false
                            }
                        }
                    }
                    
                    // Layers Toggle
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 10
                        color: showLayers ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.2) : (layersToggleMouse.containsMouse ? "#22ffffff" : "transparent")
                        border.color: showLayers ? colorAccent : "transparent"
                        border.width: 2
                        
                        Text {
                            text: "📄"
                            font.pixelSize: 18
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: layersToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                showLayers = !showLayers
                                showBrushes = false
                                showColors = false
                            }
                        }
                    }
                    
                    // Colors Toggle
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 10
                        color: showColors ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.2) : (colorsToggleMouse.containsMouse ? "#22ffffff" : "transparent")
                        border.color: showColors ? colorAccent : "transparent"
                        border.width: 2
                        
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.centerIn: parent
                            color: mainCanvas ? mainCanvas.brushColor : "#fff"
                            border.color: "#222"
                            border.width: 2
                        }
                        
                        MouseArea {
                            id: colorsToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                showColors = !showColors
                                showBrushes = false
                                showLayers = false
                            }
                        }
                    }
                }
            }
        }
        
        // VERTICAL TOOLBAR (Right Side) - Compacta y elegante
        Rectangle {
            id: simpleToolbar
            width: 54
            height: Math.min(simpleToolColumn.implicitHeight + 24, parent.height - 120)
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            z: 900
            visible: !isZenMode
            
            color: "#0f1a1a1e"
            radius: 27
            border.color: "#22ffffff"
            border.width: 1
            
            // Shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                z: -1
                radius: 35
                color: "black"
                opacity: 0.4
            }
            
            Column {
                id: simpleToolColumn
                anchors.centerIn: parent
                spacing: 6
                
                Repeater {
                    model: ["✥", "▢", "➰", "✣", "✒", "✎", "🖌", "💨", "⌫", "🪣", "💉", "✋"]
                    
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 12
                        color: index === activeToolIdx ? colorAccent : (toolMouse.containsMouse ? "#22ffffff" : "transparent")
                        
                        Text {
                            text: modelData
                            color: index === activeToolIdx ? "white" : "#aaa"
                            font.pixelSize: 18
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: toolMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeToolIdx = index
                        }
                    }
                }
            }
        }
        
        // FLOATING SLIDERS (Draggable) - Rediseñados más compactos
        Rectangle {
            id: simpleSliders
            x: 20
            y: parent.height / 2 - height / 2
            width: 48
            height: 360
            radius: 24
            color: "#0f1a1a1e"
            border.color: "#22ffffff"
            border.width: 1
            z: 800
            visible: !isZenMode
            
            // Shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                z: -1
                radius: 32
                color: "black"
                opacity: 0.4
            }
            
            // Drag Handle
            Rectangle {
                id: sliderDragHandle
                width: parent.width
                height: 32
                radius: 24
                color: "transparent"
                anchors.top: parent.top
                
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: 2
                        Rectangle {
                            width: 2
                            height: 12
                            radius: 1
                            color: "#555"
                        }
                    }
                }
                
                MouseArea {
                    id: sliderDragArea
                    anchors.fill: parent
                    drag.target: simpleSliders
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 10
                    drag.maximumX: canvasRoot.width - simpleSliders.width - 10
                    drag.minimumY: 60
                    drag.maximumY: canvasRoot.height - simpleSliders.height - 20
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                }
            }
            
            Column {
                anchors.top: sliderDragHandle.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24
                
                // Size Slider
                SliderControl {
                    label: "Size"
                    value: mainCanvas ? mainCanvas.brushSize / 100 : 0.5
                    onValueChanged: if (mainCanvas) mainCanvas.brushSize = value * 100
                }
                
                // Opacity Slider
                SliderControl {
                    label: "Opac"
                    value: mainCanvas ? mainCanvas.brushOpacity : 1.0
                    onValueChanged: if (mainCanvas) mainCanvas.brushOpacity = value
                }
            }
        }
    }
    
    // ============================================================================
    // STUDIO MODE UI
    // ============================================================================
    
    Item {
        id: studioModeContainer
        anchors.fill: parent
        visible: isStudioMode
        
        // MENUBAR - Estilo Clip Studio
        Rectangle {
            id: studioMenuBar
            width: parent.width
            height: 28
            color: "#1a1a1e"
            z: 2000
            
            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 4
                
                Repeater {
                    model: ["File", "Edit", "View", "Layer", "Select", "Filter", "Window", "Help"]
                    
                    Rectangle {
                        width: menuText.implicitWidth + 16
                        height: parent.height
                        color: menuItemMouse.containsMouse ? "#2a2a2e" : "transparent"
                        
                        Text {
                            id: menuText
                            text: modelData
                            color: "#ccc"
                            font.pixelSize: 11
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: menuItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
        
        // TOOLBAR - Horizontal bajo el menú
        Rectangle {
            id: studioToolBar
            anchors.top: studioMenuBar.bottom
            width: parent.width
            height: 48
            color: "#141416"
            z: 1900
            
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                spacing: 8
                
                Repeater {
                    model: ["↶", "↷", "|", "✥", "▢", "➰", "✣", "✒", "✎", "🖌", "💨", "⌫", "🪣", "💉", "✋"]
                    
                    Item {
                        width: modelData === "|" ? 1 : 36
                        height: 36
                        
                        Rectangle {
                            visible: modelData !== "|"
                            anchors.fill: parent
                            radius: 8
                            color: studioToolMouse.containsMouse ? "#22ffffff" : "transparent"
                            
                            Text {
                                text: modelData
                                color: "#aaa"
                                font.pixelSize: 16
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                id: studioToolMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        
                        Rectangle {
                            visible: modelData === "|"
                            width: 1
                            height: 24
                            color: "#2a2a2e"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
        
        // DOCKABLE PANELS CONTAINER
        Item {
            id: studioPanelsContainer
            anchors.top: studioToolBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            
            // Left Dock Area
            Rectangle {
                id: leftDockArea
                width: 320
                height: parent.height
                color: "#0f0f12"
                anchors.left: parent.left
                
                Column {
                    anchors.fill: parent
                    spacing: 0
                    
                    StudioPanel {
                        panelTitle: "Tool Properties"
                        panelHeight: 280
                        
                        contentItem: Item {
                            // Tool properties content
                            Text {
                                text: "Tool Properties Panel"
                                color: "#666"
                                anchors.centerIn: parent
                            }
                        }
                    }
                    
                    StudioPanel {
                        panelTitle: "Sub Tools"
                        panelHeight: 220
                        
                        contentItem: Item {
                            // Sub tools grid
                            Text {
                                text: "Sub Tools Panel"
                                color: "#666"
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }
            
            // Right Dock Area
            Rectangle {
                id: rightDockArea
                width: 300
                height: parent.height
                color: "#0f0f12"
                anchors.right: parent.right
                
                Column {
                    anchors.fill: parent
                    spacing: 0
                    
                    StudioPanel {
                        panelTitle: "Layers"
                        panelHeight: 380
                        
                        contentItem: Item {
                            // Layers panel content
                            Text {
                                text: "Layers Panel"
                                color: "#666"
                                anchors.centerIn: parent
                            }
                        }
                    }
                    
                    StudioPanel {
                        panelTitle: "Navigator"
                        panelHeight: 200
                        
                        contentItem: Item {
                            // Navigator content
                            Text {
                                text: "Navigator Panel"
                                color: "#666"
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }
            
            // Center Canvas Area con tabs
            Rectangle {
                anchors.left: leftDockArea.right
                anchors.right: rightDockArea.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "#0d0d0f"
                
                // Canvas Tabs
                Rectangle {
                    id: canvasTabs
                    width: parent.width
                    height: 32
                    color: "#141416"
                    
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        
                        Rectangle {
                            width: 180
                            height: parent.height
                            color: "#1a1a1e"
                            
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 8
                                
                                Text {
                                    text: "Untitled-1"
                                    color: "#fff"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Item { width: 1; height: 1; Layout.fillWidth: true }
                                
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: closeTabMouse.containsMouse ? "#333" : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Text {
                                        text: "×"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.centerIn: parent
                                    }
                                    
                                    MouseArea {
                                        id: closeTabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Canvas Area
                Rectangle {
                    anchors.top: canvasTabs.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: "#0a0a0c"
                    
                    // Canvas placeholder
                    Text {
                        text: "Canvas Area\n(Aquí va el QCanvasItem)"
                        color: "#444"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
        
        // Floating Panels (pueden arrastrarse fuera de dock)
        Repeater {
            model: Object.keys(studioPanels).filter(key => studioPanels[key].docked === "none")
            
            FloatingStudioPanel {
                panelId: modelData
                panelConfig: studioPanels[modelData]
            }
        }
    }
    
    // ============================================================================
    // COMPONENTS
    // ============================================================================
    
    // Simple Mode Slider Control
    component SliderControl: Item {
        property string label: ""
        property real value: 0.5
        signal valueChanged(real value)
        
        width: 32
        height: 140
        
        Column {
            anchors.fill: parent
            spacing: 8
            
            Text {
                text: label
                color: "#888"
                font.pixelSize: 10
                font.weight: Font.Medium
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                width: 8
                height: 110
                radius: 4
                color: "#2a2a2e"
                anchors.horizontalCenter: parent.horizontalCenter
                
                Rectangle {
                    width: parent.width
                    height: parent.height * parent.parent.parent.value
                    anchors.bottom: parent.bottom
                    radius: 4
                    color: colorAccent
                }
                
                Rectangle {
                    id: sliderThumb
                    width: 20
                    height: 12
                    radius: 4
                    color: "#fff"
                    border.color: "#333"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * (1 - parent.parent.parent.value)
                }
                
                MouseArea {
                    anchors.fill: parent
                    
                    function updateValue(my) {
                        var newVal = 1 - (my / parent.height)
                        newVal = Math.max(0, Math.min(1, newVal))
                        parent.parent.parent.valueChanged(newVal)
                    }
                    
                    onPressed: updateValue(mouseY)
                    onPositionChanged: if (pressed) updateValue(mouseY)
                }
            }
        }
    }
    
    // Studio Mode Panel
    component StudioPanel: Item {
        property string panelTitle: ""
        property int panelHeight: 300
        property Item contentItem
        
        width: parent.width
        height: panelHeight
        
        Rectangle {
            anchors.fill: parent
            color: "#141416"
            border.color: "#1a1a1e"
            border.width: 1
            
            Column {
                anchors.fill: parent
                spacing: 0
                
                // Panel Header
                Rectangle {
                    width: parent.width
                    height: 28
                    color: "#1a1a1e"
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        
                        Text {
                            text: panelTitle
                            color: "#ccc"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        
                        // Panel controls
                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 3
                                color: panelMinMouse.containsMouse ? "#333" : "transparent"
                                
                                Text {
                                    text: "−"
                                    color: "#888"
                                    font.pixelSize: 10
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: panelMinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 3
                                color: panelMaxMouse.containsMouse ? "#333" : "transparent"
                                
                                Text {
                                    text: "□"
                                    color: "#888"
                                    font.pixelSize: 8
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: panelMaxMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 3
                                color: panelCloseMouse.containsMouse ? "#333" : "transparent"
                                
                                Text {
                                    text: "×"
                                    color: "#888"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                                
                                MouseArea {
                                    id: panelCloseMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }
                }
                
                // Panel Content
                Item {
                    width: parent.width
                    height: parent.height - 28
                    
                    children: contentItem ? [contentItem] : []
                }
            }
        }
    }
    
    // Floating Studio Panel (can be dragged anywhere)
    component FloatingStudioPanel: Rectangle {
        id: floatingPanel
        
        property string panelId: ""
        property var panelConfig: null
        
        x: panelConfig ? panelConfig.x : 0
        y: panelConfig ? panelConfig.y : 0
        width: panelConfig ? panelConfig.width : 280
        height: panelConfig ? panelConfig.height : 400
        
        visible: panelConfig ? panelConfig.visible : false
        z: 1000
        
        color: "#141416"
        radius: 8
        border.color: "#2a2a2e"
        border.width: 1
        
        // Shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            z: -1
            radius: 16
            color: "black"
            opacity: 0.4
        }
        
        Column {
            anchors.fill: parent
            spacing: 0
            
            // Draggable Header
            Rectangle {
                id: floatingHeader
                width: parent.width
                height: 32
                color: "#1a1a1e"
                radius: 8
                
                Text {
                    text: panelId
                    color: "#ccc"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    drag.target: floatingPanel
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                }
            }
            
            // Content
            Item {
                width: parent.width
                height: parent.height - 32
                
                Text {
                    text: "Floating " + panelId
                    color: "#666"
                    anchors.centerIn: parent
                }
            }
        }
    }
}
