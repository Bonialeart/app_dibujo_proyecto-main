import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ══════════════════════════════════════════════════════════════
//  SIMPLE ANIMATION BAR  —  Flipbook-style floating timeline
//  Premium grid-based design with ruler and track labels
// ══════════════════════════════════════════════════════════════
Item {
    id: root

    // ── Public API ──────────────────────────────────────────
    property var    targetCanvas:   null
    property color  accentColor:    "#e84393"
    property int    projectFPS:     12
    property int    projectFrames:  48
    property bool   projectLoop:    true

    // Canvas background color
    property color  canvasBgColor: {
        if (targetCanvas && targetCanvas.layerModel && targetCanvas.layerModel.length > 0) {
            var bg = targetCanvas.layerModel[0]
            if (bg && bg.bgColor) return bg.bgColor
        }
        return "#ffffff"
    }

    // ── Real Frame Model ─────────────────────────────────────
    ListModel { id: _frameModel }
    property alias frameModel: _frameModel

    property int frameCount: _frameModel.count
    signal durationChanged()

    // ── Animation State ─────────────────────────────────────
    property int    currentFrameIdx: 0
    property int    fps:             projectFPS
    property bool   isPlaying:       false
    property bool   loopEnabled:     projectLoop
    property bool   onionEnabled:    false
    property bool   lightTable:      false
    property real   onionOpacity:    0.4
    property int    onionBefore:     2
    property int    onionAfter:      1

    // Grid config
    property real cellSize:   30        // each frame cell size (one slot)
    property real cellGap:    2         // gap between cells
    property real cellStep:   cellSize + cellGap
    property real trackLabelW: 72       // width of track label column
    property real rulerH:     18        // ruler height
    property int  visibleCols: Math.max(8, Math.floor((pill.width - trackLabelW - 40) / cellStep))

    // Derived
    property real currentTimeSec: currentFrameIdx / Math.max(1, fps)

    // ── Slot helpers (for duration/spanning) ──────────────────
    function getFrameDuration(fi) {
        if (fi < 0 || fi >= frameModel.count) return 1
        var item = frameModel.get(fi)
        return (item && item.duration !== undefined) ? item.duration : 1
    }
    function getSlotOffset(fi) {
        var off = 0
        for (var i = 0; i < fi && i < frameModel.count; i++)
            off += getFrameDuration(i)
        return off
    }
    function totalSlots() {
        var s = 0
        for (var i = 0; i < frameModel.count; i++)
            s += getFrameDuration(i)
        return s
    }
    function setFrameDuration(fi, dur) {
        if (fi < 0 || fi >= frameModel.count) return
        dur = Math.max(1, Math.min(12, dur))
        frameModel.setProperty(fi, "duration", dur)
        durationChanged()
    }

    // ── Playback Timer ───────────────────────────────────────
    Timer {
        id: playTimer
        interval: Math.round(1000 / Math.max(1, root.fps))
        repeat: true
        running: root.isPlaying && root.frameCount > 1

        property int tickCounter: 0

        onTriggered: {
            var currentItem = frameModel.get(root.currentFrameIdx)
            tickCounter++

            var dur = currentItem ? (currentItem.duration !== undefined ? currentItem.duration : 1) : 1
            if (tickCounter >= dur) {
                tickCounter = 0
                var next = root.currentFrameIdx + 1
                if (next >= root.frameCount) {
                    if (root.loopEnabled) next = 0
                    else { root.isPlaying = false; return }
                }
                root.goToFrame(next)
            }
        }
    }

    // ── Frame Navigation & Creation ─────────────────────────
    function findLayerIndexByName(name) {
        if (!targetCanvas || !targetCanvas.layerModel) return -1
        var model = targetCanvas.layerModel
        for (var i = 0; i < model.length; i++) {
            if (model[i].name === name) return model[i].layerId
        }
        return -1
    }

    function goToFrame(idx) {
        if (idx < 0 || idx >= frameCount) return
        currentFrameIdx = idx
        if (playTimer.running) playTimer.tickCounter = 0

        if (targetCanvas) {
            for (var i = 0; i < frameCount; i++) {
                var layerName = frameModel.get(i).layerName
                if (!layerName) continue

                var rIdx = findLayerIndexByName(layerName)
                if (rIdx < 0) continue

                var isCur = (i === currentFrameIdx)
                if (isCur) {
                    targetCanvas.setLayerVisibility(rIdx, true)
                    targetCanvas.setLayerOpacity(rIdx, 1.0)
                    targetCanvas.setActiveLayer(rIdx)
                } else if (onionEnabled) {
                    var d = i - currentFrameIdx
                    var show = (d < 0 && -d <= onionBefore) || (d > 0 && d <= onionAfter)
                    if (show) {
                        targetCanvas.setLayerVisibility(rIdx, true)
                        var ad = Math.abs(d)
                        var md = (d < 0) ? onionBefore : onionAfter
                        targetCanvas.setLayerOpacity(rIdx, Math.max(0.08, onionOpacity * (1.0 - (ad-1)/md)))
                    } else {
                        targetCanvas.setLayerVisibility(rIdx, false)
                    }
                } else {
                    targetCanvas.setLayerVisibility(rIdx, false)
                }
            }
        }
    }

    onOnionEnabledChanged: { goToFrame(currentFrameIdx) }
    onOnionBeforeChanged: { goToFrame(currentFrameIdx) }
    onOnionAfterChanged: { goToFrame(currentFrameIdx) }
    onOnionOpacityChanged: { goToFrame(currentFrameIdx) }

    function addFrame() {
        var newIdx = frameModel.count
        var nm = "AF_Simple_F" + (newIdx + 1)

        if (targetCanvas) {
            targetCanvas.addLayer()
            var ri = targetCanvas.activeLayerIndex
            targetCanvas.renameLayer(ri, nm)
        }

        frameModel.append({ thumbnail: "", layerName: nm, duration: 1 })
        goToFrame(newIdx)
    }

    function deleteCurrentFrame() {
        if (frameCount <= 1) return
        var fi = currentFrameIdx
        var layerName = frameModel.get(fi).layerName
        if (layerName && targetCanvas) {
            var rIdx = findLayerIndexByName(layerName)
            if (rIdx >= 0) targetCanvas.removeLayer(rIdx)
        }
        frameModel.remove(fi)
        if (currentFrameIdx >= frameCount) currentFrameIdx = frameCount - 1
        goToFrame(currentFrameIdx)
    }

    function duplicateCurrentFrame() {
        if (frameCount === 0) return
        var src = frameModel.get(currentFrameIdx)
        var newIdx = frameModel.count
        var nm = "AF_Simple_F" + (newIdx + 1)
        if (targetCanvas) {
            var srcRi = findLayerIndexByName(src.layerName)
            if (srcRi >= 0) {
                targetCanvas.duplicateLayer(srcRi)
                targetCanvas.renameLayer(targetCanvas.activeLayerIndex, nm)
            }
        }
        frameModel.insert(currentFrameIdx + 1, { thumbnail: "", layerName: nm, duration: src.duration || 1 })
        goToFrame(currentFrameIdx + 1)
    }

    // ── Entry Animation ──────────────────────────────────────
    property bool _ready: false
    Component.onCompleted: Qt.callLater(function() { root._ready = true })
    opacity: _ready ? 1.0 : 0.0
    y:      _ready ? 0   : 40
    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    Behavior on y       { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    // ════════════════════════════════════════════════════════
    //  FLOATING PANEL — Flipbook Style
    // ════════════════════════════════════════════════════════
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8

        width:  Math.min(960, Math.max(500, parent.width * 0.78))
        height: root.frameCount === 0 ? 52 : 136
        radius: 16
        color:  "#17171c"
        border.color: "#2a2a32"
        border.width: 1

        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Subtle top highlight
        Rectangle {
            width: parent.width * 0.5; height: 1
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.06) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // ── TOP CONTROL BAR ─────────────────────────────────
        RowLayout {
            id: topBar
            anchors.top: parent.top; anchors.topMargin: 10
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 14; anchors.rightMargin: 14
            height: 28; spacing: 6

            // ▶ Play button
            Rectangle {
                width: playRow.implicitWidth + 20; height: 26; radius: 13
                color: root.isPlaying
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                    : (playBtnMa.containsMouse ? "#252530" : "#1e1e24")
                border.color: root.isPlaying ? root.accentColor : "#333"
                border.width: root.isPlaying ? 1.5 : 1
                opacity: root.frameCount > 1 ? 1.0 : 0.4
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: playRow; anchors.centerIn: parent; spacing: 5
                    Text {
                        text: root.isPlaying ? "■" : "▶"
                        color: root.isPlaying ? root.accentColor : "#ccc"
                        font.pixelSize: root.isPlaying ? 10 : 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.isPlaying ? "Stop" : "Play"
                        color: root.isPlaying ? root.accentColor : "#aaa"
                        font.pixelSize: 11; font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: playBtnMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.frameCount > 1) root.isPlaying = !root.isPlaying
                }
            }

            // Frame counter pill
            Rectangle {
                width: fcText.implicitWidth + 18; height: 22; radius: 6
                color: "#0e0e12"; border.color: "#2a2a30"
                Text {
                    id: fcText; anchors.centerIn: parent
                    text: root.frameCount === 0 ? "—" : (root.currentFrameIdx + 1) + " / " + root.frameCount
                    color: "#777"; font.pixelSize: 10; font.family: "Monospace"; font.weight: Font.DemiBold
                }
            }

            // Time
            Text {
                text: {
                    if (root.frameCount === 0) return ""
                    var s = root.currentTimeSec; var sec = s.toFixed(1)
                    return sec + "s"
                }
                color: "#444"; font.pixelSize: 9; font.family: "Monospace"
                visible: root.frameCount > 0
            }

            Item { Layout.fillWidth: true }

            // ── RIGHT ICONS ─────────────────────────────────
            Row { spacing: 3
                // Loop
                IconBtn {
                    icon: "↻"; active: root.loopEnabled; activeCol: root.accentColor
                    tip: "Loop"; onToggled: root.loopEnabled = !root.loopEnabled
                }
                // Onion
                IconBtn {
                    icon: "◉"; active: root.onionEnabled; activeCol: "#f0d060"
                    tip: "Onion Skin"; visible: root.frameCount > 1
                    onToggled: root.onionEnabled = !root.onionEnabled
                }
                // Advanced mode
                IconBtn {
                    icon: "≡"; active: false; activeCol: "#6366f1"
                    tip: "Modo Avanzado"
                    onToggled: { if (typeof mainWindow !== "undefined") mainWindow.useAdvancedTimeline = true }
                }

                // Separator
                Rectangle { width: 1; height: 16; color: "#2a2a32"; anchors.verticalCenter: parent.verticalCenter }

                // + New Frame
                Rectangle {
                    width: root.frameCount === 0 ? (addTxt.implicitWidth + 22) : 26
                    height: 26; radius: 8
                    color: addMa.containsMouse ? Qt.lighter(root.accentColor, 1.1) : root.accentColor
                    scale: addMa.pressed ? 0.93 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Text {
                        id: addTxt; anchors.centerIn: parent
                        text: root.frameCount === 0 ? "+ Frame" : "+"
                        color: "white"; font.pixelSize: root.frameCount === 0 ? 11 : 14
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: addMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame()
                    }
                    ToolTip.visible: addMa.containsMouse; ToolTip.text: "Nuevo fotograma"
                    ToolTip.delay: 400
                }
            }
        }

        // ── EMPTY STATE ──────────────────────────────────────
        Text {
            visible: root.frameCount === 0
            anchors.bottom: parent.bottom; anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Pulsa  + Frame  para comenzar"
            color: "#333"; font.pixelSize: 10; font.italic: true
        }

        // ── TIMELINE GRID AREA (visible when frames > 0) ─────
        Item {
            id: gridArea
            visible: root.frameCount > 0
            anchors.top: topBar.bottom; anchors.topMargin: 6
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10; anchors.rightMargin: 10
            anchors.bottomMargin: 8
            clip: true

            // ── TRACK LABEL ──────────────────────────────────
            Rectangle {
                id: trackLabel
                width: root.trackLabelW; z: 5
                anchors.top: parent.top; anchors.topMargin: root.rulerH + 2
                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                radius: 8
                color: "#1e1e24"
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                border.width: 1.5

                Row {
                    anchors.centerIn: parent; spacing: 5
                    // Color dot
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Track 1"
                        color: "#ccc"; font.pixelSize: 10; font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── SCROLLABLE GRID ──────────────────────────────
            Flickable {
                id: gridFlick
                anchors.left: trackLabel.right; anchors.leftMargin: 4
                anchors.right: parent.right
                anchors.top: parent.top; anchors.bottom: parent.bottom
                contentWidth: Math.max(width, (root.totalSlots() + 2) * root.cellStep + 10)
                clip: true; boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                // Auto-scroll to current frame
                function scrollToCurrent() {
                    var slotX = root.getSlotOffset(root.currentFrameIdx) * root.cellStep
                    var targetX = slotX - (width / 2 - root.cellSize / 2)
                    contentX = Math.max(0, Math.min(targetX, Math.max(0, contentWidth - width)))
                }
                Connections {
                    target: root
                    function onCurrentFrameIdxChanged() { gridFlick.scrollToCurrent() }
                }

                Item {
                    width: gridFlick.contentWidth
                    height: gridFlick.height

                    // ── RULER ─────────────────────────────────
                    Item {
                        id: ruler
                        width: parent.width; height: root.rulerH

                        Repeater {
                            model: root.totalSlots() + 5
                            Item {
                                x: index * root.cellStep + root.cellStep / 2
                                width: 1; height: ruler.height
                                property int curSlot: root.getSlotOffset(root.currentFrameIdx)
                                property int curEnd: curSlot + root.getFrameDuration(root.currentFrameIdx) - 1
                                property bool inCurrent: index >= curSlot && index <= curEnd

                                // Tick mark
                                Rectangle {
                                    width: 1
                                    height: index < root.totalSlots() ? (parent.inCurrent ? 10 : 6) : 4
                                    color: index < root.totalSlots()
                                        ? (parent.inCurrent ? root.accentColor : "#444")
                                        : "#222"
                                    anchors.bottom: parent.bottom
                                }
                                // Number
                                Text {
                                    visible: index < root.totalSlots() && (index % 5 === 0 || index === 0 || root.totalSlots() <= 20)
                                    text: (index + 1)
                                    color: parent.inCurrent ? "#ddd" : "#555"
                                    font.pixelSize: 8; font.family: "Monospace"
                                    font.weight: parent.inCurrent ? Font.Bold : Font.Normal
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top; anchors.topMargin: 1
                                }
                            }
                        }

                        // Ruler scrub — maps slot to frame
                        MouseArea {
                            anchors.fill: parent; z: 2
                            cursorShape: Qt.PointingHandCursor
                            onPressed: function(m) { seekFromPx(m.x) }
                            onPositionChanged: function(m) { if (pressed) seekFromPx(m.x) }
                            function seekFromPx(px) {
                                var slot = Math.floor(px / root.cellStep)
                                // Find which frame this slot belongs to
                                var acc = 0
                                for (var i = 0; i < root.frameCount; i++) {
                                    var d = root.getFrameDuration(i)
                                    if (slot < acc + d) { root.goToFrame(i); return }
                                    acc += d
                                }
                                root.goToFrame(Math.max(0, root.frameCount - 1))
                            }
                        }

                        // Ruler bottom line
                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 1
                            color: "#2a2a32"
                        }
                    }

                    // ── FRAME CELLS ROW ───────────────────────
                    Item {
                        id: cellsRow
                        y: root.rulerH + 2
                        width: parent.width
                        height: parent.height - root.rulerH - 2

                        // Grid background lines (vertical)
                        Repeater {
                            model: root.totalSlots() + 5
                            Rectangle {
                                x: index * root.cellStep; width: 1; height: cellsRow.height
                                color: "#1a1a20"; opacity: 0.6
                            }
                        }

                        // Frame cells — each can span multiple slots
                        Repeater {
                            model: root.frameCount

                            Rectangle {
                                id: fCell
                                property int fi: index
                                property bool isCur: fi === root.currentFrameIdx
                                property bool isHov: cellMa.containsMouse
                                property int onionDist: fi - root.currentFrameIdx
                                property int dur: root.getFrameDuration(fi)
                                property int slotOff: root.getSlotOffset(fi)

                                // Visual drag tracking for live-resize
                                property real dragDelta: 0
                                property int visualDur: Math.max(1, Math.min(12,
                                    Math.round((dur * root.cellStep + dragDelta) / root.cellStep)))

                                x: slotOff * root.cellStep + 1
                                y: 1
                                width: dur * root.cellStep - root.cellGap
                                height: cellsRow.height - 2
                                radius: 4

                                Behavior on width {
                                    enabled: fCell.dragDelta === 0
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }

                                color: {
                                    if (isCur) return Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
                                    if (isHov) return "#1e1e26"
                                    return "#141418"
                                }
                                border.color: {
                                    if (isCur) return root.accentColor
                                    if (isHov) return "#3a3a44"
                                    return "#222228"
                                }
                                border.width: isCur ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 100 } }
                                Behavior on border.color { ColorAnimation { duration: 100 } }

                                // Onion overlay
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius; z: 1
                                    visible: root.onionEnabled && !fCell.isCur &&
                                        ((fCell.onionDist < 0 && -fCell.onionDist <= root.onionBefore) ||
                                         (fCell.onionDist > 0 &&  fCell.onionDist <= root.onionAfter))
                                    color: fCell.onionDist < 0
                                        ? Qt.rgba(1, 0.2, 0.3, 0.15)
                                        : Qt.rgba(0.2, 0.8, 0.3, 0.12)
                                }

                                // Thumbnail content
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: 2
                                    radius: 3; color: root.canvasBgColor; z: 0
                                    clip: true
                                    opacity: fCell.isCur ? 1.0 : 0.6

                                    Image {
                                        anchors.fill: parent; anchors.margins: 1
                                        fillMode: Image.PreserveAspectFit; cache: false
                                        source: {
                                            if (fi < root.frameModel.count) {
                                                var item = root.frameModel.get(fi)
                                                return item && item.thumbnail ? item.thumbnail : ""
                                            }
                                            return ""
                                        }
                                        visible: status === Image.Ready
                                    }

                                    // Frame number + duration indicator
                                    Text {
                                        anchors.centerIn: parent
                                        text: fCell.dur > 1 ? (fCell.fi + 1) + "×" + fCell.dur : (fCell.fi + 1)
                                        color: fCell.isCur ? "#ccc" : "#999"
                                        font.pixelSize: root.cellSize > 26 ? 9 : 7
                                        font.family: "Monospace"
                                        font.weight: fCell.isCur ? Font.Bold : Font.Normal
                                        opacity: 0.5
                                        z: 2
                                    }
                                }

                                // Slot division marks inside multi-slot frames
                                Repeater {
                                    model: fCell.dur > 1 ? fCell.dur - 1 : 0
                                    Rectangle {
                                        x: (index + 1) * root.cellStep - 1
                                        y: 4; width: 1; height: fCell.height - 8
                                        color: Qt.rgba(1,1,1,0.08)
                                    }
                                }

                                // Current frame top accent
                                Rectangle {
                                    visible: fCell.isCur
                                    anchors.top: parent.top; anchors.topMargin: -1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(parent.width - 4, 12); height: 2; radius: 1
                                    color: root.accentColor; z: 5
                                }

                                // ── EXTENDER HANDLE (right edge) ─────
                                Rectangle {
                                    id: extHandle
                                    width: 10; height: parent.height
                                    anchors.right: parent.right
                                    color: extMa.containsMouse || extMa.pressed
                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                                        : "transparent"
                                    radius: 2; z: 15
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    // Grip dots
                                    Column {
                                        anchors.centerIn: parent; spacing: 2
                                        Repeater {
                                            model: 3
                                            Rectangle {
                                                width: 2; height: 2; radius: 1
                                                color: extMa.containsMouse || extMa.pressed ? root.accentColor : "#444"
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: extMa; anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor; hoverEnabled: true
                                        preventStealing: true

                                        property real startX: 0

                                        onPressed: function(m) {
                                            startX = mapToItem(cellsRow, m.x, 0).x
                                            fCell.dragDelta = 0
                                            root.goToFrame(fCell.fi)
                                        }
                                        onPositionChanged: function(m) {
                                            if (!pressed) return
                                            var cur = mapToItem(cellsRow, m.x, 0).x
                                            fCell.dragDelta = cur - startX
                                        }
                                        onReleased: {
                                            var newDur = fCell.visualDur
                                            fCell.dragDelta = 0
                                            root.setFrameDuration(fCell.fi, newDur)
                                        }
                                    }
                                    ToolTip.visible: extMa.containsMouse && !extMa.pressed
                                    ToolTip.text: "⟷ Estirar duración"
                                    ToolTip.delay: 300
                                }

                                // Main click area
                                MouseArea {
                                    id: cellMa
                                    anchors.fill: parent; anchors.rightMargin: 12
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: function(m) {
                                        if (m.button === Qt.RightButton) {
                                            frameCtx.frameIdx = fCell.fi
                                            var globalPos = mapToItem(root, m.x, m.y)
                                            frameCtx.popup(globalPos.x, globalPos.y)
                                        } else {
                                            root.goToFrame(fCell.fi)
                                        }
                                    }
                                }
                            }
                        }

                        // "+" cell at end
                        Rectangle {
                            x: root.totalSlots() * root.cellStep + 1
                            y: 1; width: root.cellSize; height: cellsRow.height - 2
                            radius: 4
                            color: addCellMa2.containsMouse ? "#1a1a24" : "transparent"
                            border.color: addCellMa2.containsMouse ? "#333" : "#1e1e24"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent; text: "+"
                                color: addCellMa2.containsMouse ? "#888" : "#2a2a30"
                                font.pixelSize: 16; font.weight: Font.Light
                            }
                            MouseArea {
                                id: addCellMa2; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame()
                            }
                        }

                        // Click empty space = seek (slot-aware)
                        MouseArea {
                            anchors.fill: parent; z: -1
                            onPressed: function(m) { seekSlot(m.x) }
                            onPositionChanged: function(m) { if (pressed) seekSlot(m.x) }
                            function seekSlot(px) {
                                var slot = Math.floor(px / root.cellStep)
                                var acc = 0
                                for (var i = 0; i < root.frameCount; i++) {
                                    var d = root.getFrameDuration(i)
                                    if (slot < acc + d) { root.goToFrame(i); return }
                                    acc += d
                                }
                            }
                        }
                    }

                    // ── PLAYHEAD LINE ─────────────────────────
                    Rectangle {
                        visible: root.frameCount > 0
                        x: root.getSlotOffset(root.currentFrameIdx) * root.cellStep + root.cellStep / 2 - 1
                        y: 0; width: 2
                        height: parent.height
                        color: root.accentColor; z: 20; opacity: 0.6

                        Behavior on x {
                            enabled: !root.isPlaying
                            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                        }

                        // Top triangle
                        Rectangle {
                            width: 8; height: 8; rotation: 45; z: 21
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: -2; color: root.accentColor
                        }
                    }
                }
            }
        }
    }

    // ── ONION POPUP ──────────────────────────────────────────
    Rectangle {
        id: onionPopup
        visible: root.onionEnabled && root.frameCount > 1
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        anchors.bottom: pill.top; anchors.bottomMargin: 6
        anchors.horizontalCenter: pill.horizontalCenter
        width: 270; height: 36; radius: 18
        color: "#14141a"; border.color: "#f0d06055"; border.width: 1

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8

            Text { text: "◉"; font.pixelSize: 14; color: "#f0d060" }
            Text { text: "Antes"; color: "#cc4444"; font.pixelSize: 10; font.weight: Font.Medium }
            OSpinner { value: root.onionBefore; accentColor: "#cc4444"; onChanged: (v) => root.onionBefore = v }

            Rectangle { width: 1; height: 16; color: "#333" }

            Text { text: "Desp"; color: "#44cc66"; font.pixelSize: 10; font.weight: Font.Medium }
            OSpinner { value: root.onionAfter; accentColor: "#44cc66"; onChanged: (v) => root.onionAfter = v }

            Rectangle { width: 1; height: 16; color: "#333" }

            Text { text: "Op."; color: "#aaa"; font.pixelSize: 10 }
            Text {
                text: Math.round(root.onionOpacity * 100) + "%"
                color: "#f0d060"; font.pixelSize: 10; font.weight: Font.DemiBold
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                    property real sx; property real so
                    onPressed: (m) => { sx = m.x; so = root.onionOpacity }
                    onPositionChanged: (m) => { if (pressed) root.onionOpacity = Math.max(0.05, Math.min(1.0, so + (m.x - sx)*0.005)) }
                }
            }
        }
    }

    // ── PREMIUM CONTEXT MENU ────────────────────────────────────
    // Dismiss overlay - catches clicks outside the popup
    MouseArea {
        id: ctxDismissOverlay
        anchors.fill: parent; z: 9998
        visible: frameCtx.visible
        onClicked: frameCtx.dismiss()
    }

    // Custom popup with glassmorphism, hover states, and grouped actions
    Rectangle {
        id: frameCtx
        property int frameIdx: 0
        property real popX: 0
        property real popY: 0
        visible: false

        // Position near click point, clamped to viewport
        x: Math.min(popX, root.width - width - 12)
        y: Math.max(8, Math.min(popY - height - 4, root.height - height - 8))
        width: 220; radius: 14; z: 9999
        height: ctxCol.implicitHeight + 20
        color: "#1c1c24"
        border.color: Qt.rgba(1,1,1,0.10)
        border.width: 1

        // Shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -6
            z: -1; radius: parent.radius + 6
            color: "#000"; opacity: 0.45
        }

        // Top glass highlight
        Rectangle {
            width: parent.width * 0.6; height: 1; radius: 0.5
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.12) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // Open/close animation
        opacity: visible ? 1.0 : 0.0
        scale: visible ? 1.0 : 0.92
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        function popup(mx, my) {
            popX = mx; popY = my; visible = true
        }
        function dismiss() { visible = false }

        Column {
            id: ctxCol
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.topMargin: 10
            anchors.leftMargin: 6; anchors.rightMargin: 6
            spacing: 2

            // ── Header: Frame info ──
            Item {
                width: parent.width; height: 26
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10; spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: 6; height: 6; radius: 3; color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Frame " + (frameCtx.frameIdx + 1)
                        color: "#999"; font.pixelSize: 10; font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "·  " + root.getFrameDuration(frameCtx.frameIdx) + "f"
                        color: "#555"; font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Separator
            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // ── Actions ──
            CtxBtn {
                icon: "📋"; label: "Duplicar frame"; shortcut: ""
                iconColor: "#7aa2f7"
                onClicked: { root.goToFrame(frameCtx.frameIdx); root.duplicateCurrentFrame(); frameCtx.dismiss() }
            }
            CtxBtn {
                icon: "🧹"; label: "Limpiar contenido"; shortcut: ""
                iconColor: "#e0af68"
                onClicked: {
                    var item = root.frameModel.get(frameCtx.frameIdx)
                    if (item && item.layerName && root.targetCanvas) {
                        var ri = root.findLayerIndexByName(item.layerName)
                        if (ri >= 0) root.targetCanvas.clearLayer(ri)
                    }
                    frameCtx.dismiss()
                }
            }

            // Separator
            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // ── Duration controls ──
            Item {
                width: parent.width; height: 34
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10; spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "⟷"; font.pixelSize: 13; color: "#9ece6a"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Duración"; color: "#aaa"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                }

                // Stepper control
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter; spacing: 0

                    // Minus
                    Rectangle {
                        width: 26; height: 24; radius: 6
                        color: durMinMa.containsMouse ? "#2a2a36" : "#1e1e28"
                        border.color: durMinMa.containsMouse ? "#444" : "#2a2a32"

                        Text { text: "−"; anchors.centerIn: parent; color: "#aaa"; font.pixelSize: 14; font.weight: Font.Medium }
                        MouseArea {
                            id: durMinMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var cur = root.getFrameDuration(frameCtx.frameIdx)
                                root.setFrameDuration(frameCtx.frameIdx, cur - 1)
                            }
                        }
                    }

                    // Value display
                    Rectangle {
                        width: 32; height: 24; color: "#12121a"; radius: 0
                        border.color: "#2a2a32"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.getFrameDuration(frameCtx.frameIdx)
                            color: root.accentColor; font.pixelSize: 12
                            font.weight: Font.Bold; font.family: "Monospace"
                        }
                    }

                    // Plus
                    Rectangle {
                        width: 26; height: 24; radius: 6
                        color: durPlsMa.containsMouse ? "#2a2a36" : "#1e1e28"
                        border.color: durPlsMa.containsMouse ? "#444" : "#2a2a32"

                        Text { text: "+"; anchors.centerIn: parent; color: "#aaa"; font.pixelSize: 14; font.weight: Font.Medium }
                        MouseArea {
                            id: durPlsMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var cur = root.getFrameDuration(frameCtx.frameIdx)
                                root.setFrameDuration(frameCtx.frameIdx, cur + 1)
                            }
                        }
                    }
                }
            }

            // Separator
            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // ── Destructive ──
            CtxBtn {
                icon: "🗑"; label: "Eliminar frame"; shortcut: ""
                iconColor: "#f7768e"; labelColor: "#f7768e"
                hoverBg: "#2d1a1f"
                enabled: root.frameCount > 1
                onClicked: { root.goToFrame(frameCtx.frameIdx); root.deleteCurrentFrame(); frameCtx.dismiss() }
            }

            Item { width: 1; height: 4 }
        }
    }

    // ── Context menu button component ────────────────────────
    component CtxBtn : Rectangle {
        id: ctxb
        property string icon: ""
        property string label: ""
        property string shortcut: ""
        property color iconColor: "#888"
        property color labelColor: "#ddd"
        property color hoverBg: "#252530"
        signal clicked()

        width: parent ? parent.width : 200; height: 32; radius: 8
        color: ctxbMa.containsMouse ? hoverBg : "transparent"
        opacity: enabled ? 1.0 : 0.35
        Behavior on color { ColorAnimation { duration: 80 } }

        // Left accent bar on hover
        Rectangle {
            width: 3; height: parent.height - 8; radius: 1.5
            anchors.left: parent.left; anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            color: ctxb.iconColor
            opacity: ctxbMa.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        Row {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter; spacing: 10

            Text {
                text: ctxb.icon; font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 20
            }
            Text {
                text: ctxb.label; color: ctxb.labelColor
                font.pixelSize: 12; font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Shortcut hint (right side)
        Text {
            visible: ctxb.shortcut !== ""
            text: ctxb.shortcut; color: "#444"
            font.pixelSize: 9; font.family: "Monospace"
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            id: ctxbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (ctxb.enabled) ctxb.clicked()
        }
    }

    // ── INLINE COMPONENTS ────────────────────────────────────
    component IconBtn : Rectangle {
        id: ib
        property string icon: "?"
        property bool active: false
        property color activeCol: root.accentColor
        property string tip: ""
        signal toggled()

        width: 26; height: 26; radius: 7
        color: active
            ? Qt.rgba(activeCol.r, activeCol.g, activeCol.b, 0.15)
            : (ibMa.containsMouse ? "#252530" : "transparent")
        border.color: active ? Qt.rgba(activeCol.r, activeCol.g, activeCol.b, 0.5) : "transparent"
        border.width: active ? 1 : 0
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            text: ib.icon; anchors.centerIn: parent
            color: ib.active ? ib.activeCol : (ibMa.containsMouse ? "#bbb" : "#666")
            font.pixelSize: 13
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        MouseArea {
            id: ibMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor; onClicked: ib.toggled()
        }
        ToolTip.visible: ibMa.containsMouse && ib.tip !== ""
        ToolTip.text: ib.tip; ToolTip.delay: 400
    }

    component OSpinner : Row {
        id: osp
        property int   value: 2; property color accentColor: "#6366f1"
        signal changed(int v); spacing: 3
        Rectangle { width: 18; height: 18; radius: 4; color: mMa.containsMouse ? "#333" : "#222"
            Text { text: "−"; color: "#aaa"; font.pixelSize: 12; anchors.centerIn: parent }
            MouseArea { id: mMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (osp.value > 0) { osp.value--; osp.changed(osp.value) } } }
        Rectangle { width: 22; height: 18; radius: 4; color: "#151518"
            Text { text: osp.value; color: osp.accentColor; font.pixelSize: 11; font.bold: true; anchors.centerIn: parent } }
        Rectangle { width: 18; height: 18; radius: 4; color: pMa.containsMouse ? "#333" : "#222"
            Text { text: "+"; color: "#aaa"; font.pixelSize: 12; anchors.centerIn: parent }
            MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (osp.value < 8) { osp.value++; osp.changed(osp.value) } } }
    }
}
