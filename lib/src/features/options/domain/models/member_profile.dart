import 'package:loan_ranger/src/features/loan_programs/domain/services/program_cost_service.dart';

class MemberProfile {
  const MemberProfile({
    required this.price,
    required this.cashAvailable,
    this.annualIncome = 0,
    this.monthlyDebt = 0,
    this.annualTax = 0,
    this.annualInsurance = 0,
    this.hoaMonthly = 0,
    this.isVeteran = false,
    this.eligibility = const BorrowerEligibility(),
    this.ruralEligible = false,
  });

  final double price;
  final double cashAvailable;
  final double annualIncome;
  final double monthlyDebt;
  final double annualTax; // annual dollars
  final double annualInsurance; // annual dollars
  final double hoaMonthly;
  final bool isVeteran;
  final BorrowerEligibility eligibility;
  final bool ruralEligible;
}

/// MLO-entered rates in whole percents, keyed by program id.
class RateSheet {
  const RateSheet(this.ratesByProgramId);
  final Map<String, double> ratesByProgramId;
}
