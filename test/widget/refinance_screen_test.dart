import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/refinance/presentation/screens/refinance_screen.dart';

void main() {
  testWidgets('higher new rate shows Never, no NaN', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: RefinanceScreen()));
    for (final e in {
      'refi_balance': '300000',
      'refi_rate': '6',
      'refi_years': '28',
      'refi_new_rate': '7.5',
      'refi_new_term': '30',
      'refi_costs': '6000',
    }.entries) {
      await tester.enterText(find.byKey(Key(e.key)), e.value);
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('Never'), findsOneWidget);
    expect(find.textContaining('NaN'), findsNothing);
    expect(find.textContaining('Infinity'), findsNothing);
  });
}
