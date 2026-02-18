import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    property string label: ""
    property real value: 0.0
    property string previewType: "" // "size", "opacity"
    property bool previewOnRight: false
    property color accentColor: "#6366f1" // Default Indigo
    
    implicitWidth: 60 * uiScale
    implicitHeight: 180 * uiScale
    
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0
    
    // Main Container
    Item {
        anchors.fill: parent
        anchors.topMargin: 5 * uiScale
        anchors.bottomMargin: 10 * uiScale

        // Slider Logic Area (Hitbox)
        Item {
            id: trackArea
            width: 30 * uiScale
            height: parent.height - (30 * uiScale)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            // Background Track (Premium Etched/Glass look)
            Rectangle {
                id: trackBg
                width: 6 * uiScale
                height: parent.height
                radius: 3 * uiScale
                anchors.centerIn: parent
                color: Qt.rgba(0.1, 0.1, 0.11, 0.8)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                clip: true // ⇠ THIS FIXES THE LEAKING ISSUES

                // Progress Fill (Inside the clipped background)
                Rectangle {
                    width: parent.width
                    height: parent.height * root.value
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(root.accentColor, 1.2) } 
                        GradientStop { position: 1.0; color: root.accentColor } 
                    }
                    
                    // Subtle inner shine for the fill
                    Rectangle {
                        anchors.fill: parent
                        anchors.rightMargin: parent.width * 0.5
                        color: "white"
                        opacity: 0.1
                    }
                }
            }

            // The Premium Handle (Pill Style)
            Rectangle {
                id: handle
                width: 24 * uiScale
                height: 12 * uiScale
                radius: 6 * uiScale
                color: "#ffffff"
                
                // Position based on value (Inverted for vertical)
                y: parent.height * (1.0 - root.value) - height/2
                anchors.horizontalCenter: parent.horizontalCenter

                // Subtle shadow
                layer.enabled: true
                
                // Inner Detail (A small line)
                Rectangle {
                    width: 10 * uiScale; height: 2 * uiScale; radius: 1
                    color: slideMouse.pressed ? "white" : root.accentColor
                    anchors.centerIn: parent
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Handle Glow on Interaction
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 12; height: parent.height + 12
                    radius: 12 * uiScale
                    color: root.accentColor
                    opacity: slideMouse.pressed ? 0.2 : (slideMouse.containsMouse ? 0.1 : 0.0)
                    z: -1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                scale: slideMouse.pressed ? 1.15 : (slideMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            }

            // Value Tooltip (Clean and minimal)
            Rectangle {
                visible: slideMouse.pressed || slideMouse.containsMouse
                opacity: visible ? 1.0 : 0.0
                width: 38 * uiScale; height: 22 * uiScale
                radius: 6 * uiScale
                color: "#1a1a1e"
                border.color: "#333"
                anchors.right: parent.left
                anchors.rightMargin: 12 * uiScale
                anchors.verticalCenter: handle.verticalCenter
                
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: Math.round(root.value * 100) + "%"
                    color: "white"
                    font.pixelSize: 10 * uiScale
                    font.bold: true
                }
                
                // Little arrow pointing to handle
                Rectangle {
                    width: 6; height: 6; rotation: 45
                    color: "#1a1a1e"
                    border.color: "#333"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: -3
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
                        var val = 1.0 - (mouseY / height)
                        val = Math.max(0.0, Math.min(1.0, val))
                        root.value = val
                    }
                }
                onPressed: positionChanged(mouse)
            }
        }

        // Label (Bottom)
        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: slideMouse.containsMouse || slideMouse.pressed ? "white" : "#888"
            font.pixelSize: 10 * uiScale
            font.letterSpacing: 0.5
            font.capitalization: Font.AllUppercase
            font.weight: Font.DemiBold
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
