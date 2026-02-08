import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root
    
    // Properties
    property var canvasItem: null
    property real currentGamma: canvasItem ? canvasItem.pressureGamma : 1.0
    
    // Permitir interacción con el fondo para probar el pincel
    modal: false
    dim: false 
    
    focus: true
    width: 600
    height: 480
    
    anchors.centerIn: parent
    
    // Sincronizar al abrir
    onOpened: {
        if (canvasItem) currentGamma = canvasItem.pressureGamma
        updateCurve()
    }

    // Actualizar canvas cuando cambia gamma
    onCurrentGammaChanged: {
        if (canvasItem) canvasItem.pressureGamma = currentGamma
        updateCurve()
    }
    
    function updateCurve() {
        curveCanvas.requestPaint()
    }
    
    background: Rectangle {
        color: "#252526"
        border.color: "#3e3e42"
        radius: 8
        Rectangle { z: -1; anchors.fill: parent; anchors.margins: -4; opacity: 0.3; color: "black"; radius: 12 }
    }
    
    // --- Header ---
    Text {
        text: "Ajuste de Presión del Lápiz"
        color: "white"
        font.pixelSize: 18
        font.bold: true
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 20
    }
    
    Button {
        text: "✕"
        background: Rectangle { color: "transparent" }
        contentItem: Text { text: "✕"; color: "#aaa"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter }
        width: 40; height: 40
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 10
        onClicked: root.close()
    }
    
    RowLayout {
        anchors.fill: parent; anchors.topMargin: 60; anchors.bottomMargin: 20; anchors.leftMargin: 20; anchors.rightMargin: 20
        spacing: 30
        
        // LEFT: Graph Visualizer
        ColumnLayout {
            Layout.preferredWidth: 260
            spacing: 10

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: "#1e1e1e"
                border.color: "#333"
                radius: 4
                clip: true
                
                Canvas {
                    id: curveCanvas
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    onPaint: {
                        var ctx = getContext("2d")
                        var w = width
                        var h = height
                        
                        ctx.clearRect(0,0,w,h)
                        
                        // Grid
                        ctx.strokeStyle = "#333"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(0,h); ctx.lineTo(w,0); // Diagonal ref
                        ctx.stroke()
                        
                        // Curve: Y = X ^ Gamma
                        ctx.strokeStyle = "#00d4aa" // Accent Color
                        ctx.lineWidth = 3
                        ctx.beginPath()
                        ctx.moveTo(0, h) // Start at bottom-left
                        
                        for (var i=0; i<=w; i+=2) {
                            var xNorm = i / w;
                            var yNorm = Math.pow(xNorm, root.currentGamma);
                            // Invert Y coordinate because canvas 0 is top
                            ctx.lineTo(i, h - (yNorm * h));
                        }
                        ctx.stroke()
                    }
                }
                
                // Labels
                Text { text: "Suave"; color: "#666"; font.pixelSize: 10; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 4 }
                Text { text: "Duro"; color: "#666"; font.pixelSize: 10; anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 4 }
            }
            
            // Slider Control
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Sensibilidad:"; color: "#ddd" }
                Slider {
                    id: gammaSlider
                    Layout.fillWidth: true
                    from: 0.2; to: 2.5
                    value: root.currentGamma
                    onMoved: root.currentGamma = value
                }
                Text { text: root.currentGamma.toFixed(2); color: "#00d4aa"; font.bold: true; font.pixelSize: 14 }
            }
            
             Text { 
                text: root.currentGamma < 1.0 ? "Más sensible (Tooque suave = Trazo fuerte)" : 
                      (root.currentGamma > 1.0 ? "Menos sensible (Hay que apretar más)" : "Lineal (Estándar)")
                color: "#888"; font.pixelSize: 11
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        
        // RIGHT: Test Area
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 10
            
            Text { text: "Área de Prueba (Dibuja aquí)"; color: "#ccc"; font.pixelSize: 12 }
            
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: "#121214"
                border.color: "#444"
                radius: 4
                
                // Nota: Como CanvasItem es único, aquí solo mostramos un placeholder.
                // El usuario debe probar en el lienzo real que está detrás (el popup es modal pero deja ver).
                // O podríamos hacer el popup NO modal para que interactúe con el canvas de fondo.
                
                Text {
                    text: "Usa el lienzo principal de fondo para probar\n(Cierra este diálogo o muévelo si tapa el dibujo)"
                    anchors.centerIn: parent
                    color: "#555"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Restablecer"
                    Layout.fillWidth: true
                    onClicked: root.currentGamma = 1.0
                    background: Rectangle { color: "#333"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                
                Button {
                    text: "Listo"
                    Layout.fillWidth: true
                    onClicked: root.close()
                    background: Rectangle { color: "#00d4aa"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "black"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true }
                }
            }
        }
    }
}
