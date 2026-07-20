import 'package:flutter/foundation.dart';

import '../../domain/models/release_info.dart';
import '../../domain/services/update_service.dart';

enum UpdateState { idle, checking, updateAvailable, downloading, error }

class UpdateNotifier extends ChangeNotifier {
  UpdateNotifier({required UpdateService service}) : _service = service;

  final UpdateService _service;

  UpdateState _state = UpdateState.idle;
  ReleaseInfo? _releaseInfo;
  double _downloadProgress = 0;
  bool _dialogDismissed = false;

  UpdateState get state => _state;
  ReleaseInfo? get releaseInfo => _releaseInfo;
  double get downloadProgress => _downloadProgress;
  bool get dialogDismissed => _dialogDismissed;

  Future<void> checkForUpdate() async {
    _state = UpdateState.checking;
    notifyListeners();
    final info = await _service.checkForUpdate();
    if (info != null) {
      _releaseInfo = info;
      _state = UpdateState.updateAvailable;
    } else {
      _state = UpdateState.idle;
    }
    notifyListeners();
  }

  Future<void> install() async {
    final info = _releaseInfo;
    if (info == null) return;
    _state = UpdateState.downloading;
    _downloadProgress = 0;
    notifyListeners();
    await _service.downloadAndInstall(info, (progress) {
      _downloadProgress = progress;
      notifyListeners();
    });
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
