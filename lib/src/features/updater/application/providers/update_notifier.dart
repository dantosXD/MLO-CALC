import 'package:flutter/foundation.dart';

import '../../domain/models/release_info.dart';
import '../../domain/models/update_check_result.dart';
import '../../domain/services/update_service.dart';

enum UpdateState { idle, checking, updateAvailable, downloading, error }

class UpdateNotifier extends ChangeNotifier {
  UpdateNotifier({required UpdateService service}) : _service = service;

  final UpdateService _service;

  UpdateState _state = UpdateState.idle;
  ReleaseInfo? _releaseInfo;
  String? _errorMessage;
  double _downloadProgress = 0;
  bool _dialogDismissed = false;

  UpdateState get state => _state;
  ReleaseInfo? get releaseInfo => _releaseInfo;
  String? get errorMessage => _errorMessage;
  double get downloadProgress => _downloadProgress;
  bool get dialogDismissed => _dialogDismissed;

  Future<void> checkForUpdate() async {
    _state = UpdateState.checking;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.checkForUpdate();
    switch (result) {
      case UpdateAvailableResult(:final info):
        _releaseInfo = info;
        _state = UpdateState.updateAvailable;
      case UpToDateResult():
        _releaseInfo = null;
        _state = UpdateState.idle;
      case UpdateErrorResult(:final message):
        _errorMessage = message;
        _state = UpdateState.error;
    }
    notifyListeners();
  }

  Future<bool> canInstallApk() => _service.canInstallApk();
  Future<void> openInstallPermissionSetting() =>
      _service.openInstallPermissionSetting();

  Future<void> install() async {
    final info = _releaseInfo;
    if (info == null) return;

    final canInstall = await _service.canInstallApk();
    if (!canInstall) {
      await _service.openInstallPermissionSetting();
      _errorMessage =
          'Please enable "Allow from this source" in Settings to install updates, then try again.';
      _state = UpdateState.error;
      notifyListeners();
      return;
    }

    _state = UpdateState.downloading;
    _downloadProgress = 0;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.downloadAndInstall(info, (progress) {
        _downloadProgress = progress;
        notifyListeners();
      });
      _state = UpdateState.idle;
      _releaseInfo = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Download or installation failed: $e';
      _state = UpdateState.error;
      notifyListeners();
    }
  }

  void retryFromError() {
    if (_state != UpdateState.error) return;
    if (_releaseInfo != null) {
      _state = UpdateState.updateAvailable;
    } else {
      _state = UpdateState.idle;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void dismissDialog() {
    _dialogDismissed = true;
    notifyListeners();
  }

  void resetDialogDismissed() {
    _dialogDismissed = false;
    notifyListeners();
  }
}
