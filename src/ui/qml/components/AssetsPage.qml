import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════════
//  ASSETS PAGE — Biblioteca de recursos: texturas, referencias, paletas
// ═══════════════════════════════════════════════════════════════════
Item {
    id: assetsRoot
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
    property string activeTab:     "textures"
    property string searchQuery:   ""
    property int    activeFilter:  0

    // ─── Catalog ───
    property var textureCatalog: [
        { id: "t1",  name: "Canvas Linen",       emoji: "🧵", tag: "Paper",   colorHex: "#c4a35a", downloads: "23K", premium: false,
          desc: "Textura de lienzo auténtico con fibras visibles. Perfecta para óleo y acrílico digital." },
        { id: "t2",  name: "Watercolor Paper",   emoji: "💧", tag: "Paper",   colorHex: "#6baed6", downloads: "41K", premium: false,
          desc: "Papel de acuarela Cold Press 300gsm con grano pronunciado y absorción perfecta." },
        { id: "t3",  name: "Kraft Paper",        emoji: "📦", tag: "Paper",   colorHex: "#b5835a", downloads: "18K", premium: false,
          desc: "Papel kraft reciclado con textura orgánica. Ideal para bocetos y collage digital." },
        { id: "t4",  name: "Concrete Wall",      emoji: "🧱", tag: "Surface", colorHex: "#8d9db6", downloads: "35K", premium: false,
          desc: "Muro de hormigón brutalista con poros y manchas naturales. Ideal para concept art urbano." },
        { id: "t5",  name: "Worn Wood",          emoji: "🌲", tag: "Surface", colorHex: "#8b6247", downloads: "29K", premium: false,
          desc: "Madera envejecida con veta y nudos. Perfecta para fondos rústicos y fantasy." },
        { id: "t6",  name: "Grunge Noise",       emoji: "🌀", tag: "Grunge",  colorHex: "#555566", downloads: "67K", premium: false,
          desc: "Ruido grunge versátil para añadir desgaste y carácter a cualquier ilustración." },
        { id: "t7",  name: "Rice Paper",         emoji: "🌸", tag: "Paper",   colorHex: "#e8d5c4", downloads: "14K", premium: true,
          desc: "Papel de arroz japonés ultra-fino con fibras naturales visibles. Estética washi." },
        { id: "t8",  name: "Marble Stone",       emoji: "🏛",  tag: "Surface", colorHex: "#c8c8d8", downloads: "52K", premium: true,
          desc: "Mármol de carrara con venas y translucidez. Para retratos épicos y composiciones clásicas." },
        { id: "t9",  name: "Old Parchment",      emoji: "📜", tag: "Paper",   colorHex: "#d4b483", downloads: "38K", premium: false,
          desc: "Pergamino antiguo con manchas de humedad y oxidación. Para mapas y diseño medieval." },
        { id: "t10", name: "Rust Metal",         emoji: "⚙️", tag: "Grunge",  colorHex: "#b5541a", downloads: "44K", premium: false,
          desc: "Metal oxidado con capas de corrosión. Imprescindible para arte steampunk y sci-fi." },
        { id: "t11", name: "Fabric Denim",       emoji: "👖", tag: "Surface", colorHex: "#4a7ba7", downloads: "21K", premium: false,
          desc: "Tejido denim con trama diagonal y hilo blanco. Textura versátil para ropa y fondos." },
        { id: "t12", name: "Starry Night Sky",   emoji: "🌌", tag: "Overlay", colorHex: "#1a1a3e", downloads: "88K", premium: true,
          desc: "Cielo nocturno con estrellas y nebulosas. Overlay para fondos fantásticos." }
    ]

    property var colorPalettes: [
        { id: "p1",  name: "Sunset Gradient",  colors: ["#ff6b6b","#ffa550","#ffd166","#06d6a0"],    likes: "12K", author: "Aurora" },
        { id: "p2",  name: "Ocean Deep",       colors: ["#03045e","#0077b6","#00b4d8","#90e0ef"],    likes: "9K",  author: "Celeste" },
        { id: "p3",  name: "Forest Mist",      colors: ["#1b4332","#2d6a4f","#52b788","#b7e4c7"],    likes: "7K",  author: "Verdant" },
        { id: "p4",  name: "Neon Cyberpunk",   colors: ["#0d0d0d","#7b2d8b","#ff006e","#fb5607"],    likes: "18K", author: "Neon.X" },
        { id: "p5",  name: "Desert Dune",      colors: ["#c9843a","#e2c48a","#f4e4c1","#8b5e3c"],    likes: "5K",  author: "Sahara" },
        { id: "p6",  name: "Lavender Dream",   colors: ["#7b2fbe","#a663cc","#d4a5f5","#f3e8ff"],    likes: "14K", author: "DreamHue" },
        { id: "p7",  name: "Volcanic",         colors: ["#0d0d0d","#3d0000","#8b0000","#ff4500"],    likes: "11K", author: "Ember" },
        { id: "p8",  name: "Arctic Frost",     colors: ["#caf0f8","#90e0ef","#00b4d8","#0077b6"],    likes: "6K",  author: "Frost" }
    ]

    property var referenceData: [
        { id: "r1",  name: "Anatomy — Upper Body",     emoji: "🦾", tag: "Anatomy",    author: "Proko", uses: "34K",
          desc: "Guía completa de anatomía de torso, hombros y brazos con overlay muscular." },
        { id: "r2",  name: "Hand Poses × 50",          emoji: "✋", tag: "Anatomy",    author: "Line of Action", uses: "58K",
          desc: "50 poses de manos en diferentes ángulos para práctica de dibujo y referencia." },
        { id: "r3",  name: "Lighting Diagrams × 12",   emoji: "💡", tag: "Lighting",   author: "CGMA", uses: "27K",
          desc: "12 configuraciones de iluminación profesional con diagramas de posición." },
        { id: "r4",  name: "Perspective Grids",         emoji: "📐", tag: "Technique",  author: "DrawABox", uses: "45K",
          desc: "Cuadrículas de perspectiva de 1, 2 y 3 puntos listas para usar como capas." },
        { id: "r5",  name: "Color Theory Wheel",        emoji: "🎨", tag: "Color",      author: "James Gurney", uses: "19K",
          desc: "Rueda de color con armonías, temperaturas y valores de luminosidad." },
        { id: "r6",  name: "Facial Expressions × 24",  emoji: "😊", tag: "Anatomy",    author: "Character Design", uses: "41K",
          desc: "24 expresiones faciales básicas y avanzadas con guías de deformación." }
    ]

    property var filteredTextures: {
        var result = textureCatalog
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase()
            result = result.filter(function(t) {
                return t.name.toLowerCase().includes(q) || t.tag.toLowerCase().includes(q) || t.desc.toLowerCase().includes(q)
            })
        }
        return result
    }

    // ─── Background ───
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08080c" }
            GradientStop { position: 0.5; color: "#060609" }
            GradientStop { position: 1.0; color: "#0a0a10" }
        }
    }

    // Ambient glow
    Rectangle {
        width: 480; height: 480; radius: 240
        x: assetsRoot.width - 280; y: assetsRoot.height - 300
        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.022)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
    }

    // ─── MAIN LAYOUT ───
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        z: 1

        // ── Header ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: "#0b0b10"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.05) }
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
                anchors.leftMargin: 36; anchors.rightMargin: 36
                spacing: 20

                Column {
                    spacing: 4; Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "🗂  Biblioteca de Assets"
                        color: colorText; font.pixelSize: 22
                        font.weight: Font.Bold; font.letterSpacing: -0.5
                    }
                    Text {
                        text: (textureCatalog.length + colorPalettes.length + referenceData.length) + " recursos listos para usar"
                        color: colorMuted; font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                // Search
                Rectangle {
                    width: 260; height: 38; radius: 19
                    color: colorSurface
                    border.color: assetSearch.activeFocus
                        ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.55)
                        : colorBorder
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 6
                        Text { text: "🔍"; font.pixelSize: 13 }
                        TextField {
                            id: assetSearch
                            Layout.fillWidth: true
                            placeholderText: "Buscar assets..."
                            color: colorText; font.pixelSize: 12
                            placeholderTextColor: colorDim
                            background: Item {}
                            onTextChanged: assetsRoot.searchQuery = text
                        }
                        Text {
                            text: "✕"; color: colorMuted; font.pixelSize: 12
                            visible: assetSearch.text !== ""
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { assetSearch.text = ""; assetsRoot.searchQuery = "" }
                            }
                        }
                    }
                }
            }
        }

        // ── Tab Bar ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: colorSurface

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1; color: colorBorder
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 32; spacing: 4

                Repeater {
                    model: [
                        { id: "textures",   icon: "🧵", label: "Texturas (" + textureCatalog.length + ")" },
                        { id: "palettes",   icon: "🎨", label: "Paletas (" + colorPalettes.length + ")" },
                        { id: "references", icon: "📐", label: "Referencias (" + referenceData.length + ")" }
                    ]
                    delegate: Rectangle {
                        property bool isActive: assetsRoot.activeTab === modelData.id
                        width: tabTxt.width + 32; height: parent.height
                        color: "transparent"

                        // Active underline
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: isActive ? parent.width - 16 : 0
                            height: 2; radius: 1
                            color: colorAccent
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        Row {
                            anchors.centerIn: parent; spacing: 7
                            Text { text: modelData.icon; font.pixelSize: 14 }
                            Text {
                                id: tabTxt
                                text: modelData.label
                                color: isActive ? Qt.lighter(colorAccent, 1.5) : colorMuted
                                font.pixelSize: 13
                                font.weight: isActive ? Font.DemiBold : Font.Normal
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: assetsRoot.activeTab = modelData.id
                        }
                    }
                }
            }
        }

        // ── Content Area ─────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // ── TEXTURES TAB ─────────────────────────────────────────
            Flickable {
                anchors.fill: parent
                visible: assetsRoot.activeTab === "textures"
                contentWidth: width
                contentHeight: texFlow.height + 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    width: 4
                    contentItem: Rectangle { radius: 2; color: "#2a2a36" }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent; spacing: 14
                    visible: assetsRoot.filteredTextures.length === 0
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🧵"; font.pixelSize: 44; opacity: 0.25 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Sin resultados"; color: colorMuted; font.pixelSize: 15 }
                }

                Flow {
                    id: texFlow
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 32; anchors.rightMargin: 32
                    topPadding: 32; spacing: 18

                    Repeater {
                        model: assetsRoot.filteredTextures
                        delegate: TextureCard { packData: modelData }
                    }
                }
            }

            // ── PALETTES TAB ─────────────────────────────────────────
            Flickable {
                anchors.fill: parent
                visible: assetsRoot.activeTab === "palettes"
                contentWidth: width
                contentHeight: palFlow.height + 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    width: 4
                    contentItem: Rectangle { radius: 2; color: "#2a2a36" }
                }

                Flow {
                    id: palFlow
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 32; anchors.rightMargin: 32
                    topPadding: 32; spacing: 18

                    Repeater {
                        model: assetsRoot.colorPalettes
                        delegate: PaletteCard { palData: modelData }
                    }
                }
            }

            // ── REFERENCES TAB ───────────────────────────────────────
            Flickable {
                anchors.fill: parent
                visible: assetsRoot.activeTab === "references"
                contentWidth: width
                contentHeight: refFlow.height + 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    width: 4
                    contentItem: Rectangle { radius: 2; color: "#2a2a36" }
                }

                Flow {
                    id: refFlow
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 32; anchors.rightMargin: 32
                    topPadding: 32; spacing: 18

                    Repeater {
                        model: assetsRoot.referenceData
                        delegate: ReferenceCard { refData: modelData }
                    }
                }
            }
        }
    }

    // ─── Texture Card ────────────────────────────────────────────────
    component TextureCard : Rectangle {
        id: tc
        property var packData: ({})

        width: {
            var cols = Math.max(1, Math.floor((texFlow.width + 18) / 280))
            return Math.floor((texFlow.width - (cols - 1) * 18) / cols)
        }
        height: 190
        radius: 18
        color: tcMa.containsMouse ? "#16ffffff" : colorCard
        border.color: tcMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35) : colorBorder
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
        scale: tcMa.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        // Colour band top
        Rectangle {
            width: parent.width; height: 3
            anchors.top: parent.top
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: packData.colorHex || "#6366f1" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Texture preview swatch
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 3
            anchors.left: parent.left; anchors.right: parent.right
            height: 80
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.darker(packData.colorHex || "#6366f1", 2.2) }
                GradientStop { position: 1.0; color: Qt.darker(packData.colorHex || "#6366f1", 3.5) }
            }

            Text {
                anchors.centerIn: parent
                text: packData.emoji || "🧵"
                font.pixelSize: 36
                opacity: 0.85
            }

            // Tag badge
            Rectangle {
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.margins: 8
                height: 20; radius: 10
                color: "#cc000000"
                implicitWidth: tagLbl.width + 14
                Text {
                    id: tagLbl
                    text: packData.tag || ""; color: "#ccc"; font.pixelSize: 10
                    anchors.centerIn: parent
                }
            }

            // Premium badge
            Rectangle {
                visible: packData.premium === true
                anchors.top: parent.top; anchors.left: parent.left
                anchors.margins: 8
                height: 20; radius: 10
                color: "#cc9d4d00"
                implicitWidth: premTxt.width + 14
                Text {
                    id: premTxt
                    text: "PREMIUM"; color: "#fbbf24"; font.pixelSize: 9; font.weight: Font.Bold
                    anchors.centerIn: parent
                }
            }
        }

        // Info section
        Column {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14; anchors.rightMargin: 14
            anchors.bottomMargin: 14
            spacing: 5

            Text {
                text: packData.name || ""; color: colorText
                font.pixelSize: 13; font.weight: Font.DemiBold
                elide: Text.ElideRight; width: parent.width
            }
            Text {
                text: packData.desc || ""; color: colorMuted
                font.pixelSize: 11; lineHeight: 1.4; wrapMode: Text.WordWrap
                maximumLineCount: 2; elide: Text.ElideRight; width: parent.width
            }
            RowLayout {
                width: parent.width
                Text { text: "⬇ " + (packData.downloads || "0"); color: colorDim; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 70; height: 24; radius: 12
                    color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.18)
                    border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35); border.width: 1
                    Text {
                        text: packData.premium ? "🔒 Pro" : "⬇ Usar"
                        color: Qt.lighter(colorAccent, 1.5); font.pixelSize: 11; font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }
                }
            }
        }

        MouseArea { id: tcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: tcMa.containsMouse
            shadowColor: Qt.rgba(0,0,0,0.5); shadowBlur: 1.0; shadowVerticalOffset: 6; shadowOpacity: 0.45
        }
    }

    // ─── Palette Card ────────────────────────────────────────────────
    component PaletteCard : Rectangle {
        id: pc
        property var palData: ({})

        width: {
            var cols = Math.max(1, Math.floor((palFlow.width + 18) / 300))
            return Math.floor((palFlow.width - (cols - 1) * 18) / cols)
        }
        height: 140
        radius: 18
        color: pcMa.containsMouse ? "#16ffffff" : colorCard
        border.color: pcMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35) : colorBorder
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: 180 } }
        scale: pcMa.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        // Color swatches
        Row {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 60
            Repeater {
                model: palData.colors || []
                Rectangle {
                    width: pc.width / (palData.colors ? palData.colors.length : 1)
                    height: 60
                    color: modelData
                    // Top radius on first/last
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                    }
                }
            }
        }
        // Rounded corners clip for swatches
        Rectangle {
            anchors.top: parent.top
            width: parent.width; height: 60
            radius: 18
            color: "transparent"
        }

        // Info
        Column {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16; anchors.rightMargin: 16
            anchors.bottomMargin: 14
            spacing: 4

            RowLayout {
                width: parent.width
                Text {
                    text: palData.name || ""; color: colorText
                    font.pixelSize: 13; font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Text {
                    text: "♥ " + (palData.likes || "0"); color: colorMuted; font.pixelSize: 11
                }
            }
            Row {
                spacing: 8
                Text { text: "por"; color: colorDim; font.pixelSize: 11 }
                Text { text: palData.author || ""; color: Qt.lighter(colorAccent, 1.5); font.pixelSize: 11; font.weight: Font.DemiBold }
            }
        }

        MouseArea { id: pcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: pcMa.containsMouse
            shadowColor: Qt.rgba(0,0,0,0.5); shadowBlur: 1.0; shadowVerticalOffset: 6; shadowOpacity: 0.45
        }
    }

    // ─── Reference Card ──────────────────────────────────────────────
    component ReferenceCard : Rectangle {
        id: rc
        property var refData: ({})

        width: {
            var cols = Math.max(1, Math.floor((refFlow.width + 18) / 340))
            return Math.floor((refFlow.width - (cols - 1) * 18) / cols)
        }
        height: 155
        radius: 18
        color: rcMa.containsMouse ? "#16ffffff" : colorCard
        border.color: rcMa.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35) : colorBorder
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: 180 } }
        scale: rcMa.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        // Accent strip
        Rectangle {
            width: parent.width; height: 3; anchors.top: parent.top
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: colorAccent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 18; anchors.topMargin: 18
            spacing: 16

            Rectangle {
                width: 64; height: 64; radius: 16
                color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.12)
                border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25); border.width: 1
                Text { text: refData.emoji || "📐"; font.pixelSize: 28; anchors.centerIn: parent }
            }

            Column {
                Layout.fillWidth: true; spacing: 5

                RowLayout {
                    width: parent.width
                    Text {
                        text: refData.name || ""; color: colorText
                        font.pixelSize: 13; font.weight: Font.Bold
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Rectangle {
                        height: 20; radius: 10; color: "#0effffff"; border.color: colorBorder; border.width: 1
                        implicitWidth: tagRef.width + 14
                        Text { id: tagRef; text: refData.tag || ""; color: colorDim; font.pixelSize: 10; anchors.centerIn: parent }
                    }
                }

                Text {
                    text: refData.desc || ""; color: colorMuted; font.pixelSize: 11; lineHeight: 1.4
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                    width: parent.width
                }

                RowLayout {
                    width: parent.width
                    Row { spacing: 5
                        Text { text: "👤"; font.pixelSize: 11 }
                        Text { text: refData.author || ""; color: colorDim; font.pixelSize: 11 }
                    }
                    Text { text: "· " + (refData.uses || "0") + " usos"; color: colorDim; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 80; height: 26; radius: 13
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.85) }
                            GradientStop { position: 1.0; color: Qt.rgba(colorAccent.r * 0.7, colorAccent.g * 0.7, colorAccent.b * 0.7, 0.85) }
                        }
                        Text { text: "📥 Usar"; color: "white"; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }

        MouseArea { id: rcMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: rcMa.containsMouse
            shadowColor: Qt.rgba(0,0,0,0.5); shadowBlur: 1.0; shadowVerticalOffset: 6; shadowOpacity: 0.45
        }
    }
}
