import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loan_ranger/src/core/services/connectivity_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_cache_service.dart';

class NlpSettingsProvider with ChangeNotifier {
  static const _keyName = 'geminiApiKey';
  // Use secure storage for sensitive data like API keys
  final _storage = const FlutterSecureStorage();
  final ConnectivityService _connectivity = ConnectivityService();
  final NlpCacheService _cache = NlpCacheService();

  String? _apiKey;
  bool _loaded = false;

  NlpSettingsProvider() {
    _load();
    _connectivity.addListener(_onConnectivityChanged);
  }

  String? get apiKey => _apiKey;
  bool get isLoaded => _loaded;
  bool get hasKey => (_apiKey != null && _apiKey!.isNotEmpty);
  
  // Connectivity status
  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;
  
  // Cache access
  NlpCacheService get cache => _cache;
  int get pendingRequestCount => _cache.pendingCount;
  bool get hasPendingRequests => _cache.hasPendingRequests;

  void _onConnectivityChanged() {
    notifyListeners();
  }

  Future<void> setApiKey(String? value) async {
    _apiKey = value?.trim();
    notifyListeners();
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        await _storage.delete(key: _keyName);
      } else {
        await _storage.write(key: _keyName, value: _apiKey!);
      }
    } catch (e) {
      debugPrint('Error saving API key: $e');
    }
  }

  Future<void> _load() async {
    try {
      // Load cache
      await _cache.load();
      
      // First try to load from secure storage
      _apiKey = await _storage.read(key: _keyName);
      
      // Migration: If not found in secure storage, check SharedPreferences (old location)
      if (_apiKey == null) {
        final prefs = await SharedPreferences.getInstance();
        final oldKey = prefs.getString(_keyName);
        if (oldKey != null && oldKey.isNotEmpty) {
          // Migrate to secure storage
          _apiKey = oldKey;
          await _storage.write(key: _keyName, value: oldKey);
          await prefs.remove(_keyName); // Remove from insecure storage
        }
      }
    } catch (e) {
      debugPrint('Error loading API key: $e');
      _apiKey = null;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _connectivity.dispose();
    super.dispose();
  }
}
