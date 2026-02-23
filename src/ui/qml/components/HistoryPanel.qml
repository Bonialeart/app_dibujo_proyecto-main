import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        RowLayout {
            Layout.fillWidth: true
            Text { text: "HISTORIAL"; color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { 
                text: "Limpiar"; color: accentColor; font.pixelSize: 10
                MouseArea { anchors.fill: parent; onClicked: console.log("Clear history") }
            }
        }
        
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: 15 // Mockup for now
            spacing: 2
            
            delegate: Rectangle {
                width: parent.width
                height: 32; radius: 4
                color: index === 3 ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1) : "transparent"
                border.color: index === 3 ? accentColor : "transparent"
                border.width: 1
                opacity: index > 3 ? 0.3 : 1.0 // Past actions vs current state
                
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 12
                    spacing: 10
                    
                    Text {
                        text: index === 0 ? "Abrir Proyecto" : 
                              index === 1 ? "Pincel de Óleo" :
                              index === 2 ? "Nueva Capa" :
                              index === 3 ? "Pincel de Óleo" : "Acción Anterior"
                        color: index <= 3 ? "white" : "#666"
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: index === 3 ? "●" : ""
                        color: accentColor; font.pixelSize: 8
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // Undo/Redo logic to jump to this point
                    }
                }
            }
        }
        
        // Quick Undo/Redo footer
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                Layout.fillWidth: true
                text: "Deshacer"
                onClicked: if(targetCanvas) targetCanvas.undo()
            }
            Button {
                Layout.fillWidth: true
                text: "Rehacer"
                onClicked: if(targetCanvas) targetCanvas.redo()
            }
        }
    }
}
