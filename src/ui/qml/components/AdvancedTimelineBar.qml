import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

// ══════════════════════════════════════════════════════════════
//  ADVANCED TIMELINE BAR — Procreate Dreams-style
// ══════════════════════════════════════════════════════════════
Item {
    id: root

    property var    targetCanvas:   null
    property color  accentColor:    "#ff3366" // Dreams red-pink accent
    property int    projectFPS:     24
    property bool   isPlaying:      false

    // ── Main Container ───────────────────────────────────────
    Rectangle {
        id: container
        anchors.fill: parent
        radius: 16
        color: "#0a0a0c"
        border.color: "#1c1c20"
        border.width: 1
        clip: true

        // Background subtle noise/grid (optional)
        Image {
            anchors.fill: parent
            source: "image://icons/grid_pattern.svg"
            fillMode: Image.Tile
            opacity: 0.05
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── HEADER ───────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Project Icon
                    Image {
                        source: "image://icons/layout.svg"
                        width: 18; height: 18
                        opacity: 0.5
                    }

                    // Project Title
                    Text {
                        text: targetCanvas && targetCanvas.currentProjectName !== "" ? targetCanvas.currentProjectName : "Into The Future"
                        color: "white"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    // Toolbar Icons
                    Row {
                        spacing: 20
                        Layout.alignment: Qt.AlignVCenter

                        // Play
                        MouseArea {
                            width: 24; height: 24
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isPlaying = !root.isPlaying
                            Image {
                                source: root.isPlaying ? "image://icons/pause.svg" : "image://icons/play.svg"
                                anchors.centerIn: parent
                                width: 20; height: 20
                                opacity: parent.containsMouse ? 1.0 : 0.8
                            }
                        }

                        // Record
                        MouseArea {
                            width: 24; height: 24
                            cursorShape: Qt.PointingHandCursor
                            Rectangle {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                radius: 7
                                color: parent.containsMouse ? "white" : "#ccc"
                            }
                        }

                        // Onion Skin / Media
                        MouseArea {
                            width: 24; height: 24
                            cursorShape: Qt.PointingHandCursor
                            Image {
                                source: "image://icons/layers.svg"
                                anchors.centerIn: parent
                                width: 20; height: 20
                                opacity: parent.containsMouse ? 1.0 : 0.8
                            }
                        }

                        // Draw / Scribble
                        MouseArea {
                            width: 24; height: 24
                            cursorShape: Qt.PointingHandCursor
                            Image {
                                source: "image://icons/edit-3.svg"
                                anchors.centerIn: parent
                                width: 20; height: 20
                                opacity: parent.containsMouse ? 1.0 : 0.8
                            }
                        }

                        // Add
                        MouseArea {
                            width: 24; height: 24
                            cursorShape: Qt.PointingHandCursor
                            Image {
                                source: "image://icons/plus.svg"
                                anchors.centerIn: parent
                                width: 22; height: 22
                                opacity: parent.containsMouse ? 1.0 : 0.8
                            }
                        }

                        // Switch Mode (Flipbook)
                        MouseArea {
                            width: 24; height: 24
                            cursorShape: Qt.PointingHandCursor
                            ToolTip.text: "Volver al Modo Simple (Flipbook)"
                            ToolTip.visible: containsMouse
                            ToolTip.delay: 400
                            onClicked: {
                                if (typeof mainWindow !== "undefined") {
                                    mainWindow.useAdvancedTimeline = false;
                                }
                            }
                            Text {
                                text: "📄"
                                anchors.centerIn: parent
                                font.pixelSize: 15
                                opacity: parent.containsMouse ? 1.0 : 0.8
                            }
                        }
                    }
                }
            }

            // ── RULER / TIMECODE ──────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                color: "transparent"
                border.color: "#1c1c20"
                border.width: 1
                
                // Remove horizontal borders except bottom if desired
                Rectangle { width: parent.width; height: 1; color: "#111"; anchors.top: parent.top }
                Rectangle { width: parent.width; height: 1; color: "#222"; anchors.bottom: parent.bottom }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    spacing: 60
                    Repeater {
                        model: 20
                        Item {
                            width: 1; height: 24
                            Rectangle { width: 1; height: 8; color: "#555"; anchors.bottom: parent.bottom }
                            Text {
                                text: (index - 2) + "s"
                                color: "#888"
                                font.pixelSize: 9
                                font.family: "Monospace"
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
                
                // Minor ticks
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    spacing: 12
                    Repeater {
                        model: 100
                        Rectangle {
                            width: 1; height: 4
                            color: "#333"
                            anchors.bottom: parent.bottom
                        }
                    }
                }
            }

            // ── TRACKS AREA ───────────────────────────────────────
            Flickable {
                id: trackFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: 2000
                contentHeight: 200
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                // Background
                Rectangle { anchors.fill: parent; color: "#000000" }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // AUDIO TRACK
                    Rectangle {
                        width: 1800
                        height: 38
                        radius: 6
                        color: "#1a0810" // Dark reddish background
                        border.color: root.accentColor
                        border.width: 1

                        // Label
                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.top: parent.top; anchors.topMargin: 4
                            spacing: 4
                            Rectangle { width: 10; height: 10; radius: 2; color: "white"; anchors.verticalCenter: parent.verticalCenter; Image { source: "image://icons/check.svg"; anchors.fill: parent; anchors.margins: 2; opacity: 0.8 } }
                            Text { text: "Audio"; color: "white"; font.pixelSize: 9; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        // Fake Waveform
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 60
                            spacing: 2
                            Repeater {
                                model: 300
                                Rectangle {
                                    width: 1.5
                                    height: Math.random() * 24 + 4
                                    radius: 1
                                    color: "#ff6688"
                                    opacity: 0.8
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // VIDEO TRACK (SCENES)
                    Row {
                        spacing: 8
                        
                        // Scene 1
                        Rectangle {
                            width: 120; height: 50; radius: 6
                            color: "#222"
                            Image { source: targetCanvas && targetCanvas.currentProjectPath ? "image://projects/" + targetCanvas.currentProjectName : ""; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; opacity: 0.4 }
                            Rectangle { width: parent.width; height: parent.height; color: "transparent"; border.color: "#444"; border.width: 1; radius: 6 }
                            
                            // Pill
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 4
                                height: 16; width: label1.contentWidth + 24; radius: 8
                                color: "white"
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Rectangle { width: 8; height: 8; radius: 2; color: "black"; anchors.verticalCenter: parent.verticalCenter; Image { source: "image://icons/check.svg"; anchors.fill: parent; opacity: 0.8 } }
                                    Text { id: label1; text: "Scene 1 - Camera >"; color: "black"; font.pixelSize: 8; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }

                        // Scene 2
                        Rectangle {
                            width: 200; height: 50; radius: 6
                            color: "#222"
                            Image { source: targetCanvas && targetCanvas.currentProjectPath ? "image://projects/" + targetCanvas.currentProjectName : ""; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; opacity: 0.4 }
                            Rectangle { width: parent.width; height: parent.height; color: "transparent"; border.color: "#444"; border.width: 1; radius: 6 }
                            
                            // Pill
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 4
                                height: 16; width: label2.contentWidth + 24; radius: 8
                                color: "white"
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Rectangle { width: 8; height: 8; radius: 2; color: "black"; anchors.verticalCenter: parent.verticalCenter; Image { source: "image://icons/check.svg"; anchors.fill: parent; opacity: 0.8 } }
                                    Text { id: label2; text: "Scene 2 - Camera >"; color: "black"; font.pixelSize: 8; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }

                        // Scene 3
                        Rectangle {
                            width: 180; height: 50; radius: 6
                            color: "#222"
                            Image { source: targetCanvas && targetCanvas.currentProjectPath ? "image://projects/" + targetCanvas.currentProjectName : ""; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; opacity: 0.4 }
                            Rectangle { width: parent.width; height: parent.height; color: "transparent"; border.color: "#444"; border.width: 1; radius: 6 }
                            
                            // Pill
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 4
                                height: 16; width: label3.contentWidth + 24; radius: 8
                                color: "white"
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Rectangle { width: 8; height: 8; radius: 2; color: "black"; anchors.verticalCenter: parent.verticalCenter; Image { source: "image://icons/check.svg"; anchors.fill: parent; opacity: 0.8 } }
                                    Text { id: label3; text: "Scene 3 - Camera >"; color: "black"; font.pixelSize: 8; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }

                        // Scene 5 (Selected)
                        Rectangle {
                            width: 100; height: 50; radius: 6
                            color: "#3b5998"
                            Rectangle { width: parent.width; height: parent.height; color: "transparent"; border.color: "#5b79b8"; border.width: 1; radius: 6; opacity: 0.5 }
                            
                            // Pill
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 4
                                height: 16; width: label5.contentWidth + 24; radius: 8
                                color: "#5b89f8"
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Rectangle { width: 8; height: 8; radius: 2; color: "white"; anchors.verticalCenter: parent.verticalCenter; Image { source: "image://icons/check.svg"; anchors.fill: parent; opacity: 0.8 } }
                                    Text { id: label5; text: "Scene 5 >"; color: "white"; font.pixelSize: 8; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }

                    // BOTTOM HANDLES (Red crop marks)
                    Item {
                        width: parent.width
                        height: 20
                        Row {
                            spacing: 120
                            anchors.left: parent.left; anchors.leftMargin: 20
                            Repeater {
                                model: 8
                                Image {
                                    source: "image://icons/crop.svg"
                                    width: 14; height: 14
                                    sourceSize: Qt.size(14, 14)
                                    // Make it pink/red like in Dreams
                                    layer.enabled: true
                                    layer.effect: MultiEffect { colorization: 1.0; colorizationColor: root.accentColor }
                                }
                            }
                        }
                    }
                }

                // ── PLAYHEAD ───────────────────────────────────────
                Item {
                    id: playhead
                    x: 350 // Default position
                    y: 0
                    width: 32; height: trackFlickable.contentHeight
                    z: 50

                    Rectangle {
                        width: 2; height: parent.height
                        color: root.accentColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Playhead Handle (Clapper)
                    Rectangle {
                        width: 32; height: 26; radius: 13
                        color: root.accentColor
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -40

                        Image {
                            source: "image://icons/video.svg"
                            anchors.centerIn: parent
                            width: 14; height: 14
                            opacity: 0.9
                        }
                        
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 10; shadowColor: root.accentColor; opacity: 0.4 }

                        MouseArea {
                            anchors.fill: parent
                            drag.target: playhead
                            drag.axis: Drag.XAxis
                            cursorShape: Qt.SizeHorCursor
                        }
                    }
                }
            }
        }
    }
}
