import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/updater/application/providers/update_notifier.dart';
import 'package:loan_ranger/src/features/updater/domain/models/release_info.dart';
import 'package:loan_ranger/src/features/updater/domain/models/update_check_result.dart';
import 'package:loan_ranger/src/features/updater/domain/services/update_service.dart';

class _SlowService extends UpdateService {
  _SlowService(this.info) : super(currentVersion: '1.0.0');
  final ReleaseInfo info;
  final gate = Completer<void>();
  int downloads = 0;

  @override
  Future<UpdateCheckResult> checkForUpdate() async =>
      UpdateCheckResult.available(info);

  @override
  Future<void> downloadAndInstall(ReleaseInfo i, void Function(double) p) {
    downloads++;
    return gate.future;
  }
}

void main() {
  final info = ReleaseInfo(version: '2.0.0', releaseNotes: '', apkDownloadUrl: 'x');

  test('double-tapping Install starts only one download', () async {
    final svc = _SlowService(info);
    final n = UpdateNotifier(service: svc);
    await n.checkForUpdate();
    final first = n.install();
    await Future<void>.delayed(Duration.zero);
    await n.install(); // second tap while downloading
    svc.gate.complete();
    await first;
    expect(svc.downloads, 1);
  });

  test('release without an APK asset surfaces an error, not a silent no-op', () {
    final svc = UpdateService(currentVersion: '1.0.0');
    expect(
      svc.downloadAndInstall(
        ReleaseInfo(version: '2.0.0', releaseNotes: '', apkDownloadUrl: null),
        (_) {},
      ),
      throwsA(isA<Exception>()),
    );
  });
}
