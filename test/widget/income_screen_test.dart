import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/income/presentation/screens/income_screen.dart';
import 'package:provider/provider.dart';

import '../unit/calculator_provider_test.dart' show buildCalculatorProvider;

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  void bigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('Send to Qualification writes income x12 and debts', (
    tester,
  ) async {
    bigView(tester);
    final provider = buildCalculatorProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<CalculatorProvider>.value(
        value: provider,
        child: const MaterialApp(home: IncomeScreen()),
      ),
    );
    for (final e in {
      'inc_se_prior': '60000',
      'inc_se_recent': '72000',
      'inc_rent': '2000',
      'inc_pitia': '1200',
      'inc_sl_balance': '40000',
      'inc_other_debt': '100',
    }.entries) {
      await tester.enterText(find.byKey(Key(e.key)), e.value);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to Qualification'));
    await tester.pumpAndSettle();
    expect(provider.annualIncome, (5500 + 300) * 12);
    expect(provider.monthlyDebt, 500); // 100 other + 400 fannie student loan
  });

  testWidgets('button disabled without provider; no NaN', (tester) async {
    bigView(tester);
    await tester.pumpWidget(const MaterialApp(home: IncomeScreen()));
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
    expect(find.textContaining('NaN'), findsNothing);
  });
}
