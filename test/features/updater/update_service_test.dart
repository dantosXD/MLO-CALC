import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loan_ranger/src/features/updater/domain/models/update_check_result.dart';
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

    test('handles build metadata and pre-release tags', () {
      expect(UpdateService.isNewer('v1.0.1-beta', '1.0.0+1'), isTrue);
      expect(UpdateService.isNewer('1.0.0+2', '1.0.0+1'), isFalse);
    });
  });

  group('UpdateService.checkForUpdate', () {
    test('returns UpdateAvailableResult when newer version exists', () async {
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
      final service =
          UpdateService(httpClient: client, currentVersion: '1.0.0');
      final result = await service.checkForUpdate();
      expect(result, isA<UpdateAvailableResult>());
      final available = result as UpdateAvailableResult;
      expect(available.info.version, '1.1.0');
      expect(available.info.apkDownloadUrl, 'https://example.com/app.apk');
      expect(available.info.releaseNotes, 'Bug fixes');
    });

    test('returns UpToDateResult when already on latest', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'tag_name': 'v1.0.0', 'body': '', 'assets': []}),
          200,
        );
      });
      final service =
          UpdateService(httpClient: client, currentVersion: '1.0.0');
      final result = await service.checkForUpdate();
      expect(result, isA<UpToDateResult>());
    });

    test('returns UpdateErrorResult on network error without throwing',
        () async {
      final client = MockClient(
        (request) async => throw Exception('no network'),
      );
      final service =
          UpdateService(httpClient: client, currentVersion: '1.0.0');
      final result = await service.checkForUpdate();
      expect(result, isA<UpdateErrorResult>());
      expect((result as UpdateErrorResult).message, contains('no network'));
    });

    test('returns UpdateErrorResult on 404 response', () async {
      final client = MockClient(
        (request) async => http.Response('Not found', 404),
      );
      final service =
          UpdateService(httpClient: client, currentVersion: '1.0.0');
      final result = await service.checkForUpdate();
      expect(result, isA<UpdateErrorResult>());
      expect((result as UpdateErrorResult).message, contains('404'));
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
      final service =
          UpdateService(httpClient: client, currentVersion: '1.0.0');
      final result = await service.checkForUpdate();
      expect(result, isA<UpdateAvailableResult>());
      expect((result as UpdateAvailableResult).info.apkDownloadUrl, isNull);
    });
  });
}
