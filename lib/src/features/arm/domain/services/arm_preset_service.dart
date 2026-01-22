import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/arm_scenario.dart';

class ArmPresetStorage {
  static const String _storageKey = 'armScenario';

  Future<void> save(ArmScenario scenario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, scenario.toJsonString());
  }

  Future<ArmScenario?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return ArmScenario.fromJsonString(value);
    } catch (_) {
      return null;
    }
  }
}
