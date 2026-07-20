import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loan_ranger/src/features/updater/domain/services/update_service.dart';

void main() {
  group('UpdateService.isNewer', () {
    test('returns true when remote is newer', () {
      expect(UpdateService.isNewer('1.1.0', '1.0.0'), isTrue);
    });

    test('returns false when same version', () {
      expect(UpdateService.isNewer('1.0.0', '1.0.0'), isFalse);
    });

    test('returns false when remote is older', () {
      expect(UpdateService.isNewer('0.9.0', '1.0.0'), isFalse);
    });

    test('strips leading v from remote version', () {
      expect(UpdateService.isNewer('v1.1.0', '1.0.0'), isTrue);
    });

    test('handles patch version bump', () {
      expect(UpdateService.isNewer('1.0.1', '1.0.0'), isTrue);
    });

    test('handles major version bump', () {
      expect(UpdateService.isNewer('2.0.0', '1.9.9'), isTrue);
    });
  });

  group('UpdateService.checkForUpdate', () {
    test('returns ReleaseInfo when newer version exists', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.1.0',
            'body': 'Bug fixes',
            'assets': [
              {
                'name': 'app-release.apk',
                'browser_download_url': 'https://example.com/app.apk',
              },
            ],
          }),
          200,
        );
      });
      final service = UpdateService(httpClient: client, currentVersion: '1.0.0');
      final info = await service.checkForUpdate();
      expect(info, isNotNull);
      expect(info!.version, '1.1.0');
      expect(info.apkDownloadUrl, 'https://example.com/app.apk');
      expect(info.releaseNotes, 'Bug fixes');
    });

    test('returns null when already on latest', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'tag_name': 'v1.0.0', 'body': '', 'assets': []}),
          200,
        );
      });
      final service = UpdateService(httpClient: client, currentVersion: '1.0.0');
      final info = await service.checkForUpdate();
      expect(info, isNull);
    });

    test('returns null on network error without throwing', () async {
      final client = MockClient(
        (request) async => throw Exception('no network'),
      );
      final service = UpdateService(httpClient: client, currentVersion: '1.0.0');
      final info = await service.checkForUpdate();
      expect(info, isNull);
    });

    test('returns null on non-200 response', () async {
      final client = MockClient(
        (request) async => http.Response('Not found', 404),
      );
      final service = UpdateService(httpClient: client, currentVersion: '1.0.0');
      final info = await service.checkForUpdate();
      expect(info, isNull);
    });

    test('apkDownloadUrl is null when no apk asset', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.1.0',
            'body': '',
            'assets': [
              {
                'name': 'source.zip',
                'browser_download_url': 'https://example.com/source.zip',
              },
            ],
          }),
          200,
        );
      });
      final service = UpdateService(httpClient: client, currentVersion: '1.0.0');
      final info = await service.checkForUpdate();
      expect(info, isNotNull);
      expect(info!.apkDownloadUrl, isNull);
    });
  });
}
