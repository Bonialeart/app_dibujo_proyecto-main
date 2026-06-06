# Documento de Mejoras: Modo Ilustración

## 1. Resumen Ejecutivo

Actualmente, "Modo Ilustración" es solo un layout de paneles predefinido dentro del **Modo Studio** (panel_manager.cpp:158-176). No existe una experiencia diferenciada e integral para ilustración que optimice flujos de trabajo concretos (boceto, lineart, color, sombreado, render final).

El **Modo Esencial** carece por completo de una variante orientada a ilustración: es un modo genérico simplificado (inspirado en Procreate) sin paneles ni herramientas específicas.

Este documento detalla los cambios necesarios para que **Modo Ilustración** sea un modo de primera clase, tanto en Essential como en Studio.

---

## 2. Estado Actual

### 2.1 Modo Esencial (canvasMode: "essential")
- Interfaz simplificada con paneles flotantes/draggables.
- Barra lateral con herramientas, panel de color, ajustes de pincel, slider toolbox.
- `SimpleAnimationBar.qml` siempre visible (innecesaria en ilustración pura).
- Sin workspace switcher ni personalización de paneles.

### 2.2 Modo Studio (canvasMode: "studio") — Workspace "Ilustración"
- Dock izquierdo: Brushes, Settings, ToolSettings.
- Dock derecho: Color, Layers, Navigator, History, Reference, Gradient, Info.
- Dock inferior: Timeline.
- Misma disposición básica sin diferenciación real de Manga/Comic o Animación.

---

## 3. Cambios Propuestos

### 3.1 Modo Esencial — Variante Ilustración

#### 3.1.1 Barra Superior Contextual
- Mostrar controles específicos de ilustración:
  - Flip horizontal/vertical del canvas.
  - Botón de simetría con acceso rápido a modos (vertical, horizontal, cuadrante, radial).
  - Selector rápido de preset de pincel por fase (Boceto → Lineart → Color → Sombreado).
  - Botón "Ajustar al tamaño de la ventana" + "Vista al 100%".

#### 3.1.2 Paneles Flotantes Optimizados
- **Color Panel Plus**: Versión mejorada que ocupe menos espacio, con rueda cromática compacta, paleta de swatches recientes, y color history integrado en el mismo panel.
- **Referencia Rápida**: Panel de referencia invocable con atajo (W), que se posicione automáticamente en una esquina sin interrumpir el flujo.
- **Capas simplificadas**: Mostrar solo lo esencial: blending mode, opacidad, bloqueo de transparencia. Ocultar opciones avanzadas (máscaras, grupos) por defecto.

#### 3.1.3 Ocultación Automática
- `SimpleAnimationBar` debe ocultarse automáticamente cuando no hay fotogramas de animación.
- En ilustración, la barra de herramientas inferior (slider toolbox) debe poder contraerse a un mini-overlay.

#### 3.1.4 Presets de Herramientas por Fase
- Añadir un `ToolPresetBar` (barra deslizable arriba del canvas) con fases:
  - ✏️ Boceto (lápices, goma suave)
  - 🖊️ Lineart (plumillas, tinta, estabilización alta)
  - 🎨 Color base (pinceles planos, relleno)
  - 🌗 Sombreado/Iluminación (pinceles suaves, aerógrafo, modos de fusión)
  - ✨ Detalles/Render (pinceles de textura, luces)

---

### 3.2 Modo Studio — Workspace "Ilustración" Mejorado

#### 3.2.1 Layout de Paneles Rediseñado
- **Izquierdo**: Brushes, ToolPresets (nuevo panel con fases de ilustración), ToolSettings.
- **Derecho**: Color (rueda cromática como pestaña activa por defecto), Swatches (nuevo), Layers, Navigator.
- **Flotante**: Reference panel (posicionado arriba-derecha por defecto), Color History (mini-panel).
- **Inferior**: Info bar compacta (tamaño de pincel, zoom, coordenadas). Timeline oculta por defecto (solo se muestra cuando hay animación).
- **Añadir panel "Paleta de Colores"** con swatches por defecto para: piel, cielo, vegetación, metales.

#### 3.2.2 Nueva Funcionalidad: Quick Actions Toolbar
- Barra flotante invocable con Space (mantener presionado) con:
  - Selección rápida de color (eyedropper temporal).
  - Rotación del canvas (ruleta).
  - Flip temporal del canvas.
  - Zoom rápido con slider radial.
  - Cambio de pincel reciente (últimos 5 usados).

#### 3.2.3 Nueva Funcionalidad: Color Harmony Picker
- En el panel de color, añadir modo "Armonía":
  - Complementario, Análogo, Triádico, Tetrádico, Dividido-Complementario.
  - Muestra 3-5 variaciones del color activo en mini-círculos.
  - Click para seleccionar el color armónico.

#### 3.2.4 Nueva Funcionalidad: Brush Stroke Preview
- Panel pequeño (o tooltip) que muestra una previsualización en vivo del trazo del pincel activo.
- Útil para ajustar dinámicas sin hacer trazos de prueba en el canvas.

#### 3.2.5 Navigator Plus
- El Navigator actual muestra solo miniatura. Añadir:
  - Overlay de reglas (mostrar guías de tercios, espiral áurea, rectángulo áureo).
  - Botón de rotación rápida (0°, 90°, 180°, -90°).
  - Indicador de zona de enfoque (depth of field simulado).

---

### 3.3 Cambios Transversales (Essential y Studio)

#### 3.3.1 Sistema de Fases de Ilustración ("Illustration Pipeline")
- Nuevo concepto: El usuario selecciona en qué fase está trabajando.
- Cada fase carga automáticamente:
  - Preset de pincel principal.
  - Visibilidad de paneles relevantes.
  - Atajos de teclado contextuales.
  - Modo de fusión de capa por defecto.
  - Estabilización y dinámicas de presión recomendadas.

Fases a implementar:
| Fase | Pincel Default | Estabilización | Panel Clave | Blending Mode |
|------|---------------|---------------|-------------|---------------|
| Boceto | Lápiz 6B | Baja (10%) | Navigator, Simetría | Normal |
| Lineart | Plumilla G | Alta (60%) | Layers, History | Normal |
| Color Base | Pincel Plano | Media (20%) | Color, Swatches, Layers | Normal |
| Sombreado | Aerógrafo suave | Baja (5%) | Color, Capas (Multiply) | Multiply |
| Luces | Pincel Duro | Baja (5%) | Color, Capas (Screen) | Screen/Overlay |
| Render | Pincel Textura | Media (30%) | Color, Gradient, Info | Overlay/Normal |

#### 3.3.2 Atajos de Teclado Dedicados a Ilustración
- `W`: Alternar visibilidad de panel de referencia.
- `E`: Alternar visibilidad de panel de swatches/color.
- `R`: Rotar canvas (hold + arrastrar).
- `Shift+R`: Resetear rotación.
- `H`: Flip horizontal del canvas (espejo temporal).
- `V`: Flip vertical.
- `1-6`: Cambiar entre fases (Boceto→Render).
- `[` / `]`: Navegar entre pinceles recientes.
- `Alt+Click`: Eyedropper de color.
- `Ctrl+Alt+Click`: Eyedropper de color con promedio de área.

#### 3.3.3 Mejoras en Simetría para Ilustración
- Añadir modo "Rostro": simetría vertical automática con línea central ajustable.
- Añadir overlay visual de eje de simetría más claro (línea punteada con color de acento).
- Quick-toggle con `S` para activar/desactivar simetría sin abrir menú.

#### 3.3.4 Referencia Visual Mejorada
- El panel Reference debe permitir:
  - Cargar múltiples imágenes en galería (pestañas/carrusel).
  - Extraer paleta de colores automática (3-5 colores dominantes → añadir a Swatches).
  - Fijar la imagen de referencia semi-transparente sobre el canvas (overlay de referencia).
  - Ajustar opacidad del overlay desde el panel.

#### 3.3.5 Exportación Específica para Ilustración
- Presets de exportación:
  - **Redes Sociales**: 1080×1080 (Instagram), 1920×1080 (ArtStation/Twitter).
  - **Impresión**: A4 300dpi, A3 300dpi, Carta 300dpi.
  - **Web**: PNG con perfil de color sRGB, JPEG calidad 95%.
  - **Timelapse**: Exportar automático del proceso de ilustración (ya implementado pero sin UI dedicada).

---

## 4. Archivos a Modificar

| Archivo | Cambio | Prioridad |
|---------|--------|-----------|
| `src/ui/qml/main_pro.qml` | Añadir `illustrationPhase` property + lógica de fases; nuevos atajos; condicionales para Essential mode | Alta |
| `src/ui/qml/components/StudioCanvasLayout.qml` | Rediseñar layout de ilustración; añadir QuickActionsToolbar; mejorar barra superior | Alta |
| `src/core/cpp/src/panel_manager.cpp` | Nuevo workspace "Ilustración Pro" con layout mejorado; añadir nuevos paneles | Alta |
| `src/core/cpp/include/panel_manager.h` | Nuevas señales para cambio de fase de ilustración | Media |
| `src/ui/qml/components/ColorPanel.qml` | Añadir Color Harmony Picker y rueda cromática mejorada | Alta |
| `src/ui/qml/components/ReferencePanel.qml` | Multi-imagen, extracción de paleta, overlay | Alta |
| `src/ui/qml/components/NavigatorPanel.qml` | Overlay de reglas de composición, botón de rotación | Media |
| `src/ui/qml/components/*` (nuevo) | `ToolPresetPanel.qml`, `QuickActionsToolbar.qml`, `BrushStrokePreview.qml`, `IllustrationPhaseBar.qml` | Alta |
| `src/ui/qml/components/SimpleAnimationBar.qml` | Ocultar automáticamente en modo ilustración sin animación | Baja |
| `src/PreferencesManager.h` | Añadir preferencias para fases de ilustración y workspace switcher | Media |
| `src/ui/qml/components/PreferencesDialog.qml` | UI para configurar fases de ilustración y atajos | Media |

---

## 5. Priorización

### Fase 1 — MVP (Core Ilustración)
1. Sistema de fases de ilustración (PhaseBar).
2. Layout de paneles rediseñado para "Ilustración" en Studio.
3. Atajos de teclado básicos (W, E, R, H, 1-6).
4. Ocultación automática de Timeline en modo ilustración.
5. Presets de exportación para ilustración.

### Fase 2 — Productividad
1. Color Harmony Picker en panel de color.
2. Reference Panel mejorado (multi-imagen + overlay).
3. Quick Actions Toolbar (Space hold).
4. ToolPresetPanel con fases.
5. Navigator mejorado con reglas de composición.

### Fase 3 — Pulido
1. Brush Stroke Preview.
2. Extracción de paleta desde referencia.
3. Simetría "Rostro" y overlay mejorado.
4. Modo Esencial con variante ilustración.
5. Preferencias y personalización de fases.

---

## 6. Notas Técnicas

- **Fases de ilustración**: Implementar como enum en C++ (`enum class IllustrationPhase { Sketch, Lineart, BaseColor, Shading, Lighting, Render }`) expuesto a QML via `Q_PROPERTY`.
- **ToolPresets**: Almacenar en JSON dentro de `resources/`, cargables por fase.
- **Color Harmony**: Algoritmos de armonía de color en C++ (HSV rotaciones), UI en QML.
- **Overlay de referencia**: Usar un `ShaderEffect` o `Item` semi-transparente sobre el canvas, no bloqueante para input del lápiz.
- **Quick Actions Toolbar**: Implementar como popup radial (radial menu) o como barra circular tipo "pie menu" al estilo de Procreate o Clip Studio.
- **Workspace "Ilustración Pro"**: Debe ser un workspace aparte, preservando el actual "Ilustración" como respaldo para usuarios que prefieran el layout clásico.

---

*Documento generado el 06/06/2026 — Basado en el código fuente de Kromo Studio Pro y el Roadmap_Competitividad.md*
