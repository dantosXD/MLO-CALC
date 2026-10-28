import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/second_lien/domain/services/second_lien_calculator.dart';

void main() {
  const calc = SecondLienCalculator();
  final math = LoanMath();

  test('piggyback 80-10-10 on 500000', () {
    final r = calc.piggyback(
      price: 500000,
      firstLtv: 80,
      secondLtv: 10,
      firstRate: 6.5,
      secondRate: 9,
      termYears: 30,
      secondTermYears: 15,
      singleLoanMiAnnualPercent: 0.5,
    );
    expect(r.firstLoan, 400000);
    expect(r.secondLoan, 50000);
    expect(r.combinedPayment, closeTo(r.firstPayment + r.secondPayment, 0.001));
    final single =
        math.calculatePayment(
          loanAmount: 450000,
          interestRate: 6.5,
          termYears: 30,
        ) +
        450000 * 0.5 / 1200;
    expect(r.singleLoanPaymentWithMi, closeTo(single, 0.001));
    expect(r.monthlyDifference, closeTo(single - r.combinedPayment, 0.001));
  });

  test('heloc max line, cltv, payments', () {
    final r = calc.heloc(
      homeValue: 600000,
      firstBalance: 350000,
      maxCltv: 85,
      drawAmount: 100000,
      rate: 8,
      repayYears: 20,
    );
    expect(r.maxLine, 160000);
    expect(r.cltv, closeTo(75, 0.01));
    expect(
      r.interestOnlyPayment,
      math.calculateInterestOnlyPayment(loanAmount: 100000, interestRate: 8),
    );
    expect(
      r.fullyAmortizingPayment,
      math.calculatePayment(loanAmount: 100000, interestRate: 8, termYears: 20),
    );
  });

  test('heloc maxLine clamps to zero', () {
    final r = calc.heloc(
      homeValue: 600000,
      firstBalance: 550000,
      maxCltv: 85,
      drawAmount: 0,
      rate: 8,
      repayYears: 20,
    );
    expect(r.maxLine, 0);
  });
}
