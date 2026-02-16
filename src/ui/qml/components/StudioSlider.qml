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
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.label
                color: "#ccc"
                font.pixelSize: 11
                font.weight: Font.Medium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.displayValue.toFixed(root.decimals) + root.unit
                color: accent
                font.pixelSize: 11
                font.family: "Monospace"
            }
        }
        
        // Custom Slider Track
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 18
            
            // Track background
            Rectangle {
                width: parent.width; height: 4
                radius: 2
                color: "#1a1a1e"
                anchors.centerIn: parent
                
                // Active fill
                Rectangle {
                    width: Math.max(4, root.value * parent.width); height: parent.height
                    radius: 2
                    color: root.accent
                }
            }
            
            // Handle
            Rectangle {
                width: 12; height: 12; radius: 6
                color: "white"
                x: (parent.width - width) * root.value
                anchors.verticalCenter: parent.verticalCenter
                
                layer.enabled: true
                // Using simple shadow or border
                border.color: "#000"
                border.width: 1
            }
            
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                function updateVal(mouse) {
                    var v = Math.max(0, Math.min(1, mouse.x / width))
                    root.moved(v)
                }
                
                onPressed: updateVal(mouse)
                onPositionChanged: if(pressed) updateVal(mouse)
            }
        }
    }
}
