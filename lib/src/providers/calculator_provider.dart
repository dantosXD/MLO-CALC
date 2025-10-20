import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

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
  QualifyingRatio _qualRatio1 = QualifyingRatio(housingRatio: 28, debtRatio: 36);
  QualifyingRatio _qualRatio2 = QualifyingRatio(housingRatio: 29, debtRatio: 41);
  double? _annualIncome;
  double? _monthlyDebt;

  // Operational State
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  String _displayMode = 'pi'; // 'pi' or 'piti'
  List<AmortizationEntry> _amortizationData = [];

  // Advanced features
  double? _futureValue;
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
  double? get futureValue => _futureValue;

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
    _displayValue = _loanAmount!.toStringAsFixed(2);
    calculate();
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

  void clear() {
    _displayValue = '0';
    _loanAmount = null;
    _interestRate = null;
    _termYears = null;
    _payment = null;
    _firstOperand = null;
    _operator = null;
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
    _saveState();
    notifyListeners();
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
    } catch (e) {
      // Ignore errors during save
    }
  }

  // Financial Setters
  void setLoanAmount({double? value}) {
    _loanAmount = value ?? double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  void setInterestRate() {
    _interestRate = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  void setTermYears() {
    _termYears = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  void setPayment() {
    // If payment is already calculated and we have PITI data, toggle display mode
    if (_payment != null && _displayMode == 'pi' && (_propertyTax != null || _homeInsurance != null || _mortgageInsurance != null || _monthlyExpenses != null)) {
      togglePitiDisplay();
      return;
    }
    _payment = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    calculate();
    _saveState();
    notifyListeners();
  }

  // PITI Setters
  void setPrice() {
    _price = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    _calculateLoanAmountFromPrice();
    _saveState();
    notifyListeners();
  }

  void setDownPayment() {
    _downPayment = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    _calculateLoanAmountFromPrice();
    _saveState();
    notifyListeners();
  }

  void setPropertyTax() {
    _propertyTax = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  void setHomeInsurance() {
    _homeInsurance = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  void setMortgageInsurance() {
    _mortgageInsurance = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  void setMonthlyExpenses() {
    _monthlyExpenses = double.tryParse(_displayValue);
    _shouldResetDisplay = true;
    _saveState();
    notifyListeners();
  }

  // Qualification Setters
  void setAnnualIncome({Object? value = _noValue}) {
    if (!identical(value, _noValue)) {
      _annualIncome = value as double?;
      _shouldResetDisplay = false;
    } else {
      _annualIncome = double.tryParse(_displayValue);
      _shouldResetDisplay = true;
    }
    _saveState();
    notifyListeners();
  }

  void setMonthlyDebt({Object? value = _noValue}) {
    if (!identical(value, _noValue)) {
      _monthlyDebt = value as double?;
      _shouldResetDisplay = false;
    } else {
      _monthlyDebt = double.tryParse(_displayValue);
      _shouldResetDisplay = true;
    }
    _saveState();
    notifyListeners();
  }

  void setQualRatio1(double housingRatio, double debtRatio) {
    _qualRatio1 = QualifyingRatio(housingRatio: housingRatio, debtRatio: debtRatio);
    notifyListeners();
  }

  void setQualRatio2(double housingRatio, double debtRatio) {
    _qualRatio2 = QualifyingRatio(housingRatio: housingRatio, debtRatio: debtRatio);
    notifyListeners();
  }

  // Arithmetic Operations
  void performOperation(String op) {
    // When an arithmetic operation starts, clear financial context.
    _loanAmount = null;
    _interestRate = null;
    _termYears = null;
    _payment = null;

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

  // Financial Calculations
  void calculate() {
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
    final double r = _interestRate! / 100 / 12;
    final double n = _termYears! * 12;
    if (r <= 0 || n <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }
    _payment = _loanAmount! * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    _displayValue = _payment!.toStringAsFixed(2);
    notifyListeners();
  }

  void _calculateLoanAmount() {
    final double r = _interestRate! / 100 / 12;
    final double n = _termYears! * 12;
    if (r <= 0 || n <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }
    _loanAmount = _payment! * (pow(1 + r, n) - 1) / (r * pow(1 + r, n));
    _displayValue = _loanAmount!.toStringAsFixed(2);
    notifyListeners();
  }

  void _calculateTerm() {
    final double r = _interestRate! / 100 / 12;
    final double p = _loanAmount!;
    final double m = _payment!;
    if (m <= 0 || r <= 0 || p * r >= m) {
      _displayValue = 'Error';
    } else {
      final double n = -log(1 - (p * r) / m) / log(1 + r);
      _termYears = n / 12;
      _displayValue = _termYears!.toStringAsFixed(2);
    }
    notifyListeners();
  }

  // Calculate Interest Rate using Newton's method
  void _calculateInterestRate() {
    final double p = _loanAmount!;
    final double m = _payment!;
    final double n = _termYears! * 12;

    // Validate inputs
    if (m <= 0 || p <= 0 || n <= 0) {
      _displayValue = 'Error';
      notifyListeners();
      return;
    }

    // Initial guess (annual rate as percentage)
    double rate = 5.0;
    const double tolerance = 0.0001;
    const int maxIterations = 100;

    for (int i = 0; i < maxIterations; i++) {
      final double r = rate / 100 / 12; // Monthly rate

      if (r <= -1) {
        // Invalid rate
        rate = 0.1;
        continue;
      }

      // Calculate f(r) = P*r*(1+r)^n - M*((1+r)^n - 1)
      final double factor = pow(1 + r, n).toDouble();
      final double f = p * r * factor - m * (factor - 1);

      // Calculate f'(r) - derivative
      final double df = p * (factor + r * n * factor / (1 + r)) - m * n * factor / (1 + r);

      if (df.abs() < 0.0000001) {
        // Derivative too small, can't continue
        break;
      }

      // Newton's method: r_new = r_old - f(r)/f'(r)
      final double rateChange = f / df;
      final double newMonthlyRate = r - rateChange;
      final double newAnnualRate = newMonthlyRate * 12 * 100;

      // Check convergence
      if ((newAnnualRate - rate).abs() < tolerance) {
        rate = newAnnualRate;
        break;
      }

      rate = newAnnualRate;

      // Safety checks
      if (rate < 0) rate = 0.1;
      if (rate > 100) rate = 50;
    }

    _interestRate = rate;
    _displayValue = _interestRate!.toStringAsFixed(3);
    notifyListeners();
  }

  // Generate amortization schedule
  void generateAmortizationSchedule() {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      return;
    }

    _amortizationData = [];
    final double r = _interestRate! / 100 / 12;
    final int n = (_termYears! * 12).round();

    if (_payment == null) {
      _calculatePayment();
    }

    double currentBalance = _loanAmount!;
    final double monthlyPayment = _payment!;

    for (int month = 1; month <= n; month++) {
      final double interestPaid = currentBalance * r;
      double principalPaid = monthlyPayment - interestPaid;

      // Adjust final payment to clear remaining balance
      if (month == n) {
        principalPaid = currentBalance;
      }

      final double newBalance = currentBalance - principalPaid;

      _amortizationData.add(AmortizationEntry(
        month: month,
        payment: principalPaid + interestPaid,
        principal: principalPaid,
        interest: interestPaid,
        balance: newBalance > 0 ? newBalance : 0,
      ));

      currentBalance = newBalance;
    }

    notifyListeners();
  }

  // Calculate remaining balance (balloon payment) after specified years
  double calculateRemainingBalance(double years) {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      return 0;
    }

    final double r = _interestRate! / 100 / 12;
    final int months = (years * 12).round();

    if (_payment == null) {
      _calculatePayment();
    }

    double currentBalance = _loanAmount!;
    final double monthlyPayment = _payment!;

    for (int month = 1; month <= months; month++) {
      final double interestPaid = currentBalance * r;
      final double principalPaid = monthlyPayment - interestPaid;
      currentBalance -= principalPaid;
    }

    return currentBalance > 0 ? currentBalance : 0;
  }

  // Calculate bi-weekly payment conversion
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

    final double r = _interestRate! / 100 / 26; // Bi-weekly rate (26 periods/year)
    final double biWeeklyPayment = _payment! / 2;

    // Calculate new term with bi-weekly payments
    double currentBalance = _loanAmount!;
    int periods = 0;
    double totalInterest = 0;

    while (currentBalance > 0 && periods < 1000) { // Max 1000 periods safety
      final double interestPaid = currentBalance * r;
      final double principalPaid = biWeeklyPayment - interestPaid;

      if (principalPaid <= 0) break;

      currentBalance -= principalPaid;
      totalInterest += interestPaid;
      periods++;
    }

    final double newTermYears = periods / 26;

    // Calculate original total interest
    final int originalMonths = (_termYears! * 12).round();
    final double originalTotalInterest = (_payment! * originalMonths) - _loanAmount!;
    final double interestSaved = originalTotalInterest - totalInterest;

    return {
      'biWeeklyPayment': biWeeklyPayment,
      'newTermYears': newTermYears,
      'totalInterest': totalInterest,
      'interestSaved': interestSaved,
    };
  }

  // Calculate maximum qualifying loan amount
  void calculateMaxQualifyingLoan({bool useRatio1 = true}) {
    if (_annualIncome == null || _interestRate == null || _termYears == null) {
      _displayValue = 'Need Income, Rate, Term';
      notifyListeners();
      return;
    }

    final QualifyingRatio ratio = useRatio1 ? _qualRatio1 : _qualRatio2;
    final double monthlyIncome = _annualIncome! / 12;
    final double monthlyDebtPayment = _monthlyDebt ?? 0;

    // Calculate max PITI from front-end ratio (housing expense ratio)
    final double maxPitiFromHousing = monthlyIncome * (ratio.housingRatio / 100);

    // Calculate max PITI from back-end ratio (total debt ratio)
    final double maxTotalDebt = monthlyIncome * (ratio.debtRatio / 100);
    final double maxPitiFromDebt = maxTotalDebt - monthlyDebtPayment;

    // Use the more restrictive (lower) limit
    final double maxPiti = min(maxPitiFromHousing, maxPitiFromDebt);

    // Calculate monthly expenses portion (taxes, insurance, etc.)
    double monthlyPITIExpenses = 0;
    if (_propertyTax != null) monthlyPITIExpenses += _propertyTax! / 12;
    if (_homeInsurance != null) monthlyPITIExpenses += _homeInsurance! / 12;
    if (_mortgageInsurance != null) monthlyPITIExpenses += _mortgageInsurance! / 12;
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
    _displayValue = _loanAmount!.toStringAsFixed(2);
    notifyListeners();
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
    final double minIncomeFromHousing = (totalPITI / (ratio.housingRatio / 100)) * 12;

    // Calculate minimum income from back-end ratio
    final double totalDebt = totalPITI + monthlyDebtPayment;
    final double minIncomeFromDebt = (totalDebt / (ratio.debtRatio / 100)) * 12;

    // Use the more restrictive (higher) requirement
    _annualIncome = max(minIncomeFromHousing, minIncomeFromDebt);
    _displayValue = _annualIncome!.toStringAsFixed(2);
    notifyListeners();
  }
}
