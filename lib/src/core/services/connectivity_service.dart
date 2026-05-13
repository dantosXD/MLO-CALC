import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status
class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Future<void>? _initializeFuture;

  bool _isOnline = true;
  bool _isInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;

  ConnectivityService();

  Future<void> initialize() {
    return _initializeFuture ??= _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    final results = await _connectivity.checkConnectivity();
    _isInitialized = true;
    _updateStatus(results, notify: false);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    notifyListeners();
  }

  void _updateStatus(List<ConnectivityResult> results, {bool notify = true}) {
    final wasOnline = _isOnline;

    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      if (kDebugMode) {
        debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      }
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Manually check connectivity (useful for retry scenarios)
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return _isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
