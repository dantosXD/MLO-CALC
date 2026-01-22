import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_history.dart';
import '../services/nlp_calculator_service.dart';
import '../utils/advanced_calculations.dart';
import '../validators/financial_validators.dart';

// Model classes for structured data
class QualifyingRatio {
  final double housingRatio;
  final double debtRatio;

  QualifyingRatio({required this.housingRatio, required this.debtRatio});
}

class AmortizationEntry {
  final int month;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  AmortizationEntry({
    required this.month,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

enum _ManualVar { loanAmount, interestRate, termYears, payment }

class CalculatorProvider with ChangeNotifier {
  static const Object _noValue = Object();

  CalculatorProvider() {
    _loadState();
  }

  // Primary Loan Variables
  String _displayValue = '0';
  double? _loanAmount;
  double? _interestRate;
  double? _termYears;
  double? _payment;

  // Secondary & PITI Variables
  double? _price;
  double? _downPayment;
  double? _propertyTax; // Annual amount
  double? _homeInsurance; // Annual amount
  double? _mortgageInsurance; // Annual amount
  double? _monthlyExpenses; // Monthly amount (HOA, etc.)

  // Qualification Variables
  QualifyingRatio _qualRatio1 = QualifyingRatio(
    housingRatio: 28,
    debtRatio: 36,
  );
  QualifyingRatio _qualRatio2 = QualifyingRatio(
    housingRatio: 29,
    debtRatio: 41,
  );
  double? _annualIncome;
  double? _monthlyDebt;

  // Operational State
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  String _displayMode = 'pi'; // 'pi' or 'piti'
  List<AmortizationEntry> _amortizationData = [];
  bool _isComputingAmortization = false;
  String? _inputError;

  // Advanced features
  double? _futureValue;
  final CalculationHistory _history = CalculationHistory();
  Timer? _saveTimer;

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  final Set<_ManualVar> _manualVariables = <_ManualVar>{};
  final List<_ManualVar> _manualInputOrder = <_ManualVar>[];

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
  // Placeholder for future features
  // double? _loanFees;
  // double? _armRateChange;
  // double? _armTermYears;
  // double? _armLifetimeCap;

  // Getters - Primary Loan Variables
  String get displayValue => _displayValue;
  double? get loanAmount => _loanAmount;
  double? get interestRate => _interestRate;
  double? get termYears => _termYears;
  double? get payment => _payment;

  // Getters - PITI Variables
  double? get price => _price;
  double? get downPayment => _downPayment;
  double? get propertyTax => _propertyTax;
  double? get homeInsurance => _homeInsurance;
  double? get mortgageInsurance => _mortgageInsurance;
  double? get monthlyExpenses => _monthlyExpenses;

  // Getters - Qualification
  QualifyingRatio get qualRatio1 => _qualRatio1;
  QualifyingRatio get qualRatio2 => _qualRatio2;
  double? get annualIncome => _annualIncome;
  double? get monthlyDebt => _monthlyDebt;

  // Getters - Operational
  String get displayMode => _displayMode;
  List<AmortizationEntry> get amortizationData => _amortizationData;
  bool get isComputingAmortization => _isComputingAmortization;
  double? get futureValue => _futureValue;
  CalculationHistory get history => _history;
  String? get inputError => _inputError;

  // Computed values
  double get pitiPayment {
    if (_payment == null) return 0;
    double piti = _payment!;
    if (_propertyTax != null) piti += _propertyTax! / 12;
    if (_homeInsurance != null) piti += _homeInsurance! / 12;
    if (_mortgageInsurance != null) piti += _mortgageInsurance! / 12;
    if (_monthlyExpenses != null) piti += _monthlyExpenses!;
    return piti;
  }

  double get interestOnlyPayment {
    if (_loanAmount == null || _interestRate == null) return 0;
    final double r = _interestRate! / 100 / 12;
    return _loanAmount! * r;
  }

  // Toggle between P&I and PITI display
  void togglePitiDisplay() {
    if (_payment == null) return;

    if (_displayMode == 'pi') {
      _displayMode = 'piti';
      _displayValue = pitiPayment.toStringAsFixed(2);
    } else {
      _displayMode = 'pi';
      _displayValue = _payment!.toStringAsFixed(2);
    }
    notifyListeners();
  }

  // Auto-calculate loan amount from price and down payment
  void _calculateLoanAmountFromPrice() {
    if (_price == null || _downPayment == null) return;

    // Heuristic: values under 100 are percentages, otherwise flat amounts
    double downPaymentAmount;
    if (_downPayment! < 100) {
      // Treat as percentage
      downPaymentAmount = _price! * (_downPayment! / 100);
    } else {
      // Treat as flat amount
      downPaymentAmount = _downPayment!;
    }

    _loanAmount = _price! - downPaymentAmount;
    _unregisterManualInput(_ManualVar.loanAmount);
    _displayValue = _loanAmount!.toStringAsFixed(2);
    calculate();
  }

  // Financial Setters
  void setLoanAmount({double? value}) {
    final double? parsedValue = value ?? double.tryParse(_displayValue);
    
    if (parsedValue != null) {
      final validation = FinancialValidators.validateLoanAmount(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    if (parsedValue == null) {
      _loanAmount = null;
      _unregisterManualInput(_ManualVar.loanAmount);
    } else {
      _loanAmount = parsedValue;
      _registerManualInput(_ManualVar.loanAmount);
    }
    if (!_manualVariables.contains(_ManualVar.payment)) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    }
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  void setInterestRate() {
    final double? parsedValue = double.tryParse(_displayValue);

    if (parsedValue != null) {
      final validation = FinancialValidators.validateInterestRate(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        _displayValue = 'Error';
        _shouldResetDisplay = true;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    if (parsedValue == null) {
      _interestRate = null;
      _unregisterManualInput(_ManualVar.interestRate);
    } else {
      _interestRate = parsedValue;
      _registerManualInput(_ManualVar.interestRate);
    }
    if (!_manualVariables.contains(_ManualVar.payment)) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    }
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  void setTermYears() {
    final double? parsedValue = double.tryParse(_displayValue);

    if (parsedValue != null) {
      final validation = FinancialValidators.validateTermYears(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        _displayValue = 'Error';
        _shouldResetDisplay = true;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    if (parsedValue == null) {
      _termYears = null;
      _unregisterManualInput(_ManualVar.termYears);
    } else {
      _termYears = parsedValue;
      _registerManualInput(_ManualVar.termYears);
    }
    if (!_manualVariables.contains(_ManualVar.payment)) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    }
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  void setPayment() {
    if (_payment != null && !_manualVariables.contains(_ManualVar.payment)) {
      final bool hasPiti =
          (_propertyTax != null ||
          _homeInsurance != null ||
          _mortgageInsurance != null ||
          _monthlyExpenses != null);
      if (_displayMode == 'pi') {
        if (hasPiti) {
          togglePitiDisplay();
          return;
        } else if (_loanAmount != null && _interestRate != null) {
          _displayMode = 'io';
          _displayValue = interestOnlyPayment.toStringAsFixed(2);
          notifyListeners();
          return;
        }
      } else if (_displayMode == 'piti') {
        if (_loanAmount != null && _interestRate != null) {
          _displayMode = 'io';
          _displayValue = interestOnlyPayment.toStringAsFixed(2);
          notifyListeners();
          return;
        } else {
          _displayMode = 'pi';
          _displayValue = _payment!.toStringAsFixed(2);
          notifyListeners();
          return;
        }
      } else if (_displayMode == 'io') {
        _displayMode = 'pi';
        _displayValue = _payment!.toStringAsFixed(2);
        notifyListeners();
        return;
      }
    }
    final double? parsedValue = double.tryParse(_displayValue);

    if (parsedValue != null) {
      final validation = FinancialValidators.validatePayment(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    if (parsedValue == null) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    } else {
      _payment = parsedValue;
      _registerManualInput(_ManualVar.payment);
      _displayMode = 'pi';
    }
    if (!_manualVariables.contains(_ManualVar.loanAmount)) {
      _loanAmount = null;
      _unregisterManualInput(_ManualVar.loanAmount);
    }
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  // PITI Setters
  void setPrice() {
    final double? parsedValue = double.tryParse(_displayValue);
    if (parsedValue != null) {
      final validation = FinancialValidators.validatePrice(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _price = parsedValue;
    _shouldResetDisplay = true;
    _calculateLoanAmountFromPrice();
    _saveState();
    notifyListeners();
  }

  void setDownPayment() {
    final double? parsedValue = double.tryParse(_displayValue);
    if (parsedValue != null) {
      final validation = FinancialValidators.validateDownPayment(parsedValue, _price);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _downPayment = parsedValue;
    _shouldResetDisplay = true;
    _calculateLoanAmountFromPrice();
    _saveState();
    notifyListeners();
  }

  void setPropertyTax() {
    final double? parsedValue = double.tryParse(_displayValue);
    if (parsedValue != null) {
      final validation = FinancialValidators.validatePropertyTax(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _propertyTax = parsedValue;
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  void setHomeInsurance() {
    final double? parsedValue = double.tryParse(_displayValue);
    if (parsedValue != null) {
      final validation = FinancialValidators.validateInsurance(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _homeInsurance = parsedValue;
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  void setMortgageInsurance() {
    final double? parsedValue = double.tryParse(_displayValue);
    // No specific validator for MI, assume same as insurance
    if (parsedValue != null && parsedValue < 0) {
       _inputError = "Mortgage Insurance cannot be negative";
        notifyListeners();
        return;
    }
    _inputError = null;

    _mortgageInsurance = parsedValue;
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  void setMonthlyExpenses() {
    final double? parsedValue = double.tryParse(_displayValue);
    if (parsedValue != null) {
      final validation = FinancialValidators.validateMonthlyExpenses(parsedValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _monthlyExpenses = parsedValue;
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  // Qualification Setters
  void setAnnualIncome({Object? value = _noValue}) {
    double? incomeValue;
    bool shouldReset;

    if (!identical(value, _noValue)) {
      if (value is num) {
        incomeValue = value.toDouble();
      } else {
        incomeValue = value as double?;
      }
      shouldReset = false;
    } else {
      incomeValue = double.tryParse(_displayValue);
      shouldReset = true;
    }

    if (incomeValue != null) {
      final validation = FinancialValidators.validateAnnualIncome(incomeValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _annualIncome = incomeValue;
    _shouldResetDisplay = shouldReset;
    _saveState();
    notifyListeners();
  }

  void setMonthlyDebt({Object? value = _noValue}) {
    double? debtValue;
    bool shouldReset;

    if (!identical(value, _noValue)) {
      if (value is num) {
        debtValue = value.toDouble();
      } else {
        debtValue = value as double?;
      }
      shouldReset = false;
    } else {
      debtValue = double.tryParse(_displayValue);
      shouldReset = true;
    }

    if (debtValue != null) {
      final validation = FinancialValidators.validateMonthlyDebt(debtValue);
      if (!validation.isValid) {
        _inputError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _inputError = null;

    _monthlyDebt = debtValue;
    _shouldResetDisplay = shouldReset;
    _saveState();
    notifyListeners();
  }

  void setQualRatio1(double housingRatio, double debtRatio) {
    _qualRatio1 = QualifyingRatio(
      housingRatio: housingRatio,
      debtRatio: debtRatio,
    );
    notifyListeners();
  }

  void setQualRatio2(double housingRatio, double debtRatio) {
    _qualRatio2 = QualifyingRatio(
      housingRatio: housingRatio,
      debtRatio: debtRatio,
    );
    notifyListeners();
  }

  // Arithmetic Operations
  void performOperation(String op) {
    // When an arithmetic operation starts, clear financial context.
    _loanAmount = null;
    _interestRate = null;
    _termYears = null;
    _payment = null;
    _manualVariables.clear();
    _manualInputOrder.clear();

    // Handle chained operations like 5 * 2 +
    if (_operator != null && !_shouldResetDisplay) {
      calculateResult();
    }

    _firstOperand = double.tryParse(_displayValue);
    _operator = op;
    _shouldResetDisplay = true;
  }

  void calculateResult() {
    if (_operator == null || _firstOperand == null) {
      return;
    }

    final double secondOperand = double.tryParse(_displayValue) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case 'x':
        result = _firstOperand! * secondOperand;
        break;
      case '/':
        if (secondOperand != 0) {
          result = _firstOperand! / secondOperand;
        } else {
          _displayValue = 'Error';
          _resetArithmeticState();
          notifyListeners();
          return;
        }
        break;
    }

    _displayValue = _formatResult(result);
    _resetArithmeticState();
    _shouldResetDisplay = true;
    notifyListeners();
  }

  String _formatResult(double result) {
    // If the result is an integer, display it without decimals.
    if (result.truncateToDouble() == result) {
      return result.toInt().toString();
    } else {
      // Otherwise, format to a reasonable number of decimal places.
      return result
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

  void _resetArithmeticState() {
    _operator = null;
    _firstOperand = null;
  }

  void inputDigit(String digit) {
    if (_shouldResetDisplay) {
      _displayValue = digit;
      _shouldResetDisplay = false;
    } else if (_displayValue == '0') {
      // Avoids things like '07'
      if (digit == '0') return;
      _displayValue = digit;
    } else {
      // Add a limit to input length? Maybe later.
      _displayValue += digit;
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_shouldResetDisplay) {
      _displayValue = '0.';
      _shouldResetDisplay = false;
      return;
    }
    if (!_displayValue.contains('.')) {
      _displayValue += '.';
    }
    notifyListeners();
  }

  void backspace() {
    if (_displayValue.length > 1) {
      _displayValue = _displayValue.substring(0, _displayValue.length - 1);
    } else {
      _displayValue = '0';
    }
    notifyListeners();
  }

  void clear() {
    _displayValue = '0';
    _shouldResetDisplay = false;
    notifyListeners();
  }

  void clearAll() {
    _displayValue = '0';
    _loanAmount = null;
    _interestRate = null;
    _termYears = null;
    _payment = null;
    _price = null;
    _downPayment = null;
    _propertyTax = null;
    _homeInsurance = null;
    _mortgageInsurance = null;
    _monthlyExpenses = null;
    _annualIncome = null;
    _monthlyDebt = null;
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
    _displayMode = 'pi';
    _amortizationData = [];
    _futureValue = null;
    _inputError = null;
    _manualVariables.clear();
    _manualInputOrder.clear();
    _saveState();
    notifyListeners();
  }

  /// Apply a parsed Gemini request into calculator state and run the requested action.
  Future<String> applyNlpRequest(CalculationRequest request) async {
    // Only update if value is provided (allows for context preservation)
    void assignLoanAmount(double? value) {
      if (value != null) {
        _loanAmount = value;
        _registerManualInput(_ManualVar.loanAmount);
      }
    }

    void assignInterestRate(double? value) {
      if (value != null) {
        _interestRate = value;
        _registerManualInput(_ManualVar.interestRate);
      }
    }

    void assignTermYears(double? value) {
      if (value != null) {
        _termYears = value;
        _registerManualInput(_ManualVar.termYears);
      }
    }

    void assignPayment(double? value) {
      if (value != null) {
        _payment = value;
        _registerManualInput(_ManualVar.payment);
      }
    }

    String message = request.explanation;

    switch (request.action) {
      case 'calculate_payment':
        assignLoanAmount(request.loanAmount);
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        
        // Clear target to force calculation
        _payment = null;
        _unregisterManualInput(_ManualVar.payment);
        
        calculate();
        message = (_payment != null)
            ? 'Payment: ${_payment!.toStringAsFixed(2)}'
            : 'Need loan amount, interest rate, and term to calculate payment.';
        break;
      case 'calculate_loan_amount':
        assignPayment(request.payment);
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        
        _loanAmount = null;
        _unregisterManualInput(_ManualVar.loanAmount);
        
        calculate();
        message = (_loanAmount != null)
            ? 'Loan amount: ${_loanAmount!.toStringAsFixed(2)}'
            : 'Need payment, interest rate, and term to calculate loan amount.';
        break;
      case 'calculate_term':
        assignLoanAmount(request.loanAmount);
        assignInterestRate(request.interestRate);
        assignPayment(request.payment);
        
        _termYears = null;
        _unregisterManualInput(_ManualVar.termYears);
        
        calculate();
        message = (_termYears != null)
            ? 'Term: ${_termYears!.toStringAsFixed(2)} years'
            : 'Need loan amount, rate, and payment to calculate term.';
        break;
      case 'calculate_interest_rate':
        assignLoanAmount(request.loanAmount);
        assignPayment(request.payment);
        assignTermYears(request.termYears);
        
        _interestRate = null;
        _unregisterManualInput(_ManualVar.interestRate);
        
        calculate();
        message = (_interestRate != null)
            ? 'Interest rate: ${_interestRate!.toStringAsFixed(3)}%'
            : 'Need loan amount, payment, and term to calculate interest rate.';
        break;
      case 'calculate_max_qualifying_loan':
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        if (request.annualIncome != null) _annualIncome = request.annualIncome;
        if (request.monthlyDebt != null) _monthlyDebt = request.monthlyDebt;
        if (request.propertyTax != null) _propertyTax = request.propertyTax;
        if (request.homeInsurance != null) _homeInsurance = request.homeInsurance;
        if (request.mortgageInsurance != null) _mortgageInsurance = request.mortgageInsurance;
        if (request.monthlyExpenses != null) _monthlyExpenses = request.monthlyExpenses;
        
        _payment = null;
        _loanAmount = null; // Target
        
        if (_interestRate != null &&
            _termYears != null &&
            _annualIncome != null) {
          calculateMaxQualifyingLoan();
          message = (_loanAmount != null)
              ? 'Max loan: ${_loanAmount!.toStringAsFixed(2)}'
              : 'Unable to calculate max qualifying loan with provided info.';
        } else {
          message =
              'Need income, rate, and term to calculate max qualifying loan.';
        }
        break;
      case 'calculate_min_income':
        assignLoanAmount(request.loanAmount);
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        if (request.propertyTax != null) _propertyTax = request.propertyTax;
        if (request.homeInsurance != null) _homeInsurance = request.homeInsurance;
        if (request.mortgageInsurance != null) _mortgageInsurance = request.mortgageInsurance;
        if (request.monthlyExpenses != null) _monthlyExpenses = request.monthlyExpenses;
        if (request.monthlyDebt != null) _monthlyDebt = request.monthlyDebt;
        
        if (_loanAmount != null &&
            _interestRate != null &&
            _termYears != null) {
          calculateMinimumIncome();
          message = (_annualIncome != null)
              ? 'Required income: ${_annualIncome!.toStringAsFixed(2)}'
              : 'Unable to calculate minimum income.';
        } else {
          message =
              'Need loan amount, rate, and term to calculate minimum income.';
        }
        break;
      case 'generate_amortization':
        assignLoanAmount(request.loanAmount);
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        if (_loanAmount != null &&
            _interestRate != null &&
            _termYears != null) {
          if (_payment == null) _calculatePayment();
          generateAmortizationSchedule();
          message = 'Generated amortization schedule.';
        } else {
          message = 'Need loan amount, rate, and term to build schedule.';
        }
        break;
      case 'calculate_biweekly':
        assignLoanAmount(request.loanAmount);
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        if (_loanAmount != null &&
            _interestRate != null &&
            _termYears != null) {
          if (_payment == null) _calculatePayment();
          final result = calculateBiWeeklyConversion();
          if (result.isNotEmpty) {
            message =
                'Bi-weekly payment: ${result['biWeeklyPayment']?.toStringAsFixed(2)}, new term: ${result['newTermYears']?.toStringAsFixed(2)} yrs, interest saved: ${result['interestSaved']?.toStringAsFixed(2)}';
          } else {
            message = 'Unable to calculate bi-weekly conversion.';
          }
        } else {
          message =
              'Need loan amount, rate, and term to compare bi-weekly payments.';
        }
        break;
      default:
        // Fallback: just set whatever values we can and recalc.
        assignLoanAmount(request.loanAmount);
        assignInterestRate(request.interestRate);
        assignTermYears(request.termYears);
        assignPayment(request.payment);
        if (request.propertyTax != null) {
          _propertyTax = request.propertyTax;
        }
        if (request.homeInsurance != null) {
          _homeInsurance = request.homeInsurance;
        }
        if (request.mortgageInsurance != null) {
          _mortgageInsurance = request.mortgageInsurance;
        }
        if (request.monthlyExpenses != null) {
          _monthlyExpenses = request.monthlyExpenses;
        }
        if (request.annualIncome != null) {
          _annualIncome = request.annualIncome;
        }
        if (request.monthlyDebt != null) {
          _monthlyDebt = request.monthlyDebt;
        }
        if (request.price != null) {
          _price = request.price;
        }
        if (request.downPayment != null) {
          _downPayment = request.downPayment;
        }
        calculate();
        message = request.explanation;
    }

    await _saveState();
    notifyListeners();
    return message;
  }

  // State persistence
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _loanAmount = prefs.getDouble('loanAmount');
      _interestRate = prefs.getDouble('interestRate');
      _termYears = prefs.getDouble('termYears');
      _payment = prefs.getDouble('payment');
      _price = prefs.getDouble('price');
      _downPayment = prefs.getDouble('downPayment');
      _propertyTax = prefs.getDouble('propertyTax');
      _homeInsurance = prefs.getDouble('homeInsurance');
      _mortgageInsurance = prefs.getDouble('mortgageInsurance');
      _monthlyExpenses = prefs.getDouble('monthlyExpenses');
      _annualIncome = prefs.getDouble('annualIncome');
      _monthlyDebt = prefs.getDouble('monthlyDebt');

      final historyJson = prefs.getString('calculationHistory');
      if (historyJson != null && historyJson.isNotEmpty) {
        _history.fromJsonString(historyJson);
      }

      // Update display if we have a payment
      if (_payment != null) {
        _displayValue = _payment!.toStringAsFixed(2);
      } else if (_loanAmount != null) {
        _displayValue = _loanAmount!.toStringAsFixed(2);
      }

      notifyListeners();
    } catch (e) {
      // Ignore errors during load
    }
  }

  Future<void> _saveState() async {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final prefs = await SharedPreferences.getInstance();

        if (_loanAmount != null) {
          await prefs.setDouble('loanAmount', _loanAmount!);
        } else {
          await prefs.remove('loanAmount');
        }

        if (_interestRate != null) {
          await prefs.setDouble('interestRate', _interestRate!);
        } else {
          await prefs.remove('interestRate');
        }

        if (_termYears != null) {
          await prefs.setDouble('termYears', _termYears!);
        } else {
          await prefs.remove('termYears');
        }

        if (_payment != null) {
          await prefs.setDouble('payment', _payment!);
        } else {
          await prefs.remove('payment');
        }

        if (_price != null) {
          await prefs.setDouble('price', _price!);
        } else {
          await prefs.remove('price');
        }

        if (_downPayment != null) {
          await prefs.setDouble('downPayment', _downPayment!);
        } else {
          await prefs.remove('downPayment');
        }

        if (_propertyTax != null) {
          await prefs.setDouble('propertyTax', _propertyTax!);
        } else {
          await prefs.remove('propertyTax');
        }

        if (_homeInsurance != null) {
          await prefs.setDouble('homeInsurance', _homeInsurance!);
        } else {
          await prefs.remove('homeInsurance');
        }

        if (_mortgageInsurance != null) {
          await prefs.setDouble('mortgageInsurance', _mortgageInsurance!);
        } else {
          await prefs.remove('mortgageInsurance');
        }

        if (_monthlyExpenses != null) {
          await prefs.setDouble('monthlyExpenses', _monthlyExpenses!);
        } else {
          await prefs.remove('monthlyExpenses');
        }

        if (_annualIncome != null) {
          await prefs.setDouble('annualIncome', _annualIncome!);
        } else {
          await prefs.remove('annualIncome');
        }

        if (_monthlyDebt != null) {
          await prefs.setDouble('monthlyDebt', _monthlyDebt!);
        } else {
          await prefs.remove('monthlyDebt');
        }

        await prefs.setString('calculationHistory', _history.toJsonString());
      } catch (e) {
        // Ignore errors during save
      }
    });
  }

  // Financial Calculations
  void calculate() {
    if (_manualInputOrder.length == 3) {
      final Set<_ManualVar> provided = _manualInputOrder.toSet();
      _ManualVar? target;
      for (final _ManualVar candidate in _ManualVar.values) {
        if (!provided.contains(candidate)) {
          target = candidate;
          break;
        }
      }
      if (target != null) {
        switch (target) {
          case _ManualVar.payment:
            if (_loanAmount != null &&
                _interestRate != null &&
                _termYears != null) {
              _calculatePayment();
              return;
            }
            break;
          case _ManualVar.loanAmount:
            if (_payment != null &&
                _interestRate != null &&
                _termYears != null) {
              _calculateLoanAmount();
              return;
            }
            break;
          case _ManualVar.interestRate:
            if (_loanAmount != null && _payment != null && _termYears != null) {
              _calculateInterestRate();
              return;
            }
            break;
          case _ManualVar.termYears:
            if (_loanAmount != null &&
                _interestRate != null &&
                _payment != null) {
              _calculateTerm();
              return;
            }
            break;
        }
      }
    }

    if (_loanAmount != null &&
        _interestRate != null &&
        _termYears != null &&
        _payment == null) {
      _calculatePayment();
    } else if (_payment != null &&
        _interestRate != null &&
        _termYears != null &&
        _loanAmount == null) {
      _calculateLoanAmount();
    } else if (_loanAmount != null &&
        _payment != null &&
        _termYears != null &&
        _interestRate == null) {
      _calculateInterestRate();
    } else if (_loanAmount != null &&
        _interestRate != null &&
        _payment != null &&
        _termYears == null) {
      _calculateTerm();
    }
  }

  void _calculatePayment() {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      return;
    }

    final result = LoanMath.calculatePayment(
      loanAmount: _loanAmount!,
      interestRate: _interestRate!,
      termYears: _termYears!,
    );

    if (result <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }

    _payment = result;
    _unregisterManualInput(_ManualVar.payment);
    _displayMode = 'pi';
    _displayValue = _payment!.toStringAsFixed(2);
    _history.addEntry(
      CalculationEntry.fromLoanCalculation(
        type: 'payment',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
      ),
    );
    _saveState();
    notifyListeners();
  }

  void _calculateLoanAmount() {
    if (_payment == null || _interestRate == null || _termYears == null) {
      return;
    }

    final result = LoanMath.calculateLoanAmount(
      payment: _payment!,
      interestRate: _interestRate!,
      termYears: _termYears!,
    );

    if (result <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }

    _loanAmount = result;
    _unregisterManualInput(_ManualVar.loanAmount);
    _displayValue = _loanAmount!.toStringAsFixed(2);
    _history.addEntry(
      CalculationEntry.fromLoanCalculation(
        type: 'loan_amount',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
      ),
    );
    _saveState();
    notifyListeners();
  }

  void _calculateTerm() {
    if (_loanAmount == null || _payment == null || _interestRate == null) {
      return;
    }

    final result = LoanMath.calculateTerm(
      loanAmount: _loanAmount!,
      payment: _payment!,
      interestRate: _interestRate!,
    );

    if (result <= 0) {
      _displayValue = 'Error';
    } else {
      _termYears = result;
      _unregisterManualInput(_ManualVar.termYears);
      _displayValue = _termYears!.toStringAsFixed(2);
      _history.addEntry(
        CalculationEntry.fromLoanCalculation(
          type: 'term',
          loanAmount: _loanAmount,
          interestRate: _interestRate,
          termYears: _termYears,
          payment: _payment,
          propertyTax: _propertyTax,
          homeInsurance: _homeInsurance,
          mortgageInsurance: _mortgageInsurance,
          monthlyExpenses: _monthlyExpenses,
        ),
      );
      _saveState();
    }
    notifyListeners();
  }

  void _calculateInterestRate() {
    if (_loanAmount == null || _payment == null || _termYears == null) {
      return;
    }

    final result = LoanMath.calculateInterestRate(
      loanAmount: _loanAmount!,
      payment: _payment!,
      termYears: _termYears!,
    );

    if (result <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }

    _interestRate = result;
    _unregisterManualInput(_ManualVar.interestRate);
    _displayValue = _interestRate!.toStringAsFixed(3);
    _history.addEntry(
      CalculationEntry.fromLoanCalculation(
        type: 'interest_rate',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
      ),
    );
    _saveState();
    notifyListeners();
  }

  // Schedule and conversions
  Future<void> generateAmortizationSchedule() async {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      return;
    }

    _isComputingAmortization = true;
    notifyListeners();

    // Yield to allow UI to show loading indicator
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      _amortizationData = [];
      final double r = _interestRate! / 100 / 12;
      final int n = (_termYears! * 12).round();

      if (_payment == null) {
        _calculatePayment();
      }

      if (_payment == null) return;

      double currentBalance = _loanAmount!;
      final double monthlyPayment = _payment!;

      // In a real compute() isolate, this would be separate.
      // For now, we just do it here.
      for (int month = 1; month <= n; month++) {
        final double interestPaid = currentBalance * r;
        double principalPaid = monthlyPayment - interestPaid;

        if (month == n) {
          principalPaid = currentBalance;
        }

        final double newBalance = currentBalance - principalPaid;

        _amortizationData.add(
          AmortizationEntry(
            month: month,
            payment: principalPaid + interestPaid,
            principal: principalPaid,
            interest: interestPaid,
            balance: newBalance > 0.01 ? newBalance : 0,
          ),
        );
        currentBalance = newBalance;
        
        // Yield every 60 calculations to keep UI responsive if it's huge
        if (month % 60 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    } finally {
      _isComputingAmortization = false;
      notifyListeners();
    }
  }

  double calculateRemainingBalance(double years) {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      return 0;
    }

    final double r = _interestRate! / 100 / 12;
    final int months = (years * 12).round();

    if (_payment == null) {
      _calculatePayment();
    }

    // Safety check: if payment is still null (calculation failed), return 0
    if (_payment == null) return 0;

    double currentBalance = _loanAmount!;
    final double monthlyPayment = _payment!;

    for (int month = 1; month <= months; month++) {
      final double interestPaid = currentBalance * r;
      final double principalPaid = monthlyPayment - interestPaid;
      currentBalance -= principalPaid;
    }

    return currentBalance > 0 ? currentBalance : 0;
  }

  Map<String, double> calculateBiWeeklyConversion() {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      return {};
    }

    if (_payment == null) {
      _calculatePayment();
      if (_payment == null) {
        return {};
      }
    }

    final double r =
        _interestRate! / 100 / 26; // Bi-weekly rate (26 periods/year)
    final double biWeeklyPayment = _payment! / 2;

    double currentBalance = _loanAmount!;
    int periods = 0;
    double totalInterest = 0;

    while (currentBalance > 0 && periods < 1000) {
      // Max 1000 periods safety
      final double interestPaid = currentBalance * r;
      final double principalPaid = biWeeklyPayment - interestPaid;

      if (principalPaid <= 0) break;

      currentBalance -= principalPaid;
      totalInterest += interestPaid;
      periods++;
    }

    final double newTermYears = periods / 26;

    final int originalMonths = (_termYears! * 12).round();
    final double originalTotalInterest =
        (_payment! * originalMonths) - _loanAmount!;
    final double interestSaved = originalTotalInterest - totalInterest;

    return {
      'biWeeklyPayment': biWeeklyPayment,
      'newTermYears': newTermYears,
      'totalInterest': totalInterest,
      'interestSaved': interestSaved,
    };
  }

  void calculateMaxQualifyingLoan({bool useRatio1 = true}) {
    // ...
    final QualifyingRatio ratio = useRatio1 ? _qualRatio1 : _qualRatio2;
    final double monthlyIncome = _annualIncome! / 12;
    final double monthlyDebtPayment = _monthlyDebt ?? 0;

    // Calculate max PITI from front-end ratio (housing expense ratio)
    final double maxPitiFromHousing =
        monthlyIncome * (ratio.housingRatio / 100);

    // Calculate max PITI from back-end ratio (total debt ratio)
    final double maxTotalDebt = monthlyIncome * (ratio.debtRatio / 100);
    final double maxPitiFromDebt = maxTotalDebt - monthlyDebtPayment;

    // Use the more restrictive (lower) limit
    final double maxPiti = min(maxPitiFromHousing, maxPitiFromDebt);

    // Calculate monthly expenses portion (taxes, insurance, etc.)
    double monthlyPITIExpenses = 0;
    if (_propertyTax != null) monthlyPITIExpenses += _propertyTax! / 12;
    if (_homeInsurance != null) monthlyPITIExpenses += _homeInsurance! / 12;
    if (_mortgageInsurance != null) {
      monthlyPITIExpenses += _mortgageInsurance! / 12;
    }
    if (_monthlyExpenses != null) monthlyPITIExpenses += _monthlyExpenses!;

    // Max P&I payment available
    final double maxPI = maxPiti - monthlyPITIExpenses;

    if (maxPI <= 0) {
      _displayValue = 'Insufficient Income';
      notifyListeners();
      return;
    }

    // Calculate loan amount from max P&I payment
    final double r = _interestRate! / 100 / 12;
    final double n = _termYears! * 12;

    if (r <= 0 || n <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }

    _loanAmount = maxPI * (pow(1 + r, n) - 1) / (r * pow(1 + r, n));
    _payment = maxPI;
    _unregisterManualInput(_ManualVar.loanAmount);
    _unregisterManualInput(_ManualVar.payment);
    _displayMode = 'pi';
    _displayValue = _loanAmount!.toStringAsFixed(2);
    _history.addEntry(
      CalculationEntry.fromQualification(
        annualIncome: _annualIncome!,
        monthlyDebt: _monthlyDebt ?? 0,
        interestRate: _interestRate!,
        termYears: _termYears!,
        maxLoanAmount: _loanAmount!,
      ),
    );
    _saveState();
    notifyListeners();
  }

  void applyHistoryEntry(CalculationEntry entry) {
    try {
      final inputs = entry.inputs;
      final results = entry.results;
      _loanAmount = _toDouble(inputs['loanAmount']);
      _interestRate = _toDouble(inputs['interestRate']);
      _termYears = _toDouble(inputs['termYears']);
      _payment = _toDouble(results['payment']);
      _propertyTax = _toDouble(inputs['propertyTax']);
      _homeInsurance = _toDouble(inputs['homeInsurance']);
      _mortgageInsurance = _toDouble(inputs['mortgageInsurance']);
      _monthlyExpenses = _toDouble(inputs['monthlyExpenses']);
      _displayMode = 'pi';
      if (_payment != null) {
        _displayValue = _payment!.toStringAsFixed(2);
      } else if (_loanAmount != null) {
        _displayValue = _loanAmount!.toStringAsFixed(2);
      } else {
        _displayValue = '0';
      }
      _manualVariables.clear();
      _manualInputOrder.clear();
      _saveState();
      notifyListeners();
    } catch (_) {}
  }

  void removeHistoryEntry(String id) {
    _history.removeEntry(id);
    _saveState();
    notifyListeners();
  }

  void clearHistory() {
    _history.clearAll();
    _saveState();
    notifyListeners();
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // Calculate minimum income required for loan
  void calculateMinimumIncome({bool useRatio1 = true}) {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      _displayValue = 'Need L/A, Rate, Term';
      notifyListeners();
      return;
    }

    // Calculate P&I payment if not already calculated
    if (_payment == null) {
      _calculatePayment();
    }

    final QualifyingRatio ratio = useRatio1 ? _qualRatio1 : _qualRatio2;
    final double monthlyDebtPayment = _monthlyDebt ?? 0;

    // Calculate total PITI
    final double totalPITI = pitiPayment;

    // Calculate minimum income from front-end ratio
    final double minIncomeFromHousing =
        (totalPITI / (ratio.housingRatio / 100)) * 12;

    // Calculate minimum income from back-end ratio
    final double totalDebt = totalPITI + monthlyDebtPayment;
    final double minIncomeFromDebt = (totalDebt / (ratio.debtRatio / 100)) * 12;

    // Use the more restrictive (higher) requirement
    _annualIncome = max(minIncomeFromHousing, minIncomeFromDebt);
    _displayValue = _annualIncome!.toStringAsFixed(2);
    notifyListeners();
  }
}
