import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/features/arm/domain/models/arm_scenario.dart';
import 'package:loan_ranger/src/features/arm/domain/services/arm_preset_service.dart';

void main() {
  group('ArmPresetStorage — ARM scenario round-trips through SecureStore', () {
    late InMemorySecureStore secureStore;
    late ArmPresetStorage storage;

    const testScenario = ArmScenario(
      loanAmount: 400000.0,
      termYears: 30.0,
      initialRate: 5.5,
      initialFixedYears: 5.0,
      adjustmentFrequencyYears: 1.0,
      rateChangePerAdjustment: 0.25,
      periodicCap: 2.0,
      lifetimeCap: 5.0,
      lifetimeFloor: 2.0,
    );

    setUp(() {
      secureStore = InMemorySecureStore();
      storage = ArmPresetStorage(secureStore: secureStore);
    });

    test('save writes scenario JSON to SecureStore under key armScenario',
        () async {
      await storage.save(testScenario);

      final stored = await secureStore.read('armScenario');
      expect(stored, isNotNull);
      expect(stored, isNotEmpty);
    });

    test('load returns null when no scenario has been saved', () async {
      final result = await storage.load();
      expect(result, isNull);
    });

    test('full round-trip: save then load restores all fields', () async {
      await storage.save(testScenario);
      final loaded = await storage.load();

      expect(loaded, isNotNull);
      expect(loaded!.loanAmount, testScenario.loanAmount);
      expect(loaded.termYears, testScenario.termYears);
      expect(loaded.initialRate, testScenario.initialRate);
      expect(loaded.initialFixedYears, testScenario.initialFixedYears);
      expect(loaded.adjustmentFrequencyYears,
          testScenario.adjustmentFrequencyYears);
      expect(loaded.rateChangePerAdjustment,
          testScenario.rateChangePerAdjustment);
      expect(loaded.periodicCap, testScenario.periodicCap);
      expect(loaded.lifetimeCap, testScenario.lifetimeCap);
      expect(loaded.lifetimeFloor, testScenario.lifetimeFloor);
    });
  });
}
