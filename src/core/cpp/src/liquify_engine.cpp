/**
 * ArtFlow Studio — Liquify Engine Implementation
 * ────────────────────────────────────────────────
 * Displacement-map based real-time image deformation.
 */

#include "../include/liquify_engine.h"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace artflow {

// ══════════════════════════════════════════════════════════════════
//  DisplacementMap
// ══════════════════════════════════════════════════════════════════

void DisplacementMap::resize(int w, int h) {
  width = w;
  height = h;
  dx.assign(static_cast<size_t>(w) * h, 0.0f);
  dy.assign(static_cast<size_t>(w) * h, 0.0f);
}

void DisplacementMap::clear() {
  std::fill(dx.begin(), dx.end(), 0.0f);
  std::fill(dy.begin(), dy.end(), 0.0f);
}

void DisplacementMap::sampleAt(float x, float y, float &outDx,
                               float &outDy) const {
  // Bilinear interpolation of displacement
  int x0 = static_cast<int>(std::floor(x));
  int y0 = static_cast<int>(std::floor(y));
  int x1 = x0 + 1;
  int y1 = y0 + 1;
  float fx = x - x0;
  float fy = y - y0;

  auto safeDx = [&](int px, int py) -> float {
    int i = idx(px, py);
    return (i >= 0) ? dx[i] : 0.0f;
  };
  auto safeDy = [&](int px, int py) -> float {
    int i = idx(px, py);
    return (i >= 0) ? dy[i] : 0.0f;
  };

  float dx00 = safeDx(x0, y0), dx10 = safeDx(x1, y0);
  float dx01 = safeDx(x0, y1), dx11 = safeDx(x1, y1);
  float dy00 = safeDy(x0, y0), dy10 = safeDy(x1, y0);
  float dy01 = safeDy(x0, y1), dy11 = safeDy(x1, y1);

  outDx = dx00 * (1 - fx) * (1 - fy) + dx10 * fx * (1 - fy) +
          dx01 * (1 - fx) * fy + dx11 * fx * fy;
  outDy = dy00 * (1 - fx) * (1 - fy) + dy10 * fx * (1 - fy) +
          dy01 * (1 - fx) * fy + dy11 * fx * fy;
}

// ══════════════════════════════════════════════════════════════════
//  LiquifyEngine
// ══════════════════════════════════════════════════════════════════

LiquifyEngine::LiquifyEngine() = default;
LiquifyEngine::~LiquifyEngine() = default;

void LiquifyEngine::begin(const ImageBuffer &sourceLayer, int width,
                          int height) {
  m_width = width;
  m_height = height;

  // Snapshot the source layer pixels
  const size_t totalBytes = static_cast<size_t>(width) * height * 4;
  m_original.resize(totalBytes);

  // Copy from ImageBuffer tile storage into contiguous array
  const uint8_t *src = sourceLayer.data();
  if (src) {
    std::memcpy(m_original.data(), src, totalBytes);
  } else {
    std::fill(m_original.begin(), m_original.end(), 0);
  }

  m_dispMap.resize(width, height);
  m_active = true;
}

QImage LiquifyEngine::end() {
  m_active = false;
  return renderPreview();
}

// ── Falloff ──────────────────────────────────────────────────────
float LiquifyEngine::falloff(float dist) const {
  if (dist >= m_radius)
    return 0.0f;

  float t = dist / m_radius; // 0..1

  // Morpher controls the curve shape:
  //   morpher=0  →  sharp quadratic falloff  (1-t²)
  //   morpher=1  →  very smooth cos falloff
  float sharp = 1.0f - t * t;
  float smooth = 0.5f * (1.0f + std::cos(t * 3.14159265f));
  return sharp * (1.0f - m_morpher) + smooth * m_morpher;
}

// ── RNG ──────────────────────────────────────────────────────────
float LiquifyEngine::randFloat() {
  m_rngState ^= m_rngState << 13;
  m_rngState ^= m_rngState >> 17;
  m_rngState ^= m_rngState << 5;
  return static_cast<float>(m_rngState & 0xFFFF) / 65536.0f;
}

// ── Apply Brush ──────────────────────────────────────────────────
void LiquifyEngine::applyBrush(float cx, float cy, float prevCx, float prevCy) {
  if (!m_active)
    return;

  // Brush bounding box (clipped to canvas)
  int x0 = std::max(0, static_cast<int>(cx - m_radius));
  int y0 = std::max(0, static_cast<int>(cy - m_radius));
  int x1 = std::min(m_width - 1, static_cast<int>(cx + m_radius));
  int y1 = std::min(m_height - 1, static_cast<int>(cy + m_radius));

  // Direction vector for Push mode
  float dirX = cx - prevCx;
  float dirY = cy - prevCy;
  float dirLen = std::sqrt(dirX * dirX + dirY * dirY);
  if (dirLen > 0.001f) {
    dirX /= dirLen;
    dirY /= dirLen;
  }

  const float radiusSq = m_radius * m_radius;

  for (int py = y0; py <= y1; ++py) {
    for (int px = x0; px <= x1; ++px) {
      float dx = static_cast<float>(px) - cx;
      float dy = static_cast<float>(py) - cy;
      float distSq = dx * dx + dy * dy;

      if (distSq >= radiusSq)
        continue;

      float dist = std::sqrt(distSq);
      float f = falloff(dist) * m_strength;

      if (f < 0.0001f)
        continue;

      switch (m_mode) {
      case LiquifyMode::Push:
        applyPush(px, py, f, dist, dirX, dirY);
        break;
      case LiquifyMode::TwirlCW:
        applyTwirl(px, py, f, dist, cx, cy, true);
        break;
      case LiquifyMode::TwirlCCW:
        applyTwirl(px, py, f, dist, cx, cy, false);
        break;
      case LiquifyMode::Pinch:
        applyPinch(px, py, f, dist, cx, cy);
        break;
      case LiquifyMode::Expand:
        applyExpand(px, py, f, dist, cx, cy);
        break;
      case LiquifyMode::Crystalize:
        applyCrystalize(px, py, f, dist);
        break;
      case LiquifyMode::Reconstruct:
        applyReconstruct(px, py, f, dist);
        break;
      case LiquifyMode::Smooth:
        applySmooth(px, py, f, dist);
        break;
      default:
        break;
      }
    }
  }
}

// ── Mode Implementations ─────────────────────────────────────────

void LiquifyEngine::applyPush(int px, int py, float fx, float fy, float dirX,
                              float dirY) {
  int i = m_dispMap.idx(px, py);
  if (i < 0)
    return;

  // Push pixels in the direction of brush movement
  // Scale by radius for consistent feel at different sizes
  float pushScale = m_radius * 0.15f;
  m_dispMap.dx[i] -= dirX * fx * pushScale;
  m_dispMap.dy[i] -= dirY * fx * pushScale;
}

void LiquifyEngine::applyTwirl(int px, int py, float fx, float fy, float cx,
                               float cy, bool clockwise) {
  int i = m_dispMap.idx(px, py);
  if (i < 0)
    return;

  // Rotate the displacement around the center
  float dx = static_cast<float>(px) - cx;
  float dy = static_cast<float>(py) - cy;

  // Small angle rotation per dab
  float angle = fx * 0.08f * (clockwise ? 1.0f : -1.0f);
  float cosA = std::cos(angle);
  float sinA = std::sin(angle);

  float newDx = dx * cosA - dy * sinA;
  float newDy = dx * sinA + dy * cosA;

  m_dispMap.dx[i] += (newDx - dx);
  m_dispMap.dy[i] += (newDy - dy);
}

void LiquifyEngine::applyPinch(int px, int py, float fx, float fy, float cx,
                               float cy) {
  int i = m_dispMap.idx(px, py);
  if (i < 0)
    return;

  // Pull pixels toward center
  float dx = cx - static_cast<float>(px);
  float dy = cy - static_cast<float>(py);

  float scale = fx * 0.06f;
  m_dispMap.dx[i] += dx * scale;
  m_dispMap.dy[i] += dy * scale;
}

void LiquifyEngine::applyExpand(int px, int py, float fx, float fy, float cx,
                                float cy) {
  int i = m_dispMap.idx(px, py);
  if (i < 0)
    return;

  // Push pixels away from center (opposite of pinch)
  float dx = static_cast<float>(px) - cx;
  float dy = static_cast<float>(py) - cy;

  float scale = fx * 0.06f;
  m_dispMap.dx[i] += dx * scale;
  m_dispMap.dy[i] += dy * scale;
}

void LiquifyEngine::applyCrystalize(int px, int py, float fx, float fy) {
  int i = m_dispMap.idx(px, py);
  if (i < 0)
    return;

  // Random offset for shattered effect
  float randDx = (randFloat() - 0.5f) * 2.0f * m_radius * 0.3f;
  float randDy = (randFloat() - 0.5f) * 2.0f * m_radius * 0.3f;
  m_dispMap.dx[i] += randDx * fx * 0.4f;
  m_dispMap.dy[i] += randDy * fx * 0.4f;
}

void LiquifyEngine::applyReconstruct(int px, int py, float fx, float fy) {
  int i = m_dispMap.idx(px, py);
  if (i < 0)
    return;

  // Blend displacement back toward zero
  float blend = fx * 0.3f;
  m_dispMap.dx[i] *= (1.0f - blend);
  m_dispMap.dy[i] *= (1.0f - blend);
}

void LiquifyEngine::applySmooth(int px, int py, float fx, float fy) {
  // 3×3 box blur of displacement
  float sumDx = 0, sumDy = 0;
  int count = 0;

  for (int ky = -1; ky <= 1; ++ky) {
    for (int kx = -1; kx <= 1; ++kx) {
      int ni = m_dispMap.idx(px + kx, py + ky);
      if (ni >= 0) {
        sumDx += m_dispMap.dx[ni];
        sumDy += m_dispMap.dy[ni];
        ++count;
      }
    }
  }

  if (count > 0) {
    int i = m_dispMap.idx(px, py);
    if (i >= 0) {
      float avgDx = sumDx / count;
      float avgDy = sumDy / count;
      float blend = fx * 0.5f;
      m_dispMap.dx[i] = m_dispMap.dx[i] * (1.0f - blend) + avgDx * blend;
      m_dispMap.dy[i] = m_dispMap.dy[i] * (1.0f - blend) + avgDy * blend;
    }
  }
}

// ── Bilinear sampling from original snapshot ─────────────────────
void LiquifyEngine::sampleOriginal(float sx, float sy, uint8_t &r, uint8_t &g,
                                   uint8_t &b, uint8_t &a) const {
  // Clamp to valid range
  sx = std::max(0.0f, std::min(sx, static_cast<float>(m_width - 1)));
  sy = std::max(0.0f, std::min(sy, static_cast<float>(m_height - 1)));

  int x0 = static_cast<int>(std::floor(sx));
  int y0 = static_cast<int>(std::floor(sy));
  int x1 = std::min(x0 + 1, m_width - 1);
  int y1 = std::min(y0 + 1, m_height - 1);
  float fx = sx - x0;
  float fy = sy - y0;

  auto pixel = [&](int x, int y) -> const uint8_t * {
    return &m_original[static_cast<size_t>((y * m_width + x) * 4)];
  };

  const uint8_t *p00 = pixel(x0, y0);
  const uint8_t *p10 = pixel(x1, y0);
  const uint8_t *p01 = pixel(x0, y1);
  const uint8_t *p11 = pixel(x1, y1);

  // Bilinear interpolation per channel
  for (int ch = 0; ch < 4; ++ch) {
    float v = p00[ch] * (1 - fx) * (1 - fy) + p10[ch] * fx * (1 - fy) +
              p01[ch] * (1 - fx) * fy + p11[ch] * fx * fy;

    uint8_t val = static_cast<uint8_t>(std::max(0.0f, std::min(255.0f, v)));
    switch (ch) {
    case 0:
      r = val;
      break;
    case 1:
      g = val;
      break;
    case 2:
      b = val;
      break;
    case 3:
      a = val;
      break;
    }
  }
}

// ── Render the deformed image ────────────────────────────────────
QImage LiquifyEngine::renderPreview() const {
  if (m_width <= 0 || m_height <= 0 || m_original.empty())
    return QImage();

  QImage result(m_width, m_height, QImage::Format_RGBA8888);

  // Parallel-friendly: each row is independent
  uint8_t *dst = result.bits();
  const int stride = result.bytesPerLine();

  for (int y = 0; y < m_height; ++y) {
    uint8_t *row = dst + y * stride;
    for (int x = 0; x < m_width; ++x) {
      int i = y * m_width + x;
      float sx = static_cast<float>(x) + m_dispMap.dx[i];
      float sy = static_cast<float>(y) + m_dispMap.dy[i];

      uint8_t r, g, b, a;
      sampleOriginal(sx, sy, r, g, b, a);

      int off = x * 4;
      row[off + 0] = r;
      row[off + 1] = g;
      row[off + 2] = b;
      row[off + 3] = a;
    }
  }

  return result;
}

} // namespace artflow
