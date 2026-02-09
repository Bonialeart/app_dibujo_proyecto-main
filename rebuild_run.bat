@echo off
set "QT_DIR=C:\Qt\6.10.2\mingw_64"
set "MINGW_DIR=C:\Qt\Tools\mingw1310_64"
set "NINJA_DIR=C:\Qt\Tools\Ninja"
set "CMAKE_DIR=C:\Qt\Tools\CMake_64\bin"
set "PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%"

echo Compiling...
cmake --build build_mingw --parallel 8
if %errorlevel% neq 0 (
    echo Compilation failed
    exit /b %errorlevel%
)

echo Running ArtFlowStudio...
build_mingw\ArtFlowStudio.exe
echo Exit Code: %ERRORLEVEL%
