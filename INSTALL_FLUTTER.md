# Flutter Installation & Setup Guide

## ⚠️ IMPORTANT: Flutter Not Detected

Flutter SDK is not currently installed or not in your system PATH.
This guide will walk you through the installation process.

---

## 🚀 Quick Installation (Windows)

### Step 1: Download Flutter SDK

1. Go to: https://docs.flutter.dev/get-started/install/windows
2. Download the latest stable release (Flutter SDK zip file)
3. Or use direct link: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_stable.zip

### Step 2: Extract Flutter

```powershell
# Extract to C:\flutter (recommended) or your preferred location
# For example: C:\src\flutter or C:\dev\flutter

# The structure should be:
C:\flutter\
  ├── bin\
  ├── packages\
  └── ...
```

### Step 3: Add Flutter to PATH

**Option A: Using PowerShell (Recommended)**
```powershell
# Open PowerShell as Administrator
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\flutter\bin",
    "User"
)
```

**Option B: Using System Settings**
1. Right-click "This PC" → Properties
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "User variables", select "Path" and click "Edit"
5. Click "New" and add: `C:\flutter\bin`
6. Click "OK" on all windows

**Option C: Using Command Prompt**
```cmd
setx PATH "%PATH%;C:\flutter\bin"
```

### Step 4: Verify Installation

**Close and reopen your terminal, then run:**
```bash
flutter --version
```

You should see output like:
```
Flutter 3.x.x • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart 3.x.x
```

### Step 5: Run Flutter Doctor

```bash
flutter doctor -v
```

This will check your environment and show what needs to be configured.

---

## 🔧 Additional Setup Required

### For Android Development

1. **Install Android Studio**
   - Download: https://developer.android.com/studio
   - Install with default settings

2. **Install Android SDK**
   - Open Android Studio
   - Go to: Tools → SDK Manager
   - Install:
     - Android SDK Platform (API 33 or higher)
     - Android SDK Build-Tools
     - Android Emulator

3. **Accept Android Licenses**
   ```bash
   flutter doctor --android-licenses
   ```
   Press 'y' to accept all licenses

4. **Configure Android Studio**
   - Go to: File → Settings → Plugins
   - Install "Flutter" plugin
   - Install "Dart" plugin
   - Restart Android Studio

### For Web Development

No additional setup needed! Web support is included with Flutter.

Just ensure you have Chrome or Edge installed.

---

## 📱 Your Next Steps After Installation

Once Flutter is installed, navigate to your project and run:

### 1. Install Project Dependencies
```bash
cd C:\Users\207ds\Desktop\Apps\MLO-CALC
flutter pub get
```

### 2. Verify Project
```bash
flutter analyze
```

### 3. Run on Web (Quick Test)
```bash
flutter run -d chrome
```

### 4. Build for Android
```bash
flutter build apk --release
```

### 5. Build for Web
```bash
flutter build web --release
```

---

## 🚀 Automated Installation Script

Save this as `install-flutter.ps1` and run with PowerShell:

```powershell
# Flutter Installation Script for Windows

Write-Host "Flutter Installation Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Set installation directory
$flutterPath = "C:\flutter"
$downloadUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_stable.zip"
$zipFile = "$env:TEMP\flutter_windows.zip"

# Download Flutter
Write-Host "`nDownloading Flutter SDK..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

# Extract Flutter
Write-Host "Extracting Flutter SDK to $flutterPath..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath "C:\" -Force

# Add to PATH
Write-Host "Adding Flutter to PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterPath\bin*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$currentPath;$flutterPath\bin",
        "User"
    )
    Write-Host "Flutter added to PATH" -ForegroundColor Green
} else {
    Write-Host "Flutter already in PATH" -ForegroundColor Yellow
}

# Cleanup
Remove-Item $zipFile

Write-Host "`n================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`nPlease close and reopen your terminal, then run:" -ForegroundColor Cyan
Write-Host "  flutter doctor" -ForegroundColor White
Write-Host "`nTo start using Flutter in your project:" -ForegroundColor Cyan
Write-Host "  cd C:\Users\207ds\Desktop\Apps\MLO-CALC" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run -d chrome" -ForegroundColor White
```

To run:
```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-flutter.ps1
```

---

## 🔍 Troubleshooting

### "flutter: command not found" after installation
- Close and reopen your terminal
- Verify PATH with: `echo %PATH%` (CMD) or `$env:Path` (PowerShell)
- Ensure `C:\flutter\bin` is in the PATH

### "Waiting for another flutter command to release the startup lock"
```bash
# Delete the lock file
del C:\Users\207ds\AppData\Local\Pub\Cache\.flutter_tool_state
```

### "Android licenses are not accepted"
```bash
flutter doctor --android-licenses
# Press 'y' to accept all
```

### "Unable to locate Android SDK"
1. Open Android Studio
2. File → Project Structure → SDK Location
3. Copy the Android SDK path
4. Set environment variable:
   ```cmd
   setx ANDROID_HOME "C:\Users\YourName\AppData\Local\Android\Sdk"
   ```

---

## 📋 Verification Checklist

After installation, verify everything works:

- [ ] `flutter --version` shows version info
- [ ] `flutter doctor` shows no critical errors
- [ ] `flutter devices` shows available devices
- [ ] `dart --version` works (included with Flutter)

---

## 🎯 Quick Start After Installation

```bash
# Navigate to project
cd C:\Users\207ds\Desktop\Apps\MLO-CALC

# Get dependencies
flutter pub get

# Run on web (fastest to test)
flutter run -d chrome

# Or use the provided batch files
run-dev.bat
```

---

## 📞 Support

- Flutter Installation Guide: https://docs.flutter.dev/get-started/install/windows
- Flutter Documentation: https://docs.flutter.dev
- Common Issues: https://docs.flutter.dev/get-started/install/windows#common-issues

---

**Once Flutter is installed, you can proceed with building and testing your app!**
