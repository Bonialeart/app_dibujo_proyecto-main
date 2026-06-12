import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

// ══════════════════════════════════════════════════════════════
//  TIMELINE PANEL  —  Studio Mode (Bottom Dock)
//  Connected to the shared SimpleAnimationBar data so that
//  switching between Essential ↔ Studio preserves all frames.
// ══════════════════════════════════════════════════════════════
Item {
    id: root
    property var   targetCanvas: null
    property color accentColor:  "#e84393"
    property color colorAccent:  accentColor   // alias for DockContainer binding

    // ── Reference to the shared animation bar ────────────────
    // The SimpleAnimationBar in main_pro.qml is the single source of truth.
    property var sharedBar: {
        if (typeof mainWindow !== "undefined" && mainWindow.simpleAnimationBar)
            return mainWindow.simpleAnimationBar
        return null
    }

    // ── Shared animation camera (dedicated "Cámara" track) ──
    property var camera: {
        if (typeof mainWindow !== "undefined" && mainWindow.animationCamera)
            return mainWindow.animationCamera
        return null
    }
    property real camTrackH: 20

    // Maps a timeline slot to a frame index, honouring durations.
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

    Component.onCompleted: console.log("TimelinePanel loaded — connected:", sharedBar !== null)

    // ── Forwarded properties (read from shared bar) ──────────
    property int  currentFrameIdx: sharedBar ? sharedBar.currentFrameIdx : 0
    property int  frameCount:      sharedBar ? sharedBar.frameCount      : 0
    property int  fps:             sharedBar ? sharedBar.fps             : 12
    property bool isPlaying:       sharedBar ? sharedBar.isPlaying       : false
    property bool loopEnabled:     sharedBar ? sharedBar.loopEnabled     : true
    property bool onionEnabled:    sharedBar ? sharedBar.onionEnabled    : false
    property real onionOpacity:    sharedBar ? sharedBar.onionOpacity    : 0.4
    property int  onionBefore:     sharedBar ? sharedBar.onionBefore     : 2
    property int  onionAfter:      sharedBar ? sharedBar.onionAfter      : 1
    property bool isScrubbing:     false

    // ── Grid layout ─────────────────────────────────────────
    property real cellW:  52
    property real cellH:  44
    property real cellGap: 2
    property real cellStep: cellW + cellGap
    property real trackLabelW: 80
    property real rulerH: 20

    // ── Slot helpers (delegated to shared bar) ──────────────
    function getFrameDuration(fi) { return sharedBar ? sharedBar.getFrameDuration(fi) : 1 }
    function getSlotOffset(fi)    { return sharedBar ? sharedBar.getSlotOffset(fi)    : 0 }
    function totalSlots()         { return sharedBar ? sharedBar.totalSlots()          : 0 }

    // ── Actions (delegate to shared bar) ────────────────────
    function goToFrame(idx)       { if (sharedBar) sharedBar.goToFrame(idx) }
    function addFrame()           { if (sharedBar) sharedBar.addFrame() }
    function deleteCurrentFrame() { if (sharedBar) sharedBar.deleteCurrentFrame() }
    function duplicateFrame()     { if (sharedBar) sharedBar.duplicateCurrentFrame() }
    function setFrameDuration(fi, d) { if (sharedBar) sharedBar.setFrameDuration(fi, d) }
    function togglePlay()         { if (sharedBar && frameCount > 1) sharedBar.isPlaying = !sharedBar.isPlaying }
    function toggleLoop()         { if (sharedBar) sharedBar.loopEnabled = !sharedBar.loopEnabled }
    function toggleOnion()        { if (sharedBar) sharedBar.onionEnabled = !sharedBar.onionEnabled }
    function cycleFPS() {
        if (!sharedBar) return
        var rates = [6, 8, 12, 15, 24, 30]
        var i = rates.indexOf(sharedBar.fps)
        sharedBar.fps = rates[(i + 1) % rates.length]
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
        onActivated: root.togglePlay()
    }
    Shortcut {
        sequence: "Shift+Space"
        enabled: root.visible && root.frameCount > 1
        onActivated: root.togglePlay()
    }

    // ════════════════════════════════════════════════════════
    //  UI — Premium Dark Timeline
    // ════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        radius: 0
        color: "#0d0d11"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── 1. CONTROL BAR ────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: "#111116"

                // Bottom separator
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1
                    color: Qt.rgba(1,1,1,0.05) }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 6

                    // ── Playback transport ──
                    Row {
                        spacing: 2
                        TLPill { iconSource: "image://icons/arrow-left-to-line"; onClicked: root.goToFrame(0) }
                        TLPill { iconSource: "image://icons/arrow-left-01"; onClicked: root.goToFrame(root.currentFrameIdx - 1) }
                        TLPill {
                            iconSource: root.isPlaying ? "image://icons/pause" : "image://icons/play"
                            highlighted: root.isPlaying
                            onClicked: root.togglePlay()
                        }
                        TLPill { iconSource: "image://icons/arrow-right-01"; onClicked: root.goToFrame(root.currentFrameIdx + 1) }
                        TLPill { iconSource: "image://icons/arrow-right-to-line"; onClicked: root.goToFrame(root.frameCount - 1) }
                    }

                    // Separator
                    Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.06) }

                    // ── Frame counter pill ──
                    Rectangle {
                        width: fcTxt.implicitWidth + 20; height: 24; radius: 12
                        color: "#0a0a0e"; border.color: Qt.rgba(1,1,1,0.06)
                        Text {
                            id: fcTxt; anchors.centerIn: parent
                            text: root.frameCount === 0
                                ? "— / —"
                                : (root.currentFrameIdx + 1) + " / " + root.frameCount
                            color: root.frameCount === 0 ? "#444" : "#bbb"
                            font.pixelSize: 11; font.family: "Consolas"; font.weight: Font.DemiBold
                        }
                    }

                    // ── Timecode ──
                    Text {
                        visible: root.frameCount > 0
                        text: {
                            var s = root.currentFrameIdx / Math.max(1, root.fps)
                            return s.toFixed(1) + "s"
                        }
                        color: "#444"; font.pixelSize: 9; font.family: "Consolas"
                    }

                    Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.06) }

                    // ── Toggle buttons ──
                    TLPill { iconSource: "image://icons/repeat"; highlighted: root.loopEnabled; onClicked: root.toggleLoop() }
                    TLPill { iconSource: "image://icons/onion"; highlighted: root.onionEnabled; highlightCol: "#f0d060"
                        onClicked: root.toggleOnion() }

                    Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.06) }

                    // ── FPS pill ──
                    Rectangle {
                        id: fpsPillContainer
                        width: fpsTxt.implicitWidth + 14; height: 24; radius: 12
                        color: fpsPopup.visible ? root.accentColor : (fpsMa.containsMouse ? "#1a1a20" : "#111116")
                        border.color: fpsPopup.visible ? root.accentColor : Qt.rgba(1,1,1,0.06)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { id: fpsTxt; anchors.centerIn: parent; text: root.fps + " fps"
                            color: fpsPopup.visible ? "white" : "#777"; font.pixelSize: 9 }
                        MouseArea { id: fpsMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: fpsPopup.visible = !fpsPopup.visible }
                        ToolTip.visible: fpsMa.containsMouse && !fpsPopup.visible; ToolTip.text: "Cambiar FPS"; ToolTip.delay: 400
                    }

                    Item { Layout.fillWidth: true }

                    // ── Duplicate & Delete ──
                    TLPill { iconSource: "image://icons/duplicate_outline"; onClicked: root.duplicateFrame(); enabled: root.frameCount > 0 }
                    TLPill { iconSource: "image://icons/trash"; onClicked: root.deleteCurrentFrame(); enabled: root.frameCount > 1 }

                    Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.06) }

                    // ── + New Frame button (accent) ──
                    Rectangle {
                        width: addFTxt.implicitWidth + 22; height: 26; radius: 13
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.accentColor }
                            GradientStop { position: 1; color: Qt.lighter(root.accentColor, 1.15) }
                        }
                        scale: addFMa.pressed ? 0.93 : (addFMa.containsMouse ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                        Text { id: addFTxt; anchors.centerIn: parent; text: "+ Frame"
                            color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                        MouseArea { id: addFMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame() }
                    }
                }
            }

            // ── 2. ONION SETTINGS BAR (collapsible) ───────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.onionEnabled ? 32 : 0
                color: "#0e0e12"; clip: true; visible: height > 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 16

                    Row {
                        spacing: 5
                        Rectangle { width: 8; height: 8; radius: 2; color: "#cc4444"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Antes:"; color: "#777"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                        TLStepper { value: root.onionBefore; accent: "#cc4444"
                            onDec: { if (sharedBar && sharedBar.onionBefore > 0) sharedBar.onionBefore-- }
                            onInc: { if (sharedBar && sharedBar.onionBefore < 8) sharedBar.onionBefore++ }
                        }
                    }

                    Row {
                        spacing: 5
                        Rectangle { width: 8; height: 8; radius: 2; color: "#44cc66"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Después:"; color: "#777"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                        TLStepper { value: root.onionAfter; accent: "#44cc66"
                            onDec: { if (sharedBar && sharedBar.onionAfter > 0) sharedBar.onionAfter-- }
                            onInc: { if (sharedBar && sharedBar.onionAfter < 8) sharedBar.onionAfter++ }
                        }
                    }

                    Row {
                        spacing: 5
                        Text { text: "Opacidad:"; color: "#777"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: Math.round(root.onionOpacity * 100) + "%"
                            color: "#f0d060"; font.pixelSize: 10; font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                                property real sx; property real so
                                onPressed: (m) => { sx = m.x; so = root.onionOpacity }
                                onPositionChanged: (m) => {
                                    if (pressed && sharedBar)
                                        sharedBar.onionOpacity = Math.max(0.05, Math.min(1.0, so + (m.x - sx) * 0.005))
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // ── 3. TIMELINE BODY ──────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ── EMPTY STATE ──
                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    visible: root.frameCount === 0

                    Image {
                        source: "image://icons/film-01"
                        width: 42; height: 42
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.25
                        smooth: true; mipmap: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorizationColor: "#ffffff"
                            colorization: 1.0
                        }
                    }
                    Text {
                        text: "Sin fotogramas"
                        color: "#555"; font.pixelSize: 14; font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Pulsa  "+ "\"+ Frame\""  +"  para comenzar tu animación"
                        color: "#333"; font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 140; height: 36; radius: 18
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.accentColor }
                            GradientStop { position: 1; color: Qt.lighter(root.accentColor, 1.15) }
                        }
                        scale: emptyMa.pressed ? 0.93 : (emptyMa.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "+"; color: "white"; font.pixelSize: 18; font.weight: Font.Light }
                            Text { text: "Nuevo Frame"; color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                        MouseArea { id: emptyMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame() }
                    }
                }

                // ── FRAME STRIP AREA ──
                Item {
                    anchors.fill: parent
                    visible: root.frameCount > 0
                    clip: true

                    // ── TIMELINE NAVIGATION ──────────────────
                    // Ctrl + rueda = zoom temporal anclado al cursor;
                    // el desplazamiento lateral lo da el Flickable.
                    WheelHandler {
                        id: stWheelZoom
                        acceptedModifiers: Qt.ControlModifier
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        target: null
                        onWheel: function(event) {
                            var oldW = root.cellW
                            var factor = event.angleDelta.y > 0 ? 1.15 : 1 / 1.15
                            var newW = Math.max(24, Math.min(96, oldW * factor))
                            if (Math.abs(newW - oldW) < 0.01) return
                            var localX = stWheelZoom.point.position.x - root.trackLabelW
                            var contentPx = gridFlick.contentX + localX
                            var slotUnder = Math.max(0, contentPx / (oldW + root.cellGap))
                            root.cellW = newW
                            gridFlick.contentX = Math.max(0,
                                slotUnder * (newW + root.cellGap) - localX)
                        }
                    }

                    // Pinch-to-zoom (Android / pantallas táctiles)
                    PinchHandler {
                        id: stPinchZoom
                        target: null
                        minimumPointCount: 2
                        property real startW: 52
                        onActiveChanged: if (active) startW = root.cellW
                        onActiveScaleChanged: {
                            if (!active) return
                            root.cellW = Math.max(24, Math.min(96, startW * activeScale))
                        }
                    }

                    // ── Track label ──
                    Rectangle {
                        id: trackHeader
                        width: root.trackLabelW; height: parent.height; z: 5
                        color: "#0e0e12"
                        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Qt.rgba(1,1,1,0.04) }

                        Column {
                            anchors.fill: parent; spacing: 0

                            // Ruler spacer
                            Rectangle {
                                width: parent.width; height: root.rulerH
                                color: "#111116"
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }
                                Text { text: "FRAMES"; color: "#3a3a44"; font.pixelSize: 7; font.weight: Font.Bold
                                    font.letterSpacing: 1; anchors.centerIn: parent }
                            }

                            // ── Camera track label (dedicated track) ──
                            Item {
                                visible: root.camera !== null
                                width: parent.width; height: root.camTrackH + 4

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: 2; anchors.bottomMargin: 2
                                    anchors.leftMargin: 4; anchors.rightMargin: 4
                                    radius: 6
                                    color: root.camera && root.camera.active ? "#101c26" : "#111116"
                                    border.color: root.camera && root.camera.active
                                        ? Qt.rgba(0.13, 0.83, 0.93, 0.45)
                                        : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                    Behavior on border.color { ColorAnimation { duration: 180 } }

                                    Row {
                                        anchors.centerIn: parent; spacing: 4
                                        Image {
                                            source: "image://icons/camera-01"
                                            width: 11; height: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                            smooth: true; mipmap: true
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                colorizationColor: root.camera && root.camera.active ? "#67e8f9" : "#888"
                                                colorization: 1.0
                                            }
                                        }
                                        Text {
                                            text: "Cámara"
                                            color: root.camera && root.camera.active ? "#67e8f9" : "#888"
                                            font.pixelSize: 9; font.weight: Font.DemiBold
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                    MouseArea {
                                        id: camLabelMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root.camera) return
                                            root.camera.active = !root.camera.active
                                            root.camera.notify(root.camera.active
                                                ? "Modo cámara activado" : "Modo cámara desactivado", "info")
                                        }
                                    }
                                    ToolTip.visible: camLabelMa.containsMouse
                                    ToolTip.text: root.camera && root.camera.active
                                        ? "Desactivar la cámara" : "Activar la cámara"
                                    ToolTip.delay: 450
                                }
                            }

                            // Track row label
                            Rectangle {
                                width: parent.width; height: root.cellH + 4
                                color: "#111116"
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.03) }

                                Row {
                                    anchors.centerIn: parent; spacing: 5
                                    Rectangle { width: 6; height: 6; radius: 3; color: root.accentColor
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "Track 1"; color: "#bbb"; font.pixelSize: 10; font.weight: Font.DemiBold
                                        anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }

                    // ── Scrollable frame grid ──
                    Flickable {
                        id: gridFlick
                        anchors.left: trackHeader.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        contentWidth: Math.max(width, (root.totalSlots() + 3) * root.cellStep + 20)
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        function scrollToCurrent() {
                            var slotX = root.getSlotOffset(root.currentFrameIdx) * root.cellStep
                            var targetX = slotX - (width / 2 - root.cellW / 2)
                            contentX = Math.max(0, Math.min(targetX, Math.max(0, contentWidth - width)))
                        }
                        Connections {
                            target: root
                            function onCurrentFrameIdxChanged() { gridFlick.scrollToCurrent() }
                        }

                        Item {
                            width: gridFlick.contentWidth
                            height: gridFlick.height

                            // ── Ruler ──
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

                                        Rectangle {
                                            width: 1
                                            height: index < root.totalSlots() ? (parent.inCurrent ? 10 : 6) : 4
                                            color: index < root.totalSlots()
                                                ? (parent.inCurrent ? root.accentColor : "#333")
                                                : "#1e1e24"
                                            anchors.bottom: parent.bottom
                                        }
                                        Text {
                                            visible: index < root.totalSlots() && (index % 5 === 0 || index === 0 || root.totalSlots() <= 24)
                                            text: (index + 1)
                                            color: parent.inCurrent ? "#ddd" : "#444"
                                            font.pixelSize: 7; font.family: "Consolas"
                                            font.weight: parent.inCurrent ? Font.Bold : Font.Normal
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.top; anchors.topMargin: 1
                                        }
                                    }
                                }

                                // Ruler scrub
                                MouseArea {
                                    anchors.fill: parent; z: 2
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: function(m) { root.isScrubbing = true; seekFromPx(m.x) }
                                    onPositionChanged: function(m) { if (pressed) seekFromPx(m.x) }
                                    onReleased: { root.isScrubbing = false }
                                    onCanceled: { root.isScrubbing = false }
                                    function seekFromPx(px) {
                                        var slot = Math.floor(px / root.cellStep)
                                        var acc = 0
                                        for (var i = 0; i < root.frameCount; i++) {
                                            var d = root.getFrameDuration(i)
                                            if (slot < acc + d) { root.goToFrame(i); return }
                                            acc += d
                                        }
                                        root.goToFrame(Math.max(0, root.frameCount - 1))
                                    }
                                }

                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.04) }
                            }

                            // ── CAMERA TRACK RAIL (dedicated track) ──
                            Item {
                                id: camRail
                                visible: root.camera !== null
                                y: root.rulerH + 2
                                width: parent.width
                                height: root.camTrackH
                                z: 6

                                // Studio-grey rail
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: 2; anchors.bottomMargin: 2
                                    radius: 5
                                    color: root.camera && root.camera.active ? "#0c2230" : "#101014"
                                    border.color: root.camera && root.camera.active
                                        ? Qt.rgba(0.13, 0.83, 0.93, 0.30)
                                        : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 4; width: parent.width - 8; height: 1
                                    color: root.camera && root.camera.active
                                        ? Qt.rgba(0.13, 0.83, 0.93, 0.40)
                                        : Qt.rgba(1, 1, 1, 0.10)
                                }

                                // Click on the rail = add / update keyframe at slot;
                                // right-click removes the keyframe (if any).
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: function(m) {
                                        if (!root.camera || !root.sharedBar) return
                                        var slot = Math.max(0, Math.floor(m.x / root.cellStep))
                                        var targetFrame = root.slotToFrame(slot)
                                        if (m.button === Qt.RightButton) {
                                            if (root.camera.hasKeyframeAt(targetFrame)) {
                                                root.camera.removeKeyframeAt(targetFrame)
                                                root.camera.notify("Keyframe eliminado", "info")
                                            }
                                        } else {
                                            root.goToFrame(targetFrame)
                                            root.camera.addKeyframe()
                                            root.camera.notify(
                                                "Keyframe añadido en frame " + (targetFrame + 1), "success")
                                        }
                                    }
                                }

                                // Keyframe diamonds — selectable, draggable,
                                // context menu (right-click / long-press)
                                Repeater {
                                    model: root.camera ? root.camera.keyframes : []
                                    delegate: Item {
                                        id: stKfItem
                                        property var kf: (root.camera && modelData)
                                            ? modelData
                                            : ({ frameIdx: 0, x: 0, y: 0, zoom: 1 })
                                        property bool isSelected: root.camera && root.camera.selectedFrameIdx === kf.frameIdx
                                        property bool isCurrent:  kf.frameIdx === root.currentFrameIdx
                                        property bool isDragging: stKfMa.pressed && stKfMa.moved
                                        property int  shownFrame: isDragging ? stKfMa.dragTargetFrame : kf.frameIdx
                                        property real slotX: root.getSlotOffset(shownFrame) * root.cellStep + root.cellW / 2
                                        x: slotX - 10
                                        width: 20; height: parent.height
                                        z: isDragging ? 10 : (isSelected ? 5 : 0)

                                        Behavior on x { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }

                                        // Selection halo
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 15; height: 15; rotation: 45
                                            radius: 3
                                            visible: stKfItem.isSelected || stKfItem.isDragging
                                            color: "transparent"
                                            border.color: "#818cf8"
                                            border.width: 1.5
                                            opacity: 0.9
                                        }

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 9; height: 9; rotation: 45
                                            radius: 1.5
                                            scale: stKfItem.isDragging ? 1.25 : (stKfMa.containsMouse ? 1.12 : 1.0)
                                            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
                                            color: {
                                                if (stKfItem.isSelected || stKfItem.isDragging)
                                                    return "#818cf8"
                                                if (stKfItem.isCurrent)
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
                                            id: stKfMa
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: stKfItem.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                            preventStealing: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                                            property real pressX: 0
                                            property bool moved: false
                                            property bool menuOpened: false
                                            property int  dragTargetFrame: stKfItem.kf.frameIdx

                                            onPressed: function(m) {
                                                pressX = mapToItem(camRail, m.x, m.y).x
                                                moved = false
                                                menuOpened = false
                                                dragTargetFrame = stKfItem.kf.frameIdx
                                                if (root.camera) root.camera.selectedFrameIdx = stKfItem.kf.frameIdx
                                            }
                                            onPositionChanged: function(m) {
                                                if (!pressed) return
                                                var gx = mapToItem(camRail, m.x, m.y).x
                                                if (!moved && Math.abs(gx - pressX) < 5) return
                                                moved = true
                                                var slot = Math.max(0, Math.round(gx / root.cellStep - 0.5))
                                                dragTargetFrame = root.slotToFrame(slot)
                                            }
                                            onPressAndHold: function(m) {
                                                if (moved || menuOpened) return
                                                menuOpened = true
                                                var gp = mapToItem(root, m.x, m.y)
                                                stCamKfMenu.openFor(stKfItem.kf.frameIdx, gp.x, gp.y)
                                            }
                                            onReleased: function(m) {
                                                if (menuOpened) return
                                                if (m.button === Qt.RightButton) {
                                                    var gp = mapToItem(root, m.x, m.y)
                                                    stCamKfMenu.openFor(stKfItem.kf.frameIdx, gp.x, gp.y)
                                                    return
                                                }
                                                if (moved) {
                                                    if (dragTargetFrame !== stKfItem.kf.frameIdx && root.camera) {
                                                        if (root.camera.moveKeyframe(stKfItem.kf.frameIdx, dragTargetFrame)) {
                                                            root.goToFrame(dragTargetFrame)
                                                            root.camera.notify(
                                                                "Keyframe movido a frame " + (dragTargetFrame + 1),
                                                                "success")
                                                        }
                                                    }
                                                } else {
                                                    root.goToFrame(stKfItem.kf.frameIdx)
                                                }
                                            }
                                        }

                                        ToolTip.visible: stKfMa.containsMouse && !stKfItem.isDragging
                                        ToolTip.text: "Frame " + (kf.frameIdx + 1)
                                            + "  •  X " + Math.round(kf.x)
                                            + "  Y " + Math.round(kf.y)
                                            + "  •  Z " + Math.round(kf.zoom * 100) + "%"
                                            + "  •  " + root.easingLabel(kf.easing !== undefined ? kf.easing : "linear")
                                        ToolTip.delay: 350
                                    }
                                }
                            }

                            // ── Frame cells ──
                            Item {
                                id: cellsRow
                                y: root.rulerH + 2 + (root.camera !== null ? root.camTrackH + 2 : 0)
                                width: parent.width
                                height: parent.height - y

                                // Grid background lines
                                Repeater {
                                    model: root.totalSlots() + 5
                                    Rectangle {
                                        x: index * root.cellStep; width: 1; height: cellsRow.height
                                        color: "#1a1a20"; opacity: 0.5
                                    }
                                }

                                // ── Frame cells ──
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

                                        x: slotOff * root.cellStep + 1
                                        y: 1
                                        width: dur * root.cellStep - root.cellGap
                                        height: cellsRow.height - 2
                                        radius: 8

                                        Behavior on width {
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
                                            anchors.fill: parent; anchors.margins: 3
                                            radius: 5; z: 0; clip: true
                                            color: {
                                                if (root.targetCanvas && root.targetCanvas.layerModel && root.targetCanvas.layerModel.length > 0) {
                                                    var bg = root.targetCanvas.layerModel[0]
                                                    if (bg && bg.bgColor) return bg.bgColor
                                                }
                                                return "#ffffff"
                                            }
                                            opacity: fCell.isCur ? 1.0 : 0.5

                                            Image {
                                                anchors.fill: parent; anchors.margins: 1
                                                fillMode: Image.PreserveAspectFit; cache: false
                                                source: {
                                                    if (!root.sharedBar || fi >= root.sharedBar.frameModel.count) return ""
                                                    var item = root.sharedBar.frameModel.get(fi)
                                                    return item && item.thumbnail ? item.thumbnail : ""
                                                }
                                                visible: status === Image.Ready
                                            }

                                            // Frame number + duration
                                            Text {
                                                anchors.centerIn: parent
                                                text: fCell.dur > 1 ? (fCell.fi + 1) + "×" + fCell.dur : (fCell.fi + 1)
                                                color: fCell.isCur ? "#ccc" : "#999"
                                                font.pixelSize: root.cellW > 30 ? 9 : 7
                                                font.family: "Consolas"
                                                font.weight: fCell.isCur ? Font.Bold : Font.Normal
                                                opacity: 0.45; z: 2
                                            }
                                        }

                                        // Slot division marks
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
                                            width: Math.min(parent.width - 6, 14); height: 2.5; radius: 1.25
                                            color: root.accentColor; z: 5
                                        }

                                        // ── Stretch handle (right edge) ──
                                        Rectangle {
                                            width: 8; height: parent.height - 6
                                            anchors.right: parent.right; anchors.rightMargin: 1
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 4; z: 15
                                            color: extMa.containsMouse || extMa.pressed
                                                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                                                : "transparent"
                                            Behavior on color { ColorAnimation { duration: 100 } }

                                            Column {
                                                anchors.centerIn: parent; spacing: 2
                                                Repeater { model: 3; Rectangle { width: 2; height: 2; radius: 1
                                                    color: extMa.containsMouse || extMa.pressed ? root.accentColor : "#444" } }
                                            }

                                            MouseArea {
                                                id: extMa; anchors.fill: parent
                                                cursorShape: Qt.SizeHorCursor; hoverEnabled: true
                                                preventStealing: true
                                                property real startX: 0; property int startDur: 1

                                                onPressed: function(m) {
                                                    startX = mapToItem(cellsRow, m.x, 0).x
                                                    startDur = fCell.dur
                                                    root.goToFrame(fCell.fi)
                                                }
                                                onPositionChanged: function(m) {
                                                    if (!pressed) return
                                                    var cur = mapToItem(cellsRow, m.x, 0).x
                                                    var dx = cur - startX
                                                    var newDur = Math.max(1, Math.min(12, Math.round((startDur * root.cellStep + dx) / root.cellStep)))
                                                    if (newDur !== fCell.dur) root.setFrameDuration(fCell.fi, newDur)
                                                }
                                            }
                                            ToolTip.visible: extMa.containsMouse && !extMa.pressed
                                            ToolTip.text: "⟷ Estirar duración"; ToolTip.delay: 300
                                        }

                                        // Main click
                                        MouseArea {
                                            id: cellMa
                                            anchors.fill: parent; anchors.rightMargin: 10
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: function(m) {
                                                if (m.button === Qt.RightButton) {
                                                    ctxMenu.frameIdx = fCell.fi
                                                    var gp = mapToItem(root, m.x, m.y)
                                                    ctxMenu.popup(gp.x, gp.y)
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
                                    y: 1; width: root.cellW; height: cellsRow.height - 2
                                    radius: 8
                                    color: addCellMa.containsMouse ? "#1a1a24" : "transparent"
                                    border.color: addCellMa.containsMouse ? "#333" : "#1e1e24"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text {
                                        anchors.centerIn: parent; text: "+"
                                        color: addCellMa.containsMouse ? "#888" : "#2a2a30"
                                        font.pixelSize: 16; font.weight: Font.Light
                                    }
                                    MouseArea {
                                        id: addCellMa; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame()
                                    }
                                }

                                // Click empty = seek
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

                            // ── Scrubbing Guideline ──
                            Rectangle {
                                id: scrubbingGuideline
                                visible: root.isScrubbing
                                x: (root.getSlotOffset(root.currentFrameIdx) * root.cellStep)
                                width: root.getFrameDuration(root.currentFrameIdx) * root.cellStep - root.cellGap
                                y: cellsRow.y
                                height: cellsRow.height
                                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08)
                                border.color: root.accentColor
                                border.width: 1
                                z: 18
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            }

                            // ── Playhead line ──
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

                                // Top diamond
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

            // ── 4. STATUS BAR ──
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 22; color: "#09090c"
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.03) }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                    Text {
                        text: root.frameCount > 0
                            ? "Frame " + (root.currentFrameIdx + 1) + " / " + root.frameCount
                              + "  •  " + (root.currentFrameIdx / Math.max(1, root.fps)).toFixed(2) + "s"
                              + "  •  " + root.fps + " fps"
                            : "Sin animación"
                        color: "#333"; font.pixelSize: 8; font.family: "Consolas"
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        visible: root.onionEnabled
                        spacing: 3
                        Image {
                            source: "image://icons/onion"
                            width: 10; height: 10
                            anchors.verticalCenter: parent.verticalCenter
                            smooth: true; mipmap: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorizationColor: "#f0d060"
                                colorization: 1.0
                            }
                        }
                        Text {
                            text: root.onionBefore + "/" + root.onionAfter
                            color: "#f0d060"; font.pixelSize: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // ── Context Menu ─────────────────────────────────────────
    // Dismiss overlay
    MouseArea {
        id: ctxDismiss; anchors.fill: parent; z: 9998
        visible: ctxMenu.visible || fpsPopup.visible
        onClicked: {
            ctxMenu.dismiss()
            fpsPopup.visible = false
        }
    }

    // ── FPS POPUP ──────────────────────────────────────────
    Rectangle {
        id: fpsPopup
        visible: false
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        anchors.top: parent.top; anchors.topMargin: 40
        x: {
            if (fpsPillContainer) {
                var pos = fpsPillContainer.mapToItem(root, 0, 0)
                return Math.max(12, Math.min(root.width - width - 12, pos.x + (fpsPillContainer.width - width) / 2))
            }
            return root.width - width - 12
        }
        width: 320; height: 48; radius: 24
        color: "#14141a"; border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35); border.width: 1.5
        z: 9999

        // Shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -4
            z: -1; radius: parent.radius + 4
            color: "#000000"; opacity: 0.5
        }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10

            Image {
                source: "image://icons/sliders"
                width: 16; height: 16
                Layout.alignment: Qt.AlignVCenter
                smooth: true; mipmap: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorizationColor: root.accentColor
                    colorization: 1.0
                }
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
                        if (sharedBar) sharedBar.fps = val
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
                            onClicked: if (sharedBar) sharedBar.fps = modelData
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: ctxMenu
        property int frameIdx: 0
        property real popX: 0; property real popY: 0
        visible: false

        x: Math.min(popX, root.width - width - 12)
        y: Math.max(8, Math.min(popY - height - 4, root.height - height - 8))
        width: 200; radius: 14; z: 9999
        height: ctxCol.implicitHeight + 18
        color: "#1c1c24"; border.color: Qt.rgba(1,1,1,0.10); border.width: 1

        Rectangle { anchors.fill: parent; anchors.margins: -6; z: -1; radius: parent.radius + 6; color: "#000"; opacity: 0.4 }

        opacity: visible ? 1.0 : 0.0; scale: visible ? 1.0 : 0.92
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        function popup(mx, my) { popX = mx; popY = my; visible = true }
        function dismiss()     { visible = false }

        Column {
            id: ctxCol
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top; anchors.topMargin: 9
            anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 2

            // Header
            Item {
                width: parent.width; height: 24
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10; spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: 6; height: 6; radius: 3; color: root.accentColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Frame " + (ctxMenu.frameIdx + 1); color: "#999"; font.pixelSize: 10; font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "·  " + root.getFrameDuration(ctxMenu.frameIdx) + "f"; color: "#555"; font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.horizontalCenter: parent.horizontalCenter }

            CtxBtn { iconSource: "image://icons/duplicate_outline"; label: "Duplicar frame"; iconColor: "#7aa2f7"
                onClicked: { root.goToFrame(ctxMenu.frameIdx); root.duplicateFrame(); ctxMenu.dismiss() } }
            CtxBtn { iconSource: "image://icons/eraser"; label: "Limpiar contenido"; iconColor: "#e0af68"
                onClicked: {
                    if (root.sharedBar) {
                        var item = root.sharedBar.frameModel.get(ctxMenu.frameIdx)
                        if (item && item.layerName && root.targetCanvas) {
                            var ri = root.sharedBar.findLayerIndexByName(item.layerName)
                            if (ri >= 0) root.targetCanvas.clearLayer(ri)
                        }
                    }
                    ctxMenu.dismiss()
                }
            }

            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.horizontalCenter: parent.horizontalCenter }

            // Duration controls
            Item {
                width: parent.width; height: 32
                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10; spacing: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "⟷"; font.pixelSize: 13; color: "#9ece6a"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Duración"; color: "#aaa"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter; spacing: 0
                    Rectangle {
                        width: 24; height: 22; radius: 6
                        color: durMinMa.containsMouse ? "#2a2a36" : "#1e1e28"
                        Text { text: "−"; anchors.centerIn: parent; color: "#aaa"; font.pixelSize: 14 }
                        MouseArea { id: durMinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.setFrameDuration(ctxMenu.frameIdx, root.getFrameDuration(ctxMenu.frameIdx) - 1) }
                    }
                    Rectangle {
                        width: 28; height: 22; color: "#12121a"; border.color: "#2a2a32"; border.width: 1
                        Text { anchors.centerIn: parent; text: root.getFrameDuration(ctxMenu.frameIdx)
                            color: root.accentColor; font.pixelSize: 11; font.weight: Font.Bold; font.family: "Consolas" }
                    }
                    Rectangle {
                        width: 24; height: 22; radius: 6
                        color: durPlsMa.containsMouse ? "#2a2a36" : "#1e1e28"
                        Text { text: "+"; anchors.centerIn: parent; color: "#aaa"; font.pixelSize: 14 }
                        MouseArea { id: durPlsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.setFrameDuration(ctxMenu.frameIdx, root.getFrameDuration(ctxMenu.frameIdx) + 1) }
                    }
                }
            }

            Rectangle { width: parent.width - 16; height: 1; color: Qt.rgba(1,1,1,0.06); anchors.horizontalCenter: parent.horizontalCenter }

            CtxBtn { iconSource: "image://icons/trash"; label: "Eliminar frame"; iconColor: "#f7768e"; labelColor: "#f7768e"; hoverBg: "#2d1a1f"
                enabled: root.frameCount > 1
                onClicked: { root.goToFrame(ctxMenu.frameIdx); root.deleteCurrentFrame(); ctxMenu.dismiss() } }

            Item { width: 1; height: 3 }
        }
    }

    // ── CAMERA KEYFRAME CONTEXT MENU ─────────────────────────
    Popup {
        id: stCamKfMenu
        property int frameIdx: -1
        width: 216
        padding: 6
        z: 10000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        function openFor(fi, px, py) {
            frameIdx = fi
            x = Math.max(6, Math.min(root.width - width - 6, px - width / 2))
            y = Math.max(6, Math.min(root.height - implicitHeight - 6, py + 8))
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

            Row {
                spacing: 6
                leftPadding: 8
                topPadding: 2
                bottomPadding: 4
                Rectangle { width: 8; height: 8; rotation: 45; radius: 1.5
                    color: "#818cf8"; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Cámara · Frame " + (stCamKfMenu.frameIdx + 1)
                    color: "#a1a1aa"; font.pixelSize: 10; font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: parent.width - 10; height: 1
                color: Qt.rgba(1,1,1,0.07); anchors.horizontalCenter: parent.horizontalCenter }

            StCamMenuBtn {
                iconSource: "image://icons/duplicate_outline"; label: "Duplicar keyframe"
                onTriggered: {
                    if (!root.camera) return
                    var dst = root.camera.duplicateKeyframe(stCamKfMenu.frameIdx)
                    if (dst >= 0)
                        root.camera.notify("Keyframe duplicado en frame " + (dst + 1), "success")
                    else
                        root.camera.notify("No hay un frame libre para duplicar", "warning")
                }
            }
            StCamMenuBtn {
                iconSource: "image://icons/trash"; label: "Eliminar keyframe"; destructive: true
                onTriggered: {
                    if (!root.camera) return
                    root.camera.removeKeyframeAt(stCamKfMenu.frameIdx)
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
                StCamMenuBtn {
                    required property var modelData
                    iconSource: stCamKfMenu.kfEasing() === modelData.key ? "image://icons/check" : ""
                    label: modelData.label
                    checked: stCamKfMenu.kfEasing() === modelData.key
                    onTriggered: {
                        if (!root.camera) return
                        root.camera.setKeyframeEasing(stCamKfMenu.frameIdx, modelData.key)
                        root.camera.notify("Interpolación: " + modelData.label, "info")
                    }
                }
            }
        }
    }

    component StCamMenuBtn : Rectangle {
        id: scmb
        property string icon: ""
        property string iconSource: ""
        property string label: ""
        property bool destructive: false
        property bool checked: false
        signal triggered()
        width: parent ? parent.width : 200
        height: 28; radius: 7
        color: scmbMa.containsMouse
            ? (destructive ? "#2d1619" : "#222230")
            : (checked ? Qt.rgba(0.51, 0.55, 0.97, 0.10) : "transparent")
        Behavior on color { ColorAnimation { duration: 90 } }
        Row {
            anchors.left: parent.left; anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Item {
                width: 14; height: 14
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    visible: scmb.iconSource === ""
                    text: scmb.icon; anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: scmb.destructive ? "#f87171" : (scmb.checked ? "#818cf8" : "#9ca3af")
                    font.pixelSize: 11
                }
                Image {
                    visible: scmb.iconSource !== ""
                    source: scmb.iconSource
                    width: 12; height: 12; anchors.centerIn: parent
                    smooth: true; mipmap: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorizationColor: scmb.destructive ? "#f87171" : (scmb.checked ? "#818cf8" : "#9ca3af")
                        colorization: 1.0
                    }
                }
            }
            Text { text: scmb.label
                color: scmb.destructive ? "#f87171" : (scmb.checked ? "#c7d2fe" : "#d4d4d8")
                font.pixelSize: 11; font.weight: scmb.checked ? Font.DemiBold : Font.Medium
                anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea {
            id: scmbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { scmb.triggered(); stCamKfMenu.close() }
        }
    }

    // ── Reusable components ──────────────────────────────────
    component TLPill : Rectangle {
        id: pb
        property string icon: ""
        property string iconSource: ""
        property bool highlighted: false
        property color highlightCol: root.accentColor
        signal clicked()

        width: 26; height: 26; radius: 8
        color: highlighted ? Qt.rgba(highlightCol.r, highlightCol.g, highlightCol.b, 0.12)
                           : (pbMa.containsMouse ? "#1a1a22" : "transparent")
        opacity: enabled ? 1.0 : 0.3
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            visible: pb.iconSource === ""
            text: pb.icon
            color: highlighted ? highlightCol : (pbMa.containsMouse ? "#bbb" : "#666")
            font.pixelSize: 12; anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Image {
            visible: pb.iconSource !== ""
            source: pb.iconSource
            width: 14; height: 14; anchors.centerIn: parent
            smooth: true; mipmap: true
            opacity: pb.enabled ? 1.0 : 0.5
            layer.enabled: true
            layer.effect: MultiEffect {
                colorizationColor: highlighted ? highlightCol : (pbMa.containsMouse ? "#ffffff" : "#71717a")
                colorization: 1.0
            }
        }

        MouseArea { id: pbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: if (pb.enabled) pb.clicked() }
    }

    component TLStepper : Row {
        id: stp
        property int value: 2; property color accent: root.accentColor
        signal dec(); signal inc(); spacing: 2
        Rectangle { width: 18; height: 18; radius: 5; color: stMa1.containsMouse ? "#333" : "#222"
            Text { text: "−"; color: "#aaa"; font.pixelSize: 11; anchors.centerIn: parent }
            MouseArea { id: stMa1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: stp.dec() } }
        Rectangle { width: 22; height: 18; radius: 5; color: "#151518"
            Text { text: stp.value; color: stp.accent; font.pixelSize: 10; font.bold: true; anchors.centerIn: parent } }
        Rectangle { width: 18; height: 18; radius: 5; color: stMa2.containsMouse ? "#333" : "#222"
            Text { text: "+"; color: "#aaa"; font.pixelSize: 11; anchors.centerIn: parent }
            MouseArea { id: stMa2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: stp.inc() } }
    }

    component CtxBtn : Rectangle {
        id: ctxb
        property string icon: ""
        property string iconSource: ""
        property string label: ""
        property color iconColor: "#888"
        property color labelColor: "#ddd"
        property color hoverBg: "#252530"
        signal clicked()
        width: parent ? parent.width : 180; height: 30; radius: 8
        color: ctxbMa.containsMouse ? hoverBg : "transparent"
        opacity: enabled ? 1.0 : 0.35
        Behavior on color { ColorAnimation { duration: 80 } }

        Rectangle { width: 3; height: parent.height - 8; radius: 1.5
            anchors.left: parent.left; anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter
            color: ctxb.iconColor; opacity: ctxbMa.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } } }

        Row { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
            Text {
                visible: ctxb.iconSource === ""
                text: ctxb.icon; font.pixelSize: 13; width: 18; anchors.verticalCenter: parent.verticalCenter
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
            Text { text: ctxb.label; color: ctxb.labelColor; font.pixelSize: 11; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter } }

        MouseArea { id: ctxbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (ctxb.enabled) ctxb.clicked() }
    }
}
