import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    
    property var targetCanvas: null
    property var mainCanvas: targetCanvas
    property var layerModel: targetCanvas ? targetCanvas.layerModel : null
    property color accentColor: "#6366f1"
    
    property var activeLayer: {
        if (!layerModel) return null;
        for (var i = 0; i < layerModel.length; ++i) { 
            if (layerModel[i].active) return layerModel[i]; 
        }
        return null;
    }
    
    readonly property int activeLayerId: activeLayer ? activeLayer.layerId : -1
    
    // Panel States
    property int activeTab: 0 // 0 = Ajustes de Color, 1 = Filtros Creativos
    property string activeSectionColor: "hsl" // "hsl", "gradient", "curves"
    property string activeSectionFilter: "screentone" // "screentone", "blur", "glow", "outline"
    
    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentHeight: contentCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            active: true
        }
        
        Column {
            id: contentCol
            width: parent.width - 4
            spacing: 14
            
            // ================= LAYER INFO HEADER =================
            Item {
                width: parent.width
                height: 18
                
                Rectangle {
                    id: indicator
                    width: 3
                    height: 14
                    radius: 1.5
                    color: root.accentColor
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: activeLayer ? "Capa Activa: " + activeLayer.name : "Seleccione una capa"
                    color: "#a0a0a5"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    anchors.left: indicator.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                }
            }
            
            Rectangle {
                width: parent.width
                height: 1
                color: "#202025"
            }
            
            // ================= PREMIUM TAB BAR (Segmented Control) =================
            Rectangle {
                width: parent.width
                height: 38
                radius: 19
                color: "#121215"
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                
                Row {
                    id: tabRow
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 0
                    
                    // Tab 0: Ajustes
                    Rectangle {
                        width: tabRow.width / 2
                        height: tabRow.height
                        radius: 16
                        color: root.activeTab === 0 ? root.accentColor : "transparent"
                        
                        Text {
                            text: "Ajustes de Color"
                            anchors.centerIn: parent
                            color: root.activeTab === 0 ? "white" : "#8e8e93"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 0
                        }
                    }
                    
                    // Tab 1: Filtros
                    Rectangle {
                        width: tabRow.width / 2
                        height: tabRow.height
                        radius: 16
                        color: root.activeTab === 1 ? root.accentColor : "transparent"
                        
                        Text {
                            text: "Filtros Creativos"
                            anchors.centerIn: parent
                            color: root.activeTab === 1 ? "white" : "#8e8e93"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 1
                        }
                    }
                }
            }
            
            Item { width: 1; height: 4 } // Small Spacer
            
            // ================= VIEW SWITCHER =================
            
            // ───────────────────────────────────────────────
            // VIEW A: AJUSTES DE COLOR
            // ───────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 12
                visible: root.activeTab === 0
                
                // --- SECTION 1: HSL ---
                CollapsibleCard {
                    title: "Tono, Saturación y Luminosidad (HSL)"
                    iconChar: "✦"
                    isExpanded: root.activeSectionColor === "hsl"
                    onHeaderClicked: root.activeSectionColor = (root.activeSectionColor === "hsl" ? "" : "hsl")
                    
                    StudioSlider {
                        id: hslHue
                        width: parent.width
                        label: "Tono (Hue)"
                        unit: "°"
                        value: 0.5
                        displayValue: Math.round(value * 360)
                        accent: root.accentColor
                    }
                    
                    StudioSlider {
                        id: hslSat
                        width: parent.width
                        label: "Saturación"
                        unit: "%"
                        value: 0.5
                        displayValue: Math.round((value - 0.5) * 200)
                        accent: root.accentColor
                    }
                    
                    StudioSlider {
                        id: hslLight
                        width: parent.width
                        label: "Luminosidad"
                        unit: "%"
                        value: 0.5
                        displayValue: Math.round((value - 0.5) * 200)
                        accent: root.accentColor
                    }
                    
                    Row {
                        width: parent.width
                        spacing: 8
                        
                        AppButtonCompact {
                            width: (parent.width - 8) / 2
                            text: "Restaurar"
                            isSecondary: true
                            onClicked: {
                                hslHue.value = 0.5
                                hslSat.value = 0.5
                                hslLight.value = 0.5
                            }
                        }
                        
                        AppButtonCompact {
                            width: (parent.width - 8) / 2
                            text: "Aplicar HSL"
                            onClicked: {
                                if (targetCanvas && activeLayerId !== -1) {
                                    var hDeg = Math.round(hslHue.value * 360);
                                    var sVal = (hslSat.value - 0.5) * 2.0; // -1.0 to 1.0
                                    var lVal = (hslLight.value - 0.5) * 2.0; // -1.0 to 1.0
                                    targetCanvas.applyEffect(activeLayerId, "hsl", {
                                        "hue": hDeg,
                                        "saturation": sVal + 1.0,
                                        "lightness": lVal + 1.0
                                    });
                                }
                            }
                        }
                    }
                }
                
                // --- SECTION 2: GRADIENT MAP (Simple Button) ---
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 10
                    color: (activeLayer && activeLayer.gradientMapEnabled) ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15) : "#16161a"
                    border.width: (activeLayer && activeLayer.gradientMapEnabled) ? 1.5 : 1
                    border.color: (activeLayer && activeLayer.gradientMapEnabled) ? root.accentColor : Qt.rgba(1,1,1,0.06)
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10
                        
                        // Gradient icon swatch
                        Rectangle {
                            width: 28
                            height: 16
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#764ba2" }
                                GradientStop { position: 0.5; color: "#ff7e5f" }
                                GradientStop { position: 1.0; color: "#feb47b" }
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "Mapa de Degradado"
                                color: (activeLayer && activeLayer.gradientMapEnabled) ? "white" : "#c8c8cd"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                            Text {
                                text: (activeLayer && activeLayer.gradientMapEnabled) ? "Activo · Toca para editar" : "Toca para activar"
                                color: (activeLayer && activeLayer.gradientMapEnabled) ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.8) : "#6b7280"
                                font.pixelSize: 9
                            }
                        }
                        
                        Item { Layout.fillWidth: true; width: 1 }
                    }
                    
                    // Chevron arrow on the right
                    Text {
                        text: "›"
                        color: "#6b7280"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (targetCanvas && root.activeLayerId !== -1) {
                                // Enable gradient map if not already
                                if (activeLayer && !activeLayer.gradientMapEnabled) {
                                    targetCanvas.setLayerGradientMapEnabled(root.activeLayerId, true)
                                }
                                // Signal main window to show the bottom gradient bar
                                if (typeof mainWindow !== "undefined") {
                                    mainWindow.showGradientMapUI = true
                                }
                                // Set tool to GRAD so they can draw coords
                                targetCanvas.currentTool = "GRAD"
                            }
                        }
                    }
                }
                
                
                // --- SECTION 3: CURVES ---
                CollapsibleCard {
                    title: "Curvas Tonales"
                    iconChar: "📈"
                    isExpanded: root.activeSectionColor === "curves"
                    onHeaderClicked: root.activeSectionColor = (root.activeSectionColor === "curves" ? "" : "curves")
                    
                    // Interactive Tone Curve Canvas
                    Rectangle {
                        width: 140
                        height: 140
                        radius: 8
                        color: "#0a0a0c"
                        border.color: "#202025"
                        border.width: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Canvas {
                            id: curveCanvas
                            anchors.fill: parent
                            anchors.margins: 4
                            
                            property real ctrlX: width / 2
                            property real ctrlY: height / 2
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                
                                // Draw grid
                                ctx.strokeStyle = "#1a1a1f";
                                ctx.lineWidth = 1;
                                for (var i = 1; i < 4; i++) {
                                    var gx = (width / 4) * i;
                                    var gy = (height / 4) * i;
                                    ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke();
                                    ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke();
                                }
                                
                                // Baseline (Diagonal)
                                ctx.strokeStyle = "#3a3a40";
                                ctx.lineWidth = 1;
                                ctx.setLineDash([3, 3]);
                                ctx.beginPath(); ctx.moveTo(0, height); ctx.lineTo(width, 0); ctx.stroke();
                                ctx.setLineDash([]);
                                
                                // Curved spline
                                ctx.strokeStyle = root.accentColor;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(0, height);
                                ctx.quadraticCurveTo(ctrlX, ctrlY, width, 0);
                                ctx.stroke();
                                
                                // Anchor Handle
                                ctx.fillStyle = root.accentColor;
                                ctx.beginPath(); ctx.arc(ctrlX, ctrlY, 5, 0, 2*Math.PI); ctx.fill();
                                ctx.strokeStyle = "white"; ctx.lineWidth = 1; ctx.stroke();
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                
                                function updatePos(mouse) {
                                    var px = Math.max(0, Math.min(parent.width, mouse.x));
                                    var py = Math.max(0, Math.min(parent.height, mouse.y));
                                    parent.ctrlX = px;
                                    parent.ctrlY = py;
                                    parent.requestPaint();
                                }
                                
                                onPressed: updatePos(mouse)
                                onPositionChanged: updatePos(mouse)
                            }
                        }
                    }
                    
                    Text {
                        width: parent.width
                        text: "Arrastra el punto para doblar la curva de brillo/contraste."
                        color: "#6b7280"
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                    
                    Row {
                        width: parent.width
                        spacing: 8
                        
                        AppButtonCompact {
                            width: (parent.width - 8) / 2
                            text: "Reset"
                            isSecondary: true
                            onClicked: {
                                curveCanvas.ctrlX = curveCanvas.width / 2
                                curveCanvas.ctrlY = curveCanvas.height / 2
                                curveCanvas.requestPaint()
                            }
                        }
                        
                        AppButtonCompact {
                            width: (parent.width - 8) / 2
                            text: "Aplicar Curva"
                            onClicked: {
                                if (targetCanvas && activeLayerId !== -1) {
                                    var bNorm = (curveCanvas.ctrlX / curveCanvas.width) - 0.5; // -0.5 to 0.5
                                    var cNorm = (1.0 - (curveCanvas.ctrlY / curveCanvas.height)) - 0.5; // -0.5 to 0.5
                                    targetCanvas.applyEffect(activeLayerId, "curves", {
                                        "brightness": bNorm,
                                        "contrast": cNorm
                                    });
                                }
                            }
                        }
                    }
                }
            }
            
            // ───────────────────────────────────────────────
            // VIEW B: FILTROS CREATIVOS
            // ───────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 12
                visible: root.activeTab === 1
                
                // --- SECTION 1: SCREENTONE (TRAMA) ---
                CollapsibleCard {
                    id: screentoneCard
                    title: "Trama de Semitonos (Manga)"
                    iconChar: "░"
                    isExpanded: root.activeSectionFilter === "screentone"
                    onHeaderClicked: root.activeSectionFilter = (root.activeSectionFilter === "screentone" ? "" : "screentone")
                    
                    Row {
                        width: parent.width
                        
                        Column {
                            width: parent.width - 50
                            spacing: 1
                            Text { text: "Activar Trama"; color: "white"; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: "Rápido y procesado por GPU"; color: "#6b7280"; font.pixelSize: 9 }
                        }
                        
                        Switch {
                            id: toneSwitch
                            width: 50
                            checked: activeLayer ? activeLayer.screentoneEnabled : false
                            enabled: activeLayer !== null
                            anchors.verticalCenter: parent.verticalCenter
                            onCheckedChanged: {
                                if (targetCanvas && activeLayerId !== -1) {
                                    targetCanvas.setLayerScreentoneEnabled(activeLayerId, checked)
                                }
                            }
                        }
                    }
                    
                    // Container inside screentone card when switch is active
                    Column {
                        width: parent.width
                        spacing: 14
                        visible: toneSwitch.checked
                        
                        Rectangle { width: parent.width; height: 1; color: "#202025" }
                        
                        // Type row (Circles, Lines, Noise)
                        Row {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: [
                                    { name: "Círculos", typeId: 0, icon: "●" },
                                    { name: "Líneas", typeId: 1, icon: "▤" },
                                    { name: "Ruido", typeId: 2, icon: "░" }
                                ]
                                delegate: Rectangle {
                                    width: (parent.width - 12) / 3
                                    height: 26
                                    radius: 13
                                    color: (activeLayer && activeLayer.screentoneType === modelData.typeId) ? root.accentColor : "#121215"
                                    border.color: (activeLayer && activeLayer.screentoneType === modelData.typeId) ? "transparent" : Qt.rgba(1,1,1,0.06)
                                    
                                    Text {
                                        text: modelData.icon + " " + modelData.name
                                        anchors.centerIn: parent
                                        color: (activeLayer && activeLayer.screentoneType === modelData.typeId) ? "white" : "#a0a0a5"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (targetCanvas && activeLayerId !== -1) {
                                                targetCanvas.setLayerScreentoneType(activeLayerId, modelData.typeId);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Sliders
                        StudioSlider {
                            id: sizeSlider
                            width: parent.width
                            label: activeLayer && activeLayer.screentoneType === 2 ? "Tamaño del Grano" : "Frecuencia (Tamaño)"
                            unit: "px"
                            value: activeLayer ? (activeLayer.screentoneDotSize - 4.0) / 46.0 : (12.0 - 4.0) / 46.0
                            displayValue: activeLayer ? activeLayer.screentoneDotSize : 12.0
                            decimals: 0
                            accent: root.accentColor
                            onMoved: (val) => {
                                if(targetCanvas && activeLayerId !== -1) {
                                    var actualSize = 4.0 + (val * 46.0)
                                    targetCanvas.setLayerScreentoneDotSize(activeLayerId, actualSize)
                                }
                            }
                        }
                        
                        StudioSlider {
                            id: angleSlider
                            width: parent.width
                            visible: activeLayer && activeLayer.screentoneType !== 2
                            label: "Ángulo"
                            unit: "°"
                            value: activeLayer ? (activeLayer.screentoneAngle * 180.0 / 3.14159) / 90.0 : 45.0 / 90.0
                            displayValue: activeLayer ? Math.round(activeLayer.screentoneAngle * 180.0 / 3.14159) : 45
                            decimals: 0
                            accent: root.accentColor
                            onMoved: (val) => {
                                if(targetCanvas && activeLayerId !== -1) {
                                    var actualAngleDeg = val * 90.0
                                    targetCanvas.setLayerScreentoneAngle(activeLayerId, actualAngleDeg * 3.14159 / 180.0)
                                }
                            }
                        }
                        
                        StudioSlider {
                            id: contrastSlider
                            width: parent.width
                            visible: activeLayer && activeLayer.screentoneType !== 2
                            label: "Contraste (Dureza)"
                            unit: "%"
                            value: activeLayer ? activeLayer.screentoneContrast : 0.8
                            displayValue: activeLayer ? Math.round(activeLayer.screentoneContrast * 100) : 80
                            decimals: 0
                            accent: root.accentColor
                            onMoved: (val) => {
                                if(targetCanvas && activeLayerId !== -1) {
                                    targetCanvas.setLayerScreentoneContrast(activeLayerId, val)
                                }
                            }
                        }
                        
                        Rectangle { width: parent.width; height: 1; color: "#202025" }
                        
                        Text { text: "Prediseñados rápidos:"; color: "#8e8e93"; font.pixelSize: 10 }
                        
                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 8
                            
                            Repeater {
                                model: [
                                    { title: "Manga 10%", type: 0, size: 8, angle: 45, contrast: 0.85 },
                                    { title: "Manga 30%", type: 0, size: 12, angle: 45, contrast: 0.85 },
                                    { title: "Manga 50%", type: 0, size: 18, angle: 45, contrast: 0.85 },
                                    { title: "Líneas 45°", type: 1, size: 10, angle: 45, contrast: 0.9 },
                                    { title: "Ruido Arena", type: 2, size: 8, angle: 0, contrast: 1.0 }
                                ]
                                delegate: Rectangle {
                                    width: (parent.width - 8) / 2
                                    height: 28
                                    radius: 5
                                    color: "#121215"
                                    border.width: 1
                                    border.color: Qt.rgba(1,1,1,0.06)
                                    
                                    Text {
                                        text: modelData.title
                                        anchors.centerIn: parent
                                        color: "#e4e4e7"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (targetCanvas && activeLayerId !== -1) {
                                                if (!activeLayer.screentoneEnabled) {
                                                    targetCanvas.setLayerScreentoneEnabled(activeLayerId, true);
                                                }
                                                targetCanvas.setLayerScreentoneType(activeLayerId, modelData.type);
                                                targetCanvas.setLayerScreentoneDotSize(activeLayerId, modelData.size);
                                                targetCanvas.setLayerScreentoneAngle(activeLayerId, modelData.angle * 3.14159 / 180.0);
                                                targetCanvas.setLayerScreentoneContrast(activeLayerId, modelData.contrast);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // --- SECTION 2: GAUSSIAN BLUR ---
                CollapsibleCard {
                    title: "Desenfoque Gaussiano"
                    iconChar: "💧"
                    isExpanded: root.activeSectionFilter === "blur"
                    onHeaderClicked: root.activeSectionFilter = (root.activeSectionFilter === "blur" ? "" : "blur")
                    
                    StudioSlider {
                        id: blurSigma
                        width: parent.width
                        label: "Intensidad de Desenfoque"
                        unit: "px"
                        value: 0.3
                        displayValue: Math.round(value * 50)
                        accent: root.accentColor
                    }
                    
                    AppButtonCompact {
                        width: parent.width
                        text: "Aplicar Desenfoque"
                        onClicked: {
                            if (targetCanvas && activeLayerId !== -1) {
                                var sigmaVal = Math.max(1, Math.round(blurSigma.value * 50));
                                targetCanvas.applyEffect(activeLayerId, "gaussian_blur", {
                                    "sigma": sigmaVal
                                });
                            }
                        }
                    }
                }
                
                // --- SECTION 3: GLOW / BLOOM ---
                CollapsibleCard {
                    title: "Brillo / Glow Inteligente"
                    iconChar: "🔆"
                    isExpanded: root.activeSectionFilter === "glow"
                    onHeaderClicked: root.activeSectionFilter = (root.activeSectionFilter === "glow" ? "" : "glow")
                    
                    StudioSlider {
                        id: glowIntensity
                        width: parent.width
                        label: "Intensidad de Brillo"
                        unit: "%"
                        value: 0.5
                        displayValue: Math.round(value * 100)
                        accent: root.accentColor
                    }
                    
                    StudioSlider {
                        id: glowRadius
                        width: parent.width
                        label: "Radio de Difusión"
                        unit: "px"
                        value: 0.4
                        displayValue: Math.round(value * 40)
                        accent: root.accentColor
                    }
                    
                    AppButtonCompact {
                        width: parent.width
                        text: "Aplicar Brillo"
                        onClicked: {
                            if (targetCanvas && activeLayerId !== -1) {
                                targetCanvas.applyEffect(activeLayerId, "glow", {
                                    "intensity": glowIntensity.value,
                                    "radius": Math.round(glowRadius.value * 40)
                                });
                            }
                        }
                    }
                }
                
                // --- SECTION 4: LAYER OUTLINE (BORDE DE CAPA) ---
                CollapsibleCard {
                    id: outlineCard
                    title: "Borde de Capa Automático"
                    iconChar: "⎔"
                    isExpanded: root.activeSectionFilter === "outline"
                    onHeaderClicked: root.activeSectionFilter = (root.activeSectionFilter === "outline" ? "" : "outline")
                    
                    property string selectedColor: "#ffffff"
                    
                    StudioSlider {
                        id: outlineWidth
                        width: parent.width
                        label: "Grosor del Borde"
                        unit: "px"
                        value: 0.25
                        displayValue: Math.round(value * 20)
                        accent: root.accentColor
                    }
                    
                    Text {
                        text: "Color del contorno:"
                        color: "#8e8e93"
                        font.pixelSize: 10
                    }
                    
                    Row {
                        spacing: 8
                        
                        Repeater {
                            model: ["#ffffff", "#000000", "#ff4a4a", "#4aff4a", "#4a4aff", "#ffd84a"]
                            delegate: Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: modelData
                                border.width: outlineCard.selectedColor === modelData ? 2 : 1
                                border.color: outlineCard.selectedColor === modelData ? root.accentColor : Qt.rgba(1,1,1,0.2)
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 8
                                    color: "transparent"
                                    border.color: "white"
                                    border.width: 1
                                    visible: outlineCard.selectedColor === modelData && modelData === "#000000"
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: outlineCard.selectedColor = modelData
                                }
                            }
                        }
                    }
                    
                    AppButtonCompact {
                        width: parent.width
                        text: "Aplicar Contorno"
                        onClicked: {
                            if (targetCanvas && activeLayerId !== -1) {
                                var wVal = Math.max(1, Math.round(outlineWidth.value * 20));
                                targetCanvas.applyEffect(activeLayerId, "outline", {
                                    "width": wVal,
                                    "color": outlineCard.selectedColor
                                });
                            }
                        }
                    }
                }
            }
            
            // Helpful selection reminder if no layer active
            Text {
                width: parent.width
                text: "Por favor cree o seleccione una capa para aplicar tramas o filtros."
                color: "#6b7280"
                font.pixelSize: 11
                visible: activeLayer === null
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // COMPONENTES AUXILIARES INLINE PARA MANTENER EL CODIGO LIMPIO
    // ─────────────────────────────────────────────────────────────

    // 1. Tarjeta Colapsable (Accordion Card)
    component CollapsibleCard : Rectangle {
        id: card
        property string title: ""
        property string iconChar: ""
        property bool isExpanded: false
        default property alias content: cardContent.data
        
        signal headerClicked()
        
        width: parent.width
        height: isExpanded ? (headerRow.height + cardContent.height + 24) : headerRow.height
        
        color: "#16161a" // Premium dark card background
        border.color: isExpanded ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3) : "#202025"
        border.width: 1
        radius: 10
        clip: true
        
        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }
        
        Item {
            id: headerRow
            width: parent.width
            height: 42
            anchors.top: parent.top
            
            Text {
                id: headerIcon
                text: iconChar
                color: isExpanded ? root.accentColor : "#8e8e93"
                font.pixelSize: 14
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                id: headerTitle
                text: title
                color: isExpanded ? "white" : "#e4e4e7"
                font.pixelSize: 12
                font.weight: Font.Bold
                anchors.left: headerIcon.right
                anchors.leftMargin: 10
                anchors.right: headerArrow.left
                anchors.rightMargin: 10
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                id: headerArrow
                text: isExpanded ? "▲" : "▼"
                color: "#6b7280"
                font.pixelSize: 9
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: headerClicked()
            }
        }
        
        // Content Container
        Column {
            id: cardContent
            anchors.top: headerRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 4
            visible: isExpanded
            opacity: isExpanded ? 1.0 : 0.0
            spacing: 14
            height: childrenRect.height
            
            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
        }
    }

    // 2. Botón Compacto Premium
    component AppButtonCompact : Rectangle {
        property string text: ""
        property bool isSecondary: false
        
        signal clicked()
        
        height: 28
        radius: 6
        color: isSecondary ? "transparent" : root.accentColor
        border.color: isSecondary ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        border.width: isSecondary ? 1 : 0
        
        Text {
            text: parent.text
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 10
            font.weight: Font.Bold
        }
        
        Rectangle {
            anchors.fill: parent; radius: 6
            color: "white"
            opacity: btnMa.containsMouse ? 0.08 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        
        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
