import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text {
            text: "HISTORIAL DE COLOR"
            color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
        }

        Text {
            text: "Últimos colores usados. Clic para activar."
            color: "#888"; font.pixelSize: 10
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 32
            cellHeight: 32
            clip: true
            model: (typeof mainWindow !== "undefined" && mainWindow.recentColors)
                   ? mainWindow.recentColors : []
            delegate: Rectangle {
                width: 28
                height: 28
                color: modelData
                radius: 4
                border.color: swatchMa.containsMouse ? "#ffffff" : Qt.darker(modelData, 1.6)
                border.width: 1
                anchors.margins: 2
                MouseArea {
                    id: swatchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (targetCanvas) {
                            targetCanvas.brushColor = modelData
                            if (typeof toastManager !== "undefined") {
                                toastManager.show("Color aplicado", "info")
                            }
                        }
                    }
                    ToolTip.visible: containsMouse
                    ToolTip.text: modelData
                    ToolTip.delay: 500
                }
            }
        }

        Text {
            text: grid.count === 0 ? "Sin historial aún" : grid.count + " color(es) en historial"
            color: "#666"; font.pixelSize: 10
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
