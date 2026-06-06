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
    property color accentColor: (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#007aff"
    // Group color token
    readonly property color groupColor: "#f59e0b"
    property bool isRenaming: false

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
    property real thumbRefreshTime: Date.now()
    property int layerDepth: (typeof listModel.depth !== 'undefined' ? listModel.depth : 0)
    property bool isGroupExpanded: listModel.expanded
    property bool isParentExpanded: listModel.parentExpanded !== undefined ? listModel.parentExpanded : true
    property bool isGroup: layerType === "group"
    property var targetCanvas: (rootRef && rootRef.targetCanvas) ? rootRef.targetCanvas : mainCanvas
    // Is the drag ghost hovering over THIS layer and it's a group?
    property bool isGroupDropHover: isGroup && rootRef && rootRef.groupDropTarget === layerIndex

    // --- NUEVO: SISTEMA DE REFRESCO DE MINIATURA EN TIEMPO REAL ---
    
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
        target: (layersListRef && layersListRef.model && typeof layersListRef.model.dataChanged !== "undefined") ? layersListRef.model : null
        ignoreUnknownSignals: true
        function onDataChanged(topLeft, bottomRight, roles) {
            // Si la señal de cambio incluye a esta capa (listIndex), forzamos la recarga
            if (layerDelegate.listIndex >= topLeft.row && layerDelegate.listIndex <= bottomRight.row) {
                layerDelegate.thumbRefreshTime = Date.now()
            }
        }
    }
    // -------------------------------------------------------------
    
    width: layersListRef ? layersListRef.width : 280
    // Height: collapsed layers are 0
    height: !isParentExpanded ? 0 : ((layersListRef && layersListRef.optionsIndex === layerDelegate.layerIndex) ? 320 : (isActive ? 82 : (isGroup ? 52 : 48)))
    visible: isParentExpanded
    clip: true // Ensure content doesn't bleed out when height is 0
    
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    
    property bool isSwipedOpen: layersListRef ? layersListRef.swipedIndex === layerDelegate.listIndex : false
    
    // Helper function for icon paths (assuming parent context has this or we need to pass it)
    function iconPath(name) {
        return "image://icons/" + name
    }

    function getBlendModeAbbreviation(mode) {
        switch (mode) {
            case "Normal": return "N"
            case "Multiply": return "M"
            case "Screen": return "S"
            case "Overlay": return "O"
            case "Darken": return "D"
            case "Lighten": return "L"
            case "Color Dodge": return "CD"
            case "Color Burn": return "CB"
            case "Soft Light": return "SL"
            case "Hard Light": return "HL"
            case "Difference": return "DF"
            case "Exclusion": return "E"
            case "Hue": return "H"
            case "Saturation": return "ST"
            case "Color": return "C"
            case "Luminosity": return "Y"
            case "Glow Dodge": return "GD"
            case "Hard Mix": return "HM"
            case "Divide": return "DV"
            default: return "N"
        }
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
        
        visible: layerContent.x < -10
        opacity: Math.min(1.0, Math.abs(layerContent.x) / 80)
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
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
    
    // --- 1.5. CLIPPING HINT (Revealed when swiping RIGHT) ---
    Rectangle {
        id: clippingHint
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: headerContent.height - 8
        width: Math.max(0, layerContent.x - (isClipped ? 20 : 4))
        radius: 12
        visible: layerContent.x > 10
        opacity: Math.min(1.0, parent.width / 120)
        z: 0
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: isClipped ? "#ff9500" : "#34c759" }
            GradientStop { position: 1.0; color: isClipped ? "#ffcc00" : "#30d158" }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 8
        }
        
        Row {
            anchors.centerIn: parent
            spacing: 10
            visible: parent.width > 50
            Image { 
                source: iconPath("arrow-down-left.svg")
                width: 22; height: 22
                rotation: -90
            }
            Text { 
                text: isClipped ? "RELEASE" : "CLIPPING"
                color: "white"; font.pixelSize: 10; font.weight: Font.Black
                font.letterSpacing: 1
            }
        }
    }

    // --- 2. MAIN SWIPEABLE CONTENT ---
    Rectangle {
        id: layerContent
        height: parent.height - 4
        anchors.verticalCenter: parent.verticalCenter
        
        // --- POSITION & ANIMATION ---
        property real baseX: (layerDelegate.isSwipedOpen ? -158 : 2) + (isClipped ? 24 : 0) + (layerDepth * 16)
        x: baseX 
        width: (parent ? parent.width : 280) - 4 - (layerDepth * 16) - (isClipped ? 24 : 0)
        z: 10
        scale: (dragArea.pressed || isSwipedOpen) ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }        
        radius: 10 // Cleaner, less rounded
        // Dark background — groups get amber tint, active gets accent, clipped gets subtle
        color: {
            if (isActive) return layerDelegate.accentColor
            if (layerDelegate.isGroupDropHover) return "#2d2010"
            if (layerDelegate.isGroup) return "#181610"
            if (isClipped) return "#151517"
            return "#1c1c1e"
        }
        opacity: (layersListRef && layersListRef.draggedIndex === listIndex) ? 0.2 : 1.0
        border.width: (isActive || layerDelegate.isGroupDropHover) ? 2 : 1
        border.color: {
            if (isActive) return "#ffffff30"
            if (layerDelegate.isGroupDropHover) return layerDelegate.groupColor
            if (layerDelegate.isGroup) return "#2c2c2e"
            if (isClipped) return "#333"
            return "#2c2c2e"
        }
        
        clip: true 
        
        // Subtle Shadow for Active
        layer.enabled: isActive
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#60000000"
            shadowBlur: 10
            shadowVerticalOffset: 3
        }

        Behavior on x { 
            enabled: !dragArea.drag.active
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.5 } 
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
                        var pParent = dragArea.mapToItem(dragGhostRef.parent, mouse.x, mouse.y)
                        var newY = pParent.y - dragYOffset
                        if (newY < 0) newY = 0
                        if (newY > dragGhostRef.parent.height - dragGhostRef.height) 
                             newY = dragGhostRef.parent.height - dragGhostRef.height
                        dragGhostRef.y = newY
                        
                        // 2. FIND TARGET INDEX & CHECK FOR GROUP DROP
                        var pList = dragArea.mapToItem(layersListRef, mouse.x, mouse.y)
                        var targetIdx = layersListRef.indexAt(10, pList.y + layersListRef.contentY)
                        
                        // Reset group drop target first
                        if (rootRef) rootRef.groupDropTarget = -1
                        
                        if (targetIdx !== -1) {
                            var itm = layersListRef.itemAt(10, pList.y + layersListRef.contentY)
                            if (itm) {
                                var localY = itm.mapFromItem(layersListRef, 10, pList.y + layersListRef.contentY).y
                                var model = layersListRef.model
                                var targetModel = null
                                if (rootRef && rootRef.layerModel && targetIdx >= 0 && targetIdx < rootRef.layerModel.length) {
                                    targetModel = rootRef.layerModel[targetIdx]
                                } else if (model && targetIdx >= 0) {
                                    targetModel = (typeof model.get === "function") ? model.get(targetIdx) : model[targetIdx]
                                }
                                if (targetModel && targetModel.type === "group" && targetIdx !== listIndex) {
                                    // GROUP DROP MODE: highlight the group, hide regular indicator
                                    if (rootRef) rootRef.groupDropTarget = targetModel.layerId
                                    layersListRef.dropTargetIndex = -1
                                    if (rootRef) rootRef.dropTargetIndex = -1
                                } else {
                                    // Normal reorder
                                    if (localY > itm.height * 0.5) {
                                        targetIdx = targetIdx + 1
                                    }
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
                        
                        // Check if we're dropping INTO a group
                        var grpTarget = rootRef ? rootRef.groupDropTarget : -1
                        if (grpTarget !== -1 && grpTarget !== layerIndex) {
                            // Move layer into group
                            mainCanvas.moveLayerToGroup(layerIndex, grpTarget)
                        } else {
                            var finalTargetIdx = layersListRef.dropTargetIndex
                            if (finalTargetIdx !== -1) {
                                var model = layersListRef.model
                                var targetId = -1
                                var queryIdx = (finalTargetIdx >= layersListRef.count) ? layersListRef.count - 1 : finalTargetIdx
                                
                                var item = null
                                if (rootRef && rootRef.layerModel && queryIdx >= 0 && queryIdx < rootRef.layerModel.length) {
                                    item = rootRef.layerModel[queryIdx]
                                } else if (model && queryIdx >= 0) {
                                    item = (typeof model.get === "function") ? model.get(queryIdx) : model[queryIdx]
                                }
                                if (item) targetId = item.layerId
                                
                                if (targetId !== -1 && targetId !== undefined) {
                                    mainCanvas.moveLayer(layerIndex, targetId)
                                }
                            }
                        }
                        
                        if (rootRef) {
                            rootRef.draggedIndex = -1
                            rootRef.dropTargetIndex = -1
                            rootRef.groupDropTarget = -1
                        }
                        layersListRef.draggedIndex = -1
                        layersListRef.dropTargetIndex = -1
                    } else {
                        var delta = mouse.x - startX
                        if (layerDelegate.isSwipedOpen && delta > 30) {
                            layersListRef.swipedIndex = -1
                        } else if (!layerDelegate.isSwipedOpen && isSwiping) {
                            if (delta > 60) {
                                // Deslizar a la DERECHA -> Clipping Mask
                                mainCanvas.toggleClipping(layerIndex)
                            }
                            else if (delta < -60) {
                                // Deslizar a la IZQUIERDA -> Revelar Opciones
                                layersListRef.swipedIndex = listIndex
                            }
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
                        source: iconPath("corner-down-right.svg")
                        anchors.fill: parent
                        opacity: 0.6
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
                    
                    Rectangle {
                        visible: layerType === "vector"
                        width: 12; height: 12; radius: 3
                        color: "#007aff"
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 2
                        Text {
                            text: "V"
                            color: "white"
                            font.pixelSize: 8
                            font.weight: Font.Black
                            anchors.centerIn: parent
                        }
                    }

                    // Group Indicator (If Group)
                    Image {
                        visible: layerDelegate.isGroup
                        source: iconPath("folder.svg")
                        width: 22; height: 22; anchors.centerIn: parent
                        opacity: 1.0
                        layer.enabled: true
                        layer.effect: MultiEffect { 
                            colorization: 1.0; 
                            colorizationColor: "#f59e0b" // Explicit amber for the folder
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (layerType !== "background") {
                                layersListRef.swipedIndex = -1
                                layerOptionsPopup.open()
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
                            // Group Toggle (Expand/Collapse)
                            Rectangle {
                                visible: layerDelegate.isGroup
                                width: 24; height: 24; radius: 4; color: "transparent"
                                Image {
                                    source: iconPath("chevron-down.svg")
                                    width: 12; height: 12; anchors.centerIn: parent; opacity: 0.6
                                    rotation: isGroupExpanded ? 0 : -90
                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (targetCanvas) targetCanvas.toggleGroupExpanded(layerIndex)
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    visible: !layerDelegate.isRenaming
                                    anchors.fill: parent
                                    anchors.verticalCenter: parent.verticalCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: (layerType === "vector" ? "🔷 " : "") + layerName
                                    color: {
                                        if (!isVisible) return "#777"
                                        if (layerDelegate.isGroup) return layerDelegate.isGroupDropHover ? layerDelegate.groupColor : "#f8d87a"
                                        return "#ffffff"
                                    }
                                    font.pixelSize: 13
                                    font.weight: (isActive || layerDelegate.isGroup) ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight 
                                }

                                TextField {
                                    id: inlineRenameField
                                    visible: layerDelegate.isRenaming
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    text: layerName
                                    color: "white"
                                    font.pixelSize: 13
                                    verticalAlignment: TextInput.AlignVCenter
                                    leftPadding: 6
                                    rightPadding: 6
                                    background: Rectangle {
                                        color: "#121214"
                                        border.color: layerDelegate.accentColor
                                        border.width: 1
                                        radius: 6
                                    }
                                    
                                    onVisibleChanged: {
                                        if (visible) {
                                            forceActiveFocus()
                                            selectAll()
                                        }
                                    }
                                    
                                    onAccepted: {
                                        var txt = text.trim()
                                        if (txt !== "") {
                                            if (targetCanvas && typeof targetCanvas.renameLayer === "function") {
                                                targetCanvas.renameLayer(layerIndex, txt)
                                            }
                                        }
                                        layerDelegate.isRenaming = false
                                    }
                                    
                                    onActiveFocusChanged: {
                                        if (!activeFocus && visible) {
                                            var txt = text.trim()
                                            if (txt !== "") {
                                                if (targetCanvas && typeof targetCanvas.renameLayer === "function") {
                                                    targetCanvas.renameLayer(layerIndex, txt)
                                                }
                                            }
                                            layerDelegate.isRenaming = false
                                        }
                                    }
                                    
                                    Keys.onEscapePressed: {
                                        layerDelegate.isRenaming = false
                                    }
                                }
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
                                    color: isActive ? "#ffffff40" : "#20ffffff"
                                    
                                    // Progress Fill
                                    Rectangle {
                                        width: parent.width * (parent.parent.dragging ? parent.parent.dragValue : layerOpacity)
                                        height: parent.height
                                        radius: 2
                                        color: isActive ? "#ffffff" : layerDelegate.accentColor 
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
                
                // 4. RIGHT SIDE ICONS (Blend Mode Letter & Checkbox)
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    
                    // Blend Mode Letter Button
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        color: "transparent"
                        radius: 6
                        
                        Text {
                            anchors.centerIn: parent
                            text: layerDelegate.getBlendModeAbbreviation(blendMode)
                            color: isActive ? "white" : "#a0a0a5"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (layerType !== "background") {
                                    var newIdx = (layersListRef.optionsIndex === layerIndex) ? -1 : layerIndex
                                    layersListRef.optionsIndex = newIdx
                                    layersListRef.swipedIndex = -1
                                    if (newIdx !== -1 && layersListRef) {
                                        // Auto-scroll the list view to contain the expanded element
                                        layersListRef.positionViewAtIndex(listIndex, ListView.Contain)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Visibility Checkbox
                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        color: "transparent"
                        radius: 6
                        
                        // Checkbox container
                        Rectangle {
                            width: 16; height: 16
                            anchors.centerIn: parent
                            radius: 3
                            color: "transparent"
                            border.color: isVisible ? (isActive ? "white" : "#8e8e93") : "#444"
                            border.width: 1
                            
                            Image {
                                source: iconPath("check.svg")
                                anchors.fill: parent
                                anchors.margins: 1
                                visible: isVisible
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: isActive ? "white" : "#8e8e93"
                                }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
            height: parent.height - headerContent.height
            visible: layersListRef.optionsIndex === layerIndex
            color: "transparent"
            clip: true
            
            Column {
                id: optionsColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
                
                Text {
                    id: blendModeLabel
                    text: "Blend Mode"
                    color: "#a0a0a5"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                
                Rectangle {
                    width: optionsColumn.width
                    height: optionsColumn.height - blendModeLabel.height - optionsColumn.spacing
                    color: "#121214"
                    radius: 8
                    border.color: "#2a2a2d"
                    border.width: 1
                    
                    ListView {
                        id: blendModeList
                        anchors.fill: parent
                        anchors.margins: 4
                        clip: true
                        
                        model: ["Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten", "Color Dodge", "Color Burn", "Soft Light", "Hard Light", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity", "Glow Dodge", "Hard Mix", "Divide"]
                        
                        delegate: Rectangle {
                            width: blendModeList.width - 12; height: 32
                            radius: 6
                            color: {
                                if (blendModeList.currentIndex === index) return Qt.rgba(layerDelegate.accentColor.r, layerDelegate.accentColor.g, layerDelegate.accentColor.b, 0.25)
                                if (ma.containsMouse) return "#ffffff0a"
                                return "transparent"
                            }
                            border.color: (blendModeList.currentIndex === index) ? layerDelegate.accentColor : "transparent"
                            border.width: 1
                            
                            Text {
                                text: modelData
                                anchors.centerIn: parent
                                color: (blendModeList.currentIndex === index) ? "white" : (ma.containsMouse ? "#ffffff" : "#a0a0a5")
                                font.pixelSize: 12
                                font.weight: (blendModeList.currentIndex === index) ? Font.DemiBold : Font.Normal
                            }
                            
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    blendModeList.currentIndex = index
                                }
                            }
                        }
                        
                        ScrollBar.vertical: ScrollBar {
                            id: listScrollBar
                            width: 4
                            policy: ScrollBar.AsNeeded
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            contentItem: Rectangle {
                                radius: 2
                                color: "#444"
                            }
                        }
                        
                        onCurrentIndexChanged: {
                            if (isReady && currentIndex >= 0) {
                                var modeName = blendModeList.model[currentIndex]
                                if (blendMode !== modeName) {
                                    mainCanvas.setLayerBlendMode(layerIndex, modeName)
                                }
                            }
                        }
                        
                        property bool isReady: false
                        Component.onCompleted: {
                            for(var i=0; i<blendModeList.model.length; i++) {
                                if(blendModeList.model[i] === blendMode) {
                                    currentIndex = i
                                    positionViewAtIndex(i, ListView.Center)
                                    break
                                }
                            }
                            isReady = true
                        }
                    }

                    // Sincronizar reactivamente el modo activo cuando cambia desde fuera (ej. barra unificada superior)
                    Connections {
                        target: layerDelegate
                        ignoreUnknownSignals: true
                        function onBlendModeChanged() {
                            if (blendModeList && blendModeList.model && blendModeList.isReady) {
                                for (var i = 0; i < blendModeList.model.length; i++) {
                                    if (blendModeList.model[i] === blendMode) {
                                        if (blendModeList.currentIndex !== i) {
                                            blendModeList.isReady = false
                                            blendModeList.currentIndex = i
                                            blendModeList.positionViewAtIndex(i, ListView.Center)
                                            blendModeList.isReady = true
                                        }
                                        break
                                    }
                                }
                            }
                        }
                    }

                    // Manejador inteligente de eventos de scroll (evita que layersList exterior robe el scroll)
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: {
                            if (layersListRef) layersListRef.interactive = false
                        }
                        onExited: {
                            if (layersListRef) layersListRef.interactive = true
                        }
                        onPressed: (mouse) => {
                            mouse.accepted = false // Permite que se propague a los delegates de la lista
                            if (layersListRef) layersListRef.interactive = false
                        }
                        onReleased: {
                            if (layersListRef) layersListRef.interactive = true
                        }
                        onWheel: (wheel) => {
                            // Scroll directo extremadamente suave
                            blendModeList.contentY = Math.max(0, Math.min(blendModeList.contentHeight - blendModeList.height, blendModeList.contentY - wheel.angleDelta.y))
                            wheel.accepted = true
                        }
                    }
                }
            }
        }
    }

    // Contextual Options Popup
    Popup {
        id: layerOptionsPopup
        width: 180
        height: (layerType === "vector") ? 390 : 356
        x: -width - 8
        y: Math.max(4, Math.min(layersListRef ? layersListRef.height - height - 4 : 400, (headerContent.height - height) / 2))
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: "#141416"
            radius: 12
            border.color: "#2c2c30"
            border.width: 1
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#aa000000"
                shadowBlur: 15
                shadowVerticalOffset: 4
            }
            
            // Arrow pointing towards the thumbnail on the right
            Rectangle {
                id: popupArrow
                width: 12; height: 12
                rotation: 45
                color: "#141416"
                border.color: "#2c2c30"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.right
                anchors.horizontalCenterOffset: -1
                z: -1
            }
            // Arrow mask to keep clean inside the popup
            Rectangle {
                width: 12; height: 24
                color: "#141416"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 1
                z: 0
            }
        }
        
        contentItem: Column {
            spacing: 1
            width: parent.width
            
            Repeater {
                model: {
                    var base = [
                        { label: "Rename", icon: "edit-3.svg", action: "rename", active: false, rot: 0 },
                        { label: "Select Pixels", icon: "selection.svg", action: "select", active: false, rot: 0 },
                        { label: "Copy", icon: "copy.svg", action: "copy", active: false, rot: 0 }
                    ];
                    if (layerType === "vector") {
                        base.push({ label: "Rasterize Layer", icon: "layers.svg", action: "rasterize", active: false, rot: 0 });
                    }
                    base.push({ label: "Fill Layer", icon: "paint-bucket.svg", action: "fill", active: false, rot: 0 });
                    base.push({ label: "Clear", icon: "trash-2.svg", action: "clear", active: false, rot: 0 });
                    base.push({ label: "Alpha Lock", icon: "lock.svg", action: "alphalock", active: isAlphaLocked, rot: 0 });
                    base.push({ label: "Clipping Mask", icon: "arrow-down-left.svg", action: "clip", active: isClipped, rot: -90 });
                    base.push({ label: "Invert Colors", icon: "rotate.svg", action: "invert", active: false, rot: 0 });
                    base.push({ label: "Reference Layer", icon: "star.svg", action: "reference", active: (typeof listModel.reference !== "undefined" ? listModel.reference : false), rot: 0 });
                    base.push({ label: "Merge Down", icon: "arrow-down-left.svg", action: "mergedown", active: false, rot: 0 });
                    return base;
                }
                
                delegate: Rectangle {
                    width: 168
                    height: 34
                    color: "transparent"
                    radius: 6
                    
                    property bool isHovered: false
                    property bool isActiveItem: modelData.active
                    
                    Rectangle {
                        anchors.fill: parent
                        color: isActiveItem ? Qt.rgba(layerDelegate.accentColor.r, layerDelegate.accentColor.g, layerDelegate.accentColor.b, 0.25) : (isHovered ? "#ffffff10" : "transparent")
                        radius: 6
                        border.color: isActiveItem ? layerDelegate.accentColor : "transparent"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        
                        Image {
                            source: iconPath(modelData.icon)
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            Layout.alignment: Qt.AlignVCenter
                            rotation: modelData.rot
                            
                            layer.enabled: isActiveItem
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: layerDelegate.accentColor
                            }
                            opacity: isActiveItem ? 1.0 : (isHovered ? 0.9 : 0.7)
                        }
                        
                        Text {
                            text: modelData.label
                            color: isActiveItem ? "white" : "#e4e4e7"
                            font.pixelSize: 11
                            font.weight: isActiveItem ? Font.Bold : Font.Normal
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: isHovered = true
                        onExited: isHovered = false
                        onClicked: {
                            layerOptionsPopup.close()
                            handleMenuAction(modelData.action)
                        }
                    }
                }
            }
        }
    }

    function handleMenuAction(action) {
        if (action === "rename") {
            layerDelegate.isRenaming = true
        } else if (action === "rasterize") {
            if (targetCanvas && typeof targetCanvas.rasterizeVectorLayer === "function") {
                targetCanvas.rasterizeVectorLayer(layerIndex)
            }
        } else if (action === "select") {
            if (targetCanvas && typeof targetCanvas.selectPixels === "function") {
                targetCanvas.selectPixels(layerIndex)
            }
        } else if (action === "copy") {
            if (targetCanvas && typeof targetCanvas.duplicateLayer === "function") {
                targetCanvas.duplicateLayer(layerIndex)
            }
        } else if (action === "fill") {
            if (targetCanvas && typeof targetCanvas.selectAll === "function") {
                targetCanvas.selectAll()
                targetCanvas.colorSelection(targetCanvas.brushColor)
                targetCanvas.deselect()
            }
        } else if (action === "clear") {
            if (targetCanvas && typeof targetCanvas.clearLayer === "function") {
                targetCanvas.clearLayer(layerIndex)
            }
        } else if (action === "alphalock") {
            if (targetCanvas && typeof targetCanvas.toggleAlphaLock === "function") {
                targetCanvas.toggleAlphaLock(layerIndex)
            }
        } else if (action === "clip") {
            if (targetCanvas && typeof targetCanvas.toggleClipping === "function") {
                targetCanvas.toggleClipping(layerIndex)
            }
        } else if (action === "invert") {
            if (targetCanvas && typeof targetCanvas.invertLayerColors === "function") {
                targetCanvas.invertLayerColors(layerIndex)
            }
        } else if (action === "reference") {
            if (targetCanvas && typeof targetCanvas.toggleReference === "function") {
                targetCanvas.toggleReference(layerIndex)
            }
        } else if (action === "mergedown") {
            if (targetCanvas && typeof targetCanvas.mergeDown === "function") {
                targetCanvas.mergeDown(layerIndex)
            }
        }
    }
}

