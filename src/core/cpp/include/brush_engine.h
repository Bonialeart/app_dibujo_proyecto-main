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

  void blend(const Color &other, float factor) {
    r = static_cast<uint8_t>(r + (other.r - r) * factor);
    g = static_cast<uint8_t>(g + (other.g - g) * factor);
    b = static_cast<uint8_t>(b + (other.b - b) * factor);
    a = static_cast<uint8_t>(a + (other.a - a) * factor);
  }
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
  float size = 10.0f;
  float opacity = 1.0f;
  float hardness = 1.0f; // 1.0 = duro, 0.0 = suave
  float spacing = 0.1f;  // Espaciado del trazo
  QColor color = Qt::black;
  bool dynamicsEnabled = true; // Activar/desactivar presión

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

  // Propiedades Premium
  bool useTexture = false;
  QString textureName = "";      // assets/textures/ (e.g. "paper_grain.png")
  float textureScale = 100.0f;   // Zoom de la textura
  float textureIntensity = 0.5f; // Fuerza (0.0 a 1.0)
  float wetness = 0.0f;          // Pilar 3: Mezcla (0 = seco, 1 = húmedo)
  float dilution = 0.0f;         // Pilar 3: Dilución (Agua)
  float smudge = 0.0f;           // Pilar 1: Arrastre

  // Additional members for bindings
  float rotation = 0.0f;
  bool rotateWithStroke = false;
  uint32_t textureId = 0; // Alias/Same as grainTextureID

  // Cache e Internal
  uint32_t grainTextureID = 0;

  // Legacy / Otros
  float flow = 1.0f;
  float stabilization = 0.0f;
  float streamline = 0.0f;
  bool sizeByPressure = true;
  bool opacityByPressure = true;
  float jitter = 0.0f;
  float grain = 0.5f;            // For legacy compatibility
  float velocityDynamics = 0.0f; // For legacy compatibility
};

class StrokeRenderer; // Forward declaration

class BrushEngine {
public:
  BrushEngine();
  ~BrushEngine(); // Needed for unique_ptr cleanup if used, or raw pointer
                  // delete

  // Función principal de dibujo adaptada (QPainter based)
  void paintStroke(QPainter *painter, const QPointF &lastPoint,
                   const QPointF &currentPoint, float pressure,
                   const BrushSettings &settings, float tilt = 0.0f,
                   float velocity = 0.0f, uint32_t canvasTexId = 0,
                   float wetness = 0.0f, float dilution = 0.0f,
                   float smudge = 0.0f);

  // Compatibility methods for CanvasItem integration
  void setBrush(const BrushSettings &settings); // Implemented in cpp or inline
  BrushSettings getBrush() const { return m_currentSettings; }

  void setColor(const Color &color); // Updated to update cache
  const Color &getColor() const;

  // Stateful stroke management
  void beginStroke(const StrokePoint &point);
  void continueStroke(const StrokePoint &point);
  void endStroke();

  // Direct rendering methods exposed to Python
  void renderDab(float x, float y, float size, float rotation,
                 const Color &color, float hardness, float pressure,
                 int brushType, float wetness);

  void renderStrokeSegment(float x1, float y1, float x2, float y2,
                           float pressure, float tilt, float velocity,
                           bool useTexture);

private:
  BrushSettings m_currentSettings;
  StrokeRenderer *m_renderer = nullptr;

  // State for continueStroke
  QPointF m_lastPos;
  mutable Color
      m_cachedColor; // mutable to allow update in const getter if needed

  // Ayudante para pinceles suaves
  void paintSoftStamp(QPainter *painter, const QPointF &point, float size,
                      float opacity, const QColor &color, float hardness);
};

} // namespace artflow

#endif // BRUSH_ENGINE_H
