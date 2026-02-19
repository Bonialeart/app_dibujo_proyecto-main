import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root
    property color dropColor: "blue"
    property bool active: false
    
    // --- Gooey Properties ---
    property real startX: 0
    property real startY: 0
    property real maxStretch: 150 // Un poco más largo para efecto pro
    
    // Cálculos dinámicos de movimiento
    readonly property real dx: x - startX
    readonly property real dy: y - startY
    readonly property real distance: Math.sqrt(dx*dx + dy*dy)
    readonly property real angle: Math.atan2(dy, dx) * 180 / Math.PI
    property bool isSnapped: false

    // Lógica de ruptura (Snap)
    onDistanceChanged: {
        if (!isSnapped && distance > maxStretch) {
            isSnapped = true
            snapBounce.restart() 
        } else if (isSnapped && distance < 15) {
            isSnapped = false 
        }
    }

    // Tamaño base (Orbe principal)
    width: 38; height: 38
    visible: active
    z: 9999
    
    // Centrado suave
    transform: Translate { x: -width/2; y: -height/2 }

    // Animación de entrada/salida
    scale: active ? 1.0 : 0.0
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

    // --- ANIMACIONES ---
    SequentialAnimation {
        id: snapBounce
        NumberAnimation { target: orbVisual; property: "scale"; to: 1.35; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { target: orbVisual; property: "scale"; to: 0.8; duration: 150; easing.type: Easing.InOutSine }
        NumberAnimation { target: orbVisual; property: "scale"; to: 1.0; duration: 300; easing.type: Easing.OutElastic }
    }

    // 1. GOTA RESIDUAL (Se queda en el origen)
    Rectangle {
        id: originGlob
        property real size: Math.max(0, 24 * (1 - root.distance / root.maxStretch))
        width: size; height: size
        radius: size / 2
        color: root.dropColor
        opacity: 0.8
        
        // Se mantiene fija en startX/startY compensando el movimiento del padre
        x: (root.width / 2) - root.dx - (size / 2)
        y: (root.height / 2) - root.dy - (size / 2)
        
        visible: !root.isSnapped && root.distance > 5 && root.active

        // Brillo sutil en la gota de origen
        Rectangle {
            anchors.fill: parent; anchors.margins: 2; radius: width/2
            color: "white"; opacity: 0.3
        }
    }

    // 2. PUENTE LÍQUIDO GOOEY (Shapes)
    Shape {
        id: gooeyBridge
        anchors.centerIn: parent
        visible: !root.isSnapped && root.distance > 8 && root.active
        rotation: root.angle - 90
        z: -1
        
        // MultiEffect para suavizar el puente
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: false
            blurEnabled: true
            blur: 0.1 // Difuminado mínimo para realismo orgánico
        }

        ShapePath {
            fillColor: root.dropColor
            strokeWidth: 0
            
            property real d: root.distance
            property real w: Math.max(3, 16 * (1 - d / root.maxStretch))
            property real controlY: -d * 0.5
            
            // Base en el orbe (superior)
            startX: -16; startY: 0
            
            // Lado izquierdo estirándose hacia el origen
            PathCubic { 
                x: -w; y: -d 
                control1X: -16; control1Y: controlY 
                control2X: -w; control2Y: controlY 
            }
            // Línea en el origen
            PathLine { x: w; y: -d }
            // Lado derecho volviendo al orbe
            PathCubic { 
                x: 16; y: 0 
                control1X: w; control1Y: controlY 
                control2X: 16; control2Y: controlY 
            }
        }
    }

    // 3. ORBE PRINCIPAL (Tu diseño Premium anterior)
    Item {
        id: orbVisual
        anchors.fill: parent

        // Aura exterior (Latido)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 1.4; height: width; radius: width/2
            color: root.dropColor; opacity: 0.15; z: -1
            SequentialAnimation on scale {
                loops: Animation.Infinite; running: root.active
                NumberAnimation { to: 1.15; duration: 2500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.85; duration: 2500; easing.type: Easing.InOutSine }
            }
        }

        // Cápsula de Cristal
        Rectangle {
            id: glassShell
            anchors.fill: parent; radius: width/2
            color: "#1affffff"; border.color: "white"; border.width: 1.5
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.8; shadowVerticalOffset: 3
            }

            Rectangle {
                anchors.fill: parent; radius: width/2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#45ffffff" }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
        }

        // Núcleo Suspendido
        Rectangle {
            id: core
            anchors.fill: parent; anchors.margins: 6; radius: width/2
            color: root.dropColor
            Rectangle {
                anchors.fill: parent; radius: width/2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#66ffffff" }
                    GradientStop { position: 0.3; color: "transparent" }
                    GradientStop { position: 0.7; color: "transparent" }
                    GradientStop { position: 1.0; color: "#33000000" }
                }
            }
        }
    }
}
