#ifndef COLORPICKERIMPL_H
#define COLORPICKERIMPL_H

#include <algorithm>
#include <array>
#include <cmath>
#include <functional>
#include <memory>
#include <string>
#include <vector>


namespace ColorPickerUI {

// Color representation structure
struct Color {
  float r, g, b, a; // RGBA values (0.0 - 1.0)

  Color(float red = 0.0f, float green = 0.0f, float blue = 0.0f,
        float alpha = 1.0f)
      : r(red), g(green), b(blue), a(alpha) {}

  // Convert to HSB
  void toHSB(float &h, float &s, float &br) const;

  // Create from HSB
  static Color fromHSB(float h, float s, float br, float alpha = 1.0f);

  // Convert to Hex
  std::string toHex() const;

  // Create from Hex
  static Color fromHex(const std::string &hex);

  // Convert to CMYK
  void toCMYK(float &c, float &m, float &y, float &k) const;

  // Create from CMYK
  static Color fromCMYK(float c, float m, float y, float k, float alpha = 1.0f);

  // Get RGB values as 0-255 integers
  void getRGB255(int &red, int &green, int &blue) const;

  // Equality operator for convenience
  bool operator==(const Color &other) const {
    return std::abs(r - other.r) < 0.001f && std::abs(g - other.g) < 0.001f &&
           std::abs(b - other.b) < 0.001f && std::abs(a - other.a) < 0.001f;
  }
};

// Color shade variations
enum class ShadeType {
  SHADE,  // Darken
  TINT,   // Lighten
  TONE,   // Add gray
  WARMER, // Shift to warmer tones
  COOLER, // Shift to cooler tones
  COMPLEMENTARY_TINT,
  COMPLEMENTARY_SHADE,
  ANALOGOUS
};

// Color selection mode
enum class ColorMode {
  COLOR_BOX,     // 2D gradient box
  COLOR_WHEEL,   // Traditional color wheel
  COLOR_SLIDERS, // HSB/RGB/CMYK sliders
  COLOR_BOOK     // Predefined palettes
};

// Color space for sliders
enum class ColorSpace {
  HSB, // Hue, Saturation, Brightness
  RGB, // Red, Green, Blue
  CMYK // Cyan, Magenta, Yellow, Key (Black)
};

// Color palette structure
struct ColorPalette {
  std::string name;
  std::vector<Color> colors;

  ColorPalette(const std::string &paletteName = "Default")
      : name(paletteName) {}
};

// Main Color Picker Modal Class
class ColorPickerModal {
public:
  ColorPickerModal();
  ~ColorPickerModal();

  // Show/Hide modal
  void show();
  void hide();
  bool isVisible() const { return visible_; }

  // Get/Set active color
  Color getActiveColor() const { return activeColor_; }
  void setActiveColor(const Color &color);

  // Get/Set primary and secondary colors
  Color getPrimaryColor() const { return primaryColor_; }
  void setPrimaryColor(const Color &color);
  Color getSecondaryColor() const { return secondaryColor_; }
  void setSecondaryColor(const Color &color);

  // Switch between colors
  void swapPrimarySecondary();

  // Color mode management
  void setColorMode(ColorMode mode);
  ColorMode getColorMode() const { return currentMode_; }

  // Color space for sliders
  void setColorSpace(ColorSpace space);
  ColorSpace getColorSpace() const { return currentSpace_; }

  // Shade type management
  void setShadeType(ShadeType type);
  ShadeType getShadeType() const { return currentShadeType_; }
  std::vector<Color> generateShades(int count = 10);

  // History management
  void addToHistory(const Color &color);
  std::vector<Color> getHistory() const { return colorHistory_; }
  void clearHistory();

  // Palette management
  void addPalette(const ColorPalette &palette);
  void removePalette(const std::string &name);
  void setFavoritePalette(const std::string &name);
  std::vector<ColorPalette> getPalettes() const { return palettes_; }
  ColorPalette *getFavoritePalette();

  // Callbacks
  void setOnColorChanged(std::function<void(const Color &)> callback);
  void setOnModalClosed(std::function<void()> callback);

  // Rendering (to be implemented with your GUI framework)
  void render();

  // Input handling
  void handleMouseDown(int x, int y);
  void handleMouseMove(int x, int y);
  void handleMouseUp(int x, int y);
  void handleKeyPress(int key);

  // Helpers exposed for layout/logic if needed
  Color adjustShade(const Color &base, ShadeType type, float amount) const;

private:
  // Active state
  Color activeColor_;
  Color primaryColor_;
  Color secondaryColor_;
  bool visible_;

  // Mode and state
  ColorMode currentMode_;
  ColorSpace currentSpace_;
  ShadeType currentShadeType_;

  // History (max 10 colors)
  std::vector<Color> colorHistory_;
  static const int MAX_HISTORY = 10;

  // Palettes
  std::vector<ColorPalette> palettes_;
  std::string favoritePaletteName_;

  // Callbacks
  std::function<void(const Color &)> onColorChanged_;
  std::function<void()> onModalClosed_;

  // UI state
  bool isDragging_;
  int dragStartX_, dragStartY_;

  // Helper methods for color manipulation
  // Color adjustShade(const Color& base, ShadeType type, float amount) const;
  // // Made public for direct access in wrapper
  Color getComplementaryColor(const Color &color) const;
  std::vector<Color> getAnalogousColors(const Color &color) const;

  // Rendering helpers (implement based on your framework)
  void renderColorBox();
  void renderColorWheel();
  void renderColorSliders();
  void renderColorBook();
  void renderShades();
  void renderHistory();
  void renderPalettes();
};

// Utility functions
namespace ColorUtils {
// HSB <-> RGB conversion
void HSBtoRGB(float h, float s, float b, float &r, float &g, float &bl);
void RGBtoHSB(float r, float g, float b, float &h, float &s, float &br);

// RGB <-> CMYK conversion
void RGBtoCMYK(float r, float g, float b, float &c, float &m, float &y,
               float &k);
void CMYKtoRGB(float c, float m, float y, float k, float &r, float &g,
               float &b);

// Hex conversion
std::string RGBtoHex(float r, float g, float b);
void HextoRGB(const std::string &hex, float &r, float &g, float &b);

// Color manipulation
Color lerp(const Color &a, const Color &b, float t);
float clamp(float value, float min, float max);
int clampInt(int value, int min, int max);
} // namespace ColorUtils

} // namespace ColorPickerUI

#endif // COLORPICKERIMPL_H
