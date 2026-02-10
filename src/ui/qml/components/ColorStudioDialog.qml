import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import ArtFlow 1.0

Popup {
    id: root
    
    // --- DIMENSIONS & POPUP CONFIG ---
    width: 340
    height: viewStack.currentIndex === 2 ? 760 : 620
    
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    modal: false
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    margins: 10
    
    // --- THEME & COLORS ---
    property color accentColor: "#8E7CC3"  // Soft Purple
    property color bgColor: "#121214"      // Near Black
    property color panelColor: "#1C1C1E"   // Dark Gray
    property color borderColor: "#2C2C2E"
    property color textColor: "#FFFFFF"
    property color secondaryTextColor: "#8E8E93"

    // --- C++ BACKEND ---
    ColorPicker {
        id: backend
        activeColor: root.currentColor
    }

    // --- DATA BINDING ---
    property var targetCanvas: null
    property color currentColor: targetCanvas ? targetCanvas.brushColor : "#8E7CC3"
    property color secondaryColor: "#FFFFFF"
    
    property real h: 0.0
    property real s: 0.0
    property real v: 1.0
    
    Component.onCompleted: {
        h = currentColor.hsvHue
        s = currentColor.hsvSaturation
        v = currentColor.hsvValue
    }

    onCurrentColorChanged: {
        if (!internalUpdate) {
            h = currentColor.hsvHue
            s = currentColor.hsvSaturation
            v = currentColor.hsvValue
        }
    }

    property bool internalUpdate: false
    function updateColor() {
        internalUpdate = true
        var newColor = Qt.hsva(h, s, v, 1.0)
        currentColor = newColor
        if (targetCanvas) targetCanvas.brushColor = newColor
        internalUpdate = false
    }

    function addToHistory() {
        backend.addToHistory(currentColor)
    }

    function getCMYK() {
        var r = currentColor.r, g = currentColor.g, b = currentColor.b
        var k = 1.0 - Math.max(r, g, b)
        if (k >= 1.0) return {c:0, m:0, y:0, k:1}
        var c = (1.0 - r - k) / (1.0 - k)
        var m = (1.0 - g - k) / (1.0 - k)
        var y = (1.0 - b - k) / (1.0 - k)
        return {c: c, m: m, y: y, k: k}
    }

    function setCMYK(c, m, y, k) {
        var r = (1.0 - c) * (1.0 - k)
        var g = (1.0 - m) * (1.0 - k)
        var b = (1.0 - y) * (1.0 - k)
        currentColor = Qt.rgba(r, g, b, 1.0)
        h = currentColor.hsvHue
        s = currentColor.hsvSaturation
        v = currentColor.hsvValue
        if (targetCanvas) targetCanvas.brushColor = currentColor
    }

    signal colorSelected(color newColor)
    signal closeRequested()

    background: Rectangle {
        color: root.bgColor
        radius: 24
        border.color: root.borderColor
        border.width: 1
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 40; shadowColor: "#CC000000"; shadowVerticalOffset: 15 }
    }

    contentItem: Item {
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 0
            
            // ------------------------------------------------------------------
            // 1. HEADER
            // ------------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                RowLayout {
                    anchors.fill: parent
                    spacing: 12
                    Column {
                        Layout.fillWidth: true
                        Text { 
                            text: viewStack.currentIndex === 0 ? "Color Box" : 
                                  viewStack.currentIndex === 1 ? "Color Disc" : 
                                  viewStack.currentIndex === 2 ? "Color Sliders" : "Color Studio"
                            color: "white"
                            font.pixelSize: 18
                            font.weight: Font.Black 
                        }
                        Text { 
                            text: root.currentColor.toString().toUpperCase()
                            color: "#5E5E5E"
                            font.pixelSize: 10
                            font.family: "Monospace" 
                            visible: viewStack.currentIndex !== 2 // Hide in Sliders to match foto
                        }
                    }
                    Item {
                        width: 60; height: 40
                        Rectangle { width: 30; height: 30; radius: 15; color: root.secondaryColor; anchors.right: parent.right; anchors.bottom: parent.bottom; border.color: "#20FFFFFF"; border.width: 1.5; MouseArea { anchors.fill: parent; onClicked: { var t=root.currentColor; root.currentColor=root.secondaryColor; root.secondaryColor=t } } }
                        Rectangle { width: 38; height: 38; radius: 19; color: root.currentColor; anchors.left: parent.left; anchors.top: parent.top; border.color: "white"; border.width: 2.5 }
                    }
                    Text { text: "⋮"; color: "#666"; font.pixelSize: 22; Layout.alignment: Qt.AlignVCenter }
                }
            }
            
            // ------------------------------------------------------------------
            // 2. NAVIGATION ICONS (PREMIUM)
            // ------------------------------------------------------------------
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 55; Layout.topMargin: 10
                RowLayout {
                    anchors.fill: parent; spacing: 0
                    Repeater {
                        model: [{i: "▩", x: 0}, {i: "◎", x: 1}, {i: "⌥", x: 2}, {i: "⚲", x: 3}, {i: "🦋", x: 4}, {i: "◫", x: 5}]
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
                            Rectangle { visible: viewStack.currentIndex === modelData.x; anchors.centerIn: parent; width: 36; height: 36; radius: 10; color: "#252528"; border.color: "#303035"; border.width: 1 }
                            Text { text: modelData.i; color: viewStack.currentIndex === modelData.x ? root.accentColor : "#555"; font.pixelSize: 18; anchors.centerIn: parent }
                            MouseArea { anchors.fill: parent; onClicked: viewStack.currentIndex = modelData.x }
                        }
                    }
                }
            }
            
            // ------------------------------------------------------------------
            // 3. MAIN VIEWS
            // ------------------------------------------------------------------
            StackLayout {
                id: viewStack
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: 15
                
                // VIEW 0: COLOR BOX (REF FOTO 2)
                Item {
                    ColumnLayout {
                        anchors.fill: parent; spacing: 18
                        
                        // SV SQUARE (Rounded properly)
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: 18; clip: true; color: Qt.hsva(root.h, 1, 1, 1)
                            Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
                            Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
                            
                            // Cursor
                            Rectangle {
                                x: root.s * parent.width - 12; y: (1.0 - root.v) * parent.height - 12; width: 24; height: 24; radius: 12
                                color: "transparent"; border.color: "white"; border.width: 2.5
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: "transparent"; border.color: "black"; border.width: 1 }
                            }
                            MouseArea { anchors.fill: parent; onPressed: updatePos(mouse); onPositionChanged: if(pressed) updatePos(mouse)
                                function updatePos(m) { root.s = Math.max(0, Math.min(1, m.x/width)); root.v = Math.max(0, Math.min(1, 1.0-m.y/height)); root.updateColor() }
                                onReleased: root.addToHistory()
                            }
                        }
                        
                        // HUE SLIDER (PERFECCIONADO)
                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: 30
                            Rectangle {
                                width: parent.width; height: 6; radius: 3; anchors.centerIn: parent; clip: true
                                ShaderEffect {
                                    anchors.fill: parent
                                    fragmentShader: "
                                        varying highp vec2 qt_TexCoord0;
                                        uniform lowp float qt_Opacity;
                                        vec3 hsb2rgb(in vec3 c){
                                            vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
                                            rgb = rgb*rgb*(3.0-2.0*rgb);
                                            return c.z * mix(vec3(1.0), rgb, c.y);
                                        }
                                        void main(){ gl_FragColor = vec4(hsb2rgb(vec3(qt_TexCoord0.x, 1.0, 1.0)), 1.0) * qt_Opacity; }
                                    "
                                }
                            }
                            // Knob
                            Rectangle {
                                x: root.h * parent.width - 12; anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24; radius: 12; color: "white"
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: Qt.hsva(root.h,1,1,1); border.color: "black"; border.width: 1 }
                                layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 8; shadowColor: "#80000000" }
                            }
                            MouseArea { anchors.fill: parent; onPressed: uiHue(mouse); onPositionChanged: if(pressed) uiHue(mouse)
                                function uiHue(m) { root.h = Math.max(0, Math.min(1, m.x/width)); root.updateColor() }
                                onReleased: root.addToHistory()
                            }
                        }
                    }
                }
                
                // VIEW 1: PREMIUM COLOR WHEEL (FOTO 2 STYLE)
                Item {
                    id: wheelView
                    
                    Item {
                        width: Math.min(parent.width, parent.height) * 0.96
                        height: width
                        anchors.centerIn: parent
                        
                        // 1. Hue Ring (Premium Thinner version)
                        Canvas {
                            id: hueRingCanvas
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                
                                var cx = width / 2;
                                var cy = height / 2;
                                var outerRadius = width * 0.500; 
                                var innerRadius = width * 0.485; // Ultra thin (1.5% thickness)
                                
                                ctx.save();
                                ctx.translate(cx, cy);
                                ctx.scale(1, -1);
                                ctx.translate(-cx, -cy);
                                
                                var grad = ctx.createConicalGradient(cx, cy, 0); 
                                grad.addColorStop(0.000, Qt.hsva(0.000, 1, 1, 1));
                                grad.addColorStop(0.166, Qt.hsva(0.166, 1, 1, 1));
                                grad.addColorStop(0.333, Qt.hsva(0.333, 1, 1, 1));
                                grad.addColorStop(0.500, Qt.hsva(0.500, 1, 1, 1));
                                grad.addColorStop(0.666, Qt.hsva(0.666, 1, 1, 1));
                                grad.addColorStop(0.833, Qt.hsva(0.833, 1, 1, 1));
                                grad.addColorStop(1.000, Qt.hsva(1.000, 1, 1, 1));
                                
                                ctx.fillStyle = grad;
                                ctx.beginPath();
                                ctx.arc(cx, cy, outerRadius, 0, Math.PI * 2, false);
                                ctx.arc(cx, cy, innerRadius, 0, Math.PI * 2, true);
                                ctx.closePath();
                                ctx.fill();
                                ctx.restore();
                            }
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }
                        
                        // Hue Interaction
                        MouseArea {
                            anchors.fill: parent
                            function updateHue(m) {
                                var dx = m.x - width/2;
                                var dy = (height/2 - m.y); 
                                var d = Math.sqrt(dx*dx + dy*dy);
                                if (d > width * 0.43) { 
                                    var angle = Math.atan2(dy, dx); 
                                    var h = angle / (Math.PI * 2);
                                    if (h < 0) h += 1.0;
                                    root.h = (1.0 - h) % 1.0;
                                    root.updateColor();
                                }
                            }
                            onPressed: updateHue(mouse)
                            onPositionChanged: if(pressed) updateHue(mouse)
                            onReleased: root.addToHistory()
                        }
                        
                        // Hue Selector Knob
                        Rectangle {
                            width: 16; height: 16; radius: 8; color: "transparent"
                            border.color: "white"; border.width: 2.0
                            property real h_val: (1.0 - root.h) % 1.0
                            property real ang: -(h_val * Math.PI * 2) 
                            property real ringRadius: parent.width * 0.4925 // Perfectly centered on 0.485-0.500
                            x: (parent.width/2) + Math.cos(ang) * ringRadius - 8
                            y: (parent.height/2) + Math.sin(ang) * ringRadius - 8
                            Rectangle { anchors.fill: parent; anchors.margins: 2.0; radius: 6; color: "transparent"; border.color: "#80000000"; border.width: 1 }
                            layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 3; shadowColor: "#80000000" }
                        }
                        
                        // 2. Inner Disc (Large with CLEAR GAP and SHADOW)
                        Rectangle {
                            id: mainDisc
                            width: parent.width * 0.84; height: width; radius: width/2
                            anchors.centerIn: parent
                            color: Qt.hsva(root.h, 1, 1, 1)
                            clip: true
                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 14; shadowColor: "#80000000"; shadowVerticalOffset: 3 }
                            
                            Rectangle { anchors.fill: parent; radius: parent.radius; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
                            Rectangle { anchors.fill: parent; radius: parent.radius; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
                            Rectangle { anchors.fill: parent; radius: parent.radius; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0.0; color: "#60FFFFFF" } GradientStop { position: 0.4; color: "transparent" } GradientStop { position: 1.0; color: "#60000000" } } }
                            
                            // SV Selector
                            Rectangle {
                                id: selector
                                width: 24; height: 24; radius: 12; color: "transparent"
                                border.color: "white"; border.width: 2.5
                                Rectangle { anchors.fill: parent; anchors.margins: 2.5; radius: width/2; color: "transparent"; border.color: "#80000000"; border.width: 1 }
                                
                                property real cx: mainDisc.width/2
                                property real cy: mainDisc.height/2
                                property real mr: mainDisc.radius - 12
                                x: { var ix = root.s * mainDisc.width, iy = (1 - root.v) * mainDisc.height; var dx = ix - cx, dy = iy - cy, d = Math.sqrt(dx*dx + dy*dy); return (d > mr ? cx + (dx/d)*mr : ix) - 12 }
                                y: { var ix = root.s * mainDisc.width, iy = (1 - root.v) * mainDisc.height; var dx = ix - cx, dy = iy - cy, d = Math.sqrt(dx*dx + dy*dy); return (d > mr ? cy + (dy/d)*mr : iy) - 12 }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                function upSV(m) {
                                    root.s = Math.max(0, Math.min(1, m.x / width))
                                    root.v = Math.max(0, Math.min(1, 1.0 - m.y / height))
                                    root.updateColor()
                                }
                                onPressed: upSV(mouse)
                                onPositionChanged: if(pressed) upSV(mouse)
                                onReleased: root.addToHistory()
                            }
                        }
                    }
                }
                
                // VIEW 2: COLOR SLIDERS (ADVANCED PREMIUM VERSION)
                Item {
                    id: slidersView
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 0
                        spacing: 8
                        
                        // 1. HSB GROUP - Con gradientes vibrantes
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 110
                            color: "#161618"; radius: 12; border.color: "#252525"; border.width: 1
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 4
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "H"; value: root.h * 360; maxValue: 360; unit: "°"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => { root.h = val / 360; root.updateColor() }
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "S"; value: root.s; maxValue: 1.0; unit: "%"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => { root.s = val; root.updateColor() }
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "B"; value: root.v; maxValue: 1.0; unit: "%"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => { root.v = val; root.updateColor() }
                                }
                            }
                        }
                        
                        // 2. RGB GROUP - Con gradientes vibrantes
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 110
                            color: "#161618"; radius: 12; border.color: "#252525"; border.width: 1
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 4
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "R"; value: root.currentColor.r * 255; maxValue: 255; unit: ""
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => { 
                                        var c = root.currentColor; root.currentColor = Qt.rgba(val/255, c.g, c.b, 1.0)
                                        root.h = root.currentColor.hsvHue; root.s = root.currentColor.hsvSaturation; root.v = root.currentColor.hsvValue
                                    }
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "G"; value: root.currentColor.g * 255; maxValue: 255; unit: ""
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => { 
                                        var c = root.currentColor; root.currentColor = Qt.rgba(c.r, val/255, c.b, 1.0)
                                        root.h = root.currentColor.hsvHue; root.s = root.currentColor.hsvSaturation; root.v = root.currentColor.hsvValue
                                    }
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "B"; value: root.currentColor.b * 255; maxValue: 255; unit: ""
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => { 
                                        var c = root.currentColor; root.currentColor = Qt.rgba(c.r, c.g, val/255, 1.0)
                                        root.h = root.currentColor.hsvHue; root.s = root.currentColor.hsvSaturation; root.v = root.currentColor.hsvValue
                                    }
                                }
                            }
                        }
                        
                        // 3. CMYK GROUP - Con gradientes vibrantes
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 140
                            color: "#161618"; radius: 12; border.color: "#252525"; border.width: 1
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 4
                                property var cmyk: root.getCMYK()
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "C"; value: parent.cmyk.c; maxValue: 1.0; unit: "%"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => root.setCMYK(val, parent.cmyk.m, parent.cmyk.y, parent.cmyk.k)
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "M"; value: parent.cmyk.m; maxValue: 1.0; unit: "%"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => root.setCMYK(parent.cmyk.c, val, parent.cmyk.y, parent.cmyk.k)
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "Y"; value: parent.cmyk.y; maxValue: 1.0; unit: "%"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => root.setCMYK(parent.cmyk.c, parent.cmyk.m, val, parent.cmyk.k)
                                }
                                ImprovedColorSlider {
                                    Layout.fillWidth: true; label: "K"; value: parent.cmyk.k; maxValue: 1.0; unit: "%"
                                    currentH: root.h; currentS: root.s; currentV: root.v
                                    onSliderMoved: (val) => root.setCMYK(parent.cmyk.c, parent.cmyk.m, parent.cmyk.y, val)
                                }
                            }
                        }
                        
                        // 4. HEXADECIMAL
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 12; color: "#161618"; border.color: "#252525"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                                Text { text: "Hex Code"; color: "#8E8E93"; font.pixelSize: 10; font.weight: Font.Medium }
                                Item { Layout.fillWidth: true }
                                Rectangle { width: 28; height: 28; radius: 6; color: "transparent"; Text { text: "⎘"; color: "#5E5CE6"; anchors.centerIn: parent; font.pixelSize: 16 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor } }
                                Rectangle { width: 28; height: 28; radius: 6; color: "transparent"; Text { text: "❐"; color: "#5E5CE6"; anchors.centerIn: parent; font.pixelSize: 16 } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor } }
                                Rectangle {
                                    width: 80; height: 26; radius: 6; color: "#1C1C1E"; border.color: "#2C2C2E"
                                    TextInput {
                                        id: hexInput
                                        anchors.centerIn: parent
                                        text: "#" + root.currentColor.toString().toUpperCase().substring(1, 7)
                                        color: "white"; font.pixelSize: 10; font.family: "Monospace"; selectByMouse: true
                                        onEditingFinished: { root.currentColor = text; root.h = root.currentColor.hsvHue; root.s = root.currentColor.hsvSaturation; root.v = root.currentColor.hsvValue }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // ------------------------------------------------------------------
            // 4. FOOTER: SHADES / HISTORY / PALETTES (PERFECCIONADO)
            // ------------------------------------------------------------------
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 140; Layout.topMargin: 20
                ColumnLayout {
                    anchors.fill: parent; spacing: 12
                    
                    // Tab Buttons (Capsule style)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        spacing: 4
                        Repeater {
                            model: [{n: "Shades", x: 0}, {n: "History", x: 1}, {n: "Palettes", x: 2}]
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 16
                                color: footStack.currentIndex === modelData.x ? "#5E5CE6" : "#1A1A1C"
                                border.color: footStack.currentIndex === modelData.x ? "transparent" : "#2C2C2E"
                                border.width: 1
                                
                                Text { 
                                    text: modelData.n
                                    anchors.centerIn: parent
                                    color: footStack.currentIndex === modelData.x ? "white" : "#8E8E93"
                                    font.pixelSize: 11
                                    font.weight: footStack.currentIndex === modelData.x ? Font.Bold : Font.Medium
                                }
                                MouseArea { anchors.fill: parent; onClicked: footStack.currentIndex = modelData.x }
                            }
                        }
                    }
                    
                    StackLayout {
                        id: footStack; Layout.fillWidth: true; Layout.fillHeight: true
                        
                        // SHADES
                        Item {
                            RowLayout {
                                anchors.fill: parent; spacing: 3
                                Repeater {
                                    model: 10
                                    Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; radius: 6; color: Qt.hsva(root.h, root.s, (index+1)/10.0, 1.0); MouseArea { anchors.fill: parent; onClicked: { root.v = (index+1)/10.0; root.updateColor(); root.addToHistory() } } }
                                }
                            }
                        }
                        
                        // HISTORY
                        Item {
                            GridLayout { anchors.fill: parent; columns: 6; rowSpacing: 6; columnSpacing: 6
                                Repeater { model: backend.history
                                    Rectangle { Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 8; color: modelData; border.width: 1; border.color: "#30FFFFFF"; MouseArea { anchors.fill: parent; onClicked: root.currentColor = parent.color } }
                                }
                            }
                        }
                        
                        // PALETTES
                        Item { Text { text: "No Palettes Saved"; color: "#444"; anchors.centerIn: parent; font.pixelSize: 12 } }
                    }
                }
            }
        }
    }
}
