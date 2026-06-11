import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Kromo 1.0

Item {
    id: root
    property var canvas
    property var uiScale: 1.0
    property color accentColor: "#6366f1"

    // ColorRangeDialog is loaded on demand
    ColorRangeDialog {
        id: colorRangeDialog
        canvas: root.canvas
        uiScale: root.uiScale
        accentColor: root.accentColor
    }

    height: 62 * uiScale
    width: mainRow.implicitWidth + 40 * uiScale

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    property bool isActive: canvas ? (canvas.isSelectionModeActive ||
                                     canvas.currentTool === "lasso" ||
                                     canvas.currentTool === "magnetic_lasso" ||
                                     canvas.currentTool === "select_rect" ||
                                     canvas.currentTool === "select_ellipse" ||
                                     canvas.currentTool === "select_wand") : false

    opacity: isActive ? 1.0 : 0.0
    visible: opacity > 0.0
    scale: isActive ? 1.0 : 0.92

    anchors.bottomMargin: (isActive ? 40 : 20) * uiScale

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutBack
        }
    }
    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // Glassmorphism background
    Rectangle {
        anchors.fill: parent
        radius: 31 * uiScale
        color: "#ee0b0b0e"
        border.color: "#25ffffff"
        border.width: 1 * uiScale

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 25 * root.uiScale
            shadowColor: "#aa000000"
            shadowVerticalOffset: 8 * root.uiScale
            shadowOpacity: 0.55
        }
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 10 * uiScale

        // ─── SELECTION MODE: New / Add / Subtract / Intersect ───
        Row {
            spacing: 4 * uiScale

            ModeBtn {
                icon: "selection-new.svg"
                tooltip: "New Selection (N)"
                active: canvas && canvas.selectionAddMode === 0
                onClicked: canvas.selectionAddMode = 0
            }
            ModeBtn {
                icon: "selection-add.svg"
                tooltip: "Add to Selection (Shift)"
                active: canvas && canvas.selectionAddMode === 1
                onClicked: canvas.selectionAddMode = 1
            }
            ModeBtn {
                icon: "selection-sub.svg"
                tooltip: "Subtract from Selection (Alt)"
                active: canvas && canvas.selectionAddMode === 2
                onClicked: canvas.selectionAddMode = 2
            }
        }

        // ─── DIVIDER ───
        Divider {}

        // ─── TOOL ICONS ───
        RowLayout {
            spacing: 6 * uiScale

            // Lasso Group
            ToolBtn {
                icon: "lasso.svg"
                tip: "Freehand Lasso (L)"
                active: canvas && canvas.currentTool === "lasso" && canvas.lassoMode === 0
                onClicked: {
                    canvas.currentTool = "lasso"
                    canvas.lassoMode = 0
                }
            }
            ToolBtn {
                icon: "polygonal-lasso.svg"
                tip: "Polygonal Lasso (P)"
                active: canvas && canvas.currentTool === "lasso" && canvas.lassoMode === 1
                onClicked: {
                    canvas.currentTool = "lasso"
                    canvas.lassoMode = 1
                }
            }
            ToolBtn {
                icon: "magnet.svg"
                tip: "Magnetic Lasso (M)"
                active: canvas && canvas.currentTool === "magnetic_lasso"
                onClicked: canvas.currentTool = "magnetic_lasso"
            }

            // Small vertical separator inside the row
            Rectangle {
                width: 1; height: 16 * uiScale; color: "#25ffffff"
            }

            // Magic Selector Group
            ToolBtn {
                icon: "wand.svg"
                tip: "Magic Wand (W)"
                active: canvas && canvas.currentTool === "select_wand"
                onClicked: canvas.currentTool = "select_wand"
            }
            ToolBtn {
                id: colorRangeBtn
                icon: "eyedropper.svg"
                tip: "Select by Color Range..."
                active: false
                onClicked: colorRangeDialog.open()
            }

            // Small vertical separator inside the row
            Rectangle {
                width: 1; height: 16 * uiScale; color: "#25ffffff"
            }

            // Shape Select Group
            ToolBtn {
                icon: "shapes.svg"
                tip: "Rectangle Select (R)"
                active: canvas && canvas.currentTool === "select_rect"
                onClicked: canvas.currentTool = "select_rect"
            }
            ToolBtn {
                icon: "shapes.svg"
                tip: "Ellipse Select (E)"
                active: canvas && canvas.currentTool === "select_ellipse"
                onClicked: canvas.currentTool = "select_ellipse"
            }

            // Small vertical separator inside the row
            Rectangle {
                width: 1; height: 16 * uiScale; color: "#25ffffff"
            }

            // Select All
            ToolBtn {
                icon: "selection.svg"
                tip: "Select All (Ctrl+A)"
                active: false
                onClicked: canvas.selectAll()
            }
        }

        // ─── MAGNETIC LASSO SETTINGS ───
        Row {
            spacing: 8 * uiScale
            visible: canvas && canvas.currentTool === "magnetic_lasso"

            Column {
                spacing: 4 * uiScale

                Text {
                    text: "Sensitivity"
                    color: "#aaaaaa"
                    font.pixelSize: 9 * uiScale
                }

                Row {
                    spacing: 4 * uiScale

                    Slider {
                        id: sensitivitySlider
                        width: 72 * uiScale
                        height: 24 * uiScale
                        from: 0.1
                        to: 1.0
                        stepSize: 0.05
                        value: canvas ? canvas.magneticEdgeSensitivity : 0.85
                        onMoved: if (canvas) canvas.magneticEdgeSensitivity = value

                        background: Rectangle {
                            x: 0
                            y: (parent.height - height) / 2
                            width: parent.width; height: 4 * uiScale
                            radius: 2 * uiScale
                            color: sensitivitySlider.hovered ? "#33ffffff" : "#1affffff"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                width: sensitivitySlider.visualPosition * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: root.accentColor
                            }
                        }
                        handle: Rectangle {
                            x: sensitivitySlider.leftPadding + sensitivitySlider.visualPosition * (sensitivitySlider.availableWidth - width)
                            y: (sensitivitySlider.height - height) / 2
                            width: 12 * uiScale; height: 12 * uiScale
                            radius: 6 * uiScale
                            color: "white"
                            border.color: root.accentColor
                            border.width: 2 * uiScale
                            scale: sensitivitySlider.pressed ? 1.25 : (sensitivitySlider.hovered ? 1.12 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        }
                    }

                    Text {
                        text: Math.round((canvas ? canvas.magneticEdgeSensitivity : 0.85) * 100) + "%"
                        color: root.accentColor
                        font.pixelSize: 10 * uiScale
                        font.family: "Monospace"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Column {
                spacing: 4 * uiScale

                Text {
                    text: "Snap Radius"
                    color: "#aaaaaa"
                    font.pixelSize: 9 * uiScale
                }

                Row {
                    spacing: 4 * uiScale

                    Slider {
                        id: radiusSlider
                        width: 64 * uiScale
                        height: 24 * uiScale
                        from: 5
                        to: 30
                        stepSize: 1
                        value: canvas ? canvas.magneticSearchRadius : 12
                        onMoved: if (canvas) canvas.magneticSearchRadius = value

                        background: Rectangle {
                            x: 0
                            y: (parent.height - height) / 2
                            width: parent.width; height: 4 * uiScale
                            radius: 2 * uiScale
                            color: radiusSlider.hovered ? "#33ffffff" : "#1affffff"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                width: radiusSlider.visualPosition * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: root.accentColor
                            }
                        }
                        handle: Rectangle {
                            x: radiusSlider.leftPadding + radiusSlider.visualPosition * (radiusSlider.availableWidth - width)
                            y: (radiusSlider.height - height) / 2
                            width: 12 * uiScale; height: 12 * uiScale
                            radius: 6 * uiScale
                            color: "white"
                            border.color: root.accentColor
                            border.width: 2 * uiScale
                            scale: radiusSlider.pressed ? 1.25 : (radiusSlider.hovered ? 1.12 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        }
                    }

                    Text {
                        text: Math.round(canvas ? canvas.magneticSearchRadius : 12) + "px"
                        color: root.accentColor
                        font.pixelSize: 10 * uiScale
                        font.family: "Monospace"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Close button for polygonal lasso
        Item {
            width: closePolyBtn.visible ? closePolyBtn.width : 0
            height: 32 * uiScale

            Rectangle {
                id: closePolyBtn
                visible: canvas &&
                         (canvas.currentTool === "lasso" && canvas.lassoMode === 1 ||
                          canvas.currentTool === "magnetic_lasso")
                width: 32 * uiScale
                height: 32 * uiScale
                radius: 16 * uiScale
                color: closeArea.containsMouse ? "#1affffff" : "transparent"
                border.color: closeArea.containsMouse ? root.accentColor : "#1affffff"
                border.width: 1 * uiScale

                scale: closeArea.pressed ? 0.92 : (closeArea.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                ToolTip {
                    id: closeTipComp
                    visible: closeArea.containsMouse
                    text: "Apply / Close Path (Enter)"
                    delay: 300
                    background: Rectangle {
                        color: "#1e1e24"
                        border.color: "#3a3a3d"
                        radius: 6 * root.uiScale
                    }
                    contentItem: Text {
                        text: closeTipComp.text
                        color: "#f0f0f5"
                        font.pixelSize: 11 * root.uiScale
                        font.weight: Font.Medium
                    }
                }

                Image {
                    id: closeImg
                    anchors.fill: parent
                    anchors.margins: 7 * uiScale
                    source: "../../../../assets/icons/arrow-down-left.svg"
                    sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
                    opacity: closeArea.containsMouse ? 1.0 : 0.65
                    scale: closeArea.containsMouse ? 1.05 : 1.0
                    smooth: true
                    mipmap: true

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: canvas.closeLasso()
                }
            }
        }

        // ─── DIVIDER ───
        Divider { visible: canvas && canvas.hasSelection }

        // ─── QUICK ACTIONS ───
        Row {
            spacing: 4 * uiScale
            visible: canvas && canvas.hasSelection

            ActionBtn { icon: "invert-selection.svg"; tip: "Invert Selection (Ctrl+Shift+I)"; onClicked: canvas.invertSelection() }
            ActionBtn { icon: "feather-selection.svg"; tip: "Feather Edge"; onClicked: canvas.featherSelection(8) }
            ActionBtn { icon: "copy.svg"; tip: "Copy Selection (Ctrl+C)"; onClicked: canvas.duplicateSelection() }
            ActionBtn { icon: "trash-2.svg"; tip: "Clear Content (Delete)"; onClicked: canvas.clearSelectionContent() }
            ActionBtn { icon: "deselect.svg"; tip: "Deselect (Ctrl+D)"; onClicked: canvas.deselect() }
        }
    }

    // ─────────────────────────────────────────────────────
    //  INTERNAL COMPONENTS
    // ─────────────────────────────────────────────────────
    component Divider : Rectangle {
        width: 1
        height: 24 * uiScale
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "#25ffffff" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    component ModeBtn : Rectangle {
        id: modeBtnRoot
        property string icon: ""
        property string tooltip: ""
        property bool active: false
        signal clicked()

        width: 32 * uiScale
        height: 32 * uiScale
        radius: 16 * uiScale

        color: active ? root.accentColor : (modeMa.containsMouse ? "#1affffff" : "transparent")
        border.color: active ? root.accentColor : (modeMa.containsMouse ? "#40ffffff" : "#1affffff")
        border.width: 1 * uiScale

        scale: modeMa.pressed ? 0.92 : (modeMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        ToolTip {
            id: modeTipComp
            visible: modeMa.containsMouse && tooltip !== ""
            text: tooltip
            delay: 300
            background: Rectangle {
                color: "#1e1e24"
                border.color: "#3a3a3d"
                radius: 6 * root.uiScale
            }
            contentItem: Text {
                text: modeTipComp.text
                color: "#f0f0f5"
                font.pixelSize: 11 * root.uiScale
                font.weight: Font.Medium
            }
        }

        Image {
            id: modeImg
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
            opacity: parent.active ? 1.0 : (modeMa.containsMouse ? 0.95 : 0.65)
            scale: modeMa.containsMouse ? 1.05 : 1.0
            smooth: true
            mipmap: true

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: modeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component ToolBtn : Rectangle {
        id: toolBtnRoot
        property string icon: ""
        property string tip: ""
        property bool active: false
        signal clicked()

        width: 36 * uiScale
        height: 36 * uiScale
        radius: 10 * uiScale

        color: active ? root.accentColor : (toolMa.containsMouse ? "#1affffff" : "transparent")
        border.color: active ? root.accentColor : (toolMa.containsMouse ? "#40ffffff" : "#1affffff")
        border.width: 1 * uiScale

        scale: toolMa.pressed ? 0.92 : (toolMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        ToolTip {
            id: toolTipComp
            visible: toolMa.containsMouse && tip !== ""
            text: tip
            delay: 300
            background: Rectangle {
                color: "#1e1e24"
                border.color: "#3a3a3d"
                radius: 6 * root.uiScale
            }
            contentItem: Text {
                text: toolTipComp.text
                color: "#f0f0f5"
                font.pixelSize: 11 * root.uiScale
                font.weight: Font.Medium
            }
        }

        Image {
            id: toolImg
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(22 * uiScale, 22 * uiScale)
            opacity: parent.active ? 1.0 : (toolMa.containsMouse ? 0.95 : 0.65)
            scale: toolMa.containsMouse ? 1.05 : 1.0
            smooth: true
            mipmap: true

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: toolMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component ActionBtn : Rectangle {
        id: actionBtnRoot
        property string icon: ""
        property string tip: ""
        signal clicked()

        width: 32 * uiScale
        height: 32 * uiScale
        radius: 16 * uiScale

        color: actionMa.containsMouse ? "#1affffff" : "transparent"
        border.color: actionMa.containsMouse ? "#40ffffff" : "#1affffff"
        border.width: 1 * uiScale

        scale: actionMa.pressed ? 0.92 : (actionMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        ToolTip {
            id: actionTipComp
            visible: actionMa.containsMouse && tip !== ""
            text: tip
            delay: 300
            background: Rectangle {
                color: "#1e1e24"
                border.color: "#3a3a3d"
                radius: 6 * root.uiScale
            }
            contentItem: Text {
                text: actionTipComp.text
                color: "#f0f0f5"
                font.pixelSize: 11 * root.uiScale
                font.weight: Font.Medium
            }
        }

        Image {
            id: actionImg
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
            opacity: actionMa.containsMouse ? 1.0 : 0.65
            scale: actionMa.containsMouse ? 1.05 : 1.0
            smooth: true
            mipmap: true

            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            id: actionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
