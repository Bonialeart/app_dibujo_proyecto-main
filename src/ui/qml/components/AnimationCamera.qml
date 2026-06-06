import QtQuick 2.15

// ══════════════════════════════════════════════════════════════
//  ANIMATION CAMERA
//  Virtual camera that can be keyframed per-frame to drive
//  the canvas viewOffset (pan), zoom and rotation during
//  playback. Linear interpolation between keyframes.
//  - active: when true, the canvas is driven by the camera.
//  - keyframes: list of { frameIdx, x, y, zoom, rotation },
//    sorted asc.
//  - addKeyframe() captures the current canvas state at the
//    current frame (replaces if a keyframe already exists).
//  - removeKeyframeAt(frameIdx) removes a keyframe.
//  - applyAt(frameIdx) computes the interpolated state and
//    writes it to targetCanvas.viewOffset / zoomLevel / canvasRotation.
//  - serialize() / deserialize(arr) are used to sync data
//    between Simple and Advanced timeline modes.
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

    // Keyframes stored as an array of { frameIdx, x, y, zoom, rotation }
    // Sorted ascending by frameIdx. Empty array = no keyframes.
    property var keyframes: []

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

    // Last applied state (for read by UI to show current zoom% etc.)
    property real appliedZoom:     1.0
    property real appliedX:        0
    property real appliedY:        0
    property real appliedRotation: 0.0

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
        if (!targetCanvas) return { x: 0, y: 0, zoom: 1.0, rotation: 0.0 }
        var off = targetCanvas.viewOffset
        var x = (off && off.x !== undefined) ? off.x : 0
        var y = (off && off.y !== undefined) ? off.y : 0
        var z = targetCanvas.zoomLevel
        if (z === undefined || z <= 0) z = 1.0
        // The camera's rotation is independent of the canvas's
        // canvasRotation property (which is for the Krita-style
        // canvas rotate gesture). Use the camera's own value.
        return { x: x, y: y, zoom: z, rotation: currentRotation }
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
        // Remove existing keyframe at this index
        for (var i = arr.length - 1; i >= 0; i--) {
            if (arr[i].frameIdx === frameIdx) arr.splice(i, 1)
        }
        arr.push({ frameIdx: frameIdx, x: x, y: y, zoom: zoom, rotation: rotation })
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
                           zoom: st.zoom, rotation: st.rotation }
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
                arr[i] = { frameIdx: frameIdx, x: x, y: y, zoom: zoom, rotation: rotation }
                found = true
                break
            }
        }
        if (!found) {
            arr.push({ frameIdx: frameIdx, x: x, y: y, zoom: zoom, rotation: rotation })
            _sortKeyframes()
        }
        keyframes = arr
        keyframesChanged()
        if (found) keyframeUpdated(frameIdx)
        else keyframeAdded(frameIdx)
    }

    function removeKeyframeAt(frameIdx) {
        var idx = _findIndexOfFrame(frameIdx)
        if (idx < 0) return
        var arr = keyframes.slice()
        arr.splice(idx, 1)
        keyframes = arr
        keyframesChanged()
        keyframeRemoved(frameIdx)
    }

    function removeKeyframeAtCurrent() {
        removeKeyframeAt(currentFrameIdx)
    }

    function clearKeyframes() {
        keyframes = []
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
        return {
            x:        before.x        + (after.x        - before.x)        * t,
            y:        before.y        + (after.y        - before.y)        * t,
            zoom:     before.zoom     + (after.zoom     - before.zoom)     * t,
            rotation: _lerpAngle(before.rotation, after.rotation, t)
        }
    }

    // Applies the interpolated state at frameIdx to the canvas.
    // Pan / zoom are written to the canvas. Rotation is NOT
    // (the camera rotation is a viewfinder-frame-only effect).
    function applyAt(frameIdx) {
        if (!active || !targetCanvas) return
        var st = getStateAtFrame(frameIdx)
        if (!st) return
        targetCanvas.canvasOffset = Qt.point(st.x, st.y)
        targetCanvas.zoomLevel  = st.zoom
        // Note: do NOT write targetCanvas.canvasRotation here.
        // The camera rotation only affects the viewfinder frame.
        appliedX        = st.x
        appliedY        = st.y
        appliedZoom     = st.zoom
        appliedRotation = st.rotation
        appliedAtFrame(frameIdx, st.x, st.y, st.zoom, st.rotation)
    }

    function applyAtCurrent() { applyAt(currentFrameIdx) }

    // ── Serialization (for Simple ↔ Advanced sync) ────────────
    function serialize() {
        var out = []
        for (var i = 0; i < keyframes.length; i++) {
            var k = keyframes[i]
            out.push({ frameIdx: k.frameIdx, x: k.x, y: k.y,
                       zoom: k.zoom,
                       rotation: k.rotation !== undefined ? k.rotation : 0.0 })
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
                        rotation: k.rotation !== undefined ? k.rotation : 0.0
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
    onActiveChanged:          if (active && !_suppressApply) applyAtCurrent()
    onTargetCanvasChanged:    if (active && !_suppressApply) applyAtCurrent()
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
