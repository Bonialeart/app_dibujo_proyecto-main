// REEMPLAZO PARA LA SECCIÓN DE SLIDERS (Líneas 360-478)
// Modo 2: SLIDERS con Gradientes Premium

Item {
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        
        ColumnLayout {
            width: parent.parent.width
            spacing: 16
            topPadding: 16
            bottomPadding: 16
            
            // 1. HSB GROUP - Con gradientes vibrantes
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                color: "#161618"
                radius: 12
                border.color: "#252525"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "H"
                        value: root.h * 360
                        maxValue: 360
                        unit: "°"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.h = val / 360
                            root.updateColor()
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "S"
                        value: root.s
                        maxValue: 1.0
                        unit: "%"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.s = val
                            root.updateColor()
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "B"
                        value: root.v
                        maxValue: 1.0
                        unit: "%"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.v = val
                            root.updateColor()
                        }
                    }
                }
            }
            
            // 2. RGB GROUP - Con gradientes vibrantes
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                color: "#161618"
                radius: 12
                border.color: "#252525"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "R"
                        value: root.currentColor.r * 255
                        maxValue: 255
                        unit: ""
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            var c = root.currentColor
                            root.currentColor = Qt.rgba(val/255, c.g, c.b, 1.0)
                            root.h = root.currentColor.hsvHue
                            root.s = root.currentColor.hsvSaturation
                            root.v = root.currentColor.hsvValue
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "G"
                        value: root.currentColor.g * 255
                        maxValue: 255
                        unit: ""
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            var c = root.currentColor
                            root.currentColor = Qt.rgba(c.r, val/255, c.b, 1.0)
                            root.h = root.currentColor.hsvHue
                            root.s = root.currentColor.hsvSaturation
                            root.v = root.currentColor.hsvValue
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "B"
                        value: root.currentColor.b * 255
                        maxValue: 255
                        unit: ""
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            var c = root.currentColor
                            root.currentColor = Qt.rgba(c.r, c.g, val/255, 1.0)
                            root.h = root.currentColor.hsvHue
                            root.s = root.currentColor.hsvSaturation
                            root.v = root.currentColor.hsvValue
                        }
                    }
                }
            }
            
            // 3. CMYK GROUP - Con gradientes vibrantes
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                color: "#161618"
                radius: 12
                border.color: "#252525"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4
                    
                    property var cmyk: root.getCMYK()
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "C"
                        value: parent.cmyk.c
                        maxValue: 1.0
                        unit: "%"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.setCMYK(val, parent.cmyk.m, parent.cmyk.y, parent.cmyk.k)
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "M"
                        value: parent.cmyk.m
                        maxValue: 1.0
                        unit: "%"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.setCMYK(parent.cmyk.c, val, parent.cmyk.y, parent.cmyk.k)
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "Y"
                        value: parent.cmyk.y
                        maxValue: 1.0
                        unit: "%"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.setCMYK(parent.cmyk.c, parent.cmyk.m, val, parent.cmyk.k)
                        }
                    }
                    
                    PremiumColorSlider {
                        Layout.fillWidth: true
                        label: "K"
                        value: parent.cmyk.k
                        maxValue: 1.0
                        unit: "%"
                        currentH: root.h
                        currentS: root.s
                        currentV: root.v
                        onSliderMoved: (val) => {
                            root.setCMYK(parent.cmyk.c, parent.cmyk.m, parent.cmyk.y, val)
                        }
                    }
                }
            }
            
            // 4. HEXADECIMAL - Mantenido igual
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 12
                color: "#161618"
                border.color: "#252525"
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    
                    Text {
                        text: "Hex Code"
                        color: "#8E8E93"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Copy button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: "transparent"
                        
                        Text {
                            text: "⎘"
                            color: "#5E5CE6"
                            anchors.centerIn: parent
                            font.pixelSize: 16
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Copy to clipboard logic
                            }
                        }
                    }
                    
                    // Paste button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: "transparent"
                        
                        Text {
                            text: "❐"
                            color: "#5E5CE6"
                            anchors.centerIn: parent
                            font.pixelSize: 16
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                    
                    // Hex input
                    Rectangle {
                        width: 80
                        height: 26
                        radius: 6
                        color: "#1C1C1E"
                        border.color: "#2C2C2E"
                        
                        TextInput {
                            id: hexInput
                            anchors.centerIn: parent
                            text: "#" + root.currentColor.toString().toUpperCase().substring(1, 7)
                            color: "white"
                            font.pixelSize: 10
                            font.family: "Monospace"
                            selectByMouse: true
                            
                            onEditingFinished: {
                                root.currentColor = text
                                root.h = root.currentColor.hsvHue
                                root.s = root.currentColor.hsvSaturation
                                root.v = root.currentColor.hsvValue
                            }
                        }
                    }
                }
            }
        }
    }
}
