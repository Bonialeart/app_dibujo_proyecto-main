import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ArtFlow 1.0

Popup {
    id: root
    width: 380
    height: 520
    modal: false
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    margins: 10

    ColorPicker { id: backend; activeColor: root.currentColor }

    property var targetCanvas: null
    property color currentColor: targetCanvas ? targetCanvas.brushColor : "#BB9BD3"
    property color prevColor: "#BB9BD3" 
    
    property real h: 0.75
    property real s: 0.5
    property real v: 0.8
    
    property bool internalUpdate: false

    signal colorSelected(color newColor)
    signal closeRequested()

    onOpened: {
        prevColor = currentColor 
        if (!internalUpdate) {
            h = currentColor.hsvHue
            s = currentColor.hsvSaturation
            v = currentColor.hsvValue
            backend.activeColor = currentColor
        }
    }
    
    onCurrentColorChanged: {
        if (!internalUpdate && visible) {
            h = currentColor.hsvHue
            s = currentColor.hsvSaturation
            v = currentColor.hsvValue
            backend.activeColor = currentColor
        }
    }

    function updateColor() {
        internalUpdate = true
        var c = Qt.hsva(h, s, v, 1.0)
        currentColor = c
        if (targetCanvas) {
            targetCanvas.brushColor = c
            colorSelected(c)
        }
        internalUpdate = false
    }
    
    function addToHistory() { backend.addToHistory(currentColor) }
    function iconPath(name) { return "image://icons/" + name }

    background: Rectangle {
        color: "#1e1e1e"
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
        
        // LEFT SIDEBAR
        Rectangle {
            Layout.preferredWidth: 60
            Layout.fillHeight: true
            color: "#181818"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 20
                spacing: 20
                
                component SidebarBtn : Button {
                    property string btnIcon
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
                        source: root.iconPath(btnIcon)
                        fillMode: Image.PreserveAspectFit
                        opacity: viewStack.currentIndex === idx ? 1.0 : 0.5
                    }
                    onClicked: viewStack.currentIndex = idx
                }

                SidebarBtn { btnIcon: "grid_pattern.svg"; idx: 0 }
                SidebarBtn { btnIcon: "palette.svg"; idx: 1 }
                SidebarBtn { btnIcon: "layers.svg"; idx: 2 }
                SidebarBtn { btnIcon: "sliders.svg"; idx: 3 }
                
                Item { Layout.fillHeight: true }
            }
            
            Rectangle {
                width: 1; height: parent.height
                color: "#333"
                anchors.right: parent.right
            }
        }
        
        // MAIN CONTENT
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                // HEADER
                RowLayout {
                    Layout.fillWidth: true
                    Label { 
                        text: viewStack.currentIndex === 0 ? "Color Box" : 
                              viewStack.currentIndex === 1 ? "Color Wheel" : "Color Studio"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    Item { Layout.fillWidth: true }
                    
                    // Color circles
                    Item {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 40
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: root.currentColor
                            border.color: "#40FFFFFF"; border.width: 1.5
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: root.prevColor
                                anchors.right: parent.right; anchors.bottom: parent.bottom
                                border.color: "#60FFFFFF"; border.width: 1
                            }
                        }
                    }
                }
                
                // MAIN STACK
                StackLayout {
                    id: viewStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: 0
                    
                    // MODE 0: COLOR BOX
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 240
                                Layout.preferredHeight: 240
                                color: Qt.hsva(root.h, 1, 1, 1)
                                radius: 8
                                Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position:0;color:"white"} GradientStop{position:1;color:"transparent"} }}
                                Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position:0;color:"transparent"} GradientStop{position:1;color:"black"} }}
                                
                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    x: root.s * parent.width - 9
                                    y: (1.0 - root.v) * parent.height - 9
                                    color: "transparent"; border.color: "white"; border.width: 2
                                    Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: "transparent"; border.color: "black"; border.width: 1 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    function update(m) {
                                        root.s = Math.max(0, Math.min(1, m.x / width))
                                        root.v = 1.0 - Math.max(0, Math.min(1, m.y / height))
                                        root.updateColor()
                                    }
                                    onPressed: update(mouse)
                                    onPositionChanged: if(pressed) update(mouse)
                                    onReleased: root.addToHistory()
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                radius: 10
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
                                    x: root.h * (parent.width - 20)
                                    width: 20; height: 20; radius: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"; border.color: "#333"; border.width: 1
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -10
                                        drag.target: parent; drag.axis: Drag.XAxis; drag.minimumX: 0; drag.maximumX: parent.parent.width - 20
                                        onPositionChanged: { root.h = parent.x / (parent.parent.width - 20); updateColor() }
                                    }
                                }
                            }
                            
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
                                
                                GridLayout {
                                    columns: 5; rowSpacing: 5; columnSpacing: 5
                                    Repeater {
                                        model: backend.history
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 25
                                            color: modelData
                                            radius: 4
                                            MouseArea { anchors.fill: parent; onClicked: { root.currentColor = modelData } }
                                        }
                                    }
                                }
                                Item {
                                    Label { text: "No Palettes"; color: "#555"; anchors.centerIn: parent }
                                }
                            }
                        }
                    }
                    
                    // MODE 1: COLOR WHEEL - MEJORADO CON SEPARACIÓN
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 280
                                Layout.preferredHeight: 280
                                
                                // ============================================
                                // ANILLO DE HUE SEPARADO - CLAVE DEL DISEÑO
                                // ============================================
                                Canvas {
                                    id: hueRing
                                    anchors.fill: parent
                                    antialiasing: true
                                    
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.reset()
                                        
                                        var cx = width / 2
                                        var cy = height / 2
                                        
                                        // RADIOS AJUSTADOS PARA SEPARACIÓN VISIBLE
                                        var outerRadius = width * 0.48      // Radio exterior (96% del tamaño)
                                        var innerRadius = width * 0.38      // Radio interior (76% del tamaño)
                                        // Esto crea un anillo de 10% del ancho, separado del círculo central
                                        
                                        // Invertir el eje Y para que el gradiente cónico se vea correctamente
                                        ctx.save()
                                        ctx.translate(cx, cy)
                                        ctx.scale(1, -1)
                                        ctx.translate(-cx, -cy)
                                        
                                        // Gradiente cónico de colores
                                        var grad = ctx.createConicalGradient(cx, cy, 0)
                                        grad.addColorStop(0.000, Qt.hsva(0.000, 1, 1, 1))
                                        grad.addColorStop(0.166, Qt.hsva(0.166, 1, 1, 1))
                                        grad.addColorStop(0.333, Qt.hsva(0.333, 1, 1, 1))
                                        grad.addColorStop(0.500, Qt.hsva(0.500, 1, 1, 1))
                                        grad.addColorStop(0.666, Qt.hsva(0.666, 1, 1, 1))
                                        grad.addColorStop(0.833, Qt.hsva(0.833, 1, 1, 1))
                                        grad.addColorStop(1.000, Qt.hsva(1.000, 1, 1, 1))
                                        
                                        ctx.fillStyle = grad
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, outerRadius, 0, Math.PI * 2, false)
                                        ctx.arc(cx, cy, innerRadius, 0, Math.PI * 2, true)
                                        ctx.closePath()
                                        ctx.fill()
                                        ctx.restore()
                                    }
                                    
                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()
                                }
                                
                                // Mouse area para el anillo
                                MouseArea {
                                    anchors.fill: parent
                                    
                                    function updateHue(m) {
                                        var dx = m.x - width/2
                                        var dy = (height/2 - m.y)
                                        var dist = Math.sqrt(dx*dx + dy*dy)
                                        
                                        // Solo responder si el click está en el anillo (entre 0.38 y 0.48)
                                        var normalizedDist = dist / (width/2)
                                        if (normalizedDist >= 0.38 && normalizedDist <= 0.48) {
                                            var angle = Math.atan2(dy, dx)
                                            var h = angle / (Math.PI * 2)
                                            if (h < 0) h += 1.0
                                            root.h = (1.0 - h) % 1.0
                                            root.updateColor()
                                        }
                                    }
                                    
                                    onPressed: updateHue(mouse)
                                    onPositionChanged: if(pressed) updateHue(mouse)
                                    onReleased: root.addToHistory()
                                }
                                
                                // Indicador de posición en el anillo
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "transparent"
                                    border.color: "white"
                                    border.width: 3
                                    
                                    property real hVal: (1.0 - root.h) % 1.0
                                    property real angle: -(hVal * Math.PI * 2)
                                    // Posicionar en el centro del anillo (radio 0.43 = promedio de 0.38 y 0.48)
                                    property real ringRadius: parent.width * 0.43
                                    
                                    x: (parent.width/2) + Math.cos(angle) * ringRadius - width/2
                                    y: (parent.height/2) + Math.sin(angle) * ringRadius - height/2
                                    
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: "transparent"
                                        border.color: "black"
                                        border.width: 1
                                    }
                                    
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowBlur: 6
                                        shadowColor: "#80000000"
                                        shadowVerticalOffset: 2
                                    }
                                }
                                
                                // ============================================
                                // CÍRCULO/CUADRADO INTERIOR CON GAP VISIBLE
                                // ============================================
                                Rectangle {
                                    id: innerCircle
                                    // Tamaño del círculo interior (70% del total)
                                    width: parent.width * 0.70
                                    height: width
                                    radius: width / 2  // Círculo perfecto
                                    anchors.centerIn: parent
                                    
                                    color: Qt.hsva(root.h, 1, 1, 1)
                                    clip: true
                                    
                                    // Sombra para dar profundidad
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowBlur: 15
                                        shadowColor: "#60000000"
                                        shadowVerticalOffset: 3
                                    }
                                    
                                    // Gradiente blanco (saturación)
                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0; color: "white" }
                                            GradientStop { position: 1; color: "transparent" }
                                        }
                                    }
                                    
                                    // Gradiente negro (brillo)
                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            orientation: Gradient.Vertical
                                            GradientStop { position: 0; color: "transparent" }
                                            GradientStop { position: 1; color: "black" }
                                        }
                                    }
                                    
                                    // Indicador de selección
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: root.s * parent.width - width/2
                                        y: (1.0 - root.v) * parent.height - height/2
                                        color: "transparent"
                                        border.color: "white"
                                        border.width: 3
                                        
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: "transparent"
                                            border.color: "black"
                                            border.width: 1
                                        }
                                    }
                                    
                                    // Mouse area para selección de saturación/brillo
                                    MouseArea {
                                        anchors.fill: parent
                                        
                                        function updateSV(m) {
                                            root.s = Math.max(0, Math.min(1, m.x / width))
                                            root.v = 1.0 - Math.max(0, Math.min(1, m.y / height))
                                            root.updateColor()
                                        }
                                        
                                        onPressed: updateSV(mouse)
                                        onPositionChanged: if(pressed) updateSV(mouse)
                                        onReleased: root.addToHistory()
                                    }
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // MODE 2: HARMONY
                    Item { Label { text: "Harmony Mode"; color: "#666"; anchors.centerIn: parent } }
                    
                    // MODE 3: SLIDERS
                    Item { Label { text: "Sliders Mode"; color: "#666"; anchors.centerIn: parent } }
                }
            }
        }
    }
}
