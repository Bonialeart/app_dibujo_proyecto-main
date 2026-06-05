#include "../include/brush_engine.h"
#include "stroke_renderer.h"
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <fstream>
#include <QOpenGLFramebufferObject>
#include <QOpenGLPaintDevice>
#include <QFileInfo>
#include <QImage>
#include <QMap>
#include <QOpenGLTexture>
#include <QPaintEngine>
#include <QPainter>
#include <QPointF>
#include <QString>
#include <QStringList>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <vector>

namespace artflow {

// Global texture cache (Simple implementation)
static QMap<QString, uint32_t> g_textureCache;
static std::vector<QOpenGLTexture *> g_textures; // To manage lifetime

uint32_t BrushEngine::loadTexture(const QString &name, bool isTip) {
  QString cacheKey = name + (isTip ? "_tip" : "_grain");
  if (g_textureCache.contains(cacheKey))
    return g_textureCache[cacheKey];

  // First, check if name is already a valid absolute or relative path
  QString path;
  bool found = false;
  if (QFile::exists(name)) {
    path = name;
    found = true;
  } else {
    // Try multiple paths (searching up to root from executable or CWD)
    QStringList searchPaths;
    searchPaths << "assets/textures/" + name;
    searchPaths << "assets/brushes/tips/" + name;
    searchPaths << "assets/brushes/" + name;
    searchPaths << "../assets/textures/" + name;
    searchPaths << "../assets/brushes/tips/" + name;
    searchPaths << "../assets/brushes/" + name;
    searchPaths << "../../assets/textures/" + name;
    searchPaths << "../../assets/brushes/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/assets/textures/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/assets/brushes/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/../assets/textures/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/../assets/brushes/" + name;
    searchPaths << "src/assets/textures/" + name;
    searchPaths << ":/textures/" + name;

    for (const QString &p : searchPaths) {
      if (QFile::exists(p)) {
        path = p;
        found = true;
        break;
      }
    }
  }

  qDebug() << "BrushEngine: Loading texture:" << name << "Found:" << found
           << "Path:" << path;

  QImage img;
  if (found) {
    img.load(path);
  }

  if (img.isNull()) {
    qDebug() << "Texture failed to load or NOT found:" << name
             << ". Generating soft circle fallback.";
    img = QImage(512, 512, QImage::Format_RGBA8888);
    img.fill(Qt::transparent);

    // Procedural Soft Circle fallback
    for (int y = 0; y < 512; ++y) {
      for (int x = 0; x < 512; ++x) {
        float dx = (x - 256) / 256.0f;
        float dy = (y - 256) / 256.0f;
        float dist = std::sqrt(dx * dx + dy * dy);
        if (dist < 1.0f) {
          int v = static_cast<int>(255 * (1.0f - std::pow(dist, 2.0f)));
          v = std::max(0, std::min(255, v));
          img.setPixel(x, y, qRgba(v, v, v, v));
        }
      }
    }
  }

  if (!img.isNull() && img.hasAlphaChannel()) {
    double totalLum = 0.0;
    int count = 0;
    for (int y = 0; y < img.height(); ++y) {
      for (int x = 0; x < img.width(); ++x) {
        QRgb px = img.pixel(x, y);
        int a = qAlpha(px);
        if (a > 10) {
          double lum = 0.299 * qRed(px) + 0.587 * qGreen(px) + 0.114 * qBlue(px);
          totalLum += lum;
          count++;
        }
      }
    }
    double avgLum = count > 0 ? (totalLum / count) : 255.0;
    if (avgLum < 128.0) {
      qDebug() << "BrushEngine: Detected dark brush tip/grain texture on transparent background. Converting to white.";
      for (int y = 0; y < img.height(); ++y) {
        for (int x = 0; x < img.width(); ++x) {
          QRgb px = img.pixel(x, y);
          int a = qAlpha(px);
          img.setPixel(x, y, qRgba(255, 255, 255, a));
        }
      }
    }
  }

  // Convert to format OpenGL understands well
  QImage glImg =
      img.convertToFormat(QImage::Format_RGBA8888).flipped(Qt::Vertical);

  QOpenGLTexture *tex = new QOpenGLTexture(glImg);
  tex->setMinificationFilter(QOpenGLTexture::LinearMipMapLinear);
  tex->setMagnificationFilter(QOpenGLTexture::Linear);
  tex->setWrapMode(QOpenGLTexture::Repeat);
  tex->generateMipMaps();

  uint32_t id = tex->textureId();
  g_textureCache[cacheKey] = id;
  g_textures.push_back(tex);
  return id;
}

// Helper to get/load texture image for Raster mode
static QImage getTextureImage(const QString &name, bool isTip = true) {
  static QMap<QString, QImage> s_imageTextureCache;
  QString cacheKey = name + (isTip ? "_tip" : "_grain");
  if (s_imageTextureCache.contains(cacheKey))
    return s_imageTextureCache[cacheKey];

  QString path = name; // Primero verificar si es ruta absoluta
  bool found = false;
  if (QFile::exists(path)) {
    found = true;
  } else {
    // Try multiple paths (searching up to root from executable or CWD)
    QStringList searchPaths;
    searchPaths << "assets/textures/" + name;
    searchPaths << "assets/brushes/tips/" + name;
    searchPaths << "assets/brushes/" + name;
    searchPaths << "../assets/textures/" + name;
    searchPaths << "../assets/brushes/tips/" + name;
    searchPaths << "../assets/brushes/" + name;
    searchPaths << "../../assets/textures/" + name;
    searchPaths << "../../assets/brushes/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/assets/textures/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/assets/brushes/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/../assets/textures/" + name;
    searchPaths << QCoreApplication::applicationDirPath() +
                       "/../assets/brushes/" + name;
    searchPaths << "src/assets/textures/" + name;
    searchPaths << ":/textures/" + name;

    for (const QString &p : searchPaths) {
      if (QFile::exists(p)) {
        path = p;
        found = true;
        break;
      }
    }
  }

  qDebug() << "BrushEngine: getTextureImage Loading:" << name << "Found:" << found << "from" << path;

  QImage img(path);
  if (img.isNull()) {
    img = QImage(256, 256, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    QPainter p(&img);
    for (int i = 0; i < 1000; i++) {
      p.setPen(QColor(0, 0, 0, rand() % 50 + 20));
      p.drawPoint(rand() % 256, rand() % 256);
    }
  } else {
    bool hasAlpha = img.hasAlphaChannel();
    if (hasAlpha) {
      double totalLum = 0.0;
      int count = 0;
      for (int y = 0; y < img.height(); ++y) {
        for (int x = 0; x < img.width(); ++x) {
          QRgb px = img.pixel(x, y);
          int a = qAlpha(px);
          if (a > 10) {
            double lum = 0.299 * qRed(px) + 0.587 * qGreen(px) + 0.114 * qBlue(px);
            totalLum += lum;
            count++;
          }
        }
      }
      double avgLum = count > 0 ? (totalLum / count) : 255.0;
      if (avgLum < 128.0) {
        qDebug() << "BrushEngine: getTextureImage detected dark brush tip/grain texture on transparent background. Converting to white.";
        for (int y = 0; y < img.height(); ++y) {
          for (int x = 0; x < img.width(); ++x) {
            QRgb px = img.pixel(x, y);
            int a = qAlpha(px);
            img.setPixel(x, y, qRgba(255, 255, 255, a));
          }
        }
      }
    }

    img = img.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    for (int y = 0; y < img.height(); ++y) {
      QRgb *scanline = reinterpret_cast<QRgb *>(img.scanLine(y));
      for (int x = 0; x < img.width(); ++x) {
        QRgb pixel = scanline[x];
        int luma = qGray(pixel);
        int a = hasAlpha ? qAlpha(pixel) : 255;
        // Luma as opacity: bright = opaque brush shape, dark = transparent
        int finalAlpha = (luma * a) / 255;
        scanline[x] = qRgba(finalAlpha, finalAlpha, finalAlpha, finalAlpha);
      }
    }
  }
  if (!isTip) {
    img = img.convertToFormat(QImage::Format_Grayscale8);
  }

  s_imageTextureCache[cacheKey] = img;
  return img;
}

// Helper to draw a tinted tip in Raster mode
static void paintTipRaster(QPainter *painter, const QPointF &point, float size,
                           float opacity, const QColor &color, float rotation,
                           const QString &texName) {
  QImage tipImg = getTextureImage(texName, true);
  if (tipImg.isNull())
    return;

  // Cache key: we cache the tinted image for the current texture and color to avoid
  // expensive scaling, cropping, and QPainter setup on every single dab.
  static QString cachedTexName;
  static QColor cachedColor;
  static QImage cachedTintedImg;

  if (cachedTexName != texName || cachedColor != color || cachedTintedImg.isNull()) {
    cachedTexName = texName;
    cachedColor = color;

    // Crop center square of the texture once if it's not square
    QImage base = tipImg;
    if (base.width() != base.height()) {
      int s = std::min(base.width(), base.height());
      int cx = (base.width() - s) / 2;
      int cy = (base.height() - s) / 2;
      base = base.copy(cx, cy, s, s);
    }

    cachedTintedImg = base.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    QPainter p(&cachedTintedImg);
    p.setCompositionMode(QPainter::CompositionMode_SourceIn);
    p.fillRect(cachedTintedImg.rect(), color);
    p.end();
  }

  painter->save();
  painter->setOpacity(opacity);
  painter->translate(point);
  painter->rotate(rotation * 180.0f / 3.14159f); // rad to deg

  QRectF rect(-size / 2.0, -size / 2.0, size, size);

  // Draw the pre-tinted image, letting QPainter handle the scaling automatically
  painter->drawImage(rect, cachedTintedImg);
  painter->restore();
}

static float getGrainValueAt(const QImage &grainImg, float canvasX, float canvasY, const BrushSettings &settings) {
  if (grainImg.isNull()) return 1.0f;

  float scale = std::max(0.1f, settings.textureScale);
  float gx = canvasX / (5.0f * scale);
  float gy = canvasY / (5.0f * scale);
  if (settings.grainRotation != 0.0f) {
    float cosR = std::cos(settings.grainRotation);
    float sinR = std::sin(settings.grainRotation);
    float rx = gx * cosR - gy * sinR;
    float ry = gx * sinR + gy * cosR;
    gx = rx;
    gy = ry;
  }
  gx *= grainImg.width();
  gy *= grainImg.height();

  int ix = static_cast<int>(std::floor(gx)) % grainImg.width();
  int iy = static_cast<int>(std::floor(gy)) % grainImg.height();
  if (ix < 0) ix += grainImg.width();
  if (iy < 0) iy += grainImg.height();

  QRgb px = grainImg.pixel(ix, iy);
  float grainVal = 1.0f;
  
  int alpha = qAlpha(px);
  if (alpha < 252) {
    grainVal = alpha / 255.0f;
  } else {
    grainVal = (0.299f * qRed(px) + 0.587f * qGreen(px) + 0.114f * qBlue(px)) / 255.0f;
  }

  if (settings.invertGrain) {
    grainVal = 1.0f - grainVal;
  }

  float bright = settings.grainBright / 100.0f;
  float contrast = settings.grainCon / 100.0f;
  float factor = (1.0f + contrast);
  grainVal = std::clamp((grainVal - 0.5f) * factor + 0.5f + bright, 0.0f, 1.0f);

  return grainVal;
}

static float getDualGrainValueAt(const QImage &grainImg, float canvasX, float canvasY, const BrushSettings &settings) {
  if (grainImg.isNull()) return 1.0f;

  float scale = std::max(0.1f, settings.dualTextureScale);
  float gx = canvasX / (5.0f * scale);
  float gy = canvasY / (5.0f * scale);
  if (settings.dualGrainRotation != 0.0f) {
    float cosR = std::cos(settings.dualGrainRotation);
    float sinR = std::sin(settings.dualGrainRotation);
    float rx = gx * cosR - gy * sinR;
    float ry = gx * sinR + gy * cosR;
    gx = rx;
    gy = ry;
  }
  gx *= grainImg.width();
  gy *= grainImg.height();

  int ix = static_cast<int>(std::floor(gx)) % grainImg.width();
  int iy = static_cast<int>(std::floor(gy)) % grainImg.height();
  if (ix < 0) ix += grainImg.width();
  if (iy < 0) iy += grainImg.height();

  QRgb px = grainImg.pixel(ix, iy);
  float grainVal = 1.0f;
  
  int alpha = qAlpha(px);
  if (alpha < 252) {
    grainVal = alpha / 255.0f;
  } else {
    grainVal = (0.299f * qRed(px) + 0.587f * qGreen(px) + 0.114f * qBlue(px)) / 255.0f;
  }

  if (settings.invertDualGrain) {
    grainVal = 1.0f - grainVal;
  }

  float bright = settings.dualGrainBright / 100.0f;
  float contrast = settings.dualGrainCon / 100.0f;
  float factor = (1.0f + contrast);
  grainVal = std::clamp((grainVal - 0.5f) * factor + 0.5f + bright, 0.0f, 1.0f);

  return grainVal;
}

static void paintTexturedDabRaster(QPainter *painter, const QPointF &point, float size,
                                   float opacity, const QColor &color, float rotation,
                                   const BrushSettings &settings, const QImage &grainImg,
                                   const QImage &dualGrainImg) {
  QImage tipImg;
  if (!settings.tipTextureName.isEmpty()) {
    tipImg = getTextureImage(settings.tipTextureName, true);
  }

  int finalSize = std::max(1, static_cast<int>(std::ceil(size)));
  finalSize = std::min(1024, finalSize);

  if (tipImg.isNull()) {
    tipImg = QImage(finalSize, finalSize, QImage::Format_ARGB32);
    tipImg.fill(Qt::transparent);

    uint32_t *tipBits = reinterpret_cast<uint32_t*>(tipImg.bits());
    int tipStride = tipImg.bytesPerLine() / 4;

    float center = finalSize / 2.0f;
    float radius = size / 2.0f;
    float hardness = settings.hardness;

    for (int y = 0; y < finalSize; ++y) {
      float dy = y - center;
      float dy2 = dy * dy;
      uint32_t *row = tipBits + y * tipStride;
      for (int x = 0; x < finalSize; ++x) {
        float dx = x - center;
        float dist2 = dx * dx + dy2;
        float radius2 = radius * radius;
        if (dist2 <= radius2) {
          float dist = std::sqrt(dist2);
          float d = dist / radius;
          float val = 1.0f;
          if (hardness < 0.99f) {
            float core = hardness;
            if (d > core) {
              float t = (d - core) / (1.0f - core);
              val = 0.5f * (1.0f + std::cos(t * 3.14159265f));
              val = std::pow(val, 0.75f);
            }
          }
          int a = static_cast<int>(255 * val);
          row[x] = 0x00FFFFFF | (static_cast<uint32_t>(a) << 24);
        }
      }
    }
  } else {
    if (tipImg.width() != tipImg.height()) {
      int s = std::min(tipImg.width(), tipImg.height());
      int cx = (tipImg.width() - s) / 2;
      int cy = (tipImg.height() - s) / 2;
      tipImg = tipImg.copy(cx, cy, s, s);
    }
    QImage scaledTip(finalSize, finalSize, QImage::Format_ARGB32);
    scaledTip.fill(Qt::transparent);

    QPainter p(&scaledTip);
    p.setRenderHint(QPainter::Antialiasing);
    p.setRenderHint(QPainter::SmoothPixmapTransform);
    p.translate(finalSize / 2.0f, finalSize / 2.0f);
    p.rotate(rotation * 180.0f / 3.14159265f);
    p.drawImage(QRectF(-size / 2.0f, -size / 2.0f, size, size), tipImg, tipImg.rect());
    p.end();

    tipImg = scaledTip;
  }

  float startX = point.x() - finalSize / 2.0f;
  float startY = point.y() - finalSize / 2.0f;

  bool dualGrainApplied = false;

  QImage scaledDualTip(finalSize, finalSize, QImage::Format_ARGB32);
  scaledDualTip.fill(Qt::transparent);

  bool hasDualTip = (settings.dualTipEnabled && !settings.dualTipTextureName.isEmpty());
  if (hasDualTip) {
    QImage dualTipImg = getTextureImage(settings.dualTipTextureName, true);
    if (!dualTipImg.isNull()) {
      if (dualTipImg.width() != dualTipImg.height()) {
        int s = std::min(dualTipImg.width(), dualTipImg.height());
        int cx = (dualTipImg.width() - s) / 2;
        int cy = (dualTipImg.height() - s) / 2;
        dualTipImg = dualTipImg.copy(cx, cy, s, s);
      }
      QPainter p(&scaledDualTip);
      p.setRenderHint(QPainter::Antialiasing);
      p.setRenderHint(QPainter::SmoothPixmapTransform);
      p.translate(finalSize / 2.0f, finalSize / 2.0f);
      p.rotate((rotation + settings.dualTipRotation) * 180.0f / 3.14159265f);
      float dualSize = size * settings.dualTipScale;
      p.drawImage(QRectF(-dualSize / 2.0f, -dualSize / 2.0f, dualSize, dualSize), dualTipImg, dualTipImg.rect());
      p.end();
    }
  }

  // Ensure grain textures are in Grayscale8 for fast 1-byte direct bits access
  QImage localGrainImg = grainImg;
  if (!localGrainImg.isNull() && localGrainImg.format() != QImage::Format_Grayscale8) {
    localGrainImg = localGrainImg.convertToFormat(QImage::Format_Grayscale8);
  }
  QImage localDualGrainImg = dualGrainImg;
  if (!localDualGrainImg.isNull() && localDualGrainImg.format() != QImage::Format_Grayscale8) {
    localDualGrainImg = localDualGrainImg.convertToFormat(QImage::Format_Grayscale8);
  }

  if (hasDualTip && settings.useDualTexture && !localDualGrainImg.isNull()) {
    // 1. Modulate main tip by main grain
    if (settings.useTexture && !localGrainImg.isNull()) {
      uint32_t *tipBits = reinterpret_cast<uint32_t*>(tipImg.bits());
      int tipStride = tipImg.bytesPerLine() / 4;
      const uchar *grainBits = localGrainImg.constBits();
      int grainStride = localGrainImg.bytesPerLine();
      int grainW = localGrainImg.width();
      int grainH = localGrainImg.height();

      float scale = std::max(0.1f, settings.textureScale);
      float invScaleW = grainW / (5.0f * scale);
      float invScaleH = grainH / (5.0f * scale);

      float cosR = std::cos(settings.grainRotation);
      float sinR = std::sin(settings.grainRotation);

      float dx_tx = cosR * invScaleW;
      float dx_ty = sinR * invScaleH;

      float bright = settings.grainBright / 100.0f;
      float contrast = settings.grainCon / 100.0f;
      float f = (1.0f + contrast);

      // Pre-compute LUT
      float grainLUT[256];
      for (int i = 0; i < 256; ++i) {
        float val = i / 255.0f;
        if (settings.invertGrain) {
          val = 1.0f - val;
        }
        val = std::clamp((val - 0.5f) * f + 0.5f + bright, 0.0f, 1.0f);
        grainLUT[i] = val;
      }

      float threshold = (1.0f - opacity) * settings.textureIntensity;
      float textureIntensity = settings.textureIntensity;
      bool isSubtract = (settings.grainBlendMode == "subtract");
      bool isThreshold = (settings.grainBlendMode == "threshold" || settings.grainBlendMode == "reveal");

      for (int y = 0; y < finalSize; ++y) {
        float canvasY = startY + y;
        float tx_row = startX * cosR * invScaleW - canvasY * sinR * invScaleW;
        float ty_row = startX * sinR * invScaleH + canvasY * cosR * invScaleH;

        uint32_t *tipRow = tipBits + y * tipStride;

        float tx = tx_row;
        float ty = ty_row;

        for (int x = 0; x < finalSize; ++x) {
          uint32_t &px = tipRow[x];
          int alpha = (px >> 24) & 0xFF;
          if (alpha > 0) {
            int px_idx = static_cast<int>(std::floor(tx)) % grainW;
            if (px_idx < 0) px_idx += grainW;
            int py = static_cast<int>(std::floor(ty)) % grainH;
            if (py < 0) py += grainH;

            int grayVal = grainBits[py * grainStride + px_idx];
            float grainVal = grainLUT[grayVal];

            float grainFactor = 1.0f;
            if (isSubtract) {
              grainFactor = std::clamp(1.0f - (1.0f - grainVal) * textureIntensity, 0.0f, 1.0f);
            } else if (isThreshold) {
              float t = std::clamp((grainVal - (threshold - 0.05f)) * 10.0f, 0.0f, 1.0f);
              grainFactor = t * t * (3.0f - 2.0f * t);
            } else {
              grainFactor = (1.0f - textureIntensity) + grainVal * textureIntensity;
            }

            int newAlpha = std::clamp(static_cast<int>(alpha * grainFactor), 0, 255);
            px = (px & 0x00FFFFFF) | (static_cast<uint32_t>(newAlpha) << 24);
          }
          tx += dx_tx;
          ty += dx_ty;
        }
      }
    }

    // 2. Modulate dual tip by dual grain
    uint32_t *dualBits = reinterpret_cast<uint32_t*>(scaledDualTip.bits());
    int dualStride = scaledDualTip.bytesPerLine() / 4;
    const uchar *dualGrainBits = localDualGrainImg.constBits();
    int dgStride = localDualGrainImg.bytesPerLine();
    int dgW = localDualGrainImg.width();
    int dgH = localDualGrainImg.height();

    float dgScale = std::max(0.1f, settings.dualTextureScale);
    float dgInvScaleW = dgW / (5.0f * dgScale);
    float dgInvScaleH = dgH / (5.0f * dgScale);

    float dgCosR = std::cos(settings.dualGrainRotation);
    float dgSinR = std::sin(settings.dualGrainRotation);

    float dgdx_tx = dgCosR * dgInvScaleW;
    float dgdx_ty = dgSinR * dgInvScaleH;

    float dgBright = settings.dualGrainBright / 100.0f;
    float dgContrast = settings.dualGrainCon / 100.0f;
    float dgF = (1.0f + dgContrast);

    // Pre-compute dual grain LUT
    float dualGrainLUT[256];
    for (int i = 0; i < 256; ++i) {
      float val = i / 255.0f;
      if (settings.invertDualGrain) {
        val = 1.0f - val;
      }
      val = std::clamp((val - 0.5f) * dgF + 0.5f + dgBright, 0.0f, 1.0f);
      dualGrainLUT[i] = val;
    }

    float dgThreshold = (1.0f - opacity) * settings.dualTextureIntensity;
    float dgIntensity = settings.dualTextureIntensity;
    bool isDgSubtract = (settings.dualGrainBlendMode == 1);
    bool isDgThreshold = (settings.dualGrainBlendMode == 2);

    for (int y = 0; y < finalSize; ++y) {
      float canvasY = startY + y;
      float tx_row = startX * dgCosR * dgInvScaleW - canvasY * dgSinR * dgInvScaleW;
      float ty_row = startX * dgSinR * dgInvScaleH + canvasY * dgCosR * dgInvScaleH;

      uint32_t *dualRow = dualBits + y * dualStride;

      float tx = tx_row;
      float ty = ty_row;

      for (int x = 0; x < finalSize; ++x) {
        uint32_t &px = dualRow[x];
        int alpha = (px >> 24) & 0xFF;
        if (alpha > 0) {
          int px_idx = static_cast<int>(std::floor(tx)) % dgW;
          if (px_idx < 0) px_idx += dgW;
          int py = static_cast<int>(std::floor(ty)) % dgH;
          if (py < 0) py += dgH;

          int grayVal = dualGrainBits[py * dgStride + px_idx];
          float grainVal = dualGrainLUT[grayVal];

          float dualGrainFactor = 1.0f;
          if (isDgSubtract) {
            dualGrainFactor = std::clamp(1.0f - (1.0f - grainVal) * dgIntensity, 0.0f, 1.0f);
          } else if (isDgThreshold) {
            float t = std::clamp((grainVal - (dgThreshold - 0.05f)) * 10.0f, 0.0f, 1.0f);
            dualGrainFactor = t * t * (3.0f - 2.0f * t);
          } else {
            dualGrainFactor = (1.0f - dgIntensity) + grainVal * dgIntensity;
          }

          int newAlpha = std::clamp(static_cast<int>(alpha * dualGrainFactor), 0, 255);
          px = (px & 0x00FFFFFF) | (static_cast<uint32_t>(newAlpha) << 24);
        }
        tx += dgdx_tx;
        ty += dgdx_ty;
      }
    }

    dualGrainApplied = true;
  }

  if (hasDualTip) {
    float flow = settings.dualTipFlow;
    uint32_t *tipBits = reinterpret_cast<uint32_t*>(tipImg.bits());
    int tipStride = tipImg.bytesPerLine() / 4;
    const uint32_t *dualBits = reinterpret_cast<const uint32_t*>(scaledDualTip.constBits());
    int dualStride = scaledDualTip.bytesPerLine() / 4;

    bool isMask = (settings.dualTipBlendMode == "mask" || settings.dualTipBlendMode == "subtract");
    bool isAdd = (settings.dualTipBlendMode == "add");
    bool isHeight = (settings.dualTipBlendMode == "height_linear" || settings.dualTipBlendMode == "height");

    for (int y = 0; y < finalSize; ++y) {
      uint32_t *tipRow = tipBits + y * tipStride;
      const uint32_t *dualRow = dualBits + y * dualStride;

      for (int x = 0; x < finalSize; ++x) {
        uint32_t &pxMain = tipRow[x];
        uint32_t pxDual = dualRow[x];
        int alphaMain = (pxMain >> 24) & 0xFF;
        int alphaDual = (pxDual >> 24) & 0xFF;

        float mainVal = alphaMain / 255.0f;
        float dualVal = alphaDual / 255.0f;
        float resultVal = mainVal;

        if (isMask) {
          resultVal = mainVal * ((1.0f - flow) + flow * (1.0f - dualVal));
        } else if (isAdd) {
          resultVal = std::clamp(mainVal + dualVal * flow, 0.0f, 1.0f);
        } else if (isHeight) {
          resultVal = std::clamp(mainVal + (dualVal - 1.0f) * flow, 0.0f, 1.0f);
        } else { // multiply
          resultVal = mainVal * ((1.0f - flow) + flow * dualVal);
        }

        int newAlpha = std::clamp(static_cast<int>(resultVal * 255.0f + 0.5f), 0, 255);
        uint32_t rgb = pxMain & 0x00FFFFFF;
        if (rgb == 0) {
          rgb = pxDual & 0x00FFFFFF;
        }
        pxMain = rgb | (static_cast<uint32_t>(newAlpha) << 24);
      }
    }
  }

  if (!dualGrainApplied && settings.useTexture && !localGrainImg.isNull()) {
    uint32_t *tipBits = reinterpret_cast<uint32_t*>(tipImg.bits());
    int tipStride = tipImg.bytesPerLine() / 4;
    const uchar *grainBits = localGrainImg.constBits();
    int grainStride = localGrainImg.bytesPerLine();
    int grainW = localGrainImg.width();
    int grainH = localGrainImg.height();

    float scale = std::max(0.1f, settings.textureScale);
    float invScaleW = grainW / (5.0f * scale);
    float invScaleH = grainH / (5.0f * scale);

    float cosR = std::cos(settings.grainRotation);
    float sinR = std::sin(settings.grainRotation);

    float dx_tx = cosR * invScaleW;
    float dx_ty = sinR * invScaleH;

    float bright = settings.grainBright / 100.0f;
    float contrast = settings.grainCon / 100.0f;
    float f = (1.0f + contrast);

    // Pre-compute LUT
    float grainLUT[256];
    for (int i = 0; i < 256; ++i) {
      float val = i / 255.0f;
      if (settings.invertGrain) {
        val = 1.0f - val;
      }
      val = std::clamp((val - 0.5f) * f + 0.5f + bright, 0.0f, 1.0f);
      grainLUT[i] = val;
    }

    float threshold = (1.0f - opacity) * settings.textureIntensity;
    float textureIntensity = settings.textureIntensity;
    bool isSubtract = (settings.grainBlendMode == "subtract");
    bool isThreshold = (settings.grainBlendMode == "threshold" || settings.grainBlendMode == "reveal");

    for (int y = 0; y < finalSize; ++y) {
      float canvasY = startY + y;
      float tx_row = startX * cosR * invScaleW - canvasY * sinR * invScaleW;
      float ty_row = startX * sinR * invScaleH + canvasY * cosR * invScaleH;

      uint32_t *tipRow = tipBits + y * tipStride;

      float tx = tx_row;
      float ty = ty_row;

      for (int x = 0; x < finalSize; ++x) {
        uint32_t &px = tipRow[x];
        int alpha = (px >> 24) & 0xFF;
        if (alpha > 0) {
          int px_idx = static_cast<int>(std::floor(tx)) % grainW;
          if (px_idx < 0) px_idx += grainW;
          int py = static_cast<int>(std::floor(ty)) % grainH;
          if (py < 0) py += grainH;

          int grayVal = grainBits[py * grainStride + px_idx];
          float grainVal = grainLUT[grayVal];

          float grainFactor = 1.0f;
          if (isSubtract) {
            grainFactor = std::clamp(1.0f - (1.0f - grainVal) * textureIntensity, 0.0f, 1.0f);
          } else if (isThreshold) {
            float t = std::clamp((grainVal - (threshold - 0.05f)) * 10.0f, 0.0f, 1.0f);
            grainFactor = t * t * (3.0f - 2.0f * t);
          } else {
            grainFactor = (1.0f - textureIntensity) + grainVal * textureIntensity;
          }

          int newAlpha = std::clamp(static_cast<int>(alpha * grainFactor), 0, 255);
          px = (px & 0x00FFFFFF) | (static_cast<uint32_t>(newAlpha) << 24);
        }
        tx += dx_tx;
        ty += dx_ty;
      }
    }
  }

  QImage tintedImg = tipImg.convertToFormat(QImage::Format_ARGB32_Premultiplied);
  QPainter tintPainter(&tintedImg);
  tintPainter.setCompositionMode(QPainter::CompositionMode_SourceIn);
  tintPainter.fillRect(tintedImg.rect(), color);
  tintPainter.end();

  painter->save();
  painter->setOpacity(opacity);
  painter->drawImage(point - QPointF(finalSize / 2.0f, finalSize / 2.0f), tintedImg);
  painter->restore();
}

BrushEngine::BrushEngine() {}
BrushEngine::~BrushEngine() {
  if (m_renderer)
    delete m_renderer;
}

void BrushEngine::paintStroke(QPainter *painter, const QPointF &lastPoint,
                              const QPointF &currentPoint, float pressure,
                              const BrushSettings &settings, float tilt,
                              float velocity, uint32_t canvasTexId,
                              float wetness, float dilution, float smudge,
                              QOpenGLFramebufferObject *pingFBO,
                              QOpenGLFramebufferObject *pongFBO) {
  if (!painter)
    return;

  m_lastPos = currentPoint;

  // 1. Calculate Dynamics
  float effectivePressure = pressure;

  // Velocity Influence (Mouse pressure fallback)
  if (settings.velocityDynamics > 0.01f && velocity > 0.1f) {
    // High velocity = lower pressure (thinner stroke)
    // Reference: 1.0 - (velocity / 2000.0)
    float vPressure =
        std::max(0.1f, std::min(1.0f, 1.0f - (velocity / 2000.0f)));
    effectivePressure = effectivePressure + (vPressure - effectivePressure) *
                                                settings.velocityDynamics;
  }

  if (!settings.dynamicsEnabled) {
    effectivePressure = 1.0f;
  }

  bool isOpenGL = (QOpenGLContext::currentContext() != nullptr &&
                   (painter->device()->devType() == 10 || // QInternal::OpenGL
                    painter->device()->devType() == 12 || // QInternal::QuickPaintNode
                    dynamic_cast<QOpenGLPaintDevice*>(painter->device()) != nullptr ||
                    (painter->paintEngine() &&
                     (painter->paintEngine()->type() == QPaintEngine::OpenGL2 ||
                      painter->paintEngine()->type() == QPaintEngine::OpenGL))));

  static bool hasLoggedMode = false;
  if (!hasLoggedMode) {
    qDebug() << "BrushEngine: paintStroke mode:"
             << (isOpenGL ? "OpenGL" : "Raster")
             << "devType:" << painter->device()->devType()
             << "paintEngineType:" << (painter->paintEngine() ? painter->paintEngine()->type() : -1)
             << "glContext:" << (QOpenGLContext::currentContext() != nullptr)
             << "dynamicCast:" << (dynamic_cast<QOpenGLPaintDevice*>(painter->device()) != nullptr);
    hasLoggedMode = true;
  }

  if (isOpenGL) {
    // === LOAD TEXTURES (lazy, cached) ===
    uint32_t grainTexID = settings.grainTextureID;
    uint32_t tipTexID = settings.tipTextureID;
    uint32_t dualTipTexID = settings.dualTipTextureID;
    uint32_t dualGrainTexID = settings.dualGrainTextureID;

    // Load grain texture if needed
    if (settings.useTexture && grainTexID == 0 &&
        !settings.textureName.isEmpty()) {
      grainTexID = loadTexture(settings.textureName, false);
    }

    // Load tip texture if needed
    if (tipTexID == 0 && !settings.tipTextureName.isEmpty()) {
      tipTexID = loadTexture(settings.tipTextureName, true);
    }

    // Load dual tip texture if needed
    if (settings.dualTipEnabled && dualTipTexID == 0 &&
        !settings.dualTipTextureName.isEmpty()) {
      dualTipTexID = loadTexture(settings.dualTipTextureName, true);
    }

    // Load dual grain texture if needed
    if (settings.useDualTexture && dualGrainTexID == 0 &&
        !settings.dualTextureName.isEmpty()) {
      dualGrainTexID = loadTexture(settings.dualTextureName, false);
    }

    bool hasGrain = (grainTexID != 0 && settings.useTexture);
    bool hasTip = (tipTexID != 0);
    bool hasDualTip = (dualTipTexID != 0 && settings.dualTipEnabled);
    bool hasDualGrain = (dualGrainTexID != 0 && settings.useDualTexture);

    // DEBUG: trace grain state at draw time
    static int grainDbgCount = 0;
    if (grainDbgCount++ % 10 == 0) {
      std::ofstream logFile("e:/Programacion/Rescate_Proyecto/grain_debug_cpp.txt", std::ios::app);
      if (logFile.is_open()) {
        logFile << "[GRAIN-DEBUG] useTexture: " << settings.useTexture
                << " | textureName: " << settings.textureName.toStdString()
                << " | grainTextureID(settings): " << settings.grainTextureID
                << " | grainTexID(loaded): " << grainTexID
                << " | hasGrain: " << hasGrain
                << " | textureIntensity: " << settings.textureIntensity
                << " | textureScale: " << settings.textureScale
                << " | grainBright: " << settings.grainBright
                << " | grainCon: " << settings.grainCon
                << " | invertGrain: " << settings.invertGrain << "\n";
      }
    }

    int uDualTipBlendMode = 0; // multiply
    if (settings.dualTipBlendMode == "mask" || settings.dualTipBlendMode == "subtract") {
      uDualTipBlendMode = 1;
    } else if (settings.dualTipBlendMode == "add") {
      uDualTipBlendMode = 2;
    } else if (settings.dualTipBlendMode == "height_linear" || settings.dualTipBlendMode == "height") {
      uDualTipBlendMode = 3;
    }

    int uGrainBlendMode = 0; // multiply
    if (settings.grainBlendMode == "subtract") {
      uGrainBlendMode = 1;
    } else if (settings.grainBlendMode == "threshold" || settings.grainBlendMode == "reveal") {
      uGrainBlendMode = 2;
    }

    painter->save();
    painter->beginNativePainting();

    if (!m_renderer) {
      m_renderer = new StrokeRenderer();
      m_renderer->initialize();
    }

    // Sync clipping state from painter to native GL renderer
    m_renderer->setClippingEnabled(painter->hasClipping());

    int w = painter->device()->width();
    int h = painter->device()->height();

    m_renderer->beginFrame(w, h);

    float currentSize =
        settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
    if (currentSize < 1.0f)
      currentSize = 1.0f;

    // Robust Interpolation (Cumulative Distance Algorithm)
    float dx = currentPoint.x() - lastPoint.x();
    float dy = currentPoint.y() - lastPoint.y();
    float dist = std::hypot(dx, dy);
    float stepSize = std::max(0.5f, currentSize * settings.spacing);

    if (m_remainder < 0.0f) {
      m_remainder = stepSize; // Force dab at t=0
    }

    float distanceToDab = stepSize - m_remainder;

    QColor c = settings.color;
    c.setAlphaF(c.alphaF() * settings.opacity);

    // Calligraphy effect (Angle-based thickness)
    float calligraphyWidth = 1.0f;
    float strokeAngle = std::atan2(dy, dx);
    if (settings.type == BrushSettings::Type::Ink ||
        settings.type == BrushSettings::Type::Custom) {
      // Horizontal = thicker, Vertical = thinner
      calligraphyWidth = 0.5f + std::abs(std::sin(strokeAngle)) * 0.5f;
    }

    QTransform xform = painter->transform();
    float scaleFactor =
        std::sqrt(xform.m11() * xform.m11() + xform.m12() * xform.m12());

    std::vector<StrokeRenderer::DabInstance> instancedDabs;
    std::vector<StrokeRenderer::DabInstance> particleDabs;

    while (distanceToDab <= dist) {
      float t = (dist > 0.0001f) ? (distanceToDab / dist) : 0.0f;
      QPointF pt = lastPoint + (currentPoint - lastPoint) * t;

      // Progress within stroke
      float totalDist = m_accumulatedDistance + distanceToDab;

      // Taper and Falloff
      float sizeMultiplier = 1.0f;
      float opacityMultiplier = 1.0f;

      if (settings.taperStart > 0.0f && totalDist < settings.taperStart) {
        // Parabolic Taper (smoother start)
        float x = 1.0f - (totalDist / settings.taperStart); // 1.0 to 0.0
        float parabola = 1.0f - (x * x);
        sizeMultiplier = 0.1f + 0.9f * parabola;
      }
      if (settings.fallOff > 0.0f) {
        // Opacity falloff
        opacityMultiplier =
            std::max(0.0f, 1.0f - (totalDist / settings.fallOff));

        // Parabolic Taper (smoother end)
        if (settings.taperEnd > 0.0f &&
            totalDist > (settings.fallOff - settings.taperEnd)) {
          float x = (totalDist - (settings.fallOff - settings.taperEnd)) /
                    settings.taperEnd; // 0.0 to 1.0
          float parabola = 1.0f - (x * x);
          sizeMultiplier *= (0.1f + 0.9f * parabola);
        }
      }

      QPointF devPt = xform.map(pt);
      float devSizeBase =
          currentSize * scaleFactor * sizeMultiplier * calligraphyWidth;
      float opacityBase = c.alphaF() * opacityMultiplier;

      if (settings.mainSprayEnabled) {
        int numParticles = std::max(1, settings.mainParticleDensity * 3);
        
        float pSize = settings.mainParticleSize;
        if (settings.mainSpraySizeByBrush) {
          pSize = currentSize * (settings.mainParticleSize / 100.0f);
        }
        
        float maxScatter = (currentSize - pSize) * 0.5f;
        float scatterRadius = std::max(0.0f, maxScatter) * (settings.mainSprayDeviation / 5.0f);
        
        for (int pIdx = 0; pIdx < numParticles; ++pIdx) {
          float theta = (std::rand() % 360) * 3.14159265f / 180.0f;
          float tRandom = (std::rand() % 1001) / 1000.0f;
          float r = std::pow(tRandom, 1.5f) * scatterRadius;
          float pOffsetX = r * std::cos(theta);
          float pOffsetY = r * std::sin(theta);
          QPointF particlePt = pt + QPointF(pOffsetX, pOffsetY);
          QPointF devParticlePt = xform.map(particlePt);

          // Jitters
          float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
          if (settings.posJitterX > 0)
            jX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX * devSizeBase;
          if (settings.posJitterY > 0)
            jY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY * devSizeBase;
          if (settings.sizeJitter > 0)
            jSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
          if (settings.rotationJitter > 0)
            jRot = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.rotationJitter * 3.14159f;
          if (settings.opacityJitter > 0)
            jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

          float devParticleSize = pSize * scaleFactor * sizeMultiplier * calligraphyWidth * jSize;

          QColor finalColor = c;
          finalColor.setAlphaF(std::clamp(opacityBase * jOpac, 0.0f, 1.0f));

          // Basic Color Dynamics
          if (settings.hueJitter > 0 || settings.satJitter > 0) {
            float h, s, l, a;
            finalColor.getHslF(&h, &s, &l, &a);
            h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.hueJitter, 1.0f);
            if (h < 0) h += 1.0f;
            s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.satJitter, 0.0f, 1.0f);
            finalColor.setHslF(h, s, l, a);
          }

          StrokeRenderer::DabInstance pDab;
          pDab.x = devParticlePt.x() + jX;
          pDab.y = devParticlePt.y() + jY;
          pDab.size = devParticleSize;
          pDab.rotation = (settings.mainParticleDirection * 3.14159265f / 180.0f) + jRot;
          pDab.colorR = finalColor.redF();
          pDab.colorG = finalColor.greenF();
          pDab.colorB = finalColor.blueF();
          pDab.colorA = finalColor.alphaF();
          
          float dabPaintLoad = 1.0f;
          if (settings.type == BrushSettings::Type::Oil) {
            dabPaintLoad = std::max(0.0f, 1.0f - totalDist * settings.depletionRate);
          }
          pDab.paintLoad = dabPaintLoad;

          instancedDabs.push_back(pDab);
        }
      } else {
        // Loop for Count (Stamp stacking)
        int count = std::max(1, settings.count);
        for (int k = 0; k < count; ++k) {
          // Jitters
          float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
          if (settings.posJitterX > 0)
            jX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX *
                 devSizeBase;
          if (settings.posJitterY > 0)
            jY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY *
                 devSizeBase;
          if (settings.sizeJitter > 0)
            jSize = 1.0f +
                    ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
          if (settings.rotationJitter > 0)
            jRot = ((std::rand() % 2001 - 1000) / 1000.0f) *
                   settings.rotationJitter * 3.14159f;
          if (settings.opacityJitter > 0)
            jOpac =
                1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

          QColor finalColor = c;
          finalColor.setAlphaF(std::clamp(opacityBase * jOpac, 0.0f, 1.0f));

          // Basic Color Dynamics
          if (settings.hueJitter > 0 || settings.satJitter > 0) {
            float h, s, l, a;
            finalColor.getHslF(&h, &s, &l, &a);
            h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) *
                                  settings.hueJitter,
                          1.0f);
            if (h < 0)
              h += 1.0f;
            s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) *
                                   settings.satJitter,
                           0.0f, 1.0f);
            finalColor.setHslF(h, s, l, a);
          }

          // Blend-only brushes (e.g. blenders or watercolor wet mixers) have 0 opacity pigment
          // but need to draw dabs to trigger GPU neighbor blending and smudging.
          bool isBlendOnly = (settings.blendOnly || 
                              settings.dilution > 0.01f || 
                              settings.smudge > 0.01f || 
                              settings.type == BrushSettings::Type::Watercolor || 
                              settings.type == BrushSettings::Type::Oil);

          if (devSizeBase < 1.0f || effectivePressure < 0.001f ||
              (!isBlendOnly && opacityBase < 0.001f))
            continue;

          // Calculate base rotation
          float currentTipRot = settings.tipRotation;
          if (settings.rotateWithStroke) {
            currentTipRot += strokeAngle;
          }

          StrokeRenderer::DabInstance dab;
          dab.x = devPt.x() + jX;
          dab.y = devPt.y() + jY;
          dab.size = devSizeBase * jSize;
          dab.rotation = currentTipRot + jRot;
          dab.colorR = finalColor.redF();
          dab.colorG = finalColor.greenF();
          dab.colorB = finalColor.blueF();
          dab.colorA = finalColor.alphaF();
          
          float dabPaintLoad = 1.0f;
          if (settings.type == BrushSettings::Type::Oil) {
            dabPaintLoad = std::max(0.0f, 1.0f - totalDist * settings.depletionRate);
          }
          dab.paintLoad = dabPaintLoad;

          instancedDabs.push_back(dab);
        }
      }

      // Generate Dual Brush Spray Particles
      if (settings.dualTipEnabled && settings.sprayEnabled) {
        int numParticles = std::max(1, settings.particleDensity * 3);
        
        float pSize = settings.particleSize;
        if (settings.spraySizeByBrush) {
          pSize = currentSize * (settings.particleSize / 100.0f);
        }
        
        float maxScatter = (currentSize - pSize) * 0.5f;
        float scatterRadius = std::max(0.0f, maxScatter) * (settings.sprayDeviation / 5.0f);
        
        for (int pIdx = 0; pIdx < numParticles; ++pIdx) {
          float theta = (std::rand() % 360) * 3.14159265f / 180.0f;
          float tRandom = (std::rand() % 1001) / 1000.0f;
          float r = std::pow(tRandom, 1.5f) * scatterRadius;
          float pOffsetX = r * std::cos(theta);
          float pOffsetY = r * std::sin(theta);
          QPointF particlePt = pt + QPointF(pOffsetX, pOffsetY);
          QPointF devParticlePt = xform.map(particlePt);

          float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
          if (settings.posJitterX > 0)
            jX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX * devSizeBase;
          if (settings.posJitterY > 0)
            jY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY * devSizeBase;
          if (settings.sizeJitter > 0)
            jSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
          if (settings.rotationJitter > 0)
            jRot = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.rotationJitter * 3.14159f;
          if (settings.opacityJitter > 0)
            jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

          float devParticleSize = pSize * scaleFactor * sizeMultiplier * calligraphyWidth * jSize;

          QColor finalColor = c;
          finalColor.setAlphaF(std::clamp(opacityBase * jOpac * settings.dualTipFlow, 0.0f, 1.0f));

          if (settings.hueJitter > 0 || settings.satJitter > 0) {
            float h, s, l, a;
            finalColor.getHslF(&h, &s, &l, &a);
            h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.hueJitter, 1.0f);
            if (h < 0) h += 1.0f;
            s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.satJitter, 0.0f, 1.0f);
            finalColor.setHslF(h, s, l, a);
          }

          StrokeRenderer::DabInstance pDab;
          pDab.x = devParticlePt.x() + jX;
          pDab.y = devParticlePt.y() + jY;
          pDab.size = devParticleSize;
          pDab.rotation = (settings.particleDirection * 3.14159265f / 180.0f) + jRot;
          pDab.colorR = finalColor.redF();
          pDab.colorG = finalColor.greenF();
          pDab.colorB = finalColor.blueF();
          pDab.colorA = finalColor.alphaF();
          pDab.paintLoad = 1.0f;

          particleDabs.push_back(pDab);
        }
      }

      distanceToDab += stepSize;
    }

    if (!instancedDabs.empty()) {
      bool useSequentialPingPong = (pingFBO && pongFBO &&
                                    (settings.type == BrushSettings::Type::Oil ||
                                     settings.smudge > 0.01f ||
                                     settings.wetness > 0.01f));

      if (useSequentialPingPong) {
        // Render each dab sequentially with blit-per-dab to achieve true ping-pong double buffering
        for (size_t i = 0; i < instancedDabs.size(); ++i) {
          const auto &dab = instancedDabs[i];

          m_renderer->renderStroke(
              dab.x, dab.y, dab.size, effectivePressure, settings.hardness,
              QColor::fromRgbF(dab.colorR, dab.colorG, dab.colorB, dab.colorA),
              static_cast<int>(settings.type), m_renderer->viewportWidth(),
              m_renderer->viewportHeight(), grainTexID,
              (grainTexID != 0 && settings.useTexture),
              settings.textureScale * scaleFactor, settings.textureIntensity,
              settings.grainBright, settings.grainCon, settings.invertGrain, settings.grainRotation,
              tipTexID, (tipTexID != 0), dab.rotation,
              tilt, velocity, settings.flow,
              pingFBO->texture(), // Read from pingFBO
              wetness, dilution, smudge, settings.bleed, settings.absorptionRate,
              settings.dryingTime, settings.wetOnWetMultiplier,
              settings.granulation, settings.pigmentFlow, settings.staining,
              settings.separation, settings.bloomEnabled, settings.bloomIntensity,
              settings.bloomRadius, settings.bloomThreshold,
              settings.edgeDarkeningEnabled, settings.edgeDarkeningIntensity,
              settings.edgeDarkeningWidth, settings.textureRevealEnabled,
              settings.textureRevealIntensity,
              settings.textureRevealPressureInfluence, settings.mixing,
              dab.paintLoad, // Pass per-dab paintLoad as the loading uniform
              settings.depletionRate, settings.dirtyMixing,
              settings.colorPickup, settings.blendOnly, settings.scrapeThrough,
              settings.impastoEnabled, settings.impastoDepth, settings.impastoShine,
              settings.impastoTextureStrength, settings.impastoEdgeBuildup,
              settings.impastoDirectionalRidges, settings.impastoSmoothing,
              settings.impastoPreserveExisting, settings.bristlesEnabled,
              settings.bristleCount, settings.bristleStiffness,
              settings.bristleClumping, settings.bristleFanSpread,
              settings.bristleIndividualVariation, settings.bristleDryBrushEffect,
              settings.bristleSoftness, settings.bristlePointTaper,
              settings.smudgeStrength, settings.smudgePressureInfluence,
              settings.smudgeLength, settings.smudgeGaussianBlur,
              settings.smudgeSmear, settings.canvasAbsorption,
              settings.canvasSkipValleys, settings.canvasCatchPeaks,
              settings.temperatureShift, settings.brokenColor,
              dualTipTexID, (hasDualTip && !settings.sprayEnabled), settings.dualTipScale, settings.dualTipRotation, uDualTipBlendMode, settings.dualTipFlow, uGrainBlendMode,
              dualGrainTexID, hasDualGrain, settings.dualTextureScale * scaleFactor, settings.dualTextureIntensity,
              settings.dualGrainBright, settings.dualGrainCon, settings.invertDualGrain, settings.dualGrainBlendMode, settings.dualGrainRotation,
              settings.type == BrushSettings::Type::Eraser,
              settings.colorMixing, settings.paintAmount, settings.colorStretch, settings.blendMode,
              settings.invertShape, settings.flipX, settings.flipY, settings.roundness, settings.shapeContrast, settings.shapeBlur,
              settings.grainEmphasizeDensity, settings.dualGrainEmphasizeDensity, settings.grainApplyToTips, settings.dualGrainApplyToTips);

          // Blit the result from pongFBO (write target) back to pingFBO (read target)
          QOpenGLFramebufferObject::blitFramebuffer(pingFBO, pongFBO);
        }

        // Render sprayed particles as instances (optimized to avoid rendering/blit loop lag)
        if (settings.dualTipEnabled && settings.sprayEnabled && !particleDabs.empty()) {
          m_renderer->renderStrokeInstanced(
              particleDabs, effectivePressure, settings.hardness,
              static_cast<int>(settings.type), m_renderer->viewportWidth(),
              m_renderer->viewportHeight(), grainTexID,
              (grainTexID != 0 && settings.useTexture),
              settings.textureScale * scaleFactor, settings.textureIntensity,
              settings.grainBright, settings.grainCon, settings.invertGrain, settings.grainRotation,
              dualTipTexID, (dualTipTexID != 0),
              tilt, velocity, settings.flow,
              pingFBO->texture(), // Read from pingFBO
              wetness, dilution, smudge, settings.bleed, settings.absorptionRate,
              settings.dryingTime, settings.wetOnWetMultiplier,
              settings.granulation, settings.pigmentFlow, settings.staining,
              settings.separation, settings.bloomEnabled, settings.bloomIntensity,
              settings.bloomRadius, settings.bloomThreshold,
              settings.edgeDarkeningEnabled, settings.edgeDarkeningIntensity,
              settings.edgeDarkeningWidth, settings.textureRevealEnabled,
              settings.textureRevealIntensity,
              settings.textureRevealPressureInfluence, settings.mixing,
              1.0f, // loading for particle dabs
              settings.depletionRate, settings.dirtyMixing,
              settings.colorPickup, settings.blendOnly, settings.scrapeThrough,
              settings.impastoEnabled, settings.impastoDepth, settings.impastoShine,
              settings.impastoTextureStrength, settings.impastoEdgeBuildup,
              settings.impastoDirectionalRidges, settings.impastoSmoothing,
              settings.impastoPreserveExisting, settings.bristlesEnabled,
              settings.bristleCount, settings.bristleStiffness,
              settings.bristleClumping, settings.bristleFanSpread,
              settings.bristleIndividualVariation, settings.bristleDryBrushEffect,
              settings.bristleSoftness, settings.bristlePointTaper,
              settings.smudgeStrength, settings.smudgePressureInfluence,
              settings.smudgeLength, settings.smudgeGaussianBlur,
              settings.smudgeSmear, settings.canvasAbsorption,
              settings.canvasSkipValleys, settings.canvasCatchPeaks,
              settings.temperatureShift, settings.brokenColor,
              0, false, 1.0f, 0.0f, 0, 1.0f, uGrainBlendMode, // no dual tip
              dualGrainTexID, hasDualGrain, settings.dualTextureScale * scaleFactor, settings.dualTextureIntensity,
              settings.dualGrainBright, settings.dualGrainCon, settings.invertDualGrain, settings.dualGrainBlendMode, settings.dualGrainRotation,
              settings.type == BrushSettings::Type::Eraser,
              settings.colorMixing, settings.paintAmount, settings.colorStretch, settings.blendMode,
              false, false, false, 1.0f, 1.0f, 0.0f, // dual brush tip defaults
              settings.grainEmphasizeDensity, settings.dualGrainEmphasizeDensity, settings.grainApplyToTips, settings.dualGrainApplyToTips);

          // Blit the result from pongFBO (write target) back to pingFBO (read target)
          QOpenGLFramebufferObject::blitFramebuffer(pingFBO, pongFBO);
        }
      } else {
        // Fast instanced path for standard/dry brushes
        m_renderer->renderStrokeInstanced(
            instancedDabs, effectivePressure, settings.hardness,
            static_cast<int>(settings.type), m_renderer->viewportWidth(),
            m_renderer->viewportHeight(), grainTexID,
            (grainTexID != 0 && settings.useTexture),
            settings.textureScale * scaleFactor, settings.textureIntensity,
            settings.grainBright, settings.grainCon, settings.invertGrain, settings.grainRotation,
            tipTexID, (tipTexID != 0),
            tilt, velocity, settings.flow, canvasTexId,
            wetness, dilution, smudge, settings.bleed, settings.absorptionRate,
            settings.dryingTime, settings.wetOnWetMultiplier,
            settings.granulation, settings.pigmentFlow, settings.staining,
            settings.separation, settings.bloomEnabled, settings.bloomIntensity,
            settings.bloomRadius, settings.bloomThreshold,
            settings.edgeDarkeningEnabled, settings.edgeDarkeningIntensity,
            settings.edgeDarkeningWidth, settings.textureRevealEnabled,
            settings.textureRevealIntensity,
            settings.textureRevealPressureInfluence, settings.mixing,
            settings.loading, settings.depletionRate, settings.dirtyMixing,
            settings.colorPickup, settings.blendOnly, settings.scrapeThrough,
            settings.impastoEnabled, settings.impastoDepth, settings.impastoShine,
            settings.impastoTextureStrength, settings.impastoEdgeBuildup,
            settings.impastoDirectionalRidges, settings.impastoSmoothing,
            settings.impastoPreserveExisting, settings.bristlesEnabled,
            settings.bristleCount, settings.bristleStiffness,
            settings.bristleClumping, settings.bristleFanSpread,
            settings.bristleIndividualVariation, settings.bristleDryBrushEffect,
            settings.bristleSoftness, settings.bristlePointTaper,
            settings.smudgeStrength, settings.smudgePressureInfluence,
            settings.smudgeLength, settings.smudgeGaussianBlur,
            settings.smudgeSmear, settings.canvasAbsorption,
            settings.canvasSkipValleys, settings.canvasCatchPeaks,
            settings.temperatureShift, settings.brokenColor,
            dualTipTexID, (hasDualTip && !settings.sprayEnabled), settings.dualTipScale, settings.dualTipRotation, uDualTipBlendMode, settings.dualTipFlow, uGrainBlendMode,
            dualGrainTexID, hasDualGrain, settings.dualTextureScale * scaleFactor, settings.dualTextureIntensity,
            settings.dualGrainBright, settings.dualGrainCon, settings.invertDualGrain, settings.dualGrainBlendMode, settings.dualGrainRotation,
            settings.type == BrushSettings::Type::Eraser,
            settings.colorMixing, settings.paintAmount, settings.colorStretch, settings.blendMode,
            settings.invertShape, settings.flipX, settings.flipY, settings.roundness, settings.shapeContrast, settings.shapeBlur,
            settings.grainEmphasizeDensity, settings.dualGrainEmphasizeDensity, settings.grainApplyToTips, settings.dualGrainApplyToTips);

        // Render sprayed particles as instances
        if (settings.dualTipEnabled && settings.sprayEnabled && !particleDabs.empty()) {
          m_renderer->renderStrokeInstanced(
              particleDabs, effectivePressure, settings.hardness,
              static_cast<int>(settings.type), m_renderer->viewportWidth(),
              m_renderer->viewportHeight(), grainTexID,
              (grainTexID != 0 && settings.useTexture),
              settings.textureScale * scaleFactor, settings.textureIntensity,
              settings.grainBright, settings.grainCon, settings.invertGrain, settings.grainRotation,
              dualTipTexID, (dualTipTexID != 0), tilt, velocity, settings.flow, canvasTexId,
              wetness, dilution, smudge, settings.bleed, settings.absorptionRate,
              settings.dryingTime, settings.wetOnWetMultiplier,
              settings.granulation, settings.pigmentFlow, settings.staining,
              settings.separation, settings.bloomEnabled, settings.bloomIntensity,
              settings.bloomRadius, settings.bloomThreshold,
              settings.edgeDarkeningEnabled, settings.edgeDarkeningIntensity,
              settings.edgeDarkeningWidth, settings.textureRevealEnabled,
              settings.textureRevealIntensity,
              settings.textureRevealPressureInfluence, settings.mixing,
              1.0f, // loading for particle dabs
              settings.depletionRate, settings.dirtyMixing,
              settings.colorPickup, settings.blendOnly, settings.scrapeThrough,
              settings.impastoEnabled, settings.impastoDepth, settings.impastoShine,
              settings.impastoTextureStrength, settings.impastoEdgeBuildup,
              settings.impastoDirectionalRidges, settings.impastoSmoothing,
              settings.impastoPreserveExisting, settings.bristlesEnabled,
              settings.bristleCount, settings.bristleStiffness,
              settings.bristleClumping, settings.bristleFanSpread,
              settings.bristleIndividualVariation, settings.bristleDryBrushEffect,
              settings.bristleSoftness, settings.bristlePointTaper,
              settings.smudgeStrength, settings.smudgePressureInfluence,
              settings.smudgeLength, settings.smudgeGaussianBlur,
              settings.smudgeSmear, settings.canvasAbsorption,
              settings.canvasSkipValleys, settings.canvasCatchPeaks,
              settings.temperatureShift, settings.brokenColor,
              0, false, 1.0f, 0.0f, 0, 1.0f, uGrainBlendMode, // no dual tip
              dualGrainTexID, hasDualGrain, settings.dualTextureScale * scaleFactor, settings.dualTextureIntensity,
              settings.dualGrainBright, settings.dualGrainCon, settings.invertDualGrain, settings.dualGrainBlendMode, settings.dualGrainRotation,
              settings.type == BrushSettings::Type::Eraser,
              settings.colorMixing, settings.paintAmount, settings.colorStretch, settings.blendMode,
              false, false, false, 1.0f, 1.0f, 0.0f, // dual brush tip defaults
              settings.grainEmphasizeDensity, settings.dualGrainEmphasizeDensity, settings.grainApplyToTips, settings.dualGrainApplyToTips);
        }
      }
    }
    // Update state
    m_accumulatedDistance += dist;
    m_remainder = dist - (distanceToDab - stepSize);
    if (m_remainder < 0)
      m_remainder = 0;

    painter->endNativePainting();
    painter->restore();
    return;
  }

  // --- LEGACY PATH (QPAINTER) ---

  if (settings.type == BrushSettings::Type::Eraser) {
    painter->setCompositionMode(QPainter::CompositionMode_DestinationOut);
  } else {
    painter->setCompositionMode(QPainter::CompositionMode_SourceOver);
  }

  QImage grainImg;
  if (settings.useTexture && !settings.textureName.isEmpty()) {
    grainImg = getTextureImage(settings.textureName, false);
  }
  QImage dualGrainImg;
  if (settings.useDualTexture && !settings.dualTextureName.isEmpty()) {
    dualGrainImg = getTextureImage(settings.dualTextureName, false);
  }

  float currentSize =
      settings.size * (settings.sizeByPressure ? effectivePressure : 1.0f);
  if (currentSize < 1.0f)
    currentSize = 1.0f;

  float currentOpacity =
      settings.opacity *
      (settings.opacityByPressure ? effectivePressure : 1.0f);
  if (currentOpacity > 1.0f)
    currentOpacity = 1.0f;

  float dx = currentPoint.x() - lastPoint.x();
  float dy = currentPoint.y() - lastPoint.y();
  float dist = std::hypot(dx, dy);
  float stepSize = std::max(0.5f, currentSize * settings.spacing);

  if (m_remainder < 0.0f)
    m_remainder = stepSize;
  float distanceToDab = stepSize - m_remainder;

  QColor baseColor = settings.color;

  // Calligraphy effect (Angle-based thickness)
  float calligraphyWidth = 1.0f;
  if (settings.type == BrushSettings::Type::Ink ||
      settings.type == BrushSettings::Type::Custom) {
    calligraphyWidth = 0.5f + std::abs(std::sin(std::atan2(dy, dx))) * 0.5f;
  }

  while (distanceToDab <= dist) {
    float t = (dist > 0.0001f) ? (distanceToDab / dist) : 0.0f;
    QPointF pt = lastPoint + (currentPoint - lastPoint) * t;

    // Progress within stroke
    float totalDist = m_accumulatedDistance + distanceToDab;

    // Taper and Falloff
    float sizeMultiplier = 1.0f;
    float opacityMultiplier = 1.0f;

    if (settings.taperStart > 0.0f && totalDist < settings.taperStart) {
      float x = 1.0f - (totalDist / settings.taperStart);
      float parabola = 1.0f - (x * x);
      sizeMultiplier = 0.2f + 0.8f * parabola;
    }
    if (settings.fallOff > 0.0f) {
      opacityMultiplier = std::max(0.0f, 1.0f - (totalDist / settings.fallOff));
    }

    float dabSize = currentSize * sizeMultiplier * calligraphyWidth;
    float dabOpacity = currentOpacity * opacityMultiplier;

    // Loop for Count (Stamp stacking)
    int count = std::max(1, settings.count);
    for (int k = 0; k < count; ++k) {
      // Jitters
      float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
      if (settings.posJitterX > 0)
        jX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX *
             dabSize;
      if (settings.posJitterY > 0)
        jY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY *
             dabSize;
      if (settings.sizeJitter > 0)
        jSize = 1.0f +
                ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
      if (settings.opacityJitter > 0)
        jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

      QPointF finalPt = pt + QPointF(jX, jY);
      float finalSize = std::max(0.1f, dabSize * jSize);
      float finalOpacity = std::clamp(dabOpacity * jOpac, 0.0f, 1.0f);

      QColor finalColor = baseColor;

      // Basic Color Dynamics
      if (settings.hueJitter > 0 || settings.satJitter > 0) {
        float h, s, l, a;
        finalColor.getHslF(&h, &s, &l, &a);
        h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) *
                              settings.hueJitter,
                      1.0f);
        if (h < 0)
          h += 1.0f;
        s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) *
                               settings.satJitter,
                       0.0f, 1.0f);
        finalColor.setHslF(h, s, l, a);
      }

      // Calculate base rotation for legacy path
      float strokeAngle = std::atan2(dy, dx);
      float currentTipRot = settings.tipRotation;
      if (settings.rotateWithStroke) {
        currentTipRot += strokeAngle;
      }

      bool hasGrain = (settings.useTexture && !settings.textureName.isEmpty() && !grainImg.isNull()) ||
                      (settings.useDualTexture && !settings.dualTextureName.isEmpty() && !dualGrainImg.isNull());
      bool hasDualTip = (settings.dualTipEnabled && !settings.dualTipTextureName.isEmpty());

      // 1. Draw Main Dab (or Main Spray Particles)
      if (settings.mainSprayEnabled) {
        int numParticles = std::max(1, settings.mainParticleDensity * 3);
        float pSize = settings.mainParticleSize;
        if (settings.mainSpraySizeByBrush) {
          pSize = currentSize * (settings.mainParticleSize / 100.0f);
        }
        float maxScatter = (currentSize - pSize) * 0.5f;
        float scatterRadius = std::max(0.0f, maxScatter) * (settings.mainSprayDeviation / 5.0f);

        for (int pIdx = 0; pIdx < numParticles; ++pIdx) {
          float theta = (std::rand() % 360) * 3.14159265f / 180.0f;
          float tRandom = (std::rand() % 1001) / 1000.0f;
          float r = std::pow(tRandom, 1.5f) * scatterRadius;
          float pOffsetX = r * std::cos(theta);
          float pOffsetY = r * std::sin(theta);
          QPointF particlePt = finalPt + QPointF(pOffsetX, pOffsetY);

          float pjX = 0, pjY = 0, pjSize = 1.0f, pjRot = 0, pjOpac = 1.0f;
          if (settings.posJitterX > 0)
            pjX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX * dabSize;
          if (settings.posJitterY > 0)
            pjY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY * dabSize;
          if (settings.sizeJitter > 0)
            pjSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
          if (settings.rotationJitter > 0)
            pjRot = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.rotationJitter * 3.14159f;
          if (settings.opacityJitter > 0)
            pjOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

          float finalParticleSize = std::max(0.1f, pSize * sizeMultiplier * calligraphyWidth * pjSize);
          float finalParticleOpacity = std::clamp(dabOpacity * pjOpac, 0.0f, 1.0f);
          QPointF finalParticlePt = particlePt + QPointF(pjX, pjY);
          float pRot = (settings.mainParticleDirection * 3.14159265f / 180.0f) + pjRot;

          if (hasGrain) {
            paintTexturedDabRaster(painter, finalParticlePt, finalParticleSize, finalParticleOpacity, finalColor,
                                   pRot, settings, grainImg, dualGrainImg);
          } else if (!settings.tipTextureName.isEmpty()) {
            paintTipRaster(painter, finalParticlePt, finalParticleSize, finalParticleOpacity, finalColor,
                           pRot, settings.tipTextureName);
          } else {
            paintSoftStamp(painter, finalParticlePt, finalParticleSize, finalParticleOpacity, finalColor,
                           settings.hardness);
          }
        }
      } else {
        // Draw single main dab (or textured/dual dab if dual brush is not sprayed)
        if (hasGrain || (hasDualTip && !settings.sprayEnabled)) {
          paintTexturedDabRaster(painter, finalPt, finalSize, finalOpacity, finalColor,
                                 currentTipRot + jRot, settings, grainImg, dualGrainImg);
        } else if (!settings.tipTextureName.isEmpty()) {
          paintTipRaster(painter, finalPt, finalSize, finalOpacity, finalColor,
                         currentTipRot + jRot, settings.tipTextureName);
        } else {
          paintSoftStamp(painter, finalPt, finalSize, finalOpacity, finalColor,
                         settings.hardness);
        }
      }

      // 2. Draw Sprayed Dual Brush Particles (if enabled)
      if (settings.dualTipEnabled && settings.sprayEnabled && !settings.dualTipTextureName.isEmpty()) {
        QImage dualTipImg = getTextureImage(settings.dualTipTextureName, true);
        if (!dualTipImg.isNull()) {
          int numParticles = std::max(1, settings.particleDensity * 3);
          float pSize = settings.particleSize;
          if (settings.spraySizeByBrush) {
            pSize = currentSize * (settings.particleSize / 100.0f);
          }
          float maxScatter = (currentSize - pSize) * 0.5f;
          float scatterRadius = std::max(0.0f, maxScatter) * (settings.sprayDeviation / 5.0f);

          for (int pIdx = 0; pIdx < numParticles; ++pIdx) {
            float theta = (std::rand() % 360) * 3.14159265f / 180.0f;
            float tRandom = (std::rand() % 1001) / 1000.0f;
            float r = std::pow(tRandom, 1.5f) * scatterRadius;
            float pOffsetX = r * std::cos(theta);
            float pOffsetY = r * std::sin(theta);
            QPointF particlePt = finalPt + QPointF(pOffsetX, pOffsetY);

            float pjX = 0, pjY = 0, pjSize = 1.0f, pjRot = 0, pjOpac = 1.0f;
            if (settings.posJitterX > 0)
              pjX = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterX * dabSize;
            if (settings.posJitterY > 0)
              pjY = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.posJitterY * dabSize;
            if (settings.sizeJitter > 0)
              pjSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) * settings.sizeJitter;
            if (settings.rotationJitter > 0)
              pjRot = ((std::rand() % 2001 - 1000) / 1000.0f) * settings.rotationJitter * 3.14159f;
            if (settings.opacityJitter > 0)
              pjOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * settings.opacityJitter;

            float finalParticleSize = std::max(0.1f, pSize * sizeMultiplier * calligraphyWidth * pjSize);
            float finalParticleOpacity = std::clamp(dabOpacity * pjOpac * settings.dualTipFlow, 0.0f, 1.0f);
            QPointF finalParticlePt = particlePt + QPointF(pjX, pjY);
            float pRot = (settings.particleDirection * 3.14159265f / 180.0f) + pjRot;

            paintTipRaster(painter, finalParticlePt, finalParticleSize, finalParticleOpacity, finalColor,
                           pRot, settings.dualTipTextureName);
          }
        }
      }
    }

    distanceToDab += stepSize;
  }

  // Update state
  m_accumulatedDistance += dist;
  m_remainder = dist - (distanceToDab - stepSize);
  if (m_remainder < 0)
    m_remainder = 0;
}

// --- Python Bindings Support ---

void BrushEngine::setBrush(const BrushSettings &settings) {
  m_currentSettings = settings;
  // Sync cached color
  m_cachedColor = Color(settings.color.red(), settings.color.green(),
                        settings.color.blue(), settings.color.alpha());
}

void BrushEngine::setColor(const Color &color) {
  m_cachedColor = color;
  m_currentSettings.color = QColor(color.r, color.g, color.b, color.a);
}

const Color &BrushEngine::getColor() const { return m_cachedColor; }

void BrushEngine::beginStroke(const StrokePoint &point) {
  m_lastPos = QPointF(point.x, point.y);
  m_remainder = -1.0f;
  m_accumulatedDistance = 0.0f;
  if (!m_renderer) {
    m_renderer = new StrokeRenderer();
    m_renderer->initialize();
  }
}

void BrushEngine::continueStroke(const StrokePoint &point) {
  if (!m_renderer)
    return;

  QPointF currentPos(point.x, point.y);

  float dx = currentPos.x() - m_lastPos.x();
  float dy = currentPos.y() - m_lastPos.y();
  float dist = std::hypot(dx, dy);

  // Skip negligible moves to prevent stamping artifacts at the end of a stroke
  if (dist < 0.01f && m_remainder > 0.1f)
    return;

  float size = m_currentSettings.size;
  if (m_currentSettings.sizeByPressure) {
    size *= point.pressure;
  }

  // Ensure spacing is at least 2.0 pixels to prevent extreme performance lag
  float spacing = std::max(2.0f, size * m_currentSettings.spacing);

  if (m_remainder < 0.0f) {
    m_remainder = spacing;
  }

  float coveredDist = spacing - m_remainder;

  float opacity = m_currentSettings.opacity;
  if (m_currentSettings.opacityByPressure) {
    opacity *= point.pressure;
  }

  // Load textures
  uint32_t grainTexId = m_currentSettings.grainTextureID;
  if (m_currentSettings.useTexture && grainTexId == 0 &&
      !m_currentSettings.textureName.isEmpty()) {
    grainTexId = loadTexture(m_currentSettings.textureName, false);
  }

  uint32_t tipTexId = m_currentSettings.tipTextureID;
  if (tipTexId == 0 && !m_currentSettings.tipTextureName.isEmpty()) {
    tipTexId = loadTexture(m_currentSettings.tipTextureName, true);
  }

  uint32_t dualTipTexId = m_currentSettings.dualTipTextureID;
  if (m_currentSettings.dualTipEnabled && dualTipTexId == 0 &&
      !m_currentSettings.dualTipTextureName.isEmpty()) {
    dualTipTexId = loadTexture(m_currentSettings.dualTipTextureName, true);
  }

  uint32_t dualGrainTexId = m_currentSettings.dualGrainTextureID;
  if (m_currentSettings.useDualTexture && dualGrainTexId == 0 &&
      !m_currentSettings.dualTextureName.isEmpty()) {
    dualGrainTexId = loadTexture(m_currentSettings.dualTextureName, false);
  }

  bool hasGrain = (grainTexId != 0 && m_currentSettings.useTexture);
  bool hasTip = (tipTexId != 0);
  bool hasDualTip = (dualTipTexId != 0 && m_currentSettings.dualTipEnabled);
  bool hasDualGrain = (dualGrainTexId != 0 && m_currentSettings.useDualTexture);

  int uDualTipBlendMode = 0; // multiply
  if (m_currentSettings.dualTipBlendMode == "mask" || m_currentSettings.dualTipBlendMode == "subtract") {
    uDualTipBlendMode = 1;
  } else if (m_currentSettings.dualTipBlendMode == "add") {
    uDualTipBlendMode = 2;
  } else if (m_currentSettings.dualTipBlendMode == "height_linear" || m_currentSettings.dualTipBlendMode == "height") {
    uDualTipBlendMode = 3;
  }

  int uGrainBlendMode = 0; // multiply
  if (m_currentSettings.grainBlendMode == "subtract") {
    uGrainBlendMode = 1;
  } else if (m_currentSettings.grainBlendMode == "threshold" || m_currentSettings.grainBlendMode == "reveal") {
    uGrainBlendMode = 2;
  }

  int w = m_renderer ? m_renderer->viewportWidth() : 2000;
  int h = m_renderer ? m_renderer->viewportHeight() : 2000;

  if (m_renderer) {
    m_renderer->beginFrame(w, h);
  }

  bool isEraser = (m_currentSettings.type == BrushSettings::Type::Eraser);

  std::vector<StrokeRenderer::DabInstance> instancedDabs;
  std::vector<StrokeRenderer::DabInstance> particleDabs;

  // Render Loop
  while (coveredDist <= dist) {
    float t = (dist > 0.0001f) ? (coveredDist / dist) : 0.0f;
    QPointF pt = m_lastPos + (currentPos - m_lastPos) * t;

    float totalDist = m_accumulatedDistance + coveredDist;

    // Taper and Falloff
    float sizeMultiplier = 1.0f;
    float opacityMultiplier = 1.0f;

    if (m_currentSettings.taperStart > 0.0f &&
        totalDist < m_currentSettings.taperStart) {
      sizeMultiplier = totalDist / m_currentSettings.taperStart;
    }
    if (m_currentSettings.fallOff > 0.0f) {
      opacityMultiplier =
          std::max(0.0f, 1.0f - (totalDist / m_currentSettings.fallOff));
    }

    float devSizeBase = size * sizeMultiplier;
    float opacityBase = opacity * opacityMultiplier;

    if (m_currentSettings.mainSprayEnabled) {
      int numParticles = std::max(1, m_currentSettings.mainParticleDensity * 3);
      
      float pSize = m_currentSettings.mainParticleSize;
      if (m_currentSettings.mainSpraySizeByBrush) {
        pSize = size * (m_currentSettings.mainParticleSize / 100.0f);
      }
      
      float maxScatter = (size - pSize) * 0.5f;
      float scatterRadius = std::max(0.0f, maxScatter) * (m_currentSettings.mainSprayDeviation / 5.0f);
      
      for (int pIdx = 0; pIdx < numParticles; ++pIdx) {
        float theta = (std::rand() % 360) * 3.14159265f / 180.0f;
        float tRandom = (std::rand() % 1001) / 1000.0f;
        float r = std::pow(tRandom, 1.5f) * scatterRadius;
        float pOffsetX = r * std::cos(theta);
        float pOffsetY = r * std::sin(theta);
        QPointF particlePt = pt + QPointF(pOffsetX, pOffsetY);

        // Jitters
        float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
        if (m_currentSettings.posJitterX > 0)
          jX = ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.posJitterX * devSizeBase;
        if (m_currentSettings.posJitterY > 0)
          jY = ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.posJitterY * devSizeBase;
        if (m_currentSettings.sizeJitter > 0)
          jSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.sizeJitter;
        if (m_currentSettings.rotationJitter > 0)
          jRot = ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.rotationJitter * 3.14159f;
        if (m_currentSettings.opacityJitter > 0)
          jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * m_currentSettings.opacityJitter;

        float devParticleSize = pSize * sizeMultiplier * jSize;

        QColor finalColor = m_currentSettings.color;
        finalColor.setAlphaF(std::clamp(opacityBase * jOpac, 0.0f, 1.0f));

        if (m_currentSettings.hueJitter > 0 || m_currentSettings.satJitter > 0) {
          float h, s, l, a;
          finalColor.getHslF(&h, &s, &l, &a);
          h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.hueJitter, 1.0f);
          if (h < 0) h += 1.0f;
          s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.satJitter, 0.0f, 1.0f);
          finalColor.setHslF(h, s, l, a);
        }

        StrokeRenderer::DabInstance pDab;
        pDab.x = particlePt.x() + jX;
        pDab.y = particlePt.y() + jY;
        pDab.size = devParticleSize;
        pDab.rotation = (m_currentSettings.mainParticleDirection * 3.14159265f / 180.0f) + jRot;
        pDab.colorR = finalColor.redF();
        pDab.colorG = finalColor.greenF();
        pDab.colorB = finalColor.blueF();
        pDab.colorA = finalColor.alphaF();
        
        float dabPaintLoad = 1.0f;
        if (m_currentSettings.type == BrushSettings::Type::Oil) {
          dabPaintLoad = std::max(0.0f, 1.0f - totalDist * m_currentSettings.depletionRate);
        }
        pDab.paintLoad = dabPaintLoad;

        instancedDabs.push_back(pDab);
      }
    } else {
      // Loop for Count (Stamp stacking)
      int count = std::max(1, m_currentSettings.count);
      for (int k = 0; k < count; ++k) {
        // Jitters
        float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
        if (m_currentSettings.posJitterX > 0)
          jX = ((std::rand() % 2001 - 1000) / 1000.0f) *
               m_currentSettings.posJitterX * devSizeBase;
        if (m_currentSettings.posJitterY > 0)
          jY = ((std::rand() % 2001 - 1000) / 1000.0f) *
               m_currentSettings.posJitterY * devSizeBase;
        if (m_currentSettings.sizeJitter > 0)
          jSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) *
                             m_currentSettings.sizeJitter;
        if (m_currentSettings.rotationJitter > 0)
          jRot = ((std::rand() % 2001 - 1000) / 1000.0f) *
                 m_currentSettings.rotationJitter * 3.14159f;
        if (m_currentSettings.opacityJitter > 0)
          jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) *
                             m_currentSettings.opacityJitter;

        QColor finalColor = m_currentSettings.color;
        finalColor.setAlphaF(std::clamp(opacityBase * jOpac, 0.0f, 1.0f));

        // Basic Color Dynamics
        if (m_currentSettings.hueJitter > 0 || m_currentSettings.satJitter > 0) {
          float h, s, l, a;
          finalColor.getHslF(&h, &s, &l, &a);
          h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) *
                                m_currentSettings.hueJitter,
                        1.0f);
          if (h < 0)
            h += 1.0f;
          s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) *
                                 m_currentSettings.satJitter,
                         0.0f, 1.0f);
          finalColor.setHslF(h, s, l, a);
        }

        // Calculate base rotation
        float strokeAngle = std::atan2(dy, dx);
        float currentTipRot = m_currentSettings.tipRotation;
        if (m_currentSettings.rotateWithStroke) {
          currentTipRot += strokeAngle;
        }

        StrokeRenderer::DabInstance dab;
        dab.x = pt.x() + jX;
        dab.y = pt.y() + jY;
        dab.size = devSizeBase * jSize;
        dab.rotation = currentTipRot + jRot;
        dab.colorR = finalColor.redF();
        dab.colorG = finalColor.greenF();
        dab.colorB = finalColor.blueF();
        dab.colorA = finalColor.alphaF();
        
        float dabPaintLoad = 1.0f;
        if (m_currentSettings.type == BrushSettings::Type::Oil) {
          dabPaintLoad = std::max(0.0f, 1.0f - totalDist * m_currentSettings.depletionRate);
        }
        dab.paintLoad = dabPaintLoad;

        instancedDabs.push_back(dab);
      }
    }

    // Generate continueStroke particles
    if (m_currentSettings.dualTipEnabled && m_currentSettings.sprayEnabled) {
      int numParticles = std::max(1, m_currentSettings.particleDensity * 3);
      
      float pSize = m_currentSettings.particleSize;
      if (m_currentSettings.spraySizeByBrush) {
        pSize = size * (m_currentSettings.particleSize / 100.0f);
      }
      
      float maxScatter = (size - pSize) * 0.5f;
      float scatterRadius = std::max(0.0f, maxScatter) * (m_currentSettings.sprayDeviation / 5.0f);
      
      for (int pIdx = 0; pIdx < numParticles; ++pIdx) {
        float theta = (std::rand() % 360) * 3.14159265f / 180.0f;
        float tRandom = (std::rand() % 1001) / 1000.0f;
        float r = std::pow(tRandom, 1.5f) * scatterRadius;
        float pOffsetX = r * std::cos(theta);
        float pOffsetY = r * std::sin(theta);
        QPointF particlePt = pt + QPointF(pOffsetX, pOffsetY);

        float jX = 0, jY = 0, jSize = 1.0f, jRot = 0, jOpac = 1.0f;
        if (m_currentSettings.posJitterX > 0)
          jX = ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.posJitterX * devSizeBase;
        if (m_currentSettings.posJitterY > 0)
          jY = ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.posJitterY * devSizeBase;
        if (m_currentSettings.sizeJitter > 0)
          jSize = 1.0f + ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.sizeJitter;
        if (m_currentSettings.rotationJitter > 0)
          jRot = ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.rotationJitter * 3.14159f;
        if (m_currentSettings.opacityJitter > 0)
          jOpac = 1.0f - (std::rand() % 1001 / 1000.0f) * m_currentSettings.opacityJitter;

        float devParticleSize = pSize * sizeMultiplier * jSize;

        QColor finalColor = m_currentSettings.color;
        finalColor.setAlphaF(std::clamp(opacityBase * jOpac * m_currentSettings.dualTipFlow, 0.0f, 1.0f));

        if (m_currentSettings.hueJitter > 0 || m_currentSettings.satJitter > 0) {
          float h, s, l, a;
          finalColor.getHslF(&h, &s, &l, &a);
          h = std::fmod(h + ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.hueJitter, 1.0f);
          if (h < 0) h += 1.0f;
          s = std::clamp(s + ((std::rand() % 2001 - 1000) / 1000.0f) * m_currentSettings.satJitter, 0.0f, 1.0f);
          finalColor.setHslF(h, s, l, a);
        }

        StrokeRenderer::DabInstance pDab;
        pDab.x = particlePt.x() + jX;
        pDab.y = particlePt.y() + jY;
        pDab.size = devParticleSize;
        pDab.rotation = (m_currentSettings.particleDirection * 3.14159265f / 180.0f) + jRot;
        pDab.colorR = finalColor.redF();
        pDab.colorG = finalColor.greenF();
        pDab.colorB = finalColor.blueF();
        pDab.colorA = finalColor.alphaF();
        pDab.paintLoad = 1.0f;

        particleDabs.push_back(pDab);
      }
    }
    coveredDist += spacing;
  }

  if (!instancedDabs.empty()) {
    m_renderer->renderStrokeInstanced(
        instancedDabs, point.pressure, m_currentSettings.hardness,
        (int)m_currentSettings.type, w, h,
        // Grain
        grainTexId, hasGrain, m_currentSettings.textureScale,
        m_currentSettings.textureIntensity,
        m_currentSettings.grainBright, m_currentSettings.grainCon, m_currentSettings.invertGrain, m_currentSettings.grainRotation,
        // Tip
        tipTexId, hasTip,
        // Dynamics
        0.0f, 0.0f, m_currentSettings.flow,
        // Wet Mix
        0, m_currentSettings.wetness, m_currentSettings.dilution,
        m_currentSettings.smudge,
        // New Watercolor Params
        m_currentSettings.bleed, m_currentSettings.absorptionRate,
        m_currentSettings.dryingTime, m_currentSettings.wetOnWetMultiplier,
        m_currentSettings.granulation, m_currentSettings.pigmentFlow,
        m_currentSettings.staining, m_currentSettings.separation,
        m_currentSettings.bloomEnabled, m_currentSettings.bloomIntensity,
        m_currentSettings.bloomRadius, m_currentSettings.bloomThreshold,
        m_currentSettings.edgeDarkeningEnabled, m_currentSettings.edgeDarkeningIntensity,
        m_currentSettings.edgeDarkeningWidth, m_currentSettings.textureRevealEnabled,
        m_currentSettings.textureRevealIntensity,
        m_currentSettings.textureRevealPressureInfluence, m_currentSettings.mixing,
        m_currentSettings.loading, m_currentSettings.depletionRate, m_currentSettings.dirtyMixing,
        m_currentSettings.colorPickup, m_currentSettings.blendOnly, m_currentSettings.scrapeThrough,
        m_currentSettings.impastoEnabled, m_currentSettings.impastoDepth,
        m_currentSettings.impastoShine,
        m_currentSettings.impastoTextureStrength,
        m_currentSettings.impastoEdgeBuildup,
        m_currentSettings.impastoDirectionalRidges,
        m_currentSettings.impastoSmoothing,
        m_currentSettings.impastoPreserveExisting,
        // Bristles
        m_currentSettings.bristlesEnabled, m_currentSettings.bristleCount,
        m_currentSettings.bristleStiffness, m_currentSettings.bristleClumping,
        m_currentSettings.bristleFanSpread,
        m_currentSettings.bristleIndividualVariation,
        m_currentSettings.bristleDryBrushEffect,
        m_currentSettings.bristleSoftness, m_currentSettings.bristlePointTaper,
        // Smudge
        m_currentSettings.smudgeStrength,
        m_currentSettings.smudgePressureInfluence,
        m_currentSettings.smudgeLength, m_currentSettings.smudgeGaussianBlur,
        m_currentSettings.smudgeSmear,
        // Canvas Interaction
        m_currentSettings.canvasAbsorption, m_currentSettings.canvasSkipValleys,
        m_currentSettings.canvasCatchPeaks,
        // Color Dynamics Oil
        m_currentSettings.temperatureShift, m_currentSettings.brokenColor,
        // Dual brush and grain modes
        dualTipTexId, (hasDualTip && !m_currentSettings.sprayEnabled), m_currentSettings.dualTipScale, m_currentSettings.dualTipRotation, uDualTipBlendMode, m_currentSettings.dualTipFlow, uGrainBlendMode,
        dualGrainTexId, hasDualGrain, m_currentSettings.dualTextureScale, m_currentSettings.dualTextureIntensity,
        m_currentSettings.dualGrainBright, m_currentSettings.dualGrainCon, m_currentSettings.invertDualGrain, m_currentSettings.dualGrainBlendMode, m_currentSettings.dualGrainRotation,
        // Mode
        isEraser,
        m_currentSettings.colorMixing, m_currentSettings.paintAmount, m_currentSettings.colorStretch, m_currentSettings.blendMode,
        m_currentSettings.invertShape, m_currentSettings.flipX, m_currentSettings.flipY, m_currentSettings.roundness, m_currentSettings.shapeContrast, m_currentSettings.shapeBlur,
        m_currentSettings.grainEmphasizeDensity, m_currentSettings.dualGrainEmphasizeDensity, m_currentSettings.grainApplyToTips, m_currentSettings.dualGrainApplyToTips);

    if (m_currentSettings.dualTipEnabled && m_currentSettings.sprayEnabled && !particleDabs.empty()) {
      m_renderer->renderStrokeInstanced(
          particleDabs, point.pressure, m_currentSettings.hardness,
          (int)m_currentSettings.type, w, h,
          grainTexId, hasGrain, m_currentSettings.textureScale,
          m_currentSettings.textureIntensity,
          m_currentSettings.grainBright, m_currentSettings.grainCon, m_currentSettings.invertGrain, m_currentSettings.grainRotation,
          dualTipTexId, (dualTipTexId != 0),
          0.0f, 0.0f, m_currentSettings.flow,
          0, m_currentSettings.wetness, m_currentSettings.dilution,
          m_currentSettings.smudge,
          m_currentSettings.bleed, m_currentSettings.absorptionRate,
          m_currentSettings.dryingTime, m_currentSettings.wetOnWetMultiplier,
          m_currentSettings.granulation, m_currentSettings.pigmentFlow,
          m_currentSettings.staining, m_currentSettings.separation,
          m_currentSettings.bloomEnabled, m_currentSettings.bloomIntensity,
          m_currentSettings.bloomRadius, m_currentSettings.bloomThreshold,
          m_currentSettings.edgeDarkeningEnabled, m_currentSettings.edgeDarkeningIntensity,
          m_currentSettings.edgeDarkeningWidth, m_currentSettings.textureRevealEnabled,
          m_currentSettings.textureRevealIntensity,
          m_currentSettings.textureRevealPressureInfluence, m_currentSettings.mixing,
          1.0f, // loading for particles
          m_currentSettings.depletionRate, m_currentSettings.dirtyMixing,
          m_currentSettings.colorPickup, m_currentSettings.blendOnly, m_currentSettings.scrapeThrough,
          m_currentSettings.impastoEnabled, m_currentSettings.impastoDepth,
          m_currentSettings.impastoShine,
          m_currentSettings.impastoTextureStrength,
          m_currentSettings.impastoEdgeBuildup,
          m_currentSettings.impastoDirectionalRidges,
          m_currentSettings.impastoSmoothing,
          m_currentSettings.impastoPreserveExisting,
          m_currentSettings.bristlesEnabled, m_currentSettings.bristleCount,
          m_currentSettings.bristleStiffness, m_currentSettings.bristleClumping,
          m_currentSettings.bristleFanSpread,
          m_currentSettings.bristleIndividualVariation,
          m_currentSettings.bristleDryBrushEffect,
          m_currentSettings.bristleSoftness, m_currentSettings.bristlePointTaper,
          m_currentSettings.smudgeStrength,
          m_currentSettings.smudgePressureInfluence,
          m_currentSettings.smudgeLength, m_currentSettings.smudgeGaussianBlur,
          m_currentSettings.smudgeSmear,
          m_currentSettings.canvasAbsorption, m_currentSettings.canvasSkipValleys,
          m_currentSettings.canvasCatchPeaks,
          m_currentSettings.temperatureShift, m_currentSettings.brokenColor,
          0, false, 1.0f, 0.0f, 0, 1.0f, uGrainBlendMode, // no dual tip
          dualGrainTexId, hasDualGrain, m_currentSettings.dualTextureScale, m_currentSettings.dualTextureIntensity,
          m_currentSettings.dualGrainBright, m_currentSettings.dualGrainCon, m_currentSettings.invertDualGrain, m_currentSettings.dualGrainBlendMode, m_currentSettings.dualGrainRotation,
          isEraser,
          m_currentSettings.colorMixing, m_currentSettings.paintAmount, m_currentSettings.colorStretch, m_currentSettings.blendMode,
          false, false, false, 1.0f, 1.0f, 0.0f, // dual brush tip defaults
          m_currentSettings.grainEmphasizeDensity, m_currentSettings.dualGrainEmphasizeDensity, m_currentSettings.grainApplyToTips, m_currentSettings.dualGrainApplyToTips);
    }
  }
  // Update State
  m_accumulatedDistance += dist;

  // Update Remainder
  m_remainder = dist - (coveredDist - spacing);
  if (m_remainder < 0)
    m_remainder = 0;

  m_lastPos = currentPos;
}

void BrushEngine::endStroke() {
  // Cleanup or finish
}

void BrushEngine::renderDab(float x, float y, float size, float rotation,
                            const Color &color, float hardness, float pressure,
                            int brushType, float wetness) {
  if (!m_renderer) {
    m_renderer = new StrokeRenderer();
    m_renderer->initialize();
  }

  m_renderer->drawDab(x, y, size, rotation, color.r / 255.0f, color.g / 255.0f,
                      color.b / 255.0f, color.a / 255.0f, hardness, pressure, 0,
                      brushType, wetness);
}

void BrushEngine::renderStrokeSegment(float x1, float y1, float x2, float y2,
                                      float pressure, float tilt,
                                      float velocity, bool useTexture) {
  StrokePoint start(x1, y1, pressure);
  StrokePoint end(x2, y2, pressure);
  beginStroke(start);
  continueStroke(end);
}

void BrushEngine::paintSoftStamp(QPainter *painter, const QPointF &point,
                                 float size, float opacity, const QColor &color,
                                 float hardness) {
  painter->setPen(Qt::NoPen);
  painter->setOpacity(opacity);

  QRadialGradient gradient(point, size / 2.0);
  QColor c = color;

  if (hardness >= 0.99f) {
    gradient.setColorAt(0.0, c);
    gradient.setColorAt(0.95, c);
    c.setAlpha(0);
    gradient.setColorAt(1.0, c);
  } else {
    // Generate a smooth cosine-like gradient with 10 stops to match the GPU
    // shader
    gradient.setColorAt(0.0, c);
    if (hardness > 0.0f) {
      gradient.setColorAt(hardness, c);
    }

    int steps = 10;
    for (int i = 1; i <= steps; ++i) {
      float t = static_cast<float>(i) / steps; // 0 to 1
      float stop = std::min(1.0f, hardness + t * (1.0f - hardness));

      // Cosine curve: 0.5 * (1.0 + cos(t * pi))
      float alphaMult = 0.5f * (1.0f + std::cos(t * 3.14159265f));
      QColor stepColor = c;
      stepColor.setAlphaF(c.alphaF() * alphaMult);
      gradient.setColorAt(stop, stepColor);
    }
  }

  painter->setBrush(QBrush(gradient));
  painter->drawEllipse(point, size / 2.0, size / 2.0);
}

} // namespace artflow
