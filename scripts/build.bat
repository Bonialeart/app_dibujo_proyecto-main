@echo off
if /I "%1"=="repair" (
    call "%~dp0repair_build.bat"
    goto :EOF
)
if /I "%1"=="clean" (
    call "%~dp0clean_rebuild.bat"
    goto :EOF
)
if /I "%1"=="check" (
    call "%~dp0build_and_check.bat"
    goto :EOF
)
if /I "%1"=="android" (
    call "%~dp0build_android.bat"
    goto :EOF
)
if "%1"=="" (
    call "%~dp0auto_build.bat"
) else (
    echo Usage: build [check|clean|repair|android]
    echo   [no arg]  Compile the project for MinGW
    echo   check     Compile for MinGW and pause to see results
    echo   clean     Clean rebuild for MinGW
    echo   repair    Full CMake reconfigure from scratch for MinGW
    echo   android   Build and sign the Android APK
)
