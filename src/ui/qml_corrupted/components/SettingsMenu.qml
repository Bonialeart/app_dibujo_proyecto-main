import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../Translations.js" as Trans

Popup {
    id: root
    width: 500
    height: 380
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Position near top left, under the top bar capsule
    x: 20
    y: 70
    
    // --- PROPERTIES & SIGNALS ---
    signal settingsChanged()
    property int currentCategoryIndex: 0
    property var windowRef: null
    property var canvasRef: null

    // Design Tokens
    property string themeMode: (typeof preferencesManager !== "undefined") ? preferencesManager.themeMode : "Dark"
    property color themeAccent: (typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#6366f1"
    
    readonly property bool isDark: themeMode === "Dark" || themeMode === "Midnight" || themeMode === "Blue-Grey"
    
    readonly property color colorBg: isDark ? "#1e1e20" : "#f3f4f6"
    readonly property color colorPanel: isDark ? "#252526" : "#ffffff"
    readonly property color colorAccent: themeAccent
    readonly property color colorText: isDark ? "#ffffff" : "#1f2937"
    readonly property color colorTextMuted: isDark ? "#a1a1aa" : "#6b7280"
    readonly property color colorBorder: isDark ? "#3f3f46" : "#e5e7eb"

    background: Rectangle {
        color: colorBg
        border.color: "#33ffffff"
        border.width: 1
        radius: 16
        layer.enabled: true
    }
    
    contentItem: RowLayout {
        spacing: 0
        
        // --- SIDEBAR ---
        Rectangle {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.1)
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: "Settings"
                    color: colorText
                    font.pixelSize: 14; font.bold: true
                    Layout.leftMargin: 10
                    Layout.bottomMargin: 10
                }

                ListView {
                    id: categoryList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    
                    model: ListModel {
                        ListElement { name: "Actions"; icon: "edit-2.svg"; type: "page" }
                        ListElement { name: "Canvas"; icon: "image.svg"; type: "page" }
                        ListElement { name: "Touch"; icon: "smartphone.svg"; type: "page" }
                        ListElement { name: "Cursor"; icon: "mouse-pointer.svg"; type: "page" }
                        ListElement { name: "Advance"; icon: "sliders.svg"; type: "page" }
                        ListElement { name: "Export"; icon: "save.svg"; type: "page" }
                        ListElement { name: "Exit"; icon: "log-out.svg"; type: "action" }
                    }
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        color: (index === root.currentCategoryIndex && model.type === "page") ? colorAccent : (hoverMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                            spacing: 8
                            
                            Image {
                                source: "image://icons/" + model.icon
                                sourceSize.width: 14; sourceSize.height: 14
                                Layout.alignment: Qt.AlignVCenter
                                opacity: (index === root.currentCategoryIndex && model.type === "page") ? 1.0 : 0.7
                            }
                            
                            Text {
                                text: model.name
                                color: (index === root.currentCategoryIndex && model.type === "page") ? "white" : colorText
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                        
                        MouseArea {
                            id: hoverMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (model.type === "action") root.handleAction(model.name)
                                else root.currentCategoryIndex = index
                            }
                        }
                    }
                }
            }
        }
        
        // --- CONTENT AREA ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            StackLayout {
                anchors.fill: parent
                anchors.margins: 20
                currentIndex: root.currentCategoryIndex
                
                // 0. ACTIONS
                ColumnLayout {
                    spacing: 8
                    Text { text: "Actions"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Undo"; onClicked: { if(canvasRef) canvasRef.undo(); root.close() } }
                    ActionButton { text: "Redo"; onClicked: { if(canvasRef) canvasRef.redo(); root.close() } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff"; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                    ActionButton { text: "Cut"; onClicked: { if(canvasRef) canvasRef.cut(); root.close() } }
                    ActionButton { text: "Copy"; onClicked: { if(canvasRef) canvasRef.copy(); root.close() } }
                    ActionButton { text: "Paste"; onClicked: { if(canvasRef) canvasRef.paste(); root.close() } }
                    Item { Layout.fillHeight: true }
                }
                
                // 1. CANVAS
                ColumnLayout {
                    spacing: 8
                    Text { text: "Canvas"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Flip Horizontal"; onClicked: if(canvasRef) canvasRef.flipCanvasHorizontal() }
                    ActionButton { text: "Flip Vertical"; onClicked: if(canvasRef) canvasRef.flipCanvasVertical() }
                    ActionButton { text: "Reset View"; onClicked: if(canvasRef) canvasRef.fitToView() }
                    Item { Layout.fillHeight: true }
                }

                // 2. TOUCH
                ColumnLayout {
                    spacing: 12
                    Text { text: "Touch Gestures"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    CheckBoxOption { text: "Enable Touch Painting"; checked: true }
                    CheckBoxOption { text: "Undo with 2 Fingers"; checked: true }
                    CheckBoxOption { text: "Redo with 3 Fingers"; checked: true }
                    Item { Layout.fillHeight: true }
                }

                // 3. CURSOR
                ColumnLayout {
                    spacing: 12
                    Text { text: "Cursor"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    CheckBoxOption { text: "Show Brush Outline"; checked: true }
                    CheckBoxOption { text: "Show Crosshair"; checked: false }
                    Item { Layout.fillHeight: true }
                }

                // 4. ADVANCE
                ColumnLayout {
                    spacing: 12
                    Text { text: "Advance"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Pressure Curve Settings"; onClicked: { pressureDialog.open(); root.close() } }
                    CheckBoxOption { text: "High Precision Mode"; checked: true }
                    Item { Layout.fillHeight: true }
                }

                // 5. EXPORT
                ColumnLayout {
                    spacing: 8
                    Text { text: "Export & Save"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Save Project (.stxf)"; onClicked: { if(windowRef) windowRef.saveProjectAndRefresh(); root.close() } }
                    ActionButton { text: "Export Image..."; onClicked: { exportImageDialog.open(); root.close() } }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
    
    function handleAction(name) {
        if (name === "Exit") {
            Qt.quit();
        }
    }
    
    component CheckBoxOption : CheckBox {
        contentItem: Text {
            text: parent.text; color: colorText; font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter; leftPadding: parent.indicator.width + 8
        }
        indicator: Rectangle {
            implicitWidth: 16; implicitHeight: 16; radius: 4
            x: parent.leftPadding; y: parent.height/2 - height/2
            color: parent.checked ? colorAccent : "transparent"
            border.color: parent.checked ? colorAccent : "#555"
            Text { visible: parent.parent.checked; text: "✓"; color: "white"; font.pixelSize: 10; anchors.centerIn: parent }
        }
    }
    
    component ActionButton : MouseArea {
        property string text: ""
        Layout.fillWidth: true
        height: 30
        hoverEnabled: true
        
        Rectangle {
            anchors.fill: parent
            color: parent.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
            radius: 4
        }
        
        Text {
            text: parent.text
            color: colorText
            font.pixelSize: 13
            anchors.left: parent.left; anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
