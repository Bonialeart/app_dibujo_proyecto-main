import QtQuick 2.15
import QtQuick.Controls 2.15

// ══════════════════════════════════════════════════════════════
//  CAMERA VIEWFINDER OVERLAY
//  A frame that lives on top of the canvas. Visible only when
//  the AnimationCamera is active. Lets the user pan / zoom /
//  rotate the camera directly from the canvas:
//   - drag the center to pan
//   - drag a corner to zoom (scales uniformly around the
//     frame center, like the stroke transform tool)
//   - drag the rotation handle above the top edge to rotate
//   - on release, a keyframe is auto-committed at the current
//     frame (added if missing, updated if present)
// ══════════════════════════════════════════════════════════════
Item {
    id: overlay
    // Position (x/y) is set by the parent (main_pro.qml) so the
    // frame can be anchored to the paper. Size (width/height) is
    // computed internally from the camera's appliedZoom and the
    // current canvas zoomLevel.
    visible: camera !== null && camera.active
    enabled: visible
    z: 1000

    // ── Public API ────────────────────────────────────────────
    property var   camera:     null
    property color frameColor: "#22d3ee"
    // Suppress the overlay (e.g. while user is drawing)
    property bool  suppressed: false

    // "Modo Visor Real": letterbox preview of the export framing
    // (handles hidden, area outside the frame darkened).
    readonly property bool viewerModeActive: camera !== null && camera.viewerMode
    readonly property bool ghostingOn:  camera !== null && camera.ghostingEnabled
    readonly property bool motionPathOn: camera !== null && camera.motionPathEnabled

    // ── Internal drag state ───────────────────────────────────
    property bool  _dragging:    false
    property string _dragMode:   ""   // "pan" | "nw"|"ne"|"sw"|"se" | "rotate"
    property point _startMouse:  Qt.point(0, 0)
    // Global (root-item) coords of the press that started a pan
    property point _startGlobal: Qt.point(0, 0)
    property real  _startZoom:   1.0
    property real  _startX:      0
    property real  _startY:      0
    property real  _startRot:    0
    property point _startView:   Qt.point(0, 0)
    // Distance-from-center drag state (corner zoom handles)
    property real  _startDist:   0
    property point _centerParent: Qt.point(0, 0)

    // Don't capture mouse while suppressed
    opacity: suppressed ? 0.3 : 1.0

    // ── Reusable toolbar toggle ───────────────────────────────
    component VfToggle : Rectangle {
        id: vt
        property string icon: "?"
        property string tip: ""
        property bool   active: false
        property bool   shown: true
        signal toggled()
        visible: shown
        width: 24; height: 24; radius: 12
        color: active
            ? Qt.rgba(overlay.frameColor.r, overlay.frameColor.g, overlay.frameColor.b, 0.30)
            : Qt.rgba(0.04, 0.04, 0.06, 0.72)
        border.color: active ? overlay.frameColor : Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 130 } }
        scale: vtMa.pressed ? 0.9 : (vtMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
        Text {
            anchors.centerIn: parent
            text: vt.icon
            color: vt.active ? "#ffffff" : "#9ca3af"
            font.pixelSize: 11
        }
        MouseArea {
            id: vtMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onClicked: vt.toggled()
        }
        ToolTip.visible: vtMa.containsMouse
        ToolTip.text: vt.tip
        ToolTip.delay: 450
    }

    // The viewfinder's frame is rotated by the camera's
    // current rotation (which is what the user just keyframed).
    // The paper underneath does NOT rotate — only the frame
    // (and the crosshair, handles, etc.) rotates around the
    // canvas center.
    rotation: camera ? camera.appliedRotation : 0
    transformOrigin: Item.Center

    // Frame size is driven by the camera's appliedZoom, NOT by
    // the canvas zoomLevel.  The canvas zoomLevel only
    // determines how much the frame is magnified on screen.
    // At camZoom=1.0 the frame covers 80% of the paper width;
    // at camZoom=2.0 it covers 40% (telephoto, smaller frame).
    width:  _calcFrameSize(true)
    height: _calcFrameSize(false)

    // ── Helpers ───────────────────────────────────────────────
    function _calcFrameSize(isWidth) {
        if (!camera || !camera.targetCanvas) return 0
        var z = camera.targetCanvas.zoomLevel || 1.0
        if (z <= 0) z = 1.0
        var cz = camera.appliedZoom || 1.0
        if (cz <= 0) cz = 1.0
        var canvasDim = isWidth
            ? camera.targetCanvas.canvasWidth
            : camera.targetCanvas.canvasHeight
        return canvasDim * z * 0.80 / cz
    }

    // Frame size for an arbitrary camera zoom (ghost frames)
    function _frameSizeFor(camZoom, isWidth) {
        if (!camera || !camera.targetCanvas) return 0
        var z = camera.targetCanvas.zoomLevel || 1.0
        if (z <= 0) z = 1.0
        var cz = (camZoom && camZoom > 0) ? camZoom : 1.0
        var canvasDim = isWidth
            ? camera.targetCanvas.canvasWidth
            : camera.targetCanvas.canvasHeight
        return canvasDim * z * 0.80 / cz
    }

    // Screen-space offset (from the current frame center) at which
    // a camera state {x, y} appears. x/y are paper coordinates of
    // the frame center, so the delta is direct.
    function _stateDelta(stX, stY) {
        if (!camera || !camera.targetCanvas) return Qt.point(0, 0)
        var z = camera.targetCanvas.zoomLevel || 1.0
        return Qt.point((stX - camera.appliedX) * z,
                        (stY - camera.appliedY) * z)
    }

    // Previous / next keyframes around the current frame (for the
    // camera ghosting). Recomputed whenever the keyframe set or
    // the current frame changes.
    readonly property var ghostKfs: {
        if (!camera) return []
        var kfs = camera.keyframes
        var cur = camera.currentFrameIdx
        var prev = null, next = null
        for (var i = 0; i < kfs.length; i++) {
            if (kfs[i].frameIdx < cur) prev = kfs[i]
            else if (kfs[i].frameIdx > cur) { next = kfs[i]; break }
        }
        var out = []
        if (prev) out.push({ kf: prev, isPrev: true })
        if (next) out.push({ kf: next, isPrev: false })
        return out
    }

    function _paperCenter() {
        if (!camera || !camera.targetCanvas) return Qt.point(0, 0)
        var z = camera.targetCanvas.zoomLevel
        if (z === undefined || z <= 0) z = 1.0
        return Qt.point(
            camera.targetCanvas.viewOffset.x + width  / (2.0 * z),
            camera.targetCanvas.viewOffset.y + height / (2.0 * z)
        )
    }

    function _commitKeyframe() {
        if (!camera || !camera.targetCanvas) return
        // Suppress applyAt during keyframe update so the canvas
        // view (zoom/pan) is not disturbed.  The camera's
        // appliedX/Y/Zoom already reflect the current drag,
        // and the overlay resizes reactively.
        camera._suppressApply = true
        camera.addKeyframeAt(
            camera.currentFrameIdx,
            camera.appliedX,
            camera.appliedY,
            camera.appliedZoom,
            camera.appliedRotation
        )
        camera._suppressApply = false
    }

    // ── WORLD LAYER ───────────────────────────────────────────
    // Counter-rotated, screen-aligned container for the motion
    // path and the camera ghost frames. The overlay itself rotates
    // with the camera; this layer cancels that rotation so the
    // trajectory is drawn in stable screen space.
    Item {
        id: worldLayer
        anchors.centerIn: parent
        width: 1; height: 1
        rotation: -overlay.rotation
        visible: !overlay.suppressed && !overlay.viewerModeActive
        z: 0

        // ── Motion path: dotted camera trajectory ──
        Canvas {
            id: pathCanvas
            visible: overlay.motionPathOn
            // Kept moderate: this is an offscreen image buffer
            // (width × height × 4 bytes), so don't oversize it.
            width: 1400; height: 1400
            x: -width / 2; y: -height / 2
            renderTarget: Canvas.Image

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (!overlay.camera || !overlay.motionPathOn) return
                var samples = overlay.camera.getMotionPathSamples(10)
                if (samples.length < 2) return
                var cx = width / 2, cy = height / 2

                ctx.strokeStyle = Qt.rgba(overlay.frameColor.r, overlay.frameColor.g,
                                          overlay.frameColor.b, 0.75)
                ctx.lineWidth = 1.5
                ctx.setLineDash([4, 5])
                ctx.beginPath()
                for (var i = 0; i < samples.length; i++) {
                    var d = overlay._stateDelta(samples[i].x, samples[i].y)
                    if (i === 0) ctx.moveTo(cx + d.x, cy + d.y)
                    else         ctx.lineTo(cx + d.x, cy + d.y)
                }
                ctx.stroke()
                ctx.setLineDash([])

                // Keyframe dots along the path
                for (var j = 0; j < samples.length; j++) {
                    if (!samples[j].isKey) continue
                    var kd = overlay._stateDelta(samples[j].x, samples[j].y)
                    ctx.beginPath()
                    ctx.arc(cx + kd.x, cy + kd.y, 3.2, 0, Math.PI * 2)
                    ctx.fillStyle = overlay.frameColor
                    ctx.fill()
                    ctx.lineWidth = 1
                    ctx.strokeStyle = "#0b1220"
                    ctx.stroke()
                }
            }

            Connections {
                target: overlay.camera
                enabled: overlay.camera !== null
                function onKeyframesChanged()     { pathCanvas.requestPaint() }
                function onAppliedXChanged()      { pathCanvas.requestPaint() }
                function onAppliedYChanged()      { pathCanvas.requestPaint() }
                function onAppliedZoomChanged()   { pathCanvas.requestPaint() }
                function onCurrentFrameIdxChanged() { pathCanvas.requestPaint() }
                function onMotionPathEnabledChanged() { pathCanvas.requestPaint() }
            }
            Connections {
                target: overlay.camera ? overlay.camera.targetCanvas : null
                enabled: overlay.camera !== null && overlay.camera.targetCanvas !== null
                function onZoomLevelChanged()   { pathCanvas.requestPaint() }
                function onViewOffsetChanged()  { pathCanvas.requestPaint() }
            }
        }

        // ── Camera ghosting: prev / next keyframe framings ──
        Repeater {
            model: overlay.ghostingOn ? overlay.ghostKfs : []
            delegate: Item {
                property var entry: modelData
                property var gk: entry.kf
                property point gd: overlay._stateDelta(gk.x, gk.y)
                property real gw: overlay._frameSizeFor(gk.zoom, true)
                property real gh: overlay._frameSizeFor(gk.zoom, false)
                // Skip the ghost when it matches the current framing
                visible: Math.abs(gd.x) > 1 || Math.abs(gd.y) > 1
                         || Math.abs(gw - overlay.width) > 1
                x: gd.x - gw / 2
                y: gd.y - gh / 2
                width: gw; height: gh
                rotation: gk.rotation || 0

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: entry.isPrev ? "#cc4444" : "#44cc66"
                    border.width: 1
                    opacity: 0.45
                }
                // Corner ticks to read the ghost as a camera frame
                Repeater {
                    model: 4
                    Rectangle {
                        width: 7; height: 7
                        color: "transparent"
                        border.color: entry.isPrev ? "#cc4444" : "#44cc66"
                        border.width: 1.5
                        opacity: 0.8
                        x: (index % 2) === 0 ? -1 : parent.width - 6
                        y: index < 2 ? -1 : parent.height - 6
                    }
                }
                Text {
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    text: (entry.isPrev ? "◀ " : "▶ ") + "F" + (gk.frameIdx + 1)
                    color: entry.isPrev ? "#cc4444" : "#44cc66"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    opacity: 0.85
                }
            }
        }
    }

    // ── The frame rectangle (visualizes the camera's view) ─────
    Rectangle {
        id: frame
        anchors.fill: parent
        color: "transparent"
        border.color: overlay.viewerModeActive ? "#f8fafc" : overlay.frameColor
        border.width: overlay.viewerModeActive ? 1.5 : 1
        // Cosmetic: dashed inner stroke
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: "transparent"
            border.color: overlay.frameColor
            border.width: 1
            opacity: 0.35
        }

        // Rule-of-thirds grid: makes the overlay read as a camera
        // viewfinder and helps composing the shot.
        Item {
            anchors.fill: parent
            opacity: overlay._dragging ? 0.35 : 0.16
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Rectangle { x: parent.width / 3;     width: 1; height: parent.height; color: overlay.frameColor }
            Rectangle { x: parent.width * 2 / 3; width: 1; height: parent.height; color: overlay.frameColor }
            Rectangle { y: parent.height / 3;     height: 1; width: parent.width; color: overlay.frameColor }
            Rectangle { y: parent.height * 2 / 3; height: 1; width: parent.width; color: overlay.frameColor }
        }
    }

    // ── LETTERBOX (Modo Visor Real) ───────────────────────────
    // Darkens everything outside the camera frame so the user can
    // preview the pan / zoom exactly as it will export. The four
    // huge bars extend far past the screen in every direction
    // (the overlay rotates, so they must over-cover).
    Item {
        visible: overlay.viewerModeActive
        anchors.fill: parent
        z: 5
        readonly property real ext: 4000
        readonly property color maskCol: Qt.rgba(0.02, 0.02, 0.03, 0.82)

        Rectangle { // top
            x: -parent.ext; y: -parent.ext
            width: parent.width + 2 * parent.ext; height: parent.ext
            color: parent.maskCol
        }
        Rectangle { // bottom
            x: -parent.ext; y: parent.height
            width: parent.width + 2 * parent.ext; height: parent.ext
            color: parent.maskCol
        }
        Rectangle { // left
            x: -parent.ext; y: 0
            width: parent.ext; height: parent.height
            color: parent.maskCol
        }
        Rectangle { // right
            x: parent.width; y: 0
            width: parent.ext; height: parent.height
            color: parent.maskCol
        }
    }

    // ── Center crosshair (helps see the rotation pivot) ───────
    Item {
        visible: !overlay.viewerModeActive
        anchors.centerIn: parent
        Rectangle { width: 14; height: 1.5; color: overlay.frameColor; opacity: 0.6; anchors.centerIn: parent }
        Rectangle { width: 1.5; height: 14; color: overlay.frameColor; opacity: 0.6; anchors.centerIn: parent }
        // Tiny ring around the pivot
        Rectangle {
            anchors.centerIn: parent
            width: 8; height: 8; radius: 4
            color: "transparent"
            border.color: overlay.frameColor
            border.width: 1
            opacity: 0.8
        }
    }

    // ── VIEWFINDER TOOLBAR (top-right corner) ─────────────────
    // Quick toggles: camera ghosting, motion path and "Modo Visor
    // Real". Stays visible in viewer mode so the user can exit.
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 8
        spacing: 6
        z: 30
        visible: overlay.camera !== null && !overlay._dragging

        VfToggle {
            icon: "◈"; tip: "Papel cebolla de cámara (keyframes vecinos)"
            shown: !overlay.viewerModeActive
            active: overlay.ghostingOn
            onToggled: if (overlay.camera) overlay.camera.ghostingEnabled = !overlay.camera.ghostingEnabled
        }
        VfToggle {
            icon: "∿"; tip: "Trayectoria de la cámara (motion path)"
            shown: !overlay.viewerModeActive
            active: overlay.motionPathOn
            onToggled: if (overlay.camera) overlay.camera.motionPathEnabled = !overlay.camera.motionPathEnabled
        }
        VfToggle {
            icon: "⛶"; tip: overlay.viewerModeActive
                ? "Salir del Modo Visor Real"
                : "Modo Visor Real (previsualizar encuadre de exportación)"
            active: overlay.viewerModeActive
            onToggled: {
                if (!overlay.camera) return
                overlay.camera.viewerMode = !overlay.camera.viewerMode
                if (overlay.camera.notify)
                    overlay.camera.notify(overlay.camera.viewerMode
                        ? "Modo Visor Real activado" : "Modo Visor Real desactivado", "info")
            }
        }
    }

    // ── HUD: current camera state (top-left corner) ───────────
    Item {
        x: 10; y: 10
        visible: overlay.camera !== null
        Column {
            spacing: 2
            Text {
                text: "🎥 CÁMARA"
                color: overlay.frameColor
                font.pixelSize: 9
                font.weight: Font.Bold
                font.letterSpacing: 1
                opacity: 0.9
            }
            Text {
                text: overlay.camera
                    ? "Z " + ((overlay.camera.appliedZoom || 1) * 100).toFixed(0) + "%"
                    : ""
                color: overlay.frameColor
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
            Text {
                text: overlay.camera && Math.abs(overlay.camera.appliedRotation) > 0.05
                    ? "R " + overlay.camera.appliedRotation.toFixed(1) + "°"
                    : ""
                color: overlay.frameColor
                font.pixelSize: 10
            }
        }
    }

    // ── MOVE: drag anywhere inside the frame to move IT ───────
    // (paper-anchored: only the frame travels over the canvas,
    // the canvas view is never touched)
    Item {
        anchors.fill: parent
        visible: !overlay.viewerModeActive
        MouseArea {
            id: panArea
            anchors.fill: parent
            cursorShape: overlay._dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            hoverEnabled: true
            preventStealing: true
            z: 1
            propagateComposedEvents: false
            property point _startCam: Qt.point(0, 0)
            onPressed: function(m) {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                overlay._dragging   = true
                overlay._dragMode   = "pan"
                // Use GLOBAL coordinates (root item) so the
                // delta is unaffected by the overlay moving
                // under the mouse.
                overlay._startGlobal = panArea.mapToItem(null, m.x, m.y)
                _startCam = Qt.point(overlay.camera.appliedX, overlay.camera.appliedY)
            }
            onPositionChanged: function(m) {
                if (!overlay._dragging || overlay._dragMode !== "pan") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var gp = panArea.mapToItem(null, m.x, m.y)
                var dx = gp.x - overlay._startGlobal.x
                var dy = gp.y - overlay._startGlobal.y
                var z  = overlay.camera.targetCanvas.zoomLevel || 1.0
                // The frame follows the cursor 1:1 in screen space
                overlay.camera.appliedX = _startCam.x + dx / z
                overlay.camera.appliedY = _startCam.y + dy / z
            }
            onReleased: {
                if (overlay._dragMode === "pan") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
            ToolTip.visible: panArea.containsMouse && !overlay._dragging
                && !handleSEMa.containsMouse && !handleNWMa.containsMouse
                && !handleNEMa.containsMouse && !handleSWMa.containsMouse
            ToolTip.text: "Arrastra para mover el encuadre · esquinas: zoom · ⊙ superior: rotar"
            ToolTip.delay: 900
        }
    }

    // ── ZOOM corner handles (drag to zoom) ──────────────────
    // ── Shared visual: filled square with a diagonal arrow that
    // ── points outward. Lightens on hover, shrinks slightly on
    // ── press, shows a tooltip on hover. Drag outward = zoom
    // ── OUT (see more of the canvas), drag inward = zoom IN
    // ── (see less, at higher detail).

    // SE corner — drag ↘ to zoom in (scale up around center)
    Rectangle {
        id: handleSE
        visible: !overlay.viewerModeActive
        width: 16; height: 16
        color: handleSEMa.containsMouse ? Qt.lighter(overlay.frameColor, 1.4) : overlay.frameColor
        border.color: "white"
        border.width: 1
        radius: 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 2
        anchors.bottomMargin: 2
        z: 10
        scale: handleSEMa.pressed ? 0.90 : (handleSEMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: "\u2198"
            color: "white"
            font.pixelSize: 9
            font.weight: Font.Bold
        }
        MouseArea {
            id: handleSEMa
            anchors.fill: parent
            anchors.margins: -7
            cursorShape: Qt.SizeFDiagCursor
            hoverEnabled: true
            preventStealing: true
            onPressed: function(m) {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var cx = overlay.x + overlay.width / 2
                var cy = overlay.y + overlay.height / 2
                overlay._dragging     = true
                overlay._dragMode     = "se"
                overlay._startDist    = Math.sqrt(Math.pow(p.x - cx, 2) + Math.pow(p.y - cy, 2))
                overlay._startZoom    = overlay.camera.appliedZoom || 1.0
                overlay._centerParent = Qt.point(cx, cy)
            }
            onPositionChanged: function(m) {
                if (!overlay._dragging || overlay._dragMode !== "se") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var newDist = Math.sqrt(Math.pow(p.x - overlay._centerParent.x, 2) + Math.pow(p.y - overlay._centerParent.y, 2))
                var factor = overlay._startDist > 0 ? overlay._startDist / newDist : 1.0
                var newZoom = overlay._startZoom * factor
                newZoom = Math.max(0.01, Math.min(newZoom, 50))
                overlay.camera.appliedZoom = newZoom
            }
            onReleased: {
                if (overlay._dragMode === "se") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
        }
        ToolTip.visible: handleSEMa.containsMouse && !overlay._dragging
        ToolTip.text: "Redimensiona el encuadre: hacia afuera lo amplía (aleja la cámara), hacia adentro lo reduce (acerca)"
        ToolTip.delay: 500
    }

    // NW corner — drag ↖ to zoom in (scale up around center)
    Rectangle {
        id: handleNW
        visible: !overlay.viewerModeActive
        width: 16; height: 16
        color: handleNWMa.containsMouse ? Qt.lighter(overlay.frameColor, 1.4) : overlay.frameColor
        border.color: "white"
        border.width: 1
        radius: 2
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 2
        anchors.topMargin: 2
        z: 10
        scale: handleNWMa.pressed ? 0.90 : (handleNWMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: "\u2196"
            color: "white"
            font.pixelSize: 9
            font.weight: Font.Bold
        }
        MouseArea {
            id: handleNWMa
            anchors.fill: parent
            anchors.margins: -7
            cursorShape: Qt.SizeFDiagCursor
            hoverEnabled: true
            preventStealing: true
            onPressed: function(m) {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var cx = overlay.x + overlay.width / 2
                var cy = overlay.y + overlay.height / 2
                overlay._dragging     = true
                overlay._dragMode     = "nw"
                overlay._startDist    = Math.sqrt(Math.pow(p.x - cx, 2) + Math.pow(p.y - cy, 2))
                overlay._startZoom    = overlay.camera.appliedZoom || 1.0
                overlay._centerParent = Qt.point(cx, cy)
            }
            onPositionChanged: function(m) {
                if (!overlay._dragging || overlay._dragMode !== "nw") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var newDist = Math.sqrt(Math.pow(p.x - overlay._centerParent.x, 2) + Math.pow(p.y - overlay._centerParent.y, 2))
                var factor = overlay._startDist > 0 ? overlay._startDist / newDist : 1.0
                var newZoom = overlay._startZoom * factor
                newZoom = Math.max(0.01, Math.min(newZoom, 50))
                overlay.camera.appliedZoom = newZoom
            }
            onReleased: {
                if (overlay._dragMode === "nw") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
        }
        ToolTip.visible: handleNWMa.containsMouse && !overlay._dragging
        ToolTip.text: "Redimensiona el encuadre: hacia afuera lo amplía (aleja la cámara), hacia adentro lo reduce (acerca)"
        ToolTip.delay: 500
    }

    // NE corner — drag ↗ to zoom in (scale up around center)
    Rectangle {
        id: handleNE
        visible: !overlay.viewerModeActive
        width: 16; height: 16
        color: handleNEMa.containsMouse ? Qt.lighter(overlay.frameColor, 1.4) : overlay.frameColor
        border.color: "white"
        border.width: 1
        radius: 2
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 2
        z: 10
        scale: handleNEMa.pressed ? 0.90 : (handleNEMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: "\u2197"
            color: "white"
            font.pixelSize: 9
            font.weight: Font.Bold
        }
        MouseArea {
            id: handleNEMa
            anchors.fill: parent
            anchors.margins: -7
            cursorShape: Qt.SizeBDiagCursor
            hoverEnabled: true
            preventStealing: true
            onPressed: function(m) {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var cx = overlay.x + overlay.width / 2
                var cy = overlay.y + overlay.height / 2
                overlay._dragging     = true
                overlay._dragMode     = "ne"
                overlay._startDist    = Math.sqrt(Math.pow(p.x - cx, 2) + Math.pow(p.y - cy, 2))
                overlay._startZoom    = overlay.camera.appliedZoom || 1.0
                overlay._centerParent = Qt.point(cx, cy)
            }
            onPositionChanged: function(m) {
                if (!overlay._dragging || overlay._dragMode !== "ne") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var newDist = Math.sqrt(Math.pow(p.x - overlay._centerParent.x, 2) + Math.pow(p.y - overlay._centerParent.y, 2))
                var factor = overlay._startDist > 0 ? overlay._startDist / newDist : 1.0
                var newZoom = overlay._startZoom * factor
                newZoom = Math.max(0.01, Math.min(newZoom, 50))
                overlay.camera.appliedZoom = newZoom
            }
            onReleased: {
                if (overlay._dragMode === "ne") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
        }
        ToolTip.visible: handleNEMa.containsMouse && !overlay._dragging
        ToolTip.text: "Redimensiona el encuadre: hacia afuera lo amplía (aleja la cámara), hacia adentro lo reduce (acerca)"
        ToolTip.delay: 500
    }

    // SW corner — drag ↙ to zoom in (scale up around center)
    Rectangle {
        id: handleSW
        visible: !overlay.viewerModeActive
        width: 16; height: 16
        color: handleSWMa.containsMouse ? Qt.lighter(overlay.frameColor, 1.4) : overlay.frameColor
        border.color: "white"
        border.width: 1
        radius: 2
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 2
        anchors.bottomMargin: 2
        z: 10
        scale: handleSWMa.pressed ? 0.90 : (handleSWMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: "\u2199"
            color: "white"
            font.pixelSize: 9
            font.weight: Font.Bold
        }
        MouseArea {
            id: handleSWMa
            anchors.fill: parent
            anchors.margins: -7
            cursorShape: Qt.SizeBDiagCursor
            hoverEnabled: true
            preventStealing: true
            onPressed: function(m) {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var cx = overlay.x + overlay.width / 2
                var cy = overlay.y + overlay.height / 2
                overlay._dragging     = true
                overlay._dragMode     = "sw"
                overlay._startDist    = Math.sqrt(Math.pow(p.x - cx, 2) + Math.pow(p.y - cy, 2))
                overlay._startZoom    = overlay.camera.appliedZoom || 1.0
                overlay._centerParent = Qt.point(cx, cy)
            }
            onPositionChanged: function(m) {
                if (!overlay._dragging || overlay._dragMode !== "sw") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var p = mapToItem(overlay.parent, mouseX, mouseY)
                var newDist = Math.sqrt(Math.pow(p.x - overlay._centerParent.x, 2) + Math.pow(p.y - overlay._centerParent.y, 2))
                var factor = overlay._startDist > 0 ? overlay._startDist / newDist : 1.0
                var newZoom = overlay._startZoom * factor
                newZoom = Math.max(0.01, Math.min(newZoom, 50))
                overlay.camera.appliedZoom = newZoom
            }
            onReleased: {
                if (overlay._dragMode === "sw") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
        }
        ToolTip.visible: handleSWMa.containsMouse && !overlay._dragging
        ToolTip.text: "Redimensiona el encuadre: hacia afuera lo amplía (aleja la cámara), hacia adentro lo reduce (acerca)"
        ToolTip.delay: 500
    }

    // ── ROTATION handle (sits above the top edge, centered) ───
    Item {
        id: rotHandle
        visible: !overlay.viewerModeActive
        width: 22
        height: 36
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 6
        z: 10

        // Connecting line (from the top edge of the frame down to the
        // rotation handle's top)
        Rectangle {
            width: 1.5
            height: 6
            color: overlay.frameColor
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        // Handle dot
        Rectangle {
            width: 20; height: 20
            radius: 10
            color: rotMa.pressed ? Qt.lighter(overlay.frameColor, 1.3) : overlay.frameColor
            border.color: "white"
            border.width: 1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            scale: rotMa.pressed ? 1.1 : (rotMa.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
        }
        // Rotation icon
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -8
            text: "↻"
            color: "white"
            font.pixelSize: 12
            font.weight: Font.Bold
        }

        MouseArea {
            id: rotMa
            anchors.fill: parent
            anchors.margins: -7
            hoverEnabled: true
            cursorShape: Qt.CrossCursor
            preventStealing: true
            property real startAngle: 0
            onPressed: {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                overlay._dragging = true
                overlay._dragMode = "rotate"
                var cx = overlay.width  / 2.0
                var cy = overlay.height / 2.0
                // mapToItem uses the overlay's coord system
                var p = mapToItem(overlay, mouseX, mouseY)
                startAngle = Math.atan2(p.y - cy, p.x - cx) * 180.0 / Math.PI
                overlay._startRot = overlay.camera.appliedRotation || 0
            }
            onPositionChanged: {
                if (!overlay._dragging || overlay._dragMode !== "rotate") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var cx = overlay.width  / 2.0
                var cy = overlay.height / 2.0
                var p = mapToItem(overlay, mouseX, mouseY)
                var curAngle = Math.atan2(p.y - cy, p.x - cx) * 180.0 / Math.PI
                var delta = curAngle - startAngle
                var newRot = overlay._startRot + delta
                // Update the camera's rotation in real time. The
                // overlay's `rotation` property is bound to
                // camera.appliedRotation, so the frame visually
                // rotates immediately. The paper does NOT rotate.
                overlay.camera.appliedRotation = newRot
            }
            onReleased: {
                if (overlay._dragMode === "rotate") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
        }
        ToolTip.visible: rotMa.containsMouse && !overlay._dragging
        ToolTip.text: "Rota el encuadre alrededor de su centro"
        ToolTip.delay: 500
    }
}
