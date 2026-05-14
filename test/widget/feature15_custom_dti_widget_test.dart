import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/qualification/application/providers/qualifying_ratios_provider.dart';
import 'package:loan_ranger/src/features/qualification/presentation/screens/qualification_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CalculatorProvider buildCalculatorProvider() {
  return CalculatorProvider(
    coreCalculationService: serviceLocator<CoreCalculationService>(),
    amortizationService: serviceLocator<AmortizationService>(),
    qualificationService: serviceLocator<QualificationService>(),
    persistenceService: serviceLocator<CalculatorPersistenceService>(),
  );
}

void main() {
  group('Feature #15: Widget Tests - Custom DTI Ratio UI', () {
    late QualifyingRatiosProvider provider;

    setUpAll(() async {
      await configureDependencies();
    });

    Widget buildTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CalculatorProvider>(
            create: (_) => buildCalculatorProvider(),
          ),
          ChangeNotifierProvider<QualifyingRatiosProvider>.value(
            value: provider,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: QualificationScreen())),
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      provider = QualifyingRatiosProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('Add custom ratio with 31/43 DTI values', (tester) async {
      // Arrange - Build the screen
      await tester.pumpWidget(buildTestApp());

      await tester.pumpAndSettle();

      // Act - Tap the add custom ratio button
      final addBtn = find.byIcon(Icons.add);
      expect(addBtn, findsWidgets);
      await tester.tap(addBtn.first);
      await tester.pumpAndSettle();

      // Verify dialog appeared
      expect(find.text('Add Custom Ratio'), findsOneWidget);

      // Enter test data
      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Test FHA Expanded',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description (optional)'),
        'Test description',
      );

      // Find the Housing DTI field and enter 31
      final housingField = find.widgetWithText(TextField, 'Housing DTI %');
      await tester.enterText(housingField, '31');

      // Find the Total DTI field and enter 43
      final debtField = find.widgetWithText(TextField, 'Total DTI %');
      await tester.enterText(debtField, '43');

      // Tap the Add button
      final addButton = find.text('Add');
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Assert - Verify the ratio was added with correct values
      final customRatios = provider.customRatios;
      expect(
        customRatios.length,
        equals(1),
        reason: 'Should have 1 custom ratio',
      );

      final addedRatio = customRatios.first;
      expect(addedRatio.name, equals('Test FHA Expanded'));
      expect(
        addedRatio.housingRatio,
        equals(31.0),
        reason:
            'FAILING REGRESSION: Housing DTI is ${addedRatio.housingRatio} instead of 31.0',
      );
      expect(
        addedRatio.debtRatio,
        equals(43.0),
        reason:
            'FAILING REGRESSION: Total DTI is ${addedRatio.debtRatio} instead of 43.0',
      );
    });

    testWidgets(
      'Add custom ratio with empty name shows snackbar and does not throw',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Add Custom Ratio'));
        await tester.pumpAndSettle();

        expect(find.text('Add Custom Ratio'), findsOneWidget);

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a name'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Add custom ratio with 25/38 DTI values', (tester) async {
      // Arrange
      await tester.pumpWidget(buildTestApp());

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Conservative Ratio',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Housing DTI %'),
        '25',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Total DTI %'),
        '38',
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Assert
      final ratio = provider.customRatios.first;
      expect(
        ratio.housingRatio,
        equals(25.0),
        reason:
            'FAILING REGRESSION: Housing DTI is ${ratio.housingRatio} instead of 25.0',
      );
      expect(
        ratio.debtRatio,
        equals(38.0),
        reason:
            'FAILING REGRESSION: Total DTI is ${ratio.debtRatio} instead of 38.0',
      );
    });

    testWidgets('Edit existing ratio to change DTI values', (tester) async {
      // Arrange - Create initial ratio
      await provider.addRatio(
        name: 'Original Ratio',
        housingRatio: 28.0,
        debtRatio: 36.0,
      );
      await provider.selectRatio(provider.customRatios.first);

      await tester.pumpWidget(buildTestApp());

      await tester.pumpAndSettle();

      // Act - Edit currently selected custom ratio
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Clear and enter new values
      await tester.enterText(
        find.widgetWithText(TextField, 'Housing DTI %'),
        '35',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Total DTI %'),
        '45',
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      final updated = provider.customRatios.first;
      expect(
        updated.housingRatio,
        equals(35.0),
        reason:
            'FAILING REGRESSION: Housing DTI is ${updated.housingRatio} instead of 35.0',
      );
      expect(
        updated.debtRatio,
        equals(45.0),
        reason:
            'FAILING REGRESSION: Total DTI is ${updated.debtRatio} instead of 45.0',
      );
    });

    testWidgets(
      'Regression test: Verify user-entered values are preserved, not defaults',
      (tester) async {
        // This is the critical regression test
        // Bug: Users enter 31/43 but it saves as 28/36

        await tester.pumpWidget(buildTestApp());

        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        // Enter NON-default values
        await tester.enterText(
          find.widgetWithText(TextField, 'Name'),
          'REGRESSION TEST',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Housing DTI %'),
          '31',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Total DTI %'),
          '43',
        );

        // Save
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        // CRITICAL ASSERTIONS - These will fail if regression exists
        final ratio = provider.customRatios.first;

        expect(
          ratio.housingRatio,
          equals(31.0),
          reason:
              '\n\n*** REGRESSION DETECTED ***\n'
              'User entered: 31\n'
              'But saved as: ${ratio.housingRatio}\n'
              'This is the DEFAULT value (28)\n'
              'User input was LOST!\n',
        );

        expect(
          ratio.debtRatio,
          equals(43.0),
          reason:
              '\n\n*** REGRESSION DETECTED ***\n'
              'User entered: 43\n'
              'But saved as: ${ratio.debtRatio}\n'
              'This is the DEFAULT value (36)\n'
              'User input was LOST!\n',
        );
      },
    );

    testWidgets('Qualification inputs sync with provider updates', (
      tester,
    ) async {
      final calculatorProvider = buildCalculatorProvider();
      addTearDown(calculatorProvider.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CalculatorProvider>.value(
              value: calculatorProvider,
            ),
            ChangeNotifierProvider<QualifyingRatiosProvider>.value(
              value: provider,
            ),
          ],
          child: const MaterialApp(home: QualificationScreen()),
        ),
      );

      await tester.pumpAndSettle();

      calculatorProvider.setAnnualIncome(value: 98500);
      calculatorProvider.setMonthlyDebt(value: 1425.75);
      await tester.pump();

      final incomeField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Annual Income'),
      );
      final debtField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Monthly Debt Payments'),
      );

      expect(incomeField.controller?.text, '98500');
      expect(debtField.controller?.text, '1425.75');

      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('Qualification UI shows decimal ratio precision', (
      tester,
    ) async {
      await provider.addRatio(
        name: 'Decimal Precision',
        housingRatio: 31.5,
        debtRatio: 43.25,
      );

      await provider.selectRatio(provider.customRatios.first);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('31.50%'), findsWidgets);
      expect(find.text('43.25%'), findsWidgets);
      expect(find.text('Decimal Precision (31.5/43.25)'), findsOneWidget);
    });
  });
}
