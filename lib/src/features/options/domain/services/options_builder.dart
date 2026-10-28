import 'package:loan_ranger/src/core/math/loan_math.dart';
import 'package:loan_ranger/src/features/buydown/domain/models/buydown.dart';
import 'package:loan_ranger/src/features/buydown/domain/services/buydown_calculator.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/models/loan_program.dart';
import 'package:loan_ranger/src/features/loan_programs/domain/services/program_cost_service.dart';
import 'package:loan_ranger/src/features/second_lien/domain/services/second_lien_calculator.dart';

import '../models/loan_option.dart';
import '../models/member_profile.dart';

class OptionsBuilder {
  const OptionsBuilder();

  List<LoanOption> build(
    MemberProfile m,
    RateSheet r, {
    double estimatedClosingCostsPercent = 3,
  }) {
    final closing = m.price * estimatedClosingCostsPercent / 100;
    final canAfford20 = m.cashAvailable >= m.price * 0.2 + closing;
    final progs = {for (final p in DefaultLoanPrograms.programs) p.id: p};
    final out = <LoanOption?>[];

    LoanOption make({
      required String id,
      required String title,
      required String programId,
      required double loanAmount,
      required double down,
      required double rate,
      required double pi,
      required double monthlyMi,
      required bool exceedsLimit,
      BuydownResult? buydown,
    }) {
      final piti =
          pi +
          (m.annualTax + m.annualInsurance) / 12 +
          m.hoaMonthly +
          monthlyMi;
      final dti = m.annualIncome > 0
          ? (piti + m.monthlyDebt) / (m.annualIncome / 12) * 100
          : null;
      final cash = down + closing;
      final maxDti = progs[programId]?.debtRatio ?? 0;
      return LoanOption(
        id: id,
        title: title,
        programId: programId,
        loanAmount: loanAmount,
        downPayment: down,
        rate: rate,
        principalAndInterest: pi,
        monthlyMi: monthlyMi,
        piti: piti,
        cashToClose: cash,
        backEndDti: dti,
        buydown: buydown,
        flags: [
          if (exceedsLimit) 'Exceeds loan limit',
          if (maxDti > 0 && dti != null && dti > maxDti) 'DTI over program max',
          if (cash > m.cashAvailable) 'Short on cash',
        ],
      );
    }

    LoanOption? program(
      String id,
      String title,
      String optId,
      double downPct,
      double term, {
      bool buydown = false,
    }) {
      final rate = r.ratesByProgramId[id];
      if (rate == null || rate <= 0) return null;
      final down = m.price * downPct / 100;
      final c = const ProgramCostService().compute(
        program: progs[id]!,
        price: m.price,
        downPayment: down,
        termYears: term,
        eligibility: m.eligibility,
      );
      final pi = LoanMath().calculatePayment(
        loanAmount: c.totalLoan,
        interestRate: rate,
        termYears: term,
      );
      BuydownResult? bd;
      if (buydown) {
        // A 2-1 buydown needs a note rate above 2 points.
        if (rate <= 2) return null;
        bd = const BuydownCalculator().calculate(
          loanAmount: c.totalLoan,
          noteRate: rate,
          termYears: term,
          type: BuydownType.twoOne,
        );
      }
      return make(
        id: optId,
        title: title,
        programId: id,
        loanAmount: c.totalLoan,
        down: down,
        rate: rate,
        pi: pi,
        monthlyMi: c.annualMi / 12,
        exceedsLimit: c.exceedsLimit,
        buydown: bd,
      );
    }

    final conv30Min = progs['conventional_30']!.minDownPaymentPercent;
    out
      ..add(
        program(
          'conventional_30',
          'Conventional 30 – min down',
          'conventional_30_min',
          conv30Min,
          30,
        ),
      )
      ..add(
        canAfford20
            ? program(
                'conventional_30',
                'Conventional 30 – 20% down',
                'conventional_30_20',
                20,
                30,
              )
            : null,
      )
      ..add(
        program(
          'conventional_15',
          'Conventional 15',
          'conventional_15',
          canAfford20 ? 20 : progs['conventional_15']!.minDownPaymentPercent,
          15,
        ),
      )
      ..add(program('fha_30', 'FHA 30', 'fha_30', 3.5, 30))
      ..add(m.isVeteran ? program('va_30', 'VA 30', 'va_30', 0, 30) : null)
      ..add(
        m.ruralEligible
            ? program('usda_30', 'USDA 30', 'usda_30', 0, 30)
            : null,
      )
      ..add(
        program(
          'conventional_30',
          'Conventional 30 + 2-1 buydown',
          'conventional_30_buydown',
          conv30Min,
          30,
          buydown: true,
        ),
      );

    final convRate = r.ratesByProgramId['conventional_30'];
    if (convRate != null && convRate > 0) {
      final pb = const SecondLienCalculator().piggyback(
        price: m.price,
        firstLtv: 80,
        secondLtv: 10,
        firstRate: convRate,
        secondRate: convRate + 2,
        termYears: 30,
        secondTermYears: 15,
        singleLoanMiAnnualPercent:
            progs['conventional_30']!.miConfig?.annualPercent ?? 0,
      );
      out.add(
        make(
          id: 'piggyback_80_10_10',
          title: '80-10-10 piggyback',
          programId: 'conventional_30',
          loanAmount: pb.firstLoan + pb.secondLoan,
          down: m.price * 0.1,
          rate: convRate,
          pi: pb.combinedPayment,
          monthlyMi: 0,
          exceedsLimit:
              pb.firstLoan >
              (progs['conventional_30']!.maxLoanAmount ?? double.infinity),
        ),
      );
    }

    return out.whereType<LoanOption>().toList()
      ..sort((a, b) => a.piti.compareTo(b.piti));
  }
}
