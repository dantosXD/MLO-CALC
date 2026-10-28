enum BuydownType {
  twoOne('2-1', [2, 1]),
  oneZero('1-0', [1]),
  threeTwoOne('3-2-1', [3, 2, 1]),
  oneOne('1-1', [1, 1]);

  const BuydownType(this.label, this.steps);

  final String label;

  /// Percentage points below the note rate, one entry per buydown year.
  final List<int> steps;
}

class BuydownYear {
  const BuydownYear({
    required this.year,
    required this.rate,
    required this.payment,
    required this.monthlySubsidy,
  });

  final int year;
  final double rate;
  final double payment;
  final double monthlySubsidy;
}

class BuydownResult {
  const BuydownResult({
    required this.notePayment,
    required this.years,
    required this.totalSubsidy,
  });

  final double notePayment;
  final List<BuydownYear> years;
  final double totalSubsidy;
}
