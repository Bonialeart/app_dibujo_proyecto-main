import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kromo 1.0

// ColorRangeDialog is loaded on demand
ColorRangeDialog {
    id: colorRangeDialog
    canvas: root.canvas
    uiScale: root.uiScale
    accentColor: root.accentColor
}

Item {
    id: root
    property var canvas
    property var uiScale: 1.0
    property color accentColor: "#6366f1"

    height: 62 * uiScale
    width: mainRow.implicitWidth + 40 * uiScale

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40 * uiScale

    visible: canvas ? (canvas.isSelectionModeActive ||
                       canvas.currentTool === "lasso" ||
                       canvas.currentTool === "magnetic_lasso" ||
                       canvas.currentTool === "select_rect" ||
                       canvas.currentTool === "select_ellipse" ||
                       canvas.currentTool === "select_wand") : false

    // Glassmorphism background
    Rectangle {
        anchors.fill: parent
        radius: 31 * uiScale
        color: "#dd17171a"
        border.color: "#40ffffff"
        border.width: 1 * uiScale

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: parent.height * 0.5
            radius: parent.radius
            color: "#12ffffff"
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

            ToolBtn {
                icon: "lasso.svg"
                tip: "Freehand Lasso (L)"
                active: canvas && canvas.currentTool === "lasso"
                onClicked: canvas.currentTool = "lasso"
            }
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
            ToolBtn {
                icon: "magnet.svg"
                tip: "Polygonal Lasso (P)"
                active: canvas && canvas.currentTool === "magnetic_lasso"
                onClicked: canvas.currentTool = "magnetic_lasso"
            }
            ToolBtn {
                icon: "selection.svg"
                tip: "Select All (Ctrl+A)"
                active: false
                onClicked: canvas.selectAll()
            }
        }

        // ─── DIVIDER ───
        Divider {}

        // ─── COLOR RANGE BUTTON ───
        ToolBtn {
            id: colorRangeBtn
            icon: "dropper.svg"
            tip: "Select by Color Range..."
            active: false
            onClicked: colorRangeDialog.open()
        }

        // ─── DIVIDER ───
        Divider {}

        // ─── LASSO SUB-MODE (only when lasso is active) ───
        Row {
            spacing: 4 * uiScale
            visible: canvas && canvas.currentTool === "lasso"

            ModeBtn {
                icon: "lasso.svg"
                tooltip: "Freehand Lasso"
                active: canvas && canvas.lassoMode === 0
                onClicked: canvas.lassoMode = 0
            }
            ModeBtn {
                icon: "magnet.svg"
                tooltip: "Polygonal Lasso (click to add vertices, double-click or click start to close)"
                active: canvas && canvas.lassoMode === 1
                onClicked: canvas.lassoMode = 1
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
                            color: "#22ffffff"
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
                            color: "#22ffffff"
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
                color: closeArea.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.07)
                border.color: root.accentColor
                border.width: 1 * uiScale

                ToolTip.visible: closeArea.containsMouse
                ToolTip.text: "Apply / Close Path (Enter)"
                ToolTip.delay: 300

                Image {
                    anchors.fill: parent
                    anchors.margins: 7 * uiScale
                    source: "../../../../assets/icons/arrow-down-left.svg"
                    sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
                    opacity: closeArea.containsMouse ? 1.0 : 0.7
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: canvas.closeLasso()
                }

                Behavior on color { ColorAnimation { duration: 120 } }
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
        height: 28 * uiScale
        color: "#33ffffff"
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
        color: active ? root.accentColor : (modeMa.containsMouse ? "#22ffffff" : "transparent")
        border.color: active ? root.accentColor : "#22ffffff"
        border.width: 1 * uiScale

        ToolTip.visible: modeMa.containsMouse && tooltip !== ""
        ToolTip.text: tooltip
        ToolTip.delay: 300

        Image {
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
            opacity: parent.active ? 1.0 : 0.7
            smooth: true
            mipmap: true
        }

        MouseArea {
            id: modeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
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
        color: active ? root.accentColor : (toolMa.containsMouse ? "#22ffffff" : "transparent")

        ToolTip.visible: toolMa.containsMouse && tip !== ""
        ToolTip.text: tip
        ToolTip.delay: 300

        Image {
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(22 * uiScale, 22 * uiScale)
            opacity: parent.active ? 1.0 : 0.7
            smooth: true
            mipmap: true
        }

        MouseArea {
            id: toolMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    component ActionBtn : Rectangle {
        id: actionBtnRoot
        property string icon: ""
        property string tip: ""
        signal clicked()

        width: 32 * uiScale
        height: 32 * uiScale
        radius: 16 * uiScale
        color: actionMa.containsMouse ? "#22ffffff" : "transparent"

        ToolTip.visible: actionMa.containsMouse && tip !== ""
        ToolTip.text: tip
        ToolTip.delay: 300

        Image {
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
            opacity: actionMa.containsMouse ? 1.0 : 0.7
            smooth: true
            mipmap: true
        }

        MouseArea {
            id: actionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
