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
    height: 380
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

    // ── Sync buffers from the camera's current state ──────────
    function _sync() {
        if (!camera || !camera.targetCanvas) return
        var off = camera.targetCanvas.viewOffset
        _xBuf = (off && off.x !== undefined) ? off.x.toFixed(1) : "0.0"
        _yBuf = (off && off.y !== undefined) ? off.y.toFixed(1) : "0.0"
        var z = camera.targetCanvas.zoomLevel
        _zBuf = (z && z > 0) ? (z * 100).toFixed(1) : "100.0"
        _rBuf = (camera.appliedRotation || 0).toFixed(1)
    }

    onOpened: _sync()

    // ── Commit the edited values to the camera's current keyframe
    function _commit() {
        if (!camera || !camera.targetCanvas) return
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
        // Write to the canvas (so the user sees the change live)
        camera.targetCanvas.canvasOffset = Qt.point(nx, ny)
        camera.targetCanvas.zoomLevel  = nz
        // Rotation is camera-only (frame), written via appliedRotation
        camera.appliedRotation = nr
        // Commit (add or update) a keyframe at the current frame
        if (camera.hasKeyframeAt(camera.currentFrameIdx)) {
            // Replace existing keyframe
            var arr = camera.keyframes.slice()
            for (var i = 0; i < arr.length; i++) {
                if (arr[i].frameIdx === camera.currentFrameIdx) {
                    arr[i] = { frameIdx: camera.currentFrameIdx,
                               x: nx, y: ny, zoom: nz, rotation: nr }
                    break
                }
            }
            camera.removeKeyframeAt(camera.currentFrameIdx)
            camera.addKeyframeAt(camera.currentFrameIdx, nx, ny, nz, nr)
        } else {
            camera.addKeyframeAt(camera.currentFrameIdx, nx, ny, nz, nr)
        }
        panel.close()
    }

    function _reset() {
        if (!camera) return
        camera.active = false
        camera.clearKeyframes()
        if (camera.targetCanvas) {
            camera.targetCanvas.fitToView()
        }
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

            Text { text: "Posición X"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
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

            Text { text: "Posición Y"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
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

            Text { text: "Escala (Zoom) %"; color: "#cbd5e1"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
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
                    text: panel.camera && panel.camera.targetCanvas
                        ? (panel.camera.targetCanvas.canvasWidth/2).toFixed(0)
                          + ", "
                          + (panel.camera.targetCanvas.canvasHeight/2).toFixed(0)
                        : "—"
                    color: "#cbd5e1"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { Layout.fillWidth: true }
                Text { text: "(centro del lienzo)"; color: "#666"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter; font.italic: true }
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
