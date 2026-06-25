# ============================================================
#  Alif - Start ALL services HIDDEN (no visible windows)
#  Backend     -> http://localhost:3000
#  Admin Panel -> http://localhost:5002
#  Mobile App  -> http://localhost:5001
#
#  Runs each service as a hidden background process. The windows
#  are invisible, so use stop-all.ps1 to stop them.
#  Output of each service is written to .\logs\<name>.log
#
#  Usage:  ./start-hidden.ps1   (or double-click start-hidden.bat)
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'
$root = $PSScriptRoot

# Make a logs folder so a hidden service that fails can still be debugged.
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

# Free the fixed ports first so the links are always the same.
foreach ($port in 3000, 5001, 5002) {
    Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}

# Launch a command in a hidden PowerShell window, logging all output to a file.
function Start-HiddenService {
    param([string]$Name, [string]$WorkDir, [string]$Command)

    $log = Join-Path $logDir "$Name.log"
    "==== $Name started $(Get-Date) ====" | Out-File -FilePath $log -Encoding utf8

    $inner = "Set-Location '$WorkDir'; $Command *>> '$log'"
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-Command', $inner `
        -WindowStyle Hidden
}

Start-HiddenService 'backend' "$root\backend" 'npm run dev'
Start-HiddenService 'admin'   "$root\admin-panel" 'flutter run -d web-server --web-port 5002 --dart-define-from-file=../dart-defines.json'
Start-HiddenService 'mobile'  "$root\mobile_app" 'flutter run -d web-server --web-port 5001 --dart-define-from-file=../dart-defines.json'

Write-Host ''
Write-Host '  Alif services starting HIDDEN in the background:' -ForegroundColor Cyan
Write-Host '  Backend API   : http://localhost:3000' -ForegroundColor Green
Write-Host '  Admin Panel   : http://localhost:5002' -ForegroundColor Green
Write-Host '  Mobile App    : http://localhost:5001' -ForegroundColor Green
Write-Host ''
Write-Host '  No windows are shown. Give Flutter ~40-60s to compile, then open the links.' -ForegroundColor DarkGray
Write-Host '  Logs       : .\logs\backend.log  .\logs\admin.log  .\logs\mobile.log' -ForegroundColor DarkGray
Write-Host '  To STOP    : run ./stop-all.ps1  (or double-click stop-all.bat)' -ForegroundColor DarkGray
