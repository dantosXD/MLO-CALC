import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/core/validators/financial_validators.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/biweekly_conversion.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/calculator_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/qualification_result.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';

enum _ManualVar { loanAmount, interestRate, termYears, payment }

enum PaymentDisplayMode { 
  standardPI,      // Standard P&I payment
  interestOnly,    // Interest-only payment
  piti,            // Full PITI breakdown
}

class CalculatorProvider with ChangeNotifier {
  CalculatorProvider({
    CoreCalculationService? coreCalculationService,
    AmortizationService? amortizationService,
    QualificationService? qualificationService,
    CalculatorPersistenceService? persistenceService,
  })  : _coreCalculationService =
            coreCalculationService ?? serviceLocator<CoreCalculationService>(),
        _amortizationService =
            amortizationService ?? serviceLocator<AmortizationService>(),
        _qualificationService =
            qualificationService ?? serviceLocator<QualificationService>(),
        _persistenceService = persistenceService ??
            serviceLocator<CalculatorPersistenceService>() {
    _loadState();
  }

  final CoreCalculationService _coreCalculationService;
  final AmortizationService _amortizationService;
  final QualificationService _qualificationService;
  final CalculatorPersistenceService _persistenceService;

  // --- Domain State ---
  // Primary Loan Variables
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
  ClosingCosts _closingCosts = const ClosingCosts();

  // Qualification Variables
  QualifyingRatio _qualRatio1 = DefaultQualifyingRatios.ratios[0]; // Conventional
  QualifyingRatio _qualRatio2 = DefaultQualifyingRatios.ratios[1]; // FHA
  double? _annualIncome;
  double? _monthlyDebt;

  // Operational State
  List<AmortizationEntry> _amortizationData = [];
  bool _isComputingAmortization = false;
  String? _calculationError;
  bool _isInterestOnly = false;
  PaymentDisplayMode _displayMode = PaymentDisplayMode.standardPI;

  // Advanced features
  double? _futureValue;
  final CalculationHistory _history = CalculationHistory();
  Timer? _saveTimer;

  final Set<_ManualVar> _manualVariables = <_ManualVar>{};
  final List<_ManualVar> _manualInputOrder = <_ManualVar>[];
  
  // Notification Stream for UI to sync display
  final _calculationResultController = StreamController<double>.broadcast();
  Stream<double> get onCalculationResult => _calculationResultController.stream;

  @override
  void dispose() {
    _saveTimer?.cancel();
    _calculationResultController.close();
    super.dispose();
  }

  // --- UI Getters ---
  String? get inputError => _calculationError;

  // --- Domain Getters ---
  double? get loanAmount => _loanAmount;
  double? get interestRate => _interestRate;
  double? get termYears => _termYears;
  double? get payment => _payment;
  double? get price => _price;
  double? get downPayment => _downPayment;
  double? get downPaymentPercentage {
    if (_price == null || _price == 0 || _downPayment == null) return null;
    // If down payment is already a percentage (< 100), return it
    if (_downPayment! < 100) return _downPayment;
    // Otherwise calculate percentage from amount
    return (_downPayment! / _price!) * 100;
  }
  double? get propertyTax => _propertyTax;
  double? get homeInsurance => _homeInsurance;
  double? get mortgageInsurance => _mortgageInsurance;
  double? get monthlyExpenses => _monthlyExpenses;
  ClosingCosts get closingCosts => _closingCosts;
  
  double get cashToClose {
    double total = _closingCosts.total;
    if (_price != null && _downPayment != null) {
      if (_downPayment! < 100) {
        total += _price! * (_downPayment! / 100);
      } else {
        total += _downPayment!;
      }
    } else if (_loanAmount != null && _price != null) {
      total += (_price! - _loanAmount!);
    }
    return total;
  }

  QualifyingRatio get qualRatio1 => _qualRatio1;
  QualifyingRatio get qualRatio2 => _qualRatio2;
  double? get annualIncome => _annualIncome;
  double? get monthlyDebt => _monthlyDebt;

  List<AmortizationEntry> get amortizationData => _amortizationData;
  bool get isComputingAmortization => _isComputingAmortization;
  double? get futureValue => _futureValue;
  CalculationHistory get history => _history;
  bool get isInterestOnly => _isInterestOnly;
  PaymentDisplayMode get displayMode => _displayMode;
  
  bool get hasPitiComponents => 
      _propertyTax != null || 
      _homeInsurance != null || 
      _mortgageInsurance != null || 
      _monthlyExpenses != null;

  /// Get the display payment based on current display mode
  double? get displayPayment {
    if (_payment == null) return null;
    
    switch (_displayMode) {
      case PaymentDisplayMode.standardPI:
        return _payment;
      case PaymentDisplayMode.interestOnly:
        return _payment; // Already calculated as interest-only if mode is set
      case PaymentDisplayMode.piti:
        // Calculate full PITI
        final monthlyTax = (_propertyTax ?? 0) / 12;
        final monthlyIns = (_homeInsurance ?? 0) / 12;
        final monthlyPmi = (_mortgageInsurance ?? 0) / 12;
        final monthlyHoa = _monthlyExpenses ?? 0;
        return _payment! + monthlyTax + monthlyIns + monthlyPmi + monthlyHoa;
    }
  }

  // --- Logic Helpers ---

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
  
  // --- Domain Setters (Integrated with UI) ---

  void setLoanAmount({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validateLoanAmount(value);
      if (!validation.isValid) {
        _calculationError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _calculationError = null;

    if (value == null) {
      _loanAmount = null;
      _unregisterManualInput(_ManualVar.loanAmount);
    } else {
      _loanAmount = value;
      _registerManualInput(_ManualVar.loanAmount);
    }

    if (!_manualVariables.contains(_ManualVar.payment)) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    }
    
    calculate();
    _saveState();
    notifyListeners();
  }

  void setInterestRate({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validateInterestRate(value);
      if (!validation.isValid) {
        _calculationError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _calculationError = null;

    if (value == null) {
      _interestRate = null;
      _unregisterManualInput(_ManualVar.interestRate);
    } else {
      _interestRate = value;
      _registerManualInput(_ManualVar.interestRate);
    }

    if (!_manualVariables.contains(_ManualVar.payment)) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    }
    calculate();
    _saveState();
    notifyListeners();
  }

  void setTermYears({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validateTermYears(value);
      if (!validation.isValid) {
        _calculationError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _calculationError = null;

    if (value == null) {
      _termYears = null;
      _unregisterManualInput(_ManualVar.termYears);
    } else {
      _termYears = value;
      _registerManualInput(_ManualVar.termYears);
    }

    if (!_manualVariables.contains(_ManualVar.payment)) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    }
    calculate();
    _saveState();
    notifyListeners();
  }

  void setPayment({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validatePayment(value);
      if (!validation.isValid) {
        _calculationError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _calculationError = null;

    if (value == null) {
      _payment = null;
      _unregisterManualInput(_ManualVar.payment);
    } else {
      _payment = value;
      _registerManualInput(_ManualVar.payment);
    }

    if (!_manualVariables.contains(_ManualVar.loanAmount)) {
      _loanAmount = null;
      _unregisterManualInput(_ManualVar.loanAmount);
    }
    calculate();
    _saveState();
    notifyListeners();
  }

  void setPrice({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validatePrice(value);
      if (!validation.isValid) {
        _calculationError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _calculationError = null;

    _price = value;
    _calculateLoanAmountFromPrice();
    _saveState();
    notifyListeners();
  }

  void setDownPayment({double? value}) {
    if (value != null) {
      final validation = FinancialValidators.validateDownPayment(value, _price);
      if (!validation.isValid) {
        _calculationError = validation.errorMessage;
        notifyListeners();
        return;
      }
    }
    _calculationError = null;

    _downPayment = value;
    _calculateLoanAmountFromPrice();
    _saveState();
    notifyListeners();
  }

  void setPropertyTax({double? value}) {
    _propertyTax = value;
    _saveState();
    notifyListeners();
  }

  void setHomeInsurance({double? value}) {
    _homeInsurance = value;
    _saveState();
    notifyListeners();
  }

  void setMortgageInsurance({double? value}) {
    _mortgageInsurance = value;
    _saveState();
    notifyListeners();
  }

  void setMonthlyExpenses({double? value}) {
    _monthlyExpenses = value;
    _saveState();
    notifyListeners();
  }

  void setAnnualIncome({double? value}) {
    _annualIncome = value;
    _saveState();
    notifyListeners();
  }

  void setMonthlyDebt({double? value}) {
    _monthlyDebt = value;
    _saveState();
    notifyListeners();
  }

  void setQualRatio1(QualifyingRatio ratio) {
    _qualRatio1 = ratio;
    notifyListeners();
  }
  
  void setQualRatio2(QualifyingRatio ratio) {
    _qualRatio2 = ratio;
    notifyListeners();
  }
  
  void updateClosingCosts(ClosingCosts costs) {
    _closingCosts = costs;
    notifyListeners();
  }

  void estimateClosingCosts() {
    if (_loanAmount == null || _price == null) return;
    _closingCosts = ClosingCosts.estimate(
      loanAmount: _loanAmount!,
      price: _price!,
    );
    notifyListeners();
  }

  void toggleInterestOnly() {
    _isInterestOnly = !_isInterestOnly;
    _calculationError = null;
    
    // Recalculate payment if we have the required inputs
    if (_loanAmount != null && _interestRate != null && _termYears != null) {
      _calculatePayment();
    }
    
    _saveState();
    notifyListeners();
  }

  void cycleDisplayMode({bool reverse = false}) {
    final modes = <PaymentDisplayMode>[];
    
    // Always include standard P&I
    modes.add(PaymentDisplayMode.standardPI);
    
    // Add interest-only if we have required data
    if (_loanAmount != null && _interestRate != null) {
      modes.add(PaymentDisplayMode.interestOnly);
    }
    
    // Add PITI if we have any PITI components
    if (hasPitiComponents && _payment != null) {
      modes.add(PaymentDisplayMode.piti);
    }
    
    // If only one mode available, no cycling needed
    if (modes.length <= 1) return;
    
    final currentIndex = modes.indexOf(_displayMode);
    int nextIndex;
    
    if (reverse) {
      nextIndex = currentIndex - 1;
      if (nextIndex < 0) nextIndex = modes.length - 1;
    } else {
      nextIndex = (currentIndex + 1) % modes.length;
    }
    
    _displayMode = modes[nextIndex];
    
    // Update interest-only state based on display mode
    final wasInterestOnly = _isInterestOnly;
    _isInterestOnly = _displayMode == PaymentDisplayMode.interestOnly;
    
    // Recalculate if interest-only state changed
    if (wasInterestOnly != _isInterestOnly && 
        _loanAmount != null && 
        _interestRate != null && 
        _termYears != null) {
      _calculatePayment();
    } else {
      notifyListeners();
    }
  }

  void clearLoanAmount() {
    _loanAmount = null;
    _unregisterManualInput(_ManualVar.loanAmount);
    calculate();
    _saveState();
    notifyListeners();
  }

  void clearInterestRate() {
    _interestRate = null;
    _unregisterManualInput(_ManualVar.interestRate);
    calculate();
    _saveState();
    notifyListeners();
  }

  void clearTermYears() {
    _termYears = null;
    _unregisterManualInput(_ManualVar.termYears);
    calculate();
    _saveState();
    notifyListeners();
  }

  void clearPayment() {
    _payment = null;
    _unregisterManualInput(_ManualVar.payment);
    calculate();
    _saveState();
    notifyListeners();
  }

  void clearAll() {
    _calculationError = null;
    
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
    _amortizationData = [];
    _futureValue = null;
    _isInterestOnly = false;
    _displayMode = PaymentDisplayMode.standardPI;
    
    _manualVariables.clear();
    _manualInputOrder.clear();
    
    _saveState();
    notifyListeners();
  }

  // --- Logic Implementations ---

  void _calculateLoanAmountFromPrice() {
    if (_price == null || _downPayment == null) return;
    double downPaymentAmount;
    if (_downPayment! < 100) {
      downPaymentAmount = _price! * (_downPayment! / 100);
    } else {
      downPaymentAmount = _downPayment!;
    }
    _loanAmount = _price! - downPaymentAmount;
    _unregisterManualInput(_ManualVar.loanAmount);
    calculate();
  }

  // Financial Calculations
  void calculate() {
    // Determine target based on what's missing or least recently touched
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
    if (_loanAmount == null || _interestRate == null || _termYears == null) return;
    final result = _coreCalculationService.calculatePayment(
      loanAmount: _loanAmount!,
      interestRate: _interestRate!,
      termYears: _termYears!,
      interestOnly: _isInterestOnly,
    );

    if (!result.isSuccess) {
      _calculationError = result.error;
    } else {
      _payment = result.value;
      _unregisterManualInput(_ManualVar.payment);
      
      _calculationResultController.add(_payment!);
      
      _history.addEntry(CalculationEntry.fromLoanCalculation(
        type: 'payment',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
        price: _price,
        downPayment: _downPayment,
      ));
      _saveState();
    }
    notifyListeners();
  }

  void _calculateLoanAmount() {
    if (_payment == null || _interestRate == null || _termYears == null) return;
    final result = _coreCalculationService.calculateLoanAmount(
      payment: _payment!,
      interestRate: _interestRate!,
      termYears: _termYears!,
    );

    if (!result.isSuccess) {
      _calculationError = result.error;
    } else {
      _loanAmount = result.value;
      _unregisterManualInput(_ManualVar.loanAmount);
      
      _calculationResultController.add(_loanAmount!);
      
      _history.addEntry(CalculationEntry.fromLoanCalculation(
        type: 'loan_amount',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
        price: _price,
        downPayment: _downPayment,
      ));
      _saveState();
    }
    notifyListeners();
  }

  void _calculateTerm() {
    if (_loanAmount == null || _payment == null || _interestRate == null) return;
    final result = _coreCalculationService.calculateTerm(
      loanAmount: _loanAmount!,
      payment: _payment!,
      interestRate: _interestRate!,
    );
    if (!result.isSuccess) {
      _calculationError = result.error;
    } else {
      _termYears = result.value;
      _unregisterManualInput(_ManualVar.termYears);
      
      _calculationResultController.add(_termYears!);
      
      _history.addEntry(CalculationEntry.fromLoanCalculation(
        type: 'term',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
        price: _price,
        downPayment: _downPayment,
      ));
      _saveState();
    }
    notifyListeners();
  }

  void _calculateInterestRate() {
    if (_loanAmount == null || _payment == null || _termYears == null) return;
    final result = _coreCalculationService.solveInterestRate(
      loanAmount: _loanAmount!,
      payment: _payment!,
      termYears: _termYears!,
    );
    if (!result.isSuccess) {
      _calculationError = result.error;
    } else {
      _interestRate = result.value;
      _unregisterManualInput(_ManualVar.interestRate);

      _calculationResultController.add(_interestRate!);

      _history.addEntry(CalculationEntry.fromLoanCalculation(
        type: 'interest_rate',
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
        price: _price,
        downPayment: _downPayment,
      ));
      _saveState();
    }
    notifyListeners();
  }

  /// Public method to trigger interest rate calculation from UI
  /// When user has entered loan amount, payment, and term, this calculates the interest rate
  void calculateInterestRate() {
    _calculateInterestRate();
  }

  // --- Other Domain Methods ---

  Future<void> generateAmortizationSchedule() async {
    if (_loanAmount == null || _interestRate == null || _termYears == null) return;
    _isComputingAmortization = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      _amortizationData = await _amortizationService.buildSchedule(
        loanAmount: _loanAmount!,
        interestRate: _interestRate!,
        termYears: _termYears!,
        payment: _payment,
      );
    } finally {
      _isComputingAmortization = false;
      notifyListeners();
    }
  }

  double calculateRemainingBalance(double years) {
    if (_loanAmount == null || _interestRate == null || _termYears == null) return 0;
    if (_payment == null) _calculatePayment();
    if (_payment == null) return 0;
    return _amortizationService.remainingBalance(
      loanAmount: _loanAmount!,
      interestRate: _interestRate!,
      termYears: _termYears!,
      yearsElapsed: years,
      payment: _payment,
    );
  }

  Map<String, double> calculateBiWeeklyConversion() {
    if (_loanAmount == null || _interestRate == null || _termYears == null) return {};
    if (_payment == null) {
      _calculatePayment();
      if (_payment == null) return {};
    }
    final BiWeeklyConversion conversion = _amortizationService.calculateBiWeekly(
      loanAmount: _loanAmount!,
      interestRate: _interestRate!,
      termYears: _termYears!,
      payment: _payment,
    );
    return {
      'biWeeklyPayment': conversion.biWeeklyPayment,
      'newTermYears': conversion.newTermYears,
      'totalInterest': conversion.totalInterest,
      'interestSaved': conversion.interestSaved,
    };
  }

  void calculateMaxQualifyingLoan({bool useRatio1 = true}) {
    if (_annualIncome == null || _interestRate == null || _termYears == null) {
      _calculationError = 'Need income, rate, term';
      notifyListeners();
      return;
    }
    final ratio = useRatio1 ? _qualRatio1 : _qualRatio2;
    final result = _qualificationService.calculateMaxLoan(
      ratio: ratio,
      annualIncome: _annualIncome!,
      interestRate: _interestRate!,
      termYears: _termYears!,
      monthlyDebt: _monthlyDebt ?? 0,
      monthlyEscrows: _monthlyEscrowExpenses,
    );
    if (!result.isSuccess || result.value == null) {
      _calculationError = result.error ?? 'Unable to qualify';
      notifyListeners();
      return;
    }
    final QualificationResult outcome = result.value!;
    _loanAmount = outcome.loanAmount;
    _payment = outcome.monthlyPiPayment;
    _unregisterManualInput(_ManualVar.loanAmount);
    _unregisterManualInput(_ManualVar.payment);
    _calculationResultController.add(_loanAmount!);
    
    _history.addEntry(CalculationEntry.fromQualification(
      annualIncome: _annualIncome!,
      monthlyDebt: _monthlyDebt ?? 0,
      interestRate: _interestRate!,
      termYears: _termYears!,
      maxLoanAmount: _loanAmount!,
    ));
    _saveState();
    notifyListeners();
  }
  
  void calculateMinimumIncome({bool useRatio1 = true}) {
    if (_loanAmount == null || _interestRate == null || _termYears == null) {
      _calculationError = 'Need L/A, Rate, Term';
      notifyListeners();
      return;
    }
    if (_payment == null) _calculatePayment();
    
    final ratio = useRatio1 ? _qualRatio1 : _qualRatio2;
    final result = _qualificationService.calculateMinimumIncome(
      ratio: ratio,
      pitiPayment: pitiPayment,
      monthlyDebt: _monthlyDebt ?? 0,
    );
    if (!result.isSuccess || result.value == null) {
      _calculationError = result.error ?? 'Unable to calculate income';
      notifyListeners();
      return;
    }
    _calculationResultController.add(result.value!);
    _annualIncome = result.value;
    notifyListeners();
  }

  // --- Persistence & History ---

  Future<void> _loadState() async {
    try {
      final snapshot = await _persistenceService.load();
      _loanAmount = snapshot.loanAmount;
      _interestRate = snapshot.interestRate;
      _termYears = snapshot.termYears;
      _payment = snapshot.payment;
      _price = snapshot.price;
      _downPayment = snapshot.downPayment;
      _propertyTax = snapshot.propertyTax;
      _homeInsurance = snapshot.homeInsurance;
      _mortgageInsurance = snapshot.mortgageInsurance;
      _monthlyExpenses = snapshot.monthlyExpenses;
      _annualIncome = snapshot.annualIncome;
      _monthlyDebt = snapshot.monthlyDebt;
      
      final historyJson = snapshot.historyJson;
      if (historyJson != null && historyJson.isNotEmpty) {
        _history.fromJsonString(historyJson);
      }
      
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveState() async {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 750), () async {
      final snapshot = CalculatorStateSnapshot(
        loanAmount: _loanAmount,
        interestRate: _interestRate,
        termYears: _termYears,
        payment: _payment,
        price: _price,
        downPayment: _downPayment,
        propertyTax: _propertyTax,
        homeInsurance: _homeInsurance,
        mortgageInsurance: _mortgageInsurance,
        monthlyExpenses: _monthlyExpenses,
        annualIncome: _annualIncome,
        monthlyDebt: _monthlyDebt,
        historyJson: _history.toJsonString(),
      );
      try {
        await _persistenceService.save(snapshot);
      } catch (_) {}
    });
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
      _manualVariables.clear();
      _manualInputOrder.clear();
      
      if (_payment != null) {
        _calculationResultController.add(_payment!);
      } else if (_loanAmount != null) {
        _calculationResultController.add(_loanAmount!);
      }
      
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

  // --- NLP Integration ---
  
  Future<String> applyNlpRequest(CalculationRequest request) async {
    // Helper to conditionally set values from NLP
    void setIf(double? val, void Function({double? value}) setter) {
      if (val != null) setter(value: val);
    }
    
    setIf(request.loanAmount, setLoanAmount);
    setIf(request.interestRate, setInterestRate);
    setIf(request.termYears, setTermYears);
    setIf(request.payment, setPayment);
    setIf(request.price, setPrice);
    setIf(request.downPayment, setDownPayment);
    setIf(request.propertyTax, setPropertyTax);
    setIf(request.homeInsurance, setHomeInsurance);
    setIf(request.mortgageInsurance, setMortgageInsurance);
    setIf(request.monthlyExpenses, setMonthlyExpenses);
    setIf(request.annualIncome, setAnnualIncome);
    setIf(request.monthlyDebt, setMonthlyDebt);
    
    // If specific action requested:
    switch (request.action) {
      case 'calculate_payment':
        _calculatePayment();
        break;
      case 'calculate_loan_amount':
        _calculateLoanAmount();
        break;
      case 'calculate_term':
        _calculateTerm();
        break;
      case 'calculate_interest_rate':
        _calculateInterestRate();
        break;
      case 'calculate_max_qualifying_loan':
        calculateMaxQualifyingLoan();
        break;
      case 'calculate_min_income':
        calculateMinimumIncome();
        break;
      case 'generate_amortization':
        generateAmortizationSchedule();
        break;
      case 'calculate_biweekly':
        calculateBiWeeklyConversion();
        break;
    }
    
    return request.explanation;
  }
  
  // --- Helpers ---
  
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
  
  double get _monthlyEscrowExpenses {
    double total = 0;
    if (_propertyTax != null) total += _propertyTax! / 12;
    if (_homeInsurance != null) total += _homeInsurance! / 12;
    if (_mortgageInsurance != null) total += _mortgageInsurance! / 12;
    if (_monthlyExpenses != null) total += _monthlyExpenses!;
    return total;
  }
  
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
