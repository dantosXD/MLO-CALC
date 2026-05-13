import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/theme/calculator_palette.dart';
import 'package:provider/provider.dart';

// Record holding only the fields AnimatedDisplay actually renders.
// context.select re-renders only when one of these changes, not on any
// unrelated CalculatorProvider mutation (e.g. closingCosts, errors).
typedef _DisplaySnapshot = ({
  double? loanAmount,
  double? interestRate,
  double? termYears,
  double? displayPayment,
  PaymentDisplayMode displayMode,
  double? propertyTax,
  double? homeInsurance,
  double? mortgageInsurance,
  double? monthlyExpenses,
});

class AnimatedDisplay extends StatelessWidget {
  final String displayValue;
  final String? subtitle;
  final bool isError;

  const AnimatedDisplay({
    super.key,
    required this.displayValue,
    this.subtitle,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.select<CalculatorProvider, _DisplaySnapshot>(
      (p) => (
        loanAmount: p.loanAmount,
        interestRate: p.interestRate,
        termYears: p.termYears,
        displayPayment: p.displayPayment,
        displayMode: p.displayMode,
        propertyTax: p.propertyTax,
        homeInsurance: p.homeInsurance,
        mortgageInsurance: p.mortgageInsurance,
        monthlyExpenses: p.monthlyExpenses,
      ),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = theme.extension<CalculatorPalette>();
    final colorScheme = theme.colorScheme;
    final gradient =
        palette?.backgroundGradient ??
        LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final accent = colorScheme.secondary;
    final accentOn = colorScheme.onSecondary;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          final provider = context.read<CalculatorProvider>();
          if (details.primaryVelocity! < -500) {
            provider.cycleDisplayMode();
          } else if (details.primaryVelocity! > 500) {
            provider.cycleDisplayMode(reverse: true);
          }
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  palette?.keyShadow ??
                  Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: isDark ? 28 : 18,
              offset: Offset(0, isDark ? 12 : 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Display Value
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (palette?.displayBackground ??
                                colorScheme.surfaceContainerHighest)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerRight,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatDisplayValue(displayValue),
                            key: ValueKey<String>(displayValue),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: isError ? colorScheme.error : accentOn,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subtitle ?? _labelFor(s.displayMode),
                          style: TextStyle(
                            fontSize: 9,
                            color: accentOn,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Status Grid - Compact (Loan Info)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactStatusItem(
                    context,
                    'L/A',
                    CurrencyFormatter.formatCompactCurrency(
                      s.loanAmount,
                      maxDigits: 7,
                    ),
                    s.loanAmount != null,
                  ),
                  _buildCompactStatusItem(
                    context,
                    'Rate',
                    s.interestRate != null
                        ? CurrencyFormatter.formatPercent(
                            s.interestRate,
                            decimals: 3,
                          )
                        : '--',
                    s.interestRate != null,
                  ),
                  _buildCompactStatusItem(
                    context,
                    'Term',
                    s.termYears != null
                        ? '${s.termYears!.toStringAsFixed(1)}y'
                        : '--',
                    s.termYears != null,
                  ),
                  _buildCompactStatusItem(
                    context,
                    'Pmt',
                    CurrencyFormatter.formatCompactCurrency(
                      s.displayPayment,
                      maxDigits: 7,
                    ),
                    s.displayPayment != null,
                  ),
                ],
              ),

              // PITI Components Row - Only show if any are set
              if (s.propertyTax != null ||
                  s.homeInsurance != null ||
                  s.mortgageInsurance != null ||
                  s.monthlyExpenses != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (s.propertyTax != null)
                      _buildCompactStatusItem(
                        context,
                        'Tax',
                        CurrencyFormatter.formatCompactCurrency(
                          s.propertyTax! / 12,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                    if (s.homeInsurance != null)
                      _buildCompactStatusItem(
                        context,
                        'Ins',
                        CurrencyFormatter.formatCompactCurrency(
                          s.homeInsurance! / 12,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                    if (s.mortgageInsurance != null)
                      _buildCompactStatusItem(
                        context,
                        'PMI',
                        CurrencyFormatter.formatCompactCurrency(
                          s.mortgageInsurance! / 12,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                    if (s.monthlyExpenses != null)
                      _buildCompactStatusItem(
                        context,
                        'HOA',
                        CurrencyFormatter.formatCompactCurrency(
                          s.monthlyExpenses,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _labelFor(PaymentDisplayMode mode) => switch (mode) {
    PaymentDisplayMode.interestOnly => 'INTEREST ONLY',
    PaymentDisplayMode.piti => 'MONTHLY PITI',
    PaymentDisplayMode.standardPI => 'MONTHLY P&I',
  };

  String _formatDisplayValue(String rawValue) {
    final double? numValue = double.tryParse(rawValue);
    if (numValue != null && !isError) {
      return CurrencyFormatter.formatNumber(numValue, decimals: 2);
    }
    return rawValue;
  }

  Widget _buildCompactStatusItem(
    BuildContext context,
    String label,
    String value,
    bool isSet,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = theme.extension<CalculatorPalette>();
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: (palette?.displayBackground ?? scheme.surfaceContainerHighest)
              .withValues(alpha: isSet ? 0.35 : 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSet
                ? scheme.tertiary.withValues(alpha: 0.5)
                : scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: isSet ? scheme.tertiary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isSet
                      ? scheme.onSecondary
                      : scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
