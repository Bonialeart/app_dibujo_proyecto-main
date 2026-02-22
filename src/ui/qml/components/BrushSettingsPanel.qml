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
                value: mainCanvas ? mainCanvas.brushSize / 200.0 : 0.05
                displayValue: mainCanvas ? Math.round(mainCanvas.brushSize) : 10
                decimals: 0
                accent: accentColor
                onMoved: (val) => { if (mainCanvas) mainCanvas.brushSize = val * 200 }
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
                value: mainCanvas ? mainCanvas.brushSize / 200.0 : 0.05
                displayValue: mainCanvas ? Math.round(mainCanvas.brushSize) : 10
                decimals: 0
                accent: accentColor
                onMoved: (val) => { 
                    var bWidth = val * 200;
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
