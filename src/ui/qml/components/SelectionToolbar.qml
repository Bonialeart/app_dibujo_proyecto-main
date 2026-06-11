import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Kromo 1.0

Item {
    id: root
    property var canvas
    property var canvasPageRef: null
    property var uiScale: 1.0
    property color accentColor: "#6366f1"

    property bool featherPopoverActive: false

    // ColorRangeDialog is loaded on demand
    ColorRangeDialog {
        id: colorRangeDialog
        canvas: root.canvas
        uiScale: root.uiScale
        accentColor: root.accentColor
    }

    height: 48 * uiScale
    width: mainRow.implicitWidth + 32 * uiScale

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    // The toolbar is active if a selection tool is selected and we are NOT in the middle of a transformation
    property bool isActive: canvas ? ((canvas.isSelectionModeActive ||
                                      canvas.currentTool === "lasso" ||
                                      canvas.currentTool === "magnetic_lasso" ||
                                      canvas.currentTool === "select_rect" ||
                                      canvas.currentTool === "select_ellipse" ||
                                      canvas.currentTool === "select_wand") && !canvas.isTransforming) : false

    opacity: isActive ? 1.0 : 0.0
    visible: opacity > 0.0
    scale: isActive ? 1.0 : 0.92

    anchors.bottomMargin: (isActive ? 32 : 12) * uiScale

    onIsActiveChanged: {
        if (!isActive) {
            featherPopoverActive = false;
        }
        console.log("SelectionToolbar: isActive =", isActive, "canvas:", canvas, "currentTool:", canvas ? canvas.currentTool : "null", "isSelectionModeActive:", canvas ? canvas.isSelectionModeActive : "false")
    }

    onCanvasChanged: {
        console.log("SelectionToolbar: canvas changed to:", canvas)
    }

    Component.onCompleted: {
        console.log("SelectionToolbar: Completed! canvas:", canvas, "uiScale:", uiScale)
    }

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

    // ─── GLASSMORPHISM BACKGROUND ───
    Rectangle {
        anchors.fill: parent
        radius: 24 * uiScale
        color: "#eb0c0c0f"
        border.color: "#25ffffff"
        border.width: 1 * uiScale

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 20 * root.uiScale
            shadowColor: "#80000000"
            shadowVerticalOffset: 6 * root.uiScale
            shadowOpacity: 0.6
        }
    }

    // ─── FEATHER POPUP OVERLAY ───
    Rectangle {
        id: featherPopover
        visible: featherPopoverActive
        width: 190 * uiScale
        height: 52 * uiScale
        radius: 12 * uiScale
        color: "#f0101014"
        border.color: "#25ffffff"
        border.width: 1 * uiScale
        
        anchors.bottom: parent.top
        anchors.bottomMargin: 10 * uiScale
        x: mainRow.x + slidersBtn.x + (slidersBtn.width - width) / 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 15 * root.uiScale
            shadowColor: "#90000000"
            shadowOpacity: 0.6
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8 * uiScale
            spacing: 2 * uiScale

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Feather Selection"
                    color: "#f0f0f5"
                    font.pixelSize: 10 * uiScale
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(featherSlider.value) + " px"
                    color: root.accentColor
                    font.pixelSize: 10 * uiScale
                    font.family: "Monospace"
                }
            }

            Slider {
                id: featherSlider
                Layout.fillWidth: true
                height: 18 * uiScale
                from: 0
                to: 100
                stepSize: 1
                value: 8
                
                background: Rectangle {
                    x: 0
                    y: (parent.height - height) / 2
                    width: parent.width; height: 3 * uiScale
                    radius: 1.5 * uiScale
                    color: "#25ffffff"
                    Rectangle {
                        width: parent.parent.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: root.accentColor
                    }
                }
                
                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: (parent.height - height) / 2
                    width: 10 * uiScale; height: 10 * uiScale
                    radius: 5 * uiScale
                    color: "white"
                    border.color: root.accentColor
                    border.width: 2 * uiScale
                }

                onMoved: {
                    if (canvas) canvas.featherSelection(value)
                }
            }
        }
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 12 * uiScale

        // 1. DESELECT
        ActionBtn {
            icon: "deselect.svg"
            tip: "Deselect (Ctrl+D)"
            onClicked: {
                featherPopoverActive = false
                if (canvas) canvas.deselect()
            }
        }

        // 2. SELECTION MODE (CYCLE NEW -> ADD -> SUBTRACT)
        ActionBtn {
            id: modeBtn
            icon: {
                if (!canvas) return "selection-new.svg";
                switch (canvas.selectionAddMode) {
                    case 0: return "selection-new.svg";
                    case 1: return "selection-add.svg";
                    case 2: return "selection-sub.svg";
                    default: return "selection-new.svg";
                }
            }
            tip: {
                if (!canvas) return "Selection Mode";
                switch (canvas.selectionAddMode) {
                    case 0: return "Mode: New Selection";
                    case 1: return "Mode: Add to Selection (Shift)";
                    case 2: return "Mode: Subtract from Selection (Alt)";
                    default: return "Selection Mode";
                }
            }
            onClicked: {
                featherPopoverActive = false
                if (canvas) {
                    canvas.selectionAddMode = (canvas.selectionAddMode + 1) % 3
                }
            }
        }

        // 3. INVERT SELECTION
        ActionBtn {
            icon: "invert-selection.svg"
            tip: "Invert Selection (Ctrl+Shift+I)"
            onClicked: {
                featherPopoverActive = false
                if (canvas) canvas.invertSelection()
            }
        }

        // 4. MOVE / TRANSFORM (Ctrl+T)
        ActionBtn {
            icon: "move.svg"
            tip: "Move & Transform Selection (Ctrl+T)"
            onClicked: {
                featherPopoverActive = false
                if (canvas && canvasPageRef) {
                    canvas.isFreeTransformActive = true
                    canvasPageRef.activeToolIdx = 4 // V / Move Tool index in main_pro.qml
                }
            }
        }

        // 5. DUPLICATE SELECTION
        ActionBtn {
            icon: "copy.svg"
            tip: "Duplicate Selection (Ctrl+C)"
            onClicked: {
                featherPopoverActive = false
                if (canvas) canvas.duplicateSelection()
            }
        }

        // 6. CUT / CLEAR CONTENT
        ActionBtn {
            icon: "scissors.svg"
            tip: "Cut / Clear Content (Delete)"
            onClicked: {
                featherPopoverActive = false
                if (canvas) canvas.clearSelectionContent()
            }
        }

        // 7. FEATHER SELECTION
        ActionBtn {
            id: slidersBtn
            icon: "sliders.svg"
            tip: "Feather Edge Settings"
            onClicked: {
                featherPopoverActive = !featherPopoverActive
            }
        }

        // 8. CLOSE PATH (VISIBLE ONLY FOR POLYGONAL/MAGNETIC LASSO)
        ActionBtn {
            id: closePathBtn
            icon: "check.svg"
            tip: "Apply / Close Lasso Path (Enter)"
            visible: canvas && (
                (canvas.currentTool === "lasso" && canvas.lassoMode === 1) ||
                canvas.currentTool === "magnetic_lasso"
            )
            onClicked: {
                featherPopoverActive = false
                canvas.closeLasso()
            }
        }
    }

    // ─── REUSABLE PREMIUM ACTION BUTTON COMPONENT ───
    component ActionBtn : Rectangle {
        id: actionBtnRoot
        property string icon: ""
        property string tip: ""
        signal clicked()

        width: 32 * uiScale
        height: 32 * uiScale
        implicitWidth: 32 * uiScale
        implicitHeight: 32 * uiScale
        radius: 16 * uiScale

        color: actionMa.pressed ? "#25ffffff" : (actionMa.containsMouse ? "#15ffffff" : "transparent")
        border.color: actionMa.containsMouse ? "#30ffffff" : "transparent"
        border.width: 1 * uiScale

        scale: actionMa.pressed ? 0.92 : (actionMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        ToolTip {
            id: actionTipComp
            visible: actionMa.containsMouse && tip !== ""
            text: tip
            delay: 400
            background: Rectangle {
                color: "#1c1c22"
                border.color: "#30ffffff"
                border.width: 1
                radius: 6 * root.uiScale
            }
            contentItem: Text {
                text: actionTipComp.text
                color: "#f0f0f5"
                font.pixelSize: 10 * root.uiScale
                font.weight: Font.Medium
            }
        }

        Image {
            id: actionImg
            anchors.fill: parent
            anchors.margins: 7 * uiScale
            source: "image://icons/" + parent.icon + "?t=dark"
            sourceSize: Qt.size(18 * uiScale, 18 * uiScale)
            opacity: actionMa.containsMouse ? 1.0 : 0.75
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
