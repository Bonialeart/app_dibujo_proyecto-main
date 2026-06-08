# KromoStudio

Professional-grade digital art application for illustrators, concept artists, and 2D animators. Built with C++ and Qt6 QML with a high-performance OpenGL rendering engine.

## Features

### Drawing Engine
- OpenGL-accelerated canvas with real-time rendering
- Pressure-sensitive brush system (Wintab support)
- Multi-layer architecture with blend modes
- Advanced brush engines: watercolor, oil, charcoal, airbrush
- Liquify engine for real-time fluid transformations
- ABR brush import (Photoshop-compatible)
- Unlimited undo/redo via command pattern
- Stroke stabilization and smoothing
- Symmetry tool and perspective rulers
- Gradient maps and color harmony tools

### Animation
- Timeline-based 2D animation
- Onion skinning for frame interpolation
- Animation tracks with keyframe management

### Comic & Manga Tools
- Panel layout system
- Speech balloon tool
- Screentone shader effects

### Professional Output
- Multi-layer PSD export
- Timelapse recording of drawing sessions
- Color range selection and edge detection

### Extensibility
- Lua 5.4.6 scripting for automation
- Rust core module for parallel computing (Rayon)
- Dockable panel system with customizable layouts

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | C++17/20 |
| UI Framework | Qt 6.11.1 (QML + C++) |
| Graphics | OpenGL with custom shaders |
| Build System | CMake 3.16+ with Ninja |
| Toolchain | MinGW 13.10 (64-bit) |
| Parallel Computing | Rust (via Corrosion/pybind11) |
| Scripting | Lua 5.4.6 |
| Data Storage | JSON |

## Project Structure

```
KromoStudio/
├── src/
│   ├── core/
│   │   ├── canvas/          # Canvas rendering
│   │   ├── brushes/         # Brush engine + ABR parser
│   │   ├── layers/          # Layer management
│   │   ├── cpp/             # Core C++ engine (app logic)
│   │   ├── shaders/         # GLSL shaders
│   │   └── rust_core/       # Rust module (parallel compute)
│   ├── ui/
│   │   ├── qml/             # QML UI components
│   │   │   ├── components/  # Reusable UI widgets
│   │   │   └── views/       # Application views
│   │   └── styles/          # QSS theme stylesheets
│   └── third_party/
│       └── lua-5.4.6/       # Embedded Lua interpreter
├── assets/
│   ├── icons/               # UI icons (SVG/PNG)
│   ├── brushes/             # Default brush presets
│   └── textures/            # Canvas textures and brush tips
├── data/                    # JSON catalogs (brushes, resources)
├── scripts/                 # Utility scripts
└── docs/                    # Documentation
```

## Getting Started

### Prerequisites
- Qt 6.11.1 (MinGW 13.10 64-bit)
- CMake 3.16 or later
- Ninja build system
- Rust toolchain (for rust_core module)
- Windows (current primary target)

### Build and Run

```bash
# Configure CMake
cmake -G Ninja -B build_mingw -S . ^
    -DCMAKE_PREFIX_PATH="C:\Qt\6.11.1\mingw_64" ^
    -DCMAKE_C_COMPILER="C:\Qt\Tools\mingw1310_64\bin\gcc.exe" ^
    -DCMAKE_CXX_COMPILER="C:\Qt\Tools\mingw1310_64\bin\g++.exe" ^
    -DCMAKE_MAKE_PROGRAM="C:\Qt\Tools\Ninja\ninja.exe"

# Build
cmake --build build_mingw --target KromoStudio

# Run
build_mingw\KromoStudio.exe
```

Or use the provided batch scripts:
- `auto_build.bat` -- compile the project
- `run_app.bat` -- launch the application
- `repair_build.bat` -- clean rebuild from scratch

## License

MIT License -- see LICENSE file for details.
