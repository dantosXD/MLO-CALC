import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/qualification/domain/services/affordability_solver.dart';
import 'package:loan_ranger/src/features/qualification/presentation/widgets/max_price_card.dart';
import 'package:provider/provider.dart';

import 'calculator_provider_test.dart' show buildCalculatorProvider;

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  test('round trip: forward PITI at returned price equals target', () {
    final r = const AffordabilitySolver().maxPrice(
      targetPiti: 3000,
      rate: 6.5,
      termYears: 30,
      downPaymentPercent: 10,
      taxRatePercent: 1.2,
      insuranceRatePercent: 0.5,
      hoaMonthly: 0,
      miAnnualPercent: 0.5,
    )!;
    final loan = r.price * 0.9;
    final piti =
        LoanMath().calculatePayment(
          loanAmount: loan,
          interestRate: 6.5,
          termYears: 30,
        ) +
        r.price * (1.2 + 0.5) / 1200 +
        loan * 0.5 / 1200;
    expect(piti, closeTo(3000, 0.01));
    expect(r.loanAmount, closeTo(loan, 0.001));
    expect(r.principalAndInterest + r.monthlyTaxInsMi, closeTo(3000, 0.01));
  });

  test('target <= HOA returns null', () {
    final r = const AffordabilitySolver().maxPrice(
      targetPiti: 200,
      rate: 6.5,
      termYears: 30,
      downPaymentPercent: 10,
      taxRatePercent: 1.2,
      insuranceRatePercent: 0.5,
      hoaMonthly: 300,
      miAnnualPercent: 0,
    );
    expect(r, isNull);
  });

  test('round trip with HOA and MI', () {
    final r = const AffordabilitySolver().maxPrice(
      targetPiti: 2800,
      rate: 7,
      termYears: 30,
      downPaymentPercent: 5,
      taxRatePercent: 1.1,
      insuranceRatePercent: 0.4,
      hoaMonthly: 150,
      miAnnualPercent: 0.85,
    )!;
    expect(
      r.principalAndInterest + r.monthlyTaxInsMi + 150,
      closeTo(2800, 0.01),
    );
    final piti =
        LoanMath().calculatePayment(
          loanAmount: r.loanAmount,
          interestRate: 7,
          termYears: 30,
        ) +
        r.price * 1.5 / 1200 +
        r.loanAmount * 0.85 / 1200 +
        150;
    expect(piti, closeTo(2800, 0.01));
  });

  test('down payment outside [0, 100) returns null', () {
    for (final d in [100.0, 150.0, -5.0]) {
      expect(
        const AffordabilitySolver().maxPrice(
          targetPiti: 3000,
          rate: 6.5,
          termYears: 30,
          downPaymentPercent: d,
          taxRatePercent: 1.2,
          insuranceRatePercent: 0.5,
          hoaMonthly: 0,
          miAnnualPercent: 0,
        ),
        isNull,
      );
    }
  });

  testWidgets('Use this price sets price and down percent on provider', (
    tester,
  ) async {
    final provider = buildCalculatorProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<CalculatorProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: MaxPriceCard())),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('maxPriceTarget')), '3000');
    await tester.enterText(find.byKey(const Key('maxPriceRate')), '6.5');
    await tester.enterText(find.byKey(const Key('maxPriceTerm')), '30');
    await tester.enterText(find.byKey(const Key('maxPriceDown')), '10');
    await tester.enterText(find.byKey(const Key('maxPriceTax')), '1.2');
    await tester.enterText(find.byKey(const Key('maxPriceIns')), '0.5');
    await tester.enterText(find.byKey(const Key('maxPriceHoa')), '100');
    await tester.enterText(find.byKey(const Key('maxPriceMi')), '0.5');
    await tester.pump();
    await tester.ensureVisible(find.text('Use this price'));
    await tester.tap(find.text('Use this price'));
    await tester.pump();
    expect(provider.price, isNotNull);
    expect(provider.price!, greaterThan(300000));
    expect(provider.pitiPayment, closeTo(3000, 0.01));
    await tester.pumpAndSettle(const Duration(seconds: 2)); // debounce timers
  });
}
