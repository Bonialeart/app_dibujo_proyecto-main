// ============================================================================
// DOCKABLE PANEL - Core Building Block for Studio Mode
// A panel that can be docked to edges, floated, tabbed, and resized
// ============================================================================

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dockPanel
    
    // ============================================================================
    // PUBLIC API
    // ============================================================================
    
    property string panelId: ""
    property string panelTitle: "Panel"
    property string panelIcon: "📄"
    property color accentColor: "#6366f1"
    
    // Docking state
    property string dockSide: "right" // "left", "right", "bottom", "float"
    property bool isDocked: dockSide !== "float"
    property bool isCollapsed: false
    
    // Size constraints
    property real minWidth: 220
    property real minHeight: 150
    property real preferredWidth: 300
    property real preferredHeight: 400
    
    // Content
    default property alias content: contentContainer.data
    
    // Signals
    signal closeRequested()
    signal floatRequested()
    signal dockRequested(string side)
    signal panelDragStarted(string panelId)
    signal panelDragEnded(string panelId, real globalX, real globalY)
    
    // ============================================================================
    // VISUAL DESIGN
    // ============================================================================
    
    width: isDocked ? parent.width : preferredWidth
    height: isCollapsed ? panelHeader.height : (isDocked ? preferredHeight : preferredHeight)
    
    color: "#0e0e11"
    border.color: "#1a1a1e"
    border.width: 0
    radius: isDocked ? 0 : 10
    clip: true
    
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    
    // ============================================================================
    // HEADER
    // ============================================================================
    
    Rectangle {
        id: panelHeader
        width: parent.width
        height: 30
        color: headerMouse.containsMouse ? "#18181c" : "#121215"
        z: 10
        
        // Subtle top border
        Rectangle {
            width: parent.width; height: 1
            color: "#1e1e22"
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 6
            spacing: 6
            
            // Panel Icon
            Text {
                text: panelIcon
                font.pixelSize: 12
                Layout.alignment: Qt.AlignVCenter
            }
            
            // Panel Title
            Text {
                text: panelTitle
                color: "#999"
                font.pixelSize: 11
                font.weight: Font.Medium
                font.letterSpacing: 0.3
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
            }
            
            // Collapse button
            Rectangle {
                width: 18; height: 18; radius: 4
                color: collapseMouse.containsMouse ? "#2a2a2e" : "transparent"
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    text: isCollapsed ? "▸" : "▾"
                    color: "#666"
                    font.pixelSize: 10
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    id: collapseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: isCollapsed = !isCollapsed
                }
            }
            
            // Float/Dock toggle
            Rectangle {
                width: 18; height: 18; radius: 4
                color: floatMouse.containsMouse ? "#2a2a2e" : "transparent"
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    text: isDocked ? "⊞" : "⊟"
                    color: "#666"
                    font.pixelSize: 11
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    id: floatMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isDocked) floatRequested()
                        else dockRequested(dockSide === "float" ? "right" : dockSide)
                    }
                }
            }
            
            // Close button
            Rectangle {
                width: 18; height: 18; radius: 4
                color: closeMouse.containsMouse ? "#ff3b30" : "transparent"
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    text: "×"
                    color: closeMouse.containsMouse ? "#fff" : "#666"
                    font.pixelSize: 13
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: closeRequested()
                }
            }
        }
        
        // Drag area for the header
        MouseArea {
            id: headerMouse
            anchors.fill: parent
            anchors.rightMargin: 70 // Don't overlap buttons
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
            
            property point dragStart
            property bool dragging: false
            
            onPressed: (mouse) => {
                dragStart = Qt.point(mouse.x, mouse.y)
                dragging = false
            }
            
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var dist = Math.sqrt(Math.pow(mouse.x - dragStart.x, 2) + Math.pow(mouse.y - dragStart.y, 2))
                    if (dist > 5 && !dragging) {
                        dragging = true
                        panelDragStarted(panelId)
                    }
                    if (dragging && !isDocked) {
                        var delta = Qt.point(mouse.x - dragStart.x, mouse.y - dragStart.y)
                        dockPanel.x += delta.x
                        dockPanel.y += delta.y
                    }
                }
            }
            
            onReleased: (mouse) => {
                if (dragging) {
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    panelDragEnded(panelId, globalPos.x, globalPos.y)
                }
                dragging = false
            }
            
            // Double click to toggle collapse
            onDoubleClicked: isCollapsed = !isCollapsed
        }
    }
    
    // ============================================================================
    // CONTENT AREA
    // ============================================================================
    
    Item {
        id: contentContainer
        anchors.top: panelHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !isCollapsed
        clip: true
    }
}
