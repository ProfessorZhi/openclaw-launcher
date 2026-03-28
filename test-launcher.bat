@echo off
setlocal

set "ROOT=%~dp0"
set "EXE=%ROOT%launcher\OpenClaw Launcher.exe"

if not exist "%EXE%" (
  echo Launcher exe not found:
  echo %EXE%
  pause
  exit /b 1
)

taskkill /IM "OpenClaw Launcher.exe" /F >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Milliseconds 500"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%EXE%'"
exit /b 0
