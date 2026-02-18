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
        
        // Premium Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#1c1c1e"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
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
                    width: 32; height: 32; radius: 16
                    color: addLayerMouse.containsMouse ? "#333" : "transparent"
                    
                    Text {
                        text: "+"
                        color: "white"
                        font.pixelSize: 24
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1 // Visual alignment
                    }
                    
                    MouseArea {
                        id: addLayerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if(targetCanvas) targetCanvas.addLayer()
                    }
                }

                // Add Group Button (More subtle)
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: addGroupMouse.containsMouse ? "#333" : "transparent"
                    
                    Image {
                        source: "image://icons/folder.svg"
                        width: 18; height: 18
                        anchors.centerIn: parent
                        opacity: 0.8
                    }
                    
                    MouseArea {
                        id: addGroupMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if(targetCanvas) targetCanvas.addGroup()
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
