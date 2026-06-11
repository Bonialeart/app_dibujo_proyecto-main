import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

Item {
    id: root
    
    // --- PROPS ---
    property var targetCanvas: null // Injected by DockContainer
    property var mainCanvas: targetCanvas // For compatibility with copied code
    property color accentColor: (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#6366f1"
    
    // Switch panels based on tool
    property bool isShapeTool: {
        if (!mainCanvas) return false;
        var tool = mainCanvas.currentTool;
        return ["shape", "rect", "ellipse", "line", "panel", "bubble", "shapes"].indexOf(tool) !== -1 || tool.startsWith("panel_") || tool.startsWith("bubble_");
    }
    
    property string studioSelectedCategory: ""
    property var studioBrushList: []
    
    // Brush list loading
    function updateStudioBrushList() {
        if (!mainCanvas || studioSelectedCategory === "") return
        var catBrushes = mainCanvas.getBrushesForCategory(studioSelectedCategory)
        studioBrushList = catBrushes || []
    }

    onStudioSelectedCategoryChanged: updateStudioBrushList()
    
    function updateCategories() {
        if (!mainCanvas) return
        var categories = mainCanvas.brushCategories
        if (categories && categories.length > 0) {
            var catNames = []
            for (var i = 0; i < categories.length; i++) {
                catNames.push(categories[i].name)
            }
            if (studioSelectedCategory === "" || catNames.indexOf(studioSelectedCategory) === -1) {
                studioSelectedCategory = catNames[0]
            }
        }
        updateStudioBrushList()
    }
    
    // Crucial QML Lifecycle Fix: Update brushes when mainCanvas is bound by the Loader
    onMainCanvasChanged: {
        if (mainCanvas) {
            updateCategories()
        }
    }
    
    Component.onCompleted: {
        if (mainCanvas) {
            updateCategories()
        }
    }

    Connections {
        target: root.mainCanvas
        ignoreUnknownSignals: true
        function onBrushCategoriesChanged() {
            updateCategories()
        }
        function onAvailableBrushesChanged() {
            updateStudioBrushList()
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12
        visible: !root.isShapeTool

        // === PREMIUM CATEGORY SELECTOR (Horizontal pills with smooth transitions) ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: mainWindow ? Qt.darker(mainWindow.colorPanel, 1.1) : "#0a0a0d"
            radius: 12
            border.color: mainWindow ? mainWindow.colorBorder : "#1a1a24"
            border.width: 1
            clip: true
            
            Flickable {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                contentWidth: catRow.implicitWidth
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Row {
                    id: catRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: root.mainCanvas ? root.mainCanvas.brushCategories : []
                        delegate: Rectangle {
                            id: catPill
                            width: catText.implicitWidth + 24
                            height: 26
                            radius: 8
                            
                            // High-end state-dependent background styling
                            color: studioSelectedCategory === modelData.name 
                                ? accentColor 
                                : (catMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e5e7eb" : "#1c1c28") : "transparent")
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
 
                            Text {
                                id: catText
                                text: modelData.name
                                anchors.centerIn: parent
                                color: studioSelectedCategory === modelData.name ? "white" : (catMa.containsMouse ? (mainWindow ? mainWindow.colorText : "#ddd") : (mainWindow ? mainWindow.colorTextMuted : "#71717a"))
                                font.pixelSize: 11
                                font.weight: studioSelectedCategory === modelData.name ? Font.DemiBold : Font.Medium
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            
                            MouseArea {
                                id: catMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: studioSelectedCategory = modelData.name
                            }
                        }
                    }
                }
            }
        }

        // === ACTIVE BRUSH PREVIEW CARD (Glassmorphic look) ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 14
            color: mainWindow ? mainWindow.colorCard : "#121218"
            border.color: mainWindow ? mainWindow.colorBorder : "#222230"
            border.width: 1

            // Subtle inner gradient glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 13
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Icon Orb with Brush Initial
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                    border.color: accentColor
                    border.width: 1.5

                    Text {
                        text: {
                            var name = mainCanvas ? (mainCanvas.activeBrushName || "?") : "?";
                            return name.charAt(0).toUpperCase();
                        }
                        color: accentColor
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }
                }

                // Info text
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: mainCanvas ? (mainCanvas.activeBrushName || "Default Brush") : "Default Brush"
                        color: mainWindow ? mainWindow.colorText : "white"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Size: " + (mainCanvas ? Math.round(mainCanvas.brushSize) : 10) + "px  ·  Opac: " + (mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) : 100) + "%"
                        color: mainWindow ? mainWindow.colorTextMuted : "#71717a"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // === PREMIUM BRUSH LIST ===
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: mainWindow ? Qt.darker(mainWindow.colorPanel, 1.15) : "#07070a"
            radius: 14
            border.color: mainWindow ? mainWindow.colorBorder : "#14141d"
            border.width: 1
            clip: true

            ListView {
                id: studioBrushListView
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                spacing: 3
                model: studioBrushList
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: 300

                ScrollBar.vertical: ScrollBar { 
                    width: 4
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 2; color: "#27272a" } 
                }

                // Consume wheel
                MouseArea {
                    anchors.fill: parent; z: -1
                    onWheel: function(wheel) {
                        wheel.angleDelta.y > 0 ? studioBrushListView.flick(0, 800) : studioBrushListView.flick(0, -800)
                        wheel.accepted = true
                    }
                }

                delegate: Rectangle {
                    id: brushDelegate
                    width: studioBrushListView.width - 8
                    x: 4
                    height: 48
                    radius: 10
                    
                    property string brushName: modelData
                    property bool isActive: mainCanvas && mainCanvas.activeBrushName === brushName
                    
                    color: isActive 
                        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12) 
                        : (brushItemMa.containsMouse ? (mainWindow && !mainWindow.isDark ? "#e1e7f0" : "#181824") : "transparent")
                    
                    border.color: isActive ? accentColor : "transparent"
                    border.width: isActive ? 1 : 0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    property string previewSource: ""

                    onBrushNameChanged: {
                        if (mainCanvas && brushName) {
                            previewSource = mainCanvas.get_brush_preview(brushName)
                        } else {
                            previewSource = ""
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Selection indicator indicator
                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.preferredHeight: 18
                            radius: 1.5
                            color: accentColor
                            visible: isActive
                        }

                        // Preview Box with custom styled placeholder
                        Rectangle {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 32
                            radius: 6
                            color: mainWindow ? Qt.darker(mainWindow.colorPanel, 1.25) : "#09090c"
                            border.color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : (mainWindow ? mainWindow.colorBorder : "#1a1a24")
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: previewSource
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                opacity: isActive ? 1.0 : 0.8
                            }
                        }

                        // Brush Name
                        Text {
                            Layout.fillWidth: true
                            text: brushName
                            color: isActive ? (mainWindow && !mainWindow.isDark ? "#111827" : "white") : (brushItemMa.containsMouse ? (mainWindow ? mainWindow.colorText : "#e4e4e7") : (mainWindow ? mainWindow.colorTextMuted : "#a1a1aa"))
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            font.weight: isActive ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: brushItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { 
                            if (mainCanvas) mainCanvas.usePreset(brushName) 
                        }
                    }
                }
            }
        }
    }

    // ── Shapes Mode Overlay ──
    Item {
        anchors.fill: parent
        visible: root.isShapeTool
        
        ShapeLibrary {
            anchors.fill: parent
            targetCanvas: root.mainCanvas
            accentColor: root.accentColor
            radius: 8
            
            onShapeSelected: function(shapeName) {
                if (root.mainCanvas) {
                    root.mainCanvas.currentTool = shapeName;
                    if (["rect", "ellipse", "line"].indexOf(shapeName) !== -1) {
                        if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                            mainWindow.comicOverlayManager.startShapeDrawing(shapeName);
                        }
                    }
                }
            }
            onPanelLayoutRequested: function(layoutType) {
                if (typeof mainWindow !== "undefined" && typeof mainWindow.openPanelSettings === "function") {
                    mainWindow.openPanelSettings(layoutType, "Panel: " + layoutType);
                } else if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                    var bWidth = root.mainCanvas ? Math.round(root.mainCanvas.brushSize) : 6;
                    mainWindow.comicOverlayManager.addPanelLayout(layoutType, 10, bWidth, 30);
                }
            }
            onBubbleRequested: function(bubbleType) {
                if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                    var cx = root.mainCanvas ? root.mainCanvas.canvasWidth / 2 : 500;
                    var cy = root.mainCanvas ? root.mainCanvas.canvasHeight / 2 : 500;
                    mainWindow.comicOverlayManager.addBubble(bubbleType, cx, cy);
                    if (typeof toastManager !== "undefined") {
                        toastManager.show("Bubble added — click to select and edit", "success");
                    }
                }
            }
        }
    }
}
