import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/features/comparison/presentation/screens/comparison_screen.dart';

void main() {
  testWidgets('Comparison screen renders cards and sliders', (tester) async {
    final entries = [
      CalculationEntry(
        id: 'a',
        timestamp: DateTime.now(),
        type: 'payment',
        inputs: {
          'loanAmount': 280000.0,
          'interestRate': 4.8,
          'termYears': 30.0,
          'payment': 1468.0,
          'price': 350000.0,
        },
        results: {'payment': 1468.0},
      ),
      CalculationEntry(
        id: 'b',
        timestamp: DateTime.now(),
        type: 'payment',
        inputs: {
          'loanAmount': 310000.0,
          'interestRate': 5.5,
          'termYears': 30.0,
          'payment': 1760.0,
          'price': 380000.0,
        },
        results: {'payment': 1760.0},
      ),
    ];

    final data = ComparisonData.fromEntries(entries);

    await tester.pumpWidget(MaterialApp(home: ComparisonScreen(data: data)));

    expect(find.text('Scenario Comparison'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(find.byType(Slider), findsNWidgets(3));

    await tester.drag(
      find.byType(Slider).first,
      const Offset(100, 0),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.textContaining('Adj Payment'), findsWidgets);
  });
}
