@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/features/comparison/presentation/screens/comparison_screen.dart';

// Allows up to 3 % cross-platform pixel variance (Windows vs Linux CI).
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile, {required this.precisionTolerance});

  final double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final bool passed =
        result.passed || result.diffPercent <= precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

void main() {
  setUpAll(() {
    goldenFileComparator = _TolerantComparator(
      Uri.file('test/golden/comparison_screen_golden_test.dart'),
      precisionTolerance: 0.03,
    );
  });

  testWidgets('comparison screen golden snapshot', (tester) async {
    final entries = [
      CalculationEntry(
        id: 'a',
        timestamp: DateTime(2024, 1, 1),
        type: 'payment',
        inputs: {
          'loanAmount': 300000.0,
          'interestRate': 5.2,
          'termYears': 30.0,
          'payment': 1650.0,
          'price': 375000.0,
        },
        results: {'payment': 1650.0},
      ),
      CalculationEntry(
        id: 'b',
        timestamp: DateTime(2024, 1, 2),
        type: 'payment',
        inputs: {
          'loanAmount': 320000.0,
          'interestRate': 6.4,
          'termYears': 30.0,
          'payment': 2000.0,
          'price': 400000.0,
        },
        results: {'payment': 2000.0},
      ),
    ];

    final data = ComparisonData.fromEntries(entries);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: ComparisonScreen(data: data),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ComparisonScreen),
      matchesGoldenFile('../goldens/comparison_screen.png'),
    );
  });
}
