import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ArtFlow 1.0

Item {
    id: studioLayout

    // --- PROPS ---
    property var mainCanvas: null
    property var canvasPage: null
    property var toolsModel: null
    property color accentColor: "#6366f1"
    property bool isProjectActive: false
    property bool isZenMode: false

    signal switchToEssential()

    visible: isProjectActive && !isZenMode

    // --- MANAGER ---
    StudioPanelManager {
        id: panelManager
    }

    // --- FLOATING PANELS LAYER ---
    Item {
        id: floatingLayer
        anchors.fill: parent
        z: 2000 // Above everything except tooltips/menus
        
        Repeater {
            model: panelManager.floatingModel
            delegate: FloatingPanel {
                x: model.x !== undefined ? model.x : (parent.width - width)/2
                y: model.y !== undefined ? model.y : (parent.height - height)/2
                panelId: model.panelId
                title: model.name
                contentSource: model.source
                
                onCloseRequested: {
                    // Default logic for close: dock back to left or right? Or just hide?
                    // Let's dock back to left if brushes/settings, right if color/layers
                    if (panelId === "brushes" || panelId === "settings") panelManager.movePanel(panelId, "left")
                    else panelManager.movePanel(panelId, "right")
                }
                
                onDragReleased: (gx, gy) => {
                    // check if over dock
                    var leftRect = Qt.rect(leftIconBar.x, leftIconBar.y, leftIconBar.width + (leftDock.width > 0 ? leftDock.width : 0), leftIconBar.height)
                    var rightRect = Qt.rect(rightIconBar.x - (rightDock.width > 0 ? rightDock.width : 0), rightIconBar.y, rightDock.width + rightIconBar.width, rightIconBar.height)
                    
                    var localPos = mapFromGlobal(gx, gy)
                    
                    if (gx < 60) { // Simple check for left edge
                        panelManager.movePanel(panelId, "left")
                    } else if (gx > studioLayout.width - 60) { // Right edge
                        panelManager.movePanel(panelId, "right")
                    }
                    
                    // Update model position if still floating
                    // ListModel doesn't auto-bind back to property x,y?
                    // Only if we modify the model.
                    // model.x = x; model.y = y // Doesn't persist if not explicit.
                }
            }
        }
    }

    // --- DRAG GHOST ---
    Rectangle {
        id: dragGhost
        width: 250; height: 32
        color: "#333"
        opacity: 0.8
        visible: false
        z: 3000
        property string currentPanelId: ""
        
        Text {
            anchors.centerIn: parent
            text: "Moving Panel..."
            color: "white"
        }
        
        function startDrag(panelId, gx, gy) {
            currentPanelId = panelId
            visible = true
            var local = mapFromGlobal(gx, gy)
            x = local.x - width/2
            y = local.y - height/2
        }
        
        function updateDrag(gx, gy) {
            var local = mapFromGlobal(gx, gy)
            x = local.x - width/2
            y = local.y - height/2
        }
        
        function endDrag(gx, gy) {
            visible = false
            // Check drop zones
            // If dropped in center -> Float
            // If dropped on same dock -> Do nothing (reorder TBD)
            // If dropped on other dock -> Move
            
            if (gx > 100 && gx < studioLayout.width - 100) {
                // Float
                panelManager.movePanelToFloat(currentPanelId, x, y)
            } else if (gx <= 100) {
                panelManager.movePanel(currentPanelId, "left")
            } else if (gx >= studioLayout.width - 100) {
                panelManager.movePanel(currentPanelId, "right")
            }
        }
    }
    
    // --- TOP BAR ---
    Rectangle {
        id: studioInfoBar
        width: parent.width; height: 32
        color: "#0a0a0d"
        z: 950
        
        Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: "#1a1a1e" }
        
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
            spacing: 8
            
            // Project Info
            Text {
                text: mainCanvas ? (mainCanvas.currentProjectName || "Untitled") : "Untitled"
                color: "#555"; font.pixelSize: 10; font.weight: Font.Medium
            }
            Item { width: 8 }
            Text {
                text: mainCanvas ? Math.round((mainCanvas.zoomLevel || 1.0) * 100) + "%" : "100%"
                color: "#444"; font.pixelSize: 10; font.family: "monospace"
            }
            Item { width: 4 }
            Text {
                text: mainCanvas ? (mainCanvas.canvasWidth || 1920) + " × " + (mainCanvas.canvasHeight || 1080) : "1920 × 1080"
                color: "#444"; font.pixelSize: 10; font.family: "monospace"
            }
            
            Item { Layout.fillWidth: true }
            
            // Undo/Redo
            Row {
                spacing: 2
                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: undoMa.containsMouse ? "#1c1c20" : "transparent"
                    Text { text: "↶"; color: "#666"; font.pixelSize: 14; anchors.centerIn: parent }
                    MouseArea { id: undoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mainCanvas) mainCanvas.undo() }
                }
                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: redoMa.containsMouse ? "#1c1c20" : "transparent"
                    Text { text: "↷"; color: "#666"; font.pixelSize: 14; anchors.centerIn: parent }
                    MouseArea { id: redoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mainCanvas) mainCanvas.redo() }
                }
            }
            
            // Mode switch
            Rectangle {
                width: 60; height: 22; radius: 11
                color: essMa.containsMouse ? accentColor : "#1c1c20"
                border.color: accentColor; border.width: 0.5
                Text {
                    text: "Essential"; anchors.centerIn: parent
                    color: essMa.containsMouse ? "#fff" : "#888"
                    font.pixelSize: 9; font.weight: Font.Bold
                }
                MouseArea {
                    id: essMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: studioLayout.switchToEssential()
                }
            }
        }
    }

    // --- MAIN CONTENT ROW ---
    RowLayout {
        anchors.top: studioInfoBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0
        
        // --- LEFT DOCK ---
        SideIconBar {
            id: leftIconBar
            Layout.fillHeight: true
            panelModel: panelManager.leftDockModel
            activePanelId: panelManager.activeLeftPanel
            onPanelSelected: (id) => panelManager.toggleLeftPanel(id)
        }
        
        DockContainer {
            id: leftDock
            Layout.fillHeight: true
            dockSide: "left"
            manager: panelManager
            isCollapsed: panelManager.leftCollapsed
            currentPanelModel: activeLeftItem
            onToggleCollapse: panelManager.toggleLeftPanel(panelManager.activeLeftPanel)
            
            onPanelDragStarted: (pid, gx, gy) => dragGhost.startDrag(pid, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
        
        // Connecting Model correctly:
        // DockContainer needs the actual model DATA for the active panel.
        // Let's bind it simpler:
        property var activeLeftItem: {
            var m = panelManager.leftDockModel
            for(var i=0; i<m.count; i++) if(m.get(i).panelId === panelManager.activeLeftPanel) return m.get(i)
            return null
        }
        
        // Re-declaring DockContainer with correct binding

        
        // --- TOOLBAR (Canvas Tools) ---
        // Keeping the vertical toolbar next to canvas
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            color: "#0a0a0d"
            z: 100
            
            Rectangle { width: 1; height: parent.height; anchors.right: parent.right; color: "#1a1a1e" }
             
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 4
                spacing: 2
                
                Repeater {
                    model: studioLayout.toolsModel
                    delegate: Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        radius: 6
                        color: (canvasPage && index === canvasPage.activeToolIdx) ? accentColor : (hoverMa.containsMouse ? "#1c1c20" : "transparent")
                        
                        Image {
                            source: "image://icons/" + model.icon
                            width: 18; height: 18; anchors.centerIn: parent
                            opacity: (canvasPage && index === canvasPage.activeToolIdx) ? 1.0 : 0.6
                        }
                        
                        MouseArea {
                            id: hoverMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (canvasPage) {
                                    canvasPage.activeToolIdx = index
                                    canvasPage.activeSubToolIdx = 0 // reset subtool
                                    if(mainCanvas) mainCanvas.currentTool = model.name
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // --- CENTER CANVAS ---
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            // Canvas is normally behind this layout in main_pro.qml, 
            // but StudioCanvasLayout sits ON TOP of canvasPage?
            // Check main_pro.qml structure.
            // main_pro.qml: 
            // CanvasPage { id: canvasPage ... }
            // StudioCanvasLayout { id: studioModeUI ... visible: isStudioMode }
            // So StudioLayout is an overlay.
            // But we need a "hole" for the canvas if it's an overlay?
            // OR StudioLayout *contains* the canvas view?
            // In main_pro: StudioCanvasLayout acts as UI overlay. The CanvasPage is below it.
            // So we just leave this space transparent so CanvasPage is visible?
            // Yes.
            Rectangle { anchors.fill: parent; color: "transparent" }
        }
        
        // --- RIGHT DOCK ---
        DockContainer {
            id: rightDock
            Layout.fillHeight: true
            dockSide: "right"
            manager: panelManager
            isCollapsed: panelManager.rightCollapsed
            
            property var activeRightItem: {
                 var m = panelManager.rightDockModel
                 for(var i=0; i<m.count; i++) if(m.get(i).panelId === panelManager.activeRightPanel) return m.get(i)
                 return null
            }
            
            currentPanelModel: activeRightItem
            onToggleCollapse: panelManager.toggleRightPanel(panelManager.activeRightPanel)
            
            onPanelDragStarted: (pid, gx, gy) => dragGhost.startDrag(pid, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
        
        SideIconBar {
            id: rightIconBar
            Layout.fillHeight: true
            panelModel: panelManager.rightDockModel
            activePanelId: panelManager.activeRightPanel
            onPanelSelected: (id) => panelManager.toggleRightPanel(id)
        }
    }
}
