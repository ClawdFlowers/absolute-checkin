@echo off
setlocal

REM ==========================================
REM Absolute Check-In Launcher
REM Version: 0.7.0
REM ==========================================

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Check-In-Absolute.ps1"

echo ==========================================
echo   Absolute Check-In Launcher
echo   Version: 0.7.2
echo ==========================================
echo.

if not exist "%PS_SCRIPT%" (
    echo [FAIL] PowerShell script not found.
    pause
    exit /b 1
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting elevation...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [OK] Running as Administrator.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if "%EXITCODE%"=="0" (
    echo [OK] Completed successfully.
) else (
    echo [WARN] Exited with code %EXITCODE%.
)

pause
exit /b %EXITCODE%
