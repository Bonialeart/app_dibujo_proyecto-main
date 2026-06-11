import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Dialogs
import Kromo 1.0

Item {
    id: root

    // --- SIZING FOR RESPONSIVENESS IN DOCKS ---
    width: parent ? parent.width : 300
    height: parent ? parent.height : 600

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

    // --- HARMONY VARIABLES ---
    property string harmonyMode: "Complementary"
    property var harmonyColors: []

    // --- EVENTS & CALLBACKS ---
    Component.onCompleted: {
        h = currentColor.hsvHue < 0 ? 0 : currentColor.hsvHue
        s = currentColor.hsvSaturation
        v = currentColor.hsvValue
        a = currentColor.a
        slot0Color = currentColor
        if (viewStack.currentIndex === 3) {
            updateHarmony()
        }
    }

    onCurrentColorChanged: {
        if (!internalUpdate) {
            internalUpdate = true
            h = currentColor.hsvHue < 0 ? 0 : currentColor.hsvHue
            s = currentColor.hsvSaturation
            v = currentColor.hsvValue
            a = currentColor.a
            if (activeSlot === 0) slot0Color = currentColor
            else slot1Color = currentColor
            internalUpdate = false
            if (viewStack.currentIndex === 3) {
                updateHarmony()
            }
        }
    }

    onHChanged: {
        if (viewStack.currentIndex === 3) {
            updateHarmony()
        }
    }
    onSChanged: {
        if (viewStack.currentIndex === 3) {
            updateHarmony()
        }
    }
    onVChanged: {
        if (viewStack.currentIndex === 3) {
            updateHarmony()
        }
    }
    onHarmonyModeChanged: {
        if (viewStack.currentIndex === 3) {
            updateHarmony()
        }
    }

    // --- FUNCTIONS ---
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
            a = c.a
            if (activeSlot === 0) slot0Color = c
            else slot1Color = c
            if (targetCanvas) targetCanvas.brushColor = c
            colorSelected(c)
            internalUpdate = false
            updateHarmony()
        }
    }

    function addToHistory() {
        var c = root.currentColor
        if (colorHarmony.isInList(c, backend.history)) {
            return
        }
        backend.addToHistory(c)
    }

    function getCMYK() {
        return colorHarmony.rgbToCMYK(root.currentColor)
    }

    function setCMYK(c, m, y, k) {
        var col = colorHarmony.cmykToRGB(c, m, y, k)
        root.currentColor = col
        root.h = col.hsvHue < 0 ? 0 : col.hsvHue
        root.s = col.hsvSaturation
        root.v = col.hsvValue
        if (root.targetCanvas) root.targetCanvas.brushColor = col
    }

    function updateHarmony() {
        if (typeof colorHarmony !== "undefined") {
            harmonyColors = colorHarmony.getHarmonyColors(root.h, root.s, root.v, harmonyMode)
        }
    }

    function copyToClipboard(text) {
        var tempInput = Qt.createQmlObject('import QtQuick; TextInput { visible: false }', root)
        tempInput.text = text
        tempInput.selectAll()
        tempInput.copy()
        tempInput.destroy()
    }

    signal colorSelected(color newColor)

    // --- C++ BACKEND ---
    ColorPicker {
        id: backend
        activeColor: root.currentColor
    }

    // --- BACKGROUND PANEL ---
    Rectangle {
        anchors.fill: parent
        color: "#111113"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // ── 1. HEADER: DUAL WELLS + HEX + ALPHA ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 74

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#0e0e11"
                    border.color: "#222228"
                    border.width: 1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Dual wells
                    Item {
                        width: 58; height: 54
                        Layout.alignment: Qt.AlignVCenter

                        // Background slot
                        Rectangle {
                            id: bgSlot
                            width: 32; height: 32; radius: 8
                            x: activeSlot === 0 ? 24 : 0
                            y: 18
                            z: activeSlot === 0 ? 1 : 2
                            color: activeSlot === 0 ? root.slot1Color : root.slot0Color
                            border.color: "#2E2E35"
                            border.width: 1.5
                            scale: activeSlot === 0 ? 0.85 : 1.0
                            opacity: 0.7

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: 150 } }
                            MouseArea { anchors.fill: parent; onClicked: root.activeSlot = (root.activeSlot === 0 ? 1 : 0) }
                        }

                        // Foreground slot
                        Rectangle {
                            id: fgSlot
                            width: 36; height: 36; radius: 9
                            x: activeSlot === 0 ? 0 : 20
                            y: 2
                            z: activeSlot === 0 ? 2 : 1
                            color: activeSlot === 0 ? root.slot0Color : root.slot1Color
                            border.color: "white"
                            border.width: 2

                            layer.enabled: false
                            layer.effect: MultiEffect {
                                shadowEnabled: true; shadowBlur: 10
                                shadowColor: fgSlot.color; shadowOpacity: 0.45; shadowVerticalOffset: 2
                            }

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            MouseArea { anchors.fill: parent; onClicked: root.activeSlot = (root.activeSlot === 0 ? 1 : 0) }
                        }

                        // Swap color well button
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: "#1c1c22"; border.color: "#3A3A42"; border.width: 1
                            anchors.bottom: parent.bottom; anchors.right: parent.right
                            z: 10
                            Text { text: "⇄"; color: "#aaa"; font.pixelSize: 10; font.weight: Font.Bold; anchors.centerIn: parent }
                            MouseArea {
                                id: swapMa
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
                                    root.a = col.a
                                    if (root.targetCanvas) root.targetCanvas.brushColor = col
                                    root.internalUpdate = false
                                    root.updateHarmony()
                                }
                            }
                            ToolTip.visible: swapMa.containsMouse; ToolTip.text: "Swap Color Slots"
                        }
                    }

                    // Hex input + Alpha
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // Hex Input Row
                        Rectangle {
                            Layout.fillWidth: true
                            height: 28; radius: 6
                            color: hexField.activeFocus ? "#1a1a24" : "#141418"
                            border.color: hexField.activeFocus ? root.accentColor : "#2a2a32"
                            border.width: hexField.activeFocus ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6; anchors.rightMargin: 4
                                spacing: 4

                                Text {
                                    text: "#"
                                    color: "#5e5e6a"; font.pixelSize: 11; font.family: "Monospace"; font.weight: Font.Bold
                                }

                                TextInput {
                                    id: hexField
                                    Layout.fillWidth: true
                                    text: {
                                        var c = root.activeSlot === 0 ? root.slot0Color : root.slot1Color
                                        return c.toString().substring(1).toUpperCase()
                                    }
                                    color: "#f5f5fa"; font.pixelSize: 11; font.family: "Monospace"; font.weight: Font.Bold
                                    maximumLength: 8
                                    selectByMouse: true
                                    verticalAlignment: TextInput.AlignVCenter

                                    onAccepted: root.setFromHex(text)
                                    onEditingFinished: root.setFromHex(text)
                                    Keys.onEscapePressed: {
                                        text = (root.activeSlot === 0 ? root.slot0Color : root.slot1Color).toString().substring(1).toUpperCase()
                                        focus = false
                                    }
                                }

                                // Copy Hex
                                Rectangle {
                                    width: 22; height: 22; radius: 4
                                    color: copyHexMa.containsMouse ? "#22222b" : "transparent"
                                    Image {
                                        source: "image://icons/copy.svg"
                                        width: 13; height: 13; anchors.centerIn: parent; opacity: copyHexMa.containsMouse ? 1.0 : 0.6
                                    }
                                    MouseArea {
                                        id: copyHexMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copyToClipboard("#" + hexField.text)
                                    }
                                    ToolTip.visible: copyHexMa.containsMouse; ToolTip.text: "Copy Hex Code"
                                }

                                // Eyedropper
                                Rectangle {
                                    width: 22; height: 22; radius: 4
                                    color: pipetteMa.containsMouse ? "#22222b" : "transparent"
                                    Image {
                                        source: "image://icons/eyedropper.svg"
                                        width: 13; height: 13; anchors.centerIn: parent; opacity: pipetteMa.containsMouse ? 1.0 : 0.6
                                    }
                                    MouseArea {
                                        id: pipetteMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { if (root.targetCanvas) root.targetCanvas.currentTool = "eyedropper" }
                                    }
                                    ToolTip.visible: pipetteMa.containsMouse; ToolTip.text: "Eyedropper Tool"
                                }
                            }
                        }

                        // Alpha slider
                        Item {
                            Layout.fillWidth: true
                            height: 20

                            // Checkerboard background
                            Canvas {
                                anchors.fill: parent
                                antialiasing: false
                                onPaint: {
                                    var ctx = getContext("2d")
                                    var sz = 4
                                    for (var xi = 0; xi < width; xi += sz) {
                                        for (var yi = 0; yi < height; yi += sz) {
                                            ctx.fillStyle = ((xi + yi) / sz) % 2 === 0 ? "#444" : "#222"
                                            ctx.fillRect(xi, yi, sz, sz)
                                        }
                                    }
                                }
                                layer.enabled: false
                                layer.effect: MultiEffect { maskEnabled: true; maskSource: alphaSliderBg }
                            }

                            Rectangle {
                                id: alphaSliderBg
                                anchors.fill: parent; radius: 5; visible: false
                            }

                            Rectangle {
                                anchors.fill: parent; radius: 5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.hsva(root.h, root.s, root.v, 1.0) }
                                }
                                border.color: "#18ffffff"; border.width: 1
                            }

                            // Knob
                            Rectangle {
                                width: 14; height: 14; radius: 7
                                color: "white"; border.color: "#444"; border.width: 1
                                x: root.a * (parent.width - width)
                                anchors.verticalCenter: parent.verticalCenter
                                layer.enabled: false
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 4; shadowColor: "#90000000" }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function updateA(m) { root.a = Math.max(0, Math.min(1, m.x / width)); root.updateColor() }
                                onPressed: updateA(mouse)
                                onPositionChanged: if (pressed) updateA(mouse)
                            }
                        }
                    }
                }
            }

            // ── 2. MODE TABS (TOP NAVIGATION) ──
            Item {
                Layout.fillWidth: true
                height: 38

                Rectangle {
                    anchors.fill: parent
                    color: "#16161a"
                    radius: 10
                    border.color: "#222228"
                    border.width: 1
                }

                Row {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: [
                            { icon: "grid_pattern.svg", tip: "Color Box", idx: 0 },
                            { icon: "shape.svg",         tip: "Color Disc", idx: 1 },
                            { icon: "sliders.svg",       tip: "Sliders", idx: 2 },
                            { icon: "ghost.svg",         tip: "Harmony", idx: 3 },
                            { icon: "palette.svg",       tip: "Library", idx: 4 }
                        ]

                        Item {
                            width: parent.width / 5
                            height: 38

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: 8
                                color: viewStack.currentIndex === modelData.idx
                                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
                                    : (modeMa.containsMouse ? "#202028" : "transparent")
                                border.color: viewStack.currentIndex === modelData.idx ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Image {
                                    source: "image://icons/" + modelData.icon
                                    width: 16; height: 16
                                    anchors.centerIn: parent
                                    opacity: viewStack.currentIndex === modelData.idx ? 1.0 : 0.5
                                    smooth: true; mipmap: true

                                    layer.enabled: viewStack.currentIndex === modelData.idx
                                    layer.effect: MultiEffect { colorizationColor: root.accentColor; colorization: 0.9 }
                                }

                                MouseArea {
                                    id: modeMa
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: viewStack.currentIndex = modelData.idx
                                }

                                ToolTip.visible: modeMa.containsMouse; ToolTip.text: modelData.tip; ToolTip.delay: 350
                            }
                        }
                    }
                }
            }

            // Slidable active bar
            Item {
                Layout.fillWidth: true; height: 2
                Rectangle {
                    width: parent.width / 5
                    height: 2; radius: 1
                    color: root.accentColor
                    x: viewStack.currentIndex * parent.width / 5

                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    layer.enabled: false
                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: root.accentColor }
                }
            }

            // ── 3. MAIN STACK LAYOUT (OPTIMIZED WITH LOADERS) ──
            Item {
                id: viewStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                property int currentIndex: 0

                onCurrentIndexChanged: {
                    if (currentIndex === 3) {
                        root.updateHarmony()
                    }
                }

                Loader {
                    id: viewLoader
                    anchors.fill: parent
                    sourceComponent: {
                        switch (viewStack.currentIndex) {
                            case 0: return colorBoxComponent
                            case 1: return colorDiscComponent
                            case 2: return slidersComponent
                            case 3: return harmonyComponent
                            case 4: return palettesComponent
                            default: return colorBoxComponent
                        }
                    }
                }
            }

            // --- VIEW COMPONENTS ---
            Component {
                id: colorBoxComponent
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        // SV Square
                        Rectangle {
                            id: svSquare
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: 12
                            color: Qt.hsva(root.h, 1, 1, 1)

                            // Gradients
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "white" }
                                    GradientStop { position: 1; color: "transparent" }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: "black" }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent; radius: 12
                                color: "transparent"; border.color: "#25ffffff"; border.width: 1
                            }

                            // Cursor
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: "transparent"; border.color: "white"; border.width: 2
                                x: (root.s * svSquare.width) - 9
                                y: ((1.0 - root.v) * svSquare.height) - 9
                                Rectangle {
                                    anchors.centerIn: parent; width: 12; height: 12; radius: 6
                                    color: "transparent"; border.color: "black"; border.width: 1
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 5; shadowColor: "#90000000" }
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

                        // Hue slider
                        Item {
                            Layout.fillWidth: true; height: 26

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
                                border.color: "#18ffffff"; border.width: 1
                            }

                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: "white"; border.color: "#444"; border.width: 1
                                x: (root.h * parent.width) - 9
                                anchors.verticalCenter: parent.verticalCenter
                                Rectangle {
                                    anchors.centerIn: parent; width: 12; height: 12; radius: 6
                                    color: Qt.hsva(root.h, 1, 1, 1)
                                    border.color: "#50000000"; border.width: 1
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 6; shadowColor: "#90000000" }
                            }

                            MouseArea {
                                anchors.fill: parent
                                function upH(m) { root.h = Math.max(0, Math.min(0.9999, m.x / width)); root.updateColor() }
                                onPressed: upH(mouse)
                                onPositionChanged: if (pressed) upH(mouse)
                                onReleased: root.addToHistory()
                            }
                        }
                    }
                }
            }

            Component {
                id: colorDiscComponent
                Item {
                    Item {
                        width: Math.min(parent.width, parent.height) * 0.95
                        height: width
                        anchors.centerIn: parent

                        // Conical hue ring
                        Canvas {
                            id: wheelCanvas
                            anchors.fill: parent
                            antialiasing: true
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

                        // Hue Ring Selector
                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: "transparent"; border.color: "white"; border.width: 2
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
                            onReleased: root.addToHistory()
                        }

                        // Inner SV Circle/Square
                        Rectangle {
                            width: parent.width * 0.70; height: width
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

                            // SV Crosshair
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                border.color: "white"; border.width: 2; color: "transparent"
                                x: (root.s * parent.width) - 8
                                y: ((1.0 - root.v) * parent.height) - 8
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
                                onReleased: root.addToHistory()
                            }
                        }
                    }
                }
            }

            Component {
                id: slidersComponent
                Item {
                    Flickable {
                        anchors.fill: parent
                        contentHeight: sliderCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: sliderCol
                            width: parent.width
                            spacing: 8

                            // 1. HSB GROUP
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 114
                                color: "#151518"; radius: 10; border.color: "#22222a"; border.width: 1
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "H"; value: root.h * 360; maxValue: 360; unit: "°"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => { root.h = val / 360; root.updateColor() }
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "S"; value: root.s; maxValue: 1.0; unit: "%"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => { root.s = val; root.updateColor() }
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "V"; value: root.v; maxValue: 1.0; unit: "%"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => { root.v = val; root.updateColor() }
                                    }
                                }
                            }

                            // 2. RGB GROUP
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 114
                                color: "#151518"; radius: 10; border.color: "#22222a"; border.width: 1
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "R"; value: root.currentColor.r * 255; maxValue: 255; unit: ""
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => {
                                            var c = root.currentColor; var newCol = Qt.rgba(val / 255, c.g, c.b, root.a)
                                            root.currentColor = newCol
                                            root.h = newCol.hsvHue < 0 ? 0 : newCol.hsvHue
                                            root.s = newCol.hsvSaturation
                                            root.v = newCol.hsvValue
                                            if (root.targetCanvas) root.targetCanvas.brushColor = newCol
                                        }
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "G"; value: root.currentColor.g * 255; maxValue: 255; unit: ""
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => {
                                            var c = root.currentColor; var newCol = Qt.rgba(c.r, val / 255, c.b, root.a)
                                            root.currentColor = newCol
                                            root.h = newCol.hsvHue < 0 ? 0 : newCol.hsvHue
                                            root.s = newCol.hsvSaturation
                                            root.v = newCol.hsvValue
                                            if (root.targetCanvas) root.targetCanvas.brushColor = newCol
                                        }
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "B"; value: root.currentColor.b * 255; maxValue: 255; unit: ""
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => {
                                            var c = root.currentColor; var newCol = Qt.rgba(c.r, c.g, val / 255, root.a)
                                            root.currentColor = newCol
                                            root.h = newCol.hsvHue < 0 ? 0 : newCol.hsvHue
                                            root.s = newCol.hsvSaturation
                                            root.v = newCol.hsvValue
                                            if (root.targetCanvas) root.targetCanvas.brushColor = newCol
                                        }
                                    }
                                }
                            }

                            // 3. CMYK GROUP
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 144
                                color: "#151518"; radius: 10; border.color: "#22222a"; border.width: 1
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                                    property var cmyk: root.getCMYK()
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "C"; value: parent.cmyk.c; maxValue: 1.0; unit: "%"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => root.setCMYK(val, parent.cmyk.m, parent.cmyk.y, parent.cmyk.k)
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "M"; value: parent.cmyk.m; maxValue: 1.0; unit: "%"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => root.setCMYK(parent.cmyk.c, val, parent.cmyk.y, parent.cmyk.k)
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "Y"; value: parent.cmyk.y; maxValue: 1.0; unit: "%"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => root.setCMYK(parent.cmyk.c, parent.cmyk.m, val, parent.cmyk.k)
                                    }
                                    ImprovedColorSlider {
                                        Layout.fillWidth: true; label: "K"; value: parent.cmyk.k; maxValue: 1.0; unit: "%"
                                        currentH: root.h; currentS: root.s; currentV: root.v
                                        onSliderMoved: (val) => root.setCMYK(parent.cmyk.c, parent.cmyk.m, parent.cmyk.y, val)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: harmonyComponent
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        // Harmony mode dropdown selector
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            color: "#161618"; radius: 8; border.color: "#2c2c34"; border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10

                                Text {
                                    text: "Harmony: " + root.harmonyMode
                                    color: "#f0f0f5"; font.pixelSize: 11; font.weight: Font.Bold
                                }
                                Item { Layout.fillWidth: true }
                                Text { text: "▼"; color: "#8E8E93"; font.pixelSize: 9 }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: harmonyMenu.open()
                            }

                            Menu {
                                id: harmonyMenu
                                MenuItem { text: "Complementary"; onTriggered: root.harmonyMode = "Complementary" }
                                MenuItem { text: "Split Complementary"; onTriggered: root.harmonyMode = "Split Complementary" }
                                MenuItem { text: "Analogous"; onTriggered: root.harmonyMode = "Analogous" }
                                MenuItem { text: "Triadic"; onTriggered: root.harmonyMode = "Triadic" }
                                MenuItem { text: "Square"; onTriggered: root.harmonyMode = "Square" }
                            }
                        }

                        // Draggable Harmony Disc
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                id: harmonyDisc
                                width: Math.min(parent.width, parent.height) * 0.95; height: width
                                anchors.centerIn: parent
                                radius: width / 2; clip: true
                                color: "transparent"

                                Canvas {
                                    anchors.fill: parent
                                    antialiasing: true; smooth: true
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        var cx = width / 2, cy = height / 2, r = width / 2
                                        ctx.reset()
                                        ctx.clearRect(0, 0, width, height)

                                        var hueGrad = ctx.createConicalGradient(cx, cy, 0)
                                        for (var i = 0; i <= 1.0; i += 0.1) {
                                            hueGrad.addColorStop(i, Qt.hsva(i, 1, 1, 1))
                                        }
                                        ctx.fillStyle = hueGrad
                                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.fill()

                                        var satGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
                                        satGrad.addColorStop(0, "white")
                                        satGrad.addColorStop(1, "transparent")
                                        ctx.fillStyle = satGrad
                                        ctx.fill()
                                    }
                                }

                                // Dark overlay representing brightness / V
                                Rectangle { anchors.fill: parent; radius: parent.radius; color: "black"; opacity: 1.0 - root.v }

                                MouseArea {
                                    anchors.fill: parent
                                    function handleMouse(m) {
                                        var dx = m.x - width / 2, dy = m.y - height / 2
                                        var theta = Math.atan2(dy, dx)
                                        var hVal = -theta / (2 * Math.PI); if (hVal < 0) hVal += 1.0
                                        var dist = Math.sqrt(dx * dx + dy * dy)
                                        var sVal = Math.min(1.0, dist / (width / 2))
                                        root.h = hVal; root.s = sVal; root.updateColor()
                                    }
                                    onPressed: handleMouse(mouse)
                                    onPositionChanged: if (pressed) handleMouse(mouse)
                                    onReleased: root.addToHistory()
                                }

                                // Secondary harmony reticles
                                Repeater {
                                    model: root.harmonyColors.length - 1
                                    Rectangle {
                                        property color col: root.harmonyColors[index + 1]
                                        property real ang: -((col.hsvHue < 0 ? 0 : col.hsvHue) * 2 * Math.PI)
                                        width: 18; height: 18; radius: 9; color: "transparent"; border.color: "white"; border.width: 1.5; opacity: 0.75
                                        x: (harmonyDisc.width / 2) + (root.s * harmonyDisc.width / 2 * Math.cos(ang)) - 9
                                        y: (harmonyDisc.height / 2) + (root.s * harmonyDisc.height / 2 * Math.sin(ang)) - 9
                                    }
                                }

                                // Primary active reticle
                                Rectangle {
                                    width: 26; height: 26; radius: 13; color: "transparent"; border.color: "white"; border.width: 2.5
                                    property real ang: -(root.h * 2 * Math.PI)
                                    x: (harmonyDisc.width / 2) + (root.s * harmonyDisc.width / 2 * Math.cos(ang)) - 13
                                    y: (harmonyDisc.height / 2) + (root.s * harmonyDisc.height / 2 * Math.sin(ang)) - 13

                                    layer.enabled: true
                                    layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 8; shadowColor: "#90000000" }

                                    Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: "transparent"; border.color: "black"; border.width: 1 }
                                }
                            }
                        }

                        // Brightness slider (V) for gamut display
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18

                            Rectangle {
                                anchors.fill: parent; anchors.margins: 4; radius: 5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "black" }
                                    GradientStop { position: 1; color: Qt.hsva(root.h, root.s, 1.0, 1.0) }
                                }
                            }

                            Rectangle {
                                x: root.v * (parent.width - 16)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16; height: 16; radius: 8; color: "white"; border.color: root.accentColor; border.width: 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: uiV(mouse)
                                onPositionChanged: if (pressed) uiV(mouse)
                                onReleased: root.addToHistory()
                                function uiV(m) { root.v = Math.max(0, Math.min(1.0, m.x / width)); root.updateColor() }
                            }
                        }
                    }
                }
            }

            Component {
                id: palettesComponent
                Item {
                    id: palettesView

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
                    property var extractedColors: []
                    property bool showImagePanel: false
                    property bool isExtracting: false

                    function extractColors(imgSource) {
                        palettesView.isExtracting = true
                        palettesView.extractedColors = []
                        Qt.callLater(function() {
                            var src = imgSource || imgPreview.source
                            var colors = backend.extractColorsFromImage(src.toString(), 15)
                            palettesView.extractedColors = colors
                            palettesView.isExtracting = false
                        })
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        // Category Tabs Horizontal Row
                        Flickable {
                            Layout.fillWidth: true; Layout.preferredHeight: 30
                            contentWidth: tabRow.implicitWidth; clip: true
                            flickableDirection: Flickable.HorizontalFlick

                            Row {
                                id: tabRow; spacing: 5
                                Repeater {
                                    model: palettesView.paletteCategories.length + 1
                                    Rectangle {
                                        property bool isImg: index === palettesView.paletteCategories.length
                                        property bool isActive: isImg ? palettesView.showImagePanel
                                                                      : (!palettesView.showImagePanel && palettesView.selectedCategory === index)
                                        height: 28; width: cl.implicitWidth + 14; radius: 14
                                        color: isActive ? root.accentColor : "#1A1A22"
                                        border.color: isActive ? "transparent" : "#2A2A35"
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            id: cl
                                            text: isImg ? "🖼 Image" : palettesView.paletteCategories[index].name
                                            font.pixelSize: 10; font.weight: Font.Bold; color: "white"; anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (isImg) {
                                                    palettesView.showImagePanel = true
                                                } else {
                                                    palettesView.showImagePanel = false
                                                    palettesView.selectedCategory = index
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Themed Swatches Grid View
                        Item {
                            visible: !palettesView.showImagePanel
                            Layout.fillWidth: true; Layout.fillHeight: true

                            GridView {
                                id: themedGrid
                                anchors.fill: parent; clip: true
                                model: palettesView.paletteCategories[palettesView.selectedCategory].colors
                                cellWidth: Math.floor(width / 5); cellHeight: cellWidth

                                delegate: Item {
                                    width: themedGrid.cellWidth; height: themedGrid.cellHeight
                                    Rectangle {
                                        id: swatchRect
                                        anchors.fill: parent; anchors.margins: 4; radius: 8; color: modelData
                                        border.color: "#20FFFFFF"; border.width: 1

                                        layer.enabled: false
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true; shadowBlur: 8
                                            shadowColor: modelData; shadowOpacity: 0.45; shadowVerticalOffset: 2
                                        }

                                        Behavior on scale { NumberAnimation { duration: 100 } }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onPressed: swatchRect.scale = 0.85
                                            onReleased: swatchRect.scale = 1.0
                                            onClicked: {
                                                var c = Qt.color(modelData)
                                                root.h = c.hsvHue < 0 ? 0 : c.hsvHue
                                                root.s = c.hsvSaturation
                                                root.v = c.hsvValue
                                                root.updateColor()
                                                root.addToHistory()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Image Extraction Panel
                        Item {
                            visible: palettesView.showImagePanel
                            Layout.fillWidth: true; Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent; spacing: 6

                                // Interactive Image Drop/Click Area
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    radius: 12; color: "#131318"; border.color: dropMa.containsMouse ? root.accentColor : "#25252f"; border.width: 1
                                    clip: true

                                    Column {
                                        anchors.centerIn: parent; spacing: 6; visible: imgPreview.source == ""
                                        Image { source: "image://icons/image.svg"; width: 28; height: 28; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.3 }
                                        Text { text: "Click to select image"; color: "#666"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
                                    }

                                    Image {
                                        id: imgPreview; anchors.fill: parent; fillMode: Image.PreserveAspectFit; source: ""; visible: source != ""
                                        onStatusChanged: { if (status === Image.Ready) palettesView.extractColors(source) }
                                    }

                                    MouseArea {
                                        id: dropMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: imgFileDlg.open()
                                    }
                                }

                                // Status label
                                Text {
                                    text: palettesView.isExtracting ? "🔍 Analyzing image..." :
                                          palettesView.extractedColors.length > 0 ? "✅ Extracted colors (" + palettesView.extractedColors.length + ")" : "Select image to extract palette"
                                    color: palettesView.isExtracting ? root.accentColor : "#888"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter
                                }

                                // Extracted colors GridView
                                GridView {
                                    id: extractGrid
                                    Layout.fillWidth: true; Layout.preferredHeight: 90
                                    clip: true; model: palettesView.extractedColors
                                    cellWidth: Math.floor(width / 5); cellHeight: cellWidth

                                    delegate: Item {
                                        width: extractGrid.cellWidth; height: extractGrid.cellHeight
                                        Rectangle {
                                            id: exRect; anchors.fill: parent; anchors.margins: 4; radius: 8; color: modelData
                                            border.color: "#20FFFFFF"; border.width: 1

                                            layer.enabled: false
                                            layer.effect: MultiEffect {
                                                shadowEnabled: true; shadowBlur: 6
                                                shadowColor: modelData; shadowOpacity: 0.4
                                            }

                                            Behavior on scale { NumberAnimation { duration: 100 } }

                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onPressed: exRect.scale = 0.85
                                                onReleased: exRect.scale = 1.0
                                                onClicked: {
                                                    var c = Qt.color(modelData)
                                                    root.h = c.hsvHue < 0 ? 0 : c.hsvHue
                                                    root.s = c.hsvSaturation
                                                    root.v = c.hsvValue
                                                    root.updateColor()
                                                    root.addToHistory()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // File Dialog
                        FileDialog {
                            id: imgFileDlg
                            title: "Select Image"
                            nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp *.webp *.gif)"]
                            fileMode: FileDialog.OpenFile
                            onAccepted: {
                                palettesView.extractedColors = []
                                imgPreview.source = ""
                                imgPreview.source = selectedFile
                            }
                        }
                    }
                }
            }

            // ── 4. FOOTER (SHADES / HISTORY / PALETTES) ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 120

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#0f0f12"
                    border.color: "#222228"
                    border.width: 1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Footer navigation row
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: 28; spacing: 4
                        Repeater {
                            model: viewStack.currentIndex === 3
                                ? [{ n: "Harmony Color", x: 0 }, { n: "Color History", x: 1 }, { n: "My Palettes", x: 2 }]
                                : [{ n: "Shades", x: 0 }, { n: "History", x: 1 }, { n: "Palettes", x: 2 }]

                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 26; radius: 13
                                color: footStack.currentIndex === modelData.x ? root.accentColor : "#17171d"
                                border.color: footStack.currentIndex === modelData.x ? "transparent" : "#282830"
                                border.width: 1

                                Text {
                                    text: modelData.n
                                    anchors.centerIn: parent
                                    color: "white"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: footStack.currentIndex = modelData.x
                                }
                            }
                        }
                    }

                    // Content layout (Optimized using Loader)
                    Item {
                        id: footStack
                        Layout.fillWidth: true; Layout.fillHeight: true
                        property int currentIndex: 0

                        Loader {
                            id: footLoader
                            anchors.fill: parent
                            sourceComponent: {
                                switch (footStack.currentIndex) {
                                    case 0: return shadesComponent
                                    case 1: return historyComponent
                                    case 2: return myPalettesComponent
                                    default: return shadesComponent
                                }
                            }
                        }
                    }

                    // Footer Components
                    Component {
                        id: shadesComponent
                        Item {
                            RowLayout {
                                anchors.fill: parent; spacing: 4
                                Repeater {
                                    model: viewStack.currentIndex === 3 ? root.harmonyColors.length : 10
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                                        color: viewStack.currentIndex === 3 ? root.harmonyColors[index] : (footStack.currentIndex === 0 ? Qt.hsva(root.h, root.s, (index + 1) / 10.0, 1.0) : "black")
                                        border.color: "#1cffffff"; border.width: 1

                                        // Active Indicator
                                        Rectangle {
                                            anchors.fill: parent; anchors.margins: -1.5; radius: 9.5; color: "transparent"
                                            border.color: "white"; border.width: 1.5; visible: viewStack.currentIndex === 3 && root.currentColor === parent.color
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (viewStack.currentIndex === 3) {
                                                    var col = parent.color
                                                    root.h = col.hsvHue < 0 ? 0 : col.hsvHue
                                                    root.s = col.hsvSaturation
                                                    root.v = col.hsvValue
                                                    root.updateColor()
                                                    root.addToHistory()
                                                } else {
                                                    root.v = (index + 1) / 10.0
                                                    root.updateColor()
                                                }
                                            }
                                            onPressed: parent.scale = 0.92
                                            onReleased: parent.scale = 1.0
                                        }
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: historyComponent
                        Item {
                            Flickable {
                                anchors.fill: parent
                                contentWidth: histFlow.implicitWidth; clip: true
                                flickableDirection: Flickable.HorizontalFlick

                                Flow {
                                    id: histFlow; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                    Repeater {
                                        model: backend.history
                                        Rectangle {
                                            id: histRec; width: 28; height: 28; radius: 6; color: modelData; border.color: "#25FFFFFF"; border.width: 1
                                            Behavior on scale { NumberAnimation { duration: 100 } }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onPressed: histRec.scale = 0.85
                                                onReleased: histRec.scale = 1.0
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

                    Component {
                        id: myPalettesComponent
                        Item {
                            Text {
                                text: "Select color and paint to add to history"
                                color: "#555"; font.pixelSize: 10; font.weight: Font.Bold; anchors.centerIn: parent
                            }
                        }
                    }
                }
            }
        }
    }
}
