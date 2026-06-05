import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    
    property var targetCanvas: null
    property var mainCanvas: targetCanvas
    property int activeToolIdx: -1 // Added to prevent crash from main_pro binding
    
    property color accentColor: "#6366f1"
    property alias colorAccent: root.accentColor // Added to support main_pro binding
    
    property bool isShapeTool: {
        if (!mainCanvas) return false;
        var tool = mainCanvas.currentTool;
        console.log("[BrushSettingsPanel] Current tool:", tool);
        return ["shape", "rect", "ellipse", "line", "panel", "bubble", "shapes"].indexOf(tool) !== -1 || tool.startsWith("panel_") || tool.startsWith("bubble_");
    }
    
    Flickable {
        anchors.fill: parent; anchors.margins: 10
        contentHeight: settingsCol.implicitHeight
        clip: true; flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: settingsCol
            width: parent.width; spacing: 14
            visible: !root.isShapeTool

            // Size slider
            StudioSlider {
                Layout.fillWidth: true
                label: "Size"; unit: "px"
                value: mainCanvas ? Math.pow((mainCanvas.brushSize - 0.5) / 1999.5, 1.0 / 3.0) : 0.01
                displayValue: mainCanvas ? Math.round(mainCanvas.brushSize) : 10
                decimals: 0
                accent: accentColor
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushSize = 0.5 + 1999.5 * Math.pow(val, 3.0) }
            }

            // Opacity
            StudioSlider {
                Layout.fillWidth: true
                label: "Opacity"; unit: "%"
                value: mainCanvas ? mainCanvas.brushOpacity : 1.0
                displayValue: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) : 100
                decimals: 0
                accent: accentColor
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushOpacity = val }
            }

            // Flow
            StudioSlider {
                Layout.fillWidth: true
                label: "Flow"; unit: "%"
                value: mainCanvas ? mainCanvas.brushFlow : 1.0
                displayValue: mainCanvas ? Math.round(mainCanvas.brushFlow * 100) : 100
                decimals: 0
                accent: accentColor
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushFlow = val }
            }

            // Hardness
            StudioSlider {
                Layout.fillWidth: true
                label: "Hardness"; unit: "%"
                value: mainCanvas ? mainCanvas.brushHardness : 1.0
                displayValue: mainCanvas ? Math.round(mainCanvas.brushHardness * 100) : 100
                decimals: 0
                accent: accentColor
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushHardness = val }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252a" }

            // Pressure Dynamics Quick Toggles
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Text { 
                    text: "PRESSURE SENSITIVITY"
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: "#6b7280"; Layout.fillWidth: true
                    font.letterSpacing: 1
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Size Response"; color: "white"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch {
                        checked: mainCanvas ? mainCanvas.sizeByPressure : true
                        onCheckedChanged: if(mainCanvas) mainCanvas.sizeByPressure = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Opacity Response"; color: "white"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch {
                        checked: mainCanvas ? mainCanvas.opacityByPressure : true
                        onCheckedChanged: if(mainCanvas) mainCanvas.opacityByPressure = checked
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252a" }

            // Spacing
            StudioSlider {
                Layout.fillWidth: true
                label: "Spacing"; unit: "%"
                value: mainCanvas ? mainCanvas.brushSpacing : 0.25
                displayValue: mainCanvas ? Math.round(mainCanvas.brushSpacing * 100) : 25
                decimals: 0
                accent: "#4a9eff"
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushSpacing = Math.max(0.01, val) }
            }

            // Stabilization
            StudioSlider {
                Layout.fillWidth: true
                label: "Stabilization"; unit: "%"
                value: mainCanvas ? mainCanvas.brushStabilization : 0.0
                displayValue: mainCanvas ? Math.round(mainCanvas.brushStabilization * 100) : 0
                decimals: 0
                accent: "#6366f1"
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushStabilization = val }
            }

            // Stabilization Mode
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text { 
                    text: "ALGORITMO DE SUAVIZADO"
                    font.pixelSize: 10; font.weight: Font.Bold
                    color: "#6b7280"; Layout.fillWidth: true
                    font.letterSpacing: 1
                }

                RowLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Repeater {
                        model: ["Doble EMA", "WMA", "Lazy Mouse"]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 28; radius: 4
                            color: (mainCanvas && mainCanvas.brushStabilizerMode === (index + 1)) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                            border.color: (mainCanvas && mainCanvas.brushStabilizerMode === (index + 1)) ? accentColor : "#2a2a2d"
                            
                            Text {
                                text: modelData
                                anchors.centerIn: parent
                                color: (mainCanvas && mainCanvas.brushStabilizerMode === (index + 1)) ? "white" : "#999"
                                font.pixelSize: 10; font.weight: Font.DemiBold
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if(mainCanvas) {
                                        mainCanvas.brushStabilizerMode = index + 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- SHAPE / COMIC PANEL SETTINGS ---
        ColumnLayout {
            id: shapeSettingsCol
            width: parent.width; spacing: 14
            visible: root.isShapeTool

            Text {
                text: "TOOL PROPERTIES"
                font.pixelSize: 10; font.weight: Font.Bold
                color: "#6b7280"; Layout.fillWidth: true
                font.letterSpacing: 1
            }
            
            // Reusing mainCanvas settings for border size where possible
            StudioSlider {
                Layout.fillWidth: true
                label: "Border Width"; unit: "px"
                value: mainCanvas ? Math.pow((mainCanvas.brushSize - 0.5) / 1999.5, 1.0 / 3.0) : 0.01
                displayValue: mainCanvas ? Math.round(mainCanvas.brushSize) : 10
                decimals: 0
                accent: accentColor
                onMoved: (val) => { 
                    var bWidth = 0.5 + 1999.5 * Math.pow(val, 3.0);
                    if (mainCanvas) mainCanvas.brushSize = bWidth;
                    if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                        mainWindow.comicOverlayManager.setSelectedBorderWidth(bWidth);
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#25252a" }

            Text {
                text: "SHAPE OPACITY"
                font.pixelSize: 10; font.weight: Font.Bold
                color: "#6b7280"; Layout.fillWidth: true
                font.letterSpacing: 1
            }

            StudioSlider {
                Layout.fillWidth: true
                label: "Opacity"; unit: "%"
                value: mainCanvas ? mainCanvas.brushOpacity : 1.0
                displayValue: mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) : 100
                decimals: 0
                accent: accentColor
                onMoved: (val) => { 
                    if (mainCanvas) mainCanvas.brushOpacity = val;
                    if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                        mainWindow.comicOverlayManager.setSelectedOpacity(val);
                    }
                }
            }
        }
    }
}
