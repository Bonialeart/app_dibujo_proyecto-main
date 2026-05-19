import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ArtFlow 1.0

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
            spacing: 2 * uiScale

            ModeBtn {
                label: "New"
                tooltip: "New Selection (N)"
                active: canvas && canvas.selectionAddMode === 0
                onClicked: canvas.selectionAddMode = 0
            }
            ModeBtn {
                label: "Add"
                tooltip: "Add to Selection (Shift)"
                active: canvas && canvas.selectionAddMode === 1
                onClicked: canvas.selectionAddMode = 1
            }
            ModeBtn {
                label: "Sub"
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

        // ─── LASSO SUB-MODE (only when lasso is active) ───
        Row {
            spacing: 2 * uiScale
            visible: canvas && canvas.currentTool === "lasso"

            ModeBtn {
                label: "Free"
                tooltip: "Freehand Lasso"
                active: canvas && canvas.lassoMode === 0
                onClicked: canvas.lassoMode = 0
            }
            ModeBtn {
                label: "Poly"
                tooltip: "Polygonal Lasso (click to add vertices, double-click or click start to close)"
                active: canvas && canvas.lassoMode === 1
                onClicked: canvas.lassoMode = 1
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
                width: closeBtnLabel.implicitWidth + 18 * uiScale
                height: 30 * uiScale
                radius: 15 * uiScale
                color: closeArea.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.07)
                border.color: root.accentColor
                border.width: 1 * uiScale

                Text {
                    id: closeBtnLabel
                    anchors.centerIn: parent
                    text: "Close ↩"
                    color: root.accentColor
                    font.pixelSize: 11 * uiScale
                    font.weight: Font.Medium
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
            spacing: 2 * uiScale
            visible: canvas && canvas.hasSelection

            ActionBtn { label: "Invert";   onClicked: canvas.invertSelection() }
            ActionBtn { label: "Feather";  onClicked: canvas.featherSelection(8) }
            ActionBtn { label: "Copy";     onClicked: canvas.duplicateSelection() }
            ActionBtn { label: "Clear";    onClicked: canvas.clearSelectionContent() }
            ActionBtn { label: "Deselect"; onClicked: canvas.deselect() }
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
        property string label: ""
        property string tooltip: ""
        property bool active: false
        signal clicked()

        width: labelTxt.implicitWidth + 16 * uiScale
        height: 28 * uiScale
        radius: 14 * uiScale
        color: active ? root.accentColor : (modeMa.containsMouse ? "#22ffffff" : "transparent")
        border.color: active ? root.accentColor : "#22ffffff"
        border.width: 1 * uiScale

        ToolTip.visible: modeMa.containsMouse && tooltip !== ""
        ToolTip.text: tooltip
        ToolTip.delay: 600

        Text {
            id: labelTxt
            anchors.centerIn: parent
            text: parent.label
            color: parent.active ? "white" : "#ccffffff"
            font.pixelSize: 11 * uiScale
            font.weight: parent.active ? Font.Bold : Font.Normal
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
        ToolTip.delay: 600

        Image {
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "../../../../assets/icons/" + parent.icon
            sourceSize: Qt.size(22 * uiScale, 22 * uiScale)
            opacity: parent.active ? 1.0 : 0.7
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
        property string label: ""
        signal clicked()

        width: actionLabel.implicitWidth + 14 * uiScale
        height: 28 * uiScale
        radius: 14 * uiScale
        color: actionMa.containsMouse ? "#22ffffff" : "transparent"

        Text {
            id: actionLabel
            anchors.centerIn: parent
            text: parent.label
            color: "#ccffffff"
            font.pixelSize: 11 * uiScale
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
