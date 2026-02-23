import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property var targetCanvas: null
    property color accentColor: "#6366f1"
    
    // Animation State (Mockup)
    property int currentFrame: 1
    property int totalFrames: 120
    property int fps: 24
    property bool isPlaying: false
    property bool loopEnabled: true
    property bool onionSkinEnabled: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12
        
        // --- 1. TOP CONTROL BAR ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            
            // Playback Group
            RowLayout {
                spacing: 4
                TimelineButton { text: "⏮"; onClicked: root.currentFrame = 1 }
                TimelineButton { text: "◀"; onClicked: if(root.currentFrame > 1) root.currentFrame-- }
                
                Rectangle {
                    width: 44; height: 32; radius: 6
                    color: root.isPlaying ? root.accentColor : "#1a1a1f"
                    border.color: root.isPlaying ? Qt.lighter(root.accentColor, 1.2) : "#333"
                    Text { 
                        text: root.isPlaying ? "⏸" : "▶"
                        color: "white"; font.pixelSize: 16; anchors.centerIn: parent 
                    }
                    MouseArea { 
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: root.isPlaying = !root.isPlaying 
                    }
                }
                
                TimelineButton { text: "▶"; onClicked: if(root.currentFrame < root.totalFrames) root.currentFrame++ }
                TimelineButton { text: "⏭"; onClicked: root.currentFrame = root.totalFrames }
            }
            
            // Loop & Onion Toggle
            RowLayout {
                spacing: 6
                TimelineToggle { 
                    text: "Loop"; checked: root.loopEnabled
                    onToggled: root.loopEnabled = !root.loopEnabled 
                }
                TimelineToggle { 
                    text: "Onion Skin"; checked: root.onionSkinEnabled
                    onToggled: root.onionSkinEnabled = !root.onionSkinEnabled 
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // FPS & Info
            RowLayout {
                spacing: 10
                Text { text: "FPS:"; color: "#666"; font.pixelSize: 11 }
                SpinBox {
                    id: fpsSpin
                    from: 1; to: 60; value: root.fps
                    editable: true
                    onValueModified: root.fps = value
                    
                    contentItem: TextInput {
                        text: fpsSpin.textFromValue(fpsSpin.value, fpsSpin.locale)
                        color: "white"; font.pixelSize: 11; horizontalAlignment: Qt.AlignHCenter; verticalAlignment: Qt.AlignVCenter
                        selectByMouse: true
                    }
                    background: Rectangle { implicitWidth: 50; implicitHeight: 26; color: "#0c0c0f"; radius: 4; border.color: "#333" }
                }
                
                Rectangle { width: 1; height: 16; color: "#333" }
                
                Text {
                    text: "Frame: " + root.currentFrame + " / " + root.totalFrames
                    color: "white"; font.pixelSize: 11; font.family: "Monospace"
                    font.weight: Font.DemiBold
                }
            }
        }
        
        // --- 2. LAYERS & TIMELINE AREA ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1
            
            // Layer Headers Column
            ColumnLayout {
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                spacing: 1
                
                Rectangle { Layout.fillWidth: true; height: 24; color: "#111114"; Text { text: "Layers"; color: "#666"; font.pixelSize: 10; anchors.centerIn: parent } }
                
                Repeater {
                    model: ["Capa 3 (Anim)", "Capa 2", "Fondo"]
                    delegate: Rectangle {
                        Layout.fillWidth: true; height: 32; color: "#16161a"; border.color: "#0a0a0d"
                        Text { text: modelData; color: "#aaa"; font.pixelSize: 11; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Item { Layout.fillHeight: true }
            }
            
            // Timeline Content (Scrollable Frames)
            Flickable {
                id: timelineFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: framesRow.width
                clip: true
                onContentXChanged: syncHeaders.x = -contentX
                
                ColumnLayout {
                    id: framesRow
                    spacing: 1
                    
                    // Frame Numbers Header
                    Row {
                        Layout.fillWidth: true; height: 24
                        spacing: 0
                        Repeater {
                            model: root.totalFrames
                            delegate: Rectangle {
                                width: 20; height: 24; color: "#111114"
                                Text { 
                                    text: (index + 1) % 5 === 0 ? (index + 1) : ""
                                    color: (index + 1) === root.currentFrame ? root.accentColor : "#444"
                                    font.pixelSize: 9; anchors.centerIn: parent
                                }
                                Rectangle { width: 1; height: 4; anchors.bottom: parent.bottom; color: "#222" }
                            }
                        }
                    }
                    
                    // Tracks
                    Repeater {
                        model: 3
                        delegate: Row {
                            spacing: 0
                            Repeater {
                                model: root.totalFrames
                                delegate: Rectangle {
                                    width: 20; height: 32; color: "#131316"; border.color: "#0a0a0d"
                                    
                                    // Mock Keyframes
                                    Rectangle {
                                        visible: (index + 1) % 4 === 0 || (index + 1) === 1
                                        width: 14; height: 14; radius: 7; anchors.centerIn: parent
                                        color: (index + index*10) % 3 === 0 ? "#444" : root.accentColor
                                        opacity: (index + 1) === root.currentFrame ? 1.0 : 0.6
                                        scale: (index + 1) === root.currentFrame ? 1.1 : 1.0
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: root.currentFrame = index + 1
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
                
                // Playhead Indicator
                Rectangle {
                    x: (root.currentFrame - 1) * 20 + 9
                    y: 0; width: 2; height: parent.height; color: root.accentColor; z: 10
                    Rectangle { width: 10; height: 10; radius: 5; color: root.accentColor; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }
        
        // --- 3. ONION SKIN SETTINGS (Expandable/Bottom Bar) ---
        Rectangle {
            Layout.fillWidth: true
            height: root.onionSkinEnabled ? 60 : 0
            color: "#0c0c0f"
            radius: 8
            visible: height > 0
            clip: true
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
            
            RowLayout {
                anchors.fill: parent; anchors.margins: 12
                spacing: 20
                
                ColumnLayout {
                    Text { text: "Frames Anteriores"; color: "#666"; font.pixelSize: 10 }
                    RowLayout {
                        Slider { Layout.preferredWidth: 100; from: 0; to: 10; value: 3 }
                        Text { text: "3"; color: "white"; font.pixelSize: 11 }
                    }
                }
                
                ColumnLayout {
                    Text { text: "Frames Posteriores"; color: "#666"; font.pixelSize: 10 }
                    RowLayout {
                        Slider { Layout.preferredWidth: 100; from: 0; to: 10; value: 2 }
                        Text { text: "2"; color: "white"; font.pixelSize: 11 }
                    }
                }
                
                ColumnLayout {
                    Text { text: "Opacidad cebolla"; color: "#666"; font.pixelSize: 10 }
                    Slider { Layout.preferredWidth: 120; from: 0; to: 1.0; value: 0.5 }
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: "Ajustes Avanzados"
                    flat: true
                }
            }
        }
    }
    
    // Internal Helper Component for Buttons
    component TimelineButton : Rectangle {
        property string text: ""
        signal clicked()
        width: 32; height: 32; radius: 6; color: ma.pressed ? "#222" : (ma.containsMouse ? "#1c1c20" : "#131316")
        border.color: ma.containsMouse ? "#444" : "#2a2a2d"
        Text { text: parent.text; color: "white"; font.pixelSize: 14; anchors.centerIn: parent }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }
    
    component TimelineToggle : Rectangle {
        property string text: ""
        property bool checked: false
        signal toggled()
        width: 80; height: 32; radius: 6
        color: checked ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2) : "#131316"
        border.color: checked ? root.accentColor : "#2a2a2d"
        Text { 
            text: parent.text; anchors.centerIn: parent
            color: parent.checked ? "white" : "#666"; font.pixelSize: 11; font.weight: Font.DemiBold 
        }
        MouseArea { anchors.fill: parent; onClicked: parent.toggled() }
    }
}
