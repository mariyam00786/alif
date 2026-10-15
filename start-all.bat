@echo off
REM Double-click to start all Alif services in separate terminal windows.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-all.ps1"
