#include "BrushStroke.h"
#include <algorithm>

// ============================================
// IMPLEMENTACIÓN DE BrushStroke
// ============================================

BrushStroke::BrushStroke(const std::vector<Point>& pts, BrushType type, 
                         sf::Color col, float size, float smooth)
    : points(pts), brushType(type), color(col), brushSize(size), smoothing(smooth) {}

void BrushStroke::draw(sf::RenderWindow& window) {
    if (points.size() < 2) return;
    
    switch(brushType) {
        case BrushType::TAPERED:
            drawTaperedStroke(window);
            break;
        case BrushType::PRESSURE:
            drawPressureStroke(window);
            break;
        case BrushType::CALLIGRAPHY:
            drawCalligraphyStroke(window);
            break;
        case BrushType::MARKER:
            drawMarkerStroke(window);
            break;
    }
}

// Trazo con puntas finas y medio grueso
void BrushStroke::drawTaperedStroke(sf::RenderWindow& window) {
    std::vector<Point> smoothed = smoothPoints(points, smoothing);
    
    for (size_t i = 0; i < smoothed.size() - 1; i++) {
        float progress = static_cast<float>(i) / (smoothed.size() - 1);
        float thickness = getTaperedThickness(progress, brushSize);
        drawSegment(window, smoothed[i], smoothed[i + 1], thickness);
    }
}

// Trazo basado en presión
void BrushStroke::drawPressureStroke(sf::RenderWindow& window) {
    std::vector<Point> smoothed = smoothPoints(points, smoothing);
    
    for (size_t i = 0; i < smoothed.size() - 1; i++) {
        float pressure = smoothed[i].pressure;
        float thickness = brushSize * 1.2f * pressure;
        drawSegment(window, smoothed[i], smoothed[i + 1], thickness);
    }
}

// Trazo de caligrafía (grosor según ángulo)
void BrushStroke::drawCalligraphyStroke(sf::RenderWindow& window) {
    std::vector<Point> smoothed = smoothPoints(points, smoothing);
    
    for (size_t i = 0; i < smoothed.size() - 1; i++) {
        float dx = smoothed[i + 1].x - smoothed[i].x;
        float dy = smoothed[i + 1].y - smoothed[i].y;
        float angle = std::atan2(dy, dx);
        
        // Varía el grosor según el ángulo
        float angleVariation = std::abs(std::sin(angle * 2.0f));
        float thickness = brushSize * 0.9f * (0.3f + angleVariation * 0.7f);
        
        drawSegment(window, smoothed[i], smoothed[i + 1], thickness);
    }
}

// Trazo de marcador (grosor constante con pequeña variación)
void BrushStroke::drawMarkerStroke(sf::RenderWindow& window) {
    std::vector<Point> smoothed = smoothPoints(points, smoothing);
    
    for (size_t i = 0; i < smoothed.size() - 1; i++) {
        // Pequeña variación aleatoria
        float variation = 0.9f + (static_cast<float>(rand()) / RAND_MAX) * 0.2f;
        float thickness = brushSize * 0.85f * variation;
        
        drawSegment(window, smoothed[i], smoothed[i + 1], thickness);
    }
}

// Dibuja un segmento individual con grosor específico
void BrushStroke::drawSegment(sf::RenderWindow& window, const Point& p1, const Point& p2, float thickness) {
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    float angle = std::atan2(dy, dx);
    
    // Ángulo perpendicular para el grosor
    float perpAngle = angle + M_PI / 2.0f;
    float halfThickness = thickness / 2.0f;
    
    // Cuatro esquinas del cuadrilátero
    sf::ConvexShape quad(4);
    quad.setFillColor(color);
    
    quad.setPoint(0, sf::Vector2f(
        p1.x + std::cos(perpAngle) * halfThickness,
        p1.y + std::sin(perpAngle) * halfThickness
    ));
    quad.setPoint(1, sf::Vector2f(
        p1.x - std::cos(perpAngle) * halfThickness,
        p1.y - std::sin(perpAngle) * halfThickness
    ));
    quad.setPoint(2, sf::Vector2f(
        p2.x - std::cos(perpAngle) * halfThickness,
        p2.y - std::sin(perpAngle) * halfThickness
    ));
    quad.setPoint(3, sf::Vector2f(
        p2.x + std::cos(perpAngle) * halfThickness,
        p2.y + std::sin(perpAngle) * halfThickness
    ));
    
    window.draw(quad);
    
    // Círculos en los extremos para suavizar las uniones
    sf::CircleShape circle1(halfThickness);
    circle1.setFillColor(color);
    circle1.setPosition(p1.x - halfThickness, p1.y - halfThickness);
    window.draw(circle1);
    
    sf::CircleShape circle2(halfThickness);
    circle2.setFillColor(color);
    circle2.setPosition(p2.x - halfThickness, p2.y - halfThickness);
    window.draw(circle2);
}

// Función de grosor afilado (parábola invertida)
float BrushStroke::getTaperedThickness(float progress, float maxWidth) {
    // Normaliza de 0-1 a -1 a 1
    float normalized = (progress - 0.5f) * 2.0f;
    
    // Parábola invertida: 1 - x²
    float taper = 1.0f - (normalized * normalized);
    
    float minWidth = maxWidth * 0.2f; // 20% en las puntas
    return minWidth + (maxWidth - minWidth) * taper;
}

// Suaviza los puntos usando interpolación
std::vector<Point> BrushStroke::smoothPoints(const std::vector<Point>& pts, float smooth) {
    if (pts.size() < 3) return pts;
    
    std::vector<Point> smoothed;
    smoothed.push_back(pts[0]); // Primer punto sin cambios
    
    for (size_t i = 1; i < pts.size() - 1; i++) {
        const Point& prev = pts[i - 1];
        const Point& curr = pts[i];
        const Point& next = pts[i + 1];
        
        Point smoothPoint;
        smoothPoint.x = curr.x * (1.0f - smooth) + (prev.x + next.x) * 0.5f * smooth;
        smoothPoint.y = curr.y * (1.0f - smooth) + (prev.y + next.y) * 0.5f * smooth;
        smoothPoint.pressure = curr.pressure;
        
        smoothed.push_back(smoothPoint);
    }
    
    smoothed.push_back(pts[pts.size() - 1]); // Último punto sin cambios
    return smoothed;
}

// ============================================
// IMPLEMENTACIÓN DE DrawingApp
// ============================================

DrawingApp::DrawingApp(sf::RenderWindow& win, unsigned int width, unsigned int height)
    : window(win), isDrawing(false), currentBrush(BrushType::TAPERED),
      currentColor(sf::Color::Black), brushSize(20.0f), smoothing(0.3f) {
    
    canvas.create(width, height);
    canvas.clear(sf::Color::White);
}

void DrawingApp::handleMousePressed(const sf::Event& event) {
    if (event.mouseButton.button == sf::Mouse::Left) {
        isDrawing = true;
        currentPoints.clear();
        
        Point p(static_cast<float>(event.mouseButton.x), 
                static_cast<float>(event.mouseButton.y), 
                0.5f);
        currentPoints.push_back(p);
        
        lastMousePos = sf::Vector2f(event.mouseButton.x, event.mouseButton.y);
        velocityClock.restart();
    }
}

void DrawingApp::handleMouseMoved(const sf::Event& event) {
    if (!isDrawing) return;
    
    sf::Vector2f currentPos(event.mouseMove.x, event.mouseMove.y);
    float pressure = calculatePressure(currentPos);
    
    Point p(currentPos.x, currentPos.y, pressure);
    currentPoints.push_back(p);
    
    lastMousePos = currentPos;
    
    // Redibujar en tiempo real
    redraw();
}

void DrawingApp::handleMouseReleased(const sf::Event& event) {
    if (!isDrawing) return;
    
    isDrawing = false;
    
    if (currentPoints.size() > 1) {
        BrushStroke stroke(currentPoints, currentBrush, currentColor, brushSize, smoothing);
        strokes.push_back(stroke);
        
        // Dibujar el trazo final en el canvas permanente
        stroke.draw(canvas);
    }
    
    currentPoints.clear();
    redraw();
}

// Calcula "presión" basada en velocidad del mouse
float DrawingApp::calculatePressure(const sf::Vector2f& currentPos) {
    float elapsed = velocityClock.restart().asSeconds();
    
    if (elapsed < 0.001f) elapsed = 0.001f; // Evitar división por 0
    
    float dx = currentPos.x - lastMousePos.x;
    float dy = currentPos.y - lastMousePos.y;
    float distance = std::sqrt(dx * dx + dy * dy);
    
    // Velocidad en píxeles/segundo
    float velocity = distance / elapsed;
    
    // Normalizar velocidad a presión (0.0 - 1.0)
    // Velocidad alta = presión baja (trazo fino)
    // Velocidad baja = presión alta (trazo grueso)
    float pressure = std::max(0.2f, std::min(1.0f, 1.0f - (velocity / 2000.0f)));
    
    return pressure;
}

void DrawingApp::setBrushType(BrushType type) {
    currentBrush = type;
}

void DrawingApp::setColor(sf::Color color) {
    currentColor = color;
}

void DrawingApp::setBrushSize(float size) {
    brushSize = size;
}

void DrawingApp::setSmoothing(float smooth) {
    smoothing = smooth;
}

void DrawingApp::undo() {
    if (!strokes.empty()) {
        strokes.pop_back();
        
        // Redibujar todo el canvas desde cero
        canvas.clear(sf::Color::White);
        for (auto& stroke : strokes) {
            stroke.draw(canvas);
        }
        redraw();
    }
}

void DrawingApp::clear() {
    strokes.clear();
    canvas.clear(sf::Color::White);
    redraw();
}

void DrawingApp::redraw() {
    window.clear(sf::Color::White);
    
    // Dibujar el canvas permanente
    sf::Sprite canvasSprite(canvas.getTexture());
    window.draw(canvasSprite);
    
    // Dibujar el trazo actual (temporal)
    if (isDrawing && currentPoints.size() > 1) {
        BrushStroke tempStroke(currentPoints, currentBrush, currentColor, brushSize, smoothing);
        tempStroke.draw(window);
    }
    
    window.display();
}

void DrawingApp::display() {
    window.clear(sf::Color::White);
    sf::Sprite canvasSprite(canvas.getTexture());
    window.draw(canvasSprite);
    window.display();
}
