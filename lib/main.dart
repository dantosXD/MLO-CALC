import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/bootstrap/app_bootstrap_gate.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/core/navigation/app_router.dart';
import 'package:loan_ranger/src/core/navigation/feature_catalog.dart';
import 'package:loan_ranger/src/core/persistence/preference_store.dart';
import 'package:loan_ranger/src/core/persistence/secure_store.dart';
import 'package:loan_ranger/src/core/services/analytics_service.dart';
import 'package:loan_ranger/src/core/services/connectivity_service.dart';
import 'package:loan_ranger/src/core/theme/theme_provider.dart';
import 'package:loan_ranger/src/core/utils/unit_conversion.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/amortization_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/history_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/loan_quote_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/controllers/qualification_controller.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/layout_preference_provider.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/amortization_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/core_calculation_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/persistence_service.dart';
import 'package:loan_ranger/src/features/calculator/domain/services/qualification_service.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/info_dialog.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/nlp_bottom_sheet.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/features/loan_programs/application/providers/loan_programs_provider.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_cache_service.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:loan_ranger/src/features/qualification/application/providers/qualifying_ratios_provider.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:loan_ranger/src/features/share/application/providers/share_templates_provider.dart';
import 'package:loan_ranger/src/features/share/domain/models/quote_share_data.dart';
import 'package:loan_ranger/src/features/share/presentation/dialogs/share_quote_dialog.dart';
import 'package:loan_ranger/src/features/updater/application/providers/update_notifier.dart';
import 'package:loan_ranger/src/features/updater/domain/services/update_service.dart';
import 'package:loan_ranger/src/features/updater/presentation/widgets/update_banner.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(
    MultiProvider(providers: buildAppProviders(), child: const LoanRangerApp()),
  );
}

List<SingleChildWidget> buildAppProviders() => [
  ChangeNotifierProvider(
    create: (_) =>
        ThemeProvider(preferenceStore: serviceLocator<PreferenceStore>()),
  ),
  ChangeNotifierProvider(
    create: (_) => MloProfileProvider(
      preferenceStore: serviceLocator<PreferenceStore>(),
      secureStore: serviceLocator<SecureStore>(),
    ),
  ),
  ChangeNotifierProvider.value(value: serviceLocator<ConnectivityService>()),
  Provider.value(value: serviceLocator<AnalyticsService>()),
  ChangeNotifierProvider.value(value: serviceLocator<AppRouter>()),
  ChangeNotifierProvider(
    create: (_) => LayoutPreferenceProvider(
      preferenceStore: serviceLocator<PreferenceStore>(),
    ),
  ),
  ChangeNotifierProvider(create: (_) => CalculatorDisplayNotifier()),
  ChangeNotifierProvider(
    create: (_) => CalculatorProvider(
      coreCalculationService: serviceLocator<CoreCalculationService>(),
      amortizationService: serviceLocator<AmortizationService>(),
      qualificationService: serviceLocator<QualificationService>(),
      persistenceService: serviceLocator<CalculatorPersistenceService>(),
    ),
  ),
  ListenableProxyProvider<CalculatorProvider, LoanQuoteController>(
    update: (_, calculator, __) => calculator.loanQuoteController,
  ),
  ListenableProxyProvider<CalculatorProvider, QualificationController>(
    update: (_, calculator, __) => calculator.qualificationController,
  ),
  ListenableProxyProvider<CalculatorProvider, AmortizationController>(
    update: (_, calculator, __) => calculator.amortizationController,
  ),
  ListenableProxyProvider<CalculatorProvider, HistoryController>(
    update: (_, calculator, __) => calculator.historyController,
  ),
  ChangeNotifierProvider(create: (_) => ComparisonProvider()),
  ChangeNotifierProvider(
    create: (_) => NlpSettingsProvider(
      connectivity: serviceLocator<ConnectivityService>(),
      cache: serviceLocator<NlpCacheService>(),
      calculatorService: serviceLocator<NLPCalculatorService>(),
      secureStore: serviceLocator<SecureStore>(),
      preferenceStore: serviceLocator<PreferenceStore>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (_) => LoanProgramsProvider(
      preferenceStore: serviceLocator<PreferenceStore>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (_) => UnitConversionProvider(
      preferenceStore: serviceLocator<PreferenceStore>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (_) => QualifyingRatiosProvider(
      preferenceStore: serviceLocator<PreferenceStore>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (_) => ShareTemplatesProvider(
      preferenceStore: serviceLocator<PreferenceStore>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (_) =>
        UpdateNotifier(service: serviceLocator<UpdateService>()),
  ),
];

class LoanRangerApp extends StatelessWidget {
  const LoanRangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, AppRouter, MloProfileProvider>(
      builder: (context, themeProvider, router, mloProfile, child) {
        final accent = Color(mloProfile.accentColorValue);
        return MaterialApp(
          title: 'MLO-Calc - Professional Mortgage Calculator',
          theme: AppTheme.lightTheme(accent: accent),
          darkTheme: AppTheme.darkTheme(accent: accent),
          themeMode: themeProvider.themeMode,
          navigatorKey: router.navigatorKey,
          home: const AppBootstrapGate(child: MainNavigator()),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  final FeatureCatalog _featureCatalog = const FeatureCatalog();
  final List<FeatureCatalogEntry> _primaryFeatures =
      FeatureCatalog.primaryFeatures;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = _primaryFeatures
        .map((e) => e.toNavigationDestination())
        .toList();
  }

  void _trackScreenView(int index) {
    if (index >= 0 && index < _primaryFeatures.length) {
      context.read<AnalyticsService>().trackScreenView(
        _primaryFeatures[index].analyticsName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useRail = constraints.maxWidth >= 900;
        final bool extendRail = constraints.maxWidth >= 1200;
        final bool compactAppBar = constraints.maxWidth < 700;
        final bool bootstrapLayout = constraints.maxWidth < 50;
        final railDestinations = _primaryFeatures
            .map((FeatureCatalogEntry entry) => entry.toRailDestination())
            .toList();

        final List<Widget> appBarActions = bootstrapLayout
            ? const <Widget>[]
            : [
                _AppBarActions(
                  isCalculatorTab:
                      _primaryFeatures[_selectedIndex].id ==
                      FeatureCatalog.calculatorId,
                  compact: compactAppBar,
                  onWorkspace: () => _openWorkspaceDashboard(context),
                  onFeatureById: (id) => _openFeatureById(context, id),
                ),
              ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('MLO-Calc'),
            centerTitle: false,
            actions: appBarActions,
          ),
          body: UpdateBanner(
            child: SafeArea(
              child: Row(
                children: [
                if (useRail)
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    extended: extendRail,
                    labelType: extendRail
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _trackScreenView(index);
                    },
                    leading: const SizedBox(height: 12),
                    destinations: railDestinations,
                  ),
                if (useRail) const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _primaryFeatures[_selectedIndex].builder(context),
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _trackScreenView(index);
                  },
                  destinations: _destinations,
                  elevation: 8,
                ),
        );
      },
    );
  }

  Future<void> _openWorkspaceDashboard(BuildContext context) async {
    final selectedFeatureId = await context
        .read<AppRouter>()
        .openWorkspaceDashboard();
    if (!context.mounted || selectedFeatureId == null) {
      return;
    }

    await _openFeatureById(context, selectedFeatureId);
  }

  Future<void> _openFeatureById(BuildContext context, String featureId) async {
    final primaryIndex = _primaryFeatures.indexWhere(
      (FeatureCatalogEntry entry) => entry.id == featureId,
    );
    if (primaryIndex != -1) {
      setState(() {
        _selectedIndex = primaryIndex;
      });
      _trackScreenView(primaryIndex);
      return;
    }

    final feature = _featureCatalog.byId(featureId);
    if (feature == null || !mounted) return;

    context.read<AnalyticsService>().trackScreenView(feature.analyticsName);
    await context.read<AppRouter>().openFeatureById(featureId);
  }
}

class _AppBarActions extends StatelessWidget {
  const _AppBarActions({
    required this.isCalculatorTab,
    required this.compact,
    required this.onWorkspace,
    required this.onFeatureById,
  });

  final bool isCalculatorTab;
  final bool compact;
  final VoidCallback onWorkspace;
  final void Function(String id) onFeatureById;

  @override
  Widget build(BuildContext context) {
    void openShareQuote() {
      final provider = context.read<CalculatorProvider>();
      ShareQuoteDialog.show(
        context,
        data: QuoteShareData.fromCalculatorProvider(provider),
        scenarioName: 'Quick Quote',
      );
    }

    void showNlp() {
      NlpBottomSheet.show(context);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.ios_share),
          onPressed: isCalculatorTab ? openShareQuote : null,
          tooltip: 'Share quote',
        ),
        IconButton(
          icon: const Icon(Icons.mic_outlined),
          onPressed: showNlp,
          tooltip: 'Voice/Text input',
        ),
        PopupMenuButton<String>(
          icon: Icon(compact ? Icons.more_vert : Icons.settings_outlined),
          tooltip: 'More',
          onSelected: (value) {
            switch (value) {
              case 'settings':
                context.read<AppRouter>().openSettings();
                break;
              case 'how_to':
                InfoDialog.show(context);
                break;
              case 'workspace':
                onWorkspace();
                break;
              case 'loan_programs':
                onFeatureById(FeatureCatalog.loanProgramsId);
                break;
              case 'rent_vs_buy':
                onFeatureById(FeatureCatalog.rentVsBuyId);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.tune_outlined),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'how_to',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('How to Use'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'workspace',
              child: ListTile(
                leading: Icon(Icons.space_dashboard_outlined),
                title: Text('Workspace Dashboard'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'loan_programs',
              child: ListTile(
                leading: Icon(Icons.account_balance),
                title: Text('Loan Programs'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'rent_vs_buy',
              child: ListTile(
                leading: Icon(Icons.home_work),
                title: Text('Rent vs Buy'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
