cmake_minimum_required(VERSION 3.10)
project(ModernColorPicker VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler warnings
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Option to build as shared or static library
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)

# Option to build examples
option(BUILD_EXAMPLES "Build example applications" ON)

# Color Picker Library
set(COLORPICKER_SOURCES
    ColorPicker.cpp
    ColorPickerRenderer.cpp
)

set(COLORPICKER_HEADERS
    ColorPicker.h
    ColorPickerRenderer.h
)

# Create library
add_library(colorpicker ${COLORPICKER_SOURCES} ${COLORPICKER_HEADERS})

# Set library properties
set_target_properties(colorpicker PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    PUBLIC_HEADER "${COLORPICKER_HEADERS}"
)

# Include directories
target_include_directories(colorpicker
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
)

# Link math library (for std::sqrt, etc.)
if(UNIX)
    target_link_libraries(colorpicker PRIVATE m)
endif()

# Build examples if requested
if(BUILD_EXAMPLES)
    add_executable(colorpicker_example example_usage.cpp)
    target_link_libraries(colorpicker_example PRIVATE colorpicker)
endif()

# Installation
include(GNUInstallDirs)

install(TARGETS colorpicker
    EXPORT ColorPickerTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/colorpicker
)

install(EXPORT ColorPickerTargets
    FILE ColorPickerTargets.cmake
    NAMESPACE ColorPicker::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ColorPicker
)

# Create package config file
include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/ColorPickerConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/ColorPickerConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ColorPicker
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/ColorPickerConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/ColorPickerConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/ColorPickerConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ColorPicker
)

# Documentation
install(FILES README.md DESTINATION ${CMAKE_INSTALL_DOCDIR})

# Print configuration summary
message(STATUS "")
message(STATUS "Modern Color Picker Configuration:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Build shared libs: ${BUILD_SHARED_LIBS}")
message(STATUS "  Build examples: ${BUILD_EXAMPLES}")
message(STATUS "")
