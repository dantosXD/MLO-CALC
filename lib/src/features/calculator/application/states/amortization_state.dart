import 'package:loan_ranger/src/core/models/amortization_entry.dart';

const Object _amortizationUnset = Object();

class AmortizationState {
  const AmortizationState({
    this.amortizationData = const <AmortizationEntry>[],
    this.isComputing = false,
    this.activeFingerprint,
  });

  final List<AmortizationEntry> amortizationData;
  final bool isComputing;
  final String? activeFingerprint;

  AmortizationState copyWith({
    Object? amortizationData = _amortizationUnset,
    Object? isComputing = _amortizationUnset,
    Object? activeFingerprint = _amortizationUnset,
  }) {
    return AmortizationState(
      amortizationData: identical(amortizationData, _amortizationUnset)
          ? List<AmortizationEntry>.unmodifiable(this.amortizationData)
          : List<AmortizationEntry>.unmodifiable(
              amortizationData as List<AmortizationEntry>,
            ),
      isComputing: identical(isComputing, _amortizationUnset)
          ? this.isComputing
          : isComputing as bool,
      activeFingerprint: identical(activeFingerprint, _amortizationUnset)
          ? this.activeFingerprint
          : activeFingerprint as String?,
    );
  }
}
