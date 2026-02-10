cmake_minimum_required(VERSION 3.16)
project(ArtFlowStudio VERSION 1.0.0 LANGUAGES CXX)

message(STATUS "--------------------------------------------------")
message(STATUS "Compilador C++ detectado: ${CMAKE_CXX_COMPILER}")
message(STATUS "Version de CMake: ${CMAKE_VERSION}")
message(STATUS "--------------------------------------------------")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 1. Configuración de Qt
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Concurrent OpenGL Svg Widgets QuickEffects ShaderTools)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 2. Inclusión de directorios
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core/cpp/include
)

# 3. Fuentes del Core (Ya existentes)
set(CORE_SOURCES
    src/core/cpp/src/brush_engine.cpp
    src/core/cpp/src/layer_manager.cpp
    src/core/cpp/src/color_utils.cpp
    src/core/cpp/src/image_buffer.cpp
    src/core/cpp/src/gl_utils.cpp
    src/core/cpp/src/stroke_renderer.cpp
    src/core/cpp/src/undo_manager.cpp
    src/core/cpp/src/stroke_undo_command.cpp
    src/core/cpp/src/ColorPicker.cpp
    src/core/cpp/src/ColorPickerImpl.cpp
    src/core/cpp/include/ColorPicker.h
    src/core/cpp/include/ColorPickerImpl.h
)

# 4. Nuevas Fuentes del Motor de UI (C++)
set(UI_SOURCES
    src/main.cpp
    src/CanvasItem.cpp
    src/TestCanvas.cpp
    src/ProjectModel.cpp
    src/PreferencesManager.cpp
)

# 5. Recursos QML
# En Qt6, lo ideal es usar qt_add_qml_module, pero para simplificar la migración
# usaremos un archivo .qrc que apunte a tus archivos actuales.
set(RESOURCES
    src/ui/resources.qrc
)

# 6. Ejecutable Final
add_executable(${PROJECT_NAME}
    ${CORE_SOURCES}
    ${UI_SOURCES}
    ${RESOURCES}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Concurrent
    Qt6::OpenGL
    Qt6::Svg
    Qt6::Widgets
    Qt6::QuickEffects
    Qt6::ShaderTools
    opengl32
)

# Configuración de despliegue para Windows (Copia DLLs automáticamente)
# if(WIN32)
#    set_target_properties(${PROJECT_NAME} PROPERTIES
#        WIN32_EXECUTABLE TRUE
#    )
# endif()
