import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../Translations.js" as Trans

Popup {
    id: root
    width: 560
    height: 440
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Position near top left, under the top bar capsule
    x: 20
    y: 70
    
    // --- PROPERTIES & SIGNALS ---
    signal settingsChanged
    property int currentCategoryIndex: 0
    property var windowRef: null
    property var canvasRef: null

    // Design Tokens
    property string themeMode: (preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeMode : "Dark"
    property color themeAccent: (preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#6366f1"
    
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
            Layout.preferredWidth: 170
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.1)
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: "Opciones"
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
                        ListElement { name: "Editar"; icon: "edit-2.svg"; type: "page" }
                        ListElement { name: "Herramientas"; icon: "sliders.svg"; type: "page" }
                        ListElement { name: "Canvas"; icon: "image.svg"; type: "page" }
                        ListElement { name: "Táctil"; icon: "smartphone.svg"; type: "page" }
                        ListElement { name: "Cursor"; icon: "mouse-pointer.svg"; type: "page" }
                        ListElement { name: "Avanzado"; icon: "settings.svg"; type: "page" }
                        ListElement { name: "Exportar"; icon: "save.svg"; type: "page" }
                        ListElement { name: "Salir"; icon: "log-out.svg"; type: "action" }
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
                
                // 0. EDITAR (Edit / Actions)
                ColumnLayout {
                    spacing: 8
                    Text { text: "Editar"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Deshacer"; shortcutText: "Ctrl+Z"; onClicked: { if(canvasRef) canvasRef.undo(); root.close() } }
                    ActionButton { text: "Rehacer"; shortcutText: "Ctrl+Y"; onClicked: { if(canvasRef) canvasRef.redo(); root.close() } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff"; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                    ActionButton { text: "Cortar"; shortcutText: "Ctrl+X"; onClicked: { if(canvasRef) canvasRef.cut(); root.close() } }
                    ActionButton { text: "Copiar"; shortcutText: "Ctrl+C"; onClicked: { if(canvasRef) canvasRef.copy(); root.close() } }
                    ActionButton { text: "Pegar"; shortcutText: "Ctrl+V"; onClicked: { if(canvasRef) canvasRef.paste(); root.close() } }
                    Item { Layout.fillHeight: true }
                }
                
                // 1. HERRAMIENTAS (Tools)
                ColumnLayout {
                    spacing: 8
                    Text { text: "Herramientas"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Transformación libre"; shortcutText: "Ctrl+T"; onClicked: { if(canvasRef) { canvasRef.isFreeTransformActive = true }; root.close() } }
                    ActionButton { text: "Licuar (Liquify)"; onClicked: { if(canvasRef) canvasRef.currentTool = "liquify"; root.close() } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff"; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                    ActionButton { text: "Reglas y guías"; onClicked: { root.close() } }
                    ActionButton { text: "Guías de perspectiva"; onClicked: { root.close() } }
                    ActionButton { text: "Simetría"; onClicked: { if(canvasRef) { canvasRef.symmetryEnabled = !canvasRef.symmetryEnabled }; root.close() } }
                    ActionButton { text: "Ajuste (Snapping)"; onClicked: { root.close() } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff"; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                    ActionButton { text: "Selección por rango de color"; onClicked: { colorRangeDialog.open(); root.close() } }
                    Item { Layout.fillHeight: true }
                }

                // 2. CANVAS
                ColumnLayout {
                    spacing: 8
                    Text { text: "Canvas"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Voltear horizontal"; onClicked: if(canvasRef) canvasRef.flipCanvasHorizontal() }
                    ActionButton { text: "Voltear vertical"; onClicked: if(canvasRef) canvasRef.flipCanvasVertical() }
                    ActionButton { text: "Ajustar a pantalla"; onClicked: if(canvasRef) canvasRef.fitToView() }
                    Item { Layout.fillHeight: true }
                }

                // 3. TÁCTIL (Touch)
                ColumnLayout {
                    spacing: 12
                    Text { text: "Gestos táctiles"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    CheckBoxOption { text: "Pintar con el dedo"; checked: true }
                    CheckBoxOption { text: "Deshacer con 2 dedos"; checked: true }
                    CheckBoxOption { text: "Rehacer con 3 dedos"; checked: true }
                    Item { Layout.fillHeight: true }
                }

                // 4. CURSOR
                ColumnLayout {
                    spacing: 12
                    Text { text: "Cursor"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    CheckBoxOption { text: "Mostrar contorno del pincel"; checked: true }
                    CheckBoxOption { text: "Mostrar punto de mira"; checked: false }
                    Item { Layout.fillHeight: true }
                }

                // 5. AVANZADO (Advance)
                ColumnLayout {
                    spacing: 12
                    Text { text: "Avanzado"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Curva de presión"; onClicked: { pressureDialog.open(); root.close() } }
                    CheckBoxOption { text: "Modo de alta precisión"; checked: true }
                    Item { Layout.fillHeight: true }
                }

                // 6. EXPORTAR (Export)
                ColumnLayout {
                    spacing: 8
                    Text { text: "Exportar y guardar"; color: colorText; font.bold: true; font.pixelSize: 14 }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#15ffffff" }
                    ActionButton { text: "Guardar proyecto (.stxf)"; onClicked: { if(windowRef) windowRef.saveProjectAndRefresh(); root.close() } }
                    ActionButton { text: "Exportar imagen..."; onClicked: { exportImageDialog.open(); root.close() } }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
    
    function handleAction(name) {
        if (name === "Salir") {
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
        property string shortcutText: ""
        Layout.fillWidth: true
        height: 30
        hoverEnabled: true
        
        Rectangle {
            anchors.fill: parent
            color: parent.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
            radius: 4
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                text: parent.parent.text
                color: colorText
                font.pixelSize: 13
                Layout.fillWidth: true
            }
            Text {
                text: parent.parent.shortcutText
                color: colorTextMuted
                font.pixelSize: 10
                visible: parent.parent.shortcutText !== ""
            }
        }
    }
}
