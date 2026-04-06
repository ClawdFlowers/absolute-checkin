@echo off
setlocal

REM ==========================================
REM Absolute Check-In Launcher
REM Version: 0.6.2
REM ==========================================

REM Get the drive letter where this BAT file is running from
set "SCRIPT_DRIVE=%~d0"

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Check-In-Absolute.ps1"

echo ==========================================
echo   Absolute Check-In Launcher
echo   Version: 0.6.2
echo ==========================================
echo [INFO] Detected drive: %SCRIPT_DRIVE%
echo.

REM Check that the PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo [FAIL] PowerShell script not found:
    echo        "%PS_SCRIPT%"
    echo.
    echo Make sure Check-In-Absolute.ps1 is in the same folder as this BAT file.
    echo.
    pause
    exit /b 1
)

REM Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Administrator rights required.
    echo [INFO] Requesting elevation...
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"

    exit /b
)

echo [OK] Running with Administrator rights.
echo [INFO] Launching PowerShell script...
echo.

REM Pass the detected drive to PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -ScriptDrive "%SCRIPT_DRIVE%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if "%EXITCODE%"=="0" (
    echo [OK] Script completed successfully.
) else (
    echo [WARN] Script exited with code %EXITCODE%.
)

echo.
pause
exit /b %EXITCODE%
