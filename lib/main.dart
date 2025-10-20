import 'package:flutter/material.dart';
import 'package:loan_ranger/src/providers/calculator_provider.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'src/screens/calculator_screen.dart';
import 'src/screens/amortization_screen.dart';
import 'src/screens/qualification_screen.dart';
import 'src/screens/analysis_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => CalculatorProvider()),
      ],
      child: const LoanRangerApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
          title: 'Loan Ranger - Professional MLO Calculator',
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

  final List<Widget> _screens = const [
    CalculatorScreen(),
    AmortizationScreen(),
    QualificationScreen(),
    AnalysisScreen(),
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
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOAN RANGER'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            onPressed: () {
              // Show NLP input dialog
              _showNLPDialog(context);
            },
            tooltip: 'Voice/Text input',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _destinations,
        elevation: 8,
      ),
    );
  }

  void _showNLPDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Natural Language Input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask me to calculate anything! Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '• "Calculate payment for \$350,000 at 5.5% for 30 years"\n'
              '• "What\'s my max loan with \$100,000 income?"\n'
              '• "Show amortization schedule"',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Type your question here...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              maxLines: 3,
              onSubmitted: (value) {
                Navigator.pop(context);
                _processNLPQuery(context, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Voice input would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice input feature coming soon!'),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: 18),
                SizedBox(width: 4),
                Text('Voice'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processNLPQuery(BuildContext context, String query) {
    // TODO: Integrate with NLP service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing: $query'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
