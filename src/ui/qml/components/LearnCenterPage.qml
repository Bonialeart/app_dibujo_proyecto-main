import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: learnRoot
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    readonly property color colorBg: "#060608"
    readonly property color colorSurface: "#111116"
    readonly property color colorBorder: "#1c1c22"
    readonly property color colorAccent: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color colorText: "#f4f4f8"
    readonly property color colorMuted: "#a0a0b0"

    // Background Premium
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08080c" }
            GradientStop { position: 0.5; color: "#060609" }
            GradientStop { position: 1.0; color: "#0a0a10" }
        }
    }

    // Orb Effect Glow
    Rectangle {
        width: 600; height: 600; radius: 300
        x: parent.width - 300; y: -200
        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.03)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
    }

    // Tab Bar state
    property int currentIndex: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header Title
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text {
                    text: "Centro de Aprendizaje"
                    color: colorText
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    font.letterSpacing: -1.0
                }
                Text {
                    text: "Mejora tus habilidades con recursos profesionales y consejos de maestría"
                    color: colorMuted
                    font.pixelSize: 15
                }
            }
        }

        // Custom Premium Tab Bar
        Row {
            Layout.fillWidth: true
            Layout.leftMargin: 40
            Layout.bottomMargin: 30
            spacing: 20
            Repeater {
                model: ["🎬  Video Tutoriales", "💡  Tips de Artistas", "🏛  Consejos de Maestros"]
                delegate: Rectangle {
                    width: tabTxt.implicitWidth + 40
                    height: 44
                    radius: 22
                    color: learnRoot.currentIndex === index ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15) : (tabMa.containsMouse ? "#1affffff" : "transparent")
                    border.color: learnRoot.currentIndex === index ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        id: tabTxt
                        anchors.centerIn: parent
                        text: modelData
                        color: learnRoot.currentIndex === index ? "#ffffff" : colorMuted
                        font.pixelSize: 14
                        font.weight: learnRoot.currentIndex === index ? Font.Bold : Font.Normal
                    }
                    MouseArea {
                        id: tabMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: learnRoot.currentIndex = index
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: learnRoot.currentIndex

            // ═════════════════════════════════════════════════════════════════
            // TAB 1: VIDEOS
            // ═════════════════════════════════════════════════════════════════
            Item {
                GridView {
                    anchors.fill: parent
                    anchors.leftMargin: 40; anchors.rightMargin: 40
                    cellWidth: 320; cellHeight: 280
                    clip: true
                    model: ListModel {
                        ListElement { title: "Línea, Forma y Proporción"; channel: "Proko"; duration: "14:22"; videoId: "SU3_doNYOdk"; icon: "📐"; thumb: "https://img.youtube.com/vi/SU3_doNYOdk/mqdefault.jpg" }
                        ListElement { title: "Luces y Sombras"; channel: "Ctrl+Paint"; duration: "11:45"; videoId: "YHjuiakQ-Kk"; icon: "🌗"; thumb: "https://img.youtube.com/vi/YHjuiakQ-Kk/mqdefault.jpg" }
                        ListElement { title: "Teoría del Color"; channel: "Marco Bucci"; duration: "20:05"; videoId: "67LGQpr3Y6A"; icon: "🎨"; thumb: "https://img.youtube.com/vi/67LGQpr3Y6A/mqdefault.jpg" }
                        ListElement { title: "Perspectiva de Puntos"; channel: "DrawABox"; duration: "18:30"; videoId: "Y5PTd3rVO78"; icon: "🏛"; thumb: "https://img.youtube.com/vi/Y5PTd3rVO78/mqdefault.jpg" }
                        ListElement { title: "Anatomía Básica"; channel: "Proko"; duration: "22:10"; videoId: "74HR59yFZ7Y"; icon: "🧍"; thumb: "https://img.youtube.com/vi/74HR59yFZ7Y/mqdefault.jpg" }
                        ListElement { title: "Pintura de Fondos"; channel: "Ty Carter"; duration: "24:00"; videoId: "3aFxBWiLkiM"; icon: "🌄"; thumb: "https://img.youtube.com/vi/3aFxBWiLkiM/mqdefault.jpg" }
                    }
                    delegate: Rectangle {
                        width: 290; height: 250
                        radius: 16
                        color: colorSurface
                        border.color: vcardMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5) : colorBorder
                        border.width: 1
                        clip: true
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        scale: vcardMa.pressed ? 0.96 : 1.0

                        Column {
                            anchors.fill: parent
                            Rectangle {
                                width: parent.width; height: 160
                                color: "#000"
                                Image {
                                    anchors.fill: parent; source: thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true
                                }
                                Rectangle {
                                    anchors.fill: parent; color: vcardMa.containsMouse ? "#20000000" : "#50000000"
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Rectangle {
                                        width: 48; height: 48; radius: 24
                                        anchors.centerIn: parent
                                        color: vcardMa.containsMouse ? "#dd0000" : "#aa0000"
                                        Text { text: "▶"; color: "white"; anchors.centerIn: parent; font.pixelSize: 18 }
                                        scale: vcardMa.containsMouse ? 1.1 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 10
                                    width: durTxt.width + 12; height: 22; color: "#cc000000"; radius: 6
                                    Text { id: durTxt; text: duration; color: "white"; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.centerIn: parent }
                                }
                            }
                            Item { width: 1; height: 12 }
                            Column {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 16
                                spacing: 6
                                Text { text: title; color: colorText; font.pixelSize: 15; font.weight: Font.Bold; elide: Text.ElideRight; width: parent.width }
                                Text { text: icon + "  " + channel; color: colorMuted; font.pixelSize: 12 }
                            }
                        }
                        MouseArea {
                            id: vcardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://www.youtube.com/watch?v=" + videoId)
                        }
                    }
                }
            }

            // ═════════════════════════════════════════════════════════════════
            // TAB 2: TIPS GLOBALES
            // ═════════════════════════════════════════════════════════════════
            Item {
                ListView {
                    anchors.fill: parent
                    anchors.leftMargin: 40; anchors.rightMargin: 40
                    spacing: 20
                    clip: true
                    model: ListModel {
                        ListElement { author: "Loish"; title: "Uso del color dinámico"; content: "No te limites a sombrear con negro o aclarar con blanco. Usa variaciones de temperatura térmica: sombras frías e iluminaciones cálidas (o viceversa). Esto dará vida y riqueza a la paleta."; tag: "🎨 Color" }
                        ListElement { author: "Ross Tran"; title: "Dinámica y flujo"; content: "Busca siempre una 'línea de acción' clara antes de meter detalles. Si el gesto general es tieso o aburrido, ningún nivel de detalle lo arreglará. Exagera las curvas al inicio."; tag: "✍️ Gestual" }
                        ListElement { author: "WLOP"; title: "Subsurface Scattering"; content: "La piel humana no es plástico. Observa la dispersión subsuperficial en las sombras proyectadas sobre la piel para darle un toque realista, suave y natural a tus personajes."; tag: "💡 Iluminación" }
                        ListElement { author: "Sinix"; title: "Anatomía como bloques primitivos"; content: "No pienses en músculos primero, piensa en formas 3D primitivas. Cajas para el torso, cilindros para extremidades. Asegúrate de que esas formas funcionen en el espacio."; tag: "🧍 Anatomía" }
                        ListElement { author: "Marco Bucci"; title: "Economía del trazo"; content: "No necesitas renderizar cada hoja del árbol. El cerebro humano rellena los espacios vacíos. Céntrate en sugerir texturas donde incide la luz y deja en silencio las sombras."; tag: "🖌 Pinceladas" }
                    }
                    delegate: Rectangle {
                        width: parent.width - 80; height: 160
                        radius: 16
                        color: tipMa.containsMouse ? "#15151c" : colorSurface
                        border.color: tipMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.4) : colorBorder
                        border.width: 1
                        Behavior on color { ColorAnimation{ duration: 200 } }
                        Behavior on border.color { ColorAnimation{ duration: 200 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 20; spacing: 24
                            Rectangle {
                                width: 70; height: 70; radius: 35; color: "#1c1c24"
                                border.color: "#2a2a36"; border.width: 1
                                Text { text: "💡"; font.pixelSize: 28; anchors.centerIn: parent }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 6
                                RowLayout {
                                    Text { text: title; color: colorText; font.pixelSize: 18; font.weight: Font.Bold }
                                    Item { width: 10 }
                                    Rectangle { 
                                        width: tTag.width+16; height: 24; radius: 12; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15)
                                        Text { id: tTag; text: tag; color: Qt.lighter(colorAccent, 1.2); font.pixelSize: 11; font.weight: Font.DemiBold; anchors.centerIn: parent }
                                    }
                                }
                                Text { text: "Por: " + author; color: colorMuted; font.pixelSize: 13 }
                                Item { height: 4 }
                                Text { text: content; color: "#d0d0dc"; font.pixelSize: 14; Layout.fillWidth: true; wrapMode: Text.WordWrap; lineHeight: 1.5; font.weight: Font.Medium }
                            }
                        }
                        MouseArea { id: tipMa; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }

            // ═════════════════════════════════════════════════════════════════
            // TAB 3: MAESTROS
            // ═════════════════════════════════════════════════════════════════
            Item {
                ListView {
                    anchors.fill: parent
                    anchors.leftMargin: 40; anchors.rightMargin: 40
                    spacing: 24
                    clip: true
                    model: ListModel {
                        ListElement { master: "Leonardo da Vinci"; quote: "La pintura es poesía muda, la poesía pintura ciega."; year: "1452 - 1519"; icon: "🏰" }
                        ListElement { master: "Vincent van Gogh"; quote: "Si escuchas una voz dentro de ti decir 'no puedes pintar', entonces pinta, por todos los medios, and that voice will be silenced."; year: "1853 - 1890"; icon: "🌻" }
                        ListElement { master: "Pablo Picasso"; quote: "Aprende las reglas como un profesional, para que puedas romperlas como un artista."; year: "1881 - 1973"; icon: "🎨" }
                        ListElement { master: "Salvador Dalí"; quote: "No temas a la perfección, nunca la alcanzarás."; year: "1904 - 1989"; icon: "🕰" }
                        ListElement { master: "Frida Kahlo"; quote: "Pinto flores para que así no mueran."; year: "1907 - 1954"; icon: "🌺" }
                    }
                    delegate: Rectangle {
                        width: parent.width - 80; height: 160
                        radius: 20
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: mMa.containsMouse ? "#151520" : "#111118" }
                            GradientStop { position: 1.0; color: mMa.containsMouse ? "#1a1a28" : "#14141e" }
                        }
                        border.color: mMa.containsMouse ? "#3a3a44" : colorBorder
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 250 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 28; spacing: 30
                            Text { text: "❝"; font.pixelSize: 70; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15); Layout.alignment: Qt.AlignTop }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 12
                                Text { text: "\"" + quote + "\""; color: "#f0f0f8"; font.pixelSize: 22; font.italic: true; wrapMode: Text.WordWrap; Layout.fillWidth: true; font.weight: Font.Medium }
                                Item { Layout.fillHeight: true }
                                Text { text: icon + " — " + master + " (" + year + ")"; color: colorMuted; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 0.5; font.capitalization: Font.AllUppercase }
                            }
                        }
                        MouseArea { id: mMa; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }
    }
}
