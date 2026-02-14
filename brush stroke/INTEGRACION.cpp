// ============================================
// GUÍA DE INTEGRACIÓN RÁPIDA
// ============================================
// Cómo agregar pinceles variables a tu proyecto existente

// ============================================
// OPCIÓN 1: SI YA TIENES UN PROYECTO CON SFML
// ============================================

#include "BrushStroke.h"

class TuProyectoExistente {
private:
    sf::RenderWindow window;
    DrawingApp* drawingApp; // Agrega esto
    
public:
    TuProyectoExistente() {
        // Tu código existente...
        
        // Agrega la app de dibujo
        drawingApp = new DrawingApp(window, 1200, 800);
        drawingApp->setBrushType(BrushType::TAPERED);
        drawingApp->setColor(sf::Color::Black);
    }
    
    void handleEvents() {
        sf::Event event;
        while (window.pollEvent(event)) {
            // Tu código existente...
            
            // Agrega manejo de dibujo
            if (event.type == sf::Event::MouseButtonPressed) {
                drawingApp->handleMousePressed(event);
            }
            else if (event.type == sf::Event::MouseMoved) {
                drawingApp->handleMouseMoved(event);
            }
            else if (event.type == sf::Event::MouseButtonReleased) {
                drawingApp->handleMouseReleased(event);
            }
        }
    }
    
    void render() {
        window.clear();
        
        // Tu código de renderizado existente...
        
        // Renderiza el canvas de dibujo
        drawingApp->display();
        
        window.display();
    }
};

// ============================================
// OPCIÓN 2: SI SOLO QUIERES LA CLASE BrushStroke
// ============================================

class TuSistemaDeDibujo {
private:
    std::vector<Point> currentPoints;
    std::vector<BrushStroke> strokes;
    BrushType currentBrush = BrushType::TAPERED;
    
public:
    void onMouseDown(float x, float y) {
        currentPoints.clear();
        currentPoints.push_back(Point(x, y, 0.5f));
    }
    
    void onMouseMove(float x, float y) {
        if (currentPoints.empty()) return;
        
        // Calcula presión basada en velocidad (opcional)
        float pressure = 0.5f; // O usa tu propia lógica
        currentPoints.push_back(Point(x, y, pressure));
    }
    
    void onMouseUp(sf::RenderWindow& window) {
        if (currentPoints.size() < 2) return;
        
        // Crea el trazo con el pincel actual
        BrushStroke stroke(
            currentPoints,
            currentBrush,
            sf::Color::Black,
            20.0f,  // grosor
            0.3f    // suavizado
        );
        
        strokes.push_back(stroke);
        currentPoints.clear();
    }
    
    void render(sf::RenderWindow& window) {
        // Dibuja todos los trazos guardados
        for (auto& stroke : strokes) {
            stroke.draw(window);
        }
        
        // Dibuja trazo actual (temporal)
        if (currentPoints.size() > 1) {
            BrushStroke temp(currentPoints, currentBrush, 
                           sf::Color::Black, 20.0f, 0.3f);
            temp.draw(window);
        }
    }
};

// ============================================
// OPCIÓN 3: MIGRACIÓN DESDE TU CÓDIGO ACTUAL
// ============================================

// ANTES (tu código actual, probablemente algo así):
void tuFuncionDeDibujo() {
    sf::Vertex line[] = {
        sf::Vertex(sf::Vector2f(x1, y1)),
        sf::Vertex(sf::Vector2f(x2, y2))
    };
    window.draw(line, 2, sf::Lines);
}

// DESPUÉS (reemplazar con):
void tuFuncionDeDibujoMejorada() {
    // Acumula puntos en lugar de dibujar líneas directamente
    std::vector<Point> points;
    points.push_back(Point(x1, y1, 0.5f));
    points.push_back(Point(x2, y2, 0.5f));
    // ... más puntos según el usuario dibuje
    
    // Al finalizar el trazo:
    BrushStroke stroke(points, BrushType::TAPERED, 
                      sf::Color::Black, 20.0f, 0.3f);
    stroke.draw(window);
}

// ============================================
// CONSEJOS DE INTEGRACIÓN
// ============================================

// 1. PERFORMANCE: Si tienes muchos trazos
void optimizarTrazos() {
    // Opción A: Dibuja los trazos en una RenderTexture
    sf::RenderTexture canvas;
    canvas.create(1200, 800);
    
    // Dibuja una sola vez todos los trazos antiguos
    for (auto& stroke : strokes) {
        stroke.draw(canvas);
    }
    
    // En el loop solo dibuja el canvas + trazo actual
    sf::Sprite sprite(canvas.getTexture());
    window.draw(sprite);
    
    // Opción B: Reduce puntos en trazos largos
    if (currentPoints.size() > 100) {
        // Elimina puntos intermedios (cada 2 puntos, por ejemplo)
        std::vector<Point> simplified;
        for (size_t i = 0; i < currentPoints.size(); i += 2) {
            simplified.push_back(currentPoints[i]);
        }
        currentPoints = simplified;
    }
}

// 2. MEMORIA: Limita el número de trazos
void limpiarTrazosViejos() {
    const size_t MAX_STROKES = 1000;
    if (strokes.size() > MAX_STROKES) {
        // Elimina los primeros (más viejos)
        strokes.erase(strokes.begin(), 
                     strokes.begin() + (strokes.size() - MAX_STROKES));
    }
}

// 3. COLISIÓN DE EVENTOS: Si tienes otros sistemas
void manejarEventosConPrioridad(sf::Event& event) {
    // Checa primero si el evento es para otros sistemas
    if (estaEnMenuUI(event)) {
        manejarMenuUI(event);
        return; // No pases el evento al sistema de dibujo
    }
    
    // Si no fue capturado por otro sistema, pásalo al dibujo
    if (modoDeEdicion == MODO_DIBUJO) {
        drawingApp->handleMousePressed(event);
    }
}

// 4. SERIALIZACIÓN: Guardar trazos
void guardarTrazos(const std::string& filename) {
    std::ofstream file(filename, std::ios::binary);
    
    size_t count = strokes.size();
    file.write(reinterpret_cast<char*>(&count), sizeof(count));
    
    for (auto& stroke : strokes) {
        // Guarda tipo de pincel, color, puntos, etc.
        // ... implementa según tus necesidades
    }
}

// ============================================
// EJEMPLOS DE USO COMÚN
// ============================================

// Cambiar pincel con botones de UI
void onButtonClicked(int buttonID) {
    switch(buttonID) {
        case BTN_BRUSH_TAPERED:
            app->setBrushType(BrushType::TAPERED);
            break;
        case BTN_BRUSH_PRESSURE:
            app->setBrushType(BrushType::PRESSURE);
            break;
        case BTN_BRUSH_CALLIGRAPHY:
            app->setBrushType(BrushType::CALLIGRAPHY);
            break;
        case BTN_BRUSH_MARKER:
            app->setBrushType(BrushType::MARKER);
            break;
    }
}

// Slider para grosor del pincel
void onSliderChanged(float value) {
    // value entre 0.0 y 1.0
    float brushSize = 5.0f + value * 45.0f; // 5 a 50 pixels
    app->setBrushSize(brushSize);
}

// Color picker
void onColorSelected(sf::Color color) {
    app->setColor(color);
}

// ============================================
// PREGUNTAS FRECUENTES
// ============================================

/*
Q: ¿Cómo agrego soporte para tabletas con presión real?
A: Usa SFML + la extensión de Windows Ink o Linux Wacom:
   
   float realPressure = event.touch.pressure; // 0.0 a 1.0
   currentPoints.push_back(Point(x, y, realPressure));

Q: ¿Cómo hago que el canvas sea más grande que la ventana?
A: Usa sf::View para hacer zoom/pan:
   
   sf::View view(sf::FloatRect(0, 0, 2400, 1600)); // Canvas 2x más grande
   window.setView(view);

Q: ¿Puedo cambiar el algoritmo de suavizado?
A: Sí, modifica smoothPoints() en BrushStroke.cpp
   Prueba con Catmull-Rom o Bezier para más control

Q: ¿Cómo exporto el dibujo a PNG?
A: 
   sf::Texture texture;
   texture.create(window.getSize().x, window.getSize().y);
   texture.update(window);
   texture.copyToImage().saveToFile("dibujo.png");
*/

// ============================================
// CHECKLIST DE INTEGRACIÓN
// ============================================

/*
[ ] 1. Copiar BrushStroke.h y BrushStroke.cpp a tu proyecto
[ ] 2. Agregar -lsfml-graphics -lsfml-window -lsfml-system al linker
[ ] 3. Incluir #include "BrushStroke.h" donde lo necesites
[ ] 4. Crear instancia de DrawingApp o usar BrushStroke directamente
[ ] 5. Conectar eventos de mouse (pressed, moved, released)
[ ] 6. Agregar controles de UI para cambiar pincel/color/grosor
[ ] 7. Implementar undo/clear si los necesitas
[ ] 8. Optimizar performance si tienes muchos trazos
[ ] 9. Probar con diferentes pinceles para ver las diferencias
[ ] 10. ¡Disfrutar de trazos con grosor variable real! 🎨
*/
