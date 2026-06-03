import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    // Internal States
    property int selectedStopIdx: 0
    property bool isCompact: false // True when shown in Simple Mode bottom popover
    property bool editingMode: false // Toggles between preset library and editor in compact mode
    property string activePresetId: "sunset"
    
    Connections {
        target: targetCanvas
        ignoreUnknownSignals: true
        function onActiveLayerChanged() {
            if (targetCanvas && targetCanvas.activeLayerIndex !== undefined) {
                root.activePresetId = targetCanvas.getLayerGradientMapPreset(targetCanvas.activeLayerIndex)
            }
        }
    }
    
    Component.onCompleted: {
        if (targetCanvas && targetCanvas.activeLayerIndex !== undefined) {
            root.activePresetId = targetCanvas.getLayerGradientMapPreset(targetCanvas.activeLayerIndex)
        }
    }
    
    // Local custom presets (saved by user during session)
    property var customPresets: []
    
    implicitWidth: 320
    implicitHeight: isCompact ? 110 : 380

    // --- HSV Helper functions using QML native Color object ---
    function getSelectedColor() {
        if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return "#ffffff"
        return targetCanvas.gradientStops[root.selectedStopIdx].color
    }
    
    // Convert hex color to native QML color dynamically
    function getH() {
        var c = Qt.color(getSelectedColor())
        return c.hsvHue >= 0 ? c.hsvHue * 360 : 0
    }
    
    function getS() {
        var c = Qt.color(getSelectedColor())
        return c.hsvSaturation * 100
    }
    
    function getV() {
        var c = Qt.color(getSelectedColor())
        return c.hsvValue * 100
    }
    
    function updateStopColorHSV(h, s, v) {
        if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return
        var hexColor = Qt.hsva(h / 360.0, s / 100.0, v / 100.0, 1.0).toString()
        updateStopColorDirectly(hexColor)
    }

    function updateStopColorDirectly(hexColor) {
        if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return
        
        var stops = []
        for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
            stops.push({
                "position": targetCanvas.gradientStops[i].position,
                "color": (i === root.selectedStopIdx) ? hexColor : targetCanvas.gradientStops[i].color
            })
        }
        targetCanvas.gradientStops = stops
    }

    function applyPresetStops(stopsModel, presetId) {
        if (!targetCanvas || !stopsModel) return
        var stops = []
        for (var i = 0; i < stopsModel.length; i++) {
            var p = stopsModel[i]
            var posVal = (p.pos !== undefined) ? p.pos : ((p.position !== undefined) ? p.position : 0.0)
            var colVal = (p.col !== undefined) ? p.col : ((p.color !== undefined) ? p.color : "#ffffff")
            stops.push({
                "position": posVal,
                "color": colVal.toString()
            })
        }
        targetCanvas.gradientStops = stops
        root.selectedStopIdx = 0
        
        // Synchronize with active layer's gradient map preset and ensure it is enabled
        if (targetCanvas.activeLayerIndex !== undefined) {
            targetCanvas.setLayerGradientMapEnabled(targetCanvas.activeLayerIndex, true)
            if (presetId) {
                root.activePresetId = presetId
                targetCanvas.setLayerGradientMapPreset(targetCanvas.activeLayerIndex, presetId)
            }
        }
    }

    // =========================================================================
    // VIEW 1: DOCKABLE STUDIO PANEL (isCompact = false)
    // =========================================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        visible: !root.isCompact

        // Shape/Form Selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text {
                text: "Forma:"
                color: "#8e8e93"
                font.pixelSize: 11
                font.weight: Font.Bold
            }
            
            Item { Layout.fillWidth: true }
            
            Row {
                spacing: 4
                
                Rectangle {
                    width: 64; height: 22; radius: 4
                    color: (targetCanvas && targetCanvas.gradientShape === "linear") ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                    border.color: (targetCanvas && targetCanvas.gradientShape === "linear") ? accentColor : "#2a2a2d"
                    border.width: 1
                    
                    Text {
                        text: "Lineal"
                        color: (targetCanvas && targetCanvas.gradientShape === "linear") ? "white" : "#888"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (targetCanvas) targetCanvas.gradientShape = "linear"
                    }
                }
                
                Rectangle {
                    width: 64; height: 22; radius: 4
                    color: (targetCanvas && targetCanvas.gradientShape === "radial") ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                    border.color: (targetCanvas && targetCanvas.gradientShape === "radial") ? accentColor : "#2a2a2d"
                    border.width: 1
                    
                    Text {
                        text: "Radial"
                        color: (targetCanvas && targetCanvas.gradientShape === "radial") ? "white" : "#888"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (targetCanvas) targetCanvas.gradientShape = "radial"
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#202025" }

        // Slider track
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            
            Text {
                text: "Paradas de Color:"
                color: "#8e8e93"
                font.pixelSize: 11
                font.weight: Font.Bold
            }
            
            Item {
                id: sliderContainerStudio
                Layout.fillWidth: true
                height: 32
                
                Rectangle {
                    id: gradientBarStudio
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    height: 12
                    radius: 3
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    
                    // Checkerboard
                    Rectangle {
                        anchors.fill: parent; z: -2; radius: 2; color: "white"
                        Grid {
                            anchors.fill: parent; columns: 20; rows: 2
                            Repeater {
                                model: 40
                                Rectangle {
                                    width: gradientBarStudio.width / 20; height: 6
                                    color: (index % 2 === 0) ? "#eee" : "#ccc"
                                }
                            }
                        }
                    }
                    
                    // Canvas Live Gradient
                    Rectangle {
                        anchors.fill: parent; z: -1; radius: 2; clip: true
                        Canvas {
                            id: barGradientCanvasStudio
                            anchors.fill: parent
                            property var gradientStops: targetCanvas ? targetCanvas.gradientStops : null
                            onGradientStopsChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                var grad = ctx.createLinearGradient(0, 0, width, 0);
                                if (gradientStops && gradientStops.length > 0) {
                                    for (var i = 0; i < gradientStops.length; i++) {
                                        grad.addColorStop(gradientStops[i].position, gradientStops[i].color);
                                    }
                                } else {
                                    grad.addColorStop(0.0, "#000000"); grad.addColorStop(1.0, "#ffffff");
                                }
                                ctx.fillStyle = grad; ctx.fillRect(0, 0, width, height);
                            }
                            onWidthChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: (mouse) => {
                            if (!targetCanvas) return
                            var posVal = mouse.x / width
                            posVal = Math.max(0.0, Math.min(1.0, posVal))
                            var stops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                stops.push(targetCanvas.gradientStops[i])
                            }
                            stops.push({ "position": posVal, "color": targetCanvas.brushColor.toString() })
                            stops.sort(function(a, b) { return a.position - b.position })
                            targetCanvas.gradientStops = stops
                            for (var j = 0; j < stops.length; j++) {
                                if (Math.abs(stops[j].position - posVal) < 0.01) {
                                    root.selectedStopIdx = j; break
                                }
                            }
                        }
                    }
                }

                // Handles
                Repeater {
                    model: (targetCanvas && targetCanvas.gradientStops) ? targetCanvas.gradientStops : []
                    delegate: Item {
                        id: handleItemStudio
                        x: 8 + (modelData.position * (gradientBarStudio.width)) - width/2
                        y: gradientBarStudio.y + (gradientBarStudio.height - height)/2
                        width: 14; height: 18
                        
                        Rectangle {
                            anchors.fill: parent; radius: 3; color: modelData.color
                            border.color: (root.selectedStopIdx === index) ? "white" : "#000"
                            border.width: (root.selectedStopIdx === index) ? 1.5 : 1
                            Rectangle {
                                width: 4; height: 4; radius: 2; color: "white"
                                anchors.centerIn: parent; visible: root.selectedStopIdx === index
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            drag.target: handleItemStudio; drag.axis: Drag.XAxis
                            drag.minimumX: 8 - handleItemStudio.width/2
                            drag.maximumX: 8 + gradientBarStudio.width - handleItemStudio.width/2
                            onPressed: root.selectedStopIdx = index
                            onPositionChanged: {
                                if (drag.active) {
                                    var relativeX = handleItemStudio.x - 8 + handleItemStudio.width/2
                                    var newPos = relativeX / gradientBarStudio.width
                                    newPos = Math.max(0.0, Math.min(1.0, newPos))
                                    var stops = []
                                    for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                        stops.push({
                                            "position": (i === index) ? newPos : targetCanvas.gradientStops[i].position,
                                            "color": targetCanvas.gradientStops[i].color
                                        })
                                    }
                                    targetCanvas.gradientStops = stops
                                    
                                    if (mouseY > 35 && targetCanvas.gradientStops.length > 2) {
                                        stops.splice(index, 1)
                                        targetCanvas.gradientStops = stops
                                        root.selectedStopIdx = Math.max(0, index - 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Color details & HSV sliders
        Rectangle {
            Layout.fillWidth: true; height: 110; color: "#16161a"; radius: 6; border.color: "#202025"; border.width: 1
            
            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 10
                
                ColumnLayout {
                    spacing: 4
                    Rectangle {
                        width: 32; height: 32; radius: 16; color: root.getSelectedColor()
                        border.color: "white"; border.width: 1
                    }
                    Text {
                        text: "Parada #" + (root.selectedStopIdx + 1)
                        color: "white"; font.pixelSize: 9; font.weight: Font.Bold
                    }
                    Text {
                        text: Math.round((targetCanvas && root.selectedStopIdx < targetCanvas.gradientStops.length ? targetCanvas.gradientStops[root.selectedStopIdx].position : 0.0) * 100) + "%"
                        color: "#888"; font.pixelSize: 8
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    
                    // H Slider
                    RowLayout {
                        spacing: 4
                        Text { text: "H"; color: "#888"; font.pixelSize: 9; font.bold: true }
                        Slider {
                            id: hSliderStudio; Layout.fillWidth: true; height: 16
                            from: 0; to: 360; value: root.getH()
                            onMoved: root.updateStopColorHSV(value, sSliderStudio.value, vSliderStudio.value)
                        }
                    }
                    // S Slider
                    RowLayout {
                        spacing: 4
                        Text { text: "S"; color: "#888"; font.pixelSize: 9; font.bold: true }
                        Slider {
                            id: sSliderStudio; Layout.fillWidth: true; height: 16
                            from: 0; to: 100; value: root.getS()
                            onMoved: root.updateStopColorHSV(hSliderStudio.value, value, vSliderStudio.value)
                        }
                    }
                    // V Slider
                    RowLayout {
                        spacing: 4
                        Text { text: "V"; color: "#888"; font.pixelSize: 9; font.bold: true }
                        Slider {
                            id: vSliderStudio; Layout.fillWidth: true; height: 16
                            from: 0; to: 100; value: root.getV()
                            onMoved: root.updateStopColorHSV(hSliderStudio.value, sSliderStudio.value, value)
                        }
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Rectangle {
                        width: 64; height: 20; radius: 3; color: "#222"
                        Text { text: "Pincel Color"; color: "#aaa"; font.pixelSize: 8; font.bold: true; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (targetCanvas) root.updateStopColorDirectly(targetCanvas.brushColor.toString())
                            }
                        }
                    }
                    Rectangle {
                        width: 64; height: 20; radius: 3; color: "#3a1515"
                        visible: targetCanvas && targetCanvas.gradientStops.length > 2
                        Text { text: "Eliminar"; color: "#ff4444"; font.pixelSize: 8; font.bold: true; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!targetCanvas || targetCanvas.gradientStops.length <= 2) return
                                var stops = []
                                for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                    if (i !== root.selectedStopIdx) stops.push(targetCanvas.gradientStops[i])
                                }
                                targetCanvas.gradientStops = stops
                                root.selectedStopIdx = Math.max(0, root.selectedStopIdx - 1)
                            }
                        }
                    }
                }
            }
        }

        // Gallery List
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            RowLayout {
                Text { text: "Biblioteca:"; color: "#8e8e93"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Rectangle {
                    width: 16; height: 16; radius: 8; color: accentColor
                    Text { text: "+"; color: "white"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 10 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!targetCanvas) return
                            var customStops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                customStops.push({ "position": targetCanvas.gradientStops[i].position, "color": targetCanvas.gradientStops[i].color })
                            }
                            var list = []
                            for (var j = 0; j < root.customPresets.length; j++) list.push(root.customPresets[j])
                            list.push({
                                "id": "custom_" + list.length,
                                "name": "Mi Degradado " + (list.length + 1),
                                "colors": [customStops[0].color, customStops[Math.round(customStops.length/2)].color, customStops[customStops.length - 1].color],
                                "stops": customStops
                            })
                            root.customPresets = list
                        }
                    }
                }
            }

            Flickable {
                id: flickableStudio
                Layout.fillWidth: true; height: 80; clip: true
                contentHeight: presetsGridStudio.height; boundsBehavior: Flickable.StopAtBounds
                
                Grid {
                    id: presetsGridStudio; width: flickableStudio.width; columns: 2; spacing: 4
                    
                    Repeater {
                        model: [
                            { id: "sunset", name: "Sunset", colors: ["#764ba2", "#ff7e5f", "#feb47b"], stops: [{pos: 0.0, col: "#764ba2"}, {pos: 0.5, col: "#ff7e5f"}, {pos: 1.0, col: "#feb47b"}] },
                            { id: "ocean", name: "Ocean", colors: ["#0b1a3c", "#02aab0", "#a0f5be"], stops: [{pos: 0.0, col: "#0b1a3c"}, {pos: 0.5, col: "#02aab0"}, {pos: 1.0, col: "#a0f5be"}] },
                            { id: "forest", name: "Forest", colors: ["#0a2830", "#56ab2f", "#a8ff78"], stops: [{pos: 0.0, col: "#0a2830"}, {pos: 0.5, col: "#56ab2f"}, {pos: 1.0, col: "#a8ff78"}] },
                            { id: "retro", name: "Retro", colors: ["#0a0505", "#f12711", "#f5af19"], stops: [{pos: 0.0, col: "#0a0505"}, {pos: 0.5, col: "#f12711"}, {pos: 1.0, col: "#f5af19"}] },
                            { id: "manga", name: "Manga", colors: ["#0f0f14", "#828287", "#fafafa"], stops: [{pos: 0.0, col: "#0f0f14"}, {pos: 0.5, col: "#828287"}, {pos: 1.0, col: "#fafafa"}] },
                            { id: "neon", name: "Neon", colors: ["#00f6ff", "#ff0076", "#ffe600"], stops: [{pos: 0.0, col: "#00f6ff"}, {pos: 0.5, col: "#ff0076"}, {pos: 1.0, col: "#ffe600"}] },
                            { id: "fire", name: "Fire", colors: ["#110000", "#ff3300", "#ffffaa"], stops: [{pos: 0.0, col: "#110000"}, {pos: 0.5, col: "#ff3300"}, {pos: 1.0, col: "#ffffaa"}] },
                            { id: "ice", name: "Ice", colors: ["#0052d4", "#4364f7", "#6fb1fc"], stops: [{pos: 0.0, col: "#0052d4"}, {pos: 0.5, col: "#4364f7"}, {pos: 1.0, col: "#6fb1fc"}] }
                        ]
                        delegate: Rectangle {
                            width: (parent.width - 4) / 2; height: 32; radius: 4; color: "#16161a"
                            border.color: (root.activePresetId === modelData.id) ? root.accentColor : "#2a2a2d"
                            border.width: (root.activePresetId === modelData.id) ? 1.5 : 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 4; spacing: 6
                                Rectangle {
                                    width: 32; height: 14; radius: 2
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: modelData.colors[0] }
                                        GradientStop { position: 0.5; color: modelData.colors[1] }
                                        GradientStop { position: 1.0; color: modelData.colors[2] }
                                    }
                                }
                                Text { text: modelData.name; color: "#aaa"; font.pixelSize: 8; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPresetStops(modelData.stops, modelData.id) }
                        }
                    }
                    Repeater {
                        model: root.customPresets
                        delegate: Rectangle {
                            width: (parent.width - 4) / 2; height: 32; radius: 4; color: "#1d1d23"
                            border.color: (root.activePresetId === modelData.id) ? root.accentColor : Qt.rgba(1, 1, 1, 0.1)
                            border.width: (root.activePresetId === modelData.id) ? 1.5 : 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 4; spacing: 6
                                Rectangle {
                                    width: 32; height: 14; radius: 2
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: modelData.colors[0] }
                                        GradientStop { position: 0.5; color: modelData.colors[1] }
                                        GradientStop { position: 1.0; color: modelData.colors[2] }
                                    }
                                }
                                Text { text: modelData.name; color: "white"; font.pixelSize: 8; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.applyPresetStops(modelData.stops, modelData.id) }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // VIEW 2: PREMIUM COMPACT POP-OVER (isCompact = true)
    // =========================================================================
    Item {
        anchors.fill: parent
        visible: root.isCompact
        
        // -----------------------------------------------------------
        // SUBVIEW A: PRESET LIBRARY (editingMode = false)
        // -----------------------------------------------------------
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6
            visible: !root.editingMode

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: "Biblioteca de Degradados"
                    color: "white"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                
                // Add currentstops button
                Rectangle {
                    width: 20; height: 20; radius: 10
                    color: "#2a2a30"
                    border.color: Qt.rgba(1,1,1,0.1)
                    Text { text: "+"; color: "white"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!targetCanvas) return
                            var customStops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                customStops.push({ "position": targetCanvas.gradientStops[i].position, "color": targetCanvas.gradientStops[i].color })
                            }
                            var list = []
                            for (var j = 0; j < root.customPresets.length; j++) list.push(root.customPresets[j])
                            list.push({
                                "id": "custom_" + list.length,
                                "name": "Mi Degradado " + (list.length + 1),
                                "colors": [customStops[0].color, customStops[Math.round(customStops.length/2)].color, customStops[customStops.length - 1].color],
                                "stops": customStops
                            })
                            root.customPresets = list
                        }
                    }
                }

                // Edit Button
                Rectangle {
                    width: 58; height: 20; radius: 4
                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                    border.color: accentColor
                    border.width: 1
                    
                    Text {
                        text: "Editar"
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.editingMode = true
                    }
                }

                // Listo Button (Closes simple mode bar)
                Rectangle {
                    width: 46; height: 20; radius: 4
                    color: root.accentColor
                    
                    Text {
                        text: "Listo"
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof mainWindow !== "undefined") mainWindow.showGradientMapUI = false
                            if (typeof canvasPage !== "undefined") {
                                canvasPage.activeToolIdx = canvasPage.lastToolIdx >= 0 ? canvasPage.lastToolIdx : 5
                            } else if (targetCanvas) {
                                targetCanvas.currentTool = "brush"
                            }
                        }
                    }
                }
            }

            // Presets grid in 2 rows, 4 columns
            Flickable {
                id: flickableCompact
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: presetsGridCompact.height
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: presetsGridCompact
                    width: flickableCompact.width
                    columns: 4
                    spacing: 6

                    // Built-in presets
                    Repeater {
                        model: [
                            { id: "sunset", name: "Sunset", colors: ["#764ba2", "#ff7e5f", "#feb47b"], stops: [{pos: 0.0, col: "#764ba2"}, {pos: 0.5, col: "#ff7e5f"}, {pos: 1.0, col: "#feb47b"}] },
                            { id: "ocean", name: "Ocean", colors: ["#0b1a3c", "#02aab0", "#a0f5be"], stops: [{pos: 0.0, col: "#0b1a3c"}, {pos: 0.5, col: "#02aab0"}, {pos: 1.0, col: "#a0f5be"}] },
                            { id: "forest", name: "Forest", colors: ["#0a2830", "#56ab2f", "#a8ff78"], stops: [{pos: 0.0, col: "#0a2830"}, {pos: 0.5, col: "#56ab2f"}, {pos: 1.0, col: "#a8ff78"}] },
                            { id: "retro", name: "Retro", colors: ["#0a0505", "#f12711", "#f5af19"], stops: [{pos: 0.0, col: "#0a0505"}, {pos: 0.5, col: "#f12711"}, {pos: 1.0, col: "#f5af19"}] },
                            { id: "manga", name: "Manga", colors: ["#0f0f14", "#828287", "#fafafa"], stops: [{pos: 0.0, col: "#0f0f14"}, {pos: 0.5, col: "#828287"}, {pos: 1.0, col: "#fafafa"}] },
                            { id: "neon", name: "Neon", colors: ["#00f6ff", "#ff0076", "#ffe600"], stops: [{pos: 0.0, col: "#00f6ff"}, {pos: 0.5, col: "#ff0076"}, {pos: 1.0, col: "#ffe600"}] },
                            { id: "fire", name: "Fire", colors: ["#110000", "#ff3300", "#ffffaa"], stops: [{pos: 0.0, col: "#110000"}, {pos: 0.5, col: "#ff3300"}, {pos: 1.0, col: "#ffffaa"}] },
                            { id: "ice", name: "Ice", colors: ["#0052d4", "#4364f7", "#6fb1fc"], stops: [{pos: 0.0, col: "#0052d4"}, {pos: 0.5, col: "#4364f7"}, {pos: 1.0, col: "#6fb1fc"}] }
                        ]
                        delegate: Rectangle {
                            width: (presetsGridCompact.width - 18) / 4
                            height: 38
                            radius: 6
                            color: "#1d1d23"
                            border.color: (root.activePresetId === modelData.id) ? root.accentColor : Qt.rgba(1, 1, 1, 0.08)
                            border.width: (root.activePresetId === modelData.id) ? 2 : 1

                            // Upper 70% is the linear gradient
                            Rectangle {
                                width: parent.width; height: 26; radius: 5; clip: true
                                anchors.top: parent.top
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: modelData.colors[0] }
                                    GradientStop { position: 0.5; color: modelData.colors[1] }
                                    GradientStop { position: 1.0; color: modelData.colors[2] }
                                }
                            }

                            // Lower 30% is the title
                            Text {
                                text: modelData.name
                                color: "#888"
                                font.pixelSize: 8
                                font.bold: true
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyPresetStops(modelData.stops, modelData.id)
                            }
                        }
                    }

                    // Custom user presets list in grid
                    Repeater {
                        model: root.customPresets
                        delegate: Rectangle {
                            width: (presetsGridCompact.width - 18) / 4
                            height: 38
                            radius: 6
                            color: "#1d1d23"
                            border.color: (root.activePresetId === modelData.id) ? root.accentColor : Qt.rgba(1, 1, 1, 0.08)
                            border.width: (root.activePresetId === modelData.id) ? 2 : 1

                            Rectangle {
                                width: parent.width; height: 26; radius: 5; clip: true
                                anchors.top: parent.top
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: modelData.colors[0] }
                                    GradientStop { position: 0.5; color: modelData.colors[1] }
                                    GradientStop { position: 1.0; color: modelData.colors[2] }
                                }
                            }

                            Text {
                                text: modelData.name
                                color: "white"
                                font.pixelSize: 8
                                font.bold: true
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyPresetStops(modelData.stops, modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // -----------------------------------------------------------
        // SUBVIEW B: GRADIENT EDITOR (editingMode = true)
        // -----------------------------------------------------------
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6
            visible: root.editingMode

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: "Mapa de Degradado"
                    color: "white"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                // Small linear/radial selector
                Row {
                    spacing: 2
                    
                    // Linear
                    Rectangle {
                        width: 44; height: 18; radius: 3
                        color: (targetCanvas && targetCanvas.gradientShape === "linear") ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#222"
                        border.color: (targetCanvas && targetCanvas.gradientShape === "linear") ? accentColor : "#333"
                        border.width: 1
                        Text { text: "Lineal"; color: "white"; font.pixelSize: 8; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; onClicked: if(targetCanvas) targetCanvas.gradientShape = "linear" }
                    }
                    
                    // Radial
                    Rectangle {
                        width: 44; height: 18; radius: 3
                        color: (targetCanvas && targetCanvas.gradientShape === "radial") ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#222"
                        border.color: (targetCanvas && targetCanvas.gradientShape === "radial") ? accentColor : "#333"
                        border.width: 1
                        Text { text: "Radial"; color: "white"; font.pixelSize: 8; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; onClicked: if(targetCanvas) targetCanvas.gradientShape = "radial" }
                    }
                }

                // Done (Back to Library)
                Rectangle {
                    width: 58; height: 20; radius: 4
                    color: "#2a2a30"
                    border.color: Qt.rgba(1,1,1,0.1)
                    border.width: 1
                    
                    Text {
                        text: "Librería"
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.editingMode = false
                    }
                }

                // Listo Button (Closes simple mode bar)
                Rectangle {
                    width: 46; height: 20; radius: 4
                    color: root.accentColor
                    
                    Text {
                        text: "Listo"
                        color: "white"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof mainWindow !== "undefined") mainWindow.showGradientMapUI = false
                            if (typeof canvasPage !== "undefined") {
                                canvasPage.activeToolIdx = canvasPage.lastToolIdx >= 0 ? canvasPage.lastToolIdx : 5
                            } else if (targetCanvas) {
                                targetCanvas.currentTool = "brush"
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; height: 4 } // Spacer

            // Gradient bar track (Clean - no checkerboard)
            Item {
                id: sliderContainerCompact
                Layout.fillWidth: true
                height: 38
                
                Rectangle {
                    id: gradientBarCompact
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    height: 14
                    radius: 7
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1
                    
                    Rectangle {
                        anchors.fill: parent; z: -1; radius: 6; clip: true
                        Canvas {
                            id: barGradientCanvasCompact
                            anchors.fill: parent
                            property var gradientStops: targetCanvas ? targetCanvas.gradientStops : null
                            onGradientStopsChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                var grad = ctx.createLinearGradient(0, 0, width, 0);
                                if (gradientStops && gradientStops.length > 0) {
                                    for (var i = 0; i < gradientStops.length; i++) {
                                        grad.addColorStop(gradientStops[i].position, gradientStops[i].color);
                                    }
                                } else {
                                    grad.addColorStop(0.0, "#000000"); grad.addColorStop(1.0, "#ffffff");
                                }
                                ctx.fillStyle = grad; ctx.fillRect(0, 0, width, height);
                            }
                            onWidthChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: (mouse) => {
                            if (!targetCanvas) return
                            var posVal = mouse.x / width
                            posVal = Math.max(0.0, Math.min(1.0, posVal))
                            var stops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                stops.push(targetCanvas.gradientStops[i])
                            }
                            stops.push({ "position": posVal, "color": targetCanvas.brushColor.toString() })
                            stops.sort(function(a, b) { return a.position - b.position })
                            targetCanvas.gradientStops = stops
                            for (var j = 0; j < stops.length; j++) {
                                if (Math.abs(stops[j].position - posVal) < 0.01) {
                                    root.selectedStopIdx = j; break
                                }
                            }
                        }
                    }
                }

                // Square slider handles (swatches directly on the track)
                Repeater {
                    model: (targetCanvas && targetCanvas.gradientStops) ? targetCanvas.gradientStops : []
                    delegate: Item {
                        id: handleItemCompact
                        x: 8 + (modelData.position * (gradientBarCompact.width)) - width/2
                        y: gradientBarCompact.y + (gradientBarCompact.height - height)/2
                        width: 14; height: 16
                        
                        Rectangle {
                            anchors.fill: parent; radius: 3; color: modelData.color
                            border.color: (root.selectedStopIdx === index) ? "white" : "#000"
                            border.width: (root.selectedStopIdx === index) ? 1.5 : 1
                            
                            // subtle shadow
                            layer.enabled: true
                            
                            Rectangle {
                                width: 4; height: 4; radius: 2; color: "white"
                                anchors.centerIn: parent; visible: root.selectedStopIdx === index
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            drag.target: handleItemCompact; drag.axis: Drag.XAxis
                            drag.minimumX: 8 - handleItemCompact.width/2
                            drag.maximumX: 8 + gradientBarCompact.width - handleItemCompact.width/2
                            onPressed: root.selectedStopIdx = index
                            onPositionChanged: {
                                if (drag.active) {
                                    var relativeX = handleItemCompact.x - 8 + handleItemCompact.width/2
                                    var newPos = relativeX / gradientBarCompact.width
                                    newPos = Math.max(0.0, Math.min(1.0, newPos))
                                    var stops = []
                                    for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                        stops.push({
                                            "position": (i === index) ? newPos : targetCanvas.gradientStops[i].position,
                                            "color": targetCanvas.gradientStops[i].color
                                        })
                                    }
                                    targetCanvas.gradientStops = stops
                                    
                                    // Drag down to delete
                                    if (mouseY > 30 && targetCanvas.gradientStops.length > 2) {
                                        stops.splice(index, 1)
                                        targetCanvas.gradientStops = stops
                                        root.selectedStopIdx = Math.max(0, index - 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // FLOATING COLOR EDITOR POP-OVER (Balloon style, floats above the stop handle)
    // =========================================================================
    Rectangle {
        id: floatingColorPicker
        
        // Show only in Compact + Editing view when a stop is selected
        visible: root.isCompact && root.editingMode && root.selectedStopIdx >= 0 && root.selectedStopIdx < (targetCanvas ? targetCanvas.gradientStops.length : 0)
        
        width: 190
        height: 145
        radius: 12
        z: 10000
        
        // Premium Glassmorphism
        color: "#f51a1a24"
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        
        // Positioning
        x: {
            if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return 0
            var handlePos = targetCanvas.gradientStops[root.selectedStopIdx].position
            var xVal = 8 + (handlePos * gradientBarCompact.width) - width/2
            return Math.max(4, Math.min(root.width - width - 4, xVal))
        }
        y: sliderContainerCompact.y - height - 8
        
        // Arrow Pointer pointing down at handle
        Rectangle {
            width: 10; height: 10
            rotation: 45
            color: "#f51a1a24"
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            z: -1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -5
            
            // Sync horizontal arrow position with handle
            x: {
                var globalHandleX = 8 + (targetCanvas ? targetCanvas.gradientStops[root.selectedStopIdx].position * gradientBarCompact.width : 0)
                var localX = globalHandleX - floatingColorPicker.x - width/2
                return Math.max(10, Math.min(floatingColorPicker.width - width - 10, localX))
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6
            
            // Header: Color Info + Delete Stop Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: root.getSelectedColor()
                    border.color: "white"
                    border.width: 1
                }
                
                Text {
                    text: "Parada #" + (root.selectedStopIdx + 1) + " (" + Math.round((targetCanvas ? targetCanvas.gradientStops[root.selectedStopIdx].position : 0.0) * 100) + "%)"
                    color: "white"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                
                // Delete stop
                Rectangle {
                    width: 44; height: 16; radius: 3
                    color: "#3a1515"
                    border.color: "#ff4444"
                    border.width: 0.5
                    visible: targetCanvas && targetCanvas.gradientStops.length > 2
                    
                    Text {
                        text: "Borrar"
                        color: "#ff4444"
                        font.pixelSize: 7
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!targetCanvas || targetCanvas.gradientStops.length <= 2) return
                            var stops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                if (i !== root.selectedStopIdx) stops.push(targetCanvas.gradientStops[i])
                            }
                            targetCanvas.gradientStops = stops
                            root.selectedStopIdx = Math.max(0, root.selectedStopIdx - 1)
                        }
                    }
                }
            }

            // HSV Sliders
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                
                // H
                RowLayout {
                    spacing: 4
                    Text { text: "H"; color: "#888"; font.pixelSize: 8; font.bold: true }
                    Slider {
                        id: hSliderCompact; Layout.fillWidth: true; height: 12
                        from: 0; to: 360; value: root.getH()
                        onMoved: root.updateStopColorHSV(value, sSliderCompact.value, vSliderCompact.value)
                        
                        // Custom styled colorful track for Hue
                        background: Rectangle {
                            implicitWidth: 100; implicitHeight: 4; radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#ff0000" }
                                GradientStop { position: 0.17; color: "#ffff00" }
                                GradientStop { position: 0.33; color: "#00ff00" }
                                GradientStop { position: 0.5; color: "#00ffff" }
                                GradientStop { position: 0.67; color: "#0000ff" }
                                GradientStop { position: 0.83; color: "#ff00ff" }
                                GradientStop { position: 1.0; color: "#ff0000" }
                            }
                        }
                        handle: Rectangle {
                            x: hSliderCompact.leftPadding + hSliderCompact.visualPosition * (hSliderCompact.availableWidth - width)
                            y: hSliderCompact.topPadding + hSliderCompact.availableHeight / 2 - height / 2
                            implicitWidth: 8; implicitHeight: 8; radius: 4; color: "white"; border.color: "#888"; border.width: 1
                        }
                    }
                }

                // S
                RowLayout {
                    spacing: 4
                    Text { text: "S"; color: "#888"; font.pixelSize: 8; font.bold: true }
                    Slider {
                        id: sSliderCompact; Layout.fillWidth: true; height: 12
                        from: 0; to: 100; value: root.getS()
                        onMoved: root.updateStopColorHSV(hSliderCompact.value, value, vSliderCompact.value)
                        
                        background: Rectangle {
                            implicitWidth: 100; implicitHeight: 4; radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#ffffff" }
                                GradientStop { position: 1.0; color: Qt.hsva(hSliderCompact.value / 360.0, 1.0, 1.0, 1.0) }
                            }
                        }
                        handle: Rectangle {
                            x: sSliderCompact.leftPadding + sSliderCompact.visualPosition * (sSliderCompact.availableWidth - width)
                            y: sSliderCompact.topPadding + sSliderCompact.availableHeight / 2 - height / 2
                            implicitWidth: 8; implicitHeight: 8; radius: 4; color: "white"; border.color: "#888"; border.width: 1
                        }
                    }
                }

                // V
                RowLayout {
                    spacing: 4
                    Text { text: "V"; color: "#888"; font.pixelSize: 8; font.bold: true }
                    Slider {
                        id: vSliderCompact; Layout.fillWidth: true; height: 12
                        from: 0; to: 100; value: root.getV()
                        onMoved: root.updateStopColorHSV(hSliderCompact.value, sSliderCompact.value, value)
                        
                        background: Rectangle {
                            implicitWidth: 100; implicitHeight: 4; radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#000000" }
                                GradientStop { position: 1.0; color: Qt.hsva(hSliderCompact.value / 360.0, sSliderCompact.visualPosition, 1.0, 1.0) }
                            }
                        }
                        handle: Rectangle {
                            x: vSliderCompact.leftPadding + vSliderCompact.visualPosition * (vSliderCompact.availableWidth - width)
                            y: vSliderCompact.topPadding + vSliderCompact.visualPosition * 0.5 + vSliderCompact.availableHeight / 2 - height / 2
                            implicitWidth: 8; implicitHeight: 8; radius: 4; color: "white"; border.color: "#888"; border.width: 1
                        }
                    }
                }
            }

            // Quick Swatches (Palette)
            Row {
                spacing: 5
                Layout.alignment: Qt.AlignHCenter
                
                Repeater {
                    model: ["#ff3b30", "#ff9500", "#ffcc00", "#4cd964", "#5ac8fa", "#007aff", "#5856d6", "#ffffff", "#8e8e93", "#000000"]
                    delegate: Rectangle {
                        width: 13; height: 13; radius: 6.5
                        color: modelData
                        border.color: root.getSelectedColor() === modelData ? "white" : "transparent"
                        border.width: 1
                        
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.updateStopColorDirectly(modelData)
                        }
                    }
                }
            }
        }
    }
}
