import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    
    property string label: ""
    property string unit: ""
    property real value: 0.0 // 0-1 range usually
    property real displayValue: 0
    property int decimals: 0
    property color accent: "#6366f1"
    
    signal moved(real value)
    
    width: parent ? parent.width : 200
    height: 44
    
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0

    ColumnLayout {
        anchors.fill: parent
        spacing: 2 * uiScale
        
        // Header (Label & Value display)
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: root.label
                color: slideMouse.containsMouse || slideMouse.pressed ? "white" : "#aaa"
                font.pixelSize: 10 * uiScale
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
                font.capitalization: Font.AllUppercase
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: root.displayValue.toFixed(root.decimals) + root.unit
                color: slideMouse.pressed ? "white" : root.accent
                font.pixelSize: 11 * uiScale
                font.weight: Font.Bold
                font.family: "Monospace"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        
        // Interactive Slider Track Area
        Item {
            id: trackArea
            Layout.fillWidth: true
            Layout.preferredHeight: 20 * uiScale
            
            // Background Track (Glass/Etched look)
            Rectangle {
                id: trackBg
                width: parent.width
                height: 5 * uiScale
                radius: 2.5 * uiScale
                color: "#121215"
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                anchors.centerIn: parent
                clip: true
                
                // Progress Fill
                Rectangle {
                    width: Math.max(5 * uiScale, root.value * parent.width)
                    height: parent.height
                    radius: 2.5 * uiScale
                    
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.accent }
                        GradientStop { position: 1.0; color: Qt.lighter(root.accent, 1.25) }
                    }
                    
                    // Subtle inner highlight
                    Rectangle {
                        anchors.fill: parent
                        anchors.bottomMargin: parent.height * 0.5
                        color: "white"
                        opacity: 0.12
                    }
                }
            }
            
            // Slider Handle
            Rectangle {
                id: handle
                width: 12 * uiScale
                height: 12 * uiScale
                radius: 6 * uiScale
                color: "#ffffff"
                x: (parent.width - width) * root.value
                anchors.verticalCenter: parent.verticalCenter
                
                // Fine dark border for high contrast
                border.color: Qt.rgba(0, 0, 0, 0.15)
                border.width: 1
                
                // Internal Detail (Sleek inner dot)
                Rectangle {
                    width: 4 * uiScale
                    height: 4 * uiScale
                    radius: 2 * uiScale
                    color: slideMouse.pressed ? root.accent : "#888888"
                    anchors.centerIn: parent
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                // Glow on Interaction
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 10 * uiScale
                    height: parent.height + 10 * uiScale
                    radius: width / 2
                    color: root.accent
                    opacity: slideMouse.pressed ? 0.25 : (slideMouse.containsMouse ? 0.12 : 0.0)
                    z: -1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                // Micro-animation scale-up
                scale: slideMouse.pressed ? 1.25 : (slideMouse.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }
            
            // Floating Tooltip Value Bubble (Tracks the handle)
            Rectangle {
                id: tooltip
                visible: slideMouse.pressed || slideMouse.containsMouse
                opacity: visible ? 1.0 : 0.0
                width: Math.max(38 * uiScale, valText.contentWidth + 12 * uiScale)
                height: 20 * uiScale
                radius: 5 * uiScale
                color: "#e6141417"
                border.color: "#2e2e35"
                border.width: 1
                
                // Center on handle's X
                x: handle.x + (handle.width - width)/2
                anchors.bottom: handle.top
                anchors.bottomMargin: 8 * uiScale
                
                Behavior on opacity { NumberAnimation { duration: 150 } }
                
                Text {
                    id: valText
                    anchors.centerIn: parent
                    text: root.displayValue.toFixed(root.decimals) + root.unit
                    color: "white"
                    font.pixelSize: 9 * uiScale
                    font.weight: Font.Bold
                }
                
                // Arrow pointing down to handle
                Rectangle {
                    width: 5 * uiScale
                    height: 5 * uiScale
                    rotation: 45
                    color: "#e6141417"
                    border.color: "#2e2e35"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -3 * uiScale
                    z: -1
                }
            }
            
            // Hitbox & Interaction MouseArea
            MouseArea {
                id: slideMouse
                anchors.fill: parent
                anchors.margins: -4 * uiScale
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                function updateVal(mouse) {
                    var v = Math.max(0.0, Math.min(1.0, mouse.x / width))
                    root.moved(v)
                }
                
                onPressed: updateVal(mouse)
                onPositionChanged: if(pressed) updateVal(mouse)
            }
        }
    }
}
