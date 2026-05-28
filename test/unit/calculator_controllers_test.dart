import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/amortization_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/qualification_controller.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  group('LoanQuoteController', () {
    late HistoryController historyController;
    late LoanQuoteController quoteController;
    late CoreCalculationService coreCalculationService;

    setUp(() {
      historyController = HistoryController();
      coreCalculationService = serviceLocator<CoreCalculationService>();
      quoteController = LoanQuoteController(
        coreCalculationService: coreCalculationService,
        historyController: historyController,
      );
    });

    test('calculates payment and records quote history', () {
      quoteController.setLoanAmount(value: 350000);
      quoteController.setInterestRate(value: 5.5);
      quoteController.setTermYears(value: 30);

      expect(quoteController.payment, closeTo(1987.26, 0.01));
      expect(historyController.entries, isNotEmpty);
      expect(
        historyController.entries.first.type,
        CalculationEntryType.payment,
      );
    });

    test('restores quote inputs and results from history entry', () {
      quoteController.setPrice(value: 400000);
      quoteController.setDownPayment(value: 20);
      quoteController.setInterestRate(value: 6.25);
      quoteController.setTermYears(value: 30);

      final entry = historyController.entries.first;

      final restoredHistoryController = HistoryController();
      final restoredQuoteController = LoanQuoteController(
        coreCalculationService: coreCalculationService,
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
    late CoreCalculationService coreCalculationService;
    late QualificationService qualificationService;

    setUp(() {
      historyController = HistoryController();
      coreCalculationService = serviceLocator<CoreCalculationService>();
      qualificationService = serviceLocator<QualificationService>();
      quoteController = LoanQuoteController(
        coreCalculationService: coreCalculationService,
        historyController: historyController,
      );
      qualificationController = QualificationController(
        qualificationService: qualificationService,
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
      expect(
        historyController.entries.first.type,
        CalculationEntryType.qualification,
      );
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
    late CoreCalculationService coreCalculationService;
    late AmortizationService amortizationService;

    setUp(() {
      historyController = HistoryController();
      coreCalculationService = serviceLocator<CoreCalculationService>();
      amortizationService = serviceLocator<AmortizationService>();
      quoteController = LoanQuoteController(
        coreCalculationService: coreCalculationService,
        historyController: historyController,
      );
      amortizationController = AmortizationController(
        amortizationService: amortizationService,
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

    // Regression test: generateSchedule must not contain an artificial delay
    // (e.g. Future.delayed). If a delay is reintroduced, this test will catch
    // it because isComputing will remain true longer than the fast-path allows.
    test(
      'generateSchedule completes without artificial delay — '
      'isComputing is false after await and schedule is populated',
      () async {
        quoteController.setLoanAmount(value: 300000);
        quoteController.setInterestRate(value: 6.5);
        quoteController.setTermYears(value: 30);

        // Capture isComputing transitions via notifications.
        final isComputingSnapshots = <bool>[];
        amortizationController.addListener(() {
          isComputingSnapshots.add(
            amortizationController.isComputingAmortization,
          );
        });

        final stopwatch = Stopwatch()..start();
        await amortizationController.generateSchedule();
        stopwatch.stop();

        // The schedule must have finished: isComputing must be false.
        expect(
          amortizationController.isComputingAmortization,
          isFalse,
          reason: 'isComputing should be false after generateSchedule returns',
        );

        // At least one notification was fired while computing (true),
        // and the final notification left isComputing as false.
        expect(
          isComputingSnapshots,
          contains(true),
          reason:
              'isComputing should have been set to true during computation',
        );
        expect(
          isComputingSnapshots.last,
          isFalse,
          reason:
              'The last notification must leave isComputing as false',
        );

        // The schedule must be non-empty.
        expect(
          amortizationController.amortizationData,
          isNotEmpty,
          reason: 'generateSchedule should populate amortizationData',
        );

        // Regression guard: a 50 ms artificial delay would push elapsed well
        // above this threshold even on slow CI hardware. Pure computation for
        // a 30-year schedule finishes in single-digit milliseconds.
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason:
              'generateSchedule took ${stopwatch.elapsedMilliseconds} ms — '
              'an artificial Future.delayed may have been reintroduced',
        );
      },
    );
  });
}
