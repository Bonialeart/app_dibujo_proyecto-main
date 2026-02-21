import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root
    
    property var targetCanvas: null
    property string currentFolderPath: ""
    property color accentColor: "#6366f1"
    
    signal pageSelected(string path)
    
    // Model for the pages
    ListModel {
        id: pagesModel
    }
    
    function refresh() {
        pagesModel.clear()
        if (currentFolderPath === "") return
        
        var pages = targetCanvas.get_sketchbook_pages(currentFolderPath)
        for (var i = 0; i < pages.length; i++) {
            pagesModel.append(pages[i])
        }
    }
    
    onCurrentFolderPathChanged: refresh()
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#161619"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15; anchors.rightMargin: 10
                
                Text {
                    text: "STORY"
                    color: "#fff"
                    font.pixelSize: 12; font.weight: Font.Black
                    font.letterSpacing: 2
                    Layout.fillWidth: true
                }
                
                // Add Page Button
                Rectangle {
                    width: 30; height: 30; radius: 6
                    color: addPageMa.containsMouse ? "#2a2a2e" : "transparent"
                    border.color: "#333"; border.width: 1
                    
                    Text { text: "+"; color: "#fff"; font.pixelSize: 18; anchors.centerIn: parent }
                    
                    MouseArea {
                        id: addPageMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            targetCanvas.create_new_page(currentFolderPath, "Page")
                            root.refresh()
                        }
                    }
                }
            }
            
            Rectangle { width: parent.width; height: 1; color: "#1e1e22"; anchors.bottom: parent.bottom }
        }
        
        // Pages List
        ListView {
            id: pagesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: pagesModel
            clip: true
            spacing: 12
            topMargin: 15; bottomMargin: 15
            
            delegate: Item {
                width: pagesList.width
                height: 140
                
                property bool isCurrent: targetCanvas ? (targetCanvas.currentProjectPath === model.realPath || targetCanvas.currentProjectPath === model.path) : false
                
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    // Thumbnail Card
                    Rectangle {
                        width: 100; height: 110; radius: 6
                        color: "#0a0a0c"
                        border.color: isCurrent ? accentColor : "#333"
                        border.width: isCurrent ? 2 : 1
                        clip: true
                        
                        Image {
                            anchors.fill: parent; anchors.margins: 2
                            source: model.preview || ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        
                        // Page Number Badge
                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left
                            anchors.margins: 4
                            width: 18; height: 18; radius: 4
                            color: isCurrent ? accentColor : "#252528"
                            Text { text: (index + 1); color: "#fff"; font.pixelSize: 10; font.bold: true; anchors.centerIn: parent }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.pageSelected(model.realPath || model.path)
                            }
                        }
                    }
                    
                    Text {
                        text: model.name || "Untitled"
                        color: isCurrent ? "#fff" : "#888"
                        font.pixelSize: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                        elide: Text.ElideRight
                        width: 90
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                active: true
            }
        }
    }
}
