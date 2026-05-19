import QtQuick
import QtQuick.Controls
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root

    property var targetCanvas: null
    property string accentColor: "#10b981"
    property int projectFPS: 12
    property int projectFrames: 48
    property bool projectLoop: true

    // Canvas background color for frame thumbnails
    property color canvasBgColor: {
        if (targetCanvas && targetCanvas.layerModel && targetCanvas.layerModel.length > 0) {
            var bg = targetCanvas.layerModel[0]
            if (bg && bg.bgColor) return bg.bgColor
        }
        return "#ffffff"
    }

    ListModel { id: _trackModel }
    property alias trackModel: _trackModel

    property int  currentFrameIdx:  0
    property int  activeTrackIdx:   0
    property var  copiedFrameInfo:  null
    property int  totalFrames:      0
    property int  fps:              projectFPS
    property bool isPlaying:        false
    property bool loopEnabled:      true
    property bool onionEnabled:     false
    property real onionOpacity:     0.35
    property int  onionBefore:      2
    property int  onionAfter:       1
    property real pixelsPerFrame:   36
    property real trackLabelWidth:  90
    property real trackHeight:      56

    property real currentTimeSec: currentFrameIdx / Math.max(1, fps)
    property real totalTimelineWidth: Math.max(800, totalFrames * pixelsPerFrame + 300)

    onActiveTrackIdxChanged: {
        syncVisibility()
    }
    onCurrentFrameIdxChanged: {
        syncVisibility()
    }

    property int _frameCounter: 0
    property int _trackCounter: 0
    property bool _ready: false

    // ═══════════════════════════════════════════════════════
    //  REACTIVE FRAME STORAGE
    // ═══════════════════════════════════════════════════════
    property var _trackFrames: []
    property int _version: 0

    function _changed() {
        var tmp = _trackFrames
        _trackFrames = []
        _trackFrames = tmp
        _version++
        recalcTotalFrames()
        syncLayerStackOrder()
        syncVisibility()
    }

    function syncLayerStackOrder() {
        if (!targetCanvas || !targetCanvas.layerModel) return

        var model = targetCanvas.layerModel
        var count = model.length
        if (count <= 1) return

        // 1. Find the background layer name
        var bgName = ""
        for (var i = 0; i < count; i++) {
            if (model[i].type === "background" || model[i].layerId === 0) {
                bgName = model[i].name
                break
            }
        }

        // 2. Build target layer list where top timeline tracks have HIGHEST C++ manager indices
        var desiredOrder = []
        if (bgName !== "") {
            desiredOrder.push(bgName)
        }

        // Add track frames from bottom track up to top track
        for (var t = _trackFrames.length - 1; t >= 0; t--) {
            var frames = _trackFrames[t]
            for (var f = 0; f < frames.length; f++) {
                var name = frames[f].layerName
                if (name !== bgName && findLayerIndexByName(name) >= 0) {
                    desiredOrder.push(name)
                }
            }
        }

        // Add any orphaned/sketch layers just above background
        for (var i = 0; i < count; i++) {
            var name = model[i].name
            if (name !== bgName && desiredOrder.indexOf(name) === -1) {
                if (bgName !== "") {
                    desiredOrder.splice(1, 0, name)
                } else {
                    desiredOrder.splice(0, 0, name)
                }
            }
        }

        // 3. Move layers to align with target order
        for (var targetIdx = 0; targetIdx < desiredOrder.length; targetIdx++) {
            var layerName = desiredOrder[targetIdx]
            var currentIdx = findLayerIndexByName(layerName)
            if (currentIdx >= 0 && currentIdx !== targetIdx) {
                targetCanvas.moveLayer(currentIdx, targetIdx)
            }
        }
    }

    function splitFrameAtPlayhead() {
        var ti = root.activeTrackIdx
        if (ti < 0 || ti >= _trackFrames.length) return
        var slot = root.currentFrameIdx
        var fi = findFrameAtSlot(ti, slot)
        if (fi < 0) return

        var frames = _trackFrames[ti]
        var startSlot = 0
        for (var i = 0; i < fi; i++) {
            startSlot += (frames[i].span || 1)
        }

        var currentSpan = frames[fi].span || 1
        if (currentSpan <= 1) {
            if (targetCanvas) targetCanvas.notificationRequested("El frame es demasiado corto para dividir", "warning")
            return
        }

        var leftSpan = slot - startSlot + 1
        var rightSpan = currentSpan - leftSpan
        if (leftSpan <= 0 || rightSpan <= 0) return

        _frameCounter++
        var td = trackModel.get(ti)
        var newNm = "AF_" + td.trackName.replace(/[^a-zA-Z0-9]/g,"") + "_F" + _frameCounter

        var srcRi = findLayerIndexByName(frames[fi].layerName)
        if (srcRi >= 0) {
            targetCanvas.duplicateLayer(srcRi)
            targetCanvas.renameLayer(targetCanvas.activeLayerIndex, newNm)
        }

        frames[fi].span = leftSpan

        frames.splice(fi + 1, 0, { layerName: newNm, label: "F" + (fi + 2), span: rightSpan })
        for (var i = 0; i < frames.length; i++) frames[i].label = "F" + (i+1)

        _changed()
        if (targetCanvas) targetCanvas.notificationRequested("Frame dividido exitosamente", "success")
    }

    function getFrames(trackIdx) {
        var v = _version
        if (trackIdx < 0 || trackIdx >= _trackFrames.length) return []
        return _trackFrames[trackIdx]
    }

    function getFrameCount(trackIdx) {
        var v = _version
        if (trackIdx < 0 || trackIdx >= _trackFrames.length) return 0
        return _trackFrames[trackIdx].length
    }

    // ── SPAN HELPERS ─────────────────────────────────────────
    // Returns the pixel x-offset for frame at index fi in track ti
    function getFrameXOffset(ti, fi) {
        var v = _version
        if (ti < 0 || ti >= _trackFrames.length) return 0
        var frames = _trackFrames[ti]
        var px = 0
        for (var i = 0; i < fi && i < frames.length; i++) {
            px += (frames[i].span || 1) * pixelsPerFrame
        }
        return px
    }

    // Returns how many "timeline slots" a frame occupies
    function getFrameSpan(ti, fi) {
        var v = _version
        if (ti < 0 || ti >= _trackFrames.length) return 1
        var frames = _trackFrames[ti]
        if (fi < 0 || fi >= frames.length) return 1
        return frames[fi].span || 1
    }

    // Sets the span of a frame (minimum 1)
    function setFrameSpan(ti, fi, newSpan) {
        if (ti < 0 || ti >= _trackFrames.length) return
        var frames = _trackFrames[ti]
        if (fi < 0 || fi >= frames.length) return
        frames[fi].span = Math.max(1, newSpan)
        _changed()
    }

    // Given a timeline slot index, find which frame (fi) covers it in track ti
    function findFrameAtSlot(ti, slot) {
        var v = _version
        if (ti < 0 || ti >= _trackFrames.length) return -1
        var frames = _trackFrames[ti]
        var pos = 0
        for (var i = 0; i < frames.length; i++) {
            var sp = frames[i].span || 1
            if (slot >= pos && slot < pos + sp) return i
            pos += sp
        }
        return -1
    }

    // Total slots used by a track (sum of all spans)
    function totalSlotsForTrack(ti) {
        var v = _version
        if (ti < 0 || ti >= _trackFrames.length) return 0
        var frames = _trackFrames[ti]
        var total = 0
        for (var i = 0; i < frames.length; i++)
            total += (frames[i].span || 1)
        return total
    }

    // ═══════════════════════════════════════════════════════
    //  HELPERS
    // ═══════════════════════════════════════════════════════
    function findLayerIndexByName(name) {
        if (!targetCanvas || !targetCanvas.layerModel) return -1
        var model = targetCanvas.layerModel
        for (var i = 0; i < model.length; i++) {
            if (model[i].name === name) return model[i].layerId
        }
        return -1
    }

    function getFrameThumbnail(trackIdx, frameIdx) {
        var v = _version
        if (!targetCanvas || !targetCanvas.layerModel) return ""
        if (trackIdx < 0 || trackIdx >= _trackFrames.length) return ""
        var frames = _trackFrames[trackIdx]
        if (frameIdx < 0 || frameIdx >= frames.length) return ""
        var layerName = frames[frameIdx].layerName
        var model = targetCanvas.layerModel
        for (var i = 0; i < model.length; i++) {
            if (model[i].name === layerName) return model[i].thumbnail || ""
        }
        return ""
    }

    function formatTimecode(sec) {
        var m = Math.floor(sec / 60), s = Math.floor(sec % 60)
        var ms = Math.round((sec - Math.floor(sec)) * 1000)
        return (m<10?"0":"")+m + ":" + (s<10?"0":"")+s + "." + (ms<10?"00":(ms<100?"0":""))+ms
    }

    // ═══════════════════════════════════════════════════════
    //  INIT
    // ═══════════════════════════════════════════════════════
    Component.onCompleted: {
        _trackCounter++
        trackModel.append({ trackName: "Animación", trackIcon: "🎨", trackColor: "#ff3366" })
        _trackFrames.push([])
        _changed()
        Qt.callLater(function() { root._ready = true })
    }
    opacity: _ready ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // ── Keyboard Shortcuts ───────────────────────────────────
    Shortcut {
        sequence: "Left"
        enabled: root.visible && root.totalFrames > 0
        onActivated: root.goToFrame(Math.max(0, root.currentFrameIdx - 1))
    }
    Shortcut {
        sequence: ","
        enabled: root.visible && root.totalFrames > 0
        onActivated: root.goToFrame(Math.max(0, root.currentFrameIdx - 1))
    }
    Shortcut {
        sequence: "Right"
        enabled: root.visible && root.totalFrames > 0
        onActivated: root.goToFrame(Math.min(root.totalFrames - 1, root.currentFrameIdx + 1))
    }
    Shortcut {
        sequence: "."
        enabled: root.visible && root.totalFrames > 0
        onActivated: root.goToFrame(Math.min(root.totalFrames - 1, root.currentFrameIdx + 1))
    }
    Shortcut {
        sequence: "Return"
        enabled: root.visible && root.totalFrames > 1
        onActivated: root.isPlaying = !root.isPlaying
    }
    Shortcut {
        sequence: "Shift+Space"
        enabled: root.visible && root.totalFrames > 1
        onActivated: root.isPlaying = !root.isPlaying
    }

    // ═══════════════════════════════════════════════════════
    //  PLAYBACK
    // ═══════════════════════════════════════════════════════
    Timer {
        id: playTimer
        interval: Math.round(1000 / Math.max(1, root.fps))
        repeat: true; running: root.isPlaying && root.totalFrames > 1
        onTriggered: {
            var next = root.currentFrameIdx + 1
            if (next >= root.totalFrames) {
                if (root.loopEnabled) next = 0
                else { root.isPlaying = false; return }
            }
            root.goToFrame(next)
        }
    }

    Timer { interval: 1500; repeat: true; running: root.totalFrames > 0 && !root.isPlaying
        onTriggered: root._version++ }

    // ═══════════════════════════════════════════════════════
    //  CORE: Frame Navigation & Sync
    // ═══════════════════════════════════════════════════════
    function goToFrame(idx, force) {
        if (idx < 0 || idx >= totalFrames) return

        var isChanged = (currentFrameIdx !== idx) || force

        currentFrameIdx = idx

        if (!isChanged) return

        syncVisibility()
    }

    onOnionEnabledChanged: { goToFrame(currentFrameIdx, true) }
    onOnionBeforeChanged: { goToFrame(currentFrameIdx, true) }
    onOnionAfterChanged: { goToFrame(currentFrameIdx, true) }
    onOnionOpacityChanged: { goToFrame(currentFrameIdx, true) }

    function seekPx(px) {
        if (totalFrames <= 0) return
        var f = Math.round(px / pixelsPerFrame)
        f = Math.max(0, Math.min(totalFrames - 1, f))
        goToFrame(f)
    }

    // Seek based on slot position (for clicking in the track area)
    function seekSlotPx(ti, px) {
        if (totalFrames <= 0) return
        var slot = Math.round(px / pixelsPerFrame)
        slot = Math.max(0, Math.min(totalFrames - 1, slot))
        goToFrame(slot)
    }

    function syncVisibility() {
        if (!targetCanvas || !targetCanvas.layerModel) return

        var visibleLayers = {} // Map of layerName -> opacity (real)
        var activeLayerName = ""

        // 1. Determine which layers should be visible based on the current playhead
        for (var t = 0; t < _trackFrames.length; t++) {
            var frames = _trackFrames[t]
            var fi = findFrameAtSlot(t, currentFrameIdx)
            if (fi >= 0 && fi < frames.length) {
                var curName = frames[fi].layerName
                visibleLayers[curName] = 1.0
                if (t === activeTrackIdx) {
                    activeLayerName = curName
                }
            }

            // 2. Add onion skin layers if this is the active track
            if (onionEnabled && t === activeTrackIdx && fi >= 0) {
                for (var f = 0; f < frames.length; f++) {
                    if (f === fi) continue
                    var d = f - fi
                    var show = (d < 0 && -d <= onionBefore) || (d > 0 && d <= onionAfter)
                    if (show) {
                        var oName = frames[f].layerName
                        if (visibleLayers[oName] === undefined) {
                            var ad = Math.abs(d)
                            var md = d < 0 ? onionBefore : onionAfter
                            var op = Math.max(0.08, onionOpacity * (1.0 - (ad - 1) / md))
                            visibleLayers[oName] = op
                        }
                    }
                }
            }
        }

        // 3. Apply visibility and opacity to target canvas layers
        var model = targetCanvas.layerModel
        for (var i = 0; i < model.length; i++) {
            var layer = model[i]
            var name = layer.name
            var ri = layer.layerId

            // Do not hide the background layer
            if (layer.type === "background" || ri === 0) {
                continue
            }

            if (visibleLayers[name] !== undefined) {
                targetCanvas.setLayerVisibility(ri, true)
                targetCanvas.setLayerOpacity(ri, visibleLayers[name])
                if (name === activeLayerName) {
                    targetCanvas.setActiveLayer(ri)
                }
            } else {
                targetCanvas.setLayerVisibility(ri, false)
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    //  FRAME OPERATIONS
    // ═══════════════════════════════════════════════════════
    function addFrameToTrack(ti) {
        if (!targetCanvas || ti < 0 || ti >= _trackFrames.length) return

        _frameCounter++
        var td = trackModel.get(ti)
        var nm = "AF_" + td.trackName.replace(/[^a-zA-Z0-9]/g,"") + "_F" + _frameCounter

        targetCanvas.addLayer()
        var ri = targetCanvas.activeLayerIndex
        targetCanvas.renameLayer(ri, nm)

        _trackFrames[ti].push({ layerName: nm, label: "F" + (_trackFrames[ti].length + 1), span: 1 })
        _changed()
        goToFrame(_trackFrames[ti].length - 1)
    }

    function copyFrame(ti, fi) {
        if (ti < 0 || ti >= _trackFrames.length) return
        var frames = _trackFrames[ti]
        if (fi < 0 || fi >= frames.length) return
        copiedFrameInfo = { layerName: frames[fi].layerName, span: frames[fi].span }
        if (targetCanvas) targetCanvas.notificationRequested("Fotograma copiado al portapapeles", "info")
    }

    function pasteFrame(ti, fi) {
        if (!targetCanvas || ti < 0 || ti >= _trackFrames.length || !copiedFrameInfo) return
        var frames = _trackFrames[ti]
        var srcRi = findLayerIndexByName(copiedFrameInfo.layerName)
        if (srcRi < 0) {
            if (targetCanvas) targetCanvas.notificationRequested("La capa original ya no existe", "error")
            return
        }

        _frameCounter++
        var td = trackModel.get(ti)
        var nm = "AF_" + td.trackName.replace(/[^a-zA-Z0-9]/g,"") + "_F" + _frameCounter

        targetCanvas.duplicateLayer(srcRi)
        targetCanvas.renameLayer(targetCanvas.activeLayerIndex, nm)

        if (fi >= 0 && fi < frames.length) {
            frames.splice(fi + 1, 0, { layerName: nm, label: "", span: copiedFrameInfo.span })
        } else {
            frames.push({ layerName: nm, label: "", span: copiedFrameInfo.span })
        }

        for (var i = 0; i < frames.length; i++) frames[i].label = "F" + (i+1)
        _changed()
        syncVisibility()
        if (targetCanvas) targetCanvas.notificationRequested("Fotograma pegado", "success")
    }

    function deleteFrame(ti, fi) {
        if (ti < 0 || ti >= _trackFrames.length) return
        var frames = _trackFrames[ti]
        if (fi < 0 || fi >= frames.length) return

        var ri = findLayerIndexByName(frames[fi].layerName)
        if (ri >= 0) targetCanvas.removeLayer(ri)

        frames.splice(fi, 1)
        for (var i = 0; i < frames.length; i++) frames[i].label = "F" + (i+1)
        _changed()

        if (currentFrameIdx >= totalFrames && totalFrames > 0) currentFrameIdx = totalFrames - 1
        if (totalFrames > 0) syncVisibility()
    }

    function dupFrame(ti, fi) {
        if (!targetCanvas || ti < 0 || ti >= _trackFrames.length) return
        var frames = _trackFrames[ti]
        if (fi < 0 || fi >= frames.length) return

        var srcRi = findLayerIndexByName(frames[fi].layerName)
        if (srcRi < 0) return

        _frameCounter++
        var td = trackModel.get(ti)
        var nm = "AF_" + td.trackName.replace(/[^a-zA-Z0-9]/g,"") + "_F" + _frameCounter

        targetCanvas.duplicateLayer(srcRi)
        targetCanvas.renameLayer(targetCanvas.activeLayerIndex, nm)

        frames.splice(fi + 1, 0, { layerName: nm, label: "", span: 1 })
        for (var i = 0; i < frames.length; i++) frames[i].label = "F" + (i+1)
        _changed()
        goToFrame(fi + 1)
    }

    // ═══════════════════════════════════════════════════════
    //  TRACK OPERATIONS
    // ═══════════════════════════════════════════════════════
    function addNewTrack() {
        _trackCounter++
        var nm = "Pista " + _trackCounter
        var cols = ["#cc6644","#4488cc","#44bbcc","#cc44cc","#88cc44","#ccaa44"]
        var icons = ["🎨","🏔","✨","🖌","📐","🎭"]
        var ci = (_trackCounter-1) % cols.length
        trackModel.append({ trackName: nm, trackIcon: icons[ci], trackColor: cols[ci] })
        _trackFrames.push([])
        _changed()
        activeTrackIdx = trackModel.count - 1
    }

    function recalcTotalFrames() {
        var mx = 0
        for (var t = 0; t < _trackFrames.length; t++) {
            var slots = totalSlotsForTrack(t)
            if (slots > mx) mx = slots
        }
        totalFrames = mx
    }

    // ═══════════════════════════════════════════════════════
    //  UI — Premium Procreate Dreams Style
    // ═══════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 6; anchors.rightMargin: 6; anchors.bottomMargin: 4
        radius: 16
        color: "#0d0d11"
        border.color: Qt.rgba(1,1,1,0.06)
        border.width: 1
        clip: true

        // Subtle top highlight
        Rectangle {
            width: parent.width * 0.6; height: 1
            anchors.top: parent.top; anchors.topMargin: 0
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.08) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // ══════════ HEADER — Minimal & Clean ══════════
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 36
                color: "transparent"

                // Bottom separator
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                    color: Qt.rgba(1,1,1,0.04) }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8

                    // Title
                    Row {
                        spacing: 6
                        Text { text: "⊞"; color: "#444"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Timeline"; color: "#999"; font.pixelSize: 11; font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }

                    // Timecode pill
                    Rectangle {
                        width: tcT.implicitWidth + 16; height: 22; radius: 11
                        color: "#0a0a0e"; border.color: Qt.rgba(1,1,1,0.06)
                        Text { id: tcT; anchors.centerIn: parent; text: root.formatTimecode(root.currentTimeSec)
                            color: "#666"; font.pixelSize: 9; font.family: "Consolas" }
                    }

                    // Transport controls — minimal
                    Row { spacing: 2
                        PillBtn { icon: "⏮"; onClicked: root.goToFrame(0) }
                        PillBtn { icon: "◀"; onClicked: root.goToFrame(root.currentFrameIdx-1) }
                        PillBtn { icon: root.isPlaying ? "⏸" : "▶"; highlighted: root.isPlaying
                            onClicked: root.isPlaying = !root.isPlaying }
                        PillBtn { icon: "▶"; onClicked: root.goToFrame(root.currentFrameIdx+1) }
                        PillBtn { icon: "⏭"; onClicked: root.goToFrame(root.totalFrames-1) }
                    }

                    // Thin separator
                    Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1,0.06) }

                    PillBtn { iconSource: "image://icons/onion"; highlighted: root.onionEnabled; highlightCol: "#f0d060"
                        onClicked: { root.onionEnabled = !root.onionEnabled; root.syncVisibility() } }
                    PillBtn { icon: "↻"; highlighted: root.loopEnabled
                        onClicked: root.loopEnabled = !root.loopEnabled }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1,0.06) }

                    // FPS pill
                    Rectangle {
                        width: fpsL.implicitWidth + 14; height: 22; radius: 11
                        color: fpsMa.containsMouse ? "#1a1a20" : "#111116"
                        border.color: fpsPopup.visible ? root.accentColor : Qt.rgba(1,1,1,0.06)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { id: fpsL; anchors.centerIn: parent; text: root.fps + " fps"; color: fpsPopup.visible ? root.accentColor : "#777"; font.pixelSize: 9 }
                        MouseArea { id: fpsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: fpsPopup.visible = !fpsPopup.visible }
                    }

                    // Zoom
                    Row { spacing: 1
                        PillBtn { icon: "−"; fontSize: 11
                            onClicked: { root.pixelsPerFrame = Math.max(16, root.pixelsPerFrame - 6)
                                         root.trackHeight = Math.max(40, root.trackHeight - 6) } }
                        PillBtn { icon: "+"; fontSize: 11
                            onClicked: { root.pixelsPerFrame = Math.min(80, root.pixelsPerFrame + 6)
                                         root.trackHeight = Math.min(120, root.trackHeight + 6) } }
                    }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1,0.06) }

                    // + Frame — accent pill
                    Rectangle {
                        width: addFL.implicitWidth + 20; height: 24; radius: 12
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.accentColor }
                            GradientStop { position: 1; color: Qt.lighter(root.accentColor, 1.15) } }
                        scale: afMa.pressed ? 0.93 : (afMa.containsMouse ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        Text { id: addFL; anchors.centerIn: parent; text: "+ Frame"; color: "white"
                            font.pixelSize: 10; font.weight: Font.Bold }
                        MouseArea { id: afMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.addFrameToTrack(root.activeTrackIdx) }
                    }

                    // + Track — subtle pill
                    Rectangle {
                        width: addTL.implicitWidth + 18; height: 24; radius: 12
                        color: atMa.containsMouse ? "#1e1e24" : "#141418"; border.color: Qt.rgba(1,1,1,0.08)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { id: addTL; anchors.centerIn: parent; text: "+ Pista"; color: "#888"
                            font.pixelSize: 10; font.weight: Font.DemiBold }
                        MouseArea { id: atMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.addNewTrack() }
                    }

                    PillBtn { icon: "⊟"; onClicked: { if (typeof mainWindow !== "undefined") mainWindow.useAdvancedTimeline = false } }
                }
            }

            // ══════════ RULER — Minimal ══════════
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 20; color: "#08080b"
                Rectangle { width: root.trackLabelWidth; height: parent.height; color: "#0a0a0d"; z: 2 }

                // Bottom line
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.03) }

                Flickable {
                    id: rulerFlick
                    anchors.left: parent.left; anchors.leftMargin: root.trackLabelWidth
                    anchors.right: parent.right; height: parent.height
                    contentWidth: root.totalTimelineWidth; clip: true; interactive: false
                    boundsBehavior: Flickable.StopAtBounds

                    Repeater {
                        model: Math.ceil(root.totalTimelineWidth / root.pixelsPerFrame) + 1
                        Item { x: index * root.pixelsPerFrame; width: 1; height: rulerFlick.height
                            Rectangle { visible: index % root.fps === 0; width: 1; height: 10; color: "#444"; anchors.bottom: parent.bottom }
                            Rectangle { visible: index % root.fps !== 0; width: 1; height: 4; color: "#222"; anchors.bottom: parent.bottom }
                            Text { visible: index % root.fps === 0; text: Math.floor(index/root.fps)+"s"
                                color: "#555"; font.pixelSize: 8; x: 3; y: 2 }
                        }
                    }

                    // Playhead marker on ruler
                    Rectangle {
                        visible: root.totalFrames > 0
                        x: root.currentFrameIdx * root.pixelsPerFrame + root.pixelsPerFrame/2 - 5
                        width: 10; height: 10; radius: 5
                        anchors.bottom: parent.bottom; anchors.bottomMargin: -1
                        color: root.accentColor; z: 10

                        // Glow
                        Rectangle {
                            anchors.fill: parent; anchors.margins: -3; radius: width/2
                            color: "transparent"; border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                            border.width: 2
                        }
                    }

                    MouseArea { anchors.fill: parent; z: 5; cursorShape: Qt.PointingHandCursor
                        onPressed: function(m) { root.seekPx(m.x) }
                        onPositionChanged: function(m) { if(pressed) root.seekPx(m.x) } }
                }
            }

            // ══════════ TRACKS — Dreams Style ══════════
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                Flickable {
                    id: trackFlick
                    anchors.fill: parent
                    contentWidth: root.totalTimelineWidth + root.trackLabelWidth
                    contentHeight: tracksCol.implicitHeight + 12
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    onContentXChanged: rulerFlick.contentX = Math.max(0, contentX)

                    Column {
                        id: tracksCol; width: parent.width

                        Repeater {
                            model: trackModel

                            Item {
                                id: trackRow
                                property int tIdx: index
                                property bool isAct: tIdx === root.activeTrackIdx
                                property string tCol: model.trackColor
                                property int fCount: {
                                    var v = root._version
                                    return root._trackFrames && root._trackFrames[tIdx] ? root._trackFrames[tIdx].length : 0
                                }

                                width: tracksCol.width; height: root.trackHeight

                                // ── Track Label — Rounded Pill ────────────
                                Rectangle {
                                    width: root.trackLabelWidth; height: parent.height - 4; z: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 10
                                    color: trackRow.isAct ? "#141418" : "#0c0c10"
                                    border.color: trackRow.isAct ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g,
                                                                           Qt.color(trackRow.tCol).b, 0.4) : Qt.rgba(1,1,1,0.04)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on border.color { ColorAnimation { duration: 200 } }

                                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: function(m) {
                                            root.activeTrackIdx = trackRow.tIdx
                                            if (m.button === Qt.RightButton) { trkCtx.trackIdx = trackRow.tIdx; trkCtx.popup() }
                                        }
                                        onDoubleClicked: { trkEdit.visible = true; trkEdit.text = model.trackName
                                            trkEdit.selectAll(); trkEdit.forceActiveFocus() }
                                    }

                                    Column { anchors.centerIn: parent; spacing: 2; visible: !trkEdit.visible
                                        Row { spacing: 4; anchors.horizontalCenter: parent.horizontalCenter
                                            // Color dot
                                            Rectangle { width: 6; height: 6; radius: 3; color: trackRow.tCol
                                                anchors.verticalCenter: parent.verticalCenter }
                                            Text { text: model.trackName
                                                color: trackRow.isAct ? "#ddd" : "#777"
                                                font.pixelSize: 10; font.weight: Font.DemiBold }
                                        }
                                        Text { text: trackRow.fCount + "f"; color: "#3a3a44"; font.pixelSize: 8
                                            anchors.horizontalCenter: parent.horizontalCenter }
                                    }

                                    TextInput { id: trkEdit; visible: false; anchors.centerIn: parent
                                        width: parent.width - 14; color: "white"; font.pixelSize: 10
                                        horizontalAlignment: Text.AlignHCenter
                                        onAccepted: { trackModel.setProperty(trackRow.tIdx, "trackName", text); visible = false }
                                        onActiveFocusChanged: { if(!activeFocus) visible = false }
                                        Keys.onEscapePressed: visible = false }

                                    // Left accent stripe
                                    Rectangle { visible: trackRow.isAct; width: 3; height: parent.height - 12; radius: 1.5
                                        anchors.left: parent.left; anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter; color: trackRow.tCol }
                                }

                                // ── Frame cells area ──────
                                Item {
                                    x: root.trackLabelWidth + 2; z: 2
                                    width: parent.width - root.trackLabelWidth - 2; height: parent.height

                                    // Subtle grid lines
                                    Repeater {
                                        model: Math.ceil(root.totalTimelineWidth / root.pixelsPerFrame)
                                        Rectangle { x: index*root.pixelsPerFrame; width: 1; height: parent.height
                                            color: index % root.fps === 0 ? Qt.rgba(1,1,1,0.04) : Qt.rgba(1,1,1,0.015) }
                                    }

                                    // ── FRAME BLOCKS — Procreate Dreams Rounded Pills ──
                                    Repeater {
                                        model: trackRow.fCount

                                        Rectangle {
                                            id: fb
                                            property int fi: index
                                            property int frameSpan: root.getFrameSpan(trackRow.tIdx, fi)
                                            property real frameXOff: root.getFrameXOffset(trackRow.tIdx, fi)
                                            property bool cur: {
                                                var v = root._version
                                                var slot = root.currentFrameIdx
                                                var found = root.findFrameAtSlot(trackRow.tIdx, slot)
                                                return found === fi
                                            }
                                            property bool hov: fbMa.containsMouse

                                            // Visual drag tracking for premium live-resize
                                            property real dragDelta: 0
                                            property bool isDragging: stretchMa.pressed
                                            property int visualSpan: Math.max(1, Math.round((frameSpan * root.pixelsPerFrame + _smoothDelta) / root.pixelsPerFrame))

                                            // Smoothed drag delta for high-fidelity response
                                            property real _smoothDelta: 0
                                            Behavior on _smoothDelta {
                                                enabled: true
                                                NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
                                            }
                                            onDragDeltaChanged: _smoothDelta = dragDelta

                                            // --- PHYSICAL TACTILE INTERACTION ---
                                            property real snapImpulse: 0
                                            onVisualSpanChanged: {
                                                if (isDragging) {
                                                    snapBounceAnim.dragDirection = (visualSpan > fb.frameSpan) ? 1 : -1
                                                    snapBounceAnim.restart()
                                                    handleBounce.restart()
                                                }
                                            }

                                            SequentialAnimation {
                                                id: snapBounceAnim
                                                property int dragDirection: 1
                                                NumberAnimation {
                                                    target: fb
                                                    property: "snapImpulse"
                                                    from: dragDirection * 10
                                                    to: 0
                                                    duration: 160
                                                    easing.type: Easing.OutBack
                                                }
                                            }

                                            x: frameXOff + 2
                                            width: isDragging
                                                ? Math.max(root.pixelsPerFrame - 4, root.pixelsPerFrame * frameSpan + _smoothDelta - 4 + snapImpulse)
                                                : root.pixelsPerFrame * frameSpan - 4
                                            height: parent.height - 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 10
                                            color: cur ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g,
                                                                  Qt.color(trackRow.tCol).b, 0.2)
                                                       : (hov ? "#18181f" : "#111116")
                                            border.color: cur ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g,
                                                                         Qt.color(trackRow.tCol).b, 0.6)
                                                              : (hov ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04))
                                            border.width: cur ? 1.5 : 1

                                            Behavior on width {
                                                enabled: !fb.isDragging
                                                NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                                            }

                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                            scale: fbMa.pressed ? 0.95 : 1.0

                                            // Span indicator — shows how many slots when span > 1 or when dragging
                                            Rectangle {
                                                visible: fb.frameSpan > 1 || fb.isDragging
                                                anchors.bottom: parent.bottom; anchors.bottomMargin: 3
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: spanLabel.implicitWidth + 10; height: 14; radius: 7
                                                color: Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g,
                                                               Qt.color(trackRow.tCol).b, 0.3)
                                                z: 5
                                                Text {
                                                    id: spanLabel; anchors.centerIn: parent
                                                    text: "×" + (fb.isDragging ? fb.visualSpan : fb.frameSpan)
                                                    color: "#ccc"; font.pixelSize: 8; font.weight: Font.Bold; font.family: "Consolas"
                                                }
                                            }

                                            // Snap indicator — shows target slot boundary lines while dragging
                                            Rectangle {
                                                visible: fb.isDragging && fb.visualSpan !== fb.frameSpan
                                                x: fb.visualSpan * root.pixelsPerFrame - 4
                                                y: 0; width: 2; height: parent.height
                                                radius: 1
                                                color: trackRow.tCol
                                                opacity: 0.75
                                                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                            }

                                            // Onion overlay
                                            Rectangle {
                                                anchors.fill: parent; radius: parent.radius; z: 1
                                                property int curFi: root.findFrameAtSlot(trackRow.tIdx, root.currentFrameIdx)
                                                property int d: fb.fi - curFi
                                                visible: root.onionEnabled && !fb.cur && trackRow.isAct &&
                                                    ((d < 0 && -d <= root.onionBefore) || (d > 0 && d <= root.onionAfter))
                                                color: d < 0 ? Qt.rgba(1,0.3,0.3,0.12) : Qt.rgba(0.3,1,0.4,0.10)
                                            }

                                            // Inner thumbnail area
                                            Rectangle {
                                                anchors.fill: parent; anchors.margins: 3; z: 2
                                                radius: 7
                                                color: root.canvasBgColor
                                                clip: true

                                                Image {
                                                    anchors.fill: parent; anchors.margins: 1
                                                    fillMode: Image.PreserveAspectFit; cache: false
                                                    source: root.getFrameThumbnail(trackRow.tIdx, fb.fi, root._trackFrames)
                                                    visible: status === Image.Ready
                                                    opacity: fb.cur ? 1.0 : 0.55
                                                }

                                                // Frame number
                                                Text {
                                                    anchors.centerIn: parent; z: 3
                                                    text: fb.fi + 1
                                                    color: fb.cur ? "#888" : "#bbb"
                                                    font.pixelSize: root.pixelsPerFrame > 28 ? 10 : 8
                                                    font.weight: fb.cur ? Font.Bold : Font.Normal
                                                    font.family: "Consolas"
                                                    opacity: 0.3
                                                }
                                            }

                                            // Top accent dot (current)
                                            Rectangle {
                                                visible: fb.cur
                                                width: 4; height: 4; radius: 2
                                                color: trackRow.tCol
                                                anchors.top: parent.top; anchors.topMargin: 4
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                z: 4
                                            }

                                            // ── RIGHT EDGE STRETCH HANDLE ──────
                                            Rectangle {
                                                id: stretchHandle
                                                width: 8; height: parent.height - 8
                                                anchors.right: parent.right; anchors.rightMargin: 0
                                                anchors.verticalCenter: parent.verticalCenter
                                                radius: 4; z: 10
                                                color: stretchMa.containsMouse || stretchMa.pressed
                                                    ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g,
                                                              Qt.color(trackRow.tCol).b, 0.5)
                                                    : "transparent"
                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                // Dynamic scale animation on snap
                                                property real bounceScale: 1.0
                                                scale: bounceScale

                                                SequentialAnimation {
                                                    id: handleBounce
                                                    NumberAnimation { target: stretchHandle; property: "bounceScale"; to: 1.35; duration: 60; easing.type: Easing.OutQuad }
                                                    NumberAnimation { target: stretchHandle; property: "bounceScale"; to: 1.0; duration: 180; easing.type: Easing.OutElastic }
                                                }

                                                // Grip dots
                                                Column {
                                                    anchors.centerIn: parent; spacing: 3
                                                    visible: stretchMa.containsMouse || stretchMa.pressed || fb.hov
                                                    Repeater {
                                                        model: 3
                                                        Rectangle {
                                                            width: 2; height: 2; radius: 1
                                                            color: stretchMa.containsMouse || stretchMa.pressed
                                                                ? "#fff" : "#555"
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: stretchMa
                                                    anchors.fill: parent; anchors.margins: -4
                                                    hoverEnabled: true
                                                    cursorShape: Qt.SizeHorCursor
                                                    preventStealing: true

                                                    property real startX: 0

                                                    onPressed: function(m) {
                                                        startX = mapToItem(trackFlick.contentItem, m.x, 0).x
                                                        fb.dragDelta = 0
                                                        fb._smoothDelta = 0
                                                        root.activeTrackIdx = trackRow.tIdx
                                                    }
                                                    onPositionChanged: function(m) {
                                                        if (!pressed) return
                                                        var gx = mapToItem(trackFlick.contentItem, m.x, 0).x
                                                        fb.dragDelta = gx - startX
                                                    }
                                                    onReleased: {
                                                        var newSpan = fb.visualSpan
                                                        fb.dragDelta = 0
                                                        fb._smoothDelta = 0
                                                        root.setFrameSpan(trackRow.tIdx, fb.fi, newSpan)
                                                    }
                                                }
                                            }

                                            MouseArea { id: fbMa; anchors.fill: parent; hoverEnabled: true
                                                anchors.rightMargin: 10 // leave room for stretch handle
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: function(m) {
                                                    root.activeTrackIdx = trackRow.tIdx
                                                    if (m.button === Qt.RightButton) {
                                                        fCtx.trackIdx = trackRow.tIdx; fCtx.frameIdx = fb.fi; fCtx.popup()
                                                    } else {
                                                        // Navigate to the first slot of this frame
                                                        var slot = 0
                                                        var frames = root._trackFrames[trackRow.tIdx]
                                                        for (var i = 0; i < fb.fi && i < frames.length; i++)
                                                            slot += (frames[i].span || 1)
                                                        root.goToFrame(slot)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // "+" add at end — premium
                                    Rectangle {
                                        x: root.getFrameXOffset(trackRow.tIdx, trackRow.fCount) + 2
                                        width: trackRow.fCount === 0 ? 80 : Math.max(root.pixelsPerFrame - 4, 24)
                                        height: parent.height - 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 8
                                        color: trackRow.fCount === 0
                                            ? (aMa.containsMouse ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g, Qt.color(trackRow.tCol).b, 0.15) : Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g, Qt.color(trackRow.tCol).b, 0.05))
                                            : (aMa.containsMouse ? "#1e1e26" : "transparent")
                                        border.color: trackRow.fCount === 0
                                            ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g, Qt.color(trackRow.tCol).b, 0.25)
                                            : (aMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.centerIn: parent; spacing: 4
                                            Text {
                                                text: "+"
                                                color: trackRow.fCount === 0 ? trackRow.tCol : (aMa.containsMouse ? "#888" : "#333")
                                                font.pixelSize: 12; font.weight: Font.DemiBold
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                visible: trackRow.fCount === 0
                                                text: "Frame"
                                                color: aMa.containsMouse ? "#aaa" : "#666"
                                                font.pixelSize: 9; font.weight: Font.DemiBold
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea { id: aMa; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addFrameToTrack(trackRow.tIdx) }
                                    }

                                    // Click empty = seek & activate track
                                    MouseArea { anchors.fill: parent; z: -1
                                        onPressed: function(m) {
                                            root.activeTrackIdx = trackRow.tIdx
                                            root.seekPx(m.x)
                                        }
                                        onPositionChanged: function(m) { if(pressed) root.seekPx(m.x) } }
                                }

                                // Bottom separator
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                                    color: Qt.rgba(1,1,1,0.02) }
                            }
                        }

                        // Empty state
                        Item {
                            visible: root.totalFrames === 0; width: tracksCol.width; height: 40
                            Rectangle {
                                anchors.fill: parent; anchors.leftMargin: root.trackLabelWidth + 8; anchors.rightMargin: 8
                                anchors.topMargin: 4; anchors.bottomMargin: 4
                                color: "#0e0e13"; radius: 10; border.color: Qt.rgba(1,1,1,0.04)
                                Text { anchors.centerIn: parent; text: "Presiona  + Frame  para empezar"
                                    color: "#333"; font.pixelSize: 11 }
                            }
                        }
                    }

                    // ── PLAYHEAD — Minimal Line ──────────
                    Rectangle {
                        visible: root.totalFrames > 0
                        x: root.currentFrameIdx * root.pixelsPerFrame + root.trackLabelWidth + root.pixelsPerFrame/2 - 1
                        y: 0; width: 2; height: Math.max(trackFlick.contentHeight, trackFlick.height)
                        color: root.accentColor; z: 50
                        opacity: 0.8
                        Behavior on x { enabled: !root.isPlaying; NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

                        // Glow effect
                        Rectangle {
                            width: 8; height: parent.height; anchors.horizontalCenter: parent.horizontalCenter
                            color: "transparent"
                            gradient: Gradient { orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Top handle
                        Rectangle {
                            width: 14; height: 14; radius: 7; color: root.accentColor
                            anchors.horizontalCenter: parent.horizontalCenter; y: -2
                            Text { text: "▶"; color: "white"; font.pixelSize: 7; anchors.centerIn: parent }

                            MouseArea {
                                anchors.fill: parent; anchors.margins: -15
                                cursorShape: Qt.SizeHorCursor
                                hoverEnabled: true
                                property bool isDragging: false

                                onPressed: isDragging = false
                                onPositionChanged: function(m) {
                                    if (!pressed) return
                                    isDragging = true
                                    var gx = mapToItem(trackFlick.contentItem, m.x, 0).x
                                    var f = Math.round((gx - root.trackLabelWidth) / root.pixelsPerFrame)
                                    f = Math.max(0, Math.min(root.totalFrames - 1, f))
                                    if (f >= 0 && f !== root.currentFrameIdx) root.goToFrame(f)
                                }
                                onClicked: {
                                    if (!isDragging) {
                                        playheadActionMenu.openAtPlayhead()
                                    }
                                }
                            }
                        }
                    }
                }

                // Auto-scroll
                Connections {
                    target: root
                    function onCurrentFrameIdxChanged() {
                        var px = root.currentFrameIdx * root.pixelsPerFrame + root.trackLabelWidth
                        if (px < trackFlick.contentX + root.trackLabelWidth + 20)
                            trackFlick.contentX = Math.max(0, px - root.trackLabelWidth - 40)
                        else if (px > trackFlick.contentX + trackFlick.width - 30)
                            trackFlick.contentX = px - trackFlick.width + 60
                    }
                }
            }

            // ══════════ STATUS BAR — Minimal ══════════
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 24; color: "#09090c"
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.03) }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                    Text { text: root.totalFrames > 0
                        ? "Frame " + (root.currentFrameIdx+1) + " / " + root.totalFrames
                          + "  •  " + root.formatTimecode(root.currentTimeSec) + "  •  " + trackModel.count + " pista" + (trackModel.count>1?"s":"")
                        : "Listo"; color: "#333"; font.pixelSize: 9; font.family: "Consolas" }
                    Item { Layout.fillWidth: true }
                    Text { visible: root.onionEnabled; text: "🧅 " + root.onionBefore + "/" + root.onionAfter
                        color: "#f0d060"; font.pixelSize: 9 }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    //  MENUS — Glass Style
    // ═══════════════════════════════════════════════════════

    // Premium Context Menu Item Component
    component PremiumCtxItem : Rectangle {
        id: menuItem
        property string icon: ""
        property string label: ""
        property string subtitle: ""
        property color labelColor: "#ccc"
        property bool isDestructive: false
        signal triggered()

        width: parent.width; height: 32; radius: 6
        color: ma.containsMouse ? (isDestructive ? "#2d1616" : "#20202a") : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
            Text {
                text: menuItem.icon
                font.pixelSize: 12
                color: menuItem.isDestructive ? "#ff6666" : (ma.containsMouse ? root.accentColor : "#777")
                Behavior on color { ColorAnimation { duration: 100 } }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: menuItem.label
                font.pixelSize: 10; font.weight: Font.DemiBold
                color: menuItem.isDestructive ? "#ff6666" : (ma.containsMouse ? "#fff" : menuItem.labelColor)
                Layout.fillWidth: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: menuItem.subtitle !== ""
                text: menuItem.subtitle
                font.pixelSize: 8; color: "#555"
                Layout.alignment: Qt.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { menuItem.triggered(); menuItem.parent.parent.close() }
        }
    }

    Popup {
        id: fCtx
        property int trackIdx: 0
        property int frameIdx: 0
        width: 200; height: 186
        padding: 6
        z: 9999

        background: Rectangle {
            color: "#121218"; radius: 14
            border.color: Qt.rgba(1,1,1,0.08)
            border.width: 1.5

            // Outer glow
            Rectangle {
                anchors.fill: parent; anchors.margins: -4; radius: 18; z: -1
                color: "transparent"; border.color: Qt.rgba(1,1,1,0.04); border.width: 1
            }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.93; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
        }

        function popup() {
            var px = root.getFrameXOffset(fCtx.trackIdx, fCtx.frameIdx) + root.trackLabelWidth - trackFlick.contentX
            x = Math.max(root.trackLabelWidth + 10, Math.min(root.width - width - 10, px))
            y = Math.min(fCtx.trackIdx * root.trackHeight + 30 - trackFlick.contentY, root.height - height - 20)
            open()
        }

        Column {
            width: parent.width; spacing: 4

            PremiumCtxItem {
                icon: "📄"; label: "Copiar fotograma"
                onTriggered: root.copyFrame(fCtx.trackIdx, fCtx.frameIdx)
            }
            PremiumCtxItem {
                icon: "📋"; label: "Pegar fotograma"
                visible: root.copiedFrameInfo !== null
                onTriggered: root.pasteFrame(fCtx.trackIdx, fCtx.frameIdx)
            }
            PremiumCtxItem {
                icon: "📑"; label: "Duplicar frame"
                onTriggered: root.dupFrame(fCtx.trackIdx, fCtx.frameIdx)
            }
            PremiumCtxItem {
                icon: "🧹"; label: "Limpiar fotograma"
                onTriggered: {
                    var fr = root._trackFrames[fCtx.trackIdx]
                    if (fr && fCtx.frameIdx < fr.length && root.targetCanvas) {
                        var ri = root.findLayerIndexByName(fr[fCtx.frameIdx].layerName)
                        if (ri >= 0) root.targetCanvas.clearLayer(ri)
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }

            // Inline stretch selector
            Column {
                width: parent.width; spacing: 4
                padding: 4
                Text {
                    text: "↔ Estirar frame (slots)"
                    font.pixelSize: 8; font.weight: Font.DemiBold; color: "#555"
                    anchors.left: parent.left; anchors.leftMargin: 4
                }
                Row {
                    spacing: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: [1, 2, 3, 4, 6, 8, 12]
                        Rectangle {
                            width: 22; height: 20; radius: 5
                            property bool isAct: root.getFrameSpan(fCtx.trackIdx, fCtx.frameIdx) === modelData
                            color: isAct ? Qt.rgba(Qt.color(root.accentColor).r, Qt.color(root.accentColor).g, Qt.color(root.accentColor).b, 0.25)
                                         : (itemMa.containsMouse ? "#252530" : "#1e1e24")
                            border.color: isAct ? root.accentColor : Qt.rgba(1,1,1,0.06)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: isAct ? "#fff" : "#777"
                                font.pixelSize: 8; font.weight: Font.Bold
                            }
                            MouseArea {
                                id: itemMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.setFrameSpan(fCtx.trackIdx, fCtx.frameIdx, modelData)
                                    fCtx.close()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }

            PremiumCtxItem {
                icon: "🗑️"; label: "Eliminar frame"; isDestructive: true
                onTriggered: root.deleteFrame(fCtx.trackIdx, fCtx.frameIdx)
            }
        }
    }

    Popup {
        id: trkCtx
        property int trackIdx: 0
        width: 180; height: 86
        padding: 6
        z: 9999

        background: Rectangle {
            color: "#121218"; radius: 14
            border.color: Qt.rgba(1,1,1,0.08)
            border.width: 1.5

            // Outer glow
            Rectangle {
                anchors.fill: parent; anchors.margins: -4; radius: 18; z: -1
                color: "transparent"; border.color: Qt.rgba(1,1,1,0.04); border.width: 1
            }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.93; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
        }

        function popup() {
            x = root.trackLabelWidth + 10
            y = Math.min(trkCtx.trackIdx * root.trackHeight + 30 - trackFlick.contentY, root.height - height - 20)
            open()
        }

        Column {
            width: parent.width; spacing: 4

            PremiumCtxItem {
                icon: "✏️"; label: "Renombrar pista"
                onTriggered: renamePopup.openForTrack(trkCtx.trackIdx)
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.06) }

            PremiumCtxItem {
                icon: "🗑️"; label: "Eliminar pista"; isDestructive: true; enabled: trackModel.count > 1
                onTriggered: {
                    var frames = root._trackFrames[trkCtx.trackIdx]
                    while (frames && frames.length > 0) root.deleteFrame(trkCtx.trackIdx, 0)
                    trackModel.remove(trkCtx.trackIdx)
                    root._trackFrames.splice(trkCtx.trackIdx, 1)
                    if (root.activeTrackIdx >= trackModel.count) root.activeTrackIdx = trackModel.count - 1
                    root._changed()
                }
            }
        }
    }

    Popup {
        id: playheadActionMenu
        width: 140; height: 168
        padding: 6
        z: 9999

        background: Rectangle {
            color: "#121218"; radius: 14
            border.color: Qt.rgba(Qt.color(root.accentColor).r, Qt.color(root.accentColor).g, Qt.color(root.accentColor).b, 0.4)
            border.width: 1.5

            // Glass glow
            Rectangle {
                anchors.fill: parent; anchors.margins: -4; radius: 18; z: -1
                color: "transparent"; border.color: Qt.rgba(1,1,1,0.06); border.width: 1
            }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.OutCubic }
        }

        function openAtPlayhead() {
            var px = root.currentFrameIdx * root.pixelsPerFrame + root.trackLabelWidth + root.pixelsPerFrame/2 - trackFlick.contentX
            x = Math.max(root.trackLabelWidth + 10, Math.min(root.width - width - 15, px - width/2))
            y = 22 // Just below ruler
            open()
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 2

            PremiumCtxItem {
                icon: "🎬"; label: "Acción / Clave"
                onTriggered: {
                    if (targetCanvas) targetCanvas.notificationRequested("Modo de Fotograma Clave Activo - Arrastra el lienzo para animar", "success")
                }
            }
            PremiumCtxItem {
                icon: "🎨"; label: "Filtro Onion"
                onTriggered: {
                    root.onionEnabled = !root.onionEnabled
                    root.syncVisibility()
                    if (targetCanvas) targetCanvas.notificationRequested(root.onionEnabled ? "Papel Cebolla Activado" : "Papel Cebolla Desactivado", "info")
                }
            }
            PremiumCtxItem {
                icon: "✂️"; label: "Dividir frame"
                onTriggered: root.splitFrameAtPlayhead()
            }
            PremiumCtxItem {
                icon: "📋"; label: "Duplicar frame"
                onTriggered: {
                    var fi = root.findFrameAtSlot(root.activeTrackIdx, root.currentFrameIdx)
                    if (fi >= 0) root.dupFrame(root.activeTrackIdx, fi)
                }
            }
            PremiumCtxItem {
                icon: "🗑️"; label: "Eliminar frame"; isDestructive: true
                onTriggered: {
                    var fi = root.findFrameAtSlot(root.activeTrackIdx, root.currentFrameIdx)
                    if (fi >= 0) root.deleteFrame(root.activeTrackIdx, fi)
                }
            }
        }
    }

    Popup {
        id: renamePopup
        property int trackIdx: 0
        width: 240; height: 96
        padding: 10
        anchors.centerIn: parent
        z: 10000

        background: Rectangle {
            color: "#121218"; radius: 14
            border.color: root.accentColor
            border.width: 1.5

            // Glow shadow
            Rectangle {
                anchors.fill: parent; anchors.margins: -4; radius: 18; z: -1
                color: "#000"; opacity: 0.5
            }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120 }
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 8
            Text {
                text: "Renombrar Pista"
                color: "#999"; font.pixelSize: 10; font.weight: Font.Bold
            }
            TextField {
                id: renameInput
                Layout.fillWidth: true
                color: "white"; font.pixelSize: 11
                placeholderText: "Escribe el nombre de la pista..."
                placeholderTextColor: "#444"
                background: Rectangle {
                    color: "#1a1a24"
                    radius: 8
                    border.color: renameInput.activeFocus ? root.accentColor : Qt.rgba(1,1,1,0.06)
                    border.width: 1
                }
                Keys.onReturnPressed: {
                    if (text.trim() !== "") {
                        trackModel.setProperty(renamePopup.trackIdx, "trackName", text.trim())
                        root._changed()
                    }
                    renamePopup.close()
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Item { Layout.fillWidth: true }
                TextButton {
                    text: "Cancelar"; textColor: "#666"
                    onClicked: renamePopup.close()
                }
                TextButton {
                    text: "Guardar"; textColor: root.accentColor
                    onClicked: {
                        if (renameInput.text.trim() !== "") {
                            trackModel.setProperty(renamePopup.trackIdx, "trackName", renameInput.text.trim())
                            root._changed()
                        }
                        renamePopup.close()
                    }
                }
            }
        }

        function openForTrack(ti) {
            trackIdx = ti
            var td = trackModel.get(ti)
            renameInput.text = td ? td.trackName : ""
            open()
            renameInput.selectAll()
            renameInput.forceActiveFocus()
        }
    }

    component TextButton : Rectangle {
        id: btn
        property string text: ""
        property color textColor: root.accentColor
        signal clicked()
        width: lbl.implicitWidth + 24; height: 24; radius: 8
        color: ma.containsMouse ? Qt.rgba(btn.textColor.r, btn.textColor.g, btn.textColor.b, 0.12) : "#1a1a22"
        border.color: ma.containsMouse ? btn.textColor : Qt.rgba(1,1,1,0.06)
        Text { id: lbl; anchors.centerIn: parent; text: btn.text; color: btn.textColor; font.pixelSize: 9; font.weight: Font.Bold }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
    }

    // ═══════════════════════════════════════════════════════
    //  PILL BUTTON COMPONENT — Minimal & Clean
    // ═══════════════════════════════════════════════════════
    component PillBtn : Rectangle {
        id: pb
        property string icon: "?"
        property string iconSource: ""
        property bool highlighted: false
        property color highlightCol: root.accentColor
        property int fontSize: 11
        signal clicked()

        width: 24; height: 24; radius: 8
        color: highlighted ? Qt.rgba(highlightCol.r, highlightCol.g, highlightCol.b, 0.12)
                           : (pbMa.containsMouse ? "#1a1a22" : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            visible: pb.iconSource === ""
            text: pb.icon; color: highlighted ? highlightCol : (pbMa.containsMouse ? "#bbb" : "#666")
            font.pixelSize: pb.fontSize; anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Image {
            visible: pb.iconSource !== ""
            source: pb.iconSource
            width: 14; height: 14; anchors.centerIn: parent
            smooth: true; mipmap: true
            opacity: pbMa.containsMouse ? 1.0 : 0.8
            layer.enabled: true
            layer.effect: MultiEffect {
                colorizationColor: pb.highlighted ? pb.highlightCol : (pbMa.containsMouse ? "#ffffff" : "#888888")
                colorization: 1.0
            }
        }
        MouseArea { id: pbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked() }
    }

    // Dismiss overlay for FPS popup
    MouseArea {
        anchors.fill: parent
        z: 9998
        visible: fpsPopup.visible
        onClicked: fpsPopup.visible = false
    }

    // ── FPS POPUP ──────────────────────────────────────────
    Rectangle {
        id: fpsPopup
        visible: false
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        anchors.bottom: parent.top; anchors.bottomMargin: 8
        anchors.right: parent.right; anchors.rightMargin: 180
        width: 320; height: 48; radius: 24
        color: "#14141a"; border.color: Qt.rgba(Qt.color(root.accentColor).r, Qt.color(root.accentColor).g, Qt.color(root.accentColor).b, 0.35); border.width: 1.5
        z: 9999

        // Shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -4
            z: -1; radius: parent.radius + 4
            color: "#000000"; opacity: 0.5
        }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10

            Text {
                text: "⚡"
                font.pixelSize: 13
                color: root.accentColor
                anchors.verticalCenter: parent.verticalCenter
            }

            // Slider container
            Item {
                Layout.fillWidth: true
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                // Slider Track
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#2a2a32"

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
                        radius: 10; color: root.accentColor; opacity: sliderMa.containsMouse ? 0.2 : 0
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
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [8, 12, 24, 30]
                    Rectangle {
                        width: 24; height: 20; radius: 4
                        color: root.fps === modelData
                            ? Qt.rgba(Qt.color(root.accentColor).r, Qt.color(root.accentColor).g, Qt.color(root.accentColor).b, 0.25)
                            : (presetMa.containsMouse ? "#2a2a32" : "#1e1e24")
                        border.color: root.fps === modelData ? root.accentColor : "#333"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.fps === modelData ? root.accentColor : "#999"
                            font.pixelSize: 9; font.weight: Font.Bold
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
}
