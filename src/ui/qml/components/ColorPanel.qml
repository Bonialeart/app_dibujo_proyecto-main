import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QtQuick.Dialogs
import ArtFlow 1.0

Item {
    id: root

    // --- PROPERTIES ---
    property var targetCanvas: null
    property color accentColor: (typeof preferencesManager !== "undefined" && preferencesManager) ? preferencesManager.themeAccent : "#6366f1"
    property color currentColor: targetCanvas ? targetCanvas.brushColor : "#6366f1"

    // --- DUAL COLOR SYSTEM ---
    property int activeSlot: 0
    property bool isTransparent: false
    property color slot0Color: "#6366f1"
    property color slot1Color: "#FFFFFF"

    property real h: 0.0
    property real s: 0.7
    property real v: 1.0
    property real a: 1.0

    property bool internalUpdate: false

    onActiveSlotChanged: {
        if (!internalUpdate) {
            internalUpdate = true
            isTransparent = false
            var col = (activeSlot === 0 ? slot0Color : slot1Color)
            h = col.hsvHue < 0 ? 0 : col.hsvHue
            s = col.hsvSaturation
            v = col.hsvValue
            if (targetCanvas) targetCanvas.brushColor = col
            internalUpdate = false
        }
    }

    function updateColor() {
        if (internalUpdate) return
        internalUpdate = true
        var newColor = Qt.hsva(h, s, v, a)
        if (activeSlot === 0) slot0Color = newColor
        else slot1Color = newColor
        if (targetCanvas) targetCanvas.brushColor = newColor
        colorSelected(newColor)
        internalUpdate = false
    }

    function setFromHex(hexStr) {
        hexStr = hexStr.trim()
        if (hexStr.charAt(0) !== "#") hexStr = "#" + hexStr
        var c = Qt.color(hexStr)
        if (c.valid) {
            internalUpdate = true
            h = c.hsvHue < 0 ? 0 : c.hsvHue
            s = c.hsvSaturation
            v = c.hsvValue
            if (activeSlot === 0) slot0Color = c
            else slot1Color = c
            if (targetCanvas) targetCanvas.brushColor = c
            colorSelected(c)
            internalUpdate = false
        }
    }

    function addToHistory() {
        if (!backend) return
        backend.addToHistory(root.currentColor)
    }

    signal colorSelected(color newColor)

    // --- C++ BACKEND ---
    ColorPicker {
        id: backend
        activeColor: root.currentColor
    }

    // ── MAIN LAYOUT ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#111113"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // ── 1. HEADER: Dual Wells + Hex + Alpha ──────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 72

                // Background card
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "#0e0e11"
                    border.color: "#222228"
                    border.width: 1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // ── Dual color wells ──
                    Item {
                        width: 56; height: 52
                        Layout.alignment: Qt.AlignVCenter

                        // Background slot (inactive)
                        Rectangle {
                            id: bgSlot
                            width: 34; height: 34; radius: 6
                            x: activeSlot === 0 ? 22 : 0
                            y: 18
                            z: activeSlot === 0 ? 1 : 2
                            color: activeSlot === 0 ? root.slot1Color : root.slot0Color
                            border.color: "#333"
                            border.width: 1.5
                            scale: activeSlot === 0 ? 0.88 : 1.0
                            opacity: 0.75

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 200 } }

                            MouseArea { anchors.fill: parent; onClicked: root.activeSlot = (root.activeSlot === 0 ? 1 : 0) }
                        }

                        // Foreground slot (active)
                        Rectangle {
                            id: fgSlot
                            width: 38; height: 38; radius: 8
                            x: activeSlot === 0 ? 0 : 18
                            y: activeSlot === 0 ? 0 : 0
                            z: activeSlot === 0 ? 2 : 1
                            color: activeSlot === 0 ? root.slot0Color : root.slot1Color
                            border.color: "white"
                            border.width: 2

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true; shadowBlur: 12
                                shadowColor: fgSlot.color; shadowOpacity: 0.5; shadowVerticalOffset: 3
                            }

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                            MouseArea { anchors.fill: parent; onClicked: root.activeSlot = (root.activeSlot === 0 ? 1 : 0) }
                        }

                        // Swap button
                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: "#1a1a1f"; border.color: "#444"; border.width: 1
                            anchors.bottom: parent.bottom; anchors.right: parent.right
                            z: 10
                            Text { text: "⇄"; color: "#aaa"; font.pixelSize: 8; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var tmp = root.slot0Color
                                    root.slot0Color = root.slot1Color
                                    root.slot1Color = tmp
                                    root.internalUpdate = true
                                    var col = root.activeSlot === 0 ? root.slot0Color : root.slot1Color
                                    root.h = col.hsvHue < 0 ? 0 : col.hsvHue
                                    root.s = col.hsvSaturation
                                    root.v = col.hsvValue
                                    if (root.targetCanvas) root.targetCanvas.brushColor = col
                                    root.internalUpdate = false
                                }
                            }
                            ToolTip.visible: parent.children[2].containsMouse; ToolTip.text: "Intercambiar colores"
                        }
                    }

                    // ── Right side: Hex + Alpha ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Hex input
                        Rectangle {
                            Layout.fillWidth: true
                            height: 28; radius: 6
                            color: hexField.activeFocus ? "#1a1a22" : "#181820"
                            border.color: hexField.activeFocus ? root.accentColor : "#2a2a35"
                            border.width: hexField.activeFocus ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 6; spacing: 4

                                Text {
                                    text: "#"
                                    color: "#555"; font.pixelSize: 11; font.family: "Monospace"
                                    font.weight: Font.Bold
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                TextInput {
                                    id: hexField
                                    Layout.fillWidth: true
                                    text: {
                                        var c = root.activeSlot === 0 ? root.slot0Color : root.slot1Color
                                        return c.toString().substring(1).toUpperCase()
                                    }
                                    color: "#f0f0f5"; font.pixelSize: 11; font.family: "Monospace"
                                    font.weight: Font.Bold
                                    maximumLength: 8
                                    selectByMouse: true
                                    verticalAlignment: TextInput.AlignVCenter

                                    onAccepted: root.setFromHex(text)
                                    onEditingFinished: root.setFromHex(text)

                                    Keys.onEscapePressed: { text = (root.activeSlot === 0 ? root.slot0Color : root.slot1Color).toString().substring(1).toUpperCase(); focus = false }
                                }

                                // Eyedropper button
                                Rectangle {
                                    width: 20; height: 20; radius: 4
                                    color: pipetteMa.containsMouse ? "#252530" : "transparent"
                                    Layout.alignment: Qt.AlignVCenter

                                    Image {
                                        source: "image://icons/eyedropper.svg"
                                        width: 13; height: 13; anchors.centerIn: parent
                                        opacity: 0.7; smooth: true; mipmap: true
                                        sourceSize: Qt.size(32, 32)
                                    }
                                    MouseArea {
                                        id: pipetteMa; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.CrossCursor
                                        onClicked: { if (root.targetCanvas) root.targetCanvas.currentTool = "eyedropper" }
                                    }
                                    ToolTip.visible: pipetteMa.containsMouse; ToolTip.text: "Cuentagotas (E)"; ToolTip.delay: 400
                                }
                            }
                        }

                        // Alpha slider
                        Item {
                            Layout.fillWidth: true
                            height: 22

                            // Checkerboard bg (transparency indicator)
                            Canvas {
                                anchors.fill: parent; antialiasing: false
                                onPaint: {
                                    var ctx = getContext("2d")
                                    var sz = 5
                                    for (var xi = 0; xi < width; xi += sz)
                                        for (var yi = 0; yi < height; yi += sz)
                                            ctx.fillStyle = ((xi + yi) / sz) % 2 === 0 ? "#555" : "#333"
                                            ctx.fillRect(xi, yi, sz, sz)
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect { maskEnabled: true; maskSource: alphaSliderBg }
                            }

                            Rectangle {
                                id: alphaSliderBg
                                anchors.fill: parent; radius: 5; visible: false
                            }

                            // Color gradient overlay
                            Rectangle {
                                anchors.fill: parent; radius: 5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.hsva(root.h, root.s, root.v, 1.0) }
                                }
                                border.color: "#25FFFFFF"; border.width: 1
                            }

                            // Knob
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: "white"
                                border.color: "#555"; border.width: 1.5
                                x: root.a * (parent.width - width)
                                anchors.verticalCenter: parent.verticalCenter
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 5; shadowColor: "#80000000" }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function updateA(m) { root.a = Math.max(0, Math.min(1, m.x / width)); root.updateColor() }
                                onPressed: updateA(mouse)
                                onPositionChanged: if (pressed) updateA(mouse)
                            }

                            Text {
                                anchors.right: parent.right; anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(root.a * 100) + "%"
                                color: root.a < 0.5 ? "#aaa" : "#222"
                                font.pixelSize: 8; font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            // ── 2. MODE TABS ────────────────────────────────────
            Row {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: [
                        { icon: "grid_pattern.svg", tip: "Cuadro de Color", idx: 0 },
                        { icon: "shape.svg",         tip: "Rueda de Color", idx: 1 },
                        { icon: "sliders.svg",       tip: "Deslizadores HSV", idx: 2 },
                        { icon: "palette.svg",       tip: "Paletas", idx: 3 }
                    ]

                    Item {
                        width: parent.width / 4
                        height: 36

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: viewStack.currentIndex === modelData.idx
                                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                                : (modeMa.containsMouse ? "#1a1a1f" : "transparent")
                            border.color: viewStack.currentIndex === modelData.idx ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5) : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Image {
                                source: "image://icons/" + modelData.icon
                                width: 16; height: 16
                                anchors.centerIn: parent
                                opacity: viewStack.currentIndex === modelData.idx ? 1.0 : 0.4
                                smooth: true; mipmap: true; sourceSize: Qt.size(32, 32)

                                // Colorize active icon with accent
                                layer.enabled: viewStack.currentIndex === modelData.idx
                                layer.effect: MultiEffect { colorizationColor: root.accentColor; colorization: 0.8 }

                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: modeMa
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: viewStack.currentIndex = modelData.idx
                            }

                            ToolTip.visible: modeMa.containsMouse; ToolTip.text: modelData.tip; ToolTip.delay: 400
                        }
                    }
                }
            }

            // Active mode indicator bar
            Item {
                Layout.fillWidth: true; height: 2
                Rectangle {
                    width: parent.width / 4
                    height: 2; radius: 1
                    color: root.accentColor
                    x: viewStack.currentIndex * parent.width / 4

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 8; shadowColor: root.accentColor }
                }
            }

            // ── 3. MAIN VIEWS ──────────────────────────────────
            StackLayout {
                id: viewStack
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: 4
                currentIndex: 0

                // ── VIEW 0: COLOR BOX ──
                Item {
                    ColumnLayout {
                        anchors.fill: parent; spacing: 10

                        // SV Square
                        Rectangle {
                            id: svSquare
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: 12
                            color: Qt.hsva(root.h, 1, 1, 1)

                            // White gradient (left-right)
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "white" }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                            }
                            // Black gradient (top-bottom)
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: "black" }
                                }
                            }
                            // Border
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                color: "transparent"; border.color: "#25FFFFFF"; border.width: 1
                            }

                            // Cursor ring
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: "transparent"; border.color: "white"; border.width: 2.5
                                x: (root.s * svSquare.width) - 10
                                y: ((1.0 - root.v) * svSquare.height) - 10
                                Rectangle {
                                    anchors.centerIn: parent; width: 14; height: 14; radius: 7
                                    color: "transparent"; border.color: "black"; border.width: 1
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: "#80000000" }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function upSV(m) {
                                    root.s = Math.max(0, Math.min(1, m.x / width))
                                    root.v = Math.max(0, Math.min(1, 1.0 - m.y / height))
                                    root.updateColor()
                                }
                                onPressed: upSV(mouse)
                                onPositionChanged: if (pressed) upSV(mouse)
                                onReleased: root.addToHistory()
                            }
                        }

                        // Hue Slider
                        Item {
                            Layout.fillWidth: true; height: 28

                            Rectangle {
                                anchors.centerIn: parent; width: parent.width; height: 10; radius: 5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.000; color: "#FF0000" }
                                    GradientStop { position: 0.166; color: "#FFFF00" }
                                    GradientStop { position: 0.333; color: "#00FF00" }
                                    GradientStop { position: 0.500; color: "#00FFFF" }
                                    GradientStop { position: 0.666; color: "#0000FF" }
                                    GradientStop { position: 0.833; color: "#FF00FF" }
                                    GradientStop { position: 1.000; color: "#FF0000" }
                                }
                                border.color: "#20FFFFFF"; border.width: 1
                            }

                            // Hue Knob
                            Rectangle {
                                width: 22; height: 22; radius: 11
                                color: "white"; border.color: "#444"; border.width: 1
                                x: (root.h * parent.width) - 11
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    anchors.centerIn: parent; width: 16; height: 16; radius: 8
                                    color: Qt.hsva(root.h, 1, 1, 1)
                                    border.color: "#66000000"; border.width: 1
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 8; shadowColor: "#80000000" }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function upH(m) { root.h = Math.max(0, Math.min(0.9999, m.x / width)); root.updateColor() }
                                onPressed: upH(mouse)
                                onPositionChanged: if (pressed) upH(mouse)
                                onReleased: root.addToHistory()
                            }
                        }

                        // Color preview strip + recent colors
                        RowLayout {
                            Layout.fillWidth: true; spacing: 6

                            // Current color preview
                            Rectangle {
                                width: 32; height: 24; radius: 6
                                color: root.activeSlot === 0 ? root.slot0Color : root.slot1Color
                                border.color: "#30FFFFFF"; border.width: 1
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true; shadowBlur: 8
                                    shadowColor: root.currentColor; shadowOpacity: 0.4; shadowVerticalOffset: 2
                                }
                            }

                            // History swatches
                            Repeater {
                                model: backend ? backend.colorHistory : []
                                Rectangle {
                                    width: 20; height: 20; radius: 5
                                    color: modelData
                                    border.color: "#20FFFFFF"; border.width: 1
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onPressed: parent.scale = 0.85
                                        onReleased: parent.scale = 1.0
                                        onClicked: {
                                            var c = Qt.color(modelData)
                                            root.h = c.hsvHue < 0 ? 0 : c.hsvHue
                                            root.s = c.hsvSaturation
                                            root.v = c.hsvValue
                                            root.updateColor()
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // ── VIEW 1: COLOR WHEEL ──
                Item {
                    Item {
                        width: Math.min(parent.width, parent.height) * 0.96
                        height: width
                        anchors.centerIn: parent

                        Canvas {
                            id: hueRingCanvas
                            anchors.fill: parent; antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2, cy = height / 2
                                var outerR = width * 0.5, innerR = width * 0.40
                                ctx.save()
                                ctx.translate(cx, cy); ctx.scale(1, -1); ctx.translate(-cx, -cy)
                                var grad = ctx.createConicalGradient(cx, cy, 0)
                                grad.addColorStop(0.0, "#f00"); grad.addColorStop(0.166, "#ff0")
                                grad.addColorStop(0.333, "#0f0"); grad.addColorStop(0.5, "#0ff")
                                grad.addColorStop(0.666, "#00f"); grad.addColorStop(0.833, "#f0f")
                                grad.addColorStop(1.0, "#f00")
                                ctx.fillStyle = grad
                                ctx.beginPath()
                                ctx.arc(cx, cy, outerR, 0, Math.PI * 2, false)
                                ctx.arc(cx, cy, innerR, 0, Math.PI * 2, true)
                                ctx.closePath(); ctx.fill(); ctx.restore()
                            }
                            onWidthChanged: requestPaint()
                        }

                        // Hue ring knob indicator
                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: "transparent"; border.color: "white"; border.width: 2.5
                            x: (parent.width / 2) + (parent.width * 0.45) * Math.cos(root.h * 2 * Math.PI) - 7
                            y: (parent.height / 2) - (parent.height * 0.45) * Math.sin(root.h * 2 * Math.PI) - 7
                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 4; shadowColor: "#aa000000" }
                        }

                        MouseArea {
                            anchors.fill: parent
                            function upWheel(m) {
                                var dx = m.x - width / 2, dy = height / 2 - m.y
                                var d = Math.sqrt(dx * dx + dy * dy)
                                if (d > width * 0.36) {
                                    var ang = Math.atan2(dy, dx)
                                    var hh = ang / (Math.PI * 2)
                                    if (hh < 0) hh += 1.0
                                    root.h = (1.0 - hh) % 1.0
                                    root.updateColor()
                                }
                            }
                            onPressed: upWheel(mouse)
                            onPositionChanged: if (pressed) upWheel(mouse)
                        }

                        // SV inner square (circular clip)
                        Rectangle {
                            width: parent.width * 0.72; height: width
                            radius: width / 2
                            anchors.centerIn: parent
                            color: Qt.hsva(root.h, 1, 1, 1)
                            clip: true

                            Rectangle {
                                anchors.fill: parent; radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "white" }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: "black" }
                                }
                            }

                            // Crosshair knob
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                border.color: "white"; border.width: 2.5; color: "transparent"
                                x: (root.s * parent.width) - 10
                                y: ((1.0 - root.v) * parent.height) - 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                function upSV(m) {
                                    root.s = Math.max(0, Math.min(1, m.x / width))
                                    root.v = Math.max(0, Math.min(1, 1 - m.y / height))
                                    root.updateColor()
                                }
                                onPressed: upSV(mouse)
                                onPositionChanged: if (pressed) upSV(mouse)
                            }
                        }
                    }
                }

                // ── VIEW 2: HSV SLIDERS ──
                Item {
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 2; spacing: 14

                        // H Slider
                        _ColorSliderRow { label: "H"; unit: "°"; displayValue: Math.round(root.h * 360); minVal: 0; maxVal: 360
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.000; color: "#FF0000" } GradientStop { position: 0.166; color: "#FFFF00" }
                                GradientStop { position: 0.333; color: "#00FF00" } GradientStop { position: 0.500; color: "#00FFFF" }
                                GradientStop { position: 0.666; color: "#0000FF" } GradientStop { position: 0.833; color: "#FF00FF" }
                                GradientStop { position: 1.000; color: "#FF0000" }
                            }
                            normalizedValue: root.h
                            onMoved: (nv) => { root.h = nv; root.updateColor() }
                        }

                        // S Slider
                        _ColorSliderRow { label: "S"; unit: "%"; displayValue: Math.round(root.s * 100); minVal: 0; maxVal: 100
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Qt.hsva(root.h, 0, root.v, 1) }
                                GradientStop { position: 1; color: Qt.hsva(root.h, 1, root.v, 1) }
                            }
                            normalizedValue: root.s
                            onMoved: (nv) => { root.s = nv; root.updateColor() }
                        }

                        // V Slider
                        _ColorSliderRow { label: "V"; unit: "%"; displayValue: Math.round(root.v * 100); minVal: 0; maxVal: 100
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "black" }
                                GradientStop { position: 1; color: Qt.hsva(root.h, root.s, 1, 1) }
                            }
                            normalizedValue: root.v
                            onMoved: (nv) => { root.v = nv; root.updateColor() }
                        }

                        // A Slider
                        _ColorSliderRow { label: "A"; unit: "%"; displayValue: Math.round(root.a * 100); minVal: 0; maxVal: 100
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: Qt.hsva(root.h, root.s, root.v, 1) }
                            }
                            normalizedValue: root.a
                            onMoved: (nv) => { root.a = nv; root.updateColor() }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ── VIEW 3: PALETTES ──
                Item {
                    id: palettesView3

                    property var paletteCategories: [
                        { name: "Sunsets",
                          colors: ["#FF6B35","#F7C59F","#FFBE0B","#FB5607","#FF006E",
                                   "#E8D5B0","#FCA652","#C84B31","#6C4A4A","#2C1810",
                                   "#FFDDB0","#FFA552","#FF7547","#CF4A3C","#8B2635"] },
                        { name: "Cyberpunk",
                          colors: ["#00F5FF","#FF00FF","#7B2FBE","#FF00A4","#00FF41",
                                   "#1A1A2E","#16213E","#0F3460","#E94560","#533483",
                                   "#FF6B6B","#4ECDC4","#FFE66D","#A8DADC","#264653"] },
                        { name: "Neons",
                          colors: ["#FF4ECD","#9B5DE5","#F15BB5","#FEE440","#00BBF9",
                                   "#00F5D4","#FF6B9D","#C77DFF","#E0AAFF","#7B2FBE",
                                   "#3A0CA3","#4361EE","#4CC9F0","#F72585","#B5179E"] },
                        { name: "Forest",
                          colors: ["#2D6A4F","#40916C","#52B788","#74C69D","#95D5B2",
                                   "#38270E","#603813","#8B5E3C","#C4A882","#DEB887",
                                   "#1B4332","#081C15","#D4A847","#856A3E","#F1DFC4"] },
                        { name: "Ocean",
                          colors: ["#03045E","#023E8A","#0077B6","#0096C7","#00B4D8",
                                   "#48CAE4","#90E0EF","#ADE8F4","#CAF0F8","#FFFFFF",
                                   "#006994","#0A7EA4","#1292B4","#22B0CB","#3DCFE3"] },
                        { name: "Arctic",
                          colors: ["#E8F4F8","#D1ECF5","#AED9E0","#7EC8D9","#5BA4CF",
                                   "#B8D4E3","#9BC2D6","#7AAEC8","#5893B9","#3378A9",
                                   "#D6EAF8","#EBF5FB","#F0F3FF","#C8D8E8","#A8C0D6"] }
                    ]

                    property int selectedCategory: 0

                    ColumnLayout {
                        anchors.fill: parent; spacing: 6

                        // Category tabs
                        Flickable {
                            Layout.fillWidth: true; height: 26
                            contentWidth: catRow.implicitWidth; clip: true
                            flickableDirection: Flickable.HorizontalFlick

                            Row {
                                id: catRow; spacing: 4
                                Repeater {
                                    model: palettesView3.paletteCategories
                                    Rectangle {
                                        property bool isAct: palettesView3.selectedCategory === index
                                        height: 24; width: catLbl.implicitWidth + 16; radius: 12
                                        color: isAct ? root.accentColor : "#202025"
                                        border.color: isAct ? "transparent" : "#333"; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 160 } }

                                        Text {
                                            id: catLbl
                                            text: modelData.name
                                            font.pixelSize: 9; font.weight: Font.Bold
                                            color: "white"; anchors.centerIn: parent
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: palettesView3.selectedCategory = index
                                        }
                                    }
                                }
                            }
                        }

                        // Swatches grid
                        GridView {
                            id: p3Grid
                            Layout.fillWidth: true; Layout.fillHeight: true
                            clip: true
                            model: palettesView3.paletteCategories[palettesView3.selectedCategory].colors
                            property int cols: 5
                            cellWidth: Math.floor(width / cols); cellHeight: cellWidth

                            delegate: Item {
                                width: p3Grid.cellWidth; height: p3Grid.cellHeight

                                Rectangle {
                                    id: pSwatch
                                    anchors.fill: parent; anchors.margins: 3
                                    radius: 7; color: modelData
                                    border.color: "#20FFFFFF"; border.width: 1

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true; shadowBlur: 8
                                        shadowColor: modelData; shadowOpacity: 0.4; shadowVerticalOffset: 2
                                    }

                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onPressed: pSwatch.scale = 0.8
                                        onReleased: pSwatch.scale = 1.0
                                        onClicked: {
                                            var c = Qt.color(modelData)
                                            root.h = c.hsvHue < 0 ? 0 : c.hsvHue
                                            root.s = c.hsvSaturation
                                            root.v = c.hsvValue
                                            root.updateColor()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── REUSABLE: Color Slider Row ─────────────────────────
    component _ColorSliderRow : Item {
        id: _csr
        Layout.fillWidth: true
        height: 32

        property string label: "H"
        property string unit: ""
        property int displayValue: 0
        property int minVal: 0
        property int maxVal: 100
        property real normalizedValue: 0.0
        property Gradient gradient: Gradient {}

        signal moved(real normalizedValue)

        RowLayout {
            anchors.fill: parent; spacing: 8

            Text {
                text: _csr.label
                color: "#888"; font.pixelSize: 11; font.weight: Font.Bold
                font.family: "Monospace"
                Layout.preferredWidth: 12
                Layout.alignment: Qt.AlignVCenter
            }

            // Slider track
            Item {
                Layout.fillWidth: true; height: 26

                Rectangle {
                    id: _csrTrack
                    anchors.centerIn: parent; width: parent.width; height: 8; radius: 4
                    gradient: _csr.gradient
                    border.color: "#20FFFFFF"; border.width: 1
                }

                // Knob
                Rectangle {
                    width: 20; height: 20; radius: 10
                    color: "white"; border.color: "#555"; border.width: 1
                    x: _csr.normalizedValue * (parent.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    scale: _csrMa.pressed ? 1.15 : 1.0

                    Behavior on scale { NumberAnimation { duration: 80 } }
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: "#80000000" }
                }

                MouseArea {
                    id: _csrMa; anchors.fill: parent
                    function upV(m) { _csr.moved(Math.max(0, Math.min(1, m.x / width))) }
                    onPressed: upV(mouse)
                    onPositionChanged: if (pressed) upV(mouse)
                }
            }

            Text {
                text: _csr.displayValue + _csr.unit
                color: "#ccc"; font.pixelSize: 10; font.family: "Monospace"
                Layout.preferredWidth: 38
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
