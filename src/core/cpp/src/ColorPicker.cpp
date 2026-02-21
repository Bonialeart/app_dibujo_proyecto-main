#include "ColorPicker.h"
#include "ColorPickerImpl.h"
#include <QDebug>
#include <QtMath>
#include <algorithm>

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
