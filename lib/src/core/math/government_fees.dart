/// Government loan (FHA / VA / USDA) fee schedules and 2026 loan limits.
///
/// Tables are as of 2026-10-28 (HUD ML 2023-05; VA.gov) and must be
/// re-verified yearly. All rates are whole percents (1.75 = 1.75%).
library;

enum VaUse { first, subsequent }

enum VaPurpose { purchase, cashOutRefi, irrrl }

/// One-unit 2026 loan limits.
class LoanLimits2026 {
  const LoanLimits2026._();

  static const conformingBaseline = 832750.0;
  static const highCostCeiling = 1249125.0;
  static const fhaFloor = 541287.0;
  static const fhaCeiling = 1249125.0;
}

class GovernmentFees {
  const GovernmentFees();

  static const double _fhaBigLoan = 726200;

  /// FHA upfront MIP, % of base loan.
  double fhaUpfrontMipRate() => 1.75;

  /// FHA annual MIP rate (% per year) per HUD ML 2023-05.
  double fhaAnnualMipRate({
    required double baseLoan,
    required double ltv,
    required double termYears,
  }) {
    final big = baseLoan > _fhaBigLoan;
    if (termYears > 15) {
      if (big) return ltv <= 95 ? 0.70 : 0.75;
      return ltv <= 95 ? 0.50 : 0.55;
    }
    if (big) {
      if (ltv <= 78) return 0.15;
      return ltv <= 90 ? 0.40 : 0.65;
    }
    return ltv <= 90 ? 0.15 : 0.40;
  }

  /// Months annual MIP is charged: 132 when LTV <= 90, else null (life of loan).
  int? fhaMipMonths({required double ltv}) => ltv <= 90 ? 132 : null;

  /// VA funding fee, % of loan. Refi types ignore down payment.
  double vaFundingFeeRate({
    required double downPaymentPercent,
    required VaUse use,
    required VaPurpose purpose,
    bool exempt = false,
  }) {
    if (exempt) return 0;
    if (purpose == VaPurpose.irrrl) return 0.50;
    final down = purpose == VaPurpose.purchase ? downPaymentPercent : 0;
    if (down >= 10) return 1.25;
    if (down >= 5) return 1.50;
    return use == VaUse.first ? 2.15 : 3.30;
  }

  /// USDA upfront guarantee fee, % of loan.
  double usdaUpfrontRate() => 1.00;

  /// USDA annual fee, % per year.
  double usdaAnnualRate() => 0.35;
}
