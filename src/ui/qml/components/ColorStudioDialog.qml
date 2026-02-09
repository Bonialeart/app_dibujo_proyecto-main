import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes

Popup {
    id: root
    width: 380
    height: 520
    modal: false
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Position adjustments usually handled by caller, but we can enforce some defaults
    margins: 10

    // --- PROPIEDADES ---
    property var targetCanvas: null
    property color currentColor: targetCanvas ? targetCanvas.brushColor : "#000000"
    property color prevColor: "#000000" 
    property color accentColor: "#4A90E2"
    
    signal colorSelected(color newColor)
    signal closeRequested()

    property real hue: 0.0
    property real saturation: 1.0
    property real brightness: 1.0
    
    property bool internalUpdate: false

    onOpened: {
         prevColor = currentColor 
         if (!internalUpdate) {
            hue = currentColor.hsvHue
            saturation = currentColor.hsvSaturation
            brightness = currentColor.hsvValue
         }
    }
    
    onCurrentColorChanged: {
        if (!internalUpdate && visible) {
            hue = currentColor.hsvHue
            saturation = currentColor.hsvSaturation
            brightness = currentColor.hsvValue
        }
    }

    function updateColor() {
        internalUpdate = true
        var c = Qt.hsva(hue, saturation, brightness, 1.0)
        if (targetCanvas) {
            targetCanvas.brushColor = c
            colorSelected(c)
        }
        internalUpdate = false
    }
    
    function iconPath(name) { return "image://icons/" + name; }

    // --- BACKGROUND ---
    background: Rectangle {
        color: "#1e1e1e" // Dark Premium Background
        radius: 16
        border.color: "#333"
        border.width: 1
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 30
            shadowColor: "#80000000"
            shadowVerticalOffset: 4
        }
    }

    contentItem: RowLayout {
        spacing: 0
        
        // ===========================================
        // 1. LEFT SIDEBAR (Icons)
        // ===========================================
        Rectangle {
            Layout.preferredWidth: 60
            Layout.fillHeight: true
            color: "#181818" // Slightly darker sidebar
            
            // Mask for rounded corners on left only if needed, 
            // but the background handles the main radius. 
            // We just need this rect to fit inside.
            // Simplified: Just use transparent and column of buttons
            visible: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 20
                spacing: 20
                
                component SidebarBtn : Button {
                    property string icon
                    property int idx
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignHCenter
                    
                    background: Rectangle {
                        color: viewStack.currentIndex === idx ? "#333" : "transparent"
                        radius: 8
                        border.color: viewStack.currentIndex === idx ? "#555" : "transparent"
                    }
                    contentItem: Image {
                        source: root.iconPath(icon)
                        fillMode: Image.PreserveAspectFit
                        opacity: viewStack.currentIndex === idx ? 1.0 : 0.5
                    }
                    onClicked: viewStack.currentIndex = idx
                }

                SidebarBtn { icon: "grid_pattern.svg"; idx: 0 } // Box
                SidebarBtn { icon: "palette.svg"; idx: 1 }      // Wheel
                SidebarBtn { icon: "layers.svg"; idx: 2 }       // Harmony
                SidebarBtn { icon: "sliders.svg"; idx: 3 }      // Values
                
                Item { Layout.fillHeight: true } // Spacer
            }
            
            // Separator Line
            Rectangle {
                width: 1; height: parent.height
                color: "#333"
                anchors.right: parent.right
            }
        }
        
        // ===========================================
        // 2. MAIN CONTENT AREA
        // ===========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                // HEADER (Title + Circles)
                RowLayout {
                    Layout.fillWidth: true
                    Label { 
                        text: getModeTitle(viewStack.currentIndex)
                        color: "white"
                        font.bold: true
                        font.pixelSize: 16
                        Layout.fillWidth: true
                    }
                    
                    // Circles
                    Item {
                        width: 50; height: 24
                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: root.prevColor
                            border.color: "#444"; border.width: 1
                            anchors.right: parent.right
                        }
                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: root.currentColor
                            border.color: "white"; border.width: 2
                            anchors.left: parent.left
                        }
                    }
                    
                    // Menu
                    Button {
                        width: 24; height: 24
                        background: null
                        contentItem: Text { text: "⋮"; color: "#aaa"; verticalAlignment: Text.AlignVCenter }
                        onClicked: root.closeRequested()
                    }
                }
                
                // STACK VIEW
                StackLayout {
                    id: viewStack
                    currentIndex: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // --- 0: BOX MODE ---
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12
                            
                            // Sat/Bri Box
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true 
                                
                                Rectangle {
                                    anchors.fill: parent; radius: 8; clip: true
                                    color: Qt.hsva(root.hue, 1, 1, 1)
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "white" }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            orientation: Gradient.Vertical
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 1.0; color: "black" }
                                        }
                                    }
                                    
                                    // Reticle
                                    Rectangle {
                                        width: 18; height: 18; radius: 9
                                        x: root.saturation * parent.width - 9
                                        y: (1.0 - root.brightness) * parent.height - 9
                                        color: "transparent"; border.color: root.brightness > 0.5 ? "black" : "white"; border.width: 2
                                        Rectangle { width: 16; height: 16; radius: 8; anchors.centerIn: parent; color: "transparent"; border.color: root.brightness > 0.5 ? "white" : "black"; border.width: 1 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        function updatePos(mouse) {
                                            root.saturation = Math.max(0, Math.min(1, mouse.x / width))
                                            root.brightness = 1.0 - Math.max(0, Math.min(1, mouse.y / height))
                                            updateColor()
                                        }
                                        onPressed: (mouse)=>updatePos(mouse)
                                        onPositionChanged: (mouse)=>updatePos(mouse)
                                    }
                                }
                            }
                            
                            // Hue Slider
                            Item {
                                Layout.fillWidth: true; Layout.preferredHeight: 28
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width; height: 16; radius: 8
                                    gradient: Gradient { orientation: Gradient.Horizontal
                                        GradientStop { position: 0.00; color: "#FF0000" }
                                        GradientStop { position: 0.17; color: "#FFFF00" }
                                        GradientStop { position: 0.33; color: "#00FF00" }
                                        GradientStop { position: 0.50; color: "#00FFFF" }
                                        GradientStop { position: 0.67; color: "#0000FF" }
                                        GradientStop { position: 0.83; color: "#FF00FF" }
                                        GradientStop { position: 1.00; color: "#FF0000" }
                                    }
                                }
                                Rectangle {
                                    x: root.hue * (parent.width - 20)
                                    width: 20; height: 20; radius: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"; border.color: "#333"; border.width: 1
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -10
                                        drag.target: parent; drag.axis: Drag.XAxis; drag.minimumX: 0; drag.maximumX: parent.parent.width - 20
                                        onPositionChanged: { root.hue = parent.x / (parent.parent.width - 20); updateColor() }
                                    }
                                }
                            }
                            
                            // Bottom Tabs Area
                            TabBar {
                                id: boxTabs
                                Layout.fillWidth: true
                                background: Rectangle { color: "transparent" }
                                TabButton {
                                    text: "History"; width: implicitWidth
                                    contentItem: Text { text: parent.text; color: parent.checked ? "white" : "#666"; font.bold: parent.checked; horizontalAlignment: Text.AlignHCenter }
                                    background: null
                                }
                                TabButton {
                                    text: "Palettes"; width: implicitWidth
                                    contentItem: Text { text: parent.text; color: parent.checked ? "white" : "#666"; font.bold: parent.checked; horizontalAlignment: Text.AlignHCenter }
                                    background: null
                                }
                            }
                            
                            StackLayout {
                                currentIndex: boxTabs.currentIndex
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                
                                // History
                                GridLayout {
                                    columns: 5; rowSpacing: 5; columnSpacing: 5
                                    Repeater {
                                        model: 10
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 25
                                            color: Qt.hsva(index/10.0, 0.6, 0.8, 1)
                                            radius: 4
                                            MouseArea { anchors.fill: parent; onClicked: { root.hue = index/10.0; updateColor() } }
                                        }
                                    }
                                }
                                // Palettes (Placeholder)
                                Item {
                                    Label { text: "No Palettes"; color: "#555"; anchors.centerIn: parent }
                                }
                            }
                        }
                    }
                    
                    // --- 1: WHEEL MODE ---
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 220
                                Layout.preferredHeight: 220
                                
                                // Wheel Logic
                                Shape {
                                    anchors.fill: parent
                                    layer.enabled: true
                                    Rectangle { anchors.fill: parent; radius: width/2; color: "transparent" 
                                        ShaderEffect {
                                            anchors.fill: parent
                                            fragmentShader: "
                                                varying highp vec2 qt_TexCoord0;
                                                uniform highp float qt_Opacity;
                                                #define PI 3.14159265359
                                                vec3 hsb2rgb(in vec3 c){
                                                    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
                                                    rgb = rgb*rgb*(3.0-2.0*rgb);
                                                    return c.z * mix(vec3(1.0), rgb, c.y);
                                                }
                                                void main() {
                                                    vec2 toCenter = qt_TexCoord0 - 0.5;
                                                    float angle = atan(toCenter.y, toCenter.x) + 1.5708; 
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
                                MouseArea {
                                    anchors.fill: parent
                                    onPositionChanged: (mouse) => {
                                        var dx = mouse.x - width/2; var dy = mouse.y - height/2;
                                        var dist = Math.sqrt(dx*dx + dy*dy)
                                        if (dist > width*0.35) {
                                            var angle = Math.atan2(dy, dx) + 1.5708
                                            var h = (angle / (Math.PI * 2)) + 0.5
                                            root.hue = h - Math.floor(h)
                                            updateColor()
                                        }
                                    }
                                }
                                
                                // Inner Square
                                Rectangle {
                                    width: parent.width * 0.45; height: width
                                    anchors.centerIn: parent
                                    color: Qt.hsva(root.hue, 1, 1, 1)
                                    Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position:0;color:"white"} GradientStop{position:1;color:"transparent"} }}
                                    Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position:0;color:"transparent"} GradientStop{position:1;color:"black"} }}
                                    
                                    Rectangle {
                                        width: 14; height: 14; radius: 7
                                        x: root.saturation * parent.width - 7
                                        y: (1.0 - root.brightness) * parent.height - 7
                                        color: "transparent"; border.color: "white"; border.width: 1
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPositionChanged: (mouse) => {
                                            root.saturation = Math.max(0, Math.min(1, mouse.x / width))
                                            root.brightness = 1.0 - Math.max(0, Math.min(1, mouse.y / height))
                                            updateColor()
                                        }
                                    }
                                }
                                
                                // Hue Reticle
                                Rectangle {
                                    width: 16; height: 16; radius: 8
                                    color: "transparent"; border.color: "white"; border.width: 2
                                    property real angle: (root.hue - 0.25) * Math.PI * 2 
                                    x: (parent.width/2) + Math.cos(angle) * (parent.width/2 * 0.85) - 8
                                    y: (parent.height/2) + Math.sin(angle) * (parent.height/2 * 0.85) - 8
                                }
                            }
                        }
                    }
                    
                    // --- 2: LAYERS / HARMONY ---
                    Item { Label { text: "Harmony Mode"; color: "#666"; anchors.centerIn: parent } }
                    // --- 3: SLIDERS ---
                    Item { Label { text: "Sliders Mode"; color: "#666"; anchors.centerIn: parent } }
                }
            }
        }
    }
    
    function getModeTitle(idx) {
        if (idx === 0) return "Color Box"
        if (idx === 1) return "Color Wheel"
        return "Color Studio"
    }
}
