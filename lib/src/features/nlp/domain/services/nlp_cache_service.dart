import 'dart:convert';

import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';

import 'nlp_calculator_service.dart';

/// Cache service for NLP responses to enable offline functionality.
class NlpCacheService {
  NlpCacheService({
    SecureStore? secureStore,
    PreferenceStore? preferenceStore,
  })  : _secureStore = secureStore ?? FlutterSecureStoreBackend(),
        _legacyStore = preferenceStore ?? PreferenceStore();

  static const String _cacheKey = 'nlp_response_cache';
  static const String _queueKey = 'nlp_pending_queue';
  static const String _legacyCacheKey = 'nlp_response_cache';
  static const String _legacyQueueKey = 'nlp_pending_queue';
  static const int _maxCacheSize = 50;
  static const Duration _cacheExpiry = Duration(days: 7);

  final SecureStore _secureStore;
  final PreferenceStore _legacyStore;

  List<CachedNlpResponse> _cache = <CachedNlpResponse>[];
  List<PendingNlpRequest> _pendingQueue = <PendingNlpRequest>[];
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  List<CachedNlpResponse> get cache => List.unmodifiable(_cache);
  List<PendingNlpRequest> get pendingQueue => List.unmodifiable(_pendingQueue);
  int get pendingCount => _pendingQueue.length;
  bool get hasPendingRequests => _pendingQueue.isNotEmpty;

  Future<void> load() {
    return _loadFuture ??= _loadInternal();
  }

  Future<void> _loadInternal() async {
    if (_isLoaded) return;

    try {
      final secureCacheJson = await _secureStore.read(_cacheKey);
      final secureQueueJson = await _secureStore.read(_queueKey);

      if (secureCacheJson != null || secureQueueJson != null) {
        _cache = _decodeCache(secureCacheJson);
        _pendingQueue = _decodeQueue(secureQueueJson);
      } else {
        await _legacyStore.load();
        _cache = _decodeCache(_legacyStore.getString(_legacyCacheKey));
        _pendingQueue = _decodeQueue(_legacyStore.getString(_legacyQueueKey));
        await _save();
        await _legacyStore.remove(_legacyCacheKey);
        await _legacyStore.remove(_legacyQueueKey);
      }
    } catch (_) {
      _cache = <CachedNlpResponse>[];
      _pendingQueue = <PendingNlpRequest>[];
    } finally {
      _isLoaded = true;
    }
  }

  Future<void> _save() async {
    try {
      final cacheJson = jsonEncode(_cache.map((e) => e.toJson()).toList());
      final queueJson =
          jsonEncode(_pendingQueue.map((e) => e.toJson()).toList());
      await _secureStore.write(key: _cacheKey, value: cacheJson);
      await _secureStore.write(key: _queueKey, value: queueJson);
    } catch (_) {}
  }

  CachedNlpResponse? getCachedResponse(String query) {
    final normalizedQuery = _normalizeQuery(query);

    for (final cached in _cache) {
      if (!cached.isExpired &&
          _queriesMatch(cached.normalizedQuery, normalizedQuery)) {
        return cached;
      }
    }
    return null;
  }

  Future<void> cacheResponse(String query, CalculationRequest response) async {
    await load();

    final normalizedQuery = _normalizeQuery(query);
    _cache.removeWhere((e) => _queriesMatch(e.normalizedQuery, normalizedQuery));
    _cache.insert(
      0,
      CachedNlpResponse(
        query: query,
        normalizedQuery: normalizedQuery,
        response: response,
        cachedAt: DateTime.now(),
      ),
    );

    if (_cache.length > _maxCacheSize) {
      _cache = _cache.sublist(0, _maxCacheSize);
    }

    await _save();
  }

  Future<void> queueRequest(String query) async {
    await load();

    if (_pendingQueue.any((p) => p.query == query)) return;

    _pendingQueue.add(
      PendingNlpRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        query: query,
        queuedAt: DateTime.now(),
      ),
    );

    await _save();
  }

  Future<void> removeFromQueue(String id) async {
    _pendingQueue.removeWhere((p) => p.id == id);
    await _save();
  }

  Future<void> clearQueue() async {
    _pendingQueue.clear();
    await _save();
  }

  List<PendingNlpRequest> getPendingRequests() {
    return List<PendingNlpRequest>.from(_pendingQueue);
  }

  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _queriesMatch(String a, String b) {
    if (a == b) return true;

    final numbersA =
        RegExp(r'\d+\.?\d*').allMatches(a).map((m) => m.group(0)).toSet();
    final numbersB =
        RegExp(r'\d+\.?\d*').allMatches(b).map((m) => m.group(0)).toSet();

    if (numbersA.isEmpty || numbersB.isEmpty) return false;

    if (numbersA.containsAll(numbersB) && numbersB.containsAll(numbersA)) {
      const keywords = [
        'payment',
        'loan',
        'rate',
        'term',
        'income',
        'qualify',
        'max',
        'min',
      ];
      final keywordsA = keywords.where((k) => a.contains(k)).toSet();
      final keywordsB = keywords.where((k) => b.contains(k)).toSet();
      return keywordsA.intersection(keywordsB).isNotEmpty;
    }

    return false;
  }

  Future<void> clearCache() async {
    _cache.clear();
    await _save();
  }

  List<CachedNlpResponse> _decodeCache(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return <CachedNlpResponse>[];
    }

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => CachedNlpResponse.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => !e.isExpired)
          .toList();
    } catch (_) {
      return <CachedNlpResponse>[];
    }
  }

  List<PendingNlpRequest> _decodeQueue(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return <PendingNlpRequest>[];
    }

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => PendingNlpRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <PendingNlpRequest>[];
    }
  }
}

class CachedNlpResponse {
  final String query;
  final String normalizedQuery;
  final CalculationRequest response;
  final DateTime cachedAt;

  CachedNlpResponse({
    required this.query,
    required this.normalizedQuery,
    required this.response,
    required this.cachedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > NlpCacheService._cacheExpiry;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'query': query,
        'normalizedQuery': normalizedQuery,
        'response': response.toJson(),
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory CachedNlpResponse.fromJson(Map<String, dynamic> json) {
    return CachedNlpResponse(
      query: json['query'] as String,
      normalizedQuery: json['normalizedQuery'] as String,
      response: CalculationRequest.fromJson(
        Map<String, dynamic>.from(json['response'] as Map),
      ),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}

class PendingNlpRequest {
  final String id;
  final String query;
  final DateTime queuedAt;

  PendingNlpRequest({
    required this.id,
    required this.query,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'query': query,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory PendingNlpRequest.fromJson(Map<String, dynamic> json) {
    return PendingNlpRequest(
      id: json['id'] as String,
      query: json['query'] as String,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
    );
  }
}
