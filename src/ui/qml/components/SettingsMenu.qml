import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../translations.js" as Trans

Popup {
    id: root
    width: 520
    height: 460
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Position just below the top bar capsule, aligned left
    x: 20
    y: 80

    transformOrigin: Item.TopLeft

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
            NumberAnimation { property: "y"; from: 60; to: 80; duration: 220; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; to: 0.94; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { property: "y"; to: 65; duration: 160; easing.type: Easing.InCubic }
        }
    }
    
    // --- PROPERTIES & SIGNALS ---
    signal settingsChanged
    property int currentCategoryIndex: 0
    property var windowRef: null
    property var canvasRef: null

    // Design Tokens
    property string themeMode: (preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeMode : "Dark"
    property color themeAccent: (preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.themeAccent : "#6366f1"
    
    readonly property bool isDark: themeMode === "Dark" || themeMode === "Midnight" || themeMode === "Blue-Grey" || themeMode === "Studio-Grey"
    
    readonly property color colorBg: "#141416"
    readonly property color colorPanel: "#1a1a1c"
    readonly property color colorAccent: themeAccent
    readonly property color colorText: "#ffffff"
    readonly property color colorTextMuted: "#8e8e93"
    readonly property color colorBorder: "#2a2a2e"

    background: Rectangle {
        color: colorBg
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        radius: 20

        // Soft shadow
        Rectangle {
            anchors.fill: parent; anchors.margins: -10
            z: -1; radius: 28
            color: "black"; opacity: 0.5
        }
    }

    // Transparent overlay — replaces modal gray overlay
    Overlay.modal: Rectangle {
        color: "transparent"
    }
    
    contentItem: RowLayout {
        spacing: 0
        
        // --- SIDEBAR (Procreate-style) ---
        Item {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                anchors.bottomMargin: 12
                spacing: 0

                // Title — italic bold like Procreate
                Text {
                    text: "Settings"
                    color: colorText
                    font.pixelSize: 18
                    font.bold: true
                    font.italic: true
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 14
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
                        id: catDelegate
                        width: categoryList.width
                        height: 36
                        radius: 18
                        
                        property bool isActive: (index === root.currentCategoryIndex && model.type === "page")

                        // Blue gradient pill for active, subtle hover for others
                        gradient: isActive ? activeGrad : null
                        color: isActive ? "transparent" : (catHoverMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")

                        Gradient {
                            id: activeGrad
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#3478F6" }
                            GradientStop { position: 1.0; color: "#5A9BF6" }
                        }

                        Behavior on color { ColorAnimation { duration: 120 } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 10
                            spacing: 8

                            // Circular icon container
                            Rectangle {
                                width: 26; height: 26
                                radius: 13
                                color: catDelegate.isActive ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.06)
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Image {
                                    source: "image://icons/" + model.icon
                                    width: 13; height: 13
                                    sourceSize.width: 13; sourceSize.height: 13
                                    anchors.centerIn: parent
                                    opacity: catDelegate.isActive ? 1.0 : 0.7
                                    Behavior on opacity { NumberAnimation { duration: 100 } }
                                }
                            }
                            
                            Text {
                                text: model.name
                                color: catDelegate.isActive ? "white" : (catHoverMa.containsMouse ? "#e0e0e0" : colorTextMuted)
                                font.pixelSize: 13
                                font.weight: catDelegate.isActive ? Font.DemiBold : Font.Normal
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }
                        
                        MouseArea {
                            id: catHoverMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (model.type === "action") root.handleAction(model.name)
                                else root.currentCategoryIndex = index
                            }
                        }
                    }
                }
            }
        }

        // Subtle vertical divider
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            width: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }
        
        // --- CONTENT AREA ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            StackLayout {
                anchors.fill: parent
                anchors.margins: 20
                currentIndex: root.currentCategoryIndex
                
                // 0. EDITAR (Edit / Actions)
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Editar" }
                    ContentSeparator {}
                    ActionButton { text: "Deshacer"; shortcutText: "Ctrl+Z"; onClicked: { if(canvasRef) canvasRef.undo(); root.close() } }
                    ActionButton { text: "Rehacer"; shortcutText: "Ctrl+Y"; onClicked: { if(canvasRef) canvasRef.redo(); root.close() } }
                    ContentSeparator {}
                    ActionButton { text: "Cortar"; shortcutText: "Ctrl+X"; onClicked: { if(canvasRef) canvasRef.cut(); root.close() } }
                    ActionButton { text: "Copiar"; shortcutText: "Ctrl+C"; onClicked: { if(canvasRef) canvasRef.copy(); root.close() } }
                    ActionButton { text: "Pegar"; shortcutText: "Ctrl+V"; onClicked: { if(canvasRef) canvasRef.paste(); root.close() } }
                    Item { Layout.fillHeight: true }
                }
                
                // 1. HERRAMIENTAS (Tools)
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Herramientas" }
                    ContentSeparator {}
                    ActionButton { text: "Transformación libre"; shortcutText: "Ctrl+T"; onClicked: { if(canvasRef) { canvasRef.isFreeTransformActive = true }; root.close() } }
                    ActionButton { text: "Licuar (Liquify)"; onClicked: { if(canvasRef) canvasRef.currentTool = "liquify"; root.close() } }
                    ActionButton { text: "Reglas y guías"; onClicked: { if(canvasRef && canvasRef.perspectiveRuler) { canvasRef.perspectiveRuler.active = !canvasRef.perspectiveRuler.active }; root.close() } }
                    ActionButton { text: "Guías de perspectiva"; onClicked: { if(canvasRef && canvasRef.perspectiveRuler) { canvasRef.perspectiveRuler.active = !canvasRef.perspectiveRuler.active }; root.close() } }
                    ActionButton { text: "Simetría"; onClicked: { if(canvasRef) { canvasRef.symmetryEnabled = !canvasRef.symmetryEnabled }; root.close() } }
                    ActionButton { text: "Ajuste (Snapping)"; onClicked: { if(canvasRef && canvasRef.perspectiveRuler) { canvasRef.perspectiveRuler.active = !canvasRef.perspectiveRuler.active }; root.close() } }
                    ContentSeparator {}
                    ActionButton { text: "Selección por rango de color"; onClicked: { colorRangeDialog.open(); root.close() } }
                    Item { Layout.fillHeight: true }
                }

                // 2. CANVAS
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Canvas" }
                    ContentSeparator {}
                    ActionButton { text: "Voltear horizontal"; onClicked: if(canvasRef) canvasRef.flipCanvasHorizontal() }
                    ActionButton { text: "Voltear vertical"; onClicked: if(canvasRef) canvasRef.flipCanvasVertical() }
                    ActionButton { text: "Ajustar a pantalla"; onClicked: if(canvasRef) canvasRef.fitToView() }
                    Item { Layout.fillHeight: true }
                }

                // 3. TÁCTIL (Touch)
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Gestos táctiles" }
                    ContentSeparator {}
                    CheckBoxOption { text: "Pintar con el dedo"; checked: true }
                    CheckBoxOption { text: "Deshacer con 2 dedos"; checked: true }
                    CheckBoxOption { text: "Rehacer con 3 dedos"; checked: true }
                    Item { Layout.fillHeight: true }
                }

                // 4. CURSOR
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Cursor" }
                    ContentSeparator {}
                    CheckBoxOption { text: "Mostrar contorno del pincel"; checked: true }
                    CheckBoxOption { text: "Mostrar punto de mira"; checked: false }
                    Item { Layout.fillHeight: true }
                }

                // 5. AVANZADO (Advance)
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Avanzado" }
                    ContentSeparator {}
                    ActionButton { text: "Curva de presión"; onClicked: { pressureDialog.open(); root.close() } }
                    CheckBoxOption { text: "Modo de alta precisión"; checked: true }
                    Item { Layout.fillHeight: true }
                }

                // 6. EXPORTAR (Export)
                ColumnLayout {
                    spacing: 0
                    ContentHeader { text: "Exportar y guardar" }
                    ContentSeparator {}
                    ActionButton { text: "Guardar proyecto (.stxf)"; onClicked: { if(windowRef) windowRef.saveProjectAndRefresh(); root.close() } }
                    ActionButton { text: "Exportar imagen..."; onClicked: { exportImageDialog.open(); root.close() } }
                    ActionButton { text: "Grabar/Exportar Timelapse"; onClicked: { videoConfigDialog.open(); root.close() } }
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

    // --- Reusable content components ---

    component ContentHeader : Text {
        color: colorText
        font.pixelSize: 15
        font.bold: true
        Layout.bottomMargin: 4
    }

    component ContentSeparator : Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
        Layout.topMargin: 6
        Layout.bottomMargin: 6
    }
    
    component CheckBoxOption : CheckBox {
        Layout.fillWidth: true
        topPadding: 6
        bottomPadding: 6

        contentItem: Text {
            text: parent.text
            color: colorText
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: parent.indicator.width + 10
        }
        indicator: Rectangle {
            implicitWidth: 18; implicitHeight: 18; radius: 5
            x: parent.leftPadding; y: parent.height/2 - height/2
            color: parent.checked ? "#3478F6" : "transparent"
            border.color: parent.checked ? "#3478F6" : "#444"
            border.width: 1.5

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text { 
                visible: parent.parent.checked
                text: "✓"
                color: "white"
                font.pixelSize: 11
                font.bold: true
                anchors.centerIn: parent
            }
        }
    }
    
    component ActionButton : MouseArea {
        property string text: ""
        property string shortcutText: ""
        Layout.fillWidth: true
        height: 38
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -4
            anchors.rightMargin: -4
            color: parent.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
            radius: 6
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            Text {
                text: parent.parent.text
                color: parent.parent.containsMouse ? "#ffffff" : "#d0d0d5"
                font.pixelSize: 14
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            Text {
                text: parent.parent.shortcutText
                color: colorTextMuted
                font.pixelSize: 11
                visible: parent.parent.shortcutText !== ""
            }
        }
    }
}
