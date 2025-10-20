@echo off
REM Development run script - Loan Ranger
echo ========================================
echo Loan Ranger - Development Run
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found in PATH!
    echo Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

echo Select platform:
echo 1. Android (device/emulator)
echo 2. Web (Chrome)
echo 3. Web (Edge)
echo.
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Running on Android...
    flutter run
) else if "%choice%"=="2" (
    echo.
    echo Running on Web (Chrome)...
    flutter run -d chrome
) else if "%choice%"=="3" (
    echo.
    echo Running on Web (Edge)...
    flutter run -d edge
) else (
    echo Invalid choice!
    pause
    exit /b 1
)
