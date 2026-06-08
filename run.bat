@echo off
if /I "%1"=="debug" (
    call "%~dp0scripts\run_debug.bat"
    goto :EOF
)
if "%1"=="" (
    call "%~dp0scripts\run_app.bat"
) else (
    echo Usage: run [debug]
    echo   (no arg)  Launch KromoStudio
    echo   debug     Launch with log redirection
)