#ifndef COLORPICKER_RENDERER_H
#define COLORPICKER_RENDERER_H

#include "ColorPicker.h"
#include <vector>

namespace ColorPickerUI {

/**
 * ColorPickerRenderer - Handles all rendering for the color picker modal
 * This is framework-agnostic and can be adapted to your rendering system
 * (ImGui, Qt, wxWidgets, custom OpenGL/Vulkan, etc.)
 */
class ColorPickerRenderer {
public:
    ColorPickerRenderer(ColorPickerModal& modal);
    
    // Main render function - call this every frame when modal is visible
    void render();
    
    // Set modal position and size
    void setPosition(int x, int y);
    void setSize(int width, int height);
    
    // Get dimensions
    int getWidth() const { return width_; }
    int getHeight() const { return height_; }
    
private:
    ColorPickerModal& modal_;
    
    // Modal dimensions and position
    int x_, y_;
    int width_, height_;
    
    // UI Layout constants
    static const int PANEL_PADDING = 16;
    static const int BUTTON_SIZE = 36;
    static const int COLOR_DISPLAY_SIZE = 48;
    static const int SLIDER_HEIGHT = 24;
    static const int SHADE_BOX_SIZE = 32;
    static const int HISTORY_BOX_SIZE = 28;
    
    // Rendering methods for different sections
    void renderHeader();
    void renderColorDisplay();
    void renderModeSelector();
    void renderMainColorArea();
    void renderQuickAccess();
    void renderFooter();
    
    // Mode-specific rendering
    void renderColorBox();
    void renderColorWheel();
    void renderColorSliders();
    void renderColorBook();
    
    // Quick access rendering
    void renderShades();
    void renderHistory();
    void renderPalettes();
    
    // Helper rendering functions
    void drawColorBox(int x, int y, int size, const Color& color, bool selected = false);
    void drawGradientRect(int x, int y, int width, int height, 
                          const Color& topLeft, const Color& topRight,
                          const Color& bottomLeft, const Color& bottomRight);
    void drawColorWheel(int centerX, int centerY, int radius);
    void drawSlider(int x, int y, int width, const ColorSlider& slider);
    void drawButton(int x, int y, int width, int height, const std::string& label, bool active = false);
    void drawText(int x, int y, const std::string& text, const Color& color = Color(1,1,1));
    void drawRect(int x, int y, int width, int height, const Color& color, bool filled = true);
    void drawCircle(int centerX, int centerY, int radius, const Color& color, bool filled = true);
    void drawRoundedRect(int x, int y, int width, int height, int radius, const Color& color);
    
    // Input state
    int mouseX_, mouseY_;
    bool mouseDown_;
    
    // Color wheel helper
    std::unique_ptr<ColorWheel> colorWheel_;
    
    // Slider helpers
    std::vector<std::unique_ptr<ColorSlider>> sliders_;
    
    // Hex input
    std::unique_ptr<HexInputField> hexInput_;
    
    // Selected shade type for dropdown
    bool shadeDropdownOpen_;
};

} // namespace ColorPickerUI

#endif // COLORPICKER_RENDERER_H
