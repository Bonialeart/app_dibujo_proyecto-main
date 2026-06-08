@echo off
if "%1"=="" (
    call scripts\run_app.bat
) else if "%1"=="debug" (
    call scripts\run_debug.bat
) else (
    echo Usage: run [debug]
    echo   (no arg)  Launch KromoStudio
    echo   debug     Launch with log redirection
)
