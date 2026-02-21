from setuptools import setup, Extension
import sys
import os

# Intenta localizar pybind11
try:
    import pybind11
    pybind_include = pybind11.get_include()
except ImportError:
    print("Error: pybind11 is required to build this extension.")
    print("Run: pip install pybind11")
    sys.exit(1)

# Rutas de los archivos fuente
cpp_src_dir = os.path.join(os.getcwd(), "src")
cpp_include_dir = os.path.join(os.getcwd(), "include")
bindings_dir = os.path.abspath(os.path.join(os.getcwd(), "..", "bindings"))
canvas_dir = os.path.abspath(os.path.join(os.getcwd(), "..", "canvas"))
brushes_dir = os.path.abspath(os.path.join(os.getcwd(), "..", "brushes"))

# Configuración de Qt (MinGW hardcoded para Windows)
QT_PATH = r"C:\Qt\6.10.2\mingw_64"
qt_include_dirs = [
    os.path.join(QT_PATH, "include"),
    os.path.join(QT_PATH, "include", "QtCore"),
    os.path.join(QT_PATH, "include", "QtGui"),
    os.path.join(QT_PATH, "include", "QtOpenGL"),
    os.path.join(QT_PATH, "include", "QtWidgets"), # Potencialmente necesario
]
qt_lib_dir = os.path.join(QT_PATH, "lib")

sources = [
    os.path.join(bindings_dir, "python_bindings.cpp"),
    os.path.join(cpp_src_dir, "brush_engine.cpp"),
    os.path.join(cpp_src_dir, "stroke_renderer.cpp"),
    os.path.join(cpp_src_dir, "gl_utils.cpp"),
    os.path.join(cpp_src_dir, "layer_manager.cpp"),
    os.path.join(cpp_src_dir, "image_buffer.cpp"),
    os.path.join(cpp_src_dir, "color_utils.cpp"),
    os.path.join(canvas_dir, "renderer.cpp"),
    os.path.join(brushes_dir, "abr_parser.cpp"),
]

# Verificar que los archivos existen (filtro preventivo)
existing_sources = [f for f in sources if os.path.exists(f)]

# Librerias para linkear
libs = ["user32", "gdi32", "opengl32"]
if sys.platform == "win32":
    # MinGW libraries (libQt6Core.a -> -lQt6Core)
    libs.extend(["Qt6Core", "Qt6Gui", "Qt6OpenGL", "Qt6Widgets"])
else:
    libs.append("GL")

ext_modules = [
    Extension(
        "artflow_native",
        existing_sources,
        include_dirs=[
            cpp_include_dir,
            canvas_dir,
            brushes_dir,
            pybind_include,
        ] + qt_include_dirs,
        library_dirs=[qt_lib_dir],
        libraries=libs,
        language="c++",
        extra_compile_args=["-std=c++17", "-O3"], # MinGW flags
    ),
]

setup(
    name="artflow_native",
    version="1.0.0",
    author="Antigravity",
    description="Native C++ Engine for ArtFlow Watercolor Physics",
    ext_modules=ext_modules,
    zip_safe=False,
)
