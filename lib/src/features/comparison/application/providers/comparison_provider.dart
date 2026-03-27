import 'package:flutter/foundation.dart';
import 'package:loan_ranger/src/core/models/calculation_history.dart';

import '../../domain/models/comparison_data.dart';

export '../../domain/models/comparison_data.dart';

class ComparisonProvider extends ChangeNotifier {
  final Set<String> _selectedIds = <String>{};
  static const int maxSelections = 3;

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool isSelected(String id) => _selectedIds.contains(id);
  int get selectionCount => _selectedIds.length;
  bool get canCompare => _selectedIds.length >= 2;
  bool get isMaxSelected => _selectedIds.length >= maxSelections;

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else if (_selectedIds.length < maxSelections) {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelections() {
    _selectedIds.clear();
    notifyListeners();
  }

  void selectMultiple(List<String> ids) {
    _selectedIds
      ..clear()
      ..addAll(ids.take(maxSelections));
    notifyListeners();
  }

  List<CalculationEntry> getSelectedEntries(List<CalculationEntry> allEntries) {
    return allEntries
        .where((entry) => _selectedIds.contains(entry.id))
        .toList();
  }

  ComparisonData? buildComparison(List<CalculationEntry> allEntries) {
    final selected = getSelectedEntries(allEntries);
    if (selected.length < 2) return null;
    return ComparisonData.fromEntries(selected);
  }
}
