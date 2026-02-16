import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property var targetCanvas: null
    
    Rectangle {
        anchors.fill: parent
        color: "#1c1c1e"
        
        Text {
            text: "Navigator"
            color: "#666"
            anchors.centerIn: parent
            font.pixelSize: 14
        }
        
        // Placeholder for future mini-map implementation
        Rectangle {
            width: parent.width * 0.8
            height: width * 0.6
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 20
            color: "#252528"
            border.color: "#333"
            
            Text { text: "Preview"; color: "#444"; anchors.centerIn: parent }
        }
    }
}
