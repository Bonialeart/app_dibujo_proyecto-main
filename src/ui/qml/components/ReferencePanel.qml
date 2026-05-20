import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "6366f1"

    property string refImageSource: ""
    property real refZoom: 1.0
    property real panX: 0.0
    property real panY: 0.0

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

                // Zoom label
                Rectangle {
                    height: 22; width: 46; radius: 4
                    color: "transparent"; border.color: "#222"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: Math.round(root.refZoom * 100) + "%"
                        color: "#777"; font.pixelSize: 9; font.family: "Monospace"
                    }
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

                Behavior on x { NumberAnimation { duration: 0 } }
                Behavior on y { NumberAnimation { duration: 0 } }

                // Shadow
                layer.enabled: status === Image.Ready
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowBlur: 20
                    shadowColor: "#aa000000"; shadowVerticalOffset: 8
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

            // Interaction: pan + zoom
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                property point lastPos

                onPressed: (mouse) => { lastPos = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    if (pressed) {
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
                visible: root.refImageSource !== ""

                Text {
                    id: zoomLabel
                    anchors.centerIn: parent
                    text: Math.round(root.refZoom * 100) + "%"
                    color: "#999"; font.pixelSize: 9; font.family: "Monospace"
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
