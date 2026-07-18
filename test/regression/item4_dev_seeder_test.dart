import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/dev/dev_seeder_service.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';

CalculatorProvider _buildProvider() => CalculatorProvider(
  coreCalculationService: serviceLocator<CoreCalculationService>(),
  amortizationService: serviceLocator<AmortizationService>(),
  qualificationService: serviceLocator<QualificationService>(),
  persistenceService: serviceLocator<CalculatorPersistenceService>(),
);

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  group('Item 4: DevSeederService generates realistic history data', () {
    late List<CalculationEntry> entries;

    setUp(() {
      entries = DevSeederService.generateEntries();
    });

    test('generates exactly 25 entries', () {
      expect(entries.length, 25);
    });

    test('all entries have non-empty ids', () {
      for (final entry in entries) {
        expect(
          entry.id.isNotEmpty,
          isTrue,
          reason: 'Entry of type ${entry.type} has empty id',
        );
      }
    });

    test('all entry ids are unique', () {
      final ids = entries.map((e) => e.id).toSet();
      expect(ids.length, 25);
    });

    test('all entries have timestamps in the past', () {
      final now = DateTime.now();
      for (final entry in entries) {
        expect(
          entry.timestamp.isBefore(now),
          isTrue,
          reason: 'Entry ${entry.id} has future timestamp ${entry.timestamp}',
        );
      }
    });

    test('entries include all 5 calculation types', () {
      final types = entries.map((e) => e.type).toSet();
      expect(types, containsAll(CalculationEntryType.values));
    });

    test('entries include at least 4 qualification entries', () {
      final qualCount = entries
          .where((e) => e.type == CalculationEntryType.qualification)
          .length;
      expect(qualCount, greaterThanOrEqualTo(4));
    });

    test('payment entries have realistic loan amounts (100k–900k)', () {
      final paymentEntries = entries.where(
        (e) => e.type == CalculationEntryType.payment,
      );
      for (final entry in paymentEntries) {
        final loan = entry.loanAmount;
        expect(loan, isNotNull);
        expect(loan!, inInclusiveRange(100000, 900000));
      }
    });

    test('payment entries have realistic interest rates (4–12%)', () {
      final paymentEntries = entries.where(
        (e) => e.type == CalculationEntryType.payment,
      );
      for (final entry in paymentEntries) {
        final rate = entry.interestRate;
        expect(rate, isNotNull);
        expect(rate!, inInclusiveRange(4.0, 12.0));
      }
    });
  });

  group('Item 4: CalculatorProvider.seedDevData populates history', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = _buildProvider();
    });

    test('seedDevData adds 25 entries to history', () {
      provider.seedDevData();
      expect(provider.historyController.entries.length, 25);
    });

    test('seedDevData replaces existing history', () {
      // add a dummy entry first
      provider.historyController.addQuoteEntry(
        type: CalculationEntryType.payment,
        loanAmount: 100000,
        interestRate: 5.0,
        termYears: 30,
        payment: 537,
      );
      expect(provider.historyController.entries.length, 1);

      provider.seedDevData();
      expect(provider.historyController.entries.length, 25);
    });
  });
}
