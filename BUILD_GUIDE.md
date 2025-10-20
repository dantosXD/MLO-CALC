# Loan Ranger - Build Guide

## Production-Ready Builds

### Build Status
✅ **Android APK**: Successfully built (46MB)
✅ **Web**: Successfully built (2.4MB main.dart.js)

---

## Quick Build Commands

### Android
```bash
# Release APK
flutter build apk --release

# Debug APK
flutter build apk --debug

# App Bundle (for Google Play Store)
flutter build appbundle --release
```

**Output Location**: `build/app/outputs/flutter-apk/app-release.apk`

### Web
```bash
# Production build
flutter build web --release

# With WebAssembly (experimental)
flutter build web --release --wasm

# Local testing
flutter run -d chrome
```

**Output Location**: `build/web/`

### Development
```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d chrome          # Web browser
flutter run -d linux-desktop   # Linux desktop
flutter run -d <device-id>     # Specific device

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

---

## App Configuration

### Application ID
- **Package Name**: `com.loanranger.calculator`
- **Debug Variant**: `com.loanranger.calculator.debug`

### Version Information
- **Version Code**: 1
- **Version Name**: 1.0.0

Location: `android/app/build.gradle.kts`

### Minimum Requirements
- **Android**: API 21 (Android 5.0 Lollipop)
- **iOS**: iOS 11+ (when configured)
- **Web**: Modern browsers with JavaScript enabled

---

## Features Implemented

### Core Calculator
- ✅ Dual-mode calculator (arithmetic + financial)
- ✅ Loan amount, interest rate, term, and payment calculations
- ✅ Automatic solving for missing variable
- ✅ PITI (Principal, Interest, Taxes, Insurance) toggle
- ✅ Down payment auto-calculation with percentage/amount heuristic

### Loan Analysis
- ✅ **Amortization Schedule**: Month-by-month payment breakdown
- ✅ **Balloon Payment Calculator**: Remaining balance after X years
- ✅ **Bi-Weekly Payment Analysis**: Calculate interest savings
- ✅ **PITI Components**: Property tax, home insurance, PMI, monthly expenses

### Qualification Suite
- ✅ **Maximum Qualifying Loan**: Calculate max loan based on income and debt
- ✅ **Minimum Income Required**: Calculate income needed for specific loan
- ✅ **Dual Qualifying Ratios**: Conventional (28:36) and FHA/VA (29:41)
- ✅ **Front-end & Back-end Ratio Analysis**: Housing and total debt ratios

### UI/UX
- ✅ **Responsive Design**: Adapts to mobile, tablet, and desktop
- ✅ **Navigation Rail**: For wide screens (>900px)
- ✅ **Bottom Navigation**: For mobile screens
- ✅ **Material 3 Design**: Modern, clean interface
- ✅ **Dark/Light Mode**: Theme toggle support
- ✅ **Google Fonts Integration**: Oswald, Roboto, Roboto Condensed

---

## Production Optimizations

### Android
- ✅ Code shrinking enabled (R8)
- ✅ Resource shrinking enabled
- ✅ ProGuard rules configured
- ✅ Debug/Release build variants
- ✅ Icon tree-shaking (99.8% reduction)

### Web
- ✅ Loading spinner with branded styling
- ✅ Progressive Web App (PWA) support
- ✅ SEO meta tags configured
- ✅ Manifest.json for installability
- ✅ Responsive viewport meta tag
- ✅ Icon tree-shaking (99.4% reduction)

---

## Build Outputs

### Successfully Built Files

**Android APK** (build/app/outputs/flutter-apk/):
- `app-release.apk` - 46MB
- Optimized with R8 minification
- Ready for sideloading or distribution

**Web Build** (build/web/):
- `index.html` - Entry point (2.8KB)
- `main.dart.js` - Application code (2.4MB)
- `flutter_service_worker.js` - PWA service worker
- `manifest.json` - PWA manifest
- `assets/` - Fonts, images, and resources
- `icons/` - App icons (192x192, 512x512, maskable variants)

---

## Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage

# Watch mode (re-run on changes)
flutter test --watch
```

### Static Analysis
```bash
flutter analyze
```

**Current Status**: ✅ 8 issues (4 unused field warnings, 4 deprecated API infos)

---

## Deployment Checklist

### Before Production Release

#### Android
- [ ] Generate release signing key
- [ ] Configure signing in `android/key.properties`
- [ ] Update `build.gradle.kts` to use release signing config
- [ ] Test on physical Android devices
- [ ] Verify permissions in `AndroidManifest.xml`
- [ ] Update app icon (`android/app/src/main/res/mipmap/`)

#### Web
- [ ] Configure web hosting (Firebase, Netlify, Vercel, etc.)
- [ ] Set up custom domain
- [ ] Enable HTTPS
- [ ] Test on all major browsers
- [ ] Update icons (`web/icons/`)
- [ ] Configure analytics (if needed)

#### General
- [ ] Update README.md with app description
- [ ] Add privacy policy
- [ ] Add terms of service
- [ ] Prepare app store listings (if applicable)
- [ ] Create screenshots for marketing
- [ ] Set up crash reporting (Sentry, Firebase Crashlytics)
- [ ] Implement analytics (if needed)

---

## Known Limitations

### Not Yet Implemented
- ARM (Adjustable-Rate Mortgage) calculations
- APR (Annual Percentage Rate) calculation
- Future Value calculations
- Odd Days Interest calculation
- After-Tax Payment estimation
- Interest rate solving (requires iterative Newton's method)

### Technical Notes
- Android build uses debug signing (replace with production signing for store release)
- Some RadioListTile deprecation warnings (Flutter 3.32+ API changes)
- Unused fields for ARM/APR features (reserved for future implementation)

---

## Architecture Summary

### State Management
- **Provider** package for reactive state management
- **CalculatorProvider**: Core business logic (620+ lines)
- **ThemeProvider**: Dark/light mode management

### Project Structure
```
lib/
├── main.dart                           # App entry point, navigation
├── src/
    ├── providers/
    │   └── calculator_provider.dart    # Core calculation logic
    ├── screens/
    │   ├── calculator_screen.dart      # Main calculator UI
    │   ├── amortization_screen.dart    # Amortization schedule
    │   ├── analysis_screen.dart        # Balloon payment & bi-weekly
    │   └── qualification_screen.dart   # Borrower qualification
    └── widgets/
        └── calculator_button.dart      # Reusable button component
```

### Key Files
- `CLAUDE.md` - Developer guidance for AI assistants
- `blueprint.md` - Original technical specification
- `BUILD_GUIDE.md` - This file
- `pubspec.yaml` - Dependencies and app metadata

---

## Support & Documentation

### Flutter Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Material 3 Design](https://m3.material.io/)
- [Provider Package](https://pub.dev/packages/provider)
- [Google Fonts](https://pub.dev/packages/google_fonts)

### Build Issues
- Check `flutter doctor` for environment issues
- Clear build cache: `flutter clean`
- Reinstall dependencies: `flutter pub get`
- Update Flutter: `flutter upgrade`

---

**Last Updated**: 2025-10-16
**Flutter Version**: 3.9.0+
**Built By**: Claude Code
