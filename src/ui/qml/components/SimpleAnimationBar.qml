import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

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

    property var    copiedFrame:    null

    // ── Camera (optional) ───────────────────────────────────
    // If provided, the camera adds a virtual-camera keyframe track
    // above the frame strip and lets the user drive pan/zoom
    // per frame so the same scene can be shot from different
    // angles without re-animating.
    property var    camera:         null
    // Trigger to re-evaluate bindings that depend on the
    // camera's keyframe set from QML.
    property int    _camKeyVersion: 0

    // Emitted when the user clicks the "Edit Camera" button
    // (opens the camera properties popup).
    signal cameraEditRequested()

    function refreshCameraKeyMarker() { _camKeyVersion++ }

    // Maps a timeline slot (ruler position) to a frame index,
    // honouring per-frame durations.
    function slotToFrame(slot) {
        var acc = 0
        for (var i = 0; i < frameCount; i++) {
            var d = getFrameDuration(i)
            if (slot < acc + d) return i
            acc += d
        }
        return Math.max(0, frameCount - 1)
    }

    // Interpolation curves offered for camera keyframes
    readonly property var easingOptions: [
        { key: "linear",    label: "Lineal" },
        { key: "easeIn",    label: "Ease-In" },
        { key: "easeOut",   label: "Ease-Out" },
        { key: "easeInOut", label: "Ease-In-Out" },
        { key: "bezier",    label: "Bezier personalizada" }
    ]
    function easingLabel(key) {
        for (var i = 0; i < easingOptions.length; i++)
            if (easingOptions[i].key === key) return easingOptions[i].label
        return "Lineal"
    }

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

    // Derived — sum durations of all frames before current
    property real currentTimeSec: {
        if (!frameModel || frameModel.count === 0) return 0
        var slots = 0
        for (var i = 0; i < currentFrameIdx && i < frameModel.count; i++)
            slots += getFrameDuration(i)
        return slots / Math.max(1, fps)
    }

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
    property bool _advancingFromTimer: false   // guard to avoid tickCounter reset
    // Smooth playhead: tracks the exact slot position
    property real _playheadSlot: 0

    onIsPlayingChanged: {
        playTimer.tickCounter = 0
        _advancingFromTimer = false
        // Snap playhead to current frame start
        _playheadSlot = getSlotOffset(currentFrameIdx)
        // Sync camera with playback state
        if (root.camera) {
            root.camera.isPlaying = isPlaying
            if (isPlaying) root.camera.applyAtCurrent()
        }
    }

    Timer {
        id: playTimer
        interval: Math.round(1000 / Math.max(1, root.fps))
        repeat: true
        running: root.isPlaying && root.frameCount > 1

        property int tickCounter: 0

        onTriggered: {
            var fi = root.currentFrameIdx
            if (fi < 0 || fi >= root.frameModel.count) return
            var currentItem = root.frameModel.get(fi)
            var dur = (currentItem && currentItem.duration !== undefined) ? currentItem.duration : 1

            tickCounter++
            // Advance the playhead by one slot each tick
            root._playheadSlot = root.getSlotOffset(fi) + tickCounter

            if (tickCounter >= dur) {
                tickCounter = 0
                var next = fi + 1
                if (next >= root.frameCount) {
                    if (root.loopEnabled) {
                        next = 0
                        // Jump playhead back to start
                        root._playheadSlot = 0
                    }
                    else { root.isPlaying = false; return }
                }
                root._advancingFromTimer = true
                root.goToFrame(next)
                root._advancingFromTimer = false
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

    property bool isScrubbing: false

    // Whenever the current frame changes, push the new index into
    // the camera (if any) and re-evaluate the per-frame keyframe
    // indicator so the timeline diamond can be redrawn.
    onCurrentFrameIdxChanged: {
        if (camera) camera.currentFrameIdx = currentFrameIdx
        root.refreshCameraKeyMarker()
    }

    function goToFrame(idx, force) {
        if (idx < 0 || idx >= frameCount) return

        var isChanged = (currentFrameIdx !== idx) || force

        currentFrameIdx = idx
        // Only reset tickCounter for manual navigation, not when the timer advances
        if (playTimer.running && !_advancingFromTimer) playTimer.tickCounter = 0
        // Snap playhead for manual navigation
        if (!_advancingFromTimer) _playheadSlot = getSlotOffset(idx)

        if (!isChanged) return

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

    onOnionEnabledChanged: { goToFrame(currentFrameIdx, true) }
    onOnionBeforeChanged: { goToFrame(currentFrameIdx, true) }
    onOnionAfterChanged: { goToFrame(currentFrameIdx, true) }
    onOnionOpacityChanged: { goToFrame(currentFrameIdx, true) }

    // ── CAMERA: react to keyframe changes & playback state ───
    Connections {
        target: root.camera
        enabled: root.camera !== null
        function onKeyframesChanged() { root.refreshCameraKeyMarker() }
        function onKeyframeAdded(fi)   { root.refreshCameraKeyMarker() }
        function onKeyframeRemoved(fi) { root.refreshCameraKeyMarker() }
        function onKeyframeUpdated(fi) { root.refreshCameraKeyMarker() }
    }
    onIsScrubbingChanged: {
        if (root.camera) {
            root.camera.isScrubbing = isScrubbing
            if (isScrubbing) root.camera.applyAtCurrent()
        }
    }

    // ── CAMERA KEYFRAME CONTEXT MENU ─────────────────────────
    // Opened with right-click (desktop) or long-press (touch) on
    // a keyframe diamond: delete, duplicate and interpolation.
    Popup {
        id: camKfMenu
        property int frameIdx: -1
        width: 216
        padding: 6
        z: 10000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        function openFor(fi, px, py) {
            frameIdx = fi
            x = Math.max(6, Math.min(root.width - width - 6, px - width / 2))
            y = Math.max(6, py - implicitHeight - 12)
            open()
        }

        function kfEasing() {
            if (!root.camera) return "linear"
            var k = root.camera.getKeyframeAt(frameIdx)
            return (k && k.easing !== undefined) ? k.easing : "linear"
        }

        background: Rectangle {
            color: "#16161c"; radius: 12
            border.color: Qt.rgba(1, 1, 1, 0.09); border.width: 1
            Rectangle { anchors.fill: parent; anchors.margins: -5; z: -1
                radius: 16; color: "#000"; opacity: 0.45 }
        }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
        }

        contentItem: Column {
            spacing: 2

            // Header
            Row {
                spacing: 6
                leftPadding: 8
                topPadding: 2
                bottomPadding: 4
                Rectangle { width: 8; height: 8; rotation: 45; radius: 1.5
                    color: "#818cf8"; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Cámara · Frame " + (camKfMenu.frameIdx + 1)
                    color: "#a1a1aa"; font.pixelSize: 10; font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: parent.width - 10; height: 1
                color: Qt.rgba(1,1,1,0.07); anchors.horizontalCenter: parent.horizontalCenter }

            CamMenuBtn {
                iconSource: "image://icons/duplicate_outline"; label: "Duplicar keyframe"
                onTriggered: {
                    if (!root.camera) return
                    var dst = root.camera.duplicateKeyframe(camKfMenu.frameIdx)
                    if (dst >= 0)
                        root.camera.notify("Keyframe duplicado en frame " + (dst + 1), "success")
                    else
                        root.camera.notify("No hay un frame libre para duplicar", "warning")
                }
            }
            CamMenuBtn {
                iconSource: "image://icons/trash"; label: "Eliminar keyframe"; destructive: true
                onTriggered: {
                    if (!root.camera) return
                    root.camera.removeKeyframeAt(camKfMenu.frameIdx)
                    root.camera.notify("Keyframe eliminado", "info")
                }
            }

            Rectangle { width: parent.width - 10; height: 1
                color: Qt.rgba(1,1,1,0.07); anchors.horizontalCenter: parent.horizontalCenter }

            Text {
                text: "INTERPOLACIÓN"
                color: "#52525b"; font.pixelSize: 8; font.weight: Font.Bold
                font.letterSpacing: 1
                leftPadding: 8; topPadding: 4; bottomPadding: 2
            }

            Repeater {
                model: root.easingOptions
                CamMenuBtn {
                    required property var modelData
                    iconSource: camKfMenu.kfEasing() === modelData.key ? "image://icons/check" : ""
                    label: modelData.label
                    checked: camKfMenu.kfEasing() === modelData.key
                    closeOnTrigger: true
                    onTriggered: {
                        if (!root.camera) return
                        root.camera.setKeyframeEasing(camKfMenu.frameIdx, modelData.key)
                        root.camera.notify("Interpolación: " + modelData.label, "info")
                    }
                }
            }
        }
    }

    component CamMenuBtn : Rectangle {
        id: cmb
        property string icon: ""
        property string iconSource: ""
        property string label: ""
        property bool destructive: false
        property bool checked: false
        property bool closeOnTrigger: true
        signal triggered()
        width: parent ? parent.width : 200
        height: 28; radius: 7
        color: cmbMa.containsMouse
            ? (destructive ? "#2d1619" : "#222230")
            : (checked ? Qt.rgba(0.51, 0.55, 0.97, 0.10) : "transparent")
        Behavior on color { ColorAnimation { duration: 90 } }
        Row {
            anchors.left: parent.left; anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Text {
                visible: cmb.iconSource === ""
                text: cmb.icon; width: 14
                color: cmb.destructive ? "#f87171" : (cmb.checked ? "#818cf8" : "#9ca3af")
                font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
            }
            Image {
                visible: cmb.iconSource !== ""
                source: cmb.iconSource
                width: 11; height: 11
                anchors.verticalCenter: parent.verticalCenter
                smooth: true; mipmap: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: cmb.destructive ? "#f87171" : (cmb.checked ? "#818cf8" : "#9ca3af")
                    colorization: 1.0
                }
            }
            Text { text: cmb.label
                color: cmb.destructive ? "#f87171" : (cmb.checked ? "#c7d2fe" : "#d4d4d8")
                font.pixelSize: 11; font.weight: cmb.checked ? Font.DemiBold : Font.Medium
                anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea {
            id: cmbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { cmb.triggered(); if (cmb.closeOnTrigger) camKfMenu.close() }
        }
    }

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

    function copyFrame(fi) {
        if (fi < 0 || fi >= frameModel.count) return
        var src = frameModel.get(fi)
        copiedFrame = { layerName: src.layerName, duration: src.duration || 1 }
        if (targetCanvas) targetCanvas.notificationRequested("Fotograma copiado", "success")
    }

    function pasteFrame(fi) {
        if (!copiedFrame) return
        if (fi < 0 || fi >= frameModel.count) fi = frameModel.count - 1
        var newIdx = frameModel.count
        var nm = "AF_Simple_F" + (newIdx + 1) + "_Copia"
        if (targetCanvas) {
            var srcRi = findLayerIndexByName(copiedFrame.layerName)
            if (srcRi >= 0) {
                targetCanvas.duplicateLayer(srcRi)
                targetCanvas.renameLayer(targetCanvas.activeLayerIndex, nm)
            } else {
                targetCanvas.addLayer()
                targetCanvas.renameLayer(targetCanvas.activeLayerIndex, nm)
            }
        }
        frameModel.insert(fi + 1, { thumbnail: "", layerName: nm, duration: copiedFrame.duration || 1 })
        goToFrame(fi + 1)
        durationChanged()
        if (targetCanvas) targetCanvas.notificationRequested("Fotograma pegado", "success")
    }

    // ── Keyboard Shortcuts ───────────────────────────────────
    Shortcut {
        sequence: "Left"
        enabled: root.visible && root.frameCount > 0
        onActivated: root.goToFrame(Math.max(0, root.currentFrameIdx - 1))
    }
    Shortcut {
        sequence: ","
        enabled: root.visible && root.frameCount > 0
        onActivated: root.goToFrame(Math.max(0, root.currentFrameIdx - 1))
    }
    Shortcut {
        sequence: "Right"
        enabled: root.visible && root.frameCount > 0
        onActivated: root.goToFrame(Math.min(root.frameCount - 1, root.currentFrameIdx + 1))
    }
    Shortcut {
        sequence: "."
        enabled: root.visible && root.frameCount > 0
        onActivated: root.goToFrame(Math.min(root.frameCount - 1, root.currentFrameIdx + 1))
    }
    Shortcut {
        sequence: "Return"
        enabled: root.visible && root.frameCount > 1
        onActivated: root.isPlaying = !root.isPlaying
    }
    Shortcut {
        sequence: "Shift+Space"
        enabled: root.visible && root.frameCount > 1
        onActivated: root.isPlaying = !root.isPlaying
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
    // Premium Shadow Backplate for 3D depth
    Rectangle {
        anchors.fill: pill
        anchors.margins: -4
        radius: pill.radius + 4
        color: "#000000"
        opacity: 0.45
        z: pill.z - 1
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8

        width:  Math.min(960, Math.max(500, parent.width * 0.78))
        height: root.frameCount === 0 ? 52 : 136
        radius: 20
        color:  Qt.rgba(0.04, 0.04, 0.06, 0.94)  // Obsidian Slate Glass
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Subtle top highlight reflection
        Rectangle {
            width: parent.width * 0.5; height: 1
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.12) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // ── TOP CONTROL BAR ─────────────────────────────────
        RowLayout {
            id: topBar
            anchors.top: parent.top; anchors.topMargin: 10
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 16; anchors.rightMargin: 16
            height: 28; spacing: 8

            // ▶ Play button
            Rectangle {
                width: playRow.implicitWidth + 24; height: 26; radius: 13
                color: root.isPlaying
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                    : (playBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.02))
                border.color: root.isPlaying ? root.accentColor : Qt.rgba(1, 1, 1, 0.06)
                border.width: root.isPlaying ? 1.5 : 1
                opacity: root.frameCount > 1 ? 1.0 : 0.4
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                scale: playBtnMa.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }

                Row {
                    id: playRow; anchors.centerIn: parent; spacing: 6
                    Image {
                        source: root.isPlaying ? "image://icons/stop" : "image://icons/play"
                        width: 10; height: 10
                        anchors.verticalCenter: parent.verticalCenter
                        smooth: true; mipmap: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorizationColor: root.isPlaying ? root.accentColor : "#ffffff"
                            colorization: 1.0
                        }
                    }
                    Text {
                        text: root.isPlaying ? "Stop" : "Play"
                        color: root.isPlaying ? root.accentColor : "#e4e4e7"
                        font.pixelSize: 11; font.weight: Font.Medium
                        font.family: "System-UI, Segoe UI, sans-serif"
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
                width: fcText.implicitWidth + 18; height: 22; radius: 11
                color: Qt.rgba(1, 1, 1, 0.025); border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                Text {
                    id: fcText; anchors.centerIn: parent
                    text: root.frameCount === 0 ? "—" : (root.currentFrameIdx + 1) + " / " + root.frameCount
                    color: "#a1a1aa"; font.pixelSize: 10; font.family: "System-UI, Segoe UI, sans-serif"; font.weight: Font.DemiBold
                }
            }

            // Time
            Text {
                text: {
                    if (root.frameCount === 0) return ""
                    var s = root.currentTimeSec; var sec = s.toFixed(1)
                    return sec + "s"
                }
                color: "#61616a"; font.pixelSize: 9; font.family: "System-UI, Segoe UI, sans-serif"; font.weight: Font.Medium
                visible: root.frameCount > 0
            }

            // Interactive FPS Button
            Rectangle {
                visible: root.frameCount > 0
                width: fpsTxt.implicitWidth + 18; height: 22; radius: 11
                color: fpsMa.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.015)
                border.color: fpsPopup.visible ? root.accentColor : Qt.rgba(1, 1, 1, 0.05)
                border.width: fpsPopup.visible ? 1.2 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: fpsTxt
                    anchors.centerIn: parent
                    text: root.fps + " fps"
                    color: fpsPopup.visible ? root.accentColor : "#a1a1aa"
                    font.pixelSize: 9; font.weight: Font.DemiBold
                    font.family: "System-UI, Segoe UI, sans-serif"
                }
                MouseArea {
                    id: fpsMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fpsPopup.visible = !fpsPopup.visible
                }
            }

            Item { Layout.fillWidth: true }

            // ── RIGHT ICONS ─────────────────────────────────
            Row { spacing: 4
                // Loop
                IconBtn {
                    iconSource: "image://icons/repeat"; active: root.loopEnabled; activeCol: root.accentColor
                    tip: "Loop"; onToggled: root.loopEnabled = !root.loopEnabled
                }
                // Onion
                IconBtn {
                    iconSource: "image://icons/onion"; active: root.onionEnabled; activeCol: "#f0d060"
                    tip: "Onion Skin"; visible: root.frameCount > 1
                    onToggled: root.onionEnabled = !root.onionEnabled
                }
                // Camera mode (virtual camera with keyframes)
                IconBtn {
                    iconSource: "image://icons/camera-01"; active: root.camera && root.camera.active; activeCol: "#22d3ee"
                    tip: root.camera && root.camera.active
                        ? "Modo cámara activado (clic para desactivar)"
                        : "Modo cámara (keyframes de paneo/zoom)"
                    visible: root.camera !== null && root.frameCount > 0
                    onToggled: {
                        if (!root.camera) return
                        root.camera.active = !root.camera.active
                        root.camera.notify(
                            root.camera.active ? "Modo cámara activado" : "Modo cámara desactivado",
                            "info")
                    }
                }
                // Add / update camera keyframe at current frame
                Rectangle {
                    visible: root.camera !== null && root.frameCount > 0
                    width: kfAddTxt.implicitWidth + 18
                    height: 26; radius: 13
                    color: {
                        if (root.camera && root.camera.hasKeyframeAt(root.currentFrameIdx))
                            return "#0e7490"
                        if (root.camera && root.camera.active)
                            return "#22d3ee"
                        return Qt.rgba(1, 1, 1, 0.05)
                    }
                    border.color: root.camera && root.camera.hasKeyframeAt(root.currentFrameIdx)
                        ? "#67e8f9" : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    scale: kfAddMa.pressed ? 0.94 : (kfAddMa.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        id: kfAddTxt; anchors.centerIn: parent; spacing: 4
                        Text {
                            text: root.camera && root.camera.hasKeyframeAt(root.currentFrameIdx)
                                ? "◆" : "◇"
                            color: "#ffffff"; font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.camera && root.camera.hasKeyframeAt(root.currentFrameIdx)
                                ? "Actualizar Key" : "Añadir Key"
                            color: "#ffffff"; font.pixelSize: 10; font.weight: Font.DemiBold
                            font.family: "System-UI, Segoe UI, sans-serif"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: kfAddMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.camera) return
                            var had = root.camera.hasKeyframeAt(root.currentFrameIdx)
                            if (had) {
                                root.camera.updateKeyframe()
                                root.camera.notify("Keyframe actualizado", "success")
                            } else {
                                root.camera.addKeyframe()
                                root.camera.notify(
                                    "Keyframe añadido en frame " + (root.currentFrameIdx + 1),
                                    "success")
                            }
                        }
                    }
                    ToolTip.visible: kfAddMa.containsMouse
                    ToolTip.text: root.camera && root.camera.hasKeyframeAt(root.currentFrameIdx)
                        ? "Actualizar el keyframe del frame actual con la vista actual"
                        : "Capturar la vista actual (pan/zoom) como keyframe"
                    ToolTip.delay: 400
                }
                // Edit camera properties (opens numeric panel popup)
                IconBtn {
                    iconSource: "image://icons/edit-2"; active: false; activeCol: "#22d3ee"
                    tip: "Editar propiedades de la cámara (Pos / Zoom / Rotación)"
                    visible: root.camera !== null && root.camera.active
                    onToggled: root.cameraEditRequested()
                }
                // Advanced mode
                IconBtn {
                    iconSource: "image://icons/menu-01"; active: false; activeCol: "#6366f1"
                    tip: "Modo Avanzado"
                    onToggled: { if (typeof mainWindow !== "undefined") mainWindow.useAdvancedTimeline = true }
                }

                // Separator
                Rectangle { width: 1; height: 16; color: Qt.rgba(1, 1, 1, 0.06); anchors.verticalCenter: parent.verticalCenter }

                // + New Frame
                Rectangle {
                    width: root.frameCount === 0 ? (addTxt.implicitWidth + 24) : 26
                    height: 26; radius: 8
                    color: addMa.containsMouse ? Qt.lighter(root.accentColor, 1.05) : root.accentColor
                    scale: addMa.pressed ? 0.93 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Text {
                        id: addTxt; anchors.centerIn: parent
                        text: root.frameCount === 0 ? "+ Frame" : "+"
                        color: "white"; font.pixelSize: root.frameCount === 0 ? 11 : 14
                        font.weight: Font.Bold
                        font.family: "System-UI, Segoe UI, sans-serif"
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
            color: "#52525b"; font.pixelSize: 10; font.italic: true
            font.family: "System-UI, Segoe UI, sans-serif"
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
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.025)
                border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1

                Column {
                    anchors.centerIn: parent; spacing: 2
                    Text {
                        text: "Animación"
                        color: "#ffffff"; font.pixelSize: 10; font.weight: Font.Bold
                        font.family: "System-UI, Segoe UI, sans-serif"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: root.totalSlots() + "f"
                        color: "#a1a1aa"; font.pixelSize: 8; font.weight: Font.Medium
                        font.family: "System-UI, Segoe UI, sans-serif"
                        anchors.horizontalCenter: parent.horizontalCenter
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
                                        ? (parent.inCurrent ? root.accentColor : Qt.rgba(1, 1, 1, 0.09))
                                        : Qt.rgba(1, 1, 1, 0.02)
                                    anchors.bottom: parent.bottom
                                }
                                // Number
                                Text {
                                    visible: index < root.totalSlots() && (index % 5 === 0 || index === 0 || root.totalSlots() <= 20)
                                    text: (index + 1)
                                    color: parent.inCurrent ? "#ffffff" : "#61616a"
                                    font.pixelSize: 8; font.family: "System-UI, Segoe UI, sans-serif"
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
                            onPressed: function(m) { root.isScrubbing = true; seekFromPx(m.x) }
                            onPositionChanged: function(m) { if (pressed) seekFromPx(m.x) }
                            onReleased: { root.isScrubbing = false }
                            onCanceled: { root.isScrubbing = false }
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
                            color: Qt.rgba(1, 1, 1, 0.06)
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
                                color: Qt.rgba(1, 1, 1, 0.025)
                            }
                        }

                        // ── CAMERA KEYFRAME TRACK ──────────────────
                        // A thin row at the top of the cellsRow showing
                        // diamond markers for each camera keyframe, and
                        // letting the user click on empty space to add a
                        // keyframe at that slot. Visible whenever a
                        // camera has been provided to the bar.
                        Item {
                            id: camTrack
                            visible: root.camera !== null
                            width: parent.width
                            height: 14
                            z: 6

                            // Click on empty rail = add / update keyframe
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(m) {
                                    if (!root.camera) return
                                    var slot = Math.max(0, Math.floor(m.x / root.cellStep))
                                    // Convert slot → frame index
                                    var acc = 0
                                    var targetFrame = root.frameCount - 1
                                    for (var i = 0; i < root.frameCount; i++) {
                                        var d = root.getFrameDuration(i)
                                        if (slot < acc + d) { targetFrame = i; break }
                                        acc += d
                                    }
                                    if (m.button === Qt.RightButton) {
                                        if (root.camera.hasKeyframeAt(targetFrame)) {
                                            root.camera.removeKeyframeAt(targetFrame)
                                            root.camera.notify("Keyframe eliminado", "info")
                                        }
                                    } else {
                                        root.goToFrame(targetFrame)
                                        root.camera.addKeyframe()
                                        root.camera.notify(
                                            "Keyframe añadido en frame " + (targetFrame + 1),
                                            "success")
                                    }
                                }
                            }

                            // Soft accent rail so users see the track
                            Rectangle {
                                anchors.fill: parent
                                color: "#0c2230"
                                opacity: 0.55
                                radius: 4
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: parent.height / 2 - 0.5
                                width: parent.width - 8
                                height: 1
                                color: Qt.rgba(0.13, 0.83, 0.93, 0.45)
                            }

                            // Keyframe diamonds — selectable, draggable
                            // (move in time) with context menu on
                            // right-click or long-press (touch).
                            Repeater {
                                model: root.camera ? root.camera.keyframes : []
                                delegate: Item {
                                    id: kfItem
                                    property var kf: (root.camera && modelData)
                                        ? modelData
                                        : ({ frameIdx: 0, x: 0, y: 0, zoom: 1 })
                                    property bool isSelected: root.camera && root.camera.selectedFrameIdx === kf.frameIdx
                                    property bool isCurrent:  kf.frameIdx === root.currentFrameIdx
                                    property bool isDragging: maKf.pressed && maKf.moved
                                    property int  shownFrame: isDragging ? maKf.dragTargetFrame : kf.frameIdx
                                    property real slotX: root.getSlotOffset(shownFrame) * root.cellStep + root.cellStep / 2
                                    x: slotX - 9
                                    y: 0
                                    width: 18
                                    height: 14
                                    z: isDragging ? 10 : (isSelected ? 5 : 0)

                                    Behavior on x { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }

                                    // Selection halo
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 16; height: 16; rotation: 45
                                        radius: 3
                                        visible: kfItem.isSelected || kfItem.isDragging
                                        color: "transparent"
                                        border.color: "#818cf8"
                                        border.width: 1.5
                                        opacity: 0.9
                                    }

                                    // Diamond
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10; height: 10; rotation: 45
                                        radius: 1.5
                                        scale: kfItem.isDragging ? 1.25 : (maKf.containsMouse ? 1.12 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
                                        color: {
                                            if (kfItem.isSelected || kfItem.isDragging)
                                                return "#818cf8"
                                            if (kfItem.isCurrent)
                                                return "#ffffff"
                                            if (root.camera && root.camera.active)
                                                return "#22d3ee"
                                            return "#0e7490"
                                        }
                                        border.color: "#0b1220"
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        id: maKf
                                        anchors.fill: parent
                                        anchors.margins: -5   // generous touch target
                                        hoverEnabled: true
                                        cursorShape: kfItem.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        preventStealing: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                                        property real pressX: 0
                                        property bool moved: false
                                        property bool menuOpened: false
                                        property int  dragTargetFrame: kfItem.kf.frameIdx

                                        onPressed: function(m) {
                                            pressX = mapToItem(camTrack, m.x, m.y).x
                                            moved = false
                                            menuOpened = false
                                            dragTargetFrame = kfItem.kf.frameIdx
                                            if (root.camera) root.camera.selectedFrameIdx = kfItem.kf.frameIdx
                                        }
                                        onPositionChanged: function(m) {
                                            if (!pressed) return
                                            var gx = mapToItem(camTrack, m.x, m.y).x
                                            if (!moved && Math.abs(gx - pressX) < 5) return
                                            moved = true
                                            var slot = Math.max(0, Math.round(gx / root.cellStep - 0.5))
                                            dragTargetFrame = root.slotToFrame(slot)
                                        }
                                        onPressAndHold: function(m) {
                                            if (moved || menuOpened) return
                                            menuOpened = true
                                            var gp = mapToItem(root, m.x, m.y)
                                            camKfMenu.openFor(kfItem.kf.frameIdx, gp.x, gp.y)
                                        }
                                        onReleased: function(m) {
                                            if (menuOpened) return
                                            if (m.button === Qt.RightButton) {
                                                var gp = mapToItem(root, m.x, m.y)
                                                camKfMenu.openFor(kfItem.kf.frameIdx, gp.x, gp.y)
                                                return
                                            }
                                            if (moved) {
                                                if (dragTargetFrame !== kfItem.kf.frameIdx && root.camera) {
                                                    var from = kfItem.kf.frameIdx
                                                    if (root.camera.moveKeyframe(from, dragTargetFrame)) {
                                                        root.goToFrame(dragTargetFrame)
                                                        root.camera.notify(
                                                            "Keyframe movido a frame " + (dragTargetFrame + 1),
                                                            "success")
                                                    }
                                                }
                                            } else {
                                                root.goToFrame(kfItem.kf.frameIdx)
                                            }
                                        }
                                    }

                                    ToolTip.visible: maKf.containsMouse && !kfItem.isDragging
                                    ToolTip.text: "Frame " + (kf.frameIdx + 1)
                                        + "  •  X " + Math.round(kf.x)
                                        + "  Y " + Math.round(kf.y)
                                        + "  •  Z " + Math.round(kf.zoom * 100) + "%"
                                        + "  •  " + root.easingLabel(kf.easing !== undefined ? kf.easing : "linear")
                                    ToolTip.delay: 350
                                }
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
                                property bool isDragging: extMa.pressed
                                property int visualDur: Math.max(1, Math.min(12,
                                    Math.round((dur * root.cellStep + _smoothDelta) / root.cellStep)))

                                // Smoothed drag delta for premium feel
                                property real _smoothDelta: 0
                                Behavior on _smoothDelta {
                                    enabled: true
                                    NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
                                }
                                onDragDeltaChanged: _smoothDelta = dragDelta

                                // --- PHYSICAL TACTILE INTERACTION PROPERTIES ---
                                property real snapImpulse: 0

                                onVisualDurChanged: {
                                    if (isDragging) {
                                        // Visual bounce feedback at the snap boundary!
                                        snapBounceAnim.dragDirection = (visualDur > fCell.dur) ? 1 : -1
                                        snapBounceAnim.restart()
                                        handleBounce.restart()
                                    }
                                }

                                SequentialAnimation {
                                    id: snapBounceAnim
                                    property int dragDirection: 1
                                    NumberAnimation {
                                        target: fCell
                                        property: "snapImpulse"
                                        from: snapBounceAnim.dragDirection * 12
                                        to: 0
                                        duration: 160
                                        easing.type: Easing.OutBack
                                    }
                                }

                                // Live resize: while dragging, show the visual width (including the tactile snapImpulse!)
                                x: slotOff * root.cellStep + 1
                                y: 1
                                width: isDragging
                                    ? Math.max(root.cellStep - root.cellGap, dur * root.cellStep + _smoothDelta - root.cellGap + snapImpulse)
                                    : dur * root.cellStep - root.cellGap
                                height: cellsRow.height - 2
                                radius: 12

                                Behavior on width {
                                    enabled: !fCell.isDragging
                                    NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                                }

                                color: {
                                    if (isCur) return "#ffffff"  // High contrast white active card
                                    if (isHov) return Qt.rgba(1, 1, 1, 0.08)
                                    return Qt.rgba(1, 1, 1, 0.02)  // Obsidian Slate Glass inactive
                                }
                                border.color: {
                                    if (isCur) return "#e84393"  // Hot pink border
                                    if (isHov) return Qt.rgba(1, 1, 1, 0.15)
                                    return Qt.rgba(1, 1, 1, 0.06)
                                }
                                border.width: isCur ? 2.0 : 1.0

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                // Onion overlay
                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius; z: 1
                                    visible: root.onionEnabled && !fCell.isCur &&
                                        ((fCell.onionDist < 0 && -fCell.onionDist <= root.onionBefore) ||
                                         (fCell.onionDist > 0 &&  fCell.onionDist <= root.onionAfter))
                                    color: fCell.onionDist < 0
                                        ? Qt.rgba(1, 0.2, 0.3, 0.12)
                                        : Qt.rgba(0.2, 0.8, 0.3, 0.10)
                                }

                                // Thumbnail content
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: isCur ? 3 : 2
                                    radius: isCur ? 10 : 10
                                    color: root.canvasBgColor; z: 0
                                    clip: true
                                    opacity: fCell.isCur ? 1.0 : 0.65

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

                                    // Faint frame number placeholder
                                    Text {
                                        anchors.centerIn: parent
                                        text: (fCell.fi + 1)
                                        color: fCell.isCur ? "#888896" : "#61616a"
                                        font.pixelSize: 12
                                        font.family: "System-UI, Segoe UI, sans-serif"
                                        font.weight: fCell.isCur ? Font.Bold : Font.Normal
                                        opacity: 0.35
                                        z: 2
                                    }
                                }

                                // Slot division marks inside multi-slot frames
                                Repeater {
                                    model: fCell.dur > 1 ? fCell.dur - 1 : 0
                                    Rectangle {
                                        x: (index + 1) * root.cellStep - 1
                                        y: 4; width: 1; height: fCell.height - 8
                                        color: Qt.rgba(1,1,1,0.06)
                                    }
                                }

                                // Current frame top accent (Neon light indicator)
                                Rectangle {
                                    visible: fCell.isCur
                                    anchors.top: parent.top; anchors.topMargin: -1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(parent.width - 4, 14); height: 2; radius: 1
                                    color: "#e84393"; z: 5
                                }

                                // ── DURATION FLOATING PILL (e.g. x6 bubble) ──
                                Rectangle {
                                    id: durPill
                                    property bool showPill: fCell.dur > 1 || fCell.isDragging
                                    visible: showPill
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: -6  // float at bottom center
                                    z: 16

                                    width: durTxt.implicitWidth + 14; height: 16; radius: 8
                                    color: "#e84393"
                                    border.color: "#ffffff"
                                    border.width: 1

                                    // Shadow
                                    Rectangle {
                                        anchors.fill: parent; anchors.margins: -1
                                        radius: 9; color: "#000000"; opacity: 0.35; z: -1
                                    }

                                    Text {
                                        id: durTxt
                                        anchors.centerIn: parent
                                        text: "×" + (fCell.isDragging ? fCell.visualDur : fCell.dur)
                                        color: "#ffffff"
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        font.family: "System-UI, Segoe UI, sans-serif"
                                    }

                                    // Scale spring bounce on show/hide
                                    scale: showPill ? 1.0 : 0.0
                                    opacity: showPill ? 1.0 : 0.0
                                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                }

                                // ── EXTENDER HANDLE (right edge) ─────
                                Rectangle {
                                    id: extHandle
                                    width: 10; height: parent.height - 4
                                    anchors.right: parent.right
                                    anchors.rightMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "#e84393"  // Neon magenta/pink
                                    radius: 5; z: 15

                                    // Outer border highlight
                                    border.color: "#ffffff"
                                    border.width: 1

                                    // Glow shadow on hover/press
                                    Rectangle {
                                        anchors.fill: parent; anchors.margins: -3
                                        radius: parent.radius + 3
                                        color: "#e84393"
                                        opacity: extMa.pressed ? 0.35 : (extMa.containsMouse ? 0.15 : 0)
                                        z: -1
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }

                                    // Grip dots
                                    Column {
                                        anchors.centerIn: parent; spacing: 2
                                        Repeater {
                                            model: 3
                                            Rectangle {
                                                width: 2; height: 2; radius: 1
                                                color: "#ffffff"
                                            }
                                        }
                                    }

                                    // Dynamic scale animation on snap
                                    property real bounceScale: 1.0
                                    scale: bounceScale

                                    SequentialAnimation {
                                        id: handleBounce
                                        NumberAnimation { target: extHandle; property: "bounceScale"; to: 1.35; duration: 60; easing.type: Easing.OutQuad }
                                        NumberAnimation { target: extHandle; property: "bounceScale"; to: 1.0; duration: 180; easing.type: Easing.OutElastic }
                                    }

                                    MouseArea {
                                        id: extMa; anchors.fill: parent
                                        anchors.leftMargin: -8  // larger hit area
                                        anchors.rightMargin: -4
                                        cursorShape: Qt.SizeHorCursor; hoverEnabled: true
                                        preventStealing: true

                                        property real startX: 0

                                        onPressed: function(m) {
                                            startX = mapToItem(cellsRow, m.x, 0).x
                                            fCell.dragDelta = 0
                                            fCell._smoothDelta = 0
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
                                            fCell._smoothDelta = 0
                                            root.setFrameDuration(fCell.fi, newDur)
                                        }
                                    }
                                    ToolTip.visible: extMa.containsMouse && !extMa.pressed
                                    ToolTip.text: "⟷ Estirar duración"
                                    ToolTip.delay: 300
                                }

                                // Snap indicator — shows target slot lines while dragging
                                Rectangle {
                                    visible: fCell.isDragging && fCell.visualDur !== fCell.dur
                                    x: fCell.visualDur * root.cellStep - root.cellGap - 2
                                    y: 0; width: 2; height: parent.height
                                    radius: 1
                                    color: "#e84393"
                                    opacity: 0.75
                                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
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
                                            if (m.modifiers & Qt.AltModifier) {
                                                root.copyFrame(fCell.fi)
                                                root.pasteFrame(fCell.fi)
                                            } else {
                                                root.goToFrame(fCell.fi)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // "+" cell at end
                        Rectangle {
                            x: root.totalSlots() * root.cellStep + 1
                            y: 1; width: root.cellSize; height: cellsRow.height - 2
                            radius: 8
                            color: addCellMa2.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.02)
                            border.color: addCellMa2.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent; text: "+"
                                color: addCellMa2.containsMouse ? "#ffffff" : "#a1a1aa"
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
                            onPressed: function(m) { root.isScrubbing = true; seekSlot(m.x) }
                            onPositionChanged: function(m) { if (pressed) seekSlot(m.x) }
                            onReleased: { root.isScrubbing = false }
                            onCanceled: { root.isScrubbing = false }
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

                    // ── SCRUBBING GUIDELINE ───────────────────
                    Rectangle {
                        id: scrubbingGuideline
                        visible: root.isScrubbing
                        x: (root.getSlotOffset(root.currentFrameIdx) * root.cellStep)
                        width: root.getFrameDuration(root.currentFrameIdx) * root.cellStep - root.cellGap
                        y: 0
                        height: parent.height
                        color: Qt.rgba(0, 210, 255, 0.08)
                        border.color: "#00d2ff"
                        border.width: 1
                        z: 18
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    }

                    // ── PLAYHEAD LINE ─────────────────────────
                    Rectangle {
                        id: playheadLine
                        visible: root.frameCount > 0
                        // During playback use the smooth _playheadSlot; otherwise snap to frame start
                        x: (root.isPlaying
                            ? root._playheadSlot * root.cellStep + root.cellStep / 2 - 1
                            : root.getSlotOffset(root.currentFrameIdx) * root.cellStep + root.cellStep / 2 - 1) || 0
                        y: 0; width: 2
                        height: parent.height
                        color: "#00d2ff"; z: 20
                        opacity: root.isPlaying ? 0.95 : 0.70

                        Behavior on x {
                            NumberAnimation {
                                duration: root.isPlaying ? Math.round(900 / Math.max(1, root.fps)) : 120
                                easing.type: root.isPlaying ? Easing.Linear : Easing.OutCubic
                            }
                        }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        // Glow effect during playback or scrubbing
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 0; width: 6; height: parent.height
                            color: "#00d2ff"; opacity: 0.12; radius: 3
                            visible: root.isPlaying || root.isScrubbing
                        }

                        // Top circular playhead knob containing a mini white triangle play icon
                        Rectangle {
                            width: 16; height: 16; radius: 8; z: 21
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: -6
                            color: "#00d2ff"
                            border.color: "#ffffff"
                            border.width: 1.5

                            // Subtle drop shadow for playhead knob
                            Rectangle {
                                anchors.fill: parent; anchors.margins: -2
                                radius: 10; color: "#000000"; opacity: 0.35; z: -1
                            }

                            // Triangular play symbol inside
                            Text {
                                text: "▶"
                                color: "#ffffff"
                                font.pixelSize: 8
                                font.bold: true
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: 0.5
                            }

                            // Pulse during playback
                            scale: root.isPlaying ? 1.0 + Math.abs(Math.sin(_pulseTimer.t * 3.14)) * 0.12 : 1.0
                            Item {
                                id: _pulseTimer
                                property real t: 0
                                NumberAnimation on t {
                                    from: 0; to: 2; duration: 2000
                                    running: root.isPlaying; loops: Animation.Infinite
                                }
                            }
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
        anchors.left: pill.left; anchors.leftMargin: 12
        width: 270; height: 38; radius: 19
        color: Qt.rgba(0.06, 0.06, 0.09, 0.94)  // Slate glass
        border.color: Qt.rgba(0.94, 0.82, 0.38, 0.33); border.width: 1

        // Shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -4
            z: -1; radius: parent.radius + 4
            color: "#000000"; opacity: 0.4
        }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8

            Text { text: "◉"; font.pixelSize: 14; color: "#f0d060" }
            Text { text: "Antes"; color: "#ff6b81"; font.pixelSize: 10; font.weight: Font.Bold; font.family: "System-UI, Segoe UI, sans-serif" }
            OSpinner { value: root.onionBefore; accentColor: "#ff6b81"; onChanged: (v) => root.onionBefore = v }

            Rectangle { width: 1; height: 16; color: Qt.rgba(1, 1, 1, 0.06) }

            Text { text: "Desp"; color: "#2ed573"; font.pixelSize: 10; font.weight: Font.Bold; font.family: "System-UI, Segoe UI, sans-serif" }
            OSpinner { value: root.onionAfter; accentColor: "#2ed573"; onChanged: (v) => root.onionAfter = v }

            Rectangle { width: 1; height: 16; color: Qt.rgba(1, 1, 1, 0.06) }

            Text { text: "Op."; color: "#a1a1aa"; font.pixelSize: 10; font.family: "System-UI, Segoe UI, sans-serif" }
            Text {
                text: Math.round(root.onionOpacity * 100) + "%"
                color: "#f0d060"; font.pixelSize: 10; font.weight: Font.Black; font.family: "System-UI, Segoe UI, sans-serif"
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                    property real sx; property real so
                    onPressed: (m) => { sx = m.x; so = root.onionOpacity }
                    onPositionChanged: (m) => { if (pressed) root.onionOpacity = Math.max(0.05, Math.min(1.0, so + (m.x - sx)*0.005)) }
                }
            }
        }
    }

    // ── FPS POPUP ──────────────────────────────────────────
    Rectangle {
        id: fpsPopup
        visible: false
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        anchors.bottom: pill.top; anchors.bottomMargin: 6
        anchors.right: pill.right; anchors.rightMargin: 12
        width: 320; height: 48; radius: 24
        color: Qt.rgba(0.06, 0.06, 0.09, 0.94)  // Slate glass
        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4); border.width: 1.5
        z: 9999

        // Shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -4
            z: -1; radius: parent.radius + 4
            color: "#000000"; opacity: 0.45
        }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10

            Text {
                text: "⚡"
                font.pixelSize: 13
                color: root.accentColor
                Layout.alignment: Qt.AlignVCenter
            }

            // Slider container
            Item {
                Layout.fillWidth: true
                height: 24
                Layout.alignment: Qt.AlignVCenter

                // Slider Track
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.06)

                    // Highlighted Track
                    Rectangle {
                        height: parent.height
                        width: Math.max(0, Math.min(parent.width, (root.fps - 1) / 59 * parent.width))
                        radius: 2
                        color: root.accentColor
                    }
                }

                // Handle
                Rectangle {
                    x: Math.max(0, Math.min(parent.width - 12, (root.fps - 1) / 59 * (parent.width - 12)))
                    y: (parent.height - 12) / 2
                    width: 12; height: 12; radius: 6
                    color: "#ffffff"
                    border.color: root.accentColor
                    border.width: 2

                    // Outer shadow glow
                    Rectangle {
                        anchors.fill: parent; anchors.margins: -4
                        radius: 10; color: root.accentColor; opacity: sliderMa.containsMouse ? 0.25 : 0
                        z: -1
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: sliderMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    function updateFPS(mx) {
                        var pct = Math.max(0.0, Math.min(1.0, mx / width))
                        var val = Math.round(1 + pct * 59)
                        root.fps = val
                    }
                    onPressed: (m) => updateFPS(m.x)
                    onPositionChanged: (m) => { if (pressed) updateFPS(m.x) }
                }
            }

            // Presets
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: [8, 12, 24, 30]
                    Rectangle {
                        width: 24; height: 20; radius: 4
                        color: root.fps === modelData
                            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                            : (presetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.02))
                        border.color: root.fps === modelData ? root.accentColor : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.fps === modelData ? root.accentColor : "#a1a1aa"
                            font.pixelSize: 9; font.weight: Font.Bold
                            font.family: "System-UI, Segoe UI, sans-serif"
                        }

                        MouseArea {
                            id: presetMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fps = modelData
                        }
                    }
                }
            }
        }
    }

    // ── PREMIUM CONTEXT MENU ────────────────────────────────────
    // Dismiss overlay - catches clicks outside the popup
    MouseArea {
        id: ctxDismissOverlay
        anchors.fill: parent; z: 9998
        visible: frameCtx.visible || fpsPopup.visible
        onClicked: {
            frameCtx.dismiss()
            fpsPopup.visible = false
        }
    }

    // Custom popup with glassmorphism, hover states, and grouped actions
    Rectangle {
        id: frameCtx
        property int frameIdx: 0
        property real popX: 0
        property real popY: 0
        visible: false

        // Position near click point, clamped to viewport horizontally
        x: Math.min(popX, root.width - width - 12)
        y: Math.min(popY - height - 4, root.height - height - 8)
        width: 220; radius: 16; z: 9999
        height: ctxCol.implicitHeight + 20
        color: Qt.rgba(0.05, 0.05, 0.07, 0.94)  // Slate glass
        border.color: Qt.rgba(1, 1, 1, 0.07)
        border.width: 1

        // Shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -6
            z: -1; radius: parent.radius + 6
            color: "#000000"; opacity: 0.45
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
                        text: "Fotograma " + (frameCtx.frameIdx + 1)
                        color: "#ffffff"; font.pixelSize: 10; font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        font.family: "System-UI, Segoe UI, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "·  " + root.getFrameDuration(frameCtx.frameIdx) + "f"
                        color: "#a1a1aa"; font.pixelSize: 10
                        font.family: "System-UI, Segoe UI, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Separator
            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1, 1, 1, 0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // ── Actions ──
            CtxBtn {
                iconSource: "image://icons/copy"; label: "Copiar fotograma"; shortcut: ""
                iconColor: "#9ece6a"
                onClicked: { root.copyFrame(frameCtx.frameIdx); frameCtx.dismiss() }
            }
            CtxBtn {
                iconSource: "image://icons/clipboard"; label: "Pegar fotograma"; shortcut: ""
                iconColor: "#bb9af7"
                visible: root.copiedFrame !== null
                onClicked: { root.pasteFrame(frameCtx.frameIdx); frameCtx.dismiss() }
            }
            CtxBtn {
                iconSource: "image://icons/duplicate_outline"; label: "Duplicar frame"; shortcut: ""
                iconColor: "#7aa2f7"
                onClicked: { root.goToFrame(frameCtx.frameIdx); root.duplicateCurrentFrame(); frameCtx.dismiss() }
            }
            CtxBtn {
                iconSource: "image://icons/eraser"; label: "Limpiar contenido"; shortcut: ""
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
            CtxBtn {
                iconSource: "image://icons/trash"; label: "Borrar frame"; shortcut: ""
                iconColor: "#f7768e"
                onClicked: { root.goToFrame(frameCtx.frameIdx); root.deleteCurrentFrame(); frameCtx.dismiss() }
            }

            // Separator
            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1, 1, 1, 0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // ── Duration controls ──
            Item {
                width: parent.width; height: 34
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10; spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "⟷"; font.pixelSize: 13; color: "#9ece6a"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Duración"; color: "#d4d4d8"; font.pixelSize: 11; font.family: "System-UI, Segoe UI, sans-serif"; anchors.verticalCenter: parent.verticalCenter }
                }

                // Stepper control
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter; spacing: 0

                    // Minus
                    Rectangle {
                        width: 26; height: 24; radius: 6
                        color: durMinMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.02)
                        border.color: durMinMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1

                        Text { text: "−"; anchors.centerIn: parent; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.Medium }
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
                        width: 32; height: 24; color: Qt.rgba(1, 1, 1, 0.015); radius: 0
                        border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.getFrameDuration(frameCtx.frameIdx)
                            color: root.accentColor; font.pixelSize: 12
                            font.weight: Font.Bold; font.family: "System-UI, Segoe UI, sans-serif"
                        }
                    }

                    // Plus
                    Rectangle {
                        width: 26; height: 24; radius: 6
                        color: durPlsMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.02)
                        border.color: durPlsMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1

                        Text { text: "+"; anchors.centerIn: parent; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.Medium }
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
            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1, 1, 1, 0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // ── Destructive ──
            CtxBtn {
                icon: "🗑"; label: "Eliminar frame"; shortcut: ""
                iconColor: "#ff6b81"; labelColor: "#ff6b81"
                hoverBg: Qt.rgba(1, 0.1, 0.2, 0.1)
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
        property string iconSource: ""
        property string label: ""
        property string shortcut: ""
        property color iconColor: "#888"
        property color labelColor: "#e4e4e7"
        property color hoverBg: Qt.rgba(1, 1, 1, 0.05)
        signal clicked()

        width: parent ? parent.width : 200; height: 32; radius: 8
        color: ctxbMa.containsMouse ? hoverBg : "transparent"
        opacity: enabled ? 1.0 : 0.35
        Behavior on color { ColorAnimation { duration: 80 } }

        // Left accent bar on hover
        Rectangle {
            width: 3; height: parent.height - 12; radius: 1.5
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
                visible: ctxb.iconSource === ""
                text: ctxb.icon; font.pixelSize: 14
                color: ctxb.iconColor
                anchors.verticalCenter: parent.verticalCenter
                width: 20
            }
            Image {
                visible: ctxb.iconSource !== ""
                source: ctxb.iconSource
                width: 14; height: 14
                anchors.verticalCenter: parent.verticalCenter
                smooth: true; mipmap: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: ctxb.iconColor
                    colorization: 1.0
                }
            }
            Text {
                text: ctxb.label; color: ctxb.labelColor
                font.pixelSize: 12; font.weight: Font.Medium
                font.family: "System-UI, Segoe UI, sans-serif"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Shortcut hint (right side)
        Text {
            visible: ctxb.shortcut !== ""
            text: ctxb.shortcut; color: "#52525b"
            font.pixelSize: 9; font.family: "System-UI, Segoe UI, sans-serif"
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
        property string iconSource: ""
        property bool active: false
        property color activeCol: root.accentColor
        property string tip: ""
        signal toggled()

        width: 26; height: 26; radius: 7
        color: active
            ? Qt.rgba(activeCol.r, activeCol.g, activeCol.b, 0.15)
            : (ibMa.containsMouse ? "#ffffff0c" : "transparent")
        border.color: active ? Qt.rgba(activeCol.r, activeCol.g, activeCol.b, 0.4) : "transparent"
        border.width: active ? 1 : 0
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            visible: ib.iconSource === ""
            text: ib.icon; anchors.centerIn: parent
            color: ib.active ? ib.activeCol : (ibMa.containsMouse ? "#ffffff" : "#a1a1aa")
            font.pixelSize: 13
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        Image {
            visible: ib.iconSource !== ""
            source: ib.iconSource
            width: 14; height: 14; anchors.centerIn: parent
            smooth: true; mipmap: true
            opacity: ibMa.containsMouse ? 1.0 : 0.8
            layer.enabled: true
            layer.effect: MultiEffect {
                colorizationColor: ib.active ? ib.activeCol : (ibMa.containsMouse ? "#ffffff" : "#a1a1aa")
                colorization: 1.0
            }
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
        Rectangle { width: 18; height: 18; radius: 4; color: mMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.02)
            Text { text: "−"; color: "#a1a1aa"; font.pixelSize: 12; anchors.centerIn: parent }
            MouseArea { id: mMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (osp.value > 0) { osp.value--; osp.changed(osp.value) } } }
        Rectangle { width: 22; height: 18; radius: 4; color: Qt.rgba(1, 1, 1, 0.015)
            Text { text: osp.value; color: osp.accentColor; font.pixelSize: 11; font.bold: true; anchors.centerIn: parent } }
        Rectangle { width: 18; height: 18; radius: 4; color: pMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.02)
            Text { text: "+"; color: "#a1a1aa"; font.pixelSize: 12; anchors.centerIn: parent }
            MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (osp.value < 8) { osp.value++; osp.changed(osp.value) } } }
    }
}
