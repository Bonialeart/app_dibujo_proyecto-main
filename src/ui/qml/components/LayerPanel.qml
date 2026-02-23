import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root
    
    property var targetCanvas: null
    property var mainCanvas: targetCanvas
    property var layerModel: targetCanvas ? targetCanvas.layerModel : null
    property color accentColor: "#6366f1"
    
    // Internal state for Delegate interaction
    property int optionsIndex: -1
    property int swipedIndex: -1
    property int draggedIndex: -1
    property int dropTargetIndex: -1

    // Group drop target: when dragging over a group layer, this is that group's layerId
    property int groupDropTarget: -1
    
    property var activeLayer: {
        if (!layerModel) return null;
        for (var i = 0; i < layerModel.length; ++i) { 
            if (layerModel[i].active) return layerModel[i]; 
        }
        return null;
    }
    
    readonly property real activeLayerOpacity: activeLayer ? activeLayer.opacity : 1.0
    readonly property int activeLayerId: activeLayer ? activeLayer.layerId : -1
    readonly property bool activeLayerClipped: activeLayer ? activeLayer.clipped : false
    readonly property bool activeLayerLocked: activeLayer ? activeLayer.locked : false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // --- PRO TOOLBAR (Unified Header) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "transparent"
            z: 10
            
            Rectangle {
                anchors.fill: parent; anchors.margins: 4
                radius: 10
                color: "#141417"
                border.color: "#1E1E22"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Row 1: Actions
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        Rectangle { width: parent.width; anchors.bottom: parent.bottom; color: "#1E1E22"; height: 1 }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 2
                            
                            // Clipping Mask
                            Rectangle { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: activeLayerClipped ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) : (clipMa.containsMouse ? "#222228" : "transparent")
                                border.color: activeLayerClipped ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5) : "transparent"; border.width: 1
                                Image { source: "image://icons/corner-down-right.svg"; width: 14; height: 14; anchors.centerIn: parent; opacity: activeLayerClipped ? 1.0 : 0.5 }
                                MouseArea { id: clipMa; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas && activeLayerId !== -1) targetCanvas.toggleClipping(activeLayerId) }
                                ToolTip.visible: clipMa.containsMouse; ToolTip.text: "Clipping Mask" 
                            }
                            
                            // Alpha Lock
                            Rectangle { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: (activeLayer && activeLayer.alpha_lock) ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) : (alphaMa.containsMouse ? "#222228" : "transparent")
                                border.color: (activeLayer && activeLayer.alpha_lock) ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5) : "transparent"; border.width: 1
                                Image { source: "image://icons/lock.svg"; width: 12; height: 12; anchors.centerIn: parent; opacity: (activeLayer && activeLayer.alpha_lock) ? 1.0 : 0.5 }
                                MouseArea { id: alphaMa; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas && activeLayerId !== -1) targetCanvas.toggleAlphaLock(activeLayerId) }
                                ToolTip.visible: alphaMa.containsMouse; ToolTip.text: "Lock Alpha" 
                            }

                            Item { Layout.fillWidth: true }

                            // Duplicate
                            Rectangle { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: dupMa.containsMouse ? "#222228" : "transparent"
                                Image { source: "image://icons/copy.svg"; width: 14; height: 14; anchors.centerIn: parent; opacity: dupMa.containsMouse ? 1.0 : 0.5 }
                                MouseArea { id: dupMa; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas && activeLayerId !== -1) targetCanvas.duplicateLayer(activeLayerId) }
                                ToolTip.visible: dupMa.containsMouse; ToolTip.text: "Duplicate Layer" 
                            }

                            // Add Layer
                            Rectangle { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: addLyrMa.containsMouse ? "#222228" : "transparent"
                                Image { source: "image://icons/plus.svg"; width: 16; height: 16; anchors.centerIn: parent; opacity: addLyrMa.containsMouse ? 1.0 : 0.6 }
                                MouseArea { id: addLyrMa; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas) targetCanvas.addLayer() }
                                ToolTip.visible: addLyrMa.containsMouse; ToolTip.text: "New Layer" 
                            }
                            
                            // Add Group / Folder
                            Rectangle { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: addGrpMa.containsMouse ? "#2a1e0a" : "transparent"
                                border.color: addGrpMa.containsMouse ? "#f0903090" : "transparent"; border.width: 1
                                Image { source: "image://icons/folder-plus.svg"; width: 14; height: 14; anchors.centerIn: parent; opacity: addGrpMa.containsMouse ? 1.0 : 0.5 }
                                MouseArea { id: addGrpMa; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas) targetCanvas.addGroup() }
                                ToolTip.visible: addGrpMa.containsMouse; ToolTip.text: "New Folder (Group)" 
                            }

                            // Delete
                            Rectangle { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: delMa.containsMouse ? "#3a1a1a" : "transparent"
                                Image { source: "image://icons/trash-2.svg"; width: 14; height: 14; anchors.centerIn: parent; opacity: delMa.containsMouse ? 1.0 : 0.5 }
                                MouseArea { id: delMa; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas && activeLayerId !== -1) targetCanvas.removeLayer(activeLayerId) }
                                ToolTip.visible: delMa.containsMouse; ToolTip.text: "Delete Layer" 
                            }
                        }
                    }

                    // Row 2: Blend & Opacity
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: 36
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                            
                            // Blend Mode
                            Rectangle {
                                id: blendModeBtn
                                Layout.preferredWidth: 70; Layout.preferredHeight: 24; radius: 12
                                color: blendModePopup.visible ? root.accentColor : "#202024"
                                border.color: "#303036"; border.width: 1
                                Text { anchors.centerIn: parent; text: (activeLayer ? activeLayer.blendMode : "Normal"); color: blendModePopup.visible ? "white" : "#a0a0a5"; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(activeLayer) blendModePopup.open() }
                            }

                            // Minimalist Opacity Slider
                            Slider {
                                Layout.fillWidth: true; Layout.preferredHeight: 24
                                from: 0.0; to: 1.0; value: activeLayerOpacity; enabled: activeLayer !== null
                                
                                background: Rectangle {
                                    x: parent.leftPadding; y: parent.height / 2 - 2
                                    implicitWidth: 100; implicitHeight: 4; radius: 2; color: "#101014"; border.color: "#222228"
                                    Rectangle { width: parent.visualPosition * parent.width; height: parent.height; color: root.accentColor; radius: 2 }
                                }
                                handle: Rectangle {
                                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); y: parent.height / 2 - 7
                                    implicitWidth: 14; implicitHeight: 14; radius: 7; color: "#fff"; border.color: "#555"; border.width: 1
                                    layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: "#40000000" }
                                }
                                onMoved: if(targetCanvas) targetCanvas.setLayerOpacity(activeLayerId, value)
                            }
                            
                            Text { text: Math.round(activeLayerOpacity * 100) + "%"; color: "#8a8a93"; font.pixelSize: 10; font.weight: Font.DemiBold; font.family: "Monospace"; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                        }
                    }
                }
            }
        }


        // --- BLEND MODE POPUP ---
        Popup {
            id: blendModePopup
            x: blendModeBtn.x; y: blendModeBtn.y + blendModeBtn.height + 4
            width: 140; height: 300
            padding: 0
            
            background: Rectangle {
                color: "#1c1c1e"; radius: 8; border.color: "#2a2a2d"; border.width: 1
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 10; shadowColor: "#80000000" }
            }
            
            contentItem: ListView {
                clip: true
                model: ["Normal", "Multiply", "Screen", "Overlay", "Darken", "Lighten", "Color Dodge", "Color Burn", "Soft Light", "Hard Light", "Difference", "Exclusion", "Hue", "Saturation", "Color", "Luminosity"]
                delegate: ItemDelegate {
                    width: parent.width; height: 32
                    contentItem: Text {
                        text: modelData; color: activeLayer && activeLayer.blendMode === modelData ? root.accentColor : "white"
                        font.pixelSize: 11; verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: hovered ? "#2a2a2d" : "transparent"
                    }
                    onClicked: {
                        if(targetCanvas && activeLayerId !== -1) {
                            targetCanvas.setLayerBlendMode(activeLayerId, modelData)
                        }
                        blendModePopup.close()
                    }
                }
                ScrollBar.vertical: ScrollBar { width: 4 }
            }
        }
        
        
        // --- LAYER LIST ---
        ListView {
            id: layersListRef
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            model: root.layerModel
            spacing: 1
            
            property int optionsIndex: root.optionsIndex
            property int swipedIndex: root.swipedIndex
            property int draggedIndex: root.draggedIndex
            property int dropTargetIndex: root.dropTargetIndex
            property int groupDropTarget: root.groupDropTarget
            
            delegate: LayerDelegate { 
                width: ListView.view.width
                dragGhostRef: dragGhost
                rootRef: root
            }

            ScrollBar.vertical: ScrollBar {
                width: 4
                contentItem: Rectangle { radius: 2; color: "#333" }
            }
            
            // Footer: Drop Zone for moving layers to bottom
            footer: Item {
                width: layersListRef.width
                height: 60
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    color: (layersListRef.draggedIndex >= 0 && dropZoneMouse.containsMouse) ? "#1a6366f1" : "transparent"
                    radius: 8
                    border.color: (layersListRef.draggedIndex >= 0 && dropZoneMouse.containsMouse) ? root.accentColor : "#22ffffff"
                    border.width: (layersListRef.draggedIndex >= 0 && dropZoneMouse.containsMouse) ? 2 : 1
                    
                    visible: root.layerModel && root.layerModel.length > 0
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: (layersListRef.draggedIndex >= 0 && dropZoneMouse.containsMouse) ? 1.0 : 0.3
                        
                        Image {
                            source: "image://icons/chevron-down.svg"
                            width: 16; height: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.6
                        }
                        
                        Text {
                            text: layersListRef.draggedIndex >= 0 ? "Drop here" : "Move to bottom"
                            color: "#aaaaaa"
                            font.pixelSize: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    MouseArea {
                        id: dropZoneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (layersListRef.draggedIndex >= 0) {
                                layersListRef.dropTargetIndex = root.layerModel.length - 1
                            }
                        }
                    }
                }
            }
        }
    }

    // --- DRAG GHOST (Moved out of Layout for absolute positioning) ---
    Rectangle {
        id: dragGhost
        visible: false
        width: parent.width - 24
        height: 44
        x: 12
        color: "#2c2c2e"
        radius: 8
        border.color: root.accentColor
        border.width: 1
        z: 1000
        opacity: 0.9
        property string infoText: "Moving Layer"
        
        scale: visible ? 1.04 : 0.8
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            Image { source: "image://icons/layers.svg"; width: 14; height: 14; opacity: 0.6 }
            Text { text: dragGhost.infoText; color: "white"; font.bold: true; font.pixelSize: 12 }
        }
        
        Rectangle { anchors.fill: parent; anchors.margins: -4; z: -1; color: "#000"; opacity: 0.3; radius: 12 }
    }

    // --- GROUP DROP HINT ---
    // Shown at the bottom when dragging a layer over a group
    Rectangle {
        id: groupDropHint
        visible: root.groupDropTarget !== -1 && root.draggedIndex !== -1
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 20
        height: 36
        radius: 8
        color: "#ff990020"
        border.color: "#ff9900"
        border.width: 1.5
        z: 999
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            Image { source: "image://icons/folder.svg"; width: 14; height: 14; opacity: 0.9 }
            Text { 
                text: "Drop to add to folder"
                color: "#ff9900"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }
    }
}
