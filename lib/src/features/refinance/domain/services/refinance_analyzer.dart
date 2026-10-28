import 'package:loan_ranger/src/core/math/loan_math.dart';

import '../models/refinance.dart';

class RefinanceAnalyzer {
  const RefinanceAnalyzer();

  RefinanceResult analyze(RefinanceInputs i) {
    final math = LoanMath();
    final newLoan = i.currentBalance + i.cashOut;
    final currentPayment = math.calculatePayment(
      loanAmount: i.currentBalance,
      interestRate: i.currentRate,
      termYears: i.currentRemainingYears,
    );
    final newPayment = math.calculatePayment(
      loanAmount: newLoan,
      interestRate: i.newRate,
      termYears: i.newTermYears,
    );
    final savings = currentPayment - newPayment;
    final breakEven = savings > 0 ? i.closingCosts / savings : null;
    final lifetime =
        (newPayment * (i.newTermYears * 12).round() - newLoan) -
        (currentPayment * (i.currentRemainingYears * 12).round() -
            i.currentBalance);

    bool? met;
    String? reason;
    switch (i.program) {
      case RefiProgram.conventional:
        break;
      case RefiProgram.vaIrrrl:
        met = breakEven != null && breakEven <= 36 + 1e-9;
        reason = met
            ? 'Costs recouped within 36 months'
            : 'Costs not recouped within 36 months';
      case RefiProgram.fhaStreamline:
        // New MIP rate assumed equal to the current one (controller ruling R1).
        final cut = i.currentRate - i.newRate;
        met = cut >= 0.5 - 1e-9;
        reason = met
            ? 'Combined rate + MIP drops ${cut.toStringAsFixed(2)} pts (needs 0.50)'
            : 'Combined rate + MIP drops only ${cut.toStringAsFixed(2)} pts (needs 0.50)';
    }
    return RefinanceResult(
      currentPayment: currentPayment,
      newPayment: newPayment,
      monthlySavings: savings,
      breakEvenMonths: breakEven,
      lifetimeInterestChange: lifetime,
      ntbMet: met,
      ntbReason: reason,
    );
  }
}
