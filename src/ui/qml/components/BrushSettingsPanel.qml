import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property var targetCanvas: null
    property var mainCanvas: targetCanvas
    property int activeToolIdx: -1 // Added to prevent crash from main_pro binding
    
    property color colorAccent: "#6366f1"
    readonly property color _colorBg: (typeof colorBg !== "undefined") ? colorBg : "#2e2e2e"
    readonly property color _colorPanel: (typeof colorPanel !== "undefined") ? colorPanel : "#484848"
    readonly property color _colorAccent: colorAccent
    readonly property color _colorText: (typeof colorText !== "undefined") ? colorText : "#ffffff"
    readonly property color _colorTextMuted: (typeof colorTextMuted !== "undefined") ? colorTextMuted : "#aaaaaa"
    readonly property color _colorBorder: (typeof colorBorder !== "undefined") ? colorBorder : "#202025"
    readonly property color _colorCard: (typeof colorCard !== "undefined") ? colorCard : "#383838"

    readonly property string currentTool: mainCanvas ? mainCanvas.currentTool : "brush"

    // Helper functions/properties to check current tool category
    readonly property bool isBrushTool: {
        var t = currentTool.toLowerCase();
        return ["brush", "pen", "pencil", "airbrush", "eraser", "watercolor", "ink", "g-pen", "maru", "hb", "6b", "mech", "water", "oil", "acry", "soft", "hard", "e_soft", "e_hard"].indexOf(t) !== -1;
    }

    readonly property bool isGradientTool: {
        var t = currentTool.toLowerCase();
        return t === "grad" || t === "gradient";
    }

    readonly property bool isSelectionTool: {
        var t = currentTool.toLowerCase();
        return ["selection", "select_rect", "select_ellipse", "select_wand", "lasso", "magnetic_lasso"].indexOf(t) !== -1;
    }

    readonly property bool isFillTool: {
        var t = currentTool.toLowerCase();
        return t === "fill" || t === "bucket";
    }

    readonly property bool isTransformTool: {
        var t = currentTool.toLowerCase();
        return t === "move" || t === "transform";
    }

    readonly property bool isShapeTool: {
        var t = currentTool.toLowerCase();
        var isTool = ["shape", "rect", "ellipse", "line", "panel", "bubble", "shapes"].indexOf(t) !== -1 || t.startsWith("panel_") || t.startsWith("bubble_");
        var hasBubble = (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.selectedBubbleId >= 0);
        return isTool || hasBubble;
    }

    property int activeShapeCategory: 0 // 0: Figuras, 1: Viñetas, 2: Globos
    
    readonly property var activeBubble: (typeof comicOverlay !== "undefined" && comicOverlay) ? comicOverlay.selectedBubbleDelegate : null

    function getPanels(id, mx, my, iw, ih, g) {
        var t = id.replace("panel_", "")
        if (t === "single") return [{x:mx,y:my,w:iw,h:ih}]
        if (t === "2col") {
            var cw=(iw-g)/2
            return [{x:mx,y:my,w:cw,h:ih},{x:mx+cw+g,y:my,w:cw,h:ih}]
        }
        if (t === "2row") {
            var rh=(ih-g)/2
            return [{x:mx,y:my,w:iw,h:rh},{x:mx,y:my+rh+g,w:iw,h:rh}]
        }
        if (t === "grid") {
            var th=(ih-g)*0.45,bh=ih-th-g,c3=(iw-2*g)/3,c2=(iw-g)/2
            return [{x:mx,y:my,w:c3,h:th},{x:mx+c3+g,y:my,w:c3,h:th},{x:mx+2*(c3+g),y:my,w:c3,h:th},
                    {x:mx,y:my+th+g,w:c2,h:bh},{x:mx+c2+g,y:my+th+g,w:c2,h:bh}]
        }
        if (t === "manga") {
            var th2=ih*0.3,bh2=ih-th2-g,lw=iw*0.5,rw=iw-lw-g,rh1=(bh2-g)*0.55,rh2=bh2-rh1-g
            return [{x:mx,y:my,w:iw,h:th2},{x:mx,y:my+th2+g,w:lw,h:bh2},
                    {x:mx+lw+g,y:my+th2+g,w:rw,h:rh1},{x:mx+lw+g,y:my+th2+g+rh1+g,w:rw,h:rh2}]
        }
        if (t === "4panel") {
            var c1w=iw*0.45,c2w=iw-c1w-g,r1t=ih*0.35,r1b=ih-r1t-g,r2t=ih*0.55,r2b=ih-r2t-g
            return [{x:mx,y:my,w:c1w,h:r1t},{x:mx+c1w+g,y:my,w:c2w,h:r2t},
                    {x:mx,y:my+r1t+g,w:c1w,h:r1b},{x:mx+c1w+g,y:my+r2t+g,w:c2w,h:r2b}]
        }
        if (t === "strip") {
            var s1=ih*0.38,s2=ih*0.35,s3=ih-s1-s2-2*g
            return [{x:mx,y:my,w:iw,h:s1},{x:mx,y:my+s1+g,w:iw,h:s2},{x:mx,y:my+s1+s2+2*g,w:iw,h:s3}]
        }
        return [{x:mx,y:my,w:iw,h:ih}]
    }

    function updateBubbleProperty(name, val) {
        if (activeBubble) {
            var propName = name;
            if (name === "type") propName = "bubbleType";
            activeBubble[propName] = val;
        }
    }

    onCurrentToolChanged: {
        var t = currentTool.toLowerCase();
        if (t.startsWith("panel_") || t === "panel_cut") {
            activeShapeCategory = 1;
        } else if (t.startsWith("bubble_") || (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.selectedBubbleId >= 0)) {
            activeShapeCategory = 2;
        } else if (t === "rect" || t === "ellipse" || t === "line" || t === "shape" || t === "shapes") {
            activeShapeCategory = 0;
        }
    }

    Connections {
        target: typeof comicOverlay !== "undefined" ? comicOverlay : null
        ignoreUnknownSignals: true
        function onSelectedBubbleIdChanged() {
            if (comicOverlay && comicOverlay.selectedBubbleId >= 0) {
                activeShapeCategory = 2;
            }
        }
    }


    // Gradient State Helper Properties (Replicating GradientSettingsPanel internal state)
    property int selectedStopIdx: 0
    property string activePresetId: "sunset"
    property var customPresets: []

    Connections {
        target: mainCanvas
        ignoreUnknownSignals: true
        function onActiveLayerChanged() {
            if (mainCanvas && mainCanvas.activeLayerIndex !== undefined) {
                root.activePresetId = mainCanvas.getLayerGradientMapPreset(mainCanvas.activeLayerIndex)
            }
        }
    }

    function getSelectedColor() {
        if (!mainCanvas || root.selectedStopIdx >= mainCanvas.gradientStops.length) return "#ffffff"
        return mainCanvas.gradientStops[root.selectedStopIdx].color
    }
    
    function getH() {
        var c = Qt.color(getSelectedColor())
        return c.hsvHue >= 0 ? c.hsvHue * 360 : 0
    }
    
    function getS() {
        var c = Qt.color(getSelectedColor())
        return c.hsvSaturation * 100
    }
    
    function getV() {
        var c = Qt.color(getSelectedColor())
        return c.hsvValue * 100
    }
    
    function updateStopColorHSV(h, s, v) {
        if (!mainCanvas || root.selectedStopIdx >= mainCanvas.gradientStops.length) return
        var hexColor = Qt.hsva(h / 360.0, s / 100.0, v / 100.0, 1.0).toString()
        updateStopColorDirectly(hexColor)
    }

    function updateStopColorDirectly(hexColor) {
        if (!mainCanvas || root.selectedStopIdx >= mainCanvas.gradientStops.length) return
        
        var stops = []
        for (var i = 0; i < mainCanvas.gradientStops.length; i++) {
            stops.push({
                "position": mainCanvas.gradientStops[i].position,
                "color": (i === root.selectedStopIdx) ? hexColor : mainCanvas.gradientStops[i].color
            })
        }
        mainCanvas.gradientStops = stops
    }

    function applyPresetStops(stopsModel, presetId) {
        if (!mainCanvas || !stopsModel) return
        var stops = []
        for (var i = 0; i < stopsModel.length; i++) {
            var p = stopsModel[i]
            var posVal = (p.pos !== undefined) ? p.pos : ((p.position !== undefined) ? p.position : 0.0)
            var colVal = (p.col !== undefined) ? p.col : ((p.color !== undefined) ? p.color : "#ffffff")
            stops.push({
                "position": posVal,
                "color": colVal.toString()
            })
        }
        mainCanvas.gradientStops = stops
        root.selectedStopIdx = 0
        
        if (mainCanvas.activeLayerIndex !== undefined) {
            mainCanvas.setLayerGradientMapEnabled(mainCanvas.activeLayerIndex, true)
            if (presetId) {
                root.activePresetId = presetId
                mainCanvas.setLayerGradientMapPreset(mainCanvas.activeLayerIndex, presetId)
            }
        }
    }
    
    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentHeight: contentCol.implicitHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: 16

            // Dynamic header displaying the active tool in premium badge style
            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: _colorCard
                radius: 6
                border.color: _colorBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: {
                            var t = currentTool.toLowerCase();
                            if (root.isBrushTool) return "🖌️";
                            if (root.isGradientTool) return "🌈";
                            if (root.isSelectionTool) return "✂️";
                            if (root.isFillTool) return "🪣";
                            if (root.isTransformTool) return "⚙️";
                            if (root.isShapeTool) return "📐";
                            return "🛠️";
                        }
                        font.pixelSize: 15
                    }

                    Text {
                        text: {
                            var t = currentTool.toLowerCase();
                            if (root.isBrushTool) return "PROPIEDADES DE PINCEL";
                            if (root.isGradientTool) return "AJUSTES DE DEGRADADO";
                            if (root.isSelectionTool) return "HERRAMIENTA SELECCIÓN";
                            if (root.isFillTool) return "HERRAMIENTA RELLENO";
                            if (root.isTransformTool) return "TRANSFORMACIÓN";
                            if (root.isShapeTool) return "CONFIGURACIÓN FIGURAS";
                            return "AJUSTES DE HERRAMIENTA";
                        }
                        color: _colorText
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        Layout.fillWidth: true
                    }
                    
                    // Small active tool label indicator
                    Text {
                        text: currentTool.toUpperCase()
                        color: _colorTextMuted
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

            // ==========================================
            // BRUSH / PEN / ERASER SETTINGS
            // ==========================================
            ColumnLayout {
                id: brushSettings
                width: parent.width
                spacing: 14
                visible: root.isBrushTool

                // Size
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Tamaño"
                    unit: "px"
                    value: mainCanvas ? Math.pow((mainCanvas.brushSize - 0.5) / 1999.5, 1.0 / 3.0) : 0.01
                    displayValue: mainCanvas ? Math.round(mainCanvas.brushSize) : 10
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.brushSize = 0.5 + 1999.5 * Math.pow(val, 3.0) }
                }

                // Opacity
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Opacidad"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.brushOpacity : 1.0
                    displayValue: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) : 100
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.brushOpacity = val }
                }

                // Flow
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Flujo"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.brushFlow : 1.0
                    displayValue: mainCanvas ? Math.round(mainCanvas.brushFlow * 100) : 100
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.brushFlow = val }
                }

                // Hardness
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Dureza"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.brushHardness : 1.0
                    displayValue: mainCanvas ? Math.round(mainCanvas.brushHardness * 100) : 100
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.brushHardness = val }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Pressure Dynamics
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Text { 
                        text: "DINÁMICA DE PRESIÓN"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Presión de tamaño"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                        Switch {
                            checked: mainCanvas ? mainCanvas.sizeByPressure : true
                            onCheckedChanged: if(mainCanvas) mainCanvas.sizeByPressure = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Presión de opacidad"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                        Switch {
                            checked: mainCanvas ? mainCanvas.opacityByPressure : true
                            onCheckedChanged: if(mainCanvas) mainCanvas.opacityByPressure = checked
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Spacing
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Espaciado"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.brushSpacing : 0.25
                    displayValue: mainCanvas ? Math.round(mainCanvas.brushSpacing * 100) : 25
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.brushSpacing = Math.max(0.01, val) }
                }

                // Stabilization
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Estabilización"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.brushStabilization : 0.0
                    displayValue: mainCanvas ? Math.round(mainCanvas.brushStabilization * 100) : 0
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.brushStabilization = val }
                }

                // Stabilization Mode Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "ALGORITMO DE SUAVIZADO"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }

                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Doble EMA", "WMA", "Lazy Mouse"]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26; radius: 4
                                color: (mainCanvas && mainCanvas.brushStabilizerMode === (index + 1)) ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.25) : "#1a1a1f"
                                border.color: (mainCanvas && mainCanvas.brushStabilizerMode === (index + 1)) ? _colorAccent : _colorBorder
                                border.width: 1
                                
                                Text {
                                    text: modelData
                                    anchors.centerIn: parent
                                    color: (mainCanvas && mainCanvas.brushStabilizerMode === (index + 1)) ? "white" : _colorTextMuted
                                    font.pixelSize: 9; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if(mainCanvas) {
                                            mainCanvas.brushStabilizerMode = index + 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Mirror Mode (Symmetry) Settings - Moved from ToolSettingsPanel.qml
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "MODO DE ESPEJO (SIMETRÍA)"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }
                    
                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Off", "H", "V", "Radial"]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26; radius: 4
                                color: (mainCanvas && mainCanvas.symmetryMode === index && mainCanvas.symmetryEnabled) ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.25) : "#1a1a1f"
                                border.color: (mainCanvas && mainCanvas.symmetryMode === index && mainCanvas.symmetryEnabled) ? _colorAccent : _colorBorder
                                border.width: 1
                                
                                Text {
                                    text: modelData
                                    anchors.centerIn: parent
                                    color: (mainCanvas && mainCanvas.symmetryMode === index && mainCanvas.symmetryEnabled) ? "white" : _colorTextMuted
                                    font.pixelSize: 9; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if(!mainCanvas) return
                                        if(index === 0) mainCanvas.symmetryEnabled = false
                                        else {
                                            mainCanvas.symmetryEnabled = true
                                            mainCanvas.symmetryMode = index - 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // GRADIENT TOOL SETTINGS
            // ==========================================
            ColumnLayout {
                id: gradientSettings
                width: parent.width
                spacing: 12
                visible: root.isGradientTool

                // Shape/Form Selector
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "Forma de Degradado"
                        color: _colorTextMuted
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    
                    Row {
                        spacing: 4
                        
                        Rectangle {
                            width: 68; height: 24; radius: 4
                            color: (mainCanvas && mainCanvas.gradientShape === "linear") ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.25) : "#1a1a1f"
                            border.color: (mainCanvas && mainCanvas.gradientShape === "linear") ? _colorAccent : _colorBorder
                            border.width: 1
                            
                            Text {
                                text: "Lineal"
                                color: (mainCanvas && mainCanvas.gradientShape === "linear") ? "white" : _colorTextMuted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mainCanvas) mainCanvas.gradientShape = "linear"
                            }
                        }
                        
                        Rectangle {
                            width: 68; height: 24; radius: 4
                            color: (mainCanvas && mainCanvas.gradientShape === "radial") ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.25) : "#1a1a1f"
                            border.color: (mainCanvas && mainCanvas.gradientShape === "radial") ? _colorAccent : _colorBorder
                            border.width: 1
                            
                            Text {
                                text: "Radial"
                                color: (mainCanvas && mainCanvas.gradientShape === "radial") ? "white" : _colorTextMuted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mainCanvas) mainCanvas.gradientShape = "radial"
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Stops and Slider Bar
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    
                    Text {
                        text: "Paradas de Color (Doble clic para crear, arrastrar abajo para eliminar):"
                        color: _colorTextMuted
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    
                    Item {
                        id: sliderContainer
                        Layout.fillWidth: true
                        height: 32
                        
                        Rectangle {
                            id: gradientBar
                            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            height: 12
                            radius: 3
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1
                            
                            // Checkerboard background for transparency
                            Rectangle {
                                anchors.fill: parent; z: -2; radius: 2; color: "white"
                                Grid {
                                    anchors.fill: parent; columns: 20; rows: 2
                                    Repeater {
                                        model: 40
                                        Rectangle {
                                            width: gradientBar.width / 20; height: 6
                                            color: (index % 2 === 0) ? "#eee" : "#ccc"
                                        }
                                    }
                                }
                            }
                            
                            // Canvas Live Gradient
                            Rectangle {
                                anchors.fill: parent; z: -1; radius: 2; clip: true
                                Canvas {
                                    id: barGradientCanvas
                                    anchors.fill: parent
                                    property var stopsVal: mainCanvas ? mainCanvas.gradientStops : null
                                    onStopsValChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        var grad = ctx.createLinearGradient(0, 0, width, 0);
                                        if (stopsVal && stopsVal.length > 0) {
                                            for (var i = 0; i < stopsVal.length; i++) {
                                                grad.addColorStop(stopsVal[i].position, stopsVal[i].color);
                                            }
                                        } else {
                                            grad.addColorStop(0.0, "#000000"); grad.addColorStop(1.0, "#ffffff");
                                        }
                                        ctx.fillStyle = grad; ctx.fillRect(0, 0, width, height);
                                    }
                                    onWidthChanged: requestPaint()
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onDoubleClicked: (mouse) => {
                                    if (!mainCanvas) return
                                    var posVal = mouse.x / width
                                    posVal = Math.max(0.0, Math.min(1.0, posVal))
                                    var stops = []
                                    for (var i = 0; i < mainCanvas.gradientStops.length; i++) {
                                        stops.push(mainCanvas.gradientStops[i])
                                    }
                                    stops.push({ "position": posVal, "color": mainCanvas.brushColor.toString() })
                                    stops.sort(function(a, b) { return a.position - b.position })
                                    mainCanvas.gradientStops = stops
                                    for (var j = 0; j < stops.length; j++) {
                                        if (Math.abs(stops[j].position - posVal) < 0.01) {
                                            root.selectedStopIdx = j; break
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Stop drag handles
                        Repeater {
                            model: (mainCanvas && mainCanvas.gradientStops) ? mainCanvas.gradientStops : []
                            delegate: Item {
                                id: handleItem
                                x: 8 + (modelData.position * (gradientBar.width)) - width/2
                                y: gradientBar.y + (gradientBar.height - height)/2
                                width: 14; height: 18
                                
                                Rectangle {
                                    anchors.fill: parent; radius: 3; color: modelData.color
                                    border.color: (root.selectedStopIdx === index) ? "white" : "#000"
                                    border.width: (root.selectedStopIdx === index) ? 1.8 : 1
                                    
                                    Rectangle {
                                        width: 4; height: 4; radius: 2; color: "white"
                                        anchors.centerIn: parent; visible: root.selectedStopIdx === index
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    drag.target: handleItem; drag.axis: Drag.XAxis
                                    drag.minimumX: 8 - handleItem.width/2
                                    drag.maximumX: 8 + gradientBar.width - handleItem.width/2
                                    onPressed: root.selectedStopIdx = index
                                    onPositionChanged: {
                                        if (drag.active) {
                                            var relativeX = handleItem.x - 8 + handleItem.width/2
                                            var newPos = relativeX / gradientBar.width
                                            newPos = Math.max(0.0, Math.min(1.0, newPos))
                                            var stops = []
                                            for (var i = 0; i < mainCanvas.gradientStops.length; i++) {
                                                stops.push({
                                                    "position": (i === index) ? newPos : mainCanvas.gradientStops[i].position,
                                                    "color": mainCanvas.gradientStops[i].color
                                                })
                                            }
                                            mainCanvas.gradientStops = stops
                                            
                                            // Drag down below the bar area to delete
                                            if (mouseY > 32 && mainCanvas.gradientStops.length > 2) {
                                                stops.splice(index, 1)
                                                mainCanvas.gradientStops = stops
                                                root.selectedStopIdx = Math.max(0, index - 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Stop Color Details Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 175
                    color: _colorCard
                    radius: 6
                    border.color: _colorBorder
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            Rectangle {
                                width: 28; height: 28; radius: 14; color: root.getSelectedColor()
                                border.color: "white"; border.width: 1.5
                            }
                            
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "Parada #" + (root.selectedStopIdx + 1)
                                    color: "white"; font.pixelSize: 10; font.weight: Font.Bold
                                }
                                Text {
                                    text: "Posición: " + Math.round((mainCanvas && root.selectedStopIdx < mainCanvas.gradientStops.length ? mainCanvas.gradientStops[root.selectedStopIdx].position : 0.0) * 100) + "%"
                                    color: _colorTextMuted; font.pixelSize: 8
                                }
                            }

                            Item { Layout.fillWidth: true }
                            
                            // Color Principal Button
                            Button {
                                text: "Pincel Color"
                                font.pixelSize: 9; font.bold: true
                                implicitHeight: 22
                                onClicked: {
                                    if (mainCanvas) root.updateStopColorDirectly(mainCanvas.brushColor.toString())
                                }
                            }
                            
                            // Delete stop button
                            Button {
                                text: "Eliminar"
                                font.pixelSize: 9; font.bold: true
                                visible: mainCanvas && mainCanvas.gradientStops.length > 2
                                implicitHeight: 22
                                onClicked: {
                                    if (!mainCanvas || mainCanvas.gradientStops.length <= 2) return
                                    var stops = []
                                    for (var i = 0; i < mainCanvas.gradientStops.length; i++) {
                                        if (i !== root.selectedStopIdx) stops.push(mainCanvas.gradientStops[i])
                                    }
                                    mainCanvas.gradientStops = stops
                                    root.selectedStopIdx = Math.max(0, root.selectedStopIdx - 1)
                                }
                            }
                        }

                        // Premium HSV Sliders (uses StudioSlider for unified design!)
                        StudioSlider {
                            Layout.fillWidth: true
                            height: 34
                            label: "Matiz (H)"
                            unit: "°"
                            value: root.getH() / 360.0
                            displayValue: root.getH()
                            decimals: 0
                            accent: _colorAccent
                            onMoved: (val) => root.updateStopColorHSV(val * 360, sSlider.value * 100, vSlider.value * 100)
                            id: hSlider
                        }
                        
                        StudioSlider {
                            Layout.fillWidth: true
                            height: 34
                            label: "Saturación (S)"
                            unit: "%"
                            value: root.getS() / 100.0
                            displayValue: root.getS()
                            decimals: 0
                            accent: _colorAccent
                            onMoved: (val) => root.updateStopColorHSV(hSlider.value * 360, val * 100, vSlider.value * 100)
                            id: sSlider
                        }
                        
                        StudioSlider {
                            Layout.fillWidth: true
                            height: 34
                            label: "Valor (V)"
                            unit: "%"
                            value: root.getV() / 100.0
                            displayValue: root.getV()
                            decimals: 0
                            accent: _colorAccent
                            onMoved: (val) => root.updateStopColorHSV(hSlider.value * 360, sSlider.value * 100, val * 100)
                            id: vSlider
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Preset Library
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 6
                    
                    RowLayout {
                        Text { text: "Biblioteca de Degradados"; color: _colorText; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                        
                        // Add current gradient button
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: "#1a1a1f"
                            border.color: _colorBorder
                            Text { text: "+"; color: "white"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!mainCanvas) return
                                    var customStops = []
                                    for (var i = 0; i < mainCanvas.gradientStops.length; i++) {
                                        customStops.push({ "position": mainCanvas.gradientStops[i].position, "color": mainCanvas.gradientStops[i].color })
                                    }
                                    var list = []
                                    for (var j = 0; j < root.customPresets.length; j++) list.push(root.customPresets[j])
                                    list.push({
                                        "id": "custom_" + list.length,
                                        "name": "Degradado " + (list.length + 1),
                                        "colors": [customStops[0].color, customStops[Math.round(customStops.length/2)].color, customStops[customStops.length - 1].color],
                                        "stops": customStops
                                    })
                                    root.customPresets = list
                                }
                            }
                        }
                    }

                    // Grid layout of presets
                    Grid {
                        width: parent.width; columns: 2; spacing: 4
                        
                        Repeater {
                            model: [
                                { id: "sunset", name: "Sunset", colors: ["#764ba2", "#ff7e5f", "#feb47b"], stops: [{pos: 0.0, col: "#764ba2"}, {pos: 0.5, col: "#ff7e5f"}, {pos: 1.0, col: "#feb47b"}] },
                                { id: "ocean", name: "Ocean", colors: ["#0b1a3c", "#02aab0", "#a0f5be"], stops: [{pos: 0.0, col: "#0b1a3c"}, {pos: 0.5, col: "#02aab0"}, {pos: 1.0, col: "#a0f5be"}] },
                                { id: "forest", name: "Forest", colors: ["#0a2830", "#56ab2f", "#a8ff78"], stops: [{pos: 0.0, col: "#0a2830"}, {pos: 0.5, col: "#56ab2f"}, {pos: 1.0, col: "#a8ff78"}] },
                                { id: "retro", name: "Retro", colors: ["#0a0505", "#f12711", "#f5af19"], stops: [{pos: 0.0, col: "#0a0505"}, {pos: 0.5, col: "#f12711"}, {pos: 1.0, col: "#f5af19"}] },
                                { id: "manga", name: "Manga", colors: ["#0f0f14", "#828287", "#fafafa"], stops: [{pos: 0.0, col: "#0f0f14"}, {pos: 0.5, col: "#828287"}, {pos: 1.0, col: "#fafafa"}] },
                                { id: "neon", name: "Neon", colors: ["#00f6ff", "#ff0076", "#ffe600"], stops: [{pos: 0.0, col: "#00f6ff"}, {pos: 0.5, col: "#ff0076"}, {pos: 1.0, col: "#ffe600"}] },
                                { id: "fire", name: "Fire", colors: ["#110000", "#ff3300", "#ffffaa"], stops: [{pos: 0.0, col: "#110000"}, {pos: 0.5, col: "#ff3300"}, {pos: 1.0, col: "#ffffaa"}] },
                                { id: "ice", name: "Ice", colors: ["#0052d4", "#4364f7", "#6fb1fc"], stops: [{pos: 0.0, col: "#0052d4"}, {pos: 0.5, col: "#4364f7"}, {pos: 1.0, col: "#6fb1fc"}] }
                            ]
                            delegate: Rectangle {
                                width: (parent.width - 4) / 2; height: 32; radius: 4; color: "#1a1a1f"
                                border.color: (root.activePresetId === modelData.id) ? colorAccent : colorBorder
                                border.width: (root.activePresetId === modelData.id) ? 1.5 : 1
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 4; spacing: 6
                                    Rectangle {
                                        width: 36; height: 16; radius: 2
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: modelData.colors[0] }
                                            GradientStop { position: 0.5; color: modelData.colors[1] }
                                            GradientStop { position: 1.0; color: modelData.colors[2] }
                                        }
                                    }
                                    Text { text: modelData.name; color: _colorTextMuted; font.pixelSize: 9; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPresetStops(modelData.stops, modelData.id) }
                            }
                        }
                        
                        Repeater {
                            model: root.customPresets
                            delegate: Rectangle {
                                width: (parent.width - 4) / 2; height: 32; radius: 4; color: "#1d1d23"
                                border.color: (root.activePresetId === modelData.id) ? colorAccent : colorBorder
                                border.width: (root.activePresetId === modelData.id) ? 1.5 : 1
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 4; spacing: 6
                                    Rectangle {
                                        width: 36; height: 16; radius: 2
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: modelData.colors[0] }
                                            GradientStop { position: 0.5; color: modelData.colors[1] }
                                            GradientStop { position: 1.0; color: modelData.colors[2] }
                                        }
                                    }
                                    Text { text: modelData.name; color: "white"; font.pixelSize: 9; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPresetStops(modelData.stops, modelData.id) }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // SELECTION / LASSO SETTINGS
            // ==========================================
            ColumnLayout {
                id: selectionSettings
                width: parent.width
                spacing: 14
                visible: root.isSelectionTool

                // Selection Mode Segmented Control
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "MODO DE SELECCIÓN"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }
                    
                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Repeater {
                            model: [
                                { name: "Nueva", val: 0 },
                                { name: "Añadir", val: 1 },
                                { name: "Restar", val: 2 }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26; radius: 4
                                color: (mainCanvas && mainCanvas.selectionAddMode === modelData.val) ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25) : "#1a1a1f"
                                border.color: (mainCanvas && mainCanvas.selectionAddMode === modelData.val) ? colorAccent : colorBorder
                                border.width: 1
                                
                                Text {
                                    text: modelData.name
                                    anchors.centerIn: parent
                                    color: (mainCanvas && mainCanvas.selectionAddMode === modelData.val) ? "white" : _colorTextMuted
                                    font.pixelSize: 9; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if(mainCanvas) mainCanvas.selectionAddMode = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Tolerance Slider
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Tolerancia / Umbral"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.selectionThreshold : 0.15
                    displayValue: mainCanvas ? Math.round(mainCanvas.selectionThreshold * 100) : 15
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.selectionThreshold = val }
                }

                // Magnetic Lasso Specifics
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: currentTool.toLowerCase() === "magnetic_lasso"

                    Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                    // Magnetic Search Radius
                    StudioSlider {
                        Layout.fillWidth: true
                        label: "Radio de Búsqueda Magnética"
                        unit: "px"
                        value: mainCanvas ? (mainCanvas.magneticSearchRadius - 1.0) / 99.0 : 0.15
                        displayValue: mainCanvas ? mainCanvas.magneticSearchRadius : 15
                        decimals: 0
                        accent: _colorAccent
                        onMoved: (val) => { if (mainCanvas) mainCanvas.magneticSearchRadius = Math.round(1.0 + 99.0 * val) }
                    }

                    // Magnetic Edge Sensitivity
                    StudioSlider {
                        Layout.fillWidth: true
                        label: "Sensibilidad de Borde"
                        unit: "%"
                        value: mainCanvas ? mainCanvas.magneticEdgeSensitivity : 0.3
                        displayValue: mainCanvas ? Math.round(mainCanvas.magneticEdgeSensitivity * 100) : 30
                        decimals: 0
                        accent: _colorAccent
                        onMoved: (val) => { if (mainCanvas) mainCanvas.magneticEdgeSensitivity = val }
                    }
                }
            }

            // ==========================================
            // BUCKET FILL SETTINGS
            // ==========================================
            ColumnLayout {
                id: fillSettings
                width: parent.width
                spacing: 14
                visible: root.isFillTool

                // Tolerance Slider
                StudioSlider {
                    Layout.fillWidth: true
                    label: "Tolerancia de Relleno"
                    unit: "%"
                    value: mainCanvas ? mainCanvas.selectionThreshold : 0.15
                    displayValue: mainCanvas ? Math.round(mainCanvas.selectionThreshold * 100) : 15
                    decimals: 0
                    accent: _colorAccent
                    onMoved: (val) => { if (mainCanvas) mainCanvas.selectionThreshold = val }
                }

                // Fill modes (selection add modes)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "MODO DE SELECCIÓN DE RELLENO"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }
                    
                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Repeater {
                            model: [
                                { name: "Normal", val: 0 },
                                { name: "Sumar", val: 1 },
                                { name: "Restar", val: 2 }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26; radius: 4
                                color: (mainCanvas && mainCanvas.selectionAddMode === modelData.val) ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25) : "#1a1a1f"
                                border.color: (mainCanvas && mainCanvas.selectionAddMode === modelData.val) ? colorAccent : colorBorder
                                border.width: 1
                                
                                Text {
                                    text: modelData.name
                                    anchors.centerIn: parent
                                    color: (mainCanvas && mainCanvas.selectionAddMode === modelData.val) ? "white" : _colorTextMuted
                                    font.pixelSize: 9; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if(mainCanvas) mainCanvas.selectionAddMode = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TRANSFORM / MOVE SETTINGS
            // ==========================================
            ColumnLayout {
                id: transformSettings
                width: parent.width
                spacing: 14
                visible: root.isTransformTool

                readonly property bool _active: mainCanvas && mainCanvas.isFreeTransformActive

                // Status Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 6
                    color: transformSettings._active ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25) : "#1a1a1f"
                    border.color: transformSettings._active ? colorAccent : colorBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        
                        Text {
                            text: transformSettings._active ? "Transformación: Activa" : "Transformación: Inactiva"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: transformSettings._active ? "#22c55e" : "#6b7280"
                        }
                    }
                }

                // Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Button {
                        text: "Activar (Ctrl+T)"
                        Layout.fillWidth: true
                        enabled: !transformSettings._active
                        font.pixelSize: 10
                        onClicked: { 
                            if (mainCanvas) {
                                mainCanvas.isFreeTransformActive = true; 
                                if (typeof canvasPage !== "undefined") canvasPage.activeToolIdx = 4;
                            } 
                        }
                    }
                    
                    Button {
                        text: "Confirmar"
                        Layout.fillWidth: true
                        enabled: transformSettings._active
                        highlighted: true
                        font.pixelSize: 10
                        onClicked: { if (mainCanvas) mainCanvas.isFreeTransformActive = false }
                    }

                    Button {
                        text: "Cancelar"
                        Layout.fillWidth: true
                        enabled: transformSettings._active
                        font.pixelSize: 10
                        onClicked: { if (mainCanvas && typeof mainCanvas.cancelTransform === "function") mainCanvas.cancelTransform() }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Transform Modes Segmented Bar (Free, Perspective, Warp, Mesh)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "MODO DE TRANSFORMACIÓN"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }
                    
                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Repeater {
                            model: [
                                { name: "Libre", val: 0 },
                                { name: "Persp.", val: 1 },
                                { name: "Deform.", val: 2 },
                                { name: "Malla", val: 3 }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26; radius: 4
                                color: (mainCanvas && mainCanvas.transformMode === modelData.val) ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25) : "#1a1a1f"
                                border.color: (mainCanvas && mainCanvas.transformMode === modelData.val) ? colorAccent : colorBorder
                                border.width: 1
                                
                                Text {
                                    text: modelData.name
                                    anchors.centerIn: parent
                                    color: (mainCanvas && mainCanvas.transformMode === modelData.val) ? "white" : _colorTextMuted
                                    font.pixelSize: 9; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if(mainCanvas) mainCanvas.transformMode = modelData.val;
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // Interpolation options
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { 
                        text: "OPCIONES DE INTERPOLACIÓN"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Filtro Bilineal"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                        Switch {
                            checked: (typeof mainWindow !== "undefined") ? mainWindow.transformBilinear : true
                            onCheckedChanged: { if (typeof mainWindow !== "undefined") mainWindow.transformBilinear = checked }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Malla Avanzada GPU"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                        Switch {
                            checked: (typeof mainWindow !== "undefined") ? mainWindow.transformAdvancedMesh : false
                            onCheckedChanged: { if (typeof mainWindow !== "undefined") mainWindow.transformAdvancedMesh = checked }
                        }
                    }
                }
            }

            // ==========================================
            // SHAPE / COMIC PANEL / BUBBLE SETTINGS
            // ==========================================
            ColumnLayout {
                id: shapeSettings
                width: parent.width
                spacing: 14
                visible: root.isShapeTool

                // --- Category Selector (Segment Control) ---
                RowLayout {
                    Layout.fillWidth: true
                    height: 32
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Figuras", val: 0 },
                            { label: "Viñetas", val: 1 },
                            { label: "Globos", val: 2 }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 6
                            color: root.activeShapeCategory === modelData.val ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.2) : "#1a1a1f"
                            border.color: root.activeShapeCategory === modelData.val ? _colorAccent : _colorBorder
                            border.width: 1

                            Text {
                                text: modelData.label
                                color: root.activeShapeCategory === modelData.val ? "white" : _colorTextMuted
                                font.pixelSize: 10
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeShapeCategory = modelData.val
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                // ==========================================
                // CATEGORY 0: FIGURAS (SHAPES)
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.activeShapeCategory === 0

                    Text {
                        text: "HERRAMIENTAS DE DIBUJO"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }

                    // Grid of Shapes
                    GridLayout {
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { id: "rect", label: "Rectángulo" },
                                { id: id === "ellipse" ? "ellipse" : "ellipse", label: "Elipse" },
                                { id: "line", label: "Línea" }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 54; radius: 8
                                color: (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.shapeDrawingActive && comicOverlay.shapeDrawingType === modelData.id) ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.15) : "#141416"
                                border.color: (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.shapeDrawingActive && comicOverlay.shapeDrawingType === modelData.id) ? _colorAccent : _colorBorder
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 2

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Canvas {
                                            anchors.centerIn: parent
                                            width: 20; height: 20
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.clearRect(0,0,width,height)
                                                ctx.strokeStyle = "white"
                                                ctx.lineWidth = 1.5
                                                if (modelData.id === "rect") {
                                                    ctx.strokeRect(2, 2, width-4, height-4)
                                                } else if (modelData.id === "ellipse") {
                                                    ctx.beginPath()
                                                    ctx.ellipse(2, 2, width-4, height-4)
                                                    ctx.stroke()
                                                } else {
                                                    ctx.beginPath()
                                                    ctx.moveTo(2, height-2)
                                                    ctx.lineTo(width-2, 2)
                                                    ctx.stroke()
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.label
                                        Layout.alignment: Qt.AlignHCenter
                                        color: "#ccc"
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof comicOverlay !== "undefined" && comicOverlay) {
                                            comicOverlay.startShapeDrawing(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                    // Border Width Slider
                    StudioSlider {
                        Layout.fillWidth: true
                        label: "Ancho de Borde"
                        unit: "px"
                        value: mainCanvas ? Math.pow((mainCanvas.brushSize - 0.5) / 1999.5, 1.0 / 3.0) : 0.01
                        displayValue: mainCanvas ? Math.round(mainCanvas.brushSize) : 10
                        decimals: 0
                        accent: _colorAccent
                        onMoved: (val) => { 
                            var bWidth = 0.5 + 1999.5 * Math.pow(val, 3.0);
                            if (mainCanvas) mainCanvas.brushSize = bWidth;
                            if (typeof comicOverlay !== "undefined" && comicOverlay) {
                                comicOverlay.shapeStrokeWidth = bWidth;
                            }
                            if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                                mainWindow.comicOverlayManager.setSelectedBorderWidth(bWidth);
                            }
                        }
                    }

                    // Opacity
                    StudioSlider {
                        Layout.fillWidth: true
                        label: "Opacidad de Figura"
                        unit: "%"
                        value: mainCanvas ? mainCanvas.brushOpacity : 1.0
                        displayValue: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) : 100
                        decimals: 0
                        accent: _colorAccent
                        onMoved: (val) => { 
                            if (mainCanvas) mainCanvas.brushOpacity = val;
                            if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                                mainWindow.comicOverlayManager.setSelectedOpacity(val);
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                    // Color Controls for Shapes
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "COLORES DE FIGURA"
                            font.pixelSize: 9; font.weight: Font.Bold
                            color: _colorTextMuted; Layout.fillWidth: true
                            font.letterSpacing: 1
                        }

                        // Outline color
                        Text { text: "Color del Borde"; color: "#aaa"; font.pixelSize: 10 }
                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true
                            Repeater {
                                model: ["#000000", "#ffffff", "#d32f2f", "#1a237e", "#4b5563"]
                                delegate: Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: modelData
                                    border.color: (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.shapeStrokeColor.toString() === modelData) ? _colorAccent : "#444"
                                    border.width: (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.shapeStrokeColor.toString() === modelData) ? 2 : 1
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (typeof comicOverlay !== "undefined" && comicOverlay) {
                                                comicOverlay.shapeStrokeColor = modelData
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 24; radius: 6
                                color: "#1a1a20"; border.color: "#333"; border.width: 1
                                Text { text: "Usar Pincel"; color: "#ccc"; font.pixelSize: 9; anchors.centerIn: parent }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (mainCanvas && typeof comicOverlay !== "undefined" && comicOverlay) {
                                            comicOverlay.shapeStrokeColor = mainCanvas.brushColor
                                        }
                                    }
                                }
                            }
                        }

                        // Fill color
                        Text { text: "Color de Relleno"; color: "#aaa"; font.pixelSize: 10 }
                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true
                            Repeater {
                                model: ["transparent", "#ffffff", "#fffdd0", "#fff9c4", "#f3f4f6"]
                                delegate: Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: modelData === "transparent" ? "transparent" : modelData
                                    border.color: (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.shapeFillColor.toString() === modelData) ? _colorAccent : "#444"
                                    border.width: (typeof comicOverlay !== "undefined" && comicOverlay && comicOverlay.shapeFillColor.toString() === modelData) ? 2 : 1

                                    Rectangle {
                                        visible: modelData === "transparent"
                                        anchors.fill: parent; radius: 12; color: "transparent"; z: -1
                                        border.color: "#666"; border.width: 1
                                        Text { text: "∅"; color: "#888"; font.pixelSize: 14; font.bold: true; anchors.centerIn: parent }
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (typeof comicOverlay !== "undefined" && comicOverlay) {
                                                comicOverlay.shapeFillColor = modelData
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 24; radius: 6
                                color: "#1a1a20"; border.color: "#333"; border.width: 1
                                Text { text: "Usar Pincel"; color: "#ccc"; font.pixelSize: 9; anchors.centerIn: parent }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (mainCanvas && typeof comicOverlay !== "undefined" && comicOverlay) {
                                            comicOverlay.shapeFillColor = mainCanvas.brushColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // CATEGORY 1: VIÑETAS (PANELS)
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.activeShapeCategory === 1

                    Text {
                        text: "PLANTILLAS DE MAQUETACIÓN"
                        font.pixelSize: 9; font.weight: Font.Bold
                        color: _colorTextMuted; Layout.fillWidth: true
                        font.letterSpacing: 1
                    }

                    // Previews Grid
                    GridLayout {
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { id: "panel_single", label: "Página Completa" },
                                { id: "panel_2col", label: "2 Columnas" },
                                { id: "panel_2row", label: "2 Filas" },
                                { id: "panel_grid", label: "Cuadrícula 3+2" },
                                { id: "panel_manga", label: "Manga Clásico" },
                                { id: "panel_4panel", label: "4 Paneles" },
                                { id: "panel_strip", label: "Tira Cómica" }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 72; radius: 8
                                color: "#141416"
                                border.color: pnlMa.containsMouse ? _colorAccent : _colorBorder
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 2

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Canvas {
                                            anchors.centerIn: parent
                                            width: 44; height: 32
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                var w = width, h = height
                                                ctx.clearRect(0,0,w,h)
                                                var mx = 3, my = 3
                                                var iw = w - 2*mx, ih = h - 2*my
                                                var g = 2
                                                ctx.fillStyle = "#2d2d34"
                                                ctx.strokeStyle = "white"
                                                ctx.lineWidth = 1
                                                var panels = root.getPanels(modelData.id, mx, my, iw, ih, g)
                                                for (var i = 0; i < panels.length; i++) {
                                                    var p = panels[i]
                                                    ctx.fillRect(p.x, p.y, p.w, p.h)
                                                    ctx.strokeRect(p.x, p.y, p.w, p.h)
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.label
                                        Layout.alignment: Qt.AlignHCenter
                                        color: "#ccc"
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                }

                                MouseArea {
                                    id: pnlMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        try {
                                            var gut = mainCanvas ? mainCanvas.panelGutterSize : 12;
                                            var bW = mainCanvas ? mainCanvas.panelBorderWidth : 6;
                                            mainCanvas.drawPanelLayout(modelData.id.replace("panel_", ""), gut, bW, 30);
                                            if (typeof toastManager !== "undefined") {
                                                toastManager.show("¡Viñetas generadas!", "success")
                                            }
                                        } catch (e) {
                                            console.log("[StudioConfig] Viñeta error: " + e)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                    // Gutter Size Slider
                    StudioSlider {
                        Layout.fillWidth: true
                        label: "Separación (Gutter)"
                        unit: "px"
                        value: mainCanvas ? (mainCanvas.panelGutterSize / 100.0) : 0.12
                        displayValue: mainCanvas ? Math.round(mainCanvas.panelGutterSize) : 12
                        decimals: 0
                        accent: _colorAccent
                        onMoved: (val) => { if (mainCanvas) mainCanvas.panelGutterSize = Math.round(100.0 * val) }
                    }

                    // Border Width Slider
                    StudioSlider {
                        Layout.fillWidth: true
                        label: "Borde de Viñeta"
                        unit: "px"
                        value: mainCanvas ? (mainCanvas.panelBorderWidth / 20.0) : 0.3
                        displayValue: mainCanvas ? Math.round(mainCanvas.panelBorderWidth) : 6
                        decimals: 0
                        accent: _colorAccent
                        onMoved: (val) => { if (mainCanvas) mainCanvas.panelBorderWidth = Math.round(20.0 * val) }
                    }
                }

                // ==========================================
                // CATEGORY 2: GLOBOS (BUBBLES)
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.activeShapeCategory === 2

                    // IF A BUBBLE IS ACTIVE / SELECTED
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        visible: !!root.activeBubble

                        // Shape grid
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                text: "FORMA DE GLOBO"
                                font.pixelSize: 9; font.weight: Font.Bold
                                color: _colorTextMuted; Layout.fillWidth: true
                                font.letterSpacing: 1
                            }
                            GridLayout {
                                columns: 3
                                rowSpacing: 4
                                columnSpacing: 4
                                Layout.fillWidth: true
                                Repeater {
                                    model: [
                                        { id: "oval", label: "Óvalo" },
                                        { id: "rounded_rect", label: "Redondo" },
                                        { id: "rect", label: "Cuadrado" },
                                        { id: "double_oval", label: "Doble Óvalo" },
                                        { id: "double_rounded", label: "Doble Red." },
                                        { id: "thought", label: "Pensam." },
                                        { id: "shout", label: "Grito" },
                                        { id: "narration", label: "Narración" }
                                    ]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 28; radius: 6
                                        color: (root.activeBubble && root.activeBubble.bubbleType === modelData.id) ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.2) : "#141416"
                                        border.color: (root.activeBubble && root.activeBubble.bubbleType === modelData.id) ? _colorAccent : _colorBorder
                                        border.width: 1
                                        Text {
                                            text: modelData.label
                                            anchors.centerIn: parent
                                            color: (root.activeBubble && root.activeBubble.bubbleType === modelData.id) ? "white" : _colorTextMuted
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.updateBubbleProperty("type", modelData.id)
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                        // Geometry sliders
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: "PROPIEDADES FÍSICAS"
                                font.pixelSize: 9; font.weight: Font.Bold
                                color: _colorTextMuted; Layout.fillWidth: true
                                font.letterSpacing: 1
                            }

                            StudioSlider {
                                Layout.fillWidth: true
                                label: "Espesor de Borde"
                                unit: "px"
                                value: root.activeBubble ? (root.activeBubble.strokeWidth - 1.0) / 14.0 : 0.15
                                displayValue: root.activeBubble ? root.activeBubble.strokeWidth : 3
                                decimals: 0
                                accent: _colorAccent
                                onMoved: (val) => root.updateBubbleProperty("strokeWidth", Math.round(1.0 + 14.0 * val))
                            }

                            StudioSlider {
                                Layout.fillWidth: true
                                label: "Ancho de Cola"
                                unit: "px"
                                visible: root.activeBubble ? (root.activeBubble.bubbleType !== "narration") : true
                                value: root.activeBubble ? (root.activeBubble.tailWidth - 10.0) / 70.0 : 0.28
                                displayValue: root.activeBubble ? root.activeBubble.tailWidth : 30
                                decimals: 0
                                accent: _colorAccent
                                onMoved: (val) => root.updateBubbleProperty("tailWidth", Math.round(10.0 + 70.0 * val))
                            }

                            StudioSlider {
                                Layout.fillWidth: true
                                label: "Radio de Esquina"
                                unit: "px"
                                visible: root.activeBubble ? (root.activeBubble.bubbleType === "rounded_rect" || root.activeBubble.bubbleType === "double_rounded") : false
                                value: root.activeBubble ? root.activeBubble.cornerRadius / 50.0 : 0.32
                                displayValue: root.activeBubble ? root.activeBubble.cornerRadius : 16
                                decimals: 0
                                accent: _colorAccent
                                onMoved: (val) => root.updateBubbleProperty("cornerRadius", Math.round(50.0 * val))
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                        // Colors
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "COLORES DEL GLOBO"
                                font.pixelSize: 9; font.weight: Font.Bold
                                color: _colorTextMuted; Layout.fillWidth: true
                                font.letterSpacing: 1
                            }

                            Text { text: "Color de Fondo"; color: "#aaa"; font.pixelSize: 10 }
                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true
                                Repeater {
                                    model: [
                                        { hex: "#ffffff" },
                                        { hex: "#fffdd0" },
                                        { hex: "#fff9c4" },
                                        { hex: "#f3f4f6" },
                                        { hex: "transparent" }
                                    ]
                                    delegate: Rectangle {
                                        width: 24; height: 24; radius: 12
                                        color: modelData.hex === "transparent" ? "transparent" : modelData.hex
                                        border.color: (root.activeBubble && root.activeBubble.fillColor === modelData.hex) ? _colorAccent : "#444"
                                        border.width: (root.activeBubble && root.activeBubble.fillColor === modelData.hex) ? 2 : 1
                                        Rectangle {
                                            visible: modelData.hex === "transparent"
                                            anchors.fill: parent; radius: 12; color: "transparent"; z: -1
                                            border.color: "#666"; border.width: 1
                                            Text { text: "∅"; color: "#888"; font.pixelSize: 14; font.bold: true; anchors.centerIn: parent }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.updateBubbleProperty("fillColor", modelData.hex)
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 24; radius: 6
                                    color: "#1a1a20"; border.color: "#333"; border.width: 1
                                    Text { text: "Usar Pincel"; color: "#ccc"; font.pixelSize: 9; anchors.centerIn: parent }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.activeBubble && mainCanvas) {
                                                root.updateBubbleProperty("fillColor", mainCanvas.brushColor.toString())
                                            }
                                        }
                                    }
                                }
                            }

                            Text { text: "Color de Borde"; color: "#aaa"; font.pixelSize: 10 }
                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true
                                Repeater {
                                    model: ["#000000", "#d32f2f", "#1a237e", "#4b5563"]
                                    delegate: Rectangle {
                                        width: 24; height: 24; radius: 12
                                        color: modelData
                                        border.color: (root.activeBubble && root.activeBubble.strokeColor === modelData) ? _colorAccent : "#444"
                                        border.width: (root.activeBubble && root.activeBubble.strokeColor === modelData) ? 2 : 1
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.updateBubbleProperty("strokeColor", modelData)
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 24; radius: 6
                                    color: "#1a1a20"; border.color: "#333"; border.width: 1
                                    Text { text: "Usar Pincel"; color: "#ccc"; font.pixelSize: 9; anchors.centerIn: parent }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.activeBubble && mainCanvas) {
                                                root.updateBubbleProperty("strokeColor", mainCanvas.brushColor.toString())
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                        // Auto adjustments
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "AJUSTES AUTOMÁTICOS"
                                font.pixelSize: 9; font.weight: Font.Bold
                                color: _colorTextMuted; Layout.fillWidth: true
                                font.letterSpacing: 1
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Auto-ajustar Altura"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                                Switch {
                                    checked: root.activeBubble ? root.activeBubble.autoResize : false
                                    onCheckedChanged: {
                                        root.updateBubbleProperty("autoResize", checked)
                                        if (checked) root.updateBubbleProperty("autoFitText", false)
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Auto-ajustar Texto"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                                Switch {
                                    checked: root.activeBubble ? root.activeBubble.autoFitText : false
                                    onCheckedChanged: {
                                        root.updateBubbleProperty("autoFitText", checked)
                                        if (checked) root.updateBubbleProperty("autoResize", false)
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder }

                        // Typography controls
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: "TIPOGRAFÍA Y ALINEACIÓN"
                                font.pixelSize: 9; font.weight: Font.Bold
                                color: _colorTextMuted; Layout.fillWidth: true
                                font.letterSpacing: 1
                            }

                            // Font Family
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Repeater {
                                    model: [
                                        { id: "Comic Sans MS, sans-serif", label: "Comic" },
                                        { id: "Impact, sans-serif", label: "Manga" },
                                        { id: "Arial, sans-serif", label: "Sans" },
                                        { id: "Courier New, monospace", label: "Mono" }
                                    ]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 24; radius: 4
                                        color: (root.activeBubble && root.activeBubble.fontFamily === modelData.id) ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.2) : "#141416"
                                        border.color: (root.activeBubble && root.activeBubble.fontFamily === modelData.id) ? _colorAccent : _colorBorder
                                        border.width: 1
                                        Text {
                                            text: modelData.label
                                            anchors.centerIn: parent
                                            color: (root.activeBubble && root.activeBubble.fontFamily === modelData.id) ? "white" : _colorTextMuted
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.updateBubbleProperty("fontFamily", modelData.id)
                                        }
                                    }
                                }
                            }

                            // Font size
                            StudioSlider {
                                Layout.fillWidth: true
                                label: "Tamaño de Fuente"
                                unit: "pt"
                                enabled: root.activeBubble ? !root.activeBubble.autoFitText : true
                                value: root.activeBubble ? (root.activeBubble.fontSize - 8.0) / 52.0 : 0.19
                                displayValue: root.activeBubble ? root.activeBubble.fontSize : 18
                                decimals: 0
                                accent: _colorAccent
                                onMoved: (val) => root.updateBubbleProperty("fontSize", Math.round(8.0 + 52.0 * val))
                            }

                            // Bold/Italic Switches
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Negrita"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                                    Switch {
                                        checked: root.activeBubble ? root.activeBubble.bold : false
                                        onCheckedChanged: root.updateBubbleProperty("bold", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Cursiva"; color: _colorText; font.pixelSize: 11; Layout.fillWidth: true }
                                    Switch {
                                        checked: root.activeBubble ? root.activeBubble.italic : false
                                        onCheckedChanged: root.updateBubbleProperty("italic", checked)
                                    }
                                }
                            }

                            // Text Color Presets
                            Text { text: "Color del Texto"; color: "#aaa"; font.pixelSize: 10 }
                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true
                                Repeater {
                                    model: ["#000000", "#ffffff", "#d32f2f", "#1a237e"]
                                    delegate: Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: modelData
                                        border.color: (root.activeBubble && root.activeBubble.textColor === modelData) ? _colorAccent : "#444"
                                        border.width: (root.activeBubble && root.activeBubble.textColor === modelData) ? 2 : 1
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.updateBubbleProperty("textColor", modelData)
                                        }
                                    }
                                }
                                Item { Layout.fillWidth: true }

                                // Alignments Segmented control
                                RowLayout {
                                    spacing: 2
                                    Repeater {
                                        model: [
                                            { id: Text.AlignLeft, symbol: "├" },
                                            { id: Text.AlignHCenter, symbol: "┼" },
                                            { id: Text.AlignRight, symbol: "┤" }
                                        ]
                                        delegate: Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: (root.activeBubble && root.activeBubble.alignment === modelData.id) ? Qt.rgba(_colorAccent.r, _colorAccent.g, _colorAccent.b, 0.2) : "#141416"
                                            border.color: (root.activeBubble && root.activeBubble.alignment === modelData.id) ? _colorAccent : _colorBorder
                                            border.width: 1
                                            Text { text: modelData.symbol; color: "white"; font.pixelSize: 11; anchors.centerIn: parent }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: root.updateBubbleProperty("alignment", modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // IF NO BUBBLE IS ACTIVE / SELECTED
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: !root.activeBubble

                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            color: "#1a1a1f"
                            radius: 8
                            border.color: _colorBorder
                            border.width: 1

                            Text {
                                text: "No hay ningún globo seleccionado.\nSelecciona uno del lienzo o crea uno nuevo:"
                                color: _colorTextMuted
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                anchors.centerIn: parent
                            }
                        }

                        // Presets Grid
                        GridLayout {
                            columns: 2
                            rowSpacing: 6
                            columnSpacing: 6
                            Layout.fillWidth: true

                            Repeater {
                                model: [
                                    { id: "bubble_speech", label: "Globo de Diálogo" },
                                    { id: "bubble_double_oval", label: "Doble Óvalo" },
                                    { id: "bubble_double_rounded", label: "Doble Redondo" },
                                    { id: "bubble_thought", label: "Pensamiento" },
                                    { id: "bubble_shout", label: "Grito" },
                                    { id: "bubble_narration", label: "Narración" }
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 72; radius: 8
                                    color: "#141416"
                                    border.color: bubMa.containsMouse ? _colorAccent : _colorBorder
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 2

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Canvas {
                                                anchors.centerIn: parent
                                                width: 44; height: 32
                                                onPaint: {
                                                    var ctx = getContext("2d")
                                                    var w = width, h = height
                                                    ctx.clearRect(0,0,w,h)
                                                    var bType = modelData.id.replace("bubble_", "")
                                                    ctx.fillStyle = "#2d2d34"
                                                    ctx.strokeStyle = "white"
                                                    ctx.lineWidth = 1.5
                                                    ctx.lineJoin = "round"
                                                    var cx = w/2, cy = h/2
                                                    if (bType === "speech" || bType === "oval") {
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.1, h*0.05, w*0.8, h*0.6)
                                                        ctx.fill(); ctx.stroke()
                                                        ctx.beginPath()
                                                        ctx.moveTo(w*0.25, h*0.58)
                                                        ctx.lineTo(w*0.15, h*0.92)
                                                        ctx.lineTo(w*0.45, h*0.58)
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "double_oval") {
                                                        ctx.beginPath()
                                                        ctx.ellipse(cx - w*0.1, cy - h*0.1, w*0.3, h*0.22)
                                                        ctx.ellipse(cx + w*0.1, cy + h*0.1, w*0.3, h*0.22)
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "double_rounded") {
                                                        ctx.beginPath()
                                                        ctx.rect(cx - w*0.35, cy - h*0.3, w*0.5, h*0.4)
                                                        ctx.rect(cx - w*0.15, cy - h*0.1, w*0.5, h*0.4)
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "thought") {
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.1, h*0.05, w*0.8, h*0.55)
                                                        ctx.fill(); ctx.stroke()
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.25, h*0.7, 3, 3)
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "shout") {
                                                        ctx.beginPath()
                                                        var pts = 12
                                                        for (var j = 0; j < pts; j++) {
                                                            var a = (j/pts)*Math.PI*2 - Math.PI/2
                                                            var r = (j%2===0) ? 1.0 : 0.6
                                                            var px = cx + Math.cos(a)*w*0.45*r
                                                            var py = cy + Math.sin(a)*h*0.45*r
                                                            if (j===0) ctx.moveTo(px,py); else ctx.lineTo(px,py)
                                                        }
                                                        ctx.closePath()
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "narration") {
                                                        ctx.fillRect(w*0.05, h*0.1, w*0.9, h*0.8)
                                                        ctx.strokeRect(w*0.05, h*0.1, w*0.9, h*0.8)
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.label
                                            Layout.alignment: Qt.AlignHCenter
                                            color: "#ccc"
                                            font.pixelSize: 8
                                            font.weight: Font.Medium
                                        }
                                    }

                                    MouseArea {
                                        id: bubMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var cx = mainCanvas ? mainCanvas.canvasWidth / 2 : 500
                                            var cy = mainCanvas ? mainCanvas.canvasHeight / 2 : 500
                                            if (typeof comicOverlay !== "undefined" && comicOverlay) {
                                                comicOverlay.addBubble(modelData.id.replace("bubble_", ""), cx, cy)
                                                if (typeof toastManager !== "undefined") {
                                                    toastManager.show("Globo unificado añadido", "success")
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

            // ==========================================
            // DEFAULT PLACEHOLDER FOR NO SETTINGS
            // ==========================================
            ColumnLayout {
                id: defaultPlaceholder
                width: parent.width
                spacing: 10
                visible: !root.isBrushTool && !root.isGradientTool && !root.isSelectionTool && !root.isFillTool && !root.isTransformTool && !root.isShapeTool

                Item { height: 20 }

                Text {
                    text: "☕"
                    font.pixelSize: 32
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Ajuste de herramienta"
                    color: _colorText
                    font.pixelSize: 12
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No hay opciones adicionales disponibles para la herramienta seleccionada."
                    color: _colorTextMuted
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
