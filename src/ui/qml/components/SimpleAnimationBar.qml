import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ══════════════════════════════════════════════════════════════
//  SIMPLE ANIMATION BAR  —  Flipbook-style floating timeline
//  Real frame model: empty on start. Add frames one by one.
// ══════════════════════════════════════════════════════════════
Item {
    id: root

    // ── Public API ──────────────────────────────────────────
    property var    targetCanvas:   null
    property color  accentColor:    "#6366f1"
    property int    projectFPS:     12
    property int    projectFrames:  48   // max frames if needed
    property bool   projectLoop:    true

    // ── Real Frame Model ─────────────────────────────────────
    // Each entry: { thumbnail: "" }
    ListModel { id: frameModel }

    property int frameCount: frameModel.count

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

    // Derived
    property real currentTimeSec: currentFrameIdx / Math.max(1, fps)

    // ── Playback Timer ───────────────────────────────────────
    Timer {
        id: playTimer
        interval: Math.round(1000 / Math.max(1, root.fps))
        repeat: true
        running: root.isPlaying && root.frameCount > 1
        onTriggered: {
            var next = root.currentFrameIdx + 1
            if (next >= root.frameCount) {
                if (root.loopEnabled) next = 0
                else { root.isPlaying = false; return }
            }
            root.goToFrame(next)
        }
    }

    // ── Frame Navigation & Creation ─────────────────────────
    function goToFrame(idx) {
        if (idx < 0 || idx >= frameCount) return
        currentFrameIdx = idx
        // TODO: targetCanvas.gotoFrame(idx)
    }

    function addFrame() {
        frameModel.append({ thumbnail: "" })
        goToFrame(frameModel.count - 1)
        // TODO: canvas.clearForNewFrame()  unless onionEnabled
    }

    // ── Entry Animation ──────────────────────────────────────
    property bool _ready: false
    Component.onCompleted: Qt.callLater(function() { root._ready = true })
    opacity: _ready ? 1.0 : 0.0
    y:      _ready ? 0   : 60
    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    Behavior on y       { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    // ════════════════════════════════════════════════════════
    //  FLOATING PILL
    // ════════════════════════════════════════════════════════
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10

        width:  Math.min(900, Math.max(440, parent.width * 0.74))
        height: root.frameCount === 0 ? 56 : 96
        radius: 22
        color:        "#111114"
        border.color: "#2a2a30"
        border.width: 1

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // ── TOP CONTROL ROW ───────────────────────────────
        RowLayout {
            id: controlsRow
            anchors.top: parent.top
            anchors.left: parent.left; anchors.right: parent.right
            anchors.topMargin: 13
            anchors.leftMargin: 16; anchors.rightMargin: 14
            height: 30
            spacing: 6

            // ── PLAY BUTTON ─────────────────────────────────
            Rectangle {
                width: 72; height: 28; radius: 14
                color: root.isPlaying
                       ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                       : (playMa.containsMouse ? "#2a2a30" : "#1c1c22")
                border.color: root.isPlaying ? root.accentColor : "#333"; border.width: 1
                opacity: root.frameCount > 1 ? 1.0 : 0.4
                Behavior on color { ColorAnimation { duration: 140 } }

                Row { anchors.centerIn: parent; spacing: 6
                    Text { text: root.isPlaying ? "⏸" : "▶"; color: root.isPlaying ? root.accentColor : "#ddd"; font.pixelSize: 13; font.bold: true }
                    Text { text: root.isPlaying ? "Pause" : "Play"; color: root.isPlaying ? root.accentColor : "#aaa"; font.pixelSize: 11; font.weight: Font.Medium }
                }
                MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.frameCount > 1) root.isPlaying = !root.isPlaying }
            }

            // Frame counter
            Rectangle {
                width: 72; height: 24; radius: 6
                color: "#0d0d10"; border.color: "#222"
                Text {
                    anchors.centerIn: parent
                    text: root.frameCount === 0 ? "—" : (root.currentFrameIdx + 1) + " / " + root.frameCount
                    color: root.frameCount === 0 ? "#333" : "#888"
                    font.pixelSize: 10; font.family: "Monospace"
                }
            }

            // Time
            Text {
                text: {
                    if (root.frameCount === 0) return "0.0s"
                    var s = root.currentTimeSec
                    var m = Math.floor(s / 60)
                    var sec = (s % 60).toFixed(1)
                    return (m > 0 ? m + ":" : "") + sec + "s"
                }
                color: "#555"; font.pixelSize: 10; font.family: "Monospace"
            }

            Item { Layout.fillWidth: true }

            // ── RIGHT BUTTONS ───────────────────────────────
            Row {
                spacing: 4

                // Onion Skin
                BarBtn { icon: "🧅"; active: root.onionEnabled; activeCol: "#f0d060"; tip: "Onion Skin"
                    visible: root.frameCount > 1; onToggled: root.onionEnabled = !root.onionEnabled }
                // Loop
                BarBtn { icon: "🔁"; active: root.loopEnabled; activeCol: root.accentColor; tip: "Loop"
                    onToggled: root.loopEnabled = !root.loopEnabled }
                // Light table
                BarBtn { icon: "💡"; active: root.lightTable; activeCol: "#60c0ff"; tip: "Mesa de Luz"
                    visible: root.frameCount > 1; onToggled: root.lightTable = !root.lightTable }

                // Switch to Advanced Mode
                BarBtn { 
                    icon: "🎞️"; active: true; activeCol: "#6366f1"; tip: "Cambiar a Modo Avanzado"
                    visible: true
                    onToggled: {
                        if (typeof mainWindow !== "undefined") {
                            mainWindow.useAdvancedTimeline = true;
                        }
                    }
                }

                // Separator
                Rectangle { width: 1; height: 18; color: "#333"; anchors.verticalCenter: parent.verticalCenter }

                // ── NEW FRAME BUTTON ──────────────────────────
                Rectangle {
                    width: root.frameCount === 0 ? 120 : 34; height: 28; radius: 10
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.accentColor }
                        GradientStop { position: 1.0; color: Qt.lighter(root.accentColor, 1.18) }
                    }
                    scale: nfMa.pressed ? 0.93 : (nfMa.containsMouse ? 1.04 : 1.0)
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                    clip: true

                    Row { anchors.centerIn: parent; spacing: 5
                        Text { text: "+"; color: "white"; font.pixelSize: 16; font.weight: Font.Light }
                        Text { text: root.frameCount === 0 ? "Nuevo Frame" : ""; color: "white"; font.pixelSize: 11; font.weight: Font.DemiBold; visible: root.frameCount === 0 }
                    }
                    MouseArea { id: nfMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame() }
                    ToolTip.visible: nfMa.containsMouse; ToolTip.text: "Nuevo fotograma (vacío)"; ToolTip.delay: 400
                }
            }
        }

        // Thin separator (only when frames exist)
        Rectangle {
            visible: root.frameCount > 0
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: controlsRow.bottom; anchors.topMargin: 6
            anchors.leftMargin: 12; anchors.rightMargin: 12
            height: 1; color: "#1e1e24"
        }

        // ── FRAME THUMBNAIL STRIP ──────────────────────────
        Item {
            id: stripArea
            visible: root.frameCount > 0
            anchors.top: controlsRow.bottom; anchors.topMargin: 10
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12; anchors.rightMargin: 12
            anchors.bottomMargin: 8

            Flickable {
                id: frameFlick
                anchors.fill: parent
                contentWidth: frameRow.width
                clip: true; boundsBehavior: Flickable.StopAtBounds

                function scrollToCurrent() {
                    var cW = 44 + 3
                    var targetX = root.currentFrameIdx * cW - (width/2 - 44/2)
                    contentX = Math.max(0, Math.min(targetX, Math.max(0, contentWidth - width)))
                }
                Connections {
                    target: root
                    function onCurrentFrameIdxChanged() { frameFlick.scrollToCurrent() }
                }

                Row {
                    id: frameRow
                    spacing: 3; height: frameFlick.height

                    Repeater {
                        model: frameModel

                        Rectangle {
                            id: fCell
                            property int   fIdx:      index
                            property bool  isCurrent: fIdx === root.currentFrameIdx
                            property int   dist:      fIdx - root.currentFrameIdx

                            width: 44; height: frameFlick.height; radius: 8

                            color: isCurrent ? "#1a1a2e" : (fCellMa.containsMouse ? "#1c1c24" : "#151518")
                            border.color: isCurrent ? root.accentColor : "#252528"
                            border.width: isCurrent ? 2 : 1

                            Behavior on color        { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }

                            // Onion skin tint
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius; z: 1
                                visible: root.onionEnabled && !fCell.isCurrent &&
                                         ((fCell.dist < 0 && -fCell.dist <= root.onionBefore) ||
                                          (fCell.dist > 0 &&  fCell.dist <= root.onionAfter))
                                color: fCell.dist < 0
                                       ? Qt.rgba(1, 0.2, 0.2, root.onionOpacity * (root.onionBefore + fCell.dist + 1) / (root.onionBefore + 1))
                                       : Qt.rgba(0.2, 0.9, 0.3, root.onionOpacity * (root.onionAfter  - fCell.dist + 1) / (root.onionAfter  + 1))
                            }

                            // Thumbnail or placeholder
                            Item {
                                anchors.fill: parent; anchors.margins: 4; z: 0

                                // Placeholder
                                Column {
                                    anchors.centerIn: parent; spacing: 2; opacity: 0.35
                                    visible: model.thumbnail === ""
                                    Text { text: "🖼"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
                                }

                                // Real thumbnail
                                Image {
                                    anchors.fill: parent; visible: model.thumbnail !== ""
                                    source: model.thumbnail !== "" ? model.thumbnail : ""
                                    fillMode: Image.PreserveAspectFit
                                }
                            }

                            // Frame number badge
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 2
                                width: numTxt.implicitWidth + 6; height: 12; radius: 4; z: 2
                                color: fCell.isCurrent ? root.accentColor : "#1a1a1e"
                                Text {
                                    id: numTxt; text: fCell.fIdx + 1
                                    color: fCell.isCurrent ? "white" : "#555"
                                    font.pixelSize: 7; font.family: "Monospace"
                                    anchors.centerIn: parent
                                }
                            }

                            // Current indicator dot at top
                            Rectangle {
                                visible: fCell.isCurrent
                                anchors.top: parent.top; anchors.topMargin: -1
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 6; height: 3; radius: 1.5; z: 2
                                color: root.accentColor
                            }

                            MouseArea {
                                id: fCellMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.goToFrame(fCell.fIdx)
                            }
                            ToolTip.visible: fCellMa.containsMouse; ToolTip.text: "Frame " + (fIdx + 1); ToolTip.delay: 400
                        }
                    }

                    // ── "+" Add-frame cell at end ──────────────
                    Rectangle {
                        width: 44; height: frameFlick.height; radius: 8
                        color: addCellMa.containsMouse ? "#1a1a24" : "#101014"
                        border.color: addCellMa.containsMouse ? root.accentColor : "#202022"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent; text: "+"
                            color: addCellMa.containsMouse ? root.accentColor : "#333"
                            font.pixelSize: 22; font.weight: Font.Light
                        }
                        MouseArea { id: addCellMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame() }
                        ToolTip.visible: addCellMa.containsMouse; ToolTip.text: "Nuevo fotograma"; ToolTip.delay: 400
                    }
                }
            }
        }

        // ── EMPTY STATE hint ─────────────────────────────────
        Text {
            visible: root.frameCount === 0
            anchors.bottom: parent.bottom; anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Pulsa  + Nuevo Frame  para comenzar tu animación"
            color: "#333"; font.pixelSize: 10; font.italic: true
        }
    }

    // ── ONION POPUP (floats above pill) ─────────────────────
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

            Text { text: "🧅"; font.pixelSize: 14 }
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

    // ── INLINE COMPONENTS ────────────────────────────────────
    component BarBtn : Rectangle {
        id: bb
        property string icon: "?"; property bool active: false; property color activeCol: "#6366f1"
        property string tip: ""; property bool pulse: false
        signal toggled()
        width: 28; height: 28; radius: 7
        color: active ? Qt.rgba(activeCol.r, activeCol.g, activeCol.b, 0.18) : (bMa.containsMouse ? "#252530" : "#1a1a1e")
        border.color: active ? activeCol : "#2a2a30"; border.width: active ? 1.5 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            text: bb.icon; font.pixelSize: 15; anchors.centerIn: parent
            opacity: bb.active ? 1.0 : 0.45
            Behavior on opacity { NumberAnimation { duration: 120 } }
            SequentialAnimation on opacity { running: bb.pulse && bb.active; loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 500 } NumberAnimation { to: 1.0; duration: 500 } }
        }
        MouseArea { id: bMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bb.toggled() }
        ToolTip.visible: bMa.containsMouse; ToolTip.text: bb.tip; ToolTip.delay: 400
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
