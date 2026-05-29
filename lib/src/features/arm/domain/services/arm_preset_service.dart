import '../models/arm_scenario.dart';
import '../../../../core/persistence/secure_store.dart';

class ArmPresetStorage {
  ArmPresetStorage({required SecureStore secureStore}) : _store = secureStore;

  static const String _storageKey = 'armScenario';

  final SecureStore _store;

  Future<void> save(ArmScenario scenario) async {
    await _store.write(key: _storageKey, value: scenario.toJsonString());
  }

  Future<ArmScenario?> load() async {
    final value = await _store.read(_storageKey);
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
