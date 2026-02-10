#include "ColorPicker.h"
#include "ColorPickerRenderer.h"
#include <iostream>

using namespace ColorPickerUI;

/**
 * Example Usage of the Modern Color Picker
 * 
 * This example shows how to integrate the color picker into your application.
 * Adapt the rendering calls to your specific GUI framework.
 */

class DrawingApp {
public:
    DrawingApp() {
        initializeColorPicker();
    }
    
    void initializeColorPicker() {
        // Create the color picker modal
        colorPicker_ = std::make_unique<ColorPickerModal>();
        
        // Create the renderer
        renderer_ = std::make_unique<ColorPickerRenderer>(*colorPicker_);
        
        // Set initial color
        Color initialColor(0.7f, 0.5f, 0.8f); // Purple from the images
        colorPicker_->setActiveColor(initialColor);
        
        // Setup callbacks
        setupCallbacks();
        
        // Create custom palettes
        createCustomPalettes();
    }
    
    void setupCallbacks() {
        // Called when user selects a new color
        colorPicker_->setOnColorChanged([this](const Color& color) {
            std::cout << "Color changed to: " << color.toHex() << std::endl;
            currentBrushColor_ = color;
            
            // Update your drawing tool with the new color
            updateBrushColor(color);
        });
        
        // Called when modal is closed
        colorPicker_->setOnModalClosed([this]() {
            std::cout << "Color picker closed" << std::endl;
        });
    }
    
    void createCustomPalettes() {
        // Create a nature palette
        ColorPalette naturePalette("Nature");
        naturePalette.colors = {
            Color(0.2f, 0.5f, 0.2f),  // Forest green
            Color(0.4f, 0.3f, 0.1f),  // Earth brown
            Color(0.5f, 0.7f, 0.9f),  // Sky blue
            Color(0.9f, 0.8f, 0.3f),  // Sun yellow
            Color(0.6f, 0.4f, 0.3f)   // Tree bark
        };
        colorPicker_->addPalette(naturePalette);
        
        // Create a vibrant palette
        ColorPalette vibrantPalette("Vibrant");
        vibrantPalette.colors = {
            Color(1.0f, 0.0f, 0.5f),  // Hot pink
            Color(0.0f, 1.0f, 0.5f),  // Bright green
            Color(0.5f, 0.0f, 1.0f),  // Purple
            Color(1.0f, 0.7f, 0.0f),  // Orange
            Color(0.0f, 0.8f, 1.0f)   // Cyan
        };
        colorPicker_->addPalette(vibrantPalette);
        
        // Set favorite
        colorPicker_->setFavoritePalette("Nature");
    }
    
    void showColorPicker() {
        colorPicker_->show();
    }
    
    void hideColorPicker() {
        colorPicker_->hide();
    }
    
    void render() {
        // Render your drawing canvas
        renderCanvas();
        
        // Render the color picker if visible
        if (colorPicker_->isVisible()) {
            renderer_->render();
        }
    }
    
    void handleInput() {
        // Example: Press 'C' to toggle color picker
        // if (keyPressed('C')) {
        //     if (colorPicker_->isVisible()) {
        //         hideColorPicker();
        //     } else {
        //         showColorPicker();
        //     }
        // }
    }
    
    // Example methods to demonstrate different features
    
    void usageExampleColorModes() {
        // Switch to color wheel mode
        colorPicker_->setColorMode(ColorMode::COLOR_WHEEL);
        
        // Switch to sliders mode with RGB
        colorPicker_->setColorMode(ColorMode::COLOR_SLIDERS);
        colorPicker_->setColorSpace(ColorSpace::RGB);
        
        // Switch to HSB sliders
        colorPicker_->setColorSpace(ColorSpace::HSB);
        
        // Use color book
        colorPicker_->setColorMode(ColorMode::COLOR_BOOK);
    }
    
    void usageExampleShades() {
        // Generate darker shades
        colorPicker_->setShadeType(ShadeType::SHADE);
        auto darkShades = colorPicker_->generateShades(10);
        
        // Generate lighter tints
        colorPicker_->setShadeType(ShadeType::TINT);
        auto lightShades = colorPicker_->generateShades(10);
        
        // Generate warmer variations
        colorPicker_->setShadeType(ShadeType::WARMER);
        auto warmerShades = colorPicker_->generateShades(10);
        
        // Use the generated shades
        for (const auto& shade : darkShades) {
            std::cout << "Shade: " << shade.toHex() << std::endl;
        }
    }
    
    void usageExampleColorConversions() {
        Color myColor(0.7f, 0.5f, 0.8f);
        
        // Convert to HSB
        float h, s, b;
        myColor.toHSB(h, s, b);
        std::cout << "HSB: " << h << ", " << s << ", " << b << std::endl;
        
        // Convert to hex
        std::string hex = myColor.toHex();
        std::cout << "Hex: #" << hex << std::endl;
        
        // Create from hex
        Color fromHex = Color::fromHex("BB9BD3");
        
        // Convert to CMYK
        float c, m, y, k;
        myColor.toCMYK(c, m, y, k);
        std::cout << "CMYK: " << c << ", " << m << ", " << y << ", " << k << std::endl;
    }
    
    void usageExampleHistory() {
        // Add colors to history
        colorPicker_->addToHistory(Color(1.0f, 0.0f, 0.0f));
        colorPicker_->addToHistory(Color(0.0f, 1.0f, 0.0f));
        colorPicker_->addToHistory(Color(0.0f, 0.0f, 1.0f));
        
        // Get history
        auto history = colorPicker_->getHistory();
        std::cout << "History has " << history.size() << " colors" << std::endl;
        
        // Clear history
        // colorPicker_->clearHistory();
    }
    
    void usageExamplePrimarySecondary() {
        // Set primary color (for foreground)
        colorPicker_->setPrimaryColor(Color(0.2f, 0.2f, 0.2f));
        
        // Set secondary color (for background)
        colorPicker_->setSecondaryColor(Color(1.0f, 1.0f, 1.0f));
        
        // Swap them
        colorPicker_->swapPrimarySecondary();
        
        // Get current colors
        Color primary = colorPicker_->getPrimaryColor();
        Color secondary = colorPicker_->getSecondaryColor();
    }
    
private:
    std::unique_ptr<ColorPickerModal> colorPicker_;
    std::unique_ptr<ColorPickerRenderer> renderer_;
    Color currentBrushColor_;
    
    void renderCanvas() {
        // Your canvas rendering code
    }
    
    void updateBrushColor(const Color& color) {
        // Update your drawing brush with the new color
        currentBrushColor_ = color;
    }
};

// ============================================================================
// Integration Examples for Different Frameworks
// ============================================================================

#ifdef USE_QT
// Qt Integration Example
#include <QWidget>
#include <QPainter>

class QtColorPickerWidget : public QWidget {
    Q_OBJECT
public:
    QtColorPickerWidget(QWidget* parent = nullptr) : QWidget(parent) {
        colorPicker_ = std::make_unique<ColorPickerModal>();
        renderer_ = std::make_unique<ColorPickerRenderer>(*colorPicker_);
        
        colorPicker_->setOnColorChanged([this](const Color& color) {
            emit colorChanged(QColor(color.r * 255, color.g * 255, color.b * 255));
        });
    }
    
protected:
    void paintEvent(QPaintEvent* event) override {
        QPainter painter(this);
        
        if (colorPicker_->isVisible()) {
            // Render the color picker using Qt's QPainter
            // Adapt the renderer_ calls to use QPainter methods
        }
    }
    
signals:
    void colorChanged(const QColor& color);
    
private:
    std::unique_ptr<ColorPickerModal> colorPicker_;
    std::unique_ptr<ColorPickerRenderer> renderer_;
};
#endif

#ifdef USE_IMGUI
// ImGui Integration Example
#include "imgui.h"

void RenderImGuiColorPicker(ColorPickerModal& picker) {
    if (!picker.isVisible()) return;
    
    ImGui::Begin("Color Picker", nullptr, ImGuiWindowFlags_NoResize);
    
    Color active = picker.getActiveColor();
    float color[4] = {active.r, active.g, active.b, active.a};
    
    if (ImGui::ColorPicker4("##picker", color)) {
        picker.setActiveColor(Color(color[0], color[1], color[2], color[3]));
    }
    
    // Add custom UI elements here following the design from the images
    
    ImGui::End();
}
#endif

// ============================================================================
// Main Example
// ============================================================================

int main() {
    DrawingApp app;
    
    // Show the color picker
    app.showColorPicker();
    
    // Demonstrate different features
    app.usageExampleColorModes();
    app.usageExampleShades();
    app.usageExampleColorConversions();
    app.usageExampleHistory();
    
    // Main loop (pseudo-code)
    // while (running) {
    //     app.handleInput();
    //     app.render();
    // }
    
    return 0;
}
