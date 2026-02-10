# Modern Color Picker System for C++

A comprehensive, feature-rich color picker modal system inspired by professional drawing applications like Procreate. Designed to be framework-agnostic and easily integrated into any C++ GUI application.

![Color Picker Modes](docs/color_picker_preview.png)

## Features

### 🎨 Multiple Color Selection Modes

1. **Color Box** - 2D gradient selector with hue slider
2. **Color Wheel** - Traditional color wheel with inner saturation/brightness area
3. **Color Sliders** - Precise control with HSB, RGB, or CMYK sliders
4. **Color Book** - Browse predefined palettes and color cards

### 🌈 Color Manipulation

- **10 Shade Variations**: Generate smooth transitions from light to dark
- **Shade Types**:
  - Shade (darken)
  - Tint (lighten)
  - Tone (add gray)
  - Warmer (shift towards red/orange)
  - Cooler (shift towards blue)
  - Complementary Tint/Shade
  - Analogous Palette

### 📊 Color Spaces

- **HSB** (Hue, Saturation, Brightness)
- **RGB** (Red, Green, Blue) with 0-255 values
- **CMYK** (Cyan, Magenta, Yellow, Key/Black)
- **Hexadecimal** (web-safe color codes)

### 💾 Color Management

- **History**: Track last 10 colors used
- **Palettes**: Create and save custom color palettes
- **Favorite Palette**: Quick access to your most-used palette
- **Primary/Secondary Colors**: Manage foreground and background colors

## Installation

### Basic Integration

1. Copy the following files to your project:
   ```
   ColorPicker.h
   ColorPicker.cpp
   ColorPickerRenderer.h
   ColorPickerRenderer.cpp
   ```

2. Include the header:
   ```cpp
   #include "ColorPicker.h"
   #include "ColorPickerRenderer.h"
   ```

3. Compile with C++11 or later:
   ```bash
   g++ -std=c++11 your_app.cpp ColorPicker.cpp ColorPickerRenderer.cpp -o your_app
   ```

## Quick Start

### Basic Usage

```cpp
using namespace ColorPickerUI;

// Create the color picker
ColorPickerModal colorPicker;
ColorPickerRenderer renderer(colorPicker);

// Set initial color
colorPicker.setActiveColor(Color(0.7f, 0.5f, 0.8f)); // Purple

// Setup callback
colorPicker.setOnColorChanged([](const Color& color) {
    std::cout << "Selected: #" << color.toHex() << std::endl;
});

// Show the picker
colorPicker.show();

// Render (call every frame)
if (colorPicker.isVisible()) {
    renderer.render();
}
```

### Color Space Conversions

```cpp
Color myColor(0.7f, 0.5f, 0.8f);

// To HSB
float h, s, b;
myColor.toHSB(h, s, b);

// To Hex
std::string hex = myColor.toHex(); // Returns "BB9BD3"

// From Hex
Color fromHex = Color::fromHex("FF5733");

// To CMYK
float c, m, y, k;
myColor.toCMYK(c, m, y, k);

// From HSB
Color hsbColor = Color::fromHSB(270.0f, 0.5f, 0.8f);
```

### Working with Shades

```cpp
// Generate 10 darker shades
colorPicker.setShadeType(ShadeType::SHADE);
auto darkShades = colorPicker.generateShades(10);

// Generate lighter tints
colorPicker.setShadeType(ShadeType::TINT);
auto lightShades = colorPicker.generateShades(10);

// Warmer variations
colorPicker.setShadeType(ShadeType::WARMER);
auto warmerShades = colorPicker.generateShades(10);
```

### Managing Palettes

```cpp
// Create a custom palette
ColorPalette naturePalette("Nature");
naturePalette.colors = {
    Color(0.2f, 0.5f, 0.2f),  // Forest green
    Color(0.4f, 0.3f, 0.1f),  // Earth brown
    Color(0.5f, 0.7f, 0.9f),  // Sky blue
};

// Add to color picker
colorPicker.addPalette(naturePalette);

// Set as favorite
colorPicker.setFavoritePalette("Nature");

// Access favorite palette
ColorPalette* favorite = colorPicker.getFavoritePalette();
```

### Color History

```cpp
// Colors are automatically added to history when selected
colorPicker.addToHistory(Color(1.0f, 0.0f, 0.0f));

// Get history (max 10 colors)
auto history = colorPicker.getHistory();

// Clear history
colorPicker.clearHistory();
```

## API Reference

### ColorPickerModal Class

#### Core Methods

| Method | Description |
|--------|-------------|
| `show()` | Display the color picker modal |
| `hide()` | Hide the color picker modal |
| `isVisible()` | Check if modal is currently visible |
| `setActiveColor(color)` | Set the currently selected color |
| `getActiveColor()` | Get the currently selected color |

#### Color Management

| Method | Description |
|--------|-------------|
| `setPrimaryColor(color)` | Set primary (foreground) color |
| `getPrimaryColor()` | Get primary color |
| `setSecondaryColor(color)` | Set secondary (background) color |
| `getSecondaryColor()` | Get secondary color |
| `swapPrimarySecondary()` | Swap primary and secondary colors |

#### Mode Control

| Method | Description |
|--------|-------------|
| `setColorMode(mode)` | Switch color selection mode |
| `getColorMode()` | Get current mode |
| `setColorSpace(space)` | Set color space for sliders |
| `getColorSpace()` | Get current color space |

#### Shade Generation

| Method | Description |
|--------|-------------|
| `setShadeType(type)` | Set shade generation type |
| `getShadeType()` | Get current shade type |
| `generateShades(count)` | Generate shade variations |

#### History & Palettes

| Method | Description |
|--------|-------------|
| `addToHistory(color)` | Add color to history |
| `getHistory()` | Get color history |
| `clearHistory()` | Clear color history |
| `addPalette(palette)` | Add a color palette |
| `removePalette(name)` | Remove a palette |
| `setFavoritePalette(name)` | Set favorite palette |
| `getFavoritePalette()` | Get favorite palette |

#### Callbacks

| Method | Description |
|--------|-------------|
| `setOnColorChanged(callback)` | Called when color changes |
| `setOnModalClosed(callback)` | Called when modal closes |

### Color Class

```cpp
struct Color {
    float r, g, b, a; // 0.0 - 1.0
    
    Color(float r, float g, float b, float a = 1.0f);
    
    // Conversions
    void toHSB(float& h, float& s, float& b);
    static Color fromHSB(float h, float s, float b, float a = 1.0f);
    
    std::string toHex();
    static Color fromHex(const std::string& hex);
    
    void toCMYK(float& c, float& m, float& y, float& k);
    static Color fromCMYK(float c, float m, float y, float k, float a = 1.0f);
    
    void getRGB255(int& r, int& g, int& b);
};
```

### Enumerations

#### ColorMode
```cpp
enum class ColorMode {
    COLOR_BOX,      // 2D gradient box
    COLOR_WHEEL,    // Traditional color wheel
    COLOR_SLIDERS,  // HSB/RGB/CMYK sliders
    COLOR_BOOK      // Predefined palettes
};
```

#### ColorSpace
```cpp
enum class ColorSpace {
    HSB,   // Hue, Saturation, Brightness
    RGB,   // Red, Green, Blue
    CMYK   // Cyan, Magenta, Yellow, Key
};
```

#### ShadeType
```cpp
enum class ShadeType {
    SHADE,                  // Darken
    TINT,                   // Lighten
    TONE,                   // Add gray
    WARMER,                 // Shift to warmer tones
    COOLER,                 // Shift to cooler tones
    COMPLEMENTARY_TINT,     // Complementary + lighten
    COMPLEMENTARY_SHADE,    // Complementary + darken
    ANALOGOUS               // Adjacent colors
};
```

## Framework Integration

### Qt Integration

```cpp
void QtWidget::paintEvent(QPaintEvent* event) {
    QPainter painter(this);
    
    if (colorPicker.isVisible()) {
        // Adapt renderer drawing calls to QPainter
        // Example: renderer.drawRect() -> painter.drawRect()
    }
}
```

### wxWidgets Integration

```cpp
void MyFrame::OnPaint(wxPaintEvent& event) {
    wxPaintDC dc(this);
    
    if (colorPicker.isVisible()) {
        // Adapt renderer drawing calls to wxDC
    }
}
```

### ImGui Integration

```cpp
void RenderColorPicker() {
    if (!colorPicker.isVisible()) return;
    
    ImGui::Begin("Color Picker");
    // Use ImGui's color widgets or custom rendering
    ImGui::End();
}
```

### Custom OpenGL/Vulkan

The renderer provides abstract drawing methods that you can implement:
- `drawRect()` - Draw filled/outlined rectangles
- `drawCircle()` - Draw filled/outlined circles
- `drawText()` - Render text
- `drawRoundedRect()` - Draw rounded rectangles
- `drawGradientRect()` - Draw gradient fills

## Customization

### Styling

You can customize the appearance by modifying the constants in `ColorPickerRenderer.h`:

```cpp
static const int PANEL_PADDING = 16;
static const int BUTTON_SIZE = 36;
static const int COLOR_DISPLAY_SIZE = 48;
static const int SLIDER_HEIGHT = 24;
```

### Custom Rendering

Override the drawing methods in `ColorPickerRenderer`:

```cpp
class MyCustomRenderer : public ColorPickerRenderer {
protected:
    void drawRect(int x, int y, int w, int h, const Color& c, bool filled) override {
        // Your custom rendering code
    }
};
```

## Advanced Features

### ColorDrop Functionality

To implement ColorDrop (drag color to canvas to fill):

```cpp
// In your canvas drawing code
void onColorDrop(int x, int y, const Color& color) {
    floodFill(x, y, color);
}

// Detect drag from color picker
if (isDraggingFromColorPicker) {
    Color activeColor = colorPicker.getActiveColor();
    onColorDrop(mouseX, mouseY, activeColor);
}
```

### Eyedropper Tool

```cpp
void sampleColorFromCanvas(int x, int y) {
    Color sampledColor = getPixelColor(x, y);
    colorPicker.setActiveColor(sampledColor);
}
```

## Requirements

- C++11 or later
- Standard Library (no external dependencies for core functionality)
- GUI framework of your choice for rendering

## Performance Notes

- Color conversions are optimized for real-time use
- Shade generation is cached until color or type changes
- History uses efficient ring buffer implementation
- Minimal memory footprint (~1KB for core state)

## License

This color picker system is provided as-is for integration into your projects.

## Contributing

To adapt this for your specific framework:

1. Implement the drawing primitives in `ColorPickerRenderer`
2. Add input handling for mouse/touch events
3. Integrate with your application's event loop

## Examples

See `example_usage.cpp` for complete working examples including:
- Basic integration
- Color space conversions
- Shade generation
- Palette management
- Framework-specific adaptations

## Support

For issues or questions:
- Review the example code in `example_usage.cpp`
- Check the API reference above
- Ensure your drawing primitives are correctly implemented

## Roadmap

Potential future enhancements:
- Gradient editor
- Color harmony suggestions
- Recently used palettes
- Import/export palettes
- Color blindness simulation
- Undo/redo for color changes
