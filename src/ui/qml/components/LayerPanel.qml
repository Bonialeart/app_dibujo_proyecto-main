import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import ArtFlow 1.0

Item {
    id: root
    
    property var targetCanvas: null
    property var layerModel: targetCanvas ? targetCanvas.layerModel : null
    
    // Internal state for Delegate interaction
    property int optionsIndex: -1
    property int swipedIndex: -1
    
    // Helper to find active layer in the model list
    property var activeLayer: {
        if (!layerModel) return null;
        for (var i = 0; i < layerModel.length; ++i) {
            if (layerModel[i].active) return layerModel[i];
        }
        return null;
    }
    
    readonly property string activeLayerName: activeLayer ? activeLayer.name : "No Layer Selected"
    readonly property real activeLayerOpacity: activeLayer ? activeLayer.opacity : 1.0
    readonly property int activeLayerId: activeLayer ? activeLayer.layerId : -1
    
    // Context Menu (Essential for LayerDelegate)
    Menu {
        id: layerContextMenu
        visible: false
        width: 180
        height: contentHeight + 16
        
        property int targetLayerIndex: -1
        property string targetLayerName: ""
        property bool targetAlphaLock: false
        
        background: Rectangle {
            color: "#1c1c1e"
            border.color: "#333"
            radius: 12
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 20; shadowColor: "#80000000" }
        }
        
        Action { text: "Rename Layer"; onTriggered: console.log("Rename TBD") }
        Action { text: "Duplicate Layer"; onTriggered: if(targetCanvas) targetCanvas.duplicateLayer(layerContextMenu.targetLayerIndex) }
        Action { text: "Clear Layer"; onTriggered: if(targetCanvas) targetCanvas.clearLayer(layerContextMenu.targetLayerIndex) }
        MenuSeparator { contentItem: Rectangle { implicitWidth: 160; implicitHeight: 1; color: "#333" } }
        Action { 
            text: layerContextMenu.targetAlphaLock ? "Unlock Alpha" : "Alpha Lock"
            onTriggered: if(targetCanvas) targetCanvas.toggleAlphaLock(layerContextMenu.targetLayerIndex) 
        }
    }
    
    // Drag Ghost (Essential for LayerDelegate reordering)
    Item {
        id: dragGhost
        visible: false
        z: 1000
        width: 200; height: 40
        property int targetDepth: 0
        property string infoText: ""
        
        Rectangle {
            anchors.fill: parent
            color: "#2c2c2e"
            opacity: 0.8
            radius: 8
            border.color: "#6366f1"
            border.width: 1
            Text { text: parent.parent.infoText; color: "white"; anchors.centerIn: parent }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1c1c1e"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Premium Header + Master Controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: activeLayer ? 120 : 48
            color: "#1c1c1e"
            
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "Layers"
                        color: "white"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    
                    // Add Layer Button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: addLayerMouse.containsMouse ? "#ffffff10" : "transparent"
                        Text { text: "+"; color: "white"; font.pixelSize: 20; anchors.centerIn: parent; anchors.verticalCenterOffset: -1 }
                        MouseArea { id: addLayerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas) targetCanvas.addLayer() }
                    }

                    // Add Group Button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: addGroupMouse.containsMouse ? "#ffffff10" : "transparent"
                        Image { source: "image://icons/folder.svg"; width: 16; height: 16; anchors.centerIn: parent; opacity: 0.8 }
                        MouseArea { id: addGroupMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if(targetCanvas) targetCanvas.addGroup() }
                    }
                }

                // Master Opacity Control (Premium scrub slider)
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    visible: activeLayer !== null && activeLayer.type !== "background"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: activeLayerName
                                color: "#888"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: Math.round(activeLayerOpacity * 100) + "%"
                                color: "white"
                                font.pixelSize: 13
                                font.weight: Font.Black
                            }
                        }

                        // THE SLIDER
                        Item {
                            id: masterSliderArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32

                            // Internal value for smooth dragging
                            property real sliderValue: 1.0
                            property color accentColor: (typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#007aff"

                            // Bind to model when not dragging
                            Binding {
                                target: masterSliderArea
                                property: "sliderValue"
                                value: activeLayerOpacity
                                when: !masterMouse.pressed
                            }

                            // Background Track
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 6; radius: 3
                                color: "#121214"
                                border.color: "#252528"; border.width: 1
                                
                                // Progress
                                Rectangle {
                                    width: parent.width * masterSliderArea.sliderValue
                                    height: parent.height; radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Qt.lighter(masterSliderArea.accentColor, 1.4) }
                                        GradientStop { position: 1.0; color: masterSliderArea.accentColor }
                                    }
                                }
                            }

                            // The Handle (Premium Glow)
                            Rectangle {
                                id: scrubHandle
                                x: (parent.width - width) * masterSliderArea.sliderValue
                                anchors.verticalCenter: parent.verticalCenter
                                width: masterMouse.pressed ? 24 : 18
                                height: width; radius: width/2
                                color: "white"
                                border.color: masterSliderArea.accentColor
                                border.width: masterMouse.pressed ? 3 : 1
                                
                                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.5
                                    blurEnabled: masterMouse.pressed; blur: 0.2
                                }

                                // Inner detail
                                Rectangle {
                                    width: 4; height: 4; radius: 2; color: masterSliderArea.accentColor
                                    anchors.centerIn: parent
                                    visible: !masterMouse.pressed
                                }
                            }

                            MouseArea {
                                id: masterMouse
                                anchors.fill: parent
                                anchors.margins: -10 // Easy to grab
                                preventStealing: true
                                
                                function updateOpacity(mouse) {
                                    var meaningfulWidth = width - 20
                                    var relativeX = mouse.x - 10
                                    var v = Math.max(0.0, Math.min(1.0, relativeX / meaningfulWidth))
                                    
                                    masterSliderArea.sliderValue = v
                                    if (targetCanvas) targetCanvas.setLayerOpacityPreview(activeLayerId, v)
                                }
                                
                                onPressed: {
                                    layersListRef.interactive = false // Stop ListView from intervening
                                    updateOpacity(mouse)
                                }
                                onPositionChanged: if (pressed) updateOpacity(mouse)
                                onReleased: {
                                    layersListRef.interactive = true // Restore List interaction
                                    var meaningfulWidth = width - 20
                                    var relativeX = mouse.x - 10
                                    var v = Math.max(0.0, Math.min(1.0, relativeX / meaningfulWidth))
                                    
                                    masterSliderArea.sliderValue = v
                                    if (targetCanvas) targetCanvas.setLayerOpacity(activeLayerId, v)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#2c2c2e"
            }
        }
        
        // List
        ListView {
            id: layersListRef
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            model: root.layerModel
            spacing: 2
            
            // Expose properties needed by Delegate
            property int optionsIndex: root.optionsIndex
            property int swipedIndex: root.swipedIndex
            
            delegate: LayerDelegate {
                width: ListView.view.width
                // Inject dependencies via context properties or direct assignment if possible
                // LayerDelegate expects 'mainCanvas' context property.
                // We'll rename local property to mainCanvas to trick it? No, id matters.
                // But if mainCanvas is passed from StudioCanvasLayout context, it should work.
            }
            
            // Allow manual scroll
            ScrollBar.vertical: ScrollBar { }
        }
    }
}
