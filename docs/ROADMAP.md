# KromoStudio -- Roadmap de Desarrollo

## Estado General

Leyenda: COMPLETADO (implementado y operativo) | EN DESARROLLO (en progreso) | PLANIFICADO (pendiente)

---

## 1. Motor de Dibujo e Ilustracion

### COMPLETADO

- Motor de pinceles C++ con dinamicas de presion, angulo e inclinacion (Wintab)
- Simulador de acuarela avanzado (difusion de pigmentos, flujo humedo/seco)
- Pinceles duales y de textura (combinacion de dos puntas simultaneas)
- Reglas de perspectiva Pro (1, 2 y 3 puntos de fuga con snapping magnetico)
- Simetria dinamica multieje (Vertical, Horizontal, Cuadrante, Radial)
- Capas vectoriales inteligentes (curvas Bezier, borrador vectorial con corte por interseccion)
- Motor de licuado acelerado por GPU (Empujar, Inflar, Pellizcar, Reconstruir, Torbellino)
- Estabilizacion de trazo (smoothing con algoritmo de cuerda elastica)
- Curvas de presion ajustables por pincel
- Mapa de degradado no destructivo por GPU (5 presets: Sunset, Ocean, Forest, Retro, Manga)
- Ajustes HSL, curvas tonales y brillo/contraste
- Desenfoque Gaussiano y Glow/Bloom por GPU
- Armonia de color (algoritmos C++ para esquemas complementarios, analogos, triadicos, etc.)
- Importacion de pinceles ABR (Photoshop)
- Clipping masks (mascaras de recorte)
- Historial de color dinamico
- Capas con modos de fusion (Multiplicar, Pantalla, Superponer, etc.)
- Seleccion por gama de color (color range selector)

### PLANIFICADO

- Herramientas de seleccion (Lazo, Rectangulo, Varita Magica, Lazo Magnetico)
- Herramienta de transformacion (Escalar, Rotar, Distorsionar, Deformacion por malla)
- Cubo de pintura (Fill con tolerancia) y relleno de degradado (Lineal/Radial)
- Herramientas de formas geometricas (Linea, Rectangulo, Elipse, Poligono)
- Deformacion por malla y jaula (Mesh & Cage Warp)
- Pinceles 3D e Impasto realista (relieve tridimensional con mapas de alturas)
- Motor de pinceles de oleo con acumulacion de pasta
- Modos de fusion adicionales (Glow Dodge, Hard Mix, Divide)
- Importacion/exportacion de paletas .ASE y .CLR
- Sistema de fases de ilustracion (Boceto, Lineart, Color, Sombreado, Luces, Render)
- Presets de exportacion especificos (Redes Sociales, Impresion, Web, Timelapse)

---

## 2. Animacion 2D

### COMPLETADO

- Linea de tiempo dinamica (Timeline) con celdas y fotogramas clave
- Papel cebolla (Onion Skinning) con opacidad ajustable y fotogramas guia (rojo/verde)
- Duracion de exposicion ajustable (Duration Stretch)
- Operaciones de celda (anadir, duplicar, eliminar fotogramas)
- Barra de animacion simple (Modo Esencial) y panel completo (Modo Studio)

### PLANIFICADO

- Carpetas de animacion (Animation Folders) para agrupar lineart, color y fondos
- Interpolacion vectorial ligera (animar posicion, escala, rotacion por curvas)
- Exportacion a GIF animado, MP4 (H.264/H.265), APNG y spritesheets
- Pista de audio y sincronizacion labial (Lip-Sync)
- Camara de animacion con encuadres y movimientos
- Hoja de exposicion (X-Sheet) tradicional

---

## 3. Modo Comic / Manga

### COMPLETADO

- Distribuidor de vinetas (Panel Cutter) con corte rectangular y diagonal
- Mascaras automaticas por vineta con espacio de separacion (gutter) ajustable
- Globos de texto vectoriales (ovalo, rectangulo redondeado, grito, narracion)
- Rabos dinamicos apuntando al personaje
- Personalizacion de color, borde y dimensiones de globos
- Gestor de proyectos multipagina (StoryPanel) con miniaturas y ordenacion
- Screentone no destructivo por GPU (puntos, lineas, ruido) con frecuencia, angulo y contraste
- Overlay de camara y guias de vineta

### PLANIFICADO

- Tipografia con bordes (outlines) y sombreado 3D
- Guias de impresion profesionales (Bleed & Crop Marks)
- Diseno Webtoon horizontal/vertical con marcas de corte automaticas
- Filtro de conversion a escala de grises y tramado automatico (Halftoning Pro)
- Exportacion de paginas individuales y tomos completos
- Plantillas de formato de pagina (Japonés, Americano, Europeo, Webtoon)

---

## 4. Modo Studio y Espacios de Trabajo

### COMPLETADO

- Sistema de anclaje de paneles (Docking System) completo
- Paneles acoplables en izquierda, derecha (doble columna) e inferior
- Paneles flotantes independientes
- Auto-guardado de sesion de interfaz (.ini)
- 3 workspaces predefinidos: Ilustracion, Manga/Comic, Animacion
- Navigator Panel (miniatura interactiva del lienzo)
- Reference Panel (visor de imagenes de referencia)
- History Panel (historial de deshacer/rehacer)
- Info Panel (tamano de pincel, zoom, coordenadas)

### PLANIFICADO

- Modo sin distracciones (Distraction-Free) con menus radiales
- Barra de acciones rapidas (Quick Actions) invocable con Space
- Presets de interfaz guardables por el usuario
- Navigator Plus con overlays de reglas de composicion (tercios, espiral aurea)
- Panel de paleta de colores con swatches por defecto (piel, cielo, vegetacion, metales)
- Referencia multiple con galeria de imagenes y extraccion automatica de paleta
- Overlay de referencia semitransparente sobre el lienzo

---

## 5. Preferencias y Configuracion

### COMPLETADO

- Selector de API de tableta (Windows Ink vs WinTab)
- Temas visuales (Dark Mode, Slate Gray, Light Mode)
- Escala de interfaz (UI Scaling) para pantallas 4K
- Configuracion de idioma

### PLANIFICADO

- Asignacion visual de atajos de teclado (Shortcuts Customizer)
- Gestion de rendimiento (limite de RAM, Scratch Disk)
- Configuracion de autoguardado (intervalo, limite de respaldos)
- Personalizacion de modos de fusion por defecto
- Perfiles de configuracion exportables/importables

---

## 6. Opciones del Nucleo

### COMPLETADO

- Motor de renderizado OpenGL con shaders personalizados
- Autoguardado contra caidas con recuperacion de sesion
- Exportacion PSD multicapa nativa (capas, opacidad, modos de fusion)
- Grabacion de Timelapse en segundo plano
- Integracion con modulo Rust para computo paralelo (Rayon)
- Scripting con Lua 5.4.6
- Bloqueo alfa (Alpha Lock) por capa

### PLANIFICADO

- Aceleracion por Vulkan/DirectX (migracion de pipeline)
- Gestos multitactiles (rotacion y zoom con dos dedos)
- Sincronizacion en la nube y control de versiones
- Exportacion avanzada de Timelapse a MP4 con opciones de formato
- Renderizado por nodos (compositing node graph)
- Soporte para plugins y extensiones

---

## 7. Pinceles y Motores de Pintura

### COMPLETADO

- Motor de pinceles basado en dinamicas (presion, velocidad, angulo, inclinacion)
- Pinceles con punta unica y doble (dual brush)
- Texturas de grano (lienzo, carboncillo, papel de acuarela, papel de boceto)
- Pinceles de acuarela con simulacion fisica de pigmentos
- Catalogo de pinceles por categoria (abstract, acuarela, aerografo, artistico, caligrafia, carboncillo, dibujo, entintado, industrial, manga, oleo, pintura, texturas, vintage)
- Pinceles de tinta china con dinamicas de carga
- Pinceles de salpicaduras (splatter)
- Pinceles de portaminas y rotulador de punta pincel
- Previsualizacion de pincel en tiempo real
- Ajustes de pincel: tamano, opacidad, flujo, espaciado, suavizado, angle, scattering
- Importacion de pinceles .ABR (Photoshop)
- Presets de pinceles guardables en JSON

### PLANIFICADO

- Pinceles 3D con relieve e impasto (mapa de alturas en GPU)
- Pinceles de oleo con acumulacion de pasta y arrastre
- Pinceles de mosaico y patron
- Pinceles de pelo natural (cerda, marta, sintetico)
- Pinceles de efectos especiales (fuego, nubes, pelo, follaje)
- Pinceles de sellos (stamp brushes)
- Editor de puntas de pincel personalizadas
- Biblioteca de pinceles de la comunidad (tienda/mercado)
- Previsualizacion avanzada de trazo (Brush Stroke Preview)

---

## Prioridades Sugeridas para Proximas Iteraciones

### Fase 1 -- Herramientas Fundamentales
1. Herramientas de seleccion (Lazo, Rectangulo, Varita Magica)
2. Herramienta de transformacion (Escalar, Rotar, Distorsionar)
3. Cubo de pintura y relleno de degradado
4. Formas geometricas basicas

### Fase 2 -- Flujo de Ilustracion
1. Barra de fases de ilustracion (Boceto, Lineart, Color, Sombreado, Luces, Render)
2. Atajos de teclado dedicados a ilustracion
3. Presets de exportacion
4. Quick Actions Toolbar (Space hold)
5. Color Harmony Picker integrado en panel de color

### Fase 3 -- Animacion y Comic
1. Exportacion de animacion (GIF, MP4, APNG)
2. Carpetas de animacion
3. Guias de impresion y crop marks para comic
4. Formato Webtoon
5. Tipografia con bordes para globos de texto

### Fase 4 -- Pulido Profesional
1. Shortcuts Customizer (mapeo visual de atajos)
2. Modo sin distracciones
3. Gestos multitactiles
4. Migracion a Vulkan
5. Sincronizacion en la nube

---

*Documento generado el 07/06/2026 -- Basado en el codigo fuente de KromoStudio*
