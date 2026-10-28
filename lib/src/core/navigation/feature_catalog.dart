import 'package:flutter/material.dart';
import 'package:loan_ranger/src/features/amortization/presentation/screens/amortization_screen.dart';
import 'package:loan_ranger/src/features/analysis/presentation/screens/analysis_screen.dart';
import 'package:loan_ranger/src/features/buydown/presentation/screens/buydown_screen.dart';
import 'package:loan_ranger/src/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:loan_ranger/src/features/history/presentation/screens/history_screen.dart';
import 'package:loan_ranger/src/features/income/presentation/screens/income_screen.dart';
import 'package:loan_ranger/src/features/loan_programs/presentation/screens/loan_programs_screen.dart';
import 'package:loan_ranger/src/features/options/presentation/screens/options_screen.dart';
import 'package:loan_ranger/src/features/qualification/presentation/screens/qualification_screen.dart';
import 'package:loan_ranger/src/features/refinance/presentation/screens/refinance_screen.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/presentation/screens/rent_vs_buy_screen.dart';
import 'package:loan_ranger/src/features/second_lien/presentation/screens/second_lien_screen.dart';

class FeatureCatalogEntry {
  const FeatureCatalogEntry({
    required this.id,
    required this.title,
    required this.analyticsName,
    required this.category,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String analyticsName;
  final String category;
  final String description;
  final Widget icon;
  final Widget selectedIcon;
  final WidgetBuilder builder;
  final bool pinned;

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: title,
    );
  }

  NavigationRailDestination toRailDestination() {
    return NavigationRailDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: Text(title),
    );
  }
}

class FeatureCatalog {
  static const String calculatorId = 'calculator';
  static const String amortizationId = 'amortization';
  static const String qualificationId = 'qualification';
  static const String analysisId = 'analysis';
  static const String historyId = 'history';
  static const String loanProgramsId = 'loan_programs';
  static const String rentVsBuyId = 'rent_vs_buy';
  static const String buydownId = 'buydown';
  static const String refinanceId = 'refinance';
  static const String secondLienId = 'second_lien';
  static const String incomeId = 'income';
  static const String optionsId = 'options';

  static final List<FeatureCatalogEntry>
  primaryFeatures = <FeatureCatalogEntry>[
    FeatureCatalogEntry(
      id: calculatorId,
      title: 'Calculator',
      analyticsName: 'Calculator',
      category: 'Quote',
      description: 'Run payment, loan amount, term, and rate scenarios.',
      icon: const Icon(Icons.calculate_outlined),
      selectedIcon: const Icon(Icons.calculate),
      builder: (_) => const CalculatorScreen(),
      pinned: true,
    ),
    FeatureCatalogEntry(
      id: amortizationId,
      title: 'Amortization',
      analyticsName: 'Amortization',
      category: 'Analyze',
      description: 'Inspect payoff schedules, balances, and bi-weekly impacts.',
      icon: const Icon(Icons.table_chart_outlined),
      selectedIcon: const Icon(Icons.table_chart),
      builder: (_) => const AmortizationScreen(),
      pinned: true,
    ),
    FeatureCatalogEntry(
      id: qualificationId,
      title: 'Qualification',
      analyticsName: 'Qualification',
      category: 'Qualify',
      description: 'Calculate max loan and minimum income scenarios.',
      icon: const Icon(Icons.person_outline),
      selectedIcon: const Icon(Icons.person),
      builder: (_) => const QualificationScreen(),
      pinned: true,
    ),
    FeatureCatalogEntry(
      id: analysisId,
      title: 'Analysis',
      analyticsName: 'Analysis',
      category: 'Compare',
      description: 'Compare options and inspect scenario tradeoffs.',
      icon: const Icon(Icons.analytics_outlined),
      selectedIcon: const Icon(Icons.analytics),
      builder: (_) => const AnalysisScreen(),
      pinned: true,
    ),
    FeatureCatalogEntry(
      id: historyId,
      title: 'History',
      analyticsName: 'History',
      category: 'Follow-up',
      description: 'Restore saved calculations and recent scenario outputs.',
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history),
      builder: (_) => const HistoryScreen(),
      pinned: true,
    ),
  ];

  static final List<FeatureCatalogEntry> workspaceFeatures =
      <FeatureCatalogEntry>[
        ...primaryFeatures,
        FeatureCatalogEntry(
          id: loanProgramsId,
          title: 'Loan Programs',
          analyticsName: 'Loan Programs',
          category: 'Reference',
          description: 'Browse program guidance and preset comparisons.',
          icon: const Icon(Icons.account_balance_outlined),
          selectedIcon: const Icon(Icons.account_balance),
          builder: (_) => const LoanProgramsScreen(),
        ),
        FeatureCatalogEntry(
          id: rentVsBuyId,
          title: 'Rent vs Buy',
          analyticsName: 'Rent vs Buy',
          category: 'Analyze',
          description: 'Evaluate ownership costs against current rent.',
          icon: const Icon(Icons.home_work_outlined),
          selectedIcon: const Icon(Icons.home_work),
          builder: (_) => const RentVsBuyScreen(),
        ),
        FeatureCatalogEntry(
          id: buydownId,
          title: 'Buydown',
          analyticsName: 'Buydown',
          category: 'Quote',
          description: 'Compare 2-1, 1-0, 3-2-1 and 1-1 temporary buydowns.',
          icon: const Icon(Icons.trending_down_outlined),
          selectedIcon: const Icon(Icons.trending_down),
          builder: (_) => const BuydownScreen(),
        ),
        FeatureCatalogEntry(
          id: refinanceId,
          title: 'Refinance',
          analyticsName: 'Refinance',
          category: 'Analyze',
          description: 'Break-even and net tangible benefit for a refinance.',
          icon: const Icon(Icons.autorenew_outlined),
          selectedIcon: const Icon(Icons.autorenew),
          builder: (_) => const RefinanceScreen(),
        ),
        FeatureCatalogEntry(
          id: secondLienId,
          title: 'Second Lien',
          analyticsName: 'Second Lien',
          category: 'Quote',
          description: 'Piggyback 80-10-10 comparison and HELOC capacity.',
          icon: const Icon(Icons.layers_outlined),
          selectedIcon: const Icon(Icons.layers),
          builder: (_) => const SecondLienScreen(),
        ),
        FeatureCatalogEntry(
          id: incomeId,
          title: 'Income',
          analyticsName: 'Income',
          category: 'Qualify',
          description:
              'Self-employed, variable, rental income and student loans.',
          icon: const Icon(Icons.payments_outlined),
          selectedIcon: const Icon(Icons.payments),
          builder: (_) => const IncomeScreen(),
        ),
        FeatureCatalogEntry(
          id: optionsId,
          title: 'Options',
          analyticsName: 'Options',
          category: 'Quote',
          description:
              'Side-by-side loan options for a member, with a branded sheet.',
          icon: const Icon(Icons.view_column_outlined),
          selectedIcon: const Icon(Icons.view_column),
          builder: (_) => const OptionsScreen(),
          pinned: true,
        ),
      ];

  const FeatureCatalog();

  FeatureCatalogEntry? byId(String id) {
    for (final entry in workspaceFeatures) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }
}
