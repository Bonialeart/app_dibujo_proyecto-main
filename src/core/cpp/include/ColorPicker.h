#ifndef COLORPICKER_H
#define COLORPICKER_H

#include <QColor>
#include <QList>
#include <QObject>
#include <QString>
#include <QVariant>
#include <QVector>


// Forward declare implementation class to avoid exposing implementation details
namespace ColorPickerUI {
class ColorPickerModal;
}

class ColorPicker : public QObject {
  Q_OBJECT
  Q_PROPERTY(QColor activeColor READ activeColor WRITE setActiveColor NOTIFY
                 activeColorChanged)
  Q_PROPERTY(QColor secondaryColor READ secondaryColor WRITE setSecondaryColor
                 NOTIFY secondaryColorChanged)
  Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
  Q_PROPERTY(QVariantList palettes READ palettes NOTIFY palettesChanged)

public:
  explicit ColorPicker(QObject *parent = nullptr);
  ~ColorPicker();

  enum ShadeType {
    SHADE,
    TINT,
    TONE,
    WARMER,
    COOLER,
    COMPLEMENTARY_TINT,
    COMPLEMENTARY_SHADE,
    ANALOGOUS
  };
  Q_ENUM(ShadeType)

  QColor activeColor() const;
  void setActiveColor(const QColor &color);

  QColor secondaryColor() const;
  void setSecondaryColor(const QColor &color);

  QVariantList history() const;
  QVariantList palettes() const;

  Q_INVOKABLE void addToHistory(const QColor &color);
  Q_INVOKABLE void clearHistory();

  // Updated signature: taking a base color allows QML to trigger updates
  // reactively
  Q_INVOKABLE QVariantList generateShades(int count, int type,
                                          const QColor &color);

  Q_INVOKABLE void addPalette(const QString &name, const QVariantList &colors);
  Q_INVOKABLE void removePalette(const QString &name);

  // Color Space Conversions (Utility)
  Q_INVOKABLE QVariantList colorToHSB(const QColor &color);  // [h, s, b]
  Q_INVOKABLE QVariantList colorToCMYK(const QColor &color); // [c, m, y, k]
  Q_INVOKABLE QColor colorFromHSB(float h, float s, float b);
  Q_INVOKABLE QColor colorFromCMYK(float c, float m, float y, float k);

signals:
  void activeColorChanged();
  void secondaryColorChanged();
  void historyChanged();
  void palettesChanged();

private:
  ColorPickerUI::ColorPickerModal *m_impl;
};

#endif // COLORPICKER_H
