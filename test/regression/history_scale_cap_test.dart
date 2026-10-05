import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';

void main() {
  test('loading an oversized persisted history (5,000 entries) respects the cap', () {
    final src = CalculationHistory();
    final now = DateTime(2026, 1, 1);
    // Build the JSON directly so the source history's own cap does not apply.
    final entries = List.generate(
      5000,
      (i) => CalculationEntry(
        id: 'id$i',
        timestamp: now.subtract(Duration(minutes: i)),
        type: CalculationEntryType.payment,
        inputs: CalculationEntryInputs(
          loanAmount: 100000.0 + i,
          interestRate: 6.5,
          termYears: 30,
        ),
        results: CalculationEntryResults(payment: 632.07),
      ),
    );
    final json = '[${entries.map((e) => _enc(e)).join(',')}]';

    final sw = Stopwatch()..start();
    src.fromJsonString(json);
    sw.stop();

    expect(src.entries.length, CalculationHistory.maxEntries);
    expect(src.entries.first.id, 'id0'); // newest-first order preserved
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });
}

String _enc(CalculationEntry e) {
  final h = CalculationHistory()..addEntry(e);
  final s = h.toJsonString();
  return s.substring(1, s.length - 1);
}
