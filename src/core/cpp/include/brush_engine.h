#ifndef BRUSH_ENGINE_H
#define BRUSH_ENGINE_H

#include <QColor>
#include <QPainter>
#include <QPen>
#include <QPointF>
#include <QRadialGradient>
#include <cmath>
#include <cstdint>
#include <vector>

namespace artflow {

// Legacy Color struct for compatibility
struct Color {
  uint8_t r, g, b, a;
  Color() : r(0), g(0), b(0), a(255) {}
  Color(uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255)
      : r(r), g(g), b(b), a(a) {}
};

// Legacy StrokePoint struct for compatibility
struct StrokePoint {
  float x, y;
  float pressure;
  float tiltX, tiltY;
  uint64_t timestamp;
  StrokePoint()
      : x(0), y(0), pressure(1.0f), tiltX(0), tiltY(0), timestamp(0) {}
  StrokePoint(float x, float y, float pressure = 1.0f)
      : x(x), y(y), pressure(pressure), tiltX(0), tiltY(0), timestamp(0) {}
};

struct BrushSettings {
  // New fields
  float size = 10.0f;
  float opacity = 1.0f;
  float hardness = 1.0f; // 1.0 = duro, 0.0 = suave
  float spacing = 0.1f;  // Espaciado del trazo
  QColor color = Qt::black;
  bool dynamicsEnabled = true; // Activar/desactivar presión

  // Compatibility fields
  enum class Type {
    Round,
    Pencil,
    Airbrush,
    Ink,
    Watercolor,
    Oil,
    Acrylic,
    Eraser,
    Custom
  } type = Type::Round;
  float flow = 1.0f;
  float stabilization = 0.0f;
  float streamline = 0.0f;
  float grain = 0.0f;
  float wetness = 0.0f;
  float smudge = 0.0f;
  float jitter = 0.0f;
  bool sizeByPressure = true;
  bool opacityByPressure = true;
  float velocityDynamics = 0.0f;
};

class BrushEngine {
public:
  BrushEngine();

  // Función principal de dibujo adaptada (QPainter based)
  void paintStroke(QPainter *painter, const QPointF &lastPoint,
                   const QPointF &currentPoint, float pressure,
                   const BrushSettings &settings);

  // Compatibility methods for CanvasItem integration
  void setBrush(const BrushSettings &settings) { m_currentSettings = settings; }
  BrushSettings getBrush() const { return m_currentSettings; }
  void setColor(const Color &color) {
    m_currentSettings.color = QColor(color.r, color.g, color.b, color.a);
  }

  // Compatibility methods (Empty or mapped)
  void beginStroke(const StrokePoint &point) { /* Handled in paintStroke now */
  }
  void endStroke() { /* Handled in paintStroke now */ }

  // Helper to map legacy calls to new engine if needed,
  // but we will update CanvasItem to call paintStroke directly.
  // However, keeping these to avoid linker errors if I miss one call.
  // Ideally CanvasItem should construct QPainter and call paintStroke.

private:
  BrushSettings m_currentSettings;

  // Ayudante para pinceles suaves
  void paintSoftStamp(QPainter *painter, const QPointF &point, float size,
                      float opacity, const QColor &color, float hardness);
};

} // namespace artflow

#endif // BRUSH_ENGINE_H
