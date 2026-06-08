$appExe = Join-Path $PSScriptRoot "build_mingw\KromoStudio.exe"

if (-not (Test-Path $appExe)) {
    Write-Host "[ERROR] No se encuentra KromoStudio.exe en:" -ForegroundColor Red
    Write-Host "        $appExe"
    Write-Host ""
    Write-Host "Por favor, compila el proyecto primero con: build"
    pause
    exit 1
}

$env:Path = "C:\Qt\6.11.1\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;$env:Path"
$env:QML_IMPORT_PATH = "C:\Qt\6.11.1\mingw_64\qml"
Write-Host "[KromoStudio] Launching..."
Start-Process -FilePath $appExe
