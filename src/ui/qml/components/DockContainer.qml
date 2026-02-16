import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    // Props
    property string dockSide: "left" // "left" or "right"
    property var manager: null // StudioPanelManager
    property var currentPanelModel: null // ListElement from manager model
    property int expandedWidth: 300
    property bool isCollapsed: true
    
    signal toggleCollapse()
    signal panelDragStarted(string panelId, real globalX, real globalY)
    signal panelDragUpdated(real globalX, real globalY)
    signal panelDragEnded(real globalX, real globalY)
    
    width: isCollapsed ? 0 : expandedWidth
    height: parent.height
    color: "#1c1c1e" // Panel background
    border.color: "#333"
    border.width: isCollapsed ? 0 : 1
    
    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    
    visible: width > 0
    clip: true
    
    // --- HEADER ---
    Rectangle {
        id: header
        width: parent.width
        height: 32
        color: "#252528"
        visible: !isCollapsed
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            
            // Drag Handle (Icon)
            Image {
                source: "image://icons/" + (currentPanelModel ? currentPanelModel.icon : "")
                width: 16; height: 16
                opacity: 0.7
            }
            
            Text {
                text: currentPanelModel ? currentPanelModel.name : "Panel"
                color: "#ddd"
                font.pixelSize: 12
                font.weight: Font.Medium
                Layout.fillWidth: true
            }
            
            // Collapse Button
            Rectangle {
                width: 20; height: 20; radius: 4
                color: "transparent"
                Text { 
                    text: root.dockSide === "left" ? "◀" : "▶"
                    color: "#888"
                    anchors.centerIn: parent 
                    font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleCollapse()
                }
            }
        }
        
        // Bottom border
        Rectangle {
            width: parent.width; height: 1
            anchors.bottom: parent.bottom
            color: "#1a1a1e"
        }
        
        // Component Drag logic would go here
        MouseArea {
            id: headerDrag
            anchors.fill: parent
            z: -1 // Behind buttons
            cursorShape: Qt.OpenHandCursor
            // Drag logic
            property point startPos
            property bool isDragging: false
            
            onPressed: (mouse) => { startPos = Qt.point(mouse.x, mouse.y); isDragging = false }
            
            onPositionChanged: (mouse) => {
                if (!pressed) return
                if (!isDragging && (Math.abs(mouse.x - startPos.x) > 5 || Math.abs(mouse.y - startPos.y) > 5)) {
                    isDragging = true
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    root.panelDragStarted(currentPanelModel.panelId, globalPos.x, globalPos.y)
                }
                if (isDragging) {
                     var globalPos = mapToGlobal(mouse.x, mouse.y)
                     root.panelDragUpdated(globalPos.x, globalPos.y)
                }
            }
            
            onReleased: (mouse) => {
                if (isDragging) {
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    root.panelDragEnded(globalPos.x, globalPos.y)
                    isDragging = false
                }
            }
        }
    }
    
    // --- CONTENT LOADER ---
    Loader {
        id: contentLoader
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        source: (currentPanelModel && !isCollapsed) ? currentPanelModel.source : ""
        
        onLoaded: {
            if (item && item.hasOwnProperty("targetCanvas")) {
                // Inject mainCanvas if available in context or parent
                // Trying to find mainCanvas in parent hierarchy
                // Assuming StudioCanvasLayout has it.
                // We can also pass it as a property to DockContainer
            }
        }
    }
    
    // --- RESIZER ---
    Rectangle {
        width: 4
        height: parent.height
        anchors.right: (dockSide === "left") ? parent.right : undefined
        anchors.left: (dockSide === "right") ? parent.left : undefined
        color: resizerMa.containsMouse || resizerMa.pressed ? "#6366f1" : "transparent"
        opacity: resizerMa.pressed ? 1 : 0
        
        MouseArea {
            id: resizerMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            onPositionChanged: (mouse) => {
                if (pressed) {
                     var dx = mouse.x // Simplified
                     if (dockSide === "left") root.expandedWidth = Math.max(200, root.expandedWidth + mouse.x)
                     else root.expandedWidth = Math.max(200, root.expandedWidth - mouse.x)
                }
            }
        }
    }
}
