import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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
                        TLPill { icon: "⏮"; onClicked: root.goToFrame(0) }
                        TLPill { icon: "◀"; onClicked: root.goToFrame(root.currentFrameIdx - 1) }
                        TLPill {
                            icon: root.isPlaying ? "⏸" : "▶"
                            highlighted: root.isPlaying
                            onClicked: root.togglePlay()
                        }
                        TLPill { icon: "▶"; onClicked: root.goToFrame(root.currentFrameIdx + 1) }
                        TLPill { icon: "⏭"; onClicked: root.goToFrame(root.frameCount - 1) }
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
                    TLPill { icon: "↻"; highlighted: root.loopEnabled; onClicked: root.toggleLoop() }
                    TLPill { icon: "◉"; highlighted: root.onionEnabled; highlightCol: "#f0d060"
                        onClicked: root.toggleOnion() }

                    Rectangle { width: 1; height: 16; color: Qt.rgba(1,1,1,0.06) }

                    // ── FPS pill ──
                    Rectangle {
                        width: fpsTxt.implicitWidth + 14; height: 24; radius: 12
                        color: fpsMa.containsMouse ? "#1a1a20" : "#111116"
                        border.color: Qt.rgba(1,1,1,0.06)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { id: fpsTxt; anchors.centerIn: parent; text: root.fps + " fps"
                            color: "#777"; font.pixelSize: 9 }
                        MouseArea { id: fpsMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: root.cycleFPS() }
                        ToolTip.visible: fpsMa.containsMouse; ToolTip.text: "Cambiar FPS"; ToolTip.delay: 400
                    }

                    Item { Layout.fillWidth: true }

                    // ── Duplicate & Delete ──
                    TLPill { icon: "⧉"; onClicked: root.duplicateFrame(); enabled: root.frameCount > 0 }
                    TLPill { icon: "🗑"; onClicked: root.deleteCurrentFrame(); enabled: root.frameCount > 1 }

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

                    Text { text: "🎞"; font.pixelSize: 42; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.25 }
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
                                    onPressed: function(m) { seekFromPx(m.x) }
                                    onPositionChanged: function(m) { if (pressed) seekFromPx(m.x) }
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

                            // ── Frame cells ──
                            Item {
                                id: cellsRow
                                y: root.rulerH + 2
                                width: parent.width
                                height: parent.height - root.rulerH - 2

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
                    Text { visible: root.onionEnabled
                        text: "🧅 " + root.onionBefore + "/" + root.onionAfter
                        color: "#f0d060"; font.pixelSize: 8 }
                }
            }
        }
    }

    // ── Context Menu ─────────────────────────────────────────
    // Dismiss overlay
    MouseArea {
        id: ctxDismiss; anchors.fill: parent; z: 9998
        visible: ctxMenu.visible; onClicked: ctxMenu.dismiss()
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

            CtxBtn { icon: "📋"; label: "Duplicar frame"; iconColor: "#7aa2f7"
                onClicked: { root.goToFrame(ctxMenu.frameIdx); root.duplicateFrame(); ctxMenu.dismiss() } }
            CtxBtn { icon: "🧹"; label: "Limpiar contenido"; iconColor: "#e0af68"
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

            CtxBtn { icon: "🗑"; label: "Eliminar frame"; iconColor: "#f7768e"; labelColor: "#f7768e"; hoverBg: "#2d1a1f"
                enabled: root.frameCount > 1
                onClicked: { root.goToFrame(ctxMenu.frameIdx); root.deleteCurrentFrame(); ctxMenu.dismiss() } }

            Item { width: 1; height: 3 }
        }
    }

    // ── Reusable components ──────────────────────────────────
    component TLPill : Rectangle {
        id: pb
        property string icon: "?"
        property bool highlighted: false
        property color highlightCol: root.accentColor
        signal clicked()

        width: 26; height: 26; radius: 8
        color: highlighted ? Qt.rgba(highlightCol.r, highlightCol.g, highlightCol.b, 0.12)
                           : (pbMa.containsMouse ? "#1a1a22" : "transparent")
        opacity: enabled ? 1.0 : 0.3
        Behavior on color { ColorAnimation { duration: 120 } }

        Text { text: pb.icon; color: highlighted ? highlightCol : (pbMa.containsMouse ? "#bbb" : "#666")
            font.pixelSize: 12; anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: 120 } } }
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
        property string icon: ""; property string label: ""; property color iconColor: "#888"
        property color labelColor: "#ddd"; property color hoverBg: "#252530"
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
            Text { text: ctxb.icon; font.pixelSize: 13; width: 18; anchors.verticalCenter: parent.verticalCenter }
            Text { text: ctxb.label; color: ctxb.labelColor; font.pixelSize: 11; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter } }

        MouseArea { id: ctxbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (ctxb.enabled) ctxb.clicked() }
    }
}
