import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../Translations.js" as Trans

Item {
    id: galleryRoot
    anchors.fill: parent

    // RECARGAR AL VOLVER A SER VISIBLE
    onVisibleChanged: if (visible) refreshGallery()

    // SEÑALES
    signal openSketchbook(string path, string title)
    signal openDrawing(string path)
    signal createNewProject()
    signal createNewGroup()
    signal backRequested()

    property int draggedIndex: -1
    property int targetIndex: -1
    property point grabOffset: "0,0"
    readonly property color colorAccent: "#3c82f6"

    readonly property string lang: (typeof preferencesManager !== "undefined") ? preferencesManager.language : "en"
    function qs(key) { return Trans.get(key, lang); }

    // 1. FONDO PREMIUM RESTAURADO
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08080a" }
            GradientStop { position: 1.0; color: "#0f0f12" }
        }
    }

    // 2. EL FANTASMA (Levitación Pro)
    Item {
        id: ghost
        width: 170; height: 230
        z: 99999
        visible: galleryRoot.draggedIndex !== -1
        property var ghostData: null

        scale: visible ? 1.18 : 0.5
        rotation: visible ? 4 : 0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on rotation { NumberAnimation { duration: 250 } }
        Behavior on x { NumberAnimation { duration: dragController.pressed ? 45 : 0 } }
        Behavior on y { NumberAnimation { duration: dragController.pressed ? 45 : 0 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowBlur: 1.0; shadowVerticalOffset: 25; shadowOpacity: 0.6
        }

        Rectangle {
            anchors.fill: parent; radius: 20; color: "#1c1c1e"; border.color: "#333"
            Loader {
                anchors.fill: parent; anchors.margins: 4
                sourceComponent: (ghost.ghostData && (ghost.ghostData.type === "folder" || ghost.ghostData.type === "sketchbook")) ? ghostStackComp : ghostImgComp
            }
        }
    }

    // 3. CONTENIDO (ColumnLayout para estructura limpia)
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 40; spacing: 40

        // HEADER PREMIUM (Imagen 2)
        RowLayout {
            Layout.fillWidth: true; spacing: 15
            Text { 
                text: "Gallery"
                color: "white"
                font.pixelSize: 22
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            
            // Icono de salida/puerta (Imagen 2 arriba a la derecha)
            Rectangle {
                width: 44; height: 44; radius: 12; color: "transparent"; border.color: "#333"
                Text { text: "🚪"; color: "white"; font.pixelSize: 18; anchors.centerIn: parent; opacity: 0.7 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: galleryRoot.backRequested() }
            }
        }

        // GRID DE PROYECTOS (Ajustado a Imagen 2)
        GridView {
            id: grid
            Layout.fillWidth: true; Layout.fillHeight: true
            cellWidth: 200; cellHeight: 180
            model: projectModel; clip: true; interactive: galleryRoot.draggedIndex === -1

            delegate: Item {
                id: delegateRoot; width: grid.cellWidth; height: grid.cellHeight
                opacity: galleryRoot.draggedIndex === index ? 0.0 : 1.0
                scale: (galleryRoot.targetIndex === index && galleryRoot.draggedIndex !== index) ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                Column {
                    anchors.centerIn: parent; spacing: 8
                    
                    Rectangle {
                        width: 170; height: 110; radius: 18
                        color: "#16161a"
                        border.color: maGalItem.containsMouse ? "#3c82f6" : "#222"
                        border.width: maGalItem.containsMouse ? 2 : 1
                        clip: true
                        
                        Loader {
                            id: cellLoaderGal
                            anchors.fill: parent
                            property var thumbnails: (model.thumbnails && model.thumbnails.length) ? model.thumbnails : []
                            property string title: model.name || ""
                            property bool isExpanded: (galleryRoot.targetIndex === index)
                            property string preview: model.preview || ""
                            sourceComponent: (model.type === "folder" || model.type === "sketchbook") ? stackComp : drawingComp
                        }
                    }
                    
                    Text { 
                        text: model.name || "Sin título"
                        color: maGalItem.containsMouse ? "#3c82f6" : "#aaa"
                        font.pixelSize: 12; font.weight: Font.Medium
                        width: 170; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter 
                    }
                }

                MouseArea {
                    id: maGalItem; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    pressAndHoldInterval: 250
                    onClicked: {
                        if (model.type === "folder" || model.type === "sketchbook") galleryRoot.openSketchbook(model.path, model.name)
                        else galleryRoot.openDrawing(model.path)
                    }
                    onPressAndHold: (mouse) => {
                        galleryRoot.draggedIndex = index
                        ghost.ghostData = projectModel.get(index)
                        var pos = delegateRoot.mapToItem(galleryRoot, 0, 0)
                        ghost.x = pos.x + (delegateRoot.width - ghost.width)/2
                        ghost.y = pos.y + (delegateRoot.height - ghost.height)/2
                        var m = mapToItem(galleryRoot, mouse.x, mouse.y)
                        galleryRoot.grabOffset = Qt.point(m.x - ghost.x, m.y - ghost.y)
                    }
                }
            }
        }
    }

    // TOOLBAR INFERIOR (Imagen 2)
    Rectangle {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        width: 320; height: 60; radius: 30; color: "#1c1c1e"
        opacity: galleryRoot.draggedIndex === -1 ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        Row {
            anchors.centerIn: parent; spacing: 12
            
            // Botones redondos premium
            GalleryToolButton { icon: "✅"; onClicked: console.log("Select") }
            GalleryToolButton { icon: "☆"; onClicked: console.log("Favorite") }
            
            // Botón central Grande "+"
            Rectangle {
                width: 50; height: 50; radius: 25
                gradient: Gradient { GradientStop { position: 0; color: "#4facfe" } GradientStop { position: 1; color: "#00f2fe" } }
                Text { text: "+"; color: "white"; font.pixelSize: 28; font.bold: true; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: galleryRoot.createNewProject() }
                scale: 1.1
            }
            
            GalleryToolButton { icon: "📁"; onClicked: galleryRoot.createNewGroup() }
            GalleryToolButton { icon: "📥"; onClicked: console.log("Import") }
        }
    }

    // Componente interno para botones de la toolbar
    component GalleryToolButton : Rectangle {
        property string icon: ""
        signal clicked()
        width: 40; height: 40; radius: 20; color: "#2c2c2e"
        Text { text: icon; color: "white"; font.pixelSize: 16; anchors.centerIn: parent; opacity: 0.8 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    // 4. CONTROLADOR DE ARRASTRE GLOBAL
    MouseArea {
        id: dragController; anchors.fill: parent; enabled: galleryRoot.draggedIndex !== -1
        onPositionChanged: (mouse) => {
            ghost.x = mouse.x - galleryRoot.grabOffset.x
            ghost.y = mouse.y - galleryRoot.grabOffset.y
            var p = mapToItem(grid, mouse.x, mouse.y)
            var idx = grid.indexAt(p.x, p.y + grid.contentY)
            galleryRoot.targetIndex = (idx !== -1 && idx !== galleryRoot.draggedIndex) ? idx : -1
        }
        onReleased: {
            if (galleryRoot.targetIndex !== -1) {
                var a = projectModel.get(galleryRoot.draggedIndex)
                var b = projectModel.get(galleryRoot.targetIndex)
                if (mainCanvas.create_folder_from_merge(a.path, b.path)) refreshGallery()
            }
            galleryRoot.draggedIndex = -1; galleryRoot.targetIndex = -1
        }
    }

    // MODELO Y RECARGA
    ListModel { id: projectModel }
    function refreshGallery() {
        projectModel.clear()
        if (typeof mainCanvas !== "undefined") {
            var list = mainCanvas.get_project_list()
            for(var i=0; i<list.length; i++) {
                var it = list[i]
                if (it.thumbnails) {
                    var th = []
                    for(var j=0; j<it.thumbnails.length; j++) th.push({ "modelData": it.thumbnails[j] })
                    it.thumbnails = th
                }
                projectModel.append(it)
            }
        }
    }
    Component.onCompleted: refreshGallery()
    
    Connections {
        target: mainCanvas
        function onProjectListChanged() {
            refreshGallery()
        }
    }

    // COMPONENTES DELEGADOS
    Component { 
        id: stackComp
        StackFolder {
            thumbnails: parent.thumbnails
            title: parent.title
            isExpanded: parent.isExpanded
        }
    }
    Component { 
        id: drawingComp
        Item { 
            anchors.fill: parent
            
            // Access model property directly for reliability
            property string previewUrl: model.preview || ""

            Image { 
                id: imgPreviewGal
                anchors.fill: parent
                source: previewUrl
                fillMode: Image.PreserveAspectCrop
                mipmap: true 
                asynchronous: true
                // Removed explicit visible check to see if it's a loading/status issue
                onStatusChanged: {
                    if (status === Image.Error) console.log("Gallery Image Error: " + source)
                }
            }
            
            // Placeholder
            Rectangle {
                anchors.fill: parent; color: "#1a1a20"
                // Only show placeholder if image is not ready AND we have a source url (loading) OR no source
                visible: imgPreviewGal.status !== Image.Ready
                z: -1 // Place behind
                Text { anchors.centerIn: parent; text: "✎"; color: "#2a2a35"; font.pixelSize: 32 }
            }
        } 
    }
    Component { id: ghostStackComp; StackFolder { thumbnails: ghost.ghostData ? ghost.ghostData.thumbnails : []; title: ghost.ghostData ? (ghost.ghostData.title || ghost.ghostData.name) : "" } }
    Component { 
        id: ghostImgComp
        Item { 
            width: 170; height: 230
            Rectangle { 
                anchors.fill: parent; radius: 18; color: "#1c1c1e"; border.color: "#444"; clip: true
                Image { anchors.fill: parent; source: ghost.ghostData ? ghost.ghostData.preview : ""; fillMode: Image.PreserveAspectCrop; mipmap: true } 
            } 
        } 
    }
}
