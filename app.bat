@echo off
setlocal
set QT_DIR=C:\Qt\6.11.1\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set PATH=%QT_DIR%\bin;%MINGW_DIR%\bin;%PATH%
set QML_IMPORT_PATH=%QT_DIR%\qml

echo [KromoStudio] Launching...
start "" "%~dp0build_mingw\KromoStudio.exe"
exit /b 0
