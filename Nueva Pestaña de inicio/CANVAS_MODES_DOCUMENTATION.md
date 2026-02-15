# ArtFlow Studio Pro - Sistema de Canvas Dual Mode

## 📋 Descripción General

Este sistema implementa **dos modos de interfaz de canvas** completamente funcionales y profesionales para ArtFlow Studio Pro:

### 1. **Modo Simple** (Default)
- Interfaz limpia y minimalista inspirada en Procreate
- Paneles flotantes que aparecen/desaparecen según necesidad
- Barra de herramientas vertical compacta
- Sliders flotantes arrastrables
- Perfecto para ilustración rápida y flujo creativo sin distracciones

### 2. **Modo Studio** (Avanzado)
- Interfaz completamente personalizable estilo Clip Studio Paint
- Paneles acoplables (dockable) con drag & drop
- Sistema de pestañas múltiples
- Áreas de dock configurables (izquierda, derecha, abajo)
- Paneles flotantes con persistencia de posición
- Perfecto para trabajo profesional con múltiples herramientas simultáneas

---

## 🎨 Modo Simple - Características

### Top Bar Premium
```
┌────────────────────────────────────────────────────────────┐
│  [☰] [↶][↷] │  Untitled Canvas  │ [🖌️][📄][🎨]           │
│                1920×1080 • 100%                             │
└────────────────────────────────────────────────────────────┘
```

**Componentes:**
- **Menu hamburguesa** (izquierda): Acceso rápido a opciones
- **Undo/Redo**: Botones siempre visibles
- **Info del proyecto**: Centro con nombre y dimensiones
- **Toggles de paneles**: Pinceles, Capas, Colores (derecha)

### Toolbar Vertical (Derecha)
- **54px de ancho** - Compacta y elegante
- **Glassmorphism**: Fondo semi-transparente con blur
- **12 herramientas principales**: Selección, Formas, Lazo, Transformar, Pluma, Lápiz, Pincel, Aerógrafo, Borrador, Relleno, Cuentagotas, Mano
- **Iconos emoji** como fallback universal
- **Hover states** y **active state** con color accent

### Sliders Flotantes (Izquierda)
- **Arrastrables** por cualquier parte de la pantalla
- **Verticales compactos**: 48px × 360px
- **Controles**: Size (Tamaño) y Opac (Opacidad)
- **Drag handle** visible en la parte superior

### Paneles Modales
Los paneles se abren como **overlays flotantes** que cubren parte del canvas:

```qml
// Ejemplo de activación
showBrushes: true  // Abre panel de pinceles
showLayers: true   // Abre panel de capas
showColors: true   // Abre panel de colores
```

**Características:**
- Se cierran automáticamente al seleccionar otra herramienta
- Animaciones suaves (fade + scale)
- Click fuera para cerrar
- Máximo un panel abierto a la vez

---

## 🎯 Modo Studio - Arquitectura

### Estructura de Layout

```
┌─────────────────────────────────────────────────────────────┐
│  File  Edit  View  Layer  Select  Filter  Window  Help      │  ← MenuBar
├─────────────────────────────────────────────────────────────┤
│  [↶][↷] │ [✥][▢][➰][✣] [✒][✎][🖌][💨] [⌫][🪣][💉][✋]     │  ← ToolBar
├──────────┬──────────────────────────────────────┬───────────┤
│          │  [Untitled-1] [×]                    │           │
│  Tool    │  ┌──────────────────────────────┐    │  Layers   │
│  Props   │  │                              │    │           │
│          │  │       CANVAS AREA            │    │  ┌──────┐ │
│  ┌────┐  │  │                              │    │  │Layer1│ │
│  │    │  │  │                              │    │  │Layer2│ │
│  └────┘  │  │                              │    │  └──────┘ │
│          │  │                              │    │           │
│  Sub     │  └──────────────────────────────┘    │  Navigator│
│  Tools   │                                      │  ┌──────┐ │
│  ┌────┐  │                                      │  │ mini │ │
│  │████│  │                                      │  └──────┘ │
│  └────┘  │                                      │           │
└──────────┴──────────────────────────────────────┴───────────┘
  LEFT DOCK          CENTER                        RIGHT DOCK
```

### Sistema de Paneles

#### Panel Configuration Object
```javascript
{
    id: "layers",           // Identificador único
    title: "Layers",        // Título visible
    icon: "📄",            // Emoji o icono
    visible: true,          // Visibilidad inicial
    docked: "right",        // "left", "right", "bottom", "none"
    x: 0,                   // Posición X (si floating)
    y: 0,                   // Posición Y (si floating)
    width: 280,             // Ancho
    height: 400,            // Alto
    minWidth: 200,          // Ancho mínimo
    minHeight: 150,         // Alto mínimo
    content: Component      // Componente QML del contenido
}
```

### Dock Areas

**Left Dock** (320px)
- Tool Properties
- Sub Tools
- Brush Presets

**Right Dock** (300px)
- Layers
- Navigator
- History

**Bottom Dock** (200px altura)
- Timeline
- Animation
- Referencias

**Floating**
- Cualquier panel puede flotar libremente
- Se puede arrastrar fuera de los docks
- Mantiene posición persistente

### Drag & Drop System

**Funcionalidad:**
1. **Arrastrar Tab** → Inicia drag operation
2. **Hover sobre Dock Area** → Muestra indicador visual
3. **Drop** → Panel se acopla en el área
4. **Reordenar** → Arrastra tabs dentro del mismo dock

**Mime Type:**
```qml
Drag.mimeData: {
    "application/x-studiopanel": panelId
}
```

### Tab System

Múltiples paneles pueden compartir el mismo dock area usando **tabs**:

```
┌──────────────────────────────────┐
│ [Layers]  [Navigator]  [History] │  ← Tabs
├──────────────────────────────────┤
│                                  │
│  Content del panel activo        │
│                                  │
└──────────────────────────────────┘
```

### Resize System

**Paneles Acoplados:**
- Handle horizontal en la parte inferior
- Resize vertical dentro del dock area
- Respeta `minHeight`

**Paneles Flotantes:**
- Handle en esquina inferior derecha
- Resize en ambas direcciones
- Respeta `minWidth` y `minHeight`

---

## 🔧 Integración con el Código Existente

### 1. Reemplazar Canvas Page en main_pro.qml

**ANTES:**
```qml
Item {
    id: canvasPage
    // ... código existente ...
}
```

**DESPUÉS:**
```qml
CanvasMode {
    id: canvasMode
    mainCanvas: mainCanvas
    colorAccent: mainWindow.colorAccent
    isZenMode: mainWindow.isZenMode
    
    // Bind properties
    isStudioMode: preferencesManager.canvasMode === "studio"
    
    // Connections
    onActiveToolIdxChanged: {
        // Actualizar herramienta en mainCanvas
    }
}
```

### 2. Preferencias de Usuario

Añadir opción en `PreferencesDialog.qml`:

```qml
Column {
    Text { text: "Canvas Mode"; color: "#fff"; font.bold: true }
    
    Row {
        spacing: 10
        
        RadioButton {
            text: "Simple Mode"
            checked: preferencesManager.canvasMode === "simple"
            onClicked: preferencesManager.canvasMode = "simple"
        }
        
        RadioButton {
            text: "Studio Mode"
            checked: preferencesManager.canvasMode === "studio"
            onClicked: preferencesManager.canvasMode = "studio"
        }
    }
}
```

### 3. Persistencia de Layout

Guardar configuración al cerrar:

```qml
Component.onDestruction: {
    if (isStudioMode) {
        var layout = panelManager.savePanelLayout()
        preferencesManager.studioLayout = layout
    }
}

Component.onCompleted: {
    if (isStudioMode && preferencesManager.studioLayout) {
        panelManager.loadPanelLayout(preferencesManager.studioLayout)
    }
}
```

---

## 🎨 Mejoras de Diseño Implementadas

### Simple Mode

**Top Bar:**
- **Altura reducida**: 48px (antes 56px)
- **Glassmorphism sutil**: Transparencia del 95%
- **Spacing optimizado**: Más compacto pero respirable
- **Iconos emoji** para universalidad

**Toolbar:**
- **Ancho reducido**: 54px (antes 64px)
- **Radius aumentado**: 27px (casi circular)
- **Iconos más grandes**: 18px para mejor visibilidad
- **Spacing interno**: 6px entre herramientas

**Sliders:**
- **Más delgados**: 48px de ancho
- **Verticales puros**: Mejor para tablet/pen
- **Labels minimalistas**: Solo texto esencial
- **Drag handle obvio**: Indicador visual claro

### Studio Mode

**MenuBar:**
- **Altura compacta**: 28px
- **Tipografía Pro**: 11px font size
- **Hover states claros**

**ToolBar:**
- **48px altura** (más bajo que antes)
- **Iconos en fila**: Máximo aprovechamiento horizontal
- **Separadores visuales**: Para agrupar herramientas

**Paneles:**
- **Headers consistentes**: 32px altura
- **Controles de ventana**: Minimizar, Maximizar, Cerrar
- **Tab system**: Múltiples paneles por dock
- **Resize handles**: Visual y funcional

---

## 📱 Responsive Considerations

### Breakpoints Recomendados

```qml
property bool isCompact: width < 1280
property bool isLarge: width >= 1920

// Ajustar docks según tamaño
leftDockArea.width: isCompact ? 280 : 320
rightDockArea.width: isCompact ? 260 : 300
```

### Touch Optimization

**Simple Mode** (touch-first):
- Botones mínimo 44×44px
- Sliders con área de tap extendida
- Gestos para cerrar paneles (swipe)

**Studio Mode** (precision-first):
- Mantiene controles pequeños para maximizar espacio
- Drag handles más grandes
- Tooltip delays cortos

---

## 🚀 Features Avanzadas para Implementar

### 1. Panel Presets
```qml
StudioPanelManager {
    presets: {
        "illustration": {
            left: ["brushes", "toolProps"],
            right: ["layers", "navigator"]
        },
        "animation": {
            left: ["timeline"],
            right: ["layers"],
            bottom: ["animator"]
        }
    }
}
```

### 2. Workspace Switcher
```qml
ComboBox {
    model: ["Illustration", "Animation", "Concept Art", "Comic"]
    onActivated: panelManager.loadPreset(currentText)
}
```

### 3. Panel Groups
Agrupar paneles relacionados en tabs automáticamente:
```qml
{
    "color-tools": ["colorWheel", "colorSliders", "palettes"]
}
```

### 4. Quick Toggle
Shortcut para mostrar/ocultar todos los paneles:
```qml
Shortcut {
    sequence: "Tab"
    onActivated: isZenMode = !isZenMode
}
```

---

## 🎯 Checklist de Implementación

### Fase 1: Modo Simple
- [x] Top bar rediseñada
- [x] Toolbar vertical compacta
- [x] Sliders flotantes arrastrables
- [ ] Panel de pinceles (contenido)
- [ ] Panel de capas (contenido)
- [ ] Panel de colores (contenido)
- [ ] Animaciones polish

### Fase 2: Modo Studio
- [x] MenuBar implementation
- [x] ToolBar horizontal
- [x] Dock areas (left, right, bottom)
- [x] Panel drag & drop system
- [x] Tab system
- [x] Resize handles
- [ ] Panel content components
- [ ] Persistence system
- [ ] Workspace presets

### Fase 3: Polish & UX
- [ ] Smooth animations
- [ ] Keyboard shortcuts
- [ ] Context menus
- [ ] Panel search/filter
- [ ] Tutorial overlay
- [ ] Dark/Light theme support

---

## 🔍 Debugging & Testing

### Panel State Debugging
```qml
Text {
    text: JSON.stringify(panelManager.panels, null, 2)
    color: "lime"
    font.pixelSize: 10
    anchors.bottom: parent.bottom
    anchors.left: parent.left
}
```

### Performance Monitoring
```qml
Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
        console.log("Visible panels:", 
            Object.keys(panels).filter(k => panels[k].visible).length
        )
    }
}
```

---

## 📚 Referencias & Inspiración

- **Procreate** - Simple Mode UI/UX
- **Clip Studio Paint** - Studio Mode layout
- **Adobe Photoshop** - Panel docking system
- **Krita** - Workspace presets
- **Figma** - Floating panels

---

## 🤝 Contribución

Para añadir nuevos paneles al sistema:

```qml
// 1. Crear componente del panel
Component {
    id: myCustomPanel
    Rectangle {
        // Panel content
    }
}

// 2. Registrar en panelManager
panelManager.registerPanel("myPanel", {
    title: "My Panel",
    icon: "🎨",
    content: myCustomPanel,
    docked: "right",
    width: 280,
    height: 350
})
```

---

## 📄 Licencia

Este código es parte de ArtFlow Studio Pro y sigue la misma licencia del proyecto principal.

---

**Versión:** 1.0.0  
**Última actualización:** Febrero 2026  
**Autor:** ArtFlow Team
