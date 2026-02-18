@echo off
set QT_DIR=C:\Qt\6.10.2\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin
set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

echo [1/3] Eliminando build folder corrupto...
if exist build_mingw rmdir /s /q build_mingw

echo [2/3] Creando nuevo build folder...
mkdir build_mingw

echo [3/3] Reconfigurando CMake con nuevas rutas...
cd build_mingw
cmake -G Ninja -S .. -B . ^
    -DCMAKE_PREFIX_PATH="%QT_DIR%" ^
    -DCMAKE_C_COMPILER="%MINGW_DIR%\bin\gcc.exe" ^
    -DCMAKE_CXX_COMPILER="%MINGW_DIR%\bin\g++.exe" ^
    -DCMAKE_MAKE_PROGRAM="%NINJA_DIR%\ninja.exe"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo EXITO: El entorno se ha reparado.
    echo Ahora puedes ejecutar auto_build.bat o run_app.bat
    echo ==========================================
) else (
    echo.
    echo ERROR: La configuracion fallo. Verifica las rutas de Qt/MinGW en el script.
)
pause
