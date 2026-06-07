import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    function _c() { return targetCanvas }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Text {
            text: "SIMETRÍA"
            color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
        }

        // Master enable
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 6
            color: (_c() && _c().symmetryEnabled) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.30) : "#1a1a1f"
            border.color: (_c() && _c().symmetryEnabled) ? accentColor : "#2a2a2d"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8
                Text { text: "Activar simetría"; color: "white"; font.pixelSize: 12; Layout.fillWidth: true }
                Switch {
                    checked: _c() ? _c().symmetryEnabled : false
                    onCheckedChanged: { if (_c()) _c().symmetryEnabled = checked }
                }
            }
        }

        Text { text: "Modo"; color: "#888"; font.pixelSize: 10 }

        // Mode selector
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: [
                    { v: 0, label: "Desactivado",         desc: "Sin simetría" },
                    { v: 1, label: "Horizontal",          desc: "Espejo vertical (izquierda ↔ derecha)" },
                    { v: 2, label: "Vertical",            desc: "Espejo horizontal (arriba ↔ abajo)" },
                    { v: 3, label: "Ambos",               desc: "Espejo en cruz" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 5
                    color: (_c() && _c().symmetryMode === modelData.v)
                           ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25)
                           : (modeMa.containsMouse ? "#1f1f24" : "transparent")
                    border.color: (_c() && _c().symmetryMode === modelData.v) ? accentColor : "#2a2a2d"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        Text { text: modelData.label; color: "white"; font.pixelSize: 11; font.weight: Font.Medium }
                        Text { text: modelData.desc;  color: "#888"; font.pixelSize: 9 }
                    }

                    MouseArea {
                        id: modeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (_c()) {
                                _c().symmetryMode = modelData.v
                                if (modelData.v !== 0) _c().symmetryEnabled = true
                            }
                        }
                    }
                }
            }
        }

        // Tip
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            color: "#1a1a1f"
            radius: 5
            border.color: "#2a2a2d"; border.width: 1
            implicitHeight: tipText.implicitHeight + 16
            Text {
                id: tipText
                anchors.fill: parent
                anchors.margins: 8
                text: "Tip: la simetría refleja cada trazo en tiempo real. Úsala para rostros, vehículos, patrones."
                color: "#aaa"; font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }
}
