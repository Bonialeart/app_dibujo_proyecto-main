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
        // REMOVED BEHAVIORS ON X/Y FOR INSTANT FEEDBACK

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
                property bool isEditing: false
                opacity: galleryRoot.draggedIndex === index ? 0.0 : 1.0
                scale: (galleryRoot.targetIndex === index && galleryRoot.draggedIndex !== index) ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                Column {
                    anchors.centerIn: parent; spacing: 8
                    
                    Rectangle {
                        width: 170; height: 110; radius: 18
                        
                        // 1. Si es carpeta, fondo transparente. Si es lienzo, fondo oscuro.
                        color: (model.type === "folder" || model.type === "sketchbook") ? "transparent" : "#16161a"
                        // 2. Si es carpeta, sin bordes (los dibujaremos en la pila).
                        border.color: (model.type === "folder" || model.type === "sketchbook") ? "transparent" : (maGalItem.containsMouse ? "#3c82f6" : "#222")
                        border.width: (model.type === "folder" || model.type === "sketchbook") ? 0 : (maGalItem.containsMouse ? 2 : 1)
                        // 3. VITAL: No recortar si es carpeta
                        clip: (model.type === "folder" || model.type === "sketchbook") ? false : true 
                        
                        Loader {
                            id: cellLoaderGal
                            anchors.fill: parent
                            // ✅ CORRECCIÓN 1: Pasar el modelo directo sin chequear .length
                            property var thumbnails: model.thumbnails 
                            property string title: model.name || ""
                            property bool isExpanded: (galleryRoot.targetIndex === index)
                            property string preview: model.preview || ""
                            // 4. NUEVO: Pasamos el estado del mouse para animar la pila
                            property bool isHovered: maGalItem.containsMouse 
                            sourceComponent: (model.type === "folder" || model.type === "sketchbook") ? stackComp : drawingComp
                        }
                    }
                    
                    Item {
                        width: 170; height: 24
                        Text { 
                            anchors.fill: parent
                            visible: !delegateRoot.isEditing
                            text: model.name || "Sin título"
                            color: maGalItem.containsMouse ? "#3c82f6" : "#aaa"
                            font.pixelSize: 12; font.weight: Font.Medium
                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter 
                            verticalAlignment: Text.AlignVCenter
                        }

                        // ✅ RIGHT CLICK FOR RENAMING
                        MouseArea {
                            anchors.fill: parent
                            visible: !delegateRoot.isEditing
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    delegateRoot.isEditing = true
                                } else {
                                    if (model.type === "folder" || model.type === "sketchbook") galleryRoot.openSketchbook(model.path, model.name)
                                    else galleryRoot.openDrawing(model.path)
                                }
                            }
                        }

                        TextField {
                            id: editField
                            anchors.fill: parent
                            visible: delegateRoot.isEditing
                            text: model.name || ""
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            color: "white"
                            selectByMouse: true
                            background: Rectangle { 
                                color: "#1a1a1e"
                                radius: 4
                                border.color: "#3c82f6"
                                border.width: 1
                            }
                            onAccepted: {
                                if (text !== "" && text !== model.name) {
                                    mainCanvas.rename_item(model.path, text)
                                }
                                delegateRoot.isEditing = false
                            }
                            onEditingFinished: delegateRoot.isEditing = false
                            Component.onCompleted: if(visible) forceActiveFocus()
                            onVisibleChanged: if(visible) { text = model.name; forceActiveFocus(); selectAll(); }
                        }
                    }
                }

                // Action Buttons (Top Right)
                Rectangle {
                    width: 26; height: 26; radius: 13; z: 100
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 6
                    color: maDel.containsMouse ? "#ef4444" : "#cc1c1c1e"
                    border.color: "#30ffffff"; border.width: 1
                    opacity: (maGalItem.containsMouse || maDel.containsMouse) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Text { text: "✕"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                    MouseArea {
                        id: maDel; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (model.type === "folder" || model.type === "sketchbook") {
                                if (mainCanvas.deleteFolder(model.path)) refreshGallery()
                            } else {
                                if (mainCanvas.deleteProject(model.path)) refreshGallery()
                            }
                        }
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
                        // Absolute mapping to global gallery root
                        var globalGrab = maGalItem.mapToItem(galleryRoot, mouse.x, mouse.y)
                        var itemPos = delegateRoot.mapToItem(galleryRoot, 0, 0)
                        
                        ghost.x = itemPos.x + (delegateRoot.width - ghost.width)/2
                        ghost.y = itemPos.y + (delegateRoot.height - ghost.height)/2
                        
                        // Recalculate grabOffset based on ghost's top-left
                        galleryRoot.grabOffset = Qt.point(globalGrab.x - ghost.x, globalGrab.y - ghost.y)
                    }
                    onPositionChanged: (mouse) => {
                        if (galleryRoot.draggedIndex === index) {
                            var globalPos = maGalItem.mapToItem(galleryRoot, mouse.x, mouse.y)
                            ghost.x = globalPos.x - galleryRoot.grabOffset.x
                            ghost.y = globalPos.y - galleryRoot.grabOffset.y
                            
                            var gridPos = galleryRoot.mapToItem(grid, globalPos.x, globalPos.y)
                            var idx = grid.indexAt(gridPos.x, gridPos.y + grid.contentY)
                            galleryRoot.targetIndex = (idx !== -1 && idx !== galleryRoot.draggedIndex) ? idx : -1
                        }
                    }
                    onReleased: {
                        if (galleryRoot.draggedIndex === index) {
                            if (galleryRoot.targetIndex !== -1) {
                                var a = projectModel.get(galleryRoot.draggedIndex)
                                var b = projectModel.get(galleryRoot.targetIndex)
                                if (mainCanvas.create_folder_from_merge(a.path, b.path)) {
                                    refreshGallery()
                                }
                            }
                        }
                        galleryRoot.draggedIndex = -1
                        galleryRoot.targetIndex = -1
                    }
                    onCanceled: {
                        galleryRoot.draggedIndex = -1
                        galleryRoot.targetIndex = -1
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
        Item {
            id: stackRoot
            anchors.fill: parent
            property bool isHovered: parent.isHovered || false
            
            function getThumb(idx) {
                if (!thumbnails) return "";
                if (thumbnails.count !== undefined) {
                    return idx < thumbnails.count ? thumbnails.get(idx).modelData : "";
                }
                if (thumbnails.length !== undefined) {
                    return idx < thumbnails.length ? (thumbnails[idx].modelData || thumbnails[idx]) : "";
                }
                return "";
            }

            property int tCount: thumbnails ? (thumbnails.count !== undefined ? thumbnails.count : (thumbnails.length || 0)) : 0
            property bool isEmpty: tCount === 0

            // === CARD 3 (Al fondo) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: tCount > 2
                z: 1; radius: 18; color: "#1c1c22"
                border.color: "#2a2a30"; border.width: 1
                
                // Rotación y offset significativos para que sea MUY visible
                rotation: stackRoot.isHovered ? -18 : -10
                scale: stackRoot.isHovered ? 0.95 : 0.92
                x: stackRoot.isHovered ? -35 : -15
                y: stackRoot.isHovered ? -12 : -6
                
                Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#cc000000"; shadowBlur: 1.0; shadowVerticalOffset: 4 }

                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; mipmap: true; asynchronous: true
                    source: getThumb(2)
                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: m3 }
                }
                Rectangle { id: m3; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            }

            // === CARD 2 (Medio) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: tCount > 1
                z: 2; radius: 18; color: "#1c1c22"
                border.color: "#2a2a30"; border.width: 1
                
                // ✅ MEJORA: Siempre visible con offset
                rotation: stackRoot.isHovered ? 14 : 7
                scale: stackRoot.isHovered ? 0.98 : 0.95
                x: stackRoot.isHovered ? 35 : 15
                y: stackRoot.isHovered ? -10 : -4
                
                Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#bb000000"; shadowBlur: 1.0; shadowVerticalOffset: 4 }

                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; mipmap: true; asynchronous: true
                    source: getThumb(1)
                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: m2 }
                }
                Rectangle { id: m2; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            }

            // === CARD 1 (Frente) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: !isEmpty
                z: 3; radius: 18; color: "#1c1c22"
                
                border.color: stackRoot.isHovered ? "#3c82f6" : "#333"
                border.width: stackRoot.isHovered ? 2 : 1
                
                scale: stackRoot.isHovered ? 1.02 : 1.0
                y: stackRoot.isHovered ? 5 : 0
                
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#99000000"; shadowBlur: 1.0; shadowVerticalOffset: 8 }

                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; mipmap: true; asynchronous: true
                    source: getThumb(0)
                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: m1 }
                }
                Rectangle { id: m1; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            }

            // === ESTADO VACÍO (Carpeta nueva) ===
            Rectangle {
                anchors.fill: parent
                visible: isEmpty
                color: "#1c1c22"; radius: 18
                border.color: stackRoot.isHovered ? "#3c82f6" : "#333"
                border.width: stackRoot.isHovered ? 2 : 1

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#aa000000"; shadowBlur: 1.0; shadowVerticalOffset: 6 }

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📁"; font.pixelSize: 32; opacity: 0.5 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Empty Group"; color: "#555"; font.pixelSize: 11 }
                }
            }
        }
    }
    Component { 
        id: drawingComp
        Item { 
            anchors.fill: parent
            
            // ✅ CORRECCIÓN 1: En lugar de usar `model.preview`, leemos 
            // la propiedad que pasamos a través del Loader.
            property string previewUrl: parent.preview || ""

            // Contenedor principal de la tarjeta Premium
            Rectangle {
                id: card
                anchors.fill: parent
                color: "#1c1c22" // Fondo oscuro base
                radius: 16       // Bordes súper redondeados estilo Apple/Procreate
                
                // La Imagen de la Miniatura
                Image {
                    id: imgPreviewGal
                    anchors.fill: parent
                    source: previewUrl
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true 
                    asynchronous: true
                    
                    // ✅ CORRECCIÓN 2: Aplicación correcta de la máscara en Qt6
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskRect
                    }
                }
                
                // Sombra Premium (A nivel de tarjeta, debajo de la imagen enmascarada)
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#80000000" // Sombra oscura y profunda
                    shadowBlur: 1.0
                    shadowVerticalOffset: 8
                    shadowOpacity: 0.5
                }
                
                // Máscara (El secreto para que la imagen respete los bordes redondeados)
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 16
                    visible: false
                    layer.enabled: true // REQUISITO OBLIGATORIO PARA QUE FUNCIONE LA MÁSCARA
                }
                
                // Borde sutil
                border.color: maGalItem.containsMouse ? "#3c82f6" : "#333"
                border.width: maGalItem.containsMouse ? 2 : 1
            }
            
            // Placeholder: Si la imagen está cargando o C++ no envió nada, 
            // mostramos un icono bonito en lugar de una caja negra vacía.
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: imgPreviewGal.status !== Image.Ready && imgPreviewGal.source == ""
                
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🎨"; font.pixelSize: 32; opacity: 0.4 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No preview"; color: "#555"; font.pixelSize: 10 }
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
