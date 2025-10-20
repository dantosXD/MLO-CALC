# Loan Ranger - Mortgage Calculator

A professional Flutter application for mortgage and real estate financial calculations.

![App Status](https://img.shields.io/badge/status-ready--to--build-green)
![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web-lightgrey)

## 🎯 Features

### Core Calculator Functions
- **Loan Amount Calculation**: Calculate loan amount from payment, rate, and term
- **Interest Rate Calculation**: Find the interest rate using Newton's method
- **Term Calculation**: Determine loan term from amount, rate, and payment
- **Payment Calculation**: Monthly P&I payment calculation
- **PITI Analysis**: Includes Property Tax, Insurance, and other expenses
- **Arithmetic Operations**: Standard calculator functions (+, -, ×, ÷)

### Advanced Features
- **Price & Down Payment**: Auto-calculate loan amount from purchase price
- **Amortization Schedules**: Month-by-month payment breakdown
- **Qualification Tools**: Borrower qualification analysis
- **State Persistence**: Saves calculations between sessions
- **Professional UI**: Dark theme matching physical calculators

## 📱 Screenshots

The app design is inspired by professional-grade calculators like the Calculated Industries Qualifier Plus IIx, featuring:
- Large, easy-to-read display
- Organized button layout
- Real-time calculation status
- Professional color scheme

## 🚀 Quick Start

### For Users (No Development Experience)

1. **Download Flutter**: https://docs.flutter.dev/get-started/install/windows
2. **Double-click**: `build-android.bat` (for Android) or `build-web.bat` (for Web)
3. **Wait for build to complete**
4. **Install/Deploy** the generated app

### For Developers

```bash
# Clone or navigate to project
cd C:\Users\207ds\Desktop\Apps\MLO-CALC

# Get dependencies
flutter pub get

# Run in development mode
flutter run

# Or use the provided script
run-dev.bat
```

## 📚 Documentation

- **[MCP_SETUP_INSTRUCTIONS.md](MCP_SETUP_INSTRUCTIONS.md)**: Setup Dart MCP Server for Claude Code
- **[DEBUG_REPORT.md](DEBUG_REPORT.md)**: Comprehensive code analysis and debugging info
- **[BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md)**: Complete build and deployment guide
- **[CLAUDE.md](CLAUDE.md)**: Project architecture and development guidelines

## 🛠️ Build Scripts

### Windows Batch Scripts
- **`build-android.bat`**: Build Android APK (release)
- **`build-web.bat`**: Build web version (release)
- **`run-dev.bat`**: Run in development mode (interactive)

Simply double-click any script to start the build process!

## 🏗️ Architecture

### State Management
- **Provider Pattern**: Efficient state management
- **CalculatorProvider**: Core calculation logic
- **ThemeProvider**: Light/dark theme support

### Project Structure
```
lib/
├── main.dart                           # App entry point
├── src/
│   ├── providers/
│   │   └── calculator_provider.dart    # Business logic
│   ├── screens/
│   │   ├── calculator_screen.dart      # Main calculator UI
│   │   ├── amortization_screen.dart    # Schedule view
│   │   ├── analysis_screen.dart        # Analysis tools
│   │   └── qualification_screen.dart   # Qualification tools
│   ├── widgets/
│   │   ├── animated_display.dart       # Display widget
│   │   └── calculator_button.dart      # Button widget
│   └── utils/
│       └── formatters.dart             # Number formatting
```

## 🧮 Financial Formulas

### Monthly Payment (M)
```
M = P * [r(1+r)^n] / [(1+r)^n - 1]
```
Where:
- P = Loan Amount
- r = Monthly Interest Rate (annual/100/12)
- n = Total Payments (years × 12)

### PITI Calculation
```
PITI = P&I + (Property Tax / 12) + (Insurance / 12) + (PMI / 12) + Monthly Expenses
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/calculator_provider_test.dart

# Run with coverage
flutter test --coverage
```

## 📋 System Requirements

### Development
- **Flutter SDK**: 3.0.0 or later
- **Dart SDK**: 3.9.0 or later
- **Android Studio**: For Android builds
- **Chrome/Edge**: For web builds

### Deployment
- **Android**: Android 5.0 (API 21) or higher
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)

## 🔧 Configuration

### Dart MCP Server (for AI Development)
The project includes MCP server configuration for enhanced AI-assisted development. See [MCP_SETUP_INSTRUCTIONS.md](MCP_SETUP_INSTRUCTIONS.md) for setup.

## 📦 Dependencies

Core packages:
- `provider`: ^6.1.5+1 - State management
- `google_fonts`: ^6.3.2 - Typography
- `shared_preferences`: ^2.3.4 - Data persistence
- `fl_chart`: ^0.69.2 - Charts and graphs
- `intl`: ^0.19.0 - Number formatting

## 🐛 Debugging

See [DEBUG_REPORT.md](DEBUG_REPORT.md) for:
- Code analysis results
- Common issues and solutions
- Performance optimization tips
- Build troubleshooting

## 🚢 Deployment

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

See [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md) for detailed deployment instructions.

## 📈 Roadmap

- [x] Phase 1: Core calculator with arithmetic operations
- [x] Phase 2: Financial calculations (L/A, Rate, Term, Payment)
- [x] Phase 2a: PITI calculations
- [ ] Phase 3: Amortization schedules and analysis
- [ ] Phase 4: Qualification suite
- [ ] Phase 5: ARM calculations and advanced features

## 🤝 Contributing

This is a personal project, but suggestions and bug reports are welcome!

## 📄 License

Copyright © 2025. All rights reserved.

## 🙋 Support

For issues or questions:
1. Check [DEBUG_REPORT.md](DEBUG_REPORT.md) for common issues
2. Review [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md) for build problems
3. Consult Flutter documentation: https://docs.flutter.dev

## 🎉 Acknowledgments

- Design inspired by Calculated Industries Qualifier Plus IIx
- Built with Flutter framework
- UI matches professional calculator standards

---

## 📝 Quick Reference

### Build Commands
```bash
flutter clean                  # Clean project
flutter pub get               # Get dependencies
flutter run                   # Run in development
flutter build apk --release   # Build Android
flutter build web --release   # Build Web
flutter test                  # Run tests
flutter analyze               # Analyze code
```

### File Locations
- **Android APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Web Build**: `build/web/`
- **Tests**: `test/`

---

**Status**: ✅ Ready to build and deploy!

Last Updated: 2025-10-16
