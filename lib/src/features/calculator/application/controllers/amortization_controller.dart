import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/models/amortization_entry.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/states/amortization_state.dart';
import 'package:loan_ranger/src/features/calculator/domain/models/biweekly_conversion.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';

class AmortizationController with ChangeNotifier {
  AmortizationController({
    required AmortizationService amortizationService,
    required LoanQuoteController quoteController,
  }) : _amortizationService = amortizationService,
       _quoteController = quoteController;

  final AmortizationService _amortizationService;
  final LoanQuoteController _quoteController;

  AmortizationState _state = const AmortizationState();
  final Map<String, List<AmortizationEntry>> _scheduleCache =
      <String, List<AmortizationEntry>>{};

  AmortizationState get state => _state;
  List<AmortizationEntry> get amortizationData => _state.amortizationData;
  bool get isComputingAmortization => _state.isComputing;

  @visibleForTesting
  int get cachedScheduleCount => _scheduleCache.length;

  Future<void> generateSchedule() async {
    if (_quoteController.loanAmount == null ||
        _quoteController.interestRate == null ||
        _quoteController.termYears == null) {
      return;
    }

    final fingerprint = _buildFingerprint();
    final cached = _scheduleCache[fingerprint];
    if (cached != null) {
      _state = _state.copyWith(
        amortizationData: cached,
        isComputing: false,
        activeFingerprint: fingerprint,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isComputing: true, activeFingerprint: fingerprint);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final data = await _amortizationService.buildSchedule(
        loanAmount: _quoteController.loanAmount!,
        interestRate: _quoteController.interestRate!,
        termYears: _quoteController.termYears!,
        payment: _quoteController.payment,
      );
      _scheduleCache[fingerprint] = List<AmortizationEntry>.unmodifiable(data);
      _state = _state.copyWith(amortizationData: data);
    } finally {
      _state = _state.copyWith(isComputing: false);
      notifyListeners();
    }
  }

  double remainingBalance(double years) {
    if (_quoteController.loanAmount == null ||
        _quoteController.interestRate == null ||
        _quoteController.termYears == null) {
      return 0;
    }
    if (_quoteController.payment == null) {
      _quoteController.calculate();
    }
    if (_quoteController.payment == null) return 0;
    return _amortizationService.remainingBalance(
      loanAmount: _quoteController.loanAmount!,
      interestRate: _quoteController.interestRate!,
      termYears: _quoteController.termYears!,
      yearsElapsed: years,
      payment: _quoteController.payment,
    );
  }

  Map<String, double> biWeeklyAnalysis() {
    if (_quoteController.loanAmount == null ||
        _quoteController.interestRate == null ||
        _quoteController.termYears == null) {
      return const <String, double>{};
    }
    if (_quoteController.payment == null) {
      _quoteController.calculate();
      if (_quoteController.payment == null) {
        return const <String, double>{};
      }
    }

    final conversion = _amortizationService.calculateBiWeekly(
      loanAmount: _quoteController.loanAmount!,
      interestRate: _quoteController.interestRate!,
      termYears: _quoteController.termYears!,
      payment: _quoteController.payment,
    );
    return _toBiWeeklyMap(conversion);
  }

  void clear({bool clearCache = true}) {
    if (clearCache) {
      _scheduleCache.clear();
    }
    _state = const AmortizationState();
    notifyListeners();
  }

  String _buildFingerprint() {
    return [
      _quoteController.loanAmount,
      _quoteController.interestRate,
      _quoteController.termYears,
      _quoteController.payment,
    ].join('|');
  }

  Map<String, double> _toBiWeeklyMap(BiWeeklyConversion conversion) {
    return <String, double>{
      'biWeeklyPayment': conversion.biWeeklyPayment,
      'newTermYears': conversion.newTermYears,
      'totalInterest': conversion.totalInterest,
      'interestSaved': conversion.interestSaved,
    };
  }
}
