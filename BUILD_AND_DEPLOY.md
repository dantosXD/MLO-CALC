# Build and Deployment Guide - Loan Ranger

## Quick Start

### Prerequisites Installation

#### 1. Install Flutter SDK (includes Dart)
1. Download Flutter from: https://docs.flutter.dev/get-started/install/windows
2. Extract to: `C:\flutter` (or your preferred location)
3. Add to PATH:
   - Open "Edit system environment variables"
   - Click "Environment Variables"
   - Under "User variables", edit "Path"
   - Add: `C:\flutter\bin`
4. Verify installation:
   ```bash
   flutter doctor
   ```

#### 2. Install Dependencies for Android

**Android Studio** (Required for Android builds):
1. Download from: https://developer.android.com/studio
2. Install with default settings
3. Open Android Studio
4. Go to: Tools → SDK Manager
5. Install:
   - Android SDK Platform (API 33 or higher)
   - Android SDK Build-Tools
   - Android Emulator
6. Run `flutter doctor --android-licenses` and accept all

#### 3. Setup for Web
- No additional setup needed if you have Chrome or Edge installed
- Flutter web support is built-in

---

## Building the App

### Step 1: Prepare Project
```bash
cd C:\Users\207ds\Desktop\Apps\MLO-CALC

# Clean any previous builds
flutter clean

# Get all dependencies
flutter pub get

# Verify no issues
flutter analyze
```

### Step 2A: Build for Android

#### Debug Build (for testing)
```bash
# Connect Android device via USB (with USB debugging enabled)
# OR start Android emulator from Android Studio

# Check connected devices
flutter devices

# Run the app
flutter run
```

#### Release Build (for distribution)
```bash
# Build unsigned APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

#### Signed Release Build (for Play Store)
1. Create keystore:
   ```bash
   keytool -genkey -v -keystore loan-ranger-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias loan-ranger
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=loan-ranger
   storeFile=<path-to-keystore>/loan-ranger-key.jks
   ```

3. Update `android/app/build.gradle`:
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

4. Build signed APK:
   ```bash
   flutter build apk --release
   ```

### Step 2B: Build for Web

#### Development Server
```bash
# Run local development server
flutter run -d chrome

# Or specify different browser
flutter run -d edge
```

#### Production Build
```bash
# Build for web
flutter build web --release

# Output location:
# build/web/
```

#### Deploy to Web Server
The `build/web` folder contains all files needed. Upload to:
- **Firebase Hosting**
- **GitHub Pages**
- **Netlify**
- **Vercel**
- Any static web host

---

## Deployment Options

### Android Deployment

#### Option 1: Direct APK Installation
1. Build release APK (see above)
2. Transfer APK to Android device
3. Enable "Install from Unknown Sources" in Settings
4. Install APK

#### Option 2: Google Play Store
1. Create developer account: https://play.google.com/console
2. Build signed APK (see above)
3. Create app listing in Play Console
4. Upload APK or AAB:
   ```bash
   # Build Android App Bundle (recommended for Play Store)
   flutter build appbundle --release
   ```
5. Complete store listing and publish

### Web Deployment

#### Option 1: Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
firebase init hosting

# Build app
flutter build web --release

# Deploy
firebase deploy --only hosting
```

#### Option 2: GitHub Pages
```bash
# Build for web
flutter build web --release --base-href "/MLO-CALC/"

# Copy build/web contents to gh-pages branch
# Enable GitHub Pages in repository settings
```

#### Option 3: Netlify
1. Sign up at https://netlify.com
2. Drag and drop the `build/web` folder to Netlify
3. Or connect GitHub repository for auto-deploy

---

## Testing

### Before Release - Testing Checklist

#### Functional Tests
- [ ] Calculator displays numbers correctly
- [ ] All arithmetic operations work (+, -, ×, ÷)
- [ ] Loan amount calculation works
- [ ] Interest rate calculation works
- [ ] Term calculation works
- [ ] Payment calculation works
- [ ] PITI toggle works
- [ ] Price and down payment auto-calculation works
- [ ] Clear (C) and Clear All (AC) work
- [ ] Decimal input works correctly

#### UI Tests
- [ ] Display shows correct values
- [ ] Status rows update properly
- [ ] Buttons are responsive
- [ ] Colors match design
- [ ] Layout works in portrait mode
- [ ] Layout works in landscape mode (if applicable)

#### Platform-Specific Tests

**Android**:
- [ ] Test on multiple screen sizes
- [ ] Test on different Android versions (8.0+)
- [ ] Check app icon and splash screen
- [ ] Verify back button behavior
- [ ] Test app persistence (state saves correctly)

**Web**:
- [ ] Test in Chrome
- [ ] Test in Firefox
- [ ] Test in Safari
- [ ] Test in Edge
- [ ] Verify responsive design
- [ ] Check loading performance
- [ ] Test offline functionality (if applicable)

---

## Troubleshooting

### Common Build Errors

#### "Flutter SDK not found"
```bash
# Verify Flutter is in PATH
where flutter

# If not found, add Flutter to PATH and restart terminal
```

#### "Android SDK not found"
```bash
# Run Flutter doctor to diagnose
flutter doctor

# Follow recommended actions
flutter doctor --android-licenses
```

#### "Gradle build failed"
```bash
# Clean and retry
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk
```

#### "Web build fails"
```bash
# Ensure web support is enabled
flutter config --enable-web

# Clean and rebuild
flutter clean
flutter pub get
flutter build web
```

### Performance Issues

#### Slow Android Build
```bash
# Enable parallel builds in android/gradle.properties
org.gradle.parallel=true
org.gradle.workers.max=4
```

#### Large APK Size
```bash
# Split APKs by ABI
flutter build apk --split-per-abi

# Results in multiple smaller APKs:
# app-armeabi-v7a-release.apk
# app-arm64-v8a-release.apk
# app-x86_64-release.apk
```

---

## Post-Deployment

### Monitoring
- Set up analytics (Firebase Analytics, Google Analytics)
- Monitor crash reports
- Track user feedback

### Updates
```bash
# Update version in pubspec.yaml
version: 1.0.1+2  # version+build_number

# Rebuild and redeploy
flutter build apk --release
```

---

## Support and Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **Flutter Community**: https://flutter.dev/community
- **Issue Tracker**: https://github.com/flutter/flutter/issues
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/flutter

---

## Quick Reference Commands

```bash
# Check setup
flutter doctor

# Clean project
flutter clean

# Get dependencies
flutter pub get

# Run app (debug)
flutter run

# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build for Web
flutter build web --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/

# Check for updates
flutter upgrade
```
