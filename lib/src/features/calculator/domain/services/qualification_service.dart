import 'dart:math';

import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

import '../models/calculation_result.dart';
import '../models/qualification_result.dart';

class QualificationService {
  const QualificationService(this._loanMath);

  final LoanMath _loanMath;

  CalcResult<QualificationResult> calculateMaxLoan({
    required QualifyingRatio ratio,
    required double annualIncome,
    required double interestRate,
    required double termYears,
    double monthlyDebt = 0,
    double monthlyEscrows = 0,
  }) {
    if (annualIncome <= 0 || interestRate <= 0 || termYears <= 0) {
      return CalcResult.failure('Incomplete rate/term/income data');
    }

    if (ratio.housingRatio <= 0 && ratio.debtRatio <= 0) {
      return CalcResult.failure('Qualifying ratio has no usable limits');
    }

    final double monthlyIncome = annualIncome / 12;
    final double maxPitiHousing = monthlyIncome * (ratio.housingRatio / 100);
    final double maxTotalDebt = monthlyIncome * (ratio.debtRatio / 100);
    final double maxPitiDebt = maxTotalDebt - monthlyDebt;

    // A ratio value of 0 means "no constraint" (e.g. VA has no front-end
    // housing ratio). Only apply a bound for the ratios that are actually set,
    // otherwise a 0 would be treated as an impossible 0% cap.
    final double maxPiti;
    if (ratio.housingRatio <= 0) {
      maxPiti = maxPitiDebt;
    } else if (ratio.debtRatio <= 0) {
      maxPiti = maxPitiHousing;
    } else {
      maxPiti = min(maxPitiHousing, maxPitiDebt);
    }
    final double maxPi = maxPiti - monthlyEscrows;

    if (maxPi <= 0) {
      return CalcResult.failure('Insufficient income for housing');
    }

    final double loanAmount = _loanMath.calculateLoanAmount(
      payment: maxPi,
      interestRate: interestRate,
      termYears: termYears,
    );

    if (loanAmount <= 0) {
      return CalcResult.failure('Unable to qualify with given data');
    }

    return CalcResult.success(
      QualificationResult(loanAmount: loanAmount, monthlyPiPayment: maxPi),
    );
  }

  CalcResult<double> calculateMinimumIncome({
    required QualifyingRatio ratio,
    required double pitiPayment,
    double monthlyDebt = 0,
  }) {
    if (pitiPayment <= 0) {
      return CalcResult.failure('No payment to evaluate');
    }

    if (ratio.housingRatio <= 0 && ratio.debtRatio <= 0) {
      return CalcResult.failure('Qualifying ratio has no usable limits');
    }

    // A ratio value of 0 means "no constraint" for that side (e.g. VA has no
    // front-end housing ratio). Skip it instead of dividing by zero, which
    // previously produced an Infinity minimum income.
    final double minIncomeFront = ratio.housingRatio > 0
        ? (pitiPayment / (ratio.housingRatio / 100)) * 12
        : 0;
    final double totalDebt = pitiPayment + monthlyDebt;
    final double minIncomeBack = ratio.debtRatio > 0
        ? (totalDebt / (ratio.debtRatio / 100)) * 12
        : 0;

    return CalcResult.success(max(minIncomeFront, minIncomeBack));
  }
}
