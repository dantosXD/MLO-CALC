import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/amortization_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/qualification_controller.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  group('LoanQuoteController', () {
    late HistoryController historyController;
    late LoanQuoteController quoteController;

    setUp(() {
      historyController = HistoryController();
      quoteController = LoanQuoteController(
        historyController: historyController,
      );
    });

    test('calculates payment and records quote history', () {
      quoteController.setLoanAmount(value: 350000);
      quoteController.setInterestRate(value: 5.5);
      quoteController.setTermYears(value: 30);

      expect(quoteController.payment, closeTo(1987.26, 0.01));
      expect(historyController.entries, isNotEmpty);
      expect(historyController.entries.first.type, 'payment');
    });

    test('restores quote inputs and results from history entry', () {
      quoteController.setPrice(value: 400000);
      quoteController.setDownPayment(value: 20);
      quoteController.setInterestRate(value: 6.25);
      quoteController.setTermYears(value: 30);

      final entry = historyController.entries.first;

      final restoredHistoryController = HistoryController();
      final restoredQuoteController = LoanQuoteController(
        historyController: restoredHistoryController,
      );

      restoredQuoteController.restoreFromHistoryEntry(entry);

      expect(restoredQuoteController.price, 400000);
      expect(restoredQuoteController.downPayment, 20);
      expect(restoredQuoteController.termYears, 30);
      expect(restoredQuoteController.payment, isNotNull);
      expect(restoredQuoteController.presentedValue, isNotNull);
    });
  });

  group('QualificationController', () {
    late HistoryController historyController;
    late LoanQuoteController quoteController;
    late QualificationController qualificationController;

    setUp(() {
      historyController = HistoryController();
      quoteController = LoanQuoteController(
        historyController: historyController,
      );
      qualificationController = QualificationController(
        quoteController: quoteController,
        historyController: historyController,
      );
    });

    test('calculateMaxLoan updates quote controller and records history', () {
      qualificationController.setAnnualIncome(value: 120000);
      qualificationController.setMonthlyDebt(value: 750);
      quoteController.setInterestRate(value: 6.0);
      quoteController.setTermYears(value: 30);

      qualificationController.calculateMaxLoan();

      expect(quoteController.loanAmount, isNotNull);
      expect(quoteController.payment, isNotNull);
      expect(historyController.entries.first.type, 'qualification');
    });

    test(
      'calculateMinimumIncome updates annual income and presentation value',
      () {
        quoteController.setLoanAmount(value: 300000);
        quoteController.setInterestRate(value: 5.5);
        quoteController.setTermYears(value: 30);
        quoteController.setPropertyTax(value: 3600);
        quoteController.setHomeInsurance(value: 1200);
        qualificationController.setMonthlyDebt(value: 500);

        qualificationController.calculateMinimumIncome();

        expect(qualificationController.annualIncome, isNotNull);
        expect(qualificationController.inputError, isNull);
        expect(
          quoteController.presentedValue,
          qualificationController.annualIncome,
        );
      },
    );
  });

  group('AmortizationController', () {
    late HistoryController historyController;
    late LoanQuoteController quoteController;
    late AmortizationController amortizationController;

    setUp(() {
      historyController = HistoryController();
      quoteController = LoanQuoteController(
        historyController: historyController,
      );
      amortizationController = AmortizationController(
        quoteController: quoteController,
      );
    });

    test('reuses cached schedule for unchanged inputs', () async {
      quoteController.setLoanAmount(value: 250000);
      quoteController.setInterestRate(value: 5.25);
      quoteController.setTermYears(value: 30);

      await amortizationController.generateSchedule();
      expect(amortizationController.cachedScheduleCount, 1);
      final firstLength = amortizationController.amortizationData.length;

      await amortizationController.generateSchedule();

      expect(amortizationController.cachedScheduleCount, 1);
      expect(amortizationController.amortizationData.length, firstLength);
    });

    test(
      'creates a new cache entry when the quote fingerprint changes',
      () async {
        quoteController.setLoanAmount(value: 250000);
        quoteController.setInterestRate(value: 5.25);
        quoteController.setTermYears(value: 30);

        await amortizationController.generateSchedule();
        expect(amortizationController.cachedScheduleCount, 1);

        quoteController.setInterestRate(value: 6.0);
        await amortizationController.generateSchedule();

        expect(amortizationController.cachedScheduleCount, 2);
      },
    );
  });
}
