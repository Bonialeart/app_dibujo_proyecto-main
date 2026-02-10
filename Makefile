# Simple Makefile for Modern Color Picker
# For CMake build, use: mkdir build && cd build && cmake .. && make

CXX = g++
CXXFLAGS = -std=c++11 -Wall -Wextra -O2
LDFLAGS = -lm

# Source files
SOURCES = ColorPicker.cpp ColorPickerRenderer.cpp
HEADERS = ColorPicker.h ColorPickerRenderer.h
OBJECTS = $(SOURCES:.cpp=.o)

# Library name
LIBRARY = libcolorpicker.a

# Example executable
EXAMPLE = colorpicker_example
EXAMPLE_SRC = example_usage.cpp

# Default target
all: $(LIBRARY) $(EXAMPLE)

# Build static library
$(LIBRARY): $(OBJECTS)
	@echo "Creating static library..."
	ar rcs $@ $^
	@echo "Library created: $(LIBRARY)"

# Build example
$(EXAMPLE): $(EXAMPLE_SRC) $(LIBRARY)
	@echo "Building example..."
	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBRARY) $(LDFLAGS)
	@echo "Example built: $(EXAMPLE)"

# Compile object files
%.o: %.cpp $(HEADERS)
	@echo "Compiling $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Clean build files
clean:
	@echo "Cleaning..."
	rm -f $(OBJECTS) $(LIBRARY) $(EXAMPLE)
	@echo "Clean complete"

# Install (requires sudo on Unix systems)
install: $(LIBRARY) $(HEADERS)
	@echo "Installing..."
	mkdir -p /usr/local/include/colorpicker
	mkdir -p /usr/local/lib
	cp $(HEADERS) /usr/local/include/colorpicker/
	cp $(LIBRARY) /usr/local/lib/
	@echo "Installation complete"

# Uninstall
uninstall:
	@echo "Uninstalling..."
	rm -rf /usr/local/include/colorpicker
	rm -f /usr/local/lib/$(LIBRARY)
	@echo "Uninstall complete"

# Help
help:
	@echo "Modern Color Picker - Makefile targets:"
	@echo "  all       - Build library and example (default)"
	@echo "  clean     - Remove build files"
	@echo "  install   - Install library and headers"
	@echo "  uninstall - Remove installed files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make              # Build everything"
	@echo "  make clean        # Clean build files"
	@echo "  sudo make install # Install system-wide"

.PHONY: all clean install uninstall help
