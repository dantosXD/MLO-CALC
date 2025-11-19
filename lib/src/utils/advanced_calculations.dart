/// Advanced mortgage calculation utilities
///
/// Provides specialized calculations for ARM loans, APR, future value,
/// odd days interest, after-tax payments, and other advanced features.
library;

import 'dart:math';

/// ARM (Adjustable Rate Mortgage) calculation results
class ARMCalculation {
  final List<ARMPeriod> periods;
  final double totalInterest;
  final double totalPaid;

  ARMCalculation({
    required this.periods,
    required this.totalInterest,
    required this.totalPaid,
  });
}

/// Single period in an ARM schedule
class ARMPeriod {
  final int startMonth;
  final int endMonth;
  final double interestRate;
  final double monthlyPayment;
  final double remainingBalance;

  ARMPeriod({
    required this.startMonth,
    required this.endMonth,
    required this.interestRate,
    required this.monthlyPayment,
    required this.remainingBalance,
  });
}

class AdvancedCalculations {
  // Private constructor
  AdvancedCalculations._();
  // Calculation constants
  static const int maxNewtonIterations = 100; // Max iterations for APR solving
  static const double convergenceTolerance = 0.0001; // Convergence threshold


  /// Calculate ARM (Adjustable Rate Mortgage) schedule
  ///
  /// Parameters:
  /// - loanAmount: Initial loan principal
  /// - initialRate: Starting interest rate (percentage)
  /// - initialTermYears: Total loan term in years
  /// - rateChangePercent: How much rate changes each adjustment period (can be negative)
  /// - adjustmentPeriodYears: How often the rate adjusts (e.g., 1 for annual)
  /// - lifetimeCap: Maximum interest rate allowed (null for no cap)
  ///
  /// Returns ARMCalculation with period-by-period breakdown
  static ARMCalculation calculateARM({
    required double loanAmount,
    required double initialRate,
    required double initialTermYears,
    required double rateChangePercent,
    required double adjustmentPeriodYears,
    double? lifetimeCap,
  }) {
    final List<ARMPeriod> periods = [];
    double currentBalance = loanAmount;
    double currentRate = initialRate;
    double totalInterest = 0;
    double totalPaid = 0;

    final int totalMonths = (initialTermYears * 12).round();
    final int adjustmentMonths = (adjustmentPeriodYears * 12).round();
    int currentMonth = 0;

    while (currentMonth < totalMonths && currentBalance > 0) {
      // Calculate payment for current period
      final int remainingMonths = totalMonths - currentMonth;
      final double monthlyRate = currentRate / 100 / 12;

      double payment;
      if (monthlyRate <= 0) {
        payment = currentBalance / remainingMonths;
      } else {
        payment = currentBalance *
            (monthlyRate * pow(1 + monthlyRate, remainingMonths)) /
            (pow(1 + monthlyRate, remainingMonths) - 1);
      }

      // Determine how many months this rate applies
      final int periodEndMonth = min(currentMonth + adjustmentMonths, totalMonths);
      final int monthsInPeriod = periodEndMonth - currentMonth;

      // Amortize for this period
      for (int i = 0; i < monthsInPeriod && currentBalance > 0; i++) {
        final double interestPaid = currentBalance * monthlyRate;
        final double principalPaid = payment - interestPaid;

        currentBalance -= principalPaid;
        totalInterest += interestPaid;
        totalPaid += payment;
      }

      periods.add(ARMPeriod(
        startMonth: currentMonth + 1,
        endMonth: periodEndMonth,
        interestRate: currentRate,
        monthlyPayment: payment,
        remainingBalance: currentBalance > 0 ? currentBalance : 0,
      ));

      currentMonth = periodEndMonth;

      // Adjust rate for next period
      currentRate += rateChangePercent;

      // Apply lifetime cap if specified
      if (lifetimeCap != null && currentRate > lifetimeCap) {
        currentRate = lifetimeCap;
      }

      // Prevent negative rates
      if (currentRate < 0) currentRate = 0;
    }

    return ARMCalculation(
      periods: periods,
      totalInterest: totalInterest,
      totalPaid: totalPaid,
    );
  }

  /// Calculate APR (Annual Percentage Rate)
  ///
  /// Includes loan fees and points in the effective interest rate calculation
  ///
  /// Parameters:
  /// - loanAmount: Loan principal
  /// - interestRate: Nominal interest rate (percentage)
  /// - termYears: Loan term in years
  /// - loanFees: Upfront fees and closing costs
  /// - points: Discount points (1 point = 1% of loan amount)
  ///
  /// Returns APR as a percentage
  static double calculateAPR({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    required double loanFees,
    required double points,
  }) {
    // Calculate monthly payment on full loan amount
    final double monthlyRate = interestRate / 100 / 12;
    final int numPayments = (termYears * 12).round();

    final double monthlyPayment = loanAmount *
        (monthlyRate * pow(1 + monthlyRate, numPayments)) /
        (pow(1 + monthlyRate, numPayments) - 1);

    // Calculate total fees
    final double pointsAmount = loanAmount * (points / 100);
    final double totalFees = loanFees + pointsAmount;

    // Net amount received = loan amount - fees
    final double netLoanAmount = loanAmount - totalFees;

    // Use Newton's method to solve for APR
    // We need to find the rate where netLoanAmount equals the PV of all payments

    double apr = interestRate; // Start with nominal rate
    const double tolerance = convergenceTolerance;
    const int maxIterations = maxNewtonIterations;

    for (int i = 0; i < maxIterations; i++) {
      final double testRate = apr / 100 / 12;

      // Present value of payments at test rate
      final double pv = monthlyPayment *
          (1 - pow(1 + testRate, -numPayments)) / testRate;

      // Difference from net loan amount
      final double difference = pv - netLoanAmount;

      if (difference.abs() < tolerance) break;

      // Derivative for Newton's method
      final double pvPrime = monthlyPayment *
          (numPayments * pow(1 + testRate, -numPayments - 1) / testRate -
              (1 - pow(1 + testRate, -numPayments)) / (testRate * testRate));

      apr -= (difference / pvPrime) * 100 * 12;

      // Bounds check
      if (apr < 0) apr = 0.1;
      if (apr > 100) apr = 50;
    }

    return apr;
  }

  /// Calculate future value of property
  ///
  /// Parameters:
  /// - currentValue: Current property value
  /// - appreciationRate: Annual appreciation rate (percentage)
  /// - years: Number of years to project
  ///
  /// Returns projected future value
  static double calculateFutureValue({
    required double currentValue,
    required double appreciationRate,
    required double years,
  }) {
    final double rate = appreciationRate / 100;
    return currentValue * pow(1 + rate, years);
  }

  /// Calculate equity after specified period
  ///
  /// Parameters:
  /// - initialValue: Initial property value
  /// - loanAmount: Initial loan amount
  /// - appreciationRate: Annual appreciation rate (percentage)
  /// - interestRate: Loan interest rate (percentage)
  /// - years: Number of years
  ///
  /// Returns projected equity (value - remaining balance)
  static double calculateFutureEquity({
    required double initialValue,
    required double loanAmount,
    required double appreciationRate,
    required double interestRate,
    required double termYears,
    required double years,
  }) {
    // Calculate future property value
    final double futureValue = calculateFutureValue(
      currentValue: initialValue,
      appreciationRate: appreciationRate,
      years: years,
    );

    // Calculate remaining loan balance
    final double monthlyRate = interestRate / 100 / 12;
    final int totalMonths = (termYears * 12).round();

    final double monthlyPayment = loanAmount *
        (monthlyRate * pow(1 + monthlyRate, totalMonths)) /
        (pow(1 + monthlyRate, totalMonths) - 1);

    double balance = loanAmount;
    final int monthsElapsed = (years * 12).round();

    for (int i = 0; i < monthsElapsed && i < totalMonths; i++) {
      final double interest = balance * monthlyRate;
      final double principal = monthlyPayment - interest;
      balance -= principal;
    }

    final double remainingBalance = balance > 0 ? balance : 0;

    return futureValue - remainingBalance;
  }

  /// Calculate odd days interest
  ///
  /// This is the prepaid interest from closing date to first payment
  ///
  /// Parameters:
  /// - loanAmount: Loan principal
  /// - interestRate: Annual interest rate (percentage)
  /// - daysUntilFirstPayment: Days between closing and first payment
  ///
  /// Returns prepaid interest amount
  static double calculateOddDaysInterest({
    required double loanAmount,
    required double interestRate,
    required int daysUntilFirstPayment,
  }) {
    final double dailyRate = (interestRate / 100) / 365;
    return loanAmount * dailyRate * daysUntilFirstPayment;
  }

  /// Calculate after-tax monthly payment
  ///
  /// Estimates effective payment after mortgage interest tax deduction
  ///
  /// Parameters:
  /// - monthlyPayment: Gross monthly P&I payment
  /// - interestRate: Annual interest rate (percentage)
  /// - loanBalance: Current loan balance
  /// - taxBracket: Marginal tax rate (percentage, e.g., 24 for 24%)
  ///
  /// Returns estimated after-tax monthly payment
  static double calculateAfterTaxPayment({
    required double monthlyPayment,
    required double interestRate,
    required double loanBalance,
    required double taxBracket,
  }) {
    // Calculate interest portion of payment
    final double monthlyRate = interestRate / 100 / 12;
    final double interestPortion = loanBalance * monthlyRate;

    // Tax savings from deducting interest
    final double taxSavings = interestPortion * (taxBracket / 100);

    // Effective payment after tax benefit
    return monthlyPayment - taxSavings;
  }

  /// Calculate break-even point for buying points
  ///
  /// Parameters:
  /// - loanAmount: Loan principal
  /// - originalRate: Interest rate without points (percentage)
  /// - discountedRate: Interest rate with points (percentage)
  /// - termYears: Loan term in years
  /// - pointsCost: Cost of purchasing points
  ///
  /// Returns number of months to break even
  static double calculatePointsBreakEven({
    required double loanAmount,
    required double originalRate,
    required double discountedRate,
    required double termYears,
    required double pointsCost,
  }) {
    final int numPayments = (termYears * 12).round();

    // Calculate payment at original rate
    final double origMonthlyRate = originalRate / 100 / 12;
    final double originalPayment = loanAmount *
        (origMonthlyRate * pow(1 + origMonthlyRate, numPayments)) /
        (pow(1 + origMonthlyRate, numPayments) - 1);

    // Calculate payment at discounted rate
    final double discMonthlyRate = discountedRate / 100 / 12;
    final double discountedPayment = loanAmount *
        (discMonthlyRate * pow(1 + discMonthlyRate, numPayments)) /
        (pow(1 + discMonthlyRate, numPayments) - 1);

    // Monthly savings
    final double monthlySavings = originalPayment - discountedPayment;

    if (monthlySavings <= 0) return double.infinity;

    // Months to recover points cost
    return pointsCost / monthlySavings;
  }

  /// Calculate refinance break-even analysis
  ///
  /// Returns months to break even on refinancing costs
  static double calculateRefinanceBreakEven({
    required double currentBalance,
    required double currentRate,
    required double currentRemainingTermYears,
    required double newRate,
    required double newTermYears,
    required double refinanceCosts,
  }) {
    // Current payment
    final int currentMonths = (currentRemainingTermYears * 12).round();
    final double currentMonthlyRate = currentRate / 100 / 12;
    final double currentPayment = currentBalance *
        (currentMonthlyRate * pow(1 + currentMonthlyRate, currentMonths)) /
        (pow(1 + currentMonthlyRate, currentMonths) - 1);

    // New payment
    final int newMonths = (newTermYears * 12).round();
    final double newMonthlyRate = newRate / 100 / 12;
    final double newPayment = currentBalance *
        (newMonthlyRate * pow(1 + newMonthlyRate, newMonths)) /
        (pow(1 + newMonthlyRate, newMonths) - 1);

    // Monthly savings
    final double monthlySavings = currentPayment - newPayment;

    if (monthlySavings <= 0) return double.infinity;

    return refinanceCosts / monthlySavings;
  }
}

/// Standard mortgage calculation utilities
///
/// Provides core Time Value of Money (TVM) calculations for
/// Payment, Loan Amount, Interest Rate, and Term.
class LoanMath {
  // Private constructor
  LoanMath._();

  /// Calculate Monthly Payment (P&I)
  ///
  /// Formula: M = P * [ r(1+r)^n ] / [ (1+r)^n - 1 ]
  static double calculatePayment({
    required double loanAmount,
    required double interestRate, // Annual percentage (e.g. 5.5)
    required double termYears,
  }) {
    if (loanAmount <= 0 || interestRate <= 0 || termYears <= 0) {
      return 0;
    }

    final double r = interestRate / 100 / 12;
    final double n = termYears * 12;

    return loanAmount * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  /// Calculate Loan Amount (Principal)
  ///
  /// Formula: P = M * [ (1+r)^n - 1 ] / [ r(1+r)^n ]
  static double calculateLoanAmount({
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
  static double calculateTerm({
    required double loanAmount,
    required double payment,
    required double interestRate,
  }) {
    if (loanAmount <= 0 || payment <= 0 || interestRate <= 0) {
      return 0;
    }

    final double r = interestRate / 100 / 12;

    // Check if payment covers interest
    if (loanAmount * r >= payment) {
      return 0; // Payment too small, never pays off
    }

    final double nMonths = -log(1 - (loanAmount * r) / payment) / log(1 + r);
    return nMonths / 12;
  }

  /// Calculate Interest Rate
  ///
  /// Solves for rate using Newton-Raphson method.
  static double calculateInterestRate({
    required double loanAmount,
    required double payment,
    required double termYears,
  }) {
    if (loanAmount <= 0 || payment <= 0 || termYears <= 0) {
      return 0;
    }

    final double n = termYears * 12;

    // Initial guess strategy:
    // Total paid = M * n
    // Total interest = (M * n) - P
    // Approx avg balance = P / 2
    // Approx rate ~= (Total Interest / n_years) / (P / 2)
    final double totalInterest = (payment * n) - loanAmount;
    if (totalInterest <= 0) return 0;

    double rate = (totalInterest / termYears) / (loanAmount * 0.5) * 100;
    
    // Clamp initial guess
    if (rate < 0.1) rate = 0.1;
    if (rate > 20) rate = 10;

    const double tolerance = 0.000001;
    const int maxIterations = 50;

    for (int i = 0; i < maxIterations; i++) {
      final double r = rate / 100 / 12;
      
      if (r <= -1) {
        rate = 0.1;
        continue;
      }

      final double factor = pow(1 + r, n).toDouble();
      
      // f(r) derived from payment formula rearrangement
      final double fVal = loanAmount * r * factor - payment * (factor - 1);
      final double dfVal = loanAmount * (factor + r * n * factor / (1 + r)) - payment * n * factor / (1 + r);
      
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
