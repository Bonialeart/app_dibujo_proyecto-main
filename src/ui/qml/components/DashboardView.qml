import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import "../translations.js" as Trans

// ═══════════════════════════════════════════════════════════════
// GALERÍA KROMO — el arte es la interfaz.
// Fondo plano del tema, cabecera de texto, cuadrícula a sangre.
// Si un píxel no es un dibujo del usuario o una acción sobre él,
// no debería estar aquí.
// ═══════════════════════════════════════════════════════════════
Item {
    id: dashboardRoot
    anchors.fill: parent

    onVisibleChanged: if (visible) refresh()

    // Compatibilidad con ProjectNavigator
    property var externalModel: null
    signal openGallery()
    signal openProject(string path)
    signal openSketchbook(string path, string title)
    signal createNewProject()
    signal createNewGroup()

    // ── Estado de drag & drop ──
    property int draggedIndex: -1
    property int targetIndex: -1
    property point grabOffset: "0,0"

    // ── Estado de selección ──
    property bool selectionMode: false
    property var selectedItems: []   // [{path, type}]

    function isSelected(path) {
        for (var i = 0; i < selectedItems.length; i++)
            if (selectedItems[i].path === path) return true
        return false
    }
    function toggleSelected(path, type) {
        var list = selectedItems.slice()
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === path) { list.splice(i, 1); selectedItems = list; return }
        }
        list.push({ "path": path, "type": type })
        selectedItems = list
    }
    function exitSelection() { selectionMode = false; selectedItems = [] }

    readonly property string lang: (typeof preferencesManager !== "undefined" && preferencesManager !== null) ? preferencesManager.language : "en"
    function qs(key) { return Trans.get(key, lang); }

    // ── Tokens del tema (en vivo desde preferencias) ──
    readonly property bool dark: (typeof mainWindow !== "undefined") ? mainWindow.isDark : true
    readonly property color colorAccent: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color bg: (typeof mainWindow !== "undefined") ? mainWindow.colorBg : "#0e0e11"
    readonly property color surface: (typeof mainWindow !== "undefined") ? mainWindow.colorCard : "#1c1c1e"
    readonly property color textPrimary: (typeof mainWindow !== "undefined") ? mainWindow.colorText : "#f4f4f8"
    readonly property color textSecondary: dark ? "#9a9aa2" : "#52525b"
    readonly property color textFaint: dark ? "#5a5a62" : "#a1a1aa"
    readonly property color hairline: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color hairlineStrong: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.20)

    // ── Acciones ──
    function openItemAt(index, originRect) {
        var it = projectModel.get(index)
        if (!it) return
        if (it.type === "folder" || it.type === "sketchbook") {
            dashboardRoot.openSketchbook(it.path, it.name)
        } else if (it.preview && originRect && typeof mainWindow !== "undefined" && mainWindow.startHeroTransition) {
            mainWindow.startHeroTransition(originRect, it.preview, it.path)
        } else {
            dashboardRoot.openProject(it.path)
        }
    }

    function newCanvas(w, h) {
        if (typeof mainCanvas === "undefined" || !mainCanvas) return
        mainCanvas.clearProjectPath()
        mainCanvas.resizeCanvas(w, h)
        if (typeof mainWindow !== "undefined") {
            mainWindow.isProjectActive = true
            mainWindow.currentPage = 1
        }
        mainCanvas.fitToView()
    }

    function duplicateItems(items) {
        var did = false
        for (var i = 0; i < items.length; i++) {
            if (items[i].type !== "folder" && items[i].type !== "sketchbook")
                did = mainCanvas.duplicatePage(items[i].path) || did
        }
        if (did) refresh()
        exitSelection()
    }

    function deleteItems(items) {
        for (var i = 0; i < items.length; i++) {
            if (items[i].type === "folder" || items[i].type === "sketchbook") mainCanvas.deleteFolder(items[i].path)
            else mainCanvas.deleteProject(items[i].path)
        }
        refresh()
        exitSelection()
    }

    function stackSelected() {
        if (selectedItems.length !== 2) return
        var ops = (typeof nativeProjectModel !== "undefined" && nativeProjectModel) ? nativeProjectModel : mainCanvas
        if (ops && ops.create_folder_from_merge(selectedItems[0].path, selectedItems[1].path)) refresh()
        exitSelection()
    }

    // ═══════════════════════════════════════
    // FONDO — plano, del tema. Nada más.
    // ═══════════════════════════════════════
    Rectangle { anchors.fill: parent; color: dashboardRoot.bg }

    // ═══════════════════════════════════════
    // CABECERA — una línea de texto
    // ═══════════════════════════════════════
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        height: 52
        z: 10

        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            text: dashboardRoot.selectionMode
                  ? (dashboardRoot.selectedItems.length > 0 ? dashboardRoot.selectedItems.length + " ✓" : dashboardRoot.qs("select"))
                  : dashboardRoot.qs("gallery")
            color: dashboardRoot.textPrimary
            font.pixelSize: 18
            font.weight: Font.DemiBold
            font.letterSpacing: -0.3
        }
        Text {
            anchors.left: titleText.right
            anchors.leftMargin: 10
            anchors.baseline: titleText.baseline
            visible: !dashboardRoot.selectionMode && projectModel.count > 0
            text: projectModel.count
            color: dashboardRoot.textFaint
            font.pixelSize: 12
        }

        // Acciones normales — texto plano, sin botones
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24
            visible: !dashboardRoot.selectionMode

            ActionLabel {
                label: dashboardRoot.qs("select")
                enabled: projectModel.count > 0
                onClicked: dashboardRoot.selectionMode = true
            }
            ActionLabel {
                label: dashboardRoot.qs("import_files")
                onClicked: if (typeof openProjectDialog !== "undefined") openProjectDialog.open()
            }
            ActionLabel {
                label: dashboardRoot.qs("photo")
                onClicked: photoDialog.open()
            }

            // Botón "+" — icono fino dibujado
            Item {
                width: 24; height: 30
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 15; height: 1.5; radius: 1
                    anchors.centerIn: parent
                    color: plusMa.containsMouse ? dashboardRoot.textPrimary : dashboardRoot.textSecondary
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Rectangle {
                    width: 1.5; height: 15; radius: 1
                    anchors.centerIn: parent
                    color: plusMa.containsMouse ? dashboardRoot.textPrimary : dashboardRoot.textSecondary
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                MouseArea {
                    id: plusMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: plusPopover.open()
                }
            }

            // Menú overflow — Aprender / Recursos / Configuración
            Item {
                width: 24; height: 30
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "⋯"
                    color: moreMa.containsMouse ? dashboardRoot.textPrimary : dashboardRoot.textSecondary
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                MouseArea {
                    id: moreMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: morePopover.open()
                }
            }
        }

        // Acciones en modo selección — mismas posiciones, mismo lenguaje
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24
            visible: dashboardRoot.selectionMode

            ActionLabel {
                label: dashboardRoot.qs("stack_verb")
                enabled: dashboardRoot.selectedItems.length === 2
                onClicked: dashboardRoot.stackSelected()
            }
            ActionLabel {
                label: dashboardRoot.qs("duplicate")
                enabled: dashboardRoot.selectedItems.length > 0
                onClicked: dashboardRoot.duplicateItems(dashboardRoot.selectedItems)
            }
            ActionLabel {
                label: dashboardRoot.qs("delete")
                danger: true
                enabled: dashboardRoot.selectedItems.length > 0
                onClicked: confirmPopup.ask(dashboardRoot.selectedItems)
            }
            ActionLabel {
                label: dashboardRoot.qs("done")
                emphasized: true
                onClicked: dashboardRoot.exitSelection()
            }
        }

        // Hairline que solo aparece con scroll — ancla la cabecera
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: dashboardRoot.hairline
            opacity: grid.contentY > 4 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
    }

    // ═══════════════════════════════════════
    // CUADRÍCULA — miniaturas a sangre
    // ═══════════════════════════════════════
    GridView {
        id: grid
        anchors.top: header.bottom
        anchors.topMargin: 18
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.bottom: parent.bottom
        clip: true
        interactive: dashboardRoot.draggedIndex === -1
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 600
        footer: Item { width: 1; height: 60 }

        property int columns: Math.max(2, Math.round(width / 248))
        cellWidth: Math.floor(width / columns)
        cellHeight: cellWidth + 22

        model: projectModel

        delegate: Item {
            id: cell
            width: grid.cellWidth
            height: grid.cellHeight
            property int modelIndex: index
            property bool isEditing: false
            readonly property bool isFolder: model.type === "folder" || model.type === "sketchbook"
            readonly property bool isTarget: dashboardRoot.targetIndex === index && dashboardRoot.draggedIndex !== index
            readonly property bool selected: dashboardRoot.selectionMode && dashboardRoot.isSelected(model.path)

            opacity: dashboardRoot.draggedIndex === index ? 0.15
                   : (dashboardRoot.draggedIndex !== -1 && !isTarget ? 0.7 : 1.0)
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Item {
                id: thumbBox
                width: parent.width - 24
                height: width - 24
                anchors.top: parent.top

                scale: cell.isTarget ? 0.96
                     : ((thumbMa.containsMouse && !dashboardRoot.selectionMode && dashboardRoot.draggedIndex === -1) ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                Loader {
                    id: thumbLoader
                    anchors.fill: parent
                    property string preview: model.preview || ""
                    property string thumb0: model.thumb0 || ""
                    property string thumb1: model.thumb1 || ""
                    property string thumb2: model.thumb2 || ""
                    property int thumbCount: model.thumbCount || 0
                    property bool hovered: thumbMa.containsMouse && dashboardRoot.draggedIndex === -1
                    property bool showCheck: dashboardRoot.selectionMode
                    property bool checked: cell.selected
                    property color ringColor: cell.isTarget ? dashboardRoot.colorAccent
                        : (cell.selected ? dashboardRoot.colorAccent
                        : (hovered && !dashboardRoot.selectionMode ? dashboardRoot.hairlineStrong : "transparent"))
                    property real ringWidth: (cell.isTarget || cell.selected) ? 2 : 1
                    sourceComponent: cell.isFolder ? stackThumb : drawingThumb
                }

                MouseArea {
                    id: thumbMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    pressAndHoldInterval: 350
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            if (!dashboardRoot.selectionMode) {
                                var g = thumbMa.mapToItem(dashboardRoot, mouse.x, mouse.y)
                                ctxMenu.openFor(index, cell, g.x, g.y)
                            }
                            return
                        }
                        if (dashboardRoot.selectionMode) {
                            dashboardRoot.toggleSelected(model.path, model.type)
                            return
                        }
                        var p = thumbBox.mapToItem(null, 0, 0)
                        dashboardRoot.openItemAt(index, Qt.rect(p.x, p.y, thumbBox.width, thumbBox.height))
                    }
                    onPressAndHold: (mouse) => {
                        if (dashboardRoot.selectionMode) return
                        dashboardRoot.draggedIndex = index
                        ghost.ghostData = projectModel.get(index)
                        var globalGrab = thumbMa.mapToItem(dashboardRoot, mouse.x, mouse.y)
                        var itemPos = thumbBox.mapToItem(dashboardRoot, 0, 0)
                        ghost.x = itemPos.x + (thumbBox.width - ghost.width) / 2
                        ghost.y = itemPos.y + (thumbBox.height - ghost.height) / 2
                        dashboardRoot.grabOffset = Qt.point(globalGrab.x - ghost.x, globalGrab.y - ghost.y)
                    }
                    onPositionChanged: (mouse) => {
                        if (dashboardRoot.draggedIndex !== index) return
                        var globalPos = thumbMa.mapToItem(dashboardRoot, mouse.x, mouse.y)
                        ghost.x = globalPos.x - dashboardRoot.grabOffset.x
                        ghost.y = globalPos.y - dashboardRoot.grabOffset.y
                        var gp = dashboardRoot.mapToItem(grid, globalPos.x, globalPos.y)
                        var idx = (gp.x >= 0 && gp.y >= 0 && gp.x < grid.width && gp.y < grid.height)
                            ? grid.indexAt(gp.x + grid.contentX, gp.y + grid.contentY) : -1
                        dashboardRoot.targetIndex = (idx !== -1 && idx !== dashboardRoot.draggedIndex) ? idx : -1
                    }
                    onReleased: {
                        if (dashboardRoot.draggedIndex === index && dashboardRoot.targetIndex !== -1) {
                            var a = projectModel.get(dashboardRoot.draggedIndex)
                            var b = projectModel.get(dashboardRoot.targetIndex)
                            var ops = (typeof nativeProjectModel !== "undefined" && nativeProjectModel) ? nativeProjectModel : mainCanvas
                            if (a && b && ops && ops.create_folder_from_merge(a.path, b.path)) dashboardRoot.refresh()
                        }
                        dashboardRoot.draggedIndex = -1
                        dashboardRoot.targetIndex = -1
                    }
                    onCanceled: {
                        dashboardRoot.draggedIndex = -1
                        dashboardRoot.targetIndex = -1
                    }
                }
            }

            // ── Metadatos: título editable + fecha ──
            Column {
                anchors.top: thumbBox.bottom
                anchors.topMargin: 8
                width: thumbBox.width
                spacing: 2

                Item {
                    width: parent.width
                    height: 16

                    Text {
                        anchors.fill: parent
                        visible: !cell.isEditing
                        text: model.name || dashboardRoot.qs("untitled")
                        color: titleMa.containsMouse ? dashboardRoot.textPrimary : dashboardRoot.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: titleMa
                        anchors.fill: parent
                        visible: !cell.isEditing
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            if (dashboardRoot.selectionMode) dashboardRoot.toggleSelected(model.path, model.type)
                            else cell.isEditing = true
                        }
                    }
                    TextField {
                        anchors.fill: parent
                        visible: cell.isEditing
                        text: model.name || ""
                        font.pixelSize: 12
                        color: dashboardRoot.textPrimary
                        selectByMouse: true
                        padding: 0
                        leftPadding: 0
                        background: Item {
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 1
                                color: dashboardRoot.colorAccent
                            }
                        }
                        onAccepted: {
                            if (text !== "" && text !== model.name) mainCanvas.rename_item(model.path, text)
                            cell.isEditing = false
                        }
                        onEditingFinished: cell.isEditing = false
                        Keys.onEscapePressed: cell.isEditing = false
                        onVisibleChanged: if (visible) { text = model.name; forceActiveFocus(); selectAll() }
                    }
                }

                Text {
                    width: parent.width
                    text: model.date || ""
                    visible: text !== ""
                    color: dashboardRoot.textFaint
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ── Estado vacío: un lienzo fantasma, nada más ──
    Column {
        anchors.centerIn: grid
        spacing: 18
        visible: projectModel.count === 0

        Rectangle {
            width: 180; height: 224; radius: 8
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"
            border.color: emptyMa.containsMouse ? dashboardRoot.textSecondary : dashboardRoot.hairlineStrong
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 22; height: 1.5; radius: 1
                anchors.centerIn: parent
                color: dashboardRoot.textSecondary
            }
            Rectangle {
                width: 1.5; height: 22; radius: 1
                anchors.centerIn: parent
                color: dashboardRoot.textSecondary
            }

            MouseArea {
                id: emptyMa
                anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.createNewProject()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: dashboardRoot.qs("create_first")
            color: dashboardRoot.textSecondary
            font.pixelSize: 13
        }
    }

    // ═══════════════════════════════════════
    // GHOST DE ARRASTRE — la única sombra de la pantalla
    // ═══════════════════════════════════════
    Item {
        id: ghost
        width: 170; height: 170
        z: 9999
        visible: dashboardRoot.draggedIndex !== -1
        property var ghostData: null

        rotation: visible ? 3 : 0
        scale: visible ? 1.05 : 0.8
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowBlur: 0.9; shadowVerticalOffset: 10; shadowOpacity: 0.45
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: dashboardRoot.surface

            Image {
                anchors.fill: parent
                source: ghost.ghostData ? (ghost.ghostData.preview || ghost.ghostData.thumb0 || "") : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
                layer.enabled: true
                layer.effect: MultiEffect { maskEnabled: true; maskSource: ghostMask }
            }
            Rectangle { id: ghostMask; anchors.fill: parent; radius: 8; visible: false; layer.enabled: true }
        }
    }

    // ═══════════════════════════════════════
    // POPOVER "+" — tamaños de lienzo
    // ═══════════════════════════════════════
    Popup {
        id: plusPopover
        x: parent.width - width - 28
        y: header.height + 2
        width: 250
        padding: 6
        background: Rectangle {
            color: dashboardRoot.dark ? "#16161a" : "#ffffff"
            radius: 10
            border.color: dashboardRoot.hairline
            border.width: 1
        }
        contentItem: Column {
            spacing: 1
            MenuRow { label: dashboardRoot.qs("preset_screen"); detail: "1920 × 1080"; onClicked: { plusPopover.close(); dashboardRoot.newCanvas(1920, 1080) } }
            MenuRow { label: dashboardRoot.qs("preset_square"); detail: "2048 × 2048"; onClicked: { plusPopover.close(); dashboardRoot.newCanvas(2048, 2048) } }
            MenuRow { label: "4K"; detail: "3840 × 2160"; onClicked: { plusPopover.close(); dashboardRoot.newCanvas(3840, 2160) } }
            MenuRow { label: dashboardRoot.qs("preset_portrait"); detail: "1080 × 1920"; onClicked: { plusPopover.close(); dashboardRoot.newCanvas(1080, 1920) } }
            MenuRow { label: "A4"; detail: "2480 × 3508"; onClicked: { plusPopover.close(); dashboardRoot.newCanvas(2480, 3508) } }
            Rectangle { width: parent.width; height: 1; color: dashboardRoot.hairline }
            MenuRow { label: dashboardRoot.qs("custom_canvas"); onClicked: { plusPopover.close(); dashboardRoot.createNewProject() } }
            MenuRow { label: dashboardRoot.qs("new_stack"); onClicked: { plusPopover.close(); dashboardRoot.createNewGroup() } }
        }
    }

    // ═══════════════════════════════════════
    // POPOVER "⋯" — lo que antes era la sidebar
    // ═══════════════════════════════════════
    Popup {
        id: morePopover
        x: parent.width - width - 28
        y: header.height + 2
        width: 200
        padding: 6
        background: Rectangle {
            color: dashboardRoot.dark ? "#16161a" : "#ffffff"
            radius: 10
            border.color: dashboardRoot.hairline
            border.width: 1
        }
        contentItem: Column {
            spacing: 1
            MenuRow { label: dashboardRoot.qs("learn"); onClicked: { morePopover.close(); if (typeof mainWindow !== "undefined") mainWindow.currentPage = 2 } }
            MenuRow { label: dashboardRoot.qs("resources"); onClicked: { morePopover.close(); if (typeof mainWindow !== "undefined") mainWindow.currentPage = 3 } }
            MenuRow { label: dashboardRoot.qs("setup_page"); onClicked: { morePopover.close(); if (typeof mainWindow !== "undefined") mainWindow.currentPage = 4 } }
            Rectangle { width: parent.width; height: 1; color: dashboardRoot.hairline }
            MenuRow { label: dashboardRoot.qs("preferences"); onClicked: { morePopover.close(); if (typeof preferencesDialog !== "undefined") preferencesDialog.open() } }
        }
    }

    // ═══════════════════════════════════════
    // MENÚ CONTEXTUAL (clic derecho)
    // ═══════════════════════════════════════
    Popup {
        id: ctxMenu
        width: 190
        padding: 6
        property var targetItem: null
        property var targetCell: null

        function openFor(index, cellRef, gx, gy) {
            var it = projectModel.get(index)
            if (!it) return
            targetItem = { "path": it.path, "type": it.type, "name": it.name }
            targetCell = cellRef
            x = Math.min(gx, dashboardRoot.width - width - 8)
            y = Math.min(gy, dashboardRoot.height - height - 8)
            open()
        }

        background: Rectangle {
            color: dashboardRoot.dark ? "#16161a" : "#ffffff"
            radius: 10
            border.color: dashboardRoot.hairline
            border.width: 1
        }
        contentItem: Column {
            spacing: 1
            MenuRow {
                label: dashboardRoot.qs("rename")
                onClicked: { ctxMenu.close(); if (ctxMenu.targetCell) ctxMenu.targetCell.isEditing = true }
            }
            MenuRow {
                label: dashboardRoot.qs("duplicate")
                visible: ctxMenu.targetItem && ctxMenu.targetItem.type !== "folder" && ctxMenu.targetItem.type !== "sketchbook"
                onClicked: { ctxMenu.close(); dashboardRoot.duplicateItems([ctxMenu.targetItem]) }
            }
            MenuRow {
                label: dashboardRoot.qs("delete")
                danger: true
                onClicked: { ctxMenu.close(); confirmPopup.ask([ctxMenu.targetItem]) }
            }
        }
    }

    // ═══════════════════════════════════════
    // CONFIRMACIÓN DE BORRADO
    // ═══════════════════════════════════════
    Popup {
        id: confirmPopup
        modal: true
        anchors.centerIn: parent
        width: 300
        padding: 20
        property var pending: []
        function ask(items) { pending = items.slice(); open() }

        background: Rectangle {
            color: dashboardRoot.dark ? "#18181c" : "#ffffff"
            radius: 12
            border.color: dashboardRoot.hairline
            border.width: 1
        }
        contentItem: Column {
            spacing: 16

            Text {
                width: parent.width
                text: dashboardRoot.qs("delete_confirm")
                color: dashboardRoot.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: confirmPopup.pending.length === 1 && confirmPopup.pending[0].name
                      ? confirmPopup.pending[0].name
                      : confirmPopup.pending.length + " ✕"
                color: dashboardRoot.textSecondary
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Row {
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: cancelTxt.width + 28; height: 32; radius: 8
                    color: cancelMa.containsMouse ? dashboardRoot.hairline : "transparent"
                    border.color: dashboardRoot.hairline; border.width: 1
                    Text {
                        id: cancelTxt; anchors.centerIn: parent
                        text: dashboardRoot.qs("cancel")
                        color: dashboardRoot.textSecondary; font.pixelSize: 12
                    }
                    MouseArea {
                        id: cancelMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmPopup.close()
                    }
                }
                Rectangle {
                    width: delTxt.width + 28; height: 32; radius: 8
                    color: delMa.containsMouse ? "#f25257" : "#e5484d"
                    Text {
                        id: delTxt; anchors.centerIn: parent
                        text: dashboardRoot.qs("delete")
                        color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: delMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            confirmPopup.close()
                            dashboardRoot.deleteItems(confirmPopup.pending)
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════
    // FOTO → nuevo lienzo desde imagen
    // ═══════════════════════════════════════
    FileDialog {
        id: photoDialog
        title: dashboardRoot.qs("photo")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp *.webp)", "All Files (*)"]
        onAccepted: photoProbe.source = file
    }
    Image {
        id: photoProbe
        visible: false
        asynchronous: true
        onStatusChanged: {
            if (status !== Image.Ready || source == "") return
            var w = Math.max(64, Math.min(sourceSize.width, 8192))
            var h = Math.max(64, Math.min(sourceSize.height, 8192))
            if (typeof mainCanvas !== "undefined" && mainCanvas) {
                mainCanvas.clearProjectPath()
                mainCanvas.resizeCanvas(w, h)
                mainCanvas.importImageAsLayer(source.toString())
                if (typeof mainWindow !== "undefined") {
                    mainWindow.isProjectActive = true
                    mainWindow.currentPage = 1
                }
                mainCanvas.fitToView()
            }
            source = ""
        }
    }

    // ═══════════════════════════════════════
    // COMPONENTES INTERNOS
    // ═══════════════════════════════════════

    // Acción de cabecera: texto plano, sin caja
    component ActionLabel : Item {
        id: alRoot
        property string label: ""
        property bool danger: false
        property bool emphasized: false
        signal clicked()

        width: alText.width
        height: 30

        Text {
            id: alText
            anchors.centerIn: parent
            text: alRoot.label
            font.pixelSize: 13
            font.weight: alRoot.emphasized ? Font.DemiBold : Font.Medium
            color: !alRoot.enabled ? dashboardRoot.textFaint
                 : alRoot.danger ? (alMa.containsMouse ? "#f25257" : "#d8454a")
                 : alRoot.emphasized ? dashboardRoot.colorAccent
                 : (alMa.containsMouse ? dashboardRoot.textPrimary : dashboardRoot.textSecondary)
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
            id: alMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: alRoot.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (alRoot.enabled) alRoot.clicked()
        }
    }

    // Fila de menú flotante
    component MenuRow : Rectangle {
        id: mrRoot
        property string label: ""
        property string detail: ""
        property bool danger: false
        signal clicked()

        width: parent.width
        height: 36
        radius: 6
        color: mrMa.containsMouse
               ? (dashboardRoot.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05))
               : "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: mrRoot.label
            color: mrRoot.danger ? "#d8454a" : dashboardRoot.textPrimary
            font.pixelSize: 13
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: mrRoot.detail
            visible: text !== ""
            color: dashboardRoot.textFaint
            font.pixelSize: 11
        }
        MouseArea {
            id: mrMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mrRoot.clicked()
        }
    }

    // ── Miniatura de dibujo: el dibujo ES la tarjeta ──
    Component {
        id: drawingThumb
        Item {
            id: dRoot
            readonly property real ratio: (img.status === Image.Ready && img.sourceSize.height > 0)
                ? img.sourceSize.width / img.sourceSize.height : 4 / 3
            readonly property real fw: Math.min(width, Math.max(height * ratio, width * 0.4))
            readonly property real fh: Math.max(Math.min(height, fw / ratio), height * 0.42)

            Rectangle {
                id: frame
                width: dRoot.fw
                height: dRoot.fh
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 8
                color: dashboardRoot.surface

                Image {
                    id: img
                    anchors.fill: parent
                    source: preview !== "" ? preview : thumb0
                    sourceSize.width: 512
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                    layer.enabled: true
                    layer.effect: MultiEffect { maskEnabled: true; maskSource: dMask }
                }
                Rectangle { id: dMask; anchors.fill: parent; radius: 8; visible: false; layer.enabled: true }

                // Lienzo vacío: solo un hairline
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.color: dashboardRoot.hairline
                    border.width: 1
                    visible: img.status !== Image.Ready
                }

                // Anillo: hover / selección / destino de drop
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.color: ringColor
                    border.width: ringWidth
                    visible: ringColor.a > 0
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                // Check de selección
                Rectangle {
                    visible: showCheck
                    width: 22; height: 22; radius: 11
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    color: checked ? dashboardRoot.colorAccent : Qt.rgba(0, 0, 0, 0.35)
                    border.color: checked ? dashboardRoot.colorAccent : Qt.rgba(1, 1, 1, 0.85)
                    border.width: 1.5
                    Text {
                        anchors.centerIn: parent
                        text: "✓"; color: "white"; font.pixelSize: 12
                        visible: checked
                    }
                }
            }
        }
    }

    // ── Pila: hojas reales asomando, abanico al hover ──
    Component {
        id: stackThumb
        Item {
            id: sRoot
            readonly property real cw: width * 0.86
            readonly property real ch: cw * 0.72

            Item {
                width: sRoot.cw
                height: sRoot.ch + 14
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                // Hoja trasera
                Rectangle {
                    width: sRoot.cw; height: sRoot.ch
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: dashboardRoot.surface
                    opacity: 0.5
                    rotation: hovered ? -6.5 : -2.5
                    Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Image {
                        anchors.fill: parent
                        source: thumb2
                        visible: thumb2 !== ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; mipmap: true
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: sM3 }
                    }
                    Rectangle { id: sM3; anchors.fill: parent; radius: 8; visible: false; layer.enabled: true }
                }

                // Hoja media
                Rectangle {
                    width: sRoot.cw; height: sRoot.ch
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: dashboardRoot.surface
                    opacity: 0.75
                    rotation: hovered ? 5 : 2
                    Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Image {
                        anchors.fill: parent
                        source: thumb1
                        visible: thumb1 !== ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; mipmap: true
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: sM2 }
                    }
                    Rectangle { id: sM2; anchors.fill: parent; radius: 8; visible: false; layer.enabled: true }
                }

                // Portada
                Rectangle {
                    width: sRoot.cw; height: sRoot.ch
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: dashboardRoot.surface

                    Image {
                        anchors.fill: parent
                        source: thumb0
                        visible: thumb0 !== ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; mipmap: true
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: sM1 }
                    }
                    Rectangle { id: sM1; anchors.fill: parent; radius: 8; visible: false; layer.enabled: true }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        border.color: dashboardRoot.hairline
                        border.width: 1
                        visible: thumb0 === ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        border.color: ringColor
                        border.width: ringWidth
                        visible: ringColor.a > 0
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }

                    Rectangle {
                        visible: showCheck
                        width: 22; height: 22; radius: 11
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        color: checked ? dashboardRoot.colorAccent : Qt.rgba(0, 0, 0, 0.35)
                        border.color: checked ? dashboardRoot.colorAccent : Qt.rgba(1, 1, 1, 0.85)
                        border.width: 1.5
                        Text {
                            anchors.centerIn: parent
                            text: "✓"; color: "white"; font.pixelSize: 12
                            visible: checked
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════
    // MODELO — toda la biblioteca, sin secciones
    // ═══════════════════════════════════════
    ListModel { id: projectModel }

    function refresh() {
        projectModel.clear()
        // Usar nativeProjectModel (siempre disponible, no requiere un canvas activo).
        // Fallback a mainCanvas por compatibilidad.
        var list = []
        if (typeof nativeProjectModel !== "undefined" && nativeProjectModel)
            list = nativeProjectModel.getProjectsList()
        else if (typeof mainCanvas !== "undefined" && mainCanvas)
            list = mainCanvas.get_project_list()
        for (var i = 0; i < list.length; i++) {
            var it = list[i]
            var th = it.thumbnails || []
            projectModel.append({
                "name": it.name || it.title || qs("untitled"),
                "path": it.path || "",
                "type": it.type || "project",
                "date": it.date || "",
                "preview": it.preview || "",
                "thumb0": th.length > 0 ? (th[0].modelData || th[0] || "") : "",
                "thumb1": th.length > 1 ? (th[1].modelData || th[1] || "") : "",
                "thumb2": th.length > 2 ? (th[2].modelData || th[2] || "") : "",
                "thumbCount": th.length
            })
        }
    }
    Component.onCompleted: refresh()

    Connections {
        target: (typeof mainCanvas !== "undefined") ? mainCanvas : null
        function onProjectListChanged() { refresh() }
    }
}
