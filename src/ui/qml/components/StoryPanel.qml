import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import Qt.labs.platform 1.1

Item {
    id: root
    
    property var targetCanvas: null
    property string currentFolderPath: ""
    property color accentColor: "#6366f1"
    property bool isCompactMode: width < 200
    
    signal pageSelected(string path)
    
    // Model for the pages
    ListModel {
        id: pagesModel
    }
    
    // Currently selected page index
    property int selectedPageIndex: -1
    property string selectedPagePath: ""
    
    function refresh() {
        pagesModel.clear()
        if (currentFolderPath === "" || !targetCanvas) return
        
        var pages = targetCanvas.get_sketchbook_pages(currentFolderPath)
        for (var i = 0; i < pages.length; i++) {
            pagesModel.append(pages[i])
        }
        
        // Re-select current page
        if (targetCanvas.currentProjectPath !== "") {
            for (var j = 0; j < pagesModel.count; j++) {
                if (pagesModel.get(j).realPath === targetCanvas.currentProjectPath ||
                    pagesModel.get(j).path === targetCanvas.currentProjectPath) {
                    selectedPageIndex = j
                    break
                }
            }
        }
    }
    
    onCurrentFolderPathChanged: refresh()
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // ═══════════════ HEADER ═══════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 10
                spacing: 8
                
                // Page count badge
                Rectangle {
                    width: 28; height: 22; radius: 6
                    color: "#1a1a1e"
                    border.color: "#2a2a30"
                    
                    Text {
                        text: pagesModel.count
                        color: accentColor
                        font.pixelSize: 11; font.bold: true
                        anchors.centerIn: parent
                    }
                }
                
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "PAGES"
                        color: "#999"
                        font.pixelSize: 10; font.weight: Font.Black
                        font.letterSpacing: 1.5
                    }
                    Text {
                        text: pagesModel.count + " panel" + (pagesModel.count !== 1 ? "s" : "")
                        color: "#555"
                        font.pixelSize: 9
                    }
                }
                
                // Add Page Button
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: addPageMa.containsMouse ? accentColor : "#1e1e22"
                    border.color: addPageMa.containsMouse ? Qt.lighter(accentColor, 1.3) : "#333"
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        text: "+"
                        color: addPageMa.containsMouse ? "white" : "#aaa"
                        font.pixelSize: 20; font.bold: true
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                    }
                    
                    MouseArea {
                        id: addPageMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            targetCanvas.create_new_page(currentFolderPath, "Page")
                            root.refresh()
                        }
                    }
                    
                    ToolTip.visible: addPageMa.containsMouse
                    ToolTip.text: "Add New Page"
                    ToolTip.delay: 600
                }
                
                // Export Menu Button
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: exportMa.containsMouse ? "#252528" : "transparent"
                    border.color: exportMa.containsMouse ? "#444" : "transparent"
                    
                    Text {
                        text: "⤓"
                        color: exportMa.containsMouse ? accentColor : "#666"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }
                    
                    MouseArea {
                        id: exportMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: exportMenu.open()
                    }
                    
                    ToolTip.visible: exportMa.containsMouse
                    ToolTip.text: "Export Options"
                    ToolTip.delay: 600
                }
            }
            
            // Bottom separator with glow
            Rectangle {
                width: parent.width; height: 1
                anchors.bottom: parent.bottom
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) }
                    GradientStop { position: 0.7; color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
        
        // ═══════════════ PAGES LIST ═══════════════
        ListView {
            id: pagesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: pagesModel
            clip: true
            spacing: 8
            topMargin: 12; bottomMargin: 12
            leftMargin: 10; rightMargin: 10
            
            // Smooth scrolling
            flickDeceleration: 4000
            maximumFlickVelocity: 2000
            
            // Empty state
            Text {
                visible: pagesModel.count === 0
                anchors.centerIn: parent
                text: "No pages yet\nTap + to create one"
                color: "#555"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }
            
            delegate: Item {
                id: pageDelegate
                width: pagesList.width - 20
                height: isCompactMode ? 100 : 150
                
                property bool isCurrent: targetCanvas ? 
                    (targetCanvas.currentProjectPath === model.realPath || 
                     targetCanvas.currentProjectPath === model.path) : false
                property bool isHovered: pageDelegateMa.containsMouse
                
                // Card Container
                Rectangle {
                    id: pageCard
                    anchors.fill: parent
                    radius: 12
                    color: isCurrent ? "#1a1a24" : (isHovered ? "#151518" : "#111114")
                    border.color: isCurrent ? accentColor : (isHovered ? "#333" : "#1e1e22")
                    border.width: isCurrent ? 2 : 1
                    clip: true
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    
                    // Selection glow effect
                    Rectangle {
                        visible: isCurrent
                        anchors.fill: parent
                        radius: 12
                        color: "transparent"
                        border.color: accentColor
                        border.width: 2
                        opacity: 0.3
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: 15
                            color: "transparent"
                            border.color: accentColor
                            border.width: 1
                            opacity: 0.15
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10
                        
                        // Thumbnail
                        Rectangle {
                            Layout.preferredWidth: isCompactMode ? 60 : 80
                            Layout.fillHeight: true
                            radius: 8
                            color: "#0a0a0c"
                            border.color: isCurrent ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : "#222"
                            border.width: 1
                            clip: true
                            
                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: model.preview || ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                
                                // Loading shimmer
                                Rectangle {
                                    visible: parent.status !== Image.Ready && (model.preview || "") !== ""
                                    anchors.fill: parent
                                    color: "#1a1a1e"
                                    radius: 6
                                    
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 800 }
                                        NumberAnimation { to: 1.0; duration: 800 }
                                    }
                                }
                                
                                // Placeholder for empty pages
                                Column {
                                    visible: (model.preview || "") === ""
                                    anchors.centerIn: parent
                                    spacing: 4
                                    
                                    Rectangle {
                                        width: 24; height: 2; radius: 1; color: "#333"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Rectangle {
                                        width: 30; height: 2; radius: 1; color: "#2a2a2e"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Rectangle {
                                        width: 20; height: 2; radius: 1; color: "#333"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                            
                            // Page Number Badge (upper-left)
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left
                                anchors.margins: 4
                                width: 22; height: 22; radius: 6
                                color: isCurrent ? accentColor : "#1e1e22"
                                border.color: isCurrent ? Qt.lighter(accentColor, 1.2) : "#333"
                                border.width: 1
                                
                                Text {
                                    text: (index + 1)
                                    color: isCurrent ? "white" : "#999"
                                    font.pixelSize: 10; font.bold: true
                                    anchors.centerIn: parent
                                }
                            }
                        }
                        
                        // Page Info Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4
                            
                            Item { Layout.fillHeight: true }
                            
                            Text {
                                text: model.name || "Untitled"
                                color: isCurrent ? "white" : (isHovered ? "#ccc" : "#999")
                                font.pixelSize: 12
                                font.weight: isCurrent ? Font.Bold : Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            
                            Text {
                                text: model.date || ""
                                color: "#555"
                                font.pixelSize: 9
                                Layout.fillWidth: true
                                visible: !isCompactMode
                            }
                            
                            // Action buttons row
                            Row {
                                spacing: 4
                                visible: isHovered || isCurrent
                                
                                // Export single page
                                Rectangle {
                                    width: 26; height: 22; radius: 5
                                    color: exportSingleMa.containsMouse ? "#2a2a30" : "#1a1a1e"
                                    border.color: "#333"; border.width: 1
                                    
                                    Text {
                                        text: "⤓"; color: "#aaa"; font.pixelSize: 11
                                        anchors.centerIn: parent
                                    }
                                    
                                    MouseArea {
                                        id: exportSingleMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            exportSingleDialog.currentExportPath = model.realPath || model.path
                                            exportSingleDialog.currentExportName = model.name || "page"
                                            exportSingleDialog.open()
                                        }
                                    }
                                    
                                    ToolTip.visible: exportSingleMa.containsMouse
                                    ToolTip.text: "Export this page"
                                    ToolTip.delay: 400
                                }
                                
                                // Delete page
                                Rectangle {
                                    width: 26; height: 22; radius: 5
                                    color: deleteMa.containsMouse ? "#3a1515" : "#1a1a1e"
                                    border.color: deleteMa.containsMouse ? "#662222" : "#333"
                                    border.width: 1
                                    
                                    Text {
                                        text: "✕"; color: deleteMa.containsMouse ? "#ff4444" : "#666"; font.pixelSize: 10
                                        anchors.centerIn: parent
                                    }
                                    
                                    MouseArea {
                                        id: deleteMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (pagesModel.count > 1) {
                                                targetCanvas.deleteProject(model.realPath || model.path)
                                                root.refresh()
                                            }
                                        }
                                    }
                                    
                                    ToolTip.visible: deleteMa.containsMouse
                                    ToolTip.text: pagesModel.count > 1 ? "Delete page" : "Can't delete last page"
                                    ToolTip.delay: 400
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // Click area (lower priority than buttons)
                    MouseArea {
                        id: pageDelegateMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: {
                            root.pageSelected(model.realPath || model.path)
                        }
                    }
                }
                
                // Drop indicator for reordering (future)
                Rectangle {
                    visible: false // Enable when drag-drop is implemented
                    width: parent.width
                    height: 3
                    radius: 1.5
                    color: accentColor
                    anchors.top: parent.top
                    anchors.topMargin: -5
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                active: true
                
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: "#444"
                    opacity: parent.active ? 0.8 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
        
        // ═══════════════ FOOTER ACTIONS ═══════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: "#0d0d0f"
            
            Rectangle {
                width: parent.width; height: 1
                color: "#1e1e22"
                anchors.top: parent.top
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 6
                
                // Export All Pages button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: exportAllMa.containsMouse ? "#1e1e24" : "#151518"
                    border.color: exportAllMa.containsMouse ? accentColor : "#2a2a30"
                    border.width: 1
                    
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        Text {
                            text: "⤓"
                            color: accentColor
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: isCompactMode ? "Export" : "Export All"
                            color: exportAllMa.containsMouse ? "white" : "#aaa"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        id: exportAllMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: exportAllDialog.open()
                    }
                }
            }
        }
    }
    
    // ═══════════════ EXPORT MENU POPUP ═══════════════
    Popup {
        id: exportMenu
        x: parent.width - 200
        y: 50
        width: 180
        padding: 6
        
        background: Rectangle {
            color: "#1a1a1e"
            radius: 12
            border.color: "#333"
            border.width: 1
            
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: 16
                color: "black"
                opacity: 0.4
                z: -1
            }
        }
        
        contentItem: Column {
            spacing: 2
            
            // Export Current Page
            Rectangle {
                width: 168; height: 38; radius: 8
                color: expCurrentMa.containsMouse ? "#252528" : "transparent"
                
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12
                    spacing: 10
                    
                    Text { text: "📄"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Export Current"; color: "white"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                
                MouseArea {
                    id: expCurrentMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        exportMenu.close()
                        if (targetCanvas && targetCanvas.currentProjectPath !== "") {
                            exportSingleDialog.currentExportPath = targetCanvas.currentProjectPath
                            exportSingleDialog.currentExportName = targetCanvas.currentProjectName || "page"
                            exportSingleDialog.open()
                        }
                    }
                }
            }
            
            // Export All Pages
            Rectangle {
                width: 168; height: 38; radius: 8
                color: expAllMa.containsMouse ? "#252528" : "transparent"
                
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12
                    spacing: 10
                    
                    Text { text: "📁"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Export All Pages"; color: "white"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                
                MouseArea {
                    id: expAllMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        exportMenu.close()
                        exportAllDialog.open()
                    }
                }
            }
            
            // Separator
            Rectangle { width: 160; height: 1; color: "#2a2a2e"; anchors.horizontalCenter: parent.horizontalCenter }
            
            // Export as PNG
            Rectangle {
                width: 168; height: 38; radius: 8
                color: expPngMa.containsMouse ? "#252528" : "transparent"
                
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12
                    spacing: 10
                    
                    Text { text: "🖼️"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "All as PNG"; color: "#aaa"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                
                MouseArea {
                    id: expPngMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        exportMenu.close()
                        exportAllFormatDialog.exportFormat = "PNG"
                        exportAllFormatDialog.open()
                    }
                }
            }
            
            // Export as JPG
            Rectangle {
                width: 168; height: 38; radius: 8
                color: expJpgMa.containsMouse ? "#252528" : "transparent"
                
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12
                    spacing: 10
                    
                    Text { text: "📸"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "All as JPG"; color: "#aaa"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                
                MouseArea {
                    id: expJpgMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        exportMenu.close()
                        exportAllFormatDialog.exportFormat = "JPG"
                        exportAllFormatDialog.open()
                    }
                }
            }
        }
    }
    
    // ═══════════════ EXPORT SINGLE PAGE DIALOG ═══════════════
    FileDialog {
        id: exportSingleDialog
        title: "Export Page"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)", "JPEG Image (*.jpg)"]
        
        property string currentExportPath: ""
        property string currentExportName: "page"
        
        onAccepted: {
            var pathStr = file.toString()
            var format = "PNG"
            if (pathStr.toLowerCase().endsWith(".jpg") || pathStr.toLowerCase().endsWith(".jpeg")) {
                format = "JPG"
            }
            
            // First save current work if it's the active page
            if (targetCanvas && targetCanvas.currentProjectPath === currentExportPath) {
                targetCanvas.saveProject(targetCanvas.currentProjectPath)
            }
            
            if (targetCanvas.exportPageImage(currentExportPath, file, format)) {
                // Notification handled by toast in parent
            }
        }
    }
    
    // ═══════════════ EXPORT ALL PAGES DIALOG ═══════════════
    FolderDialog {
        id: exportAllDialog
        title: "Select Output Folder for All Pages"
        
        onAccepted: {
            // Save current page first
            if (targetCanvas && targetCanvas.currentProjectPath !== "") {
                targetCanvas.saveProject(targetCanvas.currentProjectPath)
            }
            
            targetCanvas.exportAllPages(currentFolderPath, folder, "PNG")
        }
    }
    
    // ═══════════════ EXPORT ALL WITH FORMAT ═══════════════
    FolderDialog {
        id: exportAllFormatDialog
        title: "Select Output Folder"
        
        property string exportFormat: "PNG"
        
        onAccepted: {
            // Save current page first
            if (targetCanvas && targetCanvas.currentProjectPath !== "") {
                targetCanvas.saveProject(targetCanvas.currentProjectPath)
            }
            
            targetCanvas.exportAllPages(currentFolderPath, folder, exportFormat)
        }
    }
}
