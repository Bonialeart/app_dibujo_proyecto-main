import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    
    property string label: ""
    property real value: 0.0
    property real from: 0.0
    property real to: 1.0
    property string valueText: ""
    property real maxVal: 100.0
    property string previewType: "" // "size", "opacity"
    property bool previewOnRight: false
    property color accentColor: "#3e3e42"
    property color brushColor: "#ffffff"
    
    readonly property real visualPosition: (previewType === "size" || label === "Size" || label === "Border Width") 
        ? Math.max(0.0, Math.min(1.0, Math.pow((value - 0.5) / 1999.5, 1.0 / 3.0)))
        : ((to > from) ? Math.max(0.0, Math.min(1.0, (value - from) / (to - from))) : 0.0)
    
    signal moved(real val)
    
    implicitWidth: 40 * uiScale
    implicitHeight: 140 * uiScale
    
    readonly property real uiScale: (typeof mainWindow !== "undefined" && mainWindow.uiScale) ? mainWindow.uiScale : 1.0
    
    // Main Container
    Item {
        anchors.fill: parent
        
        // Transparent Track - The slider handle slides directly inside the unified toolbox background
        Item {
            id: trackBg
            width: parent.width
            height: parent.height
            anchors.centerIn: parent

            // Dynamic Progress Fill (Image 2 style: fills the main capsule up to the handle)
            Rectangle {
                id: progressFill
                width: parent.width - 8 * uiScale // Matches capsule width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4 * uiScale
                
                // Height goes from bottom up to handle position
                height: (trackBg.height - thumbHandle.height) * root.visualPosition + thumbHandle.height
                radius: width / 2
                
                // Elegant translucent white/light-gray that fills the capsule
                color: Qt.rgba(255, 255, 255, 0.14)
                
                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
            }

            // The Flat Pill Handle (Image 2 style: solid/translucent capsule directly in the bar)
            Rectangle {
                id: thumbHandle
                width: parent.width - 8 * uiScale // elegant 4px margins on each side
                height: 54 * uiScale // Long pill capsule
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Position: bottom = max, top = min (inverted Y). Moves smoothly.
                y: (trackBg.height - height) * (1.0 - root.visualPosition)
                
                // Translucent gray capsule that responds gracefully to interaction
                color: slideMouse.pressed 
                       ? Qt.rgba(255, 255, 255, 0.22) 
                       : (slideMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.10))
                
                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                
                // Subtle scale effect on press
                scale: slideMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }

        // === ICONIC PROCREATE PREVIEW CARD (Large popup next to the sidebar!) ===
        Item {
            id: procreatePreviewCard
            
            // Only show while actively dragging the slider
            visible: slideMouse.pressed
            opacity: visible ? 1.0 : 0.0
            scale: visible ? 1.0 : 0.85
            
            width: 180 * uiScale
            height: 180 * uiScale
            
            // Anchored next to the slider track (right or left depending on previewOnRight)
            anchors.verticalCenter: parent.verticalCenter
            
            anchors.left: root.previewOnRight ? trackBg.right : undefined
            anchors.leftMargin: root.previewOnRight ? 18 * uiScale : undefined
            
            anchors.right: !root.previewOnRight ? trackBg.left : undefined
            anchors.rightMargin: !root.previewOnRight ? 18 * uiScale : undefined
            
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

            // Card Backdrop (Translucent Glassmorphism)
            Rectangle {
                anchors.fill: parent
                radius: 24 * uiScale
                color: typeof mainWindow !== "undefined" ? mainWindow.colorPanel : "#eb1c1c1f"
                border.color: typeof mainWindow !== "undefined" ? mainWindow.colorBorder : Qt.rgba(1, 1, 1, 0.06)
                border.width: 0.5
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 0.8
                    shadowVerticalOffset: 6
                    shadowColor: "#80000000"
                    shadowOpacity: 0.45
                }
            }

            // Top-Left Crosshair Symbol (Detail from the photo!)
            Item {
                width: 16 * uiScale; height: 16 * uiScale
                anchors.left: parent.left; anchors.leftMargin: 18 * uiScale
                anchors.top: parent.top; anchors.topMargin: 18 * uiScale
                
                Rectangle { width: 10 * uiScale; height: 1 * uiScale; color: typeof mainWindow !== "undefined" ? Qt.rgba(mainWindow.colorText.r, mainWindow.colorText.g, mainWindow.colorText.b, 0.35) : "#55ffffff"; anchors.centerIn: parent }
                Rectangle { width: 1 * uiScale; height: 10 * uiScale; color: typeof mainWindow !== "undefined" ? Qt.rgba(mainWindow.colorText.r, mainWindow.colorText.g, mainWindow.colorText.b, 0.35) : "#55ffffff"; anchors.centerIn: parent }
            }

            // Top Center Readout (e.g., "60 px" or "100 %")
            Text {
                anchors.top: parent.top
                anchors.topMargin: 16 * uiScale
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.previewType === "size" 
                      ? Math.round(root.value) + " px" 
                      : Math.round(root.value * 100) + " %"
                color: typeof mainWindow !== "undefined" ? mainWindow.colorText : "#e2e2e7"
                font.pixelSize: 13 * uiScale
                font.bold: true
                font.letterSpacing: 0.2
            }

            // Center Dynamic Brush Tip Preview (Grows/shrinks beautifully with Easing.OutBack micro-animation)
            Rectangle {
                id: brushTipPreview
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 6 * uiScale
                
                // Color is the active brush color!
                color: root.brushColor
                
                // Diameter scales organically
                property real targetWidth: (root.previewType === "size")
                                           ? Math.max(3 * uiScale, (90 * uiScale) * root.visualPosition)
                                           : 60 * uiScale
                                           
                width: targetWidth
                height: width
                radius: width / 2
                
                opacity: (root.previewType === "opacity") ? Math.max(0.04, root.visualPosition) : 1.0
                
                // Elegant fluid animation as it expands/shrinks
                Behavior on width { 
                    NumberAnimation { duration: 180; easing.type: Easing.OutBack } 
                }
                Behavior on opacity { 
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic } 
                }
                
                // Sutil border for lighter brushes
                border.color: Qt.rgba(0, 0, 0, 0.12)
                border.width: 0.5 * uiScale
            }
        }

        // Full Interactive MouseArea with relative Friction Scrubbing
        MouseArea {
            id: slideMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            property real pressedY: 0.0
            property real startValue: 0.0
            
            onPressed: (mouse) => {
                // Tap-to-jump relative to handle center
                var clickVal = 1.0 - (mouse.y / height)
                clickVal = Math.max(0.0, Math.min(1.0, clickVal))
                
                var calculatedVal = (root.previewType === "size" || root.label === "Size" || root.label === "Border Width")
                    ? (0.5 + 1999.5 * Math.pow(clickVal, 3.0))
                    : (root.from + clickVal * (root.to - root.from))
                root.value = calculatedVal
                root.moved(calculatedVal)
                
                pressedY = mouse.y
                startValue = clickVal
            }
            
            onPositionChanged: (mouse) => {
                if (pressed) {
                    var dx = Math.abs(mouse.x - width / 2)
                    var dy = mouse.y - pressedY
                    
                    // Friction: farther horizontally = finer vertical control
                    var friction = 1.0
                    if (dx > 30 * uiScale) {
                        friction = Math.max(0.08, 1.0 - (dx - 30 * uiScale) / (120 * uiScale))
                    }
                    
                    var deltaVal = -(dy / trackBg.height) * friction
                    var newVal = startValue + deltaVal
                    newVal = Math.max(0.0, Math.min(1.0, newVal))
                    
                    var calculatedVal = (root.previewType === "size" || root.label === "Size" || root.label === "Border Width")
                        ? (0.5 + 1999.5 * Math.pow(newVal, 3.0))
                        : (root.from + newVal * (root.to - root.from))
                    root.value = calculatedVal
                    root.moved(calculatedVal)
                    
                    pressedY = mouse.y
                    startValue = newVal
                }
            }
        }
    }
}
