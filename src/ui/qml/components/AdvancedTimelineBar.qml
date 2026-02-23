import QtQuick
import QtQuick.Controls
import QtQuick.Layouts 1.15

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
    property int  totalFrames:      0
    property int  fps:              projectFPS
    property bool isPlaying:        false
    property bool loopEnabled:      true
    property bool onionEnabled:     false
    property real onionOpacity:     0.35
    property int  onionBefore:      2
    property int  onionAfter:       1
    property int  activeTrackIdx:   0
    property real pixelsPerFrame:   36
    property real trackLabelWidth:  90
    property real trackHeight:      56

    property real currentTimeSec: currentFrameIdx / Math.max(1, fps)
    property real totalTimelineWidth: Math.max(800, totalFrames * pixelsPerFrame + 300)

    property int _frameCounter: 0
    property int _trackCounter: 0
    property bool _ready: false

    // ═══════════════════════════════════════════════════════
    //  REACTIVE FRAME STORAGE
    // ═══════════════════════════════════════════════════════
    property var _trackFrames: []
    property int _version: 0

    function _changed() {
        _version++
        recalcTotalFrames()
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

        targetCanvas.addLayer()
        var ri = targetCanvas.activeLayerIndex
        targetCanvas.renameLayer(ri, nm)

        _trackFrames[ti].push({ layerName: nm, label: "F" + (_trackFrames[ti].length + 1) })
        _changed()
        goToFrame(_trackFrames[ti].length - 1)
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

                    PillBtn { icon: "◉"; highlighted: root.onionEnabled; highlightCol: "#f0d060"
                        onClicked: { root.onionEnabled = !root.onionEnabled; root.syncVisibility() } }
                    PillBtn { icon: "↻"; highlighted: root.loopEnabled
                        onClicked: root.loopEnabled = !root.loopEnabled }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1,1,1,0.06) }

                    // FPS pill
                    Rectangle {
                        width: fpsL.implicitWidth + 14; height: 22; radius: 11
                        color: fpsMa.containsMouse ? "#1a1a20" : "#111116"
                        border.color: Qt.rgba(1,1,1,0.06)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { id: fpsL; anchors.centerIn: parent; text: root.fps + " fps"; color: "#777"; font.pixelSize: 9 }
                        MouseArea { id: fpsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { var r=[6,8,12,15,24,30]; root.fps = r[(r.indexOf(root.fps)+1)%r.length] } }
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
                                property int fCount: root._trackFrames && root._trackFrames[tIdx] ? root._trackFrames[tIdx].length : 0

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
                                            property bool cur: fi === root.currentFrameIdx
                                            property bool hov: fbMa.containsMouse

                                            x: fi * root.pixelsPerFrame + 2
                                            width: root.pixelsPerFrame - 4
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
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                            scale: fbMa.pressed ? 0.95 : 1.0

                                            // Onion overlay
                                            Rectangle {
                                                anchors.fill: parent; radius: parent.radius; z: 1
                                                property int d: fb.fi - root.currentFrameIdx
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

                                    // "+" add at end — subtle
                                    Rectangle {
                                        x: trackRow.fCount * root.pixelsPerFrame + 2
                                        width: Math.max(root.pixelsPerFrame - 4, 22); height: parent.height - 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 10; color: aMa.containsMouse ? "#14141a" : "transparent"
                                        border.color: aMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent; text: "+"; color: aMa.containsMouse ? "#666" : "#222"
                                            font.pixelSize: 14; font.weight: Font.Light
                                            Behavior on color { ColorAnimation { duration: 150 } } }
                                        MouseArea { id: aMa; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addFrameToTrack(trackRow.tIdx) }
                                    }

                                    // Click empty = seek
                                    MouseArea { anchors.fill: parent; z: -1
                                        onPressed: function(m) { root.seekPx(m.x) }
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
    Menu {
        id: fCtx; property int trackIdx: 0; property int frameIdx: 0
        background: Rectangle { color: "#1a1a22"; radius: 12; border.color: Qt.rgba(1,1,1,0.08) }
        MenuItem { text: "📋 Duplicar"; onTriggered: root.dupFrame(fCtx.trackIdx, fCtx.frameIdx)
            background: Rectangle { color: parent.highlighted ? "#252530" : "transparent"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#ccc"; font.pixelSize: 11 } }
        MenuItem { text: "🧹 Limpiar"; onTriggered: {
                var fr = root._trackFrames[fCtx.trackIdx]
                if (fr && fCtx.frameIdx < fr.length && root.targetCanvas) {
                    var ri = root.findLayerIndexByName(fr[fCtx.frameIdx].layerName)
                    if (ri >= 0) root.targetCanvas.clearLayer(ri) } }
            background: Rectangle { color: parent.highlighted ? "#252530" : "transparent"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#ccc"; font.pixelSize: 11 } }
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: Qt.rgba(1,1,1,0.06) } }
        MenuItem { text: "🗑️ Eliminar"; onTriggered: root.deleteFrame(fCtx.trackIdx, fCtx.frameIdx)
            background: Rectangle { color: parent.highlighted ? "#3a2020" : "transparent"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#ff6666"; font.pixelSize: 11 } }
    }

    Menu {
        id: trkCtx; property int trackIdx: 0
        background: Rectangle { color: "#1a1a22"; radius: 12; border.color: Qt.rgba(1,1,1,0.08) }
        MenuItem { text: "✏️ Renombrar (doble-click)"
            background: Rectangle { color: parent.highlighted ? "#252530" : "transparent"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#888"; font.pixelSize: 11 } }
        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: Qt.rgba(1,1,1,0.06) } }
        MenuItem { text: "🗑️ Eliminar pista"; enabled: trackModel.count > 1
            onTriggered: {
                var frames = root._trackFrames[trkCtx.trackIdx]
                while (frames && frames.length > 0) root.deleteFrame(trkCtx.trackIdx, 0)
                trackModel.remove(trkCtx.trackIdx)
                root._trackFrames.splice(trkCtx.trackIdx, 1)
                if (root.activeTrackIdx >= trackModel.count) root.activeTrackIdx = trackModel.count - 1
                root._changed()
            }
            background: Rectangle { color: parent.highlighted ? "#3a2020" : "transparent"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#ff6666"; font.pixelSize: 11 } }
    }

    // ═══════════════════════════════════════════════════════
    //  PILL BUTTON COMPONENT — Minimal & Clean
    // ═══════════════════════════════════════════════════════
    component PillBtn : Rectangle {
        id: pb
        property string icon: "?"
        property bool highlighted: false
        property color highlightCol: root.accentColor
        property int fontSize: 11
        signal clicked()

        width: 24; height: 24; radius: 8
        color: highlighted ? Qt.rgba(highlightCol.r, highlightCol.g, highlightCol.b, 0.12)
                           : (pbMa.containsMouse ? "#1a1a22" : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        Text { text: pb.icon; color: highlighted ? highlightCol : (pbMa.containsMouse ? "#bbb" : "#666")
            font.pixelSize: pb.fontSize; anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: 120 } } }
        MouseArea { id: pbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked() }
    }
}
