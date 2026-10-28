import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/options/application/rate_sheet_store.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';
import 'package:loan_ranger/src/features/options/domain/services/options_builder.dart';
import 'package:loan_ranger/src/features/options/presentation/screens/options_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/calculator_provider_test.dart' show buildCalculatorProvider;

Future<void> _fill(WidgetTester t, Map<String, String> v) async {
  for (final e in v.entries) {
    await t.enterText(find.byKey(Key(e.key)), e.value);
  }
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  Future<CalculatorProvider> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(1200, 4000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferenceStore();
    await prefs.load();
    final calc = buildCalculatorProvider();
    await t.pumpWidget(
      ChangeNotifierProvider<CalculatorProvider>.value(
        value: calc,
        child: MaterialApp(
          home: OptionsScreen(rateStore: RateSheetStore(prefs)),
        ),
      ),
    );
    return calc;
  }

  testWidgets('empty form shows dashes and PDF disabled', (t) async {
    await pump(t);
    expect(find.text('—'), findsWidgets);
    expect(find.textContaining('NaN'), findsNothing);
    final btn = t.widget<FilledButton>(find.byKey(const Key('opt_pdf')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('filled form renders cards; save adds N entries', (t) async {
    final calc = await pump(t);
    await _fill(t, {
      'opt_price': '400000',
      'opt_cash': '80000',
      'opt_income': '120000',
      'opt_rate_conventional_30': '6.5',
      'opt_rate_fha_30': '6.25',
    });
    final cards = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'opt_card_"),
    );
    expect(cards, findsAtLeastNWidgets(2));
    final saveBtn = find.byKey(const Key('opt_save'));
    expect(t.widget<FilledButton>(saveBtn).onPressed, isNull);
    final checks = find.byType(Checkbox);
    final selectable = find.byWidgetPredicate(
      (w) => w is Checkbox && w.key.toString().contains('opt_sel_'),
    );
    await t.tap(selectable.at(0));
    await t.tap(selectable.at(1));
    await t.pumpAndSettle();
    expect(checks, findsWidgets);
    expect(
      t.widget<FilledButton>(find.byKey(const Key('opt_pdf'))).onPressed,
      isNotNull,
    );
    await t.tap(saveBtn);
    await t.pumpAndSettle();
    expect(calc.historyController.entries.length, 2);
  });

  testWidgets('save converts MI to annual and sets term', (t) async {
    final calc = await pump(t);
    await _fill(t, {
      'opt_price': '400000',
      'opt_cash': '90000',
      'opt_income': '120000',
      'opt_rate_fha_30': '6.25',
      'opt_rate_conventional_15': '5.75',
    });
    for (final id in ['fha_30', 'conventional_15']) {
      final sel = find.byWidgetPredicate(
        (w) =>
            w is Checkbox &&
            w.key.toString().contains('opt_sel_') &&
            w.key.toString().contains(id),
      );
      expect(sel, findsWidgets, reason: id);
      await t.tap(sel.first);
    }
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('opt_save')));
    await t.pumpAndSettle();
    final es = calc.historyController.entries;
    expect(es.length, 2);
    final fha = es.firstWhere((e) => e.notes!.contains('FHA'));
    expect(fha.inputs.termYears, 30);
    final expected = const OptionsBuilder()
        .build(
          const MemberProfile(
            price: 400000,
            cashAvailable: 90000,
            annualIncome: 120000,
          ),
          const RateSheet({'fha_30': 6.25, 'conventional_15': 5.75}),
        )
        .firstWhere((o) => o.programId == 'fha_30');
    expect(expected.monthlyMi, greaterThan(0));
    expect(
      fha.inputs.mortgageInsurance,
      closeTo(expected.monthlyMi * 12, 0.001),
    );
    final c15 = es.firstWhere((e) => e.inputs.termYears == 15);
    expect(c15.inputs.interestRate, 5.75);
  });
}
