import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

PopOverPanel {
    id: root
    title: "Efectos de Material (Óleo)"
    width: 300
    height: 400
    
    // Referencia al CanvasItem que estamos controlando
    property var targetCanvas: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        // 1. RELIEVE (FUERZA)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text { 
                text: "Profundidad del Relieve" 
                color: "#e0e0e0"
                font.pixelSize: 14
            }
            
            ProSlider {
                Layout.fillWidth: true
                from: 0.0
                to: 10.0
                value: targetCanvas ? targetCanvas.impastoStrength : 1.0
                onMoved: {
                    if (targetCanvas) targetCanvas.impastoStrength = value
                }
            }
        }

        // 2. BRILLO (WETNESS)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text { 
                text: "Brillo / Humedad" 
                color: "#e0e0e0"
                font.pixelSize: 14
            }
            
            ProSlider {
                Layout.fillWidth: true
                from: 1.0
                to: 256.0
                value: targetCanvas ? targetCanvas.impastoShininess : 64.0
                onMoved: {
                    if (targetCanvas) targetCanvas.impastoShininess = value
                }
            }
        }

        // 3. DIRECCIÓN DE LA LUZ (Ángulo)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text { 
                text: "Dirección de la Luz" 
                color: "#e0e0e0"
                font.pixelSize: 14
            }
            
            // Un control visual circular simple para la luz
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 100; height: 100
                
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#333"
                    border.color: "#555"
                }

                // El "Sol" que gira
                Rectangle {
                    id: sun
                    width: 20; height: 20
                    radius: 10
                    color: "#FFD700" // Dorado
                    x: (parent.width/2 - 10) + Math.cos(targetCanvas ? targetCanvas.lightAngle * Math.PI / 180 : 0) * 35
                    y: (parent.height/2 - 10) - Math.sin(targetCanvas ? targetCanvas.lightAngle * Math.PI / 180 : 0) * 35
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: {
                        var dx = mouse.x - width/2
                        var dy = mouse.y - height/2
                        var angleRad = Math.atan2(-dy, dx)
                        var angleDeg = angleRad * 180 / Math.PI
                        if (angleDeg < 0) angleDeg += 360
                        
                        if (targetCanvas) targetCanvas.lightAngle = angleDeg
                    }
                }
            }
        }
        
        // 4. ALTURA DE LA LUZ (Sombra dura vs suave)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text { 
                text: "Elevación de la Luz" 
                color: "#e0e0e0"
                font.pixelSize: 14
            }
            
            ProSlider {
                Layout.fillWidth: true
                from: 0.1
                to: 1.0
                value: targetCanvas ? targetCanvas.lightElevation : 0.5
                onMoved: {
                    if (targetCanvas) targetCanvas.lightElevation = value
                }
            }
        }
    }
}
