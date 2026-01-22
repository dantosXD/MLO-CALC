import 'package:flutter/foundation.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/core/utils/decimal_utils.dart';

import '../models/biweekly_conversion.dart';

class AmortizationService {
  const AmortizationService(this._loanMath);

  final LoanMath _loanMath;

  Future<List<AmortizationEntry>> buildSchedule({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    double? payment,
  }) async {
    final double computedPayment = _resolvePayment(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
      paymentOverride: payment,
    );

    if (computedPayment <= 0) {
      return const [];
    }

    final params = _AmortizationParams(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
      payment: computedPayment,
    );

    return compute(_generateSchedule, params);
  }

  double remainingBalance({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    required double yearsElapsed,
    double? payment,
  }) {
    if (loanAmount <= 0 || termYears <= 0) return 0;

    final double computedPayment = _resolvePayment(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
      paymentOverride: payment,
    );

    if (computedPayment <= 0) return 0;

    final double monthlyRate = interestRate / 100 / 12;
    final int totalMonths = (yearsElapsed * 12).round();
    double balance = loanAmount;

    for (int month = 0; month < totalMonths && balance > 0; month++) {
      final double interestPaid = DecimalUtils.roundToCents(balance * monthlyRate);
      double principalPaid = computedPayment - interestPaid;

      // Prevent overpayment
      if (principalPaid > balance) {
        principalPaid = balance;
      }

      balance = DecimalUtils.ensureNonNegative(balance - principalPaid);
    }

    return DecimalUtils.roundToCents(balance);
  }

  BiWeeklyConversion calculateBiWeekly({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    double? payment,
  }) {
    if (loanAmount <= 0 || termYears <= 0) {
      return const BiWeeklyConversion(
        biWeeklyPayment: 0,
        newTermYears: 0,
        totalInterest: 0,
        interestSaved: 0,
      );
    }

    final double monthlyPayment = _resolvePayment(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
      paymentOverride: payment,
    );
    if (monthlyPayment <= 0) {
      return const BiWeeklyConversion(
        biWeeklyPayment: 0,
        newTermYears: 0,
        totalInterest: 0,
        interestSaved: 0,
      );
    }

    // Round bi-weekly payment to cents for accuracy
    final double biWeeklyPayment = DecimalUtils.roundToCents(monthlyPayment / 2);
    final double biWeeklyRate = interestRate / 100 / 26;

    double balance = loanAmount;
    double totalInterest = 0;
    int periods = 0;

    while (balance > 0 && periods < 2000) {
      final double interestPaid = DecimalUtils.roundToCents(balance * biWeeklyRate);
      double principalPaid = biWeeklyPayment - interestPaid;
      if (principalPaid <= 0) {
        break;
      }
      // On final payment, pay off exact remaining balance
      if (principalPaid > balance) {
        principalPaid = balance;
      }
      balance = DecimalUtils.ensureNonNegative(balance - principalPaid);
      totalInterest += interestPaid;
      periods++;
    }

    final double newTermYears = periods / 26;

    final int originalMonths = (termYears * 12).round();
    final double originalInterest =
        (monthlyPayment * originalMonths) - loanAmount;
    final double interestSaved = originalInterest - totalInterest;

    return BiWeeklyConversion(
      biWeeklyPayment: biWeeklyPayment,
      newTermYears: newTermYears,
      totalInterest: totalInterest,
      interestSaved: interestSaved,
    );
  }
  double _resolvePayment({
    required double loanAmount,
    required double interestRate,
    required double termYears,
    double? paymentOverride,
  }) {
    if (paymentOverride != null) {
      return paymentOverride;
    }

    if (interestRate <= 0) {
      final int months = (termYears * 12).round();
      if (months == 0) return 0;
      return loanAmount / months;
    }

    return _loanMath.calculatePayment(
      loanAmount: loanAmount,
      interestRate: interestRate,
      termYears: termYears,
    );
  }
}

class _AmortizationParams {
  const _AmortizationParams({
    required this.loanAmount,
    required this.interestRate,
    required this.termYears,
    required this.payment,
  });

  final double loanAmount;
  final double interestRate;
  final double termYears;
  final double payment;
}

List<AmortizationEntry> _generateSchedule(_AmortizationParams params) {
  final double monthlyRate = params.interestRate / 100 / 12;
  final int totalMonths = (params.termYears * 12).round();
  final List<AmortizationEntry> entries = [];

  double balance = params.loanAmount;
  final double payment = DecimalUtils.roundToCents(params.payment);

  for (int month = 1; month <= totalMonths; month++) {
    // Round interest to cents at each step for accuracy
    final double interestPaid = DecimalUtils.roundToCents(balance * monthlyRate);
    double principalPaid = payment - interestPaid;

    // On final month or if principal exceeds balance, pay off remaining balance
    if (month == totalMonths || principalPaid >= balance) {
      principalPaid = balance;
    }

    double newBalance = DecimalUtils.ensureNonNegative(balance - principalPaid);

    // Use proper zero threshold - if less than half a cent, it's effectively zero
    if (DecimalUtils.isEffectivelyZero(newBalance)) {
      newBalance = 0;
    }

    // Round all output values to cents
    entries.add(
      AmortizationEntry(
        month: month,
        payment: DecimalUtils.roundToCents(principalPaid + interestPaid),
        principal: DecimalUtils.roundToCents(principalPaid),
        interest: interestPaid,
        balance: DecimalUtils.roundToCents(newBalance),
      ),
    );

    balance = newBalance;

    // If loan is paid off early, stop generating entries
    if (balance == 0) {
      break;
    }
  }

  return entries;
}
