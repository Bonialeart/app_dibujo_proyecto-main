import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../Translations.js" as Trans

Item {
    id: dashboardRoot
    anchors.fill: parent

    // RECARGAR DATOS
    onVisibleChanged: if (visible) refresh()

    property var externalModel: null
    signal openGallery()
    signal openProject(string path)
    signal openSketchbook(string path, string title)
    signal createNewProject()

    property int draggedIndex: -1
    property int targetIndex: -1
    property point grabOffset: "0,0"

    readonly property string lang: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.language : "en"
    function qs(key) { return Trans.get(key, lang); }

    readonly property color colorAccent: (typeof mainWindow !== "undefined") ? mainWindow.colorAccent : "#6366f1"
    readonly property color colorSurface: "#0d0d11"
    readonly property color colorBorder: "#1a1a20"
    readonly property color colorGlass: "#0affffff"
    readonly property color colorTextPrimary: "#f4f4f8"
    readonly property color colorTextSecondary: "#6e6e7a"
    readonly property color colorTextMuted: "#4a4a55"

    // Time-based greeting
    property string timeGreeting: {
        var h = new Date().getHours()
        if (h < 6) return "🌙 Good Evening"
        if (h < 12) return "☀️ Good Morning"
        if (h < 18) return "🌤 Good Afternoon"
        return "🌙 Good Evening"
    }

    // ═══════════════════════════════════════
    // 1. DEEP SPACE BACKGROUND — Premium Gradient
    // ═══════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        z: -10
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#020204" }
            GradientStop { position: 0.25; color: "#050508" }
            GradientStop { position: 0.6; color: "#08080d" }
            GradientStop { position: 1.0; color: "#060609" }
        }
    }

    // Animated Ambient Orb — Top-Left (Accent Color Glow)
    Rectangle {
        id: ambientOrb1
        width: 600; height: 600; radius: 300
        x: -200; y: -200
        color: Qt.rgba(Qt.lighter(colorAccent, 1.3).r, Qt.lighter(colorAccent, 1.3).g, Qt.lighter(colorAccent, 1.3).b, 0.04)
        z: -5
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }

        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: -150; duration: 8000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -200; duration: 8000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { to: -150; duration: 6000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -200; duration: 6000; easing.type: Easing.InOutSine }
        }
    }

    // Animated Ambient Orb — Bottom-Right (Warm Glow)
    Rectangle {
        id: ambientOrb2
        width: 500; height: 500; radius: 250
        x: parent.width - 300; y: parent.height - 250
        color: Qt.rgba(1.0, 0.4, 0.2, 0.025)
        z: -5
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }

        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: parent.width - 250; duration: 10000; easing.type: Easing.InOutSine }
            NumberAnimation { to: parent.width - 300; duration: 10000; easing.type: Easing.InOutSine }
        }
    }

    // Subtle grid pattern overlay
    Canvas {
        anchors.fill: parent
        z: -4
        opacity: 0.015
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#ffffff"
            ctx.lineWidth = 0.5
            var spacing = 60
            for (var x = 0; x < width; x += spacing) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }
            for (var y = 0; y < height; y += spacing) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }
        }
    }

    // ═══════════════════════════════════════
    // 1.5. EL FANTASMA Y DRAG CONTROLLER
    // ═══════════════════════════════════════
    Item {
        id: ghost
        width: 220; height: 260 // matches card size in Dashboard
        z: 99999
        visible: dashboardRoot.draggedIndex !== -1
        property var ghostData: null

        scale: visible ? 1.05 : 0.5
        rotation: visible ? 4 : 0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on rotation { NumberAnimation { duration: 250 } }
        // REMOVED BEHAVIORS ON X/Y FOR INSTANT FEEDBACK

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowBlur: 1.0; shadowVerticalOffset: 15; shadowOpacity: 0.6
        }

        Rectangle {
            anchors.fill: parent; radius: 24; color: "#16161a"; border.color: "#333"
            clip: true
            Loader {
                anchors.fill: parent
                // Expose properties exactly as the delegates expect:
                property var thumbnails: (ghost.ghostData && ghost.ghostData.thumbnails) ? ghost.ghostData.thumbnails : []
                property string title: ghost.ghostData ? ghost.ghostData.name : ""
                property string preview: ghost.ghostData ? ghost.ghostData.preview : ""
                sourceComponent: (ghost.ghostData && (ghost.ghostData.type === "folder" || ghost.ghostData.type === "sketchbook")) ? stackComp : drawingComp
            }
        }
    }


    // ═══════════════════════════════════════
    // 2. SCROLLABLE CONTENT
    // ═══════════════════════════════════════
    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: mainCol.height + 180
        topMargin: 0; bottomMargin: 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Smooth scrolling
        flickDeceleration: 3000
        maximumFlickVelocity: 2000

        Column {
            id: mainCol
            width: Math.min(parent.width - 80, 1300)
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 60; spacing: 55

            // ═══════════════════════════════════════
            // SECTION 1: HERO — Welcome & Quick Actions
            // ═══════════════════════════════════════
            Item {
                width: parent.width
                height: 300

                // Hero Card Background with premium Glass effect
                Rectangle {
                    anchors.fill: parent
                    radius: 32
                    color: "#080810"
                    border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.12)
                    border.width: 1.5

                    // Inner gradient glow — multi-stop
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 31
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.08) }
                            GradientStop { position: 0.3; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.02) }
                            GradientStop { position: 0.6; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.015) }
                        }
                    }

                    // Decorative ambient circles
                    Rectangle {
                        width: 240; height: 240; radius: 120
                        anchors.right: parent.right; anchors.rightMargin: 40
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.05)
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.08; duration: 4000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 4000; easing.type: Easing.InOutSine }
                        }
                    }
                    Rectangle {
                        width: 140; height: 140; radius: 70
                        anchors.right: parent.right; anchors.rightMargin: 140
                        anchors.top: parent.top; anchors.topMargin: 15
                        color: Qt.rgba(1, 0.45, 0.25, 0.035)
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 0.8 }
                    }
                    Rectangle {
                        width: 80; height: 80; radius: 40
                        anchors.left: parent.left; anchors.leftMargin: 30
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 20
                        color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.03)
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 }
                    }
                }

                // Content Row
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    spacing: 40

                    // Left: Welcome Text
                    Column {
                        Layout.fillWidth: true
                        spacing: 14

                        // Time-based greeting badge
                        Rectangle {
                            width: greetingText.width + 28; height: 32
                            radius: 16
                            color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.1)
                            border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.2)
                            border.width: 1

                            // Subtle inner gradient
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 1; radius: 15
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.06) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }

                            Text {
                                id: greetingText
                                text: dashboardRoot.timeGreeting
                                color: Qt.lighter(colorAccent, 1.5)
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.6
                                anchors.centerIn: parent
                            }

                            // Staggered fade-in
                            opacity: 0; y: 8
                            Component.onCompleted: { opacity = 1; y = 0 }
                            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            text: dashboardRoot.qs("welcome")
                            color: colorTextPrimary
                            font.pixelSize: 48
                            font.weight: Font.Black
                            font.letterSpacing: -2.2

                            // Staggered fade-in
                            opacity: 0; y: 12
                            Component.onCompleted: { opacity = 1; y = 0 }
                            Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            text: dashboardRoot.qs("welcome_desc")
                            color: colorTextSecondary
                            font.pixelSize: 17
                            font.weight: Font.Light
                            font.letterSpacing: 0.4
                            lineHeight: 1.4

                            // Staggered fade-in (delayed)
                            opacity: 0; y: 10
                            Component.onCompleted: { opacity = 1; y = 0 }
                            Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Right: Quick Action Buttons
                    Column {
                        spacing: 14
                        Layout.alignment: Qt.AlignVCenter

                        // Primary CTA — New Drawing
                        Rectangle {
                            id: btnNew
                            width: 270; height: 60
                            radius: 30

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.lighter(colorAccent, 1.1) }
                                GradientStop { position: 0.5; color: colorAccent }
                                GradientStop { position: 1.0; color: Qt.darker(colorAccent, 1.15) }
                            }

                            // Inner shine (top half)
                            Rectangle {
                                width: parent.width - 4; height: parent.height / 2
                                anchors.top: parent.top; anchors.topMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 28
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }

                            // Border ring
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 1
                                radius: 29; color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.12); border.width: 1
                            }

                            Row {
                                anchors.centerIn: parent; spacing: 12
                                // Plus icon
                                Item {
                                    width: 22; height: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle { width: 14; height: 2; color: "white"; anchors.centerIn: parent; radius: 1 }
                                    Rectangle { width: 2; height: 14; color: "white"; anchors.centerIn: parent; radius: 1 }
                                    rotation: maNew.containsMouse ? 90 : 0
                                    Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                                }
                                Text {
                                    text: dashboardRoot.qs("new_drawing")
                                    color: "white"; font.bold: true; font.pixelSize: 16; font.letterSpacing: -0.2
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Hover glow
                            Rectangle {
                                anchors.fill: parent; radius: 29
                                color: "white"; opacity: maNew.containsMouse ? 0.12 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            scale: maNew.pressed ? 0.95 : (maNew.containsMouse ? 1.04 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                            MouseArea {
                                id: maNew; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardRoot.createNewProject()
                            }
                        }

                        // Secondary CTA — Open Gallery
                        Rectangle {
                            width: 270; height: 52
                            radius: 26
                            color: "transparent"
                            border.color: maGalHero.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.35) : "#20ffffff"
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Row {
                                anchors.centerIn: parent; spacing: 10
                                Text {
                                    text: "📁"
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: dashboardRoot.qs("go_gallery")
                                    color: maGalHero.containsMouse ? colorTextPrimary : colorTextSecondary
                                    font.pixelSize: 14; font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent; radius: 26
                                color: "white"; opacity: maGalHero.containsMouse ? 0.06 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            scale: maGalHero.pressed ? 0.96 : (maGalHero.containsMouse ? 1.03 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                            MouseArea {
                                id: maGalHero; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: dashboardRoot.openGallery()
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════
            // SECTION 2: QUICK ACTIONS — Canvas Preset Cards
            // ═══════════════════════════════════════
            Column {
                width: parent.width; spacing: 22

                // Section header with accent underline
                Item {
                    width: parent.width; height: 30
                    Text {
                        text: "Quick Start"
                        color: colorTextPrimary
                        font.pixelSize: 21; font.weight: Font.Bold; font.letterSpacing: -0.3
                    }
                    Rectangle {
                        width: 40; height: 2; radius: 1
                        anchors.bottom: parent.bottom
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: colorAccent }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                RowLayout {
                    width: parent.width; spacing: 18

                    // Quick Draw Card
                    QuickActionCard {
                        Layout.fillWidth: true
                        title: "Quick Draw"
                        subtitle: "1920 × 1080 — HD Canvas"
                        iconText: "✏️"
                        cardAccent: colorAccent
                        onClicked: {
                            if (typeof mainCanvas !== "undefined") {
                                mainCanvas.resizeCanvas(1920, 1080)
                                mainWindow.isProjectActive = true
                                mainWindow.currentPage = 1
                                mainCanvas.fitToView()
                            }
                        }
                    }

                    QuickActionCard {
                        Layout.fillWidth: true
                        title: "Square Canvas"
                        subtitle: "2048 × 2048 — Social Media"
                        iconText: "🖼"
                        cardAccent: "#ec4899"
                        onClicked: {
                            if (typeof mainCanvas !== "undefined") {
                                mainCanvas.resizeCanvas(2048, 2048)
                                mainWindow.isProjectActive = true
                                mainWindow.currentPage = 1
                                mainCanvas.fitToView()
                            }
                        }
                    }

                    QuickActionCard {
                        Layout.fillWidth: true
                        title: "4K Ultra"
                        subtitle: "3840 × 2160 — Print Quality"
                        iconText: "🎨"
                        cardAccent: "#10b981"
                        onClicked: {
                            if (typeof mainCanvas !== "undefined") {
                                mainCanvas.resizeCanvas(3840, 2160)
                                mainWindow.isProjectActive = true
                                mainWindow.currentPage = 1
                                mainCanvas.fitToView()
                            }
                        }
                    }

                    QuickActionCard {
                        Layout.fillWidth: true
                        title: "Portrait"
                        subtitle: "1080 × 1920 — Mobile/Story"
                        iconText: "📱"
                        cardAccent: "#f59e0b"
                        onClicked: {
                            if (typeof mainCanvas !== "undefined") {
                                mainCanvas.resizeCanvas(1080, 1920)
                                mainWindow.isProjectActive = true
                                mainWindow.currentPage = 1
                                mainCanvas.fitToView()
                            }
                        }
                    }
                }
            }


            // ═══════════════════════════════════════
            // SECTION 3: RECENT PROJECTS
            // ═══════════════════════════════════════
            Column {
                width: parent.width; spacing: 22

                RowLayout {
                    width: parent.width
                    Item {
                        Layout.fillWidth: true; height: 32
                        Text {
                            text: dashboardRoot.qs("recent_creations")
                            color: colorTextPrimary
                            font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: -0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 45; height: 2; radius: 1
                            anchors.bottom: parent.bottom
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: colorAccent }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                    Rectangle {
                        width: galLink.width + 28; height: 36
                        radius: 18
                        color: maGal.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.1) : "transparent"
                        border.color: maGal.containsMouse ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.3) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Text {
                            id: galLink
                            text: dashboardRoot.qs("go_gallery")
                            color: colorAccent
                            font.bold: true; font.pixelSize: 14
                            anchors.centerIn: parent
                        }
                        MouseArea {
                            id: maGal; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: dashboardRoot.openGallery()
                        }
                    }
                }

                // Empty state
                Rectangle {
                    width: parent.width; height: 200
                    radius: 20
                    color: "#08ffffff"
                    border.color: "#10ffffff"
                    border.width: 1
                    visible: (!dashboardRoot.externalModel || dashboardRoot.externalModel.count === 0) && recentModel.count === 0

                    Column {
                        anchors.centerIn: parent; spacing: 12
                        Text { text: "🎨"; font.pixelSize: 40; anchors.horizontalCenter: parent.horizontalCenter }
                        Text {
                            text: "No projects yet"
                            color: colorTextSecondary; font.pixelSize: 16; font.weight: Font.Medium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "Create your first masterpiece to see it here"
                            color: "#50ffffff"; font.pixelSize: 13
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Project Cards Grid
                Flow {
                    id: flowGrid
                    width: parent.width; spacing: 25
                    Repeater {
                        model: dashboardRoot.externalModel || recentModel
                        delegate: Item {
                            id: projItem; width: 220; height: 260
                            property int modelIndex: index // Exposed for the dragController
                            property bool isEditing: false
                            
                            opacity: (dashboardRoot.draggedIndex === index) ? 0.0 : 1.0

                            // Hover and Target micro-interaction
                            scale: (dashboardRoot.targetIndex === index && dashboardRoot.draggedIndex !== index) ? 1.05 : (maProj.containsMouse ? 1.05 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                            Column {
                                anchors.fill: parent; spacing: 12
                                
                                Rectangle {
                                    width: parent.width; height: 180; radius: 24
                                    
                                    color: (model.type === "folder" || model.type === "sketchbook") ? "transparent" : "#16161a"
                                    border.color: (model.type === "folder" || model.type === "sketchbook") ? "transparent" : (maProj.containsMouse ? colorAccent : "#18ffffff")
                                    border.width: (model.type === "folder" || model.type === "sketchbook") ? 0 : (maProj.containsMouse ? 2 : 1)
                                    clip: (model.type === "folder" || model.type === "sketchbook") ? false : true 
                                    
                                    Behavior on border.color { ColorAnimation { duration: 250 } }

                                    Loader {
                                        id: cellLoader
                                        anchors.fill: parent
                                        
                                        // ✅ CORRECCIÓN 1: Pasar el modelo directo sin chequear .length
                                        property var thumbnails: model.thumbnails 
                                        
                                        property string title: model.name || ""
                                        property string preview: model.preview || ""
                                        // NUEVO: Pasamos el estado del mouse
                                        property bool isHovered: maProj.containsMouse 
                                        sourceComponent: (model.type === "folder" || model.type === "sketchbook") ? stackComp : drawingComp
                                    }
                                }

                                Column {
                                    width: parent.width; spacing: 2
                                    Item {
                                        width: parent.width; height: 24
                                        Text {
                                            anchors.fill: parent
                                            visible: !projItem.isEditing
                                            text: model.name || dashboardRoot.qs("untitled")
                                            color: colorTextPrimary; font.bold: true; font.pixelSize: 14
                                            elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        // ✅ RIGHT CLICK FOR RENAMING
                                        MouseArea {
                                            anchors.fill: parent
                                            visible: !projItem.isEditing
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.RightButton) {
                                                    projItem.isEditing = true
                                                } else {
                                                    if (model.type === "folder" || model.type === "sketchbook") dashboardRoot.openSketchbook(model.path, model.name)
                                                    else dashboardRoot.openProject(model.path)
                                                }
                                            }
                                        }

                                        TextField {
                                            id: editField
                                            anchors.fill: parent
                                            visible: projItem.isEditing
                                            text: model.name || ""
                                            font.pixelSize: 14; font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            color: "white"
                                            selectByMouse: true
                                            background: Rectangle { 
                                                color: "#1a1a1e"
                                                radius: 4
                                                border.color: colorAccent
                                                border.width: 1
                                            }
                                            onAccepted: {
                                                if (text !== "" && text !== model.name) {
                                                    mainCanvas.rename_item(model.path, text)
                                                }
                                                projItem.isEditing = false
                                            }
                                            onEditingFinished: projItem.isEditing = false
                                            Component.onCompleted: if(visible) forceActiveFocus()
                                            onVisibleChanged: if(visible) { text = model.name; forceActiveFocus(); selectAll(); }
                                        }
                                    }
                                    Text {
                                        text: model.date || ""
                                        color: colorTextSecondary; font.pixelSize: 11
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: text !== ""
                                    }
                                }
                            }

                            // Action Buttons (Top Right)
                            Rectangle {
                                width: 28; height: 28; radius: 14; z: 100
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 10
                                color: maDel.containsMouse ? "#ef4444" : "#dd1c1c1e"
                                border.color: "#30ffffff"; border.width: 1
                                opacity: (maProj.containsMouse || maDel.containsMouse) ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Text { text: "✕"; color: "white"; font.pixelSize: 13; anchors.centerIn: parent }
                                MouseArea {
                                    id: maDel; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        if (model.type === "folder" || model.type === "sketchbook") {
                                            if (mainCanvas.deleteFolder(model.path)) dashboardRoot.refresh()
                                        } else {
                                            if (mainCanvas.deleteProject(model.path)) dashboardRoot.refresh()
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: maProj; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                pressAndHoldInterval: 250
                                onClicked: {
                                    if (model.type === "folder" || model.type === "sketchbook") dashboardRoot.openSketchbook(model.path, model.name)
                                    else dashboardRoot.openProject(model.path)
                                }
                                onPressAndHold: (mouse) => {
                                    dashboardRoot.draggedIndex = index
                                    var md = (dashboardRoot.externalModel || recentModel)
                                    
                                    // Extract data properly for ghost
                                    var dataObj = md.get(index)
                                    ghost.ghostData = {
                                        name: dataObj.name,
                                        preview: dataObj.preview,
                                        type: dataObj.type,
                                        thumbnails: dataObj.thumbnails
                                    }

                                    // Absolute mapping to global root
                                    var globalGrab = maProj.mapToItem(dashboardRoot, mouse.x, mouse.y)
                                    var itemPos = projItem.mapToItem(dashboardRoot, 0, 0)
                                    
                                    dashboardRoot.grabOffset = Qt.point(globalGrab.x - itemPos.x, globalGrab.y - itemPos.y)
                                    ghost.x = itemPos.x
                                    ghost.y = itemPos.y
                                }
                                onPositionChanged: (mouse) => {
                                    if (dashboardRoot.draggedIndex === index) {
                                        var globalPos = maProj.mapToItem(dashboardRoot, mouse.x, mouse.y)
                                        ghost.x = globalPos.x - dashboardRoot.grabOffset.x
                                        ghost.y = globalPos.y - dashboardRoot.grabOffset.y
                                        
                                        var targetIdx = -1
                                        for (var i = 0; i < flowGrid.children.length; i++) {
                                            var c = flowGrid.children[i]
                                            if (c.modelIndex !== undefined) {
                                                var childPos = dashboardRoot.mapToItem(c, globalPos.x, globalPos.y)
                                                if (childPos.x >= 0 && childPos.x < c.width && childPos.y >= 0 && childPos.y < c.height) {
                                                    targetIdx = c.modelIndex
                                                    break
                                                }
                                            }
                                        }
                                        dashboardRoot.targetIndex = (targetIdx !== -1 && targetIdx !== dashboardRoot.draggedIndex) ? targetIdx : -1
                                    }
                                }
                                onReleased: {
                                    if (dashboardRoot.draggedIndex === index) {
                                        if (dashboardRoot.targetIndex !== -1) {
                                            var model = (dashboardRoot.externalModel || recentModel)
                                            var a = model.get(dashboardRoot.draggedIndex)
                                            var b = model.get(dashboardRoot.targetIndex)
                                            if (mainCanvas.create_folder_from_merge(a.path, b.path)) {
                                                dashboardRoot.refresh()
                                            }
                                        }
                                    }
                                    dashboardRoot.draggedIndex = -1
                                    dashboardRoot.targetIndex = -1
                                }
                                onCanceled: {
                                    dashboardRoot.draggedIndex = -1
                                    dashboardRoot.targetIndex = -1
                                }
                            }
                        }
                    }
                }
            }


            // ═══════════════════════════════════════
            // SECTION 4: RESOURCES & ASSETS
            // ═══════════════════════════════════════
            Column {
                width: parent.width; spacing: 22

                Text {
                    text: dashboardRoot.qs("resources_assets")
                    color: colorTextPrimary
                    font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: -0.5
                }

                RowLayout {
                    width: parent.width; spacing: 18

                    AssetCard {
                        Layout.fillWidth: true
                        title: dashboardRoot.qs("new_brushes")
                        desc: dashboardRoot.qs("watercolor_pack")
                        accentColor: "#ef4444"
                        iconEmoji: "🖌"
                    }
                    AssetCard {
                        Layout.fillWidth: true
                        title: dashboardRoot.qs("paper_textures")
                        desc: dashboardRoot.qs("fine_grain")
                        accentColor: "#22c55e"
                        iconEmoji: "📄"
                    }
                    AssetCard {
                        Layout.fillWidth: true
                        title: dashboardRoot.qs("color_palettes")
                        desc: dashboardRoot.qs("sunset_insp")
                        accentColor: "#f59e0b"
                        iconEmoji: "🎨"
                    }
                }
            }


            // ═══════════════════════════════════════
            // SECTION 5: LEARNING CENTER
            // ═══════════════════════════════════════
            Column {
                width: parent.width; spacing: 22

                Text {
                    text: dashboardRoot.qs("improve_technique")
                    color: colorTextPrimary
                    font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: -0.5
                }

                Flow {
                    width: parent.width; spacing: 18
                    VideoCard {
                        title: dashboardRoot.qs("mastering_layers")
                        duration: "05:20"
                        gradStart: "#1e3a5f"; gradEnd: "#0f2439"
                        iconText: "📐"
                    }
                    VideoCard {
                        title: dashboardRoot.qs("pro_workflow")
                        duration: "12:45"
                        gradStart: "#3b1f5e"; gradEnd: "#1f1035"
                        iconText: "⚡"
                    }
                    VideoCard {
                        title: dashboardRoot.qs("advanced_shading")
                        duration: "08:15"
                        gradStart: "#1a3f2f"; gradEnd: "#0d2319"
                        iconText: "🌗"
                    }
                }
            }

            // Bottom spacer
            Item { width: 1; height: 40 }
        }
    }


    // ═══════════════════════════════════════
    // INTERNAL COMPONENTS
    // ═══════════════════════════════════════

    // Quick Action Card Component (Premium v2)
    component QuickActionCard : Rectangle {
        id: qacRoot
        property string title: ""
        property string subtitle: ""
        property string iconText: ""
        property color cardAccent: colorAccent
        signal clicked()

        height: 108
        radius: 20
        color: "#0a0a0f"
        border.color: qacHover.containsMouse ? Qt.rgba(cardAccent.r, cardAccent.g, cardAccent.b, 0.45) : "#10ffffff"
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Accent glow on hover — multi-direction
        Rectangle {
            anchors.fill: parent; radius: 20
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(qacRoot.cardAccent.r, qacRoot.cardAccent.g, qacRoot.cardAccent.b, 0.1) }
                GradientStop { position: 0.5; color: Qt.rgba(qacRoot.cardAccent.r, qacRoot.cardAccent.g, qacRoot.cardAccent.b, 0.02) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: qacHover.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        // Bottom accent line on hover
        Rectangle {
            width: parent.width * 0.6; height: 2; radius: 1
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(qacRoot.cardAccent.r, qacRoot.cardAccent.g, qacRoot.cardAccent.b, 0.5) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: qacHover.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 16

            // Icon container with gradient background
            Rectangle {
                width: 54; height: 54; radius: 17
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(qacRoot.cardAccent.r, qacRoot.cardAccent.g, qacRoot.cardAccent.b, 0.18) }
                    GradientStop { position: 1.0; color: Qt.rgba(qacRoot.cardAccent.r, qacRoot.cardAccent.g, qacRoot.cardAccent.b, 0.08) }
                }
                border.color: Qt.rgba(qacRoot.cardAccent.r, qacRoot.cardAccent.g, qacRoot.cardAccent.b, 0.22)
                border.width: 1

                Text {
                    text: qacRoot.iconText
                    font.pixelSize: 24
                    anchors.centerIn: parent

                    scale: qacHover.containsMouse ? 1.15 : 1.0
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                }
            }

            Column {
                Layout.fillWidth: true; spacing: 5
                Text {
                    text: qacRoot.title
                    color: colorTextPrimary
                    font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: -0.2
                }
                Text {
                    text: qacRoot.subtitle
                    color: colorTextSecondary
                    font.pixelSize: 12; font.letterSpacing: 0.1
                }
            }

            // Arrow indicator
            Text {
                text: "→"
                color: colorTextSecondary
                font.pixelSize: 16
                opacity: qacHover.containsMouse ? 1.0 : 0.0
                Layout.rightMargin: 4
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        scale: qacHover.pressed ? 0.97 : (qacHover.containsMouse ? 1.025 : 1.0)
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        MouseArea {
            id: qacHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: qacRoot.clicked()
        }
    }

    // Drawing Card Component
    // Drawing Card Component (Premium Version)
    Component {
        id: drawingComp
        Item {
            anchors.fill: parent
            
            // Property injected by Loader
            property string previewUrl: title !== "" ? preview : (model.preview || "") 

            // Card Container
            Rectangle {
                id: card
                anchors.fill: parent
                color: "#1c1c22"
                radius: 20 // Matching the outer container radius
                
                // 1. Premium Shadow
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#80000000"
                    shadowBlur: 1.0
                    shadowVerticalOffset: 6
                    shadowOpacity: 0.5
                }

                // 2. Thumbnail Image
                Image {
                    id: imgPreview
                    anchors.fill: parent
                    source: previewUrl
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    asynchronous: true
                    
                    // Masking for rounded corners
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskRectHome
                    }
                }

                // 3. Mask Rectangle (Hidden)
                Rectangle {
                    id: maskRectHome
                    anchors.fill: parent
                    radius: 20
                    visible: false
                    layer.enabled: true
                }
                
                // 4. Placeholder (if empty or loading)
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: imgPreview.status !== Image.Ready && imgPreview.source == ""
                    
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🎨"; font.pixelSize: 32; opacity: 0.4 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Empty"; color: "#555"; font.pixelSize: 11 }
                }
            }
        }
    }

    // Asset Card Component
    component AssetCard : Rectangle {
        id: assetRoot
        property string title: ""
        property string desc: ""
        property string iconEmoji: "★"
        property color accentColor: colorAccent

        height: 110; radius: 20
        color: "#0c0c10"
        border.color: assetHover.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35) : "#12ffffff"
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Gradient hover effect
        Rectangle {
            anchors.fill: parent; radius: 20
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(assetRoot.accentColor.r, assetRoot.accentColor.g, assetRoot.accentColor.b, 0.06) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: assetHover.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        RowLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 18

            Rectangle {
                width: 56; height: 56; radius: 16
                color: Qt.rgba(assetRoot.accentColor.r, assetRoot.accentColor.g, assetRoot.accentColor.b, 0.1)
                border.color: Qt.rgba(assetRoot.accentColor.r, assetRoot.accentColor.g, assetRoot.accentColor.b, 0.2)
                border.width: 1

                Text { anchors.centerIn: parent; text: assetRoot.iconEmoji; font.pixelSize: 24 }
            }

            Column {
                Layout.fillWidth: true; spacing: 4
                Text { text: assetRoot.title; color: colorTextPrimary; font.bold: true; font.pixelSize: 15 }
                Text { text: assetRoot.desc; color: colorTextSecondary; font.pixelSize: 13 }
            }

            // Arrow indicator
            Text {
                text: "→"
                color: colorTextSecondary
                font.pixelSize: 18
                opacity: assetHover.containsMouse ? 1.0 : 0.3
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        scale: assetHover.pressed ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }

        MouseArea {
            id: assetHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        }
    }

    // Video Card Component
    component VideoCard : Rectangle {
        id: vidRoot
        property string title: ""
        property string duration: ""
        property color gradStart: "#1e3a5f"
        property color gradEnd: "#0f2439"
        property string iconText: "▶"

        width: 310; height: 195
        radius: 20
        color: "#0c0c10"
        border.color: vidHover.containsMouse ? "#30ffffff" : "#12ffffff"
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 200 } }

        // Thumbnail area
        Rectangle {
            anchors.fill: parent; anchors.bottomMargin: 55
            radius: 20; clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: vidRoot.gradStart }
                GradientStop { position: 1.0; color: vidRoot.gradEnd }
            }

            // Play button
            Rectangle {
                width: 46; height: 46; radius: 23
                color: "#cc000000"
                anchors.centerIn: parent
                border.color: "#40ffffff"; border.width: 1

                Text {
                    text: "▶"
                    color: "white"; font.pixelSize: 16
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 2
                }

                scale: vidHover.containsMouse ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }

            // Duration badge
            Rectangle {
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.margins: 10
                width: durText.width + 14; height: 22; radius: 11
                color: "#cc000000"

                Text {
                    id: durText
                    text: vidRoot.duration; color: "white"; font.pixelSize: 11; font.bold: true
                    anchors.centerIn: parent
                }
            }

            // Category icon
            Text {
                text: vidRoot.iconText
                font.pixelSize: 32
                anchors.top: parent.top; anchors.left: parent.left
                anchors.margins: 14
                opacity: 0.5
            }
        }

        // Title
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 18
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.right: parent.right; anchors.rightMargin: 16
            text: vidRoot.title; color: colorTextPrimary; font.bold: true; font.pixelSize: 14
            elide: Text.ElideRight
        }

        scale: vidHover.pressed ? 0.97 : (vidHover.containsMouse ? 1.03 : 1.0)
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        MouseArea {
            id: vidHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        }
    }

    // ═══════════════════════════════════════
    // MODEL & DATA
    // ═══════════════════════════════════════
    ListModel { id: recentModel }

    function refresh() {
        recentModel.clear()
        if (typeof mainCanvas !== "undefined") {
            var items = mainCanvas.getRecentProjects()
            for(var i=0; i<items.length; i++) {
                var it = items[i]
                if (it.thumbnails) {
                    var th = []
                    for(var j=0; j<it.thumbnails.length; j++) th.push({ "modelData": it.thumbnails[j] })
                    it.thumbnails = th
                }
                recentModel.append(it)
            }
        }
    }
    Component.onCompleted: refresh()

    Component {
        id: stackComp
        Item {
            id: stackRoot
            anchors.fill: parent
            property bool isHovered: parent.isHovered || false
            
            function getThumb(idx) {
                if (!thumbnails) return "";
                if (thumbnails.count !== undefined) {
                    return idx < thumbnails.count ? thumbnails.get(idx).modelData : "";
                }
                if (thumbnails.length !== undefined) {
                    return idx < thumbnails.length ? (thumbnails[idx].modelData || thumbnails[idx]) : "";
                }
                return "";
            }

            property int tCount: thumbnails ? (thumbnails.count !== undefined ? thumbnails.count : (thumbnails.length || 0)) : 0
            property bool isEmpty: tCount === 0

            // === CARD 3 (Al fondo) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: tCount > 2
                z: 1; radius: 18; color: "#1c1c22"
                border.color: "#2a2a30"; border.width: 1
                
                // Rotación y offset significativos para que sea MUY visible
                rotation: stackRoot.isHovered ? -18 : -10
                scale: stackRoot.isHovered ? 0.95 : 0.92
                x: stackRoot.isHovered ? -35 : -15
                y: stackRoot.isHovered ? -12 : -6
                
                Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#cc000000"; shadowBlur: 1.0; shadowVerticalOffset: 4 }

                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; mipmap: true; asynchronous: true
                    source: getThumb(2)
                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: m3 }
                }
                Rectangle { id: m3; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            }

            // === CARD 2 (Medio) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: tCount > 1
                z: 2; radius: 18; color: "#1c1c22"
                border.color: "#2a2a30"; border.width: 1
                
                rotation: stackRoot.isHovered ? 14 : 7
                scale: stackRoot.isHovered ? 0.98 : 0.95
                x: stackRoot.isHovered ? 35 : 15
                y: stackRoot.isHovered ? -10 : -4
                
                Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#bb000000"; shadowBlur: 1.0; shadowVerticalOffset: 4 }

                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; mipmap: true; asynchronous: true
                    source: getThumb(1)
                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: m2 }
                }
                Rectangle { id: m2; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            }

            // === CARD 1 (Al frente) ===
            Rectangle {
                anchors.fill: parent; anchors.centerIn: parent
                visible: !isEmpty
                z: 3; radius: 18; color: "#1c1c22"
                
                border.color: stackRoot.isHovered ? "#3c82f6" : "#333"
                border.width: stackRoot.isHovered ? 2 : 1
                
                scale: stackRoot.isHovered ? 1.02 : 1.0
                y: stackRoot.isHovered ? 5 : 0
                
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#99000000"; shadowBlur: 1.0; shadowVerticalOffset: 8 }

                Image {
                    anchors.fill: parent; fillMode: Image.PreserveAspectCrop; mipmap: true; asynchronous: true
                    source: getThumb(0)
                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskSource: m1 }
                }
                Rectangle { id: m1; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            }

            // === ESTADO VACÍO (Carpeta nueva) ===
            Rectangle {
                anchors.fill: parent
                visible: isEmpty
                color: "#1c1c22"; radius: 18
                border.color: stackRoot.isHovered ? "#3c82f6" : "#333"
                border.width: stackRoot.isHovered ? 2 : 1

                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#aa000000"; shadowBlur: 1.0; shadowVerticalOffset: 6 }

                Column {
                    anchors.centerIn: parent; spacing: 8
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📁"; font.pixelSize: 32; opacity: 0.5 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Empty Group"; color: "#555"; font.pixelSize: 11 }
                }
            }
        }
    }
}
