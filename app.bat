@echo off
set QT_DIR=C:\Qt\6.11.1\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set PATH=%QT_DIR%\bin;%MINGW_DIR%\bin;%PATH%
set QML_IMPORT_PATH=%QT_DIR%\qml

set "APP_EXE=%~dp0build_mingw\KromoStudio.exe"

if not exist "%APP_EXE%" (
    echo [ERROR] No se encuentra KromoStudio.exe en:
    echo         %APP_EXE%
    echo.
    echo Por favor, compila el proyecto primero con: build
    pause
    exit /b 1
)

echo [KromoStudio] Launching...
start "KromoStudio" "%APP_EXE%"
