import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ═══════════════════════════════════════════════════════════
// BubbleSettingsPanel - Dynamic, premium customizable sidebar
// controls for speech bubbles (oval, rounded rect, colors, text)
// ═══════════════════════════════════════════════════════════
Item {
    id: root
    
    property var comicOverlay: null
    property color accentColor: "#6366f1"
    
    // Bind activeBubble directly to the reactive selected bubble delegate
    property var activeBubble: comicOverlay ? comicOverlay.selectedBubbleDelegate : null
    
    function updateProperty(name, val) {
        if (activeBubble) {
            var propName = name;
            if (name === "type") propName = "bubbleType";
            activeBubble[propName] = val;
        }
    }
    
    // Main UI Layout
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainCol.height + 30
        clip: true
        
        ScrollBar.vertical: ScrollBar {
            width: 4
            contentItem: Rectangle { color: "#333"; radius: 2 }
        }
        
        ColumnLayout {
            id: mainCol
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            
            Item { width: 1; height: 4 } // Top padding
            
            // If no bubble is selected
            Text {
                visible: !activeBubble
                text: "Select a speech bubble\nto customize it"
                color: "#666"
                font.pixelSize: 13
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                topPadding: 100
            }
            
            // Settings form (only visible when bubble selected)
            ColumnLayout {
                visible: !!activeBubble
                Layout.fillWidth: true
                spacing: 18
                
                // ─── SHAPE CATEGORY ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Row {
                        spacing: 8
                        Rectangle { width: 3; height: 12; radius: 1; color: accentColor; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "BUBBLE SHAPE"; color: "#777"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    }
                    
                    // Grid of Bubble Types
                    GridLayout {
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6
                        Layout.fillWidth: true
                        
                        Repeater {
                            model: [
                                { id: "oval", label: "Oval" },
                                { id: "rounded_rect", label: "Rounded" },
                                { id: "rect", label: "Square" },
                                { id: "double_oval", label: "Double Oval" },
                                { id: "double_rounded", label: "Double Round" },
                                { id: "thought", label: "Thought" },
                                { id: "shout", label: "Shout" },
                                { id: "narration", label: "Narration" }
                            ]
                            
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 32; radius: 8
                                color: (activeBubble && activeBubble.bubbleType === modelData.id) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : "#141416"
                                border.color: (activeBubble && activeBubble.bubbleType === modelData.id) ? accentColor : "#222"
                                border.width: 1
                                
                                Text {
                                    text: modelData.label
                                    anchors.centerIn: parent
                                    color: (activeBubble && activeBubble.bubbleType === modelData.id) ? "white" : "#aaa"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        updateProperty("type", modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e22" }
                
                // ─── GEOMETRY SLIDERS ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Row {
                        spacing: 8
                        Rectangle { width: 3; height: 12; radius: 1; color: "#10b981"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "GEOMETRY SIZES"; color: "#777"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    }
                    
                    // Border Thickness Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Text { text: "Border Thickness"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: Math.round(sliderStroke.value) + "px"; color: accentColor; font.pixelSize: 11; font.bold: true }
                        }
                        Slider {
                            id: sliderStroke
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            height: 36
                            from: 1; to: 15; stepSize: 1
                            value: activeBubble ? activeBubble.strokeWidth : 3
                            onMoved: updateProperty("strokeWidth", value)
                            background: Rectangle { y: 15; width: parent.width; height: 6; radius: 3; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: accentColor } }
                            handle: Rectangle { x: parent.visualPosition * (parent.width - width); y: 8; width: 20; height: 20; radius: 10; color: "#fff" }
                        }
                    }
                    
                    // Tail Base Width Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: activeBubble ? (activeBubble.bubbleType !== "narration") : true
                        RowLayout {
                            Text { text: "Tail Width"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: Math.round(sliderTailWidth.value) + "px"; color: accentColor; font.pixelSize: 11; font.bold: true }
                        }
                        Slider {
                            id: sliderTailWidth
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            height: 36
                            from: 10; to: 80; stepSize: 1
                            value: activeBubble ? activeBubble.tailWidth : 30
                            onMoved: updateProperty("tailWidth", value)
                            background: Rectangle { y: 15; width: parent.width; height: 6; radius: 3; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: accentColor } }
                            handle: Rectangle { x: parent.visualPosition * (parent.width - width); y: 8; width: 20; height: 20; radius: 10; color: "#fff" }
                        }
                    }
                    
                    // Corner Radius (Only Rounded Rect)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: activeBubble ? (activeBubble.bubbleType === "rounded_rect" || activeBubble.bubbleType === "double_rounded") : false
                        RowLayout {
                            Text { text: "Corner Radius"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: Math.round(sliderCorner.value) + "px"; color: accentColor; font.pixelSize: 11; font.bold: true }
                        }
                        Slider {
                            id: sliderCorner
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            height: 36
                            from: 0; to: 50; stepSize: 1
                            value: activeBubble ? activeBubble.cornerRadius : 16
                            onMoved: updateProperty("cornerRadius", value)
                            background: Rectangle { y: 15; width: parent.width; height: 6; radius: 3; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: accentColor } }
                            handle: Rectangle { x: parent.visualPosition * (parent.width - width); y: 8; width: 20; height: 20; radius: 10; color: "#fff" }
                        }
                    }
                }
                
                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e22" }
                
                // ─── COLORS CATEGORY ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Row {
                        spacing: 8
                        Rectangle { width: 3; height: 12; radius: 1; color: "#f59e0b"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "COLORS"; color: "#777"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    }
                    
                    // Fill Color Options
                    Text { text: "Fill Color"; color: "#aaa"; font.pixelSize: 11 }
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        
                        Repeater {
                            model: [
                                { hex: "#ffffff", label: "White" },
                                { hex: "#fffdd0", label: "Cream" },
                                { hex: "#fff9c4", label: "Yellow" },
                                { hex: "#f3f4f6", label: "Grey" },
                                { hex: "transparent", label: "Transp" }
                            ]
                            delegate: Rectangle {
                                width: 28; height: 28; radius: 14
                                color: modelData.hex === "transparent" ? "transparent" : modelData.hex
                                border.color: (activeBubble && activeBubble.fillColor === modelData.hex) ? accentColor : "#444"
                                border.width: (activeBubble && activeBubble.fillColor === modelData.hex) ? 2 : 1
                                
                                // checkerboard for transparent
                                Rectangle {
                                    visible: modelData.hex === "transparent"
                                    anchors.fill: parent; radius: 14; color: "transparent"; z: -1
                                    border.color: "#888"; border.width: 1
                                    Text { text: "∅"; color: "#888"; font.pixelSize: 18; font.bold: true; anchors.centerIn: parent }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: updateProperty("fillColor", modelData.hex)
                                }
                            }
                        }
                        
                        // Use active brush color
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 8
                            color: "#1a1a20"; border.color: "#333"; border.width: 1
                            Text { text: "Use Active"; color: "#ccc"; font.pixelSize: 10; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (comicOverlay && comicOverlay.targetCanvas) {
                                        updateProperty("fillColor", comicOverlay.targetCanvas.brushColor.toString())
                                    }
                                }
                            }
                        }
                    }
                    
                    // Stroke Color Options
                    Text { text: "Outline Color"; color: "#aaa"; font.pixelSize: 11 }
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        
                        Repeater {
                            model: [
                                { hex: "#000000", label: "Black" },
                                { hex: "#d32f2f", label: "Red" },
                                { hex: "#1a237e", label: "Navy" },
                                { hex: "#4b5563", label: "Grey" }
                            ]
                            delegate: Rectangle {
                                width: 28; height: 28; radius: 14
                                color: modelData.hex
                                border.color: (activeBubble && activeBubble.strokeColor === modelData.hex) ? accentColor : "#444"
                                border.width: (activeBubble && activeBubble.strokeColor === modelData.hex) ? 2 : 1
                                
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: updateProperty("strokeColor", modelData.hex)
                                }
                            }
                        }
                        
                        // Use active brush color
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 8
                            color: "#1a1a20"; border.color: "#333"; border.width: 1
                            Text { text: "Use Active"; color: "#ccc"; font.pixelSize: 10; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (comicOverlay && comicOverlay.targetCanvas) {
                                        updateProperty("strokeColor", comicOverlay.targetCanvas.brushColor.toString())
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e22" }
                
                // ─── AUTO ADJUSTMENT CATEGORY ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Row {
                        spacing: 8
                        Rectangle { width: 3; height: 12; radius: 1; color: "#ec4899"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "AUTO ADJUSTMENTS"; color: "#777"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    }
                    
                    // Height Auto-resize toggle
                    RowLayout {
                        Layout.fillWidth: true
                        height: 28
                        Text { text: "Auto-resize Height"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                        
                        Rectangle {
                            id: toggleAutoResize
                            width: 42; height: 22; radius: 11
                            color: active ? accentColor : "#222226"
                            border.color: active ? Qt.lighter(accentColor, 1.2) : "#333"
                            property bool active: activeBubble ? activeBubble.autoResize : false
                            
                            Rectangle { x: parent.active ? 22 : 2; y: 2; width: 18; height: 18; radius: 9; color: "#fff"
                                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    updateProperty("autoResize", !toggleAutoResize.active)
                                    if (!toggleAutoResize.active) {
                                        updateProperty("autoFitText", false)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Auto-fit Font Size toggle
                    RowLayout {
                        Layout.fillWidth: true
                        height: 28
                        Text { text: "Auto-fit Font Size"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                        
                        Rectangle {
                            id: toggleAutoFit
                            width: 42; height: 22; radius: 11
                            color: active ? accentColor : "#222226"
                            border.color: active ? Qt.lighter(accentColor, 1.2) : "#333"
                            property bool active: activeBubble ? activeBubble.autoFitText : false
                            
                            Rectangle { x: parent.active ? 22 : 2; y: 2; width: 18; height: 18; radius: 9; color: "#fff"
                                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    updateProperty("autoFitText", !toggleAutoFit.active)
                                    if (!toggleAutoFit.active) {
                                        updateProperty("autoResize", false)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e22" }
                
                // ─── TYPOGRAPHY CATEGORY ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Row {
                        spacing: 8
                        Rectangle { width: 3; height: 12; radius: 1; color: "#3b82f6"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "TYPOGRAPHY"; color: "#777"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    }
                    
                    // Font Family
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: "Font Family"; color: "#aaa"; font.pixelSize: 11 }
                        
                        RowLayout {
                            spacing: 4
                            Layout.fillWidth: true
                            Repeater {
                                model: [
                                    { id: "Comic Sans MS, sans-serif", label: "Comic" },
                                    { id: "Impact, sans-serif", label: "Manga" },
                                    { id: "Arial, sans-serif", label: "Sans" },
                                    { id: "Courier New, monospace", label: "Mono" }
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 28; radius: 6
                                    color: (activeBubble && activeBubble.fontFamily === modelData.id) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : "#141416"
                                    border.color: (activeBubble && activeBubble.fontFamily === modelData.id) ? accentColor : "#222"
                                    border.width: 1
                                    
                                    Text {
                                        text: modelData.label
                                        anchors.centerIn: parent
                                        color: (activeBubble && activeBubble.fontFamily === modelData.id) ? "white" : "#888"
                                        font.pixelSize: 10; font.bold: modelData.label === "Manga"
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: updateProperty("fontFamily", modelData.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Font Size Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Text { text: "Font Size"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                            Text { text: Math.round(sliderFontSize.value) + "pt"; color: accentColor; font.pixelSize: 11; font.bold: true }
                        }
                        Slider {
                            id: sliderFontSize
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            height: 36
                            from: 8; to: 60; stepSize: 1
                            enabled: activeBubble ? !activeBubble.autoFitText : true
                            opacity: enabled ? 1.0 : 0.4
                            value: activeBubble ? activeBubble.fontSize : 18
                            onMoved: updateProperty("fontSize", value)
                            background: Rectangle { y: 15; width: parent.width; height: 6; radius: 3; color: "#222"
                                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 3; color: accentColor } }
                            handle: Rectangle { x: parent.visualPosition * (parent.width - width); y: 8; width: 20; height: 20; radius: 10; color: "#fff" }
                        }
                    }
                    
                    // Font Styling (Bold, Italic)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        RowLayout {
                            Layout.fillWidth: true
                            height: 28
                            Text { text: "Bold"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                            Rectangle {
                                id: toggleBold
                                width: 38; height: 20; radius: 10
                                color: active ? accentColor : "#222226"
                                border.color: active ? Qt.lighter(accentColor, 1.2) : "#333"
                                property bool active: activeBubble ? activeBubble.bold : false
                                Rectangle { x: parent.active ? 20 : 2; y: 2; width: 16; height: 16; radius: 8; color: "#fff"
                                    Behavior on x { NumberAnimation { duration: 100 } } }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { updateProperty("bold", !toggleBold.active) }
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            height: 28
                            Text { text: "Italic"; color: "#aaa"; font.pixelSize: 11; Layout.fillWidth: true }
                            Rectangle {
                                id: toggleItalic
                                width: 38; height: 20; radius: 10
                                color: active ? accentColor : "#222226"
                                border.color: active ? Qt.lighter(accentColor, 1.2) : "#333"
                                property bool active: activeBubble ? activeBubble.italic : false
                                Rectangle { x: parent.active ? 20 : 2; y: 2; width: 16; height: 16; radius: 8; color: "#fff"
                                    Behavior on x { NumberAnimation { duration: 100 } } }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { updateProperty("italic", !toggleItalic.active) }
                                }
                            }
                        }
                    }
                    
                    // Text Color Presets
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: "Text Color"; color: "#aaa"; font.pixelSize: 11 }
                        
                        RowLayout {
                            spacing: 8
                            Layout.fillWidth: true
                            
                            Repeater {
                                model: ["#000000", "#ffffff", "#d32f2f", "#1a237e"]
                                delegate: Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: modelData
                                    border.color: (activeBubble && activeBubble.textColor === modelData) ? accentColor : "#555"
                                    border.width: (activeBubble && activeBubble.textColor === modelData) ? 2 : 1
                                    
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: updateProperty("textColor", modelData)
                                    }
                                }
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            // Text Alignments
                            RowLayout {
                                spacing: 2
                                Repeater {
                                    model: [
                                        { id: Text.AlignLeft, symbol: "├" },
                                        { id: Text.AlignHCenter, symbol: "┼" },
                                        { id: Text.AlignRight, symbol: "┤" }
                                    ]
                                    delegate: Rectangle {
                                        width: 24; height: 24; radius: 4
                                        color: (activeBubble && activeBubble.alignment === modelData.id) ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : "#141416"
                                        border.color: (activeBubble && activeBubble.alignment === modelData.id) ? accentColor : "#222"
                                        border.width: 1
                                        
                                        Text { text: modelData.symbol; color: "white"; font.pixelSize: 12; anchors.centerIn: parent }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: updateProperty("alignment", modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
