import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ArtFlow 1.0

Item {
    id: root
    
    // --- PROPERTIES ---
    property var targetCanvas: null
    property color accentColor: "#8E7CC3"
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

    // --- C++ BACKEND ---
    ColorPicker {
        id: backend
        activeColor: root.currentColor
    }

    // --- LOGIC ---
    onActiveSlotChanged: {
        if (!internalUpdate) {
            internalUpdate = true
            isTransparent = false
            var col = (activeSlot === 0 ? slot0Color : slot1Color)
            h = col.hsvHue
            s = col.hsvSaturation
            v = col.hsvValue
            if (targetCanvas) targetCanvas.brushColor = col
            internalUpdate = false
        }
    }

    onIsTransparentChanged: {
        if (!internalUpdate && isTransparent) {
             if (targetCanvas) {
                targetCanvas.isEraser = true
                targetCanvas.brushColor = "transparent"
             }
        } else if (!internalUpdate && !isTransparent) {
             if (targetCanvas) {
                targetCanvas.isEraser = false
                targetCanvas.brushColor = (activeSlot === 0 ? slot0Color : slot1Color)
             }
        }
    }
    
    Component.onCompleted: {
        if (currentColor) {
            h = currentColor.hsvHue
            s = currentColor.hsvSaturation
            v = currentColor.hsvValue
            slot0Color = currentColor
        }
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

    function addToHistory() {
        var c = root.currentColor
        // Backend handles dupe check
        backend.addToHistory(c)
    }

    // CMYK Helpers
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
        updateColor() // Trigger update
    }

    signal colorSelected(color newColor)

    // --- UI ---
    Rectangle {
        anchors.fill: parent
        color: "#161618" // matches ColorStudioDialog inner panels
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0
            
            // 1. TABS (Wheel, Sliders, Palettes)
            RowLayout {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                spacing: 2
                
                Repeater {
                    model: ["Wheel", "Sliders", "Palettes"]
                    delegate: Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: viewStack.currentIndex === index ? "#2c2c2e" : "transparent"
                        radius: 4
                        Text { 
                            text: modelData; anchors.centerIn: parent
                            color: viewStack.currentIndex === index ? "white" : "#888"
                            font.pixelSize: 11
                        }
                        MouseArea { anchors.fill: parent; onClicked: viewStack.currentIndex = index }
                    }
                }
            }
            
            Item { Layout.fillHeight: true; Layout.preferredHeight: 4 } // Spacer
            
            // 2. MAIN CONTENT
            StackLayout {
                id: viewStack
                Layout.fillWidth: true; Layout.fillHeight: true
                currentIndex: 0
                
                // --- VIEW 0: WHEEL ---
                Item {
                    // Similar to ColorStudioDialog WheelView
                     Canvas {
                        id: hueRingCanvas
                        anchors.fill: parent; anchors.margins: 4
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            var cx = width/2, cy = height/2;
                            var r = Math.min(cx, cy);
                            
                            // Hue Ring
                            var grad = ctx.createConicalGradient(cx, cy, 0); 
                            for(var i=0; i<=1; i+=0.1) grad.addColorStop(i, Qt.hsva(i,1,1,1));
                            
                            ctx.fillStyle = grad;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, Math.PI*2);
                            ctx.arc(cx, cy, r*0.85, 0, Math.PI*2, true);
                            ctx.fill();
                        }
                    }
                    MouseArea {
                         anchors.fill: parent
                         onPositionChanged: (mouse) => {
                             if(pressed) {
                                 var dx = mouse.x - width/2, dy = height/2 - mouse.y;
                                 var angle = Math.atan2(dy, dx);
                                 var h = angle / (Math.PI*2);
                                 if (h < 0) h+=1;
                                 root.h = (1-h)%1;
                                 root.updateColor();
                             }
                         }
                    }
                    
                    // Inner SV Square/Disc logic placeholder
                    Rectangle {
                        width: Math.min(parent.width, parent.height)*0.55
                        height: width; radius: 4
                        anchors.centerIn: parent
                        color: Qt.hsva(root.h, 1, 1, 1)
                        
                        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } orientation: Gradient.Horizontal } }
                        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } orientation: Gradient.Vertical } }
                        
                        MouseArea {
                            anchors.fill: parent
                            onPositionChanged: (mouse) => {
                                if(pressed) {
                                    root.s = Math.max(0, Math.min(1, mouse.x/width))
                                    root.v = Math.max(0, Math.min(1, 1-mouse.y/height))
                                    root.updateColor()
                                }
                            }
                        }
                        
                        // Selector
                        Rectangle {
                            x: root.s * parent.width - 5; y: (1-root.v)*parent.height - 5
                            width: 10; height: 10; radius: 5
                            border.color: "white"; border.width: 1; color: "transparent"
                        }
                    }
                }
                
                // --- VIEW 1: SLIDERS ---
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                         // Placeholder for ImprovedColorSlider usage
                        Text { text: "Sliders View"; color: "white"; anchors.centerIn: parent }
                    }
                }
                
                // --- VIEW 2: PALETTES ---
                Item {
                    Text { text: "Palettes View"; color: "white"; anchors.centerIn: parent }
                }
            }
            
            // 3. FOOTER (Hex + Wells)
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 50
                color: "#1c1c1e"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 4
                    spacing: 8
                    
                    // Hex Input
                    TextField {
                        Layout.fillWidth: true
                        text: root.currentColor.toString()
                        color: "white"
                        background: Rectangle { color: "#2c2c2e"; radius: 4 }
                        onEditingFinished: root.currentColor = text
                    }
                    
                    // Wells
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: root.slot0Color
                        border.color: activeSlot === 0 ? "white" : "transparent"; border.width: 2
                        MouseArea { anchors.fill: parent; onClicked: activeSlot = 0 }
                    }
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: root.slot1Color
                        border.color: activeSlot === 1 ? "white" : "transparent"; border.width: 2
                        MouseArea { anchors.fill: parent; onClicked: activeSlot = 1 }
                    }
                }
            }
        }
    }
}
