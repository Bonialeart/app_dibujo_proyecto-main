
@echo off
set QT_DIR=C:\Qt\6.11.1\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin

set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

cd /d "%~dp0.."
cd build_mingw
if exist KromoStudio.exe (
    start "" KromoStudio.exe
) else (
    echo Error: KromoStudio.exe not found in build_mingw!
    pause
)
