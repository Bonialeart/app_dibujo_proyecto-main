import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"

    function _c() { return targetCanvas }
    function _active() { return _c() && _c().isFreeTransformActive }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        Text {
            text: "TRANSFORMACIÓN LIBRE"
            color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1
        }

        // Status row
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 6
            color: _active() ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.30) : "#1a1a1f"
            border.color: _active() ? accentColor : "#2a2a2d"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                Text {
                    text: _active() ? "Modo activo" : "Inactivo"
                    color: "white"; font.pixelSize: 12; Layout.fillWidth: true
                }
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: _active() ? "#22c55e" : "#666"
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
                text: "Activar (Ctrl+T)"
                Layout.fillWidth: true
                enabled: !_active()
                onClicked: { if (_c()) { _c().isFreeTransformActive = true; if (typeof canvasPage !== "undefined") canvasPage.activeToolIdx = 4 } }
            }
            Button {
                text: "Confirmar"
                Layout.fillWidth: true
                enabled: _active()
                highlighted: true
                onClicked: { if (_c()) _c().isFreeTransformActive = false }
            }
        }

        Text { text: "Opciones de interpolación"; color: "#888"; font.pixelSize: 10; Layout.topMargin: 6 }

        // Interpolation toggles
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Rectangle {
                Layout.fillWidth: true; height: 38; radius: 5
                color: (typeof mainWindow !== "undefined" && mainWindow.transformBilinear) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : (bilerpMa.containsMouse ? "#1f1f24" : "transparent")
                border.color: (typeof mainWindow !== "undefined" && mainWindow.transformBilinear) ? accentColor : "#2a2a2d"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: "Bilineal"; color: "white"; font.pixelSize: 11; Layout.fillWidth: true }
                    Switch {
                        checked: (typeof mainWindow !== "undefined") ? mainWindow.transformBilinear : true
                        onCheckedChanged: { if (typeof mainWindow !== "undefined") mainWindow.transformBilinear = checked }
                    }
                }
                MouseArea { id: bilerpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1 }
            }
            Rectangle {
                Layout.fillWidth: true; height: 38; radius: 5
                color: (typeof mainWindow !== "undefined" && mainWindow.transformAdvancedMesh) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : (meshMa.containsMouse ? "#1f1f24" : "transparent")
                border.color: (typeof mainWindow !== "undefined" && mainWindow.transformAdvancedMesh) ? accentColor : "#2a2a2d"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    Text { text: "Malla avanzada"; color: "white"; font.pixelSize: 11; Layout.fillWidth: true }
                    Switch {
                        checked: (typeof mainWindow !== "undefined") ? mainWindow.transformAdvancedMesh : false
                        onCheckedChanged: { if (typeof mainWindow !== "undefined") mainWindow.transformAdvancedMesh = checked }
                    }
                }
                MouseArea { id: meshMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            color: "#1a1a1f"; radius: 5; border.color: "#2a2a2d"; border.width: 1
            implicitHeight: tInfo.implicitHeight + 16
            Text {
                id: tInfo
                anchors.fill: parent; anchors.margins: 8
                text: "Activa Ctrl+T para entrar al modo de transformación. Arrastra las esquinas para escalar, gira con el handle, mueve para reposicionar."
                color: "#aaa"; font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }
}
