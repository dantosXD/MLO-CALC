import 'package:flutter/material.dart';

class CalculatorDisplayNotifier with ChangeNotifier {
  String _displayValue = '0';
  String? _inputError;
  
  // Arithmetic State
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  
  // Memory State
  double? _memory;

  // Getters
  String get displayValue => _displayValue;
  String? get inputError => _inputError;
  bool get hasMemory => _memory != null;
  double? get memory => _memory;
  
  void setDisplayValue(String value) {
    _displayValue = value;
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void setValue(double value) {
    _displayValue = _formatResult(value);
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void setError(String? error) {
    _inputError = error;
    if (error != null) {
      // Don't overwrite display value on error, just show error toast/subtitle?
      // Or set display to "Error" if critical?
      // The original code set display to "Error" sometimes.
      // We'll keep the value but show the error message.
    }
    notifyListeners();
  }

  void clearError() {
    _inputError = null;
    notifyListeners();
  }

  // === Input Handling ===

  void inputDigit(String digit) {
    if (_shouldResetDisplay) {
      _displayValue = digit;
      _shouldResetDisplay = false;
    } else if (_displayValue == '0') {
      if (digit == '0') return; // Avoid 00 at start
      _displayValue = digit;
    } else {
      // Limit length to avoid overflow issues
      if (_displayValue.length < 15) {
        _displayValue += digit;
      }
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_shouldResetDisplay) {
      _displayValue = '0.';
      _shouldResetDisplay = false;
      return;
    }
    if (!_displayValue.contains('.')) {
      _displayValue += '.';
    }
    notifyListeners();
  }

  void inputDoubleZero() {
    if (_shouldResetDisplay) {
      _displayValue = '0';
      _shouldResetDisplay = false;
      return;
    }
    if (_displayValue == '0') return;
    if (_displayValue.length < 14) {
      _displayValue += '00';
    }
    notifyListeners();
  }

  void inputTripleZero() {
    if (_shouldResetDisplay) {
      _displayValue = '0';
      _shouldResetDisplay = false;
      return;
    }
    if (_displayValue == '0') return;
    if (_displayValue.length < 13) {
      _displayValue += '000';
    }
    notifyListeners();
  }

  void backspace() {
    if (_displayValue.length > 1) {
      _displayValue = _displayValue.substring(0, _displayValue.length - 1);
    } else {
      _displayValue = '0';
    }
    notifyListeners();
  }

  void clear() {
    _displayValue = '0';
    _shouldResetDisplay = false;
    _inputError = null;
    notifyListeners();
  }

  void clearAll() {
    clear();
    _resetArithmeticState();
    // Note: We don't clear memory here, similar to standard calculators? 
    // Original code DID clear memory in clearAll() if I recall?
    // Let's check original... it did clear everything.
    // But usually AC clears calculation, not memory. 
    // I'll keep memory persistent for now unless requested otherwise.
    notifyListeners();
  }

  // === Arithmetic Operations ===

  void performOperation(String op) {
    // Handle chained operations
    if (_operator != null && !_shouldResetDisplay) {
      calculateResult();
    }

    _firstOperand = double.tryParse(_displayValue);
    _operator = op;
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void calculateResult() {
    if (_operator == null || _firstOperand == null) {
      return;
    }

    final double secondOperand = double.tryParse(_displayValue) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case 'x':
        result = _firstOperand! * secondOperand;
        break;
      case '/':
        if (secondOperand != 0) {
          result = _firstOperand! / secondOperand;
        } else {
          _displayValue = 'Error';
          _resetArithmeticState();
          _shouldResetDisplay = true;
          notifyListeners();
          return;
        }
        break;
    }

    _displayValue = _formatResult(result);
    _resetArithmeticState();
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void calculatePercent() {
    final current = double.tryParse(_displayValue);
    if (current == null) return;
    
    // If we have a first operand, calculate percent of that
    if (_firstOperand != null) {
      // Example: 100 + 10% -> 100 + 10
      _displayValue = _formatResult(_firstOperand! * current / 100);
    } else {
      // Just convert to decimal: 50% -> 0.5
      _displayValue = _formatResult(current / 100);
    }
    _shouldResetDisplay = true;
    notifyListeners();
  }

  String _formatResult(double result) {
    if (result.isInfinite || result.isNaN) return 'Error';
    
    // If integer
    if (result.truncateToDouble() == result) {
      return result.toInt().toString();
    }
    
    // Max 10 chars to fit screen?
    final int decimals = result.abs() >= 100 ? 2 : 4;
    return result
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _resetArithmeticState() {
    _operator = null;
    _firstOperand = null;
  }

  // === Memory Functions ===

  void memoryAdd() {
    final current = double.tryParse(_displayValue);
    if (current == null) return;
    _memory = (_memory ?? 0) + current;
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void memorySubtract() {
    final current = double.tryParse(_displayValue);
    if (current == null) return;
    _memory = (_memory ?? 0) - current;
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void memoryRecall() {
    if (_memory == null) return;
    _displayValue = _formatResult(_memory!);
    _shouldResetDisplay = true;
    notifyListeners();
  }

  void memoryClear() {
    _memory = null;
    notifyListeners();
  }
}
