import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/updater/application/providers/update_notifier.dart';
import 'package:loan_ranger/src/features/updater/domain/models/release_info.dart';
import 'package:loan_ranger/src/features/updater/domain/models/update_check_result.dart';
import 'package:loan_ranger/src/features/updater/domain/services/update_service.dart';

class _FakeService extends UpdateService {
  _FakeService({this.result, this.throwOnInstall = false})
      : super(currentVersion: '1.0.0');
  final UpdateCheckResult? result;
  final bool throwOnInstall;

  @override
  Future<UpdateCheckResult> checkForUpdate() async =>
      result ?? const UpdateCheckResult.upToDate();

  @override
  Future<void> downloadAndInstall(
    ReleaseInfo info,
    void Function(double) onProgress,
  ) async {
    if (throwOnInstall) throw Exception('network failure');
    onProgress(0.5);
    onProgress(1.0);
  }
}

void main() {
  test('starts idle', () {
    final n = UpdateNotifier(service: _FakeService());
    expect(n.state, UpdateState.idle);
    expect(n.releaseInfo, isNull);
  });

  test('transitions to updateAvailable when newer version exists', () async {
    final info = ReleaseInfo(
      version: '1.1.0',
      releaseNotes: '',
      apkDownloadUrl: null,
    );
    final n = UpdateNotifier(
      service: _FakeService(result: UpdateCheckResult.available(info)),
    );
    await n.checkForUpdate();
    expect(n.state, UpdateState.updateAvailable);
    expect(n.releaseInfo, info);
  });

  test('stays idle when no update', () async {
    final n = UpdateNotifier(service: _FakeService());
    await n.checkForUpdate();
    expect(n.state, UpdateState.idle);
  });

  test('dismissDialog sets dialogDismissed', () {
    final n = UpdateNotifier(service: _FakeService());
    expect(n.dialogDismissed, isFalse);
    n.dismissDialog();
    expect(n.dialogDismissed, isTrue);
  });

  test('resetDialogDismissed clears dialogDismissed', () {
    final n = UpdateNotifier(service: _FakeService());
    n.dismissDialog();
    n.resetDialogDismissed();
    expect(n.dialogDismissed, isFalse);
  });

  test('install reports download progress', () async {
    final info = ReleaseInfo(
      version: '1.1.0',
      releaseNotes: '',
      apkDownloadUrl: 'http://x.com/a.apk',
    );
    final n = UpdateNotifier(
      service: _FakeService(result: UpdateCheckResult.available(info)),
    );
    await n.checkForUpdate();
    await n.install();
    expect(n.downloadProgress, 1.0);
  });

  test('install failure transitions to error state', () async {
    final info = ReleaseInfo(
      version: '1.1.0',
      releaseNotes: '',
      apkDownloadUrl: 'http://x.com/a.apk',
    );
    final n = UpdateNotifier(
      service: _FakeService(
        result: UpdateCheckResult.available(info),
        throwOnInstall: true,
      ),
    );
    await n.checkForUpdate();
    await n.install();
    expect(n.state, UpdateState.error);
  });

  test('retryFromError resets to updateAvailable', () async {
    final info = ReleaseInfo(
      version: '1.1.0',
      releaseNotes: '',
      apkDownloadUrl: 'http://x.com/a.apk',
    );
    final n = UpdateNotifier(
      service: _FakeService(
        result: UpdateCheckResult.available(info),
        throwOnInstall: true,
      ),
    );
    await n.checkForUpdate();
    await n.install();
    expect(n.state, UpdateState.error);
    n.retryFromError();
    expect(n.state, UpdateState.updateAvailable);
  });
}
