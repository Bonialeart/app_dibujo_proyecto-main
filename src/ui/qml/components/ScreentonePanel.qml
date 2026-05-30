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
    
    Flickable {
        anchors.fill: parent; anchors.margins: 12
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: 16
            
            // Header Info
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Rectangle {
                    width: 3; height: 14; radius: 1.5
                    color: root.accentColor
                }
                
                Text {
                    text: activeLayer ? "Capa Activa: " + activeLayer.name : "Seleccione una capa"
                    color: "#a0a0a5"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            
            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252a" }
            
            // Toggle row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Activar Trama"
                        color: "white"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Convierte escala de grises a semitonos"
                        color: "#6b7280"
                        font.pixelSize: 10
                    }
                }
                
                Switch {
                    id: toneSwitch
                    checked: activeLayer ? activeLayer.screentoneEnabled : false
                    enabled: activeLayer !== null
                    onCheckedChanged: {
                        if (targetCanvas && activeLayerId !== -1) {
                            targetCanvas.setLayerScreentoneEnabled(activeLayerId, checked)
                        }
                    }
                }
            }
            
            Rectangle { 
                Layout.fillWidth: true; height: 1; color: "#25252a"
                visible: toneSwitch.checked
            }
            
            // Pattern Type Selector (Capsule / Segmented Switch)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: toneSwitch.checked
                
                Text {
                    text: "Tipo de Trama"
                    color: "#a0a0a5"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 17
                        color: "#16161a"
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 2
                            
                            Repeater {
                                model: [
                                    { name: "Círculos", typeId: 0, icon: "●" },
                                    { name: "Líneas", typeId: 1, icon: "▤" },
                                    { name: "Ruido", typeId: 2, icon: "░" }
                                ]
                                
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 14
                                    color: (activeLayer && activeLayer.screentoneType === modelData.typeId) ? root.accentColor : "transparent"
                                    
                                    Rectangle {
                                        anchors.fill: parent; radius: 14
                                        color: "white"
                                        opacity: btnMouse.containsMouse && !(activeLayer && activeLayer.screentoneType === modelData.typeId) ? 0.05 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                    
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        
                                        Text {
                                            text: modelData.icon
                                            color: (activeLayer && activeLayer.screentoneType === modelData.typeId) ? "white" : "#a0a0a5"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: modelData.name
                                            color: (activeLayer && activeLayer.screentoneType === modelData.typeId) ? "white" : "#a0a0a5"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: btnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (targetCanvas && activeLayerId !== -1) {
                                                targetCanvas.setLayerScreentoneType(activeLayerId, modelData.typeId);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Rectangle { 
                Layout.fillWidth: true; height: 1; color: "#25252a"
                visible: toneSwitch.checked
            }
            
            // Advanced Sliders (Smart/Context-aware visibility)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: toneSwitch.checked
                
                // Dot Size (Frequency)
                // Min size: 4.0, Max size: 50.0. Range = 46.0
                StudioSlider {
                    id: sizeSlider
                    Layout.fillWidth: true
                    label: activeLayer && activeLayer.screentoneType === 2 ? "Tamaño del Grano (Ruido)" : "Frecuencia (Tamaño)"
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
                
                // Angle (Rotación) - Omit for Noise
                // Min angle: 0.0, Max angle: 90.0. Range = 90.0
                StudioSlider {
                    id: angleSlider
                    Layout.fillWidth: true
                    visible: activeLayer && activeLayer.screentoneType !== 2
                    label: "Ángulo"
                    unit: "°"
                    value: activeLayer ? (activeLayer.screentoneAngle * 180.0 / 3.14159) / 90.0 : 45.0 / 90.0
                    displayValue: activeLayer ? (activeLayer.screentoneAngle * 180.0 / 3.14159) : 45.0
                    decimals: 0
                    accent: root.accentColor
                    onMoved: (val) => {
                        if(targetCanvas && activeLayerId !== -1) {
                            var actualAngleDeg = val * 90.0
                            targetCanvas.setLayerScreentoneAngle(activeLayerId, actualAngleDeg * 3.14159 / 180.0)
                        }
                    }
                }
                
                // Hardness (Contrast) - Omit for Noise
                // Min: 0.0, Max: 1.0. Range = 1.0
                StudioSlider {
                    id: contrastSlider
                    Layout.fillWidth: true
                    visible: activeLayer && activeLayer.screentoneType !== 2
                    label: "Dureza (Contraste)"
                    unit: "%"
                    value: activeLayer ? activeLayer.screentoneContrast : 0.8
                    displayValue: activeLayer ? (activeLayer.screentoneContrast * 100) : 80
                    decimals: 0
                    accent: root.accentColor
                    onMoved: (val) => {
                        if(targetCanvas && activeLayerId !== -1) {
                            targetCanvas.setLayerScreentoneContrast(activeLayerId, val)
                        }
                    }
                }
            }
            
            Rectangle { 
                Layout.fillWidth: true; height: 1; color: "#25252a"
                visible: toneSwitch.checked
            }
            
            // Pre-established Manga Presets Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: toneSwitch.checked
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "Prediseñados (Manga Presets)"
                        color: "white"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 1; color: "#25252a"
                    }
                }
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10
                    
                    Repeater {
                        model: [
                            { title: "Trama 10% (Fina)", desc: "Puntos finos ideales para piel", type: 0, size: 8, angle: 45, contrast: 0.85, accent: "#818cf8" },
                            { title: "Trama 30% (Media)", desc: "Estándar de manga clásico", type: 0, size: 12, angle: 45, contrast: 0.85, accent: "#6366f1" },
                            { title: "Trama 50% (Gruesa)", desc: "Puntos anchos de alto contraste", type: 0, size: 18, angle: 45, contrast: 0.85, accent: "#4f46e5" },
                            { title: "Líneas Manga 45°", desc: "Trama lineal diagonal", type: 1, size: 10, angle: 45, contrast: 0.9, accent: "#10b981" },
                            { title: "Líneas Horizontales", desc: "Líneas rectas para texturas", type: 1, size: 12, angle: 0, contrast: 0.9, accent: "#059669" },
                            { title: "Sombras Arena (Fino)", desc: "Dither tipo arena para sombras", type: 2, size: 8, angle: 0, contrast: 1.0, accent: "#fbbf24" },
                            { title: "Grano Dither (Grueso)", desc: "Textura artística retro áspera", type: 2, size: 24, angle: 0, contrast: 1.0, accent: "#f59e0b" }
                        ]
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            radius: 10
                            color: "#16161a"
                            border.width: 1
                            
                            // Exact settings checking to mark the active preset card
                            property bool isPresetMatched: activeLayer && activeLayer.screentoneEnabled && 
                                activeLayer.screentoneType === modelData.type && 
                                Math.abs(activeLayer.screentoneDotSize - modelData.size) < 0.5 && 
                                (modelData.type === 2 || Math.abs((activeLayer.screentoneAngle * 180.0 / 3.14159) - modelData.angle) < 1.0)
                            
                            border.color: isPresetMatched ? modelData.accent : Qt.rgba(1, 1, 1, 0.08)
                            
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10
                                
                                // Procedural pattern thumbnail drawing inside QML
                                Rectangle {
                                    width: 36; height: 36; radius: 6
                                    color: "#0a0a0c"
                                    clip: true
                                    
                                    // Circle Pattern preview (type 0)
                                    Grid {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        rows: 3; columns: 3
                                        spacing: 4
                                        visible: modelData.type === 0
                                        Repeater {
                                            model: 9
                                            delegate: Rectangle {
                                                width: 4; height: 4; radius: 2
                                                color: isPresetMatched ? modelData.accent : "#71717a"
                                            }
                                        }
                                    }
                                    
                                    // Line Pattern preview (type 1)
                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 4
                                        visible: modelData.type === 1
                                        Repeater {
                                            model: 3
                                            delegate: Rectangle {
                                                width: parent.width; height: 2; radius: 1
                                                color: isPresetMatched ? modelData.accent : "#71717a"
                                                rotation: modelData.angle
                                            }
                                        }
                                    }
                                    
                                    // Noise Pattern preview (type 2)
                                    Grid {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        rows: 4; columns: 4
                                        spacing: 2
                                        visible: modelData.type === 2
                                        Repeater {
                                            model: 16
                                            delegate: Rectangle {
                                                width: 3; height: 3
                                                color: (index % 3 == 0 || index % 5 == 1) ? (isPresetMatched ? modelData.accent : "#71717a") : "transparent"
                                            }
                                        }
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    
                                    Text {
                                        text: modelData.title
                                        color: isPresetMatched ? "white" : "#e4e4e7"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }
                                    
                                    Text {
                                        text: modelData.desc
                                        color: "#71717a"
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.scale = 1.02
                                onExited: parent.scale = 1.0
                                onPressed: parent.scale = 0.97
                                onReleased: parent.scale = hoverEnabled ? 1.02 : 1.0
                                
                                onClicked: {
                                    if (targetCanvas && activeLayerId !== -1) {
                                        if (!activeLayer.screentoneEnabled) {
                                            targetCanvas.setLayerScreentoneEnabled(activeLayerId, true);
                                        }
                                        targetCanvas.setLayerScreentoneType(activeLayerId, modelData.type);
                                        targetCanvas.setLayerScreentoneDotSize(activeLayerId, modelData.size);
                                        var radAngle = modelData.angle * 3.14159 / 180.0;
                                        targetCanvas.setLayerScreentoneAngle(activeLayerId, radAngle);
                                        targetCanvas.setLayerScreentoneContrast(activeLayerId, modelData.contrast);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // If layer is null, show a helpful message
            Text {
                text: "Por favor cree o seleccione una capa para aplicar tramas."
                color: "#6b7280"
                font.pixelSize: 11
                visible: activeLayer === null
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }
}
