/// Base interface for calculator services
///
/// All calculator services should implement this interface to ensure
/// consistent architecture and enable easy extension of the app.
///
/// ## How to add a new calculator tool:
///
/// 1. Create a new feature folder: `lib/src/features/your_feature/`
/// 2. Create the service in `domain/services/your_calculator_service.dart`
/// 3. Implement [CalculatorServiceBase] (optional but recommended)
/// 4. Register in `service_locator.dart`:
///    ```dart
///    ..registerLazySingleton<YourCalculatorService>(
///      () => YourCalculatorService(serviceLocator<LoanMath>()),
///    )
///    ```
/// 5. Create a provider in `application/providers/` if state management needed
/// 6. Create UI in `presentation/screens/` or `presentation/widgets/`
///
/// ## Example implementation:
///
/// ```dart
/// class NewCalculatorService implements CalculatorServiceBase {
///   NewCalculatorService(this._loanMath);
///   final LoanMath _loanMath;
///
///   @override
///   String get serviceName => 'New Calculator';
///
///   @override
///   String get serviceDescription => 'Calculates something new';
///
///   // Add your calculation methods...
/// }
/// ```
library;

/// Base interface that all calculator services can optionally implement.
///
/// This provides a consistent pattern for service identification and
/// makes it easier to discover and document available calculators.
abstract class CalculatorServiceBase {
  /// Human-readable name of this calculator service
  String get serviceName;

  /// Brief description of what this calculator does
  String get serviceDescription;
}

/// Result wrapper for calculations that may fail
///
/// Use this pattern for any calculation that could return an error:
/// ```dart
/// CalculationResult<double> calculateSomething(...) {
///   if (invalid) {
///     return CalculationResult.failure('Error message');
///   }
///   return CalculationResult.success(result);
/// }
/// ```
class CalculationResultBase<T> {
  final T? value;
  final String? error;
  final bool isSuccess;
  final bool converged;

  const CalculationResultBase._({
    this.value,
    this.error,
    required this.isSuccess,
    this.converged = true,
  });

  factory CalculationResultBase.success(T value) => CalculationResultBase._(
        value: value,
        isSuccess: true,
      );

  factory CalculationResultBase.failure(String error, {bool converged = true}) =>
      CalculationResultBase._(
        error: error,
        isSuccess: false,
        converged: converged,
      );
}
