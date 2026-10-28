class ScheduleCYear {
  const ScheduleCYear({
    required this.netProfit,
    this.depreciation = 0,
    this.depletion = 0,
    this.businessUseOfHome = 0,
    this.amortization = 0,
    this.nonrecurring = 0,
  });

  final double netProfit;
  final double depreciation;
  final double depletion;
  final double businessUseOfHome;
  final double amortization;

  /// Nonrecurring income included in net profit; subtracted.
  final double nonrecurring;

  double get adjusted =>
      netProfit +
      depreciation +
      depletion +
      businessUseOfHome +
      amortization -
      nonrecurring;
}

enum StudentLoanAgency {
  fannie('Fannie Mae'),
  freddie('Freddie Mac'),
  fha('FHA'),
  va('VA'),
  usda('USDA');

  const StudentLoanAgency(this.label);
  final String label;
}
