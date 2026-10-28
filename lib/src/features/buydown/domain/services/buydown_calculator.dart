import 'package:loan_ranger/src/core/math/loan_math.dart';

import '../models/buydown.dart';

class BuydownCalculator {
  const BuydownCalculator();

  /// Throws [ArgumentError] when the first-year step is not below [noteRate].
  BuydownResult calculate({
    required double loanAmount,
    required double noteRate,
    required double termYears,
    required BuydownType type,
  }) {
    if (noteRate - type.steps.first <= 0) {
      throw ArgumentError('Buydown exceeds note rate');
    }
    final math = LoanMath();
    double pay(double rate) => math.calculatePayment(
      loanAmount: loanAmount,
      interestRate: rate,
      termYears: termYears,
    );
    final note = pay(noteRate);
    final years = <BuydownYear>[];
    for (var i = 0; i < type.steps.length; i++) {
      final rate = noteRate - type.steps[i];
      final p = pay(rate);
      years.add(
        BuydownYear(
          year: i + 1,
          rate: rate,
          payment: p,
          monthlySubsidy: note - p,
        ),
      );
    }
    return BuydownResult(
      notePayment: note,
      years: years,
      totalSubsidy: years.fold(0.0, (s, y) => s + y.monthlySubsidy * 12),
    );
  }
}
