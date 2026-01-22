class CalculatorStateSnapshot {
  final double? loanAmount;
  final double? interestRate;
  final double? termYears;
  final double? payment;
  final double? price;
  final double? downPayment;
  final double? propertyTax;
  final double? homeInsurance;
  final double? mortgageInsurance;
  final double? monthlyExpenses;
  final double? annualIncome;
  final double? monthlyDebt;
  final String? historyJson;

  const CalculatorStateSnapshot({
    this.loanAmount,
    this.interestRate,
    this.termYears,
    this.payment,
    this.price,
    this.downPayment,
    this.propertyTax,
    this.homeInsurance,
    this.mortgageInsurance,
    this.monthlyExpenses,
    this.annualIncome,
    this.monthlyDebt,
    this.historyJson,
  });

  Map<String, double> toDoubleMap() {
    return {
      if (loanAmount != null) 'loanAmount': loanAmount!,
      if (interestRate != null) 'interestRate': interestRate!,
      if (termYears != null) 'termYears': termYears!,
      if (payment != null) 'payment': payment!,
      if (price != null) 'price': price!,
      if (downPayment != null) 'downPayment': downPayment!,
      if (propertyTax != null) 'propertyTax': propertyTax!,
      if (homeInsurance != null) 'homeInsurance': homeInsurance!,
      if (mortgageInsurance != null) 'mortgageInsurance': mortgageInsurance!,
      if (monthlyExpenses != null) 'monthlyExpenses': monthlyExpenses!,
      if (annualIncome != null) 'annualIncome': annualIncome!,
      if (monthlyDebt != null) 'monthlyDebt': monthlyDebt!,
    };
  }
}
