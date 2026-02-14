#ifndef BRUSHSTROKE_H
#define BRUSHSTROKE_H

#include <vector>
#include <cmath>
#include <SFML/Graphics.hpp>

// Estructura para un punto con presión
struct Point {
    float x;
    float y;
    float pressure; // 0.0 a 1.0
    
    Point(float x = 0, float y = 0, float p = 0.5f) 
        : x(x), y(y), pressure(p) {}
};

// Tipos de pincel
enum class BrushType {
    TAPERED,      // Punta fina -> grueso -> punta fina
    PRESSURE,     // Basado en presión/velocidad
    CALLIGRAPHY,  // Varía según ángulo
    MARKER        // Grosor casi constante
};

// Clase para un trazo completo
class BrushStroke {
private:
    std::vector<Point> points;
    BrushType brushType;
    sf::Color color;
    float brushSize;
    float smoothing;
    
    // Métodos privados para cálculos
    std::vector<Point> smoothPoints(const std::vector<Point>& pts, float smooth);
    float getTaperedThickness(float progress, float maxWidth);
    void drawSegment(sf::RenderWindow& window, const Point& p1, const Point& p2, float thickness);
    
public:
    BrushStroke(const std::vector<Point>& pts, BrushType type, 
                sf::Color col, float size = 20.0f, float smooth = 0.3f);
    
    void draw(sf::RenderWindow& window);
    void drawTaperedStroke(sf::RenderWindow& window);
    void drawPressureStroke(sf::RenderWindow& window);
    void drawCalligraphyStroke(sf::RenderWindow& window);
    void drawMarkerStroke(sf::RenderWindow& window);
};

// Clase principal de la aplicación de dibujo
class DrawingApp {
private:
    sf::RenderWindow& window;
    sf::RenderTexture canvas;
    
    bool isDrawing;
    std::vector<Point> currentPoints;
    std::vector<BrushStroke> strokes;
    
    BrushType currentBrush;
    sf::Color currentColor;
    float brushSize;
    float smoothing;
    
    sf::Vector2f lastMousePos;
    sf::Clock velocityClock;
    
public:
    DrawingApp(sf::RenderWindow& win, unsigned int width, unsigned int height);
    
    void handleMousePressed(const sf::Event& event);
    void handleMouseMoved(const sf::Event& event);
    void handleMouseReleased(const sf::Event& event);
    
    void setBrushType(BrushType type);
    void setColor(sf::Color color);
    void setBrushSize(float size);
    void setSmoothing(float smooth);
    
    void undo();
    void clear();
    void redraw();
    void display();
    
    float calculatePressure(const sf::Vector2f& currentPos);
};

#endif // BRUSHSTROKE_H
