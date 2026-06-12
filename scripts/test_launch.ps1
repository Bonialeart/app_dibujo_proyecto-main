$env:QT_DIR = "C:\Qt\6.11.1\mingw_64"
$env:MINGW_DIR = "C:\Qt\Tools\mingw1310_64"
$env:PATH = "$env:QT_DIR\bin;$env:MINGW_DIR\bin;$env:PATH"
$env:QML_IMPORT_PATH = "$env:QT_DIR\qml"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appExe = Join-Path $scriptDir "..\build_mingw\KromoStudio.exe"
$outLog = Join-Path $scriptDir "..\app_debug.log"
$errLog = Join-Path $scriptDir "..\app_debug_err.log"

$p = Start-Process -FilePath $appExe -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru
Start-Sleep -Seconds 8
if (!$p.HasExited) {
    Write-Host "Process running (PID: $($p.Id))"
    Stop-Process -Id $p.Id -Force
    Write-Host "Process stopped"
} else {
    Write-Host "Process exited with code: $($p.ExitCode)"
}
