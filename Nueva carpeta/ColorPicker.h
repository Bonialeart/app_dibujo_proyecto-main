#ifndef COLORPICKER_H
#define COLORPICKER_H

#include <string>
#include <vector>
#include <functional>
#include <memory>
#include <array>

// Forward declarations for GUI framework compatibility
// Replace with your actual GUI framework includes (Qt, wxWidgets, ImGui, etc.)

namespace ColorPickerUI {

// Color representation structure
struct Color {
    float r, g, b, a; // RGBA values (0.0 - 1.0)
    
    Color(float red = 0.0f, float green = 0.0f, float blue = 0.0f, float alpha = 1.0f)
        : r(red), g(green), b(blue), a(alpha) {}
    
    // Convert to HSB
    void toHSB(float& h, float& s, float& br) const;
    
    // Create from HSB
    static Color fromHSB(float h, float s, float br, float alpha = 1.0f);
    
    // Convert to Hex
    std::string toHex() const;
    
    // Create from Hex
    static Color fromHex(const std::string& hex);
    
    // Convert to CMYK
    void toCMYK(float& c, float& m, float& y, float& k) const;
    
    // Create from CMYK
    static Color fromCMYK(float c, float m, float y, float k, float alpha = 1.0f);
    
    // Get RGB values as 0-255 integers
    void getRGB255(int& red, int& green, int& blue) const;
};

// Color shade variations
enum class ShadeType {
    SHADE,           // Darken
    TINT,            // Lighten
    TONE,            // Add gray
    WARMER,          // Shift to warmer tones
    COOLER,          // Shift to cooler tones
    COMPLEMENTARY_TINT,
    COMPLEMENTARY_SHADE,
    ANALOGOUS
};

// Color selection mode
enum class ColorMode {
    COLOR_BOX,       // 2D gradient box
    COLOR_WHEEL,     // Traditional color wheel
    COLOR_SLIDERS,   // HSB/RGB/CMYK sliders
    COLOR_BOOK       // Predefined palettes
};

// Color space for sliders
enum class ColorSpace {
    HSB,  // Hue, Saturation, Brightness
    RGB,  // Red, Green, Blue
    CMYK  // Cyan, Magenta, Yellow, Key (Black)
};

// Color palette structure
struct ColorPalette {
    std::string name;
    std::vector<Color> colors;
    
    ColorPalette(const std::string& paletteName = "Default") 
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
    void setActiveColor(const Color& color);
    
    // Get/Set primary and secondary colors
    Color getPrimaryColor() const { return primaryColor_; }
    void setPrimaryColor(const Color& color);
    Color getSecondaryColor() const { return secondaryColor_; }
    void setSecondaryColor(const Color& color);
    
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
    void addToHistory(const Color& color);
    std::vector<Color> getHistory() const { return colorHistory_; }
    void clearHistory();
    
    // Palette management
    void addPalette(const ColorPalette& palette);
    void removePalette(const std::string& name);
    void setFavoritePalette(const std::string& name);
    std::vector<ColorPalette> getPalettes() const { return palettes_; }
    ColorPalette* getFavoritePalette();
    
    // Callbacks
    void setOnColorChanged(std::function<void(const Color&)> callback);
    void setOnModalClosed(std::function<void()> callback);
    
    // Rendering (to be implemented with your GUI framework)
    void render();
    
    // Input handling
    void handleMouseDown(int x, int y);
    void handleMouseMove(int x, int y);
    void handleMouseUp(int x, int y);
    void handleKeyPress(int key);
    
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
    std::function<void(const Color&)> onColorChanged_;
    std::function<void()> onModalClosed_;
    
    // UI state
    bool isDragging_;
    int dragStartX_, dragStartY_;
    
    // Helper methods for color manipulation
    Color adjustShade(const Color& base, ShadeType type, float amount) const;
    Color getComplementaryColor(const Color& color) const;
    std::vector<Color> getAnalogousColors(const Color& color) const;
    
    // Rendering helpers (implement based on your framework)
    void renderColorBox();
    void renderColorWheel();
    void renderColorSliders();
    void renderColorBook();
    void renderShades();
    void renderHistory();
    void renderPalettes();
};

// Color Wheel Component
class ColorWheel {
public:
    ColorWheel(int centerX, int centerY, int radius);
    
    void render();
    bool handleClick(int x, int y, Color& outColor);
    void setActiveColor(const Color& color);
    
    // Color wheel modes
    enum class WheelMode {
        SATURATION,
        BRIGHTNESS,
        RED,
        GREEN,
        BLUE
    };
    
    void setWheelMode(WheelMode mode) { mode_ = mode; }
    WheelMode getWheelMode() const { return mode_; }
    
private:
    int centerX_, centerY_, radius_;
    WheelMode mode_;
    float selectedHue_;
    float selectedValue_;
    
    // Helper methods
    bool isInHueRing(int x, int y) const;
    bool isInInnerCircle(int x, int y) const;
    float calculateHue(int x, int y) const;
    void calculateSaturationBrightness(int x, int y, float& s, float& b) const;
};

// Color Slider Component
class ColorSlider {
public:
    enum class SliderType {
        HUE, SATURATION, BRIGHTNESS,
        RED, GREEN, BLUE,
        CYAN, MAGENTA, YELLOW, KEY
    };
    
    ColorSlider(SliderType type, int x, int y, int width);
    
    void render();
    bool handleClick(int mouseX, int mouseY);
    void setValue(float value);
    float getValue() const { return value_; }
    
    void setLabel(const std::string& label) { label_ = label; }
    std::string getLabel() const { return label_; }
    
private:
    SliderType type_;
    int x_, y_, width_;
    float value_; // 0.0 - 1.0
    std::string label_;
    bool isDragging_;
    
    Color getGradientColor(float position) const;
};

// Hex input field
class HexInputField {
public:
    HexInputField(int x, int y, int width);
    
    void render();
    void setText(const std::string& hex);
    std::string getText() const { return hexValue_; }
    
    bool handleKeyPress(int key);
    bool isValidHex() const;
    
    void setOnValueChanged(std::function<void(const std::string&)> callback);
    
private:
    int x_, y_, width_;
    std::string hexValue_;
    bool isFocused_;
    std::function<void(const std::string&)> onValueChanged_;
};

// Utility functions
namespace ColorUtils {
    // HSB <-> RGB conversion
    void HSBtoRGB(float h, float s, float b, float& r, float& g, float& bl);
    void RGBtoHSB(float r, float g, float b, float& h, float& s, float& br);
    
    // RGB <-> CMYK conversion
    void RGBtoCMYK(float r, float g, float b, float& c, float& m, float& y, float& k);
    void CMYKtoRGB(float c, float m, float y, float k, float& r, float& g, float& b);
    
    // Hex conversion
    std::string RGBtoHex(float r, float g, float b);
    void HextoRGB(const std::string& hex, float& r, float& g, float& b);
    
    // Color manipulation
    Color lerp(const Color& a, const Color& b, float t);
    float clamp(float value, float min, float max);
    int clampInt(int value, int min, int max);
}

} // namespace ColorPickerUI

#endif // COLORPICKER_H
