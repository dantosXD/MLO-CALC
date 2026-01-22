class CalculationResult<T> {
  final T? value;
  final String? error;
  final bool converged;

  const CalculationResult({
    this.value,
    this.error,
    this.converged = true,
  });

  factory CalculationResult.success(T value, {bool converged = true}) {
    return CalculationResult<T>(value: value, converged: converged);
  }

  factory CalculationResult.failure(
    String message, {
    bool converged = false,
  }) {
    return CalculationResult<T>(error: message, converged: converged);
  }

  bool get isSuccess => value != null && error == null;
}
