import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects


Item {
    id: layerDelegate
    
    // Properties passed from the main list
    property int listIndex: index // The special 'index' variable from Delegate
    property var listModel: model // THe special 'model' variable from Delegate
    
    // External References
    property var layersListRef: ListView.view 
    property var dragGhostRef: null // Reference to the drag ghost
    
    // --- 0. DROP INDICATOR (Blue Line) ---
    Rectangle {
        id: dropIndicator
        // Show if this item is the target AND we are dragging something AND it's not this item
        visible: layersListRef && layersListRef.draggedIndex !== -1 && layersListRef.dropTargetIndex === listIndex && layersListRef.draggedIndex !== listIndex
        width: parent.width - 16
        height: 2
        color: "#007aff"
        anchors.bottom: parent.bottom // Drop below by default
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999
        
        // Add a small glow
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 4; shadowColor: "#007aff" }
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
            color: "#0a84ff"
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
                    mainCanvas.toggleLock(listIndex); 
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
                    mainCanvas.removeLayer(listIndex); 
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
        border.width: isActive ? 2 : 1
        border.color: isActive ? "#007aff" : (isClipped ? "#333" : "#2c2c2e")
        
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
            
            // MouseArea for Dragging & Selection
            MouseArea {
                id: dragArea
                anchors.fill: parent
                property real startX: 0
                drag.target: layerContent
                drag.axis: Drag.XAxis
                drag.minimumX: -220; drag.maximumX: 180
                drag.filterChildren: true 
                onPressed: { startX = mouseX }
                onClicked: {
                    if (layersListRef.swipedIndex !== -1 || layersListRef.optionsIndex !== -1) {
                        layersListRef.swipedIndex = -1; layersListRef.optionsIndex = -1; return
                    }
                    mainCanvas.setActiveLayer(layerIndex)
                    if (layerType === "background") layerDelegate.requestBackgroundEdit()
                }
                onReleased: {
                    var delta = mouseX - startX
                    if (layerDelegate.isSwipedOpen && delta > 20) layersListRef.swipedIndex = -1
                    else if (!layerDelegate.isSwipedOpen) {
                        if (delta < -35) layersListRef.swipedIndex = listIndex
                        else if (delta > 45) mainCanvas.toggleClipping(layerIndex)
                    }
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
                    color: layerType === "background" ? "white" : "#18181a"
                    border.color: isActive ? "#ffffff50" : "#ffffff20"
                    border.width: 1
                    clip: true
                    
                    Image { visible: layerType !== "background"; anchors.fill: parent; source: iconPath("grid_pattern.svg"); fillMode: Image.Tile; opacity: 0.05 }
                    Image {
                        visible: layerType !== "background" && layerType !== "group"
                        anchors.fill: parent; anchors.margins: 2
                        source: thumbnailSource || ""
                        fillMode: Image.PreserveAspectFit
                        cache: false
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
                            
                            // PREMIUM: Blend Mode Indicator (Badge)
                            Rectangle {
                                visible: blendMode !== "Normal"
                                height: 14
                                width: modeText.contentWidth + 10
                                color: isActive ? "#007aff" : "#2c2c2e"
                                radius: 4
                                border.color: isActive ? "transparent" : "#444"
                                border.width: 1
                                Text {
                                    id: modeText
                                    anchors.centerIn: parent
                                    text: blendMode
                                    color: isActive ? "white" : "#aaa"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    font.capitalization: Font.AllUppercase
                                }
                            }
                        }

                        // Integrated Opacity Slider (Only when Active)
                        RowLayout {
                            visible: isActive
                            width: parent.width
                            spacing: 8
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                radius: 2
                                color: "#33ffffff"
                                Rectangle { width: parent.width * layerOpacity; height: parent.height; radius: 2; color: "white" }
                                Rectangle { 
                                    x: (parent.width * layerOpacity) - 6; y: -4; width: 12; height: 12; radius: 6; color: "white"
                                    layer.enabled: true
                                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 2; shadowColor: "#40000000" }
                                }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -8
                                    onPressed: { var v=Math.max(0,Math.min(1,mouseX/width)); mainCanvas.setLayerOpacity(layerIndex,v) }
                                    onPositionChanged: { var v=Math.max(0,Math.min(1,mouseX/width)); mainCanvas.setLayerOpacity(layerIndex,v) }
                                }
                            }
                            Text {
                                text: Math.round(layerOpacity*100)+"%"
                                color: "white"
                                font.pixelSize: 10
                                opacity: 0.6
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
        Rectangle {
            id: optionsPanel
            anchors.top: headerContent.bottom
            width: parent.width
            height: parent.height - 60 // Fit remaining
            visible: layersListRef.optionsIndex === layerIndex
            color: "transparent"
            clip: true
            
            // Re-implement simplified options if expanded
            // ... (For now, prioritizing the main view cleanup as requested)
            // Note: If delegate height expands to 320 for options, we need content here.
            // Restoring basic options list if expanded:
            
            // --- PREMIUM OPTIONS PANEL (Blend Modes & Opacity) ---
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                visible: parent.visible
                
                // 1. Opacity Slider (Re-added for explicit control)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Text { text: "Opacity"; color: "#aaa"; font.pixelSize: 12 }
                    
                    Slider {
                        Layout.fillWidth: true
                        from: 0.0; to: 1.0
                        value: layerOpacity
                        stepSize: 0.01
                        onMoved: mainCanvas.setLayerOpacity(layerIndex, value)
                        
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth
                            height: 4
                            radius: 2
                            color: "#3a3a3c"
                            Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; color: "#007aff"; radius: 2 }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 16; height: 16
                            radius: 8
                            color: "#fff"
                            border.width: 1; border.color: "#ccc"
                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 4; shadowOpacity: 0.3 }
                        }
                    }
                    Text { text: Math.round(layerOpacity * 100) + "%"; color: "white"; font.pixelSize: 12; Layout.preferredWidth: 30 }
                }

                // 2. Blend Mode Selector (Framed List / Wheel Style)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Text { text: "Blend Mode"; color: "#aaa"; font.pixelSize: 12; anchors.top: parent.top }
                    
                    // Container for the list
                    Rectangle {
                        anchors.top: parent.top; anchors.topMargin: 20
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        color: "transparent"
                        
                        // Blend Mode Picker Frame (Premium Glassmorphism)
                        Rectangle {
                            id: highlightFrame
                            height: 42 // Matching item height + bit more
                            width: parent.width - 8
                            anchors.centerIn: parent
                            color: "#15ffffff" // Very subtle white tint
                            radius: 12
                            border.color: "#33007aff" // Subtle blue
                            border.width: 1
                            z: 0
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: 1.0
                                shadowEnabled: true
                                shadowBlur: 15
                                shadowColor: "#40000000"
                            }
                        }

                        ListView {
                            id: blendModeList
                            anchors.fill: parent
                            anchors.margins: 2 
                            clip: true
                            focus: true
                            interactive: true 
                            
                            // Wheel Physics - Adjusted for fluid scrolling
                            snapMode: ListView.SnapToItem 
                            highlightRangeMode: ListView.StrictlyEnforceRange // More aggressive for center snapping
                            preferredHighlightBegin: height/2 - 20
                            preferredHighlightEnd: height/2 + 20
                            highlightMoveDuration: 200
                            
                            // Critical: Prevent parent ListView from stealing the scroll
                            boundsBehavior: Flickable.StopAtBounds
                            pressDelay: 0
                            
                            // Prevent parent (Channel list) from stealing scrolling
                            property bool isScrolling: moving || dragging
                            onIsScrollingChanged: {
                                if (isScrolling) {
                                    layersListRef.interactive = false
                                } else {
                                    layersListRef.interactive = true
                                }
                            }
                            
                            // Important: Extra padding so edge items can reach the center
                            header: Item { width: blendModeList.width; height: (blendModeList.height / 2) - 20 }
                            footer: Item { width: blendModeList.width; height: (blendModeList.height / 2) - 20 }
                            
                            model: ["Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten", "Color Dodge", "Color Burn", "Soft Light", "Hard Light", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity"]
                            
                            delegate: Item {
                                width: blendModeList.width
                                height: 40 // Slightly taller for better spacing
                                
                                // --- REACTIVE POSITION TRACKING (Critical for the effect to work) ---
                                // By referencing blendModeList.contentY, this property re-evaluates on every scroll
                                property real itemCenterY: y + height/2 - blendModeList.contentY
                                property real listCenterY: blendModeList.height / 2
                                property real distFromCenter: Math.abs(itemCenterY - listCenterY)
                                
                                // Factor: 1.0 at center, 0.0 at edges. Divisor (70) controls the 'width' of the lens.
                                property real factor: Math.max(0.0, 1.0 - (distFromCenter / 80.0))
                                property bool isSelected: distFromCenter < 20 // Active center item
                                
                                Text {
                                    text: modelData
                                    anchors.centerIn: parent
                                    
                                    // Visuals
                                    color: Qt.hsla(0, 0, 1.0, 0.3 + (factor * 0.7)) 
                                    
                                    // Premium Scaling: x1.5 at center, x0.9 at edges
                                    scale: 0.9 + (Math.pow(factor, 2) * 0.6) 
                                    
                                    font.pixelSize: 14
                                    font.weight: factor > 0.8 ? Font.DemiBold : Font.Normal
                                    font.letterSpacing: factor * 0.5
                                    
                                    // Subtle Glow/Shadow for central item
                                    layer.enabled: factor > 0.5
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.rgba(0, 0.48, 1, factor * 0.5) // Blue-ish glow
                                        shadowBlur: 10 * factor
                                        shadowVerticalOffset: 0
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: blendModeList.currentIndex = index
                                }
                            }
                            
                            onCurrentIndexChanged: {
                                // IMPORTANT: Only update backend if NOT dragging to avoid feedback loops
                                // which reset the list mid-scroll.
                                if (!moving && !dragging && currentIndex >= 0) {
                                    mainCanvas.setLayerBlendMode(layerIndex, model[currentIndex])
                                }
                            }
                            
                            onMovementEnded: {
                                // Commit the final selection when movement stops
                                if (currentIndex >= 0) {
                                    mainCanvas.setLayerBlendMode(layerIndex, model[currentIndex])
                                }
                            }
                            
                            // Initialize position
                            Component.onCompleted: {
                                for(var i=0; i<model.length; i++) {
                                    if(model[i] === blendMode) {
                                        currentIndex = i
                                        break
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

