import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/presentation/screens/rent_vs_buy_screen.dart';

void main() {
  testWidgets('renders the rent vs buy screen shell', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RentVsBuyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Rent vs Buy Analysis'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.calculate), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
  });

  testWidgets('accepts a fractional term and shows a result', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: RentVsBuyScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '30').first, '7.5');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    // Scroll down to reveal the results section which renders below the button
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.textContaining('Renting May Be Better'), findsOneWidget);
    expect(find.textContaining('Break-even:'), findsOneWidget);
  });
}
