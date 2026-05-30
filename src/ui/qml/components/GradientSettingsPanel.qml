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
    
    // Local custom presets (saved by user during session)
    property var customPresets: []

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.isCompact ? 8 : 12
        spacing: root.isCompact ? 8 : 14
        
        // ── SECTION 1: SHAPE / FORMA ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !root.isCompact
            
            Text {
                text: "Forma del Degradado:"
                color: "#8e8e93"
                font.pixelSize: 11
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            Row {
                spacing: 4
                
                // Linear Button
                Rectangle {
                    width: 64; height: 26; radius: 4
                    color: (targetCanvas && targetCanvas.gradientShape === "linear") ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                    border.color: (targetCanvas && targetCanvas.gradientShape === "linear") ? accentColor : "#2a2a2d"
                    border.width: 1
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "▰"; color: (targetCanvas && targetCanvas.gradientShape === "linear") ? "white" : "#888"; font.pixelSize: 10 }
                        Text { text: "Lineal"; color: (targetCanvas && targetCanvas.gradientShape === "linear") ? "white" : "#888"; font.pixelSize: 10; font.weight: Font.DemiBold }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (targetCanvas) targetCanvas.gradientShape = "linear"
                    }
                }
                
                // Radial Button
                Rectangle {
                    width: 64; height: 26; radius: 4
                    color: (targetCanvas && targetCanvas.gradientShape === "radial") ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "#16161a"
                    border.color: (targetCanvas && targetCanvas.gradientShape === "radial") ? accentColor : "#2a2a2d"
                    border.width: 1
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "◉"; color: (targetCanvas && targetCanvas.gradientShape === "radial") ? "white" : "#888"; font.pixelSize: 10 }
                        Text { text: "Radial"; color: (targetCanvas && targetCanvas.gradientShape === "radial") ? "white" : "#888"; font.pixelSize: 10; font.weight: Font.DemiBold }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (targetCanvas) targetCanvas.gradientShape = "radial"
                    }
                }
            }
        }
        
        // ── SECTION 2: THE INTERACTIVE GRADIENT SLIDER (COLOR STOPS) ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            RowLayout {
                Layout.fillWidth: true
                visible: !root.isCompact
                Text { text: "Editor de Paradas"; color: "#8e8e93"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                Text { text: "Doble clic para añadir · Arrastrar abajo para borrar"; color: "#555"; font.pixelSize: 9 }
            }
            
            // Gradient Track and Stops container
            Item {
                id: sliderContainer
                Layout.fillWidth: true
                height: 38
                
                // 1. Gradient Bar
                Rectangle {
                    id: gradientBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    height: 16
                    radius: 4
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    
                    // Checkerboard background for transparency preview
                    Rectangle {
                        anchors.fill: parent
                        z: -2
                        radius: 3
                        color: "white"
                        
                        Grid {
                            anchors.fill: parent
                            columns: 20
                            rows: 2
                            Repeater {
                                model: 40
                                Rectangle {
                                    width: gradientBar.width / 20
                                    height: 8
                                    color: (index % 2 === 0) ? "#eee" : "#ccc"
                                }
                            }
                        }
                    }
                    
                    // Live Gradient Fill
                    Rectangle {
                        anchors.fill: parent
                        z: -1
                        radius: 3
                        gradient: Gradient {
                            id: barGradient
                            Repeater {
                                model: (targetCanvas && targetCanvas.gradientStops) ? targetCanvas.gradientStops : []
                                delegate: GradientStop {
                                    position: modelData.position
                                    color: modelData.color
                                }
                            }
                        }
                    }
                    
                    // Double click to add stop
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: (mouse) => {
                            if (!targetCanvas) return
                            var posVal = mouse.x / width
                            posVal = Math.max(0.0, Math.min(1.0, posVal))
                            
                            // Get active stops
                            var stops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                stops.push(targetCanvas.gradientStops[i])
                            }
                            
                            // Use canvas active brushColor
                            stops.push({
                                "position": posVal,
                                "color": targetCanvas.brushColor.toString()
                            })
                            
                            // Sort stops by position
                            stops.sort(function(a, b) { return a.position - b.position })
                            targetCanvas.gradientStops = stops
                            
                            // Select the newly added stop
                            for (var j = 0; j < stops.length; j++) {
                                if (Math.abs(stops[j].position - posVal) < 0.01) {
                                    root.selectedStopIdx = j
                                    break
                                }
                            }
                        }
                    }
                }
                
                // 2. Interactive Stops (Handles)
                Repeater {
                    model: (targetCanvas && targetCanvas.gradientStops) ? targetCanvas.gradientStops : []
                    
                    delegate: Item {
                        id: handleItem
                        // Position handle horizontally based on position property
                        x: 8 + (modelData.position * (gradientBar.width)) - width/2
                        y: gradientBar.y + (gradientBar.height - height)/2
                        width: 14
                        height: 18
                        
                        // Handle shape: a small square swatch hanging below the track or pointing up
                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: modelData.color
                            border.color: (root.selectedStopIdx === index) ? "white" : "#000"
                            border.width: (root.selectedStopIdx === index) ? 1.5 : 1
                            
                            // Selected indicator dot
                            Rectangle {
                                width: 4; height: 4; radius: 2
                                color: "white"
                                anchors.centerIn: parent
                                visible: root.selectedStopIdx === index
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            drag.target: handleItem
                            drag.axis: Drag.XAxis
                            drag.minimumX: 8 - handleItem.width/2
                            drag.maximumX: 8 + gradientBar.width - handleItem.width/2
                            
                            onPressed: {
                                root.selectedStopIdx = index
                            }
                            
                            onPositionChanged: {
                                if (drag.active) {
                                    var relativeX = handleItem.x - 8 + handleItem.width/2
                                    var newPos = relativeX / gradientBar.width
                                    newPos = Math.max(0.0, Math.min(1.0, newPos))
                                    
                                    // Update positions model
                                    var stops = []
                                    for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                        stops.push({
                                            "position": (i === index) ? newPos : targetCanvas.gradientStops[i].position,
                                            "color": targetCanvas.gradientStops[i].color
                                        })
                                    }
                                    targetCanvas.gradientStops = stops
                                    
                                    // Drag down to delete gesture (threshold: 35px)
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
        
        // ── SECTION 3: THE INLINE COLOR STOP EDITOR (Sliders/Actions) ──
        Rectangle {
            Layout.fillWidth: true
            height: root.isCompact ? 48 : 100
            color: "#16161a"
            radius: 6
            border.color: "#2a2a2d"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                
                // Color preview circular swatch
                Rectangle {
                    width: root.isCompact ? 28 : 44
                    height: width; radius: width/2
                    color: {
                        if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return "transparent"
                        return targetCanvas.gradientStops[root.selectedStopIdx].color
                    }
                    border.color: "white"
                    border.width: 1
                }
                
                // Stop controls & Color Editor sliders
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Text {
                            text: "Parada #" + (root.selectedStopIdx + 1) + " (" + Math.round((targetCanvas && root.selectedStopIdx < targetCanvas.gradientStops.length ? targetCanvas.gradientStops[root.selectedStopIdx].position : 0.0) * 100) + "%)"
                            color: "white"
                            font.pixelSize: root.isCompact ? 9 : 10
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }
                        
                        // Use active brushColor button
                        Rectangle {
                            width: 78; height: 18; radius: 3
                            color: "#2a2a2d"
                            border.color: "#3e3e42"
                            Text {
                                text: "Usar Pincel Color"; color: "#aaa"; font.pixelSize: 8; anchors.centerIn: parent; font.weight: Font.DemiBold
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return
                                    var stops = []
                                    for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                        stops.push({
                                            "position": targetCanvas.gradientStops[i].position,
                                            "color": (i === root.selectedStopIdx) ? targetCanvas.brushColor.toString() : targetCanvas.gradientStops[i].color
                                        })
                                    }
                                    targetCanvas.gradientStops = stops
                                }
                            }
                        }
                        
                        // Delete stop button
                        Rectangle {
                            width: 48; height: 18; radius: 3
                            color: "#3a1515"
                            border.color: "#ff4444"
                            visible: targetCanvas && targetCanvas.gradientStops.length > 2
                            Text {
                                text: "Borrar"; color: "#ff4444"; font.pixelSize: 8; anchors.centerIn: parent; font.weight: Font.Bold
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!targetCanvas || targetCanvas.gradientStops.length <= 2) return
                                    var stops = []
                                    for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                        if (i !== root.selectedStopIdx) {
                                            stops.push(targetCanvas.gradientStops[i])
                                        }
                                    }
                                    targetCanvas.gradientStops = stops
                                    root.selectedStopIdx = Math.max(0, root.selectedStopIdx - 1)
                                }
                            }
                        }
                    }
                    
                    // HSV Adjustments (Hue Slider)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: !root.isCompact
                        
                        Text { text: "H:"; color: "#6b7280"; font.pixelSize: 9; font.bold: true }
                        
                        Slider {
                            id: hSlider
                            Layout.fillWidth: true
                            height: 12
                            from: 0; to: 360
                            value: {
                                if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return 0
                                return QColor(targetCanvas.gradientStops[root.selectedStopIdx].color).hsvHue() * 360
                            }
                            onMoved: {
                                updateSelectedStopColor()
                            }
                        }
                    }
                    
                    // Saturation Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: !root.isCompact
                        
                        Text { text: "S:"; color: "#6b7280"; font.pixelSize: 9; font.bold: true }
                        
                        Slider {
                            id: sSlider
                            Layout.fillWidth: true
                            height: 12
                            from: 0; to: 100
                            value: {
                                if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return 0
                                return QColor(targetCanvas.gradientStops[root.selectedStopIdx].color).hsvSaturation() * 100
                            }
                            onMoved: {
                                updateSelectedStopColor()
                            }
                        }
                    }
                    
                    // Brightness Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: !root.isCompact
                        
                        Text { text: "V:"; color: "#6b7280"; font.pixelSize: 9; font.bold: true }
                        
                        Slider {
                            id: vSlider
                            Layout.fillWidth: true
                            height: 12
                            from: 0; to: 100
                            value: {
                                if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return 0
                                return QColor(targetCanvas.gradientStops[root.selectedStopIdx].color).hsvValue() * 100
                            }
                            onMoved: {
                                updateSelectedStopColor()
                            }
                        }
                    }
                    
                    // Compact mode color choices (Quick Grid)
                    Row {
                        spacing: 4
                        visible: root.isCompact
                        Layout.fillWidth: true
                        
                        Repeater {
                            model: ["#ff0000", "#ff7f00", "#ffff00", "#00ff00", "#0000ff", "#4b0082", "#8f00ff", "#ffffff", "#888888", "#000000"]
                            delegate: Rectangle {
                                width: 14; height: 14; radius: 7
                                color: modelData
                                border.color: "white"
                                border.width: 1
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        updateStopColorDirectly(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // ── SECTION 4: PRESETS GALLERY (Sunset, Ocean, Forest, etc.) ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Biblioteca de Degradados"; color: "#8e8e93"; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                
                // Add current custom stops to library
                Rectangle {
                    width: 20; height: 20; radius: 10
                    color: accentColor
                    Text { text: "+"; color: "white"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 12 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!targetCanvas) return
                            var customStops = []
                            for (var i = 0; i < targetCanvas.gradientStops.length; i++) {
                                customStops.push({
                                    "position": targetCanvas.gradientStops[i].position,
                                    "color": targetCanvas.gradientStops[i].color
                                })
                            }
                            var list = []
                            for (var j = 0; j < root.customPresets.length; j++) {
                                list.push(root.customPresets[j])
                            }
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
            
            // Grid of Presets
            Flickable {
                Layout.fillWidth: true
                height: root.isCompact ? 36 : 94
                contentHeight: presetsGrid.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                Grid {
                    id: presetsGrid
                    width: parent.width
                    columns: root.isCompact ? 4 : 2
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
                            width: root.isCompact ? (parent.width - 18)/4 : (parent.width - 6)/2
                            height: root.isCompact ? 32 : 36
                            radius: 4
                            color: "#16161a"
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 6
                                
                                Rectangle {
                                    width: root.isCompact ? 38 : 28
                                    height: 14
                                    radius: 2
                                    Layout.alignment: Qt.AlignVCenter
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: modelData.colors[0] }
                                        GradientStop { position: 0.5; color: modelData.colors[1] }
                                        GradientStop { position: 1.0; color: modelData.colors[2] }
                                    }
                                }
                                
                                Text {
                                    text: modelData.name
                                    color: "#aaa"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    visible: !root.isCompact
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    applyPresetStops(modelData.stops)
                                }
                            }
                        }
                    }
                    
                    // User custom presets
                    Repeater {
                        model: root.customPresets
                        
                        delegate: Rectangle {
                            width: root.isCompact ? (parent.width - 18)/4 : (parent.width - 6)/2
                            height: root.isCompact ? 32 : 36
                            radius: 4
                            color: "#1d1d23"
                            border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4)
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 6
                                
                                Rectangle {
                                    width: root.isCompact ? 38 : 28
                                    height: 14
                                    radius: 2
                                    Layout.alignment: Qt.AlignVCenter
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: modelData.colors[0] }
                                        GradientStop { position: 0.5; color: modelData.colors[1] }
                                        GradientStop { position: 1.0; color: modelData.colors[2] }
                                    }
                                }
                                
                                Text {
                                    text: modelData.name
                                    color: "white"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    visible: !root.isCompact
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    applyPresetStops(modelData.stops)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helpers
    function applyPresetStops(stopsModel) {
        if (!targetCanvas) return
        var stops = []
        for (var i = 0; i < stopsModel.length; i++) {
            stops.push({
                "position": stopsModel[i].pos,
                "color": stopsModel[i].col
            })
        }
        targetCanvas.gradientStops = stops
        root.selectedStopIdx = 0
    }
    
    function updateSelectedStopColor() {
        if (!targetCanvas || root.selectedStopIdx >= targetCanvas.gradientStops.length) return
        
        var hexColor = Qt.hsva(hSlider.value / 360.0, sSlider.value / 100.0, vSlider.value / 100.0, 1.0).toString()
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
}
