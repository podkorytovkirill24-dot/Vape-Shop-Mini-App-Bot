@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo Creating virtual environment...
  python -m venv .venv
  if errorlevel 1 goto :fail
)

call ".venv\Scripts\activate.bat"
if errorlevel 1 goto :fail

echo Installing dependencies...
python -m pip install -r requirements.txt
if errorlevel 1 goto :fail

if not exist ".env" (
  copy ".env.example" ".env" >nul
)

echo Starting app locally on http://127.0.0.1:8000
python main.py
goto :end

:fail
echo Failed to start.

:end
echo.
pause

