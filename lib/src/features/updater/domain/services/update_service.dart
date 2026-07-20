import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/release_info.dart';

class UpdateService {
  UpdateService({http.Client? httpClient, String? currentVersion})
      : _client = httpClient ?? http.Client(),
        _currentVersion = currentVersion;

  static const _apiUrl =
      'https://api.github.com/repos/dantosXD/MLO-CALC/releases/latest';

  final http.Client _client;
  final String? _currentVersion;

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
    final parts = v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }

  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final response = await _client.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = data['tag_name'] as String? ?? '';
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      final current = _currentVersion ?? '0.0.0';
      if (!isNewer(tag, current)) return null;
      final assets = (data['assets'] as List<dynamic>? ?? []);
      final apkAsset = assets
          .cast<Map<String, dynamic>>()
          .where((a) => (a['name'] as String).endsWith('.apk'))
          .firstOrNull;
      return ReleaseInfo(
        version: version,
        releaseNotes: data['body'] as String? ?? '',
        apkDownloadUrl: apkAsset?['browser_download_url'] as String?,
      );
    } catch (_) {
      return null;
    }
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
    await OpenFile.open(file.path);
  }
}
