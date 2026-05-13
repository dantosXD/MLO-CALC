/// Comprehensive Rent vs Buy analysis model
///
/// This model captures all inputs and outputs for a rent vs buy comparison,
/// with full transparency into how each value is calculated.
class RentVsBuyCalculation {
  // INPUTS
  final RentVsBuyInputs inputs;

  // CALCULATED RESULTS
  final MonthlyBuyingCosts buyingCosts;
  final MonthlyRentingCosts rentingCosts;
  final double monthlySavings; // Positive = buying saves money
  final int breakEvenMonths;
  final List<YearlyProjection> projections;
  final CalculationBreakdown breakdown;

  const RentVsBuyCalculation({
    required this.inputs,
    required this.buyingCosts,
    required this.rentingCosts,
    required this.monthlySavings,
    required this.breakEvenMonths,
    required this.projections,
    required this.breakdown,
  });

  bool get buyingIsBetter => monthlySavings > 0;
}

class RentVsBuyInputs {
  // Purchase Details
  final double homePrice;
  final double downPaymentPercent;
  final double interestRate;
  final double termYears;

  // Buying Costs
  final double propertyTaxRate; // Annual rate as percentage of home value
  final double homeInsuranceAnnual;
  final double hoaMonthly;
  final double maintenancePercent; // Annual as percentage of home value
  final double closingCostsPercent;
  final double pmiRate; // Annual PMI rate if LTV > 80%

  // Renting Costs
  final double monthlyRent;
  final double annualRentIncrease; // Percentage
  final double rentersInsuranceMonthly;

  // Economic Assumptions
  final double homeAppreciationRate; // Annual percentage
  final double investmentReturnRate; // What renter earns on saved down payment
  final double
  marginalTaxRate; // For mortgage interest deduction (if itemizing)
  final int analysisYears;

  const RentVsBuyInputs({
    required this.homePrice,
    required this.downPaymentPercent,
    required this.interestRate,
    required this.termYears,
    required this.propertyTaxRate,
    required this.homeInsuranceAnnual,
    required this.hoaMonthly,
    required this.maintenancePercent,
    required this.closingCostsPercent,
    required this.pmiRate,
    required this.monthlyRent,
    required this.annualRentIncrease,
    required this.rentersInsuranceMonthly,
    required this.homeAppreciationRate,
    required this.investmentReturnRate,
    required this.marginalTaxRate,
    required this.analysisYears,
  });

  double get downPaymentAmount => homePrice * (downPaymentPercent / 100);
  double get loanAmount => homePrice - downPaymentAmount;
  double get ltv => (loanAmount / homePrice) * 100;
  double get closingCostsAmount => homePrice * (closingCostsPercent / 100);
  double get totalUpfrontCost => downPaymentAmount + closingCostsAmount;
}

class MonthlyBuyingCosts {
  final double principalAndInterest;
  final double propertyTax;
  final double homeInsurance;
  final double pmi;
  final double hoa;
  final double maintenance;
  final double taxBenefit; // Negative (reduces cost)

  const MonthlyBuyingCosts({
    required this.principalAndInterest,
    required this.propertyTax,
    required this.homeInsurance,
    required this.pmi,
    required this.hoa,
    required this.maintenance,
    required this.taxBenefit,
  });

  double get total =>
      principalAndInterest +
      propertyTax +
      homeInsurance +
      pmi +
      hoa +
      maintenance -
      taxBenefit;

  double get totalPiti =>
      principalAndInterest + propertyTax + homeInsurance + pmi;
}

class MonthlyRentingCosts {
  final double rent;
  final double rentersInsurance;
  final double opportunityCost; // Lost investment return on down payment

  const MonthlyRentingCosts({
    required this.rent,
    required this.rentersInsurance,
    required this.opportunityCost,
  });

  double get total => rent + rentersInsurance;
  double get totalWithOpportunity => total + opportunityCost;
}

class YearlyProjection {
  final int year;
  final double homeValue;
  final double remainingLoanBalance;
  final double equity;
  final double totalBuyingCostToDate;
  final double totalRentingCostToDate;
  final double rentAtYear;
  final double investmentValueIfRenting;
  final double netWorthBuying;
  final double netWorthRenting;

  const YearlyProjection({
    required this.year,
    required this.homeValue,
    required this.remainingLoanBalance,
    required this.equity,
    required this.totalBuyingCostToDate,
    required this.totalRentingCostToDate,
    required this.rentAtYear,
    required this.investmentValueIfRenting,
    required this.netWorthBuying,
    required this.netWorthRenting,
  });

  double get netWorthDifference => netWorthBuying - netWorthRenting;
  bool get buyingAhead => netWorthDifference > 0;
}

/// Detailed breakdown of how each value was calculated
/// This provides transparency for users who want to verify
class CalculationBreakdown {
  final List<CalculationStep> steps;

  const CalculationBreakdown({required this.steps});
}

class CalculationStep {
  final String name;
  final String formula;
  final Map<String, dynamic> inputs;
  final double result;
  final String explanation;

  const CalculationStep({
    required this.name,
    required this.formula,
    required this.inputs,
    required this.result,
    required this.explanation,
  });
}
