import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/features/options/application/rate_sheet_store.dart';
import 'package:loan_ranger/src/features/options/domain/models/member_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('round-trips rates', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RateSheetStore(PreferenceStore());
    await store.save(const RateSheet({'fha_30': 6.25}));
    expect(store.load().ratesByProgramId, {'fha_30': 6.25});
  });

  test('corrupt JSON loads empty sheet', () async {
    SharedPreferences.setMockInitialValues({'options_rate_sheet': '{oops'});
    final prefs = PreferenceStore();
    await prefs.load();
    expect(RateSheetStore(prefs).load().ratesByProgramId, isEmpty);
  });
}
