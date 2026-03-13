import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';

const Object _loanQuoteUnset = Object();

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
    Object? loanAmount = _loanQuoteUnset,
    Object? interestRate = _loanQuoteUnset,
    Object? termYears = _loanQuoteUnset,
    Object? payment = _loanQuoteUnset,
    Object? price = _loanQuoteUnset,
    Object? downPayment = _loanQuoteUnset,
    Object? propertyTax = _loanQuoteUnset,
    Object? homeInsurance = _loanQuoteUnset,
    Object? mortgageInsurance = _loanQuoteUnset,
    Object? monthlyExpenses = _loanQuoteUnset,
    Object? closingCosts = _loanQuoteUnset,
    Object? calculationError = _loanQuoteUnset,
    Object? isInterestOnly = _loanQuoteUnset,
    Object? displayMode = _loanQuoteUnset,
    Object? presentedValue = _loanQuoteUnset,
  }) {
    return LoanQuoteState(
      loanAmount: identical(loanAmount, _loanQuoteUnset)
          ? this.loanAmount
          : loanAmount as double?,
      interestRate: identical(interestRate, _loanQuoteUnset)
          ? this.interestRate
          : interestRate as double?,
      termYears: identical(termYears, _loanQuoteUnset)
          ? this.termYears
          : termYears as double?,
      payment: identical(payment, _loanQuoteUnset)
          ? this.payment
          : payment as double?,
      price: identical(price, _loanQuoteUnset) ? this.price : price as double?,
      downPayment: identical(downPayment, _loanQuoteUnset)
          ? this.downPayment
          : downPayment as double?,
      propertyTax: identical(propertyTax, _loanQuoteUnset)
          ? this.propertyTax
          : propertyTax as double?,
      homeInsurance: identical(homeInsurance, _loanQuoteUnset)
          ? this.homeInsurance
          : homeInsurance as double?,
      mortgageInsurance: identical(mortgageInsurance, _loanQuoteUnset)
          ? this.mortgageInsurance
          : mortgageInsurance as double?,
      monthlyExpenses: identical(monthlyExpenses, _loanQuoteUnset)
          ? this.monthlyExpenses
          : monthlyExpenses as double?,
      closingCosts: identical(closingCosts, _loanQuoteUnset)
          ? this.closingCosts
          : closingCosts as ClosingCosts,
      calculationError: identical(calculationError, _loanQuoteUnset)
          ? this.calculationError
          : calculationError as String?,
      isInterestOnly: identical(isInterestOnly, _loanQuoteUnset)
          ? this.isInterestOnly
          : isInterestOnly as bool,
      displayMode: identical(displayMode, _loanQuoteUnset)
          ? this.displayMode
          : displayMode as PaymentDisplayMode,
      presentedValue: identical(presentedValue, _loanQuoteUnset)
          ? this.presentedValue
          : presentedValue as double?,
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
