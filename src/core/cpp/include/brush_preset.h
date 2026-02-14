#pragma once

#include <QColor>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QVariantList>
#include <cmath>
#include <string>
#include <vector>

namespace artflow {

// ============================================================
// Pressure/Dynamics Curve (Bezier-based LUT)
// ============================================================
struct ResponseCurve {
  // Cubic Bezier control points: P0(0,0), P1(cx1,cy1), P2(cx2,cy2), P3(1,1)
  float cx1 = 0.0f, cy1 = 0.0f;
  float cx2 = 1.0f, cy2 = 1.0f;

  // Pre-baked LUT for fast lookup (256 entries)
  float lut[256];

  void bake() {
    for (int i = 0; i < 256; ++i) {
      float t = i / 255.0f;
      lut[i] = evalCubicBezier(t);
    }
  }

  float evaluate(float input) const {
    if (input <= 0.0f)
      return lut[0];
    if (input >= 1.0f)
      return lut[255];
    float idx = input * 255.0f;
    int lo = (int)idx;
    int hi = lo < 255 ? lo + 1 : 255;
    float frac = idx - lo;
    return lut[lo] * (1.0f - frac) + lut[hi] * frac;
  }

  static ResponseCurve linear() {
    ResponseCurve c;
    c.cx1 = 0.0f;
    c.cy1 = 0.0f;
    c.cx2 = 1.0f;
    c.cy2 = 1.0f;
    c.bake();
    return c;
  }

  static ResponseCurve easeIn() {
    ResponseCurve c;
    c.cx1 = 0.42f;
    c.cy1 = 0.0f;
    c.cx2 = 1.0f;
    c.cy2 = 1.0f;
    c.bake();
    return c;
  }

  static ResponseCurve easeOut() {
    ResponseCurve c;
    c.cx1 = 0.0f;
    c.cy1 = 0.0f;
    c.cx2 = 0.58f;
    c.cy2 = 1.0f;
    c.bake();
    return c;
  }

  static ResponseCurve soft() {
    ResponseCurve c;
    c.cx1 = 0.25f;
    c.cy1 = 0.1f;
    c.cx2 = 0.25f;
    c.cy2 = 1.0f;
    c.bake();
    return c;
  }

  static ResponseCurve hard() {
    ResponseCurve c;
    c.cx1 = 0.75f;
    c.cy1 = 0.0f;
    c.cx2 = 0.75f;
    c.cy2 = 0.9f;
    c.bake();
    return c;
  }

  QJsonArray toJson() const { return QJsonArray{cx1, cy1, cx2, cy2}; }

  static ResponseCurve fromJson(const QJsonArray &arr) {
    ResponseCurve c;
    if (arr.size() >= 4) {
      c.cx1 = arr[0].toDouble();
      c.cy1 = arr[1].toDouble();
      c.cx2 = arr[2].toDouble();
      c.cy2 = arr[3].toDouble();
    }
    c.bake();
    return c;
  }

private:
  // Attempt to find y for a given x on the Bezier, by iterating t
  float evalCubicBezier(float x) const {
    // Newton's method: find t such that bezierX(t) == x
    float t = x; // initial guess
    for (int i = 0; i < 8; ++i) {
      float bx = bezierComponent(t, 0.0f, cx1, cx2, 1.0f);
      float dx = bx - x;
      if (std::abs(dx) < 1e-6f)
        break;
      float dbx = bezierDerivative(t, 0.0f, cx1, cx2, 1.0f);
      if (std::abs(dbx) < 1e-6f)
        break;
      t -= dx / dbx;
      t = std::max(0.0f, std::min(1.0f, t));
    }
    return bezierComponent(t, 0.0f, cy1, cy2, 1.0f);
  }

  static float bezierComponent(float t, float p0, float p1, float p2,
                               float p3) {
    float mt = 1.0f - t;
    return mt * mt * mt * p0 + 3.0f * mt * mt * t * p1 +
           3.0f * mt * t * t * p2 + t * t * t * p3;
  }

  static float bezierDerivative(float t, float p0, float p1, float p2,
                                float p3) {
    float mt = 1.0f - t;
    return 3.0f * mt * mt * (p1 - p0) + 6.0f * mt * t * (p2 - p1) +
           3.0f * t * t * (p3 - p2);
  }
};

// ============================================================
// DynamicsProperty — a single parameter driven by curves
// ============================================================
struct DynamicsProperty {
  float baseValue = 1.0f;
  float minLimit = 0.0f;
  ResponseCurve pressureCurve;
  float tiltInfluence = 0.0f;
  float velocityInfluence = 0.0f;
  float jitter = 0.0f;

  DynamicsProperty() { pressureCurve = ResponseCurve::linear(); }

  float apply(float pressure, float tilt = 0.0f, float velocity = 0.0f) const {
    float p = pressureCurve.evaluate(pressure);
    float result = baseValue * (minLimit + (1.0f - minLimit) * p);
    result += tiltInfluence * tilt;
    result += velocityInfluence * velocity;
    return std::max(0.0f, std::min(1.0f, result));
  }

  // Convenience: evaluate with only pressure input
  float evaluate(float pressure) const { return apply(pressure); }

  QJsonObject toJson() const {
    QJsonObject obj;
    obj["base_value"] = baseValue;
    obj["min_limit"] = minLimit;
    obj["pressure_curve"] = pressureCurve.toJson();
    obj["tilt_influence"] = tiltInfluence;
    obj["velocity_influence"] = velocityInfluence;
    obj["jitter"] = jitter;
    return obj;
  }

  static DynamicsProperty fromJson(const QJsonObject &obj) {
    DynamicsProperty d;
    d.baseValue = obj.value("base_value").toDouble(1.0);
    d.minLimit = obj.value("min_limit").toDouble(0.0);
    d.tiltInfluence = obj.value("tilt_influence").toDouble(0.0);
    d.velocityInfluence = obj.value("velocity_influence").toDouble(0.0);
    d.jitter = obj.value("jitter").toDouble(0.0);

    if (obj.contains("pressure_curve")) {
      QJsonValue cv = obj["pressure_curve"];
      if (cv.isArray()) {
        d.pressureCurve = ResponseCurve::fromJson(cv.toArray());
      } else if (cv.isString()) {
        QString name = cv.toString();
        if (name == "ease_in")
          d.pressureCurve = ResponseCurve::easeIn();
        else if (name == "ease_out")
          d.pressureCurve = ResponseCurve::easeOut();
        else if (name == "soft")
          d.pressureCurve = ResponseCurve::soft();
        else if (name == "hard")
          d.pressureCurve = ResponseCurve::hard();
        else
          d.pressureCurve = ResponseCurve::linear();
      }
    }
    return d;
  }
};

// ============================================================
// BrushPreset — the full definition of a brush
// ============================================================
struct BrushPreset {
  // === Meta ===
  QString uuid;
  QString name;
  QString category; // e.g. "Sketching", "Inking", "Painting"
  QString author = "ArtFlow Studio";
  int version = 1;

  // === Rendering ===
  enum class BlendMode { Normal, Multiply, Screen, Overlay, Darken, Lighten };
  BlendMode blendMode = BlendMode::Normal;
  bool antiAliasing = true;

  // === Shape (Brush Tip) ===
  struct ShapeSettings {
    QString tipTexture;    // filename in assets/brushes/ or empty for round
    float rotation = 0.0f; // degrees
    bool followStroke = false;
    float scatter = 0.0f;
    float roundness = 1.0f; // 1.0 = circle, 0.1 = flat
    bool flipX = false;
    bool flipY = false;
    float contrast = 1.0f;
    float blur = 0.0f;

    // New fields
    bool invert = false;
    bool randomize = false;
    int count = 1;
    float countJitter = 0.0f;
    float calligraphic = 0.0f; // 0..1 angle influence

    QJsonObject toJson() const;
    static ShapeSettings fromJson(const QJsonObject &obj);
  } shape;

  // === Randomize (Jitter) ===
  struct RandomizeSettings {
    float posJitterX = 0.0f;
    float posJitterY = 0.0f;
    float rotationJitter = 0.0f;
    float roundnessJitter = 0.0f;
    float sizeJitter = 0.0f;
    float opacityJitter = 0.0f;

    QJsonObject toJson() const;
    static RandomizeSettings fromJson(const QJsonObject &obj);
  } randomize;

  // === Grain (Paper Texture) ===
  struct GrainSettings {
    QString texture; // filename in assets/textures/
    float scale = 1.0f;
    float intensity = 0.5f;
    float rotation = 0.0f;
    float brightness = 0.0f;
    float contrast = 1.0f;
    bool rolling = true; // true = fixed to canvas, false = stamps with brush

    // New fields
    bool invert = false;
    float overlap = 0.0f;
    float blur = 0.0f;
    float motionBlur = 0.0f;
    float motionBlurAngle = 0.0f;
    bool randomOffset = false;
    QString blendMode = "normal";

    QJsonObject toJson() const;
    static GrainSettings fromJson(const QJsonObject &obj);
  } grain;

  // === Stroke Settings ===
  struct StrokeSettings {
    float spacing = 0.1f;    // 0.01 to 1.0, fraction of brush size
    float streamline = 0.0f; // stabilizer amount (0..1)
    float taperStart = 0.0f;
    float taperEnd = 0.0f;
    bool antiConcussion = false;

    // New fields
    float jitterLateral = 0.0f;
    float jitterLinear = 0.0f;
    float fallOff = 0.0f;
    float stabilization = 0.0f;
    float taperSize = 0.0f;
    float distance = 1.0f;

    QJsonObject toJson() const;
    static StrokeSettings fromJson(const QJsonObject &obj);
  } stroke;

  // === Dynamics (Pressure/Tilt/Speed Curves) ===
  DynamicsProperty sizeDynamics;
  DynamicsProperty opacityDynamics;
  DynamicsProperty flowDynamics;
  DynamicsProperty hardnessDynamics; // Not all brushes use this

  // === Wet Mix Engine ===
  struct WetMixSettings {
    float wetMix = 0.0f; // Overall wet mix amount (0 = dry)
    float pigment = 1.0f;
    float charge = 1.0f;
    float pull = 0.0f;    // Mixer pull (smudge)
    float wetness = 0.0f; // Darkened edges
    float blur = 0.0f;
    float dilution = 0.0f;

    // New fields
    float pressurePigment = 0.0f;
    float pullPressure = 0.0f;
    float wetJitter = 0.0f;

    QJsonObject toJson() const;
    static WetMixSettings fromJson(const QJsonObject &obj);
  } wetMix;

  // === Color Dynamics ===
  struct ColorDynamics {
    // Basic Jitter (Legacy compatibility)
    float hueJitter = 0.0f;
    float saturationJitter = 0.0f;
    float brightnessJitter = 0.0f;

    // Stroke-level
    float strokeHueJitter = 0.0f;
    float strokeSatJitter = 0.0f;
    float strokeLightJitter = 0.0f;
    float strokeDarkJitter = 0.0f;

    // Stamp-level
    float stampHueJitter = 0.0f;
    float stampSatJitter = 0.0f;
    float stampLightJitter = 0.0f;
    float stampDarkJitter = 0.0f;

    // Pressure-driven
    float pressureHueJitter = 0.0f;
    float pressureSatJitter = 0.0f;
    float pressureLightJitter = 0.0f;
    float pressureDarkJitter = 0.0f;

    // Tilt-driven
    float tiltHueJitter = 0.0f;
    float tiltSatJitter = 0.0f;
    float tiltLightJitter = 0.0f;
    float tiltDarkJitter = 0.0f;

    // Secondary color
    bool useSecondaryColor = false;

    QJsonObject toJson() const;
    static ColorDynamics fromJson(const QJsonObject &obj);
  } colorDynamics;

  // === Meta Settings (Notes, History) ===
  struct MetaSettings {
    QString notes;
    QString dateCreated;
    // Images stored as Base64 strings or paths
    QString signatureImage;
    QString authorPicture;

    QJsonObject toJson() const;
    static MetaSettings fromJson(const QJsonObject &obj);
  } metaData;

  // === Customize Limits ===
  float minSize = 1.0f;
  float maxSize = 500.0f;
  float defaultSize = 20.0f;
  float minOpacity = 0.0f;
  float maxOpacity = 1.0f;
  float defaultOpacity = 1.0f;
  float defaultHardness = 0.8f;
  float defaultFlow = 1.0f;

  // === Dual Brush (optional) ===
  // For Phase 5 - placeholder
  // std::shared_ptr<BrushPreset> secondaryBrush;
  // BlendMode dualBlendMode = BlendMode::Normal;

  // === Serialization ===
  QJsonObject toJson() const;
  static BrushPreset fromJson(const QJsonObject &obj);

  // === Legacy Compat: Convert to old BrushSettings ===
  // This bridges the new system with the existing engine
  void applyToLegacy(struct BrushSettings &settings) const;

  // === Generate UUID ===
  static QString generateUUID();
};

// ============================================================
// BrushGroup — a category of brushes
// ============================================================
struct BrushGroup {
  QString name;
  QString icon; // Initials like "SK" for Sketching
  std::vector<BrushPreset> brushes;

  QJsonObject toJson() const;
  static BrushGroup fromJson(const QJsonObject &obj);
};

} // namespace artflow
