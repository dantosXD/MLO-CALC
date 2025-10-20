import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_work,
                  color: AppTheme.accentGold,
                  size: 24,
                ).animate().fadeIn(duration: 500.ms).scale(),
                const SizedBox(width: 12),
                Text(
                  'LOAN RANGER',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(),
              ],
            ),
            const SizedBox(height: 20),

            // Main Display Value with Animation
            Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Text(
                    _formatDisplayValue(displayValue),
                    key: ValueKey<String>(displayValue),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 56,
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
                  ).animate(key: ValueKey(displayValue))
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subtitle ?? 'MONTHLY P&I',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 16),

            // Status Row 1: Core Loan Variables
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  context,
                  'LOAN',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.loanAmount),
                  calculatorProvider.loanAmount != null,
                  Icons.attach_money,
                ),
                _buildStatusItem(
                  context,
                  'RATE',
                  CurrencyFormatter.formatPercent(calculatorProvider.interestRate),
                  calculatorProvider.interestRate != null,
                  Icons.percent,
                ),
                _buildStatusItem(
                  context,
                  'TERM',
                  CurrencyFormatter.formatYears(calculatorProvider.termYears),
                  calculatorProvider.termYears != null,
                  Icons.calendar_today,
                ),
                _buildStatusItem(
                  context,
                  'PMT',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.payment),
                  calculatorProvider.payment != null,
                  Icons.payments,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 12),

            // Status Row 2: PITI Variables
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  context,
                  'PRICE',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.price),
                  calculatorProvider.price != null,
                  Icons.home,
                ),
                _buildStatusItem(
                  context,
                  'DOWN',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.downPayment),
                  calculatorProvider.downPayment != null,
                  Icons.account_balance_wallet,
                ),
                _buildStatusItem(
                  context,
                  'TAX',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.propertyTax),
                  calculatorProvider.propertyTax != null,
                  Icons.receipt_long,
                ),
                _buildStatusItem(
                  context,
                  'INS',
                  CurrencyFormatter.formatCompactCurrency(calculatorProvider.homeInsurance),
                  calculatorProvider.homeInsurance != null,
                  Icons.security,
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    bool isSet,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSet ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: isSet ? AppTheme.successGreen : Colors.white54,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSet ? AppTheme.successGreen : Colors.white54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSet ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
