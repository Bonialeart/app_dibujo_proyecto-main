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

    readonly property color colorAccent: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color colorTextPrimary: "#f4f4f8"
    readonly property color colorTextSecondary: "#6e6e7a"
    readonly property color colorTextMuted: "#4a4a55"

    readonly property string lang: (typeof preferencesManager !== "undefined") ? preferencesManager.language : "en"
    function qs(key) { return Trans.get(key, lang); }
    function iconPath(name) { return "image://icons/" + name; }

    // ═══════════════════════════════════════
    // 1. PREMIUM DEEP BACKGROUND
    // ═══════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#040406" }
            GradientStop { position: 0.4; color: "#08080c" }
            GradientStop { position: 1.0; color: "#0a0a0f" }
        }
    }

    // Ambient glow orb (top-right)
    Rectangle {
        width: 400; height: 400; radius: 200
        x: parent.width - 250; y: -150
        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.03)
        z: -1
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }

        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { to: -130; duration: 6000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -150; duration: 6000; easing.type: Easing.InOutSine }
        }
    }

    // Ambient glow orb (bottom-left)
    Rectangle {
        width: 300; height: 300; radius: 150
        x: -100; y: parent.height - 200
        color: Qt.rgba(1.0, 0.4, 0.2, 0.02)
        z: -1
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
    }

    // ═══════════════════════════════════════
    // 2. GHOST (Drag Preview)
    // ═══════════════════════════════════════
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

    // ═══════════════════════════════════════
    // 3. MAIN CONTENT
    // ═══════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Premium Header ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 72
            color: "transparent"

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 36; anchors.rightMargin: 36
                spacing: 16

                // Back button with SVG icon
                Rectangle {
                    width: 42; height: 42; radius: 14
                    color: backMa.containsMouse ? "#15ffffff" : "#0affffff"
                    border.color: backMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : "#12ffffff"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Image {
                        source: iconPath("arrow-left.svg")
                        width: 20; height: 20; anchors.centerIn: parent
                        opacity: backMa.containsMouse ? 1.0 : 0.6
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    scale: backMa.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                    MouseArea {
                        id: backMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: galleryRoot.backRequested()
                    }
                }

                // Title
                Column {
                    spacing: 2
                    Text {
                        text: "Gallery"
                        color: colorTextPrimary
                        font.pixelSize: 26; font.weight: Font.Bold; font.letterSpacing: -0.8
                    }
                    Text {
                        text: projectModel.count + " projects"
                        color: colorTextMuted
                        font.pixelSize: 12; font.letterSpacing: 0.3
                    }
                }

                Item { Layout.fillWidth: true }

                // Search placeholder button
                Rectangle {
                    width: 42; height: 42; radius: 14
                    color: searchMa.containsMouse ? "#15ffffff" : "#0affffff"
                    border.color: "#12ffffff"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Image {
                        source: iconPath("search.svg")
                        width: 18; height: 18; anchors.centerIn: parent
                        opacity: searchMa.containsMouse ? 1.0 : 0.5
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: searchMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Sort button
                Rectangle {
                    width: 42; height: 42; radius: 14
                    color: sortMa.containsMouse ? "#15ffffff" : "#0affffff"
                    border.color: "#12ffffff"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Image {
                        source: iconPath("sort.svg")
                        width: 18; height: 18; anchors.centerIn: parent
                        opacity: sortMa.containsMouse ? 1.0 : 0.5
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: sortMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            // Bottom separator gradient
            Rectangle {
                width: parent.width; height: 1; anchors.bottom: parent.bottom
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: "#15ffffff" }
                    GradientStop { position: 0.7; color: "#15ffffff" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        // ── Project Grid ──
        GridView {
            id: grid
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.leftMargin: 36; Layout.rightMargin: 36
            Layout.topMargin: 25
            cellWidth: 220; cellHeight: 210
            model: projectModel; clip: true; interactive: galleryRoot.draggedIndex === -1
            boundsBehavior: Flickable.StopAtBounds

            // Empty state
            Rectangle {
                anchors.fill: parent
                visible: projectModel.count === 0
                color: "transparent"

                Column {
                    anchors.centerIn: parent; spacing: 16

                    // Icon circle
                    Rectangle {
                        width: 80; height: 80; radius: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.08)
                        border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15)
                        border.width: 1

                        Image {
                            source: iconPath("image.svg")
                            width: 32; height: 32; anchors.centerIn: parent
                            opacity: 0.4
                        }
                    }

                    Text {
                        text: "No projects yet"
                        color: colorTextSecondary; font.pixelSize: 18; font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Create your first masterpiece with the + button below"
                        color: colorTextMuted; font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            delegate: Item {
                id: delegateRoot; width: grid.cellWidth; height: grid.cellHeight
                property bool isEditing: false
                opacity: galleryRoot.draggedIndex === index ? 0.0 : 1.0
                scale: (galleryRoot.targetIndex === index && galleryRoot.draggedIndex !== index) ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                Column {
                    anchors.centerIn: parent; spacing: 10
                    
                    // ── Thumbnail Card ──
                    Rectangle {
                        width: 195; height: 140; radius: 20
                        color: (model.type === "folder" || model.type === "sketchbook") ? "transparent" : "#12121a"
                        border.color: (model.type === "folder" || model.type === "sketchbook") ? "transparent"
                            : (maGalItem.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5) : "#15ffffff")
                        border.width: (model.type === "folder" || model.type === "sketchbook") ? 0 : (maGalItem.containsMouse ? 2 : 1)
                        clip: (model.type === "folder" || model.type === "sketchbook") ? false : true

                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Loader {
                            id: cellLoaderGal
                            anchors.fill: parent
                            property var thumbnails: model.thumbnails
                            property string title: model.name || ""
                            property bool isExpanded: (galleryRoot.targetIndex === index)
                            property string preview: model.preview || ""
                            property bool isHovered: maGalItem.containsMouse
                            sourceComponent: (model.type === "folder" || model.type === "sketchbook") ? stackComp : drawingComp
                        }
                    }
                    
                    // ── Title & Date ──
                    Item {
                        width: 195; height: 36

                        Column {
                            anchors.fill: parent; spacing: 2
                            
                            Text {
                                width: parent.width
                                visible: !delegateRoot.isEditing
                                text: model.name || "Sin título"
                                color: maGalItem.containsMouse ? colorTextPrimary : colorTextSecondary
                                font.pixelSize: 13; font.weight: Font.DemiBold; font.letterSpacing: -0.2
                                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Text {
                                width: parent.width
                                text: model.date || ""
                                color: colorTextMuted; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                visible: text !== "" && !delegateRoot.isEditing
                            }
                        }

                        // Right-click to rename
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
                            anchors.fill: parent; anchors.topMargin: 0
                            visible: delegateRoot.isEditing
                            text: model.name || ""
                            font.pixelSize: 13; font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            color: "white"; selectByMouse: true
                            background: Rectangle {
                                color: "#1a1a1e"; radius: 8
                                border.color: colorAccent; border.width: 1
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

                // ── Delete Button (Top Right) ──
                Rectangle {
                    width: 28; height: 28; radius: 14; z: 100
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                    color: maDel.containsMouse ? "#ef4444" : "#cc1a1a20"
                    border.color: maDel.containsMouse ? "#ef4444" : "#25ffffff"
                    border.width: 1
                    opacity: (maGalItem.containsMouse || maDel.containsMouse) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        source: iconPath("trash-2.svg")
                        width: 14; height: 14; anchors.centerIn: parent
                        opacity: 0.9
                    }

                    MouseArea {
                        id: maDel; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
                        var globalGrab = maGalItem.mapToItem(galleryRoot, mouse.x, mouse.y)
                        var itemPos = delegateRoot.mapToItem(galleryRoot, 0, 0)
                        ghost.x = itemPos.x + (delegateRoot.width - ghost.width)/2
                        ghost.y = itemPos.y + (delegateRoot.height - ghost.height)/2
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

    // ═══════════════════════════════════════
    // 4. PREMIUM BOTTOM TOOLBAR
    // ═══════════════════════════════════════
    Rectangle {
        id: bottomToolbar
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        width: toolbarRow.width + 32; height: 64; radius: 32
        color: "#cc0e0e14"
        border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15)
        border.width: 1

        opacity: galleryRoot.draggedIndex === -1 ? 1.0 : 0.0
        scale: galleryRoot.draggedIndex === -1 ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        // Frosted glass inner layer
        Rectangle {
            anchors.fill: parent; anchors.margins: 1; radius: 31
            color: Qt.rgba(1, 1, 1, 0.03)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Row {
            id: toolbarRow
            anchors.centerIn: parent; spacing: 6

            // Select All
            GalleryToolButton {
                iconSource: iconPath("select-all.svg")
                label: "Select"
                onClicked: console.log("Select")
            }

            // Favorites
            GalleryToolButton {
                iconSource: iconPath("star.svg")
                label: "Favorites"
                onClicked: console.log("Favorite")
            }

            // ── Central "+" Button (Primary CTA) ──
            Rectangle {
                width: 54; height: 54; radius: 27
                anchors.verticalCenter: parent.verticalCenter

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.lighter(colorAccent, 1.15) }
                    GradientStop { position: 1.0; color: Qt.darker(colorAccent, 1.1) }
                }

                // Top shine
                Rectangle {
                    width: parent.width - 4; height: parent.height / 2
                    anchors.top: parent.top; anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 25
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.2) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Border ring
                Rectangle {
                    anchors.fill: parent; anchors.margins: 1; radius: 26
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.12); border.width: 1
                }

                Image {
                    source: iconPath("plus.svg")
                    width: 22; height: 22; anchors.centerIn: parent

                    rotation: addBtnMa.containsMouse ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                }

                scale: addBtnMa.pressed ? 0.9 : (addBtnMa.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                MouseArea {
                    id: addBtnMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: galleryRoot.createNewProject()
                }
            }

            // New Folder
            GalleryToolButton {
                iconSource: iconPath("folder.svg")
                label: "New Folder"
                onClicked: galleryRoot.createNewGroup()
            }

            // Import
            GalleryToolButton {
                iconSource: iconPath("import.svg")
                label: "Import"
                onClicked: console.log("Import")
            }
        }
    }

    // ═══════════════════════════════════════
    // INTERNAL COMPONENTS
    // ═══════════════════════════════════════

    // Premium Gallery Toolbar Button
    component GalleryToolButton : Rectangle {
        property string iconSource: ""
        property string label: ""
        signal clicked()

        width: 46; height: 46; radius: 23
        anchors.verticalCenter: parent.verticalCenter
        color: gtbMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.12) : "#15ffffff"
        border.color: gtbMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25) : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Image {
            source: iconSource
            width: 20; height: 20; anchors.centerIn: parent
            opacity: gtbMa.containsMouse ? 1.0 : 0.6
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        scale: gtbMa.pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        MouseArea {
            id: gtbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        ToolTip {
            visible: gtbMa.containsMouse; delay: 600
            text: label
        }
    }

    // ═══════════════════════════════════════
    // MODEL & DATA
    // ═══════════════════════════════════════
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

    // ═══════════════════════════════════════
    // DELEGATE COMPONENTS
    // ═══════════════════════════════════════

    // Stack/Folder Component
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

            // === CARD 3 (Background) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: tCount > 2
                z: 1; radius: 18; color: "#1c1c22"
                border.color: "#2a2a30"; border.width: 1
                
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

            // === CARD 2 (Middle) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: tCount > 1
                z: 2; radius: 18; color: "#1c1c22"
                border.color: "#2a2a30"; border.width: 1
                
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

            // === CARD 1 (Front) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: !isEmpty
                z: 3; radius: 18; color: "#1c1c22"
                
                border.color: stackRoot.isHovered ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.6) : "#333"
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

            // === Empty State ===
            Rectangle {
                anchors.fill: parent
                visible: isEmpty
                color: "#1c1c22"; radius: 18
                border.color: stackRoot.isHovered ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.6) : "#333"
                border.width: stackRoot.isHovered ? 2 : 1

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#aa000000"; shadowBlur: 1.0; shadowVerticalOffset: 6 }

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Image {
                        source: iconPath("folder.svg")
                        width: 28; height: 28; opacity: 0.35
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Empty Group"; color: "#555"; font.pixelSize: 11 }
                }
            }
        }
    }

    // Drawing Component
    Component {
        id: drawingComp
        Item {
            anchors.fill: parent
            property string previewUrl: parent.preview || ""

            Rectangle {
                id: card
                anchors.fill: parent
                color: "#14141a"
                radius: 20

                Image {
                    id: imgPreviewGal
                    anchors.fill: parent
                    source: previewUrl
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    asynchronous: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskRect
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#80000000"
                    shadowBlur: 1.0
                    shadowVerticalOffset: 8
                    shadowOpacity: 0.5
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent; radius: 20
                    visible: false; layer.enabled: true
                }
            }

            // Placeholder
            Column {
                anchors.centerIn: parent; spacing: 8
                visible: imgPreviewGal.status !== Image.Ready && imgPreviewGal.source == ""

                Image {
                    source: iconPath("image.svg")
                    width: 28; height: 28; opacity: 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                }
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
