import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Kromo 1.0

// ══════════════════════════════════════════════════════════════════
//  LIQUIFY BAR  —  Premium Redesigned Floating Bottom Toolbar for Liquify
//  Consolidated capsule design with settings sliders toggle animation
// ══════════════════════════════════════════════════════════════════
Item {
    id: root

    // ── Public API ──────────────────────────────────────────────
    property var    canvas:       null
    property real   uiScale:      1.0
    property color  accentColor:  "#389fff" // Sleek sky-blue active accent

    // Liquify state (bound to C++ LiquifyEngine via CanvasItem)
    property bool   active:       false
    property int    currentMode:  0       // Maps to LiquifyMode enum
    property real   brushSize:    250.0   // Matches 50% initial size (50 * 5)
    property real   morpher:      0.0     // 0–100 range for UI
    property real   strength:     100.0   // 0–100 range for UI
    property real   momentum:     0.0     // 0–100 range for UI
    
    // Sliders pill toggle state
    property bool   showSliders:  true

    // ── Signals ─────────────────────────────────────────────────
    signal applyRequested()
    signal cancelRequested()

    // ── Dimensions & Anchors ────────────────────────────────────
    height: active ? (mainPill.height + (showSliders ? sliderPill.height + 12 * uiScale : 0) + 16 * uiScale) : 0
    width: parent ? parent.width : 800
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 12 * uiScale

    visible: active
    opacity: active ? 1.0 : 0.0

    onActiveChanged: {
        if (active && canvas) {
            canvas.setLiquifyMode(currentMode)
            canvas.setLiquifyRadius(brushSize)
            canvas.setLiquifyStrength(strength / 100.0)
            canvas.setLiquifyMorpher(morpher / 100.0)
        }
    }
    
    // Smooth transition animations when showing or toggling sliders bar
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    // ── Icon helper ─────────────────────────────────────────────
    function iconPath(name) {
        return "image://icons/" + name
    }

    // ── 8 Core Modes mapping to C++ ─────────────────────────────
    readonly property var modes: [
        { name: "Push",        icon: "liquify-push.svg",        mode: 0 },
        { name: "Twirl CW",    icon: "liquify-twirl-cw.svg",    mode: 1 },
        { name: "Twirl CCW",   icon: "liquify-twirl-ccw.svg",   mode: 2 },
        { name: "Pinch",       icon: "liquify-pinch.svg",       mode: 3 },
        { name: "Expand",      icon: "liquify-expand.svg",      mode: 4 },
        { name: "Crystals",    icon: "liquify-crystalize.svg",  mode: 5 },
        { name: "Edge",        icon: "liquify-edge.svg",        mode: 6 },
        { name: "Reconstruct", icon: "liquify-reconstruct.svg", mode: 7 }
    ]

    // ════════════════════════════════════════════════════════════
    //  MAIN TOOLBAR PILL (Mode Icons + Actions + Commit/Cancel)
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: mainPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: showSliders ? sliderPill.top : parent.bottom
        anchors.bottomMargin: showSliders ? 8 * uiScale : 4 * uiScale

        width: mainRow.implicitWidth + 32 * uiScale
        height: 52 * uiScale
        radius: 26 * uiScale

        // Sleek slate dark glassmorphism
        color: "#eb121216"
        border.color: "#3a3a40"
        border.width: 1

        // Drop shadow for floating premium depth
        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            z: -1
            radius: 34 * uiScale
            color: "black"
            opacity: 0.4
        }

        RowLayout {
            id: mainRow
            anchors.centerIn: parent
            spacing: 8 * uiScale

            // ── Settings Toggle (Far Left) ──
            Rectangle {
                width: 36 * uiScale; height: 36 * uiScale; radius: 18 * uiScale
                color: root.showSliders ? "#22ffffff" : "transparent"
                Layout.alignment: Qt.AlignVCenter
                scale: settingsMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    source: iconPath("sliders.svg")
                    sourceSize.width: 18 * uiScale
                    sourceSize.height: 18 * uiScale
                    anchors.centerIn: parent
                    opacity: root.showSliders ? 1.0 : 0.65
                }
                MouseArea {
                    id: settingsMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showSliders = !root.showSliders
                }
                
                // Subtle hover highlight
                Rectangle {
                    anchors.fill: parent; radius: 18 * uiScale; color: "white"; opacity: settingsMa.containsMouse ? 0.05 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // Divider
            Rectangle {
                width: 1; height: 24 * uiScale
                color: "#22ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // ── 6 Core Modes ──
            RowLayout {
                spacing: 4 * uiScale
                Repeater {
                    model: root.modes
                    delegate: LiqModeBtn {
                        iconSrc: iconPath(modelData.icon)
                        label: modelData.name
                        isActive: root.currentMode === modelData.mode
                        onClicked: {
                            root.currentMode = modelData.mode
                            if (root.canvas) root.canvas.setLiquifyMode(modelData.mode)
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: 1; height: 24 * uiScale
                color: "#22ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // ── Reset Button ──
            Rectangle {
                width: 36 * uiScale; height: 36 * uiScale; radius: 18 * uiScale
                color: "transparent"
                Layout.alignment: Qt.AlignVCenter
                scale: resetMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }

                Image {
                    source: iconPath("rotate.svg")
                    sourceSize.width: 16 * uiScale
                    sourceSize.height: 16 * uiScale
                    anchors.centerIn: parent
                    opacity: 0.65
                }
                MouseArea {
                    id: resetMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.canvas) {
                            root.canvas.cancelLiquify()
                            root.canvas.beginLiquify()
                            // Re-apply current mode and values
                            root.canvas.setLiquifyMode(root.currentMode)
                            root.canvas.setLiquifyRadius(root.brushSize)
                            root.canvas.setLiquifyStrength(root.strength / 100.0)
                            root.canvas.setLiquifyMorpher(root.morpher / 100.0)
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent; radius: 18 * uiScale; color: "white"; opacity: resetMa.containsMouse ? 0.05 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // Divider
            Rectangle {
                width: 1; height: 24 * uiScale
                color: "#22ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // ── Discard / Cancel Button (✕ Red Circle) ──
            Rectangle {
                width: 36 * uiScale; height: 36 * uiScale; radius: 18 * uiScale
                color: "#ff4757"
                Layout.alignment: Qt.AlignVCenter
                scale: cancelMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "white"
                    font.pixelSize: 15 * uiScale
                    font.bold: true
                }
                MouseArea {
                    id: cancelMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelRequested()
                }

                Rectangle {
                    anchors.fill: parent; radius: 18 * uiScale; color: "white"; opacity: cancelMa.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Commit / Apply Button (✓ Green Circle) ──
            Rectangle {
                width: 36 * uiScale; height: 36 * uiScale; radius: 18 * uiScale
                color: "#2ed573"
                Layout.alignment: Qt.AlignVCenter
                scale: applyMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: "white"
                    font.pixelSize: 15 * uiScale
                    font.bold: true
                }
                MouseArea {
                    id: applyMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyRequested()
                }

                Rectangle {
                    anchors.fill: parent; radius: 18 * uiScale; color: "white"; opacity: applyMa.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    //  SLIDERS PILL (Size / Morpher / Strength - Side-by-Side)
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: sliderPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4 * uiScale

        width: sliderRow.implicitWidth + 36 * uiScale
        height: 48 * uiScale
        radius: 24 * uiScale

        // Matching glassmorphic design
        color: "#eb121216"
        border.color: "#3a3a40"
        border.width: 1

        visible: root.showSliders && root.active
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -6
            z: -1
            radius: 30 * uiScale
            color: "black"
            opacity: 0.35
        }

        RowLayout {
            id: sliderRow
            anchors.centerIn: parent
            spacing: 12 * uiScale

            // 1. Size Slider (Mapped 1% - 100%)
            LiqSlider {
                label: "Size"
                value: root.brushSize / 5.0
                from: 1; to: 100
                suffix: "%"
                accentColor: root.accentColor
                uiScale: root.uiScale
                onMoved: function(v) {
                    var radiusVal = v * 5.0
                    root.brushSize = radiusVal
                    if (root.canvas) root.canvas.setLiquifyRadius(radiusVal)
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 20 * uiScale
                color: "#22ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // 2. Pressure Slider
            LiqSlider {
                label: "Pressure"
                value: root.strength
                from: 1; to: 100
                suffix: "%"
                accentColor: root.accentColor
                uiScale: root.uiScale
                onMoved: function(v) {
                    root.strength = v
                    if (root.canvas) root.canvas.setLiquifyStrength(v / 100.0)
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 20 * uiScale
                color: "#22ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // 3. Distortion Slider
            LiqSlider {
                label: "Distortion"
                value: root.morpher
                from: 0; to: 100
                suffix: "%"
                accentColor: root.accentColor
                uiScale: root.uiScale
                onMoved: function(v) {
                    root.morpher = v
                    if (root.canvas) root.canvas.setLiquifyMorpher(v / 100.0)
                }
            }

            // Separator
            Rectangle {
                width: 1; height: 20 * uiScale
                color: "#22ffffff"
                Layout.alignment: Qt.AlignVCenter
            }

            // 4. Momentum Slider
            LiqSlider {
                label: "Momentum"
                value: root.momentum
                from: 0; to: 100
                suffix: "%"
                accentColor: root.accentColor
                uiScale: root.uiScale
                onMoved: function(v) {
                    root.momentum = v
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════
    //  INTERNAL COMPONENT: Mode Button Capsule
    // ════════════════════════════════════════════════════════════
    component LiqModeBtn : Rectangle {
        id: modeBtn
        property string iconSrc: ""
        property string label: ""
        property bool isActive: false
        signal clicked()

        clip: true
        width: isActive && label !== "" ? (iconImg.width + labelTxt.implicitWidth + 24 * uiScale) : (36 * uiScale)
        height: 36 * uiScale
        radius: 18 * uiScale
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: width
        Layout.preferredHeight: height

        // Sky blue highlight active pill capsule, clean transparent for inactive
        color: isActive ? root.accentColor
                        : (modeMa.containsMouse ? "#20ffffff" : "transparent")

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        scale: modeMa.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }

        Row {
            anchors.centerIn: parent
            spacing: 6 * uiScale

            Image {
                id: iconImg
                source: modeBtn.iconSrc
                sourceSize.width: 16 * uiScale
                sourceSize.height: 16 * uiScale
                anchors.verticalCenter: parent.verticalCenter
                opacity: isActive ? 1.0 : 0.65
            }

            Text {
                id: labelTxt
                text: modeBtn.label
                color: "white"
                font.pixelSize: 10 * uiScale
                font.weight: Font.DemiBold
                font.family: "System-UI, Segoe UI, sans-serif"
                opacity: modeBtn.isActive ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: modeMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modeBtn.clicked()
        }
    }

    // ════════════════════════════════════════════════════════════
    //  INTERNAL COMPONENT: Parameter Slider Nodes
    // ════════════════════════════════════════════════════════════
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

        implicitWidth: 112 * uiScale
        implicitHeight: 36 * uiScale
        Layout.alignment: Qt.AlignVCenter

        // Label (Left) + Value (Right)
        RowLayout {
            anchors.top: parent.top
            anchors.left: parent.left; anchors.right: parent.right
            spacing: 4

            Text {
                text: sliderItem.label
                color: "#999"
                font.pixelSize: 10 * uiScale
                font.weight: Font.Medium
                font.family: "System-UI, Segoe UI, sans-serif"
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

        // Track & Thumb (Bottom)
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

                // Fill value
                Rectangle {
                    width: parent.width * ((sliderItem.value - sliderItem.from) / (sliderItem.to - sliderItem.from))
                    height: parent.height
                    radius: parent.radius
                    color: sliderItem.accentColor
                }
            }

            // Sleek Round Thumb
            Rectangle {
                x: (parent.width - width) * ((sliderItem.value - sliderItem.from) / (sliderItem.to - sliderItem.from))
                anchors.verticalCenter: parent.verticalCenter
                width: 12 * uiScale; height: 12 * uiScale; radius: 6 * uiScale
                color: "white"
                border.color: sliderItem.accentColor
                border.width: 1.5
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
