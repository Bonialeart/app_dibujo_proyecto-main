import QtQuick 2.15

// ══════════════════════════════════════════════════════════════
//  ANIMATION CAMERA  (paper-anchored model)
//  Virtual camera keyframed per-frame. The camera frame is a
//  rectangle ANCHORED TO THE PAPER: appliedX/appliedY are the
//  frame center in canvas coordinates, appliedZoom its size
//  (1.0 = 80% of the paper) and appliedRotation its angle.
//  Editing the frame NEVER pans the canvas view; the view is
//  only driven in viewerMode (export preview / playback lock).
//  - active: shows the viewfinder and follows the timeline.
//  - keyframes: list of { frameIdx, x, y, zoom, rotation,
//    easing, bz }, sorted asc. x/y in paper coordinates.
//  - addKeyframe() captures the camera's live state at the
//    current frame (replaces if a keyframe already exists).
//  - applyAt(frameIdx) interpolates (with easing) into the live
//    state; in viewerMode it also fits the view to the frame.
//  - serialize() / deserialize(arr) sync data between Simple
//    and Advanced timeline modes.
// ══════════════════════════════════════════════════════════════
Item {
    id: root

    // ── Public API ────────────────────────────────────────────
    property var   targetCanvas:     null
    property color accentColor:      "#6366f1"
    // Whether the camera is actively driving the canvas.
    property bool  active:          false
    property int   currentFrameIdx:  0
    property int   frameCount:       0
    property bool  isPlaying:        false
    property bool  isScrubbing:      false

    // Keyframes stored as an array of
    //   { frameIdx, x, y, zoom, rotation, easing, bz }
    // where `easing` is one of "linear" | "easeIn" | "easeOut" |
    // "easeInOut" | "bezier" (the curve of the segment LEAVING the
    // keyframe) and `bz` is [x1, y1, x2, y2] for custom bezier.
    // Sorted ascending by frameIdx. Empty array = no keyframes.
    property var keyframes: []

    // Currently selected keyframe in the timeline (-1 = none).
    // Shared across Simple / Advanced / Studio timelines so the
    // selection follows the user between modes.
    property int selectedFrameIdx: -1

    // "Modo Visor Real": when true, the viewfinder overlay renders
    // a letterbox mask (everything outside the camera frame is
    // darkened) and editing handles are hidden, previewing the
    // exact export framing.
    property bool viewerMode: false

    // "Camera ghosting" (onion skin for the camera): the viewfinder
    // overlay draws ghost frames at the previous / next keyframes.
    property bool ghostingEnabled: true

    // Motion path: dotted trajectory of the camera center between
    // keyframes, drawn by the viewfinder overlay.
    property bool motionPathEnabled: true

    // The camera's own rotation value (viewfinder-frame-only,
    // doesn't affect the canvas content). Updated by the
    // viewfinder overlay during rotation drag.
    property real currentRotation: 0.0

    // Suppress automatic applyAt() on keyframe changes.
    // Set by the viewfinder overlay during live corner/pan/rotate
    // drags so that the canvas view isn't disturbed until the
    // user finishes the gesture.
    property bool _suppressApply: false

    // Convenience read-only: number of keyframes
    property int keyframeCount: keyframes.length

    // ── Live camera state (PAPER-ANCHORED) ────────────────────
    // appliedX / appliedY = center of the camera frame in CANVAS
    // (paper) coordinates. appliedZoom = camera zoom (1.0 = the
    // frame covers 80% of the paper). appliedRotation = frame
    // angle in degrees. This state is fully decoupled from the
    // canvas view: moving the camera frame never pans the canvas.
    // The canvas view is only driven in viewerMode (export
    // preview) via _driveView().
    property real appliedZoom:     1.0
    property real appliedX:        0
    property real appliedY:        0
    property real appliedRotation: 0.0

    // One-shot init: center the frame on the paper the first time
    // a canvas with valid dimensions is available.
    property bool _stateInitialized: false
    function _initDefaults() {
        if (!targetCanvas || _stateInitialized) return
        if (targetCanvas.canvasWidth > 0 && targetCanvas.canvasHeight > 0) {
            appliedX = targetCanvas.canvasWidth / 2
            appliedY = targetCanvas.canvasHeight / 2
            appliedZoom = 1.0
            appliedRotation = 0.0
            _stateInitialized = true
        }
    }
    function resetState() {
        _stateInitialized = false
        _initDefaults()
    }
    Component.onCompleted: _initDefaults()

    // ── Signals ───────────────────────────────────────────────
    signal appliedAtFrame(int frameIdx, real x, real y, real zoom, real rotation)
    signal keyframeAdded(int frameIdx)
    signal keyframeRemoved(int frameIdx)
    signal keyframeUpdated(int frameIdx)

    // ── Helpers ───────────────────────────────────────────────
    function _sortKeyframes() {
        // Bubble sort by frameIdx (keyframes are usually a tiny array)
        var arr = keyframes
        for (var i = 0; i < arr.length - 1; i++) {
            for (var j = 0; j < arr.length - 1 - i; j++) {
                if (arr[j].frameIdx > arr[j+1].frameIdx) {
                    var t = arr[j]; arr[j] = arr[j+1]; arr[j+1] = t
                }
            }
        }
        keyframes = arr
    }

    function _captureCurrentState() {
        // The camera's own live state (paper-anchored frame), NOT
        // the canvas view: panning the canvas to look around must
        // never change what the camera records.
        _initDefaults()
        var z = appliedZoom
        if (z === undefined || z <= 0) z = 1.0
        return { x: appliedX, y: appliedY, zoom: z,
                 rotation: appliedRotation || 0.0 }
    }

    function _findIndexOfFrame(frameIdx) {
        for (var i = 0; i < keyframes.length; i++) {
            if (keyframes[i].frameIdx === frameIdx) return i
        }
        return -1
    }

    // Normalise an angle to (-180, 180]
    function _normAngle(a) {
        while (a > 180) a -= 360
        while (a <= -180) a += 360
        return a
    }

    // Linear interpolation between two angles using the
    // shortest arc (avoids the +179° -> -179° spin).
    function _lerpAngle(a, b, t) {
        var diff = _normAngle(b - a)
        return a + diff * t
    }

    // ── Easing curves ─────────────────────────────────────────
    // Cubic bezier easing: solves x(u) = t via Newton-Raphson and
    // returns y(u). Mirrors evalCubicBezier() in animation_track.h
    // so QML playback matches the C++ interpolator.
    function _cubicBezier(t, x1, y1, x2, y2) {
        if (t <= 0) return 0
        if (t >= 1) return 1
        var u = t
        for (var i = 0; i < 8; i++) {
            var omu = 1 - u
            var x = 3*u*omu*omu*x1 + 3*u*u*omu*x2 + u*u*u
            var dx = 3*omu*omu*x1 + 6*u*omu*(x2 - x1) + 3*u*u*(1 - x2)
            var err = x - t
            if (Math.abs(err) < 1e-5 || Math.abs(dx) < 1e-6) break
            u -= err / dx
            u = Math.max(0, Math.min(1, u))
        }
        var omu2 = 1 - u
        return 3*u*omu2*omu2*y1 + 3*u*u*omu2*y2 + u*u*u
    }

    // Applies the easing curve named `easing` to progress t.
    function applyEasing(t, easing, bz) {
        switch (easing) {
        case "easeIn":    return _cubicBezier(t, 0.42, 0.0, 1.0, 1.0)
        case "easeOut":   return _cubicBezier(t, 0.0, 0.0, 0.58, 1.0)
        case "easeInOut": return _cubicBezier(t, 0.42, 0.0, 0.58, 1.0)
        case "bezier":
            if (bz && bz.length === 4)
                return _cubicBezier(t, bz[0], bz[1], bz[2], bz[3])
            return t
        default:          return t
        }
    }

    function _kfEasing(k)  { return (k && k.easing !== undefined) ? k.easing : "linear" }
    function _kfBezier(k)  { return (k && k.bz !== undefined) ? k.bz : [0.42, 0.0, 0.58, 1.0] }

    // ── Public methods ────────────────────────────────────────
    function hasKeyframeAt(frameIdx) {
        return _findIndexOfFrame(frameIdx) >= 0
    }

    // Adds or replaces a keyframe at the current frame with the
    // current canvas state.
    function addKeyframe() {
        if (!targetCanvas) return
        var st = _captureCurrentState()
        addKeyframeAt(currentFrameIdx, st.x, st.y, st.zoom, st.rotation)
    }

    function addKeyframeAt(frameIdx, x, y, zoom, rotation) {
        if (frameIdx < 0) return
        if (rotation === undefined) rotation = 0.0
        var arr = keyframes.slice()
        // Remove existing keyframe at this index (preserving its easing)
        var easing = "linear"
        var bz = [0.42, 0.0, 0.58, 1.0]
        for (var i = arr.length - 1; i >= 0; i--) {
            if (arr[i].frameIdx === frameIdx) {
                easing = _kfEasing(arr[i])
                bz = _kfBezier(arr[i])
                arr.splice(i, 1)
            }
        }
        arr.push({ frameIdx: frameIdx, x: x, y: y, zoom: zoom, rotation: rotation,
                   easing: easing, bz: bz })
        keyframes = arr
        _sortKeyframes()
        keyframesChanged()
        keyframeAdded(frameIdx)
    }

    // Updates the keyframe at the current frame with the current
    // canvas state. If no keyframe exists, behaves like addKeyframe().
    function updateKeyframe() {
        if (!targetCanvas) return
        if (!hasKeyframeAt(currentFrameIdx)) { addKeyframe(); return }
        var st = _captureCurrentState()
        var arr = keyframes.slice()
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].frameIdx === currentFrameIdx) {
                arr[i] = { frameIdx: currentFrameIdx, x: st.x, y: st.y,
                           zoom: st.zoom, rotation: st.rotation,
                           easing: _kfEasing(arr[i]), bz: _kfBezier(arr[i]) }
                break
            }
        }
        keyframes = arr
        keyframesChanged()
        keyframeUpdated(currentFrameIdx)
    }

    // Direct setter used by the viewfinder overlay: writes a
    // specific (x,y,zoom,rotation) tuple to the keyframe at the
    // given frame (or adds it if missing).
    function setKeyframeState(frameIdx, x, y, zoom, rotation) {
        if (rotation === undefined) rotation = 0.0
        var arr = keyframes.slice()
        var found = false
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].frameIdx === frameIdx) {
                arr[i] = { frameIdx: frameIdx, x: x, y: y, zoom: zoom, rotation: rotation,
                           easing: _kfEasing(arr[i]), bz: _kfBezier(arr[i]) }
                found = true
                break
            }
        }
        if (!found) {
            arr.push({ frameIdx: frameIdx, x: x, y: y, zoom: zoom, rotation: rotation,
                       easing: "linear", bz: [0.42, 0.0, 0.58, 1.0] })
            _sortKeyframes()
        }
        keyframes = arr
        keyframesChanged()
        if (found) keyframeUpdated(frameIdx)
        else keyframeAdded(frameIdx)
    }

    // Sets the interpolation curve of the segment leaving frameIdx.
    // easing: "linear" | "easeIn" | "easeOut" | "easeInOut" | "bezier"
    // bz (optional): [x1, y1, x2, y2] for "bezier".
    function setKeyframeEasing(frameIdx, easing, bz) {
        var idx = _findIndexOfFrame(frameIdx)
        if (idx < 0) return
        var arr = keyframes.slice()
        var k = arr[idx]
        arr[idx] = { frameIdx: k.frameIdx, x: k.x, y: k.y, zoom: k.zoom,
                     rotation: k.rotation, easing: easing,
                     bz: (bz && bz.length === 4) ? bz : _kfBezier(k) }
        keyframes = arr
        keyframesChanged()
        keyframeUpdated(frameIdx)
    }

    function getKeyframeAt(frameIdx) {
        var idx = _findIndexOfFrame(frameIdx)
        return idx >= 0 ? keyframes[idx] : null
    }

    // Moves a keyframe to another frame (timeline drag & drop).
    // If the destination already has a keyframe it is replaced.
    // Returns true on success.
    function moveKeyframe(fromFrame, toFrame) {
        if (toFrame < 0 || fromFrame === toFrame) return false
        var idx = _findIndexOfFrame(fromFrame)
        if (idx < 0) return false
        var arr = keyframes.slice()
        var k = arr[idx]
        arr.splice(idx, 1)
        for (var i = arr.length - 1; i >= 0; i--) {
            if (arr[i].frameIdx === toFrame) arr.splice(i, 1)
        }
        arr.push({ frameIdx: toFrame, x: k.x, y: k.y, zoom: k.zoom,
                   rotation: k.rotation, easing: _kfEasing(k), bz: _kfBezier(k) })
        keyframes = arr
        _sortKeyframes()
        if (selectedFrameIdx === fromFrame) selectedFrameIdx = toFrame
        keyframesChanged()
        keyframeUpdated(toFrame)
        return true
    }

    // Duplicates the keyframe at frameIdx onto toFrame. If toFrame
    // is omitted, the next free frame after frameIdx is used.
    // Returns the destination frame, or -1 on failure.
    function duplicateKeyframe(frameIdx, toFrame) {
        var idx = _findIndexOfFrame(frameIdx)
        if (idx < 0) return -1
        if (toFrame === undefined || toFrame < 0) {
            toFrame = frameIdx + 1
            while (hasKeyframeAt(toFrame)) toFrame++
            if (frameCount > 0 && toFrame >= frameCount) return -1
        }
        var k = keyframes[idx]
        addKeyframeAt(toFrame, k.x, k.y, k.zoom, k.rotation)
        setKeyframeEasing(toFrame, _kfEasing(k), _kfBezier(k))
        return toFrame
    }

    function removeKeyframeAt(frameIdx) {
        var idx = _findIndexOfFrame(frameIdx)
        if (idx < 0) return
        var arr = keyframes.slice()
        arr.splice(idx, 1)
        keyframes = arr
        if (selectedFrameIdx === frameIdx) selectedFrameIdx = -1
        keyframesChanged()
        keyframeRemoved(frameIdx)
    }

    function removeKeyframeAtCurrent() {
        removeKeyframeAt(currentFrameIdx)
    }

    function clearKeyframes() {
        keyframes = []
        selectedFrameIdx = -1
        keyframesChanged()
    }

    // Returns the interpolated state at frameIdx, or null if no
    // keyframes exist.
    function getStateAtFrame(frameIdx) {
        if (keyframes.length === 0) return null

        // Clamp to first / last keyframe if outside range
        if (frameIdx <= keyframes[0].frameIdx) {
            var a = keyframes[0]
            return { x: a.x, y: a.y, zoom: a.zoom, rotation: a.rotation }
        }
        var last = keyframes[keyframes.length - 1]
        if (frameIdx >= last.frameIdx) {
            return { x: last.x, y: last.y, zoom: last.zoom, rotation: last.rotation }
        }

        // Find surrounding pair
        var before = keyframes[0]
        var after  = keyframes[keyframes.length - 1]
        for (var i = 0; i < keyframes.length - 1; i++) {
            if (keyframes[i].frameIdx <= frameIdx && keyframes[i+1].frameIdx >= frameIdx) {
                before = keyframes[i]
                after  = keyframes[i+1]
                break
            }
        }
        if (before.frameIdx === after.frameIdx) {
            return { x: before.x, y: before.y, zoom: before.zoom, rotation: before.rotation }
        }
        var t = (frameIdx - before.frameIdx) / (after.frameIdx - before.frameIdx)
        // Apply the easing curve of the segment's leading keyframe
        t = applyEasing(t, _kfEasing(before), _kfBezier(before))
        return {
            x:        before.x        + (after.x        - before.x)        * t,
            y:        before.y        + (after.y        - before.y)        * t,
            zoom:     before.zoom     + (after.zoom     - before.zoom)     * t,
            rotation: _lerpAngle(before.rotation, after.rotation, t)
        }
    }

    // Samples the eased camera trajectory between the first and
    // last keyframe. Returns a list of { x, y, zoom, rotation,
    // frameIdx, isKey } — used by the viewfinder overlay to draw
    // the motion path. samplesPerSegment defaults to 8.
    function getMotionPathSamples(samplesPerSegment) {
        if (keyframes.length < 2) return []
        var n = (samplesPerSegment && samplesPerSegment > 0) ? samplesPerSegment : 8
        var out = []
        for (var i = 0; i < keyframes.length - 1; i++) {
            var a = keyframes[i], b = keyframes[i+1]
            var span = b.frameIdx - a.frameIdx
            for (var s = 0; s < n; s++) {
                var f = a.frameIdx + span * (s / n)
                var st = getStateAtFrame(f)
                out.push({ x: st.x, y: st.y, zoom: st.zoom, rotation: st.rotation,
                           frameIdx: f, isKey: s === 0 })
            }
        }
        var last = keyframes[keyframes.length - 1]
        out.push({ x: last.x, y: last.y, zoom: last.zoom, rotation: last.rotation,
                   frameIdx: last.frameIdx, isKey: true })
        return out
    }

    // Applies the interpolated state at frameIdx to the camera's
    // live state (the viewfinder frame follows it over the paper).
    // The canvas view itself is only driven in viewerMode, where
    // the user wants to preview the export framing.
    function applyAt(frameIdx) {
        if (!active || !targetCanvas) return
        var st = getStateAtFrame(frameIdx)
        if (!st) return
        appliedX        = st.x
        appliedY        = st.y
        appliedZoom     = st.zoom
        appliedRotation = st.rotation
        if (viewerMode) _driveView()
        appliedAtFrame(frameIdx, st.x, st.y, st.zoom, st.rotation)
    }

    // "Modo Visor Real": fits the camera's framed region to the
    // viewport (atomic zoom+pan via updateViewportTransform — one
    // repaint, no half-applied jumps during playback).
    function _driveView() {
        if (!targetCanvas) return
        var vw = targetCanvas.width, vh = targetCanvas.height
        if (vw <= 0 || vh <= 0) return
        var cz = (appliedZoom && appliedZoom > 0) ? appliedZoom : 1.0
        var fw = targetCanvas.canvasWidth  * 0.80 / cz
        var fh = targetCanvas.canvasHeight * 0.80 / cz
        if (fw <= 0 || fh <= 0) return
        var z = Math.min(vw / fw, vh / fh)
        z = Math.max(0.05, Math.min(20.0, z))
        var ox = (vw / 2) / z - appliedX
        var oy = (vh / 2) / z - appliedY
        if (targetCanvas.updateViewportTransform !== undefined) {
            targetCanvas.updateViewportTransform(
                z, targetCanvas.canvasRotation, Qt.point(ox, oy))
        } else {
            targetCanvas.canvasOffset = Qt.point(ox, oy)
            targetCanvas.zoomLevel  = z
        }
        // Note: canvasRotation is left untouched — the camera
        // rotation only affects the viewfinder frame.
    }

    onViewerModeChanged: if (viewerMode && active) _driveView()

    function applyAtCurrent() { applyAt(currentFrameIdx) }

    // ── Serialization (for Simple ↔ Advanced sync) ────────────
    function serialize() {
        var out = []
        for (var i = 0; i < keyframes.length; i++) {
            var k = keyframes[i]
            out.push({ frameIdx: k.frameIdx, x: k.x, y: k.y,
                       zoom: k.zoom,
                       rotation: k.rotation !== undefined ? k.rotation : 0.0,
                       easing: _kfEasing(k),
                       bz: _kfBezier(k) })
        }
        return out
    }

    function deserialize(arr) {
        if (!arr || !(arr instanceof Array)) {
            keyframes = []
        } else {
            var copy = []
            for (var i = 0; i < arr.length; i++) {
                var k = arr[i]
                if (k && k.frameIdx !== undefined) {
                    copy.push({
                        frameIdx: k.frameIdx,
                        x:    k.x    !== undefined ? k.x    : 0,
                        y:    k.y    !== undefined ? k.y    : 0,
                        zoom: k.zoom !== undefined ? k.zoom : 1.0,
                        rotation: k.rotation !== undefined ? k.rotation : 0.0,
                        easing: _kfEasing(k),
                        bz: _kfBezier(k)
                    })
                }
            }
            keyframes = copy
            _sortKeyframes()
        }
        keyframesChanged()
    }

    // ── Reactivity ────────────────────────────────────────────
    onCurrentFrameIdxChanged: if (active && !_suppressApply) applyAtCurrent()
    onActiveChanged: {
        _initDefaults()
        if (active && !_suppressApply) applyAtCurrent()
    }
    onTargetCanvasChanged: {
        _stateInitialized = false
        _initDefaults()
        if (active && !_suppressApply) applyAtCurrent()
    }
    onKeyframesChanged:       if (active && !_suppressApply) applyAtCurrent()

    // ── Public read-only helpers used by the timeline UI ──────
    // Returns a list of {frameIdx, slotX, slotWidth} for each
    // keyframe, so the timeline can draw diamonds/pills.
    // slotToX: function that converts a frame index to a pixel
    //          x-position in the timeline (passed by the caller).
    function getKeyframeMarkers(slotToX) {
        var out = []
        for (var i = 0; i < keyframes.length; i++) {
            var k = keyframes[i]
            var x = slotToX ? slotToX(k.frameIdx) : k.frameIdx
            out.push({ frameIdx: k.frameIdx, slotX: x })
        }
        return out
    }

    // ── Notification helper (delegates to canvas if available)
    function notify(msg, type) {
        if (targetCanvas && targetCanvas.notificationRequested)
            targetCanvas.notificationRequested(msg, type || "info")
    }
}
