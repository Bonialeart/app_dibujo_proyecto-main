$env:QT_DIR = "C:\Qt\6.11.1\mingw_64"
$env:MINGW_DIR = "C:\Qt\Tools\mingw1310_64"
$env:PATH = "$env:QT_DIR\bin;$env:MINGW_DIR\bin;$env:PATH"
$env:QML_IMPORT_PATH = "$env:QT_DIR\qml"

$p = Start-Process -FilePath "E:\Programacion\Rescate_Proyecto\build_mingw\KromoStudio.exe" -NoNewWindow -RedirectStandardOutput "E:\Programacion\Rescate_Proyecto\app_debug.log" -RedirectStandardError "E:\Programacion\Rescate_Proyecto\app_debug_err.log" -PassThru
Start-Sleep -Seconds 8
if (!$p.HasExited) {
    Write-Host "Process running (PID: $($p.Id))"
    Stop-Process -Id $p.Id -Force
    Write-Host "Process stopped"
} else {
    Write-Host "Process exited with code: $($p.ExitCode)"
}
