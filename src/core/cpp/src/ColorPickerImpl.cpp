#include "ColorPickerImpl.h"
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <sstream>


// Define M_PI if not defined
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace ColorPickerUI {

// ============================================================================
// Color Implementation
// ============================================================================

void Color::toHSB(float &h, float &s, float &br) const {
  ColorUtils::RGBtoHSB(r, g, b, h, s, br);
}

Color Color::fromHSB(float h, float s, float br, float alpha) {
  Color c;
  ColorUtils::HSBtoRGB(h, s, br, c.r, c.g, c.b);
  c.a = alpha;
  return c;
}

std::string Color::toHex() const { return ColorUtils::RGBtoHex(r, g, b); }

Color Color::fromHex(const std::string &hex) {
  Color c;
  ColorUtils::HextoRGB(hex, c.r, c.g, c.b);
  return c;
}

void Color::toCMYK(float &c, float &m, float &y, float &k) const {
  ColorUtils::RGBtoCMYK(r, g, b, c, m, y, k);
}

Color Color::fromCMYK(float c, float m, float y, float k, float alpha) {
  Color color;
  ColorUtils::CMYKtoRGB(c, m, y, k, color.r, color.g, color.b);
  color.a = alpha;
  return color;
}

void Color::getRGB255(int &red, int &green, int &blue) const {
  red = static_cast<int>(r * 255.0f);
  green = static_cast<int>(g * 255.0f);
  blue = static_cast<int>(b * 255.0f);
}

// ============================================================================
// ColorPickerModal Implementation
// ============================================================================

ColorPickerModal::ColorPickerModal()
    : activeColor_(0.7f, 0.5f, 0.8f, 1.0f) // Default purple color
      ,
      primaryColor_(0.7f, 0.5f, 0.8f, 1.0f),
      secondaryColor_(1.0f, 1.0f, 1.0f, 1.0f), visible_(false),
      currentMode_(ColorMode::COLOR_BOX), currentSpace_(ColorSpace::HSB),
      currentShadeType_(ShadeType::SHADE), isDragging_(false), dragStartX_(0),
      dragStartY_(0) {
  // Initialize default palette
  ColorPalette defaultPalette("Default");
  defaultPalette.colors = {
      Color(0.7f, 0.5f, 0.8f, 1.0f), // Purple
      Color(0.5f, 0.6f, 0.9f, 1.0f), // Light blue
      Color(0.3f, 0.5f, 0.3f, 1.0f), // Green
      Color(0.9f, 0.6f, 0.3f, 1.0f), // Orange
      Color(0.8f, 0.3f, 0.3f, 1.0f)  // Red
  };
  palettes_.push_back(defaultPalette);
  favoritePaletteName_ = "Default";
}

ColorPickerModal::~ColorPickerModal() {
  // Cleanup
}

void ColorPickerModal::show() { visible_ = true; }

void ColorPickerModal::hide() {
  visible_ = false;
  if (onModalClosed_) {
    onModalClosed_();
  }
}

void ColorPickerModal::setActiveColor(const Color &color) {
  activeColor_ = color;
  primaryColor_ = color;
  addToHistory(color);

  if (onColorChanged_) {
    onColorChanged_(color);
  }
}

void ColorPickerModal::setPrimaryColor(const Color &color) {
  primaryColor_ = color;
  activeColor_ = color;
  addToHistory(color);

  if (onColorChanged_) {
    onColorChanged_(color);
  }
}

void ColorPickerModal::setSecondaryColor(const Color &color) {
  secondaryColor_ = color;
}

void ColorPickerModal::swapPrimarySecondary() {
  Color temp = primaryColor_;
  primaryColor_ = secondaryColor_;
  secondaryColor_ = temp;
  activeColor_ = primaryColor_;

  if (onColorChanged_) {
    onColorChanged_(primaryColor_);
  }
}

void ColorPickerModal::setColorMode(ColorMode mode) { currentMode_ = mode; }

void ColorPickerModal::setColorSpace(ColorSpace space) {
  currentSpace_ = space;
}

void ColorPickerModal::setShadeType(ShadeType type) {
  currentShadeType_ = type;
}

std::vector<Color> ColorPickerModal::generateShades(int count) {
  std::vector<Color> shades;
  shades.reserve(count);

  for (int i = 0; i < count; ++i) {
    float amount = static_cast<float>(i) / static_cast<float>(count - 1);
    Color shade = adjustShade(activeColor_, currentShadeType_, amount);
    shades.push_back(shade);
  }

  return shades;
}

void ColorPickerModal::addToHistory(const Color &color) {
  // Check if color already exists in history
  for (const auto &c : colorHistory_) {
    if (std::abs(c.r - color.r) < 0.01f && std::abs(c.g - color.g) < 0.01f &&
        std::abs(c.b - color.b) < 0.01f) {
      return; // Color already in history
    }
  }

  colorHistory_.insert(colorHistory_.begin(), color);

  // Keep only last MAX_HISTORY colors
  if (colorHistory_.size() > MAX_HISTORY) {
    colorHistory_.resize(MAX_HISTORY);
  }
}

void ColorPickerModal::clearHistory() { colorHistory_.clear(); }

void ColorPickerModal::addPalette(const ColorPalette &palette) {
  // Check if palette already exists
  for (auto &p : palettes_) {
    if (p.name == palette.name) {
      p = palette; // Update existing palette
      return;
    }
  }
  palettes_.push_back(palette);
}

void ColorPickerModal::removePalette(const std::string &name) {
  palettes_.erase(
      std::remove_if(palettes_.begin(), palettes_.end(),
                     [&name](const ColorPalette &p) { return p.name == name; }),
      palettes_.end());
}

void ColorPickerModal::setFavoritePalette(const std::string &name) {
  for (const auto &p : palettes_) {
    if (p.name == name) {
      favoritePaletteName_ = name;
      return;
    }
  }
}

ColorPalette *ColorPickerModal::getFavoritePalette() {
  for (auto &p : palettes_) {
    if (p.name == favoritePaletteName_) {
      return &p;
    }
  }
  return palettes_.empty() ? nullptr : &palettes_[0];
}

void ColorPickerModal::setOnColorChanged(
    std::function<void(const Color &)> callback) {
  onColorChanged_ = callback;
}

void ColorPickerModal::setOnModalClosed(std::function<void()> callback) {
  onModalClosed_ = callback;
}

Color ColorPickerModal::adjustShade(const Color &base, ShadeType type,
                                    float amount) const {
  float h, s, b;
  base.toHSB(h, s, b);

  switch (type) {
  case ShadeType::SHADE:
    // Darken by reducing brightness
    b = b * (1.0f - amount);
    break;

  case ShadeType::TINT:
    // Lighten by increasing brightness and reducing saturation
    b = b + (1.0f - b) * amount;
    s = s * (1.0f - amount * 0.5f);
    break;

  case ShadeType::TONE:
    // Add gray by reducing saturation
    s = s * (1.0f - amount);
    break;

  case ShadeType::WARMER:
    // Shift hue towards orange/red
    h = h - amount * 30.0f;
    if (h < 0.0f)
      h += 360.0f;
    break;

  case ShadeType::COOLER:
    // Shift hue towards blue
    h = h + amount * 30.0f;
    if (h >= 360.0f)
      h -= 360.0f;
    break;

  case ShadeType::COMPLEMENTARY_TINT:
    h = std::fmod(h + 180.0f, 360.0f);
    b = b + (1.0f - b) * amount;
    s = s * (1.0f - amount * 0.5f);
    break;

  case ShadeType::COMPLEMENTARY_SHADE:
    h = std::fmod(h + 180.0f, 360.0f);
    b = b * (1.0f - amount);
    break;

  case ShadeType::ANALOGOUS:
    // Shift by ±30 degrees
    h = h + (amount - 0.5f) * 60.0f;
    if (h < 0.0f)
      h += 360.0f;
    if (h >= 360.0f)
      h -= 360.0f;
    break;
  }

  return Color::fromHSB(h, s, b, base.a);
}

Color ColorPickerModal::getComplementaryColor(const Color &color) const {
  float h, s, b;
  color.toHSB(h, s, b);
  h = std::fmod(h + 180.0f, 360.0f);
  return Color::fromHSB(h, s, b, color.a);
}

std::vector<Color>
ColorPickerModal::getAnalogousColors(const Color &color) const {
  std::vector<Color> colors;
  float h, s, b;
  color.toHSB(h, s, b);

  // Create analogous colors at ±30 degrees
  colors.push_back(
      Color::fromHSB(std::fmod(h + 330.0f, 360.0f), s, b, color.a));
  colors.push_back(color);
  colors.push_back(Color::fromHSB(std::fmod(h + 30.0f, 360.0f), s, b, color.a));

  return colors;
}

// Rendering Logic (stubs)
void ColorPickerModal::render() {}
void ColorPickerModal::renderColorBox() {}
void ColorPickerModal::renderColorWheel() {}
void ColorPickerModal::renderColorSliders() {}
void ColorPickerModal::renderColorBook() {}
void ColorPickerModal::renderShades() {}
void ColorPickerModal::renderHistory() {}
void ColorPickerModal::renderPalettes() {}

void ColorPickerModal::handleMouseDown(int x, int y) {}
void ColorPickerModal::handleMouseMove(int x, int y) {}
void ColorPickerModal::handleMouseUp(int x, int y) {}
void ColorPickerModal::handleKeyPress(int key) {}

// ============================================================================
// ColorUtils Implementation
// ============================================================================

void ColorUtils::HSBtoRGB(float h, float s, float b, float &r, float &g,
                          float &bl) {
  if (s == 0.0f) {
    r = g = bl = b;
    return;
  }

  h = std::fmod(h, 360.0f);
  if (h < 0.0f)
    h += 360.0f;

  float hh = h / 60.0f;
  int i = static_cast<int>(hh);
  float f = hh - i;

  float p = b * (1.0f - s);
  float q = b * (1.0f - s * f);
  float t = b * (1.0f - s * (1.0f - f));

  switch (i) {
  case 0:
    r = b;
    g = t;
    bl = p;
    break;
  case 1:
    r = q;
    g = b;
    bl = p;
    break;
  case 2:
    r = p;
    g = b;
    bl = t;
    break;
  case 3:
    r = p;
    g = q;
    bl = b;
    break;
  case 4:
    r = t;
    g = p;
    bl = b;
    break;
  default:
    r = b;
    g = p;
    bl = q;
    break;
  }
}

void ColorUtils::RGBtoHSB(float r, float g, float b, float &h, float &s,
                          float &br) {
  float maxVal = std::max({r, g, b});
  float minVal = std::min({r, g, b});
  float delta = maxVal - minVal;

  br = maxVal;

  if (maxVal == 0.0f || delta == 0.0f) {
    s = 0.0f;
    h = 0.0f;
    return;
  }

  s = delta / maxVal;

  if (r == maxVal) {
    h = 60.0f * std::fmod((g - b) / delta, 6.0f);
  } else if (g == maxVal) {
    h = 60.0f * ((b - r) / delta + 2.0f);
  } else {
    h = 60.0f * ((r - g) / delta + 4.0f);
  }

  if (h < 0.0f)
    h += 360.0f;
}

void ColorUtils::RGBtoCMYK(float r, float g, float b, float &c, float &m,
                           float &y, float &k) {
  k = 1.0f - std::max({r, g, b});

  if (k == 1.0f) {
    c = m = y = 0.0f;
    return;
  }

  c = (1.0f - r - k) / (1.0f - k);
  m = (1.0f - g - k) / (1.0f - k);
  y = (1.0f - b - k) / (1.0f - k);
}

void ColorUtils::CMYKtoRGB(float c, float m, float y, float k, float &r,
                           float &g, float &b) {
  r = (1.0f - c) * (1.0f - k);
  g = (1.0f - m) * (1.0f - k);
  b = (1.0f - y) * (1.0f - k);
}

std::string ColorUtils::RGBtoHex(float r, float g, float b) {
  int ri = clampInt(static_cast<int>(r * 255), 0, 255);
  int gi = clampInt(static_cast<int>(g * 255), 0, 255);
  int bi = clampInt(static_cast<int>(b * 255), 0, 255);

  std::stringstream ss;
  ss << std::hex << std::uppercase << std::setfill('0');
  ss << std::setw(2) << ri << std::setw(2) << gi << std::setw(2) << bi;
  return ss.str();
}

void ColorUtils::HextoRGB(const std::string &hex, float &r, float &g,
                          float &b) {
  std::string hexStr = hex;
  if (hexStr[0] == '#')
    hexStr = hexStr.substr(1);

  if (hexStr.length() != 6) {
    r = g = b = 0.0f;
    return;
  }

  int ri, gi, bi;
  std::stringstream ss;
  ss << std::hex << hexStr.substr(0, 2);
  ss >> ri;
  ss.clear();
  ss << std::hex << hexStr.substr(2, 2);
  ss >> gi;
  ss.clear();
  ss << std::hex << hexStr.substr(4, 2);
  ss >> bi;

  r = ri / 255.0f;
  g = gi / 255.0f;
  b = bi / 255.0f;
}

Color ColorUtils::lerp(const Color &a, const Color &b, float t) {
  t = clamp(t, 0.0f, 1.0f);
  return Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
               a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
}

float ColorUtils::clamp(float value, float min, float max) {
  return std::max(min, std::min(max, value));
}

int ColorUtils::clampInt(int value, int min, int max) {
  return std::max(min, std::min(max, value));
}

} // namespace ColorPickerUI
