@echo off
set PATH=C:\Qt\Tools\CMake_64\bin;C:\Qt\6.10.2\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;%PATH%
echo Running ArtFlowStudio... > run_log.txt
build_mingw\ArtFlowStudio.exe >> run_log.txt 2>&1
echo Exit Code: %ERRORLEVEL% >> run_log.txt
