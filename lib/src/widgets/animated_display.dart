import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadow,
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
                    color: AppTheme.accentGold,
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
                      color: Colors.white,
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.3),
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
                        color: isError ? AppTheme.errorRed : AppTheme.accentGold,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subtitle ?? 'MONTHLY P&I',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.accentGold,
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSet ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSet
                ? AppTheme.successGreen.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
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
                color: isSet ? AppTheme.successGreen : Colors.white54,
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
                  color: isSet ? Colors.white : Colors.white54,
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
