@echo off
if "%1"=="" (
    call scripts\auto_build.bat
) else if "%1"=="check" (
    call scripts\build_and_check.bat
) else if "%1"=="clean" (
    call scripts\clean_rebuild.bat
) else if "%1"=="repair" (
    call scripts\repair_build.bat
) else (
    echo Usage: build [check^|clean^|repair]
    echo   (no arg)  Compile the project
    echo   check     Compile and pause to see results
    echo   clean     Clean rebuild
    echo   repair    Full CMake reconfigure from scratch
)
