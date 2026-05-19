import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
Item {
    id: root
    width: parent.width
    height: 60
    
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    signal brushSelected()
    signal eraserSelected()
    signal undoClicked()
    signal redoClicked()
    signal toggleTimeline()
    
    Rectangle {
        anchors.fill: parent
        color: "#1a1a1f"
        opacity: 0.95
        
        Rectangle {
            width: parent.width
            height: 1
            anchors.bottom: parent.bottom
            color: "#2a2a30"
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16
        
        // Brand/Close
        Rectangle {
            width: 40; height: 40; radius: 20
            color: closeMa.containsMouse ? "#2a2a30" : "transparent"
            Text {
                text: "✕"
                color: "#aaa"
                font.pixelSize: 18
                font.weight: Font.Bold
                anchors.centerIn: parent
            }
            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleTimeline()
            }
        }
        
        Item { width: 10 }
        
        // Main Tools
        RowLayout {
            spacing: 12
            
            // Brush Tool
            Rectangle {
                width: 50; height: 50; radius: 12
                color: brushMa.containsMouse ? "#2a2a30" : "transparent"
                border.color: brushMa.containsMouse ? accentColor : "transparent"
                border.width: 2
                
                Image {
                    source: "image://icons/brush"
                    anchors.centerIn: parent
                    width: 28; height: 28
                    sourceSize: Qt.size(28, 28)
                    opacity: 0.8
                }
                MouseArea {
                    id: brushMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.brushSelected()
                }
            }
            
            // Eraser Tool
            Rectangle {
                width: 50; height: 50; radius: 12
                color: eraserMa.containsMouse ? "#2a2a30" : "transparent"
                border.color: eraserMa.containsMouse ? accentColor : "transparent"
                border.width: 2
                
                Image {
                    source: "image://icons/eraser"
                    anchors.centerIn: parent
                    width: 28; height: 28
                    sourceSize: Qt.size(28, 28)
                    opacity: 0.8
                }
                MouseArea {
                    id: eraserMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.eraserSelected()
                }
            }
            
            // Color Selector
            Rectangle {
                width: 50; height: 50; radius: 25
                color: targetCanvas ? targetCanvas.brushColor : "#ffffff"
                border.color: colorMa.containsMouse ? accentColor : "#333"
                border.width: 2
                
                MouseArea {
                    id: colorMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof mainWindow !== "undefined" && mainWindow) {
                            mainWindow.showColor = !mainWindow.showColor
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillWidth: true }
        
        // Playback Controls
        RowLayout {
            spacing: 16
            
            Rectangle {
                width: 40; height: 40; radius: 20
                color: prevMa.containsMouse ? "#2a2a30" : "transparent"
                Text { text: "⏮"; color: "#fff"; font.pixelSize: 20; anchors.centerIn: parent }
                MouseArea {
                    id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if(targetCanvas) { /* signal to timeline */ }
                }
            }
            
            Rectangle {
                width: 50; height: 50; radius: 25
                color: playMa.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor
                Text { text: "▶"; color: "#fff"; font.pixelSize: 22; anchors.centerIn: parent }
                MouseArea {
                    id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if(targetCanvas) { /* signal to timeline */ }
                }
            }
            
            Rectangle {
                width: 40; height: 40; radius: 20
                color: nextMa.containsMouse ? "#2a2a30" : "transparent"
                Text { text: "⏭"; color: "#fff"; font.pixelSize: 20; anchors.centerIn: parent }
                MouseArea {
                    id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if(targetCanvas) { /* signal to timeline */ }
                }
            }
        }
        
        Item { Layout.fillWidth: true }
        
        // Undo/Redo
        RowLayout {
            spacing: 8
            
            Rectangle {
                width: 44; height: 44; radius: 10
                color: uMa.containsMouse ? "#2a2a30" : "transparent"
                Text { text: "↶"; color: "#fff"; font.pixelSize: 20; anchors.centerIn: parent }
                MouseArea {
                    id: uMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.undoClicked()
                }
            }
            
            Rectangle {
                width: 44; height: 44; radius: 10
                color: rMa.containsMouse ? "#2a2a30" : "transparent"
                Text { text: "↷"; color: "#fff"; font.pixelSize: 20; anchors.centerIn: parent }
                MouseArea {
                    id: rMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.redoClicked()
                }
            }
        }
    }
}
