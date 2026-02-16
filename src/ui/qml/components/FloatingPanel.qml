import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Rectangle {
    id: root
    
    property string panelId: ""
    property string title: "Panel"
    property string contentSource: ""
    
    signal closeRequested()
    signal dragReleased(real globalX, real globalY)
    
    width: 300; height: 400
    color: "#1c1c1e"
    border.color: "#333"
    border.width: 1
    radius: 8
    
    // Shadow effect
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 20
        shadowColor: "#80000000"
        shadowVerticalOffset: 4
    }
    
    // Header
    Rectangle {
        id: header
        width: parent.width
        height: 32
        color: "#252528"
        radius: 8
        
        // Only top corners rounded
        Rectangle {
            width: parent.width; height: 10
            anchors.bottom: parent.bottom
            color: parent.color
        }
        
        RowLayout {
            anchors.fill: parent; anchors.margins: 8
            spacing: 8
            
            Text {
                text: root.title
                color: "#ddd"
                font.pixelSize: 12
                font.weight: Font.Medium
                Layout.fillWidth: true
            }
            
            // Close / Dock
            Text {
                text: "✕"
                color: "#888"
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeRequested()
                }
            }
        }
        
        MouseArea {
            id: dragArea
            anchors.fill: parent
            z: -1
            property point lastPos
            onPressed: (mouse) => { lastPos = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: (mouse) => {
                if(pressed) {
                    var dx = mouse.x - lastPos.x
                    var dy = mouse.y - lastPos.y
                    root.x += dx
                    root.y += dy
                }
            }
            onReleased: (mouse) => {
                var globalPos = mapToGlobal(mouse.x, mouse.y)
                root.dragReleased(globalPos.x, globalPos.y)
            }
        }
    }
    
    // Content
    Loader {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: resizerHandle.top
        source: root.contentSource
    }
    
    // Resizer
    Rectangle {
        id: resizerHandle
        width: parent.width
        height: 8
        anchors.bottom: parent.bottom
        color: "transparent"
        
        // Corner grip
        Image {
            source: "image://icons/resize_grip.svg" // Placeholder
            anchors.right: parent.right; anchors.bottom: parent.bottom
            width: 12; height: 12
            visible: false // Use custom drawing or image
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor // Should be diag but simple for now
            property point lastPos
            onPressed: (mouse) => { lastPos = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: (mouse) => {
                if(pressed) {
                    var dy = mouse.y - lastPos.y
                    root.height = Math.max(200, root.height + dy)
                }
            }
        }
    }
}
