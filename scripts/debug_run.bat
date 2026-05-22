@echo off
set PATH=C:\Qt\Tools\CMake_64\bin;C:\Qt\6.11.1\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;%PATH%
echo Running KromoStudio... > run_log.txt
build_mingw\KromoStudio.exe >> run_log.txt 2>&1
echo Exit Code: %ERRORLEVEL% >> run_log.txt
