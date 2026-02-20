import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Rectangle {
    id: root
    
    property string panelId: ""
    property string title: "Panel"
    property string iconName: ""
    property string contentSource: ""
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    signal closeRequested()
    signal dragMoved(real globalX, real globalY)
    signal dragReleased(real globalX, real globalY)
    
    width: 320; height: 450
    color: "#121215" // Deep OLED dark
    radius: 12
    
    border.color: "#30ffffff"
    border.width: 1
    
    // Smooth Drop Shadow
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 30
        shadowColor: "#bb000000"
        shadowVerticalOffset: 15
        shadowOpacity: 0.6
    }
    
    // --- GLASS HEADER ---
    Rectangle {
        id: header
        width: parent.width; height: 38
        color: "#18181c"
        radius: 12
        
        // Square bottom corners to blend with content
        Rectangle {
            width: parent.width; height: 12
            anchors.bottom: parent.bottom
            color: parent.color
        }
        
        // Glow line under header
        Rectangle {
            width: parent.width; height: 1
            anchors.bottom: parent.bottom
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8
            spacing: 8
            
            // Drag grip dots
            Row {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: 3
                    Rectangle { width: 3; height: 3; radius: 1.5; color: hoverHeader.containsMouse ? "#666" : "#444" }
                }
            }
            
            // Icon (optional, if provided)
            Image {
                visible: root.iconName !== ""
                source: "image://icons/" + root.iconName
                width: 16; height: 16
                opacity: 0.8
                sourceSize: Qt.size(32, 32)
            }
            
            Text {
                text: root.title
                color: "#eeeeef"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            
            // Close Button
            Rectangle {
                width: 24; height: 24; radius: 6
                color: closeHover.containsMouse ? "#2a2a2d" : "transparent"
                Text {
                    text: "✕"
                    color: closeHover.containsMouse ? "white" : "#888"
                    font.pixelSize: 12
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }
        
        MouseArea {
            id: hoverHeader
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            
            drag.target: root
            drag.axis: Drag.XAndYAxis
            
            onPositionChanged: {
                if (drag.active) {
                    var globalPos = mapToGlobal(mouseX, mouseY)
                    root.dragMoved(globalPos.x, globalPos.y)
                }
            }
            
            onReleased: {
                var globalPos = mapToGlobal(mouseX, mouseY)
                root.dragReleased(globalPos.x, globalPos.y)
            }
        }
    }
    
    // --- CONTENT ---
    Loader {
        id: panelLoader
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: resizerHandle.top
        source: root.contentSource
        clip: true
        
        onLoaded: {
            if (item && item.hasOwnProperty("targetCanvas")) {
                item.targetCanvas = Qt.binding(function() { return root.targetCanvas })
            }
            if (item && item.hasOwnProperty("colorAccent")) {
                item.colorAccent = root.accentColor
            }
        }
    }
    
    // Inner border to clean up loaded UI edges
    Rectangle {
        anchors.fill: panelLoader
        color: "transparent"
        border.color: "#0a000000"
        border.width: 1
    }
    
    // --- RESIZER ---
    Rectangle {
        id: resizerHandle
        width: parent.width; height: 14
        anchors.bottom: parent.bottom
        color: "transparent"
        
        // Corner grip lines
        Item {
            anchors.right: parent.right; anchors.bottom: parent.bottom
            width: 14; height: 14
            anchors.margins: 2
            opacity: resizerMa.containsMouse ? 1.0 : 0.4
            
            Rectangle { width: 2; height: 10; x: 8; y: 2; radius: 1; color: "#555"; rotation: -45 }
            Rectangle { width: 2; height: 6; x: 12; y: 6; radius: 1; color: "#555"; rotation: -45 }
        }
        
        MouseArea {
            id: resizerMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            
            property point startPos
            property real startHeight
            property real startWidth
            
            onPressed: (mouse) => { 
                startPos = Qt.point(mouse.x, mouse.y) 
                startHeight = root.height
                startWidth = root.width
            }
            onPositionChanged: (mouse) => {
                if(pressed) {
                    var dy = mouse.y - startPos.y
                    var dx = mouse.x - startPos.x
                    root.height = Math.max(250, root.height + dy)
                    root.width = Math.max(220, root.width + dx)
                }
            }
        }
    }
}
