cmake_minimum_required(VERSION 3.16)
project(KromoStudio VERSION 1.0.0 LANGUAGES CXX)

message(STATUS "--------------------------------------------------")
message(STATUS "Compilador C++ detectado: ${CMAKE_CXX_COMPILER}")
message(STATUS "Version de CMake: ${CMAKE_VERSION}")
message(STATUS "--------------------------------------------------")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# GCC/Clang Compiler Optimizations (Android & MinGW)
if(NOT MSVC)
    message(STATUS "Aplicando flags de optimizacion de velocidad para GCC/Clang")
    add_compile_options(-O3 -ffast-math)
    
    # Habilitar IPO/LTO si es soportado por el compilador y CMake
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_supported OUTPUT ipo_output)
    if(ipo_supported AND NOT WIN32)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
        message(STATUS "Link-Time Optimization (LTO) habilitado.")
    else()
        message(STATUS "LTO no soportado: ${ipo_output}")
    endif()
endif()


# 1. Configuración de Qt
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Concurrent OpenGL Svg Widgets QuickEffects ShaderTools Network)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 2. Inclusión de directorios
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core/cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core/brushes
)

# 2.5 Integración de Rust usando Corrosion
# Apuntamos directamente a los binarios reales de Rust (sin pasar por el proxy de rustup)
# para evitar fallos silenciosos dentro del entorno restringido de Qt Creator.
set(Rust_COMPILER "C:/Users/bonia/.rustup/toolchains/stable-x86_64-pc-windows-msvc/bin/rustc.exe" CACHE FILEPATH "Rust compiler" FORCE)
set(Rust_CARGO "C:/Users/bonia/.rustup/toolchains/stable-x86_64-pc-windows-msvc/bin/cargo.exe" CACHE FILEPATH "Rust Cargo" FORCE)

include(FetchContent)
FetchContent_Declare(
    Corrosion
    GIT_REPOSITORY https://github.com/corrosion-rs/corrosion.git
    GIT_TAG v0.5.0
)
FetchContent_MakeAvailable(Corrosion)
corrosion_import_crate(MANIFEST_PATH src/core/rust_core/Cargo.toml)

# 3. Fuentes del Core (Ya existentes)
set(CORE_SOURCES
    src/core/cpp/src/brush_engine.cpp
    src/core/cpp/src/brush_preset.cpp
    src/core/cpp/src/brush_preset_manager.cpp
    src/core/cpp/src/layer_manager.cpp
    src/core/cpp/src/color_utils.cpp
    src/core/cpp/src/image_buffer.cpp
    src/core/cpp/src/gl_utils.cpp
    src/core/cpp/src/stroke_renderer.cpp
    src/core/cpp/src/undo_manager.cpp
    src/core/cpp/src/stroke_undo_command.cpp
    src/core/cpp/src/undo_commands.cpp
    src/core/cpp/src/ColorPicker.cpp
    src/core/cpp/src/ColorPickerImpl.cpp
    src/core/cpp/src/panel_list_model.cpp
    src/core/cpp/src/panel_manager.cpp
    src/core/cpp/src/color_harmony.cpp
    src/core/cpp/src/drag_zone_calculator.cpp
    src/core/cpp/src/liquify_engine.cpp
    src/core/cpp/src/watercolor_engine.cpp
    # ABR Parser (brush pack importer)
    src/core/brushes/abr_parser.cpp
    src/core/cpp/src/edge_detector.cpp
    src/core/cpp/src/color_range_selector.cpp
    src/core/cpp/include/edge_detector.h
    src/core/cpp/include/color_range_selector.h
    src/core/cpp/include/ColorPicker.h
    src/core/cpp/include/ColorPickerImpl.h
    src/core/cpp/include/panel_manager.h
    src/core/cpp/include/panel_list_model.h
    src/core/cpp/include/color_harmony.h
    src/core/cpp/include/drag_zone_calculator.h
    src/core/cpp/include/liquify_engine.h
    src/core/cpp/include/watercolor_engine.h
    src/core/cpp/src/vector_math.cpp
    src/core/cpp/src/vector_layer_data.cpp
    src/core/cpp/include/vector_types.h
    src/core/cpp/include/vector_math.h
    src/core/cpp/include/vector_layer_data.h
    # Animation system
    src/core/cpp/src/animation_manager.cpp
    src/core/cpp/include/animation_manager.h
    src/core/cpp/include/animation_frame.h
    src/core/cpp/include/animation_track.h
    # Perspective system
    src/core/cpp/src/PerspectiveRuler.cpp
    src/core/cpp/include/PerspectiveRuler.h
)

# 4. Nuevas Fuentes del Motor de UI (C++)
set(UI_SOURCES
    src/main.cpp
    src/CanvasItem.cpp
    src/ProjectModel.cpp
    src/PreferencesManager.cpp
)

if(WIN32)
    list(APPEND UI_SOURCES
        src/WintabManager.cpp
        src/WintabManager.h
    )
endif()

# 5. Recursos QML
# En Qt6, lo ideal es usar qt_add_qml_module, pero para simplificar la migración
# usaremos un archivo .qrc que apunte a tus archivos actuales.
set(RESOURCES
    src/ui/resources.qrc
)

# 6. Ejecutable Final
qt_add_executable(${PROJECT_NAME}
    ${CORE_SOURCES}
    ${UI_SOURCES}
    ${RESOURCES}
)

# Empaquetar assets y shaders en el sistema de recursos virtuales (qrc)
file(GLOB_RECURSE ASSETS_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "assets/icons/*.svg"
    "assets/icons/*.png"
    "assets/textures/*.png"
    "assets/textures/*.jpg"
    "assets/brushes/*.json"
    "assets/brushes/**/*.json"
)
qt_add_resources(${PROJECT_NAME} "assets"
    PREFIX "/"
    BASE_RESOURCES_PATH ${CMAKE_CURRENT_SOURCE_DIR}
    FILES
        ${ASSETS_FILES}
)

file(GLOB_RECURSE SHADER_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "src/core/shaders/*.vert"
    "src/core/shaders/*.frag"
)
qt_add_resources(${PROJECT_NAME} "shaders"
    PREFIX "/"
    BASE_RESOURCES_PATH ${CMAKE_CURRENT_SOURCE_DIR}
    FILES
        ${SHADER_FILES}
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
    Qt6::Network
    rust_core
)

if(WIN32)
    target_link_libraries(${PROJECT_NAME} PRIVATE opengl32 ws2_32 userenv dbghelp)
elseif(ANDROID)
    target_link_libraries(${PROJECT_NAME} PRIVATE GLESv3)
endif()

# Copiar assets al directorio de build
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/assets
    $<TARGET_FILE_DIR:${PROJECT_NAME}>/assets
)

# Copiar shaders al directorio de build (para que sean accesibles en runtime)
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/src/core/shaders
    $<TARGET_FILE_DIR:${PROJECT_NAME}>/shaders
)

# Configuración de despliegue para Windows — SIN CONSOLA
if(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()
