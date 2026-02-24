#include "color_harmony.h"
#include <QtMath>
#include <algorithm>

namespace artflow {

ColorHarmony::ColorHarmony(QObject *parent) : QObject(parent) {}

// --- CMYK ---

QVariantMap ColorHarmony::rgbToCMYK(const QColor &color) const {
  qreal r = color.redF();
  qreal g = color.greenF();
  qreal b = color.blueF();

  qreal k = 1.0 - std::max({r, g, b});

  QVariantMap result;
  if (k >= 1.0) {
    result["c"] = 0.0;
    result["m"] = 0.0;
    result["y"] = 0.0;
    result["k"] = 1.0;
    return result;
  }

  qreal invK = 1.0 / (1.0 - k);
  result["c"] = (1.0 - r - k) * invK;
  result["m"] = (1.0 - g - k) * invK;
  result["y"] = (1.0 - b - k) * invK;
  result["k"] = k;
  return result;
}

QColor ColorHarmony::cmykToRGB(qreal c, qreal m, qreal y, qreal k) const {
  qreal r = (1.0 - c) * (1.0 - k);
  qreal g = (1.0 - m) * (1.0 - k);
  qreal b = (1.0 - y) * (1.0 - k);
  return QColor::fromRgbF(qBound(0.0, r, 1.0), qBound(0.0, g, 1.0),
                          qBound(0.0, b, 1.0), 1.0);
}

// --- Harmony ---

QVariantList ColorHarmony::getHarmonyColors(qreal hue, qreal sat, qreal val,
                                            const QString &mode) const {
  QVariantList result;

  // Primary color is always first
  result.append(QColor::fromHsvF(qBound(0.0, hue, 1.0), qBound(0.0, sat, 1.0),
                                 qBound(0.0, val, 1.0)));

  // Determine hue offsets based on mode
  QVector<qreal> offsets;

  if (mode == QStringLiteral("Complementary")) {
    offsets = {0.5};
  } else if (mode == QStringLiteral("Split Complementary")) {
    offsets = {0.41, 0.59};
  } else if (mode == QStringLiteral("Analogous")) {
    offsets = {0.917, 0.083}; // ≈ -30° and +30°
  } else if (mode == QStringLiteral("Triadic")) {
    offsets = {0.333, 0.666};
  } else if (mode == QStringLiteral("Square")) {
    offsets = {0.25, 0.5, 0.75};
  }

  for (qreal offset : offsets) {
    qreal h2 = std::fmod(hue + offset, 1.0);
    if (h2 < 0.0)
      h2 += 1.0;
    result.append(
        QColor::fromHsvF(h2, qBound(0.0, sat, 1.0), qBound(0.0, val, 1.0)));
  }

  return result;
}

// --- Comparison ---

QString ColorHarmony::toHex6(const QColor &color) const {
  int r = qBound(0, qRound(color.redF() * 255.0), 255);
  int g = qBound(0, qRound(color.greenF() * 255.0), 255);
  int b = qBound(0, qRound(color.blueF() * 255.0), 255);
  return QStringLiteral("#%1%2%3")
      .arg(r, 2, 16, QLatin1Char('0'))
      .arg(g, 2, 16, QLatin1Char('0'))
      .arg(b, 2, 16, QLatin1Char('0'))
      .toUpper();
}

bool ColorHarmony::colorsEqual(const QColor &c1, const QColor &c2) const {
  // Compare by 8-bit hex to avoid float precision issues
  // (same logic as the JavaScript toHex6 comparison)
  return toHex6(c1) == toHex6(c2);
}

bool ColorHarmony::isInList(const QColor &color,
                            const QVariantList &list) const {
  QString hex = toHex6(color);
  for (const QVariant &v : list) {
    if (v.canConvert<QColor>()) {
      if (toHex6(v.value<QColor>()) == hex)
        return true;
    }
  }
  return false;
}

} // namespace artflow
