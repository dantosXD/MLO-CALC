import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/core/models/loan_parameters_read_model.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/amortization_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/qualification_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/repositories/calculator_session_repository.dart';
import 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/closing_costs.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';

export 'package:loan_ranger/src/features/calculator/application/states/loan_quote_state.dart'
    show PaymentDisplayMode;

class CalculatorProvider
    with ChangeNotifier
    implements LoanParametersReadModel {
  factory CalculatorProvider({
    required CoreCalculationService coreCalculationService,
    required AmortizationService amortizationService,
    required QualificationService qualificationService,
    required CalculatorPersistenceService persistenceService,
    CalculatorSessionRepository? sessionRepository,
    HistoryController? historyController,
    LoanQuoteController? loanQuoteController,
    QualificationController? qualificationControllerInstance,
    AmortizationController? amortizationController,
  }) {
    final history = historyController ?? HistoryController();
    final quote =
        loanQuoteController ??
        LoanQuoteController(
          coreCalculationService: coreCalculationService,
          historyController: history,
        );
    final qualification =
        qualificationControllerInstance ??
        QualificationController(
          qualificationService: qualificationService,
          quoteController: quote,
          historyController: history,
        );
    final amortization =
        amortizationController ??
        AmortizationController(
          amortizationService: amortizationService,
          quoteController: quote,
        );
    final repository =
        sessionRepository ??
        CalculatorSessionRepository(persistenceService: persistenceService);

    return CalculatorProvider._(
      loanQuoteController: quote,
      qualificationController: qualification,
      amortizationController: amortization,
      historyController: history,
      sessionRepository: repository,
    );
  }

  CalculatorProvider._({
    required LoanQuoteController loanQuoteController,
    required QualificationController qualificationController,
    required AmortizationController amortizationController,
    required HistoryController historyController,
    required CalculatorSessionRepository sessionRepository,
  }) : _loanQuoteController = loanQuoteController,
       _qualificationController = qualificationController,
       _amortizationController = amortizationController,
       _historyController = historyController,
       _sessionRepository = sessionRepository {
    _loanQuoteController.addListener(_handleChildChanged);
    _qualificationController.addListener(_handleChildChanged);
    _amortizationController.addListener(_handleChildChanged);
    _historyController.addListener(_handleChildChanged);
  }

  final LoanQuoteController _loanQuoteController;
  final QualificationController _qualificationController;
  final AmortizationController _amortizationController;
  final HistoryController _historyController;
  final CalculatorSessionRepository _sessionRepository;

  Timer? _saveTimer;
  bool _isHydrating = false;
  Future<void>? _initializeFuture;

  LoanQuoteController get loanQuoteController => _loanQuoteController;
  QualificationController get qualificationController =>
      _qualificationController;
  AmortizationController get amortizationController => _amortizationController;
  HistoryController get historyController => _historyController;

  String? get inputError =>
      _loanQuoteController.inputError ?? _qualificationController.inputError;

  @override
  double? get loanAmount => _loanQuoteController.loanAmount;
  @override
  double? get interestRate => _loanQuoteController.interestRate;
  @override
  double? get termYears => _loanQuoteController.termYears;
  @override
  double? get payment => _loanQuoteController.payment;
  @override
  double? get price => _loanQuoteController.price;
  @override
  double? get downPayment => _loanQuoteController.downPayment;
  @override
  double? get downPaymentPercentage =>
      _loanQuoteController.downPaymentPercentage;
  @override
  double? get propertyTax => _loanQuoteController.propertyTax;
  @override
  double? get homeInsurance => _loanQuoteController.homeInsurance;
  @override
  double? get mortgageInsurance => _loanQuoteController.mortgageInsurance;
  @override
  double? get monthlyExpenses => _loanQuoteController.monthlyExpenses;
  @override
  ClosingCosts get closingCosts => _loanQuoteController.closingCosts;
  @override
  double get cashToClose => _loanQuoteController.cashToClose;
  QualifyingRatio get qualRatio1 => _qualificationController.qualRatio1;
  QualifyingRatio get qualRatio2 => _qualificationController.qualRatio2;
  @override
  double? get annualIncome => _qualificationController.annualIncome;
  @override
  double? get monthlyDebt => _qualificationController.monthlyDebt;
  @override
  List<AmortizationEntry> get amortizationData =>
      _amortizationController.amortizationData;
  @override
  bool get isComputingAmortization =>
      _amortizationController.isComputingAmortization;
  @override
  CalculationHistory get history => _historyController.history;
  @override
  bool get isInterestOnly => _loanQuoteController.isInterestOnly;
  @override
  PaymentDisplayMode get displayMode => _loanQuoteController.displayMode;
  @override
  bool get hasPitiComponents => _loanQuoteController.hasPitiComponents;
  @override
  double? get displayPayment => _loanQuoteController.displayPayment;
  @override
  double get pitiPayment => _loanQuoteController.pitiPayment;
  @override
  double get interestOnlyPayment => _loanQuoteController.interestOnlyPayment;
  @override
  double get monthlyEscrowExpenses =>
      _loanQuoteController.monthlyEscrowExpenses;

  Future<void> initialize() {
    return _initializeFuture ??= _loadState();
  }

  /// Pre-fills fields that have no persisted value with MLO-defined defaults.
  /// Only rate and term are applied here; percentage-based PITI fields require
  /// a purchase price which is not known at startup.
  void applyDefaultsIfEmpty({
    double? interestRate,
    double? termYears,
  }) {
    if (this.interestRate == null && interestRate != null) {
      setInterestRate(value: interestRate);
    }
    if (this.termYears == null && termYears != null) {
      setTermYears(value: termYears);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _loanQuoteController.removeListener(_handleChildChanged);
    _qualificationController.removeListener(_handleChildChanged);
    _amortizationController.removeListener(_handleChildChanged);
    _historyController.removeListener(_handleChildChanged);
    _loanQuoteController.dispose();
    _qualificationController.dispose();
    _amortizationController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  void setLoanAmount({double? value}) =>
      _loanQuoteController.setLoanAmount(value: value);

  void setInterestRate({double? value}) =>
      _loanQuoteController.setInterestRate(value: value);

  void setTermYears({double? value}) =>
      _loanQuoteController.setTermYears(value: value);

  void setPayment({double? value}) =>
      _loanQuoteController.setPayment(value: value);

  void setPrice({double? value}) => _loanQuoteController.setPrice(value: value);

  void setDownPayment({double? value}) =>
      _loanQuoteController.setDownPayment(value: value);

  void setPropertyTax({double? value}) =>
      _loanQuoteController.setPropertyTax(value: value);

  void setHomeInsurance({double? value}) =>
      _loanQuoteController.setHomeInsurance(value: value);

  void setMortgageInsurance({double? value}) =>
      _loanQuoteController.setMortgageInsurance(value: value);

  void setMonthlyExpenses({double? value}) =>
      _loanQuoteController.setMonthlyExpenses(value: value);

  void setAnnualIncome({double? value}) =>
      _qualificationController.setAnnualIncome(value: value);

  void setMonthlyDebt({double? value}) =>
      _qualificationController.setMonthlyDebt(value: value);

  void setQualRatio1(QualifyingRatio ratio) =>
      _qualificationController.setQualRatio1(ratio);

  void setQualRatio2(QualifyingRatio ratio) =>
      _qualificationController.setQualRatio2(ratio);

  void updateClosingCosts(ClosingCosts costs) =>
      _loanQuoteController.updateClosingCosts(costs);

  void estimateClosingCosts() => _loanQuoteController.estimateClosingCosts();

  void toggleInterestOnly() => _loanQuoteController.toggleInterestOnly();

  void cycleDisplayMode({bool reverse = false}) =>
      _loanQuoteController.cycleDisplayMode(reverse: reverse);

  void clearLoanAmount() => _loanQuoteController.clearLoanAmount();

  void clearInterestRate() => _loanQuoteController.clearInterestRate();

  void clearTermYears() => _loanQuoteController.clearTermYears();

  void clearPayment() => _loanQuoteController.clearPayment();

  void clearAll() {
    _loanQuoteController.clearAll();
    _qualificationController.clearAll();
    _amortizationController.clear();
  }

  void calculate() => _loanQuoteController.calculate();

  void calculateInterestRate() => _loanQuoteController.calculateInterestRate();

  void calculateTerm() => _loanQuoteController.calculateTerm();

  void calculateLoanAmount() => _loanQuoteController.calculateLoanAmount();

  Future<void> generateAmortizationSchedule() =>
      _amortizationController.generateSchedule();

  double calculateRemainingBalance(double years) =>
      _amortizationController.remainingBalance(years);

  Map<String, double> calculateBiWeeklyConversion() =>
      _amortizationController.biWeeklyAnalysis();

  void calculateMaxQualifyingLoan({bool useRatio1 = true}) {
    _qualificationController.calculateMaxLoan(usePrimaryRatio: useRatio1);
  }

  void calculateMinimumIncome({bool useRatio1 = true}) {
    _qualificationController.calculateMinimumIncome(usePrimaryRatio: useRatio1);
  }

  void applyHistoryEntry(CalculationEntry entry) {
    _qualificationController.restoreFromHistoryEntry(entry);
    _loanQuoteController.restoreFromHistoryEntry(entry);
    _amortizationController.clear(clearCache: false);
  }

  void removeHistoryEntry(String id) => _historyController.remove(id);

  void clearHistory() => _historyController.clear();

  Future<String> applyNlpRequest(CalculationRequest request) async {
    void setIf(double? value, void Function({double? value}) setter) {
      if (value != null) {
        setter(value: value);
      }
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

    switch (request.action) {
      case 'calculate_payment':
        _loanQuoteController.calculate();
        break;
      case 'calculate_loan_amount':
        _loanQuoteController.calculateLoanAmount();
        break;
      case 'calculate_term':
        _loanQuoteController.calculateTerm();
        break;
      case 'calculate_interest_rate':
        _loanQuoteController.calculateInterestRate();
        break;
      case 'calculate_max_qualifying_loan':
        calculateMaxQualifyingLoan();
        break;
      case 'calculate_min_income':
        calculateMinimumIncome();
        break;
      case 'generate_amortization':
        await generateAmortizationSchedule();
        break;
      case 'calculate_biweekly':
        calculateBiWeeklyConversion();
        break;
    }

    return request.explanation;
  }

  void _handleChildChanged() {
    if (!_isHydrating) {
      _saveState();
    }
    notifyListeners();
  }

  Future<void> _loadState() async {
    try {
      _isHydrating = true;
      final snapshot = await _sessionRepository.load();
      _loanQuoteController.hydrateFromSnapshot(snapshot);
      _qualificationController.hydrateFromSnapshot(snapshot);
      _historyController.replaceFromJson(snapshot.historyJson);
    } catch (_) {
      // Keep the app usable if persistence fails.
    } finally {
      _isHydrating = false;
      notifyListeners();
    }
  }

  void _saveState() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 750), () async {
      try {
        await _sessionRepository.save(
          quoteState: _loanQuoteController.state,
          qualificationState: _qualificationController.state,
          historyController: _historyController,
        );
      } catch (_) {
        // Ignore persistence failures and keep in-memory state authoritative.
      }
    });
  }
}
