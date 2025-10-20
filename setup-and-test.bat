@echo off
REM Complete Setup and Test Script for Loan Ranger
REM This script will check for Flutter, install dependencies, and run tests

echo ========================================
echo Loan Ranger - Complete Setup and Test
echo ========================================
echo.

REM Change to project directory
cd /d "%~dp0"

REM Check if Flutter is installed
echo [Step 1/7] Checking Flutter installation...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Flutter not found in PATH!
    echo.
    echo Please install Flutter first using one of these methods:
    echo   1. Run install-flutter.ps1 in PowerShell as Administrator
    echo   2. Follow the guide in INSTALL_FLUTTER.md
    echo   3. Manual install from: https://flutter.dev
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter found
flutter --version
echo.

REM Run Flutter Doctor
echo [Step 2/7] Running Flutter Doctor...
echo This checks your development environment setup
echo.
flutter doctor
echo.

REM Clean previous builds
echo [Step 3/7] Cleaning previous builds...
flutter clean
echo [OK] Clean complete
echo.

REM Get dependencies
echo [Step 4/7] Installing project dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed
echo.

REM Analyze code
echo [Step 5/7] Analyzing code...
flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Code analysis found issues
    echo Review the output above
    echo.
    set /p continue="Continue anyway? (Y/N): "
    if /i not "%continue%"=="Y" exit /b 1
)
echo [OK] Code analysis complete
echo.

REM Run tests
echo [Step 6/7] Running unit and widget tests...
flutter test
if %errorlevel% neq 0 (
    echo WARNING: Some tests failed
    echo Review the output above
    echo.
)
echo [OK] Tests complete
echo.

REM Build options
echo [Step 7/7] Build Options
echo.
echo Select what to build:
echo   1. Test on Web (Chrome) - Quick test
echo   2. Build Android APK - Release
echo   3. Build Web - Release
echo   4. Run all tests and builds
echo   5. Skip building (setup only)
echo.
set /p choice="Enter choice (1-5): "

if "%choice%"=="1" goto build_web_test
if "%choice%"=="2" goto build_android
if "%choice%"=="3" goto build_web_release
if "%choice%"=="4" goto build_all
if "%choice%"=="5" goto complete

:build_web_test
echo.
echo ========================================
echo Testing on Web (Chrome)
echo ========================================
echo.
echo Starting Flutter web server...
echo The app will open in Chrome automatically
echo Press Ctrl+C to stop the server
echo.
flutter run -d chrome
goto complete

:build_android
echo.
echo ========================================
echo Building Android APK (Release)
echo ========================================
echo.
flutter build apk --release
if %errorlevel% equ 0 (
    echo.
    echo [OK] Android build successful!
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    dir /s build\app\outputs\flutter-apk\app-release.apk 2>nul | findstr /i app-release.apk
)
goto complete

:build_web_release
echo.
echo ========================================
echo Building Web (Release)
echo ========================================
echo.
flutter build web --release
if %errorlevel% equ 0 (
    echo.
    echo [OK] Web build successful!
    echo Build Location: build\web\
    echo.
    echo To test locally:
    echo   1. cd build\web
    echo   2. python -m http.server 8080
    echo   3. Open: http://localhost:8080
)
goto complete

:build_all
echo.
echo ========================================
echo Building All Targets
echo ========================================
echo.

echo [1/2] Building Android APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Android build failed
) else (
    echo [OK] Android APK built successfully
)
echo.

echo [2/2] Building Web...
flutter build web --release
if %errorlevel% neq 0 (
    echo ERROR: Web build failed
) else (
    echo [OK] Web built successfully
)

:complete
echo.
echo ========================================
echo Setup and Test Complete!
echo ========================================
echo.
echo Project Status:
echo   - Dependencies: Installed
echo   - Code Analysis: Complete
echo   - Tests: Run
echo.
echo Build Outputs:
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo   - Android APK: build\app\outputs\flutter-apk\app-release.apk
)
if exist "build\web\index.html" (
    echo   - Web Build: build\web\
)
echo.
echo To run the app:
echo   - Web:     flutter run -d chrome
echo   - Android: flutter run (with device connected)
echo.
echo To rebuild:
echo   - Android: flutter build apk --release
echo   - Web:     flutter build web --release
echo.
pause
