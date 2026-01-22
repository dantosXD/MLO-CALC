import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';
import 'package:loan_ranger/src/features/qualification/application/providers/qualifying_ratios_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  group('Feature #15: Custom Qualifying Ratio Tests', () {
    late QualifyingRatiosProvider provider;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Create a fresh provider instance (loads asynchronously in constructor)
      provider = QualifyingRatiosProvider();
      // Wait for async loading to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('Add custom ratio with specific DTI values (31/43)', () async {
      // Arrange
      const name = 'FHA Expanded';
      const description = 'FHA expanded ratios for higher debt areas';
      const housingDTI = 31.0;
      const totalDTI = 43.0;

      // Act
      final addedRatio = await provider.addRatio(
        name: name,
        description: description,
        housingRatio: housingDTI,
        debtRatio: totalDTI,
      );

      // Assert
      expect(addedRatio.name, equals(name));
      expect(addedRatio.description, equals(description));
      expect(addedRatio.housingRatio, equals(housingDTI));
      expect(addedRatio.debtRatio, equals(totalDTI));
      expect(addedRatio.isBuiltIn, isFalse);

      // Verify it appears in allRatios
      final foundRatio = provider.allRatios.firstWhere(
        (r) => r.id == addedRatio.id,
      );
      expect(foundRatio.housingRatio, equals(31.0),
          reason: 'Housing DTI should be 31, not the default 28');
      expect(foundRatio.debtRatio, equals(43.0),
          reason: 'Total DTI should be 43, not the default 36');
    });

    test('Add custom ratio with custom values (25/38)', () async {
      // Arrange
      const housingDTI = 25.0;
      const totalDTI = 38.0;

      // Act
      final ratio = await provider.addRatio(
        name: 'Custom Conservative',
        housingRatio: housingDTI,
        debtRatio: totalDTI,
      );

      // Assert
      expect(ratio.housingRatio, equals(25.0),
          reason: 'Should preserve custom housing DTI of 25');
      expect(ratio.debtRatio, equals(38.0),
          reason: 'Should preserve custom total DTI of 38');
    });

    test('Add custom ratio with decimal values (28.5/41.5)', () async {
      // Arrange
      const housingDTI = 28.5;
      const totalDTI = 41.5;

      // Act
      final ratio = await provider.addRatio(
        name: 'Decimal Test',
        housingRatio: housingDTI,
        debtRatio: totalDTI,
      );

      // Assert
      expect(ratio.housingRatio, equals(28.5),
          reason: 'Should preserve decimal housing DTI');
      expect(ratio.debtRatio, equals(41.5),
          reason: 'Should preserve decimal total DTI');
    });

    test('Add custom ratio without description (optional field)', () async {
      // Act
      final ratio = await provider.addRatio(
        name: 'No Description Ratio',
        housingRatio: 30.0,
        debtRatio: 40.0,
      );

      // Assert
      expect(ratio.description, isNull);
      expect(ratio.housingRatio, equals(30.0));
      expect(ratio.debtRatio, equals(40.0));
    });

    test('Custom ratio persists after provider recreation', () async {
      // Arrange - Add a ratio
      final ratio = await provider.addRatio(
        name: 'Persistent Ratio',
        description: 'Should survive recreation',
        housingRatio: 33.0,
        debtRatio: 45.0,
      );

      // Act - Recreate provider (simulating app restart)
      final newProvider = QualifyingRatiosProvider();
      // Wait for async loading
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final persistedRatio = newProvider.allRatios.firstWhere(
        (r) => r.id == ratio.id,
        orElse: () => throw Exception('Ratio not found'),
      );

      expect(persistedRatio.name, equals('Persistent Ratio'));
      expect(persistedRatio.housingRatio, equals(33.0),
          reason: 'Persisted housing DTI should be 33');
      expect(persistedRatio.debtRatio, equals(45.0),
          reason: 'Persisted total DTI should be 45');
    });

    test('Add ratio with whitespace-only name', () async {
      // Act - Provider doesn't validate empty names, so it will add them
      final ratio = await provider.addRatio(
        name: '   ', // whitespace only
        housingRatio: 30.0,
        debtRatio: 40.0,
      );

      // Assert - Ratio is added with whitespace name
      expect(ratio.name, equals('   '));
      expect(ratio.housingRatio, equals(30.0));
      expect(ratio.debtRatio, equals(40.0));

      // Verify custom ratios count
      final customRatios = provider.allRatios.where((r) => !r.isBuiltIn);
      expect(customRatios.length, equals(1),
          reason: 'Provider adds ratio with whitespace name');
    });

    test('Update existing custom ratio with new DTI values', () async {
      // Arrange - Create initial ratio
      final initial = await provider.addRatio(
        name: 'Update Test',
        housingRatio: 28.0,
        debtRatio: 36.0,
      );

      // Act - Update with new values
      await provider.updateRatio(
        initial.copyWith(
          housingRatio: 35.0,
          debtRatio: 47.0,
        ),
      );

      // Assert
      final updated = provider.allRatios.firstWhere((r) => r.id == initial.id);
      expect(updated.housingRatio, equals(35.0),
          reason: 'Updated housing DTI should be 35');
      expect(updated.debtRatio, equals(47.0),
          reason: 'Updated total DTI should be 47');
    });

    test('Delete custom ratio removes it from list', () async {
      // Arrange
      final ratio = await provider.addRatio(
        name: 'Delete Me',
        housingRatio: 30.0,
        debtRatio: 40.0,
      );

      // Act
      await provider.deleteRatio(ratio.id);

      // Assert
      final exists = provider.allRatios.any((r) => r.id == ratio.id);
      expect(exists, isFalse,
          reason: 'Deleted ratio should not exist in list');
    });

    test('Cannot delete built-in ratio', () async {
      // Arrange - Get a built-in ratio
      final builtInRatio = provider.builtInRatios.first;

      // Act & Assert - Provider throws exception when trying to delete built-in
      expect(
        () => provider.deleteRatio(builtInRatio.id),
        throwsA(isA<Exception>()),
      );

      // Verify built-in ratio still exists
      final stillExists =
          provider.allRatios.any((r) => r.id == builtInRatio.id);
      expect(stillExists, isTrue,
          reason: 'Built-in ratios should not be deletable');
    });

    test('Duplicate built-in ratio creates custom copy', () async {
      // Arrange - Get FHA built-in ratio
      final fhaRatio = provider.builtInRatios.firstWhere(
        (r) => r.name.contains('FHA'),
      );

      // Act
      final duplicate = await provider.duplicateRatio(fhaRatio);

      // Assert
      expect(duplicate.id, isNot(equals(fhaRatio.id)),
          reason: 'Duplicate should have unique ID');
      expect(duplicate.isBuiltIn, isFalse,
          reason: 'Duplicate should be marked as custom');
      expect(duplicate.name, contains('Copy'),
          reason: 'Duplicate name should indicate copy');
      expect(duplicate.housingRatio, equals(fhaRatio.housingRatio),
          reason: 'Duplicate should preserve housing DTI');
      expect(duplicate.debtRatio, equals(fhaRatio.debtRatio),
          reason: 'Duplicate should preserve total DTI');
    });

    test('Multiple custom ratios maintain distinct values', () async {
      // Act - Add multiple ratios
      final ratio1 = await provider.addRatio(
        name: 'Ratio 1',
        housingRatio: 25.0,
        debtRatio: 35.0,
      );

      final ratio2 = await provider.addRatio(
        name: 'Ratio 2',
        housingRatio: 31.0,
        debtRatio: 43.0,
      );

      final ratio3 = await provider.addRatio(
        name: 'Ratio 3',
        housingRatio: 28.0,
        debtRatio: 41.0,
      );

      // Assert - Each maintains its own values
      expect(ratio1.housingRatio, equals(25.0));
      expect(ratio1.debtRatio, equals(35.0));

      expect(ratio2.housingRatio, equals(31.0));
      expect(ratio2.debtRatio, equals(43.0));

      expect(ratio3.housingRatio, equals(28.0));
      expect(ratio3.debtRatio, equals(41.0));

      // Verify all appear in allRatios
      final customRatios = provider.allRatios.where((r) => !r.isBuiltIn);
      expect(customRatios.length, equals(3),
          reason: 'Should have 3 custom ratios');
    });

    test('Select custom ratio updates selectedRatio', () async {
      // Arrange
      final custom = await provider.addRatio(
        name: 'Selection Test',
        housingRatio: 33.0,
        debtRatio: 45.0,
      );

      // Act
      provider.selectRatio(custom);

      // Assert
      expect(provider.selectedRatio?.id, equals(custom.id));
      expect(provider.selectedRatio?.housingRatio, equals(33.0));
      expect(provider.selectedRatio?.debtRatio, equals(45.0));
    });

    test('Get ratio by ID returns correct ratio', () async {
      // Arrange
      final ratio = await provider.addRatio(
        name: 'Lookup Test',
        housingRatio: 29.0,
        debtRatio: 39.0,
      );

      // Act
      final found = provider.getRatioById(ratio.id);

      // Assert
      expect(found, isNotNull);
      expect(found!.id, equals(ratio.id));
      expect(found.housingRatio, equals(29.0));
      expect(found.debtRatio, equals(39.0));
    });

    test('Regression test: Values should not default to 28/36',
        () async {
      // This test specifically addresses the regression reported
      // where custom DTI values were defaulting to 28/36

      final ratio = await provider.addRatio(
        name: 'Regression Test',
        housingRatio: 31.0,
        debtRatio: 43.0,
      );

      // These assertions should pass if regression is fixed
      expect(
        ratio.housingRatio,
        equals(31.0),
        reason:
            'FAILING: Housing DTI defaulted to 28 instead of 31 - REGRESSION',
      );
      expect(
        ratio.debtRatio,
        equals(43.0),
        reason:
            'FAILING: Total DTI defaulted to 36 instead of 43 - REGRESSION',
      );

      // Also verify it persists correctly
      final fromProvider =
          provider.allRatios.firstWhere((r) => r.id == ratio.id);
      expect(
        fromProvider.housingRatio,
        equals(31.0),
        reason: 'FAILING: Persisted housing DTI is 28 instead of 31',
      );
      expect(
        fromProvider.debtRatio,
        equals(43.0),
        reason: 'FAILING: Persisted total DTI is 36 instead of 43',
      );
    });
  });
}
