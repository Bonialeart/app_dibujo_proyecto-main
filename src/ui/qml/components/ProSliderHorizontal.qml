import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    
    property string label: ""
    property real value: 0.0
    property string previewType: "" // "size", "opacity"
    property bool previewOnBottom: false
    property string brushTipSource: ""
    property color brushColor: "black"
    
    implicitWidth: 200 * uiScale
    implicitHeight: 60 * uiScale
    
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0
    
    Row {
        anchors.fill: parent
        anchors.leftMargin: 15 * uiScale
        anchors.rightMargin: 15 * uiScale
        spacing: 12 * uiScale
        
        // Label
        Text {
            width: 45 * uiScale
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: slideMouse.containsMouse || slideMouse.pressed ? "white" : "#888"
            font.pixelSize: 10 * uiScale
            font.letterSpacing: 0.5
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Slider Logic
        Item {
            id: trackArea
            width: parent.width - (70 * uiScale)
            height: 30 * uiScale
            anchors.verticalCenter: parent.verticalCenter

            // Background Track (Premium Etched/Glass look)
            Rectangle {
                id: trackBg
                width: parent.width; height: 6 * uiScale
                radius: 3 * uiScale; anchors.centerIn: parent
                color: Qt.rgba(0.1, 0.1, 0.11, 0.8)
                border.color: Qt.rgba(1, 1, 1, 0.08); border.width: 1
                clip: true // ⇠ FIXES THE LEAKING

                // Progress Fill (Inside the clipped background)
                Rectangle {
                    width: parent.width * root.value
                    height: parent.height
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#6366f1" }
                        GradientStop { position: 1.0; color: "#7c3aed" }
                    }
                    
                    // Subtle inner shine for the fill
                    Rectangle {
                        anchors.fill: parent
                        anchors.bottomMargin: parent.height * 0.5
                        color: "white"
                        opacity: 0.1
                    }
                }
            }

            // Handle
            Rectangle {
                id: handle
                width: 12 * uiScale; height: 24 * uiScale
                radius: 6 * uiScale; color: "#ffffff"
                x: parent.width * root.value - width/2
                anchors.verticalCenter: parent.verticalCenter
                
                // Line
                Rectangle {
                    width: 2 * uiScale; height: 10 * uiScale; radius: 1; 
                    color: slideMouse.pressed ? "white" : "#6366f1"
                    anchors.centerIn: parent
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                // Glow
                Rectangle {
                    anchors.centerIn: parent; width: parent.width + 12; height: parent.height + 12
                    radius: 12 * uiScale; color: "#6366f1"
                    opacity: slideMouse.pressed ? 0.2 : (slideMouse.containsMouse ? 0.1 : 0.0)
                    z: -1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                
                scale: slideMouse.pressed ? 1.15 : (slideMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            }

            // === BRUSH PREVIEW TOOLTIP ===
            Item {
                id: previewTooltip
                
                visible: slideMouse.pressed || slideMouse.containsMouse
                opacity: visible ? 1.0 : 0.0
                
                // Bubble Size
                width: 70 * uiScale
                height: 70 * uiScale
                
                // Position above handle
                anchors.bottom: parent.top
                anchors.bottomMargin: 12 * uiScale
                anchors.horizontalCenter: (handle.x + handle.width/2) > parent.width/2 ? undefined : handle.horizontalCenter
                x: (handle.x + handle.width/2) > parent.width/2 ? (handle.x + handle.width/2 - width) : undefined
                // Wait, precise positioning:
                // Let's just center it on handle X, but clamp to avoid going off-screen?
                // For now, anchor to handle horizontalCenter is fine as track has margins.
                anchors.horizontalCenter: handle.horizontalCenter
                
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // Bubble Background
                Rectangle {
                    anchors.fill: parent
                    radius: 12 * uiScale
                    color: "#cc1a1a1e"
                    border.color: "#333"
                    border.width: 1
                    
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
                }

                // Content
                Item {
                    anchors.fill: parent; anchors.margins: 6 * uiScale
                    
                    Image {
                        id: tipImg
                        anchors.centerIn: parent
                        source: root.brushTipSource
                        visible: status === Image.Ready && root.brushTipSource !== ""
                        
                        property real sizeFactor: (root.previewType === "size") ? Math.max(0.2, root.value) : 0.7
                        width: parent.width * sizeFactor
                        height: parent.height * sizeFactor
                        
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        smooth: true
                        
                        opacity: (root.previewType === "opacity") ? root.value : 1.0
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: root.brushColor
                        }
                    }
                    
                    // Fallback Circle
                    Rectangle {
                        anchors.centerIn: parent
                        visible: tipImg.status !== Image.Ready || root.brushTipSource === ""
                        
                        property real sizeFactor: (root.previewType === "size") ? Math.max(0.2, root.value) : 0.7
                        width: parent.width * sizeFactor
                        height: width
                        radius: width/2
                        color: root.brushColor
                        opacity: (root.previewType === "opacity") ? root.value : 1.0
                    }
                    
                    // Percentage Text
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(root.value * 100)
                        color: "white"
                        font.pixelSize: 10 * uiScale
                        font.bold: true
                        style: Text.Outline
                        styleColor: "black"
                    }
                }
                
                // Arrow (Pointing Down)
                Rectangle {
                    width: 8; height: 8; rotation: 45
                    color: "#cc1a1a1e"
                    border.color: "#333"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -4
                    z: -1
                }
            }

            MouseArea {
                id: slideMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onPositionChanged: {
                    if (pressed) {
                        var val = mouseX / width
                        val = Math.max(0.0, Math.min(1.0, val))
                        root.value = val
                    }
                }
                onPressed: positionChanged(mouse)
            }
        }
    }
}
