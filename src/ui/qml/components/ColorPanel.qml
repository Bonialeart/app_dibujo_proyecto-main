import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QtQuick.Dialogs
import ArtFlow 1.0

Item {
    id: root
    
    // --- PROPERTIES ---
    property var targetCanvas: null
    property color accentColor: (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#8E7CC3"
    property color currentColor: targetCanvas ? targetCanvas.brushColor : "#8E7CC3"
    
    // --- DUAL COLOR SYSTEM ---
    property int activeSlot: 0
    property bool isTransparent: false
    property color slot0Color: "#8E7CC3"
    property color slot1Color: "#FFFFFF"
    
    property real h: 0.0
    property real s: 0.0
    property real v: 1.0
    
    property bool internalUpdate: false

    // Color Logic
    onActiveSlotChanged: {
        if (!internalUpdate) {
            internalUpdate = true; isTransparent = false
            var col = (activeSlot === 0 ? slot0Color : slot1Color)
            h = col.hsvHue; s = col.hsvSaturation; v = col.hsvValue
            if (targetCanvas) targetCanvas.brushColor = col
            internalUpdate = false
        }
    }

    function updateColor() {
        if (internalUpdate) return
        internalUpdate = true
        var newColor = Qt.hsva(h, s, v, 1.0)
        if (activeSlot === 0) slot0Color = newColor; else slot1Color = newColor
        if (targetCanvas) {
            targetCanvas.brushColor = newColor
        }
        colorSelected(newColor)
        internalUpdate = false
    }

    function addToHistory() {
        if (!backend) return
        var c = root.currentColor
        backend.addToHistory(c)
    }

    signal colorSelected(color newColor)

    // --- C++ BACKEND ---
    ColorPicker {
        id: backend
        activeColor: root.currentColor
    }

    Rectangle {
        anchors.fill: parent
        color: "#121214"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 0
            
            // 1. HEADER (Title, Code, Wells)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                RowLayout {
                    anchors.fill: parent
                    spacing: 12
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        Text { 
                            text: root.currentColor.toString().toUpperCase()
                            color: "#5E5E5E"; font.pixelSize: 10; font.family: "Monospace"; font.weight: Font.Bold
                        }
                    }
                    
                    // Premium Dual Wells (Overlapping circles)
                    Item {
                        width: 70; height: 44
                        Rectangle {
                            id: sw1_bg
                            width: 32; height: 32; radius: 16
                            x: activeSlot === 1 ? 4 : 34; y: 6; z: activeSlot === 1 ? 2 : 1
                            color: root.slot1Color; border.color: activeSlot === 1 ? "white" : "#2A2A2E"; border.width: activeSlot === 1 ? 2.5 : 1.5
                            opacity: activeSlot === 1 ? 1.0 : 0.6; scale: activeSlot === 1 ? 1.15 : 0.85
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 250 } }
                            MouseArea { anchors.fill: parent; onClicked: activeSlot = 1 }
                        }
                        Rectangle {
                            id: sw0_bg
                            width: 32; height: 32; radius: 16
                            x: activeSlot === 0 ? 4 : 34; y: 6; z: activeSlot === 0 ? 2 : 1
                            color: root.slot0Color; border.color: activeSlot === 0 ? "white" : "#2A2A2E"; border.width: activeSlot === 0 ? 2.5 : 1.5
                            opacity: activeSlot === 0 ? 1.0 : 0.6; scale: activeSlot === 0 ? 1.15 : 0.85
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 250 } }
                            MouseArea { anchors.fill: parent; onClicked: activeSlot = 0 }
                        }
                    }
                    
                    Image {
                        source: "image://icons/grip.svg"; width: 22; height: 22; opacity: 0.5; Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // 2. MODE SELECTOR (Icons)
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 50
                RowLayout {
                    anchors.fill: parent; spacing: 0
                    Repeater {
                        model: [
                            {icon: "grid_pattern.svg", x: 0},
                            {icon: "shape.svg", x: 1}, 
                            {icon: "sliders.svg", x: 2}, 
                            {icon: "palette.svg", x: 3}
                        ]
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Rectangle {
                                visible: viewStack.currentIndex === modelData.x
                                anchors.centerIn: parent; width: 38; height: 38; radius: 10; color: "#252528"; border.color: "#3A3A3C"; border.width: 1
                            }
                            Image {
                                source: "image://icons/" + modelData.icon; width: 22; height: 22; anchors.centerIn: parent
                                opacity: viewStack.currentIndex === modelData.x ? 1.0 : 0.4
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: viewStack.currentIndex = modelData.x }
                        }
                    }
                }
            }

            // 3. MAIN CONTENT
            StackLayout {
                id: viewStack
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: 15
                currentIndex: 0
                
                // --- VIEW 0: BOX ---
                Item {
                    id: boxView
                    ColumnLayout {
                        anchors.fill: parent; spacing: 18
                        
                        Rectangle {
                            id: svSquare
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 20
                            color: Qt.hsva(root.h, 1, 1, 1)
                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 15; shadowColor: "#40000000"; shadowVerticalOffset: 4 }
                            
                            Rectangle { anchors.fill: parent; radius: 20; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
                            Rectangle { anchors.fill: parent; radius: 20; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
                            Rectangle { anchors.fill: parent; radius: 20; color: "transparent"; border.color: "#30FFFFFF"; border.width: 1 }
                            
                            // Cursor
                            Rectangle {
                                width: 24; height: 24; radius: 12; color: "transparent"; border.color: "white"; border.width: 2.5
                                x: (root.s * svSquare.width) - 12; y: ((1.0 - root.v) * svSquare.height) - 12
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: "transparent"; border.color: "black"; border.width: 1 }
                                layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 5; shadowColor: "#80000000" }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                function upSV(m) { root.s = Math.max(0, Math.min(1, m.x / width)); root.v = Math.max(0, Math.min(1, 1.0 - m.y / height)); root.updateColor() }
                                onPressed: upSV(mouse); onPositionChanged: if(pressed) upSV(mouse)
                            }
                        }
                        
                        // Hue Slider
                        Item {
                            id: hueSlider
                            Layout.fillWidth: true; Layout.preferredHeight: 32
                            Rectangle {
                                anchors.centerIn: parent; width: parent.width; height: 10; radius: 5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.00; color: "#FF0000" } GradientStop { position: 0.17; color: "#FFFF00" } GradientStop { position: 0.33; color: "#00FF00" }
                                    GradientStop { position: 0.50; color: "#00FFFF" } GradientStop { position: 0.67; color: "#0000FF" } GradientStop { position: 0.83; color: "#FF00FF" } GradientStop { position: 1.00; color: "#FF0000" }
                                }
                                border.color: "#20FFFFFF"; border.width: 1
                            }
                            // Knob
                            Rectangle {
                                width: 24; height: 24; radius: 12; color: "white"; anchors.verticalCenter: parent.verticalCenter
                                x: (root.h * hueSlider.width) - 12
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: Qt.hsva(root.h, 1, 1, 1); border.color: "black"; border.width: 1 }
                                layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 8; shadowColor: "#80000000" }
                            }
                            MouseArea {
                                anchors.fill: parent
                                function uiHue(m) { root.h = Math.max(0, Math.min(1, m.x / width)); root.updateColor() }
                                onPressed: uiHue(mouse); onPositionChanged: if(pressed) uiHue(mouse)
                            }
                        }
                    }
                }
                
                // --- VIEW 1: WHEEL ---
                Item {
                    id: wheelView
                    Item {
                        width: Math.min(parent.width, parent.height) * 0.96; height: width; anchors.centerIn: parent
                        Canvas {
                            id: hueRingCanvas; anchors.fill: parent; antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset(); ctx.clearRect(0,0,width,height); var cx=width/2, cy=height/2;
                                var outerR = width*0.5, innerR = width*0.42;
                                ctx.save(); ctx.translate(cx,cy); ctx.scale(1,-1); ctx.translate(-cx,-cy);
                                var grad = ctx.createConicalGradient(cx,cy,0);
                                grad.addColorStop(0.0,"#f00"); grad.addColorStop(0.166,"#ff0"); grad.addColorStop(0.333,"#0f0");
                                grad.addColorStop(0.5,"#0ff"); grad.addColorStop(0.666,"#00f"); grad.addColorStop(0.833,"#f0f"); grad.addColorStop(1.0,"#f00");
                                ctx.fillStyle=grad; ctx.beginPath(); ctx.arc(cx,cy,outerR,0,Math.PI*2,false); ctx.arc(cx,cy,innerR,0,Math.PI*2,true); ctx.closePath(); ctx.fill(); ctx.restore();
                            }
                            onWidthChanged: requestPaint()
                        }
                        MouseArea {
                            anchors.fill: parent
                            function upWheel(m) {
                                var dx=m.x-width/2, dy=height/2-m.y, d=Math.sqrt(dx*dx+dy*dy);
                                if(d>width*0.38) {
                                    var ang=Math.atan2(dy,dx), hh=ang/(Math.PI*2); if(hh<0) hh+=1.0;
                                    root.h=(1.0-hh)%1.0; root.updateColor()
                                }
                            }
                            onPressed: upWheel(mouse); onPositionChanged: if(pressed) upWheel(mouse)
                        }
                        // Inner
                        Rectangle {
                            width: parent.width*0.78; height: width; radius: width/2; anchors.centerIn: parent; color: Qt.hsva(root.h, 1, 1, 1); clip: true
                            Rectangle { anchors.fill: parent; radius: parent.radius; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
                            Rectangle { anchors.fill: parent; radius: parent.radius; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
                            // Knob
                            Rectangle {
                                width: 22; height: 22; radius: 11; border.color: "white"; border.width: 2.5; color: "transparent"
                                x: (root.s * parent.width) - 11; y: ((1.0 - root.v) * parent.height) - 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                function upSV(m) { root.s=Math.max(0,Math.min(1,m.x/width)); root.v=Math.max(0,Math.min(1,1-m.y/height)); root.updateColor() }
                                onPressed: upSV(mouse); onPositionChanged: if(pressed) upSV(mouse)
                            }
                        }
                    }
                }
                
                // --- VIEW 2: SLIDERS ---
                Item {
                    id: slidersView
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 12
                        
                        ImprovedColorSlider {
                            label: "H"; Layout.fillWidth: true
                            value: root.h * 360; maxValue: 360
                            currentH: root.h; currentS: root.s; currentV: root.v
                            onSliderMoved: (val) => { root.h = val / 360; root.updateColor() }
                        }
                        ImprovedColorSlider {
                            label: "S"; Layout.fillWidth: true
                            value: root.s * 100; maxValue: 100; unit: "%"
                            currentH: root.h; currentS: root.s; currentV: root.v
                            onSliderMoved: (val) => { root.s = val / 100; root.updateColor() }
                        }
                        ImprovedColorSlider {
                            label: "V"; Layout.fillWidth: true
                            value: root.v * 100; maxValue: 100; unit: "%"
                            currentH: root.h; currentS: root.s; currentV: root.v
                            onSliderMoved: (val) => { root.v = val / 100; root.updateColor() }
                        }
                        
                        Item { Layout.fillHeight: true } // Spacer
                    }
                }
                
                // --- VIEW 3: PALETTES ---
                Item {
                    id: palettesView3

                    property var paletteCategories: [
                        { name: "🌅 Sunsets",
                          colors: ["#FF6B35","#F7C59F","#FFBE0B","#FB5607","#FF006E",
                                   "#E8D5B0","#FCA652","#C84B31","#6C4A4A","#2C1810",
                                   "#FFDDB0","#FFA552","#FF7547","#CF4A3C","#8B2635"] },
                        { name: "🌃 Cyberpunk",
                          colors: ["#00F5FF","#FF00FF","#7B2FBE","#FF00A4","#00FF41",
                                   "#1A1A2E","#16213E","#0F3460","#E94560","#533483",
                                   "#FF6B6B","#4ECDC4","#FFE66D","#A8DADC","#264653"] },
                        { name: "✨ Neons",
                          colors: ["#FF4ECD","#9B5DE5","#F15BB5","#FEE440","#00BBF9",
                                   "#00F5D4","#FF6B9D","#C77DFF","#E0AAFF","#7B2FBE",
                                   "#3A0CA3","#4361EE","#4CC9F0","#F72585","#B5179E"] },
                        { name: "🌿 Forest",
                          colors: ["#2D6A4F","#40916C","#52B788","#74C69D","#95D5B2",
                                   "#38270E","#603813","#8B5E3C","#C4A882","#DEB887",
                                   "#1B4332","#081C15","#D4A847","#856A3E","#F1DFC4"] },
                        { name: "🌊 Ocean",
                          colors: ["#03045E","#023E8A","#0077B6","#0096C7","#00B4D8",
                                   "#48CAE4","#90E0EF","#ADE8F4","#CAF0F8","#FFFFFF",
                                   "#006994","#0A7EA4","#1292B4","#22B0CB","#3DCFE3"] },
                        { name: "❄️ Arctic",
                          colors: ["#E8F4F8","#D1ECF5","#AED9E0","#7EC8D9","#5BA4CF",
                                   "#B8D4E3","#9BC2D6","#7AAEC8","#5893B9","#3378A9",
                                   "#D6EAF8","#EBF5FB","#F0F3FF","#C8D8E8","#A8C0D6"] }
                    ]

                    property int selectedCategory: 0
                    property var extractedColors: []
                    property bool showImagePanel: false

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        // Tabs
                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            contentWidth: p3TabRow.implicitWidth
                            clip: true
                            flickableDirection: Flickable.HorizontalFlick

                            Row {
                                id: p3TabRow
                                spacing: 4

                                Repeater {
                                    model: palettesView3.paletteCategories.length + 1
                                    Rectangle {
                                        property bool isImg: index === palettesView3.paletteCategories.length
                                        property bool isActive: isImg ? palettesView3.showImagePanel
                                                                      : (!palettesView3.showImagePanel && palettesView3.selectedCategory === index)
                                        height: 26; width: p3lbl.implicitWidth + 14; radius: 13
                                        color: isActive ? root.accentColor : "#252528"
                                        border.color: isActive ? "transparent" : "#3A3A3C"; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 160 } }
                                        scale: isActive ? 1.05 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                                        Text {
                                            id: p3lbl
                                            text: isImg ? "🖼" :
                                                  index === 0 ? "Sunsets" : index === 1 ? "Cyberpunk" :
                                                  index === 2 ? "Neons" : index === 3 ? "Forest" :
                                                  index === 4 ? "Ocean" : "Arctic"
                                            font.pixelSize: 9; font.weight: Font.Bold
                                            color: "white"; anchors.centerIn: parent
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (isImg) palettesView3.showImagePanel = true
                                                else { palettesView3.showImagePanel = false; palettesView3.selectedCategory = index }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Themed swatches
                        GridView {
                            id: p3Grid
                            Layout.fillWidth: true; Layout.fillHeight: true
                            visible: !palettesView3.showImagePanel
                            clip: true
                            model: palettesView3.paletteCategories[palettesView3.selectedCategory].colors
                            property int cols: 5
                            cellWidth: Math.floor(width / cols); cellHeight: cellWidth

                            delegate: Item {
                                width: p3Grid.cellWidth; height: p3Grid.cellHeight
                                Rectangle {
                                    id: p3swatch
                                    anchors.fill: parent; anchors.margins: 3
                                    radius: 8; color: modelData
                                    border.color: "#25FFFFFF"; border.width: 1
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true; shadowBlur: 8
                                        shadowColor: modelData; shadowOpacity: 0.45; shadowVerticalOffset: 2
                                    }
                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onPressed: p3swatch.scale = 0.82
                                        onReleased: p3swatch.scale = 1.0
                                        onClicked: {
                                            var c = Qt.color(modelData)
                                            root.h = c.hsvHue; root.s = c.hsvSaturation; root.v = c.hsvValue
                                            root.updateColor()
                                        }
                                    }
                                }
                            }
                        }

                        // Image extraction
                        ColumnLayout {
                            visible: palettesView3.showImagePanel
                            Layout.fillWidth: true; Layout.fillHeight: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 100
                                radius: 12; color: "#1A1A1E"
                                border.color: p3drop.containsMouse ? root.accentColor : "#3A3A3C"; border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                clip: true

                                Column { anchors.centerIn: parent; spacing: 4; visible: p3img.source == ""
                                    Image { source: "image://icons/image.svg"; width: 24; height: 24; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.3 }
                                    Text { text: "Tap to pick image"; color: "#666"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                Image {
                                    id: p3img; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; source: ""; visible: source != ""
                                    onStatusChanged: { if (status === Image.Ready) palettesView3.extractColors(source) }
                                }
                                MouseArea { id: p3drop; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: p3fileDlg.open() }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 8; color: root.accentColor
                                opacity: p3loadMa.pressed ? 0.7 : 1.0; Behavior on opacity { NumberAnimation { duration: 100 } }
                                Text { text: p3img.source != "" ? "Change Image" : "Browse Image…"; color: "white"; font.pixelSize: 11; font.weight: Font.Bold; anchors.centerIn: parent }
                                MouseArea { id: p3loadMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p3fileDlg.open() }
                            }

                            Text {
                                text: palettesView3.isExtracting ? "🔍 Analizando…" :
                                      palettesView3.extractedColors.length > 0 ? "✅ Colores extraidos (" + palettesView3.extractedColors.length + ")" : "Selecciona una imagen para extraer colores"
                                color: palettesView3.isExtracting ? root.accentColor : "#666"; font.pixelSize: 10
                            }

                            GridView {
                                id: p3ExtGrid
                                Layout.fillWidth: true; Layout.fillHeight: true
                                visible: palettesView3.extractedColors.length > 0
                                clip: true; model: palettesView3.extractedColors
                                property int cols: 5; cellWidth: Math.floor(width / cols); cellHeight: cellWidth
                                delegate: Item {
                                    width: p3ExtGrid.cellWidth; height: p3ExtGrid.cellHeight
                                    Rectangle {
                                        id: p3exRect; anchors.fill: parent; anchors.margins: 3; radius: 8; color: modelData
                                        border.color: "#25FFFFFF"; border.width: 1
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onPressed: p3exRect.scale = 0.82; onReleased: p3exRect.scale = 1.0
                                            onClicked: {
                                                var c = modelData
                                                root.h = c.hsvHue; root.s = c.hsvSaturation; root.v = c.hsvValue
                                                root.updateColor()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    FileDialog {
                        id: p3fileDlg
                        title: "Select Image"
                        nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp *.webp *.gif)"]
                        fileMode: FileDialog.OpenFile
                        onAccepted: {
                            palettesView3.extractedColors = []
                            p3img.source = ""
                            p3img.source = selectedFile
                        }
                    }

                    property bool isExtracting: false

                    function extractColors(imgSource) {
                        palettesView3.isExtracting = true
                        palettesView3.extractedColors = []
                        Qt.callLater(function() {
                            var src = imgSource || p3img.source
                            var colors = backend.extractColorsFromImage(src.toString(), 15)
                            palettesView3.extractedColors = colors
                            palettesView3.isExtracting = false
                        })
                    }
                }
            }


        }
    }
}
