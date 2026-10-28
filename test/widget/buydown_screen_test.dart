import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/buydown/presentation/screens/buydown_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: BuydownScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('zero loan shows dashes, never NaN', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('buydown_loan')), '0');
    await tester.enterText(find.byKey(const Key('buydown_rate')), '7');
    await tester.enterText(find.byKey(const Key('buydown_term')), '30');
    await tester.pumpAndSettle();
    expect(find.text('—'), findsWidgets);
    expect(find.textContaining('NaN'), findsNothing);
    expect(find.textContaining('Infinity'), findsNothing);
  });

  testWidgets('3-2-1 at 2.5% shows depth error', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('buydown_loan')), '400000');
    await tester.enterText(find.byKey(const Key('buydown_rate')), '2.5');
    await tester.enterText(find.byKey(const Key('buydown_term')), '30');
    await tester.tap(find.text('3-2-1'));
    await tester.pumpAndSettle();
    expect(find.text('Buydown exceeds note rate'), findsOneWidget);
  });

  testWidgets('2-1 shows subsidy and seller credit', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('buydown_loan')), '400000');
    await tester.enterText(find.byKey(const Key('buydown_rate')), '7');
    await tester.enterText(find.byKey(const Key('buydown_term')), '30');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Seller/builder credit needed: \$9,3'),
      findsOneWidget,
    );
  });
}
