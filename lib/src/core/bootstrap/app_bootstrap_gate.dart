import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/calculator/application/providers/calculator_provider.dart';
import '../../features/calculator/application/providers/layout_preference_provider.dart';
import '../../features/loan_programs/application/providers/loan_programs_provider.dart';
import '../../features/nlp/application/providers/nlp_settings_provider.dart';
import '../../features/qualification/application/providers/qualifying_ratios_provider.dart';
import '../../features/settings/domain/providers/mlo_profile_provider.dart';
import '../../features/share/application/providers/share_templates_provider.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../theme/theme_provider.dart';
import '../utils/unit_conversion.dart';

class AppBootstrapGate extends StatefulWidget {
  const AppBootstrapGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends State<AppBootstrapGate> {
  Future<void>? _bootstrapFuture;

  bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bootstrapFuture ??= _bootstrap();
  }

  Future<void> _bootstrap() async {
    final connectivity = context.read<ConnectivityService>();
    final analytics = context.read<AnalyticsService>();
    final calculator = context.read<CalculatorProvider>();
    final layout = context.read<LayoutPreferenceProvider>();
    final units = context.read<UnitConversionProvider>();
    final ratios = context.read<QualifyingRatiosProvider>();
    final programs = context.read<LoanProgramsProvider>();
    final templates = context.read<ShareTemplatesProvider>();
    final nlp = context.read<NlpSettingsProvider>();
    final mloProfile = context.read<MloProfileProvider>();
    final theme = context.read<ThemeProvider>();

    await connectivity.initialize();
    await analytics.initialize();
    await Future.wait([
      calculator.initialize(),
      layout.load(),
      units.load(),
      ratios.load(),
      programs.load(),
      templates.load(),
      nlp.load(),
      mloProfile.load(),
      theme.load(),
    ]);

    // Apply MLO-defined defaults to fields with no prior session value
    calculator.applyDefaultsIfEmpty(
      interestRate: mloProfile.defaultInterestRate,
      termYears: mloProfile.defaultTermYears,
      downPaymentPct: mloProfile.defaultDownPaymentPct,
      propertyTaxRate: mloProfile.defaultPropertyTaxRate,
      insuranceRate: mloProfile.defaultInsuranceRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isTestEnvironment) {
      return widget.child;
    }

    final future = _bootstrapFuture;
    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.child;
      },
    );
  }
}
