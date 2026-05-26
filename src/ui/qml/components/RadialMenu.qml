import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: radialRoot
    
    // Properties
    property var mainCanvas: null
    property var canvasPage: null
    property color accentColor: "#6366f1"
    
    // Position coordinates
    property real menuX: 0
    property real menuY: 0
    
    // Toggle active state with smooth scale transitions
    property bool active: false
    visible: active || opacity > 0.0
    opacity: active ? 1.0 : 0.0
    scale: active ? 1.0 : 0.4
    
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
    
    // Track where to place the menu relative to parent width/height
    anchors.fill: parent
    z: 2900 // Floating on top of other canvas items
    
    // Dismiss when clicking outside
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            radialRoot.closeMenu()
        }
    }
    
    // Summon methods
    function openMenu(gx, gy) {
        var local = radialRoot.mapFromGlobal(gx, gy)
        
        // Boundaries checks to keep menu fully visible inside window
        var limitX = Math.max(160, Math.min(radialRoot.width - 280, local.x))
        var limitY = Math.max(160, Math.min(radialRoot.height - 200, local.y))
        
        menuX = limitX
        menuY = limitY
        active = true
    }
    
    function closeMenu() {
        active = false
    }
    
    function triggerHoveredSlice() {
        if (!active) return
        var idx = radialCanvas.hoveredSlice
        if (idx >= 0 && idx < menuModel.count) {
            var item = menuModel.get(idx)
            if (item && item.action) {
                item.action()
            }
        }
        closeMenu()
    }
    
    // Circular Menu Core
    Item {
        id: menuContainer
        width: 260; height: 260
        x: radialRoot.menuX - width / 2
        y: radialRoot.menuY - height / 2
        
        // MultiEffect drop shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 24
            shadowColor: "#aa000000"
            shadowVerticalOffset: 6
        }
        
        // Menu item definitions
        ListModel {
            id: menuModel
            ListElement { name: "Pen"; icon: "pen.svg" }
            ListElement { name: "Brush"; icon: "brush.svg" }
            ListElement { name: "Undo"; icon: "undo.svg" }
            ListElement { name: "Eyedropper"; icon: "picker.svg" }
            ListElement { name: "Eraser"; icon: "eraser.svg" }
            ListElement { name: "Hand"; icon: "hand.svg" }
            ListElement { name: "Redo"; icon: "redo.svg" }
            ListElement { name: "Settings"; icon: "settings.svg" }
        }
        
        // Wedge Painting Canvas
        Canvas {
            id: radialCanvas
            anchors.fill: parent
            
            property int hoveredSlice: -1
            onHoveredSliceChanged: requestPaint()
            
            property real innerRadius: 46
            property real outerRadius: 124
            property int numSlices: 8
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                
                var cx = width / 2
                var cy = height / 2
                
                for (var i = 0; i < numSlices; i++) {
                    // Align slice 0 centered straight up (-PI/2)
                    var startAngle = i * (2 * Math.PI / numSlices) - Math.PI / numSlices - Math.PI / 2
                    var endAngle = (i + 1) * (2 * Math.PI / numSlices) - Math.PI / numSlices - Math.PI / 2
                    
                    ctx.beginPath()
                    ctx.arc(cx, cy, outerRadius, startAngle, endAngle)
                    ctx.arc(cx, cy, innerRadius, endAngle, startAngle, true)
                    ctx.closePath()
                    
                    if (i === hoveredSlice) {
                        ctx.fillStyle = Qt.rgba(radialRoot.accentColor.r, radialRoot.accentColor.g, radialRoot.accentColor.b, 0.88)
                    } else {
                        ctx.fillStyle = "#eb121216" // Very elegant glassmorphic dark slate
                    }
                    ctx.fill()
                    
                    ctx.strokeStyle = Qt.rgba(1.0, 1.0, 1.0, 0.08)
                    ctx.lineWidth = 1.5
                    ctx.stroke()
                }
            }
        }
        
        // Interactive Mouse Area for sector highlighting and clicking
        MouseArea {
            id: hoverTracker
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onPositionChanged: (mouse) => {
                var cx = width / 2
                var cy = height / 2
                var dx = mouse.x - cx
                var dy = mouse.y - cy
                var dist = Math.sqrt(dx * dx + dy * dy)
                
                if (dist > radialCanvas.innerRadius && dist < radialCanvas.outerRadius) {
                    var angle = Math.atan2(dy, dx)
                    var adjustedAngle = angle + Math.PI / 2 + Math.PI / 8
                    if (adjustedAngle < 0) adjustedAngle += 2 * Math.PI
                    var slice = Math.floor((adjustedAngle % (2 * Math.PI)) / (2 * Math.PI / 8))
                    radialCanvas.hoveredSlice = slice
                } else {
                    radialCanvas.hoveredSlice = -1
                }
            }
            
            onExited: {
                radialCanvas.hoveredSlice = -1
            }
            
            onClicked: (mouse) => {
                if (radialCanvas.hoveredSlice >= 0) {
                    triggerAction(radialCanvas.hoveredSlice)
                } else {
                    // Click in center or outside closes
                    radialRoot.closeMenu()
                }
            }
        }
        
        // Action dispatcher
        function triggerAction(idx) {
            if (!canvasPage || !mainCanvas) return
            
            switch(idx) {
                case 0: // Pen
                    canvasPage.activeToolIdx = 5
                    break
                case 1: // Brush
                    canvasPage.activeToolIdx = 7
                    break
                case 2: // Undo
                    mainCanvas.undo()
                    break
                case 3: // Eyedropper
                    canvasPage.activeToolIdx = 11
                    break
                case 4: // Eraser
                    canvasPage.activeToolIdx = 9
                    break
                case 5: // Hand
                    canvasPage.activeToolIdx = 12
                    break
                case 6: // Redo
                    mainCanvas.redo()
                    break
                case 7: // Settings (Toggle Zen Mode / Close Zen)
                    if (typeof isZenMode !== "undefined") {
                        isZenMode = false
                    } else if (radialRoot.parent && radialRoot.parent.isZenMode !== undefined) {
                        radialRoot.parent.isZenMode = false
                    }
                    break
            }
            radialRoot.closeMenu()
        }
        
        // Wedge Icons & Labels
        Repeater {
            model: menuModel
            delegate: Item {
                width: 34; height: 34
                
                // Calculate position exactly in the middle of each sector (Radius 85)
                x: 130 + 84 * Math.cos(index * (2 * Math.PI / 8) - Math.PI / 2) - 17
                y: 130 + 84 * Math.sin(index * (2 * Math.PI / 8) - Math.PI / 2) - 17
                
                Image {
                    source: "image://icons/" + model.icon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    opacity: radialCanvas.hoveredSlice === index ? 1.0 : 0.7
                    scale: radialCanvas.hoveredSlice === index ? 1.15 : 1.0
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                }
            }
        }
        
        // Central Circle core displaying current color & active tool
        Rectangle {
            id: centerCore
            width: 78; height: 78
            radius: 39
            anchors.centerIn: parent
            color: "#18181c"
            border.color: radialCanvas.hoveredSlice === -1 ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : "#3a3a40"
            border.width: 2.5
            
            Behavior on border.color { ColorAnimation { duration: 150 } }
            
            // Current brush color glowing indicator inside
            Rectangle {
                width: 60; height: 60
                radius: 30
                anchors.centerIn: parent
                color: (mainCanvas && mainCanvas.brushColor) ? mainCanvas.brushColor : "transparent"
                border.color: "white"
                border.width: 1.5
                
                // Drop a tiny glowing icon of current tool in center of color
                Image {
                    width: 20; height: 20
                    anchors.centerIn: parent
                    source: {
                        if (!canvasPage) return ""
                        var activeTool = canvasPage.toolsModel.get(canvasPage.activeToolIdx)
                        return activeTool ? "image://icons/" + activeTool.icon : ""
                    }
                    visible: source !== ""
                    // Contrast overlay
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorBorderEnabled: true
                        colorBorderColor: "black"
                        colorBorderWidth: 1.0
                    }
                }
            }
        }
    }
    
    // Floating Adjustment Sliders (Paletas Flotantes HUD side panel)
    Rectangle {
        id: sliderHUD
        width: 120; height: 210
        radius: 20
        color: "#f016161a" // High-end semi-translucent dark slate
        border.color: "#3a3a40"
        border.width: 1
        
        // Place elegantly to the right side of the radial menu wheel
        x: radialRoot.menuX + 140
        y: radialRoot.menuY - height / 2
        
        // Glassmorphism shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 20
            shadowColor: "#80000000"
            shadowVerticalOffset: 4
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            
            // Brush Size Slider Column
            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6
                
                Text {
                    text: "TAMAÑO"
                    color: "#888"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }
                
                // Beautiful Glass Vertical Slider Track
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 26
                    Layout.alignment: Qt.AlignHCenter
                    
                    Rectangle {
                        id: sizeTrack
                        anchors.fill: parent
                        radius: 13
                        color: "#0d0d0f"
                        border.color: sizeDragArea.containsPress ? accentColor : "#2a2a30"
                        border.width: 1
                        
                        // Fill indicator
                        Item {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height * (mainCanvas ? Math.min(1.0, mainCanvas.brushSize / 1000.0) : 0)
                            clip: true
                            
                            Rectangle {
                                width: sizeTrack.width
                                height: sizeTrack.height
                                y: -sizeTrack.height + height
                                radius: 13
                                color: radialRoot.accentColor
                            }
                        }
                    }
                    
                    MouseArea {
                        id: sizeDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeVerCursor
                        onPressed: (mouse) => updateValue(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateValue(mouse)
                        }
                        
                        function updateValue(mouse) {
                            if (!mainCanvas) return
                            var pct = 1.0 - Math.max(0.0, Math.min(1.0, mouse.y / height))
                            mainCanvas.brushSize = Math.max(0.1, pct * 1000.0)
                        }
                    }
                }
                
                Text {
                    text: mainCanvas ? Math.round(mainCanvas.brushSize) + "px" : "0px"
                    color: "white"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
            }
            
            // Brush Opacity Slider Column
            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6
                
                Text {
                    text: "OPAC."
                    color: "#888"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }
                
                // Beautiful Glass Vertical Slider Track
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 26
                    Layout.alignment: Qt.AlignHCenter
                    
                    Rectangle {
                        id: opacTrack
                        anchors.fill: parent
                        radius: 13
                        color: "#0d0d0f"
                        border.color: opacDragArea.containsPress ? accentColor : "#2a2a30"
                        border.width: 1
                        
                        // Fill indicator
                        Item {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height * (mainCanvas ? mainCanvas.brushOpacity : 0)
                            clip: true
                            
                            Rectangle {
                                width: opacTrack.width
                                height: opacTrack.height
                                y: -opacTrack.height + height
                                radius: 13
                                color: radialRoot.accentColor
                            }
                        }
                    }
                    
                    MouseArea {
                        id: opacDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeVerCursor
                        onPressed: (mouse) => updateValue(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateValue(mouse)
                        }
                        
                        function updateValue(mouse) {
                            if (!mainCanvas) return
                            var pct = 1.0 - Math.max(0.0, Math.min(1.0, mouse.y / height))
                            mainCanvas.brushOpacity = Math.max(0.01, pct)
                        }
                    }
                }
                
                Text {
                    text: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) + "%" : "0%"
                    color: "white"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
