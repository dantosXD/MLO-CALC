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

void main() {
  setUpAll(() async => configureDependencies());

  test('assignment confirmations use the right units', () {
    expect(formatAssignedValue('Rate', 6.5), '6.500%');
    expect(formatAssignedValue('Term', 30), '30 yrs');
    expect(formatAssignedValue('Down Pmt', 20), '20.00%');
    expect(formatAssignedValue('Down Pmt', 90000), r'$90,000.00');
    expect(formatAssignedValue('Price', 450000), r'$450,000.00');
  });

  testWidgets('percent down payment chip shows dollars, not a bare 20.00', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    final calc = CalculatorProvider(
      coreCalculationService: serviceLocator<CoreCalculationService>(),
      amortizationService: serviceLocator<AmortizationService>(),
      qualificationService: serviceLocator<QualificationService>(),
      persistenceService: serviceLocator<CalculatorPersistenceService>(),
    )
      ..setPrice(value: 450000)
      ..setDownPayment(value: 20);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CalculatorProvider>.value(value: calc),
          ChangeNotifierProvider(create: (_) => CalculatorDisplayNotifier()),
        ],
        child: const MaterialApp(home: Scaffold(body: ModernCalculator())),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text(r'$20.00'), findsNothing);
    expect(find.text(r'$90K'), findsOneWidget);
    expect(find.text('20.00%'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    calc.dispose();
    await t.pump(const Duration(seconds: 5));
  });
}
