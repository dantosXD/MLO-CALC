import 'package:loan_ranger/src/core/math/loan_math.dart';

class AffordabilityResult {
  const AffordabilityResult({
    required this.price,
    required this.loanAmount,
    required this.principalAndInterest,
    required this.monthlyTaxInsMi,
  });

  final double price;
  final double loanAmount;
  final double principalAndInterest;
  final double monthlyTaxInsMi;
}

/// Closed-form inverse of PITI: the highest price whose payment fits a target.
class AffordabilitySolver {
  const AffordabilitySolver();

  AffordabilityResult? maxPrice({
    required double targetPiti,
    required double rate,
    required double termYears,
    required double downPaymentPercent,
    required double taxRatePercent,
    required double insuranceRatePercent,
    required double hoaMonthly,
    required double miAnnualPercent,
  }) {
    if (targetPiti <= hoaMonthly || rate <= 0 || termYears <= 0) return null;
    if (downPaymentPercent < 0 || downPaymentPercent >= 100) return null;
    final k = LoanMath().calculatePayment(
      loanAmount: 1,
      interestRate: rate,
      termYears: termYears,
    );
    final ltv = 1 - downPaymentPercent / 100;
    final denom =
        ltv * k +
        (taxRatePercent + insuranceRatePercent) / 1200 +
        ltv * miAnnualPercent / 1200;
    if (!(denom > 0) || !denom.isFinite) return null;
    final price = (targetPiti - hoaMonthly) / denom;
    final loan = price * ltv;
    return AffordabilityResult(
      price: price,
      loanAmount: loan,
      principalAndInterest: loan * k,
      monthlyTaxInsMi:
          price * (taxRatePercent + insuranceRatePercent) / 1200 +
          loan * miAnnualPercent / 1200,
    );
  }
}
