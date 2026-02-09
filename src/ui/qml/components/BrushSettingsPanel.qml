import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Properties
    property var targetCanvas: null
    property int activeToolIdx: 0
    property color colorAccent: "#4A90E2"
    
    // Appearance
    width: 280
    height: settingsLayout.implicitHeight + 40
    radius: 16
    color: "#1E1E1E" // Dark Mode Background
    border.color: "#333333"
    border.width: 1
    
    // Shadow simulation
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.margins: -4
        color: "#000000"
        opacity: 0.3
        radius: 20
    }

    ColumnLayout {
        id: settingsLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "BRUSH SETTINGS"
                color: "#888888"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
                Layout.fillWidth: true
            }
            
            Text {
                text: "×"
                color: "#666666"
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = false
                }
            }
        }
        
        Rectangle { height: 1; Layout.fillWidth: true; color: "#333333" }
        
        // --- DYNAMIC SETTINGS CONTENT ---
        
        // SIZE
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text { text: "Size"; color: "#E0E0E0"; font.pixelSize: 12; Layout.preferredWidth: 60 }
            
            PremiumSlider {
                Layout.fillWidth: true
                from: 1; to: 500
                value: targetCanvas ? targetCanvas.brushSize : 10
                onMoved: if(targetCanvas) targetCanvas.brushSize = value
                accentColor: root.colorAccent
            }
            
            Text { 
                text: targetCanvas ? Math.round(targetCanvas.brushSize) : "0"
                color: "#E0E0E0"; font.pixelSize: 12; 
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }

        // OPACITY
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text { text: "Opacity"; color: "#E0E0E0"; font.pixelSize: 12; Layout.preferredWidth: 60 }
            
            PremiumSlider {
                Layout.fillWidth: true
                from: 0; to: 1.0
                value: targetCanvas ? targetCanvas.brushOpacity : 1.0
                onMoved: if(targetCanvas) targetCanvas.brushOpacity = value
                accentColor: root.colorAccent
            }
            
            Text { 
                text: targetCanvas ? Math.round(targetCanvas.brushOpacity * 100) + "%" : "0%"
                color: "#E0E0E0"; font.pixelSize: 12; 
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // FLOW / SPACING
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text { text: "Spacing"; color: "#E0E0E0"; font.pixelSize: 12; Layout.preferredWidth: 60 }
            
            PremiumSlider {
                Layout.fillWidth: true
                from: 0.01; to: 1.0
                value: targetCanvas ? targetCanvas.brushSpacing : 0.1
                onMoved: if(targetCanvas) targetCanvas.brushSpacing = value
                accentColor: root.colorAccent
            }
            
            Text { 
                text: targetCanvas ? Math.round(targetCanvas.brushSpacing * 100) + "%" : "0%"
                color: "#E0E0E0"; font.pixelSize: 12; 
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // SMOOTHING
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text { text: "Smooth"; color: "#E0E0E0"; font.pixelSize: 12; Layout.preferredWidth: 60 }
            
            PremiumSlider {
                Layout.fillWidth: true
                from: 0; to: 0.95
                value: targetCanvas ? targetCanvas.brushSmoothing : 0
                onMoved: if(targetCanvas) targetCanvas.brushSmoothing = value
                accentColor: root.colorAccent
            }
            
            Text { 
                text: targetCanvas ? Math.round(targetCanvas.brushSmoothing * 100) + "%" : "0%"
                color: "#E0E0E0"; font.pixelSize: 12; 
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // HARDNESS
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: activeToolIdx !== 3 // Hide for some tools if needed, e.g. Pencil might use Grain instead
            
            Text { text: "Hardness"; color: "#E0E0E0"; font.pixelSize: 12; Layout.preferredWidth: 60 }
            
            PremiumSlider {
                Layout.fillWidth: true
                from: 0; to: 1.0
                value: targetCanvas ? targetCanvas.brushHardness : 0.5
                onMoved: if(targetCanvas) targetCanvas.brushHardness = value
                accentColor: root.colorAccent
            }
            
            Text { 
                text: targetCanvas ? Math.round(targetCanvas.brushHardness * 100) + "%" : "0%"
                color: "#E0E0E0"; font.pixelSize: 12; 
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
        
        // GRAIN (Pencil Only - Example Logic)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: activeToolIdx === 3 // Pencil Index
            
            Text { text: "Grain"; color: "#E0E0E0"; font.pixelSize: 12; Layout.preferredWidth: 60 }
            
            PremiumSlider {
                Layout.fillWidth: true
                from: 0; to: 1.0
                value: targetCanvas ? targetCanvas.brushGrain : 0.0
                onMoved: if(targetCanvas) targetCanvas.brushGrain = value
                accentColor: root.colorAccent
            }
            
            Text { 
                text: targetCanvas ? Math.round(targetCanvas.brushGrain * 100) + "%" : "0%"
                color: "#E0E0E0"; font.pixelSize: 12; 
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
