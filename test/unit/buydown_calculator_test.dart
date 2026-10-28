import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/buydown/domain/models/buydown.dart';
import 'package:loan_ranger/src/features/buydown/domain/services/buydown_calculator.dart';

void main() {
  const calc = BuydownCalculator();
  final math = LoanMath();

  test('2-1 on 400000 @ 7% over 30y', () {
    final r = calc.calculate(
      loanAmount: 400000,
      noteRate: 7,
      termYears: 30,
      type: BuydownType.twoOne,
    );
    final p7 = math.calculatePayment(
      loanAmount: 400000,
      interestRate: 7,
      termYears: 30,
    );
    final p5 = math.calculatePayment(
      loanAmount: 400000,
      interestRate: 5,
      termYears: 30,
    );
    final p6 = math.calculatePayment(
      loanAmount: 400000,
      interestRate: 6,
      termYears: 30,
    );
    expect(r.years[0].rate, 5);
    expect(r.years[1].rate, 6);
    expect(r.notePayment, closeTo(p7, 0.001));
    expect(r.totalSubsidy, closeTo(12 * (p7 - p5) + 12 * (p7 - p6), 0.01));
    expect(r.totalSubsidy, closeTo(9323, 1));
  });

  test('year counts per type', () {
    BuydownResult run(BuydownType t) =>
        calc.calculate(loanAmount: 300000, noteRate: 7, termYears: 30, type: t);
    expect(run(BuydownType.oneZero).years, hasLength(1));
    expect(run(BuydownType.oneOne).years, hasLength(2));
    expect(run(BuydownType.threeTwoOne).years, hasLength(3));
  });

  test('throws when buydown depth reaches note rate', () {
    expect(
      () => calc.calculate(
        loanAmount: 300000,
        noteRate: 2.5,
        termYears: 30,
        type: BuydownType.threeTwoOne,
      ),
      throwsArgumentError,
    );
  });
}
