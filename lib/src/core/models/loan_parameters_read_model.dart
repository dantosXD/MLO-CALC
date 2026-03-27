import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';

abstract class LoanParametersReadModel {
  double? get loanAmount;
  double? get interestRate;
  double? get termYears;
  double? get payment;
  double? get price;
  double? get downPayment;
  double? get downPaymentPercentage;
  double? get propertyTax;
  double? get homeInsurance;
  double? get mortgageInsurance;
  double? get monthlyExpenses;
  ClosingCosts get closingCosts;
  double get cashToClose;
  double? get annualIncome;
  double? get monthlyDebt;
  List<AmortizationEntry> get amortizationData;
  bool get isComputingAmortization;
  bool get isInterestOnly;
  PaymentDisplayMode get displayMode;
  bool get hasPitiComponents;
  double? get displayPayment;
  double get pitiPayment;
  double get interestOnlyPayment;
  double get monthlyEscrowExpenses;
  CalculationHistory get history;
}
