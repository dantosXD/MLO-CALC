import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';

enum PaymentDisplayMode { standardPI, interestOnly, piti }

class LoanQuoteState {
  const LoanQuoteState({
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
    this.closingCosts = const ClosingCosts(),
    this.calculationError,
    this.isInterestOnly = false,
    this.displayMode = PaymentDisplayMode.standardPI,
    this.presentedValue,
  });

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
  final ClosingCosts closingCosts;
  final String? calculationError;
  final bool isInterestOnly;
  final PaymentDisplayMode displayMode;
  final double? presentedValue;

  LoanQuoteState copyWith({
    double? loanAmount,
    bool clearLoanAmount = false,
    double? interestRate,
    bool clearInterestRate = false,
    double? termYears,
    bool clearTermYears = false,
    double? payment,
    bool clearPayment = false,
    double? price,
    bool clearPrice = false,
    double? downPayment,
    bool clearDownPayment = false,
    double? propertyTax,
    bool clearPropertyTax = false,
    double? homeInsurance,
    bool clearHomeInsurance = false,
    double? mortgageInsurance,
    bool clearMortgageInsurance = false,
    double? monthlyExpenses,
    bool clearMonthlyExpenses = false,
    ClosingCosts? closingCosts,
    String? calculationError,
    bool clearCalculationError = false,
    bool? isInterestOnly,
    PaymentDisplayMode? displayMode,
    double? presentedValue,
    bool clearPresentedValue = false,
  }) {
    return LoanQuoteState(
      loanAmount: clearLoanAmount ? null : (loanAmount ?? this.loanAmount),
      interestRate:
          clearInterestRate ? null : (interestRate ?? this.interestRate),
      termYears: clearTermYears ? null : (termYears ?? this.termYears),
      payment: clearPayment ? null : (payment ?? this.payment),
      price: clearPrice ? null : (price ?? this.price),
      downPayment: clearDownPayment ? null : (downPayment ?? this.downPayment),
      propertyTax:
          clearPropertyTax ? null : (propertyTax ?? this.propertyTax),
      homeInsurance:
          clearHomeInsurance ? null : (homeInsurance ?? this.homeInsurance),
      mortgageInsurance: clearMortgageInsurance
          ? null
          : (mortgageInsurance ?? this.mortgageInsurance),
      monthlyExpenses: clearMonthlyExpenses
          ? null
          : (monthlyExpenses ?? this.monthlyExpenses),
      closingCosts: closingCosts ?? this.closingCosts,
      calculationError: clearCalculationError
          ? null
          : (calculationError ?? this.calculationError),
      isInterestOnly: isInterestOnly ?? this.isInterestOnly,
      displayMode: displayMode ?? this.displayMode,
      presentedValue:
          clearPresentedValue ? null : (presentedValue ?? this.presentedValue),
    );
  }

  double? get downPaymentPercentage {
    if (price == null || price == 0 || downPayment == null) return null;
    if (downPayment! < 100) return downPayment;
    return (downPayment! / price!) * 100;
  }

  bool get hasPitiComponents =>
      propertyTax != null ||
      homeInsurance != null ||
      mortgageInsurance != null ||
      monthlyExpenses != null;

  double get cashToClose {
    var total = closingCosts.total;
    if (price != null && downPayment != null) {
      if (downPayment! < 100) {
        total += price! * (downPayment! / 100);
      } else {
        total += downPayment!;
      }
    } else if (loanAmount != null && price != null) {
      total += price! - loanAmount!;
    }
    return total;
  }

  double get pitiPayment {
    if (payment == null) return 0;
    return payment! +
        ((propertyTax ?? 0) / 12) +
        ((homeInsurance ?? 0) / 12) +
        ((mortgageInsurance ?? 0) / 12) +
        (monthlyExpenses ?? 0);
  }

  double get interestOnlyPayment {
    if (loanAmount == null || interestRate == null) return 0;
    final monthlyRate = interestRate! / 100 / 12;
    return loanAmount! * monthlyRate;
  }

  double get monthlyEscrowExpenses {
    return ((propertyTax ?? 0) / 12) +
        ((homeInsurance ?? 0) / 12) +
        ((mortgageInsurance ?? 0) / 12) +
        (monthlyExpenses ?? 0);
  }

  double? get displayPayment {
    if (payment == null) return null;
    switch (displayMode) {
      case PaymentDisplayMode.standardPI:
      case PaymentDisplayMode.interestOnly:
        return payment;
      case PaymentDisplayMode.piti:
        return pitiPayment;
    }
  }
}
