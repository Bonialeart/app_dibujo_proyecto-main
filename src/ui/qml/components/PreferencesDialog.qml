import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Effects
import "../Translations.js" as Trans

Popup {
    id: root
    width: 900
    height: 720
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    
    // Position center of parent/window
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    // --- PROPERTIES & SIGNALS ---
    signal settingsChanged
    
    // Theme Colors - Bound to PreferencesManager if available, else fallback
    property string themeMode: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.themeMode : "Dark"
    property color themeAccent: (preferencesManager !== undefined && preferencesManager !== null) ? preferencesManager.themeAccent : "#6366f1"
    
    // Computed based on Mode
    readonly property bool isDark: themeMode === "Dark" || themeMode === "Midnight" || themeMode === "Blue-Grey"
    
    readonly property color colorBg: isDark ? (themeMode === "Midnight" ? "#0f172a" : (themeMode === "Blue-Grey" ? "#1e293b" : "#1e1e20")) : "#f3f4f6"
    readonly property color colorPanel: isDark ? (themeMode === "Midnight" ? "#1e293b" : (themeMode === "Blue-Grey" ? "#334155" : "#252526")) : "#ffffff"
    readonly property color colorAccent: themeAccent
    readonly property color colorText: isDark ? "#ffffff" : "#1f2937"
    readonly property color colorTextMuted: isDark ? "#a1a1aa" : "#6b7280"
    readonly property color colorBorder: isDark ? "#3f3f46" : "#e5e7eb"
    readonly property color colorInput: isDark ? "#18181b" : "#f9fafb"
    
    property int currentCategoryIndex: 0
    property string shortcutSearchQuery: ""
    property var tempShortcuts: ({})

    // --- TEMP STATE (Buffer for Cancel) ---
    property bool tempGpuEnabled: true
    property int tempUndoLevels: 50
    property int tempMemLimit: 70
    property bool tempSwitchTool: true
    property int tempSwitchDelay: 500
    property string tempLanguage: "en"
    property bool tempShowOutline: true
    property bool tempShowCrosshair: true
    property string tempTabletMode: "WindowsInk"
    property int tempDragDist: 3
    property bool tempAutoSave: true
    property double tempUiScale: 1.0
    property bool tempTouchGestures: true
    property bool tempTouchEyedropper: true
    property bool tempMultitouchUndoRedo: true
    property bool tempShowTopProjectInfo: true
    property bool tempShowTopBrushControls: true
    property bool tempShowTopActionButtons: true
    property bool tempShowTopSymmetryUndoRedo: true
    property bool tempShowTopWorkspaceSwitcher: true
    property bool tempShowRightToolbar: true
    property bool tempShowRightColorSelector: true

    readonly property string lang: (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") ? preferencesManager.language : "en"
    function qs(key) { return Trans.get(key, lang); }

    // --- LAYOUT CUSTOMIZATION HELPERS ---
    property var _layoutCache: ({})
    property int _layoutVersion: 0
    property int totalButtonCount: 0

    function refreshLayoutCache() {
        if (preferencesManager && preferencesManager.essentialLayoutConfig) {
            _layoutCache = preferencesManager.essentialLayoutConfig
        } else {
            _layoutCache = {}
        }
        var count = 0
        var keys = ["topLeft","topRight","side","rightColor","sliders"]
        for (var i = 0; i < keys.length; i++) {
            var list = _layoutCache[keys[i]]
            if (list) count += list.length
        }
        totalButtonCount = count
        _layoutVersion++
    }

    function getLocationButtons(location) {
        return (_layoutCache && _layoutCache[location]) ? _layoutCache[location] : []
    }

    function getButtonLabel(btnId) {
        if (!preferencesManager || !preferencesManager.essentialButtonCatalog)
            return btnId
        var cat = preferencesManager.essentialButtonCatalog
        var info = cat[btnId]
        return info ? info.label : btnId
    }

    function getButtonIcon(btnId) {
        if (!preferencesManager || !preferencesManager.essentialButtonCatalog)
            return ""
        var cat = preferencesManager.essentialButtonCatalog
        var info = cat[btnId]
        return info ? info.icon : ""
    }

    function getZoneLabel(location) {
        var labels = {
            "topLeft": "Barra Superior Izquierda",
            "topRight": "Barra Superior Derecha",
            "side": "Barra Lateral — Herramientas",
            "rightColor": "Selector de Color",
            "sliders": "Controles Deslizantes",
            "hidden": "Ocultos"
        }
        return labels[location] || location
    }

    function getDefLocation(btnId) {
        if (!preferencesManager || !preferencesManager.essentialButtonCatalog)
            return "hidden"
        var cat = preferencesManager.essentialButtonCatalog
        var info = cat[btnId]
        return info ? info.defaultLocation : "hidden"
    }

    function getButtonCurrentLocation(btnId) {
        var locations = ["topLeft","topRight","side","rightColor","sliders","hidden"]
        for (var i = 0; i < locations.length; i++) {
            var list = root.getLocationButtons(locations[i])
            for (var j = 0; j < list.length; j++) {
                if (list[j] === btnId) return locations[i]
            }
        }
        return "hidden"
    }

    function moveButton(btnId, targetLocation) {
        if (preferencesManager && preferencesManager.moveButtonTo) {
            preferencesManager.moveButtonTo(btnId, targetLocation)
            refreshLayoutCache()
        }
    }

    function shiftButton(btnId, direction) {
        var loc = getButtonCurrentLocation(btnId)
        if (loc === "hidden") return
        var list = root.getLocationButtons(loc)
        var idx = list.indexOf(btnId)
        if (idx === -1) return
        
        var targetIdx = idx + direction
        if (targetIdx < 0 || targetIdx >= list.length) return
        
        var newList = list.slice()
        var temp = newList[idx]
        newList[idx] = newList[targetIdx]
        newList[targetIdx] = temp
        
        var currentLayout = Object.assign({}, root._layoutCache)
        currentLayout[loc] = newList
        preferencesManager.setEssentialLayoutConfig(currentLayout)
        refreshLayoutCache()
    }

    function resetLocationToDefault(location) {
        if (preferencesManager && preferencesManager.defaultEssentialLayout) {
            var def = preferencesManager.defaultEssentialLayout()
            var defButtons = def[location] || []
            var currentLayout = Object.assign({}, root._layoutCache)
            var keys = ["topLeft","topRight","side","rightColor","sliders","hidden"]
            
            for (var i = 0; i < defButtons.length; i++) {
                var btnId = defButtons[i]
                for (var k = 0; k < keys.length; k++) {
                    var list = currentLayout[keys[k]] || []
                    var idx = list.indexOf(btnId)
                    if (idx >= 0) {
                        var newList = list.slice()
                        newList.splice(idx, 1)
                        currentLayout[keys[k]] = newList
                    }
                }
            }
            
            currentLayout[location] = defButtons.slice()
            preferencesManager.setEssentialLayoutConfig(currentLayout)
            refreshLayoutCache()
        }
    }

    Connections {
        target: preferencesManager
        function onLayoutConfigChanged() {
            root.refreshLayoutCache()
        }
    }
    
    onOpened: {
        root.refreshLayoutCache()
        if (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") {
            tempGpuEnabled = preferencesManager.gpuAcceleration
            tempUndoLevels = preferencesManager.undoLevels
            tempLanguage = preferencesManager.language
            tempMemLimit = preferencesManager.memoryUsageLimit
            tempShowOutline = preferencesManager.cursorShowOutline
            tempShowCrosshair = preferencesManager.cursorShowCrosshair
            tempTabletMode = preferencesManager.tabletInputMode
            tempSwitchDelay = preferencesManager.toolSwitchDelay
            tempDragDist = preferencesManager.dragDistance
            tempAutoSave = preferencesManager.autoSaveEnabled
            if (preferencesManager.uiScale) tempUiScale = preferencesManager.uiScale
            tempTouchGestures = preferencesManager.touchGesturesEnabled
            tempTouchEyedropper = preferencesManager.touchEyedropperEnabled
            tempMultitouchUndoRedo = preferencesManager.multitouchUndoRedoEnabled
            tempShowTopProjectInfo = preferencesManager.showTopProjectInfo
            tempShowTopBrushControls = preferencesManager.showTopBrushControls
            tempShowTopActionButtons = preferencesManager.showTopActionButtons
            tempShowTopSymmetryUndoRedo = preferencesManager.showTopSymmetryUndoRedo
            tempShowTopWorkspaceSwitcher = preferencesManager.showTopWorkspaceSwitcher
            tempShowRightToolbar = preferencesManager.showRightToolbar
            tempShowRightColorSelector = preferencesManager.showRightColorSelector
            tempShortcuts = Object.assign({}, preferencesManager.shortcuts)
            root.refreshLayoutCache()
        }
    }
    
    function saveSettings() {
        if (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") {
            preferencesManager.gpuAcceleration = tempGpuEnabled
            preferencesManager.undoLevels = tempUndoLevels
            preferencesManager.language = tempLanguage
            preferencesManager.memoryUsageLimit = tempMemLimit
            preferencesManager.cursorShowOutline = tempShowOutline
            preferencesManager.cursorShowCrosshair = tempShowCrosshair
            preferencesManager.tabletInputMode = tempTabletMode
            preferencesManager.toolSwitchDelay = tempSwitchDelay
            preferencesManager.dragDistance = tempDragDist
            preferencesManager.autoSaveEnabled = tempAutoSave
            preferencesManager.uiScale = tempUiScale
            preferencesManager.touchGesturesEnabled = tempTouchGestures
            preferencesManager.touchEyedropperEnabled = tempTouchEyedropper
            preferencesManager.multitouchUndoRedoEnabled = tempMultitouchUndoRedo
            preferencesManager.showTopProjectInfo = tempShowTopProjectInfo
            preferencesManager.showTopBrushControls = tempShowTopBrushControls
            preferencesManager.showTopActionButtons = tempShowTopActionButtons
            preferencesManager.showTopSymmetryUndoRedo = tempShowTopSymmetryUndoRedo
            preferencesManager.showTopWorkspaceSwitcher = tempShowTopWorkspaceSwitcher
            preferencesManager.showRightToolbar = tempShowRightToolbar
            preferencesManager.showRightColorSelector = tempShowRightColorSelector
            preferencesManager.shortcuts = tempShortcuts
            
            toastManager.show(root.qs("saved"), "success")
        }
    }


    
    // --- BACKGROUND ---
    background: Rectangle {
        color: colorBg
        border.color: Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.4) // Subtle accent border
        border.width: 1
        radius: 8
        
        // Shadow effect
        layer.enabled: true
        // Note: Effects might need specific import or fallback, keeping simple for now
    }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // TITLE BAR
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 40
            color: "transparent"
            
            Text {
                text: root.qs("preferences")
                color: colorText
                font.pixelSize: 14; font.bold: true
                anchors.centerIn: parent
            }
            
            // X Button
            Button {
                text: "✕"
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30
                background: Rectangle { color: "transparent" }
                contentItem: Text { 
                    text: parent.text; color: colorTextMuted; font.pixelSize: 14; 
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                }
                onClicked: root.close()
            }
            
            Rectangle { width: parent.width; height: 1; color: colorBorder; anchors.bottom: parent.bottom }
        }
        
        // MAIN CONTENT AREA
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 0
            
            // --- SIDEBAR ---
            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: "#18181b" // Darker sidebar
                
                Rectangle { width: 1; height: parent.height; color: colorBorder; anchors.right: parent.right }
                
                ListView {
                    id: categoryList
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2
                    model: [
                        { name: root.qs("appearance"), icon: "layout.svg" },
                        { name: root.qs("performance"), icon: "cpu.svg" }, 
                        { name: root.qs("cursor"), icon: "mouse-pointer.svg" },
                        { name: root.qs("tablet"), icon: "tablet.svg" },
                        { name: root.qs("shortcuts"), icon: "keyboard.svg" }, 
                        { name: root.qs("tools"), icon: "tool.svg" },      
                        { name: root.qs("file"), icon: "file.svg" },
                        { name: root.qs("color"), icon: "palette.svg" },
                        { name: root.qs("layout_design"), icon: "layout.svg" }
                    ]
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 32
                        color: index === root.currentCategoryIndex ? colorAccent : "transparent"
                        radius: 4
                        
                        property bool isHovered: hoverMa.containsMouse
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "white"
                            opacity: parent.isHovered && index !== root.currentCategoryIndex ? 0.05 : 0
                            radius: 4
                        }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10
                            spacing: 10
                            
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: "transparent" // Transparent if icon is present
                                
                                Image { 
                                    anchors.fill: parent
                                    source: (modelData && modelData.icon) ? "image://icons/" + modelData.icon : ""
                                    visible: status === Image.Ready
                                    sourceSize.width: 16; sourceSize.height: 16
                                    opacity: index === root.currentCategoryIndex ? 1.0 : 0.6
                                    
                                    // Fallback circle if icon missing
                                    onStatusChanged: if (status === Image.Error) parent.color = (index === root.currentCategoryIndex ? "white" : "#555")
                                }
                                
                                // Default circle coloring if image not loaded initially
                                Component.onCompleted: if (!modelData || !modelData.icon || modelData.icon === "") color = (index === root.currentCategoryIndex ? "white" : "#555")
                            }
                            
                            Text {
                                text: modelData.name
                                color: index === root.currentCategoryIndex ? "white" : (parent.parent.isHovered ? colorText : colorTextMuted)
                                font.pixelSize: 13
                                font.weight: index === root.currentCategoryIndex ? Font.Bold : Font.Normal
                                Layout.fillWidth: true
                            }
                        }
                        
                        MouseArea {
                            id: hoverMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.currentCategoryIndex = index
                        }
                    }
                }
            }
            
            // --- SETTINGS PAGES ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                clip: true
                
                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    currentIndex: root.currentCategoryIndex
                    
                    // 0. APPEARANCE
                    ScrollView {
                        contentHeight: interfaceCol.height
                        ColumnLayout {
                            id: interfaceCol
                            width: parent.width
                            spacing: 20
                            
                            SettingsGroup {
                                title: root.qs("theme_mode")
                                description: root.qs("theme_desc")
                                
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    
                                    Repeater {
                                        model: ["Dark", "Light", "Midnight", "Blue-Grey"]
                                        delegate: Rectangle {
                                            width: 100; height: 60
                                            color: (preferencesManager && preferencesManager.themeMode === modelData) ? colorAccent : colorPanel
                                            radius: 6
                                            border.color: colorBorder
                                            border.width: 1
                                            
                                            Text {
                                                text: modelData
                                                anchors.centerIn: parent
                                                color: (preferencesManager && preferencesManager.themeMode === modelData) ? "white" : colorText
                                                font.bold: true
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: preferencesManager.themeMode = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                title: root.qs("accent_color")
                                description: root.qs("accent_desc")
                                
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    
                                    Repeater {
                                        model: ["#6366f1", "#ef4444", "#f59e0b", "#10b981", "#3b82f6", "#ec4899", "#8b5cf6", "#64748b"]
                                        delegate: Rectangle {
                                            width: 32; height: 32
                                            radius: 16
                                            color: modelData
                                            border.color: "white"
                                            border.width: (preferencesManager && preferencesManager.themeAccent === modelData) ? 2 : 0
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: preferencesManager.themeAccent = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                title: "Interface Scale"
                                description: "Adjust size of UI elements."
                                
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    
                                    Repeater {
                                        model: [
                                            { label: "Small", value: 0.8 },
                                            { label: "Medium", value: 1.0 },
                                            { label: "Large", value: 1.2 }
                                        ]
                                        delegate: Rectangle {
                                            width: 100; height: 40
                                            color: (Math.abs(root.tempUiScale - modelData.value) < 0.01) ? colorAccent : colorPanel
                                            radius: 6
                                            border.color: colorBorder
                                            border.width: 1
                                            
                                            Text {
                                                text: modelData.label
                                                anchors.centerIn: parent
                                                color: (Math.abs(root.tempUiScale - modelData.value) < 0.01) ? "white" : colorText
                                                font.bold: true
                                                font.pixelSize: 13
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.tempUiScale = modelData.value
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                title: root.qs("language")
                                description: root.qs("language_desc")
                                
                                Flow { // Changed to Flow for many languages
                                    Layout.fillWidth: true; spacing: 12
                                    Repeater {
                                        model: [
                                            { name: "Español", code: "es" },
                                            { name: "English", code: "en" },
                                            { name: "日本語", code: "ja" },
                                            { name: "Français", code: "fr" },
                                            { name: "Português", code: "pt" },
                                            { name: "中文", code: "zh" },
                                            { name: "한국어", code: "ko" }
                                        ]
                                        delegate: Rectangle {
                                            width: 100; height: 36; radius: 6
                                            color: (root.tempLanguage === modelData.code) ? colorAccent : colorPanel
                                            border.color: colorBorder; border.width: 1
                                            
                                            Text {
                                                text: modelData.name
                                                anchors.centerIn: parent
                                                color: (root.tempLanguage === modelData.code) ? "white" : colorText
                                                font.pixelSize: 12; font.bold: true
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: root.tempLanguage = modelData.code
                                            }
                                        }
                                    }
                                }
                            }

                            SettingsGroup {
                                title: "Personalización de Interfaz"
                                description: "Configura la visibilidad de los elementos en la barra de información superior y la barra de herramientas del lado derecho."
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    CheckBoxOption {
                                        text: "Mostrar información del proyecto (Barra superior)"
                                        checked: root.tempShowTopProjectInfo
                                        onCheckedChanged: root.tempShowTopProjectInfo = checked
                                    }
                                    CheckBoxOption {
                                        text: "Mostrar controles de pincel (Barra superior)"
                                        checked: root.tempShowTopBrushControls
                                        onCheckedChanged: root.tempShowTopBrushControls = checked
                                    }
                                    CheckBoxOption {
                                        text: "Mostrar botones de acción rápida (Barra superior)"
                                        checked: root.tempShowTopActionButtons
                                        onCheckedChanged: root.tempShowTopActionButtons = checked
                                    }
                                    CheckBoxOption {
                                        text: "Mostrar controles de simetría y deshacer/rehacer (Barra superior)"
                                        checked: root.tempShowTopSymmetryUndoRedo
                                        onCheckedChanged: root.tempShowTopSymmetryUndoRedo = checked
                                    }
                                    CheckBoxOption {
                                        text: "Mostrar selector de espacio de trabajo (Barra superior)"
                                        checked: root.tempShowTopWorkspaceSwitcher
                                        onCheckedChanged: root.tempShowTopWorkspaceSwitcher = checked
                                    }
                                }
                            }
                        }
                    }
                    
                    // 1. PERFORMANCE (USER REQUEST)
                    ScrollView {
                        contentHeight: perfCol.height
                        ColumnLayout {
                            id: perfCol
                            width: parent.width
                            spacing: 20
                            
                            SettingsGroup {
                                title: "Graphic Processor"
                                description: "Configure how the application uses your hardware."
                                
                                RowLayout {
                                    spacing: 12
                                    Button {
                                        text: "GPU Acceleration (Recommended)"
                                        checkable: true
                                        checked: root.tempGpuEnabled
                                        Layout.fillWidth: true
                                        palette.button: checked ? colorAccent : "#333"
                                        palette.buttonText: "white"
                                        onClicked: root.tempGpuEnabled = true
                                    }
                                    Button {
                                        text: "CPU Only"
                                        checkable: true
                                        checked: !root.tempGpuEnabled
                                        Layout.fillWidth: true
                                        onClicked: root.tempGpuEnabled = false
                                    }
                                }
                                Text { 
                                    text: "Use GPU for rendering canvas and effects. Provides smoother zooming and rotating."
                                    color: colorTextMuted; font.pixelSize: 11; wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                            
                            SettingsGroup {
                                title: "Memory"
                                
                                Label { text: "Undo Levels: " + undoSlider.value; color: colorText }
                                PremiumSlider {
                                    id: undoSlider
                                    from: 10; to: 200; stepSize: 1
                                    value: root.tempUndoLevels
                                    Layout.fillWidth: true
                                    onMoved: root.tempUndoLevels = value
                                }
                                
                                Label { text: "Memory Usage Limit: " + memSlider.value + "%"; color: colorText }
                                PremiumSlider {
                                    id: memSlider
                                    from: 20; to: 90; value: root.tempMemLimit
                                    stepSize: 5
                                    Layout.fillWidth: true
                                    onMoved: root.tempMemLimit = value
                                }
                            }
                        }
                    }
                    
                    // 2. CURSOR
                    ScrollView {
                         contentHeight: cursorCol.height
                         ColumnLayout {
                            id: cursorCol
                            width: parent.width
                            SettingsGroup {
                                title: "Cursor Shape"
                                CheckBoxOption { 
                                    text: "Brush Size Outline"; 
                                    checked: root.tempShowOutline
                                    onCheckedChanged: root.tempShowOutline = checked
                                }
                                CheckBoxOption { 
                                    text: "Crosshair in Center"; 
                                    checked: root.tempShowCrosshair
                                    onCheckedChanged: root.tempShowCrosshair = checked
                                }
                            }
                         }
                    }
                    
                    // 3. TABLET & TOUCH
                    ScrollView {
                        contentHeight: tabletCol.height
                        ColumnLayout {
                            id: tabletCol; width: parent.width
                            spacing: 20
                            SettingsGroup {
                                title: "Input Mode"
                                CheckBoxOption { 
                                    text: "Use Windows Ink"; 
                                    checked: root.tempTabletMode === "WindowsInk"
                                    onCheckedChanged: if(checked) root.tempTabletMode = "WindowsInk"
                                }
                                CheckBoxOption { 
                                    text: "Wintab (Legacy)"; 
                                    checked: root.tempTabletMode === "Wintab"
                                    onCheckedChanged: if(checked) root.tempTabletMode = "Wintab"
                                }
                            }
                            SettingsGroup {
                                title: "Touch & Gestures"
                                CheckBoxOption { 
                                    text: "Enable Multi-touch Zoom & Pan"; 
                                    checked: root.tempTouchGestures
                                    onCheckedChanged: root.tempTouchGestures = checked
                                }
                                CheckBoxOption { 
                                    text: "One-Finger Long Press for Eyedropper"; 
                                    checked: root.tempTouchEyedropper
                                    onCheckedChanged: root.tempTouchEyedropper = checked
                                }
                                CheckBoxOption { 
                                    text: "Two-Finger Tap Undo / Three-Finger Tap Redo"; 
                                    checked: root.tempMultitouchUndoRedo
                                    onCheckedChanged: root.tempMultitouchUndoRedo = checked
                                }
                            }
                        }
                    }
                                      // 4. SHORTCUTS (USER REQUEST)
                    ScrollView {
                        contentHeight: shortcutCol.height
                        ColumnLayout {
                            id: shortcutCol
                            width: parent.width
                            spacing: 16
                            
                            Text { text: "Keyboard Shortcuts"; color: colorText; font.pixelSize: 18; font.bold: true }
                            
                            // Search
                            PremiumTextField {
                                id: shortcutSearchInput
                                Layout.fillWidth: true
                                placeholderText: "Search command..."
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: root.shortcutSearchQuery = text.toLowerCase()
                            }
                            
                            // Shortcut List Header
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Command"; color: colorTextMuted; font.pixelSize: 12; Layout.fillWidth: true }
                                Text { text: "Key"; color: colorTextMuted; font.pixelSize: 12; Layout.preferredWidth: 160 }
                            }
                            
                            Rectangle { Layout.fillWidth: true; height: 1; color: colorBorder }
                            
                            // Shortcuts Data
                            Repeater {
                                model: {
                                    let allShortcuts = [
                                        { id: "New Project", cmd: "New Project" },
                                        { id: "Open Project", cmd: "Open Project" },
                                        { id: "Save", cmd: "Save" },
                                        { id: "Undo", cmd: "Undo" },
                                        { id: "Redo", cmd: "Redo" },
                                        { id: "New Layer", cmd: "New Layer" },
                                        { id: "Pen Tool", cmd: "Pen Tool" },
                                        { id: "Brush Tool", cmd: "Brush Tool" },
                                        { id: "Eraser Tool", cmd: "Eraser Tool" },
                                        { id: "Lasso Tool", cmd: "Lasso Tool" },
                                        { id: "Hand Tool", cmd: "Hand Tool" },
                                        { id: "Eyedropper Tool", cmd: "Eyedropper Tool" },
                                        { id: "Move Tool", cmd: "Move Tool" },
                                        { id: "Transform", cmd: "Transform" },
                                        { id: "Select None", cmd: "Select None" },
                                        { id: "Zoom In", cmd: "Zoom In" },
                                        { id: "Zoom Out", cmd: "Zoom Out" },
                                        { id: "Fit to Screen", cmd: "Fit to Screen" }
                                    ];
                                    if (root.shortcutSearchQuery === "") return allShortcuts;
                                    return allShortcuts.filter(item => item.cmd.toLowerCase().indexOf(root.shortcutSearchQuery) !== -1);
                                }
                                delegate: RowLayout {
                                    width: parent.width
                                    height: 34
                                    spacing: 12
                                    
                                    Text {
                                        text: modelData.cmd
                                        color: colorText
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    
                                    // Custom Shortcut Recorder Button Control
                                     Button {
                                         id: recorderBtn
                                         Layout.preferredWidth: 160
                                         Layout.preferredHeight: 28
                                         focus: true
                                         hoverEnabled: true
                                         
                                         background: Rectangle {
                                             color: isDark ? (recorderBtn.activeFocus ? "#18181b" : "#27272a") : (recorderBtn.activeFocus ? "#ffffff" : "#f4f4f5")
                                             radius: 6
                                             border.color: recorderBtn.activeFocus ? colorAccent : (recorderBtn.hovered ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5) : colorBorder)
                                             border.width: recorderBtn.activeFocus ? 1.5 : 1
                                             
                                             Behavior on color { ColorAnimation { duration: 150 } }
                                             Behavior on border.color { ColorAnimation { duration: 150 } }
                                         }
                                         
                                         contentItem: RowLayout {
                                             anchors.fill: parent
                                             anchors.leftMargin: 8
                                             anchors.rightMargin: 4
                                             spacing: 6
                                             
                                             // Icon or state indicator (Breathing dot)
                                             Rectangle {
                                                 width: 6; height: 6; radius: 3
                                                 color: colorAccent
                                                 visible: recorderBtn.activeFocus
                                                 
                                                 SequentialAnimation on opacity {
                                                     running: recorderBtn.activeFocus
                                                     loops: Animation.Infinite
                                                     NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                                                     NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                                                 }
                                             }
                                             
                                             Text {
                                                 id: shortcutText
                                                 Layout.fillWidth: true
                                                 font.pixelSize: 12
                                                 font.bold: !recorderBtn.activeFocus && !!root.tempShortcuts[modelData.id]
                                                 font.italic: recorderBtn.activeFocus
                                                 color: recorderBtn.activeFocus ? colorAccent : (root.tempShortcuts[modelData.id] ? colorText : colorTextMuted)
                                                 verticalAlignment: Text.AlignVCenter
                                                 elide: Text.ElideRight
                                                 
                                                 text: {
                                                     if (recorderBtn.activeFocus) {
                                                         return "Press keys...";
                                                     }
                                                     return root.tempShortcuts[modelData.id] || "None";
                                                 }
                                             }
                                             
                                             // Clear Button (✕)
                                             Button {
                                                 id: clearBtn
                                                 Layout.preferredWidth: 20
                                                 Layout.preferredHeight: 20
                                                 visible: (recorderBtn.hovered || recorderBtn.activeFocus) && !!root.tempShortcuts[modelData.id]
                                                 text: "✕"
                                                 hoverEnabled: true
                                                 
                                                 background: Rectangle {
                                                     color: clearBtn.hovered ? (isDark ? "#3f3f46" : "#e4e4e7") : "transparent"
                                                     radius: 10
                                                 }
                                                 
                                                 contentItem: Text {
                                                     text: clearBtn.text
                                                     color: colorTextMuted
                                                     font.pixelSize: 10
                                                     font.bold: true
                                                     horizontalAlignment: Text.AlignHCenter
                                                     verticalAlignment: Text.AlignVCenter
                                                 }
                                                 
                                                 onClicked: {
                                                     let copy = Object.assign({}, root.tempShortcuts);
                                                     copy[modelData.id] = "";
                                                     root.tempShortcuts = copy;
                                                 }
                                             }
                                         }
                                         
                                         // Key Event Handler inside recorderBtn
                                         Keys.onPressed: (event) => {
                                             event.accepted = true;
                                             if (event.isAutoRepeat) return;
                                             
                                             let key = event.key;
                                             
                                             // If they press a modifier by itself, don't finalize the shortcut sequence yet
                                             if (key === Qt.Key_Control || key === Qt.Key_Shift || key === Qt.Key_Alt || key === Qt.Key_Meta) {
                                                 return;
                                             }
                                             
                                             let modifiersStr = "";
                                             if (event.modifiers & Qt.ControlModifier) modifiersStr += "Ctrl+";
                                             if (event.modifiers & Qt.ShiftModifier) modifiersStr += "Shift+";
                                             if (event.modifiers & Qt.AltModifier) modifiersStr += "Alt+";
                                             if (event.modifiers & Qt.MetaModifier) modifiersStr += "Meta+";
                                             
                                             let keyName = "";
                                             switch(key) {
                                                 case Qt.Key_Space: keyName = "Space"; break;
                                                 case Qt.Key_Escape: keyName = "Escape"; break;
                                                 case Qt.Key_Tab: keyName = "Tab"; break;
                                                 case Qt.Key_Backspace: keyName = "Backspace"; break;
                                                 case Qt.Key_Delete: keyName = "Delete"; break;
                                                 case Qt.Key_Insert: keyName = "Insert"; break;
                                                 case Qt.Key_Home: keyName = "Home"; break;
                                                 case Qt.Key_End: keyName = "End"; break;
                                                 case Qt.Key_PageUp: keyName = "PageUp"; break;
                                                 case Qt.Key_PageDown: keyName = "PageDown"; break;
                                                 case Qt.Key_Left: keyName = "Left"; break;
                                                 case Qt.Key_Right: keyName = "Right"; break;
                                                 case Qt.Key_Up: keyName = "Up"; break;
                                                 case Qt.Key_Down: keyName = "Down"; break;
                                                 case Qt.Key_Return: keyName = "Return"; break;
                                                 case Qt.Key_Enter: keyName = "Enter"; break;
                                                 case Qt.Key_Plus: keyName = "+"; break;
                                                 case Qt.Key_Minus: keyName = "-"; break;
                                                 case Qt.Key_Equal: keyName = "="; break;
                                                 case Qt.Key_Asterisk: keyName = "*"; break;
                                                 case Qt.Key_Slash: keyName = "/"; break;
                                                 case Qt.Key_Comma: keyName = ","; break;
                                                 case Qt.Key_Period: keyName = "."; break;
                                                 default:
                                                     keyName = Qt.keyToString(key);
                                                     break;
                                             }
                                             
                                             if (keyName && keyName.length > 0) {
                                                 let finalSeq = modifiersStr + keyName;
                                                 let copy = Object.assign({}, root.tempShortcuts);
                                                 copy[modelData.id] = finalSeq;
                                                 root.tempShortcuts = copy;
                                                 
                                                 // Release active focus
                                                 shortcutCol.forceActiveFocus();
                                             }
                                         }
                                     }
                                }
                            }
                        }
                    }
                    
                    // 5. TOOLS (USER REQUEST + CLIP STUDIO REFERENCE)
                    ScrollView {
                        contentHeight: toolsCol.height
                        ColumnLayout {
                            id: toolsCol
                            width: parent.width
                            spacing: 20
                            
                            SettingsGroup {
                                title: "Switch Tool Temporarily"
                                CheckBoxOption { 
                                    text: "Switch tool temporarily by pressing and holding shortcut key"; 
                                    checked: root.tempSwitchTool 
                                    onCheckedChanged: root.tempSwitchTool = checked
                                }
                                RowLayout {
                                    Layout.leftMargin: 24
                                    Text { text: "Length of keypress to switch tools:"; color: colorTextMuted }
                                    PremiumTextField { 
                                        text: root.tempSwitchDelay.toString()
                                        Layout.preferredWidth: 60
                                        onTextChanged: {
                                            var val = parseInt(text)
                                            if (!isNaN(val)) root.tempSwitchDelay = val
                                        }
                                    }
                                    Text { text: "ms"; color: colorTextMuted }
                                }
                            }
                            
                            SettingsGroup {
                                title: "Options"
                                RowLayout {
                                    Text { text: "Minimum drag distance:"; color: colorTextMuted; Layout.preferredWidth: 150 }
                                    PremiumTextField { 
                                        text: root.tempDragDist.toString()
                                        Layout.preferredWidth: 60
                                        onTextChanged: {
                                            var val = parseInt(text)
                                            if (!isNaN(val)) root.tempDragDist = val
                                        }
                                    }
                                }
                                CheckBoxOption { text: "Use fast view while navigating canvas"; checked: false }
                            }
                            
                            SettingsGroup {
                                title: "Brush / Line"
                                CheckBoxOption { text: "Start from current size when changing brush size"; checked: true }
                                CheckBoxOption { text: "Display brush size adjustment on canvas"; checked: true }
                            }
                        }
                    }
                    
                    // 6. FILE
                    ScrollView {
                        contentHeight: fileCol.height
                        ColumnLayout {
                            id: fileCol; width: parent.width
                            SettingsGroup {
                                title: "Save Options"
                                CheckBoxOption { 
                                    text: "Enable Auto-Save (Every 5 minutes)"; 
                                    checked: root.tempAutoSave
                                    onCheckedChanged: root.tempAutoSave = checked
                                }
                            }
                        }
                    }
                    
                    // 7. COLOR
                    Item { Text { text: "Color Config"; color: "white"; anchors.centerIn: parent } }

                    // 8. DISEÑO / LAYOUT CUSTOMIZATION
                    ScrollView {
                        id: disenioScroll
                        leftPadding: 16; rightPadding: 16; topPadding: 12; bottomPadding: 16
                        clip: true
                        contentWidth: parent.width
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            id: disenioCol
                            width: disenioScroll.width - 4
                            spacing: 20
                            Layout.alignment: Qt.AlignTop

                            // ── HEADER CARD ──
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: headerCol.implicitHeight + 32
                                color: root.isDark ? "#1a1a24" : "#f0f4ff"
                                radius: 10
                                border.color: Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.2)
                                border.width: 1

                                ColumnLayout {
                                    id: headerCol
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Text {
                                            text: "Personalización de Interfaz"
                                            color: root.colorText; font.pixelSize: 14; font.bold: true
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            Layout.preferredWidth: 120; Layout.preferredHeight: 30
                                            radius: 6
                                            color: resetBtn.containsMouse ? Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.12) : "transparent"
                                            border.color: resetBtn.containsMouse ? root.colorAccent : root.colorBorder; border.width: 1
                                            RowLayout {
                                                anchors.centerIn: parent; spacing: 5
                                                Text { text: "↺"; color: root.colorTextMuted; font.pixelSize: 12 }
                                                Text { text: "Restablecer"; color: root.colorTextMuted; font.pixelSize: 11 }
                                            }
                                            MouseArea {
                                                id: resetBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { if (preferencesManager && preferencesManager.resetEssentialLayout) preferencesManager.resetEssentialLayout() }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Usa ▾ para mover botones entre zonas y ✕ para ocultarlos. Los botones ocultos aparecerán en la zona 'Ocultos' y puedes restaurarlos con ↩."
                                        color: root.colorTextMuted; font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // ── ZONE CARDS ──
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 12

                                LayoutGroup { btnLocation: "topLeft"; zoneColor: "#3b82f6"; Layout.fillWidth: true }
                                LayoutGroup { btnLocation: "topRight"; zoneColor: "#8b5cf6"; Layout.fillWidth: true }
                                LayoutGroup { btnLocation: "side"; zoneColor: "#10b981"; Layout.fillWidth: true }
                                LayoutGroup { btnLocation: "rightColor"; zoneColor: "#f59e0b"; Layout.fillWidth: true }
                                LayoutGroup { btnLocation: "sliders"; zoneColor: "#ec4899"; Layout.fillWidth: true }
                                LayoutGroup { btnLocation: "hidden"; zoneColor: "#64748b"; Layout.fillWidth: true }
                            }

                            // ── SECTION VISIBILITY ──
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: sectionCol.implicitHeight + 28
                                color: root.isDark ? "#1a1a1e" : "#f4f4f5"
                                radius: 10
                                border.color: root.colorBorder; border.width: 1

                                ColumnLayout {
                                    id: sectionCol
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                                    spacing: 10

                                    Text {
                                        text: "Visibilidad de Secciones"
                                        color: root.colorText; font.pixelSize: 13; font.bold: true
                                    }
                                    Text {
                                        text: "Muestra u oculta bloques enteros de la interfaz."
                                        color: root.colorTextMuted; font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.colorBorder; opacity: 0.5 }
                                    GridLayout {
                                        Layout.fillWidth: true; columns: 2
                                        columnSpacing: 16; rowSpacing: 4

                                        CheckBoxOption { text: "Info del proyecto"; checked: root.tempShowTopProjectInfo; onCheckedChanged: root.tempShowTopProjectInfo = checked; Layout.fillWidth: true }
                                        CheckBoxOption { text: "Controles de pincel"; checked: root.tempShowTopBrushControls; onCheckedChanged: root.tempShowTopBrushControls = checked; Layout.fillWidth: true }
                                        CheckBoxOption { text: "Acción rápida"; checked: root.tempShowTopActionButtons; onCheckedChanged: root.tempShowTopActionButtons = checked; Layout.fillWidth: true }
                                        CheckBoxOption { text: "Simetría y undo/redo"; checked: root.tempShowTopSymmetryUndoRedo; onCheckedChanged: root.tempShowTopSymmetryUndoRedo = checked; Layout.fillWidth: true }
                                        CheckBoxOption { text: "Selector de espacio"; checked: root.tempShowTopWorkspaceSwitcher; onCheckedChanged: root.tempShowTopWorkspaceSwitcher = checked; Layout.fillWidth: true }
                                        CheckBoxOption { text: "Barra de herramientas"; checked: root.tempShowRightToolbar; onCheckedChanged: root.tempShowRightToolbar = checked; Layout.fillWidth: true }
                                        CheckBoxOption { text: "Selector de color dual"; checked: root.tempShowRightColorSelector; onCheckedChanged: root.tempShowRightColorSelector = checked; Layout.fillWidth: true }
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 8 }
                        }
                    }
                }
            }
        }
        
        // BUTTON BAR
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 60
            color: colorPanel
            border.color: colorBorder
            border.width: 1
            
            RowLayout {
                anchors.fill: parent; anchors.margins: 12
                Layout.alignment: Qt.AlignRight
                
                Button {
                    text: "Restore Defaults"
                    flat: true
                    palette.buttonText: colorTextMuted
                    onClicked: {
                        if (preferencesManager && preferencesManager && typeof preferencesManager !== "undefined") {
                            preferencesManager.resetDefaults()
                            root.close()
                             toastManager.show("Config reset to defaults", "info")
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: root.qs("cancel")
                    onClicked: root.close()
                    background: Rectangle { color: "#333"; radius: 4 }
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Layout.preferredWidth: 80; Layout.preferredHeight: 32
                }
                
                Button {
                    text: root.qs("ok")
                    onClicked: { 
                        root.saveSettings(); 
                        root.settingsChanged(); 
                        root.close() 
                    }
                    background: Rectangle { color: colorAccent; radius: 4 }
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Layout.preferredWidth: 80; Layout.preferredHeight: 32
                }
            }
        }
    }
    
    // --- HELPER COMPONENTS ---
    
    component SettingsGroup : ColumnLayout {
        property string title
        property string description: ""
        
        spacing: 12
        Layout.fillWidth: true
        
        Text { text: title; color: colorText; font.bold: true; font.pixelSize: 15 }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: "#33ffffff" }
        
        Text { 
            text: description; visible: description !== ""
            color: colorTextMuted; font.pixelSize: 12 
            Layout.fillWidth: true; wrapMode: Text.WordWrap
        }
    }
    
    component CheckBoxOption : CheckBox {
        id: cbControl
        text: ""
        hoverEnabled: true
        
        contentItem: Text {
            text: cbControl.text
            color: colorText
            font.pixelSize: 13
            font.weight: cbControl.checked ? Font.DemiBold : Font.Normal
            verticalAlignment: Text.AlignVCenter
            leftPadding: cbControl.indicator.width + 12
            
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        
        indicator: Rectangle {
            implicitWidth: 20; implicitHeight: 20
            x: cbControl.leftPadding; y: cbControl.height / 2 - height / 2
            radius: 5
            color: cbControl.checked ? colorAccent : (cbControl.hovered ? (isDark ? "#2a2a2e" : "#f3f4f6") : "transparent")
            border.color: cbControl.checked ? colorAccent : (cbControl.hovered ? colorAccent : (isDark ? "#555" : "#bbb"))
            border.width: 1.5
            
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            
            Text {
                visible: cbControl.checked
                text: "✓"
                color: "white"
                font.pixelSize: 12
                font.bold: true
                anchors.centerIn: parent
                
                scale: cbControl.checked ? 1.0 : 0.5
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }
            
            scale: cbControl.hovered || cbControl.pressed ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }
    }

    component PremiumSlider : Slider {
        id: sliderControl
        hoverEnabled: true
        
        background: Rectangle {
            x: sliderControl.leftPadding
            y: sliderControl.topPadding + (sliderControl.availableHeight - height) / 2
            width: sliderControl.availableWidth
            height: 6
            radius: 3
            color: isDark ? "#2d2d30" : "#e5e7eb"
            
            Rectangle {
                width: sliderControl.visualPosition * parent.width
                height: parent.height
                color: colorAccent
                radius: 3
            }
        }
        
        handle: Rectangle {
            x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
            y: sliderControl.topPadding + (sliderControl.availableHeight - height) / 2
            width: 16; height: 16; radius: 8
            color: sliderControl.pressed ? "white" : (sliderControl.hovered ? "#f3f4f6" : "#ffffff")
            border.color: sliderControl.pressed ? colorAccent : (sliderControl.hovered ? colorAccent : (isDark ? "#555" : "#ccc"))
            border.width: 2
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 4
                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                shadowVerticalOffset: 1
            }
            
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            scale: sliderControl.hovered || sliderControl.pressed ? 1.15 : 1.0
        }
    }

    // --- LAYOUT GROUP COMPONENT (for Diseño page) ---
    component LayoutGroup : Rectangle {
        id: layoutGroupRoot

        property string btnLocation: ""
        property color zoneColor: root.colorAccent
        property int count: (root._layoutCache && root._layoutCache[layoutGroupRoot.btnLocation] ? root._layoutCache[layoutGroupRoot.btnLocation].length : 0)

        implicitHeight: groupCol.implicitHeight + 24
        color: root.isDark ? "#1a1a1e" : "#fafafa"
        radius: 10
        border.color: Qt.rgba(layoutGroupRoot.zoneColor.r, layoutGroupRoot.zoneColor.g, layoutGroupRoot.zoneColor.b, 0.25)
        border.width: 1

        ColumnLayout {
            id: groupCol
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
            spacing: 10

            // Zone header
            RowLayout {
                Layout.fillWidth: true; spacing: 8

                Rectangle {
                    width: 4; height: 18; radius: 2
                    color: layoutGroupRoot.zoneColor
                }

                Text {
                    text: root.getZoneLabel(layoutGroupRoot.btnLocation)
                    color: root.colorText; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredHeight: 22
                    implicitWidth: badgeText.width + 14
                    radius: 11
                    color: Qt.rgba(layoutGroupRoot.zoneColor.r, layoutGroupRoot.zoneColor.g, layoutGroupRoot.zoneColor.b, 0.15)

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: layoutGroupRoot.count + " botones"
                        color: layoutGroupRoot.zoneColor; font.pixelSize: 10; font.bold: true
                    }
                }

                // Reset specific bar button
                Rectangle {
                    id: singleResetBtn
                    width: 24; height: 24; radius: 12
                    color: singleResetBtnMA.containsMouse ? (root.isDark ? "#2a2a35" : "#e5e7eb") : "transparent"
                    border.color: singleResetBtnMA.containsMouse ? (root.isDark ? "#4f4f56" : "#cbd5e1") : "transparent"
                    border.width: 1
                    visible: layoutGroupRoot.btnLocation !== "hidden"

                    Text {
                        text: "↺"
                        font.pixelSize: 12
                        color: singleResetBtnMA.containsMouse ? root.colorText : root.colorTextMuted
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: singleResetBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.resetLocationToDefault(layoutGroupRoot.btnLocation)
                            toastManager.show("Barra restablecida a valores por defecto", "info")
                        }
                    }
                }

                // Clear/Delete entire bar button
                Rectangle {
                    id: singleClearBtn
                    width: 24; height: 24; radius: 12
                    color: singleClearBtnMA.containsMouse ? "rgba(239, 68, 68, 0.15)" : "transparent"
                    border.color: singleClearBtnMA.containsMouse ? "#ef4444" : "transparent"
                    border.width: 1
                    visible: layoutGroupRoot.btnLocation !== "hidden" && layoutGroupRoot.count > 0

                    Text {
                        text: "🗑"
                        font.pixelSize: 11
                        color: singleClearBtnMA.containsMouse ? "#ef4444" : root.colorTextMuted
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: singleClearBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var buttons = root.getLocationButtons(layoutGroupRoot.btnLocation)
                            for (var i = 0; i < buttons.length; i++) {
                                root.moveButton(buttons[i], "hidden")
                            }
                            toastManager.show("Barra vaciada", "warning")
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: root.colorBorder; opacity: 0.4
            }

            // Chip area
            Flow {
                width: parent.width
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height
                spacing: 8

                Repeater {
                    model: {
                        root._layoutVersion;
                        return root.getLocationButtons(layoutGroupRoot.btnLocation)
                    }

                    delegate: Rectangle {
                        id: chip
                        width: chipRow.implicitWidth + 20; height: 34
                        color: root.isDark ? "#25252b" : "#ffffff"
                        radius: 6
                        border.color: root.isDark ? "#3f3f46" : "#e5e7eb"
                        border.width: 1

                        RowLayout {
                            id: chipRow
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: root.getButtonLabel(modelData)
                                color: root.colorText; font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                width: 1
                                Layout.preferredHeight: 14
                                color: root.isDark ? "#3f3f46" : "#e5e7eb"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                id: shiftLeftArea
                                width: 22; height: 22; radius: 4
                                visible: layoutGroupRoot.btnLocation !== "hidden" && index > 0
                                color: leftMA.containsMouse ? Qt.rgba(layoutGroupRoot.zoneColor.r, layoutGroupRoot.zoneColor.g, layoutGroupRoot.zoneColor.b, 0.15) : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "◀"
                                    font.pixelSize: 10
                                    color: leftMA.containsMouse ? layoutGroupRoot.zoneColor : root.colorTextMuted
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: leftMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.shiftButton(modelData, -1)
                                }
                            }

                            Rectangle {
                                id: shiftRightArea
                                width: 22; height: 22; radius: 4
                                visible: layoutGroupRoot.btnLocation !== "hidden" && index < layoutGroupRoot.count - 1
                                color: rightMA.containsMouse ? Qt.rgba(layoutGroupRoot.zoneColor.r, layoutGroupRoot.zoneColor.g, layoutGroupRoot.zoneColor.b, 0.15) : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "▶"
                                    font.pixelSize: 10
                                    color: rightMA.containsMouse ? layoutGroupRoot.zoneColor : root.colorTextMuted
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: rightMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.shiftButton(modelData, 1)
                                }
                            }

                            Rectangle {
                                id: moveButtonArea
                                width: 22; height: 22; radius: 4
                                color: locMA.containsMouse ? Qt.rgba(layoutGroupRoot.zoneColor.r, layoutGroupRoot.zoneColor.g, layoutGroupRoot.zoneColor.b, 0.15) : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "▾"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: locMA.containsMouse ? layoutGroupRoot.zoneColor : root.colorTextMuted
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: locMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var menu = locationMenuComp.createObject(root, {
                                            btnId: modelData,
                                            x: chip.mapToItem(null, 0, chip.height + 4).x,
                                            y: chip.mapToItem(null, 0, chip.height + 4).y
                                        })
                                        menu.open()
                                    }
                                }
                            }

                            Rectangle {
                                id: deleteButtonArea
                                width: 22; height: 22; radius: 4
                                color: hideMA.containsMouse ? (layoutGroupRoot.btnLocation === "hidden" ? "rgba(74, 222, 128, 0.15)" : "rgba(239, 68, 68, 0.15)") : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: layoutGroupRoot.btnLocation === "hidden" ? "↩" : "✕"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: hideMA.containsMouse ? (layoutGroupRoot.btnLocation === "hidden" ? "#4ade80" : "#ef4444") : root.colorTextMuted
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: hideMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var tgt = layoutGroupRoot.btnLocation === "hidden" ? root.getDefLocation(modelData) : "hidden"
                                        root.moveButton(modelData, tgt)
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    visible: layoutGroupRoot.count === 0
                    text: layoutGroupRoot.btnLocation === "hidden" ? "No hay botones ocultos" : "Vacío — mueve botones aquí con ▾"
                    color: root.colorTextMuted; font.pixelSize: 12; opacity: 0.4
                    height: 32; verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Location menu component (created dynamically)
    component LocationMenu : Popup {
        id: locMenuRoot
        property string btnId: ""
        width: 220; height: locCol.height + 16
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            id: menuBg
            color: root.isDark ? "#202026" : "#ffffff"
            radius: 8
            border.color: root.isDark ? "#3f3f46" : "#e5e7eb"
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 8
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowVerticalOffset: 2
            }
        }

        contentItem: ColumnLayout {
            id: locCol; spacing: 4
            Repeater {
                model: [
                    { key: "topLeft", label: "Barra Superior Izquierda" },
                    { key: "topRight", label: "Barra Superior Derecha" },
                    { key: "side", label: "Barra Lateral" },
                    { key: "rightColor", label: "Selector de Color" },
                    { key: "sliders", label: "Controles Deslizantes" },
                    { key: "hidden", label: "Oculto" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 32; radius: 6
                    color: optMa.containsMouse ? Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.15) : "transparent"
                    required property var modelData

                    readonly property bool isActive: (locMenuRoot.btnId && root.getButtonCurrentLocation(locMenuRoot.btnId) === modelData.key)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "✓"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.colorAccent
                            visible: parent.parent.isActive
                            Layout.preferredWidth: 12
                        }

                        Item {
                            visible: !parent.parent.isActive
                            Layout.preferredWidth: 12
                        }

                        Text {
                            text: modelData.label
                            color: parent.parent.isActive ? root.colorAccent : root.colorText
                            font.pixelSize: 12
                            font.bold: parent.parent.isActive
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: optMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.moveButton(locMenuRoot.btnId, modelData.key)
                            locMenuRoot.close()
                        }
                    }
                }
            }
        }
    }

    property Component locationMenuComp: LocationMenu {}

    component PremiumTextField : TextField {
        id: tfControl
        color: colorText
        font.pixelSize: 13
        selectByMouse: true
        hoverEnabled: true
        verticalAlignment: TextInput.AlignVCenter
        leftPadding: 10; rightPadding: 10
        palette.text: colorText
        palette.base: "transparent"
        
        background: Rectangle {
            color: tfControl.activeFocus ? (isDark ? "#121214" : "#ffffff") : colorInput
            border.color: tfControl.activeFocus ? colorAccent : (tfControl.hovered ? Qt.rgba(colorAccent.r, colorAccent.g, colorAccent.b, 0.5) : colorBorder)
            border.width: tfControl.activeFocus ? 1.5 : 1
            radius: 6
            
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
