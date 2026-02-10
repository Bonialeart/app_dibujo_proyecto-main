import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

/**
 * PremiumColorSlider - Sliders con gradientes vibrantes premium
 * Como en la imagen de referencia: gradientes de color completos en cada track
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
    property color baseColor: "#FF0000"
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
            font.weight: Font.Normal
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
                border.color: "#2C2C2E"
                border.width: 0.5
            }
            
            // Colored Track (con gradiente)
            Rectangle {
                id: track
                anchors.fill: parent
                radius: 9
                clip: true
                
                // Usar ShaderEffect para gradientes premium
                ShaderEffect {
                    anchors.fill: parent
                    property real normalizedValue: (root.value - root.minValue) / (root.maxValue - root.minValue)
                    property real hue: root.currentH
                    property real sat: root.currentS
                    property real val: root.currentV
                    property int sliderType: getSliderType()
                    
                    fragmentShader: "
                        varying highp vec2 qt_TexCoord0;
                        uniform lowp float qt_Opacity;
                        uniform highp float hue;
                        uniform highp float sat;
                        uniform highp float val;
                        uniform int sliderType;
                        
                        vec3 hsb2rgb(in vec3 c) {
                            vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
                            rgb = rgb*rgb*(3.0-2.0*rgb);
                            return c.z * mix(vec3(1.0), rgb, c.y);
                        }
                        
                        void main() {
                            float pos = qt_TexCoord0.x;
                            vec3 color = vec3(0.0);
                            
                            // 0: H (Hue) - Full rainbow
                            if (sliderType == 0) {
                                color = hsb2rgb(vec3(pos, 1.0, 1.0));
                            }
                            // 1: S (Saturation) - Gray to full color
                            else if (sliderType == 1) {
                                color = hsb2rgb(vec3(hue, pos, val));
                            }
                            // 2: B/V (Brightness/Value) - Black to full color
                            else if (sliderType == 2) {
                                color = hsb2rgb(vec3(hue, sat, pos));
                            }
                            // 3: R (Red) - Black to red
                            else if (sliderType == 3) {
                                color = vec3(pos, 0.0, 0.0);
                            }
                            // 4: G (Green) - Black to green
                            else if (sliderType == 4) {
                                color = vec3(0.0, pos, 0.0);
                            }
                            // 5: B (Blue) - Black to blue
                            else if (sliderType == 5) {
                                color = vec3(0.0, 0.0, pos);
                            }
                            // 6: C (Cyan) - White to Cyan
                            else if (sliderType == 6) {
                                color = mix(vec3(1.0), vec3(0.0, 1.0, 1.0), pos);
                            }
                            // 7: M (Magenta) - White to Magenta
                            else if (sliderType == 7) {
                                color = mix(vec3(1.0), vec3(1.0, 0.0, 1.0), pos);
                            }
                            // 8: Y (Yellow) - White to Yellow
                            else if (sliderType == 8) {
                                color = mix(vec3(1.0), vec3(1.0, 1.0, 0.0), pos);
                            }
                            // 9: K (Key/Black) - White to Black
                            else if (sliderType == 9) {
                                color = vec3(1.0 - pos);
                            }
                            
                            gl_FragColor = vec4(color, 1.0) * qt_Opacity;
                        }
                    "
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
                
                // Color blanco/gris claro
                color: "#F5F5F7"
                border.color: "#FFFFFF"
                border.width: 2
                
                // Sombra premium
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 10
                    shadowColor: "#A0000000"
                    shadowVerticalOffset: 2
                }
                
                // Hover effect
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
                    var clickX = mouse.x + 8  // Compensar margin
                    var trackX = Math.max(0, Math.min(track.width, clickX))
                    var normalized = trackX / track.width
                    var newValue = root.minValue + normalized * (root.maxValue - root.minValue)
                    root.sliderMoved(newValue)
                }
            }
        }
        
        // Value Display (Editable)
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 22
            radius: 6
            color: "#1C1C1E"
            border.color: "#2C2C2E"
            border.width: 0.5
            
            TextInput {
                id: valueInput
                anchors.centerIn: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                text: getFormattedValue()
                color: "#FFFFFF"
                font.pixelSize: 11
                font.family: "Monospace"
                selectByMouse: true
                horizontalAlignment: Text.AlignRight
                
                onEditingFinished: {
                    var v = parseFloat(text)
                    if (!isNaN(v)) {
                        var realValue = v
                        // Si es porcentaje, convertir
                        if (root.maxValue === 1.0 && root.unit === "%") {
                            realValue = v / 100.0
                        }
                        realValue = Math.max(root.minValue, Math.min(root.maxValue, realValue))
                        root.sliderMoved(realValue)
                    }
                }
            }
        }
    }
    
    // Helper Functions
    function calculateHandleX() {
        var normalized = (root.value - root.minValue) / (root.maxValue - root.minValue)
        return Math.max(0, Math.min(track.width - handle.width, normalized * (track.width - handle.width)))
    }
    
    function getFormattedValue() {
        var v = root.value
        
        if (root.maxValue === 1.0 && root.unit === "%") {
            return Math.round(v * 100)
        } else if (root.maxValue === 360) {
            return Math.round(v)
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
}
