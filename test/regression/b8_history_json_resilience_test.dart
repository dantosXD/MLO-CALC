// Regression: BUGLOG B8 — CalculationHistory.fromJsonString used a single
// try/catch around the entire parse loop. A corrupt entry mid-list caused
// _entries.clear() to have already run while the loop threw, silently losing
// all entries that followed the bad one. Additionally, a top-level parse
// failure (invalid JSON) also cleared in-memory history.
//
// Fix: per-entry try/catch + atomic swap (build a fresh list, replace _entries
// only on success) and early-return on top-level failure (don't touch
// existing in-memory state).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';

CalculationEntry _validEntry(String id) => CalculationEntry(
  id: id,
  timestamp: DateTime(2024, 1, 1),
  type: CalculationEntryType.payment,
  inputs: const CalculationEntryInputs(
    loanAmount: 100000,
    interestRate: 6.5,
    termYears: 30,
  ),
  results: const CalculationEntryResults(payment: 632.07),
);

void main() {
  group('B8: CalculationHistory.fromJsonString is resilient to corrupt data', () {
    test(
      'one corrupt entry mid-list: valid entries on either side are preserved',
      () {
        // Build a JSON list where entry[1] is corrupt (missing required 'id' field).
        final goodBefore = _validEntry('id-before').toJson();
        final corrupt = <String, dynamic>{
          // 'id' intentionally omitted → fromJson will throw
          'timestamp': '2024-01-01T00:00:00.000',
          'type': 'payment',
          'inputs': {},
          'results': {},
        };
        final goodAfter = _validEntry('id-after').toJson();

        final jsonStr = jsonEncode([goodBefore, corrupt, goodAfter]);

        final history = CalculationHistory();
        history.fromJsonString(jsonStr);

        expect(
          history.entries.length,
          2,
          reason: 'corrupt entry must be skipped; valid entries must survive',
        );
        expect(
          history.entries.map((e) => e.id),
          containsAll(['id-before', 'id-after']),
        );
      },
    );

    test(
      'completely invalid JSON leaves existing in-memory entries intact',
      () {
        final history = CalculationHistory();
        history.addEntry(_validEntry('pre-existing'));

        // Simulate corrupt storage (e.g., truncated write)
        history.fromJsonString('{not valid json[[[');

        expect(
          history.entries.length,
          1,
          reason: 'invalid JSON must not clear valid in-memory entries',
        );
        expect(history.entries.first.id, 'pre-existing');
      },
    );

    test('empty JSON array clears history normally', () {
      final history = CalculationHistory();
      history.addEntry(_validEntry('to-be-cleared'));
      history.fromJsonString('[]');
      expect(history.entries, isEmpty);
    });

    test('all-valid JSON replaces history atomically', () {
      final history = CalculationHistory();
      history.addEntry(_validEntry('old'));

      final newEntries = [
        _validEntry('new-1').toJson(),
        _validEntry('new-2').toJson(),
      ];
      history.fromJsonString(jsonEncode(newEntries));

      expect(history.entries.length, 2);
      expect(history.entries.map((e) => e.id), containsAll(['new-1', 'new-2']));
    });
  });
}
