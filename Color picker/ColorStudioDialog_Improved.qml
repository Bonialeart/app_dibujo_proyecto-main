import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import ArtFlow 1.0

Popup {
    id: root
    width: 420
    height: 600
    modal: false
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    margins: 10

    // --- C++ BACKEND ---
    ColorPicker {
        id: backend
        activeColor: root.currentColor
    }

    // --- PROPERTIES ---
    property var targetCanvas: null
    property color currentColor: targetCanvas ? targetCanvas.brushColor : "#BB9BD3"
    property color prevColor: "#BB9BD3" 
    property color secondaryColor: "#FFFFFF"
    property color accentColor: "#7D6D9D"
    
    signal colorSelected(color newColor)
    signal closeRequested()

    property real hue: 0.75  // 270° (purple)
    property real saturation: 0.5
    property real brightness: 0.8
    
    property bool internalUpdate: false

    onOpened: {
        prevColor = currentColor 
        if (!internalUpdate) {
            hue = currentColor.hsvHue
            saturation = currentColor.hsvSaturation
            brightness = currentColor.hsvValue
            backend.activeColor = currentColor
        }
    }
    
    onCurrentColorChanged: {
        if (!internalUpdate && visible) {
            hue = currentColor.hsvHue
            saturation = currentColor.hsvSaturation
            brightness = currentColor.hsvValue
            backend.activeColor = currentColor
        }
    }

    function updateColor() {
        internalUpdate = true
        var c = Qt.hsva(hue, saturation, brightness, 1.0)
        currentColor = c
        
        if (targetCanvas) {
            targetCanvas.brushColor = c
            colorSelected(c)
        }
        
        backend.addToHistory(c)
        internalUpdate = false
    }
    
    function iconPath(name) { return "image://icons/" + name; }
    function getModeTitle(idx) {
        if (idx === 0) return "Color Box"
        if (idx === 1) return "Color Wheel"
        if (idx === 2) return "Color Harmony"
        return "Color Sliders"
    }

    // --- BACKGROUND ---
    background: Rectangle {
        color: "#1E1E1E"
        radius: 16
        border.color: "#2D2D2D"
        border.width: 1
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 40
            shadowColor: "#A0000000"
            shadowVerticalOffset: 8
            shadowHorizontalOffset: 0
        }
    }

    contentItem: ColumnLayout {
        spacing: 0
        
        // ===========================================
        // HEADER (Title + Color Display)
        // ===========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                Label { 
                    text: getModeTitle(viewStack.currentIndex)
                    color: "white"
                    font.bold: true
                    font.pixelSize: 18
                    Layout.fillWidth: true
                }
                
                // Color Circles
                Item {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 50
                    
                    // Primary color (larger)
                    Rectangle {
                        id: primaryCircle
                        width: 48
                        height: 48
                        radius: 24
                        color: root.currentColor
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 2
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowBlur: 8
                            shadowColor: "#60000000"
                            shadowVerticalOffset: 2
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Swap primary/secondary
                                var temp = root.currentColor
                                root.currentColor = root.secondaryColor
                                root.secondaryColor = temp
                            }
                        }
                    }
                    
                    // Secondary color (smaller, overlay)
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: root.secondaryColor
                        border.color: Qt.rgba(1, 1, 1, 0.3)
                        border.width: 1.5
                        anchors.right: primaryCircle.right
                        anchors.bottom: primaryCircle.bottom
                        anchors.rightMargin: -4
                        anchors.bottomMargin: -4
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowBlur: 6
                            shadowColor: "#40000000"
                            shadowVerticalOffset: 2
                        }
                    }
                }
                
                // Menu button (tres puntos)
                Button {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    background: Rectangle {
                        color: parent.pressed ? "#3D3D3D" : (parent.hovered ? "#2D2D2D" : "transparent")
                        radius: 6
                    }
                    contentItem: Text {
                        text: "⋮"
                        color: "#B0B0B0"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#2D2D2D"
        }
        
        // ===========================================
        // MODE SELECTOR BUTTONS
        // ===========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                
                component ModeButton : Button {
                    property int modeIndex
                    property string iconName
                    
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    checkable: true
                    checked: viewStack.currentIndex === modeIndex
                    
                    background: Rectangle {
                        color: parent.checked ? root.accentColor : (parent.hovered ? "#2D2D2D" : "transparent")
                        radius: 8
                        border.color: parent.checked ? Qt.lighter(root.accentColor, 1.2) : "transparent"
                        border.width: parent.checked ? 1 : 0
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Image {
                        source: root.iconPath(iconName)
                        fillMode: Image.PreserveAspectFit
                        opacity: parent.checked ? 1.0 : 0.6
                        
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    
                    onClicked: viewStack.currentIndex = modeIndex
                }
                
                ModeButton { modeIndex: 0; iconName: "grid_pattern.svg" }
                ModeButton { modeIndex: 1; iconName: "palette.svg" }
                ModeButton { modeIndex: 2; iconName: "layers.svg" }
                ModeButton { modeIndex: 3; iconName: "sliders.svg" }
                
                Item { Layout.fillWidth: true }
            }
        }
        
        // ===========================================
        // MAIN CONTENT STACK
        // ===========================================
        StackLayout {
            id: viewStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0
            
            // --- MODE 0: COLOR BOX ---
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    
                    // 2D Color Box
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(parent.width, 320)
                        Layout.preferredHeight: Layout.preferredWidth
                        color: Qt.hsva(root.hue, 1, 1, 1)
                        radius: 12
                        border.color: "#2D2D2D"
                        border.width: 1
                        clip: true
                        
                        // White to transparent gradient (horizontal - saturation)
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "#FFFFFF" }
                                GradientStop { position: 1; color: "transparent" }
                            }
                        }
                        
                        // Transparent to black gradient (vertical - brightness)
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: "#000000" }
                            }
                        }
                        
                        // Selection reticle
                        Rectangle {
                            id: boxReticle
                            width: 20
                            height: 20
                            radius: 10
                            x: root.saturation * parent.width - width/2
                            y: (1.0 - root.brightness) * parent.height - height/2
                            color: "transparent"
                            border.color: "white"
                            border.width: 3
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 6
                                height: parent.height - 6
                                radius: width/2
                                color: "transparent"
                                border.color: "black"
                                border.width: 1
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onPressed: updateFromMouse(mouse)
                            onPositionChanged: if (pressed) updateFromMouse(mouse)
                            
                            function updateFromMouse(mouse) {
                                root.saturation = Math.max(0, Math.min(1, mouse.x / width))
                                root.brightness = Math.max(0, Math.min(1, 1.0 - mouse.y / height))
                                updateColor()
                            }
                        }
                    }
                    
                    // Hue Slider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 14
                        border.color: "#2D2D2D"
                        border.width: 1
                        
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
                        
                        Rectangle {
                            id: hueHandle
                            width: 24
                            height: 32
                            radius: 4
                            x: root.hue * (parent.width - width)
                            y: parent.height/2 - height/2
                            color: "white"
                            border.color: "#2D2D2D"
                            border.width: 2
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                height: parent.height - 8
                                radius: 2
                                color: Qt.hsva(root.hue, 1, 1, 1)
                            }
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowBlur: 8
                                shadowColor: "#60000000"
                                shadowVerticalOffset: 2
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onPressed: updateHue(mouse)
                            onPositionChanged: if (pressed) updateHue(mouse)
                            
                            function updateHue(mouse) {
                                root.hue = Math.max(0, Math.min(1, mouse.x / width))
                                updateColor()
                            }
                        }
                    }
                    
                    // Hex Input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Label {
                            text: "Hex"
                            color: "#888888"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        
                        TextField {
                            id: hexInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            text: root.currentColor.toString().toUpperCase()
                            font.pixelSize: 13
                            font.family: "monospace"
                            horizontalAlignment: Text.AlignLeft
                            
                            color: "#E0E0E0"
                            background: Rectangle {
                                color: "#2D2D2D"
                                radius: 6
                                border.color: hexInput.activeFocus ? root.accentColor : "#3D3D3D"
                                border.width: 1
                            }
                            
                            onEditingFinished: {
                                if (text.length === 7 && text[0] === '#') {
                                    root.currentColor = text
                                }
                            }
                        }
                        
                        Button {
                            text: "📋"
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            onClicked: {
                                // Copy to clipboard logic
                                console.log("Copy:", root.currentColor)
                            }
                            background: Rectangle {
                                color: parent.pressed ? "#3D3D3D" : (parent.hovered ? "#2D2D2D" : "#252525")
                                radius: 6
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
            
            // --- MODE 1: COLOR WHEEL ---
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    
                    // Wheel Mode Tabs
                    TabBar {
                        id: wheelModeTabs
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        background: Rectangle { 
                            color: "#252525"
                            radius: 8
                        }
                        
                        component WheelTab : TabButton {
                            property string tabText
                            text: tabText
                            height: 36
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.checked ? "white" : "#888888"
                                font.pixelSize: 12
                                font.bold: parent.checked
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                color: parent.checked ? root.accentColor : "transparent"
                                radius: 6
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        
                        WheelTab { tabText: "Ring" }
                        WheelTab { tabText: "Harm" }
                        WheelTab { tabText: "Sldr" }
                    }
                    
                    // Color Wheel
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 280
                        Layout.preferredHeight: 280
                        
                        // Outer ring shader
                        Shape {
                            anchors.fill: parent
                            layer.enabled: true
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: width/2
                                color: "transparent"
                                
                                ShaderEffect {
                                    anchors.fill: parent
                                    fragmentShader: "
                                        varying highp vec2 qt_TexCoord0;
                                        uniform highp float qt_Opacity;
                                        #define PI 3.14159265359
                                        
                                        vec3 hsb2rgb(in vec3 c) {
                                            vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
                                            rgb = rgb*rgb*(3.0-2.0*rgb);
                                            return c.z * mix(vec3(1.0), rgb, c.y);
                                        }
                                        
                                        void main() {
                                            vec2 toCenter = qt_TexCoord0 - 0.5;
                                            float angle = atan(toCenter.y, toCenter.x);
                                            float radius = length(toCenter) * 2.0;
                                            
                                            if (radius > 0.70 && radius < 1.0) {
                                                float hue = (angle / (2.0 * PI)) + 0.5;
                                                gl_FragColor = vec4(hsb2rgb(vec3(hue, 1.0, 1.0)), 1.0) * qt_Opacity;
                                            } else {
                                                gl_FragColor = vec4(0.0);
                                            }
                                        }
                                    "
                                }
                            }
                        }
                        
                        // Inner square
                        Rectangle {
                            width: parent.width * 0.5
                            height: width
                            anchors.centerIn: parent
                            radius: 8
                            color: Qt.hsva(root.hue, 1, 1, 1)
                            clip: true
                            
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "white" }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: "black" }
                                }
                            }
                            
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                x: root.saturation * parent.width - width/2
                                y: (1.0 - root.brightness) * parent.height - height/2
                                color: "transparent"
                                border.color: "white"
                                border.width: 2
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    radius: width/2
                                    color: "transparent"
                                    border.color: "black"
                                    border.width: 1
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onPressed: updateInner(mouse)
                                onPositionChanged: if (pressed) updateInner(mouse)
                                
                                function updateInner(mouse) {
                                    root.saturation = Math.max(0, Math.min(1, mouse.x / width))
                                    root.brightness = Math.max(0, Math.min(1, 1.0 - mouse.y / height))
                                    updateColor()
                                }
                            }
                        }
                        
                        // Hue reticle on ring
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "transparent"
                            border.color: "white"
                            border.width: 3
                            
                            property real angle: (root.hue - 0.25) * Math.PI * 2
                            x: (parent.width/2) + Math.cos(angle) * (parent.width/2 * 0.85) - width/2
                            y: (parent.height/2) + Math.sin(angle) * (parent.height/2 * 0.85) - height/2
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 6
                                height: parent.height - 6
                                radius: width/2
                                color: "transparent"
                                border.color: "black"
                                border.width: 1
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onPressed: updateWheel(mouse)
                            onPositionChanged: if (pressed) updateWheel(mouse)
                            
                            function updateWheel(mouse) {
                                var dx = mouse.x - width/2
                                var dy = mouse.y - height/2
                                var dist = Math.sqrt(dx*dx + dy*dy)
                                var ringRadius = width * 0.35
                                
                                if (dist > ringRadius) {
                                    var angle = Math.atan2(dy, dx) + Math.PI/2
                                    var h = (angle / (Math.PI * 2)) + 0.5
                                    root.hue = h - Math.floor(h)
                                    updateColor()
                                }
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
            
            // --- MODE 2: HARMONY ---
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    Label {
                        text: "Color Harmony"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8
                        
                        component HarmonyButton : Rectangle {
                            property string harmonyName
                            property var harmonyColors: []
                            
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            color: "#252525"
                            radius: 8
                            border.color: "#3D3D3D"
                            border.width: 1
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4
                                
                                Label {
                                    text: harmonyName
                                    color: "#B0B0B0"
                                    font.pixelSize: 10
                                    Layout.fillWidth: true
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Repeater {
                                        model: harmonyColors
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 24
                                            color: modelData
                                            radius: 4
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Apply harmony
                                    if (harmonyColors.length > 0) {
                                        root.currentColor = harmonyColors[0]
                                    }
                                }
                            }
                        }
                        
                        HarmonyButton {
                            harmonyName: "Complementary"
                            harmonyColors: [
                                Qt.hsva(root.hue, 0.8, 0.8, 1),
                                Qt.hsva((root.hue + 0.5) % 1.0, 0.8, 0.8, 1)
                            ]
                        }
                        
                        HarmonyButton {
                            harmonyName: "Analogous"
                            harmonyColors: [
                                Qt.hsva((root.hue - 0.083 + 1) % 1.0, 0.7, 0.8, 1),
                                Qt.hsva(root.hue, 0.8, 0.8, 1),
                                Qt.hsva((root.hue + 0.083) % 1.0, 0.7, 0.8, 1)
                            ]
                        }
                        
                        HarmonyButton {
                            harmonyName: "Triadic"
                            harmonyColors: [
                                Qt.hsva(root.hue, 0.8, 0.8, 1),
                                Qt.hsva((root.hue + 0.333) % 1.0, 0.8, 0.8, 1),
                                Qt.hsva((root.hue + 0.666) % 1.0, 0.8, 0.8, 1)
                            ]
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }
            }
            
            // --- MODE 3: SLIDERS ---
            Item {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 12
                        padding: 16
                        
                        // HSB Section
                        Label {
                            text: "HSB"
                            color: "#B0B0B0"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        
                        component ColorSlider : RowLayout {
                            property string label
                            property real value
                            property real maxValue: 1.0
                            property string unit: ""
                            property var gradientColors: []
                            signal valueChanged(real newValue)
                            
                            spacing: 12
                            Layout.fillWidth: true
                            
                            Label {
                                text: label
                                color: "#888888"
                                font.pixelSize: 12
                                font.bold: true
                                Layout.preferredWidth: 20
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                radius: 12
                                border.color: "#2D2D2D"
                                border.width: 1
                                
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    Repeater {
                                        model: gradientColors
                                        GradientStop {
                                            position: index / (gradientColors.length - 1)
                                            color: modelData
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: 20
                                    height: 28
                                    radius: 6
                                    x: (value / maxValue) * (parent.width - width)
                                    y: parent.height/2 - height/2
                                    color: "white"
                                    border.color: "#2D2D2D"
                                    border.width: 2
                                    
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowBlur: 6
                                        shadowColor: "#60000000"
                                        shadowVerticalOffset: 2
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: update(mouse)
                                    onPositionChanged: if (pressed) update(mouse)
                                    
                                    function update(mouse) {
                                        var newValue = Math.max(0, Math.min(maxValue, (mouse.x / width) * maxValue))
                                        valueChanged(newValue)
                                    }
                                }
                            }
                            
                            Label {
                                text: Math.round(value * (maxValue === 1.0 ? 100 : maxValue)) + unit
                                color: "#CCCCCC"
                                font.pixelSize: 11
                                font.family: "monospace"
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        
                        ColorSlider {
                            label: "H"
                            value: root.hue
                            maxValue: 1.0
                            unit: "°"
                            gradientColors: ["#FF0000", "#FFFF00", "#00FF00", "#00FFFF", "#0000FF", "#FF00FF", "#FF0000"]
                            onValueChanged: (newValue) => { root.hue = newValue; updateColor() }
                        }
                        
                        ColorSlider {
                            label: "S"
                            value: root.saturation
                            maxValue: 1.0
                            unit: "%"
                            gradientColors: [
                                Qt.hsva(root.hue, 0, root.brightness, 1),
                                Qt.hsva(root.hue, 1, root.brightness, 1)
                            ]
                            onValueChanged: (newValue) => { root.saturation = newValue; updateColor() }
                        }
                        
                        ColorSlider {
                            label: "B"
                            value: root.brightness
                            maxValue: 1.0
                            unit: "%"
                            gradientColors: [
                                Qt.hsva(root.hue, root.saturation, 0, 1),
                                Qt.hsva(root.hue, root.saturation, 1, 1)
                            ]
                            onValueChanged: (newValue) => { root.brightness = newValue; updateColor() }
                        }
                        
                        Rectangle { Layout.fillWidth: true; height: 1; color: "#2D2D2D" }
                        
                        // RGB Section
                        Label {
                            text: "RGB"
                            color: "#B0B0B0"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.topMargin: 8
                        }
                        
                        ColorSlider {
                            label: "R"
                            value: root.currentColor.r
                            maxValue: 1.0
                            unit: ""
                            gradientColors: ["#000000", "#FF0000"]
                            onValueChanged: (newValue) => {
                                root.currentColor = Qt.rgba(newValue, root.currentColor.g, root.currentColor.b, 1)
                            }
                        }
                        
                        ColorSlider {
                            label: "G"
                            value: root.currentColor.g
                            maxValue: 1.0
                            unit: ""
                            gradientColors: ["#000000", "#00FF00"]
                            onValueChanged: (newValue) => {
                                root.currentColor = Qt.rgba(root.currentColor.r, newValue, root.currentColor.b, 1)
                            }
                        }
                        
                        ColorSlider {
                            label: "B"
                            value: root.currentColor.b
                            maxValue: 1.0
                            unit: ""
                            gradientColors: ["#000000", "#0000FF"]
                            onValueChanged: (newValue) => {
                                root.currentColor = Qt.rgba(root.currentColor.r, root.currentColor.g, newValue, 1)
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
        
        // ===========================================
        // BOTTOM TABS (History / Palettes)
        // ===========================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#2D2D2D"
        }
        
        TabBar {
            id: bottomTabs
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            background: Rectangle { color: "#252525" }
            
            component BottomTab : TabButton {
                property string tabText
                text: tabText
                
                contentItem: Text {
                    text: parent.text
                    color: parent.checked ? "white" : "#666666"
                    font.pixelSize: 12
                    font.bold: parent.checked
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: root.accentColor
                        anchors.bottom: parent.bottom
                        visible: parent.parent.checked
                    }
                }
            }
            
            BottomTab { tabText: "Color Shades" }
            BottomTab { tabText: "History" }
            BottomTab { tabText: "Palettes" }
        }
        
        StackLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            currentIndex: bottomTabs.currentIndex
            
            // Shades
            Item {
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6
                    
                    Repeater {
                        model: 10
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            
                            property real factor: index / 9.0
                            color: Qt.hsva(
                                root.hue,
                                root.saturation,
                                0.2 + (root.brightness * 0.8 * factor),
                                1
                            )
                            
                            border.color: "#2D2D2D"
                            border.width: 1
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.currentColor = parent.color
                                }
                            }
                        }
                    }
                }
            }
            
            // History
            Item {
                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    columns: 10
                    rowSpacing: 6
                    columnSpacing: 6
                    
                    Repeater {
                        model: backend.history
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: modelData
                            radius: 6
                            border.color: "#2D2D2D"
                            border.width: 1
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { root.currentColor = modelData }
                            }
                        }
                    }
                }
            }
            
            // Palettes
            Item {
                Label {
                    text: "No palettes yet"
                    color: "#555555"
                    anchors.centerIn: parent
                }
            }
        }
    }
}
