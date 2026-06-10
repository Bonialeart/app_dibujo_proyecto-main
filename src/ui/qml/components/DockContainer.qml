import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Rectangle {
    id: root
    
    // Props
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0
    property string dockSide: "left"
    property var manager: null
    property var dockModel: {
        if (!manager) return null
        if (dockSide === "left") return manager.leftDockModel
        if (dockSide === "left2") return manager.leftDockModel2
        if (dockSide === "right") return manager.rightDockModel
        if (dockSide === "right2") return manager.rightDockModel2
        if (dockSide === "bottom") return manager.bottomDockModel
        return null
    }
    property var mainCanvas: null
    property int expandedWidth: 320
    property bool isCollapsed: true
    property bool isDragHover: false
    property int hoverIndex: 0
    property string dragMode: "insert" // "insert" or "group"
    
    property color accentColor: "#6366f1"
    property string tabDisplayMode: "both" // "both", "icon", "text"
    
    readonly property var allPanelsList: [
        { id: "brushes", name: "Pinceles" },
        { id: "settings", name: "Ajuste de herramienta" },
        { id: "color", name: "Color" },
        { id: "layers", name: "Capas" },
        { id: "navigator", name: "Navegador" },
        { id: "history", name: "Historial" },
        { id: "reference", name: "Referencia" },
        { id: "timeline", name: "Línea de Tiempo" }
    ]
    
    function isPanelActiveAnywhere(pId) {
        if (!manager) return false
        var models = [manager.leftDockModel, manager.leftDockModel2, manager.rightDockModel, manager.rightDockModel2, manager.bottomDockModel, manager.floatingModel]
        for (var i = 0; i < models.length; i++) {
            var model = models[i]
            if (model) {
                for (var j = 0; j < model.count; j++) {
                    var p = model.get(j)
                    if (p && p.panelId === pId) return p.visible
                }
            }
        }
        return false
    }
    
    property real targetHoverY: {
        var count = dockModel ? dockModel.count : 0
        if (count === 0) return height / 2
        var visibleCount = 0
        for(var i=0; i<count; i++) { if(dockModel.get(i).visible) visibleCount++ }
        if (visibleCount === 0) return height / 2
        var avgH = height / visibleCount
        return Math.max(0, Math.min(visibleCount, hoverIndex)) * avgH
    }
    
    signal toggleCollapse(string panelId)
    signal panelDragStarted(string panelId, string name, string icon, real globalX, real globalY)
    signal panelDragUpdated(real globalX, real globalY)
    signal panelDragEnded(real globalX, real globalY)
    
    property bool isBottom: dockSide === "bottom"
    
    width: isBottom ? parent.width : ((isCollapsed && !isDragHover) ? 0 : expandedWidth)
    height: isBottom ? ((isCollapsed && !isDragHover) ? 12 : expandedHeight) : parent.height
    Layout.fillWidth: isBottom
    Layout.preferredWidth: isBottom ? parent.width : width
    Layout.minimumWidth: isBottom ? -1 : width
    Layout.maximumWidth: isBottom ? -1 : width
    Layout.preferredHeight: isBottom ? height : -1
    
    property int expandedHeight: 250
    color: mainWindow ? mainWindow.colorPanel : "#0a0a0d"
    border.color: isCollapsed && !isBottom ? "transparent" : (mainWindow ? mainWindow.colorBorder : "#2a2a2d")
    border.width: isCollapsed && isBottom ? 0 : 1
    
    Behavior on width { 
        enabled: !resizerMa.pressed && !isBottom
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
    }
    Behavior on height {
        enabled: isBottom && !(bottomResizerMa.pressed || bottomResizerMa.dragActive)
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
    }
    
    visible: isBottom ? true : width > 0
    clip: true
    
    Rectangle { anchors.fill: parent; color: "transparent"; border.color: mainWindow ? mainWindow.colorBorder : "#1affffff"; border.width: 1; visible: !isCollapsed || !isBottom }
    
    // Drag Hover Indicator
    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: root.dragMode === "group" ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.05)
        border.color: root.isDragHover ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent"
        border.width: root.isDragHover ? (root.dragMode === "group" ? 2 : 1) : 0
        visible: root.isDragHover
        z: 90
    }
    
    // Premium Grouping Highlight
    Rectangle {
        visible: root.isDragHover && root.dragMode === "group"
        height: {
            if (!dockModel) return 0
            var vCount = 0; for(var i=0; i<dockModel.count; i++) if(dockModel.get(i).visible) vCount++;
            return vCount > 0 ? (parent.height / vCount) - 10 : 0
        }
        width: parent.width - 20
        x: 10
        y: {
            if (!dockModel) return 0
            var vCount = 0; for(var i=0; i<dockModel.count; i++) if(dockModel.get(i).visible) vCount++;
            return vCount > 0 ? (root.hoverIndex * (parent.height / vCount)) + 5 : 0
        }
        color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1)
        border.color: accentColor
        border.width: 2
        radius: 8
        z: 95
        
        Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
        
        Text {
            text: "Group with Panel"
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 12
            font.weight: Font.Bold
            
            Rectangle {
                anchors.fill: parent; anchors.margins: -4; z: -1
                color: "#1a1a1e"; radius: 4; border.color: accentColor; border.width: 1
            }
        }
    }
    
    // Premium Insertion Line
    Rectangle {
        visible: root.isDragHover && root.dragMode === "insert"
        height: 4
        width: parent.width - 16
        x: 8
        y: root.targetHoverY - 2
        color: accentColor
        radius: 2
        z: 200
        
        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuart }
        }
        
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 15; shadowColor: accentColor }
        
        Rectangle {
            anchors.centerIn: parent
            width: 70; height: 22; radius: 11
            color: "#1a1a1e"
            border.color: accentColor; border.width: 1.5
            Text {
                text: root.hoverIndex === 0 ? "Top" : "Insert Here"
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: !root.isCollapsed
        
        // Dock Header (Collapse All Button)
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            color: mainWindow ? mainWindow.colorBg : "#0d0d10"
            visible: !root.isCollapsed
            
            Rectangle {
                width: 28; height: 28; radius: 14
                color: collAllMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e5e7eb" : "#252528") : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: isBottom ? undefined : ((root.dockSide.indexOf("left") !== -1) ? parent.right : undefined)
                anchors.left: isBottom ? parent.left : ((root.dockSide.indexOf("right") !== -1) ? parent.left : undefined)
                anchors.horizontalCenter: isBottom ? parent.horizontalCenter : undefined
                anchors.rightMargin: 4; anchors.leftMargin: 4
                
                Image {
                    source: mainWindow ? mainWindow.iconPath("chevron-left.svg") : "image://icons/chevron-left.svg"
                    width: 16; height: 16; anchors.centerIn: parent
                    opacity: 0.6; smooth: true; mipmap: true
                    rotation: isBottom ? 90 : ((root.dockSide.indexOf("left") !== -1) ? 0 : 180)
                }
                
                MouseArea {
                    id: collAllMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.manager.collapseDock(root.dockSide)
                }
            }
            
            Rectangle { width: parent.width; height: 1; color: mainWindow ? mainWindow.colorBorder : "#1c1c1f"; anchors.bottom: parent.bottom }
        }

        SplitView {
            id: splitView
            Layout.fillWidth: true; Layout.fillHeight: true
            orientation: Qt.Vertical
        
            // Handle split separators premium styling
            handle: Rectangle {
                implicitWidth: parent.width; implicitHeight: 4
                color: SplitHandle.hovered || SplitHandle.pressed ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : "transparent"
                Rectangle { 
                    width: parent.width; height: 1; color: SplitHandle.hovered || SplitHandle.pressed ? root.accentColor : "#1c1c1f"; anchors.centerIn: parent 
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 10; shadowColor: root.accentColor; opacity: (SplitHandle.hovered || SplitHandle.pressed ? 0.6 : 0) }
                }
            }

            Repeater {
                model: root.dockModel
                
                delegate: Rectangle {
                    property string delegatePanelId: model.panelId
                    property string delegateName: model.name || "Panel"
                    property string delegateIcon: model.icon || ""
                    property string delegateSource: model.source || ""
                    property string delegateGroupId: model.groupId !== undefined ? model.groupId : ""
                    property int delegateIndex: index

                    property bool isFirstInGroup: {
                        if (delegateGroupId === "") return true;
                        for (var i = 0; i < delegateIndex; i++) {
                            var otherGid = root.dockModel.get(i).groupId !== undefined ? root.dockModel.get(i).groupId : "";
                            if (otherGid === delegateGroupId) return false;
                        }
                        return true;
                    }
                    
                    // If it's a grouped panel, only the FIRST item draws the UI and height. The others are completely hidden.
                    property bool isPanelVisible: (model.visible !== undefined ? model.visible : true) && isFirstInGroup

                    visible: isPanelVisible
                    implicitWidth: splitView.width
                    height: isPanelVisible ? undefined : 0
                    SplitView.fillHeight: isPanelVisible
                    SplitView.minimumHeight: isPanelVisible ? (root.isBottom ? 100 : 280) : 0
                    color: "#151518"
                    clip: true
                    
                    // For a grouped item, determine WHICH panel within the group is currently active
                    property string activeTabId: {
                        if (delegateGroupId === "") return delegatePanelId;
                        var currentlyActive = root.manager ? root.manager.activeGroupTabs[delegateGroupId] : null;
                        if (currentlyActive) return currentlyActive;
                        // Fallback to first
                        return delegatePanelId; 
                    }
                    
                        Rectangle {
                            id: panelHeader
                            width: parent.width; height: 32
                            color: "#0c0c0f" // Slightly darker for clear contrast with tab content
                            z: 5
                            
                            Rectangle {
                                width: parent.width; height: 2; anchors.bottom: parent.bottom; color: "#111114" // Smooth shadow transition
                            }
                            Rectangle {
                                width: parent.width; height: 1; anchors.bottom: parent.bottom; color: "#1c1c1f" // Hard separator line
                            }
                        
                        RowLayout {
                            anchors.fill: parent; spacing: 0
                            
                            Row {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                clip: true
                                
                                Repeater {
                                    model: {
                                        if (delegateGroupId === "") return [{pId: delegatePanelId, name: delegateName, icon: delegateIcon, isSingle: true}];
                                        var arr = [];
                                        for(var i=0; i<root.dockModel.count; i++) {
                                            var item = root.dockModel.get(i);
                                            if (item.groupId === delegateGroupId) {
                                                arr.push({pId: item.panelId, name: item.name, icon: item.icon, isSingle: false});
                                            }
                                        }
                                        return arr;
                                    }
                                    
                                    delegate: Rectangle {
                                        id: tabItem
                                        property bool isActiveTab: modelData.pId === activeTabId
                                        height: parent.height
                                        width: tabContentRow.width + 16 * root.uiScale
                                        color: isActiveTab ? "#151518" : (tabMa.containsMouse ? "#121215" : "transparent")
                                        
                                        // Slight rounding at the top for tabs
                                        radius: isActiveTab ? 5 : 0
                                        Rectangle { width: parent.width; height: 5; anchors.bottom: parent.bottom; color: parent.color; visible: isActiveTab }
                                        
                                        // Separator between inactive tabs
                                        Rectangle { 
                                            width: 1; height: 12; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; 
                                            color: "#1f1f22"; visible: !isActiveTab
                                        }
                                        
                                        // Top accent glow for active tab
                                        Rectangle { 
                                            width: parent.width - 6; height: 2; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                            radius: 1
                                            color: root.accentColor; visible: isActiveTab 
                                            layer.enabled: true
                                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 10; shadowColor: root.accentColor; shadowVerticalOffset: 1 }
                                        }
                                        
                                        // Bottom seamless cover
                                        Rectangle {
                                            width: parent.width; height: 2; anchors.bottom: parent.bottom
                                            color: "#151518"; visible: isActiveTab; z: 5 // Covers the panelHeader bottom border
                                        }
                                        
                                        Row {
                                            id: tabContentRow
                                            anchors.centerIn: parent
                                            spacing: 6 * root.uiScale
                                            opacity: isActiveTab ? 1.0 : (tabMa.containsMouse ? 0.85 : 0.6)
                                            
                                            Image {
                                                source: (root.tabDisplayMode !== "text" && modelData.icon !== "") ? (mainWindow ? mainWindow.iconPath(modelData.icon) : "image://icons/" + modelData.icon) : ""
                                                width: 13 * root.uiScale; height: 13 * root.uiScale
                                                sourceSize: Qt.size(32, 32); smooth: true; mipmap: true; anchors.verticalCenter: parent.verticalCenter
                                                visible: root.tabDisplayMode !== "text" && modelData.icon !== ""
                                                layer.enabled: isActiveTab
                                                layer.effect: MultiEffect { colorizationColor: root.accentColor; colorization: 1.0 }
                                            }
                                            
                                            Text {
                                                text: modelData.name
                                                color: isActiveTab ? "#ffffff" : "#bbbbbb"
                                                font.pixelSize: 10 * root.uiScale
                                                font.weight: isActiveTab ? Font.Bold : Font.Medium
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: root.tabDisplayMode !== "icon" && modelData.name !== ""
                                            }
                                            
                                            // Close button (x) on the tab!
                                            Rectangle {
                                                id: closeTabBtn
                                                width: 12 * root.uiScale; height: 12 * root.uiScale
                                                radius: 3
                                                color: closeTabMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e5e7eb" : "#2d2d32") : "transparent"
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: isActiveTab || tabMa.containsMouse
                                                
                                                Image {
                                                    source: mainWindow ? mainWindow.iconPath("close.svg") : "image://icons/close.svg"
                                                    width: 7 * root.uiScale; height: 7 * root.uiScale
                                                    anchors.centerIn: parent
                                                    opacity: closeTabMa.containsMouse ? 0.95 : 0.4
                                                    smooth: true; mipmap: true
                                                }
                                                
                                                MouseArea {
                                                    id: closeTabMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.manager.removePanelEverywhere(modelData.pId)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        ToolTip {
                                            id: hoverToolTip
                                            visible: tabMa.containsMouse && !tabMa.isDragging
                                            text: modelData.name
                                            delay: 400
                                            y: parent.height + 4
                                            x: (parent.width - width) / 2
                                            background: Rectangle {
                                                color: "#1e1e24"
                                                border.color: "#3a3a3d"
                                                radius: 6
                                            }
                                            contentItem: Text {
                                                text: hoverToolTip.text
                                                color: "#f0f0f5"
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: tabMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (!modelData.isSingle) root.manager.setActiveTab(delegateGroupId, modelData.pId)
                                            }
                                            
                                            property point startPos
                                            property bool isDragging: false
                                            
                                            onPressed: (mouse) => { startPos = Qt.point(mouse.x, mouse.y); isDragging = false; cursorShape = Qt.ClosedHandCursor }
                                            onPositionChanged: (mouse) => {
                                                if (!pressed) return
                                                if (!isDragging && (Math.abs(mouse.x - startPos.x) > 6 || Math.abs(mouse.y - startPos.y) > 6)) {
                                                    isDragging = true
                                                    var g = mapToGlobal(mouse.x, mouse.y)
                                                    root.panelDragStarted(modelData.pId, modelData.name, modelData.icon, g.x, g.y)
                                                }
                                                if (isDragging) { var g = mapToGlobal(mouse.x, mouse.y); root.panelDragUpdated(g.x, g.y) }
                                            }
                                            onReleased: (mouse) => {
                                                cursorShape = Qt.ArrowCursor
                                                if (isDragging) { var g = mapToGlobal(mouse.x, mouse.y); root.panelDragEnded(g.x, g.y); isDragging = false }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Row {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                Layout.rightMargin: 8
                                spacing: 4
                                
                                Rectangle {
                                    width: 24; height: 24; radius: 6
                                    color: popoutMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e5e7eb" : "#252528") : "transparent"
                                    Image { source: mainWindow ? mainWindow.iconPath("float-window.svg") : "image://icons/float-window.svg"; anchors.centerIn: parent; width: 14; height: 14; opacity: 0.6 }
                                    MouseArea {
                                        id: popoutMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.manager.movePanelToFloat(activeTabId, parent.mapToGlobal(0,0).x - 200, parent.mapToGlobal(0,0).y)
                                    }
                                }
                                
                                Rectangle {
                                    width: 24; height: 24; radius: 6
                                    color: collapseMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e5e7eb" : "#252528") : "transparent"
                                    Image { source: mainWindow ? mainWindow.iconPath("grip.svg") : "image://icons/grip.svg"; anchors.centerIn: parent; width: 14; height: 14; opacity: 0.6 }
                                    MouseArea {
                                        id: collapseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleCollapse(activeTabId)
                                    }
                                }
                                
                                Rectangle {
                                    width: 24; height: 24; radius: 6
                                    color: optionsMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e5e7eb" : "#252528") : "transparent"
                                    Image { source: mainWindow ? mainWindow.iconPath("dots-vertical.svg") : "image://icons/dots-vertical.svg"; anchors.centerIn: parent; width: 14; height: 14; opacity: 0.6 }
                                    MouseArea {
                                        id: optionsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var p = parent.mapToItem(root, 0, parent.height + 4)
                                            optionsPopup.openAt(p.x, p.y, activeTabId, delegateGroupId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // PANEL CONTENT
                    Item {
                        anchors.top: panelHeader.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        
                        Repeater {
                            model: {
                                if (delegateGroupId === "") return [{pId: delegatePanelId, source: delegateSource}];
                                var arr = [];
                                for(var i=0; i<root.dockModel.count; i++) {
                                    var item = root.dockModel.get(i);
                                    if (item.groupId === delegateGroupId) arr.push({pId: item.panelId, source: item.source});
                                }
                                return arr;
                            }
                            delegate: Loader {
                                anchors.fill: parent
                                visible: modelData.pId === activeTabId
                                source: modelData.source || ""
                                active: true // Keep it alive so state isn't lost on tab switch
                                onLoaded: {
                                    if (item) {
                                        if (item.targetCanvas !== undefined) {
                                            item.targetCanvas = Qt.binding(function() { return root.mainCanvas })
                                        }
                                        if (item.colorAccent !== undefined) {
                                            item.colorAccent = root.accentColor
                                        }
                                        if (item.accentColor !== undefined) {
                                            item.accentColor = root.accentColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // --- RESIZER ---

    Rectangle {
        visible: !root.isBottom
        width: 6; height: parent.height
        anchors.right: (dockSide === "left") ? parent.right : undefined
        anchors.left: (dockSide === "right") ? parent.left : undefined
        color: resizerMa.containsMouse || resizerMa.pressed ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : "transparent"
        
        Rectangle { width: 2; height: parent.height; anchors.centerIn: parent; color: resizerMa.containsMouse || resizerMa.pressed ? accentColor : "transparent" }
        
        MouseArea {
            id: resizerMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
            property real startW; property real startGx
            onPressed: (mouse) => { startW = root.expandedWidth; startGx = mapToGlobal(mouse.x, 0).x }
            onPositionChanged: (mouse) => {
                if (pressed) {
                     var diff = mapToGlobal(mouse.x, 0).x - startGx
                     if (dockSide === "left") root.expandedWidth = Math.max(220, Math.min(600, startW + diff))
                     else root.expandedWidth = Math.max(220, Math.min(600, startW - diff))
                }
            }
        }
    }
    
    // --- BOTTOM RESIZER ---
    Rectangle {
        visible: root.isBottom
        height: root.isCollapsed && !bottomResizerMa.pressed ? 12 : 8; width: parent.width
        anchors.top: parent.top
        color: bottomResizerMa.containsMouse || bottomResizerMa.pressed ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : ((root.isCollapsed && !bottomResizerMa.pressed) ? "#0d0d11" : "transparent")
        z: 999
        
        // The subtle timeline tab for when collapsed
        Rectangle {
            visible: root.isCollapsed
            width: 48; height: 3
            color: bottomResizerMa.containsMouse || bottomResizerMa.pressed ? accentColor : "#4a4a55"
            radius: 1.5; anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Regular separator line for when expanded
        Rectangle { 
            visible: !root.isCollapsed
            height: 2; width: parent.width; anchors.centerIn: parent; 
            color: bottomResizerMa.containsMouse || bottomResizerMa.pressed ? accentColor : "transparent" 
        }
        
        MouseArea {
            id: bottomResizerMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeVerCursor
            property real startH; property real startGy
            property bool wasCollapsed: false
            property bool dragActive: false
            
            onPressed: (mouse) => { 
                dragActive = true
                startGy = mapToGlobal(0, mouse.y).y 
                wasCollapsed = root.isCollapsed
                
                if (wasCollapsed) {
                    root.expandedHeight = 12 // Start growing from current visual size seamlessly
                    root.manager.setDockCollapsedByName(root.dockSide, false) // Inform C++ we are now open
                    startH = 12
                } else {
                    startH = root.expandedHeight
                }
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var currentGy = mapToGlobal(0, mouse.y).y
                    var diff = startGy - currentGy
                    var newH = startH + diff
                    
                    if (newH < 80) { // pull down too far = hide
                        if (!root.isCollapsed) root.manager.setDockCollapsedByName(root.dockSide, true)
                        root.expandedHeight = 12 // clamp visual size
                    } else {
                        if (root.isCollapsed) root.manager.setDockCollapsedByName(root.dockSide, false)
                        root.expandedHeight = Math.min(800, newH)
                    }
                }
            }
            onReleased: {
                dragActive = false
                // Auto-snap if too small when released
                if (!root.isCollapsed && root.expandedHeight < 150) {
                    root.manager.setDockCollapsedByName(root.dockSide, true)
                    root.expandedHeight = 250 // restore default so it pops back correctly next time
                }
            }
            onDoubleClicked: {
                if (root.isCollapsed) {
                    root.expandedHeight = 250
                    root.manager.setDockCollapsedByName(root.dockSide, false)
                } else {
                    root.manager.setDockCollapsedByName(root.dockSide, true)
                }
            }
        }
    }

    // Click-away overlay to close the options popup
    MouseArea {
        anchors.fill: parent
        z: 9990
        visible: optionsPopup.visible
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: optionsPopup.close()
    }

    // Options Popup
    Rectangle {
        id: optionsPopup
        visible: false
        width: 200 * root.uiScale
        height: Math.min(parent.height - 16 * root.uiScale, popupContent.implicitHeight + 20 * root.uiScale)
        
        property real targetX: 0
        property real targetY: 0
        property string menuActiveTabId: ""
        property string menuGroupId: ""
        
        x: Math.max(8, Math.min(parent.width - width - 8, targetX))
        y: Math.max(8, Math.min(parent.height - height - 8, targetY))
        z: 9999
        
        color: "#111115"
        border.color: "#282830"
        border.width: 1
        radius: 8
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 15
            shadowColor: "#aa000000"
            shadowVerticalOffset: 4
        }
        
        function openAt(tx, ty, activeTabId, groupId) {
            targetX = tx
            targetY = ty
            menuActiveTabId = activeTabId
            menuGroupId = groupId
            visible = true
        }
        
        function close() {
            visible = false
        }
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 6 * root.uiScale
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                id: popupContent
                width: parent.width
                spacing: 1 * root.uiScale

                // ── SECTION: Panel Actions ────────────────────
                PopupSectionHeader { sectionText: "PANEL" }

                PopupMenuItem {
                    menuText: "Flotar panel"
                    menuEmoji: "⬖"
                    onItemClicked: {
                        root.manager.movePanelToFloat(optionsPopup.menuActiveTabId,
                            root.mapToGlobal(0,0).x + 50, root.mapToGlobal(0,0).y + 50)
                        optionsPopup.close()
                    }
                }
                PopupMenuItem {
                    menuText: "Colapsar dock"
                    menuEmoji: "◁"
                    onItemClicked: { root.manager.collapseDock(root.dockSide); optionsPopup.close() }
                }
                PopupMenuItem {
                    menuText: "Cerrar pestaña"
                    menuEmoji: "✕"
                    isDanger: true
                    onItemClicked: { root.manager.removePanelEverywhere(optionsPopup.menuActiveTabId); optionsPopup.close() }
                }

                PopupDivider {}

                // ── SECTION: Tab display mode ──────────────────
                PopupSectionHeader { sectionText: "DISEÑO DE PESTAÑA" }

                PopupMenuItem {
                    menuText: "Icono y Texto"
                    menuEmoji: "⊞"
                    isChecked: root.tabDisplayMode === "both"
                    acColor: root.accentColor
                    onItemClicked: { root.tabDisplayMode = "both"; optionsPopup.close() }
                }
                PopupMenuItem {
                    menuText: "Solo Icono"
                    menuEmoji: "◉"
                    isChecked: root.tabDisplayMode === "icon"
                    acColor: root.accentColor
                    onItemClicked: { root.tabDisplayMode = "icon"; optionsPopup.close() }
                }
                PopupMenuItem {
                    menuText: "Solo Texto"
                    menuEmoji: "𝖠"
                    isChecked: root.tabDisplayMode === "text"
                    acColor: root.accentColor
                    onItemClicked: { root.tabDisplayMode = "text"; optionsPopup.close() }
                }

                PopupDivider {}

                // ── SECTION: Show panel ────────────────────────
                PopupSectionHeader { sectionText: "MOSTRAR PANEL" }

                Repeater {
                    model: root.allPanelsList
                    PopupMenuItem {
                        menuText: modelData.name
                        menuEmoji: ""
                        isChecked: root.isPanelActiveAnywhere(modelData.id)
                        acColor: root.accentColor
                        onItemClicked: { root.manager.togglePanel(modelData.id); optionsPopup.close() }
                    }
                }
            }
        }
    }

    // ── REUSABLE POPUP COMPONENTS ──────────────────────────
    component PopupSectionHeader: Item {
        property string sectionText: ""
        width: parent ? parent.width : 0
        height: 22 * root.uiScale
        Text {
            text: sectionText
            color: "#4a4a58"
            font.pixelSize: 8 * root.uiScale
            font.weight: Font.Bold
            font.letterSpacing: 0.8
            anchors.left: parent.left; anchors.leftMargin: 10 * root.uiScale
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component PopupDivider: Item {
        width: parent ? parent.width : 0
        height: 10 * root.uiScale
        Rectangle {
            width: parent.width - 16 * root.uiScale; height: 1
            color: "#1e1e26"
            anchors.centerIn: parent
        }
    }

    component PopupMenuItem: Rectangle {
        id: _pmi
        property string menuText: ""
        property string menuEmoji: ""
        property bool isChecked: false
        property bool isDanger: false
        property color acColor: root.accentColor
        signal itemClicked()

        width: parent ? parent.width : 0
        height: 28 * root.uiScale
        radius: 5
        color: _pmiMa.containsMouse
            ? (isDanger ? "#2a1518" : "#1c1c24")
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10 * root.uiScale
            anchors.rightMargin: 10 * root.uiScale
            spacing: 8 * root.uiScale

            // Check indicator or emoji icon
            Text {
                text: _pmi.isChecked ? "✓" : (_pmi.menuEmoji !== "" ? _pmi.menuEmoji : "  ")
                color: _pmi.isChecked ? _pmi.acColor : (_pmiMa.containsMouse ? "#aaa" : "#444")
                font.pixelSize: _pmi.isChecked ? 11 * root.uiScale : 12 * root.uiScale
                font.weight: Font.Bold
                Layout.preferredWidth: 14 * root.uiScale
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: _pmi.menuText
                color: _pmi.isDanger
                    ? (_pmiMa.containsMouse ? "#ff6b6b" : "#c04444")
                    : (_pmi.isChecked ? "#ffffff" : (_pmiMa.containsMouse ? "#e0e0e8" : "#9090a0"))
                font.pixelSize: 11 * root.uiScale
                font.weight: _pmi.isChecked ? Font.DemiBold : Font.Normal
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MouseArea {
            id: _pmiMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: _pmi.itemClicked()
        }
        scale: _pmiMa.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
    }
}
