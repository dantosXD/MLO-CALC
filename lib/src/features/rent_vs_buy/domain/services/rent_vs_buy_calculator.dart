import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/core/utils/decimal_utils.dart';
import '../models/rent_vs_buy_calculation.dart';

/// Calculator service for Rent vs Buy analysis
/// 
/// All calculations are performed with full transparency -
/// each step is documented with formula, inputs, and explanation.
class RentVsBuyCalculator {
  const RentVsBuyCalculator();

  static const LoanMath _loanMath = LoanMath();

  RentVsBuyCalculation calculate(RentVsBuyInputs inputs) {
    final steps = <CalculationStep>[];
    
    // Step 1: Calculate Monthly P&I Payment
    final monthlyPi = _calculateMonthlyPayment(
      principal: inputs.loanAmount,
      annualRate: inputs.interestRate,
      years: inputs.termYears,
    );
    steps.add(CalculationStep(
      name: 'Monthly P&I Payment',
      formula: 'P × [r(1+r)^n] / [(1+r)^n - 1]',
      inputs: {
        'P (Loan Amount)': inputs.loanAmount,
        'r (Monthly Rate)': inputs.interestRate / 100 / 12,
        'n (Payments)': inputs.termYears * 12,
      },
      result: monthlyPi,
      explanation: 'Standard amortization formula calculates the fixed monthly '
          'principal and interest payment over the loan term.',
    ));

    // Step 2: Calculate Monthly Property Tax
    final monthlyPropertyTax = DecimalUtils.roundToCents(
      (inputs.homePrice * inputs.propertyTaxRate / 100) / 12,
    );
    steps.add(CalculationStep(
      name: 'Monthly Property Tax',
      formula: '(Home Price × Tax Rate) / 12',
      inputs: {
        'Home Price': inputs.homePrice,
        'Tax Rate (%)': inputs.propertyTaxRate,
      },
      result: monthlyPropertyTax,
      explanation: 'Annual property tax divided by 12 months.',
    ));

    // Step 3: Calculate Monthly Home Insurance
    final monthlyHomeInsurance = DecimalUtils.roundToCents(
      inputs.homeInsuranceAnnual / 12,
    );
    steps.add(CalculationStep(
      name: 'Monthly Home Insurance',
      formula: 'Annual Insurance / 12',
      inputs: {
        'Annual Insurance': inputs.homeInsuranceAnnual,
      },
      result: monthlyHomeInsurance,
      explanation: 'Annual homeowner\'s insurance premium divided by 12 months.',
    ));

    // Step 4: Calculate Monthly PMI (if applicable)
    double monthlyPmi = 0;
    if (inputs.ltv > 80) {
      monthlyPmi = DecimalUtils.roundToCents(
        (inputs.loanAmount * inputs.pmiRate / 100) / 12,
      );
      steps.add(CalculationStep(
        name: 'Monthly PMI',
        formula: '(Loan Amount × PMI Rate) / 12',
        inputs: {
          'Loan Amount': inputs.loanAmount,
          'PMI Rate (%)': inputs.pmiRate,
          'LTV': inputs.ltv,
        },
        result: monthlyPmi,
        explanation: 'PMI is required when LTV > 80%. Calculated as annual rate '
            'applied to loan amount, divided by 12.',
      ));
    }

    // Step 5: Calculate Monthly Maintenance
    final monthlyMaintenance = DecimalUtils.roundToCents(
      (inputs.homePrice * inputs.maintenancePercent / 100) / 12,
    );
    steps.add(CalculationStep(
      name: 'Monthly Maintenance',
      formula: '(Home Price × Maintenance Rate) / 12',
      inputs: {
        'Home Price': inputs.homePrice,
        'Maintenance Rate (%)': inputs.maintenancePercent,
      },
      result: monthlyMaintenance,
      explanation: 'Industry standard is 1-2% of home value annually for '
          'repairs and maintenance.',
    ));

    // Step 6: Calculate Tax Benefit (Mortgage Interest Deduction)
    // First year interest approximation (actual varies as loan amortizes)
    final firstYearInterest = DecimalUtils.roundToCents(
      inputs.loanAmount * (inputs.interestRate / 100),
    );
    final monthlyTaxBenefit = DecimalUtils.roundToCents(
      (firstYearInterest * inputs.marginalTaxRate / 100) / 12,
    );
    steps.add(CalculationStep(
      name: 'Monthly Tax Benefit',
      formula: '(Annual Interest × Tax Rate) / 12',
      inputs: {
        'Est. Annual Interest': firstYearInterest,
        'Marginal Tax Rate (%)': inputs.marginalTaxRate,
      },
      result: monthlyTaxBenefit,
      explanation: 'Estimated tax savings from mortgage interest deduction. '
          'Only applies if you itemize deductions. Actual benefit decreases '
          'over time as interest portion decreases.',
    ));

    // Step 7: Calculate Opportunity Cost for Renter
    // The renter could invest the down payment and closing costs
    final investableAmount = DecimalUtils.roundToCents(inputs.totalUpfrontCost);
    final monthlyOpportunityCost = DecimalUtils.roundToCents(
      (investableAmount * inputs.investmentReturnRate / 100) / 12,
    );
    steps.add(CalculationStep(
      name: 'Monthly Opportunity Cost',
      formula: '(Down Payment + Closing Costs) × Return Rate / 12',
      inputs: {
        'Investable Amount': investableAmount,
        'Investment Return (%)': inputs.investmentReturnRate,
      },
      result: monthlyOpportunityCost,
      explanation: 'Represents the investment returns a renter could earn by '
          'investing the money that would otherwise be used for down payment '
          'and closing costs.',
    ));

    // Compile monthly costs
    final buyingCosts = MonthlyBuyingCosts(
      principalAndInterest: monthlyPi,
      propertyTax: monthlyPropertyTax,
      homeInsurance: monthlyHomeInsurance,
      pmi: monthlyPmi,
      hoa: inputs.hoaMonthly,
      maintenance: monthlyMaintenance,
      taxBenefit: monthlyTaxBenefit,
    );

    final rentingCosts = MonthlyRentingCosts(
      rent: inputs.monthlyRent,
      rentersInsurance: inputs.rentersInsuranceMonthly,
      opportunityCost: monthlyOpportunityCost,
    );

    // Step 8: Calculate Break-Even Point
    final monthlySavings =
        DecimalUtils.roundToCents(rentingCosts.total - buyingCosts.total);
    int breakEvenMonths = 0;
    
    if (monthlySavings > 0) {
      // Buying is cheaper, but need to recover upfront costs
      breakEvenMonths = (inputs.totalUpfrontCost / monthlySavings).ceil();
    } else if (monthlySavings < 0) {
      // Renting is cheaper monthly, but equity builds
      // More complex calculation considering appreciation
      breakEvenMonths = _calculateBreakEvenWithEquity(inputs, buyingCosts, rentingCosts);
    }

    steps.add(CalculationStep(
      name: 'Break-Even Analysis',
      formula: 'Upfront Costs / Monthly Savings',
      inputs: {
        'Monthly Buying': buyingCosts.total,
        'Monthly Renting': rentingCosts.total,
        'Monthly Difference': monthlySavings.abs(),
        'Upfront Costs': inputs.totalUpfrontCost,
      },
      result: breakEvenMonths.toDouble(),
      explanation: monthlySavings > 0
          ? 'Buying is \$${monthlySavings.toStringAsFixed(0)}/mo cheaper. '
              'You\'ll recover upfront costs in $breakEvenMonths months.'
          : 'Renting is \$${(-monthlySavings).toStringAsFixed(0)}/mo cheaper, '
              'but equity appreciation may offset this over time.',
    ));

    // Generate yearly projections
    final projections = _generateProjections(inputs, buyingCosts, rentingCosts);

    return RentVsBuyCalculation(
      inputs: inputs,
      buyingCosts: buyingCosts,
      rentingCosts: rentingCosts,
      monthlySavings: monthlySavings,
      breakEvenMonths: breakEvenMonths,
      projections: projections,
      breakdown: CalculationBreakdown(steps: steps),
    );
  }

  double _calculateMonthlyPayment({
    required double principal,
    required double annualRate,
    required double years,
  }) {
    if (principal <= 0 || years <= 0) {
      return 0;
    }
    if (annualRate <= 0) {
      return DecimalUtils.roundToCents(principal / (years * 12));
    }
    return DecimalUtils.roundToCents(
      _loanMath.calculatePayment(
        loanAmount: principal,
        interestRate: annualRate,
        termYears: years,
      ),
    );
  }

  int _calculateBreakEvenWithEquity(
    RentVsBuyInputs inputs,
    MonthlyBuyingCosts buyingCosts,
    MonthlyRentingCosts rentingCosts,
  ) {
    double homeValue = DecimalUtils.roundToCents(inputs.homePrice);
    double loanBalance = DecimalUtils.roundToCents(inputs.loanAmount);
    double totalBuyingCost = DecimalUtils.roundToCents(inputs.totalUpfrontCost);
    double totalRentingCost = 0;
    double investmentValue = DecimalUtils.roundToCents(inputs.totalUpfrontCost);
    double currentRent = DecimalUtils.roundToCents(inputs.monthlyRent);
    
    final monthlyRate = inputs.interestRate / 100 / 12;
    final monthlyAppreciation = inputs.homeAppreciationRate / 100 / 12;
    final monthlyInvestReturn = inputs.investmentReturnRate / 100 / 12;
    final monthlyRentIncrease = inputs.annualRentIncrease / 100 / 12;

    for (int month = 1; month <= inputs.analysisYears * 12; month++) {
      // Update home value
      homeValue = DecimalUtils.roundToCents(homeValue * (1 + monthlyAppreciation));
      
      // Calculate interest portion and principal paydown
      final interestPortion = DecimalUtils.roundToCents(loanBalance * monthlyRate);
      final principalPortion = DecimalUtils.roundToCents(
        buyingCosts.principalAndInterest - interestPortion,
      );
      loanBalance = DecimalUtils.ensureNonNegative(
        DecimalUtils.roundToCents(loanBalance - principalPortion),
      );
      
      // Update costs
      totalBuyingCost = DecimalUtils.roundToCents(
        totalBuyingCost + buyingCosts.total,
      );
      totalRentingCost = DecimalUtils.roundToCents(
        totalRentingCost + currentRent + inputs.rentersInsuranceMonthly,
      );
      
      // Rent increases
      currentRent = DecimalUtils.roundToCents(
        currentRent * (1 + monthlyRentIncrease),
      );
      
      // Investment grows
      investmentValue = DecimalUtils.roundToCents(
        investmentValue * (1 + monthlyInvestReturn),
      );
      
      // Check if buying is ahead
      final equity = homeValue - loanBalance;
      final netWorthBuying = equity - totalBuyingCost;
      final netWorthRenting = investmentValue - totalRentingCost;
      
      if (netWorthBuying >= netWorthRenting) {
        return month;
      }
    }
    
    return inputs.analysisYears * 12; // Didn't break even in analysis period
  }

  List<YearlyProjection> _generateProjections(
    RentVsBuyInputs inputs,
    MonthlyBuyingCosts buyingCosts,
    MonthlyRentingCosts rentingCosts,
  ) {
    final projections = <YearlyProjection>[];

    double homeValue = DecimalUtils.roundToCents(inputs.homePrice);
    double loanBalance = DecimalUtils.roundToCents(inputs.loanAmount);
    double totalBuyingCost = DecimalUtils.roundToCents(inputs.totalUpfrontCost);
    double totalRentingCost = 0;
    double investmentValue = DecimalUtils.roundToCents(inputs.totalUpfrontCost);
    double currentRent = DecimalUtils.roundToCents(inputs.monthlyRent);

    final monthlyRate = inputs.interestRate / 100 / 12;
    final monthlyAppreciation = inputs.homeAppreciationRate / 100 / 12;
    final monthlyInvestReturn = inputs.investmentReturnRate / 100 / 12;

    for (int year = 1; year <= inputs.analysisYears; year++) {
      // Process 12 months
      for (int month = 0; month < 12; month++) {
        homeValue = DecimalUtils.roundToCents(
          homeValue * (1 + monthlyAppreciation),
        );

        final interestPortion = DecimalUtils.roundToCents(loanBalance * monthlyRate);
        final principalPortion = DecimalUtils.roundToCents(
          buyingCosts.principalAndInterest - interestPortion,
        );
        loanBalance = DecimalUtils.ensureNonNegative(
          DecimalUtils.roundToCents(loanBalance - principalPortion),
        );

        totalBuyingCost = DecimalUtils.roundToCents(
          totalBuyingCost + buyingCosts.total,
        );
        totalRentingCost = DecimalUtils.roundToCents(
          totalRentingCost + currentRent + inputs.rentersInsuranceMonthly,
        );

        // Annual rent increase applied monthly
        if (month == 11) {
          currentRent = DecimalUtils.roundToCents(
            currentRent * (1 + inputs.annualRentIncrease / 100),
          );
        }

        investmentValue = DecimalUtils.roundToCents(
          investmentValue * (1 + monthlyInvestReturn),
        );
      }

      final equity = DecimalUtils.roundToCents(homeValue - loanBalance);

      projections.add(YearlyProjection(
        year: year,
        homeValue: homeValue,
        remainingLoanBalance: loanBalance,
        equity: equity,
        totalBuyingCostToDate: totalBuyingCost,
        totalRentingCostToDate: totalRentingCost,
        rentAtYear: currentRent,
        investmentValueIfRenting: investmentValue,
        netWorthBuying: DecimalUtils.roundToCents(
          equity - totalBuyingCost + inputs.totalUpfrontCost,
        ),
        netWorthRenting: DecimalUtils.roundToCents(
          investmentValue - totalRentingCost,
        ),
      ));
    }
    
    return projections;
  }
}
