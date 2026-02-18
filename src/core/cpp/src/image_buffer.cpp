/**
 * ArtFlow Studio - Image Buffer Implementation
 */

#include "../include/image_buffer.h"
#include <algorithm>
#include <cmath>
#include <cstring>

namespace artflow {

// Helper function for C++11/14 compatibility (std::clamp is C++17)
template <typename T> T clampVal(T val, T minVal, T maxVal) {
  if (val < minVal)
    return minVal;
  if (val > maxVal)
    return maxVal;
  return val;
}

ImageBuffer::ImageBuffer(int width, int height)
    : m_width(width), m_height(height) {
  m_data.resize(static_cast<size_t>(width * height * 4), 0);
}

ImageBuffer::~ImageBuffer() = default;

uint8_t *ImageBuffer::pixelAt(int x, int y) {
  if (!isValidCoord(x, y))
    return nullptr;
  return &m_data[pixelIndex(x, y)];
}

const uint8_t *ImageBuffer::pixelAt(int x, int y) const {
  if (!isValidCoord(x, y))
    return nullptr;
  return &m_data[pixelIndex(x, y)];
}

void ImageBuffer::setPixel(int x, int y, uint8_t r, uint8_t g, uint8_t b,
                           uint8_t a) {
  if (!isValidCoord(x, y))
    return;
  size_t idx = pixelIndex(x, y);
  m_data[idx + 0] = r;
  m_data[idx + 1] = g;
  m_data[idx + 2] = b;
  m_data[idx + 3] = a;
}

void ImageBuffer::fill(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
  for (int y = 0; y < m_height; ++y) {
    for (int x = 0; x < m_width; ++x) {
      setPixel(x, y, r, g, b, a);
    }
  }
}

void ImageBuffer::clear() { std::memset(m_data.data(), 0, m_data.size()); }

void ImageBuffer::blendPixel(int x, int y, uint8_t r, uint8_t g, uint8_t b,
                             uint8_t a, bool alphaLock, bool isEraser) {
  if (!isValidCoord(x, y))
    return;

  size_t idx = pixelIndex(x, y);
  uint8_t dstA = m_data[idx + 3];

  if (alphaLock && dstA == 0)
    return;

  if (isEraser) {
    // Out_A = Dst_A * (1 - Src_A)
    // Out_RGB = Dst_RGB * (1 - Src_A)
    uint32_t invAlpha = 255 - a;
    m_data[idx + 0] = (m_data[idx + 0] * invAlpha) / 255;
    m_data[idx + 1] = (m_data[idx + 1] * invAlpha) / 255;
    m_data[idx + 2] = (m_data[idx + 2] * invAlpha) / 255;
    m_data[idx + 3] = (m_data[idx + 3] * invAlpha) / 255;
    return;
  }

  // PREMULTIPLIED BLENDING (Porter-Duff Source-Over)
  // Out_RGB = Src_RGB*Src_A + Dst_RGB * (1 - Src_A)
  // Out_A   = Src_A       + Dst_A   * (1 - Src_A)

  uint32_t srcA = a;
  uint32_t invSrcA = 255 - srcA;

  // Internal data is PREMULTIPLIED.
  // Incoming r,g,b,a are assumed to be STRAIGHT colors to be applied.
  uint32_t srcR = (r * srcA) / 255;
  uint32_t srcG = (g * srcA) / 255;
  uint32_t srcB = (b * srcA) / 255;

  if (alphaLock) {
    // Treat as Source-In practically: only affects RGB, keeps A
    m_data[idx + 0] = clampVal<int>(
        (srcR * dstA / 255) + (m_data[idx + 0] * invSrcA / 255), 0, 255);
    m_data[idx + 1] = clampVal<int>(
        (srcG * dstA / 255) + (m_data[idx + 1] * invSrcA / 255), 0, 255);
    m_data[idx + 2] = clampVal<int>(
        (srcB * dstA / 255) + (m_data[idx + 2] * invSrcA / 255), 0, 255);
  } else {
    m_data[idx + 0] =
        clampVal<int>(srcR + (m_data[idx + 0] * invSrcA) / 255, 0, 255);
    m_data[idx + 1] =
        clampVal<int>(srcG + (m_data[idx + 1] * invSrcA) / 255, 0, 255);
    m_data[idx + 2] =
        clampVal<int>(srcB + (m_data[idx + 2] * invSrcA) / 255, 0, 255);
    m_data[idx + 3] =
        clampVal<int>(srcA + (m_data[idx + 3] * invSrcA) / 255, 0, 255);
  }
}

void ImageBuffer::drawCircle(int cx, int cy, float radius, uint8_t r, uint8_t g,
                             uint8_t b, uint8_t a, float hardness, float grain,
                             bool alphaLock, bool isEraser,
                             const ImageBuffer *mask) {
  // Extend bounds by 1 pixel for anti-aliasing
  int minX = std::max(0, static_cast<int>(cx - radius - 2));
  int maxX = std::min(m_width - 1, static_cast<int>(cx + radius + 2));
  int minY = std::max(0, static_cast<int>(cy - radius - 2));
  int maxY = std::min(m_height - 1, static_cast<int>(cy + radius + 2));

  // Use float center for sub-pixel accuracy
  float fcx = static_cast<float>(cx);
  float fcy = static_cast<float>(cy);

  // For very small brushes, ensure minimum radius
  float effectiveRadius = std::max(0.5f, radius);

  for (int py = minY; py <= maxY; ++py) {
    for (int px = minX; px <= maxX; ++px) {
      // Calculate distance from center with sub-pixel precision
      float dx = static_cast<float>(px) - fcx;
      float dy = static_cast<float>(py) - fcy;
      float dist = std::sqrt(dx * dx + dy * dy);

      // Skip if completely outside
      if (dist > effectiveRadius + 1.0f)
        continue;

      // Calculate normalized distance (0 = center, 1 = edge)
      float normalizedDist = dist / effectiveRadius;

      // ============================================================
      // ANTI-ALIASING: Smooth falloff at the edge
      // ============================================================
      float edgeAlpha = 1.0f;
      if (dist > effectiveRadius - 1.0f) {
        // Smooth transition in the last pixel
        edgeAlpha = std::max(0.0f, effectiveRadius - dist + 1.0f);
        edgeAlpha = std::min(1.0f, edgeAlpha);
      }

      // Skip if completely transparent
      if (edgeAlpha < 0.001f)
        continue;

      // ============================================================
      // HARDNESS FALLOFF
      // ============================================================
      float falloff = 1.0f;
      if (normalizedDist > 0.0f) {
        if (hardness >= 0.99f) {
          // Hard brush: solid until edge
          falloff = (normalizedDist <= 1.0f) ? 1.0f : 0.0f;
        } else if (hardness <= 0.01f) {
          // Very soft brush: linear falloff from center
          falloff = std::max(0.0f, 1.0f - normalizedDist);
          // Apply smooth curve for even softer feel
          falloff = falloff * falloff * (3.0f - 2.0f * falloff);
        } else {
          // Normal hardness: falloff starts at hardness threshold
          if (normalizedDist > hardness) {
            float t = (normalizedDist - hardness) / (1.0f - hardness);
            // Smooth hermite interpolation instead of linear
            falloff = 1.0f - (t * t * (3.0f - 2.0f * t));
          }
        }
      }

      // Clamp falloff
      falloff = std::max(0.0f, std::min(1.0f, falloff));

      // ============================================================
      // GRAIN (TEXTURE NOISE)
      // ============================================================
      float noise = 1.0f;
      if (grain > 0.001f) {
        auto getHash = [](float x, float y) {
          uint32_t h = (static_cast<uint32_t>(x) * 1597334677U) ^
                       (static_cast<uint32_t>(y) * 3812015801U);
          h *= 0x85ebca6b;
          h ^= h >> 13;
          h *= 0xc2b2ae35;
          return static_cast<float>(h & 0xFFFF) / 65535.0f;
        };

        // Multi-octave noise for organic texture
        float n1 = getHash(static_cast<float>(px) / 4.0f,
                           static_cast<float>(py) / 4.0f);
        float n2 = getHash(static_cast<float>(px) / 1.5f,
                           static_cast<float>(py) / 1.5f);
        float randVal = n1 * 0.7f + n2 * 0.3f;

        // High-contrast curve for paper "tooth" feeling
        float grainVal = (randVal - 0.45f) * 3.0f + 0.5f;
        grainVal = std::max(0.0f, std::min(1.0f, grainVal));

        noise = (1.0f - grain) + (grainVal * grain);
      }

      // ============================================================
      // FINAL ALPHA CALCULATION
      // ============================================================
      float finalAlpha = static_cast<float>(a) * falloff * noise * edgeAlpha;
      uint8_t pixelA =
          static_cast<uint8_t>(std::max(0.0f, std::min(255.0f, finalAlpha)));

      // Clipping Mask support
      if (mask) {
        const uint8_t *mP = mask->pixelAt(px, py);
        if (mP) {
          pixelA = static_cast<uint8_t>(pixelA * (mP[3] / 255.0f));
        } else {
          pixelA = 0;
        }
      }

      if (pixelA > 0) {
        blendPixel(px, py, r, g, b, pixelA, alphaLock, isEraser);
      }
    }
  }
}

void ImageBuffer::copyFrom(const ImageBuffer &other) {
  if (m_width != other.m_width || m_height != other.m_height)
    return;
  std::memcpy(m_data.data(), other.m_data.data(), m_data.size());
}

void ImageBuffer::composite(const ImageBuffer &other, int offsetX, int offsetY,
                            float opacity, BlendMode mode,
                            const ImageBuffer *mask) {
  if (opacity <= 0.001f)
    return;

  // Clipping regions
  int startY = std::max(0, -offsetY);
  int endY = std::min(other.height(), m_height - offsetY);
  int startX = std::max(0, -offsetX);
  int endX = std::min(other.width(), m_width - offsetX);

  for (int sy = startY; sy < endY; ++sy) {
    int dy = sy + offsetY;
    uint8_t *dstRow = &m_data[pixelIndex(offsetX + startX, dy)];
    const uint8_t *srcRow = other.pixelAt(startX, sy);

    for (int sx = startX; sx < endX; ++sx) {
      if (srcRow[3] == 0) {
        dstRow += 4;
        srcRow += 4;
        continue;
      }

      // 1. Calculate Source Alpha (Total including layer opacity)
      float sA_f = (srcRow[3] / 255.0f) * opacity;

      // Apply Clipping Mask if present
      if (mask) {
        const uint8_t *mP = mask->pixelAt(sx + offsetX, dy);
        if (mP) {
          sA_f *= (mP[3] / 255.0f);
        } else {
          sA_f = 0;
        }
      }

      if (sA_f <= 0.001f) {
        dstRow += 4;
        srcRow += 4;
        continue;
      }

      // 2. Un-premultiply Source and Destination for correct blend math
      float sR_U = 0, sG_U = 0, sB_U = 0;
      if (srcRow[3] > 0) {
          sR_U = (float)srcRow[0] / srcRow[3];
          sG_U = (float)srcRow[1] / srcRow[3];
          sB_U = (float)srcRow[2] / srcRow[3];
      }
      
      float dA_f = dstRow[3] / 255.0f;
      float dR_U = 0, dG_U = 0, dB_U = 0;
      if (dstRow[3] > 0) {
          dR_U = (float)dstRow[0] / dstRow[3];
          dG_U = (float)dstRow[1] / dstRow[3];
          dB_U = (float)dstRow[2] / dstRow[3];
      }

      // 3. Apply Blend Mode (W3C Standard Formulas)
      // Cs = Source Color (sR_U, sG_U, sB_U)
      // Cb = Backdrop/Dest Color (dR_U, dG_U, dB_U)
      // B(Cb, Cs) = Blend Result
      // Final Color Co = (1 - da) * Cs + (1 - sa) * Cb + sa * da * B(Cb, Cs)
      // Note: This is equivalent to standard Source-Over compositing where the 'source' input to the atomic composite operation
      // is actually the result of the blend function if both pixels are opaque, but handles transparency correctly.

      // We calculate the 'Mixed' component (sa * da * B(Cb, Cs)) first, let's call it BlendedPart.
      // But actually, a simpler way for implementations often is:
      // Co = sa * (1 - da) * Cs + da * (1 - sa) * Cb + sa * da * B(Cb, Cs) ... wait, standard src-over is s + d(1-sa).
      // Let's stick to the official spec:
      // fa = 1; fb = 1 - sa;
      // co = as * Cs * fa + ab * Cb * fb;  <-- This is standard SrcOver.
      //
      // For BLENDING:
      // The generalized formula is:
      // Cr = (1 - ab) * as * Cs + (1 - as) * ab * Cb + as * ab * B(Cb, Cs);
      // We have sA_f (as), dA_f (ab), Source(Cs), Backdrop(Cb).

      float r_blend = 0, g_blend = 0, b_blend = 0;

      if (mode == BlendMode::Normal) {
          r_blend = sR_U; g_blend = sG_U; b_blend = sB_U;
      } else if (mode == BlendMode::Multiply) {
          r_blend = dR_U * sR_U;
          g_blend = dG_U * sG_U;
          b_blend = dB_U * sB_U;
      } else if (mode == BlendMode::Screen) {
          r_blend = dR_U + sR_U - dR_U * sR_U;
          g_blend = dG_U + sG_U - dG_U * sG_U;
          b_blend = dB_U + sB_U - dB_U * sB_U;
      } else if (mode == BlendMode::Overlay) {
          auto overlay = [](float b, float s) {
              return (b < 0.5f) ? (2.0f * b * s) : (1.0f - 2.0f * (1.0f - b) * (1.0f - s));
          };
          r_blend = overlay(dR_U, sR_U);
          g_blend = overlay(dG_U, sG_U);
          b_blend = overlay(dB_U, sB_U);
      } else if (mode == BlendMode::Darken) {
          r_blend = std::min(dR_U, sR_U);
          g_blend = std::min(dG_U, sG_U);
          b_blend = std::min(dB_U, sB_U);
      } else if (mode == BlendMode::Lighten) {
          r_blend = std::max(dR_U, sR_U);
          g_blend = std::max(dG_U, sG_U);
          b_blend = std::max(dB_U, sB_U);
      } else if (mode == BlendMode::ColorDodge) {
          auto dodge = [](float b, float s) {
              if (b == 0.0f) return 0.0f;
              if (s == 1.0f) return 1.0f;
              return std::min(1.0f, b / (1.0f - s));
          };
          r_blend = dodge(dR_U, sR_U);
          g_blend = dodge(dG_U, sG_U);
          b_blend = dodge(dB_U, sB_U);
      } else if (mode == BlendMode::ColorBurn) {
          auto burn = [](float b, float s) {
              if (b == 1.0f) return 1.0f;
              if (s == 0.0f) return 0.0f;
              return 1.0f - std::min(1.0f, (1.0f - b) / s);
          };
          r_blend = burn(dR_U, sR_U);
          g_blend = burn(dG_U, sG_U);
          b_blend = burn(dB_U, sB_U);
      } else if (mode == BlendMode::HardLight) {
          auto hardlight = [](float b, float s) {
              return (s < 0.5f) ? (2.0f * b * s) : (1.0f - 2.0f * (1.0f - b) * (1.0f - s));
          };
          r_blend = hardlight(dR_U, sR_U);
          g_blend = hardlight(dG_U, sG_U);
          b_blend = hardlight(dB_U, sB_U);
      } else if (mode == BlendMode::SoftLight) {
          auto softlight = [](float b, float s) {
              if (s <= 0.5f) return b - (1.0f - 2.0f * s) * b * (1.0f - b);
              float d = (b <= 0.25f) ? (((16.0f * b - 12.0f) * b + 4.0f) * b) : std::sqrt(b);
              return b + (2.0f * s - 1.0f) * (d - b);
          };
          r_blend = softlight(dR_U, sR_U);
          g_blend = softlight(dG_U, sG_U);
          b_blend = softlight(dB_U, sB_U);
      } else if (mode == BlendMode::Difference) {
          r_blend = std::abs(dR_U - sR_U);
          g_blend = std::abs(dG_U - sG_U);
          b_blend = std::abs(dB_U - sB_U);
      } else if (mode == BlendMode::Exclusion) {
          r_blend = dR_U + sR_U - 2.0f * dR_U * sR_U;
          g_blend = dG_U + sG_U - 2.0f * dG_U * sG_U;
          b_blend = dB_U + sB_U - 2.0f * dB_U * sB_U;
      } 
      // HSL Modes
      else if (mode == BlendMode::Hue || mode == BlendMode::Saturation || mode == BlendMode::Color || mode == BlendMode::Luminosity) {
          // Re-use previous helpers, but applied to blend logic
           auto getLum = [](float r, float g, float b) { return 0.3f*r + 0.59f*g + 0.11f*b; };
          auto getSat = [](float r, float g, float b) { return std::max({r,g,b}) - std::min({r,g,b}); };
          auto setSat = [&](float& r, float& g, float& b, float s) {
                float *min_c = &r, *mid_c = &g, *max_c = &b;
                if (*mid_c < *min_c) std::swap(mid_c, min_c);
                if (*max_c < *mid_c) std::swap(max_c, mid_c);
                if (*mid_c < *min_c) std::swap(mid_c, min_c);
                float den = *max_c - *min_c;
                if (den > 1e-6f) { *mid_c = ((*mid_c - *min_c) * s) / den; *max_c = s; }
                else { *mid_c = *max_c = 0; }
                *min_c = 0;
          };
          auto setLum = [&](float& r, float& g, float& b, float l) {
              float d = l - getLum(r, g, b);
              r += d; g += d; b += d;
              float l_new = getLum(r, g, b);
              float n = std::min({r, g, b}), x = std::max({r, g, b});
              if (n < 0.0f) { float f = l_new / (l_new - n + 1e-6f); r = l_new + (r-l_new)*f; g = l_new + (g-l_new)*f; b = l_new + (b-l_new)*f; }
              if (x > 1.0f) { float f = (1.0f-l_new) / (x - l_new + 1e-6f); r = l_new + (r-l_new)*f; g = l_new + (g-l_new)*f; b = l_new + (b-l_new)*f; }
          };

          r_blend = dR_U; g_blend = dG_U; b_blend = dB_U; // Default to backdrop
          if (mode == BlendMode::Hue) {
              float sR_tmp = sR_U, sG_tmp = sG_U, sB_tmp = sB_U; // Use Source Hue
              setSat(sR_tmp, sG_tmp, sB_tmp, getSat(dR_U, dG_U, dB_U)); // Dest Sat
              setLum(sR_tmp, sG_tmp, sB_tmp, getLum(dR_U, dG_U, dB_U)); // Dest Lum
              r_blend = sR_tmp; g_blend = sG_tmp; b_blend = sB_tmp;
          } else if (mode == BlendMode::Saturation) {
               setSat(r_blend, g_blend, b_blend, getSat(sR_U, sG_U, sB_U)); // Source Sat
          } else if (mode == BlendMode::Color) {
               r_blend = sR_U; g_blend = sG_U; b_blend = sB_U; // Source Hue+Sat
               setLum(r_blend, g_blend, b_blend, getLum(dR_U, dG_U, dB_U)); // Dest Lum
          } else if (mode == BlendMode::Luminosity) {
               setLum(r_blend, g_blend, b_blend, getLum(sR_U, sG_U, sB_U)); // Source Lum
          }
      }

      // 4. Compositing Formula: Cr = (1 - ab) * as * Cs + (1 - as) * ab * Cb + as * ab * B(Cb, Cs)
      // Variables: as = sA_f, ab = dA_f, Cs = (sR_U, sG_U, sB_U), Cb = (dR_U, dG_U, dB_U), B = (r_blend...)
      
      float finalR = (1.0f - dA_f) * sA_f * sR_U + (1.0f - sA_f) * dA_f * dR_U + sA_f * dA_f * r_blend;
      float finalG = (1.0f - dA_f) * sA_f * sG_U + (1.0f - sA_f) * dA_f * dG_U + sA_f * dA_f * g_blend;
      float finalB = (1.0f - dA_f) * sA_f * sB_U + (1.0f - sA_f) * dA_f * dR_U + sA_f * dA_f * b_blend; // TYPO CHECK: dR_U -> dB_U
      
      // Fix typo in blue channel above:
      finalB = (1.0f - dA_f) * sA_f * sB_U + (1.0f - sA_f) * dA_f * dB_U + sA_f * dA_f * b_blend;

      float outA = sA_f + dA_f - sA_f * dA_f;

      if (outA > 1e-6f) {
           dstRow[0] = std::clamp<int>(finalR * 255.0f, 0, 255); // Output is premultiplied directly!
           dstRow[1] = std::clamp<int>(finalG * 255.0f, 0, 255); // The formula produced PREMULTIPLIED color.
           dstRow[2] = std::clamp<int>(finalB * 255.0f, 0, 255); // Wait, spec says Cr is premultiplied?
           // "The result color Cr is premultiplied." Yes.
           dstRow[3] = std::clamp<int>(outA * 255.0f, 0, 255);
      } else {
           dstRow[0] = dstRow[1] = dstRow[2] = dstRow[3] = 0;
      }
      
      dstRow += 4;
      srcRow += 4;
    }
  }
}

void ImageBuffer::drawStrokeTextured(float x1, float y1, float x2, float y2,
                                     const ImageBuffer &stamp, float spacing,
                                     float opacity, bool rotate,
                                     float angle_jitter, bool is_watercolor,
                                     const ImageBuffer *paper_texture) {
  float dx = x2 - x1;
  float dy = y2 - y1;
  float dist = std::sqrt(dx * dx + dy * dy);

  if (dist < 0.1f)
    return;

  int steps = clampVal(static_cast<int>(dist / spacing), 1, 1000);

  float stepX = dx / steps;
  float stepY = dy / steps;

  int sWidth = stamp.width();
  int sHeight = stamp.height();
  int sHalfX = sWidth / 2;
  int sHalfY = sHeight / 2;

  // Pre-calculate paper texture dims
  int pW = 0, pH = 0;
  if (paper_texture) {
    pW = paper_texture->width();
    pH = paper_texture->height();
  }

  for (int i = 0; i <= steps; ++i) {
    float cx = x1 + stepX * i;
    float cy = y1 + stepY * i;

    // Jitter? Passed in logic? Assuming handled by caller or simple jitter
    // Implementation detail: Rotation of stamp would require resampling.
    // For V1 performance, we stamp aligned (or handled by rotating coords)

    // Loop over stamp pixels
    // Optimization: Bounding box clipping
    int startX = static_cast<int>(cx - sHalfX);
    int startY = static_cast<int>(cy - sHalfY);

    for (int sy = 0; sy < sHeight; ++sy) {
      for (int sx = 0; sx < sWidth; ++sx) {
        int destX = startX + sx;
        int destY = startY + sy;

        // 1. Boundary Check
        if (!isValidCoord(destX, destY))
          continue;

        // 2. Get Stamp Source Pixel
        const uint8_t *sPixel = stamp.pixelAt(sx, sy);
        uint8_t sA = sPixel[3];
        if (sA == 0)
          continue; // optimization

        // 3. Global Texture Mapping
        float paperMod = 1.0f;
        if (paper_texture) {
          // Seamless tiling
          int px = destX % pW;
          int py = destY % pH;
          // Suppose paper is grayscale (R=G=B)
          const uint8_t *pPixel = paper_texture->pixelAt(px, py);
          float pVal = pPixel[0] / 255.0f;

          if (is_watercolor) {
            paperMod = (1.3f - pVal); // Valley accumulation
          } else {
            paperMod = pVal * 1.5f; // Peak hitting
          }
        }

        // 4. Blend
        // Simple alpha blend for now (replace reading destination for speed if
        // needed, but read is required for mix)
        uint8_t *dPixel = this->pixelAt(destX, destY);

        // Source Alpha with modifications
        float finalAlpha = (sA / 255.0f) * opacity * paperMod;
        if (finalAlpha > 1.0f)
          finalAlpha = 1.0f;

        // Standard Source-Over Blending
        // out = src * alpha + dst * (1 - alpha)
        float a = finalAlpha;
        float invA = 1.0f - a;

        dPixel[0] = static_cast<uint8_t>(sPixel[0] * a + dPixel[0] * invA);
        dPixel[1] = static_cast<uint8_t>(sPixel[1] * a + dPixel[1] * invA);
        dPixel[2] = static_cast<uint8_t>(sPixel[2] * a + dPixel[2] * invA);
        dPixel[3] = static_cast<uint8_t>(
            255 * a + dPixel[3] * invA); // Simplified alpha addition
      }
    }
  }
}

std::vector<uint8_t> ImageBuffer::getBytes() const { return m_data; }

std::unique_ptr<ImageBuffer>
ImageBuffer::fromBytes(const std::vector<uint8_t> &bytes, int width,
                       int height) {
  auto buffer = std::make_unique<ImageBuffer>(width, height);
  if (bytes.size() == buffer->m_data.size()) {
    std::memcpy(buffer->m_data.data(), bytes.data(), bytes.size());
  }
  return buffer;
}

} // namespace artflow
