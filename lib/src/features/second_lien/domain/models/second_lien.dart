class PiggybackResult {
  const PiggybackResult({
    required this.firstLoan,
    required this.secondLoan,
    required this.firstPayment,
    required this.secondPayment,
    required this.combinedPayment,
    required this.singleLoanPaymentWithMi,
    required this.monthlyDifference,
  });

  final double firstLoan;
  final double secondLoan;
  final double firstPayment;
  final double secondPayment;
  final double combinedPayment;
  final double singleLoanPaymentWithMi;

  /// Positive when the piggyback is cheaper per month than one loan with MI.
  final double monthlyDifference;
}

class HelocResult {
  const HelocResult({
    required this.maxLine,
    required this.cltv,
    required this.interestOnlyPayment,
    required this.fullyAmortizingPayment,
  });

  final double maxLine;
  final double cltv;
  final double interestOnlyPayment;
  final double fullyAmortizingPayment;
}
