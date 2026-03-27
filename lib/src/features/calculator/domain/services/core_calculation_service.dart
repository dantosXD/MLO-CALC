import 'dart:math' as math;

import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/utils/decimal_utils.dart';

import '../models/calculation_result.dart';

class CoreCalculationService {
  CoreCalculationService(this._loanMath);

  final LoanMath _loanMath;

  static const double _minTolerance = 1e-6;
  static const int _maxIterations = 75;

  CalcResult<double> calculatePayment({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    bool interestOnly = false,
  }) {
    final double payment = _loanMath.calculatePayment(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
      interestOnly: interestOnly,
    );

    if (payment <= 0 || payment.isNaN || payment.isInfinite) {
      return CalcResult.failure('Unable to calculate payment');
    }

    // Round payment to cents for display
    return CalcResult.success(DecimalUtils.roundToCents(payment));
  }
  
  CalcResult<double> calculateInterestOnlyPayment({
    required double loanAmount,
    required double interestRate,
  }) {
    final double payment = _loanMath.calculateInterestOnlyPayment(
      loanAmount: loanAmount,
      interestRate: interestRate,
    );

    if (payment <= 0 || payment.isNaN || payment.isInfinite) {
      return CalcResult.failure('Unable to calculate interest-only payment');
    }

    // Round payment to cents for display
    return CalcResult.success(DecimalUtils.roundToCents(payment));
  }

  CalcResult<double> calculateLoanAmount({
    required double payment,
    required double interestRate,
    required double termYears,
  }) {
    final double loanAmount = _loanMath.calculateLoanAmount(
      payment: payment,
      interestRate: interestRate,
      termYears: termYears,
    );

    if (loanAmount <= 0 || loanAmount.isNaN || loanAmount.isInfinite) {
      return CalcResult.failure('Unable to calculate loan amount');
    }

    // Round loan amount to cents
    return CalcResult.success(DecimalUtils.roundToCents(loanAmount));
  }

  CalcResult<double> calculateTerm({
    required double loanAmount,
    required double payment,
    required double interestRate,
  }) {
    final double termYears = _loanMath.calculateTerm(
      loanAmount: loanAmount,
      payment: payment,
      interestRate: interestRate,
    );

    if (termYears <= 0 || termYears.isNaN) {
      return CalcResult.failure('Payment too low for loan');
    }

    return CalcResult.success(termYears);
  }

  CalcResult<double> solveInterestRate({
    required double loanAmount,
    required double payment,
    required double termYears,
  }) {
    final double totalMonths = termYears * 12;
    if (loanAmount <= 0 || payment <= 0 || termYears <= 0) {
      return CalcResult.failure('Provide positive loan, payment, and term');
    }

    final double zeroInterestPayment = loanAmount / totalMonths;
    if (payment <= zeroInterestPayment + _minTolerance) {
      return CalcResult.failure('Payment too low for loan');
    }

    // Use heuristic for starting guess
    final double totalInterest = (payment * totalMonths) - loanAmount;
    double rateGuess = math.max(
      0.25,
      (totalInterest / termYears) / (loanAmount * 0.5) * 100,
    );
    rateGuess = rateGuess.clamp(0.25, 25);

    double currentRate = rateGuess;
    bool converged = false;
    double bestRate = currentRate;
    double bestError = double.infinity;

    for (int i = 0; i < _maxIterations; i++) {
      final double r = currentRate / 100 / 12;

      // Guard against invalid rate values
      if (r <= -1 || r.isNaN || r.isInfinite) {
        currentRate = rateGuess; // Reset to initial guess
        continue;
      }

      final double factor = math.pow(1 + r, totalMonths).toDouble();

      // Guard against overflow
      if (factor.isInfinite || factor.isNaN) {
        currentRate = currentRate / 2; // Reduce rate and try again
        continue;
      }

      final double fVal =
          loanAmount * r * factor - payment * (factor - 1);
      final double dfVal = loanAmount *
              (factor + (r * totalMonths * factor) / (1 + r)) -
          payment * totalMonths * factor / (1 + r);

      // Track best result so far (for fallback)
      final double error = fVal.abs();
      if (error < bestError) {
        bestError = error;
        bestRate = currentRate;
      }

      if (dfVal.abs() < _minTolerance) break;

      final double delta = (fVal / dfVal) * 12 * 100;

      // Guard against extreme deltas
      if (delta.isNaN || delta.isInfinite || delta.abs() > 50) {
        // Try bisection as fallback
        currentRate = (currentRate + bestRate) / 2;
        continue;
      }

      final double nextRate = currentRate - delta;

      if ((nextRate - currentRate).abs() < _minTolerance) {
        currentRate = nextRate;
        converged = true;
        break;
      }

      currentRate = nextRate;
      if (currentRate < 0.01) currentRate = 0.01;
      if (currentRate > 40) currentRate = 40;
    }

    // If not formally converged but we have a reasonable approximation, use it
    if (!converged && bestError < 1.0) {
      currentRate = bestRate;
      converged = true;
    }

    if (!converged) {
      return CalcResult.failure(
        'Unable to converge on interest rate',
        converged: false,
      );
    }

    // Round interest rate to reasonable precision (3 decimal places for rates like 5.125%)
    return CalcResult.success(DecimalUtils.roundToDecimal(currentRate, 3));
  }
}
