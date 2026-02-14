
@echo off
set QT_DIR=C:\Qt\6.10.2\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin

set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

cd build_mingw
if exist ArtFlowStudio.exe (
    start "" ArtFlowStudio.exe
) else (
    echo Error: ArtFlowStudio.exe not found in build_mingw!
    pause
)
