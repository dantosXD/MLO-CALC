/// Standard mortgage calculation utilities.
///
/// Provides core Time Value of Money (TVM) calculations for payment,
/// principal, interest rate, and term solving.
library;
import 'dart:math';

class LoanMath {
  const LoanMath();

  /// Calculate Monthly Payment (P&I)
  ///
  /// Formula: M = P * [ r(1+r)^n ] / [ (1+r)^n - 1 ]
  double calculatePayment({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    bool interestOnly = false,
  }) {
    if (loanAmount <= 0 || interestRate <= 0 || termYears <= 0) {
      return 0;
    }

    final double r = interestRate / 100 / 12;
    
    // Interest-only payment: just the monthly interest
    if (interestOnly) {
      return loanAmount * r;
    }

    final double n = termYears * 12;

    return loanAmount * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }
  
  /// Calculate Interest-Only Payment
  ///
  /// Formula: I = P * r
  double calculateInterestOnlyPayment({
    required double loanAmount,
    required double interestRate,
  }) {
    if (loanAmount <= 0 || interestRate <= 0) {
      return 0;
    }

    final double r = interestRate / 100 / 12;
    return loanAmount * r;
  }

  /// Calculate Loan Amount (Principal)
  ///
  /// Formula: P = M * [ (1+r)^n - 1 ] / [ r(1+r)^n ]
  double calculateLoanAmount({
    required double payment,
    required double interestRate,
    required double termYears,
  }) {
    if (payment <= 0 || interestRate <= 0 || termYears <= 0) {
      return 0;
    }

    final double r = interestRate / 100 / 12;
    final double n = termYears * 12;

    return payment * (pow(1 + r, n) - 1) / (r * pow(1 + r, n));
  }

  /// Calculate Loan Term in Years
  ///
  /// Formula: n = -log(1 - (P*r)/M) / log(1+r)
  double calculateTerm({
    required double loanAmount,
    required double payment,
    required double interestRate,
  }) {
    if (loanAmount <= 0 || payment <= 0 || interestRate <= 0) {
      return 0;
    }

    final double r = interestRate / 100 / 12;

    if (loanAmount * r >= payment) {
      return 0; // Payment too small, never pays off
    }

    final double nMonths = -log(1 - (loanAmount * r) / payment) / log(1 + r);
    return nMonths / 12;
  }

  /// Calculate Interest Rate by applying a Newton-Raphson solver.
  double calculateInterestRate({
    required double loanAmount,
    required double payment,
    required double termYears,
    double initialGuess = 5.0,
    int maxIterations = 50,
    double tolerance = 1e-6,
  }) {
    if (loanAmount <= 0 || payment <= 0 || termYears <= 0) {
      return 0;
    }

    final double n = termYears * 12;
    double rate = initialGuess;

    for (int i = 0; i < maxIterations; i++) {
      final double r = rate / 100 / 12;
      if (r <= -1) {
        rate = 0.1;
        continue;
      }

      final double factor = pow(1 + r, n).toDouble();

      final double fVal = loanAmount * r * factor - payment * (factor - 1);
      final double dfVal = loanAmount *
              (factor + ((r * n * factor) / (1 + r))) -
          payment * n * factor / (1 + r);

      if (dfVal.abs() < 1e-9) break;

      final double rateChangeMonthly = fVal / dfVal;
      final double rateChangeAnnual = rateChangeMonthly * 12 * 100;

      final double newRate = rate - rateChangeAnnual;

      if ((newRate - rate).abs() < tolerance) {
        return newRate;
      }

      rate = newRate;
      if (rate < 0) rate = 0.01;
    }

    return rate;
  }
}
