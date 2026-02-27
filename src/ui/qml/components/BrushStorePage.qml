import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
//  BRUSH STORE PAGE — Tienda de pinceles gratuitos de artistas
// ═══════════════════════════════════════════════════════════════
Item {
    id: brushStoreRoot
    // CRITICAL: explicit size binding for StackLayout
    width:  parent ? parent.width  : 800
    height: parent ? parent.height : 600

    // ─── Design tokens ───
    readonly property color colorBg:       "#060608"
    readonly property color colorSurface:  "#0e0e12"
    readonly property color colorCard:     "#111116"
    readonly property color colorBorder:   "#1c1c22"
    readonly property color colorAccent:   (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color colorText:     "#f4f4f8"
    readonly property color colorMuted:    "#6e6e7a"
    readonly property color colorDim:      "#3a3a44"

    // ─── State ───
    property string activeCategory: "all"
    property string searchQuery: ""
    property var installedPacks: []
    property var downloadingPacks: []
    property var pendingInstallPack: null

    // ─── Catalog of free brush packs ───
    property var catalog: [
        {
            id: "ink_master_v2",
            name: "Ink Master Vol.2",
            artist: "Søren Lind",
            avatar: "🖋",
            category: "inking",
            brushCount: 18,
            downloads: "42K",
            rating: 4.9,
            tags: ["lineart", "manga", "comic"],
            accentColor: "#6366f1",
            description: "Pinceles de entintado de precisión profesional. Includes dip pens, G-nibs, brush pens y marcadores técnicos.",
            url: "https://example.com/brushes/ink_master_v2.zip"
        },
        {
            id: "watercolor_dream",
            name: "Watercolor Dreams",
            artist: "Mia Svensson",
            avatar: "🎨",
            category: "watercolor",
            brushCount: 24,
            downloads: "78K",
            rating: 5.0,
            tags: ["acuarela", "suave", "translucent"],
            accentColor: "#06b6d4",
            description: "La colección de acuarela más descargada. Bordes húmedos, sangrados, lavados y pinceladas texturizadas.",
            url: "https://example.com/brushes/watercolor_dream.zip"
        },
        {
            id: "concept_sketch_pro",
            name: "Concept Sketch Pro",
            artist: "Dario Romano",
            avatar: "✏️",
            category: "sketching",
            brushCount: 32,
            downloads: "55K",
            rating: 4.8,
            tags: ["sketch", "concept", "rough"],
            accentColor: "#f59e0b",
            description: "El kit completo para conceptos rápidos. Lápices HB, B, 2B, carboncillo, grafito y herramientas de boceto digital.",
            url: "https://example.com/brushes/concept_sketch.zip"
        },
        {
            id: "oil_painting_classic",
            name: "Oil Painting Classic",
            artist: "Elena Voss",
            avatar: "🖌",
            category: "painting",
            brushCount: 20,
            downloads: "31K",
            rating: 4.7,
            tags: ["óleo", "impasto", "textured"],
            accentColor: "#dc2626",
            description: "Simula la textura y opacidad del óleo auténtico. Brochas cerdas, espátulas, glazing y blending brushes.",
            url: "https://example.com/brushes/oil_classic.zip"
        },
        {
            id: "fx_glow_pack",
            name: "FX & Glow Pack",
            artist: "Kenji Nakamura",
            avatar: "✨",
            category: "effects",
            brushCount: 15,
            downloads: "89K",
            rating: 5.0,
            tags: ["glow", "neon", "sparkle", "fx"],
            accentColor: "#8b5cf6",
            description: "Efectos especiales para arte digital: brillos, neones, partículas, humo y luces volumétricas.",
            url: "https://example.com/brushes/fx_glow.zip"
        },
        {
            id: "charcoal_studio",
            name: "Charcoal Studio",
            artist: "Ava Lindqvist",
            avatar: "🖤",
            category: "sketching",
            brushCount: 12,
            downloads: "19K",
            rating: 4.6,
            tags: ["carbón", "clásico", "textured"],
            accentColor: "#6b7280",
            description: "Carboncillo real digitalizado a alta resolución. Barridos, difuminados y trazos con grano de papel.",
            url: "https://example.com/brushes/charcoal.zip"
        },
        {
            id: "gouache_flat",
            name: "Gouache Flat Color",
            artist: "Sofia Herrera",
            avatar: "🟦",
            category: "painting",
            brushCount: 10,
            downloads: "27K",
            rating: 4.8,
            tags: ["gouache", "flat", "ilustración"],
            accentColor: "#10b981",
            description: "Pinceles de gouache para ilustración contemporánea. Bordes nítidos, colores planos y texturas sutiles.",
            url: "https://example.com/brushes/gouache.zip"
        },
        {
            id: "pastel_soft",
            name: "Soft Pastels Collection",
            artist: "Laura Bright",
            avatar: "🌸",
            category: "watercolor",
            brushCount: 16,
            downloads: "34K",
            rating: 4.7,
            tags: ["pastel", "suave", "dreamy"],
            accentColor: "#ec4899",
            description: "Pasteles suaves para ilustración kawaii y arte de fantasía. Tonos etéreos y difuminados delicados.",
            url: "https://example.com/brushes/pastels.zip"
        },
        {
            id: "texture_mega",
            name: "Texture Mega Bundle",
            artist: "Marcus Dahl",
            avatar: "🧱",
            category: "texture",
            brushCount: 40,
            downloads: "63K",
            rating: 4.9,
            tags: ["textura", "grunge", "paper", "noise"],
            accentColor: "#78716c",
            description: "40 pinceles de textura únicos: papel, lienzo, tela, madera, ruido, granulado y efectos de envejecimiento.",
            url: "https://example.com/brushes/texture_mega.zip"
        },
        {
            id: "manga_pro",
            name: "Manga Pro Kit",
            artist: "Yuki Tanaka",
            avatar: "📖",
            category: "inking",
            brushCount: 22,
            downloads: "112K",
            rating: 5.0,
            tags: ["manga", "anime", "comic", "screentone"],
            accentColor: "#3b82f6",
            description: "El kit definitivo para manga profesional. G-pen, maru pen, tramas, screentones y pinceles de efectos.",
            url: "https://example.com/brushes/manga_pro.zip"
        },
        {
            id: "hair_fur_detail",
            name: "Hair & Fur Details",
            artist: "Chloe Martin",
            avatar: "💇",
            category: "speciality",
            brushCount: 14,
            downloads: "22K",
            rating: 4.8,
            tags: ["cabello", "pelo", "fur", "detail"],
            accentColor: "#d97706",
            description: "Pinceles especializados para dibujar cabello y pelaje. Mechones, hebras, pelo corto y largo.",
            url: "https://example.com/brushes/hair_fur.zip"
        },
        {
            id: "cloud_sky_pack",
            name: "Clouds & Sky Pack",
            artist: "Felix Berg",
            avatar: "☁️",
            category: "painting",
            brushCount: 11,
            downloads: "41K",
            rating: 4.9,
            tags: ["nubes", "cielo", "fondos", "landscape"],
            accentColor: "#0ea5e9",
            description: "Pintura de cielos y nubes como un profesional. Cirros, cúmulos, tormentas y cielos del atardecer.",
            url: "https://example.com/brushes/clouds.zip"
        }
    ]

    readonly property var categories: [
        { id: "all",        label: "Todos",       icon: "🌟" },
        { id: "inking",     label: "Entintado",   icon: "🖋" },
        { id: "sketching",  label: "Boceto",       icon: "✏️" },
        { id: "watercolor", label: "Acuarela",     icon: "💧" },
        { id: "painting",   label: "Pintura",      icon: "🖌" },
        { id: "effects",    label: "Efectos",      icon: "✨" },
        { id: "texture",    label: "Texturas",     icon: "🧱" },
        { id: "speciality", label: "Especiales",   icon: "💎" }
    ]

    property var filteredCatalog: {
        var result = catalog
        if (activeCategory !== "all")
            result = result.filter(function(p) { return p.category === activeCategory })
        if (searchQuery.trim() !== "") {
            var q = searchQuery.toLowerCase()
            result = result.filter(function(p) {
                return p.name.toLowerCase().includes(q) ||
                       p.artist.toLowerCase().includes(q) ||
                       p.tags.some(function(t) { return t.includes(q) })
            })
        }
        return result
    }

    function isInstalled(id) { return installedPacks.indexOf(id) !== -1 }
    function isDownloading(id) { return downloadingPacks.indexOf(id) !== -1 }

    function install(pack) {
        if (isInstalled(pack.id) || isDownloading(pack.id)) return
        var newArr = downloadingPacks.slice()
        newArr.push(pack.id)
        downloadingPacks = newArr
        downloadTimer.packId = pack.id
        downloadTimer.restart()
        toastMsg.show("Descargando \"" + pack.name + "\"...", "info")
    }

    // Simulated download (replace with real network call)
    Timer {
        id: downloadTimer
        property string packId: ""
        interval: 2500
        onTriggered: {
            var arr1 = brushStoreRoot.downloadingPacks.filter(function(id) { return id !== packId })
            brushStoreRoot.downloadingPacks = arr1
            var arr2 = brushStoreRoot.installedPacks.slice()
            arr2.push(packId)
            brushStoreRoot.installedPacks = arr2
            toastMsg.show("✅ Pack instalado correctamente", "success")
        }
    }

    // ─── Background — Premium gradient ───
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08080c" }
            GradientStop { position: 0.5; color: "#060609" }
            GradientStop { position: 1.0; color: "#0a0a10" }
        }
    }

    // Ambient glow orb
    Rectangle {
        width: 500; height: 500; radius: 250
        x: -150; y: parent.height - 300
        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.02)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
    }


    // ─── MAIN LAYOUT ───
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        z: 1

        // ── Top Header Bar ── Glass Premium ──────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 84
            color: "#0c0c10"

            // Glass gradient
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.04) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Accent gradient bottom border
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
                anchors.leftMargin: 36
                anchors.rightMargin: 36
                spacing: 20

                // Title
                Column {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "🖌  Tienda de Pinceles"
                        color: colorText
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.letterSpacing: -0.5
                    }
                    Text {
                        text: "Pinceles gratuitos creados por artistas de la comunidad"
                        color: colorMuted
                        font.pixelSize: 13
                    }
                }

                Item { Layout.fillWidth: true }

                // Stats badge
                Rectangle {
                    height: 36; radius: 18
                    color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.1)
                    border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.25)
                    border.width: 1
                    implicitWidth: statText.width + 28

                    Text {
                        id: statText
                        anchors.centerIn: parent
                        text: brushStoreRoot.installedPacks.length + " packs instalados"
                        color: Qt.lighter(colorAccent, 1.5)
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                // Search bar
                Rectangle {
                    width: 280; height: 40; radius: 20
                    color: colorSurface
                    border.color: searchField.activeFocus ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5) : colorBorder
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 14
                        spacing: 8

                        Text { text: "🔍"; font.pixelSize: 14 }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Buscar pinceles, artistas..."
                            color: colorText
                            font.pixelSize: 13
                            placeholderTextColor: colorDim
                            background: Item {}
                            onTextChanged: brushStoreRoot.searchQuery = text
                        }

                        Text {
                            text: "✕"
                            color: colorMuted
                            font.pixelSize: 12
                            visible: searchField.text !== ""
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { searchField.text = ""; brushStoreRoot.searchQuery = "" }
                            }
                        }
                    }
                }
            }
        }

        // ── Category Pills ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 64
            color: colorSurface

            // Bottom line
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: colorBorder
            }

            ListView {
                id: catList
                anchors.fill: parent
                anchors.leftMargin: 32; anchors.rightMargin: 32
                anchors.topMargin: 14; anchors.bottomMargin: 14
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                model: brushStoreRoot.categories

                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                delegate: Rectangle {
                    id: catPill
                    property bool isActive: brushStoreRoot.activeCategory === modelData.id
                    width: catLabel.width + 36; height: 36
                    radius: 18
                    color: isActive
                        ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.18)
                        : (catMa.containsMouse ? "#16ffffff" : "#0cffffff")
                    border.color: isActive
                        ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5)
                        : (catMa.containsMouse ? "#20ffffff" : colorBorder)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: modelData.icon
                            font.pixelSize: 14
                        }
                        Text {
                            id: catLabel
                            text: modelData.label
                            color: catPill.isActive ? Qt.lighter(colorAccent, 1.6) : colorMuted
                            font.pixelSize: 13
                            font.weight: catPill.isActive ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    MouseArea {
                        id: catMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: brushStoreRoot.activeCategory = modelData.id
                    }

                    scale: catMa.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                }
            }
        }

        // ── Grid of Brush Pack Cards ─────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: packGrid.height + 60
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                width: 4
                contentItem: Rectangle { radius: 2; color: "#333" }
            }

            // Empty state
            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: brushStoreRoot.filteredCatalog.length === 0
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🔍"; font.pixelSize: 48; opacity: 0.3 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No se encontraron pinceles"
                    color: colorMuted; font.pixelSize: 16
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Intenta con otra categoría o término de búsqueda"
                    color: colorDim; font.pixelSize: 13
                }
            }

            Flow {
                id: packGrid
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 32; anchors.rightMargin: 32
                topPadding: 32; spacing: 20

                Repeater {
                    model: brushStoreRoot.filteredCatalog

                    delegate: BrushPackCard {
                        packData: modelData
                        installed: brushStoreRoot.isInstalled(modelData.id)
                        downloading: brushStoreRoot.isDownloading(modelData.id)
                        onInstallRequested: brushStoreRoot.install(packData)
                    }
                }
            }
        }
    }

    // ─── Inline Toast ───────────────────────────────────────────
    Rectangle {
        id: toastMsg
        property string message: ""
        property string msgType: "info"
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 32
        width: toastTxt.width + 40; height: 44; radius: 22
        color: msgType === "success" ? "#1a2e20" : (msgType === "error" ? "#2e1a1a" : "#1a1a2e")
        border.color: msgType === "success" ? "#22c55e" : (msgType === "error" ? "#ef4444" : colorAccent)
        border.width: 1
        opacity: 0
        z: 999

        Text {
            id: toastTxt
            text: toastMsg.message
            color: toastMsg.msgType === "success" ? "#86efac" : (toastMsg.msgType === "error" ? "#fca5a5" : Qt.lighter(colorAccent, 1.6))
            font.pixelSize: 13; font.weight: Font.Medium
            anchors.centerIn: parent
        }

        function show(msg, type) {
            message = msg
            msgType = type || "info"
            opacity = 1
            toastHideTimer.restart()
        }

        Behavior on opacity { NumberAnimation { duration: 250 } }
        Timer { id: toastHideTimer; interval: 2800; onTriggered: toastMsg.opacity = 0 }
    }

    // ─── Brush Pack Card component ───────────────────────────────
    component BrushPackCard : Rectangle {
        id: cardRoot
        property var packData: ({})
        property bool installed: false
        property bool downloading: false
        signal installRequested()

        width: {
            var available = packGrid.width
            var cols = Math.max(1, Math.floor((available + 20) / 360))
            return Math.floor((available - (cols - 1) * 20) / cols)
        }
        height: 220
        radius: 20
        color: cardMa.containsMouse ? Qt.rgba(1,1,1,0.03) : colorCard
        border.color: cardMa.containsMouse
            ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35)
            : (installed ? Qt.rgba(0.13, 0.71, 0.47, 0.3) : colorBorder)
        border.width: 1
        clip: true

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        scale: cardMa.pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: cardMa.containsMouse
            shadowColor: Qt.rgba(0,0,0,0.5)
            shadowBlur: 1.0
            shadowVerticalOffset: 8
            shadowOpacity: 0.5
        }

        // Accent strip at top
        Rectangle {
            width: parent.width; height: 3; radius: 0
            anchors.top: parent.top
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: packData.accentColor || colorAccent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Content
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            // Header: avatar + name + artist
            RowLayout {
                spacing: 14
                Layout.fillWidth: true

                // Avatar circle
                Rectangle {
                    width: 52; height: 52; radius: 16
                    color: Qt.rgba(
                        Qt.color(packData.accentColor || "#6366f1").r,
                        Qt.color(packData.accentColor || "#6366f1").g,
                        Qt.color(packData.accentColor || "#6366f1").b, 0.15)
                    border.color: Qt.rgba(
                        Qt.color(packData.accentColor || "#6366f1").r,
                        Qt.color(packData.accentColor || "#6366f1").g,
                        Qt.color(packData.accentColor || "#6366f1").b, 0.3)
                    border.width: 1
                    Text { text: packData.avatar || "🖌"; font.pixelSize: 24; anchors.centerIn: parent }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        text: packData.name || ""
                        color: colorText
                        font.pixelSize: 15; font.weight: Font.Bold
                        font.letterSpacing: -0.2
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: "por " + (packData.artist || "")
                        color: colorMuted; font.pixelSize: 12
                    }
                }

                // Rating badge
                Rectangle {
                    width: 52; height: 24; radius: 12
                    color: "#1a1a12"
                    border.color: "#f59e0b"; border.width: 1
                    Row {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "★"; color: "#f59e0b"; font.pixelSize: 11 }
                        Text {
                            text: (packData.rating || 0).toFixed(1)
                            color: "#fbbf24"; font.pixelSize: 11; font.weight: Font.Bold
                        }
                    }
                }
            }

            // Description
            Text {
                Layout.fillWidth: true
                text: packData.description || ""
                color: colorMuted; font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                lineHeight: 1.4
            }

            // Tags row
            Row {
                spacing: 6
                Repeater {
                    model: (packData.tags || []).slice(0, 3)
                    Rectangle {
                        height: 20; radius: 10
                        color: "#0effffff"
                        border.color: colorBorder; border.width: 1
                        implicitWidth: tagTxt.width + 16
                        Text {
                            id: tagTxt
                            text: "#" + modelData
                            color: colorDim; font.pixelSize: 10
                            anchors.centerIn: parent
                        }
                    }
                }
            }

            // Footer: stats + button
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Brush count
                Row {
                    spacing: 6
                    Text { text: "🖌"; font.pixelSize: 12 }
                    Text {
                        text: (packData.brushCount || 0) + " pinceles"
                        color: colorMuted; font.pixelSize: 12
                    }
                }

                // Downloads
                Row {
                    spacing: 4
                    Text { text: "⬇"; font.pixelSize: 11; color: colorDim }
                    Text {
                        text: packData.downloads || ""
                        color: colorDim; font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                // Install / Download button
                Rectangle {
                    id: installBtn
                    width: installed ? 104 : 112
                    height: 34; radius: 17
                    color: installed ? "#1a2e20" : "transparent"
                    border.color: installed ? "#22c55e" : "transparent"
                    border.width: installed ? 1 : 0
                    clip: true

                    Behavior on width { NumberAnimation { duration: 200 } }

                    // Gradient background (only when NOT installed)
                    Rectangle {
                        anchors.fill: parent; radius: 17
                        visible: !cardRoot.installed && !cardRoot.downloading
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(
                                Qt.color(packData.accentColor || "#6366f1").r,
                                Qt.color(packData.accentColor || "#6366f1").g,
                                Qt.color(packData.accentColor || "#6366f1").b, 0.9) }
                            GradientStop { position: 1.0; color: Qt.rgba(
                                Qt.color(packData.accentColor || "#6366f1").r * 0.7,
                                Qt.color(packData.accentColor || "#6366f1").g * 0.7,
                                Qt.color(packData.accentColor || "#6366f1").b * 0.7, 0.9) }
                        }
                    }

                    // Downloading state background
                    Rectangle {
                        anchors.fill: parent; radius: 17
                        visible: cardRoot.downloading
                        color: "#1a1a2e"
                        border.color: colorAccent; border.width: 1
                    }

                    // Hover glow overlay
                    Rectangle {
                        anchors.fill: parent; radius: 17
                        color: "white"
                        opacity: !installed && installBtnMa.containsMouse ? 0.15 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Row {
                        anchors.centerIn: parent; spacing: 6

                        // Spinner when downloading
                        Rectangle {
                            width: 14; height: 14; radius: 7
                            visible: cardRoot.downloading
                            color: "transparent"
                            border.color: "white"; border.width: 2
                            RotationAnimation on rotation {
                                running: cardRoot.downloading
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 900
                            }
                        }

                        Text {
                            text: cardRoot.installed
                                ? "✓ Instalado"
                                : (cardRoot.downloading ? "Instalando..." : "⬇ Instalar")
                            color: cardRoot.installed ? "#86efac" : "white"
                            font.pixelSize: 12; font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: installBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !cardRoot.installed && !cardRoot.downloading
                        onClicked: cardRoot.installRequested()
                    }
                }
            }
        }

        MouseArea {
            id: cardMa
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onClicked: (mouse) => mouse.accepted = false
        }
    }
}

