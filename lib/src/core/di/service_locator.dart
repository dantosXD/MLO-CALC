/// Service Locator for Dependency Injection
///
/// This module manages all service dependencies using GetIt.
/// Services are lazily loaded to optimize startup time.
///
/// ## Adding a New Calculator Tool
///
/// To add a new calculator or tool to the app:
///
/// 1. **Create the feature structure:**
///    ```
///    lib/src/features/your_feature/
///    ├── domain/
///    │   ├── models/
///    │   │   └── your_model.dart
///    │   └── services/
///    │       └── your_calculator_service.dart
///    ├── application/
///    │   └── providers/
///    │       └── your_provider.dart  (if state management needed)
///    └── presentation/
///        ├── screens/
///        │   └── your_screen.dart
///        └── widgets/
///            └── your_widgets.dart
///    ```
///
/// 2. **Create your service:**
///    ```dart
///    class YourCalculatorService {
///      YourCalculatorService(this._loanMath);
///      final LoanMath _loanMath;
///
///      // Add your calculation methods
///    }
///    ```
///
/// 3. **Register in this file:**
///    ```dart
///    ..registerLazySingleton<YourCalculatorService>(
///      () => YourCalculatorService(serviceLocator<LoanMath>()),
///    )
///    ```
///
/// 4. **Access in your code:**
///    ```dart
///    final service = serviceLocator<YourCalculatorService>();
///    ```
///
/// ## Existing Services
///
/// - [LoanMath]: Core mathematical formulas (payment, principal, rate, term)
/// - [CoreCalculationService]: Validated wrapper around LoanMath
/// - [AmortizationService]: Amortization schedule generation
/// - [QualificationService]: Borrower qualification calculations
/// - [ArmCalculatorService]: Adjustable Rate Mortgage calculations
/// - [NLPCalculatorService]: Natural language processing for voice input
///
library;

import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/arm/domain/services/arm_calculator_service.dart';
import '../../features/arm/domain/services/arm_preset_service.dart';
import '../../features/calculator/domain/services/amortization_service.dart';
import '../../features/calculator/domain/services/core_calculation_service.dart';
import '../../features/calculator/domain/services/persistence_service.dart';
import '../../features/calculator/domain/services/qualification_service.dart';
import '../../features/nlp/domain/services/nlp_cache_service.dart';
import '../../features/nlp/domain/services/nlp_calculator_service.dart';
import '../../features/updater/domain/services/update_service.dart';
import '../math/loan_math.dart';
import '../navigation/app_router.dart';
import '../persistence/preference_store.dart';
import '../persistence/secure_store.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';

/// Global service locator instance
///
/// Use this to access registered services throughout the app:
/// ```dart
/// final calculationService = serviceLocator<CoreCalculationService>();
/// ```
final GetIt serviceLocator = GetIt.instance;

/// Configure all dependency injections
///
/// Call this at app startup (usually in main.dart):
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await configureDependencies();
///   runApp(MyApp());
/// }
/// ```
Future<void> configureDependencies() async {
  // Prevent double registration
  if (serviceLocator.isRegistered<LoanMath>()) {
    return;
  }

  String appVersion;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
  } catch (_) {
    appVersion = '0.0.0';
  }

  // Core mathematical engine (stateless, can be const)
  const loanMath = LoanMath();

  serviceLocator
    // === Core Services ===
    ..registerSingleton<LoanMath>(loanMath)
    ..registerSingleton<PreferenceStore>(PreferenceStore())
    ..registerSingleton<SecureStore>(FlutterSecureStoreBackend())
    ..registerSingleton<ConnectivityService>(ConnectivityService())
    ..registerLazySingleton<AnalyticsService>(
      () =>
          AnalyticsService(preferenceStore: serviceLocator<PreferenceStore>()),
    )
    // === Calculator Services ===
    ..registerLazySingleton<CoreCalculationService>(
      () => CoreCalculationService(serviceLocator<LoanMath>()),
    )
    ..registerLazySingleton<AmortizationService>(
      () => AmortizationService(serviceLocator<LoanMath>()),
    )
    ..registerLazySingleton<QualificationService>(
      () => QualificationService(serviceLocator<LoanMath>()),
    )
    ..registerLazySingleton<ArmCalculatorService>(
      () => ArmCalculatorService(serviceLocator<LoanMath>()),
    )
    // === Persistence Services ===
    ..registerLazySingleton<CalculatorPersistenceService>(
      () => CalculatorPersistenceService(
        secureStore: serviceLocator<SecureStore>(),
        legacyStore: serviceLocator<PreferenceStore>(),
      ),
    )
    ..registerLazySingleton<ArmPresetStorage>(
      () => ArmPresetStorage(secureStore: serviceLocator<SecureStore>()),
    )
    ..registerLazySingleton<NlpCacheService>(
      () => NlpCacheService(
        secureStore: serviceLocator<SecureStore>(),
        preferenceStore: serviceLocator<PreferenceStore>(),
      ),
    )
    ..registerSingleton<AppRouter>(
      AppRouter(
        armCalculatorService: serviceLocator<ArmCalculatorService>(),
        armPresetStorage: serviceLocator<ArmPresetStorage>(),
      ),
    )
    // === AI/NLP Services ===
    ..registerLazySingleton<NLPCalculatorService>(NLPCalculatorService.new)
    ..registerLazySingleton<UpdateService>(
      () => UpdateService(currentVersion: appVersion),
    );

  // === ADD NEW SERVICES BELOW THIS LINE ===
  // Example:
  // ..registerLazySingleton<YourNewService>(
  //   () => YourNewService(serviceLocator<LoanMath>()),
  // )
}
