/// Enhanced validation with industry-specific warnings
///
/// Provides conforming loan limits, DTI thresholds, and LTV warnings
/// to help MLOs identify potential issues early.
library;

import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/utils/formatters.dart';

/// Warning severity levels
enum WarningSeverity { info, warning, critical }

/// Validation warning (not an error, but notable)
class ValidationWarning {
  final String message;
  final WarningSeverity severity;
  final String? suggestion;

  const ValidationWarning({
    required this.message,
    required this.severity,
    this.suggestion,
  });

  Color get color {
    switch (severity) {
      case WarningSeverity.info:
        return Colors.blue;
      case WarningSeverity.warning:
        return Colors.orange;
      case WarningSeverity.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (severity) {
      case WarningSeverity.info:
        return Icons.info_outline;
      case WarningSeverity.warning:
        return Icons.warning_amber_outlined;
      case WarningSeverity.critical:
        return Icons.error_outline;
    }
  }
}

/// Conforming loan limits by year (updated annually by FHFA)
class ConformingLoanLimits {
  // 2024 Limits
  static const int year = 2024;
  static const double standardLimit = 766550;
  static const double highCostLimit = 1149825; // For high-cost areas

  // FHA limits vary by county - using baseline
  static const double fhaFloorLimit = 472030;
  static const double fhaCeilingLimit = 1149825;

  // Jumbo threshold
  static double get jumboThreshold => standardLimit;

  /// Check if loan amount exceeds conforming limit
  static ValidationWarning? checkConformingLimit(
    double loanAmount, {
    String? county,
  }) {
    if (loanAmount > highCostLimit) {
      return ValidationWarning(
        message: 'Super jumbo loan - exceeds all conforming limits',
        severity: WarningSeverity.warning,
        suggestion: 'This loan will require non-conforming/portfolio financing',
      );
    }

    if (loanAmount > standardLimit) {
      return ValidationWarning(
        message:
            'Exceeds standard conforming limit (\$${standardLimit.toStringAsFixed(0)})',
        severity: WarningSeverity.info,
        suggestion:
            'May qualify as conforming in high-cost areas, or consider jumbo financing',
      );
    }

    return null;
  }

  /// Check FHA loan limits
  static ValidationWarning? checkFhaLimit(double loanAmount) {
    if (loanAmount > fhaCeilingLimit) {
      return ValidationWarning(
        message: 'Exceeds FHA ceiling limit',
        severity: WarningSeverity.critical,
        suggestion:
            'FHA loans cannot exceed \$${fhaCeilingLimit.toStringAsFixed(0)}',
      );
    }

    if (loanAmount > fhaFloorLimit) {
      return ValidationWarning(
        message:
            'Exceeds standard FHA limit (\$${fhaFloorLimit.toStringAsFixed(0)})',
        severity: WarningSeverity.info,
        suggestion: 'Higher limit may apply in high-cost areas',
      );
    }

    return null;
  }
}

/// DTI (Debt-to-Income) ratio validation
class DtiValidator {
  // QM (Qualified Mortgage) threshold
  static const double qmThreshold = 43.0;

  // Common program thresholds
  static const double conventionalBackEnd = 36.0;
  static const double conventionalBackEndWithStrong = 45.0;
  static const double fhaBackEnd = 43.0;
  static const double fhaBackEndStretch = 50.0; // With compensating factors
  static const double vaNoLimit =
      41.0; // VA uses residual income, this is guideline

  /// Calculate DTI ratio
  static double calculateDti({
    required double monthlyDebtPayments,
    required double monthlyGrossIncome,
  }) {
    if (monthlyGrossIncome <= 0) return 0;
    return (monthlyDebtPayments / monthlyGrossIncome) * 100;
  }

  /// Calculate housing (front-end) DTI
  static double calculateHousingDti({
    required double monthlyHousingPayment,
    required double monthlyGrossIncome,
  }) {
    if (monthlyGrossIncome <= 0) return 0;
    return (monthlyHousingPayment / monthlyGrossIncome) * 100;
  }

  /// Check DTI against QM rules
  static ValidationWarning? checkQmCompliance(double backEndDti) {
    if (backEndDti > 50) {
      return ValidationWarning(
        message:
            'DTI ${CurrencyFormatter.formatPercent(backEndDti, decimals: 1)} exceeds most program limits',
        severity: WarningSeverity.critical,
        suggestion:
            'Consider debt payoff, income increase, or lower loan amount',
      );
    }

    if (backEndDti > qmThreshold) {
      return ValidationWarning(
        message:
            'DTI ${CurrencyFormatter.formatPercent(backEndDti, decimals: 1)} exceeds QM threshold (43%)',
        severity: WarningSeverity.warning,
        suggestion: 'Non-QM loan may be required, or find compensating factors',
      );
    }

    if (backEndDti > 36) {
      return ValidationWarning(
        message:
            'DTI ${CurrencyFormatter.formatPercent(backEndDti, decimals: 1)} above standard guidelines',
        severity: WarningSeverity.info,
        suggestion:
            'May require compensating factors (credit score, reserves, etc.)',
      );
    }

    return null;
  }

  /// Get all DTI warnings
  static List<ValidationWarning> getDtiWarnings({
    required double frontEndDti,
    required double backEndDti,
    double? frontEndLimit,
    double? backEndLimit,
  }) {
    final warnings = <ValidationWarning>[];

    // Check front-end
    if (frontEndLimit != null && frontEndDti > frontEndLimit) {
      warnings.add(
        ValidationWarning(
          message:
              'Housing DTI ${CurrencyFormatter.formatPercent(frontEndDti, decimals: 1)} exceeds ${CurrencyFormatter.formatPercent(frontEndLimit, decimals: 2)} limit',
          severity: frontEndDti > frontEndLimit + 5
              ? WarningSeverity.warning
              : WarningSeverity.info,
        ),
      );
    }

    // Check back-end
    if (backEndLimit != null && backEndDti > backEndLimit) {
      warnings.add(
        ValidationWarning(
          message:
              'Total DTI ${CurrencyFormatter.formatPercent(backEndDti, decimals: 1)} exceeds ${CurrencyFormatter.formatPercent(backEndLimit, decimals: 2)} limit',
          severity: backEndDti > backEndLimit + 5
              ? WarningSeverity.warning
              : WarningSeverity.info,
        ),
      );
    }

    // Check QM
    final qmWarning = checkQmCompliance(backEndDti);
    if (qmWarning != null) warnings.add(qmWarning);

    return warnings;
  }
}

/// LTV (Loan-to-Value) ratio validation
class LtvValidator {
  // Common thresholds
  static const double pmiThreshold = 80.0;
  static const double conventionalMaxLtv = 97.0;
  static const double fhaMaxLtv = 96.5;
  static const double vaMaxLtv = 100.0;
  static const double usdaMaxLtv = 100.0;
  static const double jumboTypicalMax = 90.0;

  /// Calculate LTV
  static double calculateLtv({
    required double loanAmount,
    required double propertyValue,
  }) {
    if (propertyValue <= 0) return 0;
    return (loanAmount / propertyValue) * 100;
  }

  /// Get LTV warnings
  static List<ValidationWarning> getLtvWarnings(
    double ltv, {
    String? loanType,
  }) {
    final warnings = <ValidationWarning>[];

    // PMI warning
    if (ltv > pmiThreshold && loanType != 'VA' && loanType != 'USDA') {
      warnings.add(
        ValidationWarning(
          message:
              'LTV ${CurrencyFormatter.formatPercent(ltv, decimals: 1)} requires mortgage insurance',
          severity: WarningSeverity.info,
          suggestion: 'PMI required until LTV reaches 80%',
        ),
      );
    }

    // High LTV warnings
    if (ltv > 95) {
      warnings.add(
        ValidationWarning(
          message:
              'Very high LTV (${CurrencyFormatter.formatPercent(ltv, decimals: 1)})',
          severity: WarningSeverity.warning,
          suggestion: 'Limited program options, higher rates likely',
        ),
      );
    } else if (ltv > 90) {
      warnings.add(
        ValidationWarning(
          message:
              'High LTV (${CurrencyFormatter.formatPercent(ltv, decimals: 1)})',
          severity: WarningSeverity.info,
          suggestion: 'Higher PMI rates and stricter guidelines may apply',
        ),
      );
    }

    // Program-specific max LTV
    if (loanType == 'Conventional' && ltv > conventionalMaxLtv) {
      warnings.add(
        ValidationWarning(
          message: 'Exceeds max conventional LTV (97%)',
          severity: WarningSeverity.critical,
          suggestion: 'Increase down payment or consider FHA/VA',
        ),
      );
    } else if (loanType == 'FHA' && ltv > fhaMaxLtv) {
      warnings.add(
        ValidationWarning(
          message: 'Exceeds max FHA LTV (96.5%)',
          severity: WarningSeverity.critical,
          suggestion: 'FHA requires minimum 3.5% down payment',
        ),
      );
    } else if (loanType == 'Jumbo' && ltv > jumboTypicalMax) {
      warnings.add(
        ValidationWarning(
          message: 'High LTV for jumbo loan',
          severity: WarningSeverity.warning,
          suggestion: 'Most jumbo programs require 10%+ down payment',
        ),
      );
    }

    return warnings;
  }
}

/// Comprehensive validation result with warnings
class EnhancedValidationResult {
  final bool hasErrors;
  final List<String> errors;
  final List<ValidationWarning> warnings;

  const EnhancedValidationResult({
    required this.hasErrors,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalWarnings =>
      warnings.any((w) => w.severity == WarningSeverity.critical);
}

/// Widget to display validation warnings
class ValidationWarningsDisplay extends StatelessWidget {
  final List<ValidationWarning> warnings;
  final bool compact;

  const ValidationWarningsDisplay({
    super.key,
    required this.warnings,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: warnings
          .map((warning) => _WarningTile(warning: warning, compact: compact))
          .toList(),
    );
  }
}

class _WarningTile extends StatelessWidget {
  final ValidationWarning warning;
  final bool compact;

  const _WarningTile({required this.warning, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(warning.icon, size: 14, color: warning.color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                warning.message,
                style: TextStyle(fontSize: 11, color: warning.color),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: warning.color.withValues(alpha: 0.08),
      child: ListTile(
        dense: true,
        leading: Icon(warning.icon, color: warning.color),
        title: Text(
          warning.message,
          style: TextStyle(
            fontSize: 13,
            color: warning.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: warning.suggestion != null
            ? Text(warning.suggestion!, style: const TextStyle(fontSize: 11))
            : null,
      ),
    );
  }
}
