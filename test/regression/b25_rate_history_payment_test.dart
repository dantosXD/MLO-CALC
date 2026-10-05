import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';

void main() {
  test('interest-rate history entry keeps the payment it was solved from', () {
    final e = CalculationEntry.fromLoanCalculation(
      type: 'interestRate',
      loanAmount: 360000,
      interestRate: 6.5,
      termYears: 30,
      payment: 2275.44,
    );
    expect(e.summary, contains(r'$2,275.44/mo'));
    expect(e.summary, isNot(contains(r'$0.00')));
  });
}
