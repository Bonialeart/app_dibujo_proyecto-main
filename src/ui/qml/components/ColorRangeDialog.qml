import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects 1.15

Dialog {
    id: root
    width: 680
    height: 480
    modal: true
    anchors.centerIn: parent

    property var canvas: null
    property color accentColor: canvas ? canvas.accentColor : "#6366f1"
    property color targetColor: "#ffffff"
    property real uiScale: 1.0

    background: Rectangle {
        color: "#f816161a" // Glassmorphism dark background
        radius: 16 * uiScale
        border.color: "#30ffffff" // Soft white border
        border.width: 1 * uiScale
    }

    onAboutToShow: {
        // Load initial preview
        updatePreview()
    }

    // Debounce timer for smooth dragging of sliders
    Timer {
        id: debounceTimer
        interval: 80
        repeat: false
        onTriggered: {
            updatePreview()
        }
    }

    function triggerUpdate() {
        debounceTimer.restart()
    }

    function updatePreview() {
        if (!canvas) return
        var base64 = canvas.getColorRangePreview(root.targetColor, toleranceSlider.value, channelCombo.currentIndex, fuzzinessSlider.value, invertCheck.checked)
        previewImage.source = base64
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * uiScale
        spacing: 16 * uiScale

        // --- HEADER ---
        ColumnLayout {
            spacing: 4 * uiScale
            Text {
                text: "Color Range Selection"
                color: "white"
                font.pixelSize: 20 * uiScale
                font.bold: true
            }
            Text {
                text: "Select parts of the image by sampling colors and adjusting similarity."
                color: "#99ffffff"
                font.pixelSize: 12 * uiScale
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1 * uiScale
            color: "#1affffff"
        }

        // --- MAIN AREA (PREVIEW & CONTROLS) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24 * uiScale

            // Left Side: Live Preview
            ColumnLayout {
                spacing: 8 * uiScale
                Layout.preferredWidth: 320 * uiScale
                Layout.fillHeight: true

                Text {
                    text: "Selection Mask Preview"
                    color: "#b3ffffff"
                    font.pixelSize: 11 * uiScale
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#0a0a0c"
                    radius: 8 * uiScale
                    border.color: "#20ffffff"
                    border.width: 1 * uiScale
                    clip: true

                    Image {
                        id: previewImage
                        anchors.fill: parent
                        anchors.margins: 4 * uiScale
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        cache: false

                        // Eyedropper on the preview itself
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.CrossCursor
                            onClicked: (mouse) => {
                                // Map click to original canvas pixels
                                var cx = (mouse.x / parent.width) * canvas.canvasWidth
                                var cy = (mouse.y / parent.height) * canvas.canvasHeight
                                var screenPt = canvas.canvasToScreen(Qt.point(cx, cy))
                                var hexColor = canvas.sampleColor(screenPt.x, screenPt.y, 0)
                                root.targetColor = hexColor
                                triggerUpdate()
                            }
                        }
                    }
                }
            }

            // Right Side: Settings Panel
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: settingsColumn.implicitHeight
                clip: true

                ColumnLayout {
                    id: settingsColumn
                    width: parent.width
                    spacing: 16 * uiScale

                    // 1. Color Selection & Eyedropper
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8 * uiScale

                        Text {
                            text: "Sampled Color"
                            color: "#b3ffffff"
                            font.pixelSize: 11 * uiScale
                            font.bold: true
                        }

                        RowLayout {
                            spacing: 12 * uiScale

                            Rectangle {
                                width: 48 * uiScale
                                height: 32 * uiScale
                                radius: 6 * uiScale
                                color: root.targetColor
                                border.color: "#40ffffff"
                                border.width: 1 * uiScale
                            }

                            Text {
                                text: root.targetColor.toString().toUpperCase()
                                color: "white"
                                font.pixelSize: 13 * uiScale
                                font.family: "Monospace"
                                Layout.fillWidth: true
                            }

                            // Eyedropper Button
                            Button {
                                id: eyeButton
                                implicitWidth: 32 * uiScale
                                implicitHeight: 32 * uiScale
                                ToolTip.visible: hovered
                                ToolTip.text: "Pick color from canvas"

                                background: Rectangle {
                                    color: eyeButton.hovered ? "#30ffffff" : "#15ffffff"
                                    radius: 6 * uiScale
                                    border.color: "#20ffffff"
                                    border.width: 1 * uiScale
                                }

                                contentItem: Image {
                                    source: "../../../../assets/icons/eyedropper.svg"
                                    sourceSize: Qt.size(16 * uiScale, 16 * uiScale)
                                    fillMode: Image.Pad
                                    horizontalAlignment: Image.AlignHCenter
                                    verticalAlignment: Image.AlignVCenter
                                    opacity: eyeButton.hovered ? 1.0 : 0.8
                                }

                                onClicked: {
                                    // Direct eyedropper selection
                                    canvas.currentTool = "eyedropper"
                                    root.close()
                                }
                            }
                        }
                    }

                    // 2. Channel Selection Dropdown
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8 * uiScale

                        Text {
                            text: "Evaluation Channel"
                            color: "#b3ffffff"
                            font.pixelSize: 11 * uiScale
                            font.bold: true
                        }

                        ComboBox {
                            id: channelCombo
                            Layout.fillWidth: true
                            model: [
                                "All Channels (RGB Euclidean)",
                                "Red Channel",
                                "Green Channel",
                                "Blue Channel",
                                "Hue Channel (HSV)",
                                "Saturation Channel (HSV)",
                                "Luminosity Channel (Luminance)"
                            ]

                            onCurrentIndexChanged: triggerUpdate()

                            background: Rectangle {
                                color: "#16161a"
                                border.color: channelCombo.visualFocus ? root.accentColor : "#30ffffff"
                                border.width: 1 * uiScale
                                radius: 8 * uiScale
                            }

                            contentItem: Text {
                                text: channelCombo.displayText
                                color: "white"
                                font.pixelSize: 12 * uiScale
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12 * uiScale
                            }
                        }
                    }

                    // 3. Tolerance Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6 * uiScale

                        RowLayout {
                            Text {
                                text: "Tolerance"
                                color: "#b3ffffff"
                                font.pixelSize: 11 * uiScale
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            Text {
                                text: Math.round(toleranceSlider.value)
                                color: root.accentColor
                                font.pixelSize: 12 * uiScale
                                font.bold: true
                            }
                        }

                        Slider {
                            id: toleranceSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 40
                            onValueChanged: triggerUpdate()
                        }
                    }

                    // 4. Fuzziness Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6 * uiScale

                        RowLayout {
                            Text {
                                text: "Fuzziness (Smoothness)"
                                color: "#b3ffffff"
                                font.pixelSize: 11 * uiScale
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            Text {
                                text: Math.round(fuzzinessSlider.value) + "%"
                                color: root.accentColor
                                font.pixelSize: 12 * uiScale
                                font.bold: true
                            }
                        }

                        Slider {
                            id: fuzzinessSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: 10
                            onValueChanged: triggerUpdate()
                        }
                    }

                    // 5. Invert Mask Checkbox
                    CheckBox {
                        id: invertCheck
                        text: "Invert Selection"
                        font.pixelSize: 12 * uiScale
                        checked: false
                        onCheckedChanged: triggerUpdate()

                        indicator: Rectangle {
                            implicitWidth: 20 * uiScale
                            implicitHeight: 20 * uiScale
                            radius: 4 * uiScale
                            color: invertCheck.checked ? root.accentColor : "transparent"
                            border.color: invertCheck.checked ? root.accentColor : "#40ffffff"
                            border.width: 1.5 * uiScale

                            Image {
                                source: "../../../../assets/icons/check.svg"
                                visible: invertCheck.checked
                                anchors.centerIn: parent
                                sourceSize: Qt.size(12 * uiScale, 12 * uiScale)
                            }
                        }

                        contentItem: Text {
                            text: invertCheck.text
                            font: invertCheck.font
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 28 * uiScale
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1 * uiScale
            color: "#1affffff"
        }

        // --- BUTTONS ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * uiScale

            Item { Layout.fillWidth: true }

            Button {
                id: cancelBtn
                implicitWidth: 100 * uiScale
                implicitHeight: 38 * uiScale

                background: Rectangle {
                    color: cancelBtn.hovered ? "#2a2a2e" : "#1a1a1c"
                    radius: 8 * uiScale
                    border.color: "#30ffffff"
                    border.width: 1 * uiScale
                }

                contentItem: Text {
                    text: "Cancel"
                    color: "white"
                    font.pixelSize: 12 * uiScale
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.close()
            }

            Button {
                id: applyBtn
                implicitWidth: 100 * uiScale
                implicitHeight: 38 * uiScale

                background: Rectangle {
                    color: applyBtn.hovered ? Qt.lighter(root.accentColor, 1.1) : root.accentColor
                    radius: 8 * uiScale
                }

                contentItem: Text {
                    text: "Apply"
                    color: "white"
                    font.pixelSize: 12 * uiScale
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (canvas) {
                        canvas.selectByColorRange(root.targetColor, toleranceSlider.value, channelCombo.currentIndex, fuzzinessSlider.value, invertCheck.checked)
                    }
                    root.close()
                }
            }
        }
    }
}
