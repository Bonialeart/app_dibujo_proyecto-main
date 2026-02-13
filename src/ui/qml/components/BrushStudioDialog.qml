import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ============================================================================
// BrushStudioDialog.qml — Premium Brush Editor (Procreate-inspired)
// ============================================================================
// Three-column layout: Attributes | Settings | Drawing Pad
// Full-screen modal overlay with glassmorphism dark theme
// ============================================================================

Rectangle {
    id: studio
    anchors.fill: parent
    color: "transparent"
    visible: false
    z: 10000

    // === PUBLIC API ===
    property var targetCanvas: null
    property color colorAccent: "#6366f1"
    property string brushName: targetCanvas ? (targetCanvas.activeBrushName || "Untitled") : "Untitled"

    // Current attribute tab (0-9)
    property int activeTab: 0

    signal closed()
    signal applied()

    function open() {
        activeTab = 0
        visible = true
        // Begin editing: clone the active preset for modification
        if (targetCanvas) {
            targetCanvas.beginBrushEdit(brushName)
        }
        openAnim.start()
    }

    function close() {
        closeAnim.start()
    }

    // === DESIGN TOKENS ===
    readonly property color bgDeep:     "#0d0d0f"
    readonly property color bgPanel:    "#161618"
    readonly property color bgCard:     "#1c1c1e"
    readonly property color bgSurface:  "#242426"
    readonly property color borderDim:  "#2a2a2c"
    readonly property color borderLit:  "#3a3a3c"
    readonly property color textPrimary:"#f0f0f0"
    readonly property color textMuted:  "#888890"
    readonly property color textDim:    "#555560"

    // === ANIMATIONS ===
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: dimmer; property: "opacity"; from: 0; to: 0.7; duration: 250 }
        NumberAnimation { target: dialogCard; property: "opacity"; from: 0; to: 1; duration: 200 }
        NumberAnimation { target: dialogCard; property: "scale"; from: 0.96; to: 1; duration: 300; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: dimmer; property: "opacity"; to: 0; duration: 200 }
        NumberAnimation { target: dialogCard; property: "opacity"; to: 0; duration: 150 }
        NumberAnimation { target: dialogCard; property: "scale"; to: 0.96; duration: 200; easing.type: Easing.InCubic }
        onFinished: { studio.visible = false; studio.closed() }
    }

    // === DIMMER BACKGROUND ===
    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        MouseArea { anchors.fill: parent; onClicked: studio.close() }
    }

    // === MAIN DIALOG CARD ===
    Rectangle {
        id: dialogCard
        anchors.fill: parent
        anchors.margins: 40
        radius: 18
        color: bgDeep
        border.color: borderDim
        border.width: 1
        clip: true
        opacity: 0

        // Prevent click-through
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        // === TOP BAR ===
        Rectangle {
            id: topBar
            width: parent.width
            height: 56
            color: bgPanel
            z: 10

            // Bottom border
            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: borderDim }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 20
                spacing: 16

                // Brush Studio Title
                Text {
                    text: "Advance Brush Settings"
                    color: textPrimary
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.3
                }

                Item { Layout.fillWidth: true }

                // Cancel Button
                Rectangle {
                    Layout.preferredWidth: cancelText.width + 32
                    Layout.preferredHeight: 34
                    radius: 8
                    color: cancelMa.containsMouse ? bgSurface : "transparent"
                    border.color: cancelMa.containsMouse ? borderLit : borderDim
                    border.width: 1

                    Text {
                        id: cancelText
                        text: "Cancel"
                        color: textMuted
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (targetCanvas) targetCanvas.cancelBrushEdit()
                            studio.close()
                        }
                    }
                }

                // Save As Copy Button
                Rectangle {
                    Layout.preferredWidth: saveCopyText.width + 32
                    Layout.preferredHeight: 34
                    radius: 8
                    color: saveCopyMa.containsMouse ? bgSurface : "transparent"
                    border.color: saveCopyMa.containsMouse ? borderLit : borderDim
                    border.width: 1

                    Text {
                        id: saveCopyText
                        text: "Save As Copy Brush"
                        color: textMuted
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: saveCopyMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (targetCanvas) targetCanvas.saveAsCopyBrush(studio.brushName + " Copy")
                        }
                    }
                }

                // Apply Button (Accent)
                Rectangle {
                    Layout.preferredWidth: applyText.width + 40
                    Layout.preferredHeight: 34
                    radius: 8
                    color: applyMa.containsMouse ? Qt.lighter(colorAccent, 1.15) : colorAccent

                    Text {
                        id: applyText
                        text: "Apply"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: applyMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (targetCanvas) targetCanvas.applyBrushEdit()
                            studio.applied()
                            studio.close()
                        }
                    }
                }
            }
        }

        // === THREE-COLUMN BODY ===
        RowLayout {
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            // ─── LEFT: ATTRIBUTES SIDEBAR ───
            Rectangle {
                id: attributesSidebar
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                color: bgPanel

                // Right border
                Rectangle { width: 1; height: parent.height; anchors.right: parent.right; color: borderDim }

                // Brush stamp shape preview (Procreate-style)
                // Auto-updates when editing preset changes
                Connections {
                    target: targetCanvas
                    function onEditingPresetChanged() {
                        if (targetCanvas && targetCanvas.isEditingBrush) {
                            brushShapeImg.source = ""
                            brushShapeImg.source = targetCanvas.getStampPreview()
                        }
                    }
                }
                Rectangle {
                    id: brushPreviewThumb
                    width: parent.width - 32
                    height: 120
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 12
                    color: bgDeep
                    border.color: colorAccent
                    border.width: 1.5
                    clip: true

                    // Actual brush stroke preview from engine
                    Image {
                        id: brushShapeImg
                        anchors.fill: parent
                        anchors.margins: 8
                        source: (targetCanvas && studio.brushName) ? targetCanvas.get_brush_preview(studio.brushName) : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }

                    // Fallback when no preview
                    Text {
                        text: "🖌"
                        font.pixelSize: 28
                        anchors.centerIn: parent
                        opacity: 0.4
                        visible: brushShapeImg.status !== Image.Ready
                    }
                }

                // Brush name label
                Text {
                    id: brushNameLabel
                    text: studio.brushName
                    color: textPrimary
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    anchors.top: brushPreviewThumb.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }

                // + button
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: addMa.containsMouse ? bgSurface : "transparent"
                    border.color: borderDim; border.width: 1
                    anchors.top: brushNameLabel.bottom
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text { text: "+"; color: textMuted; font.pixelSize: 16; anchors.centerIn: parent }
                    MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }

                // Tab list
                ListView {
                    id: tabListView
                    anchors.top: brushNameLabel.bottom
                    anchors.topMargin: 50
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    spacing: 2
                    clip: true
                    interactive: false

                    model: ListModel {
                        ListElement { icon: "〰"; label: "Path";       idx: 0 }
                        ListElement { icon: "✦";  label: "Shape";      idx: 1 }
                        ListElement { icon: "◌";  label: "Randomize";  idx: 2 }
                        ListElement { icon: "▦";  label: "Texture";    idx: 3 }
                        ListElement { icon: "◇";  label: "Visibility"; idx: 4 }
                        ListElement { icon: "💧"; label: "Water Mix";  idx: 5 }
                        ListElement { icon: "✏";  label: "Stylus Sensitivity"; idx: 6 }
                        ListElement { icon: "🎨"; label: "Color Dynamic"; idx: 7 }
                        ListElement { icon: "⚙";  label: "Customize";  idx: 8 }
                        ListElement { icon: "ℹ";  label: "Creation";   idx: 9 }
                    }

                    delegate: Rectangle {
                        width: tabListView.width
                        height: 38
                        color: studio.activeTab === model.idx
                            ? colorAccent
                            : (tabDelegateMa.containsMouse ? bgSurface : "transparent")
                        radius: 0

                        // Active indicator bar
                        Rectangle {
                            width: 3; height: parent.height
                            color: colorAccent
                            visible: studio.activeTab === model.idx
                            anchors.left: parent.left
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                text: model.icon
                                font.pixelSize: 14
                                color: studio.activeTab === model.idx ? "#fff" : textMuted
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                text: model.label
                                font.pixelSize: 12
                                font.weight: studio.activeTab === model.idx ? Font.DemiBold : Font.Normal
                                color: studio.activeTab === model.idx ? "#fff" : textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tabDelegateMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: studio.activeTab = model.idx
                        }
                    }
                }
            }

            // ─── CENTER: SETTINGS PANEL ───
            Rectangle {
                id: settingsPanel
                Layout.fillHeight: true
                Layout.fillWidth: true
                color: bgDeep

                // Right border
                Rectangle { width: 1; height: parent.height; anchors.right: parent.right; color: borderDim }
                
                // ═══════ Reusable Studio Components ═══════

                // Slider with label + numeric display
                component StudioSlider : Column {
                    property string label: "Label"
                    property alias value: slider.value
                    property alias from: slider.from
                    property alias to: slider.to
                    property string suffix: "%"
                    property bool offsetColor: false
                    
                    width: parent.width
                    spacing: 6

                    RowLayout {
                        width: parent.width
                        Text { text: label; color: textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 50; height: 24; radius: 6
                            color: valueInput.activeFocus ? bgSurface : "transparent"
                            border.color: valueInput.activeFocus ? colorAccent : borderDim
                            border.width: 1

                            TextInput {
                                id: valueInput
                                anchors.fill: parent
                                text: Math.round(slider.value * 100) / 100 + suffix
                                color: textPrimary
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                selectByMouse: true
                                
                                onEditingFinished: {
                                    var val = parseFloat(text)
                                    if (!isNaN(val)) slider.value = val
                                    text = Qt.binding(function() { return Math.round(slider.value * 100) / 100 + suffix })
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 24
                        
                        Rectangle {
                            width: parent.width; height: 4
                            anchors.centerIn: parent
                            color: bgSurface
                            radius: 2
                            
                            Rectangle {
                                width: Math.max(0, slider.visualPosition * parent.width); height: parent.height
                                color: offsetColor ? textMuted : colorAccent
                                radius: 2
                                visible: !offsetColor
                            }
                        }

                        Slider {
                            id: slider
                            anchors.fill: parent
                            handle: Rectangle {
                                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                                width: 16; height: 16; radius: 8
                                color: "#fff"
                                border.color: borderDim; border.width: 1
                                
                                Rectangle {
                                    z: -1; anchors.fill: parent; anchors.margins: -2
                                    color: "black"; opacity: 0.25; radius: 10
                                }
                            }
                            background: Item {}
                        }
                    }
                }

                // Reusable Toggle Component
                component StudioToggle : RowLayout {
                    property string label: "Label"
                    property alias checked: toggle.checked
                    width: parent.width
                    spacing: 12

                    Text { text: label; color: textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                    
                    Switch {
                        id: toggle
                        checked: false
                        display: AbstractButton.IconOnly
                        
                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 22
                            x: toggle.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 11
                            color: toggle.checked ? colorAccent : bgSurface
                            border.color: borderDim
                            border.width: 1

                            Rectangle {
                                x: toggle.checked ? parent.width - width - 2 : 2
                                y: 2
                                width: 18; height: 18
                                radius: 9
                                color: "#ffffff"
                                // Behavior on x { NumberAnimation { duration: 100 } }
                            }
                        }
                    }
                }

                // Scrollable Content
                Flickable {
                    anchors.fill: parent
                    contentHeight: contentCol.height + 40
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentCol
                        width: parent.width - 48
                        x: 24; y: 24
                        spacing: 32

                        // --- TAB 0: STROKE PATH ---
                        Column {
                            visible: studio.activeTab === 0
                            width: parent.width
                            spacing: 24
                            
                            // Section Header
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "STROKE PROPERTIES"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Spacing"
                                from: 0.01; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("stroke", "spacing") || 0.1 : 0.1
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "spacing", value)
                            }
                            
                            StudioSlider {
                                label: "StreamLine"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("stroke", "streamline") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "streamline", value)
                            }

                            StudioSlider {
                                label: "Taper Start"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("stroke", "taper_start") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "taper_start", value)
                            }

                            StudioSlider {
                                label: "Taper End"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("stroke", "taper_end") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "taper_end", value)
                            }
                            
                            StudioSlider {
                                label: "Jitter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_jitter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_jitter", value)
                            }

                            StudioToggle {
                                label: "Anti-Concussion"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("stroke", "anti_concussion") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "anti_concussion", checked)
                            }
                        }
                        
                        // --- TAB 1: SHAPE ---
                        Column {
                            visible: studio.activeTab === 1
                            width: parent.width
                            spacing: 24
                            
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "SHAPE BEHAVIOR"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Roundness"
                                from: 0.01; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "roundness") || 1.0 : 1.0
                                suffix: ""
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "roundness", value)
                            }

                            StudioSlider {
                                label: "Scatter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "scatter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "scatter", value)
                            }
                            
                            StudioSlider {
                                label: "Rotation"
                                from: -180; to: 180
                                suffix: "°"
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "rotation") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "rotation", value)
                            }

                            StudioSlider {
                                label: "Contrast"
                                from: 0; to: 2.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "contrast") || 1.0 : 1.0
                                suffix: ""
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "contrast", value)
                            }

                            StudioSlider {
                                label: "Blur"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "blur") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "blur", value)
                            }

                            StudioToggle {
                                label: "Follow Stroke"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("shape", "follow_stroke") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "follow_stroke", checked)
                            }
                            
                            StudioToggle {
                                label: "Flip X"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("shape", "flip_x") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "flip_x", checked)
                            }
                            
                            StudioToggle {
                                label: "Flip Y"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("shape", "flip_y") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "flip_y", checked)
                            }
                        }

                        // --- TAB 2: RANDOMIZE (Placeholder, merged into Shape logic usually but keeping user's tab list) ---
                         Column {
                            visible: studio.activeTab === 2
                            width: parent.width
                            spacing: 24
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "RANDOMIZE"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Size Jitter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_jitter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_jitter", value)
                            }
                            StudioSlider {
                                label: "Opacity Jitter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_jitter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_jitter", value)
                            }
                        }

                        // --- TAB 3: TEXTURE (GRAIN) ---
                        Column {
                            visible: studio.activeTab === 3
                            width: parent.width
                            spacing: 24
                            
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "GRAIN BEHAVIOR"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioToggle {
                                label: "Rolling (Fixed to canvas)"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("grain", "rolling") || true : true
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "rolling", checked)
                            }

                            StudioSlider {
                                label: "Scale"
                                from: 10; to: 500
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "scale") || 100 : 100
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "scale", value)
                            }
                            
                            StudioSlider {
                                label: "Depth"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "intensity") || 0.5 : 0.5
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "intensity", value)
                            }
                            
                            StudioSlider {
                                label: "Brightness"
                                from: -1.0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "brightness") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "brightness", value)
                            }
                            
                            StudioSlider {
                                label: "Contrast"
                                from: 0; to: 2.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "contrast") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "contrast", value)
                            }

                            StudioSlider {
                                label: "Rotation"
                                from: -180; to: 180
                                suffix: "°"
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "rotation") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "rotation", value)
                            }
                        }
                        
                        // --- TAB 4: VISIBILITY (RENDERING) ---
                        Column {
                            visible: studio.activeTab === 4
                            width: parent.width
                            spacing: 24
                             Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "RENDERING"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioSlider {
                                label: "Flow"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_flow") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_flow", value)
                            }
                            
                            StudioToggle {
                                label: "Anti-Aliasing"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("rendering", "anti_aliasing") || true : true
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("rendering", "anti_aliasing", checked)
                            }
                        }

                        // --- TAB 5: WATER MIX ---
                         Column {
                            visible: studio.activeTab === 5
                            width: parent.width
                            spacing: 24
                             Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "WET MIX"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioSlider {
                                label: "Dilution"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "dilution") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "dilution", value)
                            }
                            StudioSlider {
                                label: "Charge"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "charge") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "charge", value)
                            }
                            StudioSlider {
                                label: "Pigment"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "pigment") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "pigment", value)
                            }
                            StudioSlider {
                                label: "Pull (Smudge)"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "pull") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "pull", value)
                            }
                            StudioSlider {
                                label: "Wetness"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "wetness") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "wetness", value)
                            }
                            StudioSlider {
                                label: "Blur"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "blur") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "blur", value)
                            }
                        }
                        // --- TAB 6: STYLUS SENSITIVITY ---
                        Column {
                            visible: studio.activeTab === 6
                            width: parent.width
                            spacing: 24
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "PRESSURE RESPONSE"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Size Base"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_base") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_base", value)
                            }
                            StudioSlider {
                                label: "Size Min"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_min") || 0.1 : 0.1
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_min", value)
                            }
                            StudioSlider {
                                label: "Size Tilt Influence"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_tilt") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_tilt", value)
                            }
                            StudioSlider {
                                label: "Size Velocity Influence"
                                from: -1.0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_velocity") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_velocity", value)
                            }

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "OPACITY RESPONSE"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Opacity Base"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_base") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_base", value)
                            }
                            StudioSlider {
                                label: "Opacity Min"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_min") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_min", value)
                            }
                            StudioSlider {
                                label: "Opacity Tilt Influence"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_tilt") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_tilt", value)
                            }
                            StudioSlider {
                                label: "Opacity Velocity Influence"
                                from: -1.0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_velocity") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_velocity", value)
                            }
                        }

                        // --- TAB 7: COLOR DYNAMICS ---
                        Column {
                            visible: studio.activeTab === 7
                            width: parent.width
                            spacing: 24
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "COLOR JITTER"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioSlider {
                                label: "Hue Jitter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("color", "hue_jitter") || 0 : 0
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("color", "hue_jitter", value)
                            }
                            StudioSlider {
                                label: "Saturation Jitter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("color", "saturation_jitter") || 0 : 0
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("color", "saturation_jitter", value)
                            }
                            StudioSlider {
                                label: "Brightness Jitter"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("color", "brightness_jitter") || 0 : 0
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("color", "brightness_jitter", value)
                            }
                        }

                        // --- TAB 8: CUSTOMIZE ---
                        Column {
                            visible: studio.activeTab === 8
                            width: parent.width
                            spacing: 24
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "BRUSH PROPERTIES"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Brush Name Editor
                            Column {
                                width: parent.width; spacing: 8
                                Text { text: "Brush Name"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 36; radius: 8
                                    color: bgSurface; border.color: borderDim; border.width: 1
                                    TextInput {
                                        id: brushNameEditor
                                        anchors.fill: parent; anchors.margins: 10
                                        text: targetCanvas ? targetCanvas.getBrushProperty("meta", "name") || studio.brushName : studio.brushName
                                        color: textPrimary; font.pixelSize: 13
                                        verticalAlignment: TextInput.AlignVCenter
                                        onEditingFinished: if(targetCanvas) targetCanvas.setBrushProperty("meta", "name", text)
                                    }
                                }
                            }

                            StudioSlider {
                                label: "Default Size"
                                from: 1; to: 500
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_size") || 20 : 20
                                suffix: "px"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_size", value)
                            }
                            StudioSlider {
                                label: "Max Size"
                                from: 1; to: 1000
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "max_size") || 500 : 500
                                suffix: "px"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "max_size", value)
                            }
                            StudioSlider {
                                label: "Default Opacity"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_opacity") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_opacity", value)
                            }
                            StudioSlider {
                                label: "Default Hardness"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_hardness") || 0.8 : 0.8
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_hardness", value)
                            }
                            StudioSlider {
                                label: "Default Flow"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_flow") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_flow", value)
                            }

                            // Reset Button
                            Rectangle {
                                width: parent.width; height: 36; radius: 8
                                color: resetMa.containsMouse ? bgSurface : "transparent"
                                border.color: borderDim; border.width: 1
                                Text {
                                    text: "↺ Reset to Default"
                                    color: textMuted; font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: resetMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if(targetCanvas) targetCanvas.resetBrushToDefault()
                                }
                            }
                        }

                        // --- TAB 9: ABOUT / CREATION ---
                        Column {
                            visible: studio.activeTab === 9
                            width: parent.width
                            spacing: 24
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "ABOUT THIS BRUSH"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            Column {
                                width: parent.width; spacing: 12
                                
                                Row { spacing: 12; Text { text: "Name:"; color: textDim; font.pixelSize: 12; width: 80 } Text { text: targetCanvas ? targetCanvas.getBrushProperty("meta", "name") || studio.brushName : studio.brushName; color: textPrimary; font.pixelSize: 12 } }
                                Row { spacing: 12; Text { text: "Author:"; color: textDim; font.pixelSize: 12; width: 80 } Text { text: targetCanvas ? targetCanvas.getBrushProperty("meta", "author") || "ArtFlow Studio" : "ArtFlow Studio"; color: textPrimary; font.pixelSize: 12 } }
                                Row { spacing: 12; Text { text: "Created:"; color: textDim; font.pixelSize: 12; width: 80 } Text { text: Qt.formatDate(new Date(), "dd MMM yyyy"); color: textPrimary; font.pixelSize: 12 } }
                                Row { spacing: 12; Text { text: "Category:"; color: textDim; font.pixelSize: 12; width: 80 } Text { text: targetCanvas ? targetCanvas.getBrushProperty("meta", "category") || "Custom" : "Custom"; color: textPrimary; font.pixelSize: 12 } }
                                Row { spacing: 12; Text { text: "UUID:"; color: textDim; font.pixelSize: 12; width: 80 } Text { text: targetCanvas ? targetCanvas.getBrushProperty("meta", "uuid") || "—" : "—"; color: textDim; font.pixelSize: 10; elide: Text.ElideMiddle; width: 120 } }
                            }

                            // Notes area
                            Column {
                                width: parent.width; spacing: 8
                                Text { text: "Notes"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 100; radius: 8; color: bgSurface
                                    border.color: borderDim; border.width: 1
                                    TextEdit {
                                        anchors.fill: parent; anchors.margins: 10
                                        wrapMode: TextEdit.Wrap
                                        color: textPrimary; font.pixelSize: 12
                                        text: ""
                                    }
                                    Text {
                                        text: "Add notes about this brush..."
                                        color: textDim
                                        font.pixelSize: 12
                                        anchors.left: parent.left; anchors.leftMargin: 10
                                        anchors.top: parent.top; anchors.topMargin: 10
                                        opacity: 0.5
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─── RIGHT: DRAWING PAD ───
            Rectangle {
                id: drawingPad
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(parent.width * 0.35, 360)
                color: bgPanel

                // State
                property var drawingPaths: []
                property bool isDrawing: false
                property real lastX: 0
                property real lastY: 0

                // Drawing Pad Header
                Rectangle {
                    id: padHeader
                    width: parent.width
                    height: 44
                    color: "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text { text: "✎"; font.pixelSize: 14; color: textMuted }
                        Text {
                            text: "Drawing Pad"
                            color: textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // Color swatch
                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: targetCanvas ? targetCanvas.brushColor : "#ffffff"
                            border.color: "#fff"; border.width: 2
                        }

                        // Clear button
                        Rectangle {
                            width: 60; height: 26; radius: 6
                            color: clearMa.containsMouse ? bgSurface : "transparent"
                            border.color: borderDim; border.width: 1
                            Text { text: "Clear"; font.pixelSize: 11; color: textMuted; anchors.centerIn: parent }
                            MouseArea {
                                id: clearMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    drawingPad.drawingPaths = []
                                    if (targetCanvas) targetCanvas.clearPreviewPad()
                                    padCanvas.requestPaint()
                                }
                            }
                        }

                        // Eraser toggle
                        Rectangle {
                            width: 26; height: 26; radius: 6
                            color: padEraserMa.containsMouse ? bgSurface : "transparent"
                            border.color: borderDim; border.width: 1
                            Text { text: "⌫"; font.pixelSize: 12; color: textMuted; anchors.centerIn: parent }
                            MouseArea { id: padEraserMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    Rectangle { width: parent.width - 32; height: 1; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; color: borderDim }
                }

                // ═══ FUNCTIONAL DRAWING CANVAS ═══
                Rectangle {
                    id: padCanvasContainer
                    anchors.top: padHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: padSliders.top
                    anchors.margins: 12
                    radius: 12
                    color: "#0a0a0c"
                    border.color: borderDim
                    border.width: 1
                    clip: true

                    // Hint text
                    Text {
                        id: drawHintText
                        text: "Draw here to preview brush"
                        color: textDim
                        font.pixelSize: 12
                        anchors.centerIn: parent
                        opacity: drawingPad.drawingPaths.length === 0 ? 0.4 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Image {
                        id: padCanvasImage
                        anchors.fill: parent
                        anchors.margins: 2
                        source: targetCanvas ? targetCanvas.getPreviewPadImage() : ""
                        cache: false

                        Connections {
                            target: targetCanvas
                            function onPreviewPadUpdated() {
                                padCanvasImage.source = ""
                                padCanvasImage.source = targetCanvas.getPreviewPadImage()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.CrossCursor
                        
                        onPressed: function(mouse) {
                            if (targetCanvas) {
                                targetCanvas.previewPadBeginStroke(mouse.x, mouse.y, 1.0)
                                drawingPad.isDrawing = true
                            }
                        }
                        onPositionChanged: function(mouse) {
                            if (targetCanvas && drawingPad.isDrawing) {
                                targetCanvas.previewPadContinueStroke(mouse.x, mouse.y, 1.0)
                            }
                        }
                        onReleased: {
                            if (targetCanvas) {
                                targetCanvas.previewPadEndStroke()
                                drawingPad.isDrawing = false
                            }
                        }
                    }
                }

                // Bottom info bar
                Column {
                    id: padSliders
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    width: parent.width - 24

                    Rectangle { width: parent.width; height: 1; color: borderDim }

                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text { text: "Size: " + (targetCanvas ? Math.round(targetCanvas.brushSize) : 10) + "px"; color: textDim; font.pixelSize: 10 }
                        Text { text: "Opacity: " + (targetCanvas ? Math.round(targetCanvas.brushOpacity * 100) + "%" : "100%"); color: textDim; font.pixelSize: 10 }
                        Text { text: "Flow: " + (targetCanvas ? Math.round(targetCanvas.brushFlow * 100) + "%" : "100%"); color: textDim; font.pixelSize: 10 }
                    }
                }
            }
        }
    }
}
