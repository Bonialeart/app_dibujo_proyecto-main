@echo off
setlocal EnableDelayedExpansion

echo ============================================================
echo  KromoStudio - Build para Android (arm64-v8a)
echo ============================================================

REM -- Rutas del entorno
set CMAKE=C:\Qt\Tools\CMake_64\bin\cmake.exe
set NINJA=C:\Qt\Tools\Ninja\ninja.exe
set QT_ANDROID=C:\Qt\6.11.1\android_arm64_v8a
set QT_HOST=C:\Qt\6.11.1\mingw_64
set NDK=C:\Users\bonia\AppData\Local\Android\Sdk\ndk\26.3.11579264
set SDK=C:\Users\bonia\AppData\Local\Android\Sdk
set JDK=C:\Program Files\Java\jdk-17

REM -- Obtener el directorio raíz del proyecto (un nivel arriba del script)
set SCRIPT_DIR=%~dp0
set SRC=%SCRIPT_DIR%..
for %%i in ("%SRC%") do set SRC=%%~fi

set BUILD=%SRC%\build\Android_arm64_CLI
set "LOG_DIR=%BUILD%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set LOG=%LOG_DIR%\cmake_configure.log

REM -- Variables de entorno para Java y Gradle
set JAVA_HOME=%JDK%
set ANDROID_SDK_ROOT=%SDK%
set PATH=%JDK%\bin;%PATH%

REM -- Redirigir Cargo a C: para evitar "Acceso denegado" en el pendrive
set CARGO_TARGET_DIR=C:\Users\bonia\cargo_android_build

if not exist "%BUILD%" mkdir "%BUILD%"

echo.
echo [1/3] Configurando CMake... (guardando log en build\Android_arm64_CLI\logs\cmake_configure.log)
echo.

"%CMAKE%" ^
  -S "%SRC%" ^
  -B "%BUILD%" ^
  -G "Ninja" ^
  -DCMAKE_MAKE_PROGRAM="%NINJA%" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DANDROID_ABI=arm64-v8a ^
  -DANDROID_NDK="%NDK%" ^
  -DANDROID_PLATFORM=android-28 ^
  -DANDROID_SDK_ROOT="%SDK%" ^
  -DANDROID_STL=c++_shared ^
  -DANDROID_USE_LEGACY_TOOLCHAIN_FILE=OFF ^
  -DCMAKE_TOOLCHAIN_FILE="%NDK%\build\cmake\android.toolchain.cmake" ^
  -DCMAKE_FIND_ROOT_PATH="%QT_ANDROID%" ^
  -DCMAKE_PREFIX_PATH="%QT_ANDROID%" ^
  -DQT_HOST_PATH="%QT_HOST%" ^
  -DQT_QMAKE_EXECUTABLE="%QT_ANDROID%\bin\qmake.bat" ^
  -DQT_USE_TARGET_ANDROID_BUILD_DIR=ON ^
  -DQT_NO_GLOBAL_APK_TARGET_PART_OF_ALL=OFF ^
  -DCMAKE_CXX_COMPILER="%NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\clang++.exe" ^
  -DCMAKE_C_COMPILER="%NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe" ^
  > "%LOG%" 2>&1

type "%LOG%"

if not exist "%BUILD%\CMakeCache.txt" (
    echo.
    echo [ERROR] CMake fallo - no se creo CMakeCache.txt
    echo Revisa el archivo: %LOG%
    pause
    exit /b 1
)

echo.
echo [2/3] Compilando el proyecto...
echo.

"%CMAKE%" --build "%BUILD%" --config Release --parallel > "%LOG_DIR%\cmake_build.log" 2>&1
type "%LOG_DIR%\cmake_build.log"

if errorlevel 1 (
    echo.
    echo [ERROR] Fallo la compilacion. Revisa cmake_build.log
    pause
    exit /b 1
)

echo.
echo [3/3] Generando APK...
echo.

"%CMAKE%" --build "%BUILD%" --target apk > "%LOG_DIR%\cmake_apk.log" 2>&1
type "%LOG_DIR%\cmake_apk.log"

if errorlevel 1 (
    echo.
    echo [ERROR] Fallo la generacion de APK. Revisa cmake_apk.log
    pause
    exit /b 1
)

REM -- Firmar la APK generada
echo.
echo [4/4] Firmando la APK...
echo.

set APKSIGNER=%SDK%\build-tools\37.0.0\apksigner.bat
if not exist "%APKSIGNER%" set APKSIGNER=%SDK%\build-tools\36.1.0\apksigner.bat

set "KEYSTORE=%SRC%\security\my-release-key.jks"
set "RELEASE_DIR=%SRC%\release"
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

if exist "%KEYSTORE%" goto :SIGN_APK
echo [INFO] Creando certificado de firma (keystore)...
if not exist "%SRC%\security" mkdir "%SRC%\security"
"%JDK%\bin\keytool.exe" -genkey -v -keystore "%KEYSTORE%" -keyalg RSA -keysize 2048 -validity 10000 -alias my-alias -storepass password -keypass password -dname "CN=KromoStudio, OU=Development, O=KromoStudio, L=City, S=State, C=US"

:SIGN_APK

"%APKSIGNER%" sign --ks "%KEYSTORE%" --ks-key-alias my-alias --ks-pass pass:password --key-pass pass:password --out "%RELEASE_DIR%\KromoStudio.apk" "%BUILD%\android-build-KromoStudio\build\outputs\apk\release\android-build-KromoStudio-release-unsigned.apk"

if errorlevel 1 (
    echo.
    echo [ERROR] Fallo al firmar la APK.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  BUILD COMPLETADO Y FIRMADO!
echo  Instala el archivo KromoStudio.apk en tu tablet:
echo  %RELEASE_DIR%\KromoStudio.apk
echo ============================================================
echo.
REM pause
