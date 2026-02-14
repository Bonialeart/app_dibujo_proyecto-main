# Makefile para App de Dibujo con Pinceles Variables

CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
SFML_FLAGS = -lsfml-graphics -lsfml-window -lsfml-system

# Archivos fuente
SOURCES = main.cpp BrushStroke.cpp
OBJECTS = $(SOURCES:.cpp=.o)
TARGET = dibujo_app

# Regla principal
all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(SFML_FLAGS)
	@echo "✓ Compilación exitosa!"
	@echo "Ejecuta con: ./$(TARGET)"

# Compilar archivos objeto
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Limpiar archivos generados
clean:
	rm -f $(OBJECTS) $(TARGET)
	@echo "✓ Archivos limpiados"

# Ejecutar la aplicación
run: $(TARGET)
	./$(TARGET)

# Mostrar ayuda
help:
	@echo "=== MAKEFILE PARA APP DE DIBUJO ==="
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  make         - Compila el proyecto"
	@echo "  make run     - Compila y ejecuta"
	@echo "  make clean   - Elimina archivos compilados"
	@echo "  make help    - Muestra esta ayuda"
	@echo ""
	@echo "Requisitos:"
	@echo "  - g++ con soporte C++17"
	@echo "  - SFML 2.5+ instalado"
	@echo ""
	@echo "Instalación de SFML:"
	@echo "  Ubuntu/Debian: sudo apt-get install libsfml-dev"
	@echo "  Fedora:        sudo dnf install SFML-devel"
	@echo "  Arch:          sudo pacman -S sfml"
	@echo "  macOS:         brew install sfml"
	@echo "  Windows:       Descargar de https://www.sfml-dev.org/"

.PHONY: all clean run help
