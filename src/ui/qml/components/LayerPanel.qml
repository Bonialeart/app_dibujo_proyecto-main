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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header (Add Layer, Group, Delete)
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            color: "#252528"
            
            RowLayout {
                anchors.fill: parent; anchors.margins: 4
                spacing: 4
                
                Item { Layout.fillWidth: true } // Spacer
                
                // Add Group
                Rectangle {
                    width: 28; height: 24; radius: 4
                    color: "transparent"
                    border.color: "#333"
                    Text { text: "📁"; color: "#ddd"; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: if(targetCanvas) targetCanvas.addGroup() }
                }
                
                // Add Layer
                Rectangle {
                    width: 28; height: 24; radius: 4
                    color: "transparent"
                    border.color: "#333"
                    Text { text: "+"; color: "#ddd"; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: if(targetCanvas) targetCanvas.addLayer() }
                }
                
                // Delete
                Rectangle {
                    width: 28; height: 24; radius: 4
                    color: "transparent"
                    border.color: "#333"
                    Text { text: "🗑"; color: "#ddd"; anchors.centerIn: parent }
                    MouseArea { anchors.fill: parent; onClicked: if(targetCanvas) targetCanvas.removeLayer(targetCanvas.activeLayerIndex) }
                }
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
