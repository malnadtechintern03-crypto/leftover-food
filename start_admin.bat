@echo off
title Leftover Food - Admin Panel & REST API Server
color 0A

echo =====================================================================
echo           LEFTOVER FOOD & GROCERY - ADMIN PANEL & REST API
echo =====================================================================
echo.

:: Detect PHP binary
set PHP_BIN=
where php >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set PHP_BIN=php
) else if exist "C:\xampp\php\php.exe" (
    set PHP_BIN="C:\xampp\php\php.exe"
) else if exist "D:\xampp\php\php.exe" (
    set PHP_BIN="D:\xampp\php\php.exe"
)

if "%PHP_BIN%"=="" (
    echo [ERROR] PHP executable not found in system PATH or C:\xampp\php\php.exe!
    echo Please install XAMPP or add PHP to your Windows PATH environment variable.
    echo.
    pause
    exit /b 1
)

echo [OK] Using PHP: %PHP_BIN%
echo [INFO] Document Root: admin/
echo [INFO] Local Web Admin:       http://localhost:8000
echo [INFO] Mobile REST API:       http://localhost:8000/api/
echo [INFO] Android Emulator API:  http://10.0.2.2:8000/api/
echo.
:: Check if MySQL is running on port 3306
netstat -ano | findstr :3306 >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] MySQL is not detected on port 3306.
    if exist "C:\xampp\mysql_start.bat" (
        echo [INFO] Starting MySQL service via XAMPP...
        start "" /b "C:\xampp\mysql_start.bat"
        timeout /t 2 /nobreak >nul
    ) else (
        echo [NOTE] Please ensure MySQL is started in XAMPP Control Panel.
    )
) else (
    echo [OK] MySQL is active on port 3306.
)
echo Database schema is at: admin\database\schema.sql
echo Default Admin credentials: admin / admin123
echo.
echo Opening browser to http://localhost:8000 ...
start http://localhost:8000

echo Starting PHP built-in web server on 0.0.0.0:8000 ...
echo Press Ctrl+C at any time to stop the server.
echo.

%PHP_BIN% -S 0.0.0.0:8000 -t admin
pause
