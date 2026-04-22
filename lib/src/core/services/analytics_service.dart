import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';

/// Analytics event types for tracking feature usage
enum AnalyticsEventType {
  // Calculator events
  paymentCalculation,
  loanAmountCalculation,
  termCalculation,
  interestRateCalculation,

  // Feature events
  amortizationGenerated,
  biWeeklyAnalysis,
  qualificationCalculation,
  armWizardUsed,
  rentVsBuyAnalysis,
  comparisonUsed,

  // NLP events
  nlpQuerySubmitted,
  nlpQueryFromCache,
  nlpQueryQueued,
  voiceInputUsed,

  // Program events
  programSelected,
  programCreated,
  programDuplicated,

  // UI events
  screenViewed,
  exportUsed,
  historyApplied,
}

/// Single analytics event
class AnalyticsEvent {
  final AnalyticsEventType type;
  final DateTime timestamp;
  final Map<String, Object?>? metadata;

  AnalyticsEvent({required this.type, required this.timestamp, this.metadata});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      type: AnalyticsEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnalyticsEventType.screenViewed,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: _metadataFromJson(json['metadata']),
    );
  }
}

/// Usage statistics aggregated by type
class UsageStats {
  final Map<AnalyticsEventType, int> eventCounts;
  final Map<String, int> screenViews;
  final Map<String, int> calculationTypes;
  final DateTime firstUseDate;
  final DateTime lastActiveDate;
  final int totalSessions;
  final int totalCalculations;

  UsageStats({
    required this.eventCounts,
    required this.screenViews,
    required this.calculationTypes,
    required this.firstUseDate,
    required this.lastActiveDate,
    required this.totalSessions,
    required this.totalCalculations,
  });

  String? get mostUsedFeature {
    if (eventCounts.isEmpty) return null;
    final sorted = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.name;
  }

  String? get mostCommonCalculation {
    if (calculationTypes.isEmpty) return null;
    final sorted = calculationTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  double get averageCalculationsPerSession {
    if (totalSessions == 0) return 0;
    return totalCalculations / totalSessions;
  }
}

/// Analytics service for tracking feature usage.
///
/// All data is stored locally - no external tracking.
class AnalyticsService {
  AnalyticsService({PreferenceStore? preferenceStore})
    : _preferences = preferenceStore ?? PreferenceStore();

  static const String _eventsKey = 'analytics_events';
  static const String _statsKey = 'analytics_stats';
  static const int _maxStoredEvents = 500;
  static const Duration _sessionTimeout = Duration(minutes: 30);
  static const Set<String> _allowedMetadataKeys = <String>{
    'screen',
    'calculationType',
    'feature',
    'featureId',
    'channel',
    'status',
    'action',
  };

  final PreferenceStore _preferences;

  List<AnalyticsEvent> _events = <AnalyticsEvent>[];
  DateTime? _lastActivity;
  bool _isLoaded = false;
  bool _analyticsEnabled = true;
  int _totalSessions = 0;
  DateTime? _firstUseDate;
  Future<void>? _loadFuture;

  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  bool get isLoaded => _isLoaded;
  bool get analyticsEnabled => _analyticsEnabled;

  Future<void> initialize() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      await _preferences.load();

      final eventsJson = _preferences.getString(_eventsKey);
      if (eventsJson != null && eventsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(eventsJson) as List<dynamic>;
        _events = decoded
            .map((e) => AnalyticsEvent.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      final statsJson = _preferences.getString(_statsKey);
      if (statsJson != null && statsJson.isNotEmpty) {
        final Map<String, dynamic> stats = Map<String, dynamic>.from(
          jsonDecode(statsJson) as Map,
        );
        _totalSessions = (stats['totalSessions'] as num?)?.toInt() ?? 0;
        _firstUseDate = stats['firstUseDate'] != null
            ? DateTime.parse(stats['firstUseDate'] as String)
            : null;
      }

      _startSession();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading analytics: $e');
      }
    } finally {
      _isLoaded = true;
    }
  }

  Future<void> _save() async {
    try {
      await _preferences.load();

      final trimmedEvents = _events.length > _maxStoredEvents
          ? _events.sublist(_events.length - _maxStoredEvents)
          : _events;
      final eventsJson = jsonEncode(
        trimmedEvents.map((e) => e.toJson()).toList(),
      );
      await _preferences.setString(_eventsKey, eventsJson);

      final statsJson = jsonEncode(<String, Object?>{
        'totalSessions': _totalSessions,
        'firstUseDate': _firstUseDate?.toIso8601String(),
      });
      await _preferences.setString(_statsKey, statsJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving analytics: $e');
      }
    }
  }

  void _startSession() {
    final now = DateTime.now();

    if (_lastActivity == null ||
        now.difference(_lastActivity!) > _sessionTimeout) {
      _totalSessions++;
      _firstUseDate ??= now;
    }

    _lastActivity = now;
  }

  void trackEvent(AnalyticsEventType type, {Map<String, Object?>? metadata}) {
    if (!_analyticsEnabled) return;

    final event = AnalyticsEvent(
      type: type,
      timestamp: DateTime.now(),
      metadata: _sanitizeMetadata(metadata),
    );

    _events.add(event);
    _lastActivity = DateTime.now();

    if (_events.length % 10 == 0) {
      unawaited(_save());
    }
  }

  void trackScreenView(String screenName) {
    trackEvent(
      AnalyticsEventType.screenViewed,
      metadata: <String, Object?>{'screen': screenName},
    );
  }

  void trackCalculation(
    String calculationType, {
    Map<String, Object?>? params,
  }) {
    final eventType = _calculationTypeToEvent(calculationType);
    final metadata = <String, Object?>{'calculationType': calculationType};
    final sanitized = _sanitizeMetadata(params);
    if (sanitized != null) {
      metadata.addAll(sanitized);
    }
    trackEvent(eventType, metadata: metadata);
  }

  AnalyticsEventType _calculationTypeToEvent(String type) {
    switch (type) {
      case 'payment':
        return AnalyticsEventType.paymentCalculation;
      case 'loan_amount':
        return AnalyticsEventType.loanAmountCalculation;
      case 'term':
        return AnalyticsEventType.termCalculation;
      case 'interest_rate':
        return AnalyticsEventType.interestRateCalculation;
      case 'qualification':
        return AnalyticsEventType.qualificationCalculation;
      default:
        return AnalyticsEventType.paymentCalculation;
    }
  }

  UsageStats getStats() {
    final eventCounts = <AnalyticsEventType, int>{};
    final screenViews = <String, int>{};
    final calculationTypes = <String, int>{};
    int totalCalculations = 0;

    for (final event in _events) {
      eventCounts[event.type] = (eventCounts[event.type] ?? 0) + 1;

      if (event.type == AnalyticsEventType.screenViewed) {
        final screen = event.metadata?['screen'] as String? ?? 'unknown';
        screenViews[screen] = (screenViews[screen] ?? 0) + 1;
      }

      if (_isCalculationEvent(event.type)) {
        totalCalculations++;
        final calcType =
            event.metadata?['calculationType'] as String? ?? event.type.name;
        calculationTypes[calcType] = (calculationTypes[calcType] ?? 0) + 1;
      }
    }

    return UsageStats(
      eventCounts: eventCounts,
      screenViews: screenViews,
      calculationTypes: calculationTypes,
      firstUseDate: _firstUseDate ?? DateTime.now(),
      lastActiveDate: _lastActivity ?? DateTime.now(),
      totalSessions: _totalSessions,
      totalCalculations: totalCalculations,
    );
  }

  bool _isCalculationEvent(AnalyticsEventType type) {
    return <AnalyticsEventType>[
      AnalyticsEventType.paymentCalculation,
      AnalyticsEventType.loanAmountCalculation,
      AnalyticsEventType.termCalculation,
      AnalyticsEventType.interestRateCalculation,
      AnalyticsEventType.qualificationCalculation,
    ].contains(type);
  }

  List<AnalyticsEvent> getRecentEvents(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _events.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  Map<AnalyticsEventType, int> getEventCountsByPeriod({
    DateTime? start,
    DateTime? end,
  }) {
    var filtered = _events;
    if (start != null) {
      filtered = filtered.where((e) => e.timestamp.isAfter(start)).toList();
    }
    if (end != null) {
      filtered = filtered.where((e) => e.timestamp.isBefore(end)).toList();
    }

    final counts = <AnalyticsEventType, int>{};
    for (final event in filtered) {
      counts[event.type] = (counts[event.type] ?? 0) + 1;
    }
    return counts;
  }

  void setAnalyticsEnabled(bool enabled) {
    _analyticsEnabled = enabled;
  }

  Future<void> clearAnalytics() async {
    _events.clear();
    _totalSessions = 0;
    _firstUseDate = null;
    await _save();
  }

  Future<void> flush() async {
    await _save();
  }

  Map<String, Object?>? _sanitizeMetadata(Map<String, Object?>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return null;
    }

    final sanitized = <String, Object?>{};
    metadata.forEach((key, value) {
      if (_allowedMetadataKeys.contains(key)) {
        sanitized[key] = value;
      }
    });

    return sanitized.isEmpty ? null : sanitized;
  }
}

Map<String, Object?>? _metadataFromJson(Object? raw) {
  if (raw is! Map) {
    return null;
  }

  return raw.map<String, Object?>(
    (Object? key, Object? value) =>
        MapEntry<String, Object?>(key.toString(), value),
  );
}
