import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root
    
    // Properties
    property var mainCanvas: null
    property color accentColor: "#6366f1"
    
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0

    width: 48 * uiScale
    height: 400 * uiScale
    
    // Background capsule matching the reference image
    Rectangle {
        anchors.fill: parent
        radius: 8 * uiScale
        color: "#2c2c2c" // dark grey panel background
        border.color: "#3a3a3a"
        border.width: 1
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.4
            shadowVerticalOffset: 3
            shadowColor: "#80000000"
            shadowOpacity: 0.3
        }
    }

    // Draggable background MouseArea (catches drags on empty areas and header)
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 10
        drag.maximumX: root.parent ? (root.parent.width - root.width - 10) : 2000
        drag.minimumY: 50
        drag.maximumY: root.parent ? (root.parent.height - root.height - 20) : 2000
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 4 * uiScale
        anchors.bottomMargin: 12 * uiScale
        spacing: 8 * uiScale

        // --- HEADER BUTTONS ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32 * uiScale
            spacing: 0
            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text {
                    text: "☰"
                    color: "#b0b0b0"
                    font.pixelSize: 18 * uiScale
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof mainWindow !== "undefined") {
                            mainWindow.showMenu = !mainWindow.showMenu
                        }
                    }
                }
            }
            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text {
                    text: "🎛"
                    color: "#b0b0b0"
                    font.pixelSize: 18 * uiScale
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof mainWindow !== "undefined") {
                            mainWindow.showBrush = !mainWindow.showBrush
                        }
                    }
                }
            }
        }

        // --- SIZE SLIDER GROUP ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6 * uiScale

            // Size Indicator Badge (Circle)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 34 * uiScale
                height: 34 * uiScale
                radius: 17 * uiScale
                color: "#1e1e1e"
                border.color: "#333333"
                border.width: 1
                
                Column {
                    anchors.centerIn: parent
                    spacing: -2 * uiScale
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: mainCanvas ? mainCanvas.brushSize.toFixed(1) : "10.0"
                        color: "#ffffff"
                        font.pixelSize: 9 * uiScale
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "px"
                        color: "#aaaaaa"
                        font.pixelSize: 8 * uiScale
                    }
                }
            }

            // Size Vertical Track Container
            Item {
                id: sizeTrackArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                property real sizeMin: 0.5
                property real sizeMax: 2000.0
                
                // Visual value helper using cubic scale
                readonly property real visualVal: mainCanvas 
                    ? Math.max(0.0, Math.min(1.0, Math.pow((mainCanvas.brushSize - sizeMin) / (sizeMax - sizeMin), 1.0 / 3.0)))
                    : 0.1

                // Size track bar background
                Rectangle {
                    id: sizeTrackBg
                    width: 6 * uiScale
                    height: parent.height - 20 * uiScale
                    radius: 3 * uiScale
                    color: "#18181a"
                    anchors.centerIn: parent
                    
                    // Size Track Progress Fill
                    Rectangle {
                        width: parent.width
                        anchors.bottom: parent.bottom
                        height: parent.height * sizeTrackArea.visualVal
                        radius: parent.radius
                        color: "#999999" // light grey progress fill
                    }
                }

                // Handle (Circle)
                Rectangle {
                    width: 16 * uiScale
                    height: 16 * uiScale
                    radius: 8 * uiScale
                    color: sizeMouse.pressed ? "#ffffff" : "#d0d0d0"
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // Map visualVal to Y coordinate (inverted, bottom is max, top is min)
                    y: sizeTrackBg.y + (sizeTrackBg.height - height) * (1.0 - sizeTrackArea.visualVal)
                    
                    border.color: "#1c1c1c"
                    border.width: 1
                    
                    Behavior on y {
                        enabled: !sizeMouse.pressed
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    id: sizeMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    
                    function updateVal(mouseY) {
                        var trackTop = sizeTrackBg.y
                        var trackHeight = sizeTrackBg.height
                        var pos = 1.0 - ((mouseY - trackTop) / trackHeight)
                        pos = Math.max(0.0, Math.min(1.0, pos))
                        
                        var newSize = sizeTrackArea.sizeMin + (sizeTrackArea.sizeMax - sizeTrackArea.sizeMin) * Math.pow(pos, 3.0)
                        if (mainCanvas) {
                            mainCanvas.brushSize = newSize
                        }
                    }
                    
                    onPressed: updateVal(mouseY)
                    onPositionChanged: if (pressed) updateVal(mouseY)
                }
            }
        }

        // --- OPACITY SLIDER GROUP ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6 * uiScale

            // Opacity Indicator Badge (Circle)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 34 * uiScale
                height: 34 * uiScale
                radius: 17 * uiScale
                color: "#e54e4e" // red-orange background
                
                Column {
                    anchors.centerIn: parent
                    spacing: -2 * uiScale
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100).toString() : "100"
                        color: "#ffffff"
                        font.pixelSize: 10 * uiScale
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "%"
                        color: "#ffffff"
                        font.pixelSize: 8 * uiScale
                    }
                }
            }

            // Opacity Vertical Track Container
            Item {
                id: opacityTrackArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                readonly property real opacityVal: mainCanvas ? mainCanvas.brushOpacity : 1.0

                // Opacity track bar background with checkerboard and gradient overlay
                Rectangle {
                    id: opacityTrackBg
                    width: 6 * uiScale
                    height: parent.height - 20 * uiScale
                    radius: 3 * uiScale
                    clip: true
                    anchors.centerIn: parent
                    
                    // 1. Checkerboard Background
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var size = 3 * uiScale
                            ctx.fillStyle = "#3c3c3e"
                            ctx.fillRect(0, 0, width, height)
                            ctx.fillStyle = "#6c6c6e"
                            for (var y = 0; y < height; y += size * 2) {
                                for (var x = 0; x < width; x += size * 2) {
                                    ctx.fillRect(x, y, size, size)
                                    ctx.fillRect(x + size, y + size, size, size)
                                }
                            }
                        }
                    }
                    
                    // 2. Opacity color gradient overlay (transparent at bottom, opaque at top)
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { 
                                position: 0.0
                                color: mainCanvas ? mainCanvas.brushColor : "#ffffff" 
                            }
                            GradientStop { 
                                position: 1.0 
                                color: "transparent" 
                            }
                        }
                    }
                }

                // Handle (Circle)
                Rectangle {
                    width: 16 * uiScale
                    height: 16 * uiScale
                    radius: 8 * uiScale
                    color: opacityMouse.pressed ? "#ffffff" : "#d0d0d0"
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // Map opacityVal to Y coordinate (inverted, bottom is max, top is min)
                    y: opacityTrackBg.y + (opacityTrackBg.height - height) * (1.0 - opacityTrackArea.opacityVal)
                    
                    border.color: "#1c1c1c"
                    border.width: 1
                    
                    Behavior on y {
                        enabled: !opacityMouse.pressed
                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    id: opacityMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    
                    function updateVal(mouseY) {
                        var trackTop = opacityTrackBg.y
                        var trackHeight = opacityTrackBg.height
                        var pos = 1.0 - ((mouseY - trackTop) / trackHeight)
                        pos = Math.max(0.0, Math.min(1.0, pos))
                        
                        if (mainCanvas) {
                            mainCanvas.brushOpacity = pos
                        }
                    }
                    
                    onPressed: updateVal(mouseY)
                    onPositionChanged: if (pressed) updateVal(mouseY)
                }
            }
        }
    }
}
