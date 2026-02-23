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

    // Canvas background color - mirrors the actual canvas paper color
    property color  canvasBgColor: {
        if (targetCanvas && targetCanvas.layerModel && targetCanvas.layerModel.length > 0) {
            var bg = targetCanvas.layerModel[0]
            if (bg && bg.bgColor) return bg.bgColor
        }
        return "#ffffff"
    }

    // ── Real Frame Model ─────────────────────────────────────
    // Each entry: { thumbnail: "", layerName: "...", duration: 1 }
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

    // Derived
    property real currentTimeSec: currentFrameIdx / Math.max(1, fps)

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
    // Find the raw layer index (for setLayerVisibility, setActiveLayer)
    // by searching the layerModel for a matching name.
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
        
        // C++ LAYER VISIBILITY SYNCHRONIZATION
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

            ListView {
                id: frameList
                anchors.left: parent.left
                anchors.right: addFrameBtn.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 8
                
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                function scrollToCurrent() {
                    positionViewAtIndex(root.currentFrameIdx, ListView.Contain)
                }
                Connections {
                    target: root
                    function onCurrentFrameIdxChanged() { frameList.scrollToCurrent() }
                }

                model: DelegateModel {
                    id: visualModel
                    model: frameModel
                    delegate: DropArea {
                        id: delegateRoot
                        width: fCell.width
                        height: frameList.height
                        
                        keys: ["frame"]

                        onEntered: (drag) => {
                            if (drag.source.visualIndex !== undefined && drag.source.visualIndex !== delegateRoot.visualIndex) {
                                visualModel.items.move(drag.source.visualIndex, delegateRoot.visualIndex)
                                // Keep playhead synced
                                if (root.currentFrameIdx === drag.source.visualIndex) {
                                    root.currentFrameIdx = delegateRoot.visualIndex
                                } else if (root.currentFrameIdx === delegateRoot.visualIndex) {
                                    root.currentFrameIdx = drag.source.visualIndex
                                }
                            }
                        }

                        property int visualIndex: DelegateModel.itemsIndex

                        Rectangle {
                            id: fCell
                            property int   fIdx:      delegateRoot.visualIndex
                            property bool  isCurrent: fIdx === root.currentFrameIdx
                            property int   baseDur:   model.duration !== undefined ? model.duration : 1
                            property int   dist:      fIdx - root.currentFrameIdx

                            function getBaseWidth(dur) { return Math.max(50, 50 * dur + 6 * (dur - 1)) }
                            property real  baseWidth: getBaseWidth(baseDur)
                            property real  dynamicWidth: extMa.pressed ? Math.max(50, baseWidth + dragDummy.x) : baseWidth

                            // Instant local duration calculation to update text without hitting the model
                            property int   visualDur: Math.max(1, Math.round((dynamicWidth + 6) / 56))

                            width: dynamicWidth
                            height: frameList.height
                            radius: 8

                            color: isCurrent ? "#1a1a2e" : (dragMa.containsMouse ? "#1c1c24" : "#151518")
                            border.color: isCurrent ? root.accentColor : "#252528"
                            border.width: isCurrent ? 2 : 1

                            Behavior on color        { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on width { 
                                enabled: !extMa.pressed 
                                NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.8 } 
                            }

                            Drag.active: dragMa.drag.active
                            Drag.source: delegateRoot
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                            Drag.keys: ["frame"]

                            states: [
                                State {
                                    when: dragMa.drag.active
                                    ParentChange { target: fCell; parent: frameList }
                                    AnchorChanges { target: fCell; anchors.verticalCenter: undefined; anchors.horizontalCenter: undefined }
                                    PropertyChanges { target: fCell; opacity: 0.85; scale: 1.05; z: 100 }
                                }
                            ]
                            
                            transitions: [
                                Transition {
                                    ParentAnimation {
                                        NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
                                    }
                                }
                            ]
                            
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

                            // Thumbnail area with canvas bg color
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 3; z: 0
                                radius: 5
                                color: root.canvasBgColor
                                clip: true

                                // Placeholder
                                Column {
                                    anchors.centerIn: parent; spacing: 2; opacity: 0.25
                                    visible: model.thumbnail === ""
                                    Text { text: (fCell.fIdx + 1); font.pixelSize: 14; color: "#888"; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                }

                                // Real thumbnail
                                Image {
                                    anchors.fill: parent; visible: model.thumbnail !== ""
                                    source: model.thumbnail !== "" ? model.thumbnail : ""
                                    fillMode: Image.PreserveAspectFit
                                }

                                // Duration indicator marks (vertical lines for multi-frame)
                                Row {
                                    visible: fCell.dur > 1
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 2
                                    spacing: 6
                                    Repeater {
                                        model: fCell.dur
                                        Rectangle {
                                            width: 2; height: 6; radius: 1
                                            color: index === 0 ? root.accentColor : "#aaa"
                                            opacity: 0.5
                                        }
                                    }
                                }
                            }

                            // Frame number badge
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 4
                                width: numTxt.implicitWidth + 8; height: 14; radius: 6; z: 2
                                color: fCell.isCurrent ? root.accentColor : "#101014"
                                opacity: 0.95
                                Text {
                                    id: numTxt; 
                                    text: fCell.visualDur > 1 ? (fIdx + 1) + " (" + fCell.visualDur + "f)" : (fIdx + 1)
                                    color: fCell.isCurrent ? "white" : "#888"
                                    font.pixelSize: 9; font.family: "Monospace"; font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            // Drag Area for reordering and selection
                            MouseArea {
                                id: dragMa
                                anchors.fill: parent
                                anchors.rightMargin: 16 // Leave space for the extender
                                drag.target: fCell
                                drag.axis: Drag.XAxis
                                hoverEnabled: true
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                onClicked: root.goToFrame(fIdx)
                                onReleased: {
                                    fCell.Drag.drop()
                                    // Snap back smoothly
                                    fCell.parent = delegateRoot
                                    fCell.x = 0
                                    fCell.y = 0
                                    
                                    // Re-sync layer visibilities in case order changed
                                    root.goToFrame(root.currentFrameIdx)
                                }
                            }
                            ToolTip.visible: dragMa.containsMouse && !dragMa.drag.active
                            ToolTip.text: "Frame " + (fIdx + 1) + "\nArrastra para mover"
                            ToolTip.delay: 400

                            // Extender handle (right edge) - drag to change duration
                            Rectangle {
                                width: 20
                                height: parent.height
                                anchors.right: parent.right
                                color: extMa.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1) : "transparent"
                                radius: fCell.radius
                                z: 10
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                // Visual grip dots
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Repeater {
                                        model: 3
                                        Rectangle {
                                            width: 3; height: 3; radius: 1.5
                                            color: (extMa.containsMouse || extMa.pressed) ? root.accentColor : "#555"
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }
                                    }
                                }

                                // Bullet-proof delta tracking using an unanchored dummy item
                                Item { id: dragDummy; x: 0; y: 0 }

                                MouseArea {
                                    id: extMa
                                    anchors.fill: parent
                                    cursorShape: Qt.SizeHorCursor
                                    hoverEnabled: true
                                    preventStealing: true
                                    drag.target: dragDummy
                                    drag.axis: Drag.XAxis
                                    drag.minimumX: -(fCell.baseWidth - 50) // Don't let it shrink below 1 frame

                                    property int _myIdx: fCell.fIdx

                                    onPressed: {
                                        _myIdx = fCell.fIdx
                                        root.goToFrame(_myIdx)
                                        // Reset dummy for relative drag tracking
                                        dragDummy.x = 0
                                    }
                                    
                                    onReleased: {
                                        var finalDur = fCell.visualDur
                                        var curDur = frameModel.get(_myIdx)
                                        // End of drag: Commit to model
                                        if (curDur && finalDur !== curDur.duration) {
                                            frameModel.setProperty(_myIdx, "duration", finalDur)
                                        }
                                        dragDummy.x = 0 // clean up
                                        // Notify parent to sync duration to advanced timeline
                                        root.durationChanged()
                                    }
                                }
                                ToolTip.visible: extMa.containsMouse && !extMa.pressed
                                ToolTip.text: "⟷ Estirar duración"
                                ToolTip.delay: 300
                            }
                        }
                    }
                }
            }

            // ── "+" Add-frame cell at end ──────────────
            Rectangle {
                id: addFrameBtn
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 50; radius: 12
                color: addCellMa.containsMouse ? "#1c1c28" : "#131318"
                border.color: addCellMa.containsMouse ? root.accentColor : "#25252b"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent; text: "+"
                    color: addCellMa.containsMouse ? root.accentColor : "#555"
                    font.pixelSize: 26; font.weight: Font.Light
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea { 
                    id: addCellMa; anchors.fill: parent; hoverEnabled: true; 
                    cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame() 
                }
                ToolTip.visible: addCellMa.containsMouse; ToolTip.text: "Añadir fotograma"; ToolTip.delay: 400
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
