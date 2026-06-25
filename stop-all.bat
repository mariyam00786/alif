@echo off
REM Double-click to stop all Alif services (frees ports 3000, 8080, 5071).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-all.ps1"
echo.
pause
