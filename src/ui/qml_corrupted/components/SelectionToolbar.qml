import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ArtFlow 1.0

Item {
    id: root
    property var canvas
    property var uiScale: 1.0
    property color accentColor: "#6366f1"
    
    height: 70 * uiScale
    width: 600 * uiScale // Fixed width for debugging visibility
    
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40 * uiScale
    
    visible: canvas ? (canvas.isSelectionModeActive || canvas.currentTool === "lasso" || canvas.currentTool === "select_rect" || canvas.currentTool === "select_ellipse" || canvas.currentTool === "select_wand") : false
    
    onVisibleChanged: {
        console.log("[SelectionToolbar] Visible:", visible);
        if (canvas) console.log("[SelectionToolbar] Tool:", canvas.currentTool, "ActiveFlag:", canvas.isSelectionModeActive);
    }
    
    // Glass Background (Simplified to avoid MultiEffect issues)
    Rectangle {
        anchors.fill: parent
        radius: 35 * uiScale
        color: "#f01a1a1c" // Higher opacity
        border.color: "#66ffffff"
        border.width: 2 * uiScale
    }
    
    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 15 * uiScale
        
        // --- FAVORITES ---
        Item {
            width: 32 * uiScale; height: 32 * uiScale
            Image {
                anchors.fill: parent
                source: "../../../../assets/icons/cat_favorites.svg"
                sourceSize: Qt.size(32 * root.uiScale, 32 * root.uiScale)
                opacity: 0.8
            }
            MouseArea { anchors.fill: parent; onClicked: root.canvas.notificationRequested("Favorites not implemented yet", "info") }
        }
        
        // --- MODIFIERS (Add / Remove) ---
        Row {
            spacing: 2 * uiScale
            Rectangle {
                width: 60 * uiScale; height: 32 * uiScale
                radius: 16 * uiScale
                color: root.canvas && root.canvas.selectionAddMode === 1 ? "#33ffffff" : "transparent"
                border.color: root.canvas && root.canvas.selectionAddMode === 1 ? root.accentColor : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "Add"
                    color: "white"
                    font.pixelSize: 12 * uiScale
                    font.weight: root.canvas && root.canvas.selectionAddMode === 1 ? Font.Bold : Font.Normal
                }
                MouseArea { anchors.fill: parent; onClicked: root.canvas.selectionAddMode = 1 }
            }
            Rectangle {
                width: 70 * uiScale; height: 32 * uiScale
                radius: 16 * uiScale
                color: root.canvas && root.canvas.selectionAddMode === 2 ? "#33ffffff" : "transparent"
                border.color: root.canvas && root.canvas.selectionAddMode === 2 ? root.accentColor : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "Remove"
                    color: "white"
                    font.pixelSize: 12 * uiScale
                    font.weight: root.canvas && root.canvas.selectionAddMode === 2 ? Font.Bold : Font.Normal
                }
                MouseArea { anchors.fill: parent; onClicked: root.canvas.selectionAddMode = 2 }
            }
        }
        
        // --- DIVIDER ---
        Rectangle { width: 1; height: 24 * uiScale; color: "#44ffffff" }
        
        // --- TOOLS ---
        RowLayout {
            spacing: 12 * uiScale
            
            ToolIcon {
                id: freeSelectBtn
                icon: "lasso.svg"
                active: root.canvas && root.canvas.currentTool === "lasso"
                onClicked: root.canvas.currentTool = "lasso"
            }
            
            ToolIcon {
                icon: "shapes.svg"
                active: root.canvas && root.canvas.currentTool === "select_rect"
                onClicked: root.canvas.currentTool = "select_rect"
            }
            
            ToolIcon {
                icon: "shapes.svg" // Should be Ellipse
                active: root.canvas && root.canvas.currentTool === "select_ellipse"
                onClicked: root.canvas.currentTool = "select_ellipse"
            }
            
            ToolIcon {
                id: wandBtn
                icon: "selection.svg" // Magic Wand icon
                active: root.canvas && root.canvas.currentTool === "select_wand"
                onClicked: root.canvas.currentTool = "select_wand"
                
                Timer {
                    id: thresholdTimer
                    interval: 500
                    onTriggered: thresholdOverlay.visible = true
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPressed: thresholdTimer.start()
                    onReleased: thresholdTimer.stop()
                    onCanceled: thresholdTimer.stop()
                    // Re-route click
                    onClicked: root.canvas.currentTool = "select_wand"
                }
            }
            
            ToolIcon {
                icon: "magnet.svg" // Magnetic Lasso icon
                active: root.canvas && root.canvas.currentTool === "magnetic_lasso"
                onClicked: root.canvas.currentTool = "magnetic_lasso"
            }
            
            ToolIcon {
                icon: "selection.svg" // Auto / Threshold icon
                active: false
                onClicked: root.canvas.selectAll()
            }
        }
        
        // --- DIVIDER ---
        Rectangle { width: 1; height: 24 * uiScale; color: "#44ffffff" }
        
        // --- EXIT ---
        Item {
            width: 32 * uiScale; height: 32 * uiScale
            Image {
                anchors.fill: parent
                source: "../../../../assets/icons/minimize-2.svg"
                sourceSize: Qt.size(24 * root.uiScale, 24 * root.uiScale)
                opacity: 0.8
            }
            MouseArea { 
                anchors.fill: parent
                onClicked: {
                    root.canvas.isSelectionModeActive = false
                }
            }
        }
    }
    
    // --- SECONDARY PANEL (Actions) ---
    Item {
        id: actionsPanel
        height: 50 * uiScale
        width: actionsRow.width + 40 * uiScale
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 10 * uiScale
        visible: root.canvas && root.canvas.hasSelection
        
        Rectangle {
            anchors.fill: parent
            radius: 25 * uiScale
            color: "#cc1a1a1c"
            border.color: "#33ffffff"
            border.width: 1
        }
        
        RowLayout {
            id: actionsRow
            anchors.centerIn: parent
            spacing: 20 * uiScale
            
            ActionLabel { text: "Invert"; onClicked: root.canvas.invertSelection() }
            ActionLabel { text: "Feather"; onClicked: root.canvas.featherSelection(10) }
            ActionLabel { text: "Copy"; onClicked: root.canvas.duplicateSelection() }
            ActionLabel { text: "Color"; onClicked: root.canvas.colorSelection(root.canvas.brushColor) }
            ActionLabel { text: "Clear"; onClicked: root.canvas.clearSelectionContent() }
            ActionLabel { text: "Deselect"; onClicked: root.canvas.deselect() }
        }
    }
    
    // --- CIRCULAR THRESHOLD OVERLAY ---
    Item {
        id: thresholdOverlay
        visible: false
        anchors.centerIn: wandBtn
        width: 150 * uiScale; height: 150 * uiScale
        z: 1000
        
        Rectangle {
            anchors.fill: parent
            radius: width/2
            color: "#cc1a1a1c"
            border.color: root.accentColor
            border.width: 4 * uiScale
            
            // Progress Arc (Simplified with Canvas or Shape)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 20 * uiScale
                height: parent.height - 20 * uiScale
                radius: width/2
                color: "transparent"
                border.color: "#33ffffff"
                border.width: 2
                
                Text {
                    anchors.centerIn: parent
                    text: root.canvas ? Math.round(root.canvas.selectionThreshold * 100) + "%" : "0%"
                    color: "white"
                    font.pixelSize: 20 * uiScale
                    font.weight: Font.Bold
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            property real lastAngle: 0
            
            onPositionChanged: (mouse) => {
                var dx = mouse.x - width/2
                var dy = mouse.y - height/2
                var angle = Math.atan2(dy, dx)
                if (pressed) {
                    var diff = angle - lastAngle
                    if (diff > Math.PI) diff -= 2*Math.PI
                    if (diff < -Math.PI) diff += 2*Math.PI
                    
                    root.canvas.selectionThreshold = Math.max(0, Math.min(1, root.canvas.selectionThreshold + diff / (2*Math.PI)))
                }
                lastAngle = angle
            }
            onReleased: thresholdOverlay.visible = false
        }
    }

    // Internal Components
    component ToolIcon : Rectangle {
        property string icon: ""
        property bool active: false
        signal clicked()
        
        width: 36 * uiScale; height: 36 * uiScale
        radius: 10 * uiScale
        color: active ? root.accentColor : "transparent"
        
        Image {
            anchors.fill: parent
            anchors.margins: 6 * uiScale
            source: "../../../../assets/icons/" + icon
            sourceSize: Qt.size(24 * root.uiScale, 24 * root.uiScale)
            opacity: active ? 1.0 : 0.7
        }
        
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }
    
    component ActionLabel : Text {
        signal clicked()
        text: ""
        color: "white"
        font.pixelSize: 13 * uiScale
        opacity: actionArea.containsMouse ? 1.0 : 0.8
        
        MouseArea {
            id: actionArea
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }
}
