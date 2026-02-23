import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ══════════════════════════════════════════════════════════════
//  TIMELINE PANEL  —  Studio Mode
//  Real frame model: starts empty. Press "+ New Frame" to start.
// ══════════════════════════════════════════════════════════════
Item {
    id: root
    property var   targetCanvas: null
    property color accentColor:  "#6366f1"
    
    Component.onCompleted: console.log("TimelinePanel loaded and mounted!")

    // ── Playback / Animation State ───────────────────────────
    property int  currentFrameIdx: 0          // 0-based index into frameModel
    property int  fps:             12
    property bool isPlaying:       false
    property bool loopEnabled:     true
    property bool onionSkinEnabled: false
    property int  onionBefore:     2
    property int  onionAfter:      1
    property real onionOpacity:    0.4
    property color onionColorBefore: "#ff4466"
    property color onionColorAfter:  "#44cc66"
    property bool lightTableEnabled: false

    // ── Frame Data Model ─────────────────────────────────────
    // Each entry: { thumbnail: "" }   (thumbnail will be image data URL later)
    ListModel { id: frameModel }

    property int frameCount: frameModel.count

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

    // ── Frame Navigation ─────────────────────────────────────
    function goToFrame(idx) {
        if (idx < 0 || idx >= frameCount) return
        currentFrameIdx = idx
        syncLayerVisibility()
    }

    function syncLayerVisibility() {
        if (!targetCanvas || !targetCanvas.layerModel) return;
        var model = targetCanvas.layerModel;
        var inAnimatedGroup = false;
        var groupChildIndex = 0;

        for (var i = 0; i < model.length; i++) {
            var layer = model[i];
            
            if (layer.depth === 0) {
                inAnimatedGroup = false;
            }
            
            if (layer.type === "group") {
                inAnimatedGroup = true;
                groupChildIndex = 0;
                continue;
            }
            
            if (inAnimatedGroup && layer.depth > 0) {
                var shouldBeVisible = (groupChildIndex === currentFrameIdx);
                // QML layerModel exposes layerId which maps to C++ internal ID
                if (typeof targetCanvas.setLayerVisibility === 'function') {
                    targetCanvas.setLayerVisibility(layer.layerId, shouldBeVisible);
                }
                groupChildIndex++;
            }
        }
    }

    function addFrame() {
        // Sync with Canvas by adding a new Layer
        if (targetCanvas) {
            targetCanvas.addLayer()
        }
        
        frameModel.append({ thumbnail: "" })
        goToFrame(frameModel.count - 1)
    }

    function duplicateCurrentFrame() {
        if (frameCount === 0) return
        var t = frameModel.get(currentFrameIdx).thumbnail
        frameModel.insert(currentFrameIdx + 1, { thumbnail: t })
        goToFrame(currentFrameIdx + 1)
    }

    function deleteCurrentFrame() {
        if (frameCount <= 1) return
        var wasLast = currentFrameIdx >= frameCount - 1
        frameModel.remove(currentFrameIdx)
        goToFrame(wasLast ? frameCount - 1 : currentFrameIdx)
    }

    // ── View config ──────────────────────────────────────────
    property real cellW: 64     // thumbnail cell width (wider for real thumbs)
    property real cellH: 52     // thumbnail cell height

    // ════════════════════════════════════════════════════════
    //  UI
    // ════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: "#0c0c10"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── 1. TOP CONTROL BAR ────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: "#111115"
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1e1e24" }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 4

                    // Playback controls
                    TLButton { icon: "⏮"; tip: "Primer frame"; onClicked: root.goToFrame(0); enabled: root.frameCount > 0 }
                    TLButton { icon: "◀"; tip: "Frame anterior"; onClicked: root.goToFrame(root.currentFrameIdx - 1); enabled: root.currentFrameIdx > 0 }

                    // Play/Pause
                    Rectangle {
                        width: 36; height: 30; radius: 6
                        color: root.isPlaying ? root.accentColor : (playMa.containsMouse ? "#2a2a30" : "#1a1a1f")
                        border.color: root.isPlaying ? Qt.lighter(root.accentColor, 1.3) : "#333"
                        opacity: root.frameCount > 1 ? 1.0 : 0.4
                        Text { text: root.isPlaying ? "⏸" : "▶"; color: "white"; font.pixelSize: 14; anchors.centerIn: parent }
                        MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.frameCount > 1) root.isPlaying = !root.isPlaying }
                    }

                    TLButton { icon: "▶"; tip: "Frame siguiente"; onClicked: root.goToFrame(root.currentFrameIdx + 1); enabled: root.currentFrameIdx < root.frameCount - 1 }
                    TLButton { icon: "⏭"; tip: "Último frame"; onClicked: root.goToFrame(root.frameCount - 1); enabled: root.frameCount > 0 }

                    Rectangle { width: 1; height: 20; color: "#2a2a2e" }

                    // Frame counter
                    Rectangle {
                        width: 72; height: 26; radius: 4; color: "#0a0a0e"; border.color: "#222"
                        Text {
                            anchors.centerIn: parent
                            text: root.frameCount === 0 ? "— / —" : (root.currentFrameIdx + 1) + " / " + root.frameCount
                            color: root.frameCount === 0 ? "#444" : "white"
                            font.pixelSize: 11; font.family: "Monospace"; font.weight: Font.Bold
                        }
                    }

                    Rectangle { width: 1; height: 20; color: "#2a2a2e" }

                    // Toggles
                    TLToggle { label: "Loop";     active: root.loopEnabled;      onToggled: root.loopEnabled = !root.loopEnabled }
                    TLToggle { label: "Onion";    active: root.onionSkinEnabled; onToggled: root.onionSkinEnabled = !root.onionSkinEnabled; accent: root.onionColorBefore }
                    TLToggle { label: "Mesa Luz"; active: root.lightTableEnabled; onToggled: root.lightTableEnabled = !root.lightTableEnabled; accent: "#60c0ff" }

                    Item { Layout.fillWidth: true }

                    // FPS
                    Row {
                        spacing: 4
                        Text { text: "FPS"; color: "#555"; font.pixelSize: 10; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle {
                            width: 40; height: 26; radius: 4; color: "#0a0a0e"; border.color: "#222"
                            TextInput {
                                anchors.centerIn: parent; width: parent.width - 8
                                text: root.fps.toString(); color: "white"; font.pixelSize: 12; font.family: "Monospace"
                                horizontalAlignment: TextInput.AlignHCenter; selectByMouse: true
                                onAccepted: { var v = parseInt(text); if (v > 0 && v <= 60) root.fps = v }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 20; color: "#2a2a2e" }

                    // ── NEW FRAME BUTTON (Primary action) ───────
                    Rectangle {
                        width: 100; height: 30; radius: 8
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.accentColor }
                            GradientStop { position: 1.0; color: Qt.lighter(root.accentColor, 1.2) }
                        }
                        scale: newFrameMa.pressed ? 0.95 : (newFrameMa.containsMouse ? 1.02 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }

                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Text { text: "+"; color: "white"; font.pixelSize: 16; font.weight: Font.Light }
                            Text { text: "Nuevo Frame"; color: "white"; font.pixelSize: 11; font.weight: Font.DemiBold }
                        }
                        MouseArea {
                            id: newFrameMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.addFrame()
                        }
                        ToolTip.visible: newFrameMa.containsMouse; ToolTip.text: "Crear nuevo fotograma vacío"; ToolTip.delay: 400
                    }

                    // Duplicate / Delete
                    TLButton { icon: "⧉"; tip: "Duplicar frame"; onClicked: root.duplicateCurrentFrame(); enabled: root.frameCount > 0 }
                    TLButton { icon: "🗑"; tip: "Eliminar frame"; onClicked: root.deleteCurrentFrame(); enabled: root.frameCount > 1 }
                }
            }

            // ── 2. ONION SETTINGS BAR (Collapsible) ───────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.onionSkinEnabled ? 34 : 0
                color: "#0e0e12"; clip: true; visible: height > 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1a1a1e" }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 20

                    Row {
                        spacing: 6
                        Rectangle { width: 10; height: 10; radius: 2; color: root.onionColorBefore; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Antes:"; color: "#888"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        Slider { implicitWidth: 80; from: 0; to: 5; value: root.onionBefore; stepSize: 1; onMoved: root.onionBefore = value
                            background: Rectangle { x: parent.leftPadding; y: parent.topPadding + parent.availableHeight/2 - 1.5; implicitHeight: 3; width: parent.availableWidth; radius: 1.5; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: 3; radius: 1.5; color: root.onionColorBefore } }
                            handle: Rectangle { x: parent.leftPadding + parent.visualPosition*(parent.availableWidth-width); y: parent.topPadding+parent.availableHeight/2-5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#333" } }
                        Text { text: root.onionBefore; color: "white"; font.pixelSize: 10; font.family: "Monospace"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 6
                        Rectangle { width: 10; height: 10; radius: 2; color: root.onionColorAfter; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Después:"; color: "#888"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        Slider { implicitWidth: 80; from: 0; to: 5; value: root.onionAfter; stepSize: 1; onMoved: root.onionAfter = value
                            background: Rectangle { x: parent.leftPadding; y: parent.topPadding + parent.availableHeight/2 - 1.5; implicitHeight: 3; width: parent.availableWidth; radius: 1.5; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: 3; radius: 1.5; color: root.onionColorAfter } }
                            handle: Rectangle { x: parent.leftPadding + parent.visualPosition*(parent.availableWidth-width); y: parent.topPadding+parent.availableHeight/2-5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#333" } }
                        Text { text: root.onionAfter; color: "white"; font.pixelSize: 10; font.family: "Monospace"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 6
                        Text { text: "Opacidad:"; color: "#888"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                        Slider { implicitWidth: 80; from: 0.05; to: 1.0; value: root.onionOpacity; onMoved: root.onionOpacity = value
                            background: Rectangle { x: parent.leftPadding; y: parent.topPadding + parent.availableHeight/2 - 1.5; implicitHeight: 3; width: parent.availableWidth; radius: 1.5; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: 3; radius: 1.5; color: "#888" } }
                            handle: Rectangle { x: parent.leftPadding + parent.visualPosition*(parent.availableWidth-width); y: parent.topPadding+parent.availableHeight/2-5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#333" } }
                        Text { text: Math.round(root.onionOpacity * 100) + "%"; color: "white"; font.pixelSize: 10; font.family: "Monospace"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // ── 3. TIMELINE BODY ──────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ── EMPTY STATE ───────────────────────────────
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: root.frameCount === 0

                    Text { text: "🎞"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.3 }
                    Text {
                        text: "Sin fotogramas todavía"
                        color: "#555"; font.pixelSize: 15; font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Haz clic en  "+ \"+ Nuevo Frame\"  +" para comenzar tu animación."
                        color: "#333"; font.pixelSize: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Large CTA button
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 160; height: 40; radius: 12
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.accentColor }
                            GradientStop { position: 1.0; color: Qt.lighter(root.accentColor, 1.2) }
                        }
                        scale: ctaMa.pressed ? 0.95 : (ctaMa.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                        Row { anchors.centerIn: parent; spacing: 8
                            Text { text: "+"; color: "white"; font.pixelSize: 20; font.weight: Font.Light }
                            Text { text: "Nuevo Frame"; color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        }
                        MouseArea { id: ctaMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.addFrame() }
                    }
                }

                // ── FRAME STRIP (thumbnail track) ─────────────
                Item {
                    anchors.fill: parent
                    visible: root.frameCount > 0
                    clip: true

                    // Track label column
                    Rectangle {
                        id: trackHeader
                        width: 90; height: parent.height
                        color: "#0e0e12"
                        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: "#1e1e24" }

                        Column {
                            anchors.fill: parent; spacing: 0

                            // Ruler spacer
                            Rectangle {
                                width: parent.width; height: rulerHeight
                                color: "#111115"
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1a1a1e" }
                                Text { text: "FRAMES"; color: "#444"; font.pixelSize: 8; font.weight: Font.Bold; font.letterSpacing: 1; anchors.centerIn: parent }
                            }

                            // One track row: the animation layer
                            Rectangle {
                                width: parent.width; height: root.cellH + 2
                                color: "#111115"
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1a1a1e" }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 6; spacing: 4
                                    Text { text: "👁"; font.pixelSize: 10; opacity: 0.5 }
                                    Text { text: "Capa 1"; color: "#bbb"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                            }
                        }
                    }

                    // Scrollable frame grid
                    property int rulerHeight: 20
                    Flickable {
                        id: frameFlick
                        anchors.left: trackHeader.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        contentWidth: root.frameCount * (root.cellW + 3)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        function scrollToCurrent() {
                            var targetX = root.currentFrameIdx * (root.cellW + 3) - (width/2 - root.cellW/2)
                            contentX = Math.max(0, Math.min(targetX, Math.max(0, contentWidth - width)))
                        }
                        Connections {
                            target: root
                            function onCurrentFrameIdxChanged() { frameFlick.scrollToCurrent() }
                        }

                        Item {
                            width: Math.max(frameFlick.width, root.frameCount * (root.cellW + 3))
                            height: frameFlick.height

                            // ── Ruler ──────────────────────────
                            Rectangle {
                                id: ruler
                                width: parent.width; height: 20
                                color: "#111115"
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1a1a1e" }

                                Repeater {
                                    model: root.frameCount
                                    Item {
                                        x: index * (root.cellW + 3) + (root.cellW + 3)/2
                                        width: 1; height: ruler.height
                                        Rectangle {
                                            width: 1; height: index === root.currentFrameIdx ? 10 : 6
                                            color: index === root.currentFrameIdx ? root.accentColor : "#333"
                                            anchors.bottom: parent.bottom
                                        }
                                        Text {
                                            visible: index % 5 === 0 || index === 0
                                            text: index + 1
                                            color: index === root.currentFrameIdx ? "white" : "#444"
                                            font.pixelSize: 8; font.family: "Monospace"
                                            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }

                                // Scrub by clicking ruler
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: function(mouse) { root.goToFrame(Math.max(0, Math.min(root.frameCount-1, Math.floor(mouse.x / (root.cellW + 3))))) }
                                    onPositionChanged: function(mouse) { if (pressed) root.goToFrame(Math.max(0, Math.min(root.frameCount-1, Math.floor(mouse.x / (root.cellW + 3))))) }
                                }
                            }

                            // ── Thumbnail Cells ─────────────────
                            Row {
                                y: ruler.height
                                spacing: 3

                                Repeater {
                                    model: frameModel

                                    Rectangle {
                                        id: thumbCell
                                        property int fIdx: index
                                        property bool isCurrent: fIdx === root.currentFrameIdx
                                        property int onionDist: fIdx - root.currentFrameIdx

                                        width: root.cellW; height: root.cellH
                                        radius: 6

                                        // Background
                                        color: {
                                            if (isCurrent) return "#1a1a2e"
                                            if (thumbMa.containsMouse) return "#1c1c24"
                                            return "#141418"
                                        }
                                        border.color: isCurrent ? root.accentColor : "#222"
                                        border.width: isCurrent ? 2 : 1

                                        Behavior on color { ColorAnimation { duration: 80 } }
                                        Behavior on border.color { ColorAnimation { duration: 80 } }

                                        // Onion skin overlay
                                        Rectangle {
                                            anchors.fill: parent; radius: parent.radius
                                            visible: root.onionSkinEnabled && !thumbCell.isCurrent &&
                                                     ((thumbCell.onionDist < 0 && -thumbCell.onionDist <= root.onionBefore) ||
                                                      (thumbCell.onionDist > 0 &&  thumbCell.onionDist <= root.onionAfter))
                                            color: thumbCell.onionDist < 0
                                                   ? Qt.rgba(root.onionColorBefore.r, root.onionColorBefore.g, root.onionColorBefore.b,
                                                             root.onionOpacity * (root.onionBefore - (-thumbCell.onionDist) + 1) / (root.onionBefore + 1))
                                                   : Qt.rgba(root.onionColorAfter.r,  root.onionColorAfter.g,  root.onionColorAfter.b,
                                                             root.onionOpacity * (root.onionAfter  -  thumbCell.onionDist        + 1) / (root.onionAfter  + 1))
                                        }

                                        // Thumbnail image (or placeholder)
                                        Item {
                                            anchors.fill: parent; anchors.margins: 4

                                            // Placeholder when no thumbnail yet
                                            Column {
                                                anchors.centerIn: parent; spacing: 2
                                                opacity: 0.35
                                                visible: model.thumbnail === ""
                                                Text { text: "🖼"; font.pixelSize: 18; anchors.horizontalCenter: parent.horizontalCenter }
                                                Text { text: fIdx + 1; color: "#888"; font.pixelSize: 8; font.family: "Monospace"; anchors.horizontalCenter: parent.horizontalCenter }
                                            }

                                            // Actual thumbnail (when available)
                                            Image {
                                                anchors.fill: parent
                                                source: model.thumbnail !== "" ? model.thumbnail : ""
                                                visible: model.thumbnail !== ""
                                                fillMode: Image.PreserveAspectFit
                                            }
                                        }

                                        // Current frame indicator triangle at top
                                        Rectangle {
                                            visible: thumbCell.isCurrent
                                            anchors.top: parent.top; anchors.topMargin: -1
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 8; height: 4
                                            radius: 1
                                            color: root.accentColor
                                        }

                                        // Frame number badge
                                        Rectangle {
                                            anchors.bottom: parent.bottom; anchors.right: parent.right
                                            anchors.margins: 3; width: badgeTxt.implicitWidth + 6; height: 13; radius: 4
                                            color: thumbCell.isCurrent ? root.accentColor : "#1a1a1e"
                                            border.color: thumbCell.isCurrent ? "transparent" : "#333"
                                            Text {
                                                id: badgeTxt
                                                text: thumbCell.fIdx + 1
                                                color: thumbCell.isCurrent ? "white" : "#666"
                                                font.pixelSize: 8; font.family: "Monospace"
                                                anchors.centerIn: parent
                                            }
                                        }

                                        MouseArea {
                                            id: thumbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.goToFrame(thumbCell.fIdx)
                                        }

                                        ToolTip.visible: thumbMa.containsMouse
                                        ToolTip.text: "Frame " + (fIdx + 1)
                                        ToolTip.delay: 400
                                    }
                                }

                                // ── ADD FRAME CELL (end of strip) ───
                                Rectangle {
                                    width: root.cellW; height: root.cellH; radius: 6
                                    color: addCellMa.containsMouse ? "#1a1a24" : "#111115"
                                    border.color: addCellMa.containsMouse ? root.accentColor : "#222"
                                    border.width: addCellMa.containsMouse ? 1.5 : 1
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Column {
                                        anchors.centerIn: parent; spacing: 3
                                        Text { text: "+"; color: addCellMa.containsMouse ? root.accentColor : "#444"; font.pixelSize: 22; font.weight: Font.Light; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: "Frame"; color: addCellMa.containsMouse ? root.accentColor : "#333"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                    MouseArea {
                                        id: addCellMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.addFrame()
                                    }
                                    ToolTip.visible: addCellMa.containsMouse; ToolTip.text: "Nuevo fotograma"; ToolTip.delay: 400
                                }
                            }

                            // ── PLAYHEAD line ────────────────────
                            Rectangle {
                                x: root.currentFrameIdx * (root.cellW + 3) + root.cellW/2
                                y: ruler.height
                                width: 2; height: root.cellH + 2
                                color: root.accentColor
                                z: 10; opacity: 0.7
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Reusable components ───────────────────────────────────
    component TLButton : Rectangle {
        property string icon: ""
        property string tip:  ""
        property bool   enabled: true
        signal clicked()
        width: 28; height: 30; radius: 5
        color: ma.pressed ? "#2a2a34" : (ma.containsMouse && enabled ? "#1e1e26" : "transparent")
        opacity: enabled ? 1.0 : 0.3
        Text { text: parent.icon; color: "white"; font.pixelSize: 13; anchors.centerIn: parent }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: if (parent.enabled) parent.clicked() }
        ToolTip.visible: ma.containsMouse && tip !== ""; ToolTip.text: tip; ToolTip.delay: 400
    }

    component TLToggle : Rectangle {
        property string label:  ""
        property bool   active: false
        property color  accent: root.accentColor
        signal toggled()
        width: implicitWidth + 16; height: 26; radius: 5
        implicitWidth: tlTxt.implicitWidth
        color: active ? Qt.rgba(accent.r, accent.g, accent.b, 0.15) : (tma.containsMouse ? "#1c1c22" : "transparent")
        border.color: active ? accent : "transparent"; border.width: active ? 1 : 0
        Text { id: tlTxt; text: parent.label; color: parent.active ? "white" : "#666"; font.pixelSize: 10; font.weight: Font.DemiBold; anchors.centerIn: parent }
        MouseArea { id: tma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.toggled() }
    }
}
