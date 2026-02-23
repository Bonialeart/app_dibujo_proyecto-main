import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ══════════════════════════════════════════════════════════════
//  ADVANCED TIMELINE BAR — Procreate Dreams-style
//  Fixed: QML reactivity, frame persistence, thumbnails
// ══════════════════════════════════════════════════════════════
Item {
    id: root

    property var    targetCanvas:   null
    property color  accentColor:    "#ff3366"
    property int    projectFPS:     12

    // Canvas background color for frame thumbnails
    property color  canvasBgColor: {
        if (targetCanvas && targetCanvas.layerModel && targetCanvas.layerModel.length > 0) {
            var bg = targetCanvas.layerModel[0]
            if (bg && bg.bgColor) return bg.bgColor
        }
        return "#ffffff"
    }

    ListModel { id: _trackModel }
    property alias trackModel: _trackModel

    property int  currentFrameIdx:  0
    property int  totalFrames:      0
    property int  fps:              projectFPS
    property bool isPlaying:        false
    property bool loopEnabled:      true
    property bool onionEnabled:     false
    property real onionOpacity:     0.35
    property int  onionBefore:      2
    property int  onionAfter:       1
    property int  activeTrackIdx:   0
    property real pixelsPerFrame:   28
    property real trackLabelWidth:  100
    property real trackHeight:      52

    property real currentTimeSec: currentFrameIdx / Math.max(1, fps)
    property real totalTimelineWidth: Math.max(800, totalFrames * pixelsPerFrame + 300)

    property int _frameCounter: 0
    property int _trackCounter: 0
    property bool _ready: false

    // ═══════════════════════════════════════════════════════
    //  REACTIVE FRAME STORAGE
    //  Key fix: we use a _version counter to force QML
    //  to re-evaluate all bindings that depend on frame data.
    // ═══════════════════════════════════════════════════════
    property var _trackFrames: []
    property int _version: 0  // incremented on every mutation

    // Call this AFTER every mutation to _trackFrames
    function _changed() {
        _version++
        recalcTotalFrames()
    }

    // Safe accessor that re-evaluates when _version changes
    function getFrames(trackIdx) {
        var v = _version  // create dependency
        if (trackIdx < 0 || trackIdx >= _trackFrames.length) return []
        return _trackFrames[trackIdx]
    }

    function getFrameCount(trackIdx) {
        var v = _version
        if (trackIdx < 0 || trackIdx >= _trackFrames.length) return 0
        return _trackFrames[trackIdx].length
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
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

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

    // Refresh thumbnails periodically
    Timer { interval: 1500; repeat: true; running: root.totalFrames > 0 && !root.isPlaying
        onTriggered: root._version++ }

    // ═══════════════════════════════════════════════════════
    //  CORE: Frame Navigation & Sync
    // ═══════════════════════════════════════════════════════
    function goToFrame(idx) {
        if (idx < 0 || idx >= totalFrames) return
        currentFrameIdx = idx
        syncVisibility()
    }

    function seekPx(px) {
        if (totalFrames <= 0) return
        var f = Math.round(px / pixelsPerFrame)
        f = Math.max(0, Math.min(totalFrames - 1, f))
        goToFrame(f)
    }

    function syncVisibility() {
        if (!targetCanvas) return
        for (var t = 0; t < _trackFrames.length; t++) {
            var frames = _trackFrames[t]
            for (var f = 0; f < frames.length; f++) {
                var ri = findLayerIndexByName(frames[f].layerName)
                if (ri < 0) continue
                var isCur = (f === currentFrameIdx)

                if (isCur) {
                    targetCanvas.setLayerVisibility(ri, true)
                    targetCanvas.setLayerOpacity(ri, 1.0)
                    if (t === activeTrackIdx) targetCanvas.setActiveLayer(ri)
                } else if (onionEnabled && t === activeTrackIdx) {
                    var d = f - currentFrameIdx
                    var show = (d < 0 && -d <= onionBefore) || (d > 0 && d <= onionAfter)
                    if (show) {
                        targetCanvas.setLayerVisibility(ri, true)
                        var ad = Math.abs(d), md = d < 0 ? onionBefore : onionAfter
                        targetCanvas.setLayerOpacity(ri, Math.max(0.08, onionOpacity * (1.0 - (ad-1)/md)))
                    } else {
                        targetCanvas.setLayerVisibility(ri, false)
                    }
                } else {
                    targetCanvas.setLayerVisibility(ri, false)
                }
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

        // Create new layer
        targetCanvas.addLayer()
        var ri = targetCanvas.activeLayerIndex
        targetCanvas.renameLayer(ri, nm)

        // Store
        _trackFrames[ti].push({ layerName: nm, label: "F" + (_trackFrames[ti].length + 1) })
        _changed()

        // Navigate to new frame
        goToFrame(_trackFrames[ti].length - 1)

        console.log("Added frame: " + nm + " at layer index " + ri + ", total frames: " + totalFrames)
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

        frames.splice(fi + 1, 0, { layerName: nm, label: "" })
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
        for (var t = 0; t < _trackFrames.length; t++)
            if (_trackFrames[t].length > mx) mx = _trackFrames[t].length
        totalFrames = mx
    }

    // ═══════════════════════════════════════════════════════
    //  UI
    // ═══════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4; anchors.bottomMargin: 2
        radius: 12; color: "#0c0c0f"; border.color: "#1a1a1f"; border.width: 1; clip: true

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // ══════════ HEADER ══════════
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 34; color: "#111114"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 5

                    Text { text: "⊞"; color: "#555"; font.pixelSize: 14 }
                    Text { text: "Timeline"; color: "#bbb"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }

                    // Timecode
                    Rectangle {
                        width: tcT.implicitWidth + 12; height: 20; radius: 4; color: "#090909"; border.color: "#1f1f24"
                        Text { id: tcT; anchors.centerIn: parent; text: root.formatTimecode(root.currentTimeSec)
                            color: "#777"; font.pixelSize: 10; font.family: "Consolas" }
                    }
                    Rectangle { width: 1; height: 16; color: "#222" }

                    // Transport
                    Row { spacing: 3
                        TlBtn { icon: "⏮"; tip: "Inicio"; onClicked: root.goToFrame(0) }
                        TlBtn { icon: "◀"; tip: "Anterior"; onClicked: root.goToFrame(root.currentFrameIdx-1) }
                        TlBtn { icon: root.isPlaying?"⏸":"▶"; tip: root.isPlaying?"Pausar":"Play"
                            highlighted: root.isPlaying; highlightColor: root.accentColor
                            onClicked: root.isPlaying = !root.isPlaying }
                        TlBtn { icon: "▶"; tip: "Siguiente"; onClicked: root.goToFrame(root.currentFrameIdx+1) }
                        TlBtn { icon: "⏭"; tip: "Final"; onClicked: root.goToFrame(root.totalFrames-1) }
                    }
                    Rectangle { width: 1; height: 16; color: "#222" }

                    TlBtn { icon: "◉"; tip: "Onion Skin"; highlighted: root.onionEnabled; highlightColor: "#f0d060"
                        onClicked: { root.onionEnabled = !root.onionEnabled; root.syncVisibility() } }
                    TlBtn { icon: "↻"; tip: "Loop"; highlighted: root.loopEnabled; highlightColor: root.accentColor
                        onClicked: root.loopEnabled = !root.loopEnabled }
                    Rectangle { width: 1; height: 16; color: "#222" }

                    // FPS
                    Rectangle {
                        width: fpsL.implicitWidth + 12; height: 20; radius: 4
                        color: fpsMa.containsMouse ? "#1e1e22" : "#141418"; border.color: "#252530"
                        Text { id: fpsL; anchors.centerIn: parent; text: root.fps+" fps"; color: "#888"; font.pixelSize: 10 }
                        MouseArea { id: fpsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { var r=[6,8,12,15,24,30]; root.fps = r[(r.indexOf(root.fps)+1)%r.length] } }
                    }
                    Rectangle { width: 1; height: 16; color: "#222" }

                    // Zoom
                    Row { spacing: 2
                        TlBtn { icon: "−"; btnSize: 20; fontSize: 11; tip: "Reducir"
                            onClicked: { root.pixelsPerFrame = Math.max(12, root.pixelsPerFrame - 8)
                                         root.trackHeight = Math.max(38, root.trackHeight - 8) } }
                        Rectangle { width: zmL.implicitWidth + 6; height: 18; radius: 3; color: "#0a0a0d"; border.color: "#1f1f24"
                            Text { id: zmL; anchors.centerIn: parent; text: Math.round(root.pixelsPerFrame)+"px"
                                color: "#555"; font.pixelSize: 8; font.family: "Consolas" } }
                        TlBtn { icon: "+"; btnSize: 20; fontSize: 11; tip: "Ampliar"
                            onClicked: { root.pixelsPerFrame = Math.min(80, root.pixelsPerFrame + 8)
                                         root.trackHeight = Math.min(120, root.trackHeight + 8) } }
                    }
                    Rectangle { width: 1; height: 16; color: "#222" }

                    // + Frame
                    Rectangle {
                        width: addFL.implicitWidth + 18; height: 22; radius: 11
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.accentColor }
                            GradientStop { position: 1; color: Qt.lighter(root.accentColor, 1.2) } }
                        scale: afMa.pressed ? 0.92 : (afMa.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { id: addFL; anchors.centerIn: parent; text: "+ Frame"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                        MouseArea { id: afMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.addFrameToTrack(root.activeTrackIdx) }
                    }

                    // + Track
                    Rectangle {
                        width: addTL.implicitWidth + 16; height: 22; radius: 11
                        color: atMa.containsMouse ? "#252530" : "#1a1a20"; border.color: "#333"
                        Text { id: addTL; anchors.centerIn: parent; text: "+ Pista"; color: "#aaa"; font.pixelSize: 10; font.weight: Font.DemiBold }
                        MouseArea { id: atMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.addNewTrack() }
                    }
                    Rectangle { width: 1; height: 16; color: "#222" }

                    TlBtn { icon: "⊟"; tip: "Modo Flipbook"
                        onClicked: { if (typeof mainWindow !== "undefined") mainWindow.useAdvancedTimeline = false } }
                }
            }

            // ══════════ RULER ══════════
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 18; color: "#08080b"
                Rectangle { width: root.trackLabelWidth; height: parent.height; color: "#0a0a0e"; z: 2 }

                Flickable {
                    id: rulerFlick
                    anchors.left: parent.left; anchors.leftMargin: root.trackLabelWidth
                    anchors.right: parent.right; height: parent.height
                    contentWidth: root.totalTimelineWidth; clip: true; interactive: false
                    boundsBehavior: Flickable.StopAtBounds

                    Repeater {
                        model: Math.ceil(root.totalTimelineWidth / root.pixelsPerFrame) + 1
                        Item { x: index * root.pixelsPerFrame; width: 1; height: rulerFlick.height
                            Rectangle { visible: index % root.fps === 0; width: 1; height: 8; color: "#555"; anchors.bottom: parent.bottom }
                            Rectangle { visible: index % root.fps !== 0; width: 1; height: 3; color: "#2a2a30"; anchors.bottom: parent.bottom }
                            Text { visible: index % root.fps === 0; text: Math.floor(index/root.fps)+"s"
                                color: "#555"; font.pixelSize: 7; x: 2; y: 1 }
                        }
                    }

                    // Playhead on ruler
                    Rectangle {
                        visible: root.totalFrames > 0
                        x: root.currentFrameIdx * root.pixelsPerFrame - 1
                        width: 3; height: parent.height; color: root.accentColor; z: 10
                        Rectangle { width: 8; height: 6; color: root.accentColor; radius: 1
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom }
                    }

                    MouseArea { anchors.fill: parent; z: 5; cursorShape: Qt.PointingHandCursor
                        onPressed: function(m) { root.seekPx(m.x) }
                        onPositionChanged: function(m) { if(pressed) root.seekPx(m.x) } }
                }
            }

            // ══════════ TRACKS ══════════
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
                                property int fCount: root._trackFrames && root._trackFrames[tIdx] ? root._trackFrames[tIdx].length : 0

                                width: tracksCol.width; height: root.trackHeight

                                // ── Label ────────────
                                Rectangle {
                                    width: root.trackLabelWidth; height: parent.height; z: 3
                                    color: trackRow.isAct ? "#16161a" : "#0e0e12"
                                    border.color: trackRow.isAct ? trackRow.tCol : "#1a1a1f"
                                    border.width: trackRow.isAct ? 1 : 0

                                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: function(m) {
                                            root.activeTrackIdx = trackRow.tIdx
                                            if (m.button === Qt.RightButton) { trkCtx.trackIdx = trackRow.tIdx; trkCtx.popup() }
                                        }
                                        onDoubleClicked: { trkEdit.visible = true; trkEdit.text = model.trackName
                                            trkEdit.selectAll(); trkEdit.forceActiveFocus() }
                                    }

                                    Column { anchors.centerIn: parent; spacing: 1; visible: !trkEdit.visible
                                        Row { spacing: 3; anchors.horizontalCenter: parent.horizontalCenter
                                            Text { text: model.trackIcon; font.pixelSize: 12 }
                                            Text { text: model.trackName; color: trackRow.isAct ? "#ddd" : "#888"
                                                font.pixelSize: 10; font.weight: Font.DemiBold } }
                                        Text { text: trackRow.fCount + " frames"; color: "#444"; font.pixelSize: 8
                                            anchors.horizontalCenter: parent.horizontalCenter }
                                    }

                                    TextInput { id: trkEdit; visible: false; anchors.centerIn: parent
                                        width: parent.width - 10; color: "white"; font.pixelSize: 10
                                        horizontalAlignment: Text.AlignHCenter
                                        onAccepted: { trackModel.setProperty(trackRow.tIdx, "trackName", text); visible = false }
                                        onActiveFocusChanged: { if(!activeFocus) visible = false }
                                        Keys.onEscapePressed: visible = false }

                                    Rectangle { visible: trackRow.isAct; width: 3; height: parent.height
                                        anchors.left: parent.left; color: trackRow.tCol }
                                }

                                // ── Frame cells ──────
                                Item {
                                    x: root.trackLabelWidth; z: 2
                                    width: parent.width - root.trackLabelWidth; height: parent.height

                                    Rectangle { anchors.fill: parent; color: "#0a0a0e" }

                                    // Grid
                                    Repeater {
                                        model: Math.ceil(root.totalTimelineWidth / root.pixelsPerFrame)
                                        Rectangle { x: index*root.pixelsPerFrame; width: 1; height: parent.height
                                            color: index % root.fps === 0 ? "#1a1a20" : "#111114" }
                                    }

                                    // ── FRAME BLOCKS (Premium Rounded) ──
                                    Repeater {
                                        model: trackRow.fCount

                                        Rectangle {
                                            id: fb
                                            property int fi: index
                                            property bool cur: fi === root.currentFrameIdx

                                            x: fi * root.pixelsPerFrame + 1
                                            width: root.pixelsPerFrame - 2; height: parent.height - 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 6
                                            color: cur ? Qt.rgba(Qt.color(trackRow.tCol).r, Qt.color(trackRow.tCol).g,
                                                                  Qt.color(trackRow.tCol).b, 0.3)
                                                       : (fbMa.containsMouse ? "#1e1e28" : "#131318")
                                            border.color: cur ? trackRow.tCol : "#222228"
                                            border.width: cur ? 2 : 1
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                            // Onion overlay
                                            Rectangle {
                                                anchors.fill: parent; radius: parent.radius; z: 1
                                                property int d: fb.fi - root.currentFrameIdx
                                                visible: root.onionEnabled && !fb.cur && trackRow.isAct &&
                                                    ((d < 0 && -d <= root.onionBefore) || (d > 0 && d <= root.onionAfter))
                                                color: d < 0 ? Qt.rgba(1,0.3,0.3,0.18) : Qt.rgba(0.3,1,0.4,0.15)
                                            }

                                            // Inner canvas-colored thumbnail area
                                            Rectangle {
                                                anchors.fill: parent; anchors.margins: 2; z: 2
                                                radius: 4
                                                color: root.canvasBgColor
                                                clip: true

                                                // Thumbnail
                                                Image {
                                                    anchors.fill: parent; anchors.margins: 1
                                                    fillMode: Image.PreserveAspectFit; cache: false
                                                    source: root.getFrameThumbnail(trackRow.tIdx, fb.fi, root._trackFrames)
                                                    visible: status === Image.Ready
                                                    opacity: fb.cur ? 1.0 : 0.6
                                                }

                                                // Frame number (shown when no thumbnail)
                                                Text {
                                                    anchors.centerIn: parent; z: 3
                                                    text: fb.fi + 1
                                                    color: fb.cur ? "#555" : "#bbb"
                                                    font.pixelSize: root.pixelsPerFrame > 24 ? 11 : 8
                                                    font.weight: fb.cur ? Font.Bold : Font.Normal
                                                    font.family: "Consolas"
                                                    opacity: 0.4
                                                }
                                            }

                                            // Top accent bar
                                            Rectangle {
                                                width: parent.width - 4; height: 2; radius: 1
                                                color: fb.cur ? trackRow.tCol : "transparent"
                                                anchors.top: parent.top; anchors.topMargin: 2
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                z: 4
                                            }

                                            MouseArea { id: fbMa; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: function(m) {
                                                    root.activeTrackIdx = trackRow.tIdx
                                                    if (m.button === Qt.RightButton) {
                                                        fCtx.trackIdx = trackRow.tIdx; fCtx.frameIdx = fb.fi; fCtx.popup()
                                                    } else root.goToFrame(fb.fi)
                                                }
                                            }
                                        }
                                    }

                                    // "+" add at end
                                    Rectangle {
                                        x: trackRow.fCount * root.pixelsPerFrame
                                        width: Math.max(root.pixelsPerFrame, 22); height: parent.height
                                        color: aMa.containsMouse ? "#1a1a22" : "transparent"
                                        Text { anchors.centerIn: parent; text: "+"; color: aMa.containsMouse ? "#888" : "#2a2a30"
                                            font.pixelSize: 14 }
                                        MouseArea { id: aMa; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addFrameToTrack(trackRow.tIdx) }
                                    }

                                    // Click empty = seek
                                    MouseArea { anchors.fill: parent; z: -1
                                        onPressed: function(m) { root.seekPx(m.x) }
                                        onPositionChanged: function(m) { if(pressed) root.seekPx(m.x) } }
                                }

                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#141418" }
                            }
                        }

                        // Empty state
                        Item {
                            visible: root.totalFrames === 0; width: tracksCol.width; height: 32
                            Rectangle {
                                anchors.fill: parent; anchors.leftMargin: root.trackLabelWidth + 4; anchors.rightMargin: 4
                                color: "#0e0e12"; radius: 4
                                Text { anchors.centerIn: parent; text: "🎬 Presiona  + Frame  para empezar"; color: "#444"; font.pixelSize: 10 }
                            }
                        }
                    }

                    // ── PLAYHEAD ──────────
                    Rectangle {
                        visible: root.totalFrames > 0
                        x: root.currentFrameIdx * root.pixelsPerFrame + root.trackLabelWidth
                        y: 0; width: 2; height: Math.max(trackFlick.contentHeight, trackFlick.height)
                        color: root.accentColor; z: 50
                        Behavior on x { enabled: !root.isPlaying; NumberAnimation { duration: 60; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: 18; height: 18; radius: 9; color: root.accentColor
                            anchors.horizontalCenter: parent.horizontalCenter; y: 2
                            Text { text: "▶"; color: "white"; font.pixelSize: 8; anchors.centerIn: parent }
                            Rectangle { anchors.fill: parent; anchors.margins: -3; radius: width/2; color: "transparent"
                                border.color: Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.3); border.width: 2 }

                            MouseArea {
                                anchors.fill: parent; anchors.margins: -12
                                cursorShape: Qt.SizeHorCursor
                                onPressed: function(m) { }
                                onPositionChanged: function(m) {
                                    if (!pressed) return
                                    var gx = mapToItem(trackFlick.contentItem, m.x, 0).x
                                    var f = Math.round((gx - root.trackLabelWidth) / root.pixelsPerFrame)
                                    f = Math.max(0, Math.min(root.totalFrames - 1, f))
                                    if (f >= 0 && f !== root.currentFrameIdx) root.goToFrame(f)
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

            // ══════════ STATUS ══════════
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 22; color: "#0a0a0d"
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#141418" }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: root.totalFrames > 0
                        ? "Frame " + (root.currentFrameIdx+1) + "/" + root.totalFrames
                          + " • " + root.formatTimecode(root.currentTimeSec) + " • " + trackModel.count + " pistas"
                        : "🎬 Listo"; color: "#444"; font.pixelSize: 8; font.family: "Consolas" }
                    Item { Layout.fillWidth: true }
                    Text { visible: root.onionEnabled; text: "🧅 " + root.onionBefore + "/" + root.onionAfter
                        color: "#f0d060"; font.pixelSize: 8 }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    //  MENUS
    // ═══════════════════════════════════════════════════════
    Menu {
        id: fCtx; property int trackIdx: 0; property int frameIdx: 0
        background: Rectangle { color: "#1a1a20"; radius: 8; border.color: "#333" }
        MenuItem { text: "📋 Duplicar"; onTriggered: root.dupFrame(fCtx.trackIdx, fCtx.frameIdx)
            background: Rectangle { color: parent.highlighted ? "#2a2a35" : "transparent" }
            contentItem: Text { text: parent.text; color: "#ccc"; font.pixelSize: 11 } }
        MenuItem { text: "🧹 Limpiar"; onTriggered: {
                var fr = root._trackFrames[fCtx.trackIdx]
                if (fr && fCtx.frameIdx < fr.length && root.targetCanvas) {
                    var ri = root.findLayerIndexByName(fr[fCtx.frameIdx].layerName)
                    if (ri >= 0) root.targetCanvas.clearLayer(ri) } }
            background: Rectangle { color: parent.highlighted ? "#2a2a35" : "transparent" }
            contentItem: Text { text: parent.text; color: "#ccc"; font.pixelSize: 11 } }
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#333" } }
        MenuItem { text: "🗑️ Eliminar"; onTriggered: root.deleteFrame(fCtx.trackIdx, fCtx.frameIdx)
            background: Rectangle { color: parent.highlighted ? "#3a2020" : "transparent" }
            contentItem: Text { text: parent.text; color: "#ff6666"; font.pixelSize: 11 } }
    }

    Menu {
        id: trkCtx; property int trackIdx: 0
        background: Rectangle { color: "#1a1a20"; radius: 8; border.color: "#333" }
        MenuItem { text: "✏️ Renombrar (doble-click)"
            background: Rectangle { color: parent.highlighted ? "#2a2a35" : "transparent" }
            contentItem: Text { text: parent.text; color: "#888"; font.pixelSize: 11 } }
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#333" } }
        MenuItem { text: "🗑️ Eliminar pista"; enabled: trackModel.count > 1
            onTriggered: {
                var frames = root._trackFrames[trkCtx.trackIdx]
                while (frames && frames.length > 0) root.deleteFrame(trkCtx.trackIdx, 0)
                trackModel.remove(trkCtx.trackIdx)
                root._trackFrames.splice(trkCtx.trackIdx, 1)
                if (root.activeTrackIdx >= trackModel.count) root.activeTrackIdx = trackModel.count - 1
                root._changed()
            }
            background: Rectangle { color: parent.highlighted ? "#3a2020" : "transparent" }
            contentItem: Text { text: parent.text; color: "#ff6666"; font.pixelSize: 11 } }
    }

    // ═══════════════════════════════════════════════════════
    //  BUTTON COMPONENT
    // ═══════════════════════════════════════════════════════
    component TlBtn : Rectangle {
        id: tlb
        property string icon: "?"; property string tip: ""
        property bool highlighted: false; property color highlightColor: root.accentColor
        property int btnSize: 22; property int fontSize: 12
        signal clicked()
        width: btnSize; height: btnSize; radius: btnSize/2-2
        color: highlighted ? Qt.rgba(highlightColor.r,highlightColor.g,highlightColor.b,0.18)
                           : (tlMa.containsMouse ? "#252530" : "transparent")
        Text { text: tlb.icon; color: highlighted ? highlightColor : "#aaa"; font.pixelSize: tlb.fontSize
            anchors.centerIn: parent; opacity: tlb.enabled ? (tlMa.containsMouse ? 1 : 0.8) : 0.2 }
        MouseArea { id: tlMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: tlb.clicked() }
        ToolTip.visible: tlMa.containsMouse && tlb.tip !== ""; ToolTip.text: tlb.tip; ToolTip.delay: 300
    }
}
