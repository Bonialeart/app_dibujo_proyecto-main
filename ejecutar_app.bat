@echo off
echo =========================================
echo    Lanzador de ArtFlow Studio (Con Consola)
echo =========================================
echo.

echo 1. Comprobando entorno...
set QT_DIR=C:\Qt\6.10.2\mingw_64
set MINGW_DIR=C:\Qt\Tools\mingw1310_64
set NINJA_DIR=C:\Qt\Tools\Ninja
set CMAKE_DIR=C:\Qt\Tools\CMake_64\bin

if not exist "%QT_DIR%" (
    echo ERROR CRITICO: No se encuentra Qt en %QT_DIR%
    pause
    exit /b
)

echo 2. Añadiendo rutas al sistema...
set PATH=%CMAKE_DIR%;%QT_DIR%\bin;%MINGW_DIR%\bin;%NINJA_DIR%;%PATH%

echo 3. Compilando cambios recientes en build_mingw...
cmake --build build_mingw --parallel 8
if %errorlevel% neq 0 (
    echo ERROR CRITICO: La compilacion fallo. Revisa los errores arriba.
    pause
    exit /b
)

echo 4. Verificando ejecutable...
if exist "build_mingw\ArtFlowStudio.exe" (
    set EXE_PATH=build_mingw\ArtFlowStudio.exe
) else (
    echo ERROR: No se encuentra build_mingw\ArtFlowStudio.exe
    pause
    exit /b
)

echo 5. Ejecutando aplicacion...
echo.
echo *** MIRA AQUI MIENTRAS DIBUJAS ***
echo Si ves "TABLET START P=0.XXX", la presion funciona.
echo Si ves "MOUSE EVENT", Windows Ink no esta funcionando.
echo.

"%EXE_PATH%"

echo.
echo La aplicacion se ha cerrado.
pause
