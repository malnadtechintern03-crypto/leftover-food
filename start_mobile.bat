@echo off
title Leftover Food - Mobile Flutter App
color 0B

echo =====================================================================
echo               LEFTOVER FOOD - FLUTTER MOBILE APP
echo =====================================================================
echo.

cd /d "%~dp0mobile_app"

where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 'flutter' command not found in system PATH!
    echo Please make sure Flutter SDK is installed and added to PATH.
    echo.
    pause
    exit /b 1
)

echo [INFO] Working directory: %CD%
echo [INFO] Checking connected devices / emulators...
flutter devices
echo.

echo Launching Flutter app in development mode...
flutter run
pause
