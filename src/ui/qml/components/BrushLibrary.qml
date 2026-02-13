import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root
    width: 680
    height: 520
    color: "#0d0d0f" 
    radius: 14
    border.color: "#1a1a1c"
    border.width: 1
    clip: true

    // Props
    property var brushList: []
    property string viewStyle: "stroke" // "text", "stroke", "shape", "large"
    property var targetCanvas: null
    property var contextPage: null
    property string searchQuery: ""
    property color accentColor: "#818cf8" 

    signal closeRequested()
    signal importRequested()
    signal settingsRequested(string brushName)
    signal editBrushRequested(string brushName)

    // Prevent click-through and scroll-through
    MouseArea { 
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {}
        function onWheel(wheel) { wheel.accepted = true }
    }

    // Logic
    onVisibleChanged: { if(visible) updateBrushList() }

    Connections {
        target: root.contextPage
        function onSelectedBrushCategoryChanged() { updateBrushList() }
    }

    function updateBrushList() {
        if (!root.contextPage) return
        var category = root.contextPage.selectedBrushCategory
        
        if (root.targetCanvas) {
             // For "Imported", we might still need some custom logic if it's not a real category in the backend
             // But assuming "Imported" is not one of the JSON categories generated, we might want to keep the old logic just for it,
             // OR assume the backend handles it.
             // Given the instructions, let's treat "Imported" as a special case if needed, but for the 15 categories, use the backend.
             
             if (category === "Imported") {
                 // Fallback to searching everything for now, or implement Imported logic later.
                 // For now, let's just list everything not in the main categories? 
                 // Or keep the old logic ONLY for Imported.
                 var all = root.targetCanvas.availableBrushes
                 var filtered = []
                 for(var i=0; i<all.length; i++) {
                     // Simple catch-all or specific "Imported" logic
                     // If the backend doesn't support "Imported" category, this will return empty.
                     // Let's try backend first.
                 }
                 // Actually, "Imported" brushes likely don't have a category in JSON unless added.
                 // Let's stick to the requested behavior for the 15 categories.
             }

             // Use the C++ backend for category filtering
             // If searched, we filter the result from backend
             var catBrushes = root.targetCanvas.getBrushesForCategory(category)
             
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
    }


    // Header Helper
    function autoSelectCategory(toolName) {
        if (!root.contextPage) return
        var t = String(toolName).toLowerCase()
        if (t === "brush" || t === "paint") root.contextPage.selectedBrushCategory = "Painting"
        else if (t === "pencil") root.contextPage.selectedBrushCategory = "Sketching"
        else if (t === "pen" || t === "ink") root.contextPage.selectedBrushCategory = "Inking"
        else if (t === "airbrush") root.contextPage.selectedBrushCategory = "Airbrushing"
        else if (t === "eraser") root.contextPage.selectedBrushCategory = "Sketching"
        else if (t === "watercolor" || t === "water") root.contextPage.selectedBrushCategory = "Artistic"
        updateBrushList()
    }

    function setCategoryIcon(toolName) {
         autoSelectCategory(toolName)
    }

    // ========== PREMIUM HEADER ==========
    Rectangle {
        id: header
        width: parent.width
        height: 70
        color: "transparent"
        z: 100
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 16
            spacing: 20

            Text {
                text: "LIBRARY"
                color: "white"
                font.pixelSize: 10
                font.letterSpacing: 3
                font.weight: Font.Black
                opacity: 0.9
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.maximumWidth: 260
                radius: 18
                color: "#161618"
                border.color: searchInput.activeFocus ? "#333" : "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 12

                    Text { text: ""; font.family: "Material Icons"; color: "#444"; font.pixelSize: 18; visible: false }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "white"
                        font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: {
                            root.searchQuery = text
                            root.updateBrushList()
                        }
                        
                        Text {
                            text: "Find brushes..."
                            color: "#444"
                            font.pixelSize: 13
                            visible: parent.text === "" && !parent.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 32; height: 32; radius: 16
                color: optMa.containsMouse ? "#222" : "transparent"
                
                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Repeater {
                        model: 3
                        Rectangle { width: 14; height: 1.5; color: "white"; opacity: 0.6 }
                    }
                }

                MouseArea {
                    id: optMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: optionsMenu.open()
                }
                
                Menu {
                    id: optionsMenu
                    y: parent.height + 8
                    x: -160
                    width: 200
                    
                    background: Rectangle {
                        color: "#1c1c1e"
                        radius: 10
                        border.color: "#333"
                        border.width: 1
                    }
                    
                    T_MenuItem { 
                        text: "Show Strokes" 
                        isActive: root.viewStyle === "stroke"
                        onTriggered: root.viewStyle = "stroke"
                    }
                    T_MenuItem { 
                        text: "Names Only" 
                        isActive: root.viewStyle === "text"
                        onTriggered: root.viewStyle = "text"
                    }
                    T_MenuItem { 
                        text: "Card View" 
                        isActive: root.viewStyle === "large"
                        onTriggered: root.viewStyle = "large"
                    }
                }
            }

            Rectangle {
                width: 32; height: 32; radius: 16
                color: closeMa.containsMouse ? "#222" : "transparent"
                Text { text: "✕"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent; opacity: 0.6 }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.closeRequested()
                }
            }
        }
        
        Rectangle {
            width: parent.width - 48
            height: 1
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#1a1a1c"
        }
    }

    // ========== MAIN LAYOUT ==========
    RowLayout {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 170
            color: "transparent"
            
            ListView {
                id: categoryList
                anchors.fill: parent
                anchors.topMargin: 20
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                
                model: ["Sketching", "Inking", "Drawing", "Painting", "Artistic", "Calligraphy", "Airbrushing", "Textures", "Abstract", "Charcoal", "Elements", "Sprays", "Industrial", "Luminance", "Vintage", "Imported"]
                
                delegate: Rectangle {
                    width: parent.width
                    height: 44
                    color: "transparent"
                    property bool isSelected: root.contextPage && root.contextPage.selectedBrushCategory === modelData
                    
                    Rectangle {
                        width: 3; height: 12; radius: 1.5
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: accentColor
                        visible: isSelected
                    }

                    Text {
                        text: modelData
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        anchors.verticalCenter: parent.verticalCenter
                        color: isSelected ? "white" : "#555"
                        font.pixelSize: 13
                        font.weight: isSelected ? Font.DemiBold : Font.Normal
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { if(root.contextPage) root.contextPage.selectedBrushCategory = modelData }
                    }
                }

                footer: Column {
                    width: parent.width
                    
                    Item { width: 1; height: 20 } // Spacer

                    Rectangle {
                        width: parent.width
                        height: 60
                        color: "transparent"
                        Text {
                            text: "+ IMPORT .ABR"
                            anchors.centerIn: parent
                            color: importMa.containsMouse ? "white" : accentColor
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                            opacity: 0.8
                        }
                        MouseArea {
                            id: importMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.importRequested()
                        }
                    }
                }
            }
        }
        
        Rectangle { Layout.fillHeight: true; width: 1; color: "#1a1a1c"; Layout.topMargin: 20; Layout.bottomMargin: 20 }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            clip: true
            
            ListView {
                id: brushList
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 2
                model: root.brushList
                visible: root.viewStyle !== "large"
                clip: true
                
                // Consume wheel events to prevent canvas zoom
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onWheel: function(wheel) {
                        if (wheel.angleDelta.y > 0) {
                            brushList.flick(0, 800)
                        } else {
                            brushList.flick(0, -800)
                        }
                        wheel.accepted = true
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    width: 3; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 1.5; color: "#222" }
                }
                
                delegate: Rectangle {
                    id: listDelegate
                    width: brushList.width
                    height: (root.viewStyle === "text") ? 48 : 68
                    radius: 10
                    property bool isSelected: root.targetCanvas && root.targetCanvas.activeBrushName === modelData
                    
                    // Premium background with subtle gradient on selected
                    color: isSelected 
                        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
                        : (itemMa.containsMouse ? "#0e0e10" : "transparent")
                    border.color: isSelected ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35) : "transparent"
                    border.width: isSelected ? 1 : 0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 16
                        
                        // Active indicator bar
                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.preferredHeight: 20
                            radius: 1.5
                            color: accentColor
                            visible: isSelected
                        }

                        // ARTISTIC PREVIEW
                        Item {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 48
                            visible: root.viewStyle !== "text"
                            
                            Image {
                                id: previewImg
                                anchors.fill: parent
                                source: root.targetCanvas ? root.targetCanvas.get_brush_preview(modelData) : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: "#111"; radius: 4
                                    visible: previewImg.status !== Image.Ready
                                    opacity: 0.5
                                }
                            }
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: isSelected ? "white" : (itemMa.containsMouse ? "#bbb" : "#777")
                            font.pixelSize: 14
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Settings gear (appears on hover or selected)
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: gearMa.containsMouse ? "#2a2a2c" : "transparent"
                            visible: isSelected || itemMa.containsMouse
                            opacity: gearMa.containsMouse ? 1.0 : 0.5

                            Text { text: "⚙"; font.pixelSize: 13; anchors.centerIn: parent; color: "#ccc" }
                            MouseArea {
                                id: gearMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.targetCanvas.usePreset(modelData)
                                    root.editBrushRequested(modelData)
                                }
                            }
                        }

                        Rectangle { width: 4; height: 4; radius: 2; color: accentColor; visible: isSelected }
                    }
                    
                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                brushCtxMenu.brushName = modelData
                                brushCtxMenu.popup()
                                return
                            }
                            if(root.targetCanvas) { 
                                root.targetCanvas.usePreset(modelData)
                                // Don't close — let user see it selected
                            } 
                        }
                        onDoubleClicked: {
                            if(root.targetCanvas) {
                                root.targetCanvas.usePreset(modelData)
                                root.editBrushRequested(modelData)
                            }
                        }
                    }
                }
            }
            
            GridView {
                id: brushGrid
                anchors.fill: parent
                anchors.margins: 20
                cellWidth: 154
                cellHeight: 160
                model: root.brushList
                visible: root.viewStyle === "large"
                clip: true
                
                // Consume wheel events to prevent canvas zoom
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onWheel: function(wheel) {
                        if (wheel.angleDelta.y > 0) {
                            brushGrid.flick(0, 800)
                        } else {
                            brushGrid.flick(0, -800)
                        }
                        wheel.accepted = true
                    }
                }
                
                delegate: Item {
                    width: 154; height: 160
                    property bool isSelected: root.targetCanvas && root.targetCanvas.activeBrushName === modelData
                    
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 6
                        radius: 14
                        color: isSelected 
                            ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
                            : (gMa.containsMouse ? "#0e0e10" : "transparent")
                        border.color: isSelected ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : (gMa.containsMouse ? "#2a2a2c" : "#1a1a1c")
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10
                            spacing: 10
                            
                            Item {
                                Layout.preferredWidth: 120; Layout.preferredHeight: 80
                                Layout.alignment: Qt.AlignHCenter
                                Image {
                                    anchors.fill: parent
                                    source: root.targetCanvas ? root.targetCanvas.get_brush_preview(modelData) : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                            }
                            
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: isSelected ? "white" : (gMa.containsMouse ? "#bbb" : "#777")
                                font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                font.weight: isSelected ? Font.DemiBold : Font.Normal
                            }
                        }
                        
                        // Gear icon on hover
                        Rectangle {
                            width: 24; height: 24; radius: 12
                            anchors.top: parent.top; anchors.topMargin: 6
                            anchors.right: parent.right; anchors.rightMargin: 6
                            color: gridGearMa.containsMouse ? "#333" : "#1c1c1e"
                            visible: gMa.containsMouse || isSelected
                            opacity: gridGearMa.containsMouse ? 1 : 0.7
                            
                            Text { text: "⚙"; font.pixelSize: 11; anchors.centerIn: parent; color: "#ccc" }
                            MouseArea {
                                id: gridGearMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.targetCanvas.usePreset(modelData)
                                    root.editBrushRequested(modelData)
                                }
                            }
                        }
                        
                        MouseArea {
                            id: gMa; anchors.fill: parent; hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    brushCtxMenu.brushName = modelData
                                    brushCtxMenu.popup()
                                    return
                                }
                                if(root.targetCanvas) { 
                                    root.targetCanvas.usePreset(modelData)
                                } 
                            }
                            onDoubleClicked: {
                                if(root.targetCanvas) {
                                    root.targetCanvas.usePreset(modelData)
                                    root.editBrushRequested(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // === RIGHT-CLICK CONTEXT MENU ===
    Menu {
        id: brushCtxMenu
        property string brushName: ""
        width: 220
        
        background: Rectangle {
            color: "#1c1c1e"; radius: 12; border.color: "#333"; border.width: 1
            // Shadow
            Rectangle { z: -1; anchors.fill: parent; anchors.margins: -6; color: "#000"; opacity: 0.5; radius: 18 }
        }
        
        T_MenuItem {
            text: "✎  Edit in Brush Studio"
            onTriggered: {
                if(root.targetCanvas) root.targetCanvas.usePreset(brushCtxMenu.brushName)
                root.editBrushRequested(brushCtxMenu.brushName)
            }
        }
        
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#2a2a2c" } }
        
        T_MenuItem {
            text: "⊕  Duplicate Brush"
            onTriggered: {
                // TODO: Implement brush duplication
                console.log("Duplicate brush:", brushCtxMenu.brushName)
            }
        }
        
        T_MenuItem {
            text: "↓  Share / Export"
            onTriggered: console.log("Export brush:", brushCtxMenu.brushName)
        }
        
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#2a2a2c" } }
        
        T_MenuItem {
            text: "✕  Delete"
            onTriggered: console.log("Delete brush:", brushCtxMenu.brushName)
        }
    }

    component T_MenuItem : MenuItem {
        id: menuControl
        property bool isActive: false
        contentItem: RowLayout {
            spacing: 12
            Rectangle { width: 4; height: 4; radius: 2; color: accentColor; visible: menuControl.isActive; Layout.leftMargin: -8 }
            Text { text: menuControl.text; color: menuControl.isActive ? "white" : "#aaa"; font.pixelSize: 13; Layout.fillWidth: true }
        }
        background: Rectangle { color: menuControl.hovered ? "#2c2c2e" : "transparent"; radius: 6 }
    }
}
