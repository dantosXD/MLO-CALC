import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../utils/formatters.dart';
import '../theme/calculator_palette.dart';

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

  // Helper to conditionally apply animations (skip on Android)
  Widget _conditionalAnimate(Widget child, {Duration? duration}) {
    // Disable animations on Android to prevent crashes
    if (defaultTargetPlatform == TargetPlatform.android) {
      return child;
    }
    return child.animate().fadeIn(duration: duration ?? 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = theme.extension<CalculatorPalette>();
    final colorScheme = theme.colorScheme;
    final gradient = palette?.backgroundGradient ??
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette?.keyShadow ??
                Colors.black.withOpacity(isDark ? 0.35 : 0.12),
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
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _conditionalAnimate(
                  Icon(
                    Icons.calculate_outlined,
                    color: accentOn,
                    size: 16,
                  ),
                  duration: 500.ms,
                ),
                const SizedBox(width: 6),
                _conditionalAnimate(
                  Text(
                    'MLO-Calc',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accentOn,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  duration: 600.ms,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Main Display Value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (palette?.displayBackground ??
                        colorScheme.surfaceVariant)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatDisplayValue(displayValue),
                      key: ValueKey<String>(displayValue),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isError ? colorScheme.error : accentOn,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subtitle ?? 'MONTHLY P&I',
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
            const SizedBox(height: 6),

            // Status Grid - Compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactStatusItem(
                  context,
                  'L/A',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.loanAmount),
                  calculatorProvider.loanAmount != null,
                ),
                _buildCompactStatusItem(
                  context,
                  'Rate',
                  calculatorProvider.interestRate != null
                    ? '${calculatorProvider.interestRate!.toStringAsFixed(2)}%'
                    : '--',
                  calculatorProvider.interestRate != null,
                ),
                _buildCompactStatusItem(
                  context,
                  'Term',
                  calculatorProvider.termYears != null
                    ? '${calculatorProvider.termYears!.toInt()}y'
                    : '--',
                  calculatorProvider.termYears != null,
                ),
                _buildCompactStatusItem(
                  context,
                  'Pmt',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.payment),
                  calculatorProvider.payment != null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          color: (palette?.displayBackground ?? scheme.surfaceVariant)
              .withOpacity(isSet ? 0.35 : 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSet
                ? scheme.tertiary.withOpacity(0.5)
                : scheme.outlineVariant.withOpacity(0.2),
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
                      : scheme.onSurface.withOpacity(0.6),
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
