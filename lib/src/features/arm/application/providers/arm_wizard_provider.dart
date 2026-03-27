import 'package:flutter/material.dart';

import '../../domain/models/arm_scenario.dart';
import '../../domain/services/arm_calculator_service.dart';
import '../../domain/services/arm_preset_service.dart';

class ArmWizardProvider extends ChangeNotifier {
  ArmWizardProvider({
    required ArmCalculatorService calculator,
    required ArmPresetStorage presetStorage,
  })  : _calculator = calculator,
        _presetStorage = presetStorage;

  final ArmCalculatorService _calculator;
  final ArmPresetStorage _presetStorage;

  ArmScenario _scenario = const ArmScenario(
    loanAmount: 450000,
    termYears: 30,
    initialRate: 5.25,
    initialFixedYears: 5,
    adjustmentFrequencyYears: 1,
    rateChangePerAdjustment: 1,
    periodicCap: 2,
    lifetimeCap: 9,
    lifetimeFloor: 2.5,
  );

  ArmScheduleResult? _result;
  bool _loading = false;

  ArmScenario get scenario => _scenario;
  ArmScheduleResult? get result => _result;
  bool get isLoading => _loading;

  void updateScenario(ArmScenario scenario) {
    _scenario = scenario;
    notifyListeners();
  }

  Future<void> calculate() async {
    _loading = true;
    notifyListeners();
    _result = _calculator.calculateSchedule(_scenario);
    _loading = false;
    notifyListeners();
  }

  Future<void> savePreset() async {
    await _presetStorage.save(_scenario);
  }

  Future<void> loadPreset() async {
    final stored = await _presetStorage.load();
    if (stored != null) {
      _scenario = stored;
      notifyListeners();
    }
  }
}
