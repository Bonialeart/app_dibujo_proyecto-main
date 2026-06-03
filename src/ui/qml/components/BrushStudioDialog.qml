import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kromo 1.0

// ============================================================================
// BrushStudioDialog.qml — Premium Brush Editor (Procreate-inspired)
// ============================================================================
// Two-column layout: Left sidebar properties | Right full test drawing pad
// Horizontal scrollable pills for categories
// Dark mode with vibrant blue accents and premium glassmorphism overlays
// ============================================================================

Rectangle {
    id: studio
    anchors.fill: parent
    color: "transparent"
    visible: false
    z: 10000

    // === PUBLIC API ===
    property var targetCanvas: null
    property color colorAccent: "#3b82f6" // Vibrant blue matching Image 2
    property string brushName: targetCanvas ? (targetCanvas.activeBrushName || "Untitled") : "Untitled"

    // Current attribute tab (0-9)
    property int activeTab: 0
    property int brushPropertySeed: 0

    signal closed()
    signal applied()

    function open() {
        activeTab = 0
        visible = true
        // Begin editing: clone the active preset for modification
        if (targetCanvas) {
            targetCanvas.beginBrushEdit(brushName)
            if (padCanvasContainer.width > 0 && padCanvasContainer.height > 0) {
                targetCanvas.resizePreviewPad(padCanvasContainer.width, padCanvasContainer.height)
            }
        }
        if (settingsLoader) {
            settingsLoader.active = false
            settingsLoader.active = true
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

    // Helper to get active tip texture path
    function getActiveTipTexturePath() {
        var dummy = studio.brushPropertySeed
        if (!targetCanvas) return ""
        var currentTip = targetCanvas.getBrushProperty("shape", "tip_texture") || ""
        var list = targetCanvas.getAvailableTipTextures()
        for (var i = 0; i < list.length; i++) {
            if (list[i].filename === currentTip || list[i].path.indexOf(currentTip) !== -1) {
                return list[i].path
            }
        }
        return ""
    }

    // Helper to get active grain texture path
    function getActiveGrainTexturePath() {
        var dummy = studio.brushPropertySeed
        if (!targetCanvas) return ""
        var currentGrain = targetCanvas.getBrushProperty("grain", "texture") || ""
        var list = targetCanvas.getAvailableTipTextures() // Grain uses tip textures list too
        for (var i = 0; i < list.length; i++) {
            if (list[i].filename === currentGrain || list[i].path.indexOf(currentGrain) !== -1) {
                return list[i].path
            }
        }
        return ""
    }

    // Helper to get active dual tip texture path
    function getActiveDualTipTexturePath() {
        var dummy = studio.brushPropertySeed
        if (!targetCanvas) return ""
        var currentTip = targetCanvas.getBrushProperty("dualbrush", "tip_texture") || ""
        var list = targetCanvas.getAvailableTipTextures()
        for (var i = 0; i < list.length; i++) {
            if (list[i].filename === currentTip || list[i].path.indexOf(currentTip) !== -1) {
                return list[i].path
            }
        }
        return ""
    }

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
                    text: "Configuración avanzada del pincel"
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
                        text: "Cancelar"
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
                        text: "Guardar Como Copia"
                        color: textMuted
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: saveCopyMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (targetCanvas) targetCanvas.saveAsCopyBrush(studio.brushName + " Copia")
                        }
                    }
                }

                // Apply Button (Accent)
                Rectangle {
                    Layout.preferredWidth: applyText.width + 40
                    Layout.preferredHeight: 34
                    radius: 8
                    color: applyMa.containsMouse ? Qt.lighter(colorAccent, 1.1) : colorAccent

                    Text {
                        id: applyText
                        text: "Aplicar"
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

        // === TABS BAR (HORIZONTAL SCROLLABLE PILLS) ===
        Rectangle {
            id: tabsBar
            width: parent.width
            height: 50
            color: bgPanel
            z: 9
            anchors.top: topBar.bottom

            // Bottom border
            Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: borderDim }

            Flickable {
                id: tabFlickable
                anchors.fill: parent
                contentWidth: tabsRow.width + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: tabsRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    spacing: 8

                    Repeater {
                        model: ListModel {
                            id: tabsModel
                            ListElement { icon: "trayectoria.svg"; label: "Trayectoria";       idx: 0 }
                            ListElement { icon: "forma.svg";       label: "Forma";            idx: 1 }
                            ListElement { icon: "forma.svg";       label: "Pincel Dual";      idx: 10 }
                            ListElement { icon: "aleatorizar.svg"; label: "Aleatorizar";      idx: 2 }
                            ListElement { icon: "textura.svg";     label: "Textura";          idx: 3 }
                            ListElement { icon: "visibilidad.svg"; label: "Visibilidad";      idx: 4 }
                            ListElement { icon: "mezcla-agua.svg"; label: "Mezcla de Agua";    idx: 5 }
                            ListElement { icon: "sensibilidad-lapiz.svg"; label: "Sensibilidad del Lápiz"; idx: 6 }
                            ListElement { icon: "color-dinamico.svg"; label: "Color Dinámico";   idx: 7 }
                            ListElement { icon: "personalizar.svg"; label: "Personalizar";     idx: 8 }
                            ListElement { icon: "creacion.svg";    label: "Creación";         idx: 9 }
                        }

                        delegate: Rectangle {
                            height: 30
                            width: tabRowContent.width + 24
                            radius: 15
                            color: studio.activeTab === model.idx
                                ? colorAccent
                                : (tabMa.containsMouse ? bgSurface : "#1a1a1c")
                            border.color: studio.activeTab === model.idx ? "transparent" : borderDim
                            border.width: 1

                            Row {
                                id: tabRowContent
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    source: "image://icons/" + model.icon
                                    width: 16; height: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: studio.activeTab === model.idx ? 1.0 : 0.6
                                    smooth: true
                                    mipmap: true
                                    sourceSize: Qt.size(32, 32)
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
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: studio.activeTab = model.idx
                            }
                        }
                    }
                }
            }
        }

        // === TWO-COLUMN BODY ===
        RowLayout {
            anchors.top: tabsBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            // ─── LEFT: ATTRIBUTES & SETTINGS SIDEBAR ───
            Rectangle {
                id: attributesSidebar
                Layout.fillHeight: true
                Layout.preferredWidth: 320
                color: bgPanel

                // Right border
                Rectangle { width: 1; height: parent.height; anchors.right: parent.right; color: borderDim }

                // ═══════ Reusable Studio Components ═══════

                // Slider with label + reset + numeric display (matching Image 2's two-row layout)
                component StudioSlider : Column {
                    property string label: "Etiqueta"
                    property alias value: slider.value
                    property alias from: slider.from
                    property alias to: slider.to
                    property string suffix: "%"
                    property bool offsetColor: false
                    property real defaultValue: 0.0

                    Component.onCompleted: {
                        defaultValue = slider.value
                    }
                    
                    width: parent.width
                    spacing: 4

                    RowLayout {
                        width: parent.width

                        Text {
                            text: label
                            color: textPrimary
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            // Clickable Reset Icon
                            Text {
                                text: "↺"
                                color: resetMa.containsMouse ? colorAccent : textMuted
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    id: resetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        slider.value = defaultValue
                                        slider.moved()
                                    }
                                }
                            }
                            
                            Text {
                                text: Math.round(slider.value * 100) / 100 + suffix
                                color: textMuted
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 20
                        
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
                                width: 14; height: 14; radius: 7
                                color: "#fff"
                                border.color: borderDim; border.width: 1
                                
                                Rectangle {
                                    z: -1; anchors.fill: parent; anchors.margins: -2
                                    color: "black"; opacity: 0.15; radius: 9
                                }
                            }
                            background: Item {}
                        }
                    }
                }

                // Reusable Toggle Component
                component StudioToggle : RowLayout {
                    property string label: "Etiqueta"
                    property alias checked: toggle.checked
                    width: parent.width
                    spacing: 12

                    Text { text: label; color: textPrimary; font.pixelSize: 12; Layout.fillWidth: true }
                    
                    Switch {
                        id: toggle
                        checked: false
                        display: AbstractButton.IconOnly
                        
                        indicator: Rectangle {
                            implicitWidth: 38
                            implicitHeight: 20
                            x: toggle.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 10
                            color: toggle.checked ? colorAccent : bgSurface
                            border.color: borderDim
                            border.width: 1

                            Rectangle {
                                x: toggle.checked ? parent.width - width - 2 : 2
                                y: 2
                                width: 16; height: 16
                                radius: 8
                                color: "#ffffff"
                            }
                        }
                    }
                }

                Loader {
                    id: settingsLoader
                    anchors.fill: parent
                    sourceComponent: settingsComponent
                }

                Component {
                    id: settingsComponent

                    Flickable {
                        anchors.fill: parent
                        contentHeight: contentCol.height + 40
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

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
                            function onEditingPresetChanged() {
                                studio.brushPropertySeed++
                                previewThrottle.restart()
                            }
                            function onBrushPropertyChanged(category, key) {
                                studio.brushPropertySeed++
                                previewThrottle.restart()
                            }
                        }

                    Column {
                        id: contentCol
                        width: parent.width - 32
                        x: 16; y: 16
                        spacing: 24

                        // --- SECTION: LIVE BRUSH STROKE PREVIEW (Always at the top) ---
                        Column {
                            width: parent.width
                            spacing: 10

                            Rectangle {
                                id: brushPreviewThumb
                                width: parent.width
                                height: 96
                                radius: 10
                                color: "#0a0a0c"
                                border.color: borderLit
                                border.width: 1
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
                                    font.pixelSize: 24
                                    anchors.centerIn: parent
                                    opacity: 0.3
                                    visible: brushShapeImg.status !== Image.Ready
                                }

                                // Label superpuesto
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: 18
                                    color: Qt.rgba(0,0,0,0.55)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "vista previa en vivo"
                                        color: "#888"; font.pixelSize: 9; font.letterSpacing: 0.5
                                    }
                                }
                            }

                            // Brush name label & + button row
                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Text {
                                    id: brushNameLabel
                                    text: studio.brushName
                                    color: textPrimary
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: addMa.containsMouse ? bgSurface : "transparent"
                                    border.color: borderDim; border.width: 1

                                    Text { text: "+"; color: textMuted; font.pixelSize: 14; anchors.centerIn: parent }
                                    MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }

                        // Divider line
                        Rectangle { width: parent.width; height: 1; color: borderDim }

                        // --- TAB 0: TRAYECTORIA ---
                        Column {
                            visible: studio.activeTab === 0
                            width: parent.width
                            spacing: 20
                            
                            // Section Header
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "PROPIEDADES DE TRAYECTORIA"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Espaciado"
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
                                label: "Inicio del Trazo (Taper)"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("stroke", "taper_start") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "taper_start", value)
                            }

                            StudioSlider {
                                label: "Fin del Trazo (Taper)"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("stroke", "taper_end") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "taper_end", value)
                            }
                            
                            StudioSlider {
                                label: "Dispersión (Jitter)"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_jitter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_jitter", value)
                            }

                            StudioToggle {
                                label: "Anti-Sacudida (Anti-Concussion)"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("stroke", "anti_concussion") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("stroke", "anti_concussion", checked)
                            }
                        }
                        
                        // --- TAB 1: FORMA ---
                        Column {
                            visible: studio.activeTab === 1
                            width: parent.width
                            spacing: 20

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "COMPORTAMIENTO DE FORMA"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Large Premium Shape Tip Texture Card
                            Rectangle {
                                width: parent.width
                                height: 160
                                radius: 12
                                color: "#08080a"
                                border.color: borderDim
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.centerIn: parent
                                    width: parent.width - 24; height: parent.height - 24
                                    source: getActiveTipTexturePath()
                                    fillMode: Image.PreserveAspectFit
                                    opacity: 0.85
                                    smooth: true
                                }

                                // Reset button in bottom-left
                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: "#a01c1c1e"
                                    border.color: borderDim; border.width: 1
                                    anchors.left: parent.left; anchors.leftMargin: 10
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10

                                    Text {
                                        text: "↺"
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var textures = targetCanvas ? targetCanvas.getAvailableTipTextures() : []
                                            if (textures.length > 0) {
                                                targetCanvas.setTipTextureForBrush(studio.brushName, textures[0].path)
                                            }
                                        }
                                    }
                                }
                            }

                            // Invertir Toggle directly below card
                            StudioToggle {
                                label: "Invertir"
                                checked: (studio.brushPropertySeed, targetCanvas ? targetCanvas.getBrushProperty("shape", "invert") || false : false)
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "invert", checked)
                            }

                            // Expandable Tip Picker Grid
                            Column {
                                width: parent.width; spacing: 8

                                Rectangle {
                                    width: parent.width; height: 32; radius: 8
                                    color: changeTipMa.containsMouse ? bgSurface : "transparent"
                                    border.color: borderDim; border.width: 1

                                    Text {
                                        text: "▼ Cambiar textura de punta..."
                                        color: textMuted; font.pixelSize: 11; font.weight: Font.Medium
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: changeTipMa
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: tipSelectionGrid.visible = !tipSelectionGrid.visible
                                    }
                                }

                                Grid {
                                    id: tipSelectionGrid
                                    width: parent.width
                                    columns: 4
                                    spacing: 8
                                    visible: false

                                    Repeater {
                                        model: targetCanvas ? targetCanvas.getAvailableTipTextures() : []
                                        delegate: Rectangle {
                                            width: (parent.width - 3 * 8) / 4
                                            height: width
                                            radius: 8
                                            color: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("shape", "tip_texture") : "") ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface)
                                            border.color: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("shape", "tip_texture") : "") ? colorAccent : borderDim)
                                            border.width: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("shape", "tip_texture") : "") ? 2 : 1)

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
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StudioSlider {
                                label: "Contraste"
                                from: 0; to: 2.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "contrast") || 1.0 : 1.0
                                suffix: ""
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "contrast", value)
                            }

                            StudioSlider {
                                label: "Desenfoque"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "blur") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "blur", value)
                            }

                            StudioSlider {
                                label: "Rotación"
                                from: -180; to: 180
                                suffix: "°"
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "rotation") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "rotation", value)
                            }

                            StudioSlider {
                                label: "Redondez"
                                from: 0.01; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "roundness") || 1.0 : 1.0
                                suffix: ""
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "roundness", value)
                            }

                            StudioSlider {
                                label: "Dispersión"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "scatter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "scatter", value)
                            }

                            StudioSlider {
                                label: "Caligráfico"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("shape", "calligraphic") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "calligraphic", value)
                            }

                            StudioToggle {
                                label: "Seguir Trazo"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("shape", "follow_stroke") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "follow_stroke", checked)
                            }
                            StudioToggle {
                                label: "Voltear X"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("shape", "flip_x") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "flip_x", checked)
                            }
                            StudioToggle {
                                label: "Voltear Y"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("shape", "flip_y") || false : false
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("shape", "flip_y", checked)
                            }
                        }

                        // --- TAB 2: ALEATORIZAR ---
                         Column {
                            visible: studio.activeTab === 2
                            width: parent.width
                            spacing: 20
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "VARIACIÓN Y ALEATORIEDAD"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            StudioSlider {
                                label: "Variación de Tamaño"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_jitter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_jitter", value)
                            }
                            
                            StudioSlider {
                                label: "Variación de Opacidad"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_jitter") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_jitter", value)
                            }
                        }

                        // --- TAB 3: TEXTURA ---
                        Column {
                            visible: studio.activeTab === 3
                            width: parent.width
                            spacing: 20

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "TEXTURA DE GRANO / PAPEL"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Large Premium Grain Card
                            Rectangle {
                                width: parent.width
                                height: 160
                                radius: 12
                                color: "#08080a"
                                border.color: borderDim
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.centerIn: parent
                                    width: parent.width - 24; height: parent.height - 24
                                    source: getActiveGrainTexturePath()
                                    fillMode: Image.PreserveAspectFit
                                    opacity: 0.85
                                    smooth: true
                                    visible: getActiveGrainTexturePath() !== ""
                                }

                                Text {
                                    text: "Sin Textura"
                                    color: textDim; font.pixelSize: 13
                                    anchors.centerIn: parent
                                    visible: getActiveGrainTexturePath() === ""
                                }

                                // Reset button in bottom-left
                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: "#a01c1c1e"
                                    border.color: borderDim; border.width: 1
                                    anchors.left: parent.left; anchors.leftMargin: 10
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 10

                                    Text {
                                        text: "↺"
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (targetCanvas) targetCanvas.setBrushProperty("grain", "texture", "")
                                        }
                                    }
                                }
                            }

                            // Invert Grain Toggle directly below card
                            StudioToggle {
                                label: "Invertir Grano"
                                checked: (studio.brushPropertySeed, targetCanvas ? targetCanvas.getBrushProperty("grain", "invert") || false : false)
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "invert", checked)
                            }

                            // Expandable Grain Picker Grid
                            Column {
                                width: parent.width; spacing: 8

                                Rectangle {
                                    width: parent.width; height: 32; radius: 8
                                    color: changeGrainMa.containsMouse ? bgSurface : "transparent"
                                    border.color: borderDim; border.width: 1

                                    Text {
                                        text: "▼ Seleccionar textura de grano..."
                                        color: textMuted; font.pixelSize: 11; font.weight: Font.Medium
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        id: changeGrainMa
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: grainSelectionGrid.visible = !grainSelectionGrid.visible
                                    }
                                }

                                Grid {
                                    id: grainSelectionGrid
                                    width: parent.width
                                    columns: 4
                                    spacing: 8
                                    visible: false

                                    // "None" option
                                    Rectangle {
                                        width: (parent.width - 3 * 8) / 4
                                        height: width
                                        radius: 8
                                        color: (studio.brushPropertySeed, (targetCanvas ? targetCanvas.getBrushProperty("grain", "texture") : "") === "" ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface)
                                        border.color: (studio.brushPropertySeed, (targetCanvas ? targetCanvas.getBrushProperty("grain", "texture") : "") === "" ? colorAccent : borderDim)
                                        border.width: (studio.brushPropertySeed, (targetCanvas ? targetCanvas.getBrushProperty("grain", "texture") : "") === "" ? 2 : 1)

                                        Text {
                                            text: "Ninguno"; color: textMuted; font.pixelSize: 10
                                            anchors.centerIn: parent
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (targetCanvas) targetCanvas.setBrushProperty("grain", "texture", "")
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: targetCanvas ? targetCanvas.getAvailableTipTextures() : []
                                        delegate: Rectangle {
                                            width: (parent.width - 3 * 8) / 4
                                            height: width
                                            radius: 8
                                            color: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("grain", "texture") : "") ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface)
                                            border.color: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("grain", "texture") : "") ? colorAccent : borderDim)
                                            border.width: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("grain", "texture") : "") ? 2 : 1)

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
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StudioSlider {
                                label: "Escala"
                                from: 10; to: 500
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "scale") || 100 : 100
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "scale", value)
                            }

                            StudioSlider {
                                label: "Profundidad"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "intensity") || 0.5 : 0.5
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "intensity", value)
                            }

                            StudioSlider {
                                label: "Brillo"
                                from: -1.0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "brightness") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "brightness", value)
                            }

                            StudioSlider {
                                label: "Contraste"
                                from: 0; to: 2.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("grain", "contrast") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "contrast", value)
                            }

                            Column {
                                width: parent.width; spacing: 8
                                Text { text: "Modo de Mezcla de Grano"; color: textPrimary; font.pixelSize: 12 }
                                Row {
                                    width: parent.width; spacing: 6
                                    property string currentMode: targetCanvas ? targetCanvas.getBrushProperty("grain", "blend_mode") || "multiply" : "multiply"

                                    component GrainBlendButton : Rectangle {
                                        property string modeName: "multiply"
                                        property string displayLabel: "Multiplicar"
                                        height: 28
                                        width: (parent.parent.width - 12) / 3
                                        radius: 6
                                        color: parent.currentMode === modeName ? colorAccent : (gBlendMa.containsMouse ? bgSurface : "#1a1a1c")
                                        border.color: parent.currentMode === modeName ? "transparent" : borderDim
                                        border.width: 1

                                        Text {
                                            text: displayLabel
                                            color: parent.parent.currentMode === modeName ? "#ffffff" : textMuted
                                            font.pixelSize: 10; font.weight: Font.Medium
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: gBlendMa
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (targetCanvas) targetCanvas.setBrushProperty("grain", "blend_mode", modeName)
                                            }
                                        }
                                    }

                                    GrainBlendButton { modeName: "multiply"; displayLabel: "Multiplicar" }
                                    GrainBlendButton { modeName: "subtract"; displayLabel: "Restar" }
                                    GrainBlendButton { modeName: "threshold"; displayLabel: "Umbral Seco" }
                                }
                            }

                            StudioToggle {
                                label: "Fijo al Lienzo (Rodante)"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("grain", "rolling") || true : true
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("grain", "rolling", checked)
                            }
                        }
                        
                        // --- TAB 4: VISIBILIDAD ---
                        Column {
                            visible: studio.activeTab === 4
                            width: parent.width
                            spacing: 20
                             Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "RENDERIZADO Y VISIBILIDAD"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioSlider {
                                label: "Flujo"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_flow") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_flow", value)
                            }
                            
                            StudioToggle {
                                label: "Suavizado (Anti-Aliasing)"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("rendering", "anti_aliasing") || true : true
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("rendering", "anti_aliasing", checked)
                            }
                        }

                        // --- TAB 5: MEZCLA DE AGUA ---
                         Column {
                            visible: studio.activeTab === 5
                            width: parent.width
                            spacing: 20
                             Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "MEZCLA HÚMEDA (WET MIX)"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                             }
                            
                            StudioSlider {
                                label: "Dilución"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "dilution") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "dilution", value)
                            }
                            StudioSlider {
                                label: "Carga"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "charge") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "charge", value)
                            }
                            StudioSlider {
                                label: "Pigmento"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "pigment") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "pigment", value)
                            }
                            StudioSlider {
                                label: "Arrastre (Smudge)"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "pull") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "pull", value)
                            }
                            StudioSlider {
                                label: "Humedad"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "wetness") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "wetness", value)
                            }
                            StudioSlider {
                                label: "Desenfoque"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("wetmix", "blur") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("wetmix", "blur", value)
                            }
                        }

                        // --- TAB 6: SENSIBILIDAD DEL LÁPIZ ---
                        Column {
                            visible: studio.activeTab === 6
                            width: parent.width
                            spacing: 20

                            // SIZE CURVE
                            Column {
                                width: parent.width; spacing: 10

                                Row {
                                    spacing: 8
                                    Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "CURVA DE PRESIÓN → TAMAÑO"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
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
                                Flickable {
                                    width: parent.width; height: 28
                                    contentWidth: presetRow.width
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    Row {
                                        id: presetRow
                                        spacing: 6
                                        Repeater {
                                            model: ["Lineal", "Presión Fuerte", "Presión Suave", "Curva S", "Fijo"]
                                            delegate: Rectangle {
                                                height: 28
                                                width: 80
                                                radius: 6
                                                color: presetMa.containsMouse ? bgSurface : "#1a1a1c"
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
                            }

                            // STYLUS SLIDERS
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "DINÁMICA DE TAMAÑO"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioSlider {
                                label: "Tamaño Mínimo"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_min") || 0.1 : 0.1
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_min", value)
                            }
                            
                            StudioSlider {
                                label: "Influencia de Inclinación"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_tilt") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_tilt", value)
                            }
                            
                            StudioSlider {
                                label: "Influencia de Velocidad"
                                from: -1.0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "size_velocity") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "size_velocity", value)
                            }

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "DINÁMICA DE OPACIDAD"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioToggle {
                                label: "Habilitar Opacidad por Presión"
                                checked: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_pressure_enabled") !== false : true
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_pressure_enabled", checked)
                            }
                            
                            StudioSlider {
                                label: "Opacidad Mínima"
                                from: 0; to: 1.0
                                enabled: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_pressure_enabled") !== false : true
                                opacity: enabled ? 1.0 : 0.4
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_min") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_min", value)
                            }
                            
                            StudioSlider {
                                label: "Influencia de Inclinación"
                                from: 0; to: 1.0
                                enabled: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_pressure_enabled") !== false : true
                                opacity: enabled ? 1.0 : 0.4
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_tilt") || 0 : 0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_tilt", value)
                            }
                            
                            StudioSlider {
                                label: "Influencia de Velocidad"
                                from: -1.0; to: 1.0
                                enabled: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_pressure_enabled") !== false : true
                                opacity: enabled ? 1.0 : 0.4
                                value: targetCanvas ? targetCanvas.getBrushProperty("dynamics", "opacity_velocity") || 0 : 0
                                offsetColor: true
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dynamics", "opacity_velocity", value)
                            }
                        }

                        // --- TAB 7: COLOR DINÁMICO ---
                        Column {
                            visible: studio.activeTab === 7
                            width: parent.width
                            spacing: 20
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "VARIACIÓN DE COLOR (JITTER)"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }
                            
                            StudioSlider {
                                label: "Variación de Tono"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("color", "hue_jitter") || 0 : 0
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("color", "hue_jitter", value)
                            }
                            StudioSlider {
                                label: "Variación de Saturación"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("color", "saturation_jitter") || 0 : 0
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("color", "saturation_jitter", value)
                            }
                            StudioSlider {
                                label: "Variación de Brillo"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("color", "brightness_jitter") || 0 : 0
                                suffix: "%"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("color", "brightness_jitter", value)
                            }
                        }

                        // --- TAB 8: PERSONALIZAR ---
                        Column {
                            visible: studio.activeTab === 8
                            width: parent.width
                            spacing: 20
                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "PROPIEDADES GENERALES DEL PINCEL"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Brush Name Editor
                            Column {
                                width: parent.width; spacing: 8
                                Text { text: "Nombre del Pincel"; color: textDim; font.pixelSize: 11 }
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
                                label: "Tamaño por Defecto"
                                from: 1; to: 100
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_size") || 20 : 20
                                suffix: "px"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_size", value)
                            }
                            StudioSlider {
                                label: "Tamaño Máximo"
                                from: 1; to: 100
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "max_size") || 100 : 100
                                suffix: "px"
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "max_size", value)
                            }
                            StudioSlider {
                                label: "Opacidad por Defecto"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_opacity") || 1.0 : 1.0
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_opacity", value)
                            }
                            StudioSlider {
                                label: "Dureza por Defecto"
                                from: 0; to: 1.0
                                value: targetCanvas ? targetCanvas.getBrushProperty("customize", "default_hardness") || 0.8 : 0.8
                                onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("customize", "default_hardness", value)
                            }
                            StudioSlider {
                                label: "Flujo por Defecto"
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
                                    text: "↺ Reestablecer Valores Originales"
                                    color: textMuted; font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: resetMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (targetCanvas) {
                                            targetCanvas.resetBrushToDefault()
                                            settingsLoader.active = false
                                            settingsLoader.active = true
                                        }
                                    }
                                }
                            }
                        }

                        // --- TAB 9: CREACIÓN ---
                        Column {
                            visible: studio.activeTab === 9
                            width: parent.width
                            spacing: 16

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "IDENTIDAD DEL PINCEL"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Editable Name
                            Column {
                                width: parent.width; spacing: 6
                                Text { text: "Nombre"; color: textDim; font.pixelSize: 11 }
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
                                Text { text: "Autor"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 36; radius: 8
                                    color: bgSurface; border.color: borderDim; border.width: 1
                                    TextInput {
                                        anchors.fill: parent; anchors.margins: 10
                                        text: targetCanvas ? (targetCanvas.getBrushProperty("meta", "author") || "Kromo Studio") : "Kromo Studio"
                                        color: textPrimary; font.pixelSize: 13
                                        verticalAlignment: TextInput.AlignVCenter
                                        onEditingFinished: if(targetCanvas) targetCanvas.setBrushProperty("meta", "author", text)
                                    }
                                }
                            }

                            // Editable Category
                            Column {
                                width: parent.width; spacing: 6
                                Text { text: "Categoría"; color: textDim; font.pixelSize: 11 }
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
                                Text { text: "Notas de Creación"; color: textDim; font.pixelSize: 11 }
                                Rectangle {
                                    width: parent.width; height: 96; radius: 8; color: bgSurface
                                    border.color: borderDim; border.width: 1
                                    TextEdit {
                                        anchors.fill: parent; anchors.margins: 10
                                        wrapMode: TextEdit.Wrap
                                        color: textPrimary; font.pixelSize: 12
                                        text: ""
                                    }
                                    Text {
                                        text: "Añadir notas sobre este pincel..."
                                        color: textDim
                                        font.pixelSize: 12
                                        anchors.left: parent.left; anchors.leftMargin: 10
                                        anchors.top: parent.top; anchors.topMargin: 10
                                        opacity: 0.5
                                        visible: parent.children[0].text === ""
                                    }
                                }
                            }
                        }

                        // --- TAB 10: PINCEL DUAL ---
                        Column {
                            visible: studio.activeTab === 10
                            width: parent.width
                            spacing: 20

                            Row {
                                spacing: 8
                                Rectangle { width: 3; height: 12; radius: 1; color: colorAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "MOTOR DE PINCEL DUAL"; color: textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                            }

                            // Enable Toggle
                            StudioToggle {
                                label: "Habilitar Pincel Dual"
                                checked: (studio.brushPropertySeed, targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "enabled") || false : false)
                                onCheckedChanged: if(targetCanvas) targetCanvas.setBrushProperty("dualbrush", "enabled", checked)
                            }

                            // Only show configuration if dual tip is enabled
                            Column {
                                width: parent.width
                                spacing: 20
                                visible: (studio.brushPropertySeed, targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "enabled") || false : false)

                                // Dual Tip Texture Card
                                Rectangle {
                                    width: parent.width
                                    height: 160
                                    radius: 12
                                    color: "#08080a"
                                    border.color: borderDim
                                    border.width: 1
                                    clip: true

                                    Image {
                                        anchors.centerIn: parent
                                        width: parent.width - 24; height: parent.height - 24
                                        source: getActiveDualTipTexturePath()
                                        fillMode: Image.PreserveAspectFit
                                        opacity: 0.85
                                        smooth: true
                                        visible: getActiveDualTipTexturePath() !== ""
                                    }

                                    Text {
                                        text: "Sin Pincel Secundario"
                                        color: textDim; font.pixelSize: 13
                                        anchors.centerIn: parent
                                        visible: getActiveDualTipTexturePath() === ""
                                    }

                                    // Reset button in bottom-left
                                    Rectangle {
                                        width: 26; height: 26; radius: 13
                                        color: "#a01c1c1e"
                                        border.color: borderDim; border.width: 1
                                        anchors.left: parent.left; anchors.leftMargin: 10
                                        anchors.bottom: parent.bottom; anchors.bottomMargin: 10

                                        Text {
                                            text: "↺"
                                            color: "#ffffff"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (targetCanvas) targetCanvas.setBrushProperty("dualbrush", "tip_texture", "")
                                            }
                                        }
                                    }
                                }

                                // Selector Grid for Dual Tip Texture
                                Column {
                                    width: parent.width; spacing: 8

                                    Rectangle {
                                        width: parent.width; height: 32; radius: 8
                                        color: changeDualTipMa.containsMouse ? bgSurface : "transparent"
                                        border.color: borderDim; border.width: 1

                                        Text {
                                            text: "▼ Seleccionar punta secundaria..."
                                            color: textMuted; font.pixelSize: 11; font.weight: Font.Medium
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            id: changeDualTipMa
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: dualTipSelectionGrid.visible = !dualTipSelectionGrid.visible
                                        }
                                    }

                                    Grid {
                                        id: dualTipSelectionGrid
                                        width: parent.width
                                        columns: 4
                                        spacing: 8
                                        visible: false

                                        Repeater {
                                            model: targetCanvas ? targetCanvas.getAvailableTipTextures() : []
                                            delegate: Rectangle {
                                                width: (parent.width - 3 * 8) / 4
                                                height: width
                                                radius: 8
                                                color: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "tip_texture") : "") ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : bgSurface)
                                                border.color: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "tip_texture") : "") ? colorAccent : borderDim)
                                                border.width: (studio.brushPropertySeed, modelData.filename === (targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "tip_texture") : "") ? 2 : 1)

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
                                                        if (targetCanvas) targetCanvas.setBrushProperty("dualbrush", "tip_texture", modelData.filename)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Scale and Rotation Sliders
                                StudioSlider {
                                    label: "Escala Secundaria"
                                    from: 0.1; to: 3.0
                                    value: targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "scale") || 1.0 : 1.0
                                    suffix: "x"
                                    onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dualbrush", "scale", value)
                                }

                                StudioSlider {
                                    label: "Rotación Secundaria"
                                    from: -180; to: 180
                                    suffix: "°"
                                    value: targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "rotation") || 0 : 0
                                    onValueChanged: if(targetCanvas) targetCanvas.setBrushProperty("dualbrush", "rotation", value)
                                }

                                // Blend Mode Selector
                                Column {
                                    width: parent.width; spacing: 8
                                    Text { text: "Modo de Fusión"; color: textPrimary; font.pixelSize: 12 }
                                    Row {
                                        width: parent.width; spacing: 6
                                        property string currentMode: targetCanvas ? targetCanvas.getBrushProperty("dualbrush", "blend_mode") || "multiply" : "multiply"

                                        component BlendButton : Rectangle {
                                            property string modeName: "multiply"
                                            property string displayLabel: "Multiplicar"
                                            height: 28
                                            width: (parent.parent.width - 12) / 3
                                            radius: 6
                                            color: parent.currentMode === modeName ? colorAccent : (blendMa.containsMouse ? bgSurface : "#1a1a1c")
                                            border.color: parent.currentMode === modeName ? "transparent" : borderDim
                                            border.width: 1

                                            Text {
                                                text: displayLabel
                                                color: parent.parent.currentMode === modeName ? "#ffffff" : textMuted
                                                font.pixelSize: 10; font.weight: Font.Medium
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                id: blendMa
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (targetCanvas) targetCanvas.setBrushProperty("dualbrush", "blend_mode", modeName)
                                                }
                                            }
                                        }

                                        BlendButton { modeName: "multiply"; displayLabel: "Multiplicar" }
                                        BlendButton { modeName: "mask"; displayLabel: "Restar" }
                                        BlendButton { modeName: "add"; displayLabel: "Añadir" }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── RIGHT: DRAWING PAD / TEST AREA ───
            Rectangle {
                id: drawingPad
                Layout.fillHeight: true
                Layout.fillWidth: true
                color: bgDeep

                // State
                property bool isDrawing: false
                property real padBrushSize: 18
                property real padOpacity: 1.0

                // ── Canvas Area ──
                Rectangle {
                    id: padCanvasContainer
                    anchors.fill: parent
                    anchors.margins: 10
                    radius: 12
                    color: "#0a0a0c"
                    border.color: borderDim; border.width: 1
                    clip: true

                    onWidthChanged: {
                        if (targetCanvas && width > 0 && height > 0) {
                            targetCanvas.resizePreviewPad(width, height)
                        }
                    }
                    onHeightChanged: {
                        if (targetCanvas && width > 0 && height > 0) {
                            targetCanvas.resizePreviewPad(width, height)
                        }
                    }

                    // Hint text
                    Text {
                        text: "Dibuja aquí para probar el pincel"
                        color: "#3a3a3c"; font.pixelSize: 13
                        font.weight: Font.Medium
                        anchors.centerIn: parent
                        visible: !drawingPad.isDrawing
                    }

                    // Native C++ Preview Pad Item
                    QPreviewPadItem {
                        id: padEngineImage
                        anchors.fill: parent
                        canvasItem: targetCanvas
                    }
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

                    // ── FLOATING OVERLAYS (Color circle, Clear button, vertical capsules) ──

                    // Top-right actions: Color Circle & Clear/Eraser
                    Column {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 12
                        z: 15

                        // Quick Color Circle Button
                        Rectangle {
                            id: quickColorCircle
                            width: 32; height: 32; radius: 16
                            color: targetCanvas ? targetCanvas.brushColor : "#ffffff"
                            border.color: "#ffffff"; border.width: 2
                            layer.enabled: true
                            
                            Rectangle {
                                anchors.fill: parent; anchors.margins: -3
                                radius: 20
                                color: "transparent"; border.color: "#2a2a2c"; border.width: 1
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: colorPopup.visible = !colorPopup.visible
                            }
                        }

                        // Eraser / Clear Canvas Button
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: "#cc1c1c1e"
                            border.color: borderDim; border.width: 1

                            Text {
                                text: "🧹" // Broom/eraser symbol
                                font.pixelSize: 14
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (targetCanvas) targetCanvas.clearPreviewPad() }
                            }
                        }
                    }

                    // Curated Quick Color Popover Grid
                    Rectangle {
                        id: colorPopup
                        visible: false
                        width: 140; height: 80
                        radius: 12
                        color: "#cc1c1c1e"
                        border.color: borderDim; border.width: 1
                        anchors.top: quickColorCircle.bottom
                        anchors.topMargin: 42 // Align under the column nicely
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        z: 16

                        Grid {
                            anchors.centerIn: parent
                            columns: 4
                            spacing: 10
                            Repeater {
                                model: ["#ffffff", "#000000", "#3b82f6", "#ef4444", "#10b981", "#f59e0b", "#8b5cf6", "#ec4899"]
                                delegate: Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: modelData
                                    border.color: "#ffffff"
                                    border.width: (targetCanvas && targetCanvas.brushColor.toString().toLowerCase() === modelData.toLowerCase()) ? 2 : 0
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (targetCanvas) targetCanvas.brushColor = modelData
                                            colorPopup.visible = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Floating Vertical Capsules on Right Margin
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        z: 15

                        // Size Capsule
                        Rectangle {
                            width: 36; height: 220; radius: 18
                            color: "#cc1c1c1e"
                            border.color: borderDim; border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.topMargin: 12; anchors.bottomMargin: 12
                                spacing: 8

                                Text {
                                    text: "Tamaño"
                                    color: textMuted; font.pixelSize: 8; font.weight: Font.Bold
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Slider {
                                    id: verticalSizeSlider
                                    width: 20; height: 150
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    orientation: Qt.Vertical
                                    from: 2; to: 100
                                    value: drawingPad.padBrushSize
                                    onMoved: {
                                        drawingPad.padBrushSize = value
                                        if (targetCanvas) targetCanvas.brushSize = value
                                    }
                                    background: Item {
                                        implicitWidth: 20
                                        implicitHeight: 150
                                        Rectangle {
                                            id: sizeTrack
                                            width: 8; height: parent.height
                                            radius: 4
                                            color: "#151518"
                                            border.color: Qt.rgba(1, 1, 1, 0.05)
                                            border.width: 1
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            clip: true
                                            Rectangle {
                                                width: parent.width
                                                height: (1.0 - verticalSizeSlider.visualPosition) * parent.height
                                                anchors.bottom: parent.bottom
                                                radius: 4
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Qt.lighter(colorAccent, 1.2) }
                                                    GradientStop { position: 1.0; color: colorAccent }
                                                }
                                            }
                                        }
                                    }
                                    handle: Rectangle {
                                        id: sizeHandle
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: verticalSizeSlider.topPadding + verticalSizeSlider.visualPosition * (verticalSizeSlider.availableHeight - height)
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: "#ffffff"
                                        border.color: Qt.rgba(0, 0, 0, 0.15)
                                        border.width: 1
                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: verticalSizeSlider.pressed ? colorAccent : "#e2e8f0"
                                            anchors.centerIn: parent
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width + 10; height: parent.height + 10
                                            radius: width/2
                                            color: colorAccent
                                            opacity: verticalSizeSlider.pressed ? 0.25 : (verticalSizeSlider.hovered ? 0.12 : 0.0)
                                            z: -1
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        scale: verticalSizeSlider.pressed ? 1.2 : (verticalSizeSlider.hovered ? 1.08 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    text: Math.round(verticalSizeSlider.value)
                                    color: textMuted; font.pixelSize: 8; font.weight: Font.Medium
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Opacity Capsule
                        Rectangle {
                            width: 36; height: 220; radius: 18
                            color: "#cc1c1c1e"
                            border.color: borderDim; border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.topMargin: 12; anchors.bottomMargin: 12
                                spacing: 8

                                Text {
                                    text: "Opac."
                                    color: textMuted; font.pixelSize: 8; font.weight: Font.Bold
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Slider {
                                    id: verticalOpSlider
                                    width: 20; height: 150
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    orientation: Qt.Vertical
                                    from: 0.05; to: 1.0
                                    value: drawingPad.padOpacity
                                    onMoved: {
                                        drawingPad.padOpacity = value
                                        if (targetCanvas) targetCanvas.brushOpacity = value
                                    }
                                    background: Item {
                                        implicitWidth: 20
                                        implicitHeight: 150
                                        Rectangle {
                                            id: opTrack
                                            width: 8; height: parent.height
                                            radius: 4
                                            color: "#151518"
                                            border.color: Qt.rgba(1, 1, 1, 0.05)
                                            border.width: 1
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            clip: true
                                            Rectangle {
                                                width: parent.width
                                                height: (1.0 - verticalOpSlider.visualPosition) * parent.height
                                                anchors.bottom: parent.bottom
                                                radius: 4
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Qt.lighter(colorAccent, 1.2) }
                                                    GradientStop { position: 1.0; color: colorAccent }
                                                }
                                            }
                                        }
                                    }
                                    handle: Rectangle {
                                        id: opHandle
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: verticalOpSlider.topPadding + verticalOpSlider.visualPosition * (verticalOpSlider.availableHeight - height)
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: "#ffffff"
                                        border.color: Qt.rgba(0, 0, 0, 0.15)
                                        border.width: 1
                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: verticalOpSlider.pressed ? colorAccent : "#e2e8f0"
                                            anchors.centerIn: parent
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width + 10; height: parent.height + 10
                                            radius: width/2
                                            color: colorAccent
                                            opacity: verticalOpSlider.pressed ? 0.25 : (verticalOpSlider.hovered ? 0.12 : 0.0)
                                            z: -1
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        scale: verticalOpSlider.pressed ? 1.2 : (verticalOpSlider.hovered ? 1.08 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    text: Math.round(verticalOpSlider.value * 100) + "%"
                                    color: textMuted; font.pixelSize: 8; font.weight: Font.Medium
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
