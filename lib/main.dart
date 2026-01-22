import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/di/service_locator.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/layout_preference_provider.dart';
import 'package:loan_ranger/src/features/calculator/presentation/screens/calculator_layout_preview_screen.dart';
import 'package:loan_ranger/src/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/nlp_dialog.dart';
import 'package:loan_ranger/src/features/calculator/presentation/widgets/info_dialog.dart';
import 'package:loan_ranger/src/features/comparison/application/providers/comparison_provider.dart';
import 'package:loan_ranger/src/features/history/presentation/screens/history_screen.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/loan_programs/application/providers/loan_programs_provider.dart';
import 'package:loan_ranger/src/features/loan_programs/presentation/screens/loan_programs_screen.dart';
import 'package:loan_ranger/src/core/utils/unit_conversion.dart';
import 'package:loan_ranger/src/core/services/analytics_service.dart';
import 'package:loan_ranger/src/features/qualification/application/providers/qualifying_ratios_provider.dart';
import 'package:loan_ranger/src/features/nlp/domain/services/nlp_calculator_service.dart';
import 'package:loan_ranger/src/features/share/application/providers/share_templates_provider.dart';
import 'package:loan_ranger/src/features/share/domain/models/quote_share_data.dart';
import 'package:loan_ranger/src/features/share/presentation/dialogs/share_quote_dialog.dart';
import 'package:loan_ranger/src/features/amortization/presentation/screens/amortization_screen.dart';
import 'package:loan_ranger/src/features/analysis/presentation/screens/analysis_screen.dart';
import 'package:loan_ranger/src/features/qualification/presentation/screens/qualification_screen.dart';
import 'package:loan_ranger/src/features/rent_vs_buy/presentation/screens/rent_vs_buy_screen.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LayoutPreferenceProvider()),
        ChangeNotifierProvider(create: (context) => CalculatorDisplayNotifier()),
        ChangeNotifierProvider(create: (context) => CalculatorProvider()),
        ChangeNotifierProvider(create: (context) => ComparisonProvider()),
        ChangeNotifierProvider(create: (context) => NlpSettingsProvider()),
        ChangeNotifierProvider(create: (context) => LoanProgramsProvider()),
        ChangeNotifierProvider(create: (context) => UnitConversionProvider()),
        ChangeNotifierProvider(create: (context) => AnalyticsService()),
        ChangeNotifierProvider(create: (context) => QualifyingRatiosProvider()),
        ChangeNotifierProvider(create: (context) => ShareTemplatesProvider()),
      ],
      child: const LoanRangerApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class LoanRangerApp extends StatelessWidget {
  const LoanRangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MLO-Calc - Professional Mortgage Calculator',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          home: const MainNavigator(),
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
  final NLPCalculatorService _nlpService =
      serviceLocator<NLPCalculatorService>();
  StreamSubscription<double>? _calculationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calcProvider = context.read<CalculatorProvider>();
      final displayProvider = context.read<CalculatorDisplayNotifier>();
      
      _calculationSubscription = calcProvider.onCalculationResult.listen((value) {
        displayProvider.setValue(value);
      });
    });
  }

  @override
  void dispose() {
    _calculationSubscription?.cancel();
    super.dispose();
  }
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  final List<Widget> _screens = const [
    CalculatorScreen(),
    AmortizationScreen(),
    QualificationScreen(),
    AnalysisScreen(),
    HistoryScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.calculate_outlined),
      selectedIcon: Icon(Icons.calculate),
      label: 'Calculator',
    ),
    NavigationDestination(
      icon: Icon(Icons.table_chart_outlined),
      selectedIcon: Icon(Icons.table_chart),
      label: 'Amortization',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Qualification',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analysis',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'History',
    ),
  ];

  static const List<String> _screenNames = [
    'Calculator',
    'Amortization',
    'Qualification',
    'Analysis',
    'History',
  ];

  void _trackScreenView(int index) {
    if (index >= 0 && index < _screenNames.length) {
      context.read<AnalyticsService>().trackScreenView(_screenNames[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useRail = constraints.maxWidth >= 900;
        final bool extendRail = constraints.maxWidth >= 1200;
        final bool compactAppBar = constraints.maxWidth < 700;
        final bool bootstrapLayout = constraints.maxWidth < 50;
        final railDestinations = _destinations
            .map(
              (destination) => NavigationRailDestination(
                icon: destination.icon,
                selectedIcon: destination.selectedIcon,
                label: Text(destination.label),
              ),
            )
            .toList();

        void openShareQuote() {
          final provider = context.read<CalculatorProvider>();
          ShareQuoteDialog.show(
            context,
            data: QuoteShareData.fromCalculatorProvider(provider),
            scenarioName: 'Quick Quote',
          );
        }

        final List<Widget> appBarActionChildren = [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _selectedIndex == 0 ? openShareQuote : null,
            tooltip: 'Share quote',
          ),
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            onPressed: () {
              _showNLPDialog(context);
            },
            tooltip: 'Voice/Text input',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              compactAppBar ? Icons.more_vert : Icons.settings_outlined,
            ),
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'how_to':
                  InfoDialog.show(context);
                  break;
                case 'calc_layout_preview':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalculatorLayoutPreviewScreen(),
                    ),
                  );
                  break;
                case 'toggle_theme':
                  themeProvider.toggleTheme();
                  break;
                case 'api_key':
                  _showApiKeySheet(context);
                  break;
                case 'loan_programs':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoanProgramsScreen(),
                    ),
                  );
                  break;
                case 'rent_vs_buy':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RentVsBuyScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'how_to',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('How to Use'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'calc_layout_preview',
                child: ListTile(
                  leading: Icon(Icons.dashboard_customize_outlined),
                  title: Text('Calculator Layout Preview'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'toggle_theme',
                child: ListTile(
                  leading: Icon(
                    themeProvider.themeMode == ThemeMode.light
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: const Text('Toggle theme'),
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
              const PopupMenuItem(
                value: 'api_key',
                child: ListTile(
                  leading: Icon(Icons.key),
                  title: Text('API Key'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ];

        final List<Widget> appBarActions =
            bootstrapLayout ? const <Widget>[] : appBarActionChildren;

        return Scaffold(
          appBar: AppBar(
            title: const Text('MLO-Calc'),
            centerTitle: false,
            actions: appBarActions,
          ),
          body: SafeArea(
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
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
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

  void _showApiKeySheet(BuildContext context) {
    final settings = context.read<NlpSettingsProvider>();
    final controller = TextEditingController(text: settings.apiKey ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini API Key',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your Gemini API key',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await settings.setApiKey(controller.text);
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('API key saved')),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      controller.clear();
                      await settings.setApiKey(null);
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('API key cleared')),
                      );
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Your key is stored locally on this device using Shared Preferences.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNLPDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          NlpDialog(nlpService: _nlpService, speechToText: _speechToText),
    );
  }
}
