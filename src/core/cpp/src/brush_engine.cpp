/**
 * ArtFlow Studio - Premium Brush Engine Implementation
 * Replicates Procreate/Adobe Fresco behaviors in C++
 *
 * Features:
 * - Per-brush-type shape algorithms (Pencil grain, Watercolor wet edges, etc.)
 * - Color mixing/smudging for Oil and Watercolor
 * - Proper spacing interpolation with remainder
 * - Anti-aliased edges
 */

#include "../include/brush_engine.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>

namespace artflow {

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Linear Interpolation
template <typename T> T lerp(T a, T b, float t) { return a + (b - a) * t; }

// Clamp value (C++11/14 compatible)
template <typename T> T clampVal(T val, T minVal, T maxVal) {
  if (val < minVal)
    return minVal;
  if (val > maxVal)
    return maxVal;
  return val;
}

// Smoothstep (Hermite interpolation)
float smoothstep(float edge0, float edge1, float x) {
  float t = clampVal((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
  return t * t * (3.0f - 2.0f * t);
}

// Fast deterministic 2D noise (integer input)
float hash2D(int x, int y) {
  int n = x + y * 57;
  n = (n << 13) ^ n;
  return (1.0f - ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) /
                     1073741824.0f);
}

// Smooth interpolated noise (float input) for premium texture
float noise2D(float x, float y) {
  int x0 = static_cast<int>(std::floor(x));
  int y0 = static_cast<int>(std::floor(y));
  int x1 = x0 + 1;
  int y1 = y0 + 1;

  float sx = x - x0;
  float sy = y - y0;

  // Cubic blending (s-curve) for smoothness
  sx = sx * sx * (3.0f - 2.0f * sx);
  sy = sy * sy * (3.0f - 2.0f * sy);

  float n0 = hash2D(x0, y0);
  float n1 = hash2D(x1, y0);
  float ix0 = n0 + (n1 - n0) * sx;

  float n2 = hash2D(x0, y1);
  float n3 = hash2D(x1, y1);
  float ix1 = n2 + (n3 - n2) * sx;

  return ix0 + (ix1 - ix0) * sy; // Range [-1, 1]
}

// Cubic pressure curve for more natural response
float applyPressureCurve(float p) {
  return p * p; // Quadratic curve (Gamma 2.0 style)
}

// Random noise [0, 1] - for per-pixel variation
float randomNoise01() {
  return static_cast<float>(rand()) / static_cast<float>(RAND_MAX);
}

// ============================================================================
// COLOR IMPLEMENTATION
// ============================================================================

Color Color::blend(const Color &other, float opacity) const {
  float aFactor = (other.a / 255.0f) * opacity;
  float invFactor = 1.0f - aFactor;

  return Color(static_cast<uint8_t>(
                   clampVal(other.r * aFactor + r * invFactor, 0.0f, 255.0f)),
               static_cast<uint8_t>(
                   clampVal(other.g * aFactor + g * invFactor, 0.0f, 255.0f)),
               static_cast<uint8_t>(
                   clampVal(other.b * aFactor + b * invFactor, 0.0f, 255.0f)),
               static_cast<uint8_t>(
                   clampVal(a + (other.a - a) * aFactor, 0.0f, 255.0f)));
}

// ============================================================================
// BRUSH ENGINE CORE
// ============================================================================

BrushEngine::BrushEngine() { m_color = Color(0, 0, 0, 255); }

BrushEngine::~BrushEngine() {}

void BrushEngine::setBrush(const BrushSettings &settings) {
  m_brush = settings;
}

void BrushEngine::setColor(const Color &color) { m_color = color; }

void BrushEngine::beginStroke(const StrokePoint &point) {
  m_isStroking = true;
  m_lastPoint = point;
  // Initialize stabilizer position
  m_brushPos = point;

  m_remainder = 0.0f; // CRITICAL: Reset spacing accumulator
  m_strokeDistance = 0.0f;
  m_stabilizationBuffer.clear();
  m_stabilizationBuffer.push_back(point);
}

void BrushEngine::continueStroke(const StrokePoint &point) {
  if (!m_isStroking)
    return;

  // ----------------------------------------------------------------
  // STABILIZER (Low-Pass Filter)
  // ----------------------------------------------------------------
  // Smoothing factor based on stabilization setting
  // 0.0 = Raw input, 1.0 = Super slow/smooth
  // We use a non-linear mapping for better feel
  float stabilizationFactor = m_brush.stabilization;      // [0, 1]
  float lerpFactor = 1.0f - (stabilizationFactor * 0.9f); // 0.1 to 1.0
  lerpFactor = clampVal(lerpFactor, 0.05f,
                        1.0f); // Ensure it's never too slow or too fast

  // Move smooth position towards raw target
  m_brushPos.x = lerp(m_brushPos.x, point.x, lerpFactor);
  m_brushPos.y = lerp(m_brushPos.y, point.y, lerpFactor);
  // Pressure is also somewhat smoothed to avoid sudden blobs
  m_brushPos.pressure =
      lerp(m_brushPos.pressure, point.pressure, lerpFactor * 1.5f);

  // Update last point to track raw input just in case,
  // but rendering should use m_brushPos and previous m_brushPos.
  // NOTE: In current architecture, callee uses renderStrokeSegment directly.
  // Ideally, this function should perform the rendering or emit events.
  m_lastPoint = point;
}

void BrushEngine::endStroke() {
  m_isStroking = false;
  m_remainder = 0.0f;
  m_strokeDistance = 0.0f;
  m_stabilizationBuffer.clear();
}

// ============================================================================
// PREMIUM BRUSH SHAPE CALCULATION
// This is where the "magic" happens - each brush type gets unique behavior
// ============================================================================

float calculateBrushAlpha(float dist, float radius, float hardness,
                          BrushSettings::Type type, float pressure, int px,
                          int py) {

  float normalizedDist = dist / radius;
  if (normalizedDist >= 1.0f)
    return 0.0f; // Outside the circle

  float alpha = 0.0f;

  // Premium scaling for texture frequency
  float freq = 0.5f;

  switch (type) {
  // ----------------------------------------------------------------
  // PENCIL: Grainy texture simulating graphite on paper
  // ----------------------------------------------------------------
  case BrushSettings::Type::Pencil: {
    // Smooth multi-octave noise for realistic paper grain
    // Scale coordinates by frequency factor
    float noiseVal1 =
        noise2D(px * 0.15f, py * 0.15f); // Low freq (paper undulation)
    float noiseVal2 = noise2D(px * 0.8f, py * 0.8f); // High freq (tooth)

    // Normalize to [0, 1] range
    float grain1 = noiseVal1 * 0.5f + 0.5f;
    float grain2 = noiseVal2 * 0.5f + 0.5f;
    float grain = grain1 * 0.4f + grain2 * 0.6f;

    // Base shape with soft falloff for graphite
    float shape = 1.0f - normalizedDist;
    shape = std::pow(shape, 1.5f); // Slightly harder core than linear

    // Interaction loop: Graphite sticks to "peaks" of paper
    // Less pressure = only hits peaks. More pressure = fills valleys.
    float pressureFill = 0.2f + 0.8f * pressure;
    float grainMask = smoothstep(1.0f - pressureFill - 0.2f,
                                 1.0f - pressureFill + 0.2f, grain);

    alpha = shape * grainMask;

    // Add randomness to edges (jitter)
    float edgeNoise = noise2D(px * 0.05f, py * 0.05f) * 0.1f;
    if (normalizedDist > 0.8f + edgeNoise)
      alpha *= 0.5f;

    // Pressure opacity modulation
    alpha *= std::pow(pressure, 0.5f);
    break;
  }

  // ----------------------------------------------------------------
  // WATERCOLOR: Wet edge effect (darker at borders)
  // ----------------------------------------------------------------
  case BrushSettings::Type::Watercolor: {
    // Distorted coordinates for wet bleed look
    float distortX = noise2D(px * 0.05f, py * 0.05f + radius) * 0.15f;
    float distortY = noise2D(px * 0.05f + radius, py * 0.05f) * 0.15f;
    float d = normalizedDist + (distortX + distortY);
    d = clampVal(d, 0.0f, 1.0f);

    // Core: soft gaussian-like falloff
    float core = std::pow(1.0f - d, 1.5f);

    // Edge ring: pigment accumulates at the edge
    float edgeEffect = 0.0f;
    if (d > 0.7f) {
      edgeEffect = smoothstep(0.7f, 0.95f, d) *
                   (1.0f - smoothstep(0.95f, 1.0f, d)) * 0.5f;
    }

    // Granulation (pigment settling)
    float pigmentGrain = noise2D(px * 0.5f, py * 0.5f) * 0.5f + 0.5f;
    pigmentGrain = std::pow(pigmentGrain, 2.0f) * 0.2f;

    alpha = core + edgeEffect + pigmentGrain;

    // Watercolor transparency
    alpha *= 0.7f * pressure;
    break;
  }

  // ----------------------------------------------------------------
  // INK: Super sharp edges for clean lines
  // ----------------------------------------------------------------
  case BrushSettings::Type::Ink: {
    // Very sharp cutoff with nice anti-aliasing
    float edge = 0.95f;

    // Slight waviness for "G-Pen" feel on paper approx
    float waviness = noise2D(px * 0.1f, py * 0.1f) * 0.02f;
    float effectiveEdge =
        edge + waviness * (1.0f - pressure); // More wobble on light strokes

    alpha =
        1.0f - smoothstep(effectiveEdge - 0.05f, effectiveEdge, normalizedDist);

    // Ink is fully opaque usually
    if (pressure < 0.2f)
      alpha *= pressure * 5.0f; // Fade out only at very start
    break;
  }

  // ----------------------------------------------------------------
  // AIRBRUSH: Ultra-soft gaussian spray
  // ----------------------------------------------------------------
  case BrushSettings::Type::Airbrush: {
    // Pure Gaussian
    float falloff = std::exp(-normalizedDist * normalizedDist * 5.0f);

    // Dithering spray noise
    float spray = noise2D(px * 1.5f, py * 1.5f) * 0.1f;

    alpha = falloff + spray * falloff;
    alpha *= pressure;
    break;
  }

  // ----------------------------------------------------------------
  // OIL: Bristle texture with color mixing
  // ----------------------------------------------------------------
  case BrushSettings::Type::Oil: {
    // Bristle texture: stretched noise along stroke direction would be ideal,
    // but here we use simple anisotropic-like noise
    float bristle = noise2D(px * 0.3f, py * 0.3f) * 0.5f + 0.5f;

    // Heavy body paint shape
    float shape =
        std::sqrt(std::max(0.0f, 1.0f - normalizedDist * normalizedDist));

    alpha = shape * (0.6f + 0.4f * bristle);
    alpha *= std::min(1.0f, pressure * 1.2f);
    break;
  }

  // ----------------------------------------------------------------
  // ACRYLIC: Flat with rough edges (impasto)
  // ----------------------------------------------------------------
  case BrushSettings::Type::Acrylic: {
    // Rough canvas texture
    float canvasTex = noise2D(px * 0.2f, py * 0.2f) * 0.1f;
    float effectiveDist = normalizedDist + canvasTex;

    // Sharp threshold
    alpha = 1.0f - smoothstep(hardness - 0.1f, hardness, effectiveDist);

    // Impasto texture inside
    float impasto = noise2D(px * 0.1f, py * 0.1f) * 0.05f;
    alpha += impasto * alpha;

    alpha *= pressure;
    break;
  }

  // ----------------------------------------------------------------
  // ERASER: Same as round but used for erasing
  // ----------------------------------------------------------------
  case BrushSettings::Type::Eraser:

  // ----------------------------------------------------------------
  // ROUND (Default): Standard brush with variable hardness
  // ----------------------------------------------------------------
  case BrushSettings::Type::Round:
  case BrushSettings::Type::Custom:
  default: {
    if (hardness >= 0.99f) {
      // Hard brush: solid until edge
      alpha = (normalizedDist <= 1.0f) ? 1.0f : 0.0f;
    } else if (hardness <= 0.01f) {
      // Very soft: linear falloff from center
      alpha = 1.0f - normalizedDist;
      alpha = alpha * alpha * (3.0f - 2.0f * alpha); // Smoothstep
    } else {
      // Variable hardness
      if (normalizedDist < hardness) {
        alpha = 1.0f;
      } else {
        float range = 1.0f - hardness;
        if (range > 0.001f) {
          float t = (normalizedDist - hardness) / range;
          alpha = 1.0f - smoothstep(0.0f, 1.0f, t);
        }
      }
    }
    break;
  }
  }

  return clampVal(alpha, 0.0f, 1.0f);
}

// ============================================================================
// DAB RENDERING (Single brush stamp)
// ============================================================================

void BrushEngine::renderDab(ImageBuffer &target, float x, float y,
                            float pressure, bool alphaLock,
                            const ImageBuffer *mask) {

  float size = calculateDabSize(pressure);
  float radius = size * 0.5f;
  float baseOpacity = calculateDabOpacity(pressure);

  // Bounding box with extra pixel for AA
  int minX = std::max(0, static_cast<int>(std::floor(x - radius - 1)));
  int minY = std::max(0, static_cast<int>(std::floor(y - radius - 1)));
  int maxX =
      std::min(target.width() - 1, static_cast<int>(std::ceil(x + radius + 1)));
  int maxY = std::min(target.height() - 1,
                      static_cast<int>(std::ceil(y + radius + 1)));

  // Minimum effective radius
  float effectiveRadius = std::max(0.5f, radius);

  // Check if this brush type uses color mixing
  bool isMixingBrush = (m_brush.type == BrushSettings::Type::Oil ||
                        m_brush.type == BrushSettings::Type::Watercolor) &&
                       m_brush.wetness > 0.0f;

  // Brush color
  float srcR = static_cast<float>(m_color.r);
  float srcG = static_cast<float>(m_color.g);
  float srcB = static_cast<float>(m_color.b);

  // Iterate over pixels
  for (int py = minY; py <= maxY; ++py) {
    for (int px = minX; px <= maxX; ++px) {

      // Calculate distance with sub-pixel precision
      float distX = static_cast<float>(px) - x;
      float distY = static_cast<float>(py) - y;
      float dist = std::sqrt(distX * distX + distY * distY);

      // Skip if outside
      if (dist > effectiveRadius + 1.0f)
        continue;

      // 1. Calculate premium brush shape alpha
      float shapeAlpha =
          calculateBrushAlpha(dist, effectiveRadius, m_brush.hardness,
                              m_brush.type, pressure, px, py);

      // 2. Apply edge anti-aliasing
      float edgeAA = 1.0f;
      if (dist > effectiveRadius - 1.0f) {
        edgeAA = std::max(0.0f, effectiveRadius - dist + 1.0f);
      }
      shapeAlpha *= edgeAA;

      // 3. Apply base opacity
      float finalAlpha = shapeAlpha * baseOpacity;

      // Skip if too transparent
      if (finalAlpha < 0.005f)
        continue;

      // Get destination pixel
      uint8_t *dest = target.pixelAt(px, py);
      if (!dest)
        continue;

      // ----------------------------------------------------------------
      // ERASER MODE
      // ----------------------------------------------------------------
      if (m_brush.type == BrushSettings::Type::Eraser) {
        float eraserStrength = finalAlpha;
        dest[3] = static_cast<uint8_t>(dest[3] * (1.0f - eraserStrength));
        continue;
      }

      // Alpha Lock check
      if (alphaLock && dest[3] == 0) {
        continue;
      }

      // Clipping Mask support
      if (mask) {
        const uint8_t *maskPixel = mask->pixelAt(px, py);
        if (maskPixel) {
          finalAlpha *= (maskPixel[3] / 255.0f);
        } else {
          continue;
        }
      }

      // ----------------------------------------------------------------
      // COLOR MIXING (Oil/Watercolor)
      // ----------------------------------------------------------------
      float finalR = srcR;
      float finalG = srcG;
      float finalB = srcB;

      if (isMixingBrush && dest[3] > 0) {
        // Mix brush color with canvas color based on wetness
        float bgAlpha = dest[3] / 255.0f;
        float mixFactor = m_brush.wetness * bgAlpha * 0.5f;

        finalR = srcR * (1.0f - mixFactor) + dest[0] * mixFactor;
        finalG = srcG * (1.0f - mixFactor) + dest[1] * mixFactor;
        finalB = srcB * (1.0f - mixFactor) + dest[2] * mixFactor;
      }

      // ----------------------------------------------------------------
      // COMPOSITING (Blending)
      // ----------------------------------------------------------------
      float invAlpha = 1.0f - finalAlpha;

      if (m_brush.type == BrushSettings::Type::Watercolor) {
        // Watercolor uses multiply-like blending for translucency
        float wMix = finalAlpha * 0.7f; // Lighter effect
        dest[0] = static_cast<uint8_t>(clampVal(
            (dest[0] * finalR / 255.0f) * wMix + dest[0] * (1.0f - wMix), 0.0f,
            255.0f));
        dest[1] = static_cast<uint8_t>(clampVal(
            (dest[1] * finalG / 255.0f) * wMix + dest[1] * (1.0f - wMix), 0.0f,
            255.0f));
        dest[2] = static_cast<uint8_t>(clampVal(
            (dest[2] * finalB / 255.0f) * wMix + dest[2] * (1.0f - wMix), 0.0f,
            255.0f));

        // Watercolor builds up alpha slowly
        float newAlpha = dest[3] + finalAlpha * 40.0f;
        dest[3] = static_cast<uint8_t>(clampVal(newAlpha, 0.0f, 255.0f));
      } else {
        // Standard Source Over blending
        dest[0] = static_cast<uint8_t>(
            clampVal(finalR * finalAlpha + dest[0] * invAlpha, 0.0f, 255.0f));
        dest[1] = static_cast<uint8_t>(
            clampVal(finalG * finalAlpha + dest[1] * invAlpha, 0.0f, 255.0f));
        dest[2] = static_cast<uint8_t>(
            clampVal(finalB * finalAlpha + dest[2] * invAlpha, 0.0f, 255.0f));

        // Alpha accumulation
        float alphaBuildUp =
            (m_brush.type == BrushSettings::Type::Oil) ? 1.0f : 0.8f;
        float srcA = finalAlpha * alphaBuildUp;
        float dstA = dest[3] / 255.0f;
        float outA = srcA + dstA * (1.0f - srcA);
        dest[3] = static_cast<uint8_t>(clampVal(outA * 255.0f, 0.0f, 255.0f));
      }
    }
  }
}

// ============================================================================
// STROKE SEGMENT RENDERING (Interpolation with Remainder)
// ============================================================================

void BrushEngine::renderStrokeSegment(ImageBuffer &target,
                                      const StrokePoint &from,
                                      const StrokePoint &to, bool alphaLock,
                                      const ImageBuffer *mask) {

  float dx = to.x - from.x;
  float dy = to.y - from.y;
  float distance = std::sqrt(dx * dx + dy * dy);

  // If nearly zero distance, draw single point
  if (distance < 0.1f) {
    renderDab(target, to.x, to.y, to.pressure, alphaLock, mask);
    return;
  }

  // Calculate step based on brush size and spacing
  float avgPressure = (from.pressure + to.pressure) * 0.5f;
  float currentSize = calculateDabSize(avgPressure);

  // Minimum spacing varies by brush type for optimal quality
  float minSpacing = 1.0f;
  switch (m_brush.type) {
  case BrushSettings::Type::Ink:
    // Ink needs ultra-low spacing for clean G-pen lines
    minSpacing = 0.3f;
    break;
  case BrushSettings::Type::Airbrush:
    // Airbrush needs low spacing for smooth gradients
    minSpacing = 0.5f;
    break;
  case BrushSettings::Type::Pencil:
    // Pencil can have slightly higher spacing (grain fills gaps)
    minSpacing = 0.8f;
    break;
  default:
    minSpacing = 0.5f;
    break;
  }

  float step = std::max(minSpacing, currentSize * m_brush.spacing);

  // Interpolation loop with remainder
  float currentDist = m_remainder;

  while (currentDist <= distance) {
    float t = currentDist / distance;

    // Interpolate position
    float x = lerp(from.x, to.x, t);
    float y = lerp(from.y, to.y, t);

    // Interpolate pressure
    float pressure = lerp(from.pressure, to.pressure, t);

    // Draw the dab
    renderDab(target, x, y, pressure, alphaLock, mask);

    currentDist += step;
  }

  // Save remainder for next segment (CRITICAL for continuous strokes)
  m_remainder = currentDist - distance;
  m_strokeDistance += distance;
}

// ============================================================================
// DYNAMICS CALCULATIONS
// ============================================================================

float BrushEngine::calculateDabSize(float pressure) const {
  float baseSize = m_brush.size;
  if (m_brush.sizeByPressure) {
    // Non-linear size response for premium feel
    float curvedP = applyPressureCurve(pressure);
    baseSize *= (0.1f + 0.9f * curvedP);
  }
  return baseSize;
}

float BrushEngine::calculateDabOpacity(float pressure) const {
  float opacityVal = m_brush.opacity;

  if (m_brush.opacityByPressure) {
    float curvedP = applyPressureCurve(pressure);
    opacityVal *= (0.05f + 0.95f * curvedP);
  }

  // Flow affects opacity per stamp
  opacityVal *= m_brush.flow;

  return clampVal(opacityVal, 0.0f, 1.0f);
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

std::vector<StrokePoint>
BrushEngine::interpolatePoints(const StrokePoint &from,
                               const StrokePoint &to) const {
  std::vector<StrokePoint> points;

  float dx = to.x - from.x;
  float dy = to.y - from.y; // Added missing dy
  // Calculate dabs to draw based on spacing
  float distance = std::sqrt(dx * dx + dy * dy);

  // High-density drawing for premium feel:
  // Ensure we draw at least one dab if there is any movement
  float step = std::max(0.5f, m_brush.size * m_brush.spacing * 0.5f);
  int numSteps = std::max(1, static_cast<int>(distance / step));

  float dp = to.pressure - from.pressure; // Calculate pressure difference

  for (int i = 0; i <= numSteps; ++i) {
    float t = static_cast<float>(i) / numSteps;
    StrokePoint p;         // Create a StrokePoint to store interpolated values
    p.x = from.x + dx * t; // Corrected 'start.x' to 'from.x'
    p.y = from.y + dy * t; // Corrected 'start.y' to 'from.y'
    p.pressure = from.pressure + dp * t; // Corrected 'start.pressure' and 'dp'
    points.push_back(p); // Add the interpolated point to the vector
  }

  return points;
}

void BrushEngine::applyBrushTexture(ImageBuffer &target, float x, float y,
                                    float size, float opacity) {
  // TODO: Implement custom brush tip texture application
  // This would sample from m_brush.tipImage and composite onto target
}

} // namespace artflow
