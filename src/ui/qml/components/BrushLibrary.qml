import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Dialogs

Rectangle {
    id: root
    width: 380 // Más estrecho, estilo panel lateral de iPad/Procreate
    height: 700 
    color: "#0d0d0f" 
    radius: 24
    border.color: "#1a1a1c"
    border.width: 1
    clip: true

    // Props
    property var brushList: []
    property var targetCanvas: null
    property var contextPage: null
    property string searchQuery: ""
    property color accentColor: "#3b82f6" // Azul vibrante estilo Procreate/iOS

    signal closeRequested()
    signal importRequested()
    signal settingsRequested(string brushName)
    signal editBrushRequested(string brushName)

    // Bloquear clics y rueda al lienzo
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

        // 1. LISTA DE PINCELES (Izquierda)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Header "Brushes"
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.leftMargin: 20
                Layout.rightMargin: 10
                
                Text {
                    text: root.contextPage ? root.contextPage.selectedBrushCategory : "Brushes"
                    color: "white"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: addMa.containsMouse ? "#222" : "transparent"
                    Text { text: "+"; color: "white"; font.pixelSize: 24; anchors.centerIn: parent }
                    MouseArea {
                        id: addMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: importDialog.open()
                    }
                }
            }

            // Dialogo para importar archivos ABR
            FileDialog {
                id: importDialog
                title: "Import Brush Pack (.abr)"
                nameFilters: ["Photoshop Brushes (*.abr)", "All Files (*)"]
                fileMode: FileDialog.OpenFile
                onAccepted: {
                    if (root.targetCanvas) {
                        var success = root.targetCanvas.importABR(selectedFile)
                        if (success) {
                            // Cambiar a la categoría Imported para ver los nuevos pinceles
                            if (root.contextPage) {
                                root.contextPage.selectedBrushCategory = "Imported"
                            }
                            root.updateBrushList()
                        }
                    }
                }
            }

            // Buscador
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 10
                radius: 10; color: "#161618"
                
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12
                    Text { text: ""; font.family: "Material Icons"; color: "#444"; font.pixelSize: 18 }
                    TextInput {
                        id: sInput; Layout.fillWidth: true; color: "white"; font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: { root.searchQuery = text; root.updateBrushList() }
                        Text { text: "Find brushes..."; color: "#444"; font.pixelSize: 13; visible: parent.text === ""; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            // Lista de Cards
            ListView {
                id: brushListItems
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 12
                model: root.brushList
                contentItem.anchors.leftMargin: 20
                contentItem.anchors.rightMargin: 10
                
                ScrollBar.vertical: ScrollBar { 
                    width: 4
                    contentItem: Rectangle { color: "#333"; radius: 2 }
                }

                delegate: Rectangle {
                    id: brushCard
                    width: brushListItems.width - 30
                    height: 90
                    radius: 16
                    property bool isSelected: root.targetCanvas && root.targetCanvas.activeBrushName === modelData
                    
                    color: isSelected ? Qt.rgba(59/255, 130/255, 246/255, 0.1) : "#161618"
                    border.color: isSelected ? "#3b82f6" : "transparent"
                    border.width: isSelected ? 2 : 0

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        Text {
                            text: modelData
                            color: isSelected ? "white" : "#888"
                            font.pixelSize: 12
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                        }

                        Image {
                            width: parent.width
                            height: 50
                            source: root.targetCanvas ? root.targetCanvas.get_brush_preview(modelData) : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            opacity: isSelected ? 1.0 : 0.8
                            
                            // Placeholder mientras carga
                            Rectangle {
                                anchors.fill: parent; color: "transparent"
                                visible: parent.status !== Image.Ready
                                BusyIndicator { anchors.centerIn: parent; width: 20; height: 20; visible: parent.visible }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if(root.targetCanvas) root.targetCanvas.usePreset(modelData)
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

        // 2. BARRA DE CATEGORÍAS (Derecha - Estilo Iconos)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 60
            color: "#0a0a0c"
            
            ListView {
                id: categoryListView
                anchors.fill: parent
                anchors.topMargin: 20
                anchors.bottomMargin: 20
                spacing: 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                model: [
                    { name: "Favorites", icon: "cat_favorites" },
                    { name: "Sketching", icon: "cat_sketching" },
                    { name: "Inking", icon: "cat_inking" },
                    { name: "Drawing", icon: "marker" },
                    { name: "Painting", icon: "cat_painting" },
                    { name: "Artistic", icon: "palette" },
                    { name: "Airbrushing", icon: "airbrush" },
                    { name: "Charcoal", icon: "cat_charcoal" },
                    { name: "Textures", icon: "cat_textures" },
                    { name: "Luminance", icon: "cat_luminance" },
                    { name: "Imported", icon: "cat_imported" }
                ]

                ScrollBar.vertical: ScrollBar { 
                    width: 2; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { color: "#222"; radius: 1 }
                }

                delegate: Rectangle {
                    id: cateItem
                    width: 50; height: 50; radius: 25
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: (root.contextPage && root.contextPage.selectedBrushCategory === modelData.name) ? "#1c1c1e" : "transparent"
                    
                    Image {
                        source: "image://icons/" + modelData.icon
                        width: 24; height: 24
                        anchors.centerIn: parent
                        sourceSize: Qt.size(24, 24)
                        smooth: true
                        
                        // Icono blanco por defecto, se tiñe de azul si está seleccionado
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: (root.contextPage && root.contextPage.selectedBrushCategory === modelData.name) ? "#3b82f6" : "white"
                        }
                    }

                    MouseArea {
                        id: catMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { if(root.contextPage) root.contextPage.selectedBrushCategory = modelData.name }
                    }
                    
                    ToolTip.visible: catMa.containsMouse
                    ToolTip.text: modelData.name
                    ToolTip.delay: 300
                }
            }
        }
    }
}
