import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/core/services/connectivity_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_cache_service.dart';

class NlpSettingsProvider with ChangeNotifier {
  static const _keyName = 'geminiApiKey';

  NlpSettingsProvider({
    ConnectivityService? connectivity,
    NlpCacheService? cache,
    required NLPCalculatorService calculatorService,
    SecureStore? secureStore,
    PreferenceStore? preferenceStore,
  }) : _connectivity = connectivity ?? ConnectivityService(),
       _ownsConnectivity = connectivity == null,
       _cache = cache ?? NlpCacheService(),
       _calculatorService = calculatorService,
       _secureStore = secureStore ?? FlutterSecureStoreBackend(),
       _legacyStore = preferenceStore ?? PreferenceStore();

  final ConnectivityService _connectivity;
  final bool _ownsConnectivity;
  final NlpCacheService _cache;
  final NLPCalculatorService _calculatorService;
  final SecureStore _secureStore;
  final PreferenceStore _legacyStore;

  String? _apiKey;
  bool _loaded = false;
  Future<void>? _loadFuture;

  String? get apiKey => _apiKey;
  bool get isLoaded => _loaded;
  bool get hasKey => _apiKey != null && _apiKey!.isNotEmpty;

  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;

  NlpCacheService get cache => _cache;
  NLPCalculatorService get calculatorService => _calculatorService;
  int get pendingRequestCount => _cache.pendingCount;
  bool get hasPendingRequests => _cache.hasPendingRequests;

  Future<void> load() {
    return _loadFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    await _connectivity.initialize();
    _connectivity.addListener(_onConnectivityChanged);

    try {
      await _cache.load();

      _apiKey = await _secureStore.read(_keyName);
      if (_apiKey == null || _apiKey!.isEmpty) {
        await _legacyStore.load();
        final oldKey = _legacyStore.getString(_keyName);
        if (oldKey != null && oldKey.isNotEmpty) {
          _apiKey = oldKey;
          await _secureStore.write(key: _keyName, value: oldKey);
          await _legacyStore.remove(_keyName);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading API key: $e');
      }
      _apiKey = null;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  void _onConnectivityChanged() {
    notifyListeners();
  }

  Future<void> setApiKey(String? value) async {
    _apiKey = value?.trim();
    notifyListeners();

    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        await _secureStore.delete(_keyName);
        await _legacyStore.load();
        await _legacyStore.remove(_keyName);
      } else {
        await _secureStore.write(key: _keyName, value: _apiKey!);
        await _legacyStore.load();
        await _legacyStore.remove(_keyName);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving API key: $e');
      }
    }
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    if (_ownsConnectivity) {
      _connectivity.dispose();
    }
    super.dispose();
  }
}
