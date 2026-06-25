# ============================================================
#  Alif - Stop ALL services (frees the fixed ports)
#  Stops backend (3000), admin (5002), mobile (5001) and any
#  stray Flutter/Dart dev processes started by them.
#
#  Usage:  ./stop-all.ps1   (or double-click stop-all.bat)
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

$stopped = @()

# 1) Kill whatever is listening on the fixed ports.
foreach ($port in 3000, 5001, 5002) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($procId in ($conns.OwningProcess | Select-Object -Unique)) {
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) { $stopped += "port $port -> $($proc.ProcessName) (PID $procId)" }
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
}

# 2) Clean up stray Flutter web compilers left behind (dartvm / flutter_tester).
Get-Process -Name dartvm, flutter_tester -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }

Start-Sleep -Milliseconds 600

Write-Host ''
if ($stopped.Count -gt 0) {
    Write-Host '  Stopped:' -ForegroundColor Yellow
    $stopped | ForEach-Object { Write-Host "   - $_" -ForegroundColor DarkGray }
} else {
    Write-Host '  Nothing was running on 3000 / 5001 / 5002.' -ForegroundColor DarkGray
}

foreach ($port in 3000, 5001, 5002) {
    if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
        Write-Host "  PORT $port : STILL BUSY" -ForegroundColor Red
    } else {
        Write-Host "  PORT $port : free" -ForegroundColor Green
    }
}
