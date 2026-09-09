import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/modern_calculator.dart';
import 'package:provider/provider.dart';

CalculatorProvider buildCalculatorProvider() {
  return CalculatorProvider(
    coreCalculationService: serviceLocator<CoreCalculationService>(),
    amortizationService: serviceLocator<AmortizationService>(),
    qualificationService: serviceLocator<QualificationService>(),
    persistenceService: serviceLocator<CalculatorPersistenceService>(),
  );
}

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  late CalculatorProvider calcProvider;
  late CalculatorDisplayNotifier displayNotifier;

  setUp(() {
    calcProvider = buildCalculatorProvider();
    displayNotifier = CalculatorDisplayNotifier();
  });

  tearDown(() {
    calcProvider.dispose();
    displayNotifier.dispose();
  });

  Widget createWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CalculatorProvider>.value(value: calcProvider),
        ChangeNotifierProvider<CalculatorDisplayNotifier>.value(value: displayNotifier),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ModernCalculator(),
        ),
      ),
    );
  }

  group('ModernCalculator chip long-press options tests', () {
    testWidgets('Long-pressing Price chip shows popup menu with Copy and Edit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      calcProvider.setPrice(value: 500000);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(calcProvider.price, 500000);

      // Long press Price chip - should show popup, NOT clear
      await tester.longPress(find.text('Price'));
      await tester.pumpAndSettle();

      // Price should NOT be cleared
      expect(calcProvider.price, 500000);
      // Popup menu should appear with Copy and Edit
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Dismiss popup
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
    });

    testWidgets('Long-pressing L/A chip shows popup menu, not clearing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      calcProvider.setLoanAmount(value: 400000);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('L/A'));
      await tester.pumpAndSettle();

      // Should NOT clear
      expect(calcProvider.loanAmount, 400000);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
    });
  });

  group('ModernCalculator chip double-tap clear tests', () {
    testWidgets('Double-tapping Price chip clears it and UNDO restores it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      calcProvider.setPrice(value: 500000);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(calcProvider.price, 500000);

      // Double tap Price chip
      await tester.tap(find.text('Price'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();

      expect(calcProvider.price, isNull);
      expect(find.text('Price cleared'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      // Tap UNDO
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(calcProvider.price, 500000);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Double-tapping Rate chip clears interest rate', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      calcProvider.setInterestRate(value: 6.5);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(calcProvider.interestRate, 6.5);

      // Double tap Rate chip
      await tester.tap(find.text('Rate'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Rate'));
      await tester.pumpAndSettle();

      expect(calcProvider.interestRate, isNull);
      expect(find.text('Rate cleared'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Double-tapping secondary chips (Tax, Ins, HOA, DnPmt) clears them', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      calcProvider.setPrice(value: 500000);
      calcProvider.setDownPayment(value: 100000);
      calcProvider.setPropertyTax(value: 6000);
      calcProvider.setHomeInsurance(value: 1200);
      calcProvider.setMonthlyExpenses(value: 300);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Double-tap Tax
      await tester.tap(find.text('Tax'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Tax'));
      await tester.pumpAndSettle();
      expect(calcProvider.propertyTax, isNull);
      expect(find.text('Tax cleared'), findsOneWidget);

      // Double-tap Ins
      await tester.tap(find.text('Ins'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Ins'));
      await tester.pumpAndSettle();
      expect(calcProvider.homeInsurance, isNull);
      expect(find.text('Insurance cleared'), findsOneWidget);

      // Double-tap HOA
      await tester.tap(find.text('HOA'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('HOA'));
      await tester.pumpAndSettle();
      expect(calcProvider.monthlyExpenses, isNull);
      expect(find.text('HOA cleared'), findsOneWidget);

      // Double-tap DnPmt
      await tester.tap(find.text('DnPmt'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('DnPmt'));
      await tester.pumpAndSettle();
      expect(calcProvider.downPayment, isNull);
      expect(find.text('Down Payment cleared'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('ModernCalculator chip empty state tests', () {
    testWidgets('Long-pressing empty chip does not show popup menu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Price'));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
