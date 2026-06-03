/**
 * ArtFlow Studio — Liquify Engine Implementation
 * ────────────────────────────────────────────────
 * Delegación de la lógica del motor de licuado a la librería de Rust (FFI).
 */

#include "../include/liquify_engine.h"
#include <algorithm>
#include <cmath>
#include <cstring>

// ─── Declaraciones FFI de la librería en Rust ─────────────────────
extern "C" {
    void* liquify_create();
    void liquify_destroy(void* engine);
    void liquify_begin(void* engine, const uint8_t* source_pixels, int32_t width, int32_t height);
    void liquify_end(void* engine);
    void liquify_set_parameters(void* engine, int32_t mode, float radius, float strength, float morpher);
    void liquify_apply_brush(void* engine, float cx, float cy, float prev_cx, float prev_cy);
    void liquify_render_preview(void* engine, uint8_t* out_pixels);
    bool liquify_is_active(void* engine);
    void liquify_get_displacement(void* engine, float* out_dx, float* out_dy, int32_t max_len);
}

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
  // Interpolación bilineal de desplazamientos
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

LiquifyEngine::LiquifyEngine() {
  m_rustEngine = liquify_create();
}

LiquifyEngine::~LiquifyEngine() {
  if (m_rustEngine) {
    liquify_destroy(m_rustEngine);
    m_rustEngine = nullptr;
  }
}

void LiquifyEngine::begin(const ImageBuffer &sourceLayer, int width,
                          int height) {
  m_width = width;
  m_height = height;
  m_active = true;

  m_dispMap.resize(width, height);

  const uint8_t *src = sourceLayer.data();
  if (src && m_rustEngine) {
    liquify_begin(m_rustEngine, src, width, height);
  }
}

QImage LiquifyEngine::end() {
  m_active = false;
  if (m_rustEngine) {
    liquify_end(m_rustEngine);
  }
  return renderPreview();
}

void LiquifyEngine::applyBrush(float cx, float cy, float prevCx, float prevCy) {
  if (!m_active || !m_rustEngine)
    return;

  // Sincronizar parámetros actuales a Rust antes de aplicar el pincel
  liquify_set_parameters(m_rustEngine, static_cast<int32_t>(m_mode), m_radius, m_strength, m_morpher);

  // Ejecutar el dab del pincel en Rust
  liquify_apply_brush(m_rustEngine, cx, cy, prevCx, prevCy);
}

QImage LiquifyEngine::renderPreview() const {
  if (m_width <= 0 || m_height <= 0 || !m_rustEngine)
    return QImage();

  QImage result(m_width, m_height, QImage::Format_RGBA8888_Premultiplied);
  uint8_t *dst = result.bits();

  // Renderizar la previsualización en paralelo con Rayon
  liquify_render_preview(m_rustEngine, dst);

  // Sincronizar el mapa de desplazamiento a m_dispMap para mantener compatibilidad externa
  int totalPixels = m_width * m_height;
  liquify_get_displacement(m_rustEngine, m_dispMap.dx.data(), m_dispMap.dy.data(), totalPixels);

  return result;
}

} // namespace artflow
