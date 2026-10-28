import 'package:loan_ranger/src/core/math/government_fees.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/models/loan_program.dart';

class BorrowerEligibility {
  const BorrowerEligibility({this.vaUse = VaUse.first, this.vaExempt = false});
  final VaUse vaUse;
  final bool vaExempt;
}

class ProgramCosts {
  const ProgramCosts({
    required this.baseLoan,
    required this.upfrontFee,
    required this.totalLoan,
    required this.annualMi,
    required this.miMonths,
    required this.exceedsLimit,
  });
  final double baseLoan;
  final double upfrontFee;
  final double totalLoan;
  final double annualMi; // annual dollars
  final int? miMonths;
  final bool exceedsLimit;
}

class ProgramCostService {
  const ProgramCostService();

  static const _fees = GovernmentFees();

  ProgramCosts compute({
    required LoanProgram program,
    required double price,
    required double downPayment,
    required double termYears,
    BorrowerEligibility eligibility = const BorrowerEligibility(),
  }) {
    final baseLoan = price - downPayment;
    final ltv = price > 0 ? baseLoan / price * 100 : 0.0;
    final downPct = price > 0 ? downPayment / price * 100 : 0.0;

    var upfrontPct = 0.0; // financed into the loan (FHA/VA/USDA only)
    var annualPct = 0.0;
    int? months;

    switch (program.type) {
      case LoanProgramType.fha:
        upfrontPct = _fees.fhaUpfrontMipRate();
        annualPct = _fees.fhaAnnualMipRate(
          baseLoan: baseLoan,
          ltv: ltv,
          termYears: termYears,
        );
        months = _fees.fhaMipMonths(ltv: ltv);
      case LoanProgramType.va:
        upfrontPct = _fees.vaFundingFeeRate(
          downPaymentPercent: downPct,
          use: eligibility.vaUse,
          purpose: VaPurpose.purchase,
          exempt: eligibility.vaExempt,
        );
      case LoanProgramType.usda:
        upfrontPct = _fees.usdaUpfrontRate();
        annualPct = _fees.usdaAnnualRate();
      case LoanProgramType.jumbo || LoanProgramType.nonQm:
        break;
      case LoanProgramType.conventional || LoanProgramType.custom:
        if (ltv > 80) annualPct = program.miConfig?.annualPercent ?? 0;
    }

    final fee = baseLoan * upfrontPct / 100;
    final total = baseLoan + fee;
    return ProgramCosts(
      baseLoan: baseLoan,
      upfrontFee: fee,
      totalLoan: total,
      annualMi: total * annualPct / 100,
      miMonths: months,
      exceedsLimit:
          program.maxLoanAmount != null && baseLoan > program.maxLoanAmount!,
    );
  }
}
