import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MloProfileProvider> _build() async {
  SharedPreferences.setMockInitialValues({});
  final p = MloProfileProvider(
    preferenceStore: PreferenceStore(),
    secureStore: InMemorySecureStore(),
  );
  await p.load();
  await p.saveBranding(
    applyUrl: 'https://apply.example.com',
    logoUrl: 'https://example.com/logo.png',
  );
  return p;
}

void main() {
  final png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    ),
  );

  test('404 returns false and keeps cache', () async {
    final p = await _build();
    final ok = await p.refreshLogo(
      client: MockClient((_) async => http.Response('nope', 404)),
    );
    expect(ok, isFalse);
    expect(p.logoBytesBase64, isEmpty);
  });

  test('200 caches bytes; later failure keeps them', () async {
    final p = await _build();
    expect(
      await p.refreshLogo(
        client: MockClient((_) async => http.Response.bytes(png, 200)),
      ),
      isTrue,
    );
    expect(p.logoBytesBase64, base64Encode(png));
    expect(p.toBrandInfo().logo, png);
    expect(
      await p.refreshLogo(
        client: MockClient((_) async => http.Response('x', 500)),
      ),
      isFalse,
    );
    expect(p.logoBytesBase64, base64Encode(png));
  });

  test('SocketException returns false', () async {
    final p = await _build();
    final ok = await p.refreshLogo(
      client: MockClient((_) async => throw const SocketException('down')),
    );
    expect(ok, isFalse);
  });

  test('non-image body rejected and old bytes kept', () async {
    final p = await _build();
    await p.refreshLogo(
      client: MockClient((_) async => http.Response.bytes(png, 200)),
    );
    final ok = await p.refreshLogo(
      client: MockClient((_) async => http.Response('<html>login</html>', 200)),
    );
    expect(ok, isFalse);
    expect(p.logoBytesBase64, base64Encode(png));
  });

  test('oversize body rejected', () async {
    final p = await _build();
    final ok = await p.refreshLogo(
      client: MockClient(
        (_) async => http.Response.bytes(Uint8List(500 * 1024 + 1), 200),
      ),
    );
    expect(ok, isFalse);
  });

  test('token map has applyUrl and labelled apply line', () async {
    final p = await _build();
    expect(p.toTokenMap()['applyUrl'], 'https://apply.example.com');
    expect(p.toTokenMap()['apply_line'], 'Apply: https://apply.example.com');
    await p.saveBranding(applyUrl: '', logoUrl: '');
    expect(p.toTokenMap()['apply_line'], '');
  });
}
