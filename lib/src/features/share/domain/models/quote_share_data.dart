import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/models/loan_parameters_read_model.dart';

class QuoteShareData {
  const QuoteShareData({
    required this.loanAmount,
    required this.interestRate,
    required this.termYears,
    required this.piPayment,
    required this.pitiPayment,
    required this.monthlyTax,
    required this.monthlyInsurance,
    required this.monthlyMortgageInsurance,
    required this.monthlyHoa,
    required this.cashToClose,
    required this.price,
    required this.downPayment,
  });

  final double? loanAmount;
  final double? interestRate;
  final double? termYears;
  final double? piPayment;
  final double? pitiPayment;
  final double? monthlyTax;
  final double? monthlyInsurance;
  final double? monthlyMortgageInsurance;
  final double? monthlyHoa;
  final double? cashToClose;
  final double? price;
  final double? downPayment;

  static QuoteShareData fromCalculatorProvider(LoanParametersReadModel provider) {
    final monthlyTax = (provider.propertyTax ?? 0) / 12;
    final monthlyInsurance = (provider.homeInsurance ?? 0) / 12;
    final monthlyMortgageInsurance = (provider.mortgageInsurance ?? 0) / 12;
    final monthlyHoa = provider.monthlyExpenses ?? 0;

    return QuoteShareData(
      loanAmount: provider.loanAmount,
      interestRate: provider.interestRate,
      termYears: provider.termYears,
      piPayment: provider.payment,
      pitiPayment: provider.pitiPayment,
      monthlyTax: monthlyTax == 0 ? null : monthlyTax,
      monthlyInsurance: monthlyInsurance == 0 ? null : monthlyInsurance,
      monthlyMortgageInsurance:
          monthlyMortgageInsurance == 0 ? null : monthlyMortgageInsurance,
      monthlyHoa: monthlyHoa == 0 ? null : monthlyHoa,
      cashToClose: provider.cashToClose,
      price: provider.price,
      downPayment: provider.downPayment,
    );
  }

  static QuoteShareData fromCalculationEntry(CalculationEntry entry) {
    final monthlyTax = ((entry.propertyTax ?? 0) / 12);
    final monthlyInsurance = ((entry.homeInsurance ?? 0) / 12);
    final monthlyMortgageInsurance = ((entry.mortgageInsurance ?? 0) / 12);
    final monthlyHoa = (entry.monthlyExpenses ?? 0);

    return QuoteShareData(
      loanAmount: entry.loanAmount,
      interestRate: entry.interestRate,
      termYears: entry.termYears,
      piPayment: entry.monthlyPayment,
      pitiPayment: entry.pitiPayment,
      monthlyTax: monthlyTax == 0 ? null : monthlyTax,
      monthlyInsurance: monthlyInsurance == 0 ? null : monthlyInsurance,
      monthlyMortgageInsurance:
          monthlyMortgageInsurance == 0 ? null : monthlyMortgageInsurance,
      monthlyHoa: monthlyHoa == 0 ? null : monthlyHoa,
      cashToClose: null,
      price: entry.price,
      downPayment: entry.downPayment,
    );
  }

  Map<String, String> toTokenMap({
    String? borrowerName,
    String? scenarioName,
  }) {
    final Map<String, String> tokens = <String, String>{};

    tokens['borrower_name'] = borrowerName ?? '';
    tokens['scenario_name'] = scenarioName ?? '';

    tokens['loan_amount'] = loanAmount != null
        ? CurrencyFormatter.formatCurrency(loanAmount, showDecimals: false)
        : '';
    tokens['interest_rate'] =
        interestRate != null
            ? CurrencyFormatter.formatPercent(interestRate, decimals: 3)
            : '';
    tokens['term_years'] =
        termYears != null ? '${termYears!.toStringAsFixed(1)} years' : '';

    tokens['pi_payment'] =
        piPayment != null ? CurrencyFormatter.formatCurrency(piPayment) : '';
    tokens['piti_payment'] =
        pitiPayment != null ? CurrencyFormatter.formatCurrency(pitiPayment) : '';

    tokens['monthly_tax'] = monthlyTax != null
        ? CurrencyFormatter.formatCurrency(monthlyTax)
        : '';
    tokens['monthly_insurance'] = monthlyInsurance != null
        ? CurrencyFormatter.formatCurrency(monthlyInsurance)
        : '';
    tokens['monthly_mi'] = monthlyMortgageInsurance != null
        ? CurrencyFormatter.formatCurrency(monthlyMortgageInsurance)
        : '';
    tokens['monthly_hoa'] = monthlyHoa != null
        ? CurrencyFormatter.formatCurrency(monthlyHoa)
        : '';

    tokens['cash_to_close'] = cashToClose != null
        ? CurrencyFormatter.formatCurrency(cashToClose)
        : '';

    tokens['price'] =
        price != null ? CurrencyFormatter.formatCurrency(price, showDecimals: false) : '';
    tokens['down_payment'] = downPayment != null
        ? CurrencyFormatter.formatCurrency(downPayment, showDecimals: false)
        : '';

    tokens['disclaimer'] =
        'Estimates only. Not a loan offer. Taxes/insurance/MI may vary.';

    return tokens;
  }
}
