$env:Path = "C:\Qt\6.11.1\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;$env:Path"
$env:QML_IMPORT_PATH = "C:\Qt\6.11.1\mingw_64\qml"
Write-Host "[KromoStudio] Launching..."
Start-Process -FilePath "$PSScriptRoot\build_mingw\KromoStudio.exe"
