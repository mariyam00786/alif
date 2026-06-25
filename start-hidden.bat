@echo off
REM Double-click to start all Alif services HIDDEN in the background.
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0start-hidden.ps1"
exit
