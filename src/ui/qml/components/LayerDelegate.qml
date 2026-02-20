import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects


Item {
    id: layerDelegate
    
    // Properties passed from the main list
    property int listIndex: index // The special 'index' variable from Delegate
    property var listModel: (typeof modelData !== "undefined") ? modelData : model // The special 'model' variable from Delegate
    
    // External References
    property var layersListRef: ListView.view 
    property var dragGhostRef: null // Reference to the drag ghost
    property var rootRef: null // Reference to the main panel root
    
    // Helper
    property color accentColor: (typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#007aff"

    // --- 0. DROP INDICATOR (Dual-Position Dot & Line) ---
    Item {
        id: dropIndicator
        // Only show if we are THE specific target (above) OR previous item is target (could be below)
        // Actually, let's keep it simple: It shows at the TOP of the target index.
        visible: layersListRef && layersListRef.draggedIndex !== -1 && layersListRef.dropTargetIndex === listIndex && layersListRef.draggedIndex !== listIndex
        width: parent.width - 8
        height: 10
        anchors.top: parent.top
        anchors.topMargin: -5
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999
        
        Rectangle {
            width: 6; height: 6; radius: 3
            color: layerDelegate.accentColor
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Rectangle {
            height: 2
            anchors.left: parent.left; anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: layerDelegate.accentColor
            radius: 1
            
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: layerDelegate.accentColor }
        }
    }
    
    // Bottom indicator for the very last item in the list
    Item {
        id: lastDropIndicator
        visible: layersListRef && layersListRef.draggedIndex !== -1 && layersListRef.dropTargetIndex === listIndex + 1 && listIndex === (layersListRef.count - 1)
        width: parent.width - 8; height: 10
        anchors.bottom: parent.bottom; anchors.bottomMargin: -5
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999
        
        Rectangle { width: 6; height: 6; radius: 3; color: layerDelegate.accentColor; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            height: 2; anchors.left: parent.left; anchors.leftMargin: 6; anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter; color: layerDelegate.accentColor; radius: 1
            layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: layerDelegate.accentColor }
        }
    }
    
    // Signals
    signal requestBackgroundEdit()
    
    // Layer Data (extracted from model for easier binding)
    property int layerIndex: listModel.layerId
    property string layerName: listModel.name
    property bool isVisible: listModel.visible
    property bool isActive: listModel.active
    property bool isLocked: listModel.locked
    property bool isClipped: listModel.clipped
    property bool isAlphaLocked: listModel.alpha_lock
    property bool isPrivate: listModel.is_private
    property string blendMode: listModel.blendMode || "Normal"
    property real layerOpacity: listModel.opacity !== undefined ? listModel.opacity : 1.0
    property string layerType: listModel.type
    property var thumbnailSource: listModel.thumbnail
    property int layerDepth: (typeof listModel.depth !== 'undefined' ? listModel.depth : 0)
    property bool isGroupExpanded: listModel.expanded

    // --- NUEVO: SISTEMA DE REFRESCO DE MINIATURA EN TIEMPO REAL ---
    property double thumbRefreshTime: Date.now()
    
    property string activeThumbnail: {
        var baseStr = thumbnailSource || ""
        if (baseStr === "") return ""
        
        // If it's a data URI, the data itself is the image and appending a query param corrupts it
        if (baseStr.indexOf("data:image") === 0) return baseStr;
        
        // Añade el timestamp al final (ej. "image://capa_1?ts=1690000000")
        var separator = baseStr.indexOf('?') !== -1 ? '&' : '?'
        return baseStr + separator + "ts=" + thumbRefreshTime
    }

    // Escucha directamente las actualizaciones que manda C++ al modelo
    Connections {
        target: layersListRef.model
        function onDataChanged(topLeft, bottomRight, roles) {
            // Si la señal de cambio incluye a esta capa (listIndex), forzamos la recarga
            if (layerDelegate.listIndex >= topLeft.row && layerDelegate.listIndex <= bottomRight.row) {
                layerDelegate.thumbRefreshTime = Date.now()
            }
        }
    }
    // -------------------------------------------------------------
    
    width: layersListRef.width
    // Height changes if active or options are open
    height: (layersListRef.optionsIndex === layerDelegate.layerIndex) ? 320 : (isActive ? 82 : 48)
    
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    
    property bool isSwipedOpen: layersListRef.swipedIndex === layerDelegate.listIndex
    
    // Helper function for icon paths (assuming parent context has this or we need to pass it)
    function iconPath(name) {
        return "image://icons/" + name
    }

    // --- 1. BACKGROUND ACTIONS (Copy, Lock, Delete) ---
    // Revealed when swiping LEFT
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (layersListRef.optionsIndex === layerDelegate.layerIndex) ? -128 : 0 // Align to top part if expanded
        height: 56 // Fixed height matching header
        spacing: 4
        
        visible: layerDelegate.isSwipedOpen
        opacity: layerDelegate.isSwipedOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        // Copy
        Rectangle {
            width: 50; height: parent.height; radius: 10
            color: accentColor // Apply accent to Copy? Or keep blue? Let's use accent for consistency.
            Column {
                anchors.centerIn: parent
                spacing: 2
                Image { source: iconPath("copy.svg"); width: 18; height: 18; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Copy"; color: "#fff"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea {
                anchors.fill: parent; onClicked: { 
                    mainCanvas.duplicateLayer(layerIndex); 
                    layersListRef.swipedIndex = -1 
                }
            }
        }
        
        // Lock
        Rectangle {
            width: 50; height: parent.height; radius: 10
            color: isLocked ? "#ff9500" : "#34c759"
            Column {
                anchors.centerIn: parent
                spacing: 2
                Image { source: isLocked ? iconPath("unlock.svg") : iconPath("lock.svg"); width: 18; height: 18; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: isLocked ? "Unlock" : "Lock"; color: "#fff"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea {
                anchors.fill: parent; onClicked: { 
                    mainCanvas.toggleLock(layerIndex); 
                    layersListRef.swipedIndex = -1 
                }
            }
        }
        
        // Delete
        Rectangle {
            width: layerType !== "background" ? 50 : 0
            visible: layerType !== "background"
            height: parent.height; radius: 10
            color: "#ff453a"
            Column {
                anchors.centerIn: parent
                spacing: 2
                Image { source: iconPath("trash-2.svg"); width: 18; height: 18; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "Delete"; color: "#fff"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea {
                anchors.fill: parent; onClicked: { 
                    mainCanvas.removeLayer(layerIndex); 
                    layersListRef.swipedIndex = -1 
                }
            }
        }
    }

    // --- 2. MAIN SWIPEABLE CONTENT ---
    Rectangle {
        id: layerContent
        width: parent.width - 4
        height: parent.height - 4
        anchors.verticalCenter: parent.verticalCenter
        
        // --- POSITION & ANIMATION ---
        property real baseX: (layerDelegate.isSwipedOpen ? -150 : 2) + (isClipped ? 24 : 0)
        x: baseX 
        
        radius: 10 // Cleaner, less rounded
        // Dark background for all states (Active gets border only)
        color: isClipped ? "#151517" : "#1c1c1e" 
        opacity: layersListRef.draggedIndex === listIndex ? 0.2 : 1.0 // Dim when dragging
        border.width: isActive ? 2 : 1
        border.color: isActive ? layerDelegate.accentColor : (isClipped ? "#333" : "#2c2c2e")
        
        clip: true 
        
        // Subtle Shadow for Active
        layer.enabled: isActive
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 8
            shadowVerticalOffset: 2
        }

        Behavior on x { 
            enabled: !dragArea.drag.active
            NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.6 } 
        }

        // --- CONTENT ROW ---
        Item {
            id: headerContent
            width: parent.width
            height: isActive ? 82 : 48
            anchors.top: parent.top
            
            MouseArea {
                id: dragArea
                anchors.fill: parent
                property real startX: 0
                property real startY: 0
                property real dragYOffset: 0
                property bool isReordering: false
                property bool isSwiping: false
                
                // Only connect the drag engine when we detect horizontal intent
                drag.target: isSwiping ? layerContent : null
                drag.axis: Drag.XAxis
                preventStealing: isReordering || isSwiping
                drag.minimumX: -220; drag.maximumX: 180
                drag.filterChildren: true 
                
                onPressed: { 
                    startX = mouse.x
                    startY = mouse.y
                    isReordering = false
                    isSwiping = false
                    
                    // Normalize grab offset
                    if (dragGhostRef) {
                        var ratio = mouse.y / dragArea.height
                        dragYOffset = ratio * dragGhostRef.height
                    } else {
                        dragYOffset = mouse.y
                    }
                }
                
                onPositionChanged: {
                    var dx = Math.abs(mouse.x - startX)
                    var dy = Math.abs(mouse.y - startY)

                    // Intent detection (first ~8 pixels of movement)
                    if (pressed && !isReordering && !isSwiping && layerType !== "background") {
                        if (dy > 8 || dx > 8) {
                            if (dy > dx) { 
                                // Vertical intent: Reorder
                                isReordering = true
                                if (rootRef) rootRef.draggedIndex = listIndex
                                layersListRef.draggedIndex = listIndex
                                if (dragGhostRef) {
                                    dragGhostRef.visible = true
                                    dragGhostRef.infoText = layerName || "Layer"
                                }
                            } else {
                                // Horizontal intent: Swipe
                                isSwiping = true
                            }
                        }
                    }
                    
                    if (isReordering && dragGhostRef) {
                        // 1. POSITION GHOST
                        // Map mouse from our area to the Ghost's parent coordinate system
                        var pParent = dragArea.mapToItem(dragGhostRef.parent, mouse.x, mouse.y)
                        var newY = pParent.y - dragYOffset
                        
                        // Bounds check within parent
                        if (newY < 0) newY = 0
                        if (newY > dragGhostRef.parent.height - dragGhostRef.height) 
                             newY = dragGhostRef.parent.height - dragGhostRef.height
                        dragGhostRef.y = newY
                        
                        // 2. FIND TARGET INDEX
                        // Map mouse to the ListView coordinate system
                        var pList = dragArea.mapToItem(layersListRef, mouse.x, mouse.y)
                        var targetIdx = layersListRef.indexAt(10, pList.y + layersListRef.contentY)
                        
                        if (targetIdx !== -1) {
                            var itm = layersListRef.itemAt(10, pList.y + layersListRef.contentY)
                            if (itm) {
                                var localY = itm.mapFromItem(layersListRef, 10, pList.y + layersListRef.contentY).y
                                // Threshold: if in bottom 50%, target the NEXT index
                                if (localY > itm.height * 0.5) {
                                    targetIdx = targetIdx + 1
                                }
                            }
                            
                            // Visual safety: Hide indicator if dropping results in NO CHANGE
                            if (targetIdx === listIndex || targetIdx === listIndex + 1) {
                                if (rootRef) rootRef.dropTargetIndex = -1
                                layersListRef.dropTargetIndex = -1
                            } else {
                                if (rootRef) rootRef.dropTargetIndex = targetIdx
                                layersListRef.dropTargetIndex = targetIdx
                            }
                        }
                    }
                }

                onPressAndHold: {
                    if (layerType !== "background" && !isReordering) {
                        isReordering = true
                        if (rootRef) rootRef.draggedIndex = listIndex
                        layersListRef.draggedIndex = listIndex
                        if (dragGhostRef) {
                            dragGhostRef.visible = true
                            dragGhostRef.infoText = layerName || "Layer"
                            
                            // INITIAL SYNC: Use the same item-to-item mapping
                            var pParent = dragArea.mapToItem(dragGhostRef.parent, startX, startY)
                            dragGhostRef.y = pParent.y - dragYOffset
                        }
                        // Visual feedback (dim the moving item)
                        layerContent.opacity = 0.2
                    }
                }

                onClicked: {
                    if (layersListRef.swipedIndex !== -1 || layersListRef.optionsIndex !== -1) {
                        layersListRef.swipedIndex = -1; layersListRef.optionsIndex = -1; return
                    }
                    mainCanvas.setActiveLayer(layerIndex)
                    if (layerType === "background") layerDelegate.requestBackgroundEdit()
                }

                onReleased: {
                    if (layerContent) layerContent.scale = 1.0 // Restore appearance
                    
                    if (isReordering) {
                        isReordering = false
                        if (dragGhostRef) dragGhostRef.visible = false
                        
                        var finalTargetIdx = layersListRef.dropTargetIndex
                        if (finalTargetIdx !== -1) {
                            var model = layersListRef.model
                            var targetId = -1
                            
                            // Logic: Move layerIndex TO finalTargetIdx
                            // If moving to very bottom (count), use parent logic or target last item + handled by moveLayer
                            var queryIdx = (finalTargetIdx >= layersListRef.count) ? layersListRef.count - 1 : finalTargetIdx
                            
                            if (model && queryIdx >= 0) {
                                var item = (typeof model.get === "function") ? model.get(queryIdx) : model[queryIdx]
                                if (item) targetId = item.layerId
                            }
                            
                            if (targetId !== -1 && targetId !== undefined) {
                                mainCanvas.moveLayer(layerIndex, targetId)
                            }
                        }
                        
                        if (rootRef) {
                            rootRef.draggedIndex = -1
                            rootRef.dropTargetIndex = -1
                        }
                        layersListRef.draggedIndex = -1
                        layersListRef.dropTargetIndex = -1
                    } else {
                        var delta = mouse.x - startX
                        if (layerDelegate.isSwipedOpen && delta < -20) {
                            layersListRef.swipedIndex = -1
                        } else if (!layerDelegate.isSwipedOpen && isSwiping) {
                            if (delta > 35) layersListRef.swipedIndex = listIndex
                            else if (delta < -45) mainCanvas.toggleClipping(layerIndex)
                        }
                    }
                    
                    isSwiping = false
                    isReordering = false
                    layerContent.x = Qt.binding(function() { return layerContent.baseX })
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12
                
                // 1. Clipping Indicator (Cleaner)
                Item {
                    Layout.preferredWidth: isClipped ? 12 : 0
                    Layout.preferredHeight: 12
                    visible: isClipped
                    Image {
                        source: iconPath("arrow-down-left.svg")
                        anchors.fill: parent
                        opacity: 0.6
                        rotation: -90
                        // color: isActive ? "white" : "#888" // Removed
                    }
                }
                
                // 2. Thumbnail (Smaller 36px)
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    radius: 6
                    color: layerType === "background" ? (listModel.bgColor || "white") : "#ebebeb" // Use project background color
                    border.color: isActive ? "#ffffff50" : "#ffffff20"
                    border.width: 1
                    clip: true
                    
                    // High-contrast Checkerboard for transparency
                    Image { 
                        visible: layerType !== "background"
                        anchors.fill: parent
                        source: iconPath("grid_pattern.svg")
                        fillMode: Image.Tile
                        opacity: 0.5 // High opacity to see the squares clearly
                    }
                    Image {
                        visible: layerType !== "group" // Show for drawing and background layers
                        anchors.fill: parent; anchors.margins: 2
                        source: layerDelegate.activeThumbnail
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true
                        smooth: true
                        mipmap: true
                    }
                    Image { visible: isAlphaLocked; source: iconPath("lock.svg"); width: 10; height: 10; anchors.right:parent.right; anchors.bottom:parent.bottom; anchors.margins:2; opacity:0.8 }
                    
                    // Group Indicator (If Group)
                    Image {
                        visible: layerType === "group"
                        source: iconPath("folder.svg")
                        width: 20; height: 20; anchors.centerIn: parent
                        opacity: 0.7
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (layerType !== "background") {
                                layersListRef.optionsIndex = (layersListRef.optionsIndex === layerIndex) ? -1 : layerIndex
                                layersListRef.swipedIndex = -1
                            }
                        }
                    }
                }
                
                // 3. Name area
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    
                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        
                        RowLayout {
                            width: parent.width
                            spacing: 8
                            Text {
                                text: layerName
                                color: isVisible ? "#ffffff" : "#777"
                                font.pixelSize: 13
                                font.weight: isActive ? Font.DemiBold : Font.Normal
                                Layout.fillWidth: true
                                elide: Text.ElideRight 
                            }
                            
                            // Locked Indicator
                            Image {
                                visible: isLocked
                                source: iconPath("lock.svg")
                                width: 12; height: 12
                                Layout.alignment: Qt.AlignVCenter
                                opacity: 0.6
                            }
                            
                            // PREMIUM: Blend Mode Indicator (Badge)
                            Rectangle {
                                visible: blendMode !== "Normal"
                                height: 16
                                width: modeText.contentWidth + 12
                                color: isActive ? layerDelegate.accentColor : "#222224"
                                radius: 4
                                border.color: isActive ? "#50ffffff" : "#444"
                                border.width: 1
                                Text {
                                    id: modeText
                                    anchors.centerIn: parent
                                    text: blendMode
                                    color: "white"
                                    font.pixelSize: 8
                                    font.weight: Font.Black
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.5
                                }
                            }
                        }

                        // Interactive Opacity Slider
                        RowLayout {
                            visible: isActive
                            width: parent.width
                            spacing: 8
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 16 // Sufficient touch target
                                
                                property bool dragging: false
                                property real dragValue: 0.0

                                // Background Track
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: 4 
                                    radius: 2
                                    color: "#20ffffff"
                                    
                                    // Progress Fill
                                    Rectangle {
                                        width: parent.width * (parent.parent.dragging ? parent.parent.dragValue : layerOpacity)
                                        height: parent.height
                                        radius: 2
                                        color: layerDelegate.accentColor 
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    preventStealing: true
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    function updateVal(mouse) {
                                        var v = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                        parent.dragValue = v
                                        if (mainCanvas && mainCanvas.setLayerOpacityPreview) 
                                            mainCanvas.setLayerOpacityPreview(layerIndex, v)
                                    }

                                    onPressed: {
                                        parent.dragging = true
                                        updateVal(mouse)
                                    }
                                    onPositionChanged: {
                                        if (pressed) updateVal(mouse)
                                    }
                                    onReleased: {
                                        parent.dragging = false
                                        var v = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                        if (mainCanvas && mainCanvas.setLayerOpacity) 
                                            mainCanvas.setLayerOpacity(layerIndex, v)
                                    }
                                }
                            }
                            
                            Text {
                                text: Math.round((parent.children[0].dragging ? parent.children[0].dragValue : layerOpacity)*100)+"%"
                                color: "white"
                                font.pixelSize: 11
                                font.weight: Font.Black
                                opacity: 0.8
                                Layout.preferredWidth: 32
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
                
                // 4. RIGHT SIDE ICONS (Settings & Eye)
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    
                    // Settings / Adjustments Icon
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        color: "transparent"
                        radius: 6
                        Image {
                            source: iconPath("sliders.svg")
                            width: 16; height: 16; anchors.centerIn: parent
                            opacity: isActive ? 1.0 : 0.6
                            // color: isActive ? "white" : "#aaa" // Removed
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (layerType !== "background") {
                                    var newIdx = (layersListRef.optionsIndex === layerIndex) ? -1 : layerIndex
                                    layersListRef.optionsIndex = newIdx
                                    layersListRef.swipedIndex = -1
                                }
                            }
                        }
                    }
                    
                    // Eye / Visibility Icon
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        color: "transparent"
                        radius: 6
                        Image {
                            source: isVisible ? iconPath("eye.svg") : iconPath("eye-off.svg")
                            width: 18; height: 18; anchors.centerIn: parent
                            opacity: isVisible ? (isActive ? 1.0 : 0.7) : 0.4
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: mainCanvas.toggleVisibility(layerIndex)
                            onPressAndHold: {
                                if (mainCanvas && mainCanvas.setLayerSolo) mainCanvas.setLayerSolo(layerIndex)
                            }
                        }
                    }
                }
            }
        }
        
        // --- EXPANDED OPTIONS PANEL (If needed, pushes down or overlay? Current logic expands height) ---
        // Keeping logical structure but simplified visually
        // --- PREMIUM OPTIONS PANEL (Blend Modes & Opacity) ---
        Rectangle {
            id: optionsPanel
            anchors.top: headerContent.bottom
            width: parent.width
            height: parent.height - 60
            visible: layersListRef.optionsIndex === layerIndex
            color: "transparent"
            clip: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14
                visible: parent.visible
                
                // Blend Mode Selector
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    Text { text: "Blend Mode"; color: "#999"; font.pixelSize: 11; font.weight: Font.Medium }
                    
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: "#121214"; radius: 12
                        border.color: "#1f1f22"; border.width: 1
                        
                        ListView {
                            id: blendModeList
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true
                            orientation: ListView.Vertical
                            snapMode: ListView.SnapToItem
                            highlightRangeMode: ListView.StrictlyEnforceRange
                            property real centerOffset: -50 // Raise the selection box
                            preferredHighlightBegin: height/2 + centerOffset - 22
                            preferredHighlightEnd: height/2 + centerOffset + 22
                            highlightMoveDuration: 0 // Start instant to avoid jump on load
                            
                            model: ["Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten", "Color Dodge", "Color Burn", "Soft Light", "Hard Light", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity"]
                            
                            delegate: Item {
                                width: blendModeList.width; height: 44
                                property real distFromCenter: Math.abs((y + height/2 - blendModeList.contentY) - (blendModeList.height / 2 + blendModeList.centerOffset))
                                property real factor: Math.max(0.0, 1.0 - (distFromCenter / (blendModeList.height / 2)))
                                
                                Text {
                                    text: modelData
                                    anchors.centerIn: parent
                                    color: factor > 0.8 ? "white" : Qt.rgba(1,1,1, 0.3 + factor * 0.4)
                                    font.pixelSize: 14 + (factor * 2)
                                    font.weight: factor > 0.8 ? Font.DemiBold : Font.Normal
                                    scale: 0.9 + (factor * 0.2)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: blendModeList.currentIndex = index
                                }
                            }

                            // Selection Highlight (Glass overlay)
                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: blendModeList.centerOffset
                                width: parent.width - 8; height: 40
                                color: Qt.rgba(layerDelegate.accentColor.r, layerDelegate.accentColor.g, layerDelegate.accentColor.b, 0.2)
                                radius: 8
                                z: -1
                                border.color: layerDelegate.accentColor; border.width: 1
                            }
                            
                            onCurrentIndexChanged: {
                                if (isReady && !moving && !dragging && currentIndex >= 0) {
                                    mainCanvas.setLayerBlendMode(layerIndex, model[currentIndex])
                                }
                            }
                            onMovementEnded: {
                                if (isReady && currentIndex >= 0) {
                                    mainCanvas.setLayerBlendMode(layerIndex, model[currentIndex])
                                }
                            }

                            property bool isReady: false
                            Component.onCompleted: {
                                for(var i=0; i<model.length; i++) {
                                    if(model[i] === blendMode) {
                                        currentIndex = i
                                        break
                                    }
                                }
                                isReady = true
                                restoreAnim.start()
                            }
                            
                            Timer {
                                id: restoreAnim
                                interval: 50
                                onTriggered: blendModeList.highlightMoveDuration = 250
                            }
                        }
                    }
                }
            }
        }
    }
}

