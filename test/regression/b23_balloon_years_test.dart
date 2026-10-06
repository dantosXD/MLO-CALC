import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/analysis/presentation/screens/analysis_screen.dart';

void main() {
  test('balloon year must be inside the loan term', () {
    expect(balloonYearsError(7, 30), isNull);
    expect(balloonYearsError(29.5, 30), isNull);
    expect(balloonYearsError(30, 30), isNotNull);
    expect(balloonYearsError(40, 30), isNotNull);
    expect(balloonYearsError(0, 30), isNotNull);
    expect(balloonYearsError(null, 30), isNotNull);
  });
}
