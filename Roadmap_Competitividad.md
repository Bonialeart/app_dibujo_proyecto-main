# Plan de Competitividad: Kromo Studio Pro vs. Líderes del Mercado

Este documento detalla las funcionalidades, mejoras y la hoja de ruta necesarias para que **Kromo Studio Pro** compita al más alto nivel con aplicaciones de calibre profesional como **Clip Studio Paint**, **Procreate**, **Krita** y **Photoshop**.

---

## 🎨 1. Herramientas de Dibujo (Tools)
*Para potenciar la creación artística digital y la expresión gráfica profesional.*

1. **Reglas de Perspectiva Pro**: Soporte para reglas magnéticas y guías de 1, 2 y 3 puntos de fuga que fuercen el trazo a converger de forma perfecta.
2. **Herramienta de Simetría en Tiempo Real**: Creación de espejos radiales, verticales y horizontales (ideal para mandalas, rostros o diseño de concept art).
3. **Capas Vectoriales Inteligentes**: Capas especiales donde el lineart se almacena como curvas bezier, permitiendo reescalar sin pixelación y usar el "Borrador Vectorial" (corta el trazo exactamente hasta la siguiente intersección).
4. **Herramienta de Licuado Acelerada (Liquify)**: Modos de *Empujar, Inflar, Pellizcar, Reconstruir y Torbellino* en tiempo real directamente sobre el lienzo usando la GPU.
5. **Generador de Tramas (Screentone)**: Herramientas dedicadas a la creación de manga/cómics, para aplicar patrones de puntos semitonos de forma no destructiva.
6. **Lazo Magnético y Selección por Gama de Colores**: Algoritmos avanzados de detección de bordes y canales de color para selecciones hiperprecisas.
7. **Pinceles Duales y de Textura (¡COMPLETADO!)**: Motor avanzado que mezcla dos formas de punta (brush tips) simultáneas y soporte para texturas físicas con pincel seco controladas por la presión de la tableta.

---

## 🎞️ 2. Motor de Animación 2D (Animation Engine)
*Para dotar a los artistas de las herramientas necesarias para dar vida a sus ilustraciones sin salir de la app.*

1. **Línea de Tiempo Dinámica (Timeline)**: Interfaz intuitiva en la parte inferior para gestionar fotogramas, celdas de animación, capas de animación y velocidad de reproducción (FPS).
2. **Papel Cebolla Avanzado (Onion Skinning)**: Visualización configurable de fotogramas anteriores (tonos rojos) y posteriores (tonos verdes) con opacidad ajustable para guiar el movimiento.
3. **Carpetas de Animación (Animation Folders)**: Estructuras que permiten agrupar fotogramas clave y celdas individuales para coloreado, lineart y fondos de manera independiente.
4. **Interpolación Vectorial Ligera**: Capacidad de animar posiciones, escalas y rotaciones de capas completas o trayectorias vectoriales de forma automatizada mediante curvas de interpolación.
5. **Exportación Multipropósito**: Soporte para exportar proyectos animados directamente a formatos **GIF Animado**, **Vídeo MP4 (H.264/H.265)**, **APNG** y hojas de sprites (spritesheets) para videojuegos.

---

## 📖 3. Modo Cómic / Manga (Comic Studio Mode)
*Facilidades especializadas para el desarrollo secuencial de cómics, webtoons y novelas gráficas.*

1. **Gestor de Proyectos de Múltiples Páginas**: Interfaz de navegación para visualizar y ordenar un álbum o tomo completo de páginas de cómic con vista de miniaturas doble.
2. **Herramienta de División de Viñetas (Panel Cutter)**: Creación de bordes de viñetas con corte instantáneo, espaciado de margen personalizable y máscaras automáticas para cada recuadro.
3. **Globos de Texto Vectoriales (Speech Bubbles)**: Biblioteca de bocadillos de diálogo editables como curvas, con rabo dinámico apuntando al personaje y cajas de texto autoajustables.
4. **Tipografía con Bordes y Sombreado**: Renderizado de fuentes especializadas en cómic con bordes (outlines) de color personalizables y sombreado 3D de alta legibilidad.
5. **Guías de Impresión Profesionales (Bleed & Crop Marks)**: Visualización del área de recorte, área de seguridad y marcas de sangrado para asegurar la correcta exportación para imprenta.
6. **Diseño Webtoon Horizontal/Vertical**: Formatos de lienzo continuos optimizados para scroll vertical móvil, con marcas de corte de página automáticas.

---

## 🖥️ 4. Modo Estudio y Espacios de Trabajo (Studio Mode)
*Una experiencia de usuario inmersiva, flexible y optimizada para el enfoque creativo sin distracciones.*

1. **Modo Estudio Minimalista (Distraction-Free)**: Alternar con un toque (Tab) a una interfaz ultra-limpia donde las herramientas se ocultan y solo aparecen menús radiales o paletas flotantes al pulsar atajos.
2. **Paneles Acoplables y Flotantes (Docking System)**: Capacidad total de arrastrar, soltar, apilar e integrar paneles a los lados izquierdo/derecho del lienzo para adaptar el espacio de trabajo.
3. **Ventana de Referencia Dinámica (Sub-view)**: Un panel flotante e independiente donde los artistas pueden cargar imágenes de referencia, extraer su paleta de colores y hacer zoom/pan sin alterar el lienzo activo.
4. **Ventana de Vista Previa (Navigator)**: Miniatura interactiva de todo el lienzo en tiempo real que permite orientarse y navegar rápidamente por composiciones gigantescas.
5. **Diseños de Interfaz Predefinidos**: Guardado y carga rápida de configuraciones completas de pantallas, como: *"Modo Ilustración", "Modo Entintado Cómic", "Modo Animación" y "Modo Pintura Clásica"*.

---

## ⚙️ 5. Menú de Preferencias y Configuración Avanzada (Preferences)
*Un panel de control global que permite a los profesionales adaptar el comportamiento de la aplicación a su hardware.*

1. **Ajustes de Entrada de Lápiz y Tableta (Tablet API Selector)**:
   * Alternar entre **Windows Ink** y **WinTab** para asegurar compatibilidad perfecta de la sensibilidad a la presión y el ángulo de inclinación en todas las marcas del mercado (Wacom, Huion, XP-Pen).
2. **Asignación de Atajos de Teclado (Shortcuts Customizer)**:
   * Mapeo visual y completo de todas las acciones del teclado, botones de la tableta y controladores externos (como TourBox o diales).
3. **Gestión de Rendimiento y Memoria (Performance Settings)**:
   * Selector del límite de uso de memoria RAM asignado a la app para buffers de deshacer (Undo history limits).
   * Ruta asignada al **Disco de Memoria Virtual (Scratch Disk)** para evitar cuellos de botella en lienzos colosales.
4. **Configuración de Autoguardado e Intervalos**:
   * Control de frecuencia del autoguardado dinámico ante crashes y límite de espacio consumido por copias de seguridad.
5. **Personalización del Espacio Visual (Themes & Scaling)**:
   * Selector de temas (Dark Mode, Slate Gray, Light Mode), colores de acento y escala de la interfaz de usuario en tiempo real (UI Scaling) para compatibilidad con pantallas 4K.

---

## ⚙️ 6. Opciones Core (Core Options)
*Para dar control absoluto al artista profesional durante el trazo.*

1. **Estabilización Inteligente (Smoothing) (¡COMPLETADO!)**: Algoritmos de "cuerda elástica" y media móvil para líneas fluidas y perfectas.
2. **Máscaras de Recorte (Clipping Masks)**: Capacidad de anclar una capa al contorno de la capa inferior.
3. **Gestión de Paletas .ASE y .CLR**: Importación y exportación de paletas de color estándar del software de diseño.
4. **Historial de Color Dinámico**: Lista flotante o panel que almacena de forma activa los últimos colores seleccionados.
5. **Modos de Fusión Adicionales**: Implementar modos premium de iluminación como "Glow Dodge", "Hard Mix" y "Divide".
6. **Curvas de Presión por Pincel**: Sensibilidad a la presión e inclinación ajustable por cada herramienta individualmente.

---

## 🚀 7. Rendimiento Core (Performance & Engine)
*El núcleo tecnológico robusto y seguro.*

1. **Aceleración por GPU Completa (Vulkan / DirectX)**: Migración a pipelines modernos de renderizado para 0 latencia en lienzos masivos.
2. **Timelapse de Alta Resolución**: Grabación de deltas del lienzo en segundo plano con exportación a MP4 4K y formatos verticales.
3. **Gestos Multitáctiles Fluent**: Rotación y zoom con gestos fluidos e interactivos de dos dedos sin generar falsos trazos.
4. **Autoguardado contra Caídas (¡COMPLETADO!)**: Recuperación y detección de sesiones no guardadas tras interrupciones.
5. **Exportador PSD Multicapa Nativo (¡COMPLETADO!)**: Exportación binaria directa con capas, nombres, opacidad y modos de fusión.

---
*Este plan de competitividad y mejoras actualizadas constituye la base conceptual estratégica para las siguientes iteraciones tecnológicas de Kromo Studio Pro.*
