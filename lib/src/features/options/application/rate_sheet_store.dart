import 'dart:convert';

import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';

class RateSheetStore {
  RateSheetStore(this._prefs);

  static const key = 'options_rate_sheet';
  final PreferenceStore _prefs;

  RateSheet load() {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return const RateSheet({});
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return RateSheet({
        for (final e in map.entries)
          if (e.value is num) e.key: (e.value as num).toDouble(),
      });
    } catch (_) {
      return const RateSheet({});
    }
  }

  Future<void> save(RateSheet s) =>
      _prefs.setString(key, jsonEncode(s.ratesByProgramId));
}
