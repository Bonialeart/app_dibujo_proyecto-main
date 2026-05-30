import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// === CLIP STUDIO-STYLE PROFESSIONAL NAVIGATOR PANEL ===
// Used in Studio Mode — full-featured with live preview, zoom, rotation, flip controls
Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    readonly property real currentZoom: targetCanvas ? (targetCanvas.zoomLevel || 1.0) : 1.0
    readonly property real currentRotation: targetCanvas ? (targetCanvas.canvasRotation || 0.0) : 0.0
    readonly property bool isFlippedH: targetCanvas ? (targetCanvas.isFlippedH || false) : false
    readonly property bool isFlippedV: targetCanvas ? (targetCanvas.isFlippedV || false) : false

    // === LAYOUT ===
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // ── 1. LIVE CANVAS MINIMAP ──────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 100
            color: "#0a0a0d"
            radius: 6
            clip: true

            // Subtle checkerboard
            Canvas {
                anchors.fill: parent; opacity: 0.04; z: 0
                onPaint: {
                    var ctx = getContext("2d"); ctx.fillStyle = "#666"
                    for (var i = 0; i < width; i += 10)
                        for (var j = 0; j < height; j += 10)
                            if ((i + j) % 20 === 0) ctx.fillRect(i, j, 10, 10)
                }
            }

            // Canvas preview property cache
            property string _previewSrc: ""

            Timer {
                id: _navPanelRefreshTimer
                interval: 40
                repeat: true
                running: targetCanvas !== null
                onTriggered: {
                    if (targetCanvas && targetCanvas.getCanvasPreview) {
                        _previewContainer.parent._previewSrc = targetCanvas.getCanvasPreview()
                    }
                }
            }

            // Canvas preview image
            Item {
                id: _previewContainer
                anchors.fill: parent
                anchors.margins: 8

                Image {
                    id: _previewImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    source: _previewContainer.parent._previewSrc
                    asynchronous: false
                    cache: false
                    opacity: 1.0

                    // Drop shadow for the preview
                    Rectangle {
                        z: -1; anchors.fill: parent; anchors.margins: -2
                        color: "transparent"
                        border.color: "#1affffff"; border.width: 0.5
                        radius: 2
                        visible: _previewImage.status === Image.Ready
                    }
                }

                // Viewport indicator overlay
                Rectangle {
                    id: _viewportRect
                    visible: _previewImage.status === Image.Ready && targetCanvas !== null
                    // Calculate position based on canvas view offset and zoom
                    property real canvasW: targetCanvas ? (targetCanvas.canvasWidth || 1) : 1
                    property real canvasH: targetCanvas ? (targetCanvas.canvasHeight || 1) : 1
                    property real imgDisplayW: _previewImage.paintedWidth || 1
                    property real imgDisplayH: _previewImage.paintedHeight || 1
                    property real scaleX: imgDisplayW / canvasW
                    property real scaleY: imgDisplayH / canvasH

                    // Center offset for PreserveAspectFit
                    property real offsetX: (_previewContainer.width - imgDisplayW) / 2
                    property real offsetY: (_previewContainer.height - imgDisplayH) / 2

                    x: offsetX + (targetCanvas ? (-targetCanvas.viewOffset.x * scaleX) : 0)
                    y: offsetY + (targetCanvas ? (-targetCanvas.viewOffset.y * scaleY) : 0)
                    width: targetCanvas ? (targetCanvas.width * scaleX / root.currentZoom) : imgDisplayW
                    height: targetCanvas ? (targetCanvas.height * scaleY / root.currentZoom) : imgDisplayH

                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1)
                    border.color: root.accentColor
                    border.width: 1.5
                    radius: 1

                    // Apply canvas rotation to viewport indicator
                    transform: Rotation {
                        origin.x: _viewportRect.width / 2
                        origin.y: _viewportRect.height / 2
                        angle: root.currentRotation
                    }

                    // Crosshair
                    Rectangle { width: 10; height: 1; color: root.accentColor; anchors.centerIn: parent; opacity: 0.5 }
                    Rectangle { width: 1; height: 10; color: root.accentColor; anchors.centerIn: parent; opacity: 0.5 }

                    // Viewport drag area
                    MouseArea {
                        id: viewportDragArea
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        
                        property point lastPos
                        
                        onPressed: (mouse) => {
                            var pt = mapToItem(_previewContainer, mouse.x, mouse.y)
                            lastPos = pt
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (pressed && targetCanvas) {
                                var pt = mapToItem(_previewContainer, mouse.x, mouse.y)
                                var dx = pt.x - lastPos.x
                                var dy = pt.y - lastPos.y
                                
                                var real_dx = -dx / _viewportRect.scaleX
                                var real_dy = -dy / _viewportRect.scaleY
                                
                                targetCanvas.canvasOffset = Qt.point(
                                    targetCanvas.viewOffset.x + real_dx,
                                    targetCanvas.viewOffset.y + real_dy
                                )
                                lastPos = pt
                            }
                        }
                    }
                }
            }

            // Empty state
            Column {
                anchors.centerIn: parent; spacing: 6
                visible: !targetCanvas || _previewImage.status !== Image.Ready
                opacity: 0.3
                Text { text: "🖼"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "No canvas"; color: "#666"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
            }

            // Click-to-pan & Click-to-Jump interaction
            MouseArea {
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property point lastPos

                onPressed: (mouse) => {
                    lastPos = Qt.point(mouse.x, mouse.y)
                    jumpToPoint(mouse)
                }
                onPositionChanged: (mouse) => {
                    if (pressed && targetCanvas) {
                        var dx = mouse.x - lastPos.x
                        var dy = mouse.y - lastPos.y
                        if (typeof targetCanvas.pan_canvas === "function") {
                            targetCanvas.pan_canvas(dx * 2, dy * 2)
                        }
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                }

                onWheel: (wheel) => {
                    if (targetCanvas) {
                        if (wheel.angleDelta.y > 0) targetCanvas.zoomLevel = targetCanvas.zoomLevel * 1.15
                        else targetCanvas.zoomLevel = targetCanvas.zoomLevel * 0.85
                    }
                }
                
                function jumpToPoint(mouse) {
                    if (!targetCanvas || _previewImage.status !== Image.Ready) return
                    
                    var local = _previewImage.mapFromItem(parent, mouse.x, mouse.y)
                    var imgDisplayW = _previewImage.paintedWidth
                    var imgDisplayH = _previewImage.paintedHeight
                    var ox = (_previewImage.width - imgDisplayW) / 2
                    var oy = (_previewImage.height - imgDisplayH) / 2
                    
                    var px = local.x - ox
                    var py = local.y - oy
                    
                    if (px >= 0 && px <= imgDisplayW && py >= 0 && py <= imgDisplayH) {
                        var rx = px / imgDisplayW
                        var ry = py / imgDisplayH
                        
                        targetCanvas.canvasOffset = Qt.point(
                            -rx * targetCanvas.canvasWidth + targetCanvas.width / (2 * targetCanvas.zoomLevel),
                            -ry * targetCanvas.canvasHeight + targetCanvas.height / (2 * targetCanvas.zoomLevel)
                        )
                    }
                }
            }

            // Top-right info badge
            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 6; anchors.rightMargin: 6
                width: _infoText.implicitWidth + 12; height: 18; radius: 9
                color: "#aa1a1a1e"
                visible: targetCanvas !== null

                Text {
                    id: _infoText
                    anchors.centerIn: parent
                    text: (targetCanvas ? (targetCanvas.canvasWidth + "×" + targetCanvas.canvasHeight) : "")
                    color: "#777"; font.pixelSize: 8; font.weight: Font.Medium
                }
            }
        }

        // ── 2. ZOOM CONTROL ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 6

                // Zoom out button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: _zoomOutMa.containsMouse ? "#252530" : "transparent"
                    Text { text: "−"; color: _zoomOutMa.containsMouse ? "#ddd" : "#666"; font.pixelSize: 16; font.weight: Font.Bold; anchors.centerIn: parent }
                    MouseArea {
                        id: _zoomOutMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(targetCanvas) targetCanvas.zoomLevel = targetCanvas.zoomLevel * 0.8
                    }
                    ToolTip.visible: _zoomOutMa.containsMouse; ToolTip.text: "Alejar"; ToolTip.delay: 400
                }

                // Zoom slider
                Slider {
                    id: _zoomSlider
                    Layout.fillWidth: true
                    from: 0.1; to: 8.0
                    value: root.currentZoom
                    onMoved: if(targetCanvas) targetCanvas.zoomLevel = value

                    background: Rectangle {
                        x: _zoomSlider.leftPadding
                        y: _zoomSlider.topPadding + _zoomSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200; implicitHeight: 3; radius: 1.5
                        color: "#1c1c1e"

                        // Fill
                        Rectangle {
                            width: _zoomSlider.visualPosition * parent.width
                            height: parent.height; radius: parent.radius
                            color: root.accentColor; opacity: 0.8
                        }

                        // Center tick (100%)
                        Rectangle {
                            x: parent.width * ((1.0 - 0.1) / (8.0 - 0.1)) - 0.5
                            y: -2; width: 1; height: 7; color: "#444"
                        }
                    }

                    handle: Rectangle {
                        x: _zoomSlider.leftPadding + _zoomSlider.visualPosition * (_zoomSlider.availableWidth - width)
                        y: _zoomSlider.topPadding + _zoomSlider.availableHeight / 2 - height / 2
                        implicitWidth: 12; implicitHeight: 12; radius: 6
                        color: _zoomSlider.pressed ? "#fff" : "#ccc"
                        border.color: "#444"; border.width: 0.5

                        Behavior on scale { NumberAnimation { duration: 80 } }
                        scale: _zoomSlider.pressed ? 1.15 : 1.0
                    }
                }

                // Zoom in button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: _zoomInMa.containsMouse ? "#252530" : "transparent"
                    Text { text: "+"; color: _zoomInMa.containsMouse ? "#ddd" : "#666"; font.pixelSize: 16; font.weight: Font.Bold; anchors.centerIn: parent }
                    MouseArea {
                        id: _zoomInMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(targetCanvas) targetCanvas.zoomLevel = targetCanvas.zoomLevel * 1.2
                    }
                    ToolTip.visible: _zoomInMa.containsMouse; ToolTip.text: "Acercar"; ToolTip.delay: 400
                }

                // Zoom percentage (clickable to reset)
                Rectangle {
                    width: 42; height: 20; radius: 4
                    color: _zoomPctMa.containsMouse ? "#252530" : "transparent"
                    border.color: _zoomPctMa.containsMouse ? "#333" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(root.currentZoom * 100) + "%"
                        color: "#aaa"; font.pixelSize: 10; font.weight: Font.Medium
                        font.family: "monospace"
                    }
                    MouseArea {
                        id: _zoomPctMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(targetCanvas) targetCanvas.zoomLevel = 1.0
                    }
                    ToolTip.visible: _zoomPctMa.containsMouse; ToolTip.text: "Restablecer zoom (100%)"; ToolTip.delay: 400
                }
            }
        }

        // ── 2.5 ROTATION CONTROL ─────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 6

                // Rotate CCW button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: _rotCcwMa.containsMouse ? "#252530" : "transparent"
                    Text { text: "↺"; color: _rotCcwMa.containsMouse ? "#ddd" : "#666"; font.pixelSize: 14; font.weight: Font.Bold; anchors.centerIn: parent }
                    MouseArea {
                        id: _rotCcwMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(targetCanvas) targetCanvas.rotateCanvasBy(-15.0)
                    }
                    ToolTip.visible: _rotCcwMa.containsMouse; ToolTip.text: "Rotar Izquierda (-15°)"; ToolTip.delay: 400
                }

                // Rotation slider
                Slider {
                    id: _rotSlider
                    Layout.fillWidth: true
                    from: -180.0; to: 180.0
                    value: root.currentRotation
                    onMoved: if(targetCanvas) targetCanvas.canvasRotation = value

                    background: Rectangle {
                        x: _rotSlider.leftPadding
                        y: _rotSlider.topPadding + _rotSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200; implicitHeight: 3; radius: 1.5
                        color: "#1c1c1e"

                        // Center tick (0°)
                        Rectangle {
                            x: parent.width / 2 - 0.5
                            y: -2; width: 1; height: 7; color: "#444"
                        }
                    }

                    handle: Rectangle {
                        x: _rotSlider.leftPadding + _rotSlider.visualPosition * (_rotSlider.availableWidth - width)
                        y: _rotSlider.topPadding + _rotSlider.availableHeight / 2 - height / 2
                        implicitWidth: 12; implicitHeight: 12; radius: 6
                        color: _rotSlider.pressed ? "#fff" : "#ccc"
                        border.color: "#444"; border.width: 0.5

                        Behavior on scale { NumberAnimation { duration: 80 } }
                        scale: _rotSlider.pressed ? 1.15 : 1.0
                    }
                }

                // Rotate CW button
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: _rotCwMa.containsMouse ? "#252530" : "transparent"
                    Text { text: "↻"; color: _rotCwMa.containsMouse ? "#ddd" : "#666"; font.pixelSize: 14; font.weight: Font.Bold; anchors.centerIn: parent }
                    MouseArea {
                        id: _rotCwMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(targetCanvas) targetCanvas.rotateCanvasBy(15.0)
                    }
                    ToolTip.visible: _rotCwMa.containsMouse; ToolTip.text: "Rotar Derecha (+15°)"; ToolTip.delay: 400
                }

                // Rotation degree (clickable to reset)
                Rectangle {
                    width: 42; height: 20; radius: 4
                    color: _rotDegMa.containsMouse ? "#252530" : "transparent"
                    border.color: _rotDegMa.containsMouse ? "#333" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(root.currentRotation) + "°"
                        color: "#aaa"; font.pixelSize: 10; font.weight: Font.Medium
                        font.family: "monospace"
                    }
                    MouseArea {
                        id: _rotDegMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(targetCanvas) targetCanvas.resetCanvasRotation()
                    }
                    ToolTip.visible: _rotDegMa.containsMouse; ToolTip.text: "Restablecer rotación (0°)"; ToolTip.delay: 400
                }
            }
        }

        // ── 3. ACTION TOOLBAR ───────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: "#0d0d10"
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 4

                // Flip Horizontal
                NavToolBtn {
                    iconSrc: "flip_horizontal.svg"
                    tip: "Voltear horizontal"
                    isActive: root.isFlippedH
                    activeColor: root.accentColor
                    onClicked: if(targetCanvas) targetCanvas.isFlippedH = !targetCanvas.isFlippedH
                }

                // Flip Vertical
                NavToolBtn {
                    iconSrc: "flip_horizontal.svg"  // reuse icon, rotate 90°
                    tip: "Voltear vertical"
                    isActive: root.isFlippedV
                    activeColor: root.accentColor
                    iconRotation: 90
                    onClicked: if(targetCanvas) targetCanvas.isFlippedV = !targetCanvas.isFlippedV
                }

                // Fit to View
                NavToolBtn {
                    iconSrc: "maximize.svg"
                    tip: "Ajustar a pantalla (Ctrl+0)"
                    onClicked: if(targetCanvas) targetCanvas.fitToView()
                }

                // Separator
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: "#252530"; Layout.alignment: Qt.AlignVCenter }

                // Zoom Quick Presets
                Repeater {
                    model: [
                        { label: "50%", zoom: 0.5 },
                        { label: "100%", zoom: 1.0 },
                        { label: "200%", zoom: 2.0 }
                    ]

                    Rectangle {
                        Layout.preferredWidth: 32; Layout.preferredHeight: 22; radius: 6
                        property bool isCurrentZoom: Math.abs(root.currentZoom - modelData.zoom) < 0.05
                        color: isCurrentZoom ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2) : (_zPresetMa.containsMouse ? "#252530" : "transparent")
                        border.color: isCurrentZoom ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : "transparent"
                        border.width: isCurrentZoom ? 1 : 0

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: isCurrentZoom ? root.accentColor : (_zPresetMa.containsMouse ? "#ddd" : "#777")
                            font.pixelSize: 9; font.weight: isCurrentZoom ? Font.Bold : Font.Medium
                        }
                        MouseArea {
                            id: _zPresetMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if(targetCanvas) targetCanvas.zoomLevel = modelData.zoom
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Spacer
            }
        }
    }

    // ── REUSABLE TOOL BUTTON COMPONENT ──────────────────
    component NavToolBtn : Rectangle {
        id: _ntb
        property string iconSrc: ""
        property string tip: ""
        property bool isActive: false
        property color activeColor: root.accentColor
        property real iconRotation: 0

        signal clicked()

        Layout.preferredWidth: 28; Layout.preferredHeight: 26; radius: 7
        color: isActive
            ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.18)
            : (_ntbMa.containsMouse ? "#252530" : "transparent")
        border.color: isActive ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.45) : "transparent"
        border.width: isActive ? 1 : 0

        Behavior on color { ColorAnimation { duration: 100 } }

        Image {
            source: iconSrc !== "" ? ("image://icons/" + iconSrc) : ""
            width: 16; height: 16
            anchors.centerIn: parent
            rotation: _ntb.iconRotation
            opacity: _ntb.isActive ? 1.0 : (_ntbMa.containsMouse ? 0.9 : 0.5)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            id: _ntbMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: _ntb.clicked()
        }
        ToolTip.visible: _ntbMa.containsMouse && tip !== ""
        ToolTip.text: tip; ToolTip.delay: 400

        scale: _ntbMa.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
    }
}
