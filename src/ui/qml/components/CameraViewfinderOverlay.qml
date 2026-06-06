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

    // ── Internal drag state ───────────────────────────────────
    property bool  _dragging:    false
    property string _dragMode:   ""   // "pan" | "nw"|"ne"|"sw"|"se" | "rotate"
    property point _startMouse:  Qt.point(0, 0)
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

    // ── The frame rectangle (visualizes the camera's view) ─────
    Rectangle {
        id: frame
        anchors.fill: parent
        color: "transparent"
        border.color: overlay.frameColor
        border.width: 1
        // Cosmetic: dashed inner stroke
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: "transparent"
            border.color: overlay.frameColor
            border.width: 1
            opacity: 0.35
        }
    }

    // ── Center crosshair (helps see the rotation pivot) ───────
    Item {
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

    // ── HUD: current camera state (top-left corner) ───────────
    Item {
        x: 10; y: 10
        visible: overlay.camera !== null
        Column {
            spacing: 2
            Text {
                text: overlay.camera && overlay.camera.targetCanvas
                    ? "Z " + (overlay.camera.targetCanvas.zoomLevel * 100).toFixed(0) + "%"
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

    // ── PAN: drag the center of the frame ─────────────────────
    Item {
        anchors.fill: parent
        MouseArea {
            id: panArea
            anchors.fill: parent
            cursorShape: overlay._dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            preventStealing: true
            z: 1
            propagateComposedEvents: false
            onPressed: function(m) {
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                overlay._dragging   = true
                overlay._dragMode   = "pan"
                overlay._startMouse = Qt.point(m.x, m.y)
                overlay._startView  = Qt.point(
                    overlay.camera.appliedX,
                    overlay.camera.appliedY
                )
            }
            onPositionChanged: function(m) {
                if (!overlay._dragging || overlay._dragMode !== "pan") return
                if (!overlay.camera || !overlay.camera.targetCanvas) return
                var z = overlay.camera.targetCanvas.zoomLevel || 1.0
                overlay.camera.appliedX = overlay._startView.x + (m.x - overlay._startMouse.x) / z
                overlay.camera.appliedY = overlay._startView.y + (m.y - overlay._startMouse.y) / z
            }
            onReleased: {
                if (overlay._dragMode === "pan") {
                    overlay._dragging = false
                    overlay._dragMode = ""
                    overlay._commitKeyframe()
                }
            }
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
        width: 12; height: 12
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
        ToolTip.text: "Zoom: arrastra hacia afuera (↘) para alejar, hacia adentro (↖) para acercar"
        ToolTip.delay: 500
    }

    // NW corner — drag ↖ to zoom in (scale up around center)
    Rectangle {
        id: handleNW
        width: 12; height: 12
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
        ToolTip.text: "Zoom: arrastra hacia afuera (↖) para alejar, hacia adentro (↘) para acercar"
        ToolTip.delay: 500
    }

    // NE corner — drag ↗ to zoom in (scale up around center)
    Rectangle {
        id: handleNE
        width: 12; height: 12
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
        ToolTip.text: "Zoom: arrastra hacia afuera (↗) para alejar, hacia adentro (↙) para acercar"
        ToolTip.delay: 500
    }

    // SW corner — drag ↙ to zoom in (scale up around center)
    Rectangle {
        id: handleSW
        width: 12; height: 12
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
        ToolTip.text: "Zoom: arrastra hacia afuera (↙) para alejar, hacia adentro (↗) para acercar"
        ToolTip.delay: 500
    }

    // ── ROTATION handle (sits above the top edge, centered) ───
    Item {
        id: rotHandle
        width: 16
        height: 32
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4
        z: 10

        // Connecting line (from the top edge of the frame down to the
        // rotation handle's top)
        Rectangle {
            width: 1.5
            height: 4
            color: overlay.frameColor
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        // Handle dot
        Rectangle {
            width: 16; height: 16
            radius: 8
            color: overlay.frameColor
            border.color: "white"
            border.width: 1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        // Rotation icon
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -8
            text: "↻"
            color: "white"
            font.pixelSize: 10
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
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
    }
}
