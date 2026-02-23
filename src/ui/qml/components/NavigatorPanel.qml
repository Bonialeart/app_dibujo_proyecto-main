import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    readonly property real currentZoom: targetCanvas ? (targetCanvas.zoomLevel || 1.0) : 1.0
    readonly property real currentRotation: targetCanvas ? (targetCanvas.canvasRotation || 0) : 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16
        
        // 1. MINIMAP PREMIUM
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0a0a0d"
            radius: 8
            border.color: "#2a2a2d"
            clip: true
            
            // Background pattern
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                opacity: 0.1
                // Chessboard pattern for transparency
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.fillStyle = "#333";
                        for (var i = 0; i < width; i += 10) {
                            for (var j = 0; j < height; j += 10) {
                                if ((i + j) % 20 === 0) ctx.fillRect(i, j, 10, 10);
                            }
                        }
                    }
                }
            }
            
            // Canvas Representation
            Item {
                id: minimapContainer
                width: parent.width * 0.8
                height: parent.height * 0.8
                anchors.centerIn: parent
                
                // Shadow for the canvas
                Rectangle {
                    anchors.fill: canvasRect
                    color: "black"
                    opacity: 0.5
                    radius: 2
                    z: -1
                }

                Rectangle {
                    id: canvasRect
                    anchors.centerIn: parent
                    // Maintain aspect ratio
                    width: parent.width
                    height: targetCanvas ? (parent.width * (targetCanvas.canvasHeight / targetCanvas.canvasWidth)) : parent.height
                    color: "#e0e0e0"
                    radius: 2
                    rotation: root.currentRotation
                    
                    // The viewport indicator
                    Rectangle {
                        id: viewportIndicator
                        // Simple approximation of viewport
                        width: parent.width / root.currentZoom
                        height: parent.height / root.currentZoom
                        anchors.centerIn: parent
                        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                        border.color: root.accentColor
                        border.width: 1.5
                        
                        // Crosshair central
                        Rectangle { width: 8; height: 1; color: root.accentColor; anchors.centerIn: parent }
                        Rectangle { width: 1; height: 8; color: root.accentColor; anchors.centerIn: parent }
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onPositionChanged: (mouse) => {
                    // Logic to pan the canvas when dragging here would go here
                    // if targetCanvas has a panTo() method
                }
            }
        }
        
        // 2. CONTROLS
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            
            // Zoom Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text { 
                    text: "🔍"
                    color: zoomMa.containsMouse ? "white" : "#666"
                    font.pixelSize: 14
                    MouseArea {
                        id: zoomMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if(targetCanvas) targetCanvas.zoomLevel = 1.0
                    }
                    ToolTip.visible: zoomMa.containsMouse
                    ToolTip.text: "Restablecer Zoom (100%)"
                }
                
                Slider {
                    id: zoomSlider
                    Layout.fillWidth: true
                    from: 0.1
                    to: 8.0
                    value: root.currentZoom
                    onValueChanged: if(targetCanvas && pressed) targetCanvas.zoomLevel = value
                    
                    background: Rectangle {
                        x: parent.leftPadding
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        radius: 2
                        color: "#1c1c1e"
                        Rectangle {
                            width: parent.visualPosition * parent.width
                            height: parent.height
                            color: root.accentColor
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: parent.pressed ? "white" : "#ccc"
                        border.color: "#333"
                        border.width: 1
                    }
                }
                
                Text {
                    text: Math.round(root.currentZoom * 100) + "%"
                    color: "#aaa"
                    font.pixelSize: 11
                    font.family: "Monospace"
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
            
            // Rotation Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text { 
                    text: "↻"
                    color: rotMa.containsMouse ? "white" : "#666"
                    font.pixelSize: 16
                    MouseArea {
                        id: rotMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if(targetCanvas) targetCanvas.canvasRotation = 0
                    }
                    ToolTip.visible: rotMa.containsMouse
                    ToolTip.text: "Restablecer Rotación (0°)"
                }
                
                Slider {
                    id: rotSlider
                    Layout.fillWidth: true
                    from: -180
                    to: 180
                    value: root.currentRotation
                    onValueChanged: if(targetCanvas && pressed) targetCanvas.canvasRotation = value
                    
                    background: Rectangle {
                        x: parent.leftPadding
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        radius: 2
                        color: "#1c1c1e"
                        Rectangle {
                            width: 2; height: 10; color: "#444"; anchors.centerIn: parent
                        }
                    }
                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: parent.pressed ? "white" : "#ccc"
                        border.color: "#333"
                        border.width: 1
                    }
                }
                
                Text {
                    text: Math.round(root.currentRotation) + "°"
                    color: "#aaa"
                    font.pixelSize: 11
                    font.family: "Monospace"
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

