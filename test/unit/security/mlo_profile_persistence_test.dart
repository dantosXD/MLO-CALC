import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MloProfileProvider — PII round-trips through SecureStore', () {
    late InMemorySecureStore secureStore;
    late PreferenceStore preferenceStore;
    late MloProfileProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      secureStore = InMemorySecureStore();
      preferenceStore = PreferenceStore();
      provider = MloProfileProvider(
        preferenceStore: preferenceStore,
        secureStore: secureStore,
      );
    });

    test('saveProfile writes PII fields to SecureStore', () async {
      await provider.saveProfile(
        name: 'Jane Doe',
        nmls: '1234567',
        company: 'Acme Lending',
        phone: '555-123-4567',
        email: 'jane@example.com',
      );

      expect(await secureStore.read('mlo_name'), 'Jane Doe');
      expect(await secureStore.read('mlo_nmls'), '1234567');
      expect(await secureStore.read('mlo_phone'), '555-123-4567');
      expect(await secureStore.read('mlo_email'), 'jane@example.com');
    });

    test('saveProfile does NOT write PII fields to PreferenceStore', () async {
      await provider.saveProfile(
        name: 'Jane Doe',
        nmls: '1234567',
        company: 'Acme Lending',
        phone: '555-123-4567',
        email: 'jane@example.com',
      );

      // PII keys must be absent from plaintext preference store
      expect(preferenceStore.getString('mlo_name'), isNull);
      expect(preferenceStore.getString('mlo_nmls'), isNull);
      expect(preferenceStore.getString('mlo_phone'), isNull);
      expect(preferenceStore.getString('mlo_email'), isNull);
    });

    test('saveProfile writes non-PII company to PreferenceStore', () async {
      await provider.saveProfile(
        name: 'Jane Doe',
        nmls: '1234567',
        company: 'Acme Lending',
        phone: '555-123-4567',
        email: 'jane@example.com',
      );

      expect(preferenceStore.getString('mlo_company'), 'Acme Lending');
    });

    test('load reads PII fields back from SecureStore', () async {
      // Pre-populate secure store directly
      await secureStore.write(key: 'mlo_name', value: 'Bob Builder');
      await secureStore.write(key: 'mlo_nmls', value: '9876543');
      await secureStore.write(key: 'mlo_phone', value: '555-987-6543');
      await secureStore.write(key: 'mlo_email', value: 'bob@example.com');

      await provider.load();

      expect(provider.mloName, 'Bob Builder');
      expect(provider.mloNmls, '9876543');
      expect(provider.mloPhone, '555-987-6543');
      expect(provider.mloEmail, 'bob@example.com');
    });

    test('full round-trip: save then load restores all fields', () async {
      await provider.saveProfile(
        name: 'Alice Smith',
        nmls: '1111111',
        company: 'Best Bank',
        phone: '555-000-0001',
        email: 'alice@bestbank.com',
      );

      // Create a fresh provider and load from stores
      final provider2 = MloProfileProvider(
        preferenceStore: preferenceStore,
        secureStore: secureStore,
      );
      await provider2.load();

      expect(provider2.mloName, 'Alice Smith');
      expect(provider2.mloNmls, '1111111');
      expect(provider2.mloCompany, 'Best Bank');
      expect(provider2.mloPhone, '555-000-0001');
      expect(provider2.mloEmail, 'alice@bestbank.com');
    });
  });
}
