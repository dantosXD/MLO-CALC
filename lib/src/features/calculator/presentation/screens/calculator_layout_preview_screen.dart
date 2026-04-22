import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/layout_preference_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

class CalculatorLayoutPreviewScreen extends StatefulWidget {
  const CalculatorLayoutPreviewScreen({super.key});

  @override
  State<CalculatorLayoutPreviewScreen> createState() =>
      _CalculatorLayoutPreviewScreenState();
}

class _CalculatorLayoutPreviewScreenState
    extends State<CalculatorLayoutPreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set initial tab based on current preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final layoutPref = context.read<LayoutPreferenceProvider>();
      _tabController.index = layoutPref.isModern ? 1 : 0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyLayout(BuildContext context) {
    final layoutPref = context.read<LayoutPreferenceProvider>();
    final selectedLayout = _tabController.index == 0
        ? CalculatorLayout.classic
        : CalculatorLayout.modern;

    layoutPref.setLayout(selectedLayout);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedLayout == CalculatorLayout.modern ? "Modern" : "Classic"} layout applied!',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutPreferenceProvider>(
      builder: (context, layoutPref, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Choose Layout'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.calculate_outlined), text: 'Classic'),
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Modern'),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _applyLayout(context),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Apply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [CalculatorScreen(), _ModernCalculatorPreview()],
          ),
        );
      },
    );
  }
}

class _ModernCalculatorPreview extends StatelessWidget {
  const _ModernCalculatorPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
                // Display + secondary fields (no scroll, compact)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: _DisplayCard(calc: calc, display: display),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SecondaryFieldsRow(calc: calc, display: display),
                ),
                const SizedBox(height: 6),
                // Keypad takes remaining space
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
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.calc, required this.display});

  final CalculatorProvider calc;
  final CalculatorDisplayNotifier display;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isError =
        display.displayValue == 'Error' ||
        display.inputError != null ||
        calc.inputError != null;

    return Container(
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
          // Display value row
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : AppTheme.accentGold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  display.inputError ?? calc.inputError ?? 'MONTHLY P&I',
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
          // 4 main tappable stat chips (L/A, Rate, Term, Pmt) - NO DUPLICATION
          Row(
            children: [
              _StatChip(
                label: 'L/A',
                value: CurrencyFormatter.formatCompactCurrency(calc.loanAmount),
                isSet: calc.loanAmount != null,
                onTap: () => _setFromDisplay(
                  context,
                  'Loan Amount',
                  (v) => calc.setLoanAmount(value: v),
                ),
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Rate',
                value: calc.interestRate != null
                    ? CurrencyFormatter.formatPercent(
                        calc.interestRate,
                        decimals: 3,
                      )
                    : '--',
                isSet: calc.interestRate != null,
                onTap: () => _setFromDisplay(
                  context,
                  'Rate',
                  (v) => calc.setInterestRate(value: v),
                ),
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Term',
                value: calc.termYears != null
                    ? '${calc.termYears!.toInt()}y'
                    : '--',
                isSet: calc.termYears != null,
                onTap: () => _setFromDisplay(
                  context,
                  'Term',
                  (v) => calc.setTermYears(value: v),
                ),
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Pmt',
                value: CurrencyFormatter.formatCompactCurrency(calc.payment),
                isSet: calc.payment != null,
                onTap: () => _setFromDisplay(
                  context,
                  'Payment',
                  (v) => calc.setPayment(value: v),
                ),
              ),
            ],
          ),
        ],
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

  void _setFromDisplay(
    BuildContext context,
    String label,
    void Function(double) setter,
  ) {
    final parsed = double.tryParse(display.displayValue);
    if (parsed != null && parsed != 0) {
      display.clear();
      setter(parsed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label = ${CurrencyFormatter.formatCurrency(parsed)}'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.isSet,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isSet ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSet
                    ? AppTheme.accentGold.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.2),
                width: isSet ? 1.5 : 1,
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
                    color: isSet
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
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
          onTap: () =>
              _setFromDisplay(context, 'Price', (v) => calc.setPrice(value: v)),
        ),
        _RowChip(
          label: 'DnPmt',
          value: calc.downPayment,
          color: AppTheme.successGreen,
          onTap: () => _setFromDisplay(
            context,
            'Down Pmt',
            (v) => calc.setDownPayment(value: v),
          ),
        ),
        _RowChip(
          label: 'Tax',
          value: calc.propertyTax,
          color: AppTheme.pitiButton,
          onTap: () => _setFromDisplay(
            context,
            'Tax/yr',
            (v) => calc.setPropertyTax(value: v),
          ),
        ),
        _RowChip(
          label: 'Ins',
          value: calc.homeInsurance,
          color: AppTheme.pitiButton,
          onTap: () => _setFromDisplay(
            context,
            'Ins/yr',
            (v) => calc.setHomeInsurance(value: v),
          ),
        ),
        _RowChip(
          label: 'HOA',
          value: calc.monthlyExpenses,
          color: AppTheme.warningOrange,
          onTap: () => _setFromDisplay(
            context,
            'HOA/mo',
            (v) => calc.setMonthlyExpenses(value: v),
          ),
        ),
      ],
    );
  }

  void _setFromDisplay(
    BuildContext context,
    String label,
    void Function(double) setter,
  ) {
    final parsed = double.tryParse(display.displayValue);
    if (parsed != null && parsed != 0) {
      display.clear();
      setter(parsed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label = ${CurrencyFormatter.formatCurrency(parsed)}'),
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
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade200),
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
                    hasValue
                        ? CurrencyFormatter.formatCompactCurrency(value)
                        : '--',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasValue
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey,
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

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildKey(
                  context,
                  'AC',
                  onTap: () {
                    calculatorProvider.clearAll();
                    displayProvider.clearAll();
                  },
                  color: AppTheme.errorRed,
                  textColor: Colors.white,
                ),
                _buildKey(
                  context,
                  '⌫',
                  onTap: displayProvider.backspace,
                  onLongPress: displayProvider.clear,
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),
                _buildKey(
                  context,
                  '%',
                  onTap: displayProvider.calculatePercent,
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),
                _buildKey(
                  context,
                  '÷',
                  onTap: () => displayProvider.performOperation('/'),
                  color: AppTheme.primaryTeal,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildKey(
                  context,
                  '7',
                  onTap: () => displayProvider.inputDigit('7'),
                ),
                _buildKey(
                  context,
                  '8',
                  onTap: () => displayProvider.inputDigit('8'),
                ),
                _buildKey(
                  context,
                  '9',
                  onTap: () => displayProvider.inputDigit('9'),
                ),
                _buildKey(
                  context,
                  '×',
                  onTap: () => displayProvider.performOperation('x'),
                  color: AppTheme.primaryTeal,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildKey(
                  context,
                  '4',
                  onTap: () => displayProvider.inputDigit('4'),
                ),
                _buildKey(
                  context,
                  '5',
                  onTap: () => displayProvider.inputDigit('5'),
                ),
                _buildKey(
                  context,
                  '6',
                  onTap: () => displayProvider.inputDigit('6'),
                ),
                _buildKey(
                  context,
                  '−',
                  onTap: () => displayProvider.performOperation('-'),
                  color: AppTheme.primaryTeal,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildKey(
                  context,
                  '1',
                  onTap: () => displayProvider.inputDigit('1'),
                ),
                _buildKey(
                  context,
                  '2',
                  onTap: () => displayProvider.inputDigit('2'),
                ),
                _buildKey(
                  context,
                  '3',
                  onTap: () => displayProvider.inputDigit('3'),
                ),
                _buildKey(
                  context,
                  '+',
                  onTap: () => displayProvider.performOperation('+'),
                  color: AppTheme.primaryTeal,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildKey(
                  context,
                  '00',
                  onTap: () {
                    displayProvider.inputDigit('0');
                    displayProvider.inputDigit('0');
                  },
                ),
                _buildKey(
                  context,
                  '0',
                  onTap: () => displayProvider.inputDigit('0'),
                ),
                _buildKey(context, '.', onTap: displayProvider.inputDecimal),
                _buildKey(
                  context,
                  '=',
                  onTap: displayProvider.calculateResult,
                  color: AppTheme.accentGold,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(
    BuildContext context,
    String text, {
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? color,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final fgColor = textColor ?? (isDark ? Colors.white : Colors.black87);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          elevation: color != null ? 2 : 0,
          shadowColor: (color ?? Colors.black).withValues(alpha: 0.3),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            splashColor: (color ?? AppTheme.primaryTeal).withValues(alpha: 0.2),
            highlightColor: (color ?? AppTheme.primaryTeal).withValues(
              alpha: 0.1,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: color == null
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: text.length > 1 ? 18 : 24,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
