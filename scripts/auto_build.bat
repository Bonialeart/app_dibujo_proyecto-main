@echo off
set QT_DIR=C:\Qt\6.11.1\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin
set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

set "BUILD_DIR=%~dp0..\build_mingw"

if not exist "%BUILD_DIR%" (
    echo [ERROR] No existe el directorio build_mingw.
    echo.
    echo Ejecuta primero: build repair
    pause
    exit /b 1
)

cmake --build "%BUILD_DIR%" --target KromoStudio
