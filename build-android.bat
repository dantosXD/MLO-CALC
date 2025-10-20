@echo off
REM Build script for Android - Loan Ranger
echo ========================================
echo Loan Ranger - Android Build Script
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

echo [1/5] Checking Flutter installation...
flutter doctor -v
echo.

echo [2/5] Cleaning previous builds...
flutter clean
echo.

echo [3/5] Getting dependencies...
flutter pub get
echo.

echo [4/5] Analyzing code...
flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Code analysis found issues
    echo Continue anyway? (Press Ctrl+C to cancel)
    pause
)
echo.

echo [5/5] Building Android APK (Release)...
flutter build apk --release
echo.

if %errorlevel% equ 0 (
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo APK Location:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo File size:
    dir /s build\app\outputs\flutter-apk\app-release.apk | findstr app-release.apk
    echo.
    echo To install on device:
    echo 1. Enable USB Debugging on your Android device
    echo 2. Connect device via USB
    echo 3. Run: flutter install
    echo.
) else (
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo Check the error messages above.
    echo.
)

pause
