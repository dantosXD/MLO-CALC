enum RefiProgram {
  conventional('Conventional'),
  fhaStreamline('FHA Streamline'),
  vaIrrrl('VA IRRRL');

  const RefiProgram(this.label);

  final String label;
}

class RefinanceInputs {
  const RefinanceInputs({
    required this.currentBalance,
    required this.currentRate,
    required this.currentRemainingYears,
    required this.currentAnnualMiRate,
    required this.newRate,
    required this.newTermYears,
    required this.closingCosts,
    required this.cashOut,
    required this.program,
  });

  final double currentBalance;
  final double currentRate;
  final double currentRemainingYears;
  final double currentAnnualMiRate;
  final double newRate;
  final double newTermYears;
  final double closingCosts;
  final double cashOut;
  final RefiProgram program;
}

class RefinanceResult {
  const RefinanceResult({
    required this.currentPayment,
    required this.newPayment,
    required this.monthlySavings,
    required this.breakEvenMonths,
    required this.lifetimeInterestChange,
    required this.ntbMet,
    required this.ntbReason,
  });

  final double currentPayment;
  final double newPayment;
  final double monthlySavings;
  final double? breakEvenMonths;

  /// Negative means the member pays less total interest.
  final double lifetimeInterestChange;
  final bool? ntbMet;
  final String? ntbReason;
}
