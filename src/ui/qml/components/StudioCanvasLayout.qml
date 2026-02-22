import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import ArtFlow 1.0

Item {
    id: studioLayout

    // --- PROPS ---
    property var mainCanvas: null
    property var canvasPage: null
    property var toolsModel: null
    property var subToolBar: null
    property color accentColor: (typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#6366f1"
    property bool isProjectActive: false
    property bool isZenMode: false

    signal switchToEssential()

    visible: isProjectActive && !isZenMode
    
    // Catch icon drags from SideIconBar that are dropped outside
    DropArea {
        anchors.fill: parent
        keys: ["sidebarIcon"]
        z: -100 // Behind everything else, so specific docks catch drops first!

        onPositionChanged: (drop) => {
            var g = mapToGlobal(drop.x, drop.y)
            studioLayout.updateDragZones(g.x, g.y)
        }
        
        onExited: {
            leftDock.isDragHover = false; leftDock2.isDragHover = false
            rightDock.isDragHover = false; rightDock2.isDragHover = false
        }
        
        onDropped: (drop) => {
            var g = mapToGlobal(drop.x, drop.y)
            var res = studioLayout.updateDragZones(g.x, g.y)
            
            leftDock.isDragHover = false; leftDock2.isDragHover = false
            rightDock.isDragHover = false; rightDock2.isDragHover = false
            
            if (res) {
                panelManager.movePanel(drop.source.panelId, res.dock, res.mode === "group" ? res.modelIndex : res.index, res.mode)
            } else {
                panelManager.movePanelToFloat(drop.source.panelId, drop.x, drop.y)
            }
            drop.accept()
        }
    }
    
    function updateDragZones(gx, gy) {
        // Find visible widths safely
        var lw1 = leftIconBar.width + leftDock.width;
        var lw2 = (leftIconBar2.visible ? leftIconBar2.width : 0) + leftDock2.width;
        var rw1 = rightIconBar.width + rightDock.width;
        var rw2 = (rightIconBar2.visible ? rightIconBar2.width : 0) + rightDock2.width;
        
        // Define dynamic thresholds based on collapsed states
        var zL1 = leftIconBar.width + (panelManager.leftCollapsed ? 40 : leftDock.expandedWidth/2) + 20;
        var zL2 = lw1 + (leftIconBar2.visible ? leftIconBar2.width : 20) + (panelManager.leftCollapsed2 ? 40 : leftDock2.expandedWidth) + 30;
        
        var zR1 = studioLayout.width - rightIconBar.width - (panelManager.rightCollapsed ? 40 : rightDock.expandedWidth/2) - 20;
        var zR2 = studioLayout.width - rw1 - (rightIconBar2.visible ? rightIconBar2.width : 20) - (panelManager.rightCollapsed2 ? 40 : rightDock2.expandedWidth) - 30;
        
        leftDock.isDragHover = false; leftDock2.isDragHover = false;
        rightDock.isDragHover = false; rightDock2.isDragHover = false;
        
        if (gx <= zL1) {
            leftDock.isDragHover = true;
            var res = calculateHoverIndex(leftDock.mapFromGlobal(0, gy).y, leftDock.height, panelManager.leftDockModel);
            leftDock.hoverIndex = res.index;
            leftDock.dragMode = res.mode;
            return { dock: "left", index: res.index, mode: res.mode, modelIndex: res.modelIndex };
        } else if (gx <= zL2) {
            leftDock2.isDragHover = true;
            var res = calculateHoverIndex(leftDock2.mapFromGlobal(0, gy).y, leftDock2.height, panelManager.leftDockModel2);
            leftDock2.hoverIndex = res.index;
            leftDock2.dragMode = res.mode;
            return { dock: "left2", index: res.index, mode: res.mode, modelIndex: res.modelIndex };
        } else if (gx >= zR1) {
            rightDock.isDragHover = true;
            var res = calculateHoverIndex(rightDock.mapFromGlobal(0, gy).y, rightDock.height, panelManager.rightDockModel);
            rightDock.hoverIndex = res.index;
            rightDock.dragMode = res.mode;
            return { dock: "right", index: res.index, mode: res.mode, modelIndex: res.modelIndex };
        } else if (gx >= zR2) {
            rightDock2.isDragHover = true;
            var res = calculateHoverIndex(rightDock2.mapFromGlobal(0, gy).y, rightDock2.height, panelManager.rightDockModel2);
            rightDock2.hoverIndex = res.index;
            rightDock2.dragMode = res.mode;
            return { dock: "right2", index: res.index, mode: res.mode, modelIndex: res.modelIndex };
        }
        return null;
    }
    
    function calculateHoverIndex(localY, dHeight, dModel) {
        var visibleItems = []; 
        for(var i=0; i<dModel.count; i++) {
            var it = dModel.get(i);
            if(it.visible && it.groupId === "") {
                visibleItems.push(i);
            } else if (it.visible) {
                 var gid = it.groupId;
                 var isFirst = true;
                 for(var j=0; j<i; j++) { if(dModel.get(j).visible && dModel.get(j).groupId === gid) { isFirst = false; break; } }
                 if (isFirst) visibleItems.push(i);
            }
        }
        
        var vCount = visibleItems.length;
        if (vCount === 0) return { index: 0, mode: "insert", modelIndex: -1 };
        
        var itemHeight = dHeight / vCount;
        var vIdx = Math.floor(localY / itemHeight);
        var subY_pixels = localY % itemHeight;
        
        var modelIdx = visibleItems[Math.max(0, Math.min(vCount - 1, vIdx))];
        
        var mode = "group";
        // Thin insertion zones (15px) at the very top/bottom of items
        if (subY_pixels < 15) {
            if (vIdx === 0) mode = "insert"; // Top of dock
            else mode = "insert"; // Between panels
        } else if (subY_pixels > itemHeight - 15) {
            mode = "insert";
            vIdx++; // Increment visible index for insertion
        }
        
        return { index: vIdx, mode: mode, modelIndex: modelIdx };
    }

    // --- MANAGER ---
    StudioPanelManager {
        id: panelManager
    }

    // --- DRAG GHOST (Float Preview) ---
    Rectangle {
        id: dragGhost
        width: 240; height: 38
        radius: 12
        color: "#d918181c" // Extremely translucent dark
        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8)
        border.width: 1.5
        visible: false
        z: 3000
        
        property string currentPanelId: ""
        property string currentName: "Panel"
        property string currentIcon: ""
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 20
            shadowColor: "#66000000"
            shadowVerticalOffset: 10
        }
        
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 8
            
            Image {
                visible: dragGhost.currentIcon !== ""
                source: dragGhost.currentIcon !== "" ? "image://icons/" + dragGhost.currentIcon : ""
                width: 16; height: 16
                opacity: 0.9
            }
            Text {
                text: dragGhost.currentName
                color: "white"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
        }
        
        function startDrag(panelId, name, icon, gx, gy) {
            currentPanelId = panelId
            currentName = name
            currentIcon = icon
            visible = true
            var local = studioLayout.mapFromGlobal(gx, gy)
            x = local.x - width/2
            y = local.y - height/2
            
            // Subtle pop animation
            scaleAnim.restart()
        }
        
        NumberAnimation on scale {
            id: scaleAnim
            from: 0.8; to: 1.05
            duration: 250
            easing.type: Easing.OutBack
            running: false
        }
        
        function updateDrag(gx, gy) {
            var local = studioLayout.mapFromGlobal(gx, gy)
            x = local.x - width/2
            y = local.y - height/2
            studioLayout.updateDragZones(gx, gy)
        }
        
        function endDrag(gx, gy) {
            visible = false
            var res = studioLayout.updateDragZones(gx, gy)
            leftDock.isDragHover = false; leftDock2.isDragHover = false;
            rightDock.isDragHover = false; rightDock2.isDragHover = false;
            
            if (res) {
                panelManager.movePanel(currentPanelId, res.dock, res.mode === "group" ? res.modelIndex : res.index, res.mode)
            } else {
                panelManager.movePanelToFloat(currentPanelId, x, y)
            }
        }
    }

    // --- FLOATING PANELS LAYER ---
    Item {
        id: floatingLayer
        anchors.fill: parent
        z: 2000 // Above center tools, below dragged ghosts
        
        
        Repeater {
            model: panelManager.floatingModel
            delegate: FloatingPanel {
                // We only use the model pos to initialize, then the panel manages its own dragging natively
                Component.onCompleted: {
                    x = model.x !== undefined ? model.x : (parent.width - width)/2
                    y = model.y !== undefined ? model.y : (parent.height - height)/2
                }
                
                panelId: model.panelId
                title: model.name
                iconName: model.icon !== undefined ? model.icon : ""
                contentSource: model.source
                targetCanvas: studioLayout.mainCanvas
                accentColor: studioLayout.accentColor
                
                onCloseRequested: {
                    if (panelId === "brushes" || panelId === "settings") panelManager.movePanel(panelId, "left")
                    else panelManager.movePanel(panelId, "right")
                }
                
                onDragMoved: (gx, gy) => {
                    studioLayout.updateDragZones(gx, gy)
                }
                
                onDragReleased: (gx, gy) => {
                    var res = studioLayout.updateDragZones(gx, gy)
                    leftDock.isDragHover = false; leftDock2.isDragHover = false;
                    rightDock.isDragHover = false; rightDock2.isDragHover = false;
                    
                    if (res) {
                        panelManager.movePanel(panelId, res.dock, res.mode === "group" ? res.modelIndex : res.index, res.mode)
                    } else {
                        model.x = x
                        model.y = y
                    }
                }
            }
        }
    }

    // --- TOP BAR (STUDIO INFO) ---
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
                color: "#777"; font.pixelSize: 11; font.weight: Font.DemiBold
            }
            Item { width: 4 }
            Rectangle { width: 1; height: 12; color: "#333" }
            Item { width: 4 }
            
            Text {
                text: mainCanvas ? Math.round((mainCanvas.zoomLevel || 1.0) * 100) + "%" : "100%"
                color: "#555"; font.pixelSize: 10; font.family: "Monospace"
            }
            Text {
                text: mainCanvas ? (mainCanvas.canvasWidth || 1920) + " × " + (mainCanvas.canvasHeight || 1080) : "1920 × 1080"
                color: "#555"; font.pixelSize: 10; font.family: "Monospace"
            }
            
            Item { Layout.fillWidth: true }
            
            // Undo/Redo
            Row {
                spacing: 4
                Rectangle {
                    width: 24; height: 24; radius: 6
                    color: undoMa.containsMouse ? "#1c1c20" : "transparent"
                    border.color: undoMa.containsMouse ? "#333" : "transparent"
                    Text { text: "↶"; color: "#888"; font.pixelSize: 14; anchors.centerIn: parent }
                    MouseArea { id: undoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mainCanvas) mainCanvas.undo() }
                }
                Rectangle {
                    width: 24; height: 24; radius: 6
                    color: redoMa.containsMouse ? "#1c1c20" : "transparent"
                    border.color: redoMa.containsMouse ? "#333" : "transparent"
                    Text { text: "↷"; color: "#888"; font.pixelSize: 14; anchors.centerIn: parent }
                    MouseArea { id: redoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mainCanvas) mainCanvas.redo() }
                }
            }
            
            Item { width: 8 }
            
            // Mode switch
            Rectangle {
                width: 70; height: 24; radius: 12
                color: essMa.containsMouse ? accentColor : "#1c1c20"
                border.color: accentColor; border.width: 1
                Text {
                    text: "Essential"
                    anchors.centerIn: parent
                    color: essMa.containsMouse ? "#fff" : "#aaa"
                    font.pixelSize: 10; font.weight: Font.Bold
                }
                MouseArea {
                    id: essMa
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
            isCollapsed: panelManager.leftCollapsed
            accentColor: studioLayout.accentColor
            dockSide: "left"
            onToggleDock: (panelId) => panelManager.togglePanel(panelId)
            onReorder: (src, tgt, mode) => panelManager.reorderPanel("left", src, tgt, mode)
        }
        
        DockContainer {
            id: leftDock
            Layout.fillHeight: true
            dockSide: "left"
            manager: panelManager
            dockModel: panelManager.leftDockModel
            isCollapsed: panelManager.leftCollapsed
            mainCanvas: studioLayout.mainCanvas
            accentColor: studioLayout.accentColor
            
            onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
            onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
        
        // --- LEFT DOCK 2 ---
        SideIconBar {
            id: leftIconBar2
            visible: panelManager.leftDockModel2.count > 0 || leftDock2.isDragHover
            Layout.fillHeight: true
            panelModel: panelManager.leftDockModel2
            isCollapsed: panelManager.leftCollapsed2
            accentColor: studioLayout.accentColor
            dockSide: "left2"
            onToggleDock: (panelId) => panelManager.togglePanel(panelId)
            onReorder: (src, tgt, mode) => panelManager.reorderPanel("left2", src, tgt, mode)
        }
        
        DockContainer {
            id: leftDock2
            Layout.fillHeight: true
            dockSide: "left2"
            manager: panelManager
            dockModel: panelManager.leftDockModel2
            isCollapsed: panelManager.leftCollapsed2
            mainCanvas: studioLayout.mainCanvas
            accentColor: studioLayout.accentColor
            
            onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
            onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
        
    // --- TOOLBAR (Canvas Tools) Movable ---
    Rectangle {
        id: toolsToolbar
        width: 44
        height: toolsCol.height + 24
        color: "#0c0c0f"
        radius: isToolbarFloating ? 8 : 0
        border.color: isToolbarFloating ? "#333" : "transparent"
        border.width: isToolbarFloating ? 1 : 0
        z: 2500
        
        property bool isToolbarFloating: false
        
        // Initial / Docked positioning
        x: isToolbarFloating ? x : (leftIconBar.width + leftDock.width + (leftIconBar2.visible ? leftIconBar2.width : 0) + leftDock2.width)
        y: isToolbarFloating ? y : studioInfoBar.height
        
        // Shadow when floating
        layer.enabled: isToolbarFloating
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 15; shadowColor: "#80000000"; shadowVerticalOffset: 4 }
        
        // Grip area
        Rectangle {
            id: toolbarGrip
            width: parent.width; height: 16
            color: "transparent"
            anchors.top: parent.top
            
            Row {
                spacing: 2; anchors.centerIn: parent
                Repeater { model: 4; Rectangle { width: 3; height: 3; radius: 1.5; color: hoverGrip.containsMouse ? "#888" : "#444" } }
            }
            
            MouseArea {
                id: hoverGrip
                anchors.fill: parent; hoverEnabled: true; cursorShape: dragGrip.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: toolsToolbar
                drag.axis: Drag.XAndYAxis
                // drag constraints
                drag.minimumX: 0
                drag.maximumX: studioLayout.width - toolsToolbar.width
                drag.minimumY: 0
                drag.maximumY: studioLayout.height - toolsToolbar.height
                
                onPressed: toolsToolbar.isToolbarFloating = true
                onReleased: {
                    // Smart snap back to dock if dragged to the left edge
                    var lSnap = leftIconBar.width + leftDock.width + (leftIconBar2.visible ? leftIconBar2.width : 0) + leftDock2.width
                    if (toolsToolbar.x < lSnap + 20) {
                        toolsToolbar.isToolbarFloating = false
                        toolsToolbar.x = Qt.binding(function() { return leftIconBar.width + leftDock.width + (leftIconBar2.visible ? leftIconBar2.width : 0) + leftDock2.width })
                        toolsToolbar.y = Qt.binding(function() { return studioInfoBar.height })
                    }
                }
            }
        }
        
        ColumnLayout {
            id: toolsCol
            anchors.top: toolbarGrip.bottom; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 4; anchors.topMargin: 0
            spacing: 4
            
            Repeater {
                model: studioLayout.toolsModel
                delegate: Rectangle {
                    Layout.preferredWidth: 36; Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignHCenter
                    radius: 10
                    color: (canvasPage && index === canvasPage.activeToolIdx) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : (hoverMa.containsMouse ? "#1c1c20" : "transparent")
                    border.color: (canvasPage && index === canvasPage.activeToolIdx) ? accentColor : "transparent"
                    
                    Image {
                        source: "image://icons/" + model.icon
                        width: 20; height: 20; anchors.centerIn: parent
                        opacity: (canvasPage && index === canvasPage.activeToolIdx) ? 1.0 : 0.6
                    }
                    
                    MouseArea {
                        id: hoverMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        
                        Timer {
                            id: longPressTimer
                            interval: 500
                            onTriggered: {
                                if (canvasPage) {
                                    canvasPage.activeToolIdx = index
                                    canvasPage.showSubTools = true
                                    // Position subtool bar next to this button
                                    if (typeof subToolBar !== "undefined") {
                                        subToolBar.yLevel = parent.mapToItem(canvasPage, 0, 0).y
                                        subToolBar.isFromStudio = true
                                        subToolBar.studioToolX = toolsToolbar.x
                                    }
                                }
                            }
                        }

                        onPressed: longPressTimer.start()
                        onReleased: {
                            if (longPressTimer.running) {
                                longPressTimer.stop()
                                if (canvasPage) {
                                    if (canvasPage.activeToolIdx === index) {
                                        // If already active, toggle subtools or settings
                                        canvasPage.showSubTools = !canvasPage.showSubTools
                                        if (canvasPage.showSubTools && typeof subToolBar !== "undefined") {
                                            subToolBar.yLevel = parent.mapToItem(canvasPage, 0, 0).y
                                            subToolBar.isFromStudio = true
                                            subToolBar.studioToolX = toolsToolbar.x
                                        }
                                    } else {
                                        canvasPage.activeToolIdx = index
                                        canvasPage.activeSubToolIdx = 0
                                        if(mainCanvas) mainCanvas.currentTool = model.name
                                        canvasPage.showSubTools = false
                                    }
                                }
                            }
                        }
                        onCanceled: longPressTimer.stop()
                    }
                }
            }
        }
    }

        // --- CENTER CANVAS ---
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            Rectangle { anchors.fill: parent; color: "transparent" }
            
            // Subtle inset shadow at the edges of the canvas space
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#22000000"
                border.width: 4
            }
        }
        
        // --- RIGHT DOCK 2 ---
        DockContainer {
            id: rightDock2
            Layout.fillHeight: true
            dockSide: "right2"
            manager: panelManager
            dockModel: panelManager.rightDockModel2
            isCollapsed: panelManager.rightCollapsed2
            mainCanvas: studioLayout.mainCanvas
            accentColor: studioLayout.accentColor
            
            onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
            onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
        
        SideIconBar {
            id: rightIconBar2
            visible: panelManager.rightDockModel2.count > 0 || rightDock2.isDragHover
            Layout.fillHeight: true
            panelModel: panelManager.rightDockModel2
            isCollapsed: panelManager.rightCollapsed2
            accentColor: studioLayout.accentColor
            dockSide: "right2"
            onToggleDock: (panelId) => panelManager.togglePanel(panelId)
            onReorder: (src, tgt, mode) => panelManager.reorderPanel("right2", src, tgt, mode)
        }
        
        // --- RIGHT DOCK 1 ---
        DockContainer {
            id: rightDock
            Layout.fillHeight: true
            dockSide: "right"
            manager: panelManager
            dockModel: panelManager.rightDockModel
            isCollapsed: panelManager.rightCollapsed
            mainCanvas: studioLayout.mainCanvas
            accentColor: studioLayout.accentColor
            
            onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
            onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
        
        SideIconBar {
            id: rightIconBar
            Layout.fillHeight: true
            panelModel: panelManager.rightDockModel
            isCollapsed: panelManager.rightCollapsed
            accentColor: studioLayout.accentColor
            dockSide: "right"
            onToggleDock: (panelId) => panelManager.togglePanel(panelId)
            onReorder: (src, tgt, mode) => panelManager.reorderPanel("right", src, tgt, mode)
        }
    }
}
