import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:uuid/uuid.dart';
import 'package:loan_ranger/src/core/models/qualifying_ratio.dart';

/// Provider to manage qualifying ratios with persistence
class QualifyingRatiosProvider with ChangeNotifier {
  static const String _storageKey = 'qualifying_ratios_custom';
  static const String _selectedKey = 'qualifying_ratio_selected';
  
  final Uuid _uuid = const Uuid();
  final PreferenceStore _preferences;
  
  List<QualifyingRatio> _customRatios = [];
  QualifyingRatio? _selectedRatio;
  bool _isLoading = true;

  QualifyingRatiosProvider({PreferenceStore? preferenceStore})
      : _preferences = preferenceStore ?? PreferenceStore();

  // Getters
  bool get isLoading => _isLoading;
  List<QualifyingRatio> get builtInRatios => DefaultQualifyingRatios.ratios;
  List<QualifyingRatio> get customRatios => _customRatios;
  List<QualifyingRatio> get allRatios => [...builtInRatios, ..._customRatios];
  QualifyingRatio? get selectedRatio => _selectedRatio;
  
  /// Load custom ratios from storage
  Future<void> load() async {
    try {
      await _preferences.load();

      final ratiosJson = _preferences.getString(_storageKey);
      if (ratiosJson != null) {
        final List<dynamic> decoded = jsonDecode(ratiosJson);
        _customRatios = decoded
            .map((e) => QualifyingRatio.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      final selectedId = _preferences.getString(_selectedKey);
      if (selectedId != null) {
        _selectedRatio = allRatios.firstWhere(
          (r) => r.id == selectedId,
          orElse: () => builtInRatios.first,
        );
      } else {
        _selectedRatio = builtInRatios.first;
      }
    } catch (e) {
      debugPrint('Error loading qualifying ratios: $e');
      _selectedRatio = builtInRatios.first;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save custom ratios to storage
  Future<void> _saveRatios() async {
    try {
      await _preferences.load();
      final ratiosJson = jsonEncode(_customRatios.map((r) => r.toJson()).toList());
      await _preferences.setString(_storageKey, ratiosJson);
    } catch (e) {
      debugPrint('Error saving qualifying ratios: $e');
    }
  }

  /// Select a qualifying ratio
  Future<void> selectRatio(QualifyingRatio ratio) async {
    _selectedRatio = ratio;
    notifyListeners();
    
    try {
      await _preferences.load();
      await _preferences.setString(_selectedKey, ratio.id);
    } catch (e) {
      debugPrint('Error saving selected ratio: $e');
    }
  }

  /// Add a new custom ratio
  Future<QualifyingRatio> addRatio({
    required String name,
    String? description,
    required double housingRatio,
    required double debtRatio,
  }) async {
    final ratio = QualifyingRatio(
      id: _uuid.v4(),
      name: name,
      description: description,
      housingRatio: housingRatio,
      debtRatio: debtRatio,
      isBuiltIn: false,
    );
    
    _customRatios.add(ratio);
    notifyListeners();
    await _saveRatios();
    return ratio;
  }

  /// Update an existing custom ratio
  Future<void> updateRatio(QualifyingRatio updatedRatio) async {
    if (updatedRatio.isBuiltIn) return; // Can't edit built-in ratios
    
    final index = _customRatios.indexWhere((r) => r.id == updatedRatio.id);
    if (index != -1) {
      _customRatios[index] = updatedRatio;
      
      // Update selected if it was the one being edited
      if (_selectedRatio?.id == updatedRatio.id) {
        _selectedRatio = updatedRatio;
      }
      
      notifyListeners();
      await _saveRatios();
    }
  }

  /// Delete a custom ratio
  Future<void> deleteRatio(String ratioId) async {
    final ratio = _customRatios.firstWhere(
      (r) => r.id == ratioId,
      orElse: () => throw Exception('Ratio not found'),
    );
    
    if (ratio.isBuiltIn) return; // Can't delete built-in ratios
    
    _customRatios.removeWhere((r) => r.id == ratioId);
    
    // If deleted ratio was selected, select first built-in
    if (_selectedRatio?.id == ratioId) {
      _selectedRatio = builtInRatios.first;
      await _preferences.load();
      await _preferences.setString(_selectedKey, _selectedRatio!.id);
    }
    
    notifyListeners();
    await _saveRatios();
  }

  /// Duplicate an existing ratio (creates custom copy)
  Future<QualifyingRatio> duplicateRatio(QualifyingRatio original) async {
    return addRatio(
      name: '${original.name} (Copy)',
      description: original.description,
      housingRatio: original.housingRatio,
      debtRatio: original.debtRatio,
    );
  }

  /// Get a ratio by ID
  QualifyingRatio? getRatioById(String id) {
    final matches = allRatios.where((r) => r.id == id);
    return matches.isEmpty ? null : matches.first;
  }
}
