import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'nlp_calculator_service.dart';

/// Cache service for NLP responses to enable offline functionality
class NlpCacheService {
  static const String _cacheKey = 'nlp_response_cache';
  static const String _queueKey = 'nlp_pending_queue';
  static const int _maxCacheSize = 50;
  static const Duration _cacheExpiry = Duration(days: 7);

  /// Cached response with metadata
  List<CachedNlpResponse> _cache = [];
  List<PendingNlpRequest> _pendingQueue = [];
  bool _isLoaded = false;

  List<CachedNlpResponse> get cache => List.unmodifiable(_cache);
  List<PendingNlpRequest> get pendingQueue => List.unmodifiable(_pendingQueue);
  int get pendingCount => _pendingQueue.length;
  bool get hasPendingRequests => _pendingQueue.isNotEmpty;

  /// Load cache from storage
  Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cache
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson != null) {
        final List<dynamic> decoded = jsonDecode(cacheJson);
        _cache = decoded
            .map((e) => CachedNlpResponse.fromJson(e))
            .where((e) => !e.isExpired)
            .toList();
      }
      
      // Load pending queue
      final queueJson = prefs.getString(_queueKey);
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _pendingQueue = decoded
            .map((e) => PendingNlpRequest.fromJson(e))
            .toList();
      }
      
      _isLoaded = true;
    } catch (e) {
      _cache = [];
      _pendingQueue = [];
      _isLoaded = true;
    }
  }

  /// Save cache to storage
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save cache
      final cacheJson = jsonEncode(_cache.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, cacheJson);
      
      // Save queue
      final queueJson = jsonEncode(_pendingQueue.map((e) => e.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      // Silently fail
    }
  }

  /// Get cached response for a query (fuzzy matching)
  CachedNlpResponse? getCachedResponse(String query) {
    final normalizedQuery = _normalizeQuery(query);
    
    for (final cached in _cache) {
      if (!cached.isExpired && _queriesMatch(cached.normalizedQuery, normalizedQuery)) {
        return cached;
      }
    }
    return null;
  }

  /// Cache a response
  Future<void> cacheResponse(String query, CalculationRequest response) async {
    await load();
    
    final normalizedQuery = _normalizeQuery(query);
    
    // Remove existing cache for same query
    _cache.removeWhere((e) => _queriesMatch(e.normalizedQuery, normalizedQuery));
    
    // Add new cache entry
    _cache.insert(0, CachedNlpResponse(
      query: query,
      normalizedQuery: normalizedQuery,
      response: response,
      cachedAt: DateTime.now(),
    ));
    
    // Trim cache to max size
    if (_cache.length > _maxCacheSize) {
      _cache = _cache.sublist(0, _maxCacheSize);
    }
    
    await _save();
  }

  /// Add a request to the pending queue (for offline processing later)
  Future<void> queueRequest(String query) async {
    await load();
    
    // Avoid duplicates
    if (_pendingQueue.any((p) => p.query == query)) return;
    
    _pendingQueue.add(PendingNlpRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      query: query,
      queuedAt: DateTime.now(),
    ));
    
    await _save();
  }

  /// Remove a request from the pending queue
  Future<void> removeFromQueue(String id) async {
    _pendingQueue.removeWhere((p) => p.id == id);
    await _save();
  }

  /// Clear the pending queue
  Future<void> clearQueue() async {
    _pendingQueue.clear();
    await _save();
  }

  /// Get all pending requests for processing
  List<PendingNlpRequest> getPendingRequests() {
    return List.from(_pendingQueue);
  }

  /// Normalize query for matching
  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Check if two normalized queries are similar enough
  bool _queriesMatch(String a, String b) {
    // Exact match
    if (a == b) return true;
    
    // Extract key numbers and check if they match
    final numbersA = RegExp(r'\d+\.?\d*').allMatches(a).map((m) => m.group(0)).toSet();
    final numbersB = RegExp(r'\d+\.?\d*').allMatches(b).map((m) => m.group(0)).toSet();
    
    if (numbersA.isEmpty || numbersB.isEmpty) return false;
    
    // If all numbers match and queries have similar keywords, consider it a match
    if (numbersA.containsAll(numbersB) && numbersB.containsAll(numbersA)) {
      // Check for similar intent keywords
      final keywords = ['payment', 'loan', 'rate', 'term', 'income', 'qualify', 'max', 'min'];
      final keywordsA = keywords.where((k) => a.contains(k)).toSet();
      final keywordsB = keywords.where((k) => b.contains(k)).toSet();
      
      return keywordsA.intersection(keywordsB).isNotEmpty;
    }
    
    return false;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _cache.clear();
    await _save();
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

  Map<String, dynamic> toJson() => {
    'query': query,
    'normalizedQuery': normalizedQuery,
    'response': response.toJson(),
    'cachedAt': cachedAt.toIso8601String(),
  };

  factory CachedNlpResponse.fromJson(Map<String, dynamic> json) {
    return CachedNlpResponse(
      query: json['query'],
      normalizedQuery: json['normalizedQuery'],
      response: CalculationRequest.fromJson(json['response']),
      cachedAt: DateTime.parse(json['cachedAt']),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory PendingNlpRequest.fromJson(Map<String, dynamic> json) {
    return PendingNlpRequest(
      id: json['id'],
      query: json['query'],
      queuedAt: DateTime.parse(json['queuedAt']),
    );
  }
}
