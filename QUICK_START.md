# 🚀 Quick Start Guide - Loan Ranger

## Current Status

⚠️ **Flutter SDK is not installed on your system**

You need to install Flutter before you can build and test your app.

---

## Option 1: Automated Installation (Easiest) ⚡

### Step 1: Install Flutter SDK

**Open PowerShell as Administrator** and run:

```powershell
cd C:\Users\207ds\Desktop\Apps\MLO-CALC
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-flutter.ps1
```

This will:
- ✅ Download Flutter SDK (~800 MB)
- ✅ Extract to C:\flutter
- ✅ Add Flutter to your PATH
- ✅ Verify installation

**Time Required**: 5-10 minutes (depending on internet speed)

### Step 2: Setup and Test Everything

After Flutter is installed, close and reopen your terminal, then run:

```batch
setup-and-test.bat
```

This will:
- ✅ Check Flutter installation
- ✅ Install project dependencies
- ✅ Analyze code
- ✅ Run tests
- ✅ Build for Android and/or Web

**Time Required**: 5-10 minutes

---

## Option 2: Manual Installation 📝

If you prefer manual control or the automated script doesn't work:

### Step 1: Install Flutter Manually

1. **Download Flutter**
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Download the zip file
   - Extract to `C:\flutter`

2. **Add to PATH**
   - Open System Environment Variables
   - Edit PATH variable
   - Add: `C:\flutter\bin`
   - Restart terminal

3. **Verify Installation**
   ```batch
   flutter --version
   flutter doctor
   ```

### Step 2: Install Dependencies

```batch
cd C:\Users\207ds\Desktop\Apps\MLO-CALC
flutter pub get
```

### Step 3: Run Code Analysis

```batch
flutter analyze
```

### Step 4: Run Tests

```batch
flutter test
```

### Step 5: Build and Test

**For Web (Quick Test)**:
```batch
flutter run -d chrome
```

**For Android**:
```batch
flutter build apk --release
```

**For Web (Production)**:
```batch
flutter build web --release
```

---

## Option 3: Use Provided Scripts 🛠️

After Flutter is installed, you can use these convenient scripts:

### Development

```batch
run-dev.bat
```
Interactive menu to run on Android or Web

### Build Android

```batch
build-android.bat
```
Builds release APK for Android

### Build Web

```batch
build-web.bat
```
Builds production web version

### Complete Setup and Test

```batch
setup-and-test.bat
```
Runs full setup, tests, and builds

---

## 📋 Installation Checklist

Use this checklist to track your progress:

- [ ] Flutter SDK downloaded and extracted
- [ ] Flutter added to PATH
- [ ] `flutter --version` works
- [ ] `flutter doctor` shows no critical errors
- [ ] Android Studio installed (for Android builds)
- [ ] Android licenses accepted (`flutter doctor --android-licenses`)
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] Code analysis passed (`flutter analyze`)
- [ ] Tests passed (`flutter test`)
- [ ] App runs on web (`flutter run -d chrome`)
- [ ] Android APK built successfully
- [ ] Web build completed successfully

---

## 🎯 Quick Commands Reference

```batch
# Check Flutter installation
flutter --version
flutter doctor

# Project setup
cd C:\Users\207ds\Desktop\Apps\MLO-CALC
flutter clean
flutter pub get

# Code quality
flutter analyze
flutter test

# Development
flutter run -d chrome              # Run on web
flutter run                        # Run on Android (device connected)

# Build Release
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android App Bundle (for Play Store)
flutter build web --release        # Web production build
```

---

## 🐛 Common Issues

### "flutter: command not found"
**Solution**: Flutter not in PATH. Restart terminal after installation or add manually.

### "Waiting for another flutter command..."
**Solution**: Delete lock file
```batch
del C:\Users\207ds\AppData\Local\Pub\Cache\.flutter_tool_state
```

### "Android licenses not accepted"
**Solution**:
```batch
flutter doctor --android-licenses
```
Press 'y' to accept all

### "No connected devices"
For Web:
```batch
flutter config --enable-web
```

For Android:
- Enable USB Debugging on your phone
- Connect via USB
- Check with: `flutter devices`

---

## 📦 What Gets Installed

### Flutter SDK (~800 MB)
- Dart SDK
- Flutter framework
- Development tools
- Web support

### Project Dependencies (~50 MB)
- provider (state management)
- google_fonts (typography)
- shared_preferences (storage)
- fl_chart (charts)
- And other packages from pubspec.yaml

### Android SDK (if building for Android) (~3 GB)
- Android Studio
- Android SDK Platform
- Android SDK Build-Tools
- Android Emulator (optional)

---

## 📱 Expected Results

After successful installation and build:

### Android
- **APK File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: ~15-25 MB
- **Min Android**: Android 5.0 (API 21)
- **Installation**: Transfer APK to phone and install

### Web
- **Build Folder**: `build/web/`
- **Size**: ~2-3 MB (gzipped)
- **Compatibility**: All modern browsers
- **Deployment**: Upload folder to any web host

---

## ⏱️ Time Estimates

| Task | First Time | Subsequent |
|------|-----------|------------|
| Flutter SDK Install | 10-15 min | - |
| Project Dependencies | 2-5 min | 30 sec |
| Code Analysis | 30 sec | 30 sec |
| Run Tests | 1-2 min | 1-2 min |
| Web Test (dev) | 30-60 sec | 10-20 sec |
| Android APK Build | 5-10 min | 1-2 min |
| Web Build | 1-2 min | 30-60 sec |

**Total First Setup**: 20-35 minutes
**Daily Development**: Instant with hot reload

---

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ `flutter doctor` shows all green checkmarks
2. ✅ `flutter pub get` completes without errors
3. ✅ `flutter analyze` shows no issues
4. ✅ `flutter test` all tests pass
5. ✅ App opens in Chrome with `flutter run -d chrome`
6. ✅ APK builds successfully
7. ✅ You see the Loan Ranger calculator UI

---

## 📞 Need Help?

1. **Check Documentation**:
   - INSTALL_FLUTTER.md - Detailed installation guide
   - DEBUG_REPORT.md - Troubleshooting
   - BUILD_AND_DEPLOY.md - Build instructions

2. **Run Diagnostics**:
   ```batch
   flutter doctor -v
   ```

3. **Flutter Resources**:
   - Official Docs: https://docs.flutter.dev
   - Installation Guide: https://docs.flutter.dev/get-started/install/windows
   - Common Issues: https://docs.flutter.dev/get-started/install/windows#common-issues

---

**🎯 Start Here**: Run `install-flutter.ps1` in PowerShell as Administrator!
