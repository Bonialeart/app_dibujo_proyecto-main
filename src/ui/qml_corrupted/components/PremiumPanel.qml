import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════
// PremiumPanel — Reusable Glassmorphism Floating Panel
// Features: Drag & Drop, 8-point Resize, Bring-to-Front, 
//           Smooth Animations, Premium Dark Glass Design
// ═══════════════════════════════════════════════════════════════
Item {
    id: root

    // ── Public API ──
    property string panelTitle: "Panel"
    property string panelIcon: ""         // Icon name for iconPath()
    property bool panelVisible: false
    property color accentColor: "#6366f1"

    // Size constraints
    property real minWidth: 200
    property real maxWidth: 600
    property real minHeight: 150
    property real maxHeight: 800
    property real defaultWidth: 280
    property real defaultHeight: 400

    // Initial position (set by parent)
    property real initialX: 100
    property real initialY: 100

    // Content slot
    default property alias content: contentArea.data

    // Signals
    signal closeRequested()
    signal panelClicked()

    // ── Internal State ──
    property int panelZ: 100
    property bool _initialized: false
    property bool _minimized: false

    // Use iconPath from mainWindow context
    function iconPath(name) {
        return "image://icons/" + name
    }

    // ── Visibility & Animation ──
    visible: opacity > 0
    opacity: panelVisible ? 1.0 : 0.0
    scale: panelVisible ? 1.0 : 0.92

    // Bind position to initial values (breaks when dragged)
    x: initialX
    y: initialY

    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

    // Initialize dimensions (position is bound via x: initialX / y: initialY)
    Component.onCompleted: {
        if (!_initialized) {
            root.width = defaultWidth
            root.height = defaultHeight
            _initialized = true
        }
    }

    // ── PANEL BODY ──
    Item {
        id: panel
        anchors.fill: parent

        // ── Shadow (Outer Glow) ──
        Rectangle {
            id: panelShadow
            anchors.fill: parent
            anchors.margins: -10
            z: -2
            radius: panelBg.radius + 10
            color: "black"
            opacity: 0.5
        }

        // ── Accent Glow (subtle) ──
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            radius: panelBg.radius + 2
            color: "transparent"
            border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
            border.width: 1
        }

        // ── Main Background ──
        Rectangle {
            id: panelBg
            anchors.fill: parent
            radius: 14
            color: "#f0131316"
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            clip: true

            // Inner glass gradient
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                    GradientStop { position: 0.15; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.1) }
                }
            }

            // ════════════════════════════════════════════
            // TITLE BAR (Drag Handle)
            // ════════════════════════════════════════════
            Rectangle {
                id: titleBar
                width: parent.width
                height: 36
                color: "transparent"
                z: 10

                // Subtle bottom border
                Rectangle {
                    width: parent.width
                    height: 1
                    anchors.bottom: parent.bottom
                    color: Qt.rgba(1, 1, 1, 0.06)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    // Panel Icon
                    Image {
                        id: titleIcon
                        visible: root.panelIcon !== ""
                        source: root.panelIcon !== "" ? root.iconPath(root.panelIcon) : ""
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        opacity: 0.6
                        smooth: true
                        mipmap: true
                    }

                    // Title Text
                    Text {
                        text: root.panelTitle
                        color: "#c0c0c5"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.3
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // ── Minimize Button ──
                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 6
                        color: minimizeMouse.containsMouse ? "#22ffffff" : "transparent"

                        Rectangle {
                            width: 10; height: 2; radius: 1
                            anchors.centerIn: parent
                            color: minimizeMouse.containsMouse ? "#ddd" : "#555"
                        }

                        MouseArea {
                            id: minimizeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root._minimized = !root._minimized
                            }
                        }

                        ToolTip.visible: minimizeMouse.containsMouse
                        ToolTip.text: root._minimized ? "Expand" : "Minimize"
                        ToolTip.delay: 600
                    }

                    // ── Close Button ──
                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 6
                        color: closeMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.3) : "transparent"

                        Text {
                            text: "×"
                            color: closeMouse.containsMouse ? "#ff6b6b" : "#555"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeRequested()
                            }
                        }

                        ToolTip.visible: closeMouse.containsMouse
                        ToolTip.text: "Close"
                        ToolTip.delay: 600
                    }
                }

                // ── Drag Handler ──
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    anchors.rightMargin: 60  // Leave space for buttons
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    
                    property point pressPos: Qt.point(0, 0)
                    
                    onPressed: (mouse) => {
                        pressPos = Qt.point(mouse.x, mouse.y)
                        root.panelClicked()
                    }
                    
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            var dx = mouse.x - pressPos.x
                            var dy = mouse.y - pressPos.y
                            var newX = root.x + dx
                            var newY = root.y + dy
                            
                            // Constrain to parent
                            newX = Math.max(-root.width + 60, Math.min(newX, root.parent ? root.parent.width - 60 : 9999))
                            newY = Math.max(0, Math.min(newY, root.parent ? root.parent.height - 40 : 9999))
                            
                            root.x = newX
                            root.y = newY
                        }
                    }
                }
            }

            // ════════════════════════════════════════════
            // CONTENT AREA
            // ════════════════════════════════════════════
            Item {
                id: contentArea
                anchors.top: titleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                anchors.topMargin: 0
                clip: true

                visible: !root._minimized
            }

        }

        // Saved height for minimize/restore
        property real _savedHeight: root.defaultHeight

        // Minimized state: collapse height
        states: [
            State {
                name: "minimized"
                when: root._minimized
                PropertyChanges { target: root; height: 36 }
            },
            State {
                name: "normal"
                when: !root._minimized
                PropertyChanges { target: root; height: panel._savedHeight > 0 ? panel._savedHeight : root.defaultHeight }
            }
        ]

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // ════════════════════════════════════════════
        // RESIZE HANDLES (8 points: 4 edges + 4 corners)
        // ════════════════════════════════════════════
        
        // Edge size
        property int edgeSize: 6

        // ── Right Edge ──
        MouseArea {
            id: rightEdge
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: panel.edgeSize
            anchors.bottomMargin: panel.edgeSize
            width: panel.edgeSize
            cursorShape: Qt.SizeHorCursor
            visible: !root._minimized
            
            property real startX: 0
            property real startW: 0
            
            onPressed: (mouse) => {
                startX = mapToItem(root.parent, mouse.x, 0).x
                startW = root.width
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var globalX = mapToItem(root.parent, mouse.x, 0).x
                    var delta = globalX - startX
                    root.width = Math.max(root.minWidth, Math.min(root.maxWidth, startW + delta))
                }
            }
        }

        // ── Left Edge ──
        MouseArea {
            id: leftEdge
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: panel.edgeSize
            anchors.bottomMargin: panel.edgeSize
            width: panel.edgeSize
            cursorShape: Qt.SizeHorCursor
            visible: !root._minimized
            
            property real startX: 0
            property real startW: 0
            property real startPanelX: 0
            
            onPressed: (mouse) => {
                startX = mapToItem(root.parent, mouse.x, 0).x
                startW = root.width
                startPanelX = root.x
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var globalX = mapToItem(root.parent, mouse.x, 0).x
                    var delta = startX - globalX
                    var newW = Math.max(root.minWidth, Math.min(root.maxWidth, startW + delta))
                    var actualDelta = newW - startW
                    root.x = startPanelX - actualDelta
                    root.width = newW
                }
            }
        }

        // ── Bottom Edge ──
        MouseArea {
            id: bottomEdge
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: panel.edgeSize
            anchors.rightMargin: panel.edgeSize
            height: panel.edgeSize
            cursorShape: Qt.SizeVerCursor
            visible: !root._minimized
            
            property real startY: 0
            property real startH: 0
            
            onPressed: (mouse) => {
                startY = mapToItem(root.parent, 0, mouse.y).y
                startH = root.height
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var globalY = mapToItem(root.parent, 0, mouse.y).y
                    var delta = globalY - startY
                    var newH = Math.max(root.minHeight, Math.min(root.maxHeight, startH + delta))
                    root.height = newH
                    panel._savedHeight = newH
                }
            }
        }

        // ── Top Edge ──
        MouseArea {
            id: topEdge
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: panel.edgeSize
            anchors.rightMargin: panel.edgeSize
            height: panel.edgeSize
            cursorShape: Qt.SizeVerCursor
            visible: !root._minimized
            
            property real startY: 0
            property real startH: 0
            property real startPanelY: 0
            
            onPressed: (mouse) => {
                startY = mapToItem(root.parent, 0, mouse.y).y
                startH = root.height
                startPanelY = root.y
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var globalY = mapToItem(root.parent, 0, mouse.y).y
                    var delta = startY - globalY
                    var newH = Math.max(root.minHeight, Math.min(root.maxHeight, startH + delta))
                    var actualDelta = newH - startH
                    root.y = startPanelY - actualDelta
                    root.height = newH
                    panel._savedHeight = newH
                }
            }
        }

        // ── Bottom-Right Corner ──
        MouseArea {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: panel.edgeSize * 2
            height: panel.edgeSize * 2
            cursorShape: Qt.SizeFDiagCursor
            visible: !root._minimized
            
            property real startX: 0
            property real startY: 0
            property real startW: 0
            property real startH: 0
            
            onPressed: (mouse) => {
                var gp = mapToItem(root.parent, mouse.x, mouse.y)
                startX = gp.x; startY = gp.y
                startW = root.width; startH = root.height
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var gp = mapToItem(root.parent, mouse.x, mouse.y)
                    root.width = Math.max(root.minWidth, Math.min(root.maxWidth, startW + (gp.x - startX)))
                    var newH = Math.max(root.minHeight, Math.min(root.maxHeight, startH + (gp.y - startY)))
                    root.height = newH
                    panel._savedHeight = newH
                }
            }
        }

        // ── Bottom-Left Corner ──
        MouseArea {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: panel.edgeSize * 2
            height: panel.edgeSize * 2
            cursorShape: Qt.SizeBDiagCursor
            visible: !root._minimized
            
            property real startX: 0
            property real startY: 0
            property real startW: 0
            property real startH: 0
            property real startPanelX: 0
            
            onPressed: (mouse) => {
                var gp = mapToItem(root.parent, mouse.x, mouse.y)
                startX = gp.x; startY = gp.y
                startW = root.width; startH = root.height
                startPanelX = root.x
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var gp = mapToItem(root.parent, mouse.x, mouse.y)
                    var deltaX = startX - gp.x
                    var newW = Math.max(root.minWidth, Math.min(root.maxWidth, startW + deltaX))
                    root.x = startPanelX - (newW - startW)
                    root.width = newW
                    var newH = Math.max(root.minHeight, Math.min(root.maxHeight, startH + (gp.y - startY)))
                    root.height = newH
                    panel._savedHeight = newH
                }
            }
        }

        // ── Top-Right Corner ──
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            width: panel.edgeSize * 2
            height: panel.edgeSize * 2
            cursorShape: Qt.SizeBDiagCursor
            visible: !root._minimized
            
            property real startX: 0
            property real startY: 0
            property real startW: 0
            property real startH: 0
            property real startPanelY: 0
            
            onPressed: (mouse) => {
                var gp = mapToItem(root.parent, mouse.x, mouse.y)
                startX = gp.x; startY = gp.y
                startW = root.width; startH = root.height
                startPanelY = root.y
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var gp = mapToItem(root.parent, mouse.x, mouse.y)
                    root.width = Math.max(root.minWidth, Math.min(root.maxWidth, startW + (gp.x - startX)))
                    var deltaY = startY - gp.y
                    var newH = Math.max(root.minHeight, Math.min(root.maxHeight, startH + deltaY))
                    root.y = startPanelY - (newH - startH)
                    root.height = newH
                    panel._savedHeight = newH
                }
            }
        }

        // ── Top-Left Corner ──
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            width: panel.edgeSize * 2
            height: panel.edgeSize * 2
            cursorShape: Qt.SizeFDiagCursor
            visible: !root._minimized
            
            property real startX: 0
            property real startY: 0
            property real startW: 0
            property real startH: 0
            property real startPanelX: 0
            property real startPanelY: 0
            
            onPressed: (mouse) => {
                var gp = mapToItem(root.parent, mouse.x, mouse.y)
                startX = gp.x; startY = gp.y
                startW = root.width; startH = root.height
                startPanelX = root.x; startPanelY = root.y
                root.panelClicked()
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var gp = mapToItem(root.parent, mouse.x, mouse.y)
                    var deltaX = startX - gp.x
                    var newW = Math.max(root.minWidth, Math.min(root.maxWidth, startW + deltaX))
                    root.x = startPanelX - (newW - startW)
                    root.width = newW
                    var deltaY = startY - gp.y
                    var newH = Math.max(root.minHeight, Math.min(root.maxHeight, startH + deltaY))
                    root.y = startPanelY - (newH - startH)
                    root.height = newH
                    panel._savedHeight = newH
                }
            }
        }

        // ── Resize visual indicator (bottom-right corner grip) ──
        Item {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            width: 12; height: 12
            visible: !root._minimized
            opacity: 0.3

            Column {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 2

                Row {
                    spacing: 2
                    anchors.right: parent.right
                    Rectangle { width: 2; height: 2; radius: 1; color: "#888" }
                }
                Row {
                    spacing: 2
                    anchors.right: parent.right
                    Rectangle { width: 2; height: 2; radius: 1; color: "#888" }
                    Rectangle { width: 2; height: 2; radius: 1; color: "#888" }
                }
                Row {
                    spacing: 2
                    anchors.right: parent.right
                    Rectangle { width: 2; height: 2; radius: 1; color: "#888" }
                    Rectangle { width: 2; height: 2; radius: 1; color: "#888" }
                    Rectangle { width: 2; height: 2; radius: 1; color: "#888" }
                }
            }
        }
    }

    // ── Panel dimensions follow internal panel item ──
    // ── Panel dimensions no longer bound to internal panel, but the other way around ──

}
