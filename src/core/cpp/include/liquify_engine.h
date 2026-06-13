/**
 * ArtFlow Studio — Liquify Engine
 * ────────────────────────────────
 * High-performance displacement-map based image deformation.
 *
 * Architecture
 * ────────────
 *   Original Image ──►  Displacement Map  ──►  Deformed Image
 *                        (vec2 per pixel)
 *
 * Each pixel in the displacement map stores an (dx, dy) offset.
 * The deformed image is produced by: out(x,y) = src(x+dx, y+dy).
 *
 * Modes
 * ─────
 *   Push       – translates pixels in the direction of brush movement
 *   TwirlCW    – rotates pixels clockwise around the brush center
 *   TwirlCCW   – rotates pixels counter-clockwise
 *   Pinch      – contracts pixels toward the brush center
 *   Expand     – expands pixels outward from the brush center
 *   Crystalize – randomizes displacement for a shattered look
 *   Edge       – pushes pixels away from detected edges
 *   Reconstruct– blends displacement back toward (0,0) to undo
 *   Smooth     – box-blurs the displacement map for smoothness
 */

#pragma once

#include "image_buffer.h"
#include <QImage>
#include <QPointF>
#include <memory>
#include <vector>

class QOpenGLShaderProgram;
class QOpenGLFramebufferObject;
class QOpenGLTexture;

namespace artflow {

// ─── Liquify Brush Modes ──────────────────────────────────────────
enum class LiquifyMode {
  Push = 0,
  TwirlCW,
  TwirlCCW,
  Pinch,
  Expand,
  Crystalize,
  Edge,
  Reconstruct,
  Smooth
};

// ─── Displacement Map ─────────────────────────────────────────────
// Stores per-pixel (dx, dy) offsets as 32-bit floats.
struct DisplacementMap {
  int width = 0;
  int height = 0;
  std::vector<float> dx; // displacement X per pixel
  std::vector<float> dy; // displacement Y per pixel

  void resize(int w, int h);
  void clear();

  // Bilinear-interpolated sample
  void sampleAt(float x, float y, float &outDx, float &outDy) const;

  // Index helper (bounds-checked)
  inline int idx(int x, int y) const {
    if (x < 0 || x >= width || y < 0 || y >= height)
      return -1;
    return y * width + x;
  }
};

// ─── Liquify Engine ───────────────────────────────────────────────
class LiquifyEngine {
public:
  LiquifyEngine();
  ~LiquifyEngine();

  // ── Session lifecycle ──
  // Call begin() before any deformation.  Captures a snapshot of the
  // active layer's current pixel data so we can keep re-sampling from
  // the original while accumulating displacement.
  void begin(const ImageBuffer &sourceLayer, int width, int height);

  // Call end() to finalize – bakes the deformed pixels into the output.
  // Returns the deformed image as a QImage (RGBA8888, pre-multiplied).
  QImage end();

  // ── Brush interaction ──
  // Apply a single brush dab at (cx, cy) in canvas coordinates.
  // `prevPos` is the previous dab position (needed for Push direction).
  void applyBrush(float cx, float cy, float prevCx, float prevCy);

  // ── Parameters (set from QML) ──
  void setMode(LiquifyMode mode) { m_mode = mode; }
  LiquifyMode mode() const { return m_mode; }

  void setRadius(float r) { m_radius = r; }
  float radius() const { return m_radius; }

  void setStrength(float s) { m_strength = s; }
  float strength() const { return m_strength; }

  // Morpher blends deformation softly (0 = hard edge, 1 = very soft)
  void setMorpher(float m) { m_morpher = m; }
  float morpher() const { return m_morpher; }

  // ── Live preview ──
  // Generate the deformed image from the current displacement state.
  // This is called frequently to provide real-time feedback.
  QImage renderPreview() const;

  // Get raw displacement map (for potential GPU upload)
  const DisplacementMap &displacementMap() const { return m_dispMap; }

  bool isActive() const { return m_active; }

  // ── GPU path (OpenGL ES 2.0/3.0) ──
  // The displacement map lives in a ping-pong pair of FBOs; each brush dab
  // is one fragment pass (liquify_brush.frag) and the live preview is drawn
  // straight from GPU textures (liquify.frag) — no per-dab CPU readback.

  // Starts/joins the GPU session. Requires a current GL context; returns
  // false (and the engine stays on the Rust/CPU path) when none is current.
  bool primeGpu();
  bool gpuActive() const { return m_gpuSession; }

  // Draws the deformed preview as a screen-space quad. Must be called with
  // the GL context current (inside QPainter::beginNativePainting()).
  // ndcCorners: TL, TR, BL, BR of the canvas rect in normalized device coords.
  void drawPreview(const QPointF ndcCorners[4], float opacity);

  // Discards the session without baking (cancel path).
  void abort();

  // Frees GL objects; call with the GL context current.
  void releaseGpuResources();

private:
  // ── GPU internals ──
  bool ensureGpuResources();
  void applyBrushGpu(float cx, float cy, float prevCx, float prevCy);
  QImage bakeGpu() const;

  bool m_gpuSession = false;       // dabs are accumulating on the GPU
  bool m_dispClearPending = false; // displacement FBOs need a zero-clear
  bool m_sourceDirty = false;      // m_sourceImage needs (re)upload
  float m_dispZero = 0.5f;         // exact encoding zero point (format-dependent)
  QImage m_sourceImage;            // snapshot of the layer at begin()

  QOpenGLShaderProgram *m_brushProgram = nullptr;
  QOpenGLShaderProgram *m_previewProgram = nullptr;
  QOpenGLFramebufferObject *m_dispPing = nullptr; // read
  QOpenGLFramebufferObject *m_dispPong = nullptr; // write
  mutable QOpenGLFramebufferObject *m_bakeFBO = nullptr;
  QOpenGLTexture *m_sourceTex = nullptr;
  // ── State ──
  bool m_active = false;
  LiquifyMode m_mode = LiquifyMode::Push;
  float m_radius = 80.0f;
  float m_strength = 0.6f;
  float m_morpher = 0.0f; // 0..1

  int m_width = 0;
  int m_height = 0;

  // Accumulated displacement field (cache para compatibilidad C++)
  mutable DisplacementMap m_dispMap;

  // Puntero al motor implementado en Rust
  void* m_rustEngine = nullptr;
};

} // namespace artflow
