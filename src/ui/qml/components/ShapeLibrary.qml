import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ═══════════════════════════════════════════════════════════
// ShapeLibrary — Premium modal panel for shape tools,
// comic panel layouts, and speech bubble forms.
// ═══════════════════════════════════════════════════════════
Rectangle {
    id: root
    color: "#0d0d0f"
    radius: 24
    border.color: "#1a1a1c"
    border.width: 1
    clip: true

    property var targetCanvas: null
    property var comicOverlay: null
    property color accentColor: "#6366f1"

    signal closeRequested()
    signal shapeSelected(string shapeName)
    signal panelLayoutRequested(string layoutType)
    signal bubbleRequested(string bubbleType)

    property int selectedCategory: 0

    function iconPath(name) {
        return "image://icons/" + name + ".svg"
    }

    // ── Shape items per category ──
    ListModel {
        id: shapesModel
        ListElement { itemId: "rect";    label: "Rectangle";  desc: "Draw rectangle shape";       iconName: "shapes" }
        ListElement { itemId: "ellipse"; label: "Ellipse";    desc: "Draw ellipse or circle";     iconName: "shapes" }
        ListElement { itemId: "line";    label: "Line";       desc: "Draw straight line";         iconName: "shapes" }
    }

    ListModel {
        id: panelsModel
        ListElement { itemId: "panel_single";  label: "Full Page";    desc: "Single full-page panel";        iconName: "panel_single" }
        ListElement { itemId: "panel_2col";    label: "2 Columns";    desc: "Two vertical panels";           iconName: "panel_2col" }
        ListElement { itemId: "panel_2row";    label: "2 Rows";       desc: "Two horizontal panels";         iconName: "panel_2row" }
        ListElement { itemId: "panel_grid";    label: "Grid 3+2";     desc: "3 top + 2 bottom panels";       iconName: "panel_grid" }
        ListElement { itemId: "panel_manga";   label: "Manga";        desc: "Banner + L-shape + 2 side";     iconName: "panel_manga" }
        ListElement { itemId: "panel_4panel";  label: "4 Panels";     desc: "Staggered classic layout";      iconName: "panel_4panel" }
        ListElement { itemId: "panel_strip";   label: "Strip";        desc: "3 horizontal strips";           iconName: "panel_strip" }
    }

    ListModel {
        id: bubblesModel
        ListElement { itemId: "bubble_speech";    label: "Speech";     desc: "Oval dialog with tail pointer";    iconName: "bubble_speech" }
        ListElement { itemId: "bubble_thought";   label: "Thought";    desc: "Cloud bubble with dots";           iconName: "bubble_thought" }
        ListElement { itemId: "bubble_shout";     label: "Shout";      desc: "Starburst for emphasis";           iconName: "bubble_shout" }
        ListElement { itemId: "bubble_narration"; label: "Narration";  desc: "Rectangular text box";             iconName: "bubble_narration" }
    }

    function currentModel() {
        if (selectedCategory === 0) return shapesModel
        if (selectedCategory === 1) return panelsModel
        return bubblesModel
    }

    function currentTitle() {
        if (selectedCategory === 0) return "Shapes"
        if (selectedCategory === 1) return "Panels"
        return "Bubbles"
    }

    function currentCount() {
        return currentModel().count
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ══════ LEFT: Content Area ══════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Header ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56

                    Text {
                        text: currentTitle()
                        color: "white"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: currentCount() + " items"
                        color: "#555"
                        font.pixelSize: 11
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // ── Separator ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    color: "#1e1e22"
                }

                // ── Scrollable Grid ──
                Flickable {
                    id: gridFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 12
                    contentWidth: width
                    contentHeight: gridCol.height
                    clip: true
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        contentItem: Rectangle { color: "#333"; radius: 2 }
                    }

                    Column {
                        id: gridCol
                        width: gridFlick.width - 8
                        spacing: 10

                        // ── SHAPES CATEGORY ──
                        Repeater {
                            model: selectedCategory === 0 ? shapesModel : 0

                            delegate: Rectangle {
                                id: shpCard
                                width: gridCol.width
                                height: 72
                                radius: 14
                                color: shpCard._applied ? "#1a3a1a" : (shpMa.containsMouse ? "#1e1e26" : "#141416")
                                border.color: shpCard._applied ? "#4ade80" : (shpMa.containsMouse ? accentColor : "#222")
                                border.width: shpMa.containsMouse || shpCard._applied ? 2 : 1
                                
                                property bool _applied: false

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 14

                                    // Icon box
                                    Rectangle {
                                        width: 48; height: 48; radius: 12
                                        color: "#1a1a20"
                                        anchors.verticalCenter: parent.verticalCenter

                                        // Shape preview
                                        Canvas {
                                            id: shpCvs
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                var w = width, h = height
                                                ctx.clearRect(0,0,w,h)
                                                ctx.strokeStyle = shpMa.containsMouse ? accentColor.toString() : "white"
                                                ctx.lineWidth = 2
                                                if (model.itemId === "rect") {
                                                    ctx.strokeRect(2, 4, w-4, h-8)
                                                } else if (model.itemId === "ellipse") {
                                                    ctx.beginPath()
                                                    ctx.ellipse(2, 2, w-4, h-4)
                                                    ctx.stroke()
                                                } else {
                                                    ctx.beginPath()
                                                    ctx.moveTo(2, h-2)
                                                    ctx.lineTo(w-2, 2)
                                                    ctx.stroke()
                                                }
                                            }
                                            Component.onCompleted: requestPaint()
                                            Connections {
                                                target: shpMa
                                                function onContainsMouseChanged() { shpCvs.requestPaint() }
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3
                                        Text {
                                            text: model.label
                                            color: shpMa.containsMouse ? "white" : "#ccc"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            text: model.desc
                                            color: "#666"
                                            font.pixelSize: 11
                                        }
                                    }
                                    
                                    // Applied checkmark
                                    Text {
                                        visible: shpCard._applied
                                        text: "✓"
                                        color: "#4ade80"
                                        font.pixelSize: 18
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: shpMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        console.log("[ShapeLibrary] Shape clicked: " + model.itemId)
                                        shpCard._applied = true
                                        root.shapeSelected(model.itemId)
                                    }
                                }
                            }
                        }

                        // ── PANELS CATEGORY ──
                        Flow {
                            width: gridCol.width
                            spacing: 10
                            visible: selectedCategory === 1

                            Repeater {
                                model: selectedCategory === 1 ? panelsModel : 0

                                delegate: Rectangle {
                                    width: (gridCol.width - 10) / 2
                                    height: 140
                                    radius: 14
                                    color: pnlMa.containsMouse ? "#1e1e26" : "#141416"
                                    border.color: pnlMa.containsMouse ? accentColor : "#222"
                                    border.width: pnlMa.containsMouse ? 2 : 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        // Panel preview
                                        Rectangle {
                                            width: parent.width
                                            height: 80
                                            radius: 8
                                            color: "#222"
                                            clip: true

                                            Canvas {
                                                id: pnlCvs
                                                anchors.fill: parent
                                                anchors.margins: 6

                                                onPaint: {
                                                    var ctx = getContext("2d")
                                                    var w = width, h = height
                                                    ctx.clearRect(0,0,w,h)

                                                    var mx = 5, my = 5
                                                    var iw = w - 2*mx, ih = h - 2*my
                                                    var g = 3

                                                    ctx.fillStyle = "#f5f5f0"
                                                    ctx.strokeStyle = pnlMa.containsMouse ? accentColor.toString() : "#888"
                                                    ctx.lineWidth = 1.5

                                                    var panels = getPanels(model.itemId, mx, my, iw, ih, g)
                                                    for (var i = 0; i < panels.length; i++) {
                                                        var p = panels[i]
                                                        ctx.fillRect(p.x, p.y, p.w, p.h)
                                                        ctx.strokeRect(p.x, p.y, p.w, p.h)
                                                    }
                                                }

                                                Component.onCompleted: requestPaint()
                                                Connections {
                                                    target: pnlMa
                                                    function onContainsMouseChanged() { pnlCvs.requestPaint() }
                                                }
                                            }
                                        }

                                        Text {
                                            text: model.label
                                            color: pnlMa.containsMouse ? "white" : "#ccc"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            width: parent.width
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.desc
                                            color: "#555"
                                            font.pixelSize: 9
                                            width: parent.width
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: pnlMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            console.log("[ShapeLibrary] Panel clicked: " + model.itemId)
                                            root.panelLayoutRequested(model.itemId.replace("panel_", ""))
                                        }
                                    }
                                }
                            }
                        }

                        // ── BUBBLES CATEGORY ──
                        Flow {
                            width: gridCol.width
                            spacing: 10
                            visible: selectedCategory === 2

                            Repeater {
                                model: selectedCategory === 2 ? bubblesModel : 0

                                delegate: Rectangle {
                                    width: (gridCol.width - 10) / 2
                                    height: 140
                                    radius: 14
                                    color: bubMa.containsMouse ? "#1e1e26" : "#141416"
                                    border.color: bubMa.containsMouse ? accentColor : "#222"
                                    border.width: bubMa.containsMouse ? 2 : 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        // Bubble preview
                                        Rectangle {
                                            width: parent.width
                                            height: 80
                                            radius: 8
                                            color: "#1a1a20"
                                            clip: true

                                            Canvas {
                                                id: bubCvs
                                                anchors.fill: parent
                                                anchors.margins: 8

                                                onPaint: {
                                                    var ctx = getContext("2d")
                                                    var w = width, h = height
                                                    ctx.clearRect(0,0,w,h)

                                                    var bType = model.itemId.replace("bubble_", "")

                                                    ctx.fillStyle = "white"
                                                    ctx.strokeStyle = bubMa.containsMouse ? accentColor.toString() : "#888"
                                                    ctx.lineWidth = 2
                                                    ctx.lineJoin = "round"

                                                    var cx = w/2, cy = h/2

                                                    if (bType === "speech") {
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.1, h*0.05, w*0.8, h*0.6)
                                                        ctx.fill(); ctx.stroke()
                                                        // Tail
                                                        ctx.beginPath()
                                                        ctx.moveTo(w*0.25, h*0.58)
                                                        ctx.lineTo(w*0.15, h*0.92)
                                                        ctx.lineTo(w*0.45, h*0.58)
                                                        ctx.fillStyle = "white"
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "thought") {
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.1, h*0.05, w*0.8, h*0.55)
                                                        ctx.fill(); ctx.stroke()
                                                        // Dots
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.22, h*0.68, 8, 8)
                                                        ctx.fill(); ctx.stroke()
                                                        ctx.beginPath()
                                                        ctx.ellipse(w*0.14, h*0.8, 5, 5)
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "shout") {
                                                        ctx.beginPath()
                                                        var pts = 12
                                                        for (var j = 0; j < pts; j++) {
                                                            var a = (j/pts)*Math.PI*2 - Math.PI/2
                                                            var r = (j%2===0) ? 1.0 : 0.65
                                                            var px = cx + Math.cos(a)*w*0.4*r
                                                            var py = cy + Math.sin(a)*h*0.4*r
                                                            if (j===0) ctx.moveTo(px,py); else ctx.lineTo(px,py)
                                                        }
                                                        ctx.closePath()
                                                        ctx.fill(); ctx.stroke()
                                                    } else if (bType === "narration") {
                                                        ctx.fillRect(w*0.05, h*0.1, w*0.9, h*0.8)
                                                        ctx.strokeRect(w*0.05, h*0.1, w*0.9, h*0.8)
                                                        // Text lines
                                                        ctx.strokeStyle = "#bbb"
                                                        ctx.lineWidth = 1
                                                        ctx.beginPath()
                                                        ctx.moveTo(w*0.2, h*0.4)
                                                        ctx.lineTo(w*0.8, h*0.4)
                                                        ctx.stroke()
                                                        ctx.beginPath()
                                                        ctx.moveTo(w*0.2, h*0.58)
                                                        ctx.lineTo(w*0.65, h*0.58)
                                                        ctx.stroke()
                                                    }
                                                }

                                                Component.onCompleted: requestPaint()
                                                Connections {
                                                    target: bubMa
                                                    function onContainsMouseChanged() { bubCvs.requestPaint() }
                                                }
                                            }
                                        }

                                        Text {
                                            text: model.label
                                            color: bubMa.containsMouse ? "white" : "#ccc"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            width: parent.width
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.desc
                                            color: "#555"
                                            font.pixelSize: 9
                                            width: parent.width
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    MouseArea {
                                        id: bubMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            console.log("[ShapeLibrary] Bubble clicked: " + model.itemId)
                                            root.bubbleRequested(model.itemId.replace("bubble_", ""))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ══════ RIGHT: Category Sidebar ══════
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 64
            color: "#0a0a0c"

            Column {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                spacing: 6

                // Shapes category
                Rectangle {
                    width: 52; height: 54
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 14
                    color: selectedCategory === 0 ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : (cat0ma.containsMouse ? "#1a1a1e" : "transparent")
                    border.color: selectedCategory === 0 ? accentColor : "transparent"
                    border.width: selectedCategory === 0 ? 1.5 : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Image {
                            source: root.iconPath("shapes")
                            width: 22; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: selectedCategory === 0 ? 1.0 : 0.5
                        }
                        Text {
                            text: "Shapes"
                            font.pixelSize: 8; font.weight: Font.Medium
                            color: selectedCategory === 0 ? accentColor : "#666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    MouseArea {
                        id: cat0ma; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = 0
                    }
                }

                // Panels category
                Rectangle {
                    width: 52; height: 54
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 14
                    color: selectedCategory === 1 ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : (cat1ma.containsMouse ? "#1a1a1e" : "transparent")
                    border.color: selectedCategory === 1 ? accentColor : "transparent"
                    border.width: selectedCategory === 1 ? 1.5 : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Image {
                            source: root.iconPath("panel_grid")
                            width: 22; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: selectedCategory === 1 ? 1.0 : 0.5
                        }
                        Text {
                            text: "Panels"
                            font.pixelSize: 8; font.weight: Font.Medium
                            color: selectedCategory === 1 ? accentColor : "#666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    MouseArea {
                        id: cat1ma; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = 1
                    }
                }

                // Bubbles category
                Rectangle {
                    width: 52; height: 54
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 14
                    color: selectedCategory === 2 ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : (cat2ma.containsMouse ? "#1a1a1e" : "transparent")
                    border.color: selectedCategory === 2 ? accentColor : "transparent"
                    border.width: selectedCategory === 2 ? 1.5 : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Image {
                            source: root.iconPath("bubble_speech")
                            width: 22; height: 22
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: selectedCategory === 2 ? 1.0 : 0.5
                        }
                        Text {
                            text: "Bubbles"
                            font.pixelSize: 8; font.weight: Font.Medium
                            color: selectedCategory === 2 ? accentColor : "#666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    MouseArea {
                        id: cat2ma; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = 2
                    }
                }
            }
        }
    }

    // ── Helper: compute panel rects for preview ──
    function getPanels(id, mx, my, iw, ih, g) {
        var t = id.replace("panel_", "")
        if (t === "single") return [{x:mx,y:my,w:iw,h:ih}]
        if (t === "2col") {
            var cw=(iw-g)/2
            return [{x:mx,y:my,w:cw,h:ih},{x:mx+cw+g,y:my,w:cw,h:ih}]
        }
        if (t === "2row") {
            var rh=(ih-g)/2
            return [{x:mx,y:my,w:iw,h:rh},{x:mx,y:my+rh+g,w:iw,h:rh}]
        }
        if (t === "grid") {
            var th=(ih-g)*0.45,bh=ih-th-g,c3=(iw-2*g)/3,c2=(iw-g)/2
            return [{x:mx,y:my,w:c3,h:th},{x:mx+c3+g,y:my,w:c3,h:th},{x:mx+2*(c3+g),y:my,w:c3,h:th},
                    {x:mx,y:my+th+g,w:c2,h:bh},{x:mx+c2+g,y:my+th+g,w:c2,h:bh}]
        }
        if (t === "manga") {
            var th2=ih*0.3,bh2=ih-th2-g,lw=iw*0.5,rw=iw-lw-g,rh1=(bh2-g)*0.55,rh2=bh2-rh1-g
            return [{x:mx,y:my,w:iw,h:th2},{x:mx,y:my+th2+g,w:lw,h:bh2},
                    {x:mx+lw+g,y:my+th2+g,w:rw,h:rh1},{x:mx+lw+g,y:my+th2+g+rh1+g,w:rw,h:rh2}]
        }
        if (t === "4panel") {
            var c1w=iw*0.45,c2w=iw-c1w-g,r1t=ih*0.35,r1b=ih-r1t-g,r2t=ih*0.55,r2b=ih-r2t-g
            return [{x:mx,y:my,w:c1w,h:r1t},{x:mx+c1w+g,y:my,w:c2w,h:r2t},
                    {x:mx,y:my+r1t+g,w:c1w,h:r1b},{x:mx+c1w+g,y:my+r2t+g,w:c2w,h:r2b}]
        }
        if (t === "strip") {
            var s1=ih*0.38,s2=ih*0.35,s3=ih-s1-s2-2*g
            return [{x:mx,y:my,w:iw,h:s1},{x:mx,y:my+s1+g,w:iw,h:s2},{x:mx,y:my+s1+s2+2*g,w:iw,h:s3}]
        }
        return [{x:mx,y:my,w:iw,h:ih}]
    }
}
