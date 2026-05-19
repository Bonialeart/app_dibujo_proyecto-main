import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string iconName: ""
    property string label: ""
    property bool active: false
    property color accentColor: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 62 * uiScale

    // ── Left accent bar (only when active) ──
    Rectangle {
        width: 3 * uiScale; height: 26 * uiScale
        radius: 1.5 * uiScale
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: accentColor
        opacity: root.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Background pill ──
    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 16 * uiScale
        height: 50 * uiScale
        radius: 12 * uiScale
        color: root.active
            ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
            : (hoverArea.containsMouse ? "#12ffffff" : "transparent")
        border.color: root.active
            ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
            : (hoverArea.containsMouse ? "#0affffff" : "transparent")
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    // ── Icon + Label ──
    Column {
        anchors.centerIn: parent
        spacing: 5 * uiScale

        Image {
            source: root.iconName ? "image://icons/" + root.iconName : ""
            width: 22 * uiScale; height: 22 * uiScale
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.active ? 1.0 : (hoverArea.containsMouse ? 0.65 : 0.38)
            mipmap: true
            fillMode: Image.PreserveAspectFit
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            text: root.label
            color: root.active
                ? Qt.lighter(accentColor, 1.6)
                : (hoverArea.containsMouse ? "#aaa" : "#555")
            font.pixelSize: 10 * uiScale
            font.weight: root.active ? Font.DemiBold : Font.Normal
            font.letterSpacing: 0.2
            anchors.horizontalCenter: parent.horizontalCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // ── Press feedback ──
    scale: hoverArea.pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
