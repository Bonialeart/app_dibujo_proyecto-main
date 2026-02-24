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
    property real yOffset: 0
    
    // --- POSITIONING ---
    // Margin 0 at top to allow precise positioning from parent
    topMargin: 0
    leftMargin: 10
    rightMargin: 10
    bottomMargin: 10
    
    // Elegant entrance/exit (using yOffset to avoid binding drift)
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
            NumberAnimation { property: "yOffset"; from: -30; to: 0; duration: 500; easing.type: Easing.OutBack }
            NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 450; easing.type: Easing.OutQuart }
        }
    }
    
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { property: "yOffset"; from: 0; to: -20; duration: 300; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: 250; easing.type: Easing.InCubic }
        }
    }
    
    // --- THEME & COLORS ---
    property color accentColor: (typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#8E7CC3"
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
    
    // --- DUAL COLOR SYSTEM ---
    property int activeSlot: 0
    property bool isTransparent: false
    property color slot0Color: "#8E7CC3"
    property color slot1Color: "#FFFFFF"
    
    property real h: 0.0
    property real s: 0.0
    property real v: 1.0
    
    property string harmonyMode: "Complementary"
    property var harmonyColors: []
    
    onActiveSlotChanged: {
        if (!internalUpdate) {
            internalUpdate = true
            isTransparent = false // Switching slots disables transparency
            var col = (activeSlot === 0 ? slot0Color : slot1Color)
            h = col.hsvHue
            s = col.hsvSaturation
            v = col.hsvValue
            // Update canvas AND parent-level currentColor if they exist
            if (targetCanvas) targetCanvas.brushColor = col
            internalUpdate = false
        }
    }

    onIsTransparentChanged: {
        if (!internalUpdate) {
            updateColor()
        }
    }
    
    Component.onCompleted: {
        h = currentColor.hsvHue
        s = currentColor.hsvSaturation
        v = currentColor.hsvValue
        slot0Color = currentColor
    }

    onCurrentColorChanged: {
        if (!internalUpdate) {
            h = currentColor.hsvHue
            s = currentColor.hsvSaturation
            v = currentColor.hsvValue
            if (activeSlot === 0) slot0Color = currentColor
            else slot1Color = currentColor
        }
    }

    property bool internalUpdate: false
    function updateColor() {
        if (internalUpdate) return
        internalUpdate = true
        
        var newColor = Qt.hsva(h, s, v, 1.0)
        
        if (activeSlot === 0) slot0Color = newColor
        else slot1Color = newColor
        
        if (targetCanvas) {
            if (isTransparent) {
                targetCanvas.isEraser = true
                targetCanvas.brushColor = "transparent"
            } else {
                targetCanvas.isEraser = false
                targetCanvas.brushColor = newColor
            }
        }
        
        colorSelected(newColor)
        internalUpdate = false
    }

    // --- SIGNAL CONNECTIONS ---
    Connections {
        target: root.targetCanvas
        function onStrokeStarted(col) {
            root.addToHistory()
        }
    }

    function addToHistory() {
        var c = root.currentColor
        // Use C++ colorHarmony for efficient hex-rounded comparison
        if (colorHarmony.isInList(c, backend.history)) {
            return // Duplicate detected, skip
        }
        backend.addToHistory(c)
    }

    function getCMYK() {
        // Delegated to C++ colorHarmony for exact same result, faster
        return colorHarmony.rgbToCMYK(currentColor)
    }

    function setCMYK(c, m, y, k) {
        var col = colorHarmony.cmykToRGB(c, m, y, k)
        currentColor = col
        h = col.hsvHue
        s = col.hsvSaturation
        v = col.hsvValue
        if (targetCanvas) targetCanvas.brushColor = col
    }

    onHChanged: updateHarmony()
    onSChanged: updateHarmony()
    onVChanged: updateHarmony() // Value might affect harmony color appearance
    onHarmonyModeChanged: updateHarmony()
    
    function updateHarmony() {
        // Delegated to C++ colorHarmony — returns QVariantList of QColors
        harmonyColors = colorHarmony.getHarmonyColors(root.h, root.s, root.v, harmonyMode)
    }

    signal colorSelected(color newColor)
    signal closeRequested()

    background: Rectangle {
        color: "#E6121214" // Slightly translucent for glass effect
        radius: 28
        border.color: "#3A3A3C"
        border.width: 1.5
        
        transform: Translate { y: root.yOffset }
        
        // Premium Linear Gradient for the background depth
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1C1C1E" }
            GradientStop { position: 1.0; color: "#121214" }
        }

        layer.enabled: true
        layer.effect: MultiEffect { 
            shadowEnabled: true 
            shadowBlur: 50 
            shadowColor: "#E0000000" 
            shadowVerticalOffset: 20 
        }
        
        // Subtle highlight line at the very top edge
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            radius: parent.radius
            color: "#40FFFFFF"
        }
    }

    contentItem: Item {
        transform: Translate { y: root.yOffset }
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
                                  viewStack.currentIndex === 2 ? "Color Sliders" : 
                                  viewStack.currentIndex === 3 ? "Color Harmony" : "Color Studio"
                            color: "white"
                            font.pixelSize: 18
                            font.weight: Font.Black 
                        }
                        Text { 
                            text: root.currentColor.toString().toUpperCase()
                            color: "#5E5E5E"
                            font.pixelSize: 10
                            font.family: "Monospace" 
                            visible: viewStack.currentIndex !== 2 && viewStack.currentIndex !== 3
                        }
                    }
                    
                    // --- HARMONY MODE MENU (Three Dots) ---
                    Rectangle {
                        visible: viewStack.currentIndex === 3
                        width: 32; height: 32; radius: 8; color: "transparent"
                        Text { text: "•••"; color: "white"; font.pixelSize: 20; anchors.centerIn: parent }
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: harmonyMenu.open()
                        }
                        Menu {
                            id: harmonyMenu
                            y: 35
                            MenuItem { text: "Complementary"; onTriggered: root.harmonyMode = "Complementary" }
                            MenuItem { text: "Split Complementary"; onTriggered: root.harmonyMode = "Split Complementary" }
                            MenuItem { text: "Analogous"; onTriggered: root.harmonyMode = "Analogous" }
                            MenuItem { text: "Triadic"; onTriggered: root.harmonyMode = "Triadic" }
                            MenuItem { text: "Square"; onTriggered: root.harmonyMode = "Square" }
                        }
                    }

                    // --- PREMIUM DUAL COLOR WELLS ---
                    Item {
                        width: 76; height: 44
                        
                        // Slot 1 (Secondary/Back)
                        Rectangle {
                            id: well1
                            width: 32; height: 32; radius: 16
                            x: activeSlot === 1 ? 4 : 36
                            y: activeSlot === 1 ? 4 : 8
                            z: activeSlot === 1 ? 10 : 5
                            
                            color: root.slot1Color
                            border.color: activeSlot === 1 ? "white" : "#20FFFFFF"
                            border.width: activeSlot === 1 ? 2.5 : 1.5
                            opacity: activeSlot === 1 ? 1.0 : 0.6
                            
                            Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            
                            scale: activeSlot === 1 ? 1.15 : 0.85
                            
                            layer.enabled: activeSlot === 1
                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 12; shadowColor: "#A0000000" }
                            
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (activeSlot !== 1) {
                                        activeSlot = 1
                                        root.internalUpdate = true
                                        root.h = root.slot1Color.hsvHue
                                        root.s = root.slot1Color.hsvSaturation
                                        root.v = root.slot1Color.hsvValue
                                        if (root.targetCanvas) root.targetCanvas.brushColor = root.slot1Color
                                        root.internalUpdate = false
                                    }
                                }
                            }
                        }
                        
                        // Slot 0 (Primary/Front)
                        Rectangle {
                            id: well0
                            width: 32; height: 32; radius: 16
                            x: activeSlot === 0 ? 4 : 36
                            y: activeSlot === 0 ? 4 : 8
                            z: activeSlot === 0 ? 10 : 5
                            
                            color: root.slot0Color
                            border.color: activeSlot === 0 ? "white" : "#20FFFFFF"
                            border.width: activeSlot === 0 ? 2.5 : 1.5
                            opacity: activeSlot === 0 ? 1.0 : 0.6
                            
                            Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            scale: activeSlot === 0 ? 1.15 : 0.85
                            
                            layer.enabled: activeSlot === 0
                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 12; shadowColor: "#A0000000" }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (activeSlot !== 0) {
                                        activeSlot = 0
                                        root.internalUpdate = true
                                        root.h = root.slot0Color.hsvHue
                                        root.s = root.slot0Color.hsvSaturation
                                        root.v = root.slot0Color.hsvValue
                                        if (root.targetCanvas) root.targetCanvas.brushColor = root.slot0Color
                                        root.internalUpdate = false
                                    } else {
                                        root.addToHistory()
                                        saveAnim.restart()
                                    }
                                }
                                SequentialAnimation {
                                    id: saveAnim
                                    NumberAnimation { target: well0; property: "scale"; from: 1.15; to: 1.4; duration: 100 }
                                    NumberAnimation { target: well0; property: "scale"; from: 1.4; to: 1.15; duration: 150 }
                                }
                            }
                        }
                        
                            // Swap Micro-Button
                        Rectangle {
                            id: swapBtnRect
                            width: 20; height: 20; radius: 10
                            color: "#2C2C2E"
                            border.color: "#3A3A3C"
                            anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: -2
                            z: 25
                            
                            Image {
                                source: "image://icons/rotate.svg"
                                width: 12; height: 12
                                anchors.centerIn: parent
                                opacity: 0.9
                            }
                            
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var t = root.slot0Color
                                    root.slot0Color = root.slot1Color
                                    root.slot1Color = t
                                    
                                    // Refresh logic for active slot
                                    root.internalUpdate = true
                                    var activeCol = (activeSlot === 0 ? root.slot0Color : root.slot1Color)
                                    root.h = activeCol.hsvHue
                                    root.s = activeCol.hsvSaturation
                                    root.v = activeCol.hsvValue
                                    if (root.targetCanvas) root.targetCanvas.brushColor = activeCol
                                    root.internalUpdate = false
                                    
                                    swapPulse.restart()
                                }
                                onPressed: swapBtnRect.scale = 0.8
                                onReleased: swapBtnRect.scale = 1.0
                            }
                            SequentialAnimation {
                                id: swapPulse
                                NumberAnimation { target: swapBtnRect; property: "rotation"; from: 0; to: 180; duration: 300; easing.type: Easing.OutBack }
                                PropertyAction { target: swapBtnRect; property: "rotation"; value: 0 }
                            }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }
                    Image {
                        source: "image://icons/grip.svg"
                        width: 20; height: 20
                        Layout.alignment: Qt.AlignVCenter
                        opacity: 0.6
                    }
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
                        // Icons: Box (App Store/Grid), Disc (Circle), Sliders, Picker, Harmony/Butterfly, Library
                        // Mapping: 0=Box, 1=Disc, 2=Sliders, 3=Picker(TBD), 4=Harmony(TBD), 5=Library
                        model: [
                            {icon: "grid_pattern.svg", x: 0},
                            {icon: "shape.svg", x: 1}, 
                            {icon: "sliders.svg", x: 2}, 
                            {icon: "ghost.svg", x: 3}, // Harmony (Fourth Icon)
                            {icon: "eyedropper.svg", x: 4}, // Picker moved
                            {icon: "palette.svg", x: 5}
                        ]
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
                            
                            // Active Indicator Background
                            Rectangle { 
                                visible: viewStack.currentIndex === modelData.x
                                anchors.centerIn: parent
                                width: 36; height: 36; radius: 10
                                color: "#252528"
                                border.color: "#303035"
                                border.width: 1 
                            }
                            
                            Image {
                                source: "image://icons/" + modelData.icon
                                width: 22; height: 22
                                anchors.centerIn: parent
                                opacity: viewStack.currentIndex === modelData.x ? 1.0 : 0.5
                                // Phosphor icons are white by default now, so opacity handles 'gray' look
                            }
                            
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
                                id: svSquare
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: 20
                            color: Qt.hsva(root.h, 1, 1, 1)
                            
                            // Forzamos el redondeo premium asegurando que el efecto de sombra no oculte el contenido
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 15
                                shadowColor: "#40000000"
                                shadowVerticalOffset: 4
                            }
                            
                            // Capa de Saturación (Blanco a Transparente)
                            Rectangle { 
                                anchors.fill: parent
                                radius: 20
                                gradient: Gradient { 
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "white" } 
                                    GradientStop { position: 1; color: "transparent" } 
                                } 
                            }
                            
                            // Capa de Valor (Transparente a Negro)
                            Rectangle { 
                                anchors.fill: parent
                                radius: 20
                                gradient: Gradient { 
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" } 
                                    GradientStop { position: 1; color: "black" } 
                                } 
                            }
                            
                            // Borde sutil interno para premium feel
                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: "transparent"
                                border.color: "#30FFFFFF"
                                border.width: 1
                            }
                            
                            // Cursor (Constreñido para que no se salga nunca)
                            Rectangle {
                                x: root.s * (parent.width - 24)
                                y: (1.0 - root.v) * (parent.height - 24)
                                width: 24; height: 24; radius: 12
                                color: "transparent"; border.color: "white"; border.width: 2.5
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: "transparent"; border.color: "black"; border.width: 1 }
                                layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 5; shadowColor: "#80000000" }
                            }
                            
                            MouseArea { 
                                anchors.fill: parent; onPressed: updatePos(mouse); onPositionChanged: if(pressed) updatePos(mouse)
                                function updatePos(m) { root.s = Math.max(0, Math.min(1, m.x/width)); root.v = Math.max(0, Math.min(1, 1.0-m.y/height)); root.updateColor() }
                            }
                        }
                        
                        // HUE SLIDER (PERFECCIONADO CON GRADIENTE REAL)
                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: 32
                            Rectangle {
                                width: parent.width; height: 10; radius: 5; anchors.centerIn: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.00; color: "#FF0000" }
                                    GradientStop { position: 0.17; color: "#FFFF00" }
                                    GradientStop { position: 0.33; color: "#00FF00" }
                                    GradientStop { position: 0.50; color: "#00FFFF" }
                                    GradientStop { position: 0.67; color: "#0000FF" }
                                    GradientStop { position: 0.83; color: "#FF00FF" }
                                    GradientStop { position: 1.00; color: "#FF0000" }
                                }
                                border.color: "#20FFFFFF"
                                border.width: 1
                            }
                            // Knob (Constreñido para que no se salga del slider)
                            Rectangle {
                                x: root.h * (parent.width - 24)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24; radius: 12; color: "white"
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: Qt.hsva(root.h,1,1,1); border.color: "black"; border.width: 1 }
                                layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 8; shadowColor: "#80000000" }
                            }
                            MouseArea { anchors.fill: parent; onPressed: uiHue(mouse); onPositionChanged: if(pressed) uiHue(mouse)
                                function uiHue(m) { root.h = Math.max(0, Math.min(1, m.x/width)); root.updateColor() }
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
                                ctx.clearRect(0, 0, width, height);
                                
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
                            onReleased: {
                                // Manual history is now handled by painting or direct click
                            }
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
                                onReleased: {
                                    // Manual history is now handled by painting or direct click
                                }
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
                        
                        // 3. CMYK GROUP
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
                        
                        // Hex Code Row
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 12; color: "#161618"; border.color: "#252525"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                                Text { text: "Hex Code"; color: "#8E8E93"; font.pixelSize: 10; font.weight: Font.Medium }
                                Item { Layout.fillWidth: true }
                                Rectangle { 
                                    width: 28; height: 28; radius: 6; color: "transparent"; 
                                    Image { source: "image://icons/copy.svg"; width: 16; height: 16; anchors.centerIn: parent; opacity: 0.8 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor } 
                                }
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
                
                // VIEW 3: COLOR HARMONY
                Item {
                    id: harmonyView
                    ColumnLayout {
                        anchors.fill: parent; spacing: 20
                        
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Rectangle {
                                id: harmonyDisc
                                width: Math.min(parent.width, parent.height) * 0.95; height: width
                                anchors.centerIn: parent
                                radius: width/2; clip: true
                                color: "transparent"
                                
                                Canvas {
                                    anchors.fill: parent; antialiasing: true; smooth: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        var cx = width/2, cy = height/2, r = width/2;
                                        ctx.reset();
                                        ctx.clearRect(0, 0, width, height);
                                        
                                        var hueGrad = ctx.createConicalGradient(cx, cy, 0);
                                        for(var i=0; i<=1.0; i+=0.1) hueGrad.addColorStop(i, Qt.hsva(i, 1, 1, 1));
                                        ctx.fillStyle = hueGrad;
                                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2*Math.PI); ctx.fill();
                                        
                                        var satGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
                                        satGrad.addColorStop(0, "white");
                                        satGrad.addColorStop(1, "transparent");
                                        ctx.fillStyle = satGrad;
                                        ctx.fill();
                                    }
                                }
                                
                                Rectangle { anchors.fill: parent; radius: parent.radius; color: "black"; opacity: 1.0 - root.v }
                                
                                // Drag Logic for primary reticle
                                MouseArea {
                                    anchors.fill: parent
                                    function handleMouse(m) {
                                        var dx = m.x - width/2, dy = m.y - height/2
                                        var theta = Math.atan2(dy, dx)
                                        var hVal = -theta / (2*Math.PI); if (hVal < 0) hVal += 1.0
                                        var dist = Math.sqrt(dx*dx + dy*dy)
                                        var sVal = Math.min(1.0, dist / (width/2))
                                        root.h = hVal; root.s = sVal; root.updateColor()
                                    }
                                    onPressed: handleMouse(mouse)
                                    onPositionChanged: if(pressed) handleMouse(mouse)
                                }

                                // Secondary Reticles
                                Repeater {
                                    model: root.harmonyColors.length - 1
                                    Rectangle {
                                        property color col: root.harmonyColors[index+1]
                                        property real ang: -(col.hsvHue * 2 * Math.PI)
                                        width: 22; height: 22; radius: 11; color: "transparent"; border.color: "white"; border.width: 2; opacity: 0.7
                                        x: (harmonyDisc.width/2) + (root.s * harmonyDisc.width/2 * Math.cos(ang)) - 11
                                        y: (harmonyDisc.height/2) + (root.s * harmonyDisc.height/2 * Math.sin(ang)) - 11
                                    }
                                }
                                
                                // Primary Reticle
                                Rectangle {
                                    width: 32; height: 32; radius: 16; color: "transparent"; border.color: "white"; border.width: 3
                                    property real ang: -(root.h * 2 * Math.PI)
                                    x: (harmonyDisc.width/2) + (root.s * harmonyDisc.width/2 * Math.cos(ang)) - 16
                                    y: (harmonyDisc.height/2) + (root.s * harmonyDisc.height/2 * Math.sin(ang)) - 16
                                    layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 10; shadowColor: "#80000000" }
                                    Rectangle { anchors.centerIn: parent; width: 24; height: 24; radius: 12; color: "transparent"; border.color: "black"; border.width: 1 }
                                }
                            }
                        }
                        // Brush Config (Renamed from Settings)
                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: 30
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 10; radius: 5
                                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "black" } GradientStop { position: 1; color: "white" } }
                            }
                            Rectangle {
                                x: root.v * (parent.width - 24)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24; radius: 12; color: "white"; border.color: root.accentColor; border.width: 2
                            }
                            MouseArea { anchors.fill: parent; onPressed: uiV(mouse); onPositionChanged: if(pressed) uiV(mouse)
                                function uiV(m) { root.v = Math.max(0, Math.min(1, m.x/width)); root.updateColor() }
                            }
                        }
                    }
                }
                
                // VIEW 4: EYE DROPPER (Placeholder)
                Item { Text { text: "Sampler coming soon"; anchors.centerIn: parent; color: "white" } }
                
                // VIEW 5: PALETTES
                Item { Text { text: "Palettes coming soon"; anchors.centerIn: parent; color: "white" } }
            }
            
            // ------------------------------------------------------------------
            // 4. FOOTER: SHADES / HISTORY / PALETTES
            // ------------------------------------------------------------------
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 140; Layout.topMargin: 20
                ColumnLayout {
                    anchors.fill: parent; spacing: 12
                    
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 4
                        Repeater {
                            model: viewStack.currentIndex === 3 
                                ? [{n: "Harmony Color", x: 0}, {n: "Color History", x: 1}, {n: "My Palettes", x: 2}]
                                : [{n: "Shades", x: 0}, {n: "History", x: 1}, {n: "Palettes", x: 2}]
                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 16
                                color: footStack.currentIndex === modelData.x ? root.accentColor : "#1A1A1C"
                                border.color: footStack.currentIndex === modelData.x ? "transparent" : "#2C2C2E"
                                border.width: 1
                                
                                Text { text: modelData.n; anchors.centerIn: parent; color: "white"; font.pixelSize: 11; font.weight: Font.Bold }
                                MouseArea { anchors.fill: parent; onClicked: footStack.currentIndex = modelData.x }
                            }
                        }
                    }
                    
                    StackLayout {
                        id: footStack; Layout.fillWidth: true; Layout.fillHeight: true
                        
                        // 0: SHADES / HARMONY BOX
                        Item {
                            RowLayout {
                                anchors.fill: parent; spacing: 5
                                Repeater {
                                    model: viewStack.currentIndex === 3 ? root.harmonyColors.length : 10
                                    Rectangle { 
                                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 10
                                        color: viewStack.currentIndex === 3 ? root.harmonyColors[index] : Qt.hsva(root.h, root.s, (index+1)/10.0, 1.0)
                                        
                                        // Premium Active Indicator
                                        Rectangle {
                                            anchors.fill: parent; anchors.margins: -2; radius: 12; color: "transparent"
                                            border.color: "white"; border.width: 2; visible: viewStack.currentIndex === 3 && root.currentColor === parent.color
                                        }

                                        MouseArea { 
                                            anchors.fill: parent; 
                                            hoverEnabled: true
                                            onClicked: { 
                                                if(viewStack.currentIndex===3) {
                                                    var col = parent.color
                                                    root.h = col.hsvHue
                                                    // Maintenance s and v if needed, though they are usually same in my current logic
                                                    root.updateColor()
                                                    root.addToHistory()
                                                } else { 
                                                    root.v = (index+1)/10.0; root.updateColor() 
                                                }
                                            }
                                            onPressed: parent.scale = 0.95
                                            onReleased: parent.scale = 1.0
                                        }
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }
                        
                        // 1: HISTORY
                        Item {
                            Flow { anchors.fill: parent; spacing: 8; Repeater { model: backend.history; Rectangle { width: 36; height: 36; radius: 8; color: modelData; MouseArea { anchors.fill: parent; onClicked: root.currentColor = modelData } } } }
                        }
                        
                        // 2: PALETTES
                        Item { Text { text: "Save your favorite palettes"; color: "#555"; anchors.centerIn: parent } }
                    }
                }
            }
        }
    }
}
