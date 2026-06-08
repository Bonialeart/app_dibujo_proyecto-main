@echo off
if /I "%1"=="repair" (
    call "%~dp0scripts\repair_build.bat"
    goto :EOF
)
if /I "%1"=="clean" (
    call "%~dp0scripts\clean_rebuild.bat"
    goto :EOF
)
if /I "%1"=="check" (
    call "%~dp0scripts\build_and_check.bat"
    goto :EOF
)
if "%1"=="" (
    call "%~dp0scripts\auto_build.bat"
) else (
    echo Usage: build [check|clean|repair]
    echo   (no arg)  Compile the project
    echo   check     Compile and pause to see results
    echo   clean     Clean rebuild
    echo   repair    Full CMake reconfigure from scratch
)
