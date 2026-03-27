import 'package:shared_preferences/shared_preferences.dart';

class PreferenceStore {
  PreferenceStore({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;

  bool get isLoaded => _preferences != null;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _prefs {
    final prefs = _preferences;
    if (prefs == null) {
      throw StateError('PreferenceStore has not been loaded');
    }
    return prefs;
  }

  String? getString(String key) => _preferences?.getString(key);

  double? getDouble(String key) => _preferences?.getDouble(key);

  bool? getBool(String key) => _preferences?.getBool(key);

  List<String>? getStringList(String key) => _preferences?.getStringList(key);

  Future<void> setString(String key, String value) async {
    await load();
    await _prefs.setString(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await load();
    await _prefs.setDouble(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await load();
    await _prefs.setBool(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await load();
    await _prefs.setStringList(key, value);
  }

  Future<void> remove(String key) async {
    await load();
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await load();
    await _prefs.clear();
  }
}
