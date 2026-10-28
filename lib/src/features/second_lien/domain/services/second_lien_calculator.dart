import 'dart:math' as math;

import 'package:loan_ranger/src/core/math/loan_math.dart';

import '../models/second_lien.dart';

class SecondLienCalculator {
  const SecondLienCalculator();

  PiggybackResult piggyback({
    required double price,
    required double firstLtv,
    required double secondLtv,
    required double firstRate,
    required double secondRate,
    required double termYears,
    required double secondTermYears,
    required double singleLoanMiAnnualPercent,
  }) {
    final m = LoanMath();
    final firstLoan = price * firstLtv / 100;
    final secondLoan = price * secondLtv / 100;
    final firstPayment = m.calculatePayment(
      loanAmount: firstLoan,
      interestRate: firstRate,
      termYears: termYears,
    );
    final secondPayment = m.calculatePayment(
      loanAmount: secondLoan,
      interestRate: secondRate,
      termYears: secondTermYears,
    );
    final combined = firstPayment + secondPayment;
    final single = firstLoan + secondLoan;
    final singlePayment =
        m.calculatePayment(
          loanAmount: single,
          interestRate: firstRate,
          termYears: termYears,
        ) +
        single * singleLoanMiAnnualPercent / 1200;
    return PiggybackResult(
      firstLoan: firstLoan,
      secondLoan: secondLoan,
      firstPayment: firstPayment,
      secondPayment: secondPayment,
      combinedPayment: combined,
      singleLoanPaymentWithMi: singlePayment,
      monthlyDifference: singlePayment - combined,
    );
  }

  HelocResult heloc({
    required double homeValue,
    required double firstBalance,
    required double maxCltv,
    required double drawAmount,
    required double rate,
    required double repayYears,
  }) {
    final m = LoanMath();
    return HelocResult(
      maxLine: math.max(0, homeValue * maxCltv / 100 - firstBalance),
      cltv: (firstBalance + drawAmount) / homeValue * 100,
      interestOnlyPayment: m.calculateInterestOnlyPayment(
        loanAmount: drawAmount,
        interestRate: rate,
      ),
      fullyAmortizingPayment: m.calculatePayment(
        loanAmount: drawAmount,
        interestRate: rate,
        termYears: repayYears,
      ),
    );
  }
}
