# BrushStudio — Lista de tareas pendientes

Archivo: `src/ui/qml/components/BrushStudioDialog.qml`

---

## 🔴 Alta prioridad

### H1 — Botón "+" sin funcionalidad
**Líneas:** ~670-677  
**Problema:** El botón "+" al lado del nombre del pincel tiene MouseArea con hover y cursor de mano, pero **no tiene `onClicked`**. No hace nada.  
**Solución:** Implementar la acción (ej: crear nuevo pincel, duplicar, o mostrar un menú).

### H2 — Reactividad rota en Tab 11 (D- Textura)
**Línea:** 2253  
**Problema:** `isDualBrushEnabled` no depende de `studio.brushPropertySeed`, por lo que al activar/desactivar "Pincel Dual" desde Tab 10, la visibilidad del contenido en Tab 11 no se actualiza hasta que se cambia de pestaña.  
**Solución:** Agregar `studio.brushPropertySeed;` como dependencia en la propiedad.

### H3 — Popup de color sin cierre al hacer clic fuera
**Líneas:** ~2813-2847  
**Problema:** El selector rápido de color (`colorPopup`) solo se cierra al hacer clic en el círculo de color nuevamente o al seleccionar un color. No hay forma de cerrarlo haciendo clic fuera.  
**Solución:** Agregar un MouseArea detrás (overlay) que lo cierre, o convertir a Popup nativo con `closePolicy`.

---

## 🟡 Prioridad media

### M1 — Etiqueta de tamaño del pincel muestra valor incorrecto
**Línea:** 2942  
**Problema:** `Math.round(verticalSizeSlider.value)` muestra el valor normalizado (0–1) en lugar del tamaño real en píxeles. Siempre muestra 0 o 1.  
**Solución:** Cambiar a `Math.round(drawingPad.padBrushSize) + "px"`.

### M2 — ID duplicado `resetMa`
**Líneas:** 434 y 1821  
**Problema:** El id `resetMa` aparece tanto dentro del componente `StudioSlider` (línea 434) como en el botón "Reestablecer" de la pestaña Personalizar (línea 1821). Aunque están en ámbitos distintos, el motor QML puede emitir advertencias.  
**Solución:** Renombrar uno de ellos (ej: `resetDefaultsMa`).

### M3 — Patrón `brushPropertySeed` frágil (43 ocurrencias)
**Múltiples líneas**  
**Problema:** El patrón `(studio.brushPropertySeed, expresión)` se usa extensamente para forzar re-evaluación de bindings. Es frágil y puede fallar en ciertas versiones de Qt. En algunas líneas se usa `studio.brushPropertySeed;` como statement (no como expresión), lo cual **no fuerza re-evaluación**.  
**Solución:** Reemplazar con señales/propiedades reactivas adecuadas desde el backend C++, o usar un patrón más robusto.

### M4 — Referencia frágil a `children[0]`
**Línea:** 1917  
**Problema:** `parent.children[0].text === ""` asume que el TextEdit es el primer hijo. Si se agrega otro hijo antes, se rompe.  
**Solución:** Usar un id explícito en el TextEdit y referenciarlo directamente.

### M5 — Editores de nombre duplicados en Tab 8 y Tab 9
**Líneas:** 1719-1726 y 1853-1859  
**Problema:** Ambas pestañas tienen un TextInput para editar el nombre del pincel, pero **no están sincronizados**. Editar en una no actualiza la otra.  
**Solución:** Unificar en un solo editor o sincronizar mediante señales.

### M6 — `settingsLoader.active` toggle destruye estado del componente
**Líneas:** 43-46 y 1825-1827  
**Problema:** `settingsLoader.active = false; settingsLoader.active = true` destruye y recrea todo el árbol de settings, perdiendo estado transiente (valores por defecto capturados en `Component.onCompleted`).  
**Solución:** Usar un mecanismo más selectivo para refrescar (ej: señales del backend, o solo recargar los valores sin recrear el componente).

---

## 🟢 Baja prioridad / Refactorización

### L1 — `getAvailableTipTextures()` usado también para grain
**Líneas:** 84, 112, 1110, 2390  
**Problema:** Se usa la misma función para texturas de punta y de grano. Asume que el backend comparte la misma lista.  
**Solución:** Verificar si existe `getAvailableGrainTextures()` y usarla donde corresponda.

### L2 — Cuatro funciones getter de textura casi idénticas
**Líneas:** 66-119  
**Problema:** `getActiveTipTexturePath()`, `getActiveGrainTexturePath()`, `getActiveDualTipTexturePath()`, `getActiveDualGrainTexturePath()` comparten >95% del código.  
**Solución:** Refactorizar a una sola función parametrizada.

### L3 — Grids de selección de textura duplicados 4 veces
**Líneas:** 837-881, 1080-1141, 2031-2072, 2363-2412  
**Problema:** El patrón "grid expandible de thumbnails de textura" se repite casi idéntico para punta, grano, punta dual y grano dual.  
**Solución:** Extraer a un componente reutilizable `TexturePickerGrid`.

### L4 — Componentes de botón de blend mode duplicados 3 veces
**Líneas:** 1192, 2111, 2486  
**Problema:** `GrainBlendButton`, `BlendButton`, `DualGrainBlendButtonTab11` son prácticamente idénticos.  
**Solución:** Unificar en un solo componente `BlendModeButton`.

### L5 — Sliders verticales de tamaño y opacidad casi idénticos
**Líneas:** 2857-2947 y 2949-3037  
**Problema:** Los dos capsules verticales (tamaño y opacidad) comparten ~90% del código.  
**Solución:** Extraer a un componente `VerticalSliderCapsule`.

### L6 — Botón "Guardar Como Copia" sin feedback
**Líneas:** 241-243  
**Problema:** No hay confirmación visual de que la copia se guardó exitosamente.  
**Solución:** Agregar un toast o cambiar temporalmente el texto a "✓ Guardado".

### L7 — Botones superiores sin estado disabled
**Líneas:** 190-275  
**Problema:** Cuando `targetCanvas` es null, los botones Cancelar/Guardar Como Copia/Aplicar siguen viéndose activos pero no hacen nada.  
**Solución:** Agregar estado visual `enabled: targetCanvas !== null` con opacidad reducida.

### L8 — Escala del cursor en el pad de prueba
**Líneas:** 2693-2694  
**Problema:** El tamaño del cursor del pincel puede no coincidir con la escala del preview pad si hay diferencias de DPI.  
**Solución:** Verificar y ajustar la escala si es necesario.

---

## ✨ Mejoras adicionales sugeridas

### S1 — Atajo de teclado
Agregar `Enter` para aplicar y `Escape` para cancelar.

### S2 — Tooltips
Agregar tooltips a los botones de la barra superior y a las píldoras de pestañas.

### S3 — Slider doble (range) para límites min/max
En lugar de sliders separados para "Tamaño mín/máx", usar un slider doble.

### S4 — Búsqueda en grids de texturas
Cuando hay muchas texturas, agregar un campo de búsqueda/filtro.

### S5 — Vista previa en tiempo real más fluida
El sistema actual de crossfade (Timer dual con swap) podría reemplazarse con actualización directa usando `Image.currentFrame` o un `ShaderEffect`.

### S6 — Botón "Aplicar a todos los pinceles"
Opción para aplicar la configuración actual a múltiples pinceles.
