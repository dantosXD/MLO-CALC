import 'dart:math';

import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/utils/decimal_utils.dart';

import '../models/arm_scenario.dart';

class ArmCalculatorService {
  ArmCalculatorService(this._loanMath);

  final LoanMath _loanMath;

  ArmScheduleResult calculateSchedule(ArmScenario scenario) {
    final int totalMonths = max(1, (scenario.termYears * 12).round());
    final int fixedMonths = max(1, (scenario.initialFixedYears * 12).round());
    final int adjustmentMonths =
        max(1, (scenario.adjustmentFrequencyYears * 12).round());

    double balance = scenario.loanAmount;
    double currentRate = scenario.initialRate;

    int startMonth = 1;
    int monthsRemaining = totalMonths;
    bool firstPeriod = true;

    final List<ArmPeriodSummary> periods = [];
    double totalInterest = 0;
    double totalPaid = 0;

    while (monthsRemaining > 0 && !DecimalUtils.isEffectivelyZero(balance)) {
      final int periodLength = min(
        firstPeriod ? fixedMonths : adjustmentMonths,
        monthsRemaining,
      );

      final double monthlyPayment = DecimalUtils.roundToCents(_resolvePayment(
        balance: balance,
        rate: currentRate,
        remainingMonths: monthsRemaining,
      ));

      double periodInterest = 0;
      double periodPrincipal = 0;

      for (int i = 0; i < periodLength; i++) {
        final double monthlyRate = currentRate / 100 / 12;
        final double interestPaid = DecimalUtils.roundToCents(balance * monthlyRate);
        double principalPaid = monthlyPayment - interestPaid;

        if (principalPaid <= 0) {
          principalPaid = 0;
        }

        if (i == periodLength - 1 && monthsRemaining == periodLength) {
          principalPaid = balance;
        }

        if (principalPaid > balance) {
          principalPaid = balance;
        }

        balance = DecimalUtils.ensureNonNegative(balance - principalPaid);
        periodInterest += interestPaid;
        periodPrincipal += principalPaid;
        totalInterest += interestPaid;
        totalPaid += principalPaid + interestPaid;
        monthsRemaining--;

        if (monthsRemaining == 0 || DecimalUtils.isEffectivelyZero(balance)) {
          break;
        }
      }

      periods.add(
        ArmPeriodSummary(
          startMonth: startMonth,
          endMonth: startMonth + periodLength - 1,
          rate: DecimalUtils.roundToDecimal(currentRate, 3),
          monthlyPayment: monthlyPayment,
          principalPaid: DecimalUtils.roundToCents(periodPrincipal),
          interestPaid: DecimalUtils.roundToCents(periodInterest),
          endingBalance: DecimalUtils.isEffectivelyZero(balance) ? 0 : DecimalUtils.roundToCents(balance),
        ),
      );

      if (monthsRemaining <= 0 || DecimalUtils.isEffectivelyZero(balance)) {
        break;
      }

      startMonth += periodLength;
      firstPeriod = false;
      currentRate = _nextRate(
        currentRate,
        scenario.rateChangePerAdjustment,
        scenario.periodicCap,
        scenario.lifetimeCap,
        scenario.lifetimeFloor,
      );
    }

    return ArmScheduleResult(
      periods: periods,
      totalInterest: DecimalUtils.roundToCents(totalInterest),
      totalPaid: DecimalUtils.roundToCents(totalPaid),
    );
  }

  double _resolvePayment({
    required double balance,
    required double rate,
    required int remainingMonths,
  }) {
    if (remainingMonths <= 0) return balance;
    if (rate <= 0) {
      return balance / remainingMonths;
    }

    return _loanMath.calculatePayment(
      loanAmount: balance,
      interestRate: rate,
      termYears: remainingMonths / 12,
    );
  }

  double _nextRate(
    double current,
    double adjustment,
    double periodicCap,
    double lifetimeCap,
    double lifetimeFloor,
  ) {
    double delta = adjustment;

    if (periodicCap > 0 && delta.abs() > periodicCap) {
      delta = delta.isNegative ? -periodicCap : periodicCap;
    }

    double nextRate = current + delta;

    if (lifetimeCap > 0 && nextRate > lifetimeCap) {
      nextRate = lifetimeCap;
    }

    if (nextRate < lifetimeFloor) {
      nextRate = lifetimeFloor;
    }

    if (nextRate < 0) {
      nextRate = 0;
    }

    return nextRate;
  }
}
