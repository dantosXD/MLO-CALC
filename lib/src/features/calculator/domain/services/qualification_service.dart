import 'dart:math';

import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

import '../models/calculation_result.dart';
import '../models/qualification_result.dart';

class QualificationService {
  const QualificationService(this._loanMath);

  final LoanMath _loanMath;

  CalculationResult<QualificationResult> calculateMaxLoan({
    required QualifyingRatio ratio,
    required double annualIncome,
    required double interestRate,
    required double termYears,
    double monthlyDebt = 0,
    double monthlyEscrows = 0,
  }) {
    if (annualIncome <= 0 || interestRate <= 0 || termYears <= 0) {
      return CalculationResult.failure('Incomplete rate/term/income data');
    }

    final double monthlyIncome = annualIncome / 12;
    final double maxPitiHousing = monthlyIncome * (ratio.housingRatio / 100);
    final double maxTotalDebt = monthlyIncome * (ratio.debtRatio / 100);
    final double maxPitiDebt = maxTotalDebt - monthlyDebt;

    final double maxPiti = min(maxPitiHousing, maxPitiDebt);
    final double maxPi = maxPiti - monthlyEscrows;

    if (maxPi <= 0) {
      return CalculationResult.failure('Insufficient income for housing');
    }

    final double loanAmount = _loanMath.calculateLoanAmount(
      payment: maxPi,
      interestRate: interestRate,
      termYears: termYears,
    );

    if (loanAmount <= 0) {
      return CalculationResult.failure('Unable to qualify with given data');
    }

    return CalculationResult.success(
      QualificationResult(
        loanAmount: loanAmount,
        monthlyPiPayment: maxPi,
      ),
    );
  }

  CalculationResult<double> calculateMinimumIncome({
    required QualifyingRatio ratio,
    required double pitiPayment,
    double monthlyDebt = 0,
  }) {
    if (pitiPayment <= 0) {
      return CalculationResult.failure('No payment to evaluate');
    }

    final double minIncomeFront =
        (pitiPayment / (ratio.housingRatio / 100)) * 12;
    final double totalDebt = pitiPayment + monthlyDebt;
    final double minIncomeBack = (totalDebt / (ratio.debtRatio / 100)) * 12;

    return CalculationResult.success(max(minIncomeFront, minIncomeBack));
  }
}
