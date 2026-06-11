import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import Kromo 1.0

Item {
    id: studioLayout

    // --- PROPS ---
    property var mainCanvas: null
    property var canvasPage: null
    property var toolsModel: null
    property var subToolBar: null
    property color accentColor: (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#6366f1"
    property bool isProjectActive: false
    property bool isZenMode: false

    // Dynamic sidebar / dock properties assigned on completed
    property var leftDock: null
    property var leftDock2: null
    property var rightDock: null
    property var rightDock2: null
    
    property var leftIconBar: null
    property var leftIconBar2: null
    property var rightIconBar: null
    property var rightIconBar2: null

    readonly property real leftDocksWidth: (leftIconBar ? leftIconBar.width : 0) + (leftDock ? leftDock.width : 0) + ((leftIconBar2 && leftIconBar2.visible) ? leftIconBar2.width : 0) + (leftDock2 ? leftDock2.width : 0)
    readonly property real rightDocksWidth: (rightIconBar ? rightIconBar.width : 0) + (rightDock ? rightDock.width : 0) + ((rightIconBar2 && rightIconBar2.visible) ? rightIconBar2.width : 0) + (rightDock2 ? rightDock2.width : 0)

    states: [
        State {
            name: "minimalist"
            when: isZenMode
            
            PropertyChanges { target: infoBarTranslate; y: -studioInfoBar.height }
            PropertyChanges { target: studioInfoBar; opacity: 0.0 }
            
            PropertyChanges { target: leftTranslate; x: -leftDocksWidth }
            PropertyChanges { target: leftDocksContainer; opacity: 0.0 }
            
            PropertyChanges { target: rightTranslate; x: rightDocksWidth }
            PropertyChanges { target: rightDocksContainer; opacity: 0.0 }
            
            PropertyChanges { target: toolsTranslate; x: -100 }
            PropertyChanges { target: toolsToolbar; opacity: 0.0 }
            
            PropertyChanges { target: bottomTranslate; y: bottomDock.height + 20 }
            PropertyChanges { target: bottomDock; opacity: 0.0 }
        }
    ]
    
    transitions: [
        Transition {
            NumberAnimation {
                properties: "x,y,opacity"
                duration: 350
                easing.type: Easing.InOutCubic
            }
        }
    ]
    
    readonly property bool showTopProjectInfo: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.showTopProjectInfo : true
    readonly property bool showTopBrushControls: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.showTopBrushControls : true
    readonly property bool showTopActionButtons: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.showTopActionButtons : true
    readonly property bool showTopSymmetryUndoRedo: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.showTopSymmetryUndoRedo : true
    readonly property bool showTopWorkspaceSwitcher: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.showTopWorkspaceSwitcher : true
    
    // Custom Dropdown State
    property bool wsMenuOpen: false
    property real wsMenuX: 0
    property real wsMenuY: 0

    property bool winMenuOpen: false
    property real winMenuX: 0
    property real winMenuY: 0
    property bool wsSubMenuOpen: false
    property real wsSubMenuX: 0
    property real wsSubMenuY: 0
    property bool hiddenPanelsOpen: false
    property real hiddenPanelsX: 0
    property real hiddenPanelsY: 0

    signal switchToEssential()
    signal tabActivated(int index)
    signal tabClosed(int index)

    // Multi-project model passed from main_pro.qml
    property var openProjectsModel: null
    property int activeProjectIndex: 0

    // Color state (bound to colorStudioDialog in main_pro.qml)
    property color primaryColor: "#ffffff"
    property color secondaryColor: "#000000"
    property int activeColorSlot: 0
    property bool isTransparentMode: false
    signal colorOrbClicked(int slot)
    signal transparencyOrbClicked()
    
    function loadWorkspace(name) { if (panelManager) panelManager.loadWorkspace(name) }

    visible: isProjectActive
    
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
        if (!panelManager) return null;
        // --- C++ does the heavy math ---
        var zone = dragCalculator.computeDragZone(
            gx, studioLayout.width,
            leftIconBar ? leftIconBar.width : 0, leftDock ? leftDock.width : 0,
            leftIconBar2 ? leftIconBar2.visible : false, (leftIconBar2 && leftIconBar2.visible) ? leftIconBar2.width : 0, leftDock2 ? leftDock2.width : 0,
            rightIconBar ? rightIconBar.width : 0, rightDock ? rightDock.width : 0,
            rightIconBar2 ? rightIconBar2.visible : false, (rightIconBar2 && rightIconBar2.visible) ? rightIconBar2.width : 0, rightDock2 ? rightDock2.width : 0,
            panelManager.leftCollapsed, panelManager.leftCollapsed2,
            panelManager.rightCollapsed, panelManager.rightCollapsed2,
            leftDock ? leftDock.expandedWidth : 0, leftDock2 ? leftDock2.expandedWidth : 0,
            rightDock ? rightDock.expandedWidth : 0, rightDock2 ? rightDock2.expandedWidth : 0
        )

        if (leftDock) leftDock.isDragHover = false;
        if (leftDock2) leftDock2.isDragHover = false;
        if (rightDock) rightDock.isDragHover = false;
        if (rightDock2) rightDock2.isDragHover = false;

        if (!zone.dock || zone.dock === "") return null;

        var targetDockWidget, targetModel;
        if (zone.dock === "left")        { targetDockWidget = leftDock;  targetModel = panelManager.leftDockModel; }
        else if (zone.dock === "left2")  { targetDockWidget = leftDock2; targetModel = panelManager.leftDockModel2; }
        else if (zone.dock === "right")  { targetDockWidget = rightDock; targetModel = panelManager.rightDockModel; }
        else if (zone.dock === "right2") { targetDockWidget = rightDock2; targetModel = panelManager.rightDockModel2; }
        else return null;

        targetDockWidget.isDragHover = true;
        // C++ calculates hover index directly on the model — no JS loops
        var localY = targetDockWidget.mapFromGlobal(0, gy).y;
        var res = dragCalculator.calculateHoverIndex(localY, targetDockWidget.height, targetModel);
        targetDockWidget.hoverIndex = res.index;
        targetDockWidget.dragMode = res.mode;
        return { dock: zone.dock, index: res.index, mode: res.mode, modelIndex: res.modelIndex };
    }
    
    // calculateHoverIndex is now fully in C++ — dragCalculator.calculateHoverIndex()
    // Kept as a thin wrapper for any external callers
    function calculateHoverIndex(localY, dHeight, dModel) {
        return dragCalculator.calculateHoverIndex(localY, dHeight, dModel);
    }


    // MANAGER: The global C++ `panelManager` context property is used directly.
    // No local QML wrapper needed — the C++ PanelManager handles everything.

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
            model: panelManager ? panelManager.floatingModel : null
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
        width: parent.width; height: 42
        color: mainWindow ? mainWindow.colorPanel : "#0a0a0d"
        z: 950
        
        transform: Translate {
            id: infoBarTranslate
            y: 0
        }
        opacity: 1.0
        
        Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: mainWindow ? mainWindow.colorBorder : "#1a1a1e" }
        
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 12
            
            // Project Info Group
            RowLayout {
                visible: studioLayout.showTopProjectInfo
                spacing: 12
                Text {
                    text: mainCanvas ? (mainCanvas.currentProjectName || "Untitled") : "Untitled"
                    color: mainWindow ? mainWindow.colorText : "#999"; font.pixelSize: 13; font.weight: Font.DemiBold
                }
                Item { width: 4 }
                Rectangle { width: 1; height: 16; color: mainWindow ? mainWindow.colorBorder : "#333" }
                Item { width: 4 }
                
                Text {
                    text: mainCanvas ? Math.round((mainCanvas.zoomLevel || 1.0) * 100) + "%" : "100%"
                    color: mainWindow ? mainWindow.colorTextMuted : "#777"; font.pixelSize: 11; font.family: "Monospace"
                }
                Text {
                    text: mainCanvas ? (mainCanvas.canvasWidth || 1920) + " × " + (mainCanvas.canvasHeight || 1080) : "1920 × 1080"
                    color: mainWindow ? mainWindow.colorTextMuted : "#777"; font.pixelSize: 11; font.family: "Monospace"
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // --- BRUSH CONTROLS ---
            RowLayout {
                visible: studioLayout.showTopBrushControls
                spacing: 8
                
                // --- Premium Size Scrubber ---
                Item {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 28
                    
                    Rectangle {
                        id: sizeBg
                        anchors.fill: parent
                        radius: 14
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: mainWindow ? Qt.darker(mainWindow.colorBg, 1.1) : "#111114" }
                            GradientStop { position: 1.0; color: mainWindow ? Qt.darker(mainWindow.colorBg, 1.05) : "#1c1c20" }
                        }
                        
                        // Fill Container (clips correctly without squishing radius)
                        Item {
                            id: sizeFillClip
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (mainCanvas ? Math.max(0.0, Math.min(1.0, Math.pow((mainCanvas.brushSize - 0.5) / 1999.5, 1.0 / 3.0))) : 0)
                            clip: true
                            
                            Rectangle {
                                width: sizeBg.width
                                height: sizeBg.height
                                radius: 14
                                color: sizeMouse.pressed ? accentColor : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1, 0.1) }
                                        GradientStop { position: 0.5; color: "transparent" }
                                    }
                                }
                            }
                            
                            // Glowing edge indicator
                            Rectangle {
                                width: 2
                                height: 14
                                radius: 1
                                color: sizeMouse.containsMouse ? "white" : Qt.lighter(accentColor, 1.3)
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: sizeFillClip.width > 8 ? (sizeMouse.containsMouse ? 1.0 : 0.6) : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 4
                            Text {
                                text: "SIZE"
                                color: sizeMouse.containsMouse ? (mainWindow ? mainWindow.colorText : "white") : (mainWindow ? mainWindow.colorTextMuted : "#999")
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: mainCanvas ? Math.round(mainCanvas.brushSize) + " px" : "0 px"
                                color: mainWindow ? mainWindow.colorText : "white"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: sizeMouse.containsMouse ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#3a3a40")
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    MouseArea {
                        id: sizeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        property bool isDragging: false
                        onPressed: (mouse) => {
                            isDragging = true;
                            updateValue(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (isDragging) updateValue(mouse);
                        }
                        onReleased: isDragging = false
                        
                        function updateValue(mouse) {
                            if (!mainCanvas) return;
                            var v = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            mainCanvas.brushSize = 0.5 + 1999.5 * Math.pow(v, 3.0);
                        }
                    }
                }
                
                Item { width: 4 }
                
                // --- Premium Opacity Scrubber ---
                Item {
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 28
                    
                    Rectangle {
                        id: opacBg
                        anchors.fill: parent
                        radius: 14
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: mainWindow ? Qt.darker(mainWindow.colorBg, 1.1) : "#111114" }
                            GradientStop { position: 1.0; color: mainWindow ? Qt.darker(mainWindow.colorBg, 1.05) : "#1c1c20" }
                        }
                        
                        // Fill Container (clips correctly without squishing radius)
                        Item {
                            id: opacFillClip
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (mainCanvas ? mainCanvas.brushOpacity : 0)
                            clip: true
                            
                            Rectangle {
                                width: opacBg.width
                                height: opacBg.height
                                radius: 14
                                color: opacMouse.pressed ? accentColor : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1, 0.1) }
                                        GradientStop { position: 0.5; color: "transparent" }
                                    }
                                }
                            }
                            
                            // Glowing edge indicator
                            Rectangle {
                                width: 2
                                height: 14
                                radius: 1
                                color: opacMouse.containsMouse ? "white" : Qt.lighter(accentColor, 1.3)
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: opacFillClip.width > 8 ? (opacMouse.containsMouse ? 1.0 : 0.6) : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 4
                            Text {
                                text: "OPAC"
                                color: opacMouse.containsMouse ? (mainWindow ? mainWindow.colorText : "white") : (mainWindow ? mainWindow.colorTextMuted : "#999")
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) + "%" : "100%"
                                color: mainWindow ? mainWindow.colorText : "white"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: opacMouse.containsMouse ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#3a3a40")
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    MouseArea {
                        id: opacMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        property bool isDragging: false
                        onPressed: (mouse) => {
                            isDragging = true;
                            updateValue(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (isDragging) updateValue(mouse);
                        }
                        onReleased: isDragging = false
                        
                        function updateValue(mouse) {
                            if (!mainCanvas) return;
                            var v = Math.max(0.01, Math.min(1.0, mouse.x / width));
                            mainCanvas.brushOpacity = v;
                        }
                    }
                }
                
                Item { width: 4 }
                
                // --- Premium Stabilization Scrubber ---
                Item {
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 28
                    
                    Rectangle {
                        id: stabBg
                        anchors.fill: parent
                        radius: 14
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: mainWindow ? Qt.darker(mainWindow.colorBg, 1.1) : "#111114" }
                            GradientStop { position: 1.0; color: mainWindow ? Qt.darker(mainWindow.colorBg, 1.05) : "#1c1c20" }
                        }
                        
                        // Fill Container (clips correctly without squishing radius)
                        Item {
                            id: stabFillClip
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (mainCanvas ? mainCanvas.brushStabilization : 0)
                            clip: true
                            
                            Rectangle {
                                width: stabBg.width
                                height: stabBg.height
                                radius: 14
                                color: stabMouse.pressed ? accentColor : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1, 0.1) }
                                        GradientStop { position: 0.5; color: "transparent" }
                                    }
                                }
                            }
                            
                            // Glowing edge indicator
                            Rectangle {
                                width: 2
                                height: 14
                                radius: 1
                                color: stabMouse.containsMouse ? "white" : Qt.lighter(accentColor, 1.3)
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: stabFillClip.width > 8 ? (stabMouse.containsMouse ? 1.0 : 0.6) : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 4
                            Text {
                                text: "STAB"
                                color: stabMouse.containsMouse ? (mainWindow ? mainWindow.colorText : "white") : (mainWindow ? mainWindow.colorTextMuted : "#999")
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: mainCanvas ? Math.round(mainCanvas.brushStabilization * 100) + "%" : "0%"
                                color: mainWindow ? mainWindow.colorText : "white"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.color: stabMouse.containsMouse ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#3a3a40")
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    MouseArea {
                        id: stabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        property bool isDragging: false
                        onPressed: (mouse) => {
                            isDragging = true;
                            updateValue(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (isDragging) updateValue(mouse);
                        }
                        onReleased: isDragging = false
                        
                        function updateValue(mouse) {
                            if (!mainCanvas) return;
                            var v = Math.max(0.00, Math.min(1.0, mouse.x / width));
                            mainCanvas.brushStabilization = v;
                        }
                    }
                }
            }
            
            Item { width: 16; visible: studioLayout.showTopBrushControls }
            
            // --- ACTION BUTTONS ---
            RowLayout {
                visible: studioLayout.showTopActionButtons
                spacing: 6
                
                Rectangle {
                    width: 60; height: 26; radius: 6
                    color: saveBtn.containsMouse ? accentColor : (mainWindow ? mainWindow.colorCard : "#1a1a1f")
                    border.color: saveBtn.containsMouse ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#333")
                    border.width: 1
                    Text { text: "Save"; color: saveBtn.containsMouse ? "white" : (mainWindow ? mainWindow.colorText : "white"); font.pixelSize: 11; font.weight: Font.DemiBold; anchors.centerIn: parent }
                    MouseArea {
                        id: saveBtn
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof mainWindow !== "undefined" && mainWindow) mainWindow.saveProjectAndRefresh()
                        }
                    }
                }
                
                Rectangle {
                    width: 65; height: 26; radius: 6
                    color: exportBtn.containsMouse ? accentColor : (mainWindow ? mainWindow.colorCard : "#1a1a1f")
                    border.color: exportBtn.containsMouse ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#333")
                    border.width: 1
                    Text { text: "Export"; color: exportBtn.containsMouse ? "white" : (mainWindow ? mainWindow.colorText : "white"); font.pixelSize: 11; font.weight: Font.DemiBold; anchors.centerIn: parent }
                    MouseArea {
                        id: exportBtn
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof exportImageDialog !== "undefined" && exportImageDialog) exportImageDialog.open()
                        }
                    }
                }
            }
            
            Item { width: 16; visible: studioLayout.showTopActionButtons }
            
            // Symmetry & Undo/Redo Group
            RowLayout {
                visible: studioLayout.showTopSymmetryUndoRedo
                spacing: 8
                
                // Symmetry
                Rectangle {
                    width: 32; height: 24; radius: 6
                    color: mainCanvas && mainCanvas.symmetryEnabled ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : (symMa.containsMouse ? "#1c1c20" : "transparent")
                    border.color: mainCanvas && mainCanvas.symmetryEnabled ? accentColor : (symMa.containsMouse ? "#333" : "transparent")
                    
                    Image {
                        source: "image://icons/symmetry.svg"
                        width: 14; height: 14; anchors.centerIn: parent
                        sourceSize: Qt.size(14, 14)
                        opacity: mainCanvas && mainCanvas.symmetryEnabled ? 1.0 : 0.6
                    }
                    
                    MouseArea {
                        id: symMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (!mainCanvas) return;
                            if (mouse.button === Qt.RightButton) {
                                mainCanvas.symmetryMode = (mainCanvas.symmetryMode + 1) % 4;
                                mainCanvas.symmetryEnabled = true;
                            } else {
                                mainCanvas.symmetryEnabled = !mainCanvas.symmetryEnabled;
                            }
                        }
                    }
                    ToolTip.visible: symMa.containsMouse
                    ToolTip.text: "Simetría (Click: On/Off | Click Derecho: Modo)"
                }
                
                // Undo/Redo
                Row {
                    spacing: 4
                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: undoMa.containsMouse ? "#1c1c20" : "transparent"
                        border.color: undoMa.containsMouse ? "#333" : "transparent"
                        Image {
                            source: "image://icons/undo.svg"
                            width: 14; height: 14; anchors.centerIn: parent
                            sourceSize: Qt.size(14, 14)
                            opacity: undoMa.containsMouse ? 1.0 : 0.6
                        }
                        MouseArea { id: undoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mainCanvas) mainCanvas.undo() }
                    }
                    Rectangle {
                        width: 24; height: 24; radius: 6
                        color: redoMa.containsMouse ? "#1c1c20" : "transparent"
                        border.color: redoMa.containsMouse ? "#333" : "transparent"
                        Image {
                            source: "image://icons/redo.svg"
                            width: 14; height: 14; anchors.centerIn: parent
                            sourceSize: Qt.size(14, 14)
                            opacity: redoMa.containsMouse ? 1.0 : 0.6
                        }
                        MouseArea { id: redoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mainCanvas) mainCanvas.redo() }
                    }
                }
            }
            
            Item { width: 8; visible: studioLayout.showTopSymmetryUndoRedo }
            
            // --- WORKSPACES SWITCHER ---
            Rectangle {
                id: workspaceBtn
                visible: studioLayout.showTopWorkspaceSwitcher
                width: 140; height: 26; radius: 6
                color: wsMa.containsMouse || studioLayout.wsMenuOpen ? (mainWindow ? Qt.lighter(mainWindow.colorCard, 1.05) : "#2a2a30") : (mainWindow ? mainWindow.colorCard : "#1a1a1f")
                border.color: wsMa.containsMouse || studioLayout.wsMenuOpen ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#333")
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 4
                    
                    Image {
                        source: "image://icons/layout.svg"
                        Layout.preferredWidth: 12; Layout.preferredHeight: 12
                        sourceSize: Qt.size(12, 12)
                        opacity: 0.6
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: panelManager ? panelManager.activeWorkspace : ""
                        color: mainWindow ? mainWindow.colorText : "white"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text { text: "▾"; color: mainWindow ? mainWindow.colorTextMuted : "#aaa"; font.pixelSize: 12 }
                }
                
                MouseArea {
                    id: wsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var pt = workspaceBtn.mapToItem(studioLayout, 0, workspaceBtn.height + 6)
                        studioLayout.wsMenuX = pt.x
                        studioLayout.wsMenuY = pt.y
                        studioLayout.wsMenuOpen = !studioLayout.wsMenuOpen
                    }
                }
            }
            
            Item { width: 8; visible: studioLayout.showTopWorkspaceSwitcher }

            // --- VENTANA MENU BUTTON ---
            Rectangle {
                id: ventanaBtn
                width: 90; height: 26; radius: 6
                color: ventMa.containsMouse || studioLayout.winMenuOpen ? (mainWindow ? Qt.lighter(mainWindow.colorCard, 1.05) : "#2a2a30") : (mainWindow ? mainWindow.colorCard : "#1a1a1f")
                border.color: ventMa.containsMouse || studioLayout.winMenuOpen ? Qt.lighter(accentColor, 1.2) : (mainWindow ? mainWindow.colorBorder : "#333")
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 4
                    
                    Image {
                        source: "image://icons/window.svg"
                        Layout.preferredWidth: 12; Layout.preferredHeight: 12
                        sourceSize: Qt.size(12, 12)
                        opacity: 0.6
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: "Ventana"
                        color: ventMa.containsMouse || studioLayout.winMenuOpen ? "white" : (mainWindow ? mainWindow.colorText : "white")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text { text: "▾"; color: mainWindow ? mainWindow.colorTextMuted : "#aaa"; font.pixelSize: 12 }
                }
                
                MouseArea {
                    id: ventMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var pt = ventanaBtn.mapToItem(studioLayout, 0, ventanaBtn.height + 6)
                        studioLayout.winMenuX = pt.x
                        studioLayout.winMenuY = pt.y
                        studioLayout.winMenuOpen = !studioLayout.winMenuOpen
                        studioLayout.wsSubMenuOpen = false
                        studioLayout.hiddenPanelsOpen = false
                    }
                }
            }

            Item { width: 8; visible: true }
            
            Rectangle {
                width: 80; height: 26; radius: 13
                color: essMa.containsMouse ? accentColor : (mainWindow ? mainWindow.colorCard : "#1c1c20")
                border.color: accentColor; border.width: 1
                Text {
                    text: "Essential"
                    anchors.centerIn: parent
                    color: essMa.containsMouse ? "#fff" : (mainWindow ? mainWindow.colorTextMuted : "#aaa")
                    font.pixelSize: 11; font.weight: Font.Bold
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

    // --- STUDIO PROJECT TAB BAR (visible when ≥2 projects open) ---
    Rectangle {
        id: studioTabBar
        anchors.top: studioInfoBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: (openProjectsModel && openProjectsModel.count >= 2) ? 30 : 0
        visible: openProjectsModel && openProjectsModel.count >= 2
        color: mainWindow ? Qt.darker(mainWindow.colorPanel, 1.08) : "#0d0d10"
        z: 940
        clip: true

        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Bottom border line
        Rectangle {
            width: parent.width; height: 1
            anchors.bottom: parent.bottom
            color: mainWindow ? mainWindow.colorBorder : "#222"
        }

        ScrollView {
            anchors.fill: parent
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Row {
                id: studioTabRow
                height: parent.height
                spacing: 0

                Repeater {
                    model: openProjectsModel
                    delegate: Rectangle {
                        id: studioTab
                        width: Math.min(200, Math.max(90, studioTabLabel.implicitWidth + 40))
                        height: studioTabBar.height
                        color: index === activeProjectIndex
                            ? (mainWindow ? mainWindow.colorPanel : "#16161a")
                            : (studioTabHover.containsMouse ? Qt.rgba(1,1,1,0.03) : "transparent")

                        Behavior on color { ColorAnimation { duration: 100 } }

                        // Active top indicator line
                        Rectangle {
                            width: parent.width
                            height: 2
                            anchors.top: parent.top
                            color: index === activeProjectIndex ? accentColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Right separator
                        Rectangle {
                            width: 1; height: parent.height * 0.6
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: mainWindow ? mainWindow.colorBorder : "#222"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 6

                            // Unsaved dot
                            Rectangle {
                                width: 5; height: 5; radius: 3
                                color: accentColor
                                anchors.verticalCenter: parent.verticalCenter
                                visible: model.dirty === true
                            }

                            Text {
                                id: studioTabLabel
                                text: model.name || "Sin Título"
                                color: index === activeProjectIndex
                                    ? (mainWindow ? mainWindow.colorText : "white")
                                    : (mainWindow ? mainWindow.colorTextMuted : "#888")
                                font.pixelSize: 11
                                font.weight: index === activeProjectIndex ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 36
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Close X
                            Item {
                                width: 16; height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: "×"
                                    font.pixelSize: 13
                                    color: studioCloseHover.containsMouse ? "#ef4444"
                                        : (mainWindow ? mainWindow.colorTextMuted : "#666")
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }
                                MouseArea {
                                    id: studioCloseHover
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        mouse.accepted = true
                                        studioLayout.tabClosed(index)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: studioTabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            propagateComposedEvents: true
                            onClicked: (mouse) => {
                                studioLayout.tabActivated(index)
                                mouse.accepted = false
                            }
                        }
                    }
                }
            }
        }
    }

    // --- MAIN CONTENT AREA ---
    ColumnLayout {
        anchors.top: studioTabBar.visible ? studioTabBar.bottom : studioInfoBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0
        
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
        
        // --- DYNAMIC LEFT DOCKS ---
        RowLayout {
            id: leftDocksContainer
            Layout.fillHeight: true
            spacing: 0
            
            transform: Translate {
                id: leftTranslate
                x: 0
            }
            opacity: 1.0
            
            Repeater {
                model: [
                    { side: "left", isSecond: false },
                    { side: "left2", isSecond: true }
                ]
                delegate: RowLayout {
                    spacing: 0
                    Layout.fillHeight: true
                    visible: !modelData.isSecond || ((panelManager && panelManager.leftDockModel2 ? panelManager.leftDockModel2.count > 0 : false) || (studioLayout.leftDock2 && studioLayout.leftDock2.isDragHover))
                    
                    SideIconBar {
                        Layout.fillHeight: true
                        panelModel: modelData.isSecond ? (panelManager ? panelManager.leftDockModel2 : null) : (panelManager ? panelManager.leftDockModel : null)
                        isCollapsed: modelData.isSecond ? (panelManager ? panelManager.leftCollapsed2 : true) : (panelManager ? panelManager.leftCollapsed : true)
                        accentColor: studioLayout.accentColor
                        dockSide: modelData.side
                        onToggleDock: (panelId) => panelManager.togglePanel(panelId)
                        onReorder: (src, tgt, mode) => panelManager.reorderPanel(modelData.side, src, tgt, mode)
                        
                        Component.onCompleted: {
                            if (modelData.isSecond) {
                                studioLayout.leftIconBar2 = this
                            } else {
                                studioLayout.leftIconBar = this
                            }
                        }
                    }
                    
                    DockContainer {
                        Layout.fillHeight: true
                        dockSide: modelData.side
                        manager: panelManager
                        dockModel: modelData.isSecond ? (panelManager ? panelManager.leftDockModel2 : null) : (panelManager ? panelManager.leftDockModel : null)
                        isCollapsed: modelData.isSecond ? (panelManager ? panelManager.leftCollapsed2 : true) : (panelManager ? panelManager.leftCollapsed : true)
                        mainCanvas: studioLayout.mainCanvas
                        accentColor: studioLayout.accentColor
                        
                        onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
                        onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
                        onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
                        onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
                        
                        Component.onCompleted: {
                            if (modelData.isSecond) {
                                studioLayout.leftDock2 = this
                            } else {
                                studioLayout.leftDock = this
                            }
                        }
                    }
                }
            }
        }
        
        // Placeholder for toolbar in the RowLayout to reserve space when docked
        Item {
            id: toolsToolbarPlaceholder
            Layout.preferredWidth: toolsToolbar.isToolbarFloating ? 0 : 48
            Layout.fillHeight: true
            visible: !toolsToolbar.isToolbarFloating
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
        
        // --- DYNAMIC RIGHT DOCKS ---
        RowLayout {
            id: rightDocksContainer
            Layout.fillHeight: true
            spacing: 0
            
            transform: Translate {
                id: rightTranslate
                x: 0
            }
            opacity: 1.0
            
            Repeater {
                model: [
                    { side: "right2", isSecond: true },
                    { side: "right", isSecond: false }
                ]
                delegate: RowLayout {
                    spacing: 0
                    Layout.fillHeight: true
                    visible: !modelData.isSecond || ((panelManager && panelManager.rightDockModel2 ? panelManager.rightDockModel2.count > 0 : false) || (studioLayout.rightDock2 && studioLayout.rightDock2.isDragHover))
                    
                    DockContainer {
                        Layout.fillHeight: true
                        dockSide: modelData.side
                        manager: panelManager
                        dockModel: modelData.isSecond ? (panelManager ? panelManager.rightDockModel2 : null) : (panelManager ? panelManager.rightDockModel : null)
                        isCollapsed: modelData.isSecond ? (panelManager ? panelManager.rightCollapsed2 : true) : (panelManager ? panelManager.rightCollapsed : true)
                        mainCanvas: studioLayout.mainCanvas
                        accentColor: studioLayout.accentColor
                        
                        onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
                        onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
                        onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
                        onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
                        
                        Component.onCompleted: {
                            if (modelData.isSecond) {
                                studioLayout.rightDock2 = this
                            } else {
                                studioLayout.rightDock = this
                            }
                        }
                    }
                    
                    SideIconBar {
                        Layout.fillHeight: true
                        panelModel: modelData.isSecond ? (panelManager ? panelManager.rightDockModel2 : null) : (panelManager ? panelManager.rightDockModel : null)
                        isCollapsed: modelData.isSecond ? (panelManager ? panelManager.rightCollapsed2 : true) : (panelManager ? panelManager.rightCollapsed : true)
                        accentColor: studioLayout.accentColor
                        dockSide: modelData.side
                        onToggleDock: (panelId) => panelManager.togglePanel(panelId)
                        onReorder: (src, tgt, mode) => panelManager.reorderPanel(modelData.side, src, tgt, mode)
                        
                        Component.onCompleted: {
                            if (modelData.isSecond) {
                                studioLayout.rightIconBar2 = this
                            } else {
                                studioLayout.rightIconBar = this
                            }
                        }
                    }
                }
            }
        }
        }
        
        // --- BOTTOM DOCK ---
        DockContainer {
            id: bottomDock
            dockSide: "bottom"
            manager: panelManager
            isCollapsed: panelManager ? panelManager.bottomCollapsed : true
            mainCanvas: studioLayout.mainCanvas
            accentColor: studioLayout.accentColor
            
            transform: Translate {
                id: bottomTranslate
                y: 0
            }
            opacity: 1.0
            
            onToggleCollapse: (panelId) => panelManager.togglePanel(panelId)
            onPanelDragStarted: (pid, name, icon, gx, gy) => dragGhost.startDrag(pid, name, icon, gx, gy)
            onPanelDragUpdated: (gx, gy) => dragGhost.updateDrag(gx, gy)
            onPanelDragEnded: (gx, gy) => dragGhost.endDrag(gx, gy)
        }
    }
    
    // --- CUSTOM FLOATING DROPDOWN FOR WORKSPACES & WINDOW MENUS ---
    // Guaranteed to be on top of EVERYTHING via z-index and root containment
    
    // 1. Invisible fullscreen dismisser
    MouseArea {
        anchors.fill: parent
        z: 9997
        visible: studioLayout.wsMenuOpen || studioLayout.winMenuOpen
                 || studioLayout.wsSubMenuOpen || studioLayout.hiddenPanelsOpen
        onClicked: {
            studioLayout.wsMenuOpen = false
            studioLayout.winMenuOpen = false
            studioLayout.wsSubMenuOpen = false
            studioLayout.hiddenPanelsOpen = false
        }
    }
    
    // 2. The Original Floating Workspaces Menu
    Rectangle {
        id: customWsMenu
        z: 9998
        visible: studioLayout.wsMenuOpen
        x: studioLayout.wsMenuX
        y: studioLayout.wsMenuY
        width: 150
        height: wsMenuCol.height + 16
        color: "#18181c"
        border.color: "#3a3a40"
        border.width: 1
        radius: 8
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 24
            shadowColor: "#88000000"
            shadowVerticalOffset: 4
        }
        
        Column {
            id: wsMenuCol
            width: parent.width - 12
            anchors.centerIn: parent
            spacing: 4
            
            Repeater {
                model: panelManager ? panelManager.availableWorkspaces : null
                delegate: Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: wsItemMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                    border.color: wsItemMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                    border.width: 1
                    
                    Text { 
                        text: modelData
                        color: panelManager && modelData === panelManager.activeWorkspace ? accentColor : (wsItemMa.containsMouse ? "white" : "#ddd")
                        font.pixelSize: 12
                        font.weight: panelManager && modelData === panelManager.activeWorkspace ? Font.Bold : Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 28
                    }
                    
                    Text {
                        visible: panelManager && modelData === panelManager.activeWorkspace
                        text: "✓"
                        color: accentColor
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                    }
                    
                    MouseArea {
                        id: wsItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panelManager.loadWorkspace(modelData)
                            studioLayout.wsMenuOpen = false
                        }
                    }
                }
            }
        }
    }

    // 3. The Custom "Ventana" Dropdown Menu (with search + remove)
    Rectangle {
        id: customWinMenu
        z: 9998
        visible: studioLayout.winMenuOpen
        x: studioLayout.winMenuX
        y: studioLayout.winMenuY
        width: 280
        height: winMenuCol.height + 16
        color: "#18181c"
        border.color: "#3a3a40"
        border.width: 1
        radius: 8

        // Master list of panels in the Ventana menu.
        // `id` matches the C++ panel_manager catalog id.
        // The Repeater below filters this list by the search text AND
        // excludes panels the user has hidden via the ✕ button.
        readonly property var _allPanels: [
            { id: "color",        name: "Color" },
            { id: "colorhistory", name: "Historial de Color" },
            { id: "layers",       name: "Capas" },
            { id: "brushes",      name: "Pinceles" },
            { id: "settings",     name: "Ajuste de herramienta" },
            { id: "navigator",    name: "Navegador" },
            { id: "history",      name: "Historial" },
            { id: "reference",    name: "Referencia" },
            { id: "info",         name: "Info" },
            { id: "timeline",     name: "Línea de tiempo" }
        ]

        // List of hidden panels (from C++ panel_manager.hiddenPanels).
        // Re-read whenever the C++ signal fires so the menu reflects changes
        // immediately.
        property var hiddenList: (typeof panelManager !== "undefined" && panelManager)
                                ? panelManager.hiddenPanels : []
        Connections {
            target: (typeof panelManager !== "undefined") ? panelManager : null
            function onHiddenPanelsChanged() {
                customWinMenu.hiddenList = panelManager.hiddenPanels
                panelListRepeater.model = customWinMenu._filteredPanels()
            }
        }

        function _filteredPanels() {
            var q = (typeof winSearch !== "undefined" && winSearch) ? winSearch.text.toLowerCase().trim() : ""
            var hidden = customWinMenu.hiddenList || []
            var out = []
            for (var i = 0; i < _allPanels.length; i++) {
                // Skip hidden panels
                if (hidden.indexOf(_allPanels[i].id) !== -1) continue
                if (q.length > 0 && _allPanels[i].name.toLowerCase().indexOf(q) === -1) continue
                out.push(_allPanels[i])
            }
            return out
        }

        function _hiddenPanelDetails() {
            var hidden = customWinMenu.hiddenList || []
            var out = []
            for (var i = 0; i < _allPanels.length; i++) {
                if (hidden.indexOf(_allPanels[i].id) !== -1) {
                    out.push(_allPanels[i])
                }
            }
            return out
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 24
            shadowColor: "#88000000"
            shadowVerticalOffset: 4
        }

        Column {
            id: winMenuCol
            width: parent.width - 12
            anchors.centerIn: parent
            spacing: 2

            // Item 1: Espacio de trabajo (Workspace submenu trigger)
            Rectangle {
                id: wsSubMenuTrigger
                width: parent.width
                height: 30
                radius: 6
                color: wsTriggerMa.containsMouse || studioLayout.wsSubMenuOpen ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                border.color: wsTriggerMa.containsMouse || studioLayout.wsSubMenuOpen ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text {
                        text: "Espacio de trabajo"
                        color: wsTriggerMa.containsMouse || studioLayout.wsSubMenuOpen ? "white" : "#ddd"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "▶"
                        color: "#888"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: wsTriggerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleSubMenu()
                    onEntered: toggleSubMenu()

                    function toggleSubMenu() {
                        var pt = wsSubMenuTrigger.mapToItem(studioLayout, wsSubMenuTrigger.width + 4, -8)
                        studioLayout.wsSubMenuX = pt.x
                        studioLayout.wsSubMenuY = pt.y
                        studioLayout.wsSubMenuOpen = true
                    }
                }
            }

            // Search bar
            Rectangle {
                width: parent.width
                height: 30
                radius: 6
                color: "#101015"
                border.color: winSearch.activeFocus ? accentColor : "#2a2a2d"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: "🔍"
                        color: "#888"
                        font.pixelSize: 11
                    }
                    TextField {
                        id: winSearch
                        Layout.fillWidth: true
                        background: null
                        placeholderText: "Buscar panel…"
                        placeholderTextColor: "#666"
                        color: "white"
                        selectByMouse: true
                        font.pixelSize: 11
                        padding: 0
                        onTextChanged: panelListRepeater.model = customWinMenu._filteredPanels()
                        Keys.onEscapePressed: { text = ""; focus = false }
                    }
                    Text {
                        text: "✕"
                        color: winSearch.text.length > 0 ? "#aaa" : "transparent"
                        font.pixelSize: 10
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: winSearch.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: { if (winSearch.text.length > 0) winSearch.text = "" }
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: "#2d2d34"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // No results message
            Text {
                width: parent.width
                height: 32
                visible: customWinMenu._filteredPanels().length === 0
                text: winSearch.text.length > 0
                      ? "Sin resultados para «" + winSearch.text + "»"
                      : (customWinMenu._hiddenPanelDetails().length > 0
                            ? "Todos los paneles visibles están ocultos. Pulsa «Mostrar paneles ocultos» abajo para restaurarlos."
                            : "Sin paneles")
                color: "#666"
                font.pixelSize: 11
                font.italic: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // Checklist of Panels (filtered)
            Repeater {
                id: panelListRepeater
                model: customWinMenu._filteredPanels()

                delegate: Rectangle {
                    id: panelRow
                    width: parent.width
                    height: 30
                    radius: 6
                    color: panelToggleMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                    border.color: panelToggleMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                    border.width: 1

                    function checkIsVisible(pid) {
                        if (!panelManager) return false
                        var models = [
                            panelManager.leftDockModel,
                            panelManager.leftDockModel2,
                            panelManager.rightDockModel,
                            panelManager.rightDockModel2,
                            panelManager.bottomDockModel,
                            panelManager.floatingModel
                        ]
                        for (var i = 0; i < models.length; i++) {
                            var m = models[i];
                            if (!m) continue;
                            var idx = m.findById(pid);
                            if (idx >= 0) {
                                return m.get(idx).visible;
                            }
                        }
                        return false;
                    }

                    Text {
                        text: modelData.name
                        color: panelToggleMa.containsMouse && !removeBtnMa.containsMouse ? "white" : "#ddd"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 28
                    }

                    Text {
                        visible: checkIsVisible(modelData.id)
                        text: "✓"
                        color: accentColor
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                    }

                    // ✕ Remove button (stops event propagation so the toggle doesn't fire)
                    Rectangle {
                        id: removeBtn
                        width: 20; height: 20
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        color: removeBtnMa.containsMouse ? "#b91c1c" : "transparent"
                        border.color: removeBtnMa.containsMouse ? "#ef4444" : "#444"
                        border.width: 1
                        visible: panelToggleMa.containsMouse
                        z: 5
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: removeBtnMa.containsMouse ? "white" : "#888"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: removeBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Remove panel from every dock AND from the Ventana menu.
                                panelManager.removePanelEverywhere(modelData.id)
                                customWinMenu.hiddenList = panelManager.hiddenPanels
                                panelListRepeater.model = customWinMenu._filteredPanels()
                            }
                            ToolTip.visible: containsMouse
                            ToolTip.text: "Eliminar «" + modelData.name + "» del menú y de los docks"
                            ToolTip.delay: 400
                        }
                    }

                    MouseArea {
                        id: panelToggleMa
                        anchors.fill: parent
                        anchors.rightMargin: 28
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panelManager.togglePanel(modelData.id)
                        }
                    }
                }
            }

            // Separator (only if there are hidden panels)
            Rectangle {
                width: parent.width
                height: 1
                color: "#2d2d34"
                anchors.horizontalCenter: parent.horizontalCenter
                visible: customWinMenu._hiddenPanelDetails().length > 0
            }

            // "Mostrar paneles ocultos" submenu trigger (only if there are hidden)
            Rectangle {
                id: restoreSubMenuTrigger
                width: parent.width
                height: 30
                visible: customWinMenu._hiddenPanelDetails().length > 0
                radius: 6
                color: restoreTriggerMa.containsMouse || studioLayout.hiddenPanelsOpen
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                border.color: restoreTriggerMa.containsMouse || studioLayout.hiddenPanelsOpen
                              ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text {
                        text: "🔄 Mostrar paneles ocultos (" + customWinMenu._hiddenPanelDetails().length + ")"
                        color: restoreTriggerMa.containsMouse ? "white" : "#ddd"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "▶"
                        color: "#888"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: restoreTriggerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleRestoreMenu()
                    onEntered: toggleRestoreMenu()

                    function toggleRestoreMenu() {
                        var pt = restoreSubMenuTrigger.mapToItem(studioLayout, restoreSubMenuTrigger.width + 4, -8)
                        studioLayout.hiddenPanelsX = pt.x
                        studioLayout.hiddenPanelsY = pt.y
                        studioLayout.hiddenPanelsOpen = true
                    }
                }
            }

            // Bottom hint
            Text {
                width: parent.width
                height: 22
                visible: customWinMenu._filteredPanels().length > 0
                text: "Clic = abrir/cerrar · ✕ = eliminar del menú"
                color: "#555"
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Auto-focus the search field when the menu opens
        Connections {
            target: studioLayout
            function onWinMenuOpenChanged() {
                if (studioLayout.winMenuOpen) {
                    Qt.callLater(function() { winSearch.forceActiveFocus() })
                } else {
                    winSearch.text = ""
                }
            }
        }
    }

    // 3b. The "Hidden Panels" Restore Submenu (flyout)
    Rectangle {
        id: customHiddenPanelsMenu
        z: 9999
        visible: studioLayout.winMenuOpen && studioLayout.hiddenPanelsOpen
        x: studioLayout.hiddenPanelsX
        y: studioLayout.hiddenPanelsY
        width: 260
        height: hiddenCol.height + 16
        color: "#18181c"
        border.color: "#3a3a40"
        border.width: 1
        radius: 8

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 24
            shadowColor: "#88000000"
            shadowVerticalOffset: 4
        }

        Column {
            id: hiddenCol
            width: parent.width - 12
            anchors.centerIn: parent
            spacing: 2

            Text {
                width: parent.width
                height: 26
                text: "PANELES OCULTOS"
                color: "#888"
                font.pixelSize: 9
                font.letterSpacing: 1
                font.weight: Font.Bold
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#2d2d34"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Repeater {
                model: customWinMenu._hiddenPanelDetails()
                delegate: Rectangle {
                    width: parent.width
                    height: 30
                    radius: 6
                    color: restoreItemMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                    border.color: restoreItemMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                    border.width: 1

                    Text {
                        text: modelData.name
                        color: restoreItemMa.containsMouse ? "white" : "#bbb"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                    }
                    Text {
                        text: "+ Agregar"
                        color: accentColor
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        opacity: restoreItemMa.containsMouse ? 1.0 : 0.7
                    }

                    MouseArea {
                        id: restoreItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panelManager.restorePanel(modelData.id)
                            customWinMenu.hiddenList = panelManager.hiddenPanels
                            panelListRepeater.model = customWinMenu._filteredPanels()
                            // Close the submenu if no more hidden panels
                            if (customWinMenu._hiddenPanelDetails().length === 0) {
                                studioLayout.hiddenPanelsOpen = false
                            }
                        }
                        ToolTip.visible: containsMouse
                        ToolTip.text: "Restaurar «" + modelData.name + "» al dock lateral"
                        ToolTip.delay: 400
                    }
                }
            }

            // Restore-all button
            Rectangle {
                visible: customWinMenu._hiddenPanelDetails().length > 1
                width: parent.width
                height: 30
                radius: 6
                color: restoreAllMa.containsMouse ? "#1f1f24" : "transparent"
                border.color: restoreAllMa.containsMouse ? "#3a3a40" : "transparent"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Restaurar todos"
                    color: accentColor
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: restoreAllMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        panelManager.clearHiddenPanels()
                        customWinMenu.hiddenList = []
                        panelListRepeater.model = customWinMenu._filteredPanels()
                        studioLayout.hiddenPanelsOpen = false
                    }
                }
            }
        }
    }

    // 4. The Workspace Submenu (Flyout)
    Rectangle {
        id: customWsSubMenu
        z: 9999
        visible: studioLayout.winMenuOpen && studioLayout.wsSubMenuOpen
        x: studioLayout.wsSubMenuX
        y: studioLayout.wsSubMenuY
        width: 240
        height: wsSubCol.height + 16
        color: "#18181c"
        border.color: "#3a3a40"
        border.width: 1
        radius: 8
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 24
            shadowColor: "#88000000"
            shadowVerticalOffset: 4
        }
        
        Column {
            id: wsSubCol
            width: parent.width - 12
            anchors.centerIn: parent
            spacing: 2
            
            // Volver a la disposición básica
            Rectangle {
                width: parent.width; height: 30; radius: 6
                color: resetMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                border.color: resetMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                border.width: 1
                Text {
                    text: "Volver a la disposición básica"
                    color: resetMa.containsMouse ? "white" : "#ddd"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                }
                MouseArea {
                    id: resetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        panelManager.resetCurrentWorkspace()
                        studioLayout.winMenuOpen = false
                        studioLayout.wsSubMenuOpen = false
                    }
                }
            }
            
            // Volver a cargar espacio de trabajo
            Rectangle {
                width: parent.width; height: 30; radius: 6
                color: reloadMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                border.color: reloadMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                border.width: 1
                Text {
                    text: "Volver a cargar espacio de trabajo"
                    color: reloadMa.containsMouse ? "white" : "#ddd"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                }
                MouseArea {
                    id: reloadMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        panelManager.reloadCurrentWorkspace()
                        studioLayout.winMenuOpen = false
                        studioLayout.wsSubMenuOpen = false
                    }
                }
            }
            
            // Registrar espacio de trabajo
            Rectangle {
                width: parent.width; height: 30; radius: 6
                color: regMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                border.color: regMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                border.width: 1
                Text {
                    text: "Registrar espacio de trabajo..."
                    color: regMa.containsMouse ? "white" : "#ddd"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                }
                MouseArea {
                    id: regMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        studioLayout.winMenuOpen = false
                        studioLayout.wsSubMenuOpen = false
                        registerWorkspaceDialog.open()
                    }
                }
            }
            
            // Gestionar espacios de trabajo
            Rectangle {
                width: parent.width; height: 30; radius: 6
                color: manageMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                border.color: manageMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                border.width: 1
                Text {
                    text: "Gestionar espacios de trabajo..."
                    color: manageMa.containsMouse ? "white" : "#ddd"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                }
                MouseArea {
                    id: manageMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        studioLayout.winMenuOpen = false
                        studioLayout.wsSubMenuOpen = false
                        manageWorkspacesDialog.open()
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: parent.width; height: 1; color: "#2d2d34"
            }
            
            // List of available workspaces
            Repeater {
                model: panelManager ? panelManager.availableWorkspaces : null
                delegate: Rectangle {
                    width: parent.width; height: 30; radius: 6
                    color: wsItMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : "transparent"
                    border.color: wsItMa.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.8) : "transparent"
                    border.width: 1
                    
                    Text {
                        text: modelData
                        color: panelManager && modelData === panelManager.activeWorkspace ? accentColor : (wsItMa.containsMouse ? "white" : "#ddd")
                        font.pixelSize: 12
                        font.weight: panelManager && modelData === panelManager.activeWorkspace ? Font.Bold : Font.Medium
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 28
                    }
                    
                    Text {
                        visible: panelManager && modelData === panelManager.activeWorkspace
                        text: "✓"
                        color: accentColor
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                    }
                    
                    MouseArea {
                        id: wsItMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            panelManager.loadWorkspace(modelData)
                            studioLayout.winMenuOpen = false
                            studioLayout.wsSubMenuOpen = false
                        }
                    }
                }
            }
        }
    }

    // 5. Register Workspace Dialog
    Dialog {
        id: registerWorkspaceDialog
        title: "Registrar espacio de trabajo"
        anchors.centerIn: parent
        width: 320
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: "#18181c"
            border.color: "#3a3a40"
            border.width: 1
            radius: 12
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 24
                shadowColor: "#bb000000"
            }
        }
        
        header: Rectangle {
            color: "#111114"
            height: 40
            radius: 12
            clip: true
            Text {
                text: "Registrar espacio de trabajo"
                color: "white"
                font.pixelSize: 14
                font.weight: Font.Bold
                anchors.centerIn: parent
            }
            Rectangle { width: parent.width; height: 1; color: "#2d2d34"; anchors.bottom: parent.bottom }
        }
        
        contentItem: ColumnLayout {
            spacing: 12
            anchors.margins: 12
            
            Text {
                text: "Nombre del espacio de trabajo:"
                color: "#aaa"
                font.pixelSize: 12
            }
            
            TextField {
                id: wsNameInput
                Layout.fillWidth: true
                color: "white"
                font.pixelSize: 13
                placeholderText: "Mi Espacio Personal"
                placeholderTextColor: "#555"
                selectByMouse: true
                
                background: Rectangle {
                    color: "#0a0a0d"
                    border.color: wsNameInput.activeFocus ? accentColor : "#3a3a40"
                    border.width: 1
                    radius: 6
                }
                
                onAccepted: {
                    if (wsNameInput.text.trim() !== "") {
                        panelManager.registerWorkspace(wsNameInput.text.trim())
                        wsNameInput.text = ""
                        registerWorkspaceDialog.close()
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 8
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 80; height: 28; radius: 6
                    color: "transparent"
                    border.color: "#3a3a40"
                    border.width: 1
                    Text { text: "Cancelar"; color: "#aaa"; font.pixelSize: 12; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: registerWorkspaceDialog.close()
                    }
                }
                
                Rectangle {
                    width: 80; height: 28; radius: 6
                    color: wsNameInput.text.trim() === "" ? "#333" : (regBtnMa.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor)
                    opacity: wsNameInput.text.trim() === "" ? 0.5 : 1.0
                    Text { text: "Aceptar"; color: "white"; font.pixelSize: 12; font.weight: Font.Bold; anchors.centerIn: parent }
                    MouseArea {
                        id: regBtnMa
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        enabled: wsNameInput.text.trim() !== ""
                        onClicked: {
                            panelManager.registerWorkspace(wsNameInput.text.trim())
                            wsNameInput.text = ""
                            registerWorkspaceDialog.close()
                        }
                    }
                }
            }
        }
    }

    // 6. Manage Workspaces Dialog
    Dialog {
        id: manageWorkspacesDialog
        title: "Gestionar espacios de trabajo"
        anchors.centerIn: parent
        width: 360
        height: 380
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: "#18181c"
            border.color: "#3a3a40"
            border.width: 1
            radius: 12
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 24
                shadowColor: "#bb000000"
            }
        }
        
        header: Rectangle {
            color: "#111114"
            height: 40
            radius: 12
            clip: true
            Text {
                text: "Gestionar espacios de trabajo"
                color: "white"
                font.pixelSize: 14
                font.weight: Font.Bold
                anchors.centerIn: parent
            }
            Rectangle { width: parent.width; height: 1; color: "#2d2d34"; anchors.bottom: parent.bottom }
        }
        
        contentItem: ColumnLayout {
            spacing: 12
            anchors.margins: 12
            
            Text {
                text: "Espacios de trabajo personalizados:"
                color: "#aaa"
                font.pixelSize: 12
                Layout.topMargin: 4
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ListView {
                    id: customWsListView
                    model: panelManager ? panelManager.availableWorkspaces : null
                    spacing: 4
                    delegate: Item {
                        width: customWsListView.width
                        height: visible ? 34 : 0
                        visible: modelData !== "Ilustración" && modelData !== "Manga/Comic" && modelData !== "Animación"
                        clip: true
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "#111114"
                            border.color: "#2d2d34"
                            border.width: 1
                            radius: 6
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                
                                Text {
                                    text: modelData
                                    color: "white"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                }
                                
                                Rectangle {
                                    width: 24; height: 24; radius: 4
                                    color: trashMa.containsMouse ? "#d9534f" : "#2a2a30"
                                    border.color: trashMa.containsMouse ? "#d43f3a" : "#3a3a40"
                                    border.width: 1
                                    
                                    Text {
                                        text: "✕"
                                        color: "white"
                                        font.pixelSize: 11
                                        anchors.centerIn: parent
                                    }
                                    
                                    MouseArea {
                                        id: trashMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            panelManager.deleteWorkspace(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Text {
                visible: {
                    if (!panelManager) return false
                    var avail = panelManager.availableWorkspaces;
                    var hasCustom = false;
                    for (var i = 0; i < avail.length; i++) {
                        if (avail[i] !== "Ilustración" && avail[i] !== "Manga/Comic" && avail[i] !== "Animación") {
                            hasCustom = true;
                            break;
                        }
                    }
                    return !hasCustom;
                }
                text: "No hay espacios de trabajo personalizados."
                color: "#555"
                font.pixelSize: 12
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 80; height: 28; radius: 6
                    color: accentColor
                    Text { text: "Cerrar"; color: "white"; font.pixelSize: 12; font.weight: Font.Bold; anchors.centerIn: parent }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: manageWorkspacesDialog.close()
                    }
                }
            }
        }
    }
    // --- TOOLBAR (Canvas Tools) Full-height docked (Movable, Dockable Left/Right, Minimizable) ---
    Rectangle {
        id: toolsToolbar
        width: 48
        property bool isToolbarFloating: false
        property string dockedSide: "left"
        property bool isMinimized: false

        Connections {
            target: studioLayout
            ignoreUnknownSignals: true
            function onWidthChanged() {
                if (toolsToolbar.isToolbarFloating) {
                    toolsToolbar.x = Math.max(0, Math.min(toolsToolbar.x, studioLayout.width - toolsToolbar.width))
                }
            }
            function onHeightChanged() {
                if (toolsToolbar.isToolbarFloating) {
                    toolsToolbar.y = Math.max(0, Math.min(toolsToolbar.y, studioLayout.height - toolsToolbar.height))
                }
            }
        }

        // Helper calculations for left and right docking snap points
        readonly property real leftSnapX: (leftIconBar ? leftIconBar.width : 0) + (leftDock ? leftDock.width : 0) + ((leftIconBar2 && leftIconBar2.visible) ? leftIconBar2.width : 0) + (leftDock2 ? leftDock2.width : 0)
        readonly property real rightSnapX: studioLayout.width - ((rightIconBar ? rightIconBar.width : 0) + (rightDock ? rightDock.width : 0) + ((rightIconBar2 && rightIconBar2.visible) ? rightIconBar2.width : 0) + (rightDock2 ? rightDock2.width : 0)) - width

        // Full height when docked; compact when floating; 48px when minimized
        height: isMinimized 
            ? 48
            : (isToolbarFloating
                ? Math.min(toolsCol.implicitHeight + 150, studioLayout.height * 0.8)
                : (studioLayout.height - (studioTabBar.visible ? studioTabBar.height : 0) - studioInfoBar.height))
        color: mainWindow ? mainWindow.colorPanel : "#0c0c0f"
        radius: (isToolbarFloating || isMinimized) ? 8 : 0
        border.color: (isToolbarFloating || isMinimized) ? (mainWindow ? mainWindow.colorBorder : "#333") : "transparent"
        border.width: (isToolbarFloating || isMinimized) ? 1 : 0
        z: 2500
        
        // Border line when docked (left side if docked right, right side if docked left)
        Rectangle {
            visible: !toolsToolbar.isToolbarFloating && !toolsToolbar.isMinimized
            width: 1; height: parent.height
            anchors.left: toolsToolbar.dockedSide === "right" ? parent.left : undefined
            anchors.right: toolsToolbar.dockedSide === "left" ? parent.right : undefined
            color: mainWindow ? mainWindow.colorBorder : "#1a1a1e"
        }

        transform: Translate {
            id: toolsTranslate
            x: 0
        }
        opacity: 1.0
        
        // Initial / Docked positioning
        x: isToolbarFloating ? x : (dockedSide === "left" ? leftSnapX : rightSnapX)
        y: isToolbarFloating ? y : (studioInfoBar.height + (studioTabBar.visible ? studioTabBar.height : 0))
        
        // Shadow when floating
        layer.enabled: isToolbarFloating || isMinimized
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 15; shadowColor: "#80000000"; shadowVerticalOffset: 4 }
        
        // Persistent grip area (always visible and draggable when not minimized)
        Rectangle {
            id: toolbarGrip
            width: parent.width; height: 20
            color: "transparent"
            anchors.top: parent.top
            visible: !toolsToolbar.isMinimized
            
            Row {
                spacing: 2; anchors.centerIn: parent
                opacity: toolsToolbar.isToolbarFloating ? 0.9 : 0.4
                Repeater { model: 4; Rectangle { width: 3; height: 3; radius: 1.5; color: hoverGrip.containsMouse ? "#888" : "#444" } }
            }
            
            MouseArea {
                id: hoverGrip
                anchors.fill: parent; hoverEnabled: true
                cursorShape: hoverGrip.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: toolsToolbar
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: studioLayout.width - toolsToolbar.width
                drag.minimumY: 0
                drag.maximumY: studioLayout.height - toolsToolbar.height
                
                onPressed: toolsToolbar.isToolbarFloating = true
                onReleased: {
                    var lSnap = toolsToolbar.leftSnapX
                    var rSnap = toolsToolbar.rightSnapX
                    if (toolsToolbar.x < lSnap + 50) {
                        toolsToolbar.isToolbarFloating = false
                        toolsToolbar.dockedSide = "left"
                        toolsToolbar.x = Qt.binding(function() { return toolsToolbar.leftSnapX })
                        toolsToolbar.y = Qt.binding(function() { return studioInfoBar.height + (studioTabBar.visible ? studioTabBar.height : 0) })
                    } else if (toolsToolbar.x > rSnap - 50) {
                        toolsToolbar.isToolbarFloating = false
                        toolsToolbar.dockedSide = "right"
                        toolsToolbar.x = Qt.binding(function() { return toolsToolbar.rightSnapX })
                        toolsToolbar.y = Qt.binding(function() { return studioInfoBar.height + (studioTabBar.visible ? studioTabBar.height : 0) })
                    } else {
                        toolsToolbar.isToolbarFloating = true
                    }
                }
            }
        }

        // ── MINIMIZED VIEW ──
        Item {
            anchors.fill: parent
            visible: toolsToolbar.isMinimized
            
            // Drag support even when minimized!
            MouseArea {
                anchors.fill: parent
                drag.target: toolsToolbar
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: studioLayout.width - toolsToolbar.width
                drag.minimumY: 0
                drag.maximumY: studioLayout.height - toolsToolbar.height
                onPressed: toolsToolbar.isToolbarFloating = true
                onReleased: {
                    var lSnap = toolsToolbar.leftSnapX
                    var rSnap = toolsToolbar.rightSnapX
                    if (toolsToolbar.x < lSnap + 50) {
                        toolsToolbar.isToolbarFloating = false
                        toolsToolbar.dockedSide = "left"
                        toolsToolbar.x = Qt.binding(function() { return toolsToolbar.leftSnapX })
                        toolsToolbar.y = Qt.binding(function() { return studioInfoBar.height + (studioTabBar.visible ? studioTabBar.height : 0) })
                    } else if (toolsToolbar.x > rSnap - 50) {
                        toolsToolbar.isToolbarFloating = false
                        toolsToolbar.dockedSide = "right"
                        toolsToolbar.x = Qt.binding(function() { return toolsToolbar.rightSnapX })
                        toolsToolbar.y = Qt.binding(function() { return studioInfoBar.height + (studioTabBar.visible ? studioTabBar.height : 0) })
                    } else {
                        toolsToolbar.isToolbarFloating = true
                    }
                }
            }

            // Expand Button / Active Tool Display
            Rectangle {
                width: 36; height: 36
                radius: 18
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                border.color: accentColor
                border.width: 1
                anchors.centerIn: parent
                
                Image {
                    source: (canvasPage && studioLayout.toolsModel) ? (mainWindow ? mainWindow.iconPath(studioLayout.toolsModel.get(canvasPage.activeToolIdx).icon) : ("image://icons/" + studioLayout.toolsModel.get(canvasPage.activeToolIdx).icon)) : ""
                    width: 20; height: 20
                    anchors.centerIn: parent
                }
                
                // Small indicator badge
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: accentColor
                    anchors.top: parent.top; anchors.right: parent.right
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toolsToolbar.isMinimized = false
                }
            }
        }

        // ── SINGLE COLUMN LAYOUT: tools centered, orbs pinned at bottom ──
        ColumnLayout {
            id: toolbarInnerLayout
            anchors.fill: parent
            anchors.topMargin: 20
            anchors.bottomMargin: 8
            spacing: 0
            visible: !toolsToolbar.isMinimized

            // Minimize Button (Header Control)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 32; Layout.preferredHeight: 18
                color: "transparent"
                radius: 4
                
                Text {
                    anchors.centerIn: parent
                    text: "─"
                    color: hoverMin.containsMouse ? accentColor : "#777"
                    font.bold: true
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: hoverMin
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: toolsToolbar.isMinimized = true
                }
                
                ToolTip.visible: hoverMin.containsMouse
                ToolTip.text: "Minimizar Barra"
                ToolTip.delay: 500
            }

            // Flexible top spacer
            Item { Layout.fillWidth: true; Layout.fillHeight: true }

            // ── TOOLS ──
            ColumnLayout {
                id: toolsCol
                Layout.alignment: Qt.AlignHCenter
                spacing: 3

                Repeater {
                    model: studioLayout.toolsModel
                    delegate: Rectangle {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignHCenter
                        radius: 10
                        color: (canvasPage && index === canvasPage.activeToolIdx)
                            ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.28)
                            : (hoverMa.containsMouse ? (mainWindow ? mainWindow.colorCard : "#1c1c20") : "transparent")
                        border.color: (canvasPage && index === canvasPage.activeToolIdx) ? accentColor : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            visible: canvasPage && index === canvasPage.activeToolIdx
                            width: 3; height: 3; radius: 1.5; color: accentColor
                            anchors.left: parent.left; anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Image {
                            source: mainWindow ? mainWindow.iconPath(model.icon) : ("image://icons/" + model.icon)
                            width: 20; height: 20; anchors.centerIn: parent
                            opacity: (canvasPage && index === canvasPage.activeToolIdx) ? 1.0 : 0.6
                        }
                        ToolTip.visible: hoverMa.containsMouse
                        ToolTip.text: model.label || ""
                        ToolTip.delay: 700
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
                                            canvasPage.showSubTools = !canvasPage.showSubTools
                                            if (canvasPage.showSubTools && typeof subToolBar !== "undefined") {
                                                subToolBar.yLevel = parent.mapToItem(canvasPage, 0, 0).y
                                                subToolBar.isFromStudio = true
                                                subToolBar.studioToolX = toolsToolbar.x
                                            }
                                        } else {
                                            canvasPage.activeToolIdx = index
                                            canvasPage.activeSubToolIdx = 0
                                            if (mainCanvas) mainCanvas.currentTool = model.name
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

            // Flexible bottom spacer
            Item { Layout.fillWidth: true; Layout.fillHeight: true }

            // Divider
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 28; Layout.preferredHeight: 1
                color: mainWindow ? mainWindow.colorBorder : "#333"
            }
            Item { Layout.preferredWidth: 1; Layout.preferredHeight: 8 }

            // ── COLOR ORBS (always at bottom) ──
            Item {
                id: colorOrbsSection
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 46
                Layout.preferredHeight: 58

                // Secondary color (back/bottom-right)
                Rectangle {
                    id: studioBarWell1
                    width: 24; height: 24; radius: 12
                    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                    color: studioLayout.secondaryColor
                    border.color: mainWindow ? mainWindow.colorBorder : "#555"
                    border.width: 1
                    z: studioLayout.activeColorSlot === 1 ? 5 : 1
                    scale: studioLayout.activeColorSlot === 1 ? 1.15 : 1.0
                    opacity: studioLayout.activeColorSlot === 1 ? 1.0 : 0.72
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        border.color: accentColor; border.width: 2; color: "transparent"
                        visible: studioLayout.activeColorSlot === 1 && mainWindow && mainWindow.showColor
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: studioLayout.colorOrbClicked(1) }
                    ToolTip.visible: studioWell1Hover.containsMouse; ToolTip.text: "Color Secundario"
                    MouseArea { id: studioWell1Hover; anchors.fill: parent; hoverEnabled: true; enabled: false }
                }

                // Primary color (front/top-left)
                Rectangle {
                    id: studioBarWell0
                    width: 24; height: 24; radius: 12
                    anchors.left: parent.left; anchors.top: parent.top
                    color: studioLayout.primaryColor
                    border.color: mainWindow ? mainWindow.colorBorder : "#555"
                    border.width: 1
                    z: studioLayout.activeColorSlot === 0 ? 5 : 2
                    scale: studioLayout.activeColorSlot === 0 ? 1.15 : 1.0
                    opacity: studioLayout.activeColorSlot === 0 ? 1.0 : 0.72
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        border.color: accentColor; border.width: 2; color: "transparent"
                        visible: studioLayout.activeColorSlot === 0 && mainWindow && mainWindow.showColor
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: studioLayout.colorOrbClicked(0) }
                    ToolTip.visible: studioWell0Hover.containsMouse; ToolTip.text: "Color Primario"
                    MouseArea { id: studioWell0Hover; anchors.fill: parent; hoverEnabled: true; enabled: false }
                }

                // Transparency orb (small, bottom-right)
                Rectangle {
                    id: studioTransWell
                    width: 18; height: 18; radius: 9
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 26
                    clip: true
                    color: mainWindow ? mainWindow.colorCard : "#1a1a1f"
                    border.color: studioLayout.isTransparentMode ? accentColor : (mainWindow ? Qt.rgba(1,1,1,0.2) : "#555")
                    border.width: studioLayout.isTransparentMode ? 1.5 : 1
                    scale: studioLayout.isTransparentMode ? 1.15 : 1.0
                    z: 3
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Canvas {
                        anchors.fill: parent
                        opacity: studioLayout.isTransparentMode ? 1.0 : 0.45
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.beginPath()
                            ctx.arc(width/2, height/2, width/2, 0, 2*Math.PI)
                            ctx.clip()
                            var sz = 3
                            ctx.fillStyle = "#ffffff"; ctx.fillRect(0,0,width,height)
                            ctx.fillStyle = "#cccccc"
                            for (var cy=0; cy<height; cy+=sz)
                                    for (var cx=0; cx<width; cx+=sz)
                                    if (((cx+cy)/sz)%2===0) ctx.fillRect(cx,cy,sz,sz)
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: studioLayout.transparencyOrbClicked() }
                    ToolTip.visible: studioTransHover.containsMouse; ToolTip.text: "Transparencia"
                    MouseArea { id: studioTransHover; anchors.fill: parent; hoverEnabled: true; enabled: false }
                }
            }
        }
    }
}
