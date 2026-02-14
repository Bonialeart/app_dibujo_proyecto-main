#include "BrushStroke.h"
#include <SFML/Graphics.hpp>
#include <iostream>

int main() {
    // Configuración de la ventana
    const unsigned int WINDOW_WIDTH = 1200;
    const unsigned int WINDOW_HEIGHT = 800;
    
    sf::RenderWindow window(sf::VideoMode(WINDOW_WIDTH, WINDOW_HEIGHT), 
                            "App de Dibujo - Pinceles con Grosor Variable");
    window.setFramerateLimit(60);
    
    // Crear la aplicación de dibujo
    DrawingApp app(window, WINDOW_WIDTH, WINDOW_HEIGHT);
    
    // Variables para UI
    BrushType currentBrush = BrushType::TAPERED;
    sf::Color currentColor = sf::Color::Black;
    
    std::cout << "=== CONTROLES ===" << std::endl;
    std::cout << "Click izquierdo: Dibujar" << std::endl;
    std::cout << "1: Pincel Afilado (punta fina)" << std::endl;
    std::cout << "2: Pincel Presión (variable)" << std::endl;
    std::cout << "3: Pincel Caligrafía (ángulo)" << std::endl;
    std::cout << "4: Pincel Marcador (constante)" << std::endl;
    std::cout << "+/-: Aumentar/Reducir grosor" << std::endl;
    std::cout << "R: Color Rojo" << std::endl;
    std::cout << "G: Color Verde" << std::endl;
    std::cout << "B: Color Azul" << std::endl;
    std::cout << "K: Color Negro" << std::endl;
    std::cout << "Z: Deshacer" << std::endl;
    std::cout << "C: Limpiar todo" << std::endl;
    std::cout << "ESC: Salir" << std::endl;
    
    float brushSize = 20.0f;
    
    // Loop principal
    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed) {
                window.close();
            }
            
            // Eventos de mouse
            else if (event.type == sf::Event::MouseButtonPressed) {
                app.handleMousePressed(event);
            }
            else if (event.type == sf::Event::MouseMoved) {
                app.handleMouseMoved(event);
            }
            else if (event.type == sf::Event::MouseButtonReleased) {
                app.handleMouseReleased(event);
            }
            
            // Eventos de teclado
            else if (event.type == sf::Event::KeyPressed) {
                switch(event.key.code) {
                    // Cambiar tipo de pincel
                    case sf::Keyboard::Num1:
                        currentBrush = BrushType::TAPERED;
                        app.setBrushType(currentBrush);
                        std::cout << "Pincel: AFILADO (punta fina -> grueso -> punta fina)" << std::endl;
                        break;
                    
                    case sf::Keyboard::Num2:
                        currentBrush = BrushType::PRESSURE;
                        app.setBrushType(currentBrush);
                        std::cout << "Pincel: PRESIÓN (varía con velocidad)" << std::endl;
                        break;
                    
                    case sf::Keyboard::Num3:
                        currentBrush = BrushType::CALLIGRAPHY;
                        app.setBrushType(currentBrush);
                        std::cout << "Pincel: CALIGRAFÍA (varía por ángulo)" << std::endl;
                        break;
                    
                    case sf::Keyboard::Num4:
                        currentBrush = BrushType::MARKER;
                        app.setBrushType(currentBrush);
                        std::cout << "Pincel: MARCADOR (grosor constante)" << std::endl;
                        break;
                    
                    // Cambiar color
                    case sf::Keyboard::R:
                        currentColor = sf::Color::Red;
                        app.setColor(currentColor);
                        std::cout << "Color: ROJO" << std::endl;
                        break;
                    
                    case sf::Keyboard::G:
                        currentColor = sf::Color::Green;
                        app.setColor(currentColor);
                        std::cout << "Color: VERDE" << std::endl;
                        break;
                    
                    case sf::Keyboard::B:
                        currentColor = sf::Color::Blue;
                        app.setColor(currentColor);
                        std::cout << "Color: AZUL" << std::endl;
                        break;
                    
                    case sf::Keyboard::K:
                        currentColor = sf::Color::Black;
                        app.setColor(currentColor);
                        std::cout << "Color: NEGRO" << std::endl;
                        break;
                    
                    // Ajustar grosor
                    case sf::Keyboard::Equal: // Tecla +
                        brushSize += 5.0f;
                        if (brushSize > 50.0f) brushSize = 50.0f;
                        app.setBrushSize(brushSize);
                        std::cout << "Grosor: " << brushSize << "px" << std::endl;
                        break;
                    
                    case sf::Keyboard::Hyphen: // Tecla -
                        brushSize -= 5.0f;
                        if (brushSize < 5.0f) brushSize = 5.0f;
                        app.setBrushSize(brushSize);
                        std::cout << "Grosor: " << brushSize << "px" << std::endl;
                        break;
                    
                    // Deshacer
                    case sf::Keyboard::Z:
                        app.undo();
                        std::cout << "Deshacer último trazo" << std::endl;
                        break;
                    
                    // Limpiar
                    case sf::Keyboard::C:
                        app.clear();
                        std::cout << "Canvas limpiado" << std::endl;
                        break;
                    
                    // Salir
                    case sf::Keyboard::Escape:
                        window.close();
                        break;
                    
                    default:
                        break;
                }
            }
        }
        
        app.display();
    }
    
    return 0;
}
