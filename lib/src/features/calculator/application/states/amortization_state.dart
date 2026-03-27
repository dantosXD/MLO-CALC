import 'package:loan_ranger/src/core/models/amortization_entry.dart';

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
    List<AmortizationEntry>? amortizationData,
    bool? isComputing,
    String? activeFingerprint,
    bool clearActiveFingerprint = false,
  }) {
    return AmortizationState(
      amortizationData: amortizationData == null
          ? List<AmortizationEntry>.unmodifiable(this.amortizationData)
          : List<AmortizationEntry>.unmodifiable(amortizationData),
      isComputing: isComputing ?? this.isComputing,
      activeFingerprint: clearActiveFingerprint
          ? null
          : (activeFingerprint ?? this.activeFingerprint),
    );
  }
}
