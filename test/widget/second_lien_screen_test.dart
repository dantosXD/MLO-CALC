import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/second_lien/presentation/screens/second_lien_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: SecondLienScreen()));
  }

  testWidgets('empty inputs show dashes', (tester) async {
    await pump(tester);
    expect(find.text('Combined payment: —'), findsOneWidget);
    await tester.tap(find.text('HELOC'));
    await tester.pumpAndSettle();
    expect(find.text('Max line: —'), findsOneWidget);
    expect(find.textContaining('NaN'), findsNothing);
  });

  testWidgets('piggyback computes loans', (tester) async {
    await pump(tester);
    for (final e in {
      'sl_price': '500000',
      'sl_first_rate': '6.5',
      'sl_second_rate': '9',
      'sl_second_term': '15',
    }.entries) {
      await tester.enterText(find.byKey(Key(e.key)), e.value);
    }
    await tester.pumpAndSettle();
    expect(find.text('First loan: \$400,000.00'), findsOneWidget);
    expect(find.text('Second loan: \$50,000.00'), findsOneWidget);
  });

  testWidgets('heloc warns when draw exceeds line', (tester) async {
    await pump(tester);
    await tester.tap(find.text('HELOC'));
    await tester.pumpAndSettle();
    for (final e in {
      'hl_value': '600000',
      'hl_first': '350000',
      'hl_draw': '200000',
      'hl_rate': '8',
      'hl_repay': '20',
    }.entries) {
      await tester.enterText(find.byKey(Key(e.key)), e.value);
    }
    await tester.pumpAndSettle();
    expect(find.text('Draw exceeds available line'), findsOneWidget);
  });

  testWidgets('tab inputs persist across tab switches', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('sl_price')), '500000');
    await tester.tap(find.text('HELOC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Piggyback'));
    await tester.pumpAndSettle();
    expect(find.text('500000'), findsOneWidget);
  });
}
