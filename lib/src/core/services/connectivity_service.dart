import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status
class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true;
  bool _isInitialized = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Get initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    _isInitialized = true;
    
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    notifyListeners();
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    // Consider online if any non-none connection exists
    _isOnline = results.any((result) => 
      result != ConnectivityResult.none
    );
    
    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
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
