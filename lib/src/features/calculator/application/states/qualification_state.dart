import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

const Object _qualificationUnset = Object();

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
    Object? qualRatio1 = _qualificationUnset,
    Object? qualRatio2 = _qualificationUnset,
    Object? annualIncome = _qualificationUnset,
    Object? monthlyDebt = _qualificationUnset,
    Object? calculationError = _qualificationUnset,
  }) {
    return QualificationState(
      qualRatio1: identical(qualRatio1, _qualificationUnset)
          ? this.qualRatio1
          : qualRatio1 as QualifyingRatio,
      qualRatio2: identical(qualRatio2, _qualificationUnset)
          ? this.qualRatio2
          : qualRatio2 as QualifyingRatio,
      annualIncome: identical(annualIncome, _qualificationUnset)
          ? this.annualIncome
          : annualIncome as double?,
      monthlyDebt: identical(monthlyDebt, _qualificationUnset)
          ? this.monthlyDebt
          : monthlyDebt as double?,
      calculationError: identical(calculationError, _qualificationUnset)
          ? this.calculationError
          : calculationError as String?,
    );
  }
}
