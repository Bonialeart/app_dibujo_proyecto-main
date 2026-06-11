#pragma once

#include <QColor>
#include <QPainter>
#include <QPen>
#include <QPointF>
#include <QRadialGradient>
#include <cmath>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include <QString>

class QOpenGLFramebufferObject;

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
  QColor color = QColor(0, 0, 0);
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
  QString textureName = "";      // Grain texture: assets/textures/
  float textureScale = 100.0f;   // Zoom de la textura de grano
  float textureIntensity = 0.5f; // Fuerza del grano (0.0 a 1.0)
  float wetness = 0.0f;          // Pilar 3: Mezcla (0 = seco, 1 = húmedo)
  float dilution = 0.0f;         // Pilar 3: Dilución (Agua)
  float smudge = 0.0f;           // Pilar 1: Arrastre

  // Dual Texture System: Brush Tip (Shape)
  QString tipTextureName = ""; // Tip shape: assets/textures/ or brushes/
  uint32_t tipTextureID = 0;   // OpenGL texture ID for tip

  // Additional members for bindings
  float rotation = 0.0f;
  float tipRotation = 0.0f; // Rotation of the brush tip in radians
  bool rotateWithStroke = false;
  uint32_t textureId = 0; // Alias/Same as grainTextureID

  // Dual Brush Tip Settings
  bool dualTipEnabled = false;
  QString dualTipTextureName = "";
  uint32_t dualTipTextureID = 0;
  float dualTipScale = 1.0f;
  float dualTipRotation = 0.0f;
  QString dualTipBlendMode = "multiply";
  float dualTipFlow = 1.0f;

  // Dual Grain Settings
  bool useDualTexture = false;
  QString dualTextureName = "";
  uint32_t dualGrainTextureID = 0;
  float dualTextureScale = 100.0f;
  float dualTextureIntensity = 0.5f;
  bool invertDualGrain = false;
  int dualGrainBlendMode = 0;
  float dualGrainBright = 0.0f;
  float dualGrainCon = 1.0f;
  float dualGrainRotation = 0.0f;
  bool dualGrainEmphasizeDensity = false;
  bool dualGrainApplyToTips = true;

  // Dual Brush Spray Settings
  bool sprayEnabled = false;
  float particleSize = 50.0f;
  bool spraySizeByBrush = true;
  int particleDensity = 3;
  int sprayDeviation = 3;
  float particleDirection = 0.0f;

  // Main Brush Spray Settings
  bool mainSprayEnabled = false;
  float mainParticleSize = 50.0f;
  bool mainSpraySizeByBrush = true;
  int mainParticleDensity = 3;
  int mainSprayDeviation = 3;
  float mainParticleDirection = 0.0f;

  // === NEW BRUSH STUDIO FIELDS ===
  // Shape
  float roundness = 1.0f;
  bool flipX = false;
  bool flipY = false;
  bool invertShape = false;
  bool randomizeShape = false;
  int count = 1;
  float countJitter = 0.0f;
  float shapeContrast = 1.0f;
  float shapeBlur = 0.0f;

  // Grain
  bool invertGrain = false;
  float grainOverlap = 0.0f;
  float grainBlur = 0.0f;
  float grainMotionBlur = 0.0f;
  float grainMotionBlurAngle = 0.0f;
  bool grainRandomOffset = false;
  QString grainBlendMode = "multiply";
  float grainBright = 0.0f;
  float grainCon = 1.0f;
  float grainRotation = 0.0f;
  bool grainEmphasizeDensity = false;
  bool grainApplyToTips = true;

  // Jitter
  float jitterLateral = 0.0f;
  float jitterLinear = 0.0f;
  float posJitterX = 0.0f;
  float posJitterY = 0.0f;
  float rotationJitter = 0.0f;
  float roundnessJitter = 0.0f;
  float sizeJitter = 0.0f;
  float opacityJitter = 0.0f;

  // Taper
  float taperStart = 0.0f;
  float taperEnd = 0.0f;
  float taperSize = 0.0f;
  float fallOff = 0.0f;
  float distance = 1.0f;

  // Color Dynamics
  float hueJitter = 0.0f;
  float satJitter = 0.0f;
  float lightJitter = 0.0f;
  float darkJitter = 0.0f;
  float strokeHueJitter = 0.0f;
  float strokeSatJitter = 0.0f;
  float strokeLightJitter = 0.0f;
  float strokeDarkJitter = 0.0f;
  float tiltDarkJitter = 0.0f;
  bool useSecondaryColor = false;

  // Wet Mix
  float pressurePigment = 0.0f;
  float pullPressure = 0.0f;
  float wetJitter = 0.0f;

  // === NEW REALISTIC WATERCOLOR FIELDS ===
  // Wet Mix
  float bleed = 0.0f;
  float absorptionRate = 0.0f;
  float dryingTime = 0.0f;
  float wetOnWetMultiplier = 1.0f;
  bool colorMixing = true;
  float paintAmount = 0.7f;
  float colorStretch = 0.1f;
  int blendMode = 0;

  // Oil Paint Wet Mix
  float mixing = 0.5f;
  float loading = 1.0f;
  float depletionRate = 0.0f;
  bool dirtyMixing = false;
  float colorPickup = 0.0f;
  bool blendOnly = false;
  bool scrapeThrough = false;

  // Pigment
  float granulation = 0.0f;
  float pigmentFlow = 1.0f;
  float staining = 0.0f;
  float separation = 0.0f;

  // Oil Color Dynamics
  float temperatureShift = 0.0f;
  float brokenColor = 0.0f;

  // Bloom
  bool bloomEnabled = false;
  float bloomIntensity = 0.0f;
  float bloomRadius = 0.0f;
  float bloomThreshold = 0.0f;

  // Edge Darkening
  bool edgeDarkeningEnabled = false;
  float edgeDarkeningIntensity = 0.0f;
  float edgeDarkeningWidth = 0.0f;

  // Texture Reveal (Dry Brush)
  bool textureRevealEnabled = false;
  float textureRevealIntensity = 0.0f;
  float textureRevealPressureInfluence = 0.0f;

  // === OIL PAINT FIELDS ===
  // Impasto
  bool impastoEnabled = false;
  float impastoDepth = 0.0f;
  float impastoShine = 0.0f;
  float impastoTextureStrength = 0.0f;
  float impastoEdgeBuildup = 0.0f;
  bool impastoDirectionalRidges = false;
  float impastoSmoothing = 0.0f;
  bool impastoPreserveExisting = false;

  // Bristles
  bool bristlesEnabled = false;
  int bristleCount = 1;
  float bristleStiffness = 0.5f;
  float bristleClumping = 0.0f;
  float bristleFanSpread = 0.0f;
  float bristleIndividualVariation = 0.0f;
  bool bristleDryBrushEffect = false;
  float bristleSoftness = 0.0f;
  float bristlePointTaper = 0.0f;

  // Smudge (Advanced)
  float smudgeStrength = 0.0f;
  // Blendmode is tricky in C++, maybe map to int enum or just float flag
  // For now let's skip complex string blendmode in shader uniforms
  float smudgePressureInfluence = 0.0f;
  float smudgeLength = 0.0f;
  float smudgeGaussianBlur = 0.0f;
  bool smudgeSmear = false;

  // Canvas Interaction
  float canvasAbsorption = 0.0f;
  bool canvasSkipValleys = false;
  float canvasCatchPeaks = 0.0f;

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
  float calligraphicInfluence =
      0.0f; // 0.0 = none, 1.0 = full angle-based width

  // === Per-Brush Pressure Response ===
  // Cubic Bezier P1/P2 control points; endpoints fixed at (0,0) and (1,1).
  // Identity (linear) by default so legacy presets behave unchanged.
  float pressureCurveX1 = 0.0f, pressureCurveY1 = 0.0f;
  float pressureCurveX2 = 1.0f, pressureCurveY2 = 1.0f;
  float sizeMinPressure = 0.0f;    // size factor floor at zero pressure
  float opacityMinPressure = 0.0f; // opacity factor floor at zero pressure

  // Evaluate the per-brush pressure curve: y for a given input pressure x.
  float applyPressureCurve(float x) const {
    // Fast path: identity curve
    if (pressureCurveX1 == 0.0f && pressureCurveY1 == 0.0f &&
        pressureCurveX2 == 1.0f && pressureCurveY2 == 1.0f) {
      return x;
    }
    x = std::max(0.0f, std::min(1.0f, x));
    // Newton's method: find t such that bezierX(t) == x
    float t = x;
    for (int i = 0; i < 8; ++i) {
      float mt = 1.0f - t;
      float bx = 3.0f * mt * mt * t * pressureCurveX1 +
                 3.0f * mt * t * t * pressureCurveX2 + t * t * t;
      float dx = bx - x;
      if (std::abs(dx) < 1e-5f)
        break;
      float dbx = 3.0f * mt * mt * pressureCurveX1 +
                  6.0f * mt * t * (pressureCurveX2 - pressureCurveX1) +
                  3.0f * t * t * (1.0f - pressureCurveX2);
      if (std::abs(dbx) < 1e-6f)
        break;
      t -= dx / dbx;
      t = std::max(0.0f, std::min(1.0f, t));
    }
    float mt = 1.0f - t;
    float y = 3.0f * mt * mt * t * pressureCurveY1 +
              3.0f * mt * t * t * pressureCurveY2 + t * t * t;
    return std::max(0.0f, std::min(1.0f, y));
  }
};

class StrokeRenderer; // Forward declaration

class BrushEngine {
public:
  static uint32_t loadTexture(const QString &name, bool isTip = true);
  BrushEngine();
  ~BrushEngine(); // Needed for unique_ptr cleanup if used, or raw pointer
                  // delete

  // Función principal de dibujo adaptada (QPainter based)
  void paintStroke(QPainter *painter, const QPointF &lastPoint,
                   const QPointF &currentPoint, float pressure,
                   const BrushSettings &settings, float tilt = 0.0f,
                   float velocity = 0.0f, uint32_t canvasTexId = 0,
                   float wetness = 0.0f, float dilution = 0.0f,
                   float smudge = 0.0f,
                   QOpenGLFramebufferObject *pingFBO = nullptr,
                   QOpenGLFramebufferObject *pongFBO = nullptr);

  // Compatibility methods for CanvasItem integration
  void setBrush(const BrushSettings &settings); // Implemented in cpp or inline
  BrushSettings getBrush() const { return m_currentSettings; }

  void setColor(const Color &color); // Updated to update cache
  const Color &getColor() const;

  // Stateful stroke management
  // Stateful stroke management
  void resetRemainder() {
    m_remainder = -1.0f;
    m_accumulatedDistance = 0.0f;
  }
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
  float m_remainder = 0.0f;
  float m_accumulatedDistance =
      0.0f; // Track total stroke length for taper/falloff
  mutable Color
      m_cachedColor; // mutable to allow update in const getter if needed

  // Ayudante para pinceles suaves
  void paintSoftStamp(QPainter *painter, const QPointF &point, float size,
                      float opacity, const QColor &color, float hardness);
};

} // namespace artflow
