import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import QtQuick.Effects

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    property string refImageSource: ""
    property real refZoom: 1.0
    property real panX: 0.0
    property real panY: 0.0
    property bool goteroActive: false
    
    // Extracted palette model
    ListModel {
        id: paletteModel
    }

    // Hidden sampling canvas for palette extraction and eyedropper color picking
    Canvas {
        id: samplingCanvas
        width: 80; height: 80
        visible: true
        opacity: 0.0
        z: -100 // Out of sight behind other layers
        
        property string samplingSource: ""
        onSamplingSourceChanged: {
            if (samplingSource !== "") {
                requestPaint()
            }
        }
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (samplingSource !== "" && refImage.status === Image.Ready) {
                ctx.drawImage(refImage, 0, 0, width, height)
                extractPalette()
            }
        }
        
        function extractPalette() {
            var ctx = getContext("2d")
            var colors = []
            
            // Sample a 3x3 grid across the 80x80 canvas
            var coords = [
                {x: 15, y: 15}, {x: 40, y: 15}, {x: 65, y: 15},
                {x: 15, y: 40}, {x: 40, y: 40}, {x: 65, y: 40},
                {x: 15, y: 65}, {x: 40, y: 65}, {x: 65, y: 65}
            ]
            
            for (var i = 0; i < coords.length; i++) {
                var p = ctx.getImageData(coords[i].x, coords[i].y, 1, 1).data
                var hex = rgbToHex(p[0], p[1], p[2])
                
                // Avoid plain black or white and filter duplicates
                if (colors.indexOf(hex) === -1 && hex !== "#000000" && hex !== "#ffffff") {
                    colors.push(hex)
                }
            }
            
            // Fillers if too few colors
            var fallbacks = ["#e11d48", "#ea580c", "#ca8a04", "#16a34a", "#2563eb", "#7c3aed", "#db2777", "#4b5563"]
            while (colors.length < 8) {
                var fb = fallbacks[colors.length]
                if (colors.indexOf(fb) === -1) {
                    colors.push(fb)
                } else {
                    colors.push("#6366f1")
                }
            }
            
            paletteModel.clear()
            for (var j = 0; j < Math.min(8, colors.length); j++) {
                paletteModel.append({ "colorVal": colors[j] })
            }
        }
        
        function samplePixel(rx, ry) {
            var ctx = getContext("2d")
            var px = Math.max(0, Math.min(width - 1, Math.floor(rx * width)))
            var py = Math.max(0, Math.min(height - 1, Math.floor(ry * height)))
            var p = ctx.getImageData(px, py, 1, 1).data
            return rgbToHex(p[0], p[1], p[2])
        }
        
        function rgbToHex(r, g, b) {
            var toHex = function(c) {
                var hex = c.toString(16)
                return hex.length === 1 ? "0" + hex : hex
            }
            return "#" + toHex(r) + toHex(g) + toHex(b)
        }
    }

    // ── Layout ─────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Top toolbar ──────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "#0d0d10"

            Rectangle {
                width: parent.width; height: 1; anchors.bottom: parent.bottom; color: "#1c1c1f"
            }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6

                // Title
                Text {
                    text: "REFERENCIA"
                    color: "#5a5a6a"
                    font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1.2
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Manual Eyedropper Pipette Tool Button
                Rectangle {
                    width: 26; height: 26; radius: 6
                    color: root.goteroActive ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) : (_pipMa.containsMouse ? "#252530" : "transparent")
                    border.color: root.goteroActive ? root.accentColor : "transparent"
                    border.width: 1
                    
                    Text {
                        text: "🧪"
                        color: root.goteroActive ? "white" : "#777"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: _pipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.goteroActive = !root.goteroActive
                    }
                    ToolTip.visible: _pipMa.containsMouse
                    ToolTip.text: "Gotero de Referencia (Muestrear color de la imagen)"
                }

                // Reset pan button
                _RefBtn {
                    iconTxt: "◫"; tipText: "Centrar vista"
                    onBtnClicked: { root.panX = 0; root.panY = 0 }
                }

                // Reset zoom button
                _RefBtn {
                    iconTxt: "⊡"; tipText: "Restablecer zoom (100%)"
                    onBtnClicked: root.refZoom = 1.0
                }

                // Zoom in
                _RefBtn {
                    iconTxt: "+"; tipText: "Acercar"
                    onBtnClicked: root.refZoom = Math.min(10.0, root.refZoom * 1.25)
                }

                // Zoom out
                _RefBtn {
                    iconTxt: "−"; tipText: "Alejar"
                    onBtnClicked: root.refZoom = Math.max(0.05, root.refZoom * 0.8)
                }

                // Open file button
                Rectangle {
                    height: 26; width: openMa.implicitWidth + 20; radius: 6
                    color: openMa.containsMouse ? root.accentColor : "#1a1a22"
                    border.color: openMa.containsMouse ? Qt.lighter(root.accentColor, 1.2) : "#333"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: 5
                        Text { text: "📂"; font.pixelSize: 11 }
                        Text {
                            text: "Abrir"
                            color: "white"; font.pixelSize: 10; font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: openMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: refFileDialog.open()
                    }
                }
            }
        }

        // ── Image viewer ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#080810"
            clip: true

            // Subtle checkerboard to indicate transparency
            Canvas {
                anchors.fill: parent; opacity: 0.07; z: 0
                onPaint: {
                    var ctx = getContext("2d"); var sz = 12
                    for (var xi = 0; xi < width; xi += sz)
                        for (var yi = 0; yi < height; yi += sz) {
                            ctx.fillStyle = ((xi / sz + yi / sz) % 2 === 0) ? "#888" : "#444"
                            ctx.fillRect(xi, yi, sz, sz)
                        }
                }
            }

            // Image
            Image {
                id: refImage
                source: root.refImageSource
                fillMode: Image.PreserveAspectFit
                smooth: true; mipmap: true
                visible: root.refImageSource !== ""
                antialiasing: true

                width: {
                    if (status !== Image.Ready) return 0
                    var aspect = implicitWidth / Math.max(1, implicitHeight)
                    var fitW = parent.width * 0.9
                    var fitH = parent.height * 0.9
                    return Math.min(fitW, fitH * aspect) * root.refZoom
                }
                height: implicitWidth > 0 ? (width / (implicitWidth / Math.max(1, implicitHeight))) : 0
                x: (parent.width - width) / 2 + root.panX
                y: (parent.height - height) / 2 + root.panY

                onStatusChanged: {
                    if (status === Image.Ready) {
                        samplingCanvas.samplingSource = ""
                        samplingCanvas.samplingSource = source
                    }
                }

                // Shadow
                layer.enabled: status === Image.Ready
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowBlur: 20
                    shadowColor: "#aa000000"; shadowVerticalOffset: 8
                }
            }

            // Pipette sampling preview ring
            Rectangle {
                id: goteroRing
                width: 32; height: 32; radius: 16
                border.color: "white"
                border.width: 2
                visible: root.goteroActive && dragArea.pressed
                x: dragArea.mouseX - width/2
                y: dragArea.mouseY - height/2
                z: 100
                color: (targetCanvas && targetCanvas.brushColor) ? targetCanvas.brushColor : "transparent"
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 10
                    shadowColor: "#aa000000"
                }
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: root.refImageSource === ""
                opacity: 0.4

                Rectangle {
                    width: 56; height: 56; radius: 14
                    color: "#1a1a22"; border.color: "#333"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        source: "image://icons/image.svg"
                        width: 28; height: 28; anchors.centerIn: parent
                        opacity: 0.5; smooth: true; mipmap: true; sourceSize: Qt.size(64, 64)
                    }
                }

                Text {
                    text: "Sin imagen de referencia"
                    color: "#777"; font.pixelSize: 11; font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Haz clic en 'Abrir' o arrastra una imagen aquí"
                    color: "#555"; font.pixelSize: 9
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Drop area indicator
            Rectangle {
                anchors.fill: parent; radius: 8
                color: "transparent"
                border.color: root.accentColor; border.width: 2
                visible: imgDropArea.containsDrag
                opacity: 0.6
            }

            // Interaction: pan + zoom + eyedropper sampling
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.goteroActive ? Qt.CrossCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                property point lastPos

                onPressed: (mouse) => {
                    if (root.goteroActive && mouse.button === Qt.LeftButton) {
                        sampleColorFromMouse(mouse)
                    } else {
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                }
                onPositionChanged: (mouse) => {
                    if (root.goteroActive && pressed && mouse.button === Qt.LeftButton) {
                        sampleColorFromMouse(mouse)
                    } else if (pressed) {
                        root.panX += (mouse.x - lastPos.x)
                        root.panY += (mouse.y - lastPos.y)
                        lastPos = Qt.point(mouse.x, mouse.y)
                    }
                }
                onWheel: (wheel) => {
                    var factor = wheel.angleDelta.y > 0 ? 1.12 : 0.88
                    var newZoom = Math.max(0.05, Math.min(10.0, root.refZoom * factor))

                    // Zoom toward cursor position
                    var cx = wheel.x - parent.width / 2
                    var cy = wheel.y - parent.height / 2
                    var ratio = newZoom / root.refZoom
                    root.panX = cx + (root.panX - cx) * ratio
                    root.panY = cy + (root.panY - cy) * ratio
                    root.refZoom = newZoom
                }
                
                function sampleColorFromMouse(mouse) {
                    var localX = mouse.x - refImage.x
                    var localY = mouse.y - refImage.y
                    var rx = localX / refImage.width
                    var ry = localY / refImage.height
                    if (rx >= 0 && rx <= 1 && ry >= 0 && ry <= 1) {
                        var c = samplingCanvas.samplePixel(rx, ry)
                        if (targetCanvas) {
                            targetCanvas.brushColor = c
                        }
                    }
                }
            }

            // Drag & drop
            DropArea {
                id: imgDropArea
                anchors.fill: parent
                keys: ["text/uri-list"]
                onDropped: (drop) => {
                    var url = drop.urls[0].toString()
                    if (url.match(/\.(png|jpg|jpeg|bmp|webp|gif|tiff|svg)$/i)) {
                        root.refImageSource = ""
                        root.refImageSource = drop.urls[0]
                        root.refZoom = 1.0
                        root.panX = 0; root.panY = 0
                    }
                }
            }

            // Zoom pill overlay
            Rectangle {
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.bottomMargin: 8; anchors.rightMargin: 8
                width: zoomLabel.implicitWidth + 14; height: 20; radius: 10
                color: "#aa111118"
                visible: root.refImageSource !== "" && !paletteBar.visible

                Text {
                    id: zoomLabel
                    anchors.centerIn: parent
                    text: Math.round(root.refZoom * 100) + "%"
                    color: "#999"; font.pixelSize: 9; font.family: "Monospace"
                }
            }
        }
        
        // ── 3. AUTOMATIC EXTRACTED COLOR SWATCHES BAR ───────
        Rectangle {
            id: paletteBar
            Layout.fillWidth: true
            height: 42
            color: "#0a0a0d"
            visible: root.refImageSource !== "" && paletteModel.count > 0
            
            Rectangle {
                width: parent.width; height: 1; anchors.top: parent.top; color: "#1c1c1f"
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 8
                
                Text {
                    text: "PALETA:"
                    color: "#555"
                    font.pixelSize: 9; font.weight: Font.Bold
                    Layout.alignment: Qt.AlignVCenter
                }
                
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8
                    
                    Repeater {
                        model: paletteModel
                        delegate: Rectangle {
                            width: 22; height: 22; radius: 11
                            color: model.colorVal
                            border.color: (targetCanvas && targetCanvas.brushColor === color) ? "white" : (swatchMa.containsMouse ? Qt.rgba(1,1,1,0.5) : "#1c1c1f")
                            border.width: (targetCanvas && targetCanvas.brushColor === color) ? 2.0 : 1.0
                            
                            scale: swatchMa.pressed ? 0.88 : (swatchMa.containsMouse ? 1.15 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            
                            MouseArea {
                                id: swatchMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (targetCanvas) {
                                        targetCanvas.brushColor = color
                                    }
                                    swatchPulse.start()
                                }
                            }
                            
                            SequentialAnimation {
                                id: swatchPulse
                                NumberAnimation { target: parent; property: "scale"; from: 1.0; to: 1.3; duration: 100 }
                                NumberAnimation { target: parent; property: "scale"; from: 1.3; to: 1.0; duration: 150; easing.type: Easing.OutBack }
                            }
                            
                            ToolTip.visible: swatchMa.containsMouse
                            ToolTip.text: model.colorVal
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Zoom label in palette mode
                Text {
                    text: Math.round(root.refZoom * 100) + "%"
                    color: "#555"; font.pixelSize: 9; font.family: "Monospace"
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // ── File dialog ────────────────────────────────────────
    FileDialog {
        id: refFileDialog
        title: "Seleccionar Imagen de Referencia"
        nameFilters: ["Imágenes (*.png *.jpg *.jpeg *.bmp *.webp *.gif *.tiff *.svg)", "Todos los archivos (*)"]
        onAccepted: {
            root.refImageSource = ""
            root.refImageSource = selectedFile
            root.refZoom = 1.0
            root.panX = 0; root.panY = 0
        }
    }

    // ── Reusable mini button ────────────────────────────────
    component _RefBtn: Rectangle {
        id: _rb
        property string iconTxt: ""
        property string tipText: ""
        signal btnClicked()

        width: 26; height: 26; radius: 6
        color: _rbMa.containsMouse ? "#252530" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            text: _rb.iconTxt
            color: _rbMa.containsMouse ? "#ddd" : "#777"
            font.pixelSize: 13; anchors.centerIn: parent
            font.weight: Font.Bold
        }
        MouseArea {
            id: _rbMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: _rb.btnClicked()
        }
        ToolTip.visible: _rbMa.containsMouse && _rb.tipText !== ""
        ToolTip.text: _rb.tipText; ToolTip.delay: 400
        scale: _rbMa.pressed ? 0.88 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
    }
}
