// ============================================================================
// DOCK AREA - Container for docked panels in Studio Mode
// Supports tab stacking and resize handles
// ============================================================================

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dockArea
    
    // ============================================================================
    // PROPERTIES
    // ============================================================================
    
    property string areaId: "right" // "left", "right", "bottom"
    property bool isVertical: areaId === "left" || areaId === "right"
    property color accentColor: "#6366f1"
    property var panelList: [] // Array of panel configs: {id, title, icon, component, visible}
    property int activeTabIndex: 0
    
    property real minSize: 200
    property real maxSize: 600
    
    // Signals
    signal panelTabClicked(int index)
    signal panelClosed(string panelId)
    signal panelFloated(string panelId)
    signal resized(real newSize)
    
    // ============================================================================
    // VISUAL
    // ============================================================================
    
    color: "#0c0c0f"
    visible: panelList.length > 0
    
    // ============================================================================
    // TAB BAR
    // ============================================================================
    
    Rectangle {
        id: tabBar
        width: parent.width
        height: panelList.length > 1 ? 28 : 0
        color: "#0e0e11"
        visible: panelList.length > 1
        z: 10
        
        // Bottom border
        Rectangle {
            width: parent.width; height: 1
            anchors.bottom: parent.bottom
            color: "#1a1a1e"
        }
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            
            Repeater {
                model: panelList.length
                
                Rectangle {
                    width: Math.min(110, (tabBar.width - 8) / panelList.length)
                    height: 22
                    radius: 4
                    color: index === activeTabIndex ? "#1c1c20" : (tabMouse.containsMouse ? "#15151a" : "transparent")
                    
                    // Active indicator  
                    Rectangle {
                        width: parent.width - 8
                        height: 2
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: accentColor
                        visible: index === activeTabIndex
                        radius: 1
                    }
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Text {
                            text: index < panelList.length ? panelList[index].icon : ""
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: index < panelList.length ? panelList[index].title : ""
                            color: index === activeTabIndex ? "#ddd" : "#666"
                            font.pixelSize: 10
                            font.weight: index === activeTabIndex ? Font.Medium : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: Math.min(70, parent.parent.width - 30)
                        }
                    }
                    
                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: activeTabIndex = index
                    }
                }
            }
        }
    }
    
    // ============================================================================
    // PANEL CONTENT STACK
    // ============================================================================
    
    Item {
        id: panelStack
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
    }
    
    // ============================================================================
    // RESIZE HANDLE
    // ============================================================================
    
    Rectangle {
        id: resizeHandle
        color: resizeHover.containsMouse || resizeHover.pressed ? accentColor : "#1a1a1e"
        opacity: resizeHover.containsMouse || resizeHover.pressed ? 0.8 : 1.0
        
        // Position based on dock side
        anchors.top: isVertical ? parent.top : undefined
        anchors.bottom: isVertical ? parent.bottom : parent.top
        anchors.left: areaId === "right" ? parent.left : (areaId === "bottom" ? parent.left : undefined)
        anchors.right: areaId === "left" ? parent.right : (areaId === "bottom" ? parent.right : undefined)
        
        width: isVertical ? 3 : undefined
        height: isVertical ? undefined : 3
        z: 100
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        MouseArea {
            id: resizeHover
            anchors.fill: parent
            anchors.margins: isVertical ? -3 : -3
            hoverEnabled: true
            cursorShape: isVertical ? Qt.SizeHorCursor : Qt.SizeVerCursor
            
            property real startPos
            property real startSize
            
            onPressed: (mouse) => {
                startPos = isVertical ? mouse.x + mapToGlobal(0,0).x : mouse.y + mapToGlobal(0,0).y
                startSize = isVertical ? dockArea.width : dockArea.height
            }
            
            onPositionChanged: (mouse) => {
                if (!pressed) return
                var currentPos = isVertical ? mouse.x + mapToGlobal(0,0).x : mouse.y + mapToGlobal(0,0).y
                var delta = currentPos - startPos
                
                // Invert direction for right/bottom docks
                if (areaId === "right") delta = -delta
                if (areaId === "bottom") delta = -delta
                
                var newSize = Math.max(minSize, Math.min(maxSize, startSize + delta))
                resized(newSize)
            }
        }
    }
}
