import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

class QualificationState {
  QualificationState({
    QualifyingRatio? qualRatio1,
    QualifyingRatio? qualRatio2,
    this.annualIncome,
    this.monthlyDebt,
    this.calculationError,
  }) : qualRatio1 = qualRatio1 ?? DefaultQualifyingRatios.ratios[0],
       qualRatio2 = qualRatio2 ?? DefaultQualifyingRatios.ratios[1];

  final QualifyingRatio qualRatio1;
  final QualifyingRatio qualRatio2;
  final double? annualIncome;
  final double? monthlyDebt;
  final String? calculationError;

  QualificationState copyWith({
    QualifyingRatio? qualRatio1,
    QualifyingRatio? qualRatio2,
    double? annualIncome,
    bool clearAnnualIncome = false,
    double? monthlyDebt,
    bool clearMonthlyDebt = false,
    String? calculationError,
    bool clearCalculationError = false,
  }) {
    return QualificationState(
      qualRatio1: qualRatio1 ?? this.qualRatio1,
      qualRatio2: qualRatio2 ?? this.qualRatio2,
      annualIncome: clearAnnualIncome
          ? null
          : (annualIncome ?? this.annualIncome),
      monthlyDebt: clearMonthlyDebt ? null : (monthlyDebt ?? this.monthlyDebt),
      calculationError: clearCalculationError
          ? null
          : (calculationError ?? this.calculationError),
    );
  }
}
