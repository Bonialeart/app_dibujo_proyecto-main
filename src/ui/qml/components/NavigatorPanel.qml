import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16
        
        // 1. MINIMAP PREMIUM
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0a0a0d"
            radius: 8
            border.color: "#2a2a2d"
            clip: true
            
            // Patrón tenue para indicar transparencia
            Image { anchors.fill: parent; source: "image://icons/grid_pattern.svg"; fillMode: Image.Tile; opacity: 0.1 }
            
            // Representación del Canvas
            Rectangle {
                width: parent.width * 0.7; height: parent.height * 0.7
                anchors.centerIn: parent; color: "#e0e0e0"; radius: 2 // Canvas "Blanco"
                
                layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 10; shadowColor: "#cc000000" }
                
                // Indicador de Viewport (Cámara actual)
                Rectangle {
                    width: parent.width * 0.6; height: parent.height * 0.6; anchors.centerIn: parent
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                    border.color: root.accentColor; border.width: 1.5
                    
                    // Crosshair central
                    Rectangle { width: 8; height: 1; color: root.accentColor; anchors.centerIn: parent }
                    Rectangle { width: 1; height: 8; color: root.accentColor; anchors.centerIn: parent }
                }
            }
        }
        
        // 2. SLIDERS COMPACTOS
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            // Zoom Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Image { id: searchIcon; source: "image://icons/search.svg"; width: 12; height: 12; opacity: 0.5; visible: status === Image.Ready }
                Text { text: "🔍"; color: "#666"; font.pixelSize: 10; visible: searchIcon.status !== Image.Ready } 
                
                Slider {
                    Layout.fillWidth: true; from: 0.1; to: 4.0; value: 1.0
                    background: Rectangle {
                        x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 200; implicitHeight: 3; radius: 1.5; color: "#1c1c1e"
                        Rectangle { width: parent.visualPosition * parent.width; height: parent.height; color: root.accentColor; radius: 1.5 }
                    }
                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 10; implicitHeight: 10; radius: 5
                        color: parent.pressed ? "white" : "#ccc"; border.color: "#555"; border.width: 1
                    }
                }
                Text { text: "100%"; color: "#aaa"; font.pixelSize: 10; font.family: "Monospace"; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
            }
            
            // Angle Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Image { id: rotateIcon; source: "image://icons/rotate-cw.svg"; width: 12; height: 12; opacity: 0.5; visible: status === Image.Ready }
                Text { text: "↻"; color: "#666"; font.pixelSize: 12; visible: rotateIcon.status !== Image.Ready; anchors.verticalCenterOffset: -2 } 
                
                Slider {
                    Layout.fillWidth: true; from: -180; to: 180; value: 0
                    background: Rectangle {
                        x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 200; implicitHeight: 3; radius: 1.5; color: "#1c1c1e"
                        Rectangle { width: parent.visualPosition * parent.width; height: parent.height; color: "#666"; radius: 1.5 }
                        Rectangle { width: 2; height: 7; color: "#888"; anchors.centerIn: parent } 
                    }
                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 10; implicitHeight: 10; radius: 5
                        color: parent.pressed ? "white" : "#ccc"; border.color: "#555"; border.width: 1
                    }
                }
                Text { text: "0°"; color: "#aaa"; font.pixelSize: 10; font.family: "Monospace"; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
            }
        }
    }
}
