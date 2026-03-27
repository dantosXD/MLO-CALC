sealed class CalcResult<T> {
  const CalcResult();

  T? get value;
  String? get error;
  bool get converged;
  bool get isSuccess => this is CalcSuccess<T>;

  factory CalcResult.success(T value, {bool converged = true}) {
    return CalcSuccess<T>(value, converged: converged);
  }

  factory CalcResult.failure(
    String message, {
    bool converged = false,
  }) {
    return CalcFailure<T>(message, converged: converged);
  }
}

final class CalcSuccess<T> extends CalcResult<T> {
  const CalcSuccess(this._value, {this.converged = true});

  final T _value;

  @override
  T get value => _value;

  @override
  String? get error => null;

  @override
  final bool converged;
}

final class CalcFailure<T> extends CalcResult<T> {
  const CalcFailure(this._error, {this.converged = false});

  final String _error;

  @override
  T? get value => null;

  @override
  String get error => _error;

  @override
  final bool converged;
}

typedef CalculationResult<T> = CalcResult<T>;
