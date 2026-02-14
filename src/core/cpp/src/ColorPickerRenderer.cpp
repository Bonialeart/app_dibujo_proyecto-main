#include "ColorPickerRenderer.h"
#include <string>
#include <sstream>
#include <iomanip>

namespace ColorPickerUI {

ColorPickerRenderer::ColorPickerRenderer(ColorPickerModal& modal)
    : modal_(modal)
    , x_(100)
    , y_(100)
    , width_(420)
    , height_(600)
    , mouseX_(0)
    , mouseY_(0)
    , mouseDown_(false)
    , shadeDropdownOpen_(false)
{
    // Initialize color wheel
    colorWheel_ = std::make_unique<ColorWheel>(width_/2, 250, 120);
    
    // Initialize hex input
    hexInput_ = std::make_unique<HexInputField>(PANEL_PADDING, height_ - 100, 200);
}

void ColorPickerRenderer::setPosition(int x, int y) {
    x_ = x;
    y_ = y;
}

void ColorPickerRenderer::setSize(int width, int height) {
    width_ = width;
    height_ = height;
}

void ColorPickerRenderer::render() {
    if (!modal_.isVisible()) return;
    
    // Draw modal background with rounded corners
    drawRoundedRect(x_, y_, width_, height_, 12, Color(0.15f, 0.15f, 0.15f, 0.98f));
    
    // Render all sections
    renderHeader();
    renderColorDisplay();
    renderModeSelector();
    renderMainColorArea();
    renderQuickAccess();
    renderFooter();
}

void ColorPickerRenderer::renderHeader() {
    int headerY = y_ + PANEL_PADDING;
    
    // Title based on current mode
    std::string title;
    switch (modal_.getColorMode()) {
        case ColorMode::COLOR_BOX: title = "Color Box"; break;
        case ColorMode::COLOR_WHEEL: title = "Color Wheel"; break;
        case ColorMode::COLOR_SLIDERS: title = "Color Sliders"; break;
        case ColorMode::COLOR_BOOK: title = "Color Book"; break;
    }
    
    drawText(x_ + PANEL_PADDING, headerY, title, Color(1, 1, 1));
    
    // Close button (three dots menu)
    drawButton(x_ + width_ - BUTTON_SIZE - PANEL_PADDING, headerY - 8, 
               BUTTON_SIZE, BUTTON_SIZE, "⋮", false);
}

void ColorPickerRenderer::renderColorDisplay() {
    int displayY = y_ + PANEL_PADDING + 40;
    int displayX = x_ + width_ - COLOR_DISPLAY_SIZE - PANEL_PADDING - 60;
    
    // Primary color (larger circle)
    Color primary = modal_.getPrimaryColor();
    drawCircle(displayX + COLOR_DISPLAY_SIZE/2, displayY + COLOR_DISPLAY_SIZE/2, 
               COLOR_DISPLAY_SIZE/2, primary, true);
    
    // Border
    drawCircle(displayX + COLOR_DISPLAY_SIZE/2, displayY + COLOR_DISPLAY_SIZE/2, 
               COLOR_DISPLAY_SIZE/2, Color(0.3f, 0.3f, 0.3f), false);
    
    // Secondary color (smaller circle overlay)
    Color secondary = modal_.getSecondaryColor();
    int secondarySize = COLOR_DISPLAY_SIZE / 3;
    drawCircle(displayX + COLOR_DISPLAY_SIZE - secondarySize/2, 
               displayY + COLOR_DISPLAY_SIZE - secondarySize/2,
               secondarySize/2, secondary, true);
    
    // Secondary border
    drawCircle(displayX + COLOR_DISPLAY_SIZE - secondarySize/2, 
               displayY + COLOR_DISPLAY_SIZE - secondarySize/2,
               secondarySize/2, Color(0.3f, 0.3f, 0.3f), false);
}

void ColorPickerRenderer::renderModeSelector() {
    int selectorY = y_ + PANEL_PADDING + 40;
    int selectorX = x_ + PANEL_PADDING;
    int buttonSpacing = 8;
    
    // Mode buttons (icons)
    const char* icons[] = {"□", "○", "≡", "📚"};
    ColorMode modes[] = {ColorMode::COLOR_BOX, ColorMode::COLOR_WHEEL, 
                         ColorMode::COLOR_SLIDERS, ColorMode::COLOR_BOOK};
    
    for (int i = 0; i < 4; i++) {
        bool active = (modal_.getColorMode() == modes[i]);
        int btnX = selectorX + i * (BUTTON_SIZE + buttonSpacing);
        
        // Highlight active mode
        if (active) {
            drawRoundedRect(btnX, selectorY, BUTTON_SIZE, BUTTON_SIZE, 6, 
                          Color(0.4f, 0.4f, 0.6f, 0.5f));
        }
        
        drawButton(btnX, selectorY, BUTTON_SIZE, BUTTON_SIZE, icons[i], active);
    }
}

void ColorPickerRenderer::renderMainColorArea() {
    int areaY = y_ + PANEL_PADDING + 100;
    
    switch (modal_.getColorMode()) {
        case ColorMode::COLOR_BOX:
            renderColorBox();
            break;
        case ColorMode::COLOR_WHEEL:
            renderColorWheel();
            break;
        case ColorMode::COLOR_SLIDERS:
            renderColorSliders();
            break;
        case ColorMode::COLOR_BOOK:
            renderColorBook();
            break;
    }
}

void ColorPickerRenderer::renderColorBox() {
    int boxSize = 280;
    int boxX = x_ + (width_ - boxSize) / 2;
    int boxY = y_ + PANEL_PADDING + 120;
    
    // Get current color HSB values
    Color active = modal_.getActiveColor();
    float h, s, b;
    active.toHSB(h, s, b);
    
    // Draw the 2D gradient box (saturation horizontal, brightness vertical)
    const int steps = 50;
    for (int row = 0; row < steps; row++) {
        for (int col = 0; col < steps; col++) {
            float sat = static_cast<float>(col) / steps;
            float bright = 1.0f - static_cast<float>(row) / steps;
            
            Color boxColor = Color::fromHSB(h, sat, bright);
            
            int rectX = boxX + (col * boxSize) / steps;
            int rectY = boxY + (row * boxSize) / steps;
            int rectSize = (boxSize / steps) + 1;
            
            drawRect(rectX, rectY, rectSize, rectSize, boxColor, true);
        }
    }
    
    // Draw selection reticle
    int reticleX = boxX + static_cast<int>(s * boxSize);
    int reticleY = boxY + static_cast<int>((1.0f - b) * boxSize);
    
    // Draw reticle circle (white with black outline)
    drawCircle(reticleX, reticleY, 8, Color(1, 1, 1), false);
    drawCircle(reticleX, reticleY, 7, Color(0, 0, 0), false);
    
    // Hue slider below the box
    int hueSliderY = boxY + boxSize + 20;
    int hueSliderX = boxX;
    int hueSliderWidth = boxSize;
    int hueSliderHeight = 20;
    
    // Draw hue gradient
    const int hueSteps = 100;
    for (int i = 0; i < hueSteps; i++) {
        float hue = (360.0f * i) / hueSteps;
        Color hueColor = Color::fromHSB(hue, 1.0f, 1.0f);
        
        int rectX = hueSliderX + (i * hueSliderWidth) / hueSteps;
        int rectW = (hueSliderWidth / hueSteps) + 1;
        
        drawRect(rectX, hueSliderY, rectW, hueSliderHeight, hueColor, true);
    }
    
    // Draw hue slider handle
    int hueHandleX = hueSliderX + static_cast<int>((h / 360.0f) * hueSliderWidth);
    drawRect(hueHandleX - 2, hueSliderY - 4, 4, hueSliderHeight + 8, Color(1, 1, 1), true);
    drawRect(hueHandleX - 1, hueSliderY - 3, 2, hueSliderHeight + 6, active, true);
}

void ColorPickerRenderer::renderColorWheel() {
    int centerX = x_ + width_ / 2;
    int centerY = y_ + PANEL_PADDING + 250;
    int radius = 120;
    
    // Draw the color wheel
    drawColorWheel(centerX, centerY, radius);
    
    // Draw mode selector buttons at top right
    int modeX = x_ + width_ - PANEL_PADDING - 100;
    int modeY = y_ + PANEL_PADDING + 120;
    
    const char* modes[] = {"S", "B", "R", "G", "B"};
    for (int i = 0; i < 5; i++) {
        drawButton(modeX + i * 22, modeY, 20, 20, modes[i], false);
    }
}

void ColorPickerRenderer::renderColorSliders() {
    int startY = y_ + PANEL_PADDING + 140;
    int sliderX = x_ + PANEL_PADDING + 50;
    int sliderWidth = width_ - PANEL_PADDING * 2 - 100;
    int sliderSpacing = 40;
    
    Color active = modal_.getActiveColor();
    
    if (modal_.getColorSpace() == ColorSpace::HSB) {
        float h, s, b;
        active.toHSB(h, s, b);
        
        // H slider
        drawText(sliderX - 30, startY, "H", Color(0.8f, 0.8f, 0.8f));
        drawSlider(sliderX, startY, sliderWidth, *sliders_[0]);
        std::stringstream ss;
        ss << static_cast<int>(h) << "°";
        drawText(sliderX + sliderWidth + 10, startY, ss.str(), Color(0.8f, 0.8f, 0.8f));
        
        // S slider
        startY += sliderSpacing;
        drawText(sliderX - 30, startY, "S", Color(0.8f, 0.8f, 0.8f));
        drawSlider(sliderX, startY, sliderWidth, *sliders_[1]);
        ss.str("");
        ss << static_cast<int>(s * 100) << "%";
        drawText(sliderX + sliderWidth + 10, startY, ss.str(), Color(0.8f, 0.8f, 0.8f));
        
        // B slider
        startY += sliderSpacing;
        drawText(sliderX - 30, startY, "B", Color(0.8f, 0.8f, 0.8f));
        drawSlider(sliderX, startY, sliderWidth, *sliders_[2]);
        ss.str("");
        ss << static_cast<int>(b * 100) << "%";
        drawText(sliderX + sliderWidth + 10, startY, ss.str(), Color(0.8f, 0.8f, 0.8f));
        
    } else if (modal_.getColorSpace() == ColorSpace::RGB) {
        int r, g, b;
        active.getRGB255(r, g, b);
        
        // R slider
        drawText(sliderX - 30, startY, "R", Color(0.8f, 0.8f, 0.8f));
        drawSlider(sliderX, startY, sliderWidth, *sliders_[3]);
        drawText(sliderX + sliderWidth + 10, startY, std::to_string(r), Color(0.8f, 0.8f, 0.8f));
        
        // G slider
        startY += sliderSpacing;
        drawText(sliderX - 30, startY, "G", Color(0.8f, 0.8f, 0.8f));
        drawSlider(sliderX, startY, sliderWidth, *sliders_[4]);
        drawText(sliderX + sliderWidth + 10, startY, std::to_string(g), Color(0.8f, 0.8f, 0.8f));
        
        // B slider
        startY += sliderSpacing;
        drawText(sliderX - 30, startY, "B", Color(0.8f, 0.8f, 0.8f));
        drawSlider(sliderX, startY, sliderWidth, *sliders_[5]);
        drawText(sliderX + sliderWidth + 10, startY, std::to_string(b), Color(0.8f, 0.8f, 0.8f));
    }
    
    // Hex input at bottom
    startY += sliderSpacing + 20;
    drawText(sliderX - 30, startY, "Hexadecimal Code", Color(0.8f, 0.8f, 0.8f));
    
    startY += 25;
    std::string hexValue = active.toHex();
    drawRoundedRect(sliderX, startY, 120, 30, 4, Color(0.2f, 0.2f, 0.2f));
    drawText(sliderX + 10, startY + 8, "#" + hexValue, Color(0.9f, 0.9f, 0.9f));
}

void ColorPickerRenderer::renderColorBook() {
    int startY = y_ + PANEL_PADDING + 140;
    int paletteX = x_ + PANEL_PADDING;
    
    // HSB slider for browsing
    drawText(paletteX, startY, "Browse Colors", Color(0.9f, 0.9f, 0.9f));
    
    startY += 30;
    int sliderWidth = width_ - PANEL_PADDING * 2;
    
    // Hue slider
    const int hueSteps = 100;
    for (int i = 0; i < hueSteps; i++) {
        float hue = (360.0f * i) / hueSteps;
        Color hueColor = Color::fromHSB(hue, 1.0f, 1.0f);
        
        int rectX = paletteX + (i * sliderWidth) / hueSteps;
        int rectW = (sliderWidth / hueSteps) + 1;
        
        drawRect(rectX, startY, rectW, 30, hueColor, true);
    }
    
    // Color cards below
    startY += 50;
    drawText(paletteX, startY, "Color Cards", Color(0.9f, 0.9f, 0.9f));
    
    startY += 30;
    int cardSize = 60;
    int cardSpacing = 12;
    int cardsPerRow = (width_ - PANEL_PADDING * 2) / (cardSize + cardSpacing);
    
    // Generate sample color cards based on current hue
    float h, s, b;
    modal_.getActiveColor().toHSB(h, s, b);
    
    for (int i = 0; i < 12; i++) {
        int row = i / cardsPerRow;
        int col = i % cardsPerRow;
        
        int cardX = paletteX + col * (cardSize + cardSpacing);
        int cardY = startY + row * (cardSize + cardSpacing);
        
        // Vary saturation and brightness
        float cardS = 0.3f + (i % 4) * 0.2f;
        float cardB = 0.4f + (i / 4) * 0.2f;
        
        Color cardColor = Color::fromHSB(h, cardS, cardB);
        drawColorBox(cardX, cardY, cardSize, cardColor, false);
    }
}

void ColorPickerRenderer::renderQuickAccess() {
    int quickY = y_ + height_ - 200;
    
    // Tab buttons
    int tabX = x_ + PANEL_PADDING;
    const char* tabs[] = {"Color Shades", "Color History", "My Palettes"};
    int activeTab = 0; // TODO: track active tab
    
    for (int i = 0; i < 3; i++) {
        bool active = (i == activeTab);
        int btnWidth = 110;
        drawButton(tabX + i * (btnWidth + 8), quickY, btnWidth, 32, tabs[i], active);
    }
    
    quickY += 45;
    
    // Render content based on active tab
    if (activeTab == 0) {
        renderShades();
    } else if (activeTab == 1) {
        renderHistory();
    } else {
        renderPalettes();
    }
}

void ColorPickerRenderer::renderShades() {
    int shadeY = y_ + height_ - 150;
    int shadeX = x_ + PANEL_PADDING;
    
    // Shade type selector
    const char* shadeTypes[] = {"Shade", "Tint", "Tone", "Warmer", "Cooler"};
    int currentType = static_cast<int>(modal_.getShadeType());
    
    drawButton(shadeX, shadeY - 35, 120, 28, shadeTypes[currentType % 5], false);
    
    // Generate and display shades
    auto shades = modal_.generateShades(10);
    
    for (size_t i = 0; i < shades.size() && i < 10; i++) {
        int boxX = shadeX + i * (SHADE_BOX_SIZE + 4);
        drawColorBox(boxX, shadeY, SHADE_BOX_SIZE, shades[i], false);
    }
}

void ColorPickerRenderer::renderHistory() {
    int historyY = y_ + height_ - 150;
    int historyX = x_ + PANEL_PADDING;
    
    auto history = modal_.getHistory();
    
    if (history.empty()) {
        drawText(historyX, historyY, "No recent colors", Color(0.5f, 0.5f, 0.5f));
    } else {
        for (size_t i = 0; i < history.size() && i < 10; i++) {
            int boxX = historyX + i * (HISTORY_BOX_SIZE + 6);
            drawColorBox(boxX, historyY, HISTORY_BOX_SIZE, history[i], false);
        }
        
        // Clear button
        drawButton(x_ + width_ - PANEL_PADDING - 80, historyY - 35, 80, 28, "Clear", false);
    }
}

void ColorPickerRenderer::renderPalettes() {
    int paletteY = y_ + height_ - 150;
    int paletteX = x_ + PANEL_PADDING;
    
    auto palette = modal_.getFavoritePalette();
    
    if (palette && !palette->colors.empty()) {
        drawText(paletteX, paletteY - 35, palette->name, Color(0.9f, 0.9f, 0.9f));
        
        for (size_t i = 0; i < palette->colors.size() && i < 10; i++) {
            int boxX = paletteX + i * (SHADE_BOX_SIZE + 4);
            drawColorBox(boxX, paletteY, SHADE_BOX_SIZE, palette->colors[i], false);
        }
    }
}

void ColorPickerRenderer::renderFooter() {
    // Optional footer with additional controls or info
}

// ============================================================================
// Helper Drawing Functions
// ============================================================================

void ColorPickerRenderer::drawColorBox(int x, int y, int size, const Color& color, bool selected) {
    // Fill
    drawRect(x, y, size, size, color, true);
    
    // Border
    Color borderColor = selected ? Color(1, 1, 1) : Color(0.3f, 0.3f, 0.3f);
    drawRect(x, y, size, size, borderColor, false);
    
    if (selected) {
        // Inner highlight
        drawRect(x + 2, y + 2, size - 4, size - 4, Color(1, 1, 1, 0.5f), false);
    }
}

void ColorPickerRenderer::drawColorWheel(int centerX, int centerY, int radius) {
    // Draw outer hue ring
    const int segments = 120;
    const float innerRadius = radius * 0.7f;
    
    for (int i = 0; i < segments; i++) {
        float angle1 = (2.0f * M_PI * i) / segments;
        float angle2 = (2.0f * M_PI * (i + 1)) / segments;
        
        float hue = (360.0f * i) / segments;
        Color hueColor = Color::fromHSB(hue, 1.0f, 1.0f);
        
        // Draw ring segment (simplified - you'd draw actual triangles/quads here)
        // This is pseudocode for the concept
        // drawRingSegment(centerX, centerY, innerRadius, radius, angle1, angle2, hueColor);
    }
    
    // Draw inner saturation/brightness area
    const int gridSize = 50;
    for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
            // Map to -1 to 1
            float x = (2.0f * col / gridSize) - 1.0f;
            float y = (2.0f * row / gridSize) - 1.0f;
            
            float dist = std::sqrt(x * x + y * y);
            if (dist <= 0.7f) {
                // Calculate position-based saturation and brightness
                float s = std::abs(x);
                float b = 1.0f - std::abs(y);
                
                Color c = Color::fromHSB(270.0f, s, b); // Use current hue
                
                int px = centerX + static_cast<int>(x * innerRadius);
                int py = centerY + static_cast<int>(y * innerRadius);
                
                // drawPixel or small rect
            }
        }
    }
}

void ColorPickerRenderer::drawSlider(int x, int y, int width, const ColorSlider& slider) {
    const int height = SLIDER_HEIGHT;
    
    // Background track with gradient
    const int steps = 100;
    for (int i = 0; i < steps; i++) {
        float pos = static_cast<float>(i) / steps;
        Color gradColor = Color(pos, pos, pos); // Simplified - use slider.getGradientColor(pos)
        
        int rectX = x + (i * width) / steps;
        int rectW = (width / steps) + 1;
        drawRect(rectX, y, rectW, height, gradColor, true);
    }
    
    // Handle/thumb
    int handleX = x + static_cast<int>(slider.getValue() * width);
    drawRoundedRect(handleX - 4, y - 2, 8, height + 4, 4, Color(1, 1, 1));
}

void ColorPickerRenderer::drawButton(int x, int y, int width, int height, 
                                      const std::string& label, bool active) {
    Color bgColor = active ? Color(0.3f, 0.3f, 0.5f) : Color(0.25f, 0.25f, 0.25f);
    drawRoundedRect(x, y, width, height, 4, bgColor);
    
    // Center text
    drawText(x + width/2 - 6, y + height/2 - 6, label, Color(0.9f, 0.9f, 0.9f));
}

void ColorPickerRenderer::drawText(int x, int y, const std::string& text, const Color& color) {
    // Platform-specific text rendering
    // This would use your GUI framework's text rendering
}

void ColorPickerRenderer::drawRect(int x, int y, int width, int height, 
                                    const Color& color, bool filled) {
    // Platform-specific rectangle drawing
    // This would use your GUI framework's drawing functions
}

void ColorPickerRenderer::drawCircle(int centerX, int centerY, int radius, 
                                      const Color& color, bool filled) {
    // Platform-specific circle drawing
}

void ColorPickerRenderer::drawRoundedRect(int x, int y, int width, int height, 
                                           int radius, const Color& color) {
    // Platform-specific rounded rectangle drawing
}

} // namespace ColorPickerUI
