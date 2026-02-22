import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    
    // --- PROPS ---
    property var targetCanvas: null // Injected by DockContainer
    property var mainCanvas: targetCanvas // For compatibility with copied code
    property color accentColor: "#6366f1"
    
    // Switch panels based on tool
    property bool isShapeTool: {
        if (!mainCanvas) return false;
        var tool = mainCanvas.currentTool;
        console.log("[BrushLibraryPanel] Current tool:", tool);
        return ["shape", "rect", "ellipse", "line", "panel", "bubble", "shapes"].indexOf(tool) !== -1 || tool.startsWith("panel_") || tool.startsWith("bubble_");
    }
    
    property string studioSelectedCategory: "Sketching"
    property var studioBrushList: []
    
    // Brush list loading
    function updateStudioBrushList() {
        if (!mainCanvas) return
        var catBrushes = mainCanvas.getBrushesForCategory(studioSelectedCategory)
        studioBrushList = catBrushes || []
    }

    onStudioSelectedCategoryChanged: updateStudioBrushList()
    Component.onCompleted: updateStudioBrushList()
    
    Connections {
        target: mainCanvas
        function onBrushesChanged() { updateStudioBrushList() }
    }
    
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 6
        visible: !root.isShapeTool

        // Category selector (scrollable)
        Flickable {
            Layout.fillWidth: true; Layout.preferredHeight: 30
            contentWidth: catRow.implicitWidth; clip: true
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: catRow; spacing: 4

                Repeater {
                    model: root.targetCanvas ? root.targetCanvas.getBrushCategoryNames() : []
                    Rectangle {
                        width: catText.implicitWidth + 16; height: 22; radius: 11
                        color: studioSelectedCategory === modelData ? accentColor : (catMa.containsMouse ? "#222226" : "#141418")

                        Text {
                            id: catText; text: modelData; anchors.centerIn: parent
                            color: studioSelectedCategory === modelData ? "#fff" : "#888"
                            font.pixelSize: 9; font.weight: Font.Medium
                        }
                        MouseArea {
                            id: catMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: studioSelectedCategory = modelData
                        }
                    }
                }
            }
        }

        // Current brush preview
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50
            color: "#0a0a0d"; radius: 8; border.color: "#1a1a1e"

            Row {
                anchors.centerIn: parent; spacing: 12
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: "#1c1c20"; border.color: accentColor; border.width: 1.5

                    Text {
                        text: mainCanvas ? (mainCanvas.activeBrushName || "?") : "?"
                        color: "#aaa"; font.pixelSize: 7; anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter; width: 30
                        wrapMode: Text.WordWrap
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text {
                        text: mainCanvas ? (mainCanvas.activeBrushName || "Default Brush") : "Default Brush"
                        color: "#ccc"; font.pixelSize: 11; font.weight: Font.Medium
                    }
                    Text {
                        text: "Size: " + (mainCanvas ? Math.round(mainCanvas.brushSize) : 10) + "px  |  Opacity: " + (mainCanvas ? Math.round(mainCanvas.brushOpacity * 100) : 100) + "%"
                        color: "#666"; font.pixelSize: 9
                    }
                }
            }
        }

        // Brush list
        ListView {
            id: studioBrushListView
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 2
            model: studioBrushList
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { width: 3; policy: ScrollBar.AsNeeded; contentItem: Rectangle { radius: 1.5; color: "#333" } }

            // Consume wheel
            MouseArea {
                anchors.fill: parent; z: -1
                onWheel: function(wheel) {
                    wheel.angleDelta.y > 0 ? studioBrushListView.flick(0, 800) : studioBrushListView.flick(0, -800)
                    wheel.accepted = true
                }
            }

            delegate: Rectangle {
                width: studioBrushListView.width; height: 44; radius: 6
                property bool isActive: mainCanvas && mainCanvas.activeBrushName === modelData
                color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : (brushItemMa.containsMouse ? "#141418" : "transparent")
                border.color: isActive ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : "transparent"
                border.width: isActive ? 1 : 0

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Rectangle { width: 3; height: 16; radius: 1.5; color: accentColor; visible: isActive }

                    // Preview
                    Item {
                        Layout.preferredWidth: 60; Layout.preferredHeight: 30
                        Image {
                            anchors.fill: parent
                            source: mainCanvas ? mainCanvas.get_brush_preview(modelData) : ""
                            fillMode: Image.PreserveAspectFit; asynchronous: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true; text: modelData
                        color: isActive ? "#fff" : (brushItemMa.containsMouse ? "#bbb" : "#777")
                        font.pixelSize: 12; elide: Text.ElideRight
                        font.weight: isActive ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    id: brushItemMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (mainCanvas) mainCanvas.usePreset(modelData) }
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
                console.log("[BrushLibraryPanel] Shape selected:", shapeName);
                if (root.mainCanvas) {
                    root.mainCanvas.currentTool = shapeName;
                    // If it's a basic shape (rect/ellipse/line), we might want to tell comicOverlay
                    if (["rect", "ellipse", "line"].indexOf(shapeName) !== -1) {
                        if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                            mainWindow.comicOverlayManager.startShapeDrawing(shapeName);
                        }
                    }
                }
            }
            onPanelLayoutRequested: function(layoutType) {
                console.log("[BrushLibraryPanel] Panel layout requested:", layoutType);
                if (typeof mainWindow !== "undefined" && typeof mainWindow.openPanelSettings === "function") {
                    mainWindow.openPanelSettings(layoutType, "Panel: " + layoutType);
                } else if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                    var bWidth = root.mainCanvas ? Math.round(root.mainCanvas.brushSize) : 6;
                    mainWindow.comicOverlayManager.addPanelLayout(layoutType, 10, bWidth, 30);
                } else {
                    console.log("[BrushLibraryPanel] Cannot locate comicOverlayManager via mainWindow");
                }
            }
            onBubbleRequested: function(bubbleType) {
                console.log("[BrushLibraryPanel] Bubble requested:", bubbleType);
                if (typeof mainWindow !== "undefined" && mainWindow.comicOverlayManager) {
                    // Add bubble at center of screen
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
