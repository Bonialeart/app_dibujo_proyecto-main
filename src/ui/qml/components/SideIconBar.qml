import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    // Props
    property var panelModel: null // ListModel
    property string activePanelId: ""
    property int iconSize: 24
    property color accentColor: "#6366f1"
    
    signal panelSelected(string panelId)
    
    width: 42
    color: "#0e0e11" // Dark sidebar background
    
    // Border
    Rectangle {
        width: 1; height: parent.height
        anchors.right: parent.right
        color: "#1a1a1e"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 4
        
        Repeater {
            model: root.panelModel
            
            delegate: Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignHCenter
                
                property bool isActive: root.activePanelId === model.panelId
                property bool isHovered: ma.containsMouse
                
                radius: 8
                color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : 
                       (isHovered ? "#1c1c1e" : "transparent")
                       
                border.color: isActive ? accentColor : "transparent"
                border.width: 1
                
                // Active indicator line
                Rectangle {
                    visible: isActive
                    width: 3; height: 16
                    radius: 1.5
                    color: accentColor
                    anchors.left: parent.left; anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                // Icon (Assuming image://icons/ provider)
                Image {
                    source: "image://icons/" + model.icon
                    width: root.iconSize; height: root.iconSize
                    anchors.centerIn: parent
                    opacity: isActive ? 1.0 : (isHovered ? 0.8 : 0.5)
                    mipmap: true
                    
                    // Simple tint behavior logic if needed, but SVGs usually have their own color
                    // or are monochrome. Assuming monochrome icons that can be colored?
                    // QtQuick.Effects could be used for ColorOverlay if needed.
                }
                
                // Tooltip
                ToolTip {
                    visible: isHovered
                    text: model.name
                    delay: 400
                    x: root.width + 4
                    y: (parent.height - height) / 2
                    
                    background: Rectangle {
                        color: "#252528"
                        border.color: "#333"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ddd"
                        font.pixelSize: 11
                    }
                }
                
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.panelSelected(model.panelId)
                }
            }
        }
        
        Item { Layout.fillHeight: true } // Spacer
    }
}
