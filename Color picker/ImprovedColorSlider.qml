import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

/**
 * ImprovedColorSlider - Slider de color premium con preview y gradientes dinámicos
 */
Item {
    id: root
    
    // Properties
    property string label: "H"
    property real value: 0
    property real minValue: 0
    property real maxValue: 360
    property string unit: "°"
    property bool showValue: true
    property bool showPreview: true
    
    // Gradient colors for the track (auto-generated if empty)
    property var gradientStops: []
    
    // Current color context (for generating gradients)
    property color baseColor: "#FF0000"
    
    // Signal
    signal valueChanged(real newValue)
    
    implicitHeight: 40
    implicitWidth: 300
    
    RowLayout {
        anchors.fill: parent
        spacing: 12
        
        // Label
        Label {
            text: root.label
            color: "#888888"
            font.bold: true
            font.pixelSize: 13
            Layout.preferredWidth: 24
            horizontalAlignment: Text.AlignLeft
        }
        
        // Slider Track Container
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            
            // Background track
            Rectangle {
                id: track
                anchors.fill: parent
                radius: 14
                color: "#1A1A1A"
                border.color: "#2D2D2D"
                border.width: 1
                clip: true
                
                // Gradient fill
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        
                        // Generate gradient stops
                        Repeater {
                            model: root.gradientStops.length > 0 ? root.gradientStops : getDefaultGradient()
                            GradientStop {
                                position: modelData.position !== undefined ? modelData.position : index / (root.gradientStops.length - 1 || 1)
                                color: modelData.color !== undefined ? modelData.color : modelData
                            }
                        }
                    }
                }
                
                // Checkerboard pattern for alpha channel (if needed)
                Canvas {
                    anchors.fill: parent
                    visible: root.label === "A" || root.label === "Alpha"
                    z: -1
                    
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.fillStyle = "#1A1A1A"
                        ctx.fillRect(0, 0, width, height)
                        
                        var squareSize = 4
                        ctx.fillStyle = "#2D2D2D"
                        for (var x = 0; x < width; x += squareSize) {
                            for (var y = 0; y < height; y += squareSize) {
                                if ((x / squareSize + y / squareSize) % 2 === 0) {
                                    ctx.fillRect(x, y, squareSize, squareSize)
                                }
                            }
                        }
                    }
                }
            }
            
            // Handle/Thumb
            Rectangle {
                id: handle
                width: 26
                height: 32
                radius: 6
                
                x: calculateHandleX()
                y: track.height / 2 - height / 2
                
                color: "#FFFFFF"
                border.color: "#1A1A1A"
                border.width: 2
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 10
                    shadowColor: "#80000000"
                    shadowVerticalOffset: 3
                }
                
                // Inner color preview
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 10
                    height: parent.height - 10
                    radius: 3
                    color: root.showPreview ? getCurrentColor() : "transparent"
                    border.color: Qt.rgba(0, 0, 0, 0.2)
                    border.width: 1
                }
                
                // Hover effect
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: "#7D6D9D"
                    border.width: mouseArea.containsMouse ? 2 : 0
                    opacity: mouseArea.containsMouse ? 0.6 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                Behavior on x {
                    enabled: !mouseArea.pressed
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }
            
            // Mouse interaction
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onPressed: (mouse) => updateValue(mouse)
                onPositionChanged: (mouse) => {
                    if (pressed) updateValue(mouse)
                }
                
                function updateValue(mouse) {
                    var trackX = Math.max(0, Math.min(track.width, mouse.x))
                    var normalizedValue = trackX / track.width
                    var newValue = root.minValue + normalizedValue * (root.maxValue - root.minValue)
                    root.valueChanged(newValue)
                }
            }
        }
        
        // Value display
        Label {
            visible: root.showValue
            text: getFormattedValue()
            color: "#CCCCCC"
            font.pixelSize: 12
            font.family: "monospace"
            Layout.preferredWidth: 50
            horizontalAlignment: Text.AlignRight
        }
    }
    
    // Helper functions
    function calculateHandleX() {
        var normalized = (root.value - root.minValue) / (root.maxValue - root.minValue)
        return normalized * (track.width - handle.width)
    }
    
    function getFormattedValue() {
        var displayValue = root.value
        
        // Format based on type
        if (root.maxValue === 1.0) {
            displayValue = Math.round(displayValue * 100)
        } else if (root.maxValue === 360) {
            displayValue = Math.round(displayValue)
        } else {
            displayValue = Math.round(displayValue)
        }
        
        return displayValue + root.unit
    }
    
    function getCurrentColor() {
        // Return the color at the current position
        // This should be bound to the actual color being edited
        return root.baseColor
    }
    
    function getDefaultGradient() {
        // Generate default gradient based on label
        switch(root.label) {
            case "H":
            case "Hue":
                return [
                    "#FF0000", "#FFFF00", "#00FF00", 
                    "#00FFFF", "#0000FF", "#FF00FF", "#FF0000"
                ]
            
            case "S":
            case "Saturation":
                return ["#808080", root.baseColor]
            
            case "B":
            case "V":
            case "Brightness":
            case "Value":
                return ["#000000", root.baseColor]
            
            case "L":
            case "Lightness":
                return ["#000000", root.baseColor, "#FFFFFF"]
            
            case "R":
            case "Red":
                return ["#000000", "#FF0000"]
            
            case "G":
            case "Green":
                return ["#000000", "#00FF00"]
            
            case "B_Blue":
            case "Blue":
                return ["#000000", "#0000FF"]
            
            case "C":
            case "Cyan":
                return ["#FFFFFF", "#00FFFF"]
            
            case "M":
            case "Magenta":
                return ["#FFFFFF", "#FF00FF"]
            
            case "Y":
            case "Yellow":
                return ["#FFFFFF", "#FFFF00"]
            
            case "K":
            case "Black":
                return ["#FFFFFF", "#000000"]
            
            case "A":
            case "Alpha":
                return [
                    Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0),
                    Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 1)
                ]
            
            default:
                return ["#000000", "#FFFFFF"]
        }
    }
}
