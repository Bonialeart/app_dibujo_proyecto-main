
@echo off
set QT_DIR=C:\Qt\6.10.2\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin

set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

mkdir build_mingw
cd build_mingw

cmake -G "Ninja" ^
    -DCMAKE_BUILD_TYPE=Debug ^
    -DCMAKE_PREFIX_PATH="%QT_DIR%" ^
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ^
    ..
