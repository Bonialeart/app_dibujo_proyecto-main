#ifndef COLOR_HARMONY_H
#define COLOR_HARMONY_H

#include <QColor>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

namespace artflow {

/**
 * ColorHarmony - Color math utilities exposed to QML.
 *
 * Moves the JavaScript color calculation functions from ColorStudioDialog.qml
 * to native C++ for better performance and reusability.
 *
 * Functions:
 *  - RGB ↔ CMYK conversion
 *  - Color harmony generation (Complementary, Analogous, Triadic, etc.)
 *  - Color comparison (hex-rounded, avoids float precision issues)
 *  - Hex string formatting
 */
class ColorHarmony : public QObject {
  Q_OBJECT

public:
  explicit ColorHarmony(QObject *parent = nullptr);

  // --- CMYK Conversion ---
  // Returns {c, m, y, k} as a QVariantMap with keys "c","m","y","k"
  Q_INVOKABLE QVariantMap rgbToCMYK(const QColor &color) const;

  // Returns QColor from CMYK values (0.0 - 1.0 each)
  Q_INVOKABLE QColor cmykToRGB(qreal c, qreal m, qreal y, qreal k) const;

  // --- Harmony Generation ---
  // Returns a list of QColors based on the harmony mode.
  // The first color in the list is always the primary (input) color.
  // Modes: "Complementary", "Split Complementary", "Analogous",
  //        "Triadic", "Square"
  Q_INVOKABLE QVariantList getHarmonyColors(qreal hue, qreal sat, qreal val,
                                            const QString &mode) const;

  // --- Color Comparison ---
  // Compares two colors by rounding to 8-bit hex to avoid float noise.
  Q_INVOKABLE bool colorsEqual(const QColor &c1, const QColor &c2) const;

  // --- Hex Formatting ---
  // Returns uppercase hex string like "#FF00AA"
  Q_INVOKABLE QString toHex6(const QColor &color) const;

  // Check if a color is already in a list (using hex-rounded comparison)
  Q_INVOKABLE bool isInList(const QColor &color,
                            const QVariantList &list) const;
};

} // namespace artflow

#endif // COLOR_HARMONY_H
