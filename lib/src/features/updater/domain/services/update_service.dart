import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/release_info.dart';
import '../models/update_check_result.dart';

class UpdateService {
  UpdateService({http.Client? httpClient, String currentVersion = '0.0.0'})
      : _client = httpClient ?? http.Client(),
        _currentVersion = currentVersion;

  static const _apiUrl =
      'https://api.github.com/repos/dantosXD/MLO-CALC/releases/latest';

  final http.Client _client;
  final String _currentVersion;

  static bool isNewer(String remoteTag, String current) {
    final remote =
        remoteTag.startsWith('v') ? remoteTag.substring(1) : remoteTag;
    final r = _parseSemver(remote);
    final c = _parseSemver(current);
    for (var i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parseSemver(String v) {
    // Strip build metadata (+...) and pre-release suffix (-...)
    final clean = v.split('+').first.split('-').first.trim();
    final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }

  static const _timeout = Duration(seconds: 10);

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final response = await _client
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return const UpdateCheckResult.error(
          'No release published on GitHub yet (HTTP 404)',
        );
      }
      if (response.statusCode != 200) {
        return UpdateCheckResult.error(
          'GitHub API returned HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = data['tag_name'] as String? ?? '';
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      final current = _currentVersion;

      if (!isNewer(tag, current)) {
        return const UpdateCheckResult.upToDate();
      }

      final assets = (data['assets'] as List<dynamic>? ?? []);
      final apkAsset = assets
          .cast<Map<String, dynamic>>()
          .where((a) => (a['name'] as String).endsWith('.apk'))
          .firstOrNull;

      return UpdateCheckResult.available(
        ReleaseInfo(
          version: version,
          releaseNotes: data['body'] as String? ?? '',
          apkDownloadUrl: apkAsset?['browser_download_url'] as String?,
        ),
      );
    } catch (e) {
      debugPrint('UpdateService: checkForUpdate failed — $e');
      return UpdateCheckResult.error('Connection failed: $e');
    }
  }

  static const MethodChannel _installerChannel =
      MethodChannel('com.loanranger.calculator/package_installer');

  Future<bool> canInstallApk() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final allowed =
          await _installerChannel.invokeMethod<bool>('canRequestPackageInstalls');
      return allowed ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openInstallPermissionSetting() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _installerChannel.invokeMethod('openInstallPermissionSetting');
    } catch (_) {}
  }

  Future<void> downloadAndInstall(
    ReleaseInfo info,
    void Function(double progress) onProgress,
  ) async {
    if (kIsWeb) {
      final url = Uri.parse(
        'https://github.com/dantosXD/MLO-CALC/releases/tag/v${info.version}',
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    final apkUrl = info.apkDownloadUrl;
    if (apkUrl == null) return;

    final request = http.Request('GET', Uri.parse(apkUrl));
    final response = await _client.send(request);
    final total = response.contentLength ?? 0;
    var received = 0;

    final tmpDir = await getTemporaryDirectory();
    final apkDir = Directory('${tmpDir.path}/apk_downloads');
    await apkDir.create(recursive: true);
    final file = File('${apkDir.path}/update.apk');
    final sink = file.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress(received / total);
    }
    await sink.close();

    if (Platform.isAndroid) {
      try {
        final success = await _installerChannel.invokeMethod<bool>(
          'installApk',
          {'filePath': file.path},
        );
        if (success == true) return;
      } catch (e) {
        debugPrint('UpdateService: Native install failed: $e, falling back to OpenFile');
      }
    }

    final openResult = await OpenFile.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (openResult.type != ResultType.done) {
      throw Exception(
        openResult.message.isNotEmpty
            ? openResult.message
            : 'Could not launch package installer (${openResult.type})',
      );
    }
  }
}

