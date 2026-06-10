import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    // Props
    property var panelModel: null // ListModel
    property bool isCollapsed: true
    property int iconSize: 18
    property color accentColor: "#6366f1"
    property string dockSide: "left"
    
    signal toggleDock(string panelId)
    signal reorder(int sourceIdx, int targetIdx, string mode)
    
    width: 34
    color: mainWindow ? mainWindow.colorPanel : "#0c0c0f" // Ultra-dark
    
    // Border
    Rectangle {
        width: 1; height: parent.height
        anchors.left: root.dockSide.indexOf("right") !== -1 ? parent.left : undefined
        anchors.right: root.dockSide.indexOf("left") !== -1 ? parent.right : undefined
        color: mainWindow ? mainWindow.colorBorder : "#1c1c1e"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        spacing: 0
        
        Repeater {
            model: root.panelModel
            
            delegate: Item {
                id: delegateRoot
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34 + (isGroupLast ? 8 : 0) // Spacing at end of groups
                Layout.alignment: Qt.AlignHCenter
                
                property bool isActive: (model.visible !== undefined ? model.visible : true) && !root.isCollapsed
                property bool isHovered: ma.containsMouse || dropArea.containsDrag
                
                property string myGroup: model.groupId !== undefined ? model.groupId : ""
                property bool isGroupFirst: index === 0 || (myGroup === "" || root.panelModel.get(index - 1).groupId !== myGroup)
                property bool isGroupLast: index === root.panelModel.count - 1 || (myGroup === "" || root.panelModel.get(index + 1).groupId !== myGroup)
                
                property bool customDragging: false
                z: customDragging ? 2000 : 1
                
                // Actual visual button container
                Item {
                    width: 28; height: 28
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // Subtle background highlight for active or hover states
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : (isHovered ? (mainWindow && !mainWindow.isDark ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(255, 255, 255, 0.08)) : "transparent")
                        border.color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : "transparent"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Active indicator line adjacent to the dock!
                    Rectangle {
                        visible: isActive
                        width: 2; height: 16
                        radius: 1
                        color: accentColor
                        anchors.left: root.dockSide.indexOf("right") !== -1 ? parent.left : undefined
                        anchors.right: root.dockSide.indexOf("left") !== -1 ? parent.right : undefined
                        anchors.leftMargin: root.dockSide.indexOf("right") !== -1 ? -3 : 0
                        anchors.rightMargin: root.dockSide.indexOf("left") !== -1 ? -3 : 0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    // Icon
                    Image {
                        source: mainWindow ? mainWindow.iconPath(model.icon) : ("image://icons/" + model.icon)
                        width: root.iconSize; height: root.iconSize
                        anchors.centerIn: parent
                        opacity: customDragging ? 0.3 : (isActive ? 1.0 : (isHovered ? 0.95 : 0.65))
                        mipmap: true; smooth: true
                        sourceSize: Qt.size(32, 32) // Render at crisp 32x32 source
                        
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                // Spacing indicator bar at bottom of group
                Rectangle {
                    width: 14; height: 1
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#1c1c1f"
                    visible: isGroupLast && index !== root.panelModel.count - 1
                }
                
                DropArea {
                    id: dropArea
                    anchors.fill: parent
                    keys: ["sidebarIcon"]
                    
                    onDropped: (drop) => {
                        if (drop.source.dockSide !== root.dockSide) {
                            drop.accepted = false
                            return
                        }
                        
                        var sourceIdx = drop.source.modelIndex
                        if (sourceIdx === index) {
                            drop.accept()
                            return
                        }
                        
                        var dy = drop.y / height
                        if (dy < 0.25) root.reorder(sourceIdx, index, "before")
                        else if (dy > 0.75) root.reorder(sourceIdx, index, "after")
                        else root.reorder(sourceIdx, index, "group")
                        
                        drop.accept()
                    }
                    
                    // Drop Hint Visuals
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4; radius: 6
                        color: "transparent"; border.color: accentColor; border.width: 1
                        visible: dropArea.containsDrag && (dropArea.drag.y > height * 0.25 && dropArea.drag.y < height * 0.75)
                    }
                    Rectangle {
                        width: 24; height: 2; color: accentColor; anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; visible: dropArea.containsDrag && dropArea.drag.y <= height * 0.25
                    }
                    Rectangle {
                        width: 24; height: 2; color: accentColor; anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom; visible: dropArea.containsDrag && dropArea.drag.y >= height * 0.75
                    }
                }
                
                ToolTip {
                    id: sideTooltip
                    visible: isHovered && !customDragging
                    text: model.name || "Panel"
                    delay: 500
                    x: root.dockSide.indexOf("right") !== -1 ? -width - 4 : root.width + 4
                    y: (parent.height - height) / 2
                    background: Rectangle { color: "#1e1e24"; border.color: "#3a3a3d"; radius: 6 }
                    contentItem: Text { text: sideTooltip.text; color: "#f0f0f5"; font.pixelSize: 12; font.weight: Font.Medium }
                }
                
                // Ghost item when dragging
                Rectangle {
                    id: ghostPanel
                    visible: customDragging
                    width: 40; height: 40
                    color: "#161619"; border.color: accentColor; border.width: 1
                    radius: 10; opacity: 0.9 // Floating above
                    x: customDragging ? (ma.mouseX - width/2) : 0
                    y: customDragging ? (ma.mouseY - height/2) : 0
                    Image { source: mainWindow ? mainWindow.iconPath(model.icon) : ("image://icons/" + model.icon); width: root.iconSize; height: root.iconSize; anchors.centerIn: parent; mipmap: true; smooth: true; opacity: 1.0; sourceSize: Qt.size(48, 48) }
                    
                    // Expose properties for DropArea's onDropped
                    property int modelIndex: index
                    property string dockSide: root.dockSide
                    property string panelId: model.panelId

                    Drag.active: customDragging
                    Drag.source: ghostPanel
                    Drag.keys: ["sidebarIcon"]
                    Drag.hotSpot.x: width/2; Drag.hotSpot.y: height/2
                }
                
                Timer {
                    id: dragCleanup
                    interval: 100
                    onTriggered: customDragging = false
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    
                    property point startPos
                    property bool held: false
                    
                    onPressed: (mouse) => { held = true; startPos = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: (mouse) => {
                        if (!pressed) return
                        if (held && !customDragging && (Math.abs(mouse.x - startPos.x) > 12 || Math.abs(mouse.y - startPos.y) > 12)) {
                            customDragging = true
                        }
                    }
                    onReleased: {
                        if (customDragging) {
                            ghostPanel.Drag.drop()
                            dragCleanup.start()
                        } else {
                            root.toggleDock(model.panelId)
                        }
                        held = false
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true } // Spacer
    }
}
