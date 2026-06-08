@echo off
set QT_DIR=C:\Qt\6.11.1\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin
set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%
set QML_IMPORT_PATH=%QT_DIR%\qml

set "APP_DIR=%~dp0.."
set "APP_EXE=%APP_DIR%\build_mingw\KromoStudio.exe"

if not exist "%APP_EXE%" (
    echo [ERROR] No se encuentra KromoStudio.exe en:
    echo         %APP_EXE%
    echo.
    echo Por favor, compila el proyecto primero con: build
    pause
    exit /b 1
)

echo Running KromoStudio...
"%APP_EXE%"
