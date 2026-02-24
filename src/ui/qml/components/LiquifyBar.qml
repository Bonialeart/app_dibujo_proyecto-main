import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ArtFlow 1.0

// ══════════════════════════════════════════════════════════════════
//  LIQUIFY BAR  —  Floating bottom toolbar for Liquify/Deformation
//  Premium glassmorphism design with mode selection & parameter sliders
//  Inspired by Procreate / Clip Studio liquify panels
// ══════════════════════════════════════════════════════════════════
Item {
    id: root

    // ── Public API ──────────────────────────────────────────────
    property var    canvas:       null
    property real   uiScale:      1.0
    property color  accentColor:  "#6366f1"

    // Liquify state (bound to C++ LiquifyEngine via CanvasItem)
    property bool   active:       false
    property int    currentMode:  0       // Maps to LiquifyMode enum
    property real   brushSize:    80.0
    property real   morpher:      0.0     // 0–100 range for UI
    property real   strength:     100.0   // 0–100 range for UI

    // ── Signals ─────────────────────────────────────────────────
    signal modeChanged(int mode)
    signal sizeChanged(real size)
    signal morpherChanged(real morpher)
    signal strengthChanged(real strength)
    signal applyRequested()
    signal cancelRequested()

    // ── Dimensions ──────────────────────────────────────────────
    height: active ? (mainPill.height + sliderPill.height + 16 * uiScale) : 0
    width: parent ? parent.width : 800
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 12 * uiScale

    visible: active
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // ── Entry Animation ─────────────────────────────────────────
    property bool _ready: false
    Component.onCompleted: Qt.callLater(function() { root._ready = true })

    // ── Icon helper ─────────────────────────────────────────────
    function iconPath(name) {
        return "image://icons/" + name
    }

    // ── Mode definitions ────────────────────────────────────────
    readonly property var modes: [
        { name: "Push",        icon: "liquify-push.svg",        mode: 0 },
        { name: "Twirl CW",   icon: "liquify-twirl-cw.svg",    mode: 1 },
        { name: "Twirl CCW",  icon: "liquify-twirl-ccw.svg",   mode: 2 },
        { name: "Pinch",      icon: "liquify-pinch.svg",       mode: 3 },
        { name: "Expand",     icon: "liquify-expand.svg",      mode: 4 },
        { name: "Crystalize", icon: "liquify-crystalize.svg",  mode: 5 },
        { name: "Reconstruct",icon: "liquify-reconstruct.svg", mode: 7 },
        { name: "Smooth",     icon: "liquify-smooth.svg",      mode: 8 }
    ]

    // ════════════════════════════════════════════════════════════
    //  MAIN TOOLBAR PILL (Mode Icons + Apply/Cancel)
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: mainPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: sliderPill.top
        anchors.bottomMargin: 8 * uiScale

        width: mainRow.implicitWidth + 32 * uiScale
        height: 52 * uiScale
        radius: 26 * uiScale

        // Glassmorphism background
        color: "#e8101014"
        border.color: "#30ffffff"
        border.width: 1.2

        // Soft shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#60000000"
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }

        // Premium top highlight
        Rectangle {
            width: parent.width * 0.4; height: 1
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: "#20ffffff" }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        RowLayout {
            id: mainRow
            anchors.centerIn: parent
            spacing: 4 * uiScale

            // ── Settings toggle ──
            LiqModeBtn {
                iconSrc: iconPath("liquify-settings.svg")
                label: ""
                isActive: settingsPopup.visible
                isAccent: false
                onClicked: settingsPopup.visible = !settingsPopup.visible
            }

            // Separator
            Rectangle {
                width: 1; height: 24 * uiScale
                color: "#25ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // ── Mode Buttons ──
            Repeater {
                model: root.modes

                LiqModeBtn {
                    iconSrc: iconPath(modelData.icon)
                    label: modelData.name
                    isActive: root.currentMode === modelData.mode
                    isAccent: root.currentMode === modelData.mode
                    onClicked: {
                        root.currentMode = modelData.mode
                        root.modeChanged(modelData.mode)
                        if (root.canvas) root.canvas.setLiquifyMode(modelData.mode)
                    }
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 24 * uiScale
                color: "#25ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // ── Cancel ──
            Rectangle {
                width: 36 * uiScale; height: 36 * uiScale; radius: 18 * uiScale
                color: cancelMa.containsMouse ? "#40ff4444" : "#25ff4444"
                border.color: "#ff4444"; border.width: 1.2
                Layout.alignment: Qt.AlignVCenter
                scale: cancelMa.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#ff6666"
                    font.pixelSize: 16 * uiScale
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: cancelMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelRequested()
                }
                ToolTip.visible: cancelMa.containsMouse
                ToolTip.text: "Cancel Liquify"
                ToolTip.delay: 400
            }

            // ── Apply ──
            Rectangle {
                width: 36 * uiScale; height: 36 * uiScale; radius: 18 * uiScale
                color: applyMa.containsMouse ? "#4044ff44" : "#2544ff44"
                border.color: "#44cc66"; border.width: 1.2
                Layout.alignment: Qt.AlignVCenter
                scale: applyMa.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: "#66ff88"
                    font.pixelSize: 18 * uiScale
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: applyMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyRequested()
                }
                ToolTip.visible: applyMa.containsMouse
                ToolTip.text: "Apply Liquify"
                ToolTip.delay: 400
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    //  SLIDER PILL (Size / Morpher / Strength)
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: sliderPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4 * uiScale

        width: sliderRow.implicitWidth + 40 * uiScale
        height: 48 * uiScale
        radius: 24 * uiScale

        color: "#e8101014"
        border.color: "#25ffffff"
        border.width: 1

        RowLayout {
            id: sliderRow
            anchors.centerIn: parent
            spacing: 20 * uiScale

            // Size
            LiqSlider {
                label: "Size"
                value: root.brushSize
                from: 5; to: 500
                suffix: "px"
                accentColor: root.accentColor
                uiScale: root.uiScale
                onMoved: function(v) {
                    root.brushSize = v
                    root.sizeChanged(v)
                    if (root.canvas) root.canvas.setLiquifyRadius(v)
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 20 * uiScale
                color: "#20ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // Morpher
            LiqSlider {
                label: "Morpher"
                value: root.morpher
                from: 0; to: 100
                suffix: "%"
                accentColor: "#f0d060"
                uiScale: root.uiScale
                onMoved: function(v) {
                    root.morpher = v
                    root.morpherChanged(v)
                    if (root.canvas) root.canvas.setLiquifyMorpher(v / 100.0)
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 20 * uiScale
                color: "#20ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // Strength
            LiqSlider {
                label: "Strength"
                value: root.strength
                from: 1; to: 100
                suffix: "%"
                accentColor: "#e84393"
                uiScale: root.uiScale
                onMoved: function(v) {
                    root.strength = v
                    root.strengthChanged(v)
                    if (root.canvas) root.canvas.setLiquifyStrength(v / 100.0)
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    //  SETTINGS POPUP (Extra options)
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: settingsPopup
        visible: false
        anchors.bottom: mainPill.top
        anchors.bottomMargin: 8 * uiScale
        anchors.horizontalCenter: parent.horizontalCenter
        width: 220 * uiScale
        height: settingsCol.implicitHeight + 28 * uiScale
        radius: 16 * uiScale

        color: "#f0101014"
        border.color: "#25ffffff"
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#50000000"
            shadowBlur: 0.4
            shadowVerticalOffset: 3
        }

        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: settingsCol
            anchors.fill: parent
            anchors.margins: 14 * uiScale
            spacing: 10 * uiScale

            Text {
                text: "Liquify Settings"
                color: "#8e8e93"
                font.pixelSize: 10 * uiScale
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
            }

            // Edge Mode toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * uiScale

                Text {
                    text: "Edge Mode"
                    color: "#ccc"
                    font.pixelSize: 12 * uiScale
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 36 * uiScale; height: 20 * uiScale; radius: 10 * uiScale
                    color: root.currentMode === 6 ? root.accentColor : "#333"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        x: root.currentMode === 6 ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16 * uiScale; height: 16 * uiScale; radius: 8 * uiScale
                        color: "white"
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.currentMode === 6) {
                                root.currentMode = 0
                            } else {
                                root.currentMode = 6
                            }
                            root.modeChanged(root.currentMode)
                            if (root.canvas) root.canvas.setLiquifyMode(root.currentMode)
                        }
                    }
                }
            }

            // Pressure sensitivity toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * uiScale

                Text {
                    text: "Pen Pressure"
                    color: "#ccc"
                    font.pixelSize: 12 * uiScale
                    Layout.fillWidth: true
                }
                Rectangle {
                    id: pressureToggle
                    property bool enabled: true
                    width: 36 * uiScale; height: 20 * uiScale; radius: 10 * uiScale
                    color: enabled ? root.accentColor : "#333"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        x: pressureToggle.enabled ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16 * uiScale; height: 16 * uiScale; radius: 8 * uiScale
                        color: "white"
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: pressureToggle.enabled = !pressureToggle.enabled
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    //  INTERNAL COMPONENTS
    // ════════════════════════════════════════════════════════════

    // ── Mode Button ─────────────────────────────────────────────
    component LiqModeBtn : Rectangle {
        id: modeBtn
        property string iconSrc: ""
        property string label: ""
        property bool isActive: false
        property bool isAccent: false
        signal clicked()

        width: isActive && label !== "" ? (iconImg.width + labelTxt.implicitWidth + 18 * uiScale) : (36 * uiScale)
        height: 36 * uiScale
        radius: 18 * uiScale
        Layout.alignment: Qt.AlignVCenter

        color: isActive ? root.accentColor
                        : (modeMa.containsMouse ? "#20ffffff" : "transparent")

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        scale: modeMa.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }

        Row {
            anchors.centerIn: parent
            spacing: 5 * uiScale

            Image {
                id: iconImg
                source: modeBtn.iconSrc
                sourceSize.width: 18 * uiScale
                sourceSize.height: 18 * uiScale
                anchors.verticalCenter: parent.verticalCenter
                opacity: isActive ? 1.0 : 0.65
            }

            Text {
                id: labelTxt
                text: modeBtn.label
                color: "white"
                font.pixelSize: 11 * uiScale
                font.weight: Font.DemiBold
                visible: modeBtn.isActive && modeBtn.label !== ""
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: modeMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modeBtn.clicked()
        }

        ToolTip.visible: modeMa.containsMouse && !modeBtn.isActive
        ToolTip.text: modeBtn.label
        ToolTip.delay: 500
    }

    // ── Parameter Slider ────────────────────────────────────────
    component LiqSlider : Item {
        id: sliderItem
        property string label: ""
        property real value: 50
        property real from: 0
        property real to: 100
        property string suffix: "%"
        property color accentColor: root.accentColor
        property real uiScale: 1.0
        signal moved(real newValue)

        implicitWidth: 160 * uiScale
        implicitHeight: 36 * uiScale
        Layout.alignment: Qt.AlignVCenter

        // Label + Value
        RowLayout {
            anchors.top: parent.top
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 4

            Text {
                text: sliderItem.label
                color: "#999"
                font.pixelSize: 10 * uiScale
                font.weight: Font.Medium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(sliderItem.value) + sliderItem.suffix
                color: "#ccc"
                font.pixelSize: 10 * uiScale
                font.weight: Font.DemiBold
                font.family: "Monospace"
            }
        }

        // Track
        Item {
            anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right
            height: 14 * uiScale

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 4 * uiScale
                radius: 2 * uiScale
                color: "#20ffffff"

                // Fill
                Rectangle {
                    width: parent.width * ((sliderItem.value - sliderItem.from) / (sliderItem.to - sliderItem.from))
                    height: parent.height
                    radius: parent.radius
                    color: sliderItem.accentColor

                    Behavior on width { NumberAnimation { duration: 60 } }
                }
            }

            // Thumb
            Rectangle {
                x: (parent.width - width) * ((sliderItem.value - sliderItem.from) / (sliderItem.to - sliderItem.from))
                anchors.verticalCenter: parent.verticalCenter
                width: 12 * uiScale; height: 12 * uiScale; radius: 6 * uiScale
                color: sliderDrag.pressed ? Qt.lighter(sliderItem.accentColor, 1.3) : "white"
                border.color: sliderItem.accentColor; border.width: 1.5

                Behavior on color { ColorAnimation { duration: 100 } }
            }

            MouseArea {
                id: sliderDrag
                anchors.fill: parent
                anchors.margins: -6
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function calc(mx) {
                    var ratio = Math.max(0, Math.min(1, mx / parent.width))
                    return sliderItem.from + ratio * (sliderItem.to - sliderItem.from)
                }

                onPressed: function(m) {
                    sliderItem.value = calc(m.x)
                    sliderItem.moved(sliderItem.value)
                }
                onPositionChanged: function(m) {
                    if (pressed) {
                        sliderItem.value = calc(m.x)
                        sliderItem.moved(sliderItem.value)
                    }
                }
            }
        }
    }
}
