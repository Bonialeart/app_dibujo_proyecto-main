import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16
        
        Text { text: "INFORMACIÓN"; color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
        
        GridLayout {
            columns: 2
            rowSpacing: 12
            columnSpacing: 12
            Layout.fillWidth: true
            
            // Dimensions
            Text { text: "Dimensiones"; color: "#666"; font.pixelSize: 11 }
            Text { 
                text: targetCanvas ? (targetCanvas.canvasWidth + " × " + targetCanvas.canvasHeight) : "1920 × 1080"
                color: "white"; font.pixelSize: 11; font.family: "Monospace"
                Layout.alignment: Qt.AlignRight
            }
            
            // Zoom
            Text { text: "Zoom"; color: "#666"; font.pixelSize: 11 }
            Text { 
                text: (targetCanvas ? Math.round(targetCanvas.zoomLevel * 100) : 100) + "%"
                color: "white"; font.pixelSize: 11; font.family: "Monospace"
                Layout.alignment: Qt.AlignRight
            }
            
            // Rotation
            Text { text: "Rotación"; color: "#666"; font.pixelSize: 11 }
            Text { 
                text: (targetCanvas ? Math.round(targetCanvas.canvasRotation) : 0) + "°"
                color: "white"; font.pixelSize: 11; font.family: "Monospace"
                Layout.alignment: Qt.AlignRight
            }
            
            // Memory (Mockup)
            Text { text: "Memoria VRAM"; color: "#666"; font.pixelSize: 11 }
            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 4
                Text { text: "128 MB / 4 GB"; color: "#aaa"; font.pixelSize: 10; font.family: "Monospace"; Layout.alignment: Qt.AlignRight }
                Rectangle {
                    width: 80; height: 4; radius: 2; color: "#1a1a1e"
                    Rectangle { width: 12; height: 4; radius: 2; color: accentColor }
                }
            }
        }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: "#1a1a1e" }
        
        // Color Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text { text: "Color Actual"; color: "#666"; font.pixelSize: 11 }
            
            RowLayout {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: targetCanvas ? targetCanvas.currentColor : "#ff0000"
                    border.color: "#333"
                }
                ColumnLayout {
                    spacing: 2
                    Text { 
                        text: "HEX: " + (targetCanvas ? targetCanvas.currentColor.toString().toUpperCase() : "#FF0000")
                        color: "white"; font.pixelSize: 10; font.family: "Monospace"
                    }
                    Text { 
                        text: "RGB: 255, 0, 0"; color: "#999"; font.pixelSize: 9; font.family: "Monospace"
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
