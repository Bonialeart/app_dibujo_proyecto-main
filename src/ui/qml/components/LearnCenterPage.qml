import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: learnRoot
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    // ═══════════════════════════════════════════════════════
    // DESIGN TOKENS
    // ═══════════════════════════════════════════════════════
    readonly property color colorBg: "#060608"
    readonly property color colorSurface: "#0e0e14"
    readonly property color colorSurfaceHover: "#14141c"
    readonly property color colorCard: "#111118"
    readonly property color colorCardHover: "#16161f"
    readonly property color colorBorder: "#1a1a24"
    readonly property color colorBorderHover: "#2a2a3a"
    readonly property color colorAccent: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color colorAccentSoft: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.12)
    readonly property color colorAccentGlow: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.06)
    readonly property color colorText: "#f0f0f8"
    readonly property color colorTextSecondary: "#c8c8d8"
    readonly property color colorMuted: "#8888a0"
    readonly property color colorDimmed: "#55556a"
    readonly property real cardRadius: 18
    readonly property real animDuration: 280

    // Tab state
    property int currentIndex: 0
    // Entry animation trigger
    property bool _entered: false
    Component.onCompleted: _entryTimer.start()
    Timer { id: _entryTimer; interval: 80; onTriggered: _entered = true }

    // ═══════════════════════════════════════════════════════
    // BACKGROUND – COSMIC GRADIENT + GRAIN + ORBS
    // ═══════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#07070c" }
            GradientStop { position: 0.4; color: "#060609" }
            GradientStop { position: 1.0; color: "#0a0a12" }
        }
    }

    // Ambient orb top-right
    Rectangle {
        id: orb1
        width: 700; height: 700; radius: 350
        x: parent.width - 350; y: -280
        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.025)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
        // Slow breathing
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.7; duration: 4000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 4000; easing.type: Easing.InOutSine }
        }
    }

    // Ambient orb bottom-left
    Rectangle {
        width: 500; height: 500; radius: 250
        x: -180; y: parent.height - 220
        color: Qt.rgba(colorAccent.r * 0.8, colorAccent.g * 0.6, colorAccent.b, 0.02)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.6; duration: 5000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 5000; easing.type: Easing.InOutSine }
        }
    }

    // Subtle top-line accent
    Rectangle {
        width: parent.width; height: 1
        y: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15) }
            GradientStop { position: 0.7; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.15) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════════════════
        // HEADER — COMPACT PREMIUM
        // ═══════════════════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            opacity: _entered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            Row {
                anchors.left: parent.left; anchors.leftMargin: 40
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                Rectangle {
                    width: 40; height: 40; radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r,colorAccent.g,colorAccent.b,0.22) }
                        GradientStop { position: 1.0; color: Qt.rgba(colorAccent.r,colorAccent.g,colorAccent.b,0.08) }
                    }
                    border.color: Qt.rgba(colorAccent.r,colorAccent.g,colorAccent.b,0.30); border.width: 1
                    Text { text: "🎓"; font.pixelSize: 19; anchors.centerIn: parent }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.05; duration: 2200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 2200; easing.type: Easing.InOutSine }
                    }
                }
                Column {
                    spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Centro de Aprendizaje"; color: colorText; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: -0.6 }
                    Text { text: "Mejora tus habilidades con recursos profesionales"; color: colorMuted; font.pixelSize: 12 }
                }
            }

            // ═══════════════════════════════════════════════════════
            // PREMIUM TAB BAR — Floating pill moved to top-right
            // ═══════════════════════════════════════════════════════
            Rectangle {
                id: tabBarBg
                anchors.right: parent.right
                anchors.rightMargin: 48
                anchors.verticalCenter: parent.verticalCenter
                width: tabRow.width + 8
                height: 48
                radius: 24
                color: Qt.rgba(colorSurface.r, colorSurface.g, colorSurface.b, 0.7)
                border.color: colorBorder
                border.width: 1
                opacity: _entered ? 1.0 : 0.0
                transform: Translate { y: _entered ? 0 : 12 }
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

                // Animated selection pill
                Rectangle {
                    id: selectionPill
                    height: 38
                    y: 5
                    radius: 19
                    color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.14)
                    border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35)
                    border.width: 1
                    // Position/width set by Repeater
                    property real targetX: 4
                    property real targetW: 100
                    x: targetX
                    width: targetW
                    Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

                    // Inner glow
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.08) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                Row {
                    id: tabRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Video Tutoriales",    emoji: "🎬" },
                            { label: "Artista del Mes",     emoji: "🌟" },
                            { label: "Tips de Artistas",    emoji: "💡" },
                            { label: "Consejos de Maestros", emoji: "🏛" }
                        ]
                        delegate: Item {
                            id: tabDel
                            width: tabLabel.implicitWidth + 44
                            height: 38

                            Component.onCompleted: {
                                if (index === learnRoot.currentIndex) {
                                    selectionPill.targetX = tabDel.x + tabRow.anchors.leftMargin
                                    selectionPill.targetW = tabDel.width
                                }
                            }

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.emoji + "  " + modelData.label
                                color: learnRoot.currentIndex === index ? "#ffffff" : (tabHover.containsMouse ? colorTextSecondary : colorMuted)
                                font.pixelSize: 13
                                font.weight: learnRoot.currentIndex === index ? Font.Bold : Font.Medium
                                font.letterSpacing: 0.3
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: tabHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    learnRoot.currentIndex = index
                                    selectionPill.targetX = tabDel.x + tabRow.anchors.leftMargin
                                    selectionPill.targetW = tabDel.width
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 1; anchors.bottom: parent.bottom
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.15; color: colorBorder }
                    GradientStop { position: 0.85; color: colorBorder }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        // ═══════════════════════════════════════════════════════
        // CONTENT AREA
        // ═══════════════════════════════════════════════════════
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: learnRoot.currentIndex

            // ═══════════════════════════════════════════════════
            // TAB 1: VIDEO TUTORIALES
            // ═══════════════════════════════════════════════════
            Item {
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Flickable {
                        contentWidth: parent.width
                        contentHeight: videoCol.height + 60
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: videoCol
                            width: parent.width
                            spacing: 32

                            // Section header
                            Item { Layout.preferredHeight: 8 } // spacer

                            RowLayout {
                                Layout.leftMargin: 48; Layout.rightMargin: 48
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    width: 4; height: 22; radius: 2
                                    color: colorAccent
                                }
                                Text {
                                    text: "Tutoriales Seleccionados"
                                    color: colorText
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.5
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "6 videos disponibles"
                                    color: colorDimmed
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }

                            // Video grid (Flow/GridView)
                            GridView {
                                id: videoGrid
                                Layout.fillWidth: true
                                Layout.leftMargin: 48; Layout.rightMargin: 48
                                Layout.preferredHeight: Math.ceil(count / Math.max(1, Math.floor(width / 330))) * 300
                                cellWidth: 330; cellHeight: 300
                                clip: true
                                interactive: false
                                model: ListModel {
                                    ListElement { title: "Línea, Forma y Proporción"; channel: "Proko"; duration: "14:22"; videoId: "SU3_doNYOdk"; icon: "📐"; thumb: "https://img.youtube.com/vi/SU3_doNYOdk/mqdefault.jpg"; difficulty: "Intermedio"; color_tag: "#ff6b6b" }
                                    ListElement { title: "Luces y Sombras"; channel: "Ctrl+Paint"; duration: "11:45"; videoId: "YHjuiakQ-Kk"; icon: "🌗"; thumb: "https://img.youtube.com/vi/YHjuiakQ-Kk/mqdefault.jpg"; difficulty: "Básico"; color_tag: "#51cf66" }
                                    ListElement { title: "Teoría del Color"; channel: "Marco Bucci"; duration: "20:05"; videoId: "67LGQpr3Y6A"; icon: "🎨"; thumb: "https://img.youtube.com/vi/67LGQpr3Y6A/mqdefault.jpg"; difficulty: "Intermedio"; color_tag: "#ff6b6b" }
                                    ListElement { title: "Perspectiva de Puntos"; channel: "DrawABox"; duration: "18:30"; videoId: "Y5PTd3rVO78"; icon: "🏛"; thumb: "https://img.youtube.com/vi/Y5PTd3rVO78/mqdefault.jpg"; difficulty: "Avanzado"; color_tag: "#ffd43b" }
                                    ListElement { title: "Anatomía Básica"; channel: "Proko"; duration: "22:10"; videoId: "74HR59yFZ7Y"; icon: "🧍"; thumb: "https://img.youtube.com/vi/74HR59yFZ7Y/mqdefault.jpg"; difficulty: "Básico"; color_tag: "#51cf66" }
                                    ListElement { title: "Pintura de Fondos"; channel: "Ty Carter"; duration: "24:00"; videoId: "3aFxBWiLkiM"; icon: "🌄"; thumb: "https://img.youtube.com/vi/3aFxBWiLkiM/mqdefault.jpg"; difficulty: "Avanzado"; color_tag: "#ffd43b" }
                                }
                                delegate: Item {
                                    width: 330; height: 300
                                    // Staggered entry
                                    property bool _show: false
                                    Component.onCompleted: _showTimer.start()
                                    Timer { id: _showTimer; interval: 60 + index * 80; onTriggered: _show = true }

                                    Rectangle {
                                        id: vCard
                                        width: 310; height: 280
                                        anchors.centerIn: parent
                                        radius: cardRadius
                                        color: vcMa.containsMouse ? colorCardHover : colorCard
                                        border.color: vcMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.45) : colorBorder
                                        border.width: 1
                                        clip: true
                                        opacity: _show ? 1.0 : 0.0
                                        scale: vcMa.pressed ? 0.97 : (_show ? 1.0 : 0.92)
                                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: animDuration } }
                                        Behavior on border.color { ColorAnimation { duration: animDuration } }

                                        // Hover glow effect
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: parent.radius
                                            color: "transparent"
                                            border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, vcMa.containsMouse ? 0.08 : 0)
                                            border.width: 30
                                            opacity: vcMa.containsMouse ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: 300 } }
                                        }

                                        Column {
                                            anchors.fill: parent

                                            // Thumbnail
                                            Item {
                                                width: parent.width; height: 170
                                                clip: true

                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "#0a0a0f"
                                                    // Top rounded only
                                                    radius: cardRadius
                                                    Rectangle {
                                                        anchors.bottom: parent.bottom
                                                        width: parent.width; height: cardRadius
                                                        color: parent.color
                                                    }
                                                }

                                                Image {
                                                    anchors.fill: parent
                                                    source: thumb
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                                }

                                                // Hover overlay
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "#000000"
                                                    opacity: vcMa.containsMouse ? 0.15 : 0.40
                                                    Behavior on opacity { NumberAnimation { duration: 250 } }
                                                }

                                                // Gradient bottom fade
                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width; height: 60
                                                    gradient: Gradient {
                                                        GradientStop { position: 0.0; color: "transparent" }
                                                        GradientStop { position: 1.0; color: colorCard }
                                                    }
                                                }

                                                // Play button
                                                Rectangle {
                                                    id: playBtn
                                                    width: 52; height: 52; radius: 26
                                                    anchors.centerIn: parent
                                                    color: "#e60000"
                                                    border.color: Qt.rgba(1, 1, 1, 0.15)
                                                    border.width: 1
                                                    scale: vcMa.containsMouse ? 1.12 : 0.92
                                                    opacity: vcMa.containsMouse ? 1.0 : 0.8
                                                    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                                                    Behavior on opacity { NumberAnimation { duration: 250 } }

                                                    Text {
                                                        text: "▶"
                                                        color: "white"
                                                        anchors.centerIn: parent
                                                        anchors.horizontalCenterOffset: 2
                                                        font.pixelSize: 18
                                                    }

                                                    // Play button glow
                                                    Rectangle {
                                                        anchors.fill: parent; anchors.margins: -6
                                                        radius: 32; z: -1
                                                        color: "#e60000"
                                                        opacity: vcMa.containsMouse ? 0.3 : 0
                                                        Behavior on opacity { NumberAnimation { duration: 250 } }
                                                    }
                                                }

                                                // Duration badge
                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.right: parent.right
                                                    anchors.margins: 12
                                                    width: durT.width + 14; height: 24
                                                    radius: 8
                                                    color: "#cc000000"
                                                    border.color: Qt.rgba(1, 1, 1, 0.08)
                                                    border.width: 1
                                                    Text {
                                                        id: durT; text: duration; color: "#ffffff"
                                                        font.pixelSize: 11; font.weight: Font.Bold
                                                        font.letterSpacing: 0.5
                                                        anchors.centerIn: parent
                                                    }
                                                }

                                                // Difficulty badge
                                                Rectangle {
                                                    anchors.top: parent.top
                                                    anchors.left: parent.left
                                                    anchors.margins: 12
                                                    width: diffT.width + 16; height: 24
                                                    radius: 8
                                                    color: Qt.rgba(0, 0, 0, 0.65)
                                                    border.color: color_tag
                                                    border.width: 1
                                                    Row {
                                                        anchors.centerIn: parent
                                                        spacing: 4
                                                        Rectangle { width: 6; height: 6; radius: 3; color: color_tag; anchors.verticalCenter: parent.verticalCenter }
                                                        Text { id: diffT; text: difficulty; color: color_tag; font.pixelSize: 10; font.weight: Font.Bold; font.capitalization: Font.AllUppercase; font.letterSpacing: 0.8 }
                                                    }
                                                }
                                            }

                                            // Info area
                                            Item {
                                                width: parent.width; height: 110
                                                Column {
                                                    anchors.left: parent.left; anchors.right: parent.right
                                                    anchors.top: parent.top; anchors.topMargin: 12
                                                    anchors.leftMargin: 18; anchors.rightMargin: 18
                                                    spacing: 8

                                                    Text {
                                                        text: title
                                                        color: colorText
                                                        font.pixelSize: 15
                                                        font.weight: Font.Bold
                                                        font.letterSpacing: -0.3
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                        maximumLineCount: 2
                                                        wrapMode: Text.WordWrap
                                                    }

                                                    Row {
                                                        spacing: 8
                                                        // Channel avatar
                                                        Rectangle {
                                                            width: 22; height: 22; radius: 11
                                                            gradient: Gradient {
                                                                GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) }
                                                                GradientStop { position: 1.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.1) }
                                                            }
                                                            Text { text: icon; font.pixelSize: 12; anchors.centerIn: parent }
                                                        }
                                                        Text {
                                                            text: channel
                                                            color: colorMuted
                                                            font.pixelSize: 13
                                                            font.weight: Font.Medium
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: vcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: Qt.openUrlExternally("https://www.youtube.com/watch?v=" + videoId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════
            // TAB 2: ARTISTA DEL MES
            // ═══════════════════════════════════════════════════
            Item {
                id: artistOfMonthTab
                
                // Propiedades dinámicas en lugar de estáticas
                property bool isLoading: false
                property string artistName:    "Cargando..."
                property string artistWebsite: "..."
                property string artistBio:     "..."
                property string artistInfo:    "..."
                property string artistAvatar:  ""
                property var artworks: []
                
                // Modelo de datos para la galería a pantalla completa
                property ListModel galleryModel: ListModel {}

                // Función nativa para llamar al JSON hospedado (Firebase)
                function fetchArtistData() {
                    isLoading = true;
                    var xhr = new XMLHttpRequest();
                    // 👇 REEMPLAZA ESTA URL CON LA DE TU FIREBASE REALTIME DATABASE 👇
                    var url = "https://TU-PROYECTO.firebaseio.com/artistOfMonth.json";
                    
                    xhr.open("GET", url);
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            isLoading = false;
                            if (xhr.status === 200 && xhr.responseText !== "null") {
                                try {
                                    var data = JSON.parse(xhr.responseText);
                                    artistOfMonthTab.artistName = data.artistName || "Sin Nombre";
                                    artistOfMonthTab.artistWebsite = data.artistWebsite || "";
                                    artistOfMonthTab.artistBio = data.artistBio || "";
                                    artistOfMonthTab.artistInfo = data.artistInfo || "";
                                    artistOfMonthTab.artistAvatar = data.artistAvatar || "";
                                    
                                    var arts = data.artworks || [];
                                    var newArtworks = [];
                                    galleryModel.clear();
                                    for (var i = 0; i < arts.length; i++) {
                                        newArtworks.push(arts[i].src); // para la cascada pequeña
                                        galleryModel.append(arts[i]);  // para la galería grande
                                    }
                                    if(newArtworks.length > 0) {
                                        artistOfMonthTab.artworks = newArtworks;
                                    }
                                } catch(e) {
                                    console.error("Error parseando JSON de Firebase:", e);
                                    loadFallbackData();
                                }
                            } else {
                                console.warn("No se detectó servidor Firebase o no hay datos (usando datos locales fallback)");
                                loadFallbackData();
                            }
                        }
                    }
                    xhr.send();
                }

                function loadFallbackData() {
                    artistOfMonthTab.artistName = "Rossdraws (Ross Tran)";
                    artistOfMonthTab.artistWebsite = "www.rossdraws.com";
                    artistOfMonthTab.artistBio = "\"El arte no es lo que ves, sino lo que haces que otros vean. Cada trazo es una historia, cada color una emoción que conecta almas a través del lienzo digital.\"";
                    artistOfMonthTab.artistInfo = "Ross Tran, conocido como Rossdraws, es un ilustrador digital autodidacta de Los Ángeles. Reconocido por su estilo vibrante y expresivo, ha trabajado con Netflix, Disney y Sony. Su contenido educativo en YouTube ha inspirado a millones de artistas en todo el mundo a encontrar su propio estilo artístico.";
                    artistOfMonthTab.artistAvatar = ""; // Usa el perrito si está vacío
                    artistOfMonthTab.artworks = [
                        "https://img.youtube.com/vi/mKP9M0Fgrvk/maxresdefault.jpg",
                        "https://img.youtube.com/vi/YHjuiakQ-Kk/maxresdefault.jpg",
                        "https://img.youtube.com/vi/67LGQpr3Y6A/maxresdefault.jpg"
                    ]
                    galleryModel.clear();
                    galleryModel.append({ title: "Spiderverse", cat: "Animación", src: "https://img.youtube.com/vi/mKP9M0Fgrvk/maxresdefault.jpg", isVideo: false, bg: true });
                    galleryModel.append({ title: "Painter", cat: "Ilustración", src: "https://img.youtube.com/vi/YHjuiakQ-Kk/maxresdefault.jpg", isVideo: false, bg: false });
                    galleryModel.append({ title: "Hollow", cat: "Diseño", src: "https://img.youtube.com/vi/67LGQpr3Y6A/maxresdefault.jpg", isVideo: true, bg: false });
                    galleryModel.append({ title: "Depths", cat: "Ilustración", src: "https://img.youtube.com/vi/a_6HrdK4Ovs/maxresdefault.jpg", isVideo: false, bg: false });
                }

                Component.onCompleted: fetchArtistData()

                ScrollView {
                    id: amSV
                    anchors.fill: parent
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    // Plain Item child → ScrollView auto-wraps in Flickable.
                    // width explicitly bound to ScrollView id so binding resolves
                    // immediately. height is fixed → no circular dependency.
                    Item {
                        id: amRootContent
                        width: amSV.width
                        height: 720

                        property bool showGallery: false

                        Item {
                            id: dashboardCont
                            width: parent.width; height: parent.height
                            x: amRootContent.showGallery ? -width * 0.3 : 0
                            opacity: amRootContent.showGallery ? 0.0 : 1.0
                            visible: opacity > 0
                            Behavior on x { NumberAnimation { duration: 550; easing.type: Easing.OutQuint } }
                            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

                        // ── Section title row ──
                        Row {
                            id: amHdr; x: 40; y: 22; spacing: 12
                            Rectangle {
                                width: 4; height: 26; radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#ffd43b" }
                                    GradientStop { position: 1.0; color: "#f76707" }
                                }
                            }
                            Text {
                                text: "🌟  Artista del Mes"
                                color: colorText; font.pixelSize: 20; font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 40; y: 24
                            width: _mLbl.implicitWidth + 22; height: 28; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(1,0.83,0.24,0.18) }
                                GradientStop { position: 1.0; color: Qt.rgba(0.97,0.40,0.03,0.18) }
                            }
                            border.color: Qt.rgba(1,0.83,0.24,0.40); border.width: 1
                            Text { id: _mLbl; text: "Marzo 2026"; color: "#ffd43b"; font.pixelSize: 11; font.weight: Font.Bold; anchors.centerIn: parent }
                        }

                        // ── LEFT ARTIST CARD ──
                        // Sombra brutalista
                        Rectangle {
                            x: amLC.x + 12; y: amLC.y + 12; width: amLC.width; height: amLC.height
                            radius: 40; color: "#000000"
                        }
                        Rectangle {
                            id: amLC; x: 40; y: 70; width: 360; height: 600  // Mucho más ancho y alto
                            radius: 40; color: "#acb6e7"
                            border.color: "#000000"; border.width: 1

                            // Avatar + Name
                            Item {
                                id: amAv
                                anchors.top: parent.top; anchors.topMargin: 40
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width; height: 120

                                Row {
                                    anchors.centerIn: parent; spacing: 20
                                    Item {
                                        width: 100; height: 100
                                        Rectangle {
                                            width: 100; height: 100; radius: 50; color: "white"
                                            border.color: "#000000"; border.width: 1
                                            clip: true
                                            Image {
                                                anchors.fill: parent; source: artistOfMonthTab.artistAvatar
                                                fillMode: Image.PreserveAspectCrop; visible: artistOfMonthTab.artistAvatar !== ""
                                            }
                                            Text { 
                                                text: "🐶"; font.pixelSize: 50; anchors.centerIn: parent 
                                                visible: artistOfMonthTab.artistAvatar === ""
                                            } 
                                        }
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                        Text { text: artistOfMonthTab.artistName; color: "#111111"; font.pixelSize: 18; font.weight: Font.Black }
                                        Text { text: "Página web: " + artistOfMonthTab.artistWebsite; color: "#333333"; font.pixelSize: 10; font.weight: Font.Bold }
                                    }
                                }
                            }

                            // Bio
                            Text {
                                id: amBio
                                anchors.top: amAv.bottom; anchors.topMargin: 30
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 36; anchors.rightMargin: 36
                                text: artistOfMonthTab.artistBio
                                color: "#1a1a1a"; font.pixelSize: 17; lineHeight: 1.4
                                wrapMode: Text.WordWrap
                            }

                            // Socials
                            Text {
                                id: amSocLbl
                                anchors.bottom: amSocRow.top; anchors.bottomMargin: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Redes sociales"; color: "#111111"; font.pixelSize: 22; font.weight: Font.Black
                            }
                            Row {
                                id: amSocRow
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 40
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 18
                                Repeater {
                                    model: ["✕", "▶", "A"]
                                    delegate: Rectangle {
                                        width: 50; height: 50; radius: 25; color: "#000000"
                                        Text { text: modelData; color: "white"; font.pixelSize: 20; font.weight: Font.Bold; anchors.centerIn: parent }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }
                        }

                        // ── GALLERY – CASCADA FLOTANTE ──
                        Item {
                            id: amGC
                            x: amLC.x + amLC.width + 50; y: amLC.y  // Alineado exactamente en la parte superior ('y' al ras)
                            width: parent.width - x - 50; height: 320 // Más "aplastada" o landscape

                            // Tamaño de imagen responsiva para que solapen bien al centro
                            property real cardW: width * 0.48
                            property real spacingX: (width - cardW - 60) / 2

                            // Card 3 (fondo derecha)
                            Rectangle {
                                x: amGC.spacingX * 2; y: 20
                                width: amGC.cardW; height: amGC.height - 40
                                radius: 40; clip: true; color: "#1c1c38"
                                border.color: "#33000000"; border.width: 1
                                Image {
                                    anchors.fill: parent
                                    source: artistOfMonthTab.artworks.length > 2 ? artistOfMonthTab.artworks[2] : ""
                                    fillMode: Image.PreserveAspectCrop; asynchronous: true
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 500 } }
                                }
                            }

                            // Card 2 (medio)
                            Rectangle {
                                x: amGC.spacingX; y: 10
                                width: amGC.cardW; height: amGC.height - 20
                                radius: 40; clip: true; color: "#1e1e40"
                                border.color: "#33000000"; border.width: 1
                                Image {
                                    anchors.fill: parent
                                    source: artistOfMonthTab.artworks.length > 1 ? artistOfMonthTab.artworks[1] : ""
                                    fillMode: Image.PreserveAspectCrop; asynchronous: true
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 500 } }
                                }
                                Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.2) }
                            }

                            // Card 1 (frente izquierda)
                            Rectangle {
                                x: 0; y: 0
                                width: amGC.cardW; height: amGC.height
                                radius: 40; clip: true; color: "#22224a"
                                border.color: "#33ffffff"; border.width: 1
                                Image {
                                    anchors.fill: parent
                                    source: artistOfMonthTab.artworks.length > 0 ? artistOfMonthTab.artworks[0] : ""
                                    fillMode: Image.PreserveAspectCrop; asynchronous: true
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 500 } }
                                }
                            }

                            // Flecha lateral
                            Rectangle {
                                id: galleryArrow
                                width: 44; height: 44; radius: 22; color: "#ffffff"
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                border.color: "#000000"; border.width: 1
                                scale: gaMa.pressed ? 0.9 : (gaMa.containsMouse ? 1.1 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                Text { text: "→"; color: "#000000"; font.pixelSize: 20; font.weight: Font.Black; anchors.centerIn: parent }
                                MouseArea { id: gaMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: amRootContent.showGallery = true }
                            }
                        }

                        // ── INFO CARD ──
                        // Sombra bruta
                        Rectangle {
                            x: amInfo.x + 12; y: amInfo.y + 12; width: amInfo.width; height: amInfo.height
                            radius: 40; color: "#000000"
                        }
                        Rectangle {
                            id: amInfo
                            x: amGC.x; y: amLC.y + amLC.height - height // Alineado exactamente con la base de la tarjeta izquierda
                            width: amGC.width; height: 240 // Altura llenando el vacío, amGC=320, gap=40, amInfo=240 -> Total 600 (= amLC.height)
                            radius: 40; color: "#acb6e7"
                            border.color: "#000000"; border.width: 1

                            Text {
                                id: amInfoLbl
                                anchors.top: parent.top; anchors.topMargin: 36
                                anchors.left: parent.left; anchors.leftMargin: 36
                                text: "Información del Artista"
                                color: "#111111"; font.pixelSize: 24; font.weight: Font.Black
                            }

                            Text {
                                anchors.top: amInfoLbl.bottom; anchors.topMargin: 20
                                anchors.left: parent.left; anchors.leftMargin: 36
                                anchors.right: parent.right; anchors.rightMargin: 80
                                text: artistOfMonthTab.artistInfo
                                color: "#1a1a1a"; font.pixelSize: 18; lineHeight: 1.4; wrapMode: Text.WordWrap
                            }

                            // Flecha
                            Rectangle {
                                width: 44; height: 44; radius: 22; color: "#ffffff"
                                anchors.right: parent.right; anchors.rightMargin: -22
                                anchors.verticalCenter: parent.verticalCenter
                                border.color: "#000000"; border.width: 1
                                scale: iaMa.pressed ? 0.9 : (iaMa.containsMouse ? 1.1 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                Text { text: "→"; color: "#000000"; font.pixelSize: 20; font.weight: Font.Black; anchors.centerIn: parent }
                                MouseArea { id: iaMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: amRootContent.showGallery = true }
                            }
                        }
                        } // End dashboardCont

                        // ── FULL GALLERY VIEW ("Ultimas Obras") ──
                        Item {
                            id: fullGalleryView
                            width: parent.width; height: parent.height
                            x: amRootContent.showGallery ? 0 : width * 0.3
                            opacity: amRootContent.showGallery ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on x { NumberAnimation { duration: 550; easing.type: Easing.OutQuint } }
                            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

                            // ── Botón Atrás glassmorphic ──
                            Rectangle {
                                id: backBtn
                                width: 48; height: 48; radius: 24
                                color: Qt.rgba(1,1,1,0.08)
                                anchors.left: parent.left; anchors.leftMargin: 40
                                anchors.top: parent.top; anchors.topMargin: 24
                                border.color: Qt.rgba(1,1,1,0.15); border.width: 1
                                scale: backMa.pressed ? 0.9 : (backMa.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                Text { text: "←"; color: "#ffffff"; font.pixelSize: 24; font.weight: Font.Bold; anchors.centerIn: parent }
                                MouseArea {
                                    id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: amRootContent.showGallery = false
                                }
                            }

                            // ── Título "Últimas Obras" Premium ──
                            Column {
                                anchors.top: parent.top; anchors.topMargin: 18
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4

                                Text {
                                    id: uoTitle
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Últimas Obras"
                                    color: "#ffffff"; font.pixelSize: 42; font.weight: Font.Black
                                    font.letterSpacing: -1.5
                                }
                                // Línea decorativa degradada debajo del título
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: uoTitle.implicitWidth * 0.5; height: 3; radius: 2
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#ffd43b" }
                                        GradientStop { position: 1.0; color: "#f76707" }
                                    }
                                }
                            }

                            // ── Grid de obras – 4 columnas premium ──
                            Row {
                                anchors.top: parent.top; anchors.topMargin: 100
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 28

                                Repeater {
                                    model: artistOfMonthTab.galleryModel
                                    delegate: Item {
                                        id: artCard
                                        width: 220; height: 380

                                        property bool hovered: artMa.containsMouse

                                        // Sombra suave detrás
                                        Rectangle {
                                            x: 6; y: 8; width: parent.width; height: 320
                                            radius: 24; color: Qt.rgba(0,0,0,0.35)
                                            visible: artCard.hovered
                                        }

                                        // Tarjeta principal
                                        Rectangle {
                                            id: artImg
                                            width: parent.width; height: 320
                                            radius: 24; color: "#1a1a28"; clip: true
                                            border.color: artCard.hovered ? Qt.rgba(1,1,1,0.25) : Qt.rgba(1,1,1,0.06)
                                            border.width: 1
                                            scale: artMa.pressed ? 0.97 : (artCard.hovered ? 1.03 : 1.0)
                                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                            Behavior on border.color { ColorAnimation { duration: 200 } }

                                            Image {
                                                anchors.fill: parent; source: model.src
                                                fillMode: Image.PreserveAspectCrop; asynchronous: true
                                                opacity: status === Image.Ready ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 600 } }
                                            }

                                            // Gradient overlay abajo para legibilidad
                                            Rectangle {
                                                anchors.bottom: parent.bottom; width: parent.width; height: 100
                                                radius: 24
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: "transparent" }
                                                    GradientStop { position: 0.5; color: Qt.rgba(0,0,0,0.3) }
                                                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.75) }
                                                }
                                            }

                                            // Categoría pill interna
                                            Rectangle {
                                                anchors.top: parent.top; anchors.topMargin: 14
                                                anchors.left: parent.left; anchors.leftMargin: 14
                                                width: catLbl.implicitWidth + 18; height: 24; radius: 12
                                                color: Qt.rgba(0,0,0,0.55)
                                                border.color: Qt.rgba(1,1,1,0.12); border.width: 1
                                                Text {
                                                    id: catLbl; anchors.centerIn: parent
                                                    text: model.cat; color: "#d0d0e0"; font.pixelSize: 10; font.weight: Font.Medium
                                                }
                                            }

                                            // Icono de video
                                            Rectangle {
                                                visible: model.isVideo === true
                                                anchors.top: parent.top; anchors.topMargin: 14
                                                anchors.right: parent.right; anchors.rightMargin: 14
                                                width: 32; height: 32; radius: 16
                                                color: Qt.rgba(0,0,0,0.6)
                                                border.color: Qt.rgba(1,1,1,0.2); border.width: 1
                                                Text { text: "▶"; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                                            }
                                        }

                                        // Nombre de la obra
                                        Text {
                                            anchors.top: artImg.bottom; anchors.topMargin: 14
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: model.title; color: "#ffffff"
                                            font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 0.3
                                        }
                                        // Categoría subtexto
                                        Text {
                                            anchors.top: artImg.bottom; anchors.topMargin: 36
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: model.cat; color: colorMuted
                                            font.pixelSize: 11; font.weight: Font.Medium
                                        }

                                        MouseArea {
                                            id: artMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        }
                                    }
                                }
                            }

                            // ── Pie de galería ──
                            Text {
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Mostrando 4 de 12 obras  ·  Desliza para ver más →"
                                color: colorDimmed; font.pixelSize: 12; font.weight: Font.Medium
                            }
                        }
                    } // end of amRootContent
                }
            }

            // ═══════════════════════════════════════════════════
            // TAB 3: TIPS DE ARTISTAS

            // ═══════════════════════════════════════════════════
            Item {
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Flickable {
                        contentWidth: parent.width
                        contentHeight: tipsCol.height + 60
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: tipsCol
                            width: parent.width
                            spacing: 20

                            Item { Layout.preferredHeight: 8 }

                            // Section header
                            RowLayout {
                                Layout.leftMargin: 48; Layout.rightMargin: 48
                                Layout.fillWidth: true
                                spacing: 12
                                Rectangle { width: 4; height: 22; radius: 2; color: colorAccent }
                                Text {
                                    text: "Tips de Artistas Profesionales"
                                    color: colorText; font.pixelSize: 20; font.weight: Font.Bold; font.letterSpacing: -0.5
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: hintLabel.width + 20; height: 28; radius: 14
                                    color: colorAccentSoft
                                    border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.2); border.width: 1
                                    Text { id: hintLabel; text: "✨ Curado por expertos"; color: Qt.lighter(colorAccent, 1.3); font.pixelSize: 11; font.weight: Font.DemiBold; anchors.centerIn: parent }
                                }
                            }

                            Repeater {
                                model: ListModel {
                                    ListElement { author: "Loish"; title: "Uso del color dinámico"; content: "No te limites a sombrear con negro o aclarar con blanco. Usa variaciones de temperatura térmica: sombras frías e iluminaciones cálidas (o viceversa). Esto dará vida y riqueza a la paleta."; tag: "🎨 Color"; tagColor: "#ff6b6b"; idx: 0 }
                                    ListElement { author: "Ross Tran"; title: "Dinámica y flujo"; content: "Busca siempre una 'línea de acción' clara antes de meter detalles. Si el gesto general es tieso o aburrido, ningún nivel de detalle lo arreglará. Exagera las curvas al inicio."; tag: "✍️ Gestual"; tagColor: "#ffd43b"; idx: 1 }
                                    ListElement { author: "WLOP"; title: "Subsurface Scattering"; content: "La piel humana no es plástico. Observa la dispersión subsuperficial en las sombras proyectadas sobre la piel para darle un toque realista, suave y natural a tus personajes."; tag: "💡 Iluminación"; tagColor: "#4dabf7"; idx: 2 }
                                    ListElement { author: "Sinix"; title: "Anatomía como bloques primitivos"; content: "No pienses en músculos primero, piensa en formas 3D primitivas. Cajas para el torso, cilindros para extremidades. Asegúrate de que esas formas funcionen en el espacio."; tag: "🧍 Anatomía"; tagColor: "#51cf66"; idx: 3 }
                                    ListElement { author: "Marco Bucci"; title: "Economía del trazo"; content: "No necesitas renderizar cada hoja del árbol. El cerebro humano rellena los espacios vacíos. Céntrate en sugerir texturas donde incide la luz y deja en silencio las sombras."; tag: "🖌 Pinceladas"; tagColor: "#cc5de8"; idx: 4 }
                                }
                                delegate: Item {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 48; Layout.rightMargin: 48
                                    Layout.preferredHeight: tipCard.height

                                    property bool _tipShow: false
                                    Component.onCompleted: _tipShowTimer.start()
                                    Timer { id: _tipShowTimer; interval: 60 + idx * 100; onTriggered: _tipShow = true }

                                    Rectangle {
                                        id: tipCard
                                        width: parent.width
                                        height: Math.max(140, tipContentCol.height + 48)
                                        radius: cardRadius
                                        color: tipMa.containsMouse ? colorCardHover : colorCard
                                        border.color: tipMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35) : colorBorder
                                        border.width: 1
                                        opacity: _tipShow ? 1.0 : 0.0
                                        scale: _tipShow ? 1.0 : 0.96
                                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: animDuration } }
                                        Behavior on border.color { ColorAnimation { duration: animDuration } }

                                        // Left accent bar
                                        Rectangle {
                                            width: 3; height: parent.height - 32
                                            anchors.left: parent.left; anchors.leftMargin: 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 2
                                            color: tagColor
                                            opacity: tipMa.containsMouse ? 1.0 : 0.4
                                            Behavior on opacity { NumberAnimation { duration: 250 } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 24; anchors.leftMargin: 20; spacing: 22

                                            // Avatar
                                            Rectangle {
                                                width: 56; height: 56; radius: 16
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Qt.rgba(tagColor.r || 0.4, tagColor.g || 0.4, tagColor.b || 0.9, 0.18) }
                                                    GradientStop { position: 1.0; color: Qt.rgba(tagColor.r || 0.4, tagColor.g || 0.4, tagColor.b || 0.9, 0.06) }
                                                }
                                                border.color: Qt.rgba(tagColor.r || 0.4, tagColor.g || 0.4, tagColor.b || 0.9, 0.25)
                                                border.width: 1
                                                Text {
                                                    text: author.charAt(0)
                                                    font.pixelSize: 22; font.weight: Font.Bold
                                                    color: tagColor
                                                    anchors.centerIn: parent
                                                }

                                                // Hover ring
                                                scale: tipMa.containsMouse ? 1.08 : 1.0
                                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                            }

                                            ColumnLayout {
                                                id: tipContentCol
                                                Layout.fillWidth: true; spacing: 8

                                                // Title row
                                                RowLayout {
                                                    spacing: 12
                                                    Text {
                                                        text: title
                                                        color: colorText
                                                        font.pixelSize: 17
                                                        font.weight: Font.Bold
                                                        font.letterSpacing: -0.3
                                                    }
                                                    Rectangle {
                                                        width: tagT.width + 16; height: 24; radius: 12
                                                        color: Qt.rgba(tagColor.r || 0.4, tagColor.g || 0.4, tagColor.b || 0.9, 0.12)
                                                        border.color: Qt.rgba(tagColor.r || 0.4, tagColor.g || 0.4, tagColor.b || 0.9, 0.25)
                                                        border.width: 1
                                                        Text { id: tagT; text: tag; color: tagColor; font.pixelSize: 11; font.weight: Font.Bold; anchors.centerIn: parent }
                                                    }
                                                }

                                                // Author
                                                Row {
                                                    spacing: 6
                                                    Text { text: "Por"; color: colorDimmed; font.pixelSize: 12 }
                                                    Text { text: author; color: colorMuted; font.pixelSize: 12; font.weight: Font.Bold }
                                                }

                                                // Content
                                                Text {
                                                    text: content
                                                    color: colorTextSecondary
                                                    font.pixelSize: 14
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WordWrap
                                                    lineHeight: 1.55
                                                    font.weight: Font.Medium
                                                }
                                            }
                                        }

                                        MouseArea { id: tipMa; anchors.fill: parent; hoverEnabled: true }
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 20 }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════
            // TAB 3: CONSEJOS DE MAESTROS
            // ═══════════════════════════════════════════════════
            Item {
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Flickable {
                        contentWidth: parent.width
                        contentHeight: mastersCol.height + 60
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: mastersCol
                            width: parent.width
                            spacing: 24

                            Item { Layout.preferredHeight: 8 }

                            // Section header
                            RowLayout {
                                Layout.leftMargin: 48; Layout.rightMargin: 48
                                Layout.fillWidth: true
                                spacing: 12
                                Rectangle { width: 4; height: 22; radius: 2; color: colorAccent }
                                Text {
                                    text: "Sabiduría de los Grandes Maestros"
                                    color: colorText; font.pixelSize: 20; font.weight: Font.Bold; font.letterSpacing: -0.5
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "Citas que inspiran"
                                    color: colorDimmed; font.pixelSize: 12; font.weight: Font.Medium; font.italic: true
                                }
                            }

                            Repeater {
                                model: ListModel {
                                    ListElement { master: "Leonardo da Vinci"; quote: "La pintura es poesía muda, la poesía pintura ciega."; year: "1452 – 1519"; icon: "🏰"; accentHue: 0.7; idx: 0 }
                                    ListElement { master: "Vincent van Gogh"; quote: "Si escuchas una voz dentro de ti decir 'no puedes pintar', entonces pinta, por todos los medios, y esa voz será silenciada."; year: "1853 – 1890"; icon: "🌻"; accentHue: 0.15; idx: 1 }
                                    ListElement { master: "Pablo Picasso"; quote: "Aprende las reglas como un profesional, para que puedas romperlas como un artista."; year: "1881 – 1973"; icon: "🎨"; accentHue: 0.0; idx: 2 }
                                    ListElement { master: "Salvador Dalí"; quote: "No temas a la perfección, nunca la alcanzarás."; year: "1904 – 1989"; icon: "🕰"; accentHue: 0.55; idx: 3 }
                                    ListElement { master: "Frida Kahlo"; quote: "Pinto flores para que así no mueran."; year: "1907 – 1954"; icon: "🌺"; accentHue: 0.95; idx: 4 }
                                }
                                delegate: Item {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 48; Layout.rightMargin: 48
                                    Layout.preferredHeight: masterCard.height

                                    property bool _mShow: false
                                    Component.onCompleted: _mShowTimer.start()
                                    Timer { id: _mShowTimer; interval: 80 + idx * 120; onTriggered: _mShow = true }

                                    property color masterAccent: Qt.hsla(accentHue, 0.55, 0.55, 1.0)

                                    Rectangle {
                                        id: masterCard
                                        width: parent.width
                                        height: Math.max(180, masterContentCol.height + 64)
                                        radius: 22

                                        // Glass-like gradient background
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: mMa.containsMouse ? Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.06) : "#0f0f16" }
                                            GradientStop { position: 0.5; color: mMa.containsMouse ? "#151520" : "#111118" }
                                            GradientStop { position: 1.0; color: mMa.containsMouse ? "#18182a" : "#131320" }
                                        }
                                        border.color: mMa.containsMouse ? Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.35) : colorBorder
                                        border.width: 1
                                        opacity: _mShow ? 1.0 : 0.0
                                        scale: _mShow ? 1.0 : 0.96
                                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 300 } }

                                        // Corner decoration
                                        Rectangle {
                                            width: 200; height: 200; radius: 100
                                            anchors.right: parent.right; anchors.rightMargin: -80
                                            anchors.top: parent.top; anchors.topMargin: -80
                                            color: Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.03)
                                            opacity: mMa.containsMouse ? 1.0 : 0.3
                                            Behavior on opacity { NumberAnimation { duration: 400 } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 32; spacing: 28

                                            // Quote mark
                                            Column {
                                                Layout.alignment: Qt.AlignTop
                                                spacing: 8

                                                Text {
                                                    text: "❝"
                                                    font.pixelSize: 64
                                                    color: Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, mMa.containsMouse ? 0.25 : 0.12)
                                                    Behavior on color { ColorAnimation { duration: 300 } }
                                                }

                                                // Icon pill
                                                Rectangle {
                                                    width: 44; height: 44; radius: 14
                                                    color: Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.10)
                                                    border.color: Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.2)
                                                    border.width: 1
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    Text { text: icon; font.pixelSize: 20; anchors.centerIn: parent }
                                                }
                                            }

                                            ColumnLayout {
                                                id: masterContentCol
                                                Layout.fillWidth: true; spacing: 16

                                                // Quote text
                                                Text {
                                                    text: "\"" + quote + "\""
                                                    color: "#eeeef4"
                                                    font.pixelSize: 20
                                                    font.italic: true
                                                    font.weight: Font.Medium
                                                    font.letterSpacing: -0.3
                                                    wrapMode: Text.WordWrap
                                                    Layout.fillWidth: true
                                                    lineHeight: 1.5
                                                }

                                                // Separator line
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 1
                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal
                                                        GradientStop { position: 0.0; color: Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.3) }
                                                        GradientStop { position: 1.0; color: "transparent" }
                                                    }
                                                }

                                                // Attribution
                                                RowLayout {
                                                    spacing: 12
                                                    Text {
                                                        text: "— " + master
                                                        color: masterAccent
                                                        font.pixelSize: 15
                                                        font.weight: Font.Bold
                                                        font.letterSpacing: 0.3
                                                    }
                                                    Rectangle {
                                                        width: yearT.width + 16; height: 24; radius: 12
                                                        color: Qt.rgba(masterAccent.r, masterAccent.g, masterAccent.b, 0.10)
                                                        Text {
                                                            id: yearT; text: year; color: colorMuted
                                                            font.pixelSize: 11; font.weight: Font.DemiBold
                                                            anchors.centerIn: parent
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea { id: mMa; anchors.fill: parent; hoverEnabled: true }
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 20 }
                        }
                    }
                }
            }
        }
    }
}
