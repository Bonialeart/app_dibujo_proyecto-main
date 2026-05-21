import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    readonly property string currentTool: targetCanvas ? (targetCanvas.currentToolName || "Brush") : "Brush"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16
        
        // Tool Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Rectangle {
                width: 32; height: 32; radius: 6
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1)
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                Text {
                    text: root.getToolIcon(root.currentTool)
                    anchors.centerIn: parent
                    font.pixelSize: 16
                    color: accentColor
                }
            }
            
            ColumnLayout {
                spacing: 0
                Text {
                    text: root.currentTool.toUpperCase()
                    color: "white"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }
                Text {
                    text: "Configuración de herramienta"
                    color: "#666"
                    font.pixelSize: 10
                }
            }
        }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: "#1a1a1e" }
        
        // Settings based on tool
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: settingsCol.height
            clip: true
            
            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: 20
                
                // Example setting: Stabilization (Common for Brush/Eraser)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.currentTool === "Brush" || root.currentTool === "Eraser"
                    
                    RowLayout {
                        Text { text: "Estabilización"; color: "#999"; font.pixelSize: 11; Layout.fillWidth: true }
                        Text { text: Math.round((targetCanvas ? targetCanvas.brushStabilization : 0) * 100) + "%"; color: accentColor; font.pixelSize: 11; font.family: "Monospace" }
                    }
                    Slider {
                        Layout.fillWidth: true
                        value: targetCanvas ? targetCanvas.brushStabilization : 0
                        onValueChanged: if(targetCanvas && pressed) targetCanvas.brushStabilization = value
                        // Custom styling here...
                    }
                }

                // Stabilizer Mode Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.currentTool === "Brush" || root.currentTool === "Eraser"
                    
                    Text { text: "Algoritmo de Suavizado"; color: "#999"; font.pixelSize: 11 }
                    
                    RowLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Doble EMA", "WMA", "Lazy Mouse"]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 28; radius: 4
                                color: (targetCanvas && targetCanvas.brushStabilizerMode === (index + 1)) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                                border.color: (targetCanvas && targetCanvas.brushStabilizerMode === (index + 1)) ? accentColor : "#2a2a2d"
                                
                                Text {
                                    text: modelData
                                    anchors.centerIn: parent
                                    color: (targetCanvas && targetCanvas.brushStabilizerMode === (index + 1)) ? "white" : "#999"
                                    font.pixelSize: 10; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if(targetCanvas) {
                                            targetCanvas.brushStabilizerMode = index + 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Example setting: Symmetry
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { text: "Modo de Espejo"; color: "#999"; font.pixelSize: 11 }
                    
                    RowLayout {
                        spacing: 4
                        Repeater {
                            model: ["Off", "H", "V", "Radial"]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 28; radius: 4
                                color: (targetCanvas && targetCanvas.symmetryMode === index && targetCanvas.symmetryEnabled) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                                border.color: (targetCanvas && targetCanvas.symmetryMode === index && targetCanvas.symmetryEnabled) ? accentColor : "#2a2a2d"
                                
                                Text {
                                    text: modelData
                                    anchors.centerIn: parent
                                    color: (targetCanvas && targetCanvas.symmetryMode === index && targetCanvas.symmetryEnabled) ? "white" : "#666"
                                    font.pixelSize: 10; font.weight: Font.DemiBold
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if(!targetCanvas) return
                                        if(index === 0) targetCanvas.symmetryEnabled = false
                                        else {
                                            targetCanvas.symmetryEnabled = true
                                            targetCanvas.symmetryMode = index - 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Placeholder for other settings
                Text {
                    text: "Más ajustes próximamente..."
                    color: "#333"
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
    
    function getToolIcon(name) {
        switch(name) {
            case "Brush": return "🖌️";
            case "Eraser": return "🧹";
            case "Fill": return "🪣";
            case "Selection": return "✂️";
            default: return "🛠️";
        }
    }
}
