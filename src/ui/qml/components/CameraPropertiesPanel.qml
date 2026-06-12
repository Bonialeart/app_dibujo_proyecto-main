import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts 1.15

// ══════════════════════════════════════════════════════════════
//  CAMERA PROPERTIES PANEL
//  Modal popup that lets the user edit the camera's
//  position, zoom and rotation numerically. The values
//  reflect what's currently visible (interpolated) and the
//  edits go to the current frame's keyframe (added if missing).
// ══════════════════════════════════════════════════════════════
Popup {
    id: panel
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0
    width: 340
    height: _easingBuf === "bezier" ? 640 : 500
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    anchors.centerIn: parent
    z: 10000
    background: Rectangle {
        color: "#1a1a20"
        radius: 10
        border.color: "#3a3a44"
        border.width: 1
    }

    // ── Public API ────────────────────────────────────────────
    property var camera: null
    // Buffers for the text fields (string-typed)
    property string _xBuf: ""
    property string _yBuf: ""
    property string _zBuf: ""
    property string _rBuf: ""
    // Interpolation buffers (segment leaving the current keyframe)
    property string _easingBuf: "linear"
    property var    _bzBuf: [0.42, 0.0, 0.58, 1.0]

    readonly property var easingOptions: [
        { key: "linear",    label: "Lineal" },
        { key: "easeIn",    label: "Ease-In" },
        { key: "easeOut",   label: "Ease-Out" },
        { key: "easeInOut", label: "Ease-In-Out" },
        { key: "bezier",    label: "Bezier" }
    ]

    // ── Sync buffers from the camera's live state ─────────────
    // (paper-anchored frame: X/Y = frame center in canvas coords)
    function _sync() {
        if (!camera) return
        _xBuf = (camera.appliedX !== undefined) ? camera.appliedX.toFixed(1) : "0.0"
        _yBuf = (camera.appliedY !== undefined) ? camera.appliedY.toFixed(1) : "0.0"
        var z = camera.appliedZoom
        _zBuf = (z && z > 0) ? (z * 100).toFixed(1) : "100.0"
        _rBuf = (camera.appliedRotation || 0).toFixed(1)
        var k = camera.getKeyframeAt ? camera.getKeyframeAt(camera.currentFrameIdx) : null
        _easingBuf = (k && k.easing !== undefined) ? k.easing : "linear"
        _bzBuf = (k && k.bz !== undefined && k.bz.length === 4)
            ? k.bz.slice() : [0.42, 0.0, 0.58, 1.0]
        bezierEditor.requestPaint()
    }

    onOpened: _sync()

    // ── Commit the edited values to the camera's current keyframe
    function _commit() {
        if (!camera) return
        var nx = parseFloat(_xBuf)
        var ny = parseFloat(_yBuf)
        var nz = parseFloat(_zBuf) / 100.0
        var nr = parseFloat(_rBuf)
        if (isNaN(nx) || isNaN(ny) || isNaN(nz) || isNaN(nr)) {
            // Bad input — just resync and bail
            _sync()
            return
        }
        nz = Math.max(0.05, Math.min(20.0, nz))
        // Update the camera's live state (the frame moves on the
        // paper; the canvas view is never touched here)
        camera.appliedX = nx
        camera.appliedY = ny
        camera.appliedZoom = nz
        camera.appliedRotation = nr
        // Commit (add or replace) a keyframe at the current frame,
        // then store its interpolation curve.
        camera.addKeyframeAt(camera.currentFrameIdx, nx, ny, nz, nr)
        camera.setKeyframeEasing(camera.currentFrameIdx, _easingBuf, _bzBuf.slice())
        panel.close()
    }

    function _reset() {
        if (!camera) return
        camera.active = false
        camera.viewerMode = false
        camera.clearKeyframes()
        camera.resetState()
        _sync()
    }

    // ── UI ────────────────────────────────────────────────────
    contentItem: ColumnLayout {
        id: contentCol
        spacing: 0
        anchors.fill: parent
        anchors.margins: 0

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Rectangle { anchors.fill: parent; color: "#22222a" }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text { text: "🎥"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Propiedades de la Cámara"
                    color: "white"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "Frame " + (panel.camera ? panel.camera.currentFrameIdx : 0)
                color: "#888"
                font.pixelSize: 10
            }
        }

        // Hint
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Text {
                anchors.centerIn: parent
                text: panel.camera && panel.camera.hasKeyframeAt(panel.camera.currentFrameIdx)
                      ? "Editando keyframe existente"
                      : "Creará un keyframe en el frame actual al confirmar"
                color: "#888"
                font.pixelSize: 10
                font.italic: true
            }
        }

        // Position X / Y
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 4
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            Text { text: "Centro X (lienzo)"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
            TextField {
                id: xField
                Layout.fillWidth: true
                text: panel._xBuf
                onTextChanged: if (activeFocus) panel._xBuf = text
                onActiveFocusChanged: if (!activeFocus) text = panel._xBuf
                selectByMouse: true
                horizontalAlignment: TextInput.AlignRight
                background: Rectangle {
                    color: "#0c0c10"
                    border.color: xField.activeFocus ? "#22d3ee" : "#3a3a44"
                    border.width: 1
                    radius: 4
                }
                color: "white"
                font.pixelSize: 12
                padding: 6
            }

            Text { text: "Centro Y (lienzo)"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
            TextField {
                id: yField
                Layout.fillWidth: true
                text: panel._yBuf
                onTextChanged: if (activeFocus) panel._yBuf = text
                onActiveFocusChanged: if (!activeFocus) text = panel._yBuf
                selectByMouse: true
                horizontalAlignment: TextInput.AlignRight
                background: Rectangle {
                    color: "#0c0c10"
                    border.color: yField.activeFocus ? "#22d3ee" : "#3a3a44"
                    border.width: 1
                    radius: 4
                }
                color: "white"
                font.pixelSize: 12
                padding: 6
            }

            Text { text: "Zoom de cámara %"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
            TextField {
                id: zField
                Layout.fillWidth: true
                text: panel._zBuf
                onTextChanged: if (activeFocus) panel._zBuf = text
                onActiveFocusChanged: if (!activeFocus) text = panel._zBuf
                selectByMouse: true
                horizontalAlignment: TextInput.AlignRight
                background: Rectangle {
                    color: "#0c0c10"
                    border.color: zField.activeFocus ? "#22d3ee" : "#3a3a44"
                    border.width: 1
                    radius: 4
                }
                color: "white"
                font.pixelSize: 12
                padding: 6
            }

            Text { text: "Rotación (°)"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
            TextField {
                id: rField
                Layout.fillWidth: true
                text: panel._rBuf
                onTextChanged: if (activeFocus) panel._rBuf = text
                onActiveFocusChanged: if (!activeFocus) text = panel._rBuf
                selectByMouse: true
                horizontalAlignment: TextInput.AlignRight
                background: Rectangle {
                    color: "#0c0c10"
                    border.color: rField.activeFocus ? "#22d3ee" : "#3a3a44"
                    border.width: 1
                    radius: 4
                }
                color: "white"
                font.pixelSize: 12
                padding: 6
            }
        }

        // Center of rotation info (read-only — always canvas center)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 6
            Rectangle { anchors.fill: parent; color: "#0c0c10"; radius: 4; border.color: "#2a2a32"; border.width: 1 }
            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                Text { text: "Centro de rotación:"; color: "#888"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: panel.camera
                        ? (panel.camera.appliedX || 0).toFixed(0)
                          + ", "
                          + (panel.camera.appliedY || 0).toFixed(0)
                        : "—"
                    color: "#cbd5e1"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { Layout.fillWidth: true }
                Text { text: "(centro del encuadre)"; color: "#666"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter; font.italic: true }
            }
        }

        // ── Interpolation (easing) ────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            Layout.leftMargin: 16
            Layout.topMargin: 10
            Text {
                text: "INTERPOLACIÓN HASTA EL SIGUIENTE KEYFRAME"
                color: "#52525b"; font.pixelSize: 8; font.weight: Font.Bold
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Row {
                anchors.fill: parent
                spacing: 5
                Repeater {
                    model: panel.easingOptions
                    Rectangle {
                        required property var modelData
                        property bool isAct: panel._easingBuf === modelData.key
                        width: easeTxt.implicitWidth + 14
                        height: 24; radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: isAct ? Qt.rgba(0.51, 0.55, 0.97, 0.22) : "#0c0c10"
                        border.color: isAct ? "#818cf8" : "#3a3a44"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Text {
                            id: easeTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            color: isAct ? "#c7d2fe" : "#9ca3af"
                            font.pixelSize: 9
                            font.weight: isAct ? Font.DemiBold : Font.Medium
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                panel._easingBuf = modelData.key
                                bezierEditor.requestPaint()
                            }
                        }
                    }
                }
            }
        }

        // ── Bezier curve editor (only for "bezier") ───────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: panel._easingBuf === "bezier" ? 150 : 0
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: panel._easingBuf === "bezier" ? 6 : 0
            clip: true
            visible: Layout.preferredHeight > 0
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                color: "#0c0c10"; radius: 6
                border.color: "#2a2a32"; border.width: 1
            }

            // Plot area (with margins inside the box)
            Item {
                id: bzPlot
                anchors.fill: parent
                anchors.margins: 14

                function toPx(v)  { return v * width }
                function toPy(v)  { return height - v * height }
                function fromPx(px) { return Math.max(0, Math.min(1, px / width)) }
                function fromPy(py) { return Math.max(-0.4, Math.min(1.4, (height - py) / height)) }

                Canvas {
                    id: bezierEditor
                    anchors.fill: parent
                    renderTarget: Canvas.Image
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        // Grid
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06)
                        ctx.lineWidth = 1
                        for (var g = 0; g <= 4; g++) {
                            var gx = width * g / 4, gy = height * g / 4
                            ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke()
                        }

                        var bz = panel._bzBuf
                        var x0 = 0, y0 = height, x3 = width, y3 = 0
                        var x1 = bzPlot.toPx(bz[0]), y1 = bzPlot.toPy(bz[1])
                        var x2 = bzPlot.toPx(bz[2]), y2 = bzPlot.toPy(bz[3])

                        // Handle stems
                        ctx.strokeStyle = Qt.rgba(0.51, 0.55, 0.97, 0.45)
                        ctx.lineWidth = 1
                        ctx.beginPath(); ctx.moveTo(x0, y0); ctx.lineTo(x1, y1); ctx.stroke()
                        ctx.beginPath(); ctx.moveTo(x3, y3); ctx.lineTo(x2, y2); ctx.stroke()

                        // Curve
                        ctx.strokeStyle = "#818cf8"
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.moveTo(x0, y0)
                        ctx.bezierCurveTo(x1, y1, x2, y2, x3, y3)
                        ctx.stroke()

                        // End points
                        ctx.fillStyle = "#9ca3af"
                        ctx.beginPath(); ctx.arc(x0, y0, 3, 0, Math.PI * 2); ctx.fill()
                        ctx.beginPath(); ctx.arc(x3, y3, 3, 0, Math.PI * 2); ctx.fill()
                    }
                }

                // Draggable control handles
                Repeater {
                    model: 2
                    Rectangle {
                        id: bzHandle
                        required property int index
                        width: 14; height: 14; radius: 7
                        color: bzHMa.pressed ? "#a5b4fc" : "#818cf8"
                        border.color: "#0b1220"; border.width: 1
                        x: bzPlot.toPx(panel._bzBuf[index * 2]) - 7
                        y: bzPlot.toPy(panel._bzBuf[index * 2 + 1]) - 7
                        MouseArea {
                            id: bzHMa
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            cursorShape: Qt.SizeAllCursor
                            onPositionChanged: function(m) {
                                if (!pressed) return
                                var p = mapToItem(bzPlot, m.x, m.y)
                                var bz = panel._bzBuf.slice()
                                bz[bzHandle.index * 2]     = bzPlot.fromPx(p.x)
                                bz[bzHandle.index * 2 + 1] = bzPlot.fromPy(p.y)
                                panel._bzBuf = bz
                                bezierEditor.requestPaint()
                            }
                        }
                    }
                }
            }

            // Numeric readout
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 5
                text: "(" + panel._bzBuf[0].toFixed(2) + ", " + panel._bzBuf[1].toFixed(2)
                    + ", " + panel._bzBuf[2].toFixed(2) + ", " + panel._bzBuf[3].toFixed(2) + ")"
                color: "#52525b"; font.pixelSize: 8; font.family: "Consolas"
            }
        }

        // Buttons
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.topMargin: 12
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 32
                    radius: 6
                    color: rmArea.containsMouse ? "#3a1418" : "#2a1a1c"
                    border.color: "#5a2a30"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Resetear"
                        color: "#ff8a90"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: rmArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel._reset()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 32
                    radius: 6
                    color: cancelArea.containsMouse ? "#2a2a32" : "#22222a"
                    border.color: "#3a3a44"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: "#cbd5e1"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { panel._sync(); panel.close() }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 32
                    radius: 6
                    color: okArea.containsMouse ? Qt.lighter("#22d3ee", 1.2) : "#22d3ee"
                    Text {
                        anchors.centerIn: parent
                        text: "Aplicar"
                        color: "#0a1a1f"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: okArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel._commit()
                    }
                }
            }
        }
    }
}
