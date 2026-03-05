#include "ColorPicker.h"
#include "ColorPickerImpl.h"
#include <QDebug>
#include <QtMath>
#include <algorithm>
#include <QImage>
#include <QUrl>
#include <cmath>
#include <random>

using namespace ColorPickerUI;

// Helper conversions
static Color qColorToImpl(const QColor &c) {
  return Color(c.redF(), c.greenF(), c.blueF(), c.alphaF());
}

static QColor implToQColor(const Color &c) {
  return QColor::fromRgbF(c.r, c.g, c.b, c.a);
}

ColorPicker::ColorPicker(QObject *parent)
    : QObject(parent), m_impl(new ColorPickerModal()) {
  // Setup callbacks
  m_impl->setOnColorChanged([this](const Color &c) {
    emit activeColorChanged();
    emit historyChanged();
  });
}

ColorPicker::~ColorPicker() { delete m_impl; }

QColor ColorPicker::activeColor() const {
  return implToQColor(m_impl->getActiveColor());
}

void ColorPicker::setActiveColor(const QColor &color) {
  Color c = qColorToImpl(color);
  if (m_impl->getActiveColor() == c)
    return;

  m_impl->setActiveColor(c);
  emit activeColorChanged();
  emit historyChanged();
}

QColor ColorPicker::secondaryColor() const {
  return implToQColor(m_impl->getSecondaryColor());
}

void ColorPicker::setSecondaryColor(const QColor &color) {
  Color c = qColorToImpl(color);
  if (m_impl->getSecondaryColor() == c)
    return;

  m_impl->setSecondaryColor(c);
  emit secondaryColorChanged();
}

QVariantList ColorPicker::history() const {
  QVariantList list;
  auto hist = m_impl->getHistory();
  for (const auto &c : hist) {
    list.append(implToQColor(c));
  }
  return list;
}

void ColorPicker::addToHistory(const QColor &color) {
  m_impl->addToHistory(qColorToImpl(color));
  emit historyChanged();
}

void ColorPicker::clearHistory() {
  m_impl->clearHistory();
  emit historyChanged();
}

QVariantList ColorPicker::palettes() const {
  QVariantList list;
  auto pals = m_impl->getPalettes();
  for (const auto &p : pals) {
    QVariantMap map;
    map["name"] = QString::fromStdString(p.name);
    QVariantList colors;
    for (const auto &c : p.colors) {
      colors.append(implToQColor(c));
    }
    map["colors"] = colors;
    list.append(map);
  }
  return list;
}

void ColorPicker::addPalette(const QString &name, const QVariantList &colors) {
  ColorPalette p(name.toStdString());
  for (const QVariant &v : colors) {
    if (v.canConvert<QColor>()) {
      p.colors.push_back(qColorToImpl(v.value<QColor>()));
    }
  }
  m_impl->addPalette(p);
  emit palettesChanged();
}

void ColorPicker::removePalette(const QString &name) {
  m_impl->removePalette(name.toStdString());
  emit palettesChanged();
}

QVariantList ColorPicker::generateShades(int count, int type,
                                         const QColor &color) {
  QVariantList shades;
  if (count <= 0)
    return shades;

  // Convert int type to enum
  ShadeType st = static_cast<ShadeType>(type);
  ColorPickerUI::ShadeType implType;

  switch (st) {
  case SHADE:
    implType = ColorPickerUI::ShadeType::SHADE;
    break;
  case TINT:
    implType = ColorPickerUI::ShadeType::TINT;
    break;
  case TONE:
    implType = ColorPickerUI::ShadeType::TONE;
    break;
  case WARMER:
    implType = ColorPickerUI::ShadeType::WARMER;
    break;
  case COOLER:
    implType = ColorPickerUI::ShadeType::COOLER;
    break;
  case COMPLEMENTARY_TINT:
    implType = ColorPickerUI::ShadeType::COMPLEMENTARY_TINT;
    break;
  case COMPLEMENTARY_SHADE:
    implType = ColorPickerUI::ShadeType::COMPLEMENTARY_SHADE;
    break;
  case ANALOGOUS:
    implType = ColorPickerUI::ShadeType::ANALOGOUS;
    break;
  default:
    implType = ColorPickerUI::ShadeType::SHADE;
    break;
  }

  // We use the exposed adjustShade helper to generate shades without modifying
  // global state This allows QML to request shades for any color (e.g. for
  // previews)
  Color base = qColorToImpl(color);

  for (int i = 0; i < count; ++i) {
    // Fix for count=1 division by zero
    float amount = (count > 1)
                       ? static_cast<float>(i) / static_cast<float>(count - 1)
                       : 0.0f;

    Color c = m_impl->adjustShade(base, implType, amount);
    shades.append(implToQColor(c));
  }

  return shades;
}

QVariantList ColorPicker::colorToHSB(const QColor &color) {
  QVariantList list;
  float h, s, b;
  Color c = qColorToImpl(color);
  c.toHSB(h, s, b);
  list << h << s << b;
  return list;
}

QVariantList ColorPicker::colorToCMYK(const QColor &color) {
  QVariantList list;
  float c, m, y, k;
  Color col = qColorToImpl(color);
  col.toCMYK(c, m, y, k);
  list << c << m << y << k;
  return list;
}

QColor ColorPicker::colorFromHSB(float h, float s, float b) {
  return implToQColor(Color::fromHSB(h, s, b));
}

QColor ColorPicker::colorFromCMYK(float c, float m, float y, float k) {
  return implToQColor(Color::fromCMYK(c, m, y, k));
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Color Extraction — K-Means Clustering
// ─────────────────────────────────────────────────────────────────────────────
QVariantList ColorPicker::extractColorsFromImage(const QString &path, int count) {
    QVariantList result;
    if (path.isEmpty() || count <= 0) return result;

    // Handle file:// URLs from QML FileDialog
    QString localPath = path;
    if (localPath.startsWith("file:///")) {
#ifdef Q_OS_WIN
        localPath = localPath.mid(8); // remove "file:///"
#else
        localPath = localPath.mid(7); // remove "file://"
#endif
    } else if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QImage img(localPath);
    if (img.isNull()) {
        qWarning() << "[ColorPicker] Could not load image:" << localPath;
        return result;
    }

    // Scale down for performance: max 256×256
    const int maxDim = 256;
    if (img.width() > maxDim || img.height() > maxDim) {
        img = img.scaled(maxDim, maxDim, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    img = img.convertToFormat(QImage::Format_RGB32);

    // Sample pixels in a regular grid (skip nearly-black and nearly-white)
    struct Vec3 { float r, g, b; };
    std::vector<Vec3> pixels;
    pixels.reserve(4096);

    int step = std::max(1, static_cast<int>(std::sqrt(
        static_cast<float>(img.width() * img.height()) / 4096.0f)));

    for (int y = 0; y < img.height(); y += step) {
        const QRgb *line = reinterpret_cast<const QRgb *>(img.constScanLine(y));
        for (int x = 0; x < img.width(); x += step) {
            QRgb px = line[x];
            float r = qRed(px)   / 255.0f;
            float g = qGreen(px) / 255.0f;
            float b = qBlue(px)  / 255.0f;
            // Skip very dark (< 5% brightness) and very light (> 95%) neutrals
            float brightness = 0.299f*r + 0.587f*g + 0.114f*b;
            float saturation = std::max({r,g,b}) - std::min({r,g,b});
            if (brightness < 0.04f || (brightness > 0.96f && saturation < 0.05f)) continue;
            pixels.push_back({r, g, b});
        }
    }

    if (pixels.empty()) {
        qWarning() << "[ColorPicker] No usable pixels sampled from image.";
        return result;
    }

    // K-Means initialisation (k-means++)
    int k = std::min(count, static_cast<int>(pixels.size()));
    std::vector<Vec3> centers(k);
    std::mt19937 rng(42);

    // Pick first center randomly
    centers[0] = pixels[rng() % pixels.size()];

    // Pick remaining centers weighted by distance from nearest existing center
    for (int ci = 1; ci < k; ++ci) {
        std::vector<float> dist(pixels.size(), std::numeric_limits<float>::max());
        for (int pi = 0; pi < static_cast<int>(pixels.size()); ++pi) {
            for (int cj = 0; cj < ci; ++cj) {
                float dr = pixels[pi].r - centers[cj].r;
                float dg = pixels[pi].g - centers[cj].g;
                float db = pixels[pi].b - centers[cj].b;
                float d = dr*dr + dg*dg + db*db;
                if (d < dist[pi]) dist[pi] = d;
            }
        }
        // Weighted random pick
        float total = 0.0f;
        for (float d : dist) total += d;
        float threshold = std::uniform_real_distribution<float>(0.0f, total)(rng);
        float cum = 0.0f;
        int chosen = 0;
        for (int pi = 0; pi < static_cast<int>(pixels.size()); ++pi) {
            cum += dist[pi];
            if (cum >= threshold) { chosen = pi; break; }
        }
        centers[ci] = pixels[chosen];
    }

    // K-Means iterations
    std::vector<int> assignments(pixels.size(), 0);
    const int ITERS = 20;

    for (int iter = 0; iter < ITERS; ++iter) {
        // Assignment step
        bool changed = false;
        for (int pi = 0; pi < static_cast<int>(pixels.size()); ++pi) {
            float bestDist = std::numeric_limits<float>::max();
            int bestC = 0;
            for (int ci = 0; ci < k; ++ci) {
                float dr = pixels[pi].r - centers[ci].r;
                float dg = pixels[pi].g - centers[ci].g;
                float db = pixels[pi].b - centers[ci].b;
                float d = dr*dr + dg*dg + db*db;
                if (d < bestDist) { bestDist = d; bestC = ci; }
            }
            if (assignments[pi] != bestC) { assignments[pi] = bestC; changed = true; }
        }
        if (!changed) break;

        // Update step: recompute cluster centers
        std::vector<float> sumR(k, 0), sumG(k, 0), sumB(k, 0);
        std::vector<int> cnt(k, 0);
        for (int pi = 0; pi < static_cast<int>(pixels.size()); ++pi) {
            int ci = assignments[pi];
            sumR[ci] += pixels[pi].r;
            sumG[ci] += pixels[pi].g;
            sumB[ci] += pixels[pi].b;
            cnt[ci]++;
        }
        for (int ci = 0; ci < k; ++ci) {
            if (cnt[ci] > 0) {
                centers[ci] = {sumR[ci]/cnt[ci], sumG[ci]/cnt[ci], sumB[ci]/cnt[ci]};
            }
        }
    }

    // Count cluster sizes and sort by descending size (most dominant first)
    std::vector<int> clusterCount(k, 0);
    for (int a : assignments) clusterCount[a]++;
    std::vector<int> order(k);
    std::iota(order.begin(), order.end(), 0);
    std::sort(order.begin(), order.end(), [&](int a, int b){
        return clusterCount[a] > clusterCount[b];
    });

    // Build result, deduplicating very similar colors (threshold: ~0.07 Euclidean)
    std::vector<Vec3> unique;
    for (int ci : order) {
        if (clusterCount[ci] == 0) continue;
        Vec3 &c = centers[ci];
        bool dup = false;
        for (const Vec3 &u : unique) {
            float dr = c.r-u.r, dg = c.g-u.g, db = c.b-u.b;
            if (std::sqrt(dr*dr + dg*dg + db*db) < 0.07f) { dup = true; break; }
        }
        if (!dup) {
            unique.push_back(c);
            result.append(QColor::fromRgbF(
                static_cast<double>(c.r),
                static_cast<double>(c.g),
                static_cast<double>(c.b)
            ));
        }
        if (static_cast<int>(unique.size()) >= count) break;
    }

    qDebug() << "[ColorPicker] Extracted" << result.size() << "colors from" << localPath;
    return result;
}

