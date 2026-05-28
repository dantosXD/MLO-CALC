import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/utils/type_utils.dart';
import 'package:loan_ranger/src/core/validators/financial_validators.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculator_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/qualification_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';

enum LoanQuoteField {
  loanAmount,
  interestRate,
  termYears,
  payment,
  price,
  downPayment,
  propertyTax,
  homeInsurance,
  mortgageInsurance,
  monthlyExpenses,
}

enum _ManualVar { loanAmount, interestRate, termYears, payment }

class LoanQuoteController with ChangeNotifier {
  LoanQuoteController({
    required CoreCalculationService coreCalculationService,
    required HistoryController historyController,
  }) : _coreCalculationService = coreCalculationService,
       _historyController = historyController;

  final CoreCalculationService _coreCalculationService;
  final HistoryController _historyController;

  LoanQuoteState _state = const LoanQuoteState();
  final Set<_ManualVar> _manualVariables = <_ManualVar>{};
  final List<_ManualVar> _manualInputOrder = <_ManualVar>[];

  LoanQuoteState get state => _state;
  String? get inputError => _state.calculationError;
  double? get presentedValue => _state.presentedValue;

  double? get loanAmount => _state.loanAmount;
  double? get interestRate => _state.interestRate;
  double? get termYears => _state.termYears;
  double? get payment => _state.payment;
  double? get price => _state.price;
  double? get downPayment => _state.downPayment;
  double? get downPaymentPercentage => _state.downPaymentPercentage;
  double? get propertyTax => _state.propertyTax;
  double? get homeInsurance => _state.homeInsurance;
  double? get mortgageInsurance => _state.mortgageInsurance;
  double? get monthlyExpenses => _state.monthlyExpenses;
  ClosingCosts get closingCosts => _state.closingCosts;
  bool get isInterestOnly => _state.isInterestOnly;
  PaymentDisplayMode get displayMode => _state.displayMode;
  bool get hasPitiComponents => _state.hasPitiComponents;
  double? get displayPayment => _state.displayPayment;
  double get cashToClose => _state.cashToClose;
  double get pitiPayment => _state.pitiPayment;
  double get interestOnlyPayment => _state.interestOnlyPayment;
  double get monthlyEscrowExpenses => _state.monthlyEscrowExpenses;

  void assignInput(LoanQuoteField field, {double? value}) {
    switch (field) {
      case LoanQuoteField.loanAmount:
        setLoanAmount(value: value);
        break;
      case LoanQuoteField.interestRate:
        setInterestRate(value: value);
        break;
      case LoanQuoteField.termYears:
        setTermYears(value: value);
        break;
      case LoanQuoteField.payment:
        setPayment(value: value);
        break;
      case LoanQuoteField.price:
        setPrice(value: value);
        break;
      case LoanQuoteField.downPayment:
        setDownPayment(value: value);
        break;
      case LoanQuoteField.propertyTax:
        setPropertyTax(value: value);
        break;
      case LoanQuoteField.homeInsurance:
        setHomeInsurance(value: value);
        break;
      case LoanQuoteField.mortgageInsurance:
        setMortgageInsurance(value: value);
        break;
      case LoanQuoteField.monthlyExpenses:
        setMonthlyExpenses(value: value);
        break;
    }
  }

  void clearField(LoanQuoteField field) {
    switch (field) {
      case LoanQuoteField.loanAmount:
        clearLoanAmount();
        break;
      case LoanQuoteField.interestRate:
        clearInterestRate();
        break;
      case LoanQuoteField.termYears:
        clearTermYears();
        break;
      case LoanQuoteField.payment:
        clearPayment();
        break;
      case LoanQuoteField.price:
        setPrice(value: null);
        break;
      case LoanQuoteField.downPayment:
        setDownPayment(value: null);
        break;
      case LoanQuoteField.propertyTax:
        setPropertyTax(value: null);
        break;
      case LoanQuoteField.homeInsurance:
        setHomeInsurance(value: null);
        break;
      case LoanQuoteField.mortgageInsurance:
        setMortgageInsurance(value: null);
        break;
      case LoanQuoteField.monthlyExpenses:
        setMonthlyExpenses(value: null);
        break;
    }
  }

  void hydrateFromSnapshot(CalculatorStateSnapshot snapshot) {
    _manualVariables.clear();
    _manualInputOrder.clear();
    _state = LoanQuoteState(
      loanAmount: snapshot.loanAmount,
      interestRate: snapshot.interestRate,
      termYears: snapshot.termYears,
      payment: snapshot.payment,
      price: snapshot.price,
      downPayment: snapshot.downPayment,
      propertyTax: snapshot.propertyTax,
      homeInsurance: snapshot.homeInsurance,
      mortgageInsurance: snapshot.mortgageInsurance,
      monthlyExpenses: snapshot.monthlyExpenses,
      closingCosts: _state.closingCosts,
    );
    notifyListeners();
  }

  void restoreFromHistoryEntry(CalculationEntry entry) {
    final inputs = entry.inputs;
    final results = entry.results;
    _manualVariables.clear();
    _manualInputOrder.clear();
    _state = _state.copyWith(
      loanAmount:
          TypeUtils.toDouble(inputs['loanAmount']) ??
          TypeUtils.toDouble(results['loanAmount']) ??
          TypeUtils.toDouble(results['maxLoanAmount']),
      interestRate:
          TypeUtils.toDouble(inputs['interestRate']) ??
          TypeUtils.toDouble(results['interestRate']),
      termYears:
          TypeUtils.toDouble(inputs['termYears']) ?? TypeUtils.toDouble(results['termYears']),
      payment: TypeUtils.toDouble(results['payment']) ?? TypeUtils.toDouble(inputs['payment']),
      price: TypeUtils.toDouble(inputs['price']),
      downPayment: TypeUtils.toDouble(inputs['downPayment']),
      propertyTax: TypeUtils.toDouble(inputs['propertyTax']),
      homeInsurance: TypeUtils.toDouble(inputs['homeInsurance']),
      mortgageInsurance: TypeUtils.toDouble(inputs['mortgageInsurance']),
      monthlyExpenses: TypeUtils.toDouble(inputs['monthlyExpenses']),
      clearCalculationError: true,
      presentedValue:
          TypeUtils.toDouble(results['payment']) ??
          TypeUtils.toDouble(inputs['payment']) ??
          TypeUtils.toDouble(results['loanAmount']) ??
          TypeUtils.toDouble(results['maxLoanAmount']) ??
          TypeUtils.toDouble(inputs['loanAmount']),
      isInterestOnly: false,
      displayMode: PaymentDisplayMode.standardPI,
    );
    notifyListeners();
  }

  void presentValue(double value) {
    _state = _state.copyWith(presentedValue: value);
    notifyListeners();
  }

  void setLoanAmount({double? value}) {
    if (!_validateValue(value, FinancialValidators.validateLoanAmount)) return;
    if (value == null) {
      _state = _state.copyWith(
        clearLoanAmount: true,
        clearCalculationError: true,
      );
      _unregisterManualInput(_ManualVar.loanAmount);
    } else {
      _state = _state.copyWith(loanAmount: value, clearCalculationError: true);
      _registerManualInput(_ManualVar.loanAmount);
    }

    if (!_manualVariables.contains(_ManualVar.payment)) {
      _state = _state.copyWith(clearPayment: true);
      _unregisterManualInput(_ManualVar.payment);
    }

    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void setInterestRate({double? value}) {
    if (!_validateValue(value, FinancialValidators.validateInterestRate)) {
      return;
    }
    if (value == null) {
      _state = _state.copyWith(
        clearInterestRate: true,
        clearCalculationError: true,
      );
      _unregisterManualInput(_ManualVar.interestRate);
    } else {
      _state = _state.copyWith(
        interestRate: value,
        clearCalculationError: true,
      );
      _registerManualInput(_ManualVar.interestRate);
    }

    if (!_manualVariables.contains(_ManualVar.payment)) {
      _state = _state.copyWith(clearPayment: true);
      _unregisterManualInput(_ManualVar.payment);
    }

    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void setTermYears({double? value}) {
    if (!_validateValue(value, FinancialValidators.validateTermYears)) return;
    if (value == null) {
      _state = _state.copyWith(
        clearTermYears: true,
        clearCalculationError: true,
      );
      _unregisterManualInput(_ManualVar.termYears);
    } else {
      _state = _state.copyWith(termYears: value, clearCalculationError: true);
      _registerManualInput(_ManualVar.termYears);
    }

    if (!_manualVariables.contains(_ManualVar.payment)) {
      _state = _state.copyWith(clearPayment: true);
      _unregisterManualInput(_ManualVar.payment);
    }

    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void setPayment({double? value}) {
    if (!_validateValue(value, FinancialValidators.validatePayment)) return;
    if (value == null) {
      _state = _state.copyWith(clearPayment: true, clearCalculationError: true);
      _unregisterManualInput(_ManualVar.payment);
    } else {
      _state = _state.copyWith(payment: value, clearCalculationError: true);
      _registerManualInput(_ManualVar.payment);
    }

    if (!_manualVariables.contains(_ManualVar.loanAmount)) {
      _state = _state.copyWith(clearLoanAmount: true);
      _unregisterManualInput(_ManualVar.loanAmount);
    }

    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void setPrice({double? value}) {
    if (!_validateValue(value, FinancialValidators.validatePrice)) return;
    _state = value == null
        ? _state.copyWith(clearPrice: true, clearCalculationError: true)
        : _state.copyWith(price: value, clearCalculationError: true);
    final didCalculate = _calculateLoanAmountFromPrice();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void setDownPayment({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validateDownPayment(
        value,
        _state.price,
      );
      if (!validation.isValid) {
        _state = _state.copyWith(calculationError: validation.errorMessage);
        notifyListeners();
        return;
      }
    }
    _state = value == null
        ? _state.copyWith(clearDownPayment: true, clearCalculationError: true)
        : _state.copyWith(downPayment: value, clearCalculationError: true);
    final didCalculate = _calculateLoanAmountFromPrice();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void setPropertyTax({double? value}) {
    _state = value == null
        ? _state.copyWith(clearPropertyTax: true)
        : _state.copyWith(propertyTax: value);
    notifyListeners();
  }

  void setHomeInsurance({double? value}) {
    _state = value == null
        ? _state.copyWith(clearHomeInsurance: true)
        : _state.copyWith(homeInsurance: value);
    notifyListeners();
  }

  void setMortgageInsurance({double? value}) {
    _state = value == null
        ? _state.copyWith(clearMortgageInsurance: true)
        : _state.copyWith(mortgageInsurance: value);
    notifyListeners();
  }

  void setMonthlyExpenses({double? value}) {
    _state = value == null
        ? _state.copyWith(clearMonthlyExpenses: true)
        : _state.copyWith(monthlyExpenses: value);
    notifyListeners();
  }

  void updateClosingCosts(ClosingCosts costs) {
    _state = _state.copyWith(closingCosts: costs);
    notifyListeners();
  }

  void estimateClosingCosts() {
    if (_state.loanAmount == null || _state.price == null) return;
    _state = _state.copyWith(
      closingCosts: ClosingCosts.estimate(
        loanAmount: _state.loanAmount!,
        price: _state.price!,
      ),
    );
    notifyListeners();
  }

  void toggleInterestOnly() {
    _state = _state.copyWith(
      isInterestOnly: !_state.isInterestOnly,
      clearCalculationError: true,
    );
    if (_state.loanAmount != null &&
        _state.interestRate != null &&
        _state.termYears != null) {
      _calculatePayment();
      return;
    }
    notifyListeners();
  }

  void cycleDisplayMode({bool reverse = false}) {
    final modes = <PaymentDisplayMode>[PaymentDisplayMode.standardPI];
    if (_state.loanAmount != null && _state.interestRate != null) {
      modes.add(PaymentDisplayMode.interestOnly);
    }
    if (_state.hasPitiComponents && _state.payment != null) {
      modes.add(PaymentDisplayMode.piti);
    }
    if (modes.length <= 1) return;

    final currentIndex = modes.indexOf(_state.displayMode);
    final nextIndex = reverse
        ? (currentIndex - 1 + modes.length) % modes.length
        : (currentIndex + 1) % modes.length;
    final nextMode = modes[nextIndex];
    final wasInterestOnly = _state.isInterestOnly;
    final isInterestOnlyMode = nextMode == PaymentDisplayMode.interestOnly;

    _state = _state.copyWith(
      displayMode: nextMode,
      isInterestOnly: isInterestOnlyMode,
    );

    if (wasInterestOnly != isInterestOnlyMode &&
        _state.loanAmount != null &&
        _state.interestRate != null &&
        _state.termYears != null) {
      _calculatePayment();
      return;
    }
    notifyListeners();
  }

  void clearLoanAmount() {
    _state = _state.copyWith(
      clearLoanAmount: true,
      clearCalculationError: true,
    );
    _unregisterManualInput(_ManualVar.loanAmount);
    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void clearInterestRate() {
    _state = _state.copyWith(
      clearInterestRate: true,
      clearCalculationError: true,
    );
    _unregisterManualInput(_ManualVar.interestRate);
    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void clearTermYears() {
    _state = _state.copyWith(clearTermYears: true, clearCalculationError: true);
    _unregisterManualInput(_ManualVar.termYears);
    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void clearPayment() {
    _state = _state.copyWith(clearPayment: true, clearCalculationError: true);
    _unregisterManualInput(_ManualVar.payment);
    final didCalculate = calculate();
    if (!didCalculate) {
      notifyListeners();
    }
  }

  void clearAll() {
    _manualVariables.clear();
    _manualInputOrder.clear();
    _state = const LoanQuoteState();
    notifyListeners();
  }

  bool calculate() {
    if (_manualInputOrder.length == 3) {
      final provided = _manualInputOrder.toSet();
      _ManualVar? target;
      for (final candidate in _ManualVar.values) {
        if (!provided.contains(candidate)) {
          target = candidate;
          break;
        }
      }
      if (target != null) {
        switch (target) {
          case _ManualVar.payment:
            if (_state.loanAmount != null &&
                _state.interestRate != null &&
                _state.termYears != null) {
              _calculatePayment();
              return true;
            }
            break;
          case _ManualVar.loanAmount:
            if (_state.payment != null &&
                _state.interestRate != null &&
                _state.termYears != null) {
              _calculateLoanAmount();
              return true;
            }
            break;
          case _ManualVar.interestRate:
            if (_state.loanAmount != null &&
                _state.payment != null &&
                _state.termYears != null) {
              _calculateInterestRate();
              return true;
            }
            break;
          case _ManualVar.termYears:
            if (_state.loanAmount != null &&
                _state.interestRate != null &&
                _state.payment != null) {
              _calculateTerm();
              return true;
            }
            break;
        }
      }
    }

    if (_state.loanAmount != null &&
        _state.interestRate != null &&
        _state.termYears != null &&
        _state.payment == null) {
      _calculatePayment();
      return true;
    }
    if (_state.payment != null &&
        _state.interestRate != null &&
        _state.termYears != null &&
        _state.loanAmount == null) {
      _calculateLoanAmount();
      return true;
    }
    if (_state.loanAmount != null &&
        _state.payment != null &&
        _state.termYears != null &&
        _state.interestRate == null) {
      _calculateInterestRate();
      return true;
    }
    if (_state.loanAmount != null &&
        _state.interestRate != null &&
        _state.payment != null &&
        _state.termYears == null) {
      _calculateTerm();
      return true;
    }
    return false;
  }

  void calculateInterestRate() {
    _calculateInterestRate();
  }

  void calculateTerm() {
    _calculateTerm();
  }

  void calculateLoanAmount() {
    _calculateLoanAmount();
  }

  void applyQualificationResult(QualificationResult outcome) {
    _state = _state.copyWith(
      loanAmount: outcome.loanAmount,
      payment: outcome.monthlyPiPayment,
      clearCalculationError: true,
      presentedValue: outcome.loanAmount,
    );
    _unregisterManualInput(_ManualVar.loanAmount);
    _unregisterManualInput(_ManualVar.payment);
    notifyListeners();
  }

  bool _validateValue(double? value, ValidationResult Function(double) validator) {
    if (value != null) {
      final validation = validator(value);
      if (!validation.isValid) {
        _state = _state.copyWith(calculationError: validation.errorMessage);
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  void _registerManualInput(_ManualVar variable) {
    _manualVariables.add(variable);
    _manualInputOrder.remove(variable);
    _manualInputOrder.add(variable);
    if (_manualInputOrder.length > 3) {
      _manualInputOrder.removeAt(0);
    }
  }

  void _unregisterManualInput(_ManualVar variable) {
    _manualVariables.remove(variable);
    _manualInputOrder.remove(variable);
  }

  bool _calculateLoanAmountFromPrice() {
    if (_state.price == null || _state.downPayment == null) {
      return false;
    }

    final downPaymentAmount = _state.downPayment! < 100
        ? _state.price! * (_state.downPayment! / 100)
        : _state.downPayment!;
    _state = _state.copyWith(
      loanAmount: _state.price! - downPaymentAmount,
      clearCalculationError: true,
    );
    _unregisterManualInput(_ManualVar.loanAmount);
    return calculate();
  }

  void _calculatePayment() {
    if (_state.loanAmount == null ||
        _state.interestRate == null ||
        _state.termYears == null) {
      return;
    }

    final result = _coreCalculationService.calculatePayment(
      loanAmount: _state.loanAmount!,
      interestRate: _state.interestRate!,
      termYears: _state.termYears!,
      interestOnly: _state.isInterestOnly,
    );

    if (!result.isSuccess) {
      _state = _state.copyWith(calculationError: result.error);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      payment: result.value,
      clearCalculationError: true,
      presentedValue: result.value,
    );
    _unregisterManualInput(_ManualVar.payment);
    _historyController.addQuoteEntry(
      type: CalculationEntryType.payment,
      loanAmount: _state.loanAmount,
      interestRate: _state.interestRate,
      termYears: _state.termYears,
      payment: _state.payment,
      propertyTax: _state.propertyTax,
      homeInsurance: _state.homeInsurance,
      mortgageInsurance: _state.mortgageInsurance,
      monthlyExpenses: _state.monthlyExpenses,
      price: _state.price,
      downPayment: _state.downPayment,
    );
    notifyListeners();
  }

  void _calculateLoanAmount() {
    if (_state.payment == null ||
        _state.interestRate == null ||
        _state.termYears == null) {
      return;
    }

    final result = _coreCalculationService.calculateLoanAmount(
      payment: _state.payment!,
      interestRate: _state.interestRate!,
      termYears: _state.termYears!,
    );

    if (!result.isSuccess) {
      _state = _state.copyWith(calculationError: result.error);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      loanAmount: result.value,
      clearCalculationError: true,
      presentedValue: result.value,
    );
    _unregisterManualInput(_ManualVar.loanAmount);
    _historyController.addQuoteEntry(
      type: CalculationEntryType.loanAmount,
      loanAmount: _state.loanAmount,
      interestRate: _state.interestRate,
      termYears: _state.termYears,
      payment: _state.payment,
      propertyTax: _state.propertyTax,
      homeInsurance: _state.homeInsurance,
      mortgageInsurance: _state.mortgageInsurance,
      monthlyExpenses: _state.monthlyExpenses,
      price: _state.price,
      downPayment: _state.downPayment,
    );
    notifyListeners();
  }

  void _calculateTerm() {
    if (_state.loanAmount == null ||
        _state.payment == null ||
        _state.interestRate == null) {
      return;
    }

    final result = _coreCalculationService.calculateTerm(
      loanAmount: _state.loanAmount!,
      payment: _state.payment!,
      interestRate: _state.interestRate!,
    );

    if (!result.isSuccess) {
      _state = _state.copyWith(calculationError: result.error);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      termYears: result.value,
      clearCalculationError: true,
      presentedValue: result.value,
    );
    _unregisterManualInput(_ManualVar.termYears);
    _historyController.addQuoteEntry(
      type: CalculationEntryType.term,
      loanAmount: _state.loanAmount,
      interestRate: _state.interestRate,
      termYears: _state.termYears,
      payment: _state.payment,
      propertyTax: _state.propertyTax,
      homeInsurance: _state.homeInsurance,
      mortgageInsurance: _state.mortgageInsurance,
      monthlyExpenses: _state.monthlyExpenses,
      price: _state.price,
      downPayment: _state.downPayment,
    );
    notifyListeners();
  }

  void _calculateInterestRate() {
    if (_state.loanAmount == null ||
        _state.payment == null ||
        _state.termYears == null) {
      return;
    }

    final result = _coreCalculationService.solveInterestRate(
      loanAmount: _state.loanAmount!,
      payment: _state.payment!,
      termYears: _state.termYears!,
    );

    if (!result.isSuccess) {
      _state = _state.copyWith(calculationError: result.error);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      interestRate: result.value,
      clearCalculationError: true,
      presentedValue: result.value,
    );
    _unregisterManualInput(_ManualVar.interestRate);
    _historyController.addQuoteEntry(
      type: CalculationEntryType.interestRate,
      loanAmount: _state.loanAmount,
      interestRate: _state.interestRate,
      termYears: _state.termYears,
      payment: _state.payment,
      propertyTax: _state.propertyTax,
      homeInsurance: _state.homeInsurance,
      mortgageInsurance: _state.mortgageInsurance,
      monthlyExpenses: _state.monthlyExpenses,
      price: _state.price,
      downPayment: _state.downPayment,
    );
    notifyListeners();
  }

}
