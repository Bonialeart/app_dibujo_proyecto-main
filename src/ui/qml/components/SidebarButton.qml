import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    property string iconName: ""
    property string label: ""
    property bool active: false
    property color accentColor: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    
    signal clicked()
    
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    radius: 12
    
    color: active ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12) : (hoverArea.containsMouse ? "#12ffffff" : "transparent")
    Behavior on color { ColorAnimation { duration: 200 } }
    
    // Left active indicator (subtle accent line)
    Rectangle {
        width: 3; height: 24; radius: 1.5
        anchors.left: parent.left; anchors.leftMargin: -2
        anchors.verticalCenter: parent.verticalCenter
        color: accentColor
        visible: active
        
        // Glow effect
        Rectangle {
            anchors.fill: parent; anchors.margins: -3
            radius: 5
            color: accentColor; opacity: 0.3
            visible: parent.visible
        }
    }
    
    Column {
        anchors.centerIn: parent
        spacing: 5
        
        Image {
            source: root.iconName ? "image://icons/" + root.iconName : ""
            width: 22; height: 22
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.active ? 1.0 : (hoverArea.containsMouse ? 0.7 : 0.45)
            mipmap: true
            fillMode: Image.PreserveAspectFit
            
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        Text {
            text: root.label
            color: root.active ? "#f0f0f5" : (hoverArea.containsMouse ? "#aaa" : "#666")
            font.pixelSize: 10
            font.weight: root.active ? Font.DemiBold : Font.Normal
            font.letterSpacing: 0.3
            anchors.horizontalCenter: parent.horizontalCenter
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
    
    // Scale animation on press
    scale: hoverArea.pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
