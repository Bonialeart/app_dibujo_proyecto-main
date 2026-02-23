import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    property string refImageSource: ""
    property real refZoom: 1.0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12
        
        // --- HEADER ---
        RowLayout {
            Layout.fillWidth: true
            Text { text: "REFERENCIA"; color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            
            Button {
                text: "Abrir"
                onClicked: imageDialog.open()
            }
        }
        
        // --- VIEWER AREA ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0a0a0d"
            radius: 8
            border.color: "#2a2a2d"
            clip: true
            
            Image {
                id: refImage
                anchors.centerIn: parent
                source: root.refImageSource !== "" ? root.refImageSource : "image://icons/image.svg"
                width: parent.width * 0.9 * root.refZoom
                height: parent.height * 0.9 * root.refZoom
                fillMode: Image.PreserveAspectFit
                opacity: root.refImageSource !== "" ? 1.0 : 0.2
                
                transform: Translate {
                    id: imgTranslate
                    x: 0; y: 0
                }
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: containsMouse ? Qt.CrossCursor : Qt.ArrowCursor
                
                property point lastPos
                
                onPressed: (mouse) => {
                    if (mouse.button === Qt.MiddleButton || (mouse.button === Qt.LeftButton && mouse.modifiers & Qt.ControlModifier)) {
                        lastPos = Qt.point(mouse.x, mouse.y)
                    } else if (mouse.button === Qt.LeftButton) {
                        // Eyedropper logic (Mockup)
                        console.log("Sampling color from reference...")
                    }
                }
                
                onPositionChanged: (mouse) => {
                    if (pressed && (pressedButtons & Qt.MiddleButton || (pressedButtons & Qt.LeftButton && modifiers & Qt.ControlModifier))) {
                        var delta = Qt.point(mouse.x - lastPos.x, mouse.y - lastPos.y)
                        imgTranslate.x += delta.x
                        imgTranslate.y += delta.y
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                }
                
                onWheel: (wheel) => {
                    var scaleFact = wheel.angleDelta.y > 0 ? 1.1 : 0.9
                    root.refZoom = Math.max(0.1, Math.min(10.0, root.refZoom * scaleFact))
                }
            }
            
            // Empty State Badge
            Text {
                visible: root.refImageSource === ""
                text: "Suelte una imagen aquí\no use el botón 'Abrir'"
                color: "#444"
                font.pixelSize: 10
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 30
            }
        }
        
        // --- TOOLBAR ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Rectangle {
                width: 28; height: 28; radius: 6
                color: "#1a1a1f"; border.color: "#333"
                Text { text: "🔍"; anchors.centerIn: parent; color: "#888" }
                MouseArea { anchors.fill: parent; onClicked: root.refZoom = 1.0; ToolTip.text: "Restablecer Zoom"; ToolTip.visible: containsMouse }
            }
            
            Rectangle {
                width: 28; height: 28; radius: 6
                color: "#1a1a1f"; border.color: "#333"
                Text { text: "◫"; anchors.centerIn: parent; color: "#888" }
                MouseArea { anchors.fill: parent; onClicked: { imgTranslate.x = 0; imgTranslate.y = 0 }; ToolTip.text: "Centrar Vista"; ToolTip.visible: containsMouse }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: Math.round(root.refZoom * 100) + "%"
                color: "#666"; font.pixelSize: 10; font.family: "Monospace"
            }
        }
    }
    
    FileDialog {
        id: imageDialog
        title: "Seleccionar Imagen de Referencia"
        folder: shortcuts.pictures
        nameFilters: [ "Archivos de imagen (*.png *.jpg *.jpeg *.bmp)", "Todos los archivos (*)" ]
        onAccepted: {
            root.refImageSource = imageDialog.fileUrl
        }
    }
}
