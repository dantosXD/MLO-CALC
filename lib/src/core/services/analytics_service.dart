import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Map<String, dynamic>? metadata;

  AnalyticsEvent({
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
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
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] as Map<String, dynamic>?,
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

  /// Most used feature
  String? get mostUsedFeature {
    if (eventCounts.isEmpty) return null;
    final sorted = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.name;
  }

  /// Most common calculation type
  String? get mostCommonCalculation {
    if (calculationTypes.isEmpty) return null;
    final sorted = calculationTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Average calculations per session
  double get averageCalculationsPerSession {
    if (totalSessions == 0) return 0;
    return totalCalculations / totalSessions;
  }
}

/// Analytics service for tracking feature usage
/// 
/// All data is stored locally - no external tracking.
class AnalyticsService with ChangeNotifier {
  static const String _eventsKey = 'analytics_events';
  static const String _statsKey = 'analytics_stats';
  static const int _maxStoredEvents = 500;
  static const Duration _sessionTimeout = Duration(minutes: 30);

  List<AnalyticsEvent> _events = [];
  DateTime? _lastActivity;
  bool _isLoaded = false;
  bool _analyticsEnabled = true;

  // Aggregated stats
  int _totalSessions = 0;
  DateTime? _firstUseDate;

  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  bool get isLoaded => _isLoaded;
  bool get analyticsEnabled => _analyticsEnabled;

  AnalyticsService() {
    _load();
  }

  /// Load stored analytics data
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load events
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final List<dynamic> decoded = jsonDecode(eventsJson);
        _events = decoded
            .map((e) => AnalyticsEvent.fromJson(e))
            .toList();
      }
      
      // Load stats
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        final stats = jsonDecode(statsJson);
        _totalSessions = stats['totalSessions'] ?? 0;
        _firstUseDate = stats['firstUseDate'] != null
            ? DateTime.parse(stats['firstUseDate'])
            : null;
      }
      
      // Start new session
      _startSession();
      
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save analytics data
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save events (trim to max size)
      final trimmedEvents = _events.length > _maxStoredEvents
          ? _events.sublist(_events.length - _maxStoredEvents)
          : _events;
      final eventsJson = jsonEncode(trimmedEvents.map((e) => e.toJson()).toList());
      await prefs.setString(_eventsKey, eventsJson);
      
      // Save stats
      final statsJson = jsonEncode({
        'totalSessions': _totalSessions,
        'firstUseDate': _firstUseDate?.toIso8601String(),
      });
      await prefs.setString(_statsKey, statsJson);
      
    } catch (e) {
      debugPrint('Error saving analytics: $e');
    }
  }

  /// Start a new session
  void _startSession() {
    final now = DateTime.now();
    
    // Check if this is a new session
    if (_lastActivity == null || 
        now.difference(_lastActivity!) > _sessionTimeout) {
      _totalSessions++;
      _firstUseDate ??= now;
    }
    
    _lastActivity = now;
  }

  /// Track an analytics event
  void trackEvent(
    AnalyticsEventType type, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_analyticsEnabled) return;
    
    final event = AnalyticsEvent(
      type: type,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    _events.add(event);
    _lastActivity = DateTime.now();
    
    // Save periodically (not on every event to reduce I/O)
    if (_events.length % 10 == 0) {
      _save();
    }
    
    notifyListeners();
  }

  /// Track a screen view
  void trackScreenView(String screenName) {
    trackEvent(
      AnalyticsEventType.screenViewed,
      metadata: {'screen': screenName},
    );
  }

  /// Track a calculation
  void trackCalculation(String calculationType, {Map<String, dynamic>? params}) {
    final eventType = _calculationTypeToEvent(calculationType);
    trackEvent(eventType, metadata: {
      'calculationType': calculationType,
      ...?params,
    });
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

  /// Get aggregated usage statistics
  UsageStats getStats() {
    final eventCounts = <AnalyticsEventType, int>{};
    final screenViews = <String, int>{};
    final calculationTypes = <String, int>{};
    int totalCalculations = 0;

    for (final event in _events) {
      // Count by event type
      eventCounts[event.type] = (eventCounts[event.type] ?? 0) + 1;
      
      // Count screen views
      if (event.type == AnalyticsEventType.screenViewed) {
        final screen = event.metadata?['screen'] as String? ?? 'unknown';
        screenViews[screen] = (screenViews[screen] ?? 0) + 1;
      }
      
      // Count calculation types
      if (_isCalculationEvent(event.type)) {
        totalCalculations++;
        final calcType = event.metadata?['calculationType'] as String? ?? 
            event.type.name;
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
    return [
      AnalyticsEventType.paymentCalculation,
      AnalyticsEventType.loanAmountCalculation,
      AnalyticsEventType.termCalculation,
      AnalyticsEventType.interestRateCalculation,
      AnalyticsEventType.qualificationCalculation,
    ].contains(type);
  }

  /// Get events from the last N days
  List<AnalyticsEvent> getRecentEvents(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _events.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Get event count by type for a time period
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

  /// Toggle analytics on/off
  void setAnalyticsEnabled(bool enabled) {
    _analyticsEnabled = enabled;
    notifyListeners();
  }

  /// Clear all analytics data
  Future<void> clearAnalytics() async {
    _events.clear();
    _totalSessions = 0;
    _firstUseDate = null;
    await _save();
    notifyListeners();
  }

  /// Force save (call on app pause/close)
  Future<void> flush() async {
    await _save();
  }
}
