import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
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
                    id: palettesView
                    ColumnLayout {
                        anchors.fill: parent; spacing: 10
                        Text { text: "Color Palettes"; color: "white"; font.pixelSize: 14; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                        
                        GridView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            cellWidth: width / 5; cellHeight: cellWidth
                            model: 20
                            delegate: Rectangle {
                                width: gridView.cellWidth - 8; height: width; radius: 6
                                color: Qt.hsva(index/20, 0.7, 0.8, 1.0)
                                border.color: "#30FFFFFF"; border.width: 1
                                MouseArea { anchors.fill: parent; onClicked: { root.h = index/20; root.s = 0.7; root.v = 0.8; root.updateColor() } }
                            }
                            id: gridView
                        }
                    }
                }
            }


        }
    }
}
