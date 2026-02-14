
@echo off
set QT_DIR=C:\Qt\6.10.2\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin
set PYTHON_DIR=C:\Program Files\Python311

set PATH=%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

cd src\core\cpp
python setup.py build_ext --inplace --compiler=mingw32
