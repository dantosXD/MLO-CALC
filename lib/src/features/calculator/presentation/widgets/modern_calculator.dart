import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ModernCalculator extends StatefulWidget {
  const ModernCalculator({super.key});

  @override
  State<ModernCalculator> createState() => _ModernCalculatorState();
}

class _ModernCalculatorState extends State<ModernCalculator> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(KeyEvent event, CalculatorDisplayNotifier displayProvider, CalculatorProvider calculatorProvider) {
    if (event is! KeyDownEvent) return;
    
    final key = event.logicalKey;

    // Numbers 0-9
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      displayProvider.inputDigit('0');
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      displayProvider.inputDigit('1');
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      displayProvider.inputDigit('2');
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      displayProvider.inputDigit('3');
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      displayProvider.inputDigit('4');
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      displayProvider.inputDigit('5');
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      displayProvider.inputDigit('6');
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      displayProvider.inputDigit('7');
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      displayProvider.inputDigit('8');
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      displayProvider.inputDigit('9');
    }
    // Decimal point
    else if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
      displayProvider.inputDecimal();
    }
    // Operations
    else if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      displayProvider.performOperation('+');
    } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      displayProvider.performOperation('-');
    } else if (key == LogicalKeyboardKey.asterisk || key == LogicalKeyboardKey.numpadMultiply) {
      displayProvider.performOperation('x');
    } else if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.numpadDivide) {
      displayProvider.performOperation('/');
    }
    // Equals
    else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.equal) {
      displayProvider.calculateResult();
    }
    // Clear
    else if (key == LogicalKeyboardKey.escape) {
      displayProvider.clearAll();
      calculatorProvider.clearAll();
    } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      displayProvider.backspace();
    }
    // Percent
    else if (key == LogicalKeyboardKey.percent) {
      displayProvider.calculatePercent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final calculatorProvider = context.read<CalculatorProvider>();
    final displayProvider = context.read<CalculatorDisplayNotifier>();

    // Only use keyboard listener on desktop platforms
    final bool isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final Widget calculatorUI = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        ),
      ),
      child: SafeArea(
        child: Consumer2<CalculatorProvider, CalculatorDisplayNotifier>(
          builder: (context, calc, display, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: _DisplayCard(calc: calc, display: display),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SecondaryFieldsRow(calc: calc, display: display),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _ModernKeypad(
                    displayProvider: display,
                    calculatorProvider: calc,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    // Wrap with KeyboardListener only on desktop
    return isDesktop
        ? KeyboardListener(
            focusNode: _focusNode..requestFocus(),
            autofocus: true,
            onKeyEvent: (event) => _handleKeyPress(event, displayProvider, calculatorProvider),
            child: calculatorUI,
          )
        : calculatorUI;
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.calc, required this.display});

  final CalculatorProvider calc;
  final CalculatorDisplayNotifier display;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isError = display.displayValue == 'Error' ||
        display.inputError != null ||
        calc.inputError != null;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe up = forward, Swipe down = reverse
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe up
            calc.cycleDisplayMode();
          } else if (details.primaryVelocity! > 500) {
            // Swipe down
            calc.cycleDisplayMode(reverse: true);
          }
        }
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A365D), const Color(0xFF0891B2)]
              : [AppTheme.primaryNavy, AppTheme.primaryTeal],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _formatDisplayValue(display.displayValue),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : calc.isInterestOnly
                          ? const Color(0xFF7B68EE).withValues(alpha: 0.3)
                          : AppTheme.accentGold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  display.inputError ?? calc.inputError ?? _getDisplayLabel(calc),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.red.shade100 : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'L/A',
                value: CurrencyFormatter.formatCompactCurrency(calc.loanAmount),
                isSet: calc.loanAmount != null,
                onTap: () => _setFromDisplay(context, 'Loan Amount', (v) => calc.setLoanAmount(value: v)),
                onDoubleTap: () => _clearField(context, 'Loan Amount', () => calc.clearLoanAmount()),
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Rate',
                value: calc.interestRate != null
                    ? '${calc.interestRate!.toStringAsFixed(2)}%'
                    : '--',
                isSet: calc.interestRate != null,
                onTap: () => _setFromDisplay(context, 'Rate', (v) => calc.setInterestRate(value: v)),
                onDoubleTap: () => _clearField(context, 'Rate', () => calc.clearInterestRate()),
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Term',
                value: calc.termYears != null ? '${calc.termYears!.toInt()}y' : '--',
                isSet: calc.termYears != null,
                onTap: () => _setFromDisplay(context, 'Term', (v) => calc.setTermYears(value: v)),
                onDoubleTap: () => _clearField(context, 'Term', () => calc.clearTermYears()),
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: calc.isInterestOnly ? 'I/O' : 'Pmt',
                value: CurrencyFormatter.formatCompactCurrency(calc.displayPayment),
                isSet: calc.displayPayment != null,
                isInterestOnly: calc.isInterestOnly,
                onTap: () => _setFromDisplay(context, 'Payment', (v) => calc.setPayment(value: v)),
                onLongPress: () => _showPaymentOptions(context, calc, display),
                onDoubleTap: () => _clearField(context, 'Payment', () => calc.clearPayment()),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _formatDisplayValue(String rawValue) {
    final double? numValue = double.tryParse(rawValue);
    if (numValue != null) {
      return CurrencyFormatter.formatNumber(numValue, decimals: 2);
    }
    return rawValue;
  }

  void _setFromDisplay(BuildContext context, String label, void Function(double) setter) {
    final parsed = double.tryParse(display.displayValue);
    if (parsed != null && parsed != 0) {
      display.clear();
      setter(parsed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label = ${parsed.toStringAsFixed(2)}'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }

  String _getDisplayLabel(CalculatorProvider provider) {
    switch (provider.displayMode) {
      case PaymentDisplayMode.interestOnly:
        return 'INTEREST ONLY';
      case PaymentDisplayMode.piti:
        return 'MONTHLY PITI';
      case PaymentDisplayMode.standardPI:
        return 'MONTHLY P&I';
    }
  }

  void _clearField(BuildContext context, String label, VoidCallback clearAction) {
    clearAction();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label cleared'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, CalculatorProvider provider, CalculatorDisplayNotifier displayNotifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Payment Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Interest Only Payment'),
              subtitle: Text(
                provider.isInterestOnly 
                  ? 'Calculating interest-only payment'
                  : 'Standard P&I payment',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: provider.isInterestOnly,
              onChanged: (value) {
                provider.toggleInterestOnly();
              },
              activeTrackColor: const Color(0xFF7B68EE),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.isSet,
    required this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.isInterestOnly = false,
  });

  final String label;
  final String value;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final bool isInterestOnly;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onDoubleTap: onDoubleTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isInterestOnly 
                  ? const Color(0xFF7B68EE).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: isSet ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isInterestOnly
                    ? const Color(0xFF7B68EE).withValues(alpha: 0.8)
                    : isSet
                        ? AppTheme.accentGold.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.2),
                width: isSet || isInterestOnly ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSet ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryFieldsRow extends StatelessWidget {
  const _SecondaryFieldsRow({required this.calc, required this.display});

  final CalculatorProvider calc;
  final CalculatorDisplayNotifier display;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RowChip(
          label: 'Price',
          value: calc.price,
          color: AppTheme.loanButton,
          onTap: () => _setFromDisplay(context, 'Price', (v) => calc.setPrice(value: v)),
        ),
        _RowChip(
          label: 'DnPmt',
          value: calc.downPayment,
          color: AppTheme.successGreen,
          onTap: () => _setFromDisplay(context, 'Down Pmt', (v) => calc.setDownPayment(value: v)),
        ),
        _RowChip(
          label: 'Tax',
          value: calc.propertyTax,
          color: AppTheme.pitiButton,
          onTap: () => _setFromDisplay(context, 'Tax/yr', (v) => calc.setPropertyTax(value: v)),
        ),
        _RowChip(
          label: 'Ins',
          value: calc.homeInsurance,
          color: AppTheme.pitiButton,
          onTap: () => _setFromDisplay(context, 'Ins/yr', (v) => calc.setHomeInsurance(value: v)),
        ),
        _RowChip(
          label: 'HOA',
          value: calc.monthlyExpenses,
          color: AppTheme.warningOrange,
          onTap: () => _setFromDisplay(context, 'HOA/mo', (v) => calc.setMonthlyExpenses(value: v)),
        ),
      ],
    );
  }

  void _setFromDisplay(BuildContext context, String label, void Function(double) setter) {
    final parsed = double.tryParse(display.displayValue);
    if (parsed != null && parsed != 0) {
      display.clear();
      setter(parsed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label = ${parsed.toStringAsFixed(2)}'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }
}

class _RowChip extends StatelessWidget {
  const _RowChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final double? value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: hasValue
                    ? color.withValues(alpha: isDark ? 0.15 : 0.1)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? color : Colors.grey,
                    ),
                  ),
                  Text(
                    hasValue ? CurrencyFormatter.formatCompactCurrency(value) : '--',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasValue ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernKeypad extends StatelessWidget {
  const _ModernKeypad({
    required this.displayProvider,
    required this.calculatorProvider,
  });

  final CalculatorDisplayNotifier displayProvider;
  final CalculatorProvider calculatorProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final numBg = isDark ? const Color(0xFF374151) : Colors.white;
    final numFg = isDark ? Colors.white : Colors.black87;
    final opBg = AppTheme.primaryTeal;
    const opFg = Colors.white;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalculatorButton(
                  text: 'AC',
                  onPressed: () {
                    calculatorProvider.clearAll();
                    displayProvider.clearAll();
                  },
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: Colors.white,
                ),
                CalculatorButton(
                  text: '⌫',
                  icon: Icons.backspace_outlined,
                  onPressed: displayProvider.backspace,
                  onLongPress: displayProvider.clear,
                  backgroundColor: numBg,
                  foregroundColor: numFg,
                ),
                CalculatorButton(
                  text: '%',
                  onPressed: displayProvider.calculatePercent,
                  backgroundColor: numBg,
                  foregroundColor: numFg,
                ),
                CalculatorButton(
                  text: '÷',
                  onPressed: () => displayProvider.performOperation('/'),
                  backgroundColor: opBg,
                  foregroundColor: opFg,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalculatorButton(text: '7', onPressed: () => displayProvider.inputDigit('7'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '8', onPressed: () => displayProvider.inputDigit('8'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '9', onPressed: () => displayProvider.inputDigit('9'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '×', onPressed: () => displayProvider.performOperation('x'), backgroundColor: opBg, foregroundColor: opFg),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalculatorButton(text: '4', onPressed: () => displayProvider.inputDigit('4'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '5', onPressed: () => displayProvider.inputDigit('5'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '6', onPressed: () => displayProvider.inputDigit('6'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '−', onPressed: () => displayProvider.performOperation('-'), backgroundColor: opBg, foregroundColor: opFg),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalculatorButton(text: '1', onPressed: () => displayProvider.inputDigit('1'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '2', onPressed: () => displayProvider.inputDigit('2'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '3', onPressed: () => displayProvider.inputDigit('3'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '+', onPressed: () => displayProvider.performOperation('+'), backgroundColor: opBg, foregroundColor: opFg),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalculatorButton(text: '00', onPressed: () { displayProvider.inputDigit('0'); displayProvider.inputDigit('0'); }, backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '0', onPressed: () => displayProvider.inputDigit('0'), backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '.', onPressed: displayProvider.inputDecimal, backgroundColor: numBg, foregroundColor: numFg),
                CalculatorButton(text: '=', onPressed: displayProvider.calculateResult, backgroundColor: AppTheme.accentGold, foregroundColor: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
