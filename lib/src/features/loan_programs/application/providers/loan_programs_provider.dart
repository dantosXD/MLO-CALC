import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/loan_program.dart';

class LoanProgramsProvider with ChangeNotifier {
  static const String _storageKey = 'loan_programs_custom';
  static const String _selectedKey = 'loan_program_selected';
  
  final Uuid _uuid = const Uuid();
  final PreferenceStore _preferences;
  
  List<LoanProgram> _customPrograms = [];
  LoanProgram? _selectedProgram;
  bool _isLoading = true;

  LoanProgramsProvider({PreferenceStore? preferenceStore})
      : _preferences = preferenceStore ?? PreferenceStore();

  /// All available programs (built-in + custom)
  List<LoanProgram> get allPrograms => [
    ...DefaultLoanPrograms.programs,
    ..._customPrograms,
  ];

  /// Only built-in programs
  List<LoanProgram> get builtInPrograms => DefaultLoanPrograms.programs;

  /// Only custom programs
  List<LoanProgram> get customPrograms => _customPrograms;

  /// Currently selected program
  LoanProgram? get selectedProgram => _selectedProgram;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Load programs from storage
  Future<void> load() async {
    try {
      await _preferences.load();

      final customJson = _preferences.getString(_storageKey);
      if (customJson != null) {
        final List<dynamic> decoded = jsonDecode(customJson);
        _customPrograms = decoded
            .map((e) => LoanProgram.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      final selectedId = _preferences.getString(_selectedKey);
      if (selectedId != null) {
        _selectedProgram = allPrograms.firstWhere(
          (p) => p.id == selectedId,
          orElse: () => DefaultLoanPrograms.programs.first,
        );
      } else {
        _selectedProgram = DefaultLoanPrograms.programs.first;
      }
    } catch (e) {
      debugPrint('Error loading loan programs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save custom programs to storage
  Future<void> _savePrograms() async {
    try {
      await _preferences.load();
      final json = jsonEncode(_customPrograms.map((p) => p.toJson()).toList());
      await _preferences.setString(_storageKey, json);
    } catch (e) {
      debugPrint('Error saving loan programs: $e');
    }
  }

  /// Save selected program to storage
  Future<void> _saveSelectedProgram() async {
    try {
      await _preferences.load();
      if (_selectedProgram != null) {
        await _preferences.setString(_selectedKey, _selectedProgram!.id);
      } else {
        await _preferences.remove(_selectedKey);
      }
    } catch (e) {
      debugPrint('Error saving selected program: $e');
    }
  }

  /// Select a program
  void selectProgram(LoanProgram program) {
    _selectedProgram = program;
    _saveSelectedProgram();
    notifyListeners();
  }

  /// Add a new custom program
  Future<LoanProgram> addProgram({
    required String name,
    required String description,
    required LoanProgramType type,
    required double housingRatio,
    required double debtRatio,
    required double minDownPaymentPercent,
    double? maxLoanAmount,
    MortgageInsuranceConfig? miConfig,
  }) async {
    final now = DateTime.now();
    final program = LoanProgram(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: type,
      housingRatio: housingRatio,
      debtRatio: debtRatio,
      minDownPaymentPercent: minDownPaymentPercent,
      maxLoanAmount: maxLoanAmount,
      miConfig: miConfig,
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
    );
    
    _customPrograms.add(program);
    await _savePrograms();
    notifyListeners();
    return program;
  }

  /// Duplicate an existing program
  Future<LoanProgram> duplicateProgram(LoanProgram source) async {
    final now = DateTime.now();
    final program = source.copyWith(
      id: _uuid.v4(),
      name: '${source.name} (Copy)',
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
    );
    
    _customPrograms.add(program);
    await _savePrograms();
    notifyListeners();
    return program;
  }

  /// Update an existing custom program
  Future<void> updateProgram(LoanProgram program) async {
    final index = _customPrograms.indexWhere((p) => p.id == program.id);
    if (index == -1) {
      throw Exception('Cannot update built-in or non-existent program');
    }
    
    _customPrograms[index] = program.copyWith(updatedAt: DateTime.now());
    
    // Update selected if it was the one being edited
    if (_selectedProgram?.id == program.id) {
      _selectedProgram = _customPrograms[index];
    }
    
    await _savePrograms();
    notifyListeners();
  }

  /// Delete a custom program
  Future<void> deleteProgram(String id) async {
    final program = _customPrograms.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Program not found'),
    );
    
    if (program.isBuiltIn) {
      throw Exception('Cannot delete built-in programs');
    }
    
    _customPrograms.removeWhere((p) => p.id == id);
    
    // If deleted program was selected, select first built-in
    if (_selectedProgram?.id == id) {
      _selectedProgram = DefaultLoanPrograms.programs.first;
      await _saveSelectedProgram();
    }
    
    await _savePrograms();
    notifyListeners();
  }

  /// Get programs by type
  List<LoanProgram> getProgramsByType(LoanProgramType type) {
    return allPrograms.where((p) => p.type == type).toList();
  }

  /// Search programs by name
  List<LoanProgram> searchPrograms(String query) {
    final q = query.toLowerCase();
    return allPrograms.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q)
    ).toList();
  }
}
