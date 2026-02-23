import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Rectangle {
    id: root
    
    // Props
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
    height: isBottom ? ((isCollapsed && !isDragHover) ? 0 : expandedHeight) : parent.height
    Layout.preferredWidth: isBottom ? -1 : width
    Layout.minimumWidth: isBottom ? -1 : width
    Layout.maximumWidth: isBottom ? -1 : width
    Layout.preferredHeight: isBottom ? height : -1
    
    property int expandedHeight: 250
    color: "#0a0a0d"
    border.color: isCollapsed ? "transparent" : "#2a2a2d"
    border.width: 1
    
    Behavior on width { 
        enabled: !resizerMa.pressed && !isBottom
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
    }
    Behavior on height {
        enabled: isBottom
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
    }
    
    visible: isBottom ? height > 0 : width > 0
    clip: true
    
    Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#1affffff"; border.width: 1 }
    
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
            var vCount = 0; for(var i=0; i<dockModel.count; i++) if(dockModel.get(i).visible) vCount++;
            return vCount > 0 ? (parent.height / vCount) - 10 : 0
        }
        width: parent.width - 20
        x: 10
        y: {
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
            color: "#0d0d10"
            visible: !root.isCollapsed
            
            Rectangle {
                width: 28; height: 28; radius: 14
                color: collAllMa.containsMouse ? "#252528" : "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: isBottom ? undefined : ((root.dockSide.indexOf("left") !== -1) ? parent.right : undefined)
                anchors.left: isBottom ? parent.left : ((root.dockSide.indexOf("right") !== -1) ? parent.left : undefined)
                anchors.horizontalCenter: isBottom ? parent.horizontalCenter : undefined
                anchors.rightMargin: 4; anchors.leftMargin: 4
                
                Image {
                    source: "image://icons/chevron-left.svg"
                    width: 16; height: 16; anchors.centerIn: parent
                    opacity: 0.6; smooth: true; mipmap: true
                    rotation: isBottom ? 90 : ((root.dockSide.indexOf("left") !== -1) ? 0 : 180)
                }
                
                MouseArea {
                    id: collAllMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.manager.collapseDock(root.dockSide)
                }
            }
            
            Rectangle { width: parent.width; height: 1; color: "#1c1c1f"; anchors.bottom: parent.bottom }
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
                        var currentlyActive = root.manager.activeGroupTabs[delegateGroupId];
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
                                        width: Math.min(130, Math.max(90, tabText.implicitWidth + 40))
                                        color: isActiveTab ? "#151518" : (tabMa.containsMouse ? "#121215" : "transparent")
                                        
                                        // Slight rounding at the top for tabs
                                        radius: isActiveTab ? 6 : 0
                                        Rectangle { width: parent.width; height: 6; anchors.bottom: parent.bottom; color: parent.color; visible: isActiveTab }
                                        
                                        // Separator between inactive tabs
                                        Rectangle { 
                                            width: 1; height: 14; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; 
                                            color: "#1f1f22"; visible: !isActiveTab
                                        }
                                        
                                        // Top accent glow for active tab
                                        Rectangle { 
                                            width: parent.width - 16; height: 2; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                            radius: 1
                                            color: root.accentColor; visible: isActiveTab 
                                            layer.enabled: true
                                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 12; shadowColor: root.accentColor; shadowVerticalOffset: 2 }
                                        }
                                        
                                        // Bottom seamless cover
                                        Rectangle {
                                            width: parent.width; height: 2; anchors.bottom: parent.bottom
                                            color: "#151518"; visible: isActiveTab; z: 5 // Covers the panelHeader bottom border
                                        }
                                        
                                        Row {
                                            anchors.centerIn: parent; spacing: 8
                                            opacity: isActiveTab ? 1.0 : (tabMa.containsMouse ? 0.8 : 0.5)
                                            
                                            Image {
                                                source: modelData.icon !== "" ? "image://icons/" + modelData.icon : ""
                                                width: 14; height: 14; 
                                                sourceSize: Qt.size(28, 28); smooth: true; mipmap: true; anchors.verticalCenter: parent.verticalCenter
                                                visible: modelData.icon !== ""
                                                layer.enabled: isActiveTab
                                                layer.effect: MultiEffect { colorizationColor: root.accentColor; colorization: 1.0 }
                                            }
                                            Text {
                                                id: tabText
                                                text: modelData.name
                                                color: isActiveTab ? "#ffffff" : "#aaabaf"
                                                font.pixelSize: 11; font.weight: isActiveTab ? Font.DemiBold : Font.Medium
                                                anchors.verticalCenter: parent.verticalCenter
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
                                    color: popoutMa.containsMouse ? "#252528" : "transparent"
                                    Image { source: "image://icons/external-link.svg"; anchors.centerIn: parent; width: 14; height: 14; opacity: 0.6 }
                                    MouseArea {
                                        id: popoutMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.manager.movePanelToFloat(activeTabId, parent.mapToGlobal(0,0).x - 200, parent.mapToGlobal(0,0).y)
                                    }
                                }
                                
                                Rectangle {
                                    width: 24; height: 24; radius: 6
                                    color: collapseMa.containsMouse ? "#252528" : "transparent"
                                    Image { source: "image://icons/grip.svg"; anchors.centerIn: parent; width: 14; height: 14; opacity: 0.6 }
                                    MouseArea {
                                        id: collapseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleCollapse(activeTabId)
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
                                    if (item && item.hasOwnProperty("targetCanvas")) item.targetCanvas = Qt.binding(function() { return root.mainCanvas })
                                    if (item && item.hasOwnProperty("colorAccent")) item.colorAccent = root.accentColor
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
        visible: root.isBottom && !root.isCollapsed
        height: 6; width: parent.width
        anchors.top: parent.top
        color: bottomResizerMa.containsMouse || bottomResizerMa.pressed ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : "transparent"
        z: 10
        
        Rectangle { height: 2; width: parent.width; anchors.centerIn: parent; color: bottomResizerMa.containsMouse || bottomResizerMa.pressed ? accentColor : "transparent" }
        
        MouseArea {
            id: bottomResizerMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeVerCursor
            property real startH; property real startGy
            onPressed: (mouse) => { startH = root.expandedHeight; startGy = mapToGlobal(0, mouse.y).y }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var diff = startGy - mapToGlobal(0, mouse.y).y
                    root.expandedHeight = Math.max(150, Math.min(500, startH + diff))
                }
            }
        }
    }
}
