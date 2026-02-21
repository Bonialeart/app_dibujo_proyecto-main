import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    
    // Props
    property var panelModel: null // ListModel
    property bool isCollapsed: true
    property int iconSize: 22
    property color accentColor: "#6366f1"
    property string dockSide: "left"
    
    signal toggleDock(string panelId)
    signal reorder(int sourceIdx, int targetIdx, string mode)
    
    width: 48
    color: "#0c0c0f" // Ultra-dark
    
    // Border
    Rectangle {
        width: 1; height: parent.height
        anchors.right: parent.right
        color: "#1c1c1e"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        spacing: 0
        
        Repeater {
            model: root.panelModel
            
            delegate: Item {
                id: delegateRoot
                Layout.preferredWidth: 48
                Layout.preferredHeight: 40 + (isGroupLast ? 8 : 0) // Extra spacing only at the end of groups/singles
                Layout.alignment: Qt.AlignHCenter
                
                property bool isActive: (model.visible !== undefined ? model.visible : true) && !root.isCollapsed
                property bool isHovered: ma.containsMouse || dropArea.containsDrag
                
                property string myGroup: model.groupId !== undefined ? model.groupId : ""
                property bool isGroupFirst: index === 0 || (myGroup === "" || root.panelModel.get(index - 1).groupId !== myGroup)
                property bool isGroupLast: index === root.panelModel.count - 1 || (myGroup === "" || root.panelModel.get(index + 1).groupId !== myGroup)
                
                property bool customDragging: false
                z: customDragging ? 2000 : 1
                
                // Actual visual pill (Container)
                Item {
                    width: 40; height: parent.height - (isGroupLast ? 8 : 0) // Extra 8 at bottom of group
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true
                    
                    Rectangle {
                        width: parent.width
                        y: isGroupFirst ? 0 : -12
                        height: parent.height + (isGroupFirst ? 0 : 12) + (isGroupLast ? 0 : 12)
                        
                        radius: 12
                        
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.45) : (isHovered ? "#2a2a2f" : "#1e1e22") }
                            GradientStop { position: 1.0; color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : (isHovered ? "#222226" : "#161619") }
                        }
                               
                        border.color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : (isHovered ? "#3a3a3d" : "#2a2a2d")
                        border.width: 1
                    }

                    // Separator line between group items (only if NOT last) - subtle and modern
                    Rectangle {
                        width: 28; height: 1
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#1affffff"
                        visible: !isGroupLast
                    }
                    
                    // Active indicator line
                    Rectangle {
                        visible: isActive
                        width: 3; height: 24
                        radius: 1.5
                        color: accentColor
                        anchors.left: parent.left; anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        
                        layer.enabled: true
                        layer.effect: Qt.createQmlObject('import QtQuick.Effects; MultiEffect { blurEnabled: true; blur: 0.5 }', root)
                    }
                    
                    // Icon
                    Image {
                        source: "image://icons/" + model.icon
                        width: root.iconSize; height: root.iconSize
                        anchors.centerIn: parent
                        opacity: isDragging ? 0.3 : (isActive ? 1.0 : (isHovered ? 0.9 : 0.6))
                        mipmap: true; smooth: true
                        sourceSize: Qt.size(48, 48)
                    }
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
                    visible: isHovered && !customDragging
                    text: model.name || "Panel"
                    delay: 500
                    x: root.width + 4
                    y: (parent.height - height) / 2
                    background: Rectangle { color: "#1e1e24"; border.color: "#3a3a3d"; radius: 6 }
                    contentItem: Text { text: parent.text; color: "#f0f0f5"; font.pixelSize: 12; font.weight: Font.Medium }
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
                    Image { source: "image://icons/" + model.icon; width: root.iconSize; height: root.iconSize; anchors.centerIn: parent; mipmap: true; smooth: true; opacity: 1.0; sourceSize: Qt.size(48, 48) }
                    
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
