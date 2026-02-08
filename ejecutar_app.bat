@echo off
echo =========================================
echo    Lanzador de ArtFlow Studio (Con Consola)
echo =========================================
echo.

echo 1. Comprobando entorno...
set QT_DIR=C:\Qt\6.10.2\mingw_64\bin
set MINGW_DIR=C:\Qt\Tools\mingw1310_64\bin

if not exist "%QT_DIR%" (
    echo ERROR CRITICO: No se encuentra Qt en %QT_DIR%
    pause
    exit /b
)

echo 2. Añandiendo rutas al sistema...
set PATH=%QT_DIR%;%MINGW_DIR%;%PATH%

echo 3. Buscando ejecutable en build_debug_winink...
if not exist "build_debug_winink\ArtFlowStudio.exe" (
    echo ERROR: No se encuentra build_debug_winink\ArtFlowStudio.exe
    if exist "build_debug\ArtFlowStudio.exe" (
         set EXE_PATH=build_debug\ArtFlowStudio.exe
    ) else (
         if exist "build_release\ArtFlowStudio.exe" (
             set EXE_PATH=build_release\ArtFlowStudio.exe
         ) else (
             echo No se encuentra ningun ejecutable.
             pause
             exit /b
         )
    )
) else (
    set EXE_PATH=build_debug_winink\ArtFlowStudio.exe
)

echo 4. Ejecutando aplicacion...
echo.
echo *** MIRA AQUI MIENTRAS DIBUJAS ***
echo Si ves "TABLET START P=0.XXX", la presion funciona.
echo Si ves "MOUSE EVENT", Windows Ink no esta funcionando.
echo.

"%EXE_PATH%"

echo.
echo La aplicacion se ha cerrado.
pause
