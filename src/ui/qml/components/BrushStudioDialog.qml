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
                    text: "Advance Brush Config"
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

                // Preview sin parpadeo: usa un Timer + crossfade entre dos imágenes
                property string nextPreviewSrc: ""

                Timer {
                    id: previewThrottle
                    interval: 120
                    repeat: false
                    onTriggered: {
                        if (targetCanvas) {
                            var newSrc = targetCanvas.get_brush_preview(studio.brushName)
                            brushShapeImg2.source = newSrc
                            brushShapeImg2.opacity = 1
                            brushShapeImg.opacity = 0
                            swapTimer.start()
                        }
                    }
                }
                Timer {
                    id: swapTimer
                    interval: 180
                    repeat: false
                    onTriggered: {
                        brushShapeImg.source  = brushShapeImg2.source
                        brushShapeImg.opacity = 1
                        brushShapeImg2.opacity = 0
                    }
                }

                Connections {
                    target: targetCanvas
                    function onEditingPresetChanged() { previewThrottle.restart() }
                    function onBrushPropertyChanged(category, key) { previewThrottle.restart() }
                }
                Rectangle {
                    id: brushPreviewThumb
                    width: parent.width - 32
                    height: 110
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: "#0a0a0a"
                    border.color: colorAccent
                    border.width: 1.5
                    clip: true

                    // Trazo real del pincel — imagen base
                    Image {
                        id: brushShapeImg
                        anchors.fill: parent
                        source: (targetCanvas && studio.brushName) ? targetCanvas.get_brush_preview(studio.brushName) : ""
                        fillMode: Image.Stretch
                        cache: false; smooth: true
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Segunda capa para crossfade suave
                    Image {
                        id: brushShapeImg2
                        anchors.fill: parent
                        source: ""
                        fillMode: Image.Stretch
                        cache: false; smooth: true
                        opacity: 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Fallback
                    Text {
                        text: "\uD83D\uDD8C"
                        font.pixelSize: 28
                        anchors.centerIn: parent
                        opacity: 0.3
                        visible: brushShapeImg.status !== Image.Ready
                    }

                    // Label superpuesto
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 20
                        color: Qt.rgba(0,0,0,0.55)
                        Text {
                            anchors.centerIn: parent
                            text: "live preview"
                            color: "#888"; font.pixelSize: 9; font.letterSpacing: 0.5
                        }
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

                            // TIP TEXTURE PICKER
                            Column {
                                width: parent.width; spacing: 10
                                Text { text: "Brush Tip Texture"; color: textDim; font.pixelSize: 11 }

                                property var tipTextures: targetCanvas ? targetCanvas.getAvailableTipTextures() : []
                                property string currentTip: targetCanvas ? (targetCanvas.getBrushProperty("shape", "tip_texture") || "") : ""

                                Grid {
                                    width: parent.width
                                    columns: 4
                                    spacing: 8

                                    Repeater {
                                        model: parent.parent.tipTextures
                                        delegate: Rectangle {
                                            width: (parent.width - 3 * 8) / 4
                                            height: width
                                            radius: 8
                                            color: modelData.filename === parent.parent.parent.currentTip ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface
                                            border.color: modelData.filename === parent.parent.parent.currentTip ? colorAccent : borderDim
                                            border.width: modelData.filename === parent.parent.parent.currentTip ? 2 : 1

                                            Image {
                                                anchors.centerIn: parent
                                                width: parent.width - 12; height: parent.height - 12
                                                source: modelData.path
                                                fillMode: Image.PreserveAspectFit
                                                opacity: 0.85
                                            }

                                            Text {
                                                text: modelData.name
                                                color: textDim; font.pixelSize: 8
                                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottomMargin: 3
                                                elide: Text.ElideRight; width: parent.width - 4
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (targetCanvas) targetCanvas.setTipTextureForBrush(studio.brushName, modelData.path)
                                                    parent.parent.parent.currentTip = modelData.filename
                                                }
                                            }
                                        }
                                    }
                                }

                                // No textures message
                                Text {
                                    visible: parent.tipTextures.length === 0
                                    text: "No tip textures found in assets/brushes/"
                                    color: textDim; font.pixelSize: 11
                                    width: parent.width; wrapMode: Text.WordWrap
                                }
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
                                label: "Calligraphic"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "calligraphic") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "calligraphic", value)
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
                                Text { text: "GRAIN / PAPER TEXTURE"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // GRAIN TEXTURE PICKER
                            Column {
                                width: parent.width; spacing: 10
                                Text { text: "Grain Texture"; color: textDim; font.pixelSize: 11 }

                                property var grainTextures: targetCanvas ? targetCanvas.getAvailableTipTextures() : []
                                property string currentGrain: targetCanvas ? (targetCanvas.getBrushProperty("grain", "texture") || "") : ""

                                Grid {
                                    width: parent.width
                                    columns: 4
                                    spacing: 8

                                    // "None" option
                                    Rectangle {
                                        width: (parent.width - 3 * 8) / 4
                                        height: width
                                        radius: 8
                                        color: parent.parent.currentGrain === "" ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface
                                        border.color: parent.parent.currentGrain === "" ? colorAccent : borderDim
                                        border.width: parent.parent.currentGrain === "" ? 2 : 1
                                        Text {
                                            text: "None"; color: textMuted; font.pixelSize: 11
                                            anchors.centerIn: parent
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (targetCanvas) targetCanvas.setBrushProperty("grain", "texture", "")
                                                parent.parent.currentGrain = ""
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: parent.parent.grainTextures
                                        delegate: Rectangle {
                                            width: (parent.width - 3 * 8) / 4
                                            height: width
                                            radius: 8
                                            color: modelData.filename === parent.parent.parent.currentGrain ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface
                                            border.color: modelData.filename === parent.parent.parent.currentGrain ? colorAccent : borderDim
                                            border.width: modelData.filename === parent.parent.parent.currentGrain ? 2 : 1

                                            Image {
                                                anchors.centerIn: parent
                                                width: parent.width - 12; height: parent.height - 12
                                                source: modelData.path
                                                fillMode: Image.PreserveAspectFit
                                                opacity: 0.85
                                            }
                                            Text {
                                                text: modelData.name; color: textDim; font.pixelSize: 8
                                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottomMargin: 3; elide: Text.ElideRight
                                                width: parent.width - 4; horizontalAlignment: Text.AlignHCenter
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (targetCanvas) targetCanvas.setGrainTextureForBrush(studio.brushName, modelData.path)
                                                    parent.parent.parent.currentGrain = modelData.filename
                                                }
                                            }
                                        }
                                    }
                                }
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

                            StudioToggle {
                                label: "Invert Grain"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("grain", "invert") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "invert", checked)
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

                            // SIZE CURVE
                            Column {
                                width: parent.width; spacing: 10

                                Row {
                                    spacing: 8
                                    Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "SIZE → PRESSURE CURVE"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                                }

                                // Pressure curve canvas
                                Rectangle {
                                    width: parent.width; height: 160
                                    color: bgSurface; radius: 10
                                    border.color: borderDim; border.width: 1

                                    Canvas {
                                        id: sizeCurveCanvas
                                        anchors.fill: parent; anchors.margins: 12

                                        property var pts: [[0.0,0.0],[0.33,0.33],[0.66,0.66],[1.0,1.0]]
                                        property int dragging: -1

                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)

                                            // Grid
                                            ctx.strokeStyle = "#2a2a2c"
                                            ctx.lineWidth = 1
                                            for (var i = 0; i <= 4; i++) {
                                                ctx.beginPath()
                                                ctx.moveTo(i * width / 4, 0)
                                                ctx.lineTo(i * width / 4, height)
                                                ctx.stroke()
                                                ctx.beginPath()
                                                ctx.moveTo(0, i * height / 4)
                                                ctx.lineTo(width, i * height / 4)
                                                ctx.stroke()
                                            }

                                            // Diagonal guide
                                            ctx.strokeStyle = "#333340"
                                            ctx.setLineDash([4,4])
                                            ctx.beginPath()
                                            ctx.moveTo(0, height); ctx.lineTo(width, 0)
                                            ctx.stroke()
                                            ctx.setLineDash([])

                                            // Curve
                                            ctx.strokeStyle = colorAccent
                                            ctx.lineWidth = 2.5
                                            ctx.beginPath()
                                            for (var t = 0; t <= 1; t += 0.01) {
                                                // Cubic bezier using the 4 control points
                                                var mt = 1 - t
                                                var bx = mt*mt*mt*pts[0][0] + 3*mt*mt*t*pts[1][0] + 3*mt*t*t*pts[2][0] + t*t*t*pts[3][0]
                                                var by = mt*mt*mt*pts[0][1] + 3*mt*mt*t*pts[1][1] + 3*mt*t*t*pts[2][1] + t*t*t*pts[3][1]
                                                var cx2 = bx * width
                                                var cy2 = (1 - by) * height
                                                if (t === 0) ctx.moveTo(cx2, cy2); else ctx.lineTo(cx2, cy2)
                                            }
                                            ctx.stroke()

                                            // Control points
                                            for (var k = 0; k < pts.length; k++) {
                                                ctx.beginPath()
                                                ctx.arc(pts[k][0]*width, (1-pts[k][1])*height, 7, 0, Math.PI*2)
                                                ctx.fillStyle = k === dragging ? colorAccent : "#ffffff"
                                                ctx.strokeStyle = colorAccent
                                                ctx.lineWidth = 2
                                                ctx.fill(); ctx.stroke()
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onPressed: {
                                                // Find nearest point
                                                var best = -1, bestD = 1e9
                                                for (var k = 0; k < sizeCurveCanvas.pts.length; k++) {
                                                    var px = sizeCurveCanvas.pts[k][0]*sizeCurveCanvas.width
                                                    var py = (1-sizeCurveCanvas.pts[k][1])*sizeCurveCanvas.height
                                                    var d = Math.sqrt((mouseX-px)*(mouseX-px)+(mouseY-py)*(mouseY-py))
                                                    if (d < bestD) { bestD = d; best = k }
                                                }
                                                if (bestD < 20) sizeCurveCanvas.dragging = best
                                            }
                                            onReleased: { sizeCurveCanvas.dragging = -1; sizeCurveCanvas.requestPaint() }
                                            onPositionChanged: {
                                                if (sizeCurveCanvas.dragging >= 0) {
                                                    var nx = Math.max(0, Math.min(1, mouseX / sizeCurveCanvas.width))
                                                    var ny = Math.max(0, Math.min(1, 1 - mouseY / sizeCurveCanvas.height))
                                                    sizeCurveCanvas.pts[sizeCurveCanvas.dragging] = [nx, ny]
                                                    sizeCurveCanvas.requestPaint()
                                                    // Apply to canvas: map to pressure curve (using P1 and P2 bezier)
                                                    if (targetCanvas && sizeCurveCanvas.pts.length >= 4) {
                                                        targetCanvas.setCurvePoints([sizeCurveCanvas.pts[1][0], sizeCurveCanvas.pts[1][1], sizeCurveCanvas.pts[2][0], sizeCurveCanvas.pts[2][1]])
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Curve presets
                                Row {
                                    width: parent.width; spacing: 6
                                    Repeater {
                                        model: ["Linear", "Heavy→Light", "Light→Heavy", "S-Curve", "Fixed"]
                                        delegate: Rectangle {
                                            height: 28
                                            width: (parent.width - 4 * 6) / 5
                                            radius: 6
                                            color: presetMa.containsMouse ? bgSurface : "transparent"
                                            border.color: borderDim; border.width: 1
                                            Text {
                                                text: modelData; color: textMuted; font.pixelSize: 9
                                                anchors.centerIn: parent; wrapMode: Text.WordWrap
                                                horizontalAlignment: Text.AlignHCenter
                                                width: parent.width - 4
                                            }
                                            MouseArea {
                                                id: presetMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var presets = [
                                                        [[0,0],[0.33,0.33],[0.66,0.66],[1,1]],        // Linear
                                                        [[0,0],[0.1,0.6],[0.7,0.95],[1,1]],           // Heavy→Light
                                                        [[0,0],[0.3,0.05],[0.9,0.4],[1,1]],           // Light→Heavy
                                                        [[0,0],[0.15,0.6],[0.85,0.4],[1,1]],          // S-Curve
                                                        [[0,1],[0.33,1],[0.66,1],[1,1]]               // Fixed
                                                    ]
                                                    sizeCurveCanvas.pts = presets[index]
                                                    sizeCurveCanvas.requestPaint()
                                                    if (targetCanvas && sizeCurveCanvas.pts.length >= 4) {
                                                        targetCanvas.setCurvePoints([sizeCurveCanvas.pts[1][0], sizeCurveCanvas.pts[1][1], sizeCurveCanvas.pts[2][0], sizeCurveCanvas.pts[2][1]])
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // STYLUS SLIDERS
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "SIZE DYNAMICS"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            StudioSlider {
                                label: "Size Min"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_min") || 0.1 : 0.1
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_min", value)
                            }
                            StudioSlider {
                                label: "Tilt Influence"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_tilt") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_tilt", value)
                            }
                            StudioSlider {
                                label: "Velocity Influence"
                                from: -1.0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_velocity") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_velocity", value)
                            }

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "OPACITY DYNAMICS"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            StudioSlider {
                                label: "Opacity Min"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_min") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_min", value)
                            }
                            StudioSlider {
                                label: "Tilt Influence"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_tilt") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_tilt", value)
                            }
                            StudioSlider {
                                label: "Velocity Influence"
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

                        // --- TAB 9: CREATION / ABOUT ---
                        Column {
                            visible: studio.activeTab === 9
                            width: parent.width
                            spacing: 20

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "BRUSH IDENTITY"; color: textMuted; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Editable Name
                            Column {
                                width: parent.width; spacing: 6
                                Text { text: "Name"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 36; radius: 8
                                    color: bgSurface; border.color: borderDim; border.width: 1
                                    TextInput {
                                        anchors.fill: parent; anchors.margins: 10
                                        text: targetCanvas ? (targetCanvas.getBrushProperty("meta", "name") || studio.brushName) : studio.brushName
                                        color: textPrimary; font.pixelSize: 13
                                        verticalAlignment: TextInput.AlignVCenter
                                        onEditingFinished: if(targetCanvas) targetCanvas.setBrushProperty("meta", "name", text)
                                    }
                                }
                            }

                            // Editable Author
                            Column {
                                width: parent.width; spacing: 6
                                Text { text: "Author"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 36; radius: 8
                                    color: bgSurface; border.color: borderDim; border.width: 1
                                    TextInput {
                                        anchors.fill: parent; anchors.margins: 10
                                        text: targetCanvas ? (targetCanvas.getBrushProperty("meta", "author") || "ArtFlow Studio") : "ArtFlow Studio"
                                        color: textPrimary; font.pixelSize: 13
                                        verticalAlignment: TextInput.AlignVCenter
                                        onEditingFinished: if(targetCanvas) targetCanvas.setBrushProperty("meta", "author", text)
                                    }
                                }
                            }

                            // Editable Category
                            Column {
                                width: parent.width; spacing: 6
                                Text { text: "Category"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 36; radius: 8
                                    color: bgSurface; border.color: borderDim; border.width: 1
                                    TextInput {
                                        anchors.fill: parent; anchors.margins: 10
                                        text: targetCanvas ? (targetCanvas.getBrushProperty("meta", "category") || "Custom") : "Custom"
                                        color: textPrimary; font.pixelSize: 13
                                        verticalAlignment: TextInput.AlignVCenter
                                        onEditingFinished: if(targetCanvas) targetCanvas.setBrushProperty("meta", "category", text)
                                    }
                                }
                            }

                            // Notes area
                            Column {
                                width: parent.width; spacing: 6
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
                property bool isDrawing: false
                property real padBrushSize: 18
                property real padOpacity: 1.0

                // ── Header ──
                Rectangle {
                    id: padHeader
                    width: parent.width; height: 48
                    color: "transparent"

                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text { text: "✎"; font.pixelSize: 14; color: textMuted }
                        Text { text: "Drawing Pad"; color: textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                    }

                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 52; height: 26; radius: 6
                            color: clearPadMa.containsMouse ? bgSurface : "transparent"
                            border.color: borderDim; border.width: 1
                            Text { text: "Clear"; font.pixelSize: 11; color: textMuted; anchors.centerIn: parent }
                            MouseArea {
                                id: clearPadMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (targetCanvas) targetCanvas.clearPreviewPad() }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: borderDim }
                }

                // ── Canvas Area ──
                Rectangle {
                    id: padCanvasContainer
                    anchors.top: padHeader.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.bottom: padInfoBar.top
                    anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.topMargin: 10
                    radius: 10
                    color: "#0a0a0c"
                    border.color: borderDim; border.width: 1
                    clip: true

                    // Hint text
                    Text {
                        text: "Draw here to test brush"
                        color: "#3a3a3c"; font.pixelSize: 13
                        anchors.centerIn: parent
                        visible: !drawingPad.isDrawing
                    }

                    // Image from the C++ Brush Engine
                    Image {
                        id: padEngineImage
                        anchors.fill: parent
                        source: targetCanvas ? targetCanvas.getPreviewPadImage() : ""
                        cache: false
                        asynchronous: false
                        fillMode: Image.PreserveAspectFit
                        smooth: true

                        Connections {
                            target: targetCanvas
                            function onPreviewPadUpdated() {
                                padEngineImage.source = ""
                                padEngineImage.source = targetCanvas.getPreviewPadImage()
                            }
                        }
                    }

                    // Cursor circle — shows brush size
                    Rectangle {
                        id: padCursor
                        width: Math.max(4, drawingPad.padBrushSize)
                        height: width; radius: width * 0.5
                        color: "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.7)
                        border.width: 1.5
                        visible: padInputArea.containsMouse
                        x: padInputArea.mouseX - width * 0.5
                        y: padInputArea.mouseY - height * 0.5
                        antialiasing: true
                        z: 10
                    }

                    // ── Mouse Input ──
                    MouseArea {
                        id: padInputArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.BlankCursor

                        property real prevX: 0
                        property real prevY: 0
                        property real smoothedDist: 0
                        property real currentPressure: 0.6
                        property real targetPressure: 0.6

                        onPressed: function(mouse) {
                            // Sync size/opacity from current brush settings
                            drawingPad.padBrushSize = targetCanvas ? targetCanvas.brushSize : 18
                            drawingPad.padOpacity   = targetCanvas ? targetCanvas.brushOpacity : 1.0
                            prevX = mouse.x
                            prevY = mouse.y
                            currentPressure = 0.6
                            targetPressure  = 0.6
                            smoothedDist    = 0
                            drawingPad.isDrawing = true
                            if (targetCanvas)
                                targetCanvas.previewPadBeginStroke(mouse.x, mouse.y, 0.6)
                        }

                        onPositionChanged: function(mouse) {
                            if (!drawingPad.isDrawing) return

                            var dx   = mouse.x - prevX
                            var dy   = mouse.y - prevY
                            var dist = Math.sqrt(dx*dx + dy*dy)

                            // Exponential moving average on distance per event
                            smoothedDist = smoothedDist * 0.85 + dist * 0.15

                            // Map 0–30px/event → pressure 1.0–0.15
                            var speed = Math.min(1.0, smoothedDist / 30.0)
                            targetPressure = Math.max(0.15, 1.0 - speed * 0.85)

                            // Ease pressure to avoid sudden spikes
                            currentPressure = currentPressure + (targetPressure - currentPressure) * 0.12

                            if (targetCanvas)
                                targetCanvas.previewPadContinueStroke(mouse.x, mouse.y, currentPressure)

                            prevX = mouse.x
                            prevY = mouse.y
                        }

                        onReleased: {
                            if (targetCanvas) targetCanvas.previewPadEndStroke()
                            drawingPad.isDrawing = false
                        }
                    }
                }

                // ── Bottom Info Bar ──
                Rectangle {
                    id: padInfoBar
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 46
                    color: "transparent"

                    Rectangle { width: parent.width; height: 1; color: borderDim }

                    Row {
                        anchors.centerIn: parent
                        spacing: 20

                        // Size slider
                        Row {
                            spacing: 8; anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Size"; color: textDim; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Slider {
                                id: padSizeSlider
                                width: 90; height: 20
                                from: 2; to: 200
                                value: drawingPad.padBrushSize
                                onMoved: {
                                    drawingPad.padBrushSize = value
                                    if (targetCanvas) targetCanvas.brushSize = value
                                }
                                handle: Rectangle {
                                    x: padSizeSlider.leftPadding + padSizeSlider.visualPosition*(padSizeSlider.availableWidth - width)
                                    y: padSizeSlider.topPadding + padSizeSlider.availableHeight/2 - height/2
                                    width: 14; height: 14; radius: 7; color: "#ffffff"
                                    layer.enabled: true
                                    layer.effect: null
                                }
                                background: Rectangle {
                                    x: padSizeSlider.leftPadding
                                    y: padSizeSlider.topPadding + padSizeSlider.availableHeight/2 - height/2
                                    width: padSizeSlider.availableWidth; height: 3; radius: 2; color: bgSurface
                                    Rectangle { width: padSizeSlider.visualPosition * parent.width; height: parent.height; color: colorAccent; radius: 2 }
                                }
                            }
                            Text { text: Math.round(padSizeSlider.value)+"px"; color: textDim; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        }

                        // Opacity slider
                        Row {
                            spacing: 8; anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Opacity"; color: textDim; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Slider {
                                id: padOpSlider
                                width: 70; height: 20
                                from: 0.05; to: 1.0
                                value: drawingPad.padOpacity
                                onMoved: {
                                    drawingPad.padOpacity = value
                                    if (targetCanvas) targetCanvas.brushOpacity = value
                                }
                                handle: Rectangle {
                                    x: padOpSlider.leftPadding + padOpSlider.visualPosition*(padOpSlider.availableWidth - width)
                                    y: padOpSlider.topPadding + padOpSlider.availableHeight/2 - height/2
                                    width: 14; height: 14; radius: 7; color: "#ffffff"
                                    layer.enabled: true
                                    layer.effect: null
                                }
                                background: Rectangle {
                                    x: padOpSlider.leftPadding
                                    y: padOpSlider.topPadding + padOpSlider.availableHeight/2 - height/2
                                    width: padOpSlider.availableWidth; height: 3; radius: 2; color: bgSurface
                                    Rectangle { width: padOpSlider.visualPosition * parent.width; height: parent.height; color: colorAccent; radius: 2 }
                                }
                            }
                            Text { text: Math.round(padOpSlider.value*100)+"%"; color: textDim; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }
    }
}
