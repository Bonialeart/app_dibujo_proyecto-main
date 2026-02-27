import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════════
//  LEARN CENTER PAGE — Centro de aprendizaje con video embebido
//  Usa QtWebEngine para reproducir YouTube directamente en la app
// ═══════════════════════════════════════════════════════════════════
Item {
    id: learnRoot
    // CRITICAL: explicit size binding for StackLayout
    width:  parent ? parent.width  : 800
    height: parent ? parent.height : 600

    // ─── Design tokens ───
    readonly property color colorBg:      "#060608"
    readonly property color colorSurface: "#0e0e12"
    readonly property color colorCard:    "#111116"
    readonly property color colorBorder:  "#1c1c22"
    readonly property color colorAccent:  (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color colorText:    "#f4f4f8"
    readonly property color colorMuted:   "#6e6e7a"
    readonly property color colorDim:     "#3a3a44"

    // ─── State ───
    property string activeCategory: "all"
    property string searchQuery: ""
    property var currentVideo: null
    property var watchedVideos: []

    function markWatched(videoId) {
        if (watchedVideos.indexOf(videoId) === -1) {
            var arr = watchedVideos.slice()
            arr.push(videoId)
            watchedVideos = arr
        }
    }
    function isWatched(videoId) { return watchedVideos.indexOf(videoId) !== -1 }

    // ─── Video catalog ───────────────────────────────────────────
    property var catalog: [
        // ── FUNDAMENTOS ──────────────────────────────────────────
        {
            id: "fund_linea", category: "fundamentals", playlist: "Fundamentos del Dibujo",
            title: "Línea, Forma y Proporción",
            channel: "Proko", duration: "14:22",
            videoId: "SU3_doNYOdk",
            accentColor: "#6366f1",
            icon: "📐",
            description: "Aprende los principios básicos de la línea confiada, formas geométricas fundamentales y cómo mantener proporciones correctas desde el inicio."
        },
        {
            id: "fund_sombra", category: "fundamentals", playlist: "Fundamentos del Dibujo",
            title: "Luces y Sombras para Principiantes",
            channel: "Ctrl+Paint", duration: "11:45",
            videoId: "YHjuiakQ-Kk",
            accentColor: "#6366f1",
            icon: "🌗",
            description: "Comprende cómo funciona la luz y la sombra: forma de luz, sombra propia, sombra proyectada, medios tonos y brillos especulares."
        },
        {
            id: "fund_perspectiva", category: "fundamentals", playlist: "Fundamentos del Dibujo",
            title: "Perspectiva de 1, 2 y 3 Puntos",
            channel: "DrawABox", duration: "18:30",
            videoId: "Y5PTd3rVO78",
            accentColor: "#6366f1",
            icon: "🏛",
            description: "Tutorial completo de perspectiva lineal desde cero. Con ejercicios prácticos y errores comunes a evitar."
        },
        {
            id: "fund_composicion", category: "fundamentals", playlist: "Fundamentos del Dibujo",
            title: "Composición y Regla de Tercios",
            channel: "Marco Bucci", duration: "09:15",
            videoId: "O8i7OKbWmRM",
            accentColor: "#6366f1",
            icon: "🖼",
            description: "Cómo disponer los elementos en tu lienzo para crear imágenes visualmente atractivas y con mayor impacto narrativo."
        },
        // ── PERSONAJES ──────────────────────────────────────────
        {
            id: "char_anatomia", category: "characters", playlist: "Diseño de Personajes",
            title: "Anatomía Básica del Cuerpo Humano",
            channel: "Proko", duration: "22:10",
            videoId: "74HR59yFZ7Y",
            accentColor: "#ec4899",
            icon: "🧍",
            description: "Cuerpo humano desde las proporciones de cabeza. Aprende el mannequin, la caja del cuerpo y ubicación de articulaciones."
        },
        {
            id: "char_rostro", category: "characters", playlist: "Diseño de Personajes",
            title: "Cómo Dibujar Rostros Realistas",
            channel: "Aaron Rutten", duration: "19:55",
            videoId: "J9s5SqtK7WI",
            accentColor: "#ec4899",
            icon: "😊",
            description: "Proporciones del rostro, ubicación de ojos, nariz y boca. Estructuras de cráneo para diferentes ángulos."
        },
        {
            id: "char_expresiones", category: "characters", playlist: "Diseño de Personajes",
            title: "Expresiones Faciales Dinámicas",
            channel: "Olga Andriyenko", duration: "13:20",
            videoId: "Yvb3bczPnvU",
            accentColor: "#ec4899",
            icon: "😄",
            description: "7 expresiones básicas y cómo variarlas. Músculos faciales y cómo exagerarlos para personajes de animación."
        },
        {
            id: "char_poses", category: "characters", playlist: "Diseño de Personajes",
            title: "Poses Dinámicas con Línea de Acción",
            channel: "Sinix Design", duration: "16:40",
            videoId: "6kLN1r4ymhk",
            accentColor: "#ec4899",
            icon: "🏃",
            description: "La línea de acción, gestos y cómo dar energía a tus poses. De figuras estáticas a poses llenas de movimiento."
        },
        // ── PAISAJES ────────────────────────────────────────────
        {
            id: "land_fondos", category: "landscapes", playlist: "Fondos y Paisajes",
            title: "Pintura de Fondos desde Cero",
            channel: "Ty Carter", duration: "24:00",
            videoId: "3aFxBWiLkiM",
            accentColor: "#10b981",
            icon: "🌄",
            description: "Step-by-step: cielo, terreno, árboles, atmósfera. Cómo crear fondos creíbles para ilustración y concept art."
        },
        {
            id: "land_niebla", category: "landscapes", playlist: "Fondos y Paisajes",
            title: "Niebla, Nubes y Atmósfera",
            channel: "Ross Draws", duration: "15:30",
            videoId: "JTBNPXfN6YA",
            accentColor: "#10b981",
            icon: "🌫",
            description: "Cómo pintar nubes volumétricas, neblina y perspectiva atmosférica para profundidad y misterio."
        },
        {
            id: "land_ciudad", category: "landscapes", playlist: "Fondos y Paisajes",
            title: "Concept Art Urbano",
            channel: "CGMA", duration: "28:15",
            videoId: "NJgYK7orvoc",
            accentColor: "#10b981",
            icon: "🏙",
            description: "Diseño de entornos urbanos futuristas y fantásticos. Desde thumbnails hasta la imagen final de concept art."
        },
        // ── PINTURA DIGITAL ──────────────────────────────────────
        {
            id: "digit_color", category: "digital_painting", playlist: "Pintura Digital",
            title: "Teoría del Color para Artistas Digitales",
            channel: "Marco Bucci", duration: "20:05",
            videoId: "67LGQpr3Y6A",
            accentColor: "#f59e0b",
            icon: "🎨",
            description: "Rueda de colores, armonías, temperatura, saturación y cómo aplicar la teoría del color en tus obras."
        },
        {
            id: "digit_pinceladas", category: "digital_painting", playlist: "Pintura Digital",
            title: "Técnica de Pinceladas Eficientes",
            channel: "Sinix Design", duration: "12:20",
            videoId: "lMU_LA4TQe4",
            accentColor: "#f59e0b",
            icon: "🖌",
            description: "Cómo usar menos trazos para más impacto. Economía de pinceladas, variación de pinceles y confianza en el trazo."
        },
        {
            id: "digit_piel", category: "digital_painting", playlist: "Pintura Digital",
            title: "Pintar Piel Realista Paso a Paso",
            channel: "WLOP", duration: "31:00",
            videoId: "5Tms8RP5-qE",
            accentColor: "#f59e0b",
            icon: "✋",
            description: "Técnica completa para pintar piel: subsurface scattering, brillos, poros, variación tonal y saturación."
        },
        // ── ANIMACIÓN ───────────────────────────────────────────
        {
            id: "anim_principios", category: "animation", playlist: "Animación 2D",
            title: "12 Principios de la Animación",
            channel: "Alan Becker", duration: "17:50",
            videoId: "uDqjIdI4bF4",
            accentColor: "#8b5cf6",
            icon: "🎬",
            description: "Los 12 principios de Disney: Squash & Stretch, Anticipación, Staging, Follow Through y más, explicados con ejemplos."
        },
        {
            id: "anim_walk", category: "animation", playlist: "Animación 2D",
            title: "Ciclo de Caminata Completo",
            channel: "Toniko Pantoja", duration: "25:15",
            videoId: "AZJ91o5v95E",
            accentColor: "#8b5cf6",
            icon: "🚶",
            description: "Anima un ciclo de caminata convincente frame a frame. Contacto, bajada, pasada y pose de arriba."
        },
        {
            id: "anim_smear", category: "animation", playlist: "Animación 2D",
            title: "Animación Dinámica: Smear Frames",
            channel: "Maaz Hayat", duration: "10:30",
            videoId: "eDtMmMqM0MA",
            accentColor: "#8b5cf6",
            icon: "💨",
            description: "Cómo usar smear frames, motion blur y exageración para dar vida y dinamismo a tus animaciones."
        }
    ]

    readonly property var categories: [
        { id: "all",              label: "Todos",            icon: "🌟" },
        { id: "fundamentals",    label: "Fundamentos",      icon: "📐" },
        { id: "characters",     label: "Personajes",       icon: "🧍" },
        { id: "landscapes",     label: "Paisajes",          icon: "🌄" },
        { id: "digital_painting", label: "Pintura Digital", icon: "🎨" },
        { id: "animation",      label: "Animación",        icon: "🎬" }
    ]

    property var filteredCatalog: {
        var result = catalog
        if (activeCategory !== "all")
            result = result.filter(function(v) { return v.category === activeCategory })
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase()
            result = result.filter(function(v) {
                return v.title.toLowerCase().includes(q) ||
                       v.channel.toLowerCase().includes(q) ||
                       v.description.toLowerCase().includes(q)
            })
        }
        return result
    }

    // YouTube embed URL
    function youtubeEmbedUrl(videoId) {
        return "https://www.youtube.com/embed/" + videoId + "?autoplay=1&rel=0&modestbranding=1&color=white"
    }

    // Background — Premium deep gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08080c" }
            GradientStop { position: 0.4; color: "#060609" }
            GradientStop { position: 1.0; color: "#0a0a10" }
        }
    }

    // Ambient glow orb
    Rectangle {
        width: 400; height: 400; radius: 200
        x: parent.width - 250; y: -100
        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.025)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
    }


    // ─── MAIN LAYOUT: left panel + right video player ────────────
    RowLayout {
        anchors.fill: parent
        spacing: 0
        z: 1

        // ══════════════════════════════════════════════════════════
        //  LEFT: Browse panel 
        // ══════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: !currentVideo
            Layout.preferredWidth: currentVideo ? 420 : -1
            Layout.minimumWidth: currentVideo ? 420 : 200
            Layout.fillHeight: true
            color: "transparent"
            clip: true

            Behavior on Layout.preferredWidth { NumberAnimation { duration: 350; easing.type: Easing.InOutCubic } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header — Glass Surface
                Rectangle {
                    Layout.fillWidth: true; height: 84
                    color: "#0c0c10"

                    // Subtle glass gradient
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.04) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.4) }
                            GradientStop { position: 0.5; color: colorBorder }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: currentVideo ? 18 : 36
                        anchors.rightMargin: currentVideo ? 18 : 36
                        spacing: 16

                        Column {
                            spacing: 3
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                text: "🎬  Centro de Aprendizaje"
                                color: colorText
                                font.pixelSize: currentVideo ? 18 : 24
                                font.weight: Font.Bold
                                font.letterSpacing: -0.5
                            }
                            Text {
                                text: learnRoot.filteredCatalog.length + " tutoriales · " +
                                      learnRoot.watchedVideos.length + " completados"
                                color: colorMuted
                                font.pixelSize: 12
                                visible: !currentVideo
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Search bar (compact when playerOpen)
                        Rectangle {
                            width: currentVideo ? 140 : 260; height: 38; radius: 19
                            color: colorSurface
                            border.color: sField.activeFocus
                                ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5)
                                : colorBorder
                            border.width: 1
                            Behavior on width { NumberAnimation { duration: 300 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 6
                                Text { text: "🔍"; font.pixelSize: 13 }
                                TextField {
                                    id: sField
                                    Layout.fillWidth: true
                                    placeholderText: currentVideo ? "Buscar..." : "Buscar tutoriales..."
                                    color: colorText; font.pixelSize: 12
                                    placeholderTextColor: colorDim
                                    background: Item {}
                                    onTextChanged: learnRoot.searchQuery = text
                                }
                            }
                        }
                    }
                }

                // Category filter pills
                Rectangle {
                    Layout.fillWidth: true; height: 58
                    color: colorSurface

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        color: colorBorder
                    }

                    ListView {
                        anchors.fill: parent
                        anchors.leftMargin: currentVideo ? 12 : 28
                        anchors.rightMargin: currentVideo ? 12 : 28
                        anchors.topMargin: 11; anchors.bottomMargin: 11
                        orientation: ListView.Horizontal
                        spacing: 8; clip: true
                        model: learnRoot.categories
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                        delegate: Rectangle {
                            property bool isActive: learnRoot.activeCategory === modelData.id
                            height: 36; radius: 18
                            color: isActive
                                ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.18)
                                : (cMa.containsMouse ? "#14ffffff" : "#0affffff")
                            border.color: isActive
                                ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5)
                                : colorBorder
                            border.width: 1
                            implicitWidth: cTxt.width + 32
                            Behavior on color { ColorAnimation { duration: 160 } }

                            Row { anchors.centerIn: parent; spacing: 5
                                Text { text: modelData.icon; font.pixelSize: 13 }
                                Text {
                                    id: cTxt
                                    text: modelData.label
                                    color: isActive ? Qt.lighter(colorAccent, 1.6) : colorMuted
                                    font.pixelSize: 12; font.weight: isActive ? Font.DemiBold : Font.Normal
                                }
                            }
                            MouseArea {
                                id: cMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: learnRoot.activeCategory = modelData.id
                            }
                            scale: cMa.pressed ? 0.93 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                        }
                    }
                }

                // Progress bar
                Rectangle {
                    Layout.fillWidth: true; height: 36
                    color: "#08ffffff"
                    visible: learnRoot.watchedVideos.length > 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: currentVideo ? 14 : 28
                        anchors.rightMargin: currentVideo ? 14 : 28
                        spacing: 12

                        Text {
                            text: "Progreso:"
                            color: colorMuted; font.pixelSize: 11
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 4; radius: 2
                            color: colorBorder
                            Rectangle {
                                height: parent.height; radius: 2
                                width: parent.width * (learnRoot.watchedVideos.length / learnRoot.catalog.length)
                                color: "#22c55e"
                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            text: learnRoot.watchedVideos.length + "/" + learnRoot.catalog.length
                            color: "#86efac"; font.pixelSize: 11; font.weight: Font.DemiBold
                        }
                    }
                }

                // Video list
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: videoCol.height + 40
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        contentItem: Rectangle { radius: 2; color: "#2a2a30" }
                    }

                    // Empty state
                    Column {
                        anchors.centerIn: parent; spacing: 14
                        visible: learnRoot.filteredCatalog.length === 0
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🎬"; font.pixelSize: 40; opacity: 0.3 }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No se encontraron tutoriales"
                            color: colorMuted; font.pixelSize: 15
                        }
                    }

                    Column {
                        id: videoCol
                        anchors.left: parent.left; anchors.right: parent.right
                        topPadding: 16; bottomPadding: 16; spacing: 0

                        // Group by playlist
                        Repeater {
                            model: learnRoot.categories

                            delegate: Column {
                                width: parent.width
                                spacing: 0

                                property string catId: modelData.id
                                property var catVideos: learnRoot.filteredCatalog.filter(function(v) {
                                    return catId === "all" ? false : v.category === catId
                                })

                                visible: catId !== "all" && catVideos.length > 0 &&
                                         (learnRoot.activeCategory === "all" || learnRoot.activeCategory === catId)

                                // Playlist header
                                Rectangle {
                                    width: parent.width; height: 38
                                    color: "transparent"
                                    visible: parent.visible

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: currentVideo ? 14 : 28
                                        anchors.rightMargin: 14
                                        spacing: 10

                                        Text { text: modelData.icon; font.pixelSize: 14 }
                                        Text {
                                            text: modelData.label
                                            color: colorDim; font.pixelSize: 11
                                            font.weight: Font.Bold; font.letterSpacing: 1.2
                                            font.capitalization: Font.AllUppercase
                                        }
                                        // Count badge
                                        Rectangle {
                                            width: cntTxt.width + 12; height: 18; radius: 9
                                            color: "#12ffffff"
                                            Text {
                                                id: cntTxt
                                                anchors.centerIn: parent
                                                text: parent.parent.catVideos.length
                                                color: colorDim; font.pixelSize: 10
                                            }
                                        }
                                        Item { Layout.fillWidth: true }
                                    }
                                }

                                // Videos in this playlist
                                Repeater {
                                    model: parent.catVideos

                                    delegate: VideoListItem {
                                        width: parent.width
                                        videoData: modelData
                                        isActive: learnRoot.currentVideo && learnRoot.currentVideo.id === modelData.id
                                        watched: learnRoot.isWatched(modelData.id)
                                        compact: learnRoot.currentVideo !== null
                                        onPlayRequested: {
                                            learnRoot.currentVideo = videoData
                                            learnRoot.markWatched(videoData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right separator
        Rectangle {
            width: 1
            Layout.fillHeight: true
            color: colorBorder
            visible: learnRoot.currentVideo !== null
        }

        // ══════════════════════════════════════════════════════════
        //  RIGHT: Video Player
        // ══════════════════════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: learnRoot.currentVideo !== null

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Player header
                Rectangle {
                    Layout.fillWidth: true; height: 56
                    color: colorSurface
                    border.color: colorBorder

                    // Bottom line
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: colorBorder }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20; anchors.rightMargin: 20
                        spacing: 14

                        // Close / back button
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: closeMa.containsMouse ? "#20ffffff" : "transparent"
                            border.color: colorBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { text: "←"; color: colorText; font.pixelSize: 16; anchors.centerIn: parent }
                            MouseArea {
                                id: closeMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: learnRoot.currentVideo = null
                            }
                        }

                        Column {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: learnRoot.currentVideo ? learnRoot.currentVideo.title : ""
                                color: colorText; font.pixelSize: 14; font.weight: Font.Bold
                                elide: Text.ElideRight; width: parent.width
                            }
                            Row {
                                spacing: 8
                                Text {
                                    text: learnRoot.currentVideo ? learnRoot.currentVideo.channel : ""
                                    color: colorMuted; font.pixelSize: 12
                                }
                                Text { text: "·"; color: colorDim; font.pixelSize: 12 }
                                Text {
                                    text: learnRoot.currentVideo ? learnRoot.currentVideo.duration : ""
                                    color: colorDim; font.pixelSize: 12
                                }
                            }
                        }

                        // Watched badge
                        Rectangle {
                            visible: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id)
                            width: 90; height: 28; radius: 14
                            color: "#1a2e20"; border.color: "#22c55e"; border.width: 1
                            Text {
                                text: "✓ Visto"
                                anchors.centerIn: parent
                                color: "#86efac"; font.pixelSize: 11; font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                // ── Premium Video Player Panel ──
                // Works without WebEngine: shows thumbnail + YouTube button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#080810"

                    Column {
                        anchors.centerIn: parent
                        spacing: 32
                        width: Math.min(parent.width - 60, 520)

                        // ── Large Thumbnail ──
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(parent.width, 460)
                            height: width * 9 / 16  // 16:9 ratio
                            radius: 20
                            color: "#111118"
                            clip: true

                            // Gradient placeholder while image loads
                            Rectangle {
                                anchors.fill: parent; radius: 20
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.darker(Qt.color(learnRoot.currentVideo ? learnRoot.currentVideo.accentColor || "#6366f1" : "#6366f1"), 2.0) }
                                    GradientStop { position: 1.0; color: "#0a0a12" }
                                }
                            }

                            // YouTube thumbnail (loaded asynchronously)
                            Image {
                                anchors.fill: parent
                                source: learnRoot.currentVideo
                                    ? "https://img.youtube.com/vi/" + learnRoot.currentVideo.videoId + "/maxresdefault.jpg"
                                    : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                mipmap: true
                                smooth: true
                                // Fade in on load
                                opacity: status === Image.Ready ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 400 } }
                            }

                            // Dark overlay with play button
                            Rectangle {
                                anchors.fill: parent; radius: 20
                                color: thumbHover.containsMouse ? "#50000000" : "#70000000"
                                Behavior on color { ColorAnimation { duration: 200 } }

                                // YouTube play button (authentic style)
                                Rectangle {
                                    width: 72; height: 52; radius: 12
                                    anchors.centerIn: parent
                                    color: thumbHover.containsMouse ? "#d90000" : "#cc0000"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: thumbHover.containsMouse ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                                    // Triangle play icon
                                    Canvas {
                                        anchors.centerIn: parent
                                        width: 24; height: 24
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            ctx.fillStyle = "white"
                                            ctx.beginPath()
                                            ctx.moveTo(6, 3)
                                            ctx.lineTo(21, 12)
                                            ctx.lineTo(6, 21)
                                            ctx.closePath()
                                            ctx.fill()
                                        }
                                    }
                                }
                            }

                            // Duration badge
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 12
                                width: durLabel.width + 14; height: 24; radius: 6
                                color: "#cc000000"
                                Text {
                                    id: durLabel
                                    text: learnRoot.currentVideo ? learnRoot.currentVideo.duration : ""
                                    color: "white"; font.pixelSize: 12; font.weight: Font.Bold
                                    anchors.centerIn: parent
                                }
                            }

                            // Icon badge top-left
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left
                                anchors.margins: 12
                                width: 36; height: 36; radius: 10
                                color: "#cc000000"
                                Text {
                                    text: learnRoot.currentVideo ? learnRoot.currentVideo.icon || "🎬" : "🎬"
                                    font.pixelSize: 18; anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: thumbHover; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (learnRoot.currentVideo)
                                        Qt.openUrlExternally("https://www.youtube.com/watch?v=" + learnRoot.currentVideo.videoId)
                                }
                            }
                        }

                        // ── Video Info ──
                        Column {
                            width: parent.width
                            spacing: 10

                            Text {
                                width: parent.width
                                text: learnRoot.currentVideo ? learnRoot.currentVideo.title : ""
                                color: "#f4f4f8"
                                font.pixelSize: 20; font.weight: Font.Bold; font.letterSpacing: -0.4
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 12

                                // Channel pill
                                Rectangle {
                                    height: 28; radius: 14
                                    color: "#10ffffff"; border.color: "#18ffffff"; border.width: 1
                                    implicitWidth: chanRow.width + 20
                                    Row {
                                        id: chanRow; anchors.centerIn: parent; spacing: 6
                                        Text { text: "📺"; font.pixelSize: 12 }
                                        Text {
                                            text: learnRoot.currentVideo ? learnRoot.currentVideo.channel : ""
                                            color: "#b0b0c0"; font.pixelSize: 12; font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                // Playlist pill
                                Rectangle {
                                    height: 28; radius: 14
                                    color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.1)
                                    border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25); border.width: 1
                                    implicitWidth: plRow.width + 20
                                    Row {
                                        id: plRow; anchors.centerIn: parent; spacing: 6
                                        Text { text: "📁"; font.pixelSize: 12 }
                                        Text {
                                            text: learnRoot.currentVideo ? learnRoot.currentVideo.playlist : ""
                                            color: Qt.lighter(colorAccent, 1.4); font.pixelSize: 12; font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }

                            // Description
                            Text {
                                width: parent.width
                                text: learnRoot.currentVideo ? learnRoot.currentVideo.description : ""
                                color: "#6e6e7a"; font.pixelSize: 13; lineHeight: 1.5
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // ── Action Buttons ──
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 14

                            // PRIMARY: Open in YouTube
                            Rectangle {
                                width: 200; height: 48; radius: 24
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#cc2020" }
                                    GradientStop { position: 1.0; color: "#881818" }
                                }

                                Rectangle {
                                    anchors.fill: parent; radius: 24; color: "white"
                                    opacity: ytBtnMa.containsMouse ? 0.15 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                                Row {
                                    anchors.centerIn: parent; spacing: 10
                                    Canvas {
                                        width: 18; height: 14
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0,0,width,height)
                                            ctx.fillStyle = "white"
                                            ctx.beginPath()
                                            ctx.moveTo(4, 2); ctx.lineTo(16, 7); ctx.lineTo(4, 12)
                                            ctx.closePath(); ctx.fill()
                                        }
                                    }
                                    Text { text: "Ver en YouTube"; color: "white"; font.pixelSize: 14; font.weight: Font.Bold }
                                }
                                scale: ytBtnMa.pressed ? 0.95 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130 } }
                                MouseArea {
                                    id: ytBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (learnRoot.currentVideo)
                                            Qt.openUrlExternally("https://www.youtube.com/watch?v=" + learnRoot.currentVideo.videoId)
                                    }
                                }
                            }

                            // SECONDARY: Mark as watched
                            Rectangle {
                                width: 160; height: 48; radius: 24
                                color: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id)
                                    ? "#1a2e20" : "#10ffffff"
                                border.color: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id)
                                    ? "#22c55e" : "#20ffffff"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 250 } }

                                Rectangle {
                                    anchors.fill: parent; radius: 24; color: "white"
                                    opacity: markMa.containsMouse ? 0.08 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                                Row {
                                    anchors.centerIn: parent; spacing: 8
                                    Text {
                                        text: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id) ? "✓" : "○"
                                        color: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id) ? "#86efac" : "#6e6e7a"
                                        font.pixelSize: 14; font.weight: Font.Bold
                                    }
                                    Text {
                                        text: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id) ? "Completado" : "Marcar visto"
                                        color: learnRoot.currentVideo && learnRoot.isWatched(learnRoot.currentVideo.id) ? "#86efac" : "#8888a0"
                                        font.pixelSize: 13; font.weight: Font.DemiBold
                                    }
                                }
                                scale: markMa.pressed ? 0.95 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130 } }
                                MouseArea {
                                    id: markMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (learnRoot.currentVideo)
                                            learnRoot.markWatched(learnRoot.currentVideo.id)
                                    }
                                }
                            }
                        }
                    }
                }


                // Description panel
                Rectangle {
                    Layout.fillWidth: true
                    height: descContent.height + 28
                    color: colorSurface

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width; height: 1
                        color: colorBorder
                    }

                    Column {
                        id: descContent
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 24; anchors.rightMargin: 24
                        anchors.topMargin: 16
                        spacing: 10

                        Text {
                            text: learnRoot.currentVideo ? learnRoot.currentVideo.description : ""
                            color: colorMuted
                            font.pixelSize: 13; lineHeight: 1.5
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        // Tags / playlist
                        Row {
                            spacing: 10
                            Text { text: "📁"; font.pixelSize: 13 }
                            Text {
                                text: learnRoot.currentVideo ? learnRoot.currentVideo.playlist : ""
                                color: Qt.lighter(colorAccent, 1.4)
                                font.pixelSize: 12; font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Video List Item component ────────────────────────────────
    component VideoListItem : Rectangle {
        id: vliRoot
        property var videoData: ({})
        property bool isActive: false
        property bool watched: false
        property bool compact: false
        signal playRequested()

        height: compact ? 68 : 84
        color: isActive
            ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.1)
            : (vliMa.containsMouse ? "#0affffff" : "transparent")
        Behavior on color { ColorAnimation { duration: 160 } }

        // Left active accent bar
        Rectangle {
            width: 3; height: parent.height * 0.7
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            radius: 1.5
            color: Qt.rgba(Qt.color(videoData.accentColor || "#6366f1").r,
                           Qt.color(videoData.accentColor || "#6366f1").g,
                           Qt.color(videoData.accentColor || "#6366f1").b, 1.0)
            visible: isActive
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: compact ? 16 : 28
            anchors.rightMargin: 16
            spacing: 14

            // Thumbnail card
            Rectangle {
                width: compact ? 80 : 112; height: compact ? 50 : 64
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.darker(Qt.color(videoData.accentColor || "#6366f1"), 1.5) }
                    GradientStop { position: 1.0; color: Qt.darker(Qt.color(videoData.accentColor || "#6366f1"), 2.5) }
                }
                Behavior on width { NumberAnimation { duration: 300 } }

                // Thumbnail image from YouTube
                Image {
                    anchors.fill: parent
                    source: "https://img.youtube.com/vi/" + (videoData.videoId || "") + "/mqdefault.jpg"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: thumbMask
                    }
                }
                Rectangle {
                    id: thumbMask
                    anchors.fill: parent; radius: 10
                    visible: false; layer.enabled: true
                }

                // Play overlay
                Rectangle {
                    anchors.fill: parent; radius: 10
                    color: vliMa.containsMouse ? "#60000000" : "#30000000"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        anchors.centerIn: parent
                        color: "#cc000000"
                        scale: vliMa.containsMouse ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        Text {
                            text: "▶"; color: "white"; font.pixelSize: 10
                            anchors.centerIn: parent; anchors.horizontalCenterOffset: 2
                        }
                    }
                }

                // Duration badge
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    anchors.margins: 5
                    width: durTxt.width + 8; height: 16; radius: 4
                    color: "#cc000000"
                    Text {
                        id: durTxt
                        text: videoData.duration || ""
                        anchors.centerIn: parent
                        color: "white"; font.pixelSize: 9; font.weight: Font.Bold
                    }
                }

                // Watched checkmark
                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.top: parent.top; anchors.right: parent.right
                    anchors.margins: 5
                    color: "#22c55e"
                    visible: vliRoot.watched
                    Text { text: "✓"; color: "white"; font.pixelSize: 9; font.weight: Font.Bold; anchors.centerIn: parent }
                }
            }

            // Info
            Column {
                Layout.fillWidth: true; spacing: 4

                Text {
                    text: videoData.title || ""
                    color: vliRoot.isActive ? colorText : (vliMa.containsMouse ? colorText : "#d0d0d8")
                    font.pixelSize: compact ? 12 : 13; font.weight: Font.DemiBold
                    elide: Text.ElideRight; width: parent.width
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Row {
                    spacing: 8
                    Text {
                        text: videoData.channel || ""
                        color: colorDim; font.pixelSize: compact ? 10 : 11
                    }
                    Text { text: "·"; color: colorDim; font.pixelSize: 11 }
                    Text {
                        text: videoData.icon || ""
                        font.pixelSize: 11
                    }
                }

                Text {
                    text: videoData.description || ""
                    color: colorDim; font.pixelSize: 11
                    elide: Text.ElideRight; width: parent.width
                    visible: !compact
                    maximumLineCount: 1
                }
            }

            // Play arrow indicator
            Text {
                text: "▶"
                color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.8)
                font.pixelSize: 14
                opacity: vliRoot.isActive ? 1.0 : (vliMa.containsMouse ? 0.7 : 0)
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }

        // Bottom divider
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: compact ? 16 : 28
            height: 1; color: colorBorder; opacity: 0.5
        }

        MouseArea {
            id: vliMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: vliRoot.playRequested()
        }

        scale: vliMa.pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 120 } }
    }
}
