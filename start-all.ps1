# ============================================================
#  Alif - Start ALL services on FIXED ports (do NOT change)
#  Backend     -> http://localhost:3000
#  Admin Panel -> http://localhost:8080
#  Mobile App  -> http://localhost:5071
#  Usage:  ./start-all.ps1   (run from the project root)
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'
$root = $PSScriptRoot

# Free the fixed ports first so they are always the same link
foreach ($port in 3000, 8080, 5071) {
    Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}

# Backend API -> http://localhost:3000
Start-Process powershell -ArgumentList '-NoExit', '-Command',
    "Set-Location '$root\backend'; npm run dev"

# Admin Panel -> http://localhost:8080 (web-server: same link, just refresh)
Start-Process powershell -ArgumentList '-NoExit', '-Command',
    "Set-Location '$root\admin-panel'; flutter run -d web-server --web-port 8080 --dart-define-from-file=../dart-defines.json"

# Mobile App -> http://localhost:5071 (web-server: same link, just refresh)
Start-Process powershell -ArgumentList '-NoExit', '-Command',
    "Set-Location '$root\mobile_app'; flutter run -d web-server --web-port 5071 --dart-define-from-file=../dart-defines.json"

Write-Host ''
Write-Host '  Alif services starting on FIXED links:' -ForegroundColor Cyan
Write-Host '  Backend API   : http://localhost:3000' -ForegroundColor Green
Write-Host '  Admin Panel   : http://localhost:8080' -ForegroundColor Green
Write-Host '  Mobile App    : http://localhost:5071' -ForegroundColor Green
Write-Host ''
Write-Host '  Tip: after editing code, press "r" (hot reload) or "R" (restart)' -ForegroundColor DarkGray
Write-Host '       in the Flutter window, then just refresh the SAME link.' -ForegroundColor DarkGray
