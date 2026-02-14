# 🎨 App de Dibujo C++ - Pinceles con Grosor Variable

## 📋 Problema Original

Tu app mostraba **el mismo trazo para todos los pinceles** porque usabas líneas simples con grosor constante. Esto no permite diferencias visuales entre tipos de pincel.

## ✅ Solución en C++ con SFML

Esta implementación resuelve el problema dibujando **polígonos en lugar de líneas**, permitiendo grosor variable a lo largo del trazo.

### 🎯 4 Tipos de Pincel Implementados

| Pincel | Descripción | Efecto Visual |
|--------|-------------|---------------|
| **TAPERED** | Punta fina → medio grueso → punta fina | Ideal para firma, lettering |
| **PRESSURE** | Varía según velocidad del mouse | Rápido=fino, Lento=grueso |
| **CALLIGRAPHY** | Grosor cambia según ángulo del trazo | Horizontal=grueso, Vertical=fino |
| **MARKER** | Grosor casi constante con textura | Subrayado, notas |

## 🔧 Estructura del Proyecto

```
tu-proyecto/
├── BrushStroke.h       # Header con clases principales
├── BrushStroke.cpp     # Implementación de los pinceles
├── main.cpp            # Programa principal
├── Makefile            # Para compilar fácilmente
└── README.md           # Esta documentación
```

## 🚀 Instalación y Compilación

### Requisitos

- **g++** con soporte C++17
- **SFML 2.5+** (Simple and Fast Multimedia Library)

### Instalar SFML

```bash
# Ubuntu/Debian
sudo apt-get install libsfml-dev

# Fedora
sudo dnf install SFML-devel

# Arch Linux
sudo pacman -S sfml

# macOS
brew install sfml

# Windows
# Descargar desde https://www.sfml-dev.org/download.php
```

### Compilar

```bash
# Opción 1: Usar Makefile (recomendado)
make
./dibujo_app

# Opción 2: Compilación manual
g++ -std=c++17 main.cpp BrushStroke.cpp -o dibujo_app -lsfml-graphics -lsfml-window -lsfml-system
./dibujo_app
```

## 🎮 Controles

| Tecla | Acción |
|-------|--------|
| **Click Izquierdo** | Dibujar |
| **1** | Pincel Afilado |
| **2** | Pincel Presión |
| **3** | Pincel Caligrafía |
| **4** | Pincel Marcador |
| **+** | Aumentar grosor |
| **-** | Reducir grosor |
| **R** | Color Rojo |
| **G** | Color Verde |
| **B** | Color Azul |
| **K** | Color Negro (blacK) |
| **Z** | Deshacer último trazo |
| **C** | Limpiar todo |
| **ESC** | Salir |

## 💡 Cómo Funciona

### El Secreto: Dibujar Polígonos

En lugar de:
```cpp
// ❌ MAL: Línea con grosor constante
sf::Vertex line[] = {
    sf::Vertex(sf::Vector2f(x1, y1)),
    sf::Vertex(sf::Vector2f(x2, y2))
};
window.draw(line, 2, sf::Lines);
```

Ahora usamos:
```cpp
// ✅ BIEN: Cuadrilátero con grosor variable
sf::ConvexShape quad(4);
quad.setPoint(0, esquina1);
quad.setPoint(1, esquina2);
quad.setPoint(2, esquina3);
quad.setPoint(3, esquina4);
window.draw(quad);
```

### Cálculo de Grosor Variable

#### 1️⃣ Pincel Afilado (Tapered)

Usa una **parábola invertida** para hacer las puntas finas:

```cpp
float getTaperedThickness(float progress, float maxWidth) {
    float normalized = (progress - 0.5f) * 2.0f;  // -1 a 1
    float taper = 1.0f - (normalized * normalized); // Parábola
    float minWidth = maxWidth * 0.2f;
    return minWidth + (maxWidth - minWidth) * taper;
}
```

Gráfica del grosor:
```
Grosor
  │     ╱‾‾╲
  │    ╱    ╲
  │___╱______╲___
  └──────────────► Progreso
  0%    50%   100%
```

#### 2️⃣ Pincel de Presión

Simula presión usando la **velocidad del mouse**:

```cpp
float calculatePressure(const sf::Vector2f& currentPos) {
    float distance = sqrt(dx*dx + dy*dy);
    float velocity = distance / elapsed_time;
    
    // Velocidad alta = presión baja (fino)
    // Velocidad baja = presión alta (grueso)
    return max(0.2f, min(1.0f, 1.0f - velocity/2000.0f));
}
```

#### 3️⃣ Pincel de Caligrafía

El grosor varía según el **ángulo del trazo**:

```cpp
float angle = atan2(dy, dx);
float angleVariation = abs(sin(angle * 2.0f));
float thickness = brushSize * (0.3f + angleVariation * 0.7f);
```

### Suavizado de Trazos

Los puntos se promedian con sus vecinos:

```cpp
smoothPoint.x = curr.x * (1-smooth) + (prev.x + next.x) * 0.5 * smooth;
smoothPoint.y = curr.y * (1-smooth) + (prev.y + next.y) * 0.5 * smooth;
```

## 🔗 Integración en Tu Proyecto

### Opción 1: Reemplazar tu código existente

1. Copia `BrushStroke.h` y `BrushStroke.cpp` a tu proyecto
2. Incluye el header:
   ```cpp
   #include "BrushStroke.h"
   ```
3. Crea la app:
   ```cpp
   DrawingApp app(window, 1200, 800);
   ```
4. Maneja eventos:
   ```cpp
   app.handleMousePressed(event);
   app.handleMouseMoved(event);
   app.handleMouseReleased(event);
   ```

### Opción 2: Adaptar solo la clase BrushStroke

Si ya tienes un sistema de dibujo:

```cpp
#include "BrushStroke.h"

// En tu bucle de dibujo:
std::vector<Point> points;

// Al hacer click y mover el mouse:
points.push_back(Point(mouseX, mouseY, 0.5f));

// Al soltar el mouse:
BrushStroke stroke(points, BrushType::TAPERED, sf::Color::Black, 20.0f, 0.3f);
stroke.draw(window);
```

## 📊 Diferencias Visuales

### Antes (❌)
```
Todos los pinceles:  ═══════════════
```

### Ahora (✅)
```
Afilado:     ╱‾‾‾‾‾‾‾‾‾╲
Presión:     ══╱‾‾‾╲════
Caligrafía:  ╱╲╱╲╱╲╱╲╱╲
Marcador:    ═══════════
```

## 🐛 Solución de Problemas

### Problema: "SFML no encontrado al compilar"

```bash
# Verifica que SFML esté instalado
pkg-config --modversion sfml-all

# Si no está instalado, instálalo según tu sistema
```

### Problema: Los trazos se ven pixelados

Aumenta el suavizado en el código:
```cpp
app.setSmoothing(0.5f); // Valores de 0.0 a 1.0
```

### Problema: Los trazos son muy lentos

Reduce el número de puntos o simplifica el suavizado:
```cpp
// En handleMouseMoved, solo agrega puntos cada cierta distancia
float dist = sqrt(dx*dx + dy*dy);
if (dist > 3.0f) { // Solo agrega si se movió más de 3 píxeles
    currentPoints.push_back(point);
}
```

### Problema: Las puntas no se ven finas

Ajusta el porcentaje mínimo en `getTaperedThickness`:
```cpp
float minWidth = maxWidth * 0.1f; // Cambia de 0.2 a 0.1 para puntas más finas
```

## 🎯 Conceptos Clave

1. **NO uses líneas simples** → Dibuja polígonos
2. **Guarda arrays de puntos** → No solo inicio y fin
3. **Calcula grosor por segmento** → Permite variación
4. **Suaviza los puntos** → Trazos más naturales
5. **Usa círculos en las uniones** → Evita esquinas

## 📚 Clases Principales

### `Point`
```cpp
struct Point {
    float x, y;
    float pressure; // 0.0 a 1.0
};
```

### `BrushStroke`
```cpp
class BrushStroke {
    void draw(sf::RenderWindow& window);
    void drawTaperedStroke(...);
    void drawPressureStroke(...);
    // ...
};
```

### `DrawingApp`
```cpp
class DrawingApp {
    void handleMousePressed(...);
    void setBrushType(BrushType type);
    void setColor(sf::Color color);
    void undo();
    void clear();
    // ...
};
```

## 🚀 Mejoras Futuras

- [ ] Selector de color con UI
- [ ] Barra de herramientas visual
- [ ] Goma de borrar
- [ ] Sistema de capas
- [ ] Guardar/cargar imágenes (PNG, JPG)
- [ ] Deshacer/Rehacer múltiple
- [ ] Zoom y pan
- [ ] Texturas de pincel

## 📄 Licencia

Código libre para usar en tu proyecto.

---

**¡Ahora tienes pinceles con grosor variable real en C++!** 🎨✨

Cada tipo de pincel muestra diferencias visuales claras y naturales.
