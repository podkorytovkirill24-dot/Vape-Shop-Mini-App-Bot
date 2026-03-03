@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo Starting OZON Oskemen with Cloudflare tunnel...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start_with_cloudflare.ps1"

echo.
echo Stopped.
pause

