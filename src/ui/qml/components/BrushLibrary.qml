import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Dialogs

Rectangle {
    id: root
    width: 380 * uiScale
    height: 700 * uiScale
    color: Qt.rgba(10/255, 10/255, 12/255, 0.88)
    radius: 24 * uiScale
    border.color: "#161619"
    border.width: 1
    clip: true

    // Props
    property var brushList: []
    property var targetCanvas: null
    property var contextPage: null
    property string searchQuery: ""
    property color accentColor: "#3b82f6" // Vibrant iOS/Procreate Blue
    
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0

    signal closeRequested()
    signal importRequested()
    signal settingsRequested(string brushName)
    signal editBrushRequested(string brushName)

    property string selectedCategory: ""

    // Block all clicks and scroll wheel leaks to canvas
    MouseArea { 
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {}
        onWheel: (wheel) => { wheel.accepted = true }
    }

    onVisibleChanged: { if(visible) updateBrushList() }

    Connections {
        target: root.contextPage
        function onSelectedBrushCategoryChanged() { updateBrushList() }
    }

    Connections {
        target: root.targetCanvas
        function onAvailableBrushesChanged() { updateBrushList() }
    }

    function updateBrushList() {
        if (!root.contextPage || !root.targetCanvas) return
        var category = root.contextPage.selectedBrushCategory
        var catBrushes = root.targetCanvas.getBrushesForCategory(category)
        if (!catBrushes) return
        
        if (root.searchQuery !== "") {
            var filtered = []
            for(var i=0; i<catBrushes.length; i++) {
                if (String(catBrushes[i]).toLowerCase().includes(root.searchQuery.toLowerCase())) {
                    filtered.push(catBrushes[i])
                }
            }
            root.brushList = filtered
        } else {
            root.brushList = catBrushes
        }
    }

    // ========== MAIN CONTENT ==========
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 1. BRUSH LIST (Left Panel)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 64 * root.uiScale
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 16 * root.uiScale
                Layout.topMargin: 4 * root.uiScale
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * root.uiScale
                    
                    Text {
                        id: headerCategoryText
                        text: root.contextPage ? root.contextPage.selectedBrushCategory : "Brushes"
                        color: "white"
                        font.pixelSize: 20 * root.uiScale
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.brushList.length + (root.brushList.length === 1 ? " brush" : " brushes")
                        color: "#71717a"
                        font.pixelSize: 11 * root.uiScale
                        font.weight: Font.Medium
                    }
                }

                // Import .ABR Button
                Rectangle {
                    width: 36 * root.uiScale; height: 36 * root.uiScale
                    radius: 18 * root.uiScale
                    color: importBtnMa.pressed ? "#27272a" : (importBtnMa.containsMouse ? "#1f1f22" : "#141416")
                    border.color: importBtnMa.containsMouse ? "#3f3f46" : "#27272a"
                    border.width: 1
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        text: "+"
                        color: importBtnMa.containsMouse ? "white" : "#a1a1aa"
                        font.pixelSize: 20 * root.uiScale
                        font.weight: Font.Light
                        anchors.centerIn: parent
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    MouseArea {
                        id: importBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: importDialog.open()
                    }
                    
                    ToolTip.visible: importBtnMa.containsMouse
                    ToolTip.text: "Import Photoshop Brushes (.abr)"
                    ToolTip.delay: 300
                }
            }

            // Dialog to import ABR files
            FileDialog {
                id: importDialog
                title: "Import Brush Pack (.abr)"
                nameFilters: ["Photoshop Brushes (*.abr)", "All Files (*)"]
                fileMode: FileDialog.OpenFile
                onAccepted: {
                    if (root.targetCanvas) {
                        var success = root.targetCanvas.importABR(selectedFile)
                        if (success) {
                            if (root.contextPage) {
                                root.contextPage.selectedBrushCategory = "Imported"
                            }
                            root.updateBrushList()
                        }
                    }
                }
            }

            // Premium Search Bar (Frosted/Focused glowing)
            Rectangle {
                id: searchBarContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 36 * root.uiScale
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 20 * root.uiScale
                Layout.topMargin: 4 * root.uiScale
                Layout.bottomMargin: 12 * root.uiScale
                radius: 10 * root.uiScale
                
                color: sInput.activeFocus ? "#131316" : (searchBarMouse.containsMouse ? "#111113" : "#0d0d0f")
                border.color: sInput.activeFocus ? root.accentColor : "#1e1e22"
                border.width: 1
                
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12 * root.uiScale
                    anchors.rightMargin: 12 * root.uiScale
                    spacing: 8 * root.uiScale
                    
                    // Vector magnifying glass
                    Item {
                        width: 14 * root.uiScale; height: 14 * root.uiScale
                        Layout.alignment: Qt.AlignVCenter
                        
                        Rectangle {
                            width: 10 * root.uiScale; height: 10 * root.uiScale
                            radius: 5 * root.uiScale
                            color: "transparent"
                            border.color: sInput.activeFocus ? root.accentColor : "#52525b"
                            border.width: 1.5 * root.uiScale
                            anchors.left: parent.left
                            anchors.top: parent.top
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                        
                        Rectangle {
                            width: 5 * root.uiScale; height: 1.5 * root.uiScale
                            color: sInput.activeFocus ? root.accentColor : "#52525b"
                            rotation: 45
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 0
                            anchors.bottomMargin: 0
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    
                    TextInput {
                        id: sInput
                        Layout.fillWidth: true
                        color: "white"
                        font.pixelSize: 12 * root.uiScale
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        activeFocusOnTab: true
                        
                        onTextChanged: { root.searchQuery = text; root.updateBrushList() }
                        
                        Text {
                            text: "Search brushes..."
                            color: "#52525b"
                            font.pixelSize: 12 * root.uiScale
                            visible: parent.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Clear search text button
                    Text {
                        text: "✕"
                        color: "#71717a"
                        font.pixelSize: 11 * root.uiScale
                        visible: sInput.text !== ""
                        Layout.alignment: Qt.AlignVCenter
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { sInput.text = ""; sInput.focus = false }
                        }
                    }
                }
                
                MouseArea {
                    id: searchBarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sInput.forceActiveFocus()
                }
            }

            // Brush Grid / ListView
            ListView {
                id: brushListItems
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 10 * root.uiScale
                model: root.brushList
                
                leftMargin: 20 * root.uiScale
                rightMargin: 16 * root.uiScale
                topMargin: 2 * root.uiScale
                bottomMargin: 2 * root.uiScale
                
                ScrollBar.vertical: ScrollBar { 
                    id: verticalScrollBar
                    width: 6 * root.uiScale
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { 
                        color: verticalScrollBar.pressed ? root.accentColor : (verticalScrollBar.active || verticalScrollBar.hovered ? Qt.lighter(root.accentColor, 1.2) : "#27272a")
                        radius: 3 * root.uiScale 
                        opacity: 0.6
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                delegate: Item {
                    id: brushCard
                    width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                    height: 86 * root.uiScale
                    
                    property bool isSelected: root.targetCanvas && root.targetCanvas.activeBrushName === modelData
                    property string previewSource: ""
                    
                    onModelDataChanged: {
                        previewSource = root.targetCanvas ? root.targetCanvas.get_brush_preview(modelData) : ""
                    }
                    Component.onCompleted: {
                        previewSource = root.targetCanvas ? root.targetCanvas.get_brush_preview(modelData) : ""
                    }
                    
                    Rectangle {
                        id: cardRect
                        anchors.fill: parent
                        radius: 14 * root.uiScale
                        
                        color: brushCard.isSelected 
                            ? "#131620" 
                            : (brushItemMa.containsMouse ? "#0f0f12" : "#08080a")
                        
                        border.color: brushCard.isSelected 
                            ? root.accentColor 
                            : (brushItemMa.containsMouse ? "#222227" : "#131316")
                        
                        border.width: brushCard.isSelected ? 1.5 * root.uiScale : 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        
                        layer.enabled: brushCard.isSelected
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(59/255, 130/255, 246/255, 0.25)
                            shadowBlur: 0.5
                            shadowVerticalOffset: 1 * root.uiScale
                        }
                        
                        // Brush Title Text (Elegant, inside the card at the top-left)
                        Text {
                            id: brushNameText
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 16 * root.uiScale
                            anchors.topMargin: 10 * root.uiScale
                            anchors.right: parent.right
                            anchors.rightMargin: 16 * root.uiScale
                            
                            text: modelData
                            color: brushCard.isSelected ? "#ffffff" : (brushItemMa.containsMouse ? "#f3f4f6" : "#a1a1aa")
                            font.pixelSize: 11.5 * root.uiScale
                            font.weight: brushCard.isSelected ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        
                        // Brush Stroke Preview Image (Below the text inside the same selected border)
                        Image {
                            id: strokeImg
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: brushNameText.bottom
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 16 * root.uiScale
                            anchors.rightMargin: 16 * root.uiScale
                            anchors.topMargin: 4 * root.uiScale
                            anchors.bottomMargin: 8 * root.uiScale
                            source: brushCard.previewSource
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            opacity: brushCard.isSelected ? 1.0 : (brushItemMa.containsMouse ? 0.92 : 0.75)
                            mipmap: true
                            smooth: true
                            
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            
                            // Spinner while loading
                            Rectangle {
                                anchors.fill: parent; color: "transparent"
                                visible: parent.status !== Image.Ready
                                BusyIndicator { 
                                    anchors.centerIn: parent; 
                                    width: 16 * root.uiScale; height: 16 * root.uiScale; 
                                    visible: parent.visible 
                                }
                            }
                        }
                    }
                    
                    MouseArea {
                        id: brushItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                brushContextMenu.brushTarget = modelData
                                brushContextMenu.popup()
                            } else {
                                if(root.targetCanvas) root.targetCanvas.usePreset(modelData)
                            }
                        }
                        onDoubleClicked: {
                            if(root.targetCanvas) {
                                root.targetCanvas.usePreset(modelData)
                                root.editBrushRequested(modelData)
                            }
                        }
                    }
                    
                    // Brush Option Context Menu
                    Menu {
                        id: brushContextMenu
                        property string brushTarget: ""
                        
                        background: Rectangle {
                            implicitWidth: 160 * root.uiScale
                            color: "#121214"
                            border.color: "#222225"
                            border.width: 1
                            radius: 10 * root.uiScale
                        }
                        
                        MenuItem {
                            text: "✏️  Edit Brush"
                            onTriggered: {
                                if(root.targetCanvas) {
                                    root.targetCanvas.usePreset(brushContextMenu.brushTarget)
                                    root.editBrushRequested(brushContextMenu.brushTarget)
                                }
                            }
                        }
                        MenuItem {
                            text: "⎘  Duplicate"
                            onTriggered: {
                                if(root.targetCanvas) {
                                    root.targetCanvas.duplicateBrush(brushContextMenu.brushTarget)
                                    updateBrushList()
                                }
                            }
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "✎  Rename"
                            onTriggered: {
                                renameDialog.oldName = brushContextMenu.brushTarget
                                renameDialog.newNameText = brushContextMenu.brushTarget
                                renameDialog.open()
                            }
                        }
                        MenuItem {
                            text: "🗑  Delete"
                            enabled: root.targetCanvas ? !root.targetCanvas.isBuiltInBrush(brushContextMenu.brushTarget) : false
                            onTriggered: {
                                deleteDialog.brushTarget = brushContextMenu.brushTarget
                                deleteDialog.open()
                            }
                        }
                    }
                }
            }

            // New Brush Button (Clean Frosted Action Button)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38 * root.uiScale
                Layout.leftMargin: 20 * root.uiScale
                Layout.rightMargin: 16 * root.uiScale
                Layout.topMargin: 8 * root.uiScale
                Layout.bottomMargin: 16 * root.uiScale
                radius: 12 * root.uiScale
                
                color: newBrushMa.pressed ? "#1c1c1f" : (newBrushMa.containsMouse ? "#141416" : "#0e0e10")
                border.color: newBrushMa.containsMouse ? "#2d2d31" : "#1a1a1d"
                border.width: 1
                
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6 * root.uiScale
                    
                    Text { 
                        text: "+" 
                        color: root.accentColor 
                        font.pixelSize: 15 * root.uiScale 
                        font.weight: Font.Bold 
                        verticalAlignment: Text.AlignVCenter 
                    }
                    
                    Text { 
                        text: "New Brush" 
                        color: newBrushMa.containsMouse ? "white" : "#a1a1aa" 
                        font.pixelSize: 12 * root.uiScale 
                        font.weight: Font.Medium 
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: newBrushMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.targetCanvas) {
                            var category = root.contextPage ? root.contextPage.selectedBrushCategory : "Custom"
                            root.targetCanvas.createNewBrush("New Brush", category)
                            updateBrushList()
                            root.editBrushRequested("New Brush")
                        }
                    }
                }
            }
        }

        // 2. CATEGORY ICON TOOLBAR (Right Panel - Sleek & Tactile)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 56 * root.uiScale
            color: "#060608" // Deep contrast background
            
            // Left division separator
            Rectangle {
                width: 1; height: parent.height
                color: "#111114"
                anchors.left: parent.left
            }
            
            ListView {
                id: categoryListView
                anchors.fill: parent
                anchors.topMargin: 18 * root.uiScale
                anchors.bottomMargin: 18 * root.uiScale
                spacing: 12 * root.uiScale
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                model: root.targetCanvas ? root.targetCanvas.brushCategories : []

                ScrollBar.vertical: ScrollBar { 
                    width: 2; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { color: "#18181b"; radius: 1 }
                }

                delegate: Rectangle {
                    id: cateItem
                    width: 40 * root.uiScale; height: 40 * root.uiScale
                    radius: 20 * root.uiScale
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    property bool isCurrent: root.contextPage && root.contextPage.selectedBrushCategory === modelData.name
                    
                    color: isCurrent 
                        ? Qt.rgba(59/255, 130/255, 246/255, 0.1) 
                        : (catMa.containsMouse ? "#111113" : "transparent")
                    
                    border.color: isCurrent ? root.accentColor : "transparent"
                    border.width: isCurrent ? 1 : 0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Image {
                        source: "image://icons/" + modelData.icon
                        width: 18 * root.uiScale; height: 18 * root.uiScale
                        anchors.centerIn: parent
                        sourceSize: Qt.size(18 * root.uiScale, 18 * root.uiScale)
                        smooth: true
                        mipmap: true
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: cateItem.isCurrent ? root.accentColor : (catMa.containsMouse ? "#ffffff" : "#6b7280")
                        }
                    }

                    MouseArea {
                        id: catMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if(root.contextPage) root.contextPage.selectedBrushCategory = modelData.name }
                    }
                    
                    ToolTip.visible: catMa.containsMouse
                    ToolTip.text: modelData.name
                    ToolTip.delay: 300
                }
            }
        }
    }

    // 3. ABR IMPORTING SCREEN OVERLAY
    Rectangle {
        id: importOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: root.targetCanvas && root.targetCanvas.isImporting
        z: 1000

        // Block interaction
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width * 0.7
            spacing: 16 * root.uiScale

            Text {
                text: "Importing Brushes..."
                color: "white"
                font.pixelSize: 15 * root.uiScale
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
            }

            // Custom glowing progress track
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6 * root.uiScale
                color: "#18181b"
                radius: 3 * root.uiScale

                Rectangle {
                    width: parent.width * (root.targetCanvas ? root.targetCanvas.importProgress : 0)
                    height: parent.height
                    color: root.accentColor
                    radius: 3 * root.uiScale
                    
                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                text: root.targetCanvas ? Math.round(root.targetCanvas.importProgress * 100) + "%" : "0%"
                color: "#71717a"
                font.pixelSize: 11 * root.uiScale
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // ── Rename Dialog ──────────────────────────────────────────────────
    Dialog {
        id: renameDialog
        property string oldName: ""
        property string newNameText: ""
        title: "Rename Brush"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel

        Column {
            spacing: 8; width: 280

            Text { text: "New name:"; color: "#ccc"; font.pixelSize: 12 }
            Rectangle {
                width: parent.width; height: 36; radius: 6
                color: "#1c1c1e"; border.color: "#3a3a3a"; border.width: 1
                TextInput {
                    id: renameInput
                    anchors.fill: parent; anchors.margins: 8
                    text: renameDialog.newNameText
                    color: "white"; font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                }
            }
        }

        onAccepted: {
            var newN = renameInput.text.trim()
            if (newN.length > 0 && root.targetCanvas) {
                root.targetCanvas.renameBrush(renameDialog.oldName, newN)
                updateBrushList()
            }
        }
    }

    // ── Delete Confirm Dialog ──────────────────────────────────────────
    Dialog {
        id: deleteDialog
        property string brushTarget: ""
        title: "Delete Brush"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No

        Text {
            text: "Delete \"" + deleteDialog.brushTarget + "\"?\nThis cannot be undone."
            color: "#ccc"; font.pixelSize: 13
            wrapMode: Text.WordWrap; width: 260
        }

        onAccepted: {
            if (root.targetCanvas) {
                root.targetCanvas.deleteBrush(deleteDialog.brushTarget)
                updateBrushList()
            }
        }
    }
}
