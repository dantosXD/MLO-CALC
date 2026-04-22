import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';
import 'package:loan_ranger/src/theme/calculator_palette.dart';

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
    final calculatorProvider = context.watch<CalculatorProvider>();
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
        // Swipe up = forward, Swipe down = reverse
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe up
            calculatorProvider.cycleDisplayMode();
          } else if (details.primaryVelocity! > 500) {
            // Swipe down
            calculatorProvider.cycleDisplayMode(reverse: true);
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
                          subtitle ?? _getDisplayLabel(calculatorProvider),
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
                      calculatorProvider.loanAmount,
                      maxDigits: 7,
                    ),
                    calculatorProvider.loanAmount != null,
                  ),
                  _buildCompactStatusItem(
                    context,
                    'Rate',
                    calculatorProvider.interestRate != null
                        ? CurrencyFormatter.formatPercent(
                            calculatorProvider.interestRate,
                            decimals: 3,
                          )
                        : '--',
                    calculatorProvider.interestRate != null,
                  ),
                  _buildCompactStatusItem(
                    context,
                    'Term',
                    calculatorProvider.termYears != null
                        ? '${calculatorProvider.termYears!.toStringAsFixed(1)}y'
                        : '--',
                    calculatorProvider.termYears != null,
                  ),
                  _buildCompactStatusItem(
                    context,
                    'Pmt',
                    CurrencyFormatter.formatCompactCurrency(
                      calculatorProvider.displayPayment,
                      maxDigits: 7,
                    ),
                    calculatorProvider.displayPayment != null,
                  ),
                ],
              ),

              // PITI Components Row - Only show if any are set
              if (_hasPitiComponents(calculatorProvider)) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (calculatorProvider.propertyTax != null)
                      _buildCompactStatusItem(
                        context,
                        'Tax',
                        CurrencyFormatter.formatCompactCurrency(
                          calculatorProvider.propertyTax! / 12,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                    if (calculatorProvider.homeInsurance != null)
                      _buildCompactStatusItem(
                        context,
                        'Ins',
                        CurrencyFormatter.formatCompactCurrency(
                          calculatorProvider.homeInsurance! / 12,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                    if (calculatorProvider.mortgageInsurance != null)
                      _buildCompactStatusItem(
                        context,
                        'PMI',
                        CurrencyFormatter.formatCompactCurrency(
                          calculatorProvider.mortgageInsurance! / 12,
                          maxDigits: 7,
                        ),
                        true,
                      ),
                    if (calculatorProvider.monthlyExpenses != null)
                      _buildCompactStatusItem(
                        context,
                        'HOA',
                        CurrencyFormatter.formatCompactCurrency(
                          calculatorProvider.monthlyExpenses,
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

  bool _hasPitiComponents(CalculatorProvider provider) {
    return provider.propertyTax != null ||
        provider.homeInsurance != null ||
        provider.mortgageInsurance != null ||
        provider.monthlyExpenses != null;
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

  String _formatDisplayValue(String rawValue) {
    // Try to parse and format the display value
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
