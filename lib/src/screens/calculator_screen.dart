import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/calculator_button.dart';
import '../widgets/animated_display.dart';
import '../services/nlp_calculator_service.dart';
import '../widgets/nlp_dialog.dart';
import '../utils/constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

enum MicState { idle, listening, processing, error }

class _CalculatorScreenState extends State<CalculatorScreen> {
  late FocusNode _focusNode;
  final NLPCalculatorService _nlpService = NLPCalculatorService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  MicState _micState = MicState.idle;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _focusNode.dispose();
    super.dispose();
  }

  Color _getMicColor() {
    switch (_micState) {
      case MicState.idle:
        return AppConstants.micIdleColor;
      case MicState.listening:
        return AppConstants.micListeningColor;
      case MicState.processing:
        return AppConstants.micProcessingColor;
      case MicState.error:
        return AppConstants.micErrorColor;
    }
  }

  void _showVoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NlpDialog(
        nlpService: _nlpService,
        speechToText: _speechToText,
        onStateChanged: (bool isListening, bool isProcessing, bool hasError) {
          setState(() {
            if (hasError) {
              _micState = MicState.error;
            } else if (isProcessing) {
              _micState = MicState.processing;
            } else if (isListening) {
              _micState = MicState.listening;
            } else {
              _micState = MicState.idle;
            }
          });
        },
      ),
    ).then((_) {
      // Reset mic state when dialog closes
      setState(() {
        _micState = MicState.idle;
      });
    });
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection(
                context,
                'Standard Calculator',
                'Enter 3 of the 4 main variables (Price/Loan Amount, Rate, Term, Payment) and the 4th will be calculated automatically.',
              ),
              _buildInfoSection(
                context,
                'PITI Factors',
                'Enter Tax, Insurance, and HOA (Monthly Expenses) to see the full monthly payment (PITI).',
              ),
              _buildInfoSection(
                context,
                'Voice Assistant',
                'Tap the microphone to ask questions like "Payment for 400k at 6.5%" or "Amortization for 300k".',
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _handleKeyPress(KeyEvent event, CalculatorProvider provider) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Numbers 0-9 (main keyboard)
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      provider.inputDigit('0');
    } else if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      provider.inputDigit('1');
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      provider.inputDigit('2');
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      provider.inputDigit('3');
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      provider.inputDigit('4');
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      provider.inputDigit('5');
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      provider.inputDigit('6');
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      provider.inputDigit('7');
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      provider.inputDigit('8');
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      provider.inputDigit('9');
    }
    // Decimal point
    else if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      provider.inputDecimal();
    }
    // Operations
    else if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      provider.performOperation('+');
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      provider.performOperation('-');
    } else if (key == LogicalKeyboardKey.asterisk ||
        key == LogicalKeyboardKey.numpadMultiply) {
      provider.performOperation('x');
    } else if (key == LogicalKeyboardKey.slash ||
        key == LogicalKeyboardKey.numpadDivide) {
      provider.performOperation('/');
    }
    // Equals
    else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.equal) {
      provider.calculateResult();
    }
    // Clear
    else if (key == LogicalKeyboardKey.escape) {
      provider.clearAll();
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      provider.backspace();
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider>(context);

    // Only use keyboard listener on desktop platforms
    final bool isDesktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final Widget calculatorUI = Container(
      color: const Color(0xFF2C3E50),
      child: Column(
        children: [
          // Display Screen
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedDisplay(
                key: const ValueKey('display'),
                displayValue: calculatorProvider.displayValue,
                subtitle: calculatorProvider.inputError ??
                    (calculatorProvider.displayMode == 'piti' &&
                            calculatorProvider.payment != null
                        ? 'PITI'
                        : (calculatorProvider.displayMode == 'io'
                            ? 'Interest Only'
                            : null)),
                isError: calculatorProvider.displayValue == 'Error' ||
                    calculatorProvider.inputError != null,
              ),
            ),
          ),

          // Calculator Buttons
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                children: [
                  // Row 1: Price, L/A, Term, Pmt, AC
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: 'Price',
                          onPressed: () => calculatorProvider.setPrice(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'L/A',
                          onPressed: () => calculatorProvider.setLoanAmount(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Term',
                          onPressed: () => calculatorProvider.setTermYears(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Pmt',
                          onPressed: () => calculatorProvider.setPayment(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'AC',
                          onPressed: () => calculatorProvider.clearAll(),
                          backgroundColor: const Color(0xFF8B3A3A),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 2: DnPmt, Int, Tax, Ins, ÷
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: 'DnPmt',
                          onPressed: () => calculatorProvider.setDownPayment(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Int',
                          onPressed: () => calculatorProvider.setInterestRate(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Tax',
                          onPressed: () => calculatorProvider.setPropertyTax(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Ins',
                          onPressed: () =>
                              calculatorProvider.setHomeInsurance(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '÷',
                          onPressed: () =>
                              calculatorProvider.performOperation('/'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 3: 7, 8, 9, Calculator Icon, ×
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: '7',
                          onPressed: () => calculatorProvider.inputDigit('7'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '8',
                          onPressed: () => calculatorProvider.inputDigit('8'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '9',
                          onPressed: () => calculatorProvider.inputDigit('9'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Backspace',
                          icon: Icons.backspace_outlined,
                          onPressed: () => calculatorProvider.backspace(),
                          onLongPress: () => calculatorProvider.clearAll(),
                          backgroundColor: AppConstants.backspaceNormalColor,
                          foregroundColor: Colors.white,
                          animationType: ButtonAnimationType.wiggle,
                        ),
                        CalculatorButton(
                          text: '×',
                          onPressed: () =>
                              calculatorProvider.performOperation('x'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 4: 4, 5, 6, Info Icon, −
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: '4',
                          onPressed: () => calculatorProvider.inputDigit('4'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '5',
                          onPressed: () => calculatorProvider.inputDigit('5'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '6',
                          onPressed: () => calculatorProvider.inputDigit('6'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Info',
                          icon: Icons.info_outline,
                          onPressed: () => _showInfoDialog(context),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '−',
                          onPressed: () =>
                              calculatorProvider.performOperation('-'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 5: 1, 2, 3, Mic Icon, +
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: '1',
                          onPressed: () => calculatorProvider.inputDigit('1'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '2',
                          onPressed: () => calculatorProvider.inputDigit('2'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '3',
                          onPressed: () => calculatorProvider.inputDigit('3'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Voice',
                          icon: Icons.mic,
                          onPressed: () => _showVoiceDialog(context),
                          backgroundColor: _getMicColor(),
                          foregroundColor: Colors.white,
                          animationType: ButtonAnimationType.pulse,
                          isActive: _micState == MicState.listening,
                        ),
                        CalculatorButton(
                          text: '+',
                          onPressed: () =>
                              calculatorProvider.performOperation('+'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 6: 0 (wider), ., =
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ElevatedButton(
                              key: const Key('btn_0'),
                              onPressed: () =>
                                  calculatorProvider.inputDigit('0'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34495E),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('0'),
                            ),
                          ),
                        ),
                        CalculatorButton(
                          text: '.',
                          onPressed: () => calculatorProvider.inputDecimal(),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '=',
                          onPressed: () => calculatorProvider.calculateResult(),
                          backgroundColor: const Color(0xFFE67E22),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap with KeyboardListener only on desktop
    return isDesktop
        ? KeyboardListener(
            focusNode: _focusNode..requestFocus(),
            autofocus: true,
            onKeyEvent: (event) => _handleKeyPress(event, calculatorProvider),
            child: calculatorUI,
          )
        : calculatorUI;
  }
}
