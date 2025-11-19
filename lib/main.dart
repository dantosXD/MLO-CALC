import 'package:flutter/material.dart';
import 'package:loan_ranger/src/providers/calculator_provider.dart';
import 'package:loan_ranger/src/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/services/nlp_calculator_service.dart';
import 'package:loan_ranger/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'src/screens/amortization_screen.dart';
import 'src/screens/analysis_screen.dart';
import 'src/screens/calculator_screen.dart';
import 'src/screens/history_screen.dart';
import 'src/screens/qualification_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => CalculatorProvider()),
        ChangeNotifierProvider(create: (context) => NlpSettingsProvider()),
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
  final NLPCalculatorService _nlpService = NLPCalculatorService();
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MLO-Calc'),
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showApiKeySheet(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            onPressed: () => _showNLPDialog(context),
            tooltip: 'Voice/Text input',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _screens[_selectedIndex]),
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
          _NlpDialog(nlpService: _nlpService, speechToText: _speechToText),
    );
  }
}

class _NlpDialog extends StatefulWidget {
  const _NlpDialog({required this.nlpService, required this.speechToText});

  final NLPCalculatorService nlpService;
  final stt.SpeechToText speechToText;

  @override
  State<_NlpDialog> createState() => _NlpDialogState();
}

class _NlpDialogState extends State<_NlpDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;
  bool _isProcessing = false;
  String? _status;

  @override
  void dispose() {
    widget.speechToText.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.speechToText.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await widget.speechToText.initialize(
      onStatus: (status) => setState(() => _status = status),
      onError: (error) => setState(() => _status = error.errorMsg),
    );

    if (!available) {
      setState(() {
        _status = 'Microphone not available';
      });
      return;
    }

    setState(() => _isListening = true);

    await widget.speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  Future<void> _runNlp() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _status = 'Please say or type a question.');
      return;
    }

    final settings = context.read<NlpSettingsProvider>();
    final apiKey = settings.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _status = 'Add your Gemini API key in Settings.');
      return;
    }

    final calculator = context.read<CalculatorProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isProcessing = true;
      _status = 'Understanding your request...';
    });

    try {
      if (!widget.nlpService.isInitialized) {
        await widget.nlpService.initialize(apiKey);
      }
      final request = await widget.nlpService.processQuery(query);
      final String resultMessage = await calculator.applyNlpRequest(request);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(resultMessage)));
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = NLPCalculatorService().getSuggestions();

    return AlertDialog(
      title: const Text('Natural Language Input'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Say or type your question...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            maxLines: 3,
            onSubmitted: (_) => _runNlp(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(3).map((s) {
              return ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  _controller.text = s;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: s.length),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (_status != null)
            Text(
              _status!,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        IconButton(
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          tooltip: _isListening ? 'Stop listening' : 'Start voice input',
          onPressed: _isProcessing ? null : _toggleListening,
        ),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _runNlp,
          icon: _isProcessing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isProcessing ? 'Processing...' : 'Go'),
        ),
      ],
    );
  }
}
