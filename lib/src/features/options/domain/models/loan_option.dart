import 'package:loan_ranger/src/features/buydown/domain/models/buydown.dart';

class LoanOption {
  const LoanOption({
    required this.id,
    required this.title,
    required this.programId,
    required this.loanAmount,
    required this.downPayment,
    required this.rate,
    required this.principalAndInterest,
    required this.monthlyMi,
    required this.piti,
    required this.cashToClose,
    required this.backEndDti,
    this.flags = const [],
    this.buydown,
  });

  final String id;
  final String title;
  final String programId;
  final double loanAmount;
  final double downPayment;
  final double rate;
  final double principalAndInterest;
  final double monthlyMi;
  final double piti;
  final double cashToClose;
  final double? backEndDti;
  final List<String> flags;
  final BuydownResult? buydown;
}
