import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

/**
 * ImprovedColorSlider - Sliders con gradientes vibrantes premium
 * Esta versión usa LinearGradient para máxima compatibilidad y rendimiento.
 */
Item {
    id: root
    
    // Properties
    property string label: "H"
    property real value: 0
    property real minValue: 0
    property real maxValue: 360
    property string unit: "°"
    
    // Context para generar gradientes dinámicos
    property real currentH: 0.0
    property real currentS: 1.0
    property real currentV: 1.0
    
    // Signal
    signal sliderMoved(real newValue)
    
    implicitHeight: 32
    implicitWidth: 300
    
    RowLayout {
        anchors.fill: parent
        spacing: 12
        
        // Label
        Text {
            text: root.label
            color: "#8E8E93"
            font.pixelSize: 12
            font.weight: Font.Bold
            Layout.preferredWidth: 12
            horizontalAlignment: Text.AlignLeft
        }
        
        // Slider Container
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            
            // Track Background
            Rectangle {
                id: trackBg
                anchors.fill: parent
                radius: 9
                color: "#1C1C1E"
                border.color: "#353538"
                border.width: 1
            }
            
            // Colored Track (con gradiente)
            Rectangle {
                id: track
                anchors.fill: parent
                radius: 9
                clip: true
                
                // --- GRADIENT LOGIC (Qt 6 Compatible) ---
                
                // 1. HUE RAINBOW
                Rectangle {
                    anchors.fill: parent
                    visible: root.getSliderType() === 0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.00; color: "#FF0000" }
                        GradientStop { position: 0.17; color: "#FFFF00" }
                        GradientStop { position: 0.33; color: "#00FF00" }
                        GradientStop { position: 0.50; color: "#00FFFF" }
                        GradientStop { position: 0.67; color: "#0000FF" }
                        GradientStop { position: 0.83; color: "#FF00FF" }
                        GradientStop { position: 1.00; color: "#FF0000" }
                    }
                }
                
                // 2. DYNAMIC TWO-STOP (S, B, R, G, B, CMYK)
                Rectangle {
                    anchors.fill: parent
                    visible: root.getSliderType() !== 0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.getGradientStart() }
                        GradientStop { position: 1.0; color: root.getGradientEnd() }
                    }
                }
            }
            
            // Handle (Knob circular grande)
            Rectangle {
                id: handle
                width: 22
                height: 22
                radius: 11
                
                x: calculateHandleX()
                anchors.verticalCenter: parent.verticalCenter
                
                color: "#F5F5F7"
                border.color: "#FFFFFF"
                border.width: 2
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 10
                    shadowColor: "#A0000000"
                    shadowVerticalOffset: 2
                }
                
                scale: mouseArea.containsMouse ? 1.1 : 1.0
                
                Behavior on x {
                    enabled: !mouseArea.pressed
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
            }
            
            // Mouse Area
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
                    var normalized = trackX / track.width
                    var newValue = root.minValue + normalized * (root.maxValue - root.minValue)
                    root.sliderMoved(newValue)
                }
            }
        }
        
        // Value Display (Editable)
        Rectangle {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 22
            radius: 6
            color: "#1C1C1E"
            border.color: "#353538"
            border.width: 1
            
            TextInput {
                id: valueInput
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                verticalAlignment: Text.AlignVCenter
                text: root.getFormattedValue()
                color: "#FFFFFF"
                font.pixelSize: 11
                font.family: "Monospace"
                selectByMouse: true
                horizontalAlignment: Text.AlignRight
                
                onEditingFinished: {
                    var v = parseFloat(text)
                    if (!isNaN(v)) {
                        var realValue = v
                        if (root.maxValue === 1.0 && root.unit === "%") {
                            realValue = v / 100.0
                        }
                        realValue = Math.max(root.minValue, Math.min(root.maxValue, realValue))
                        root.sliderMoved(realValue)
                        focus = false
                    }
                }
            }
        }
    }
    
    // Helper Functions
    function calculateHandleX() {
        var normalized = (root.value - root.minValue) / (root.maxValue - root.minValue)
        if (track.width <= 0) return 0
        return Math.max(0, Math.min(track.width - handle.width, normalized * (track.width - handle.width)))
    }
    
    function getFormattedValue() {
        var v = root.value
        if (root.maxValue === 1.0 && root.unit === "%") {
            return Math.round(v * 100)
        } else {
            return Math.round(v)
        }
    }
    
    function getSliderType() {
        switch(root.label) {
            case "H": return 0   // Hue rainbow
            case "S": return 1   // Saturation
            case "B": 
                if (root.maxValue === 255) return 5  // Blue RGB
                return 2  // Brightness/Value
            case "V": return 2   // Value
            case "R": return 3   // Red
            case "G": return 4   // Green
            case "C": return 6   // Cyan
            case "M": return 7   // Magenta
            case "Y": return 8   // Yellow
            case "K": return 9   // Key (Black)
            default: return 0
        }
    }

    function getGradientStart() {
        var type = getSliderType();
        switch(type) {
            case 1: return Qt.hsva(root.currentH, 0.0, root.currentV, 1.0); // Saturation: Gray to Color
            case 2: return Qt.hsva(root.currentH, root.currentS, 0.0, 1.0); // Brightness: Black to Color
            case 3: return "#000000"; // Red start
            case 4: return "#000000"; // Green start
            case 5: return "#000000"; // Blue start
            case 6: return "#FFFFFF"; // CMYK starts from white usually in this design
            case 7: return "#FFFFFF";
            case 8: return "#FFFFFF";
            case 9: return "#FFFFFF";
            default: return "#000000";
        }
    }

    function getGradientEnd() {
        var type = getSliderType();
        switch(type) {
            case 1: return Qt.hsva(root.currentH, 1.0, root.currentV, 1.0); // Saturation end
            case 2: return Qt.hsva(root.currentH, root.currentS, 1.0, 1.0); // Brightness end
            case 3: return "#FF0000"; // Red end
            case 4: return "#00FF00"; // Green end
            case 5: return "#0000FF"; // Blue end
            case 6: return "#00FFFF"; // Cyan
            case 7: return "#FF00FF"; // Magenta
            case 8: return "#FFFF00"; // Yellow
            case 9: return "#000000"; // Black
            default: return "#FFFFFF";
        }
    }
}
