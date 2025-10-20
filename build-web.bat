@echo off
REM Build script for Web - Loan Ranger
echo ========================================
echo Loan Ranger - Web Build Script
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

echo [5/5] Building for Web (Release)...
flutter build web --release
echo.

if %errorlevel% equ 0 (
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo Build Location: build\web\
    echo.
    echo To test locally:
    echo 1. Install 'dhttpd' package: dart pub global activate dhttpd
    echo 2. Run: cd build\web
    echo 3. Run: dhttpd --host localhost --port 8080
    echo 4. Open: http://localhost:8080
    echo.
    echo To deploy:
    echo - Upload the entire 'build\web' folder to your web host
    echo - Or use Firebase/Netlify/Vercel for hosting
    echo.
) else (
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo Check the error messages above.
    echo.
)

pause
