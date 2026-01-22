import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loan_ranger/src/core/utils/constants.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_display_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/calculator_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/layout_preference_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/animated_display.dart';
import '../widgets/calculator_button.dart';
import '../widgets/modern_calculator.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(KeyEvent event, CalculatorDisplayNotifier displayProvider, CalculatorProvider calculatorProvider) {
    if (event is! KeyDownEvent) return;
    
    final key = event.logicalKey;

    // Numbers 0-9 (main keyboard)
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      displayProvider.inputDigit('0');
    } else if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      displayProvider.inputDigit('1');
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      displayProvider.inputDigit('2');
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      displayProvider.inputDigit('3');
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      displayProvider.inputDigit('4');
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      displayProvider.inputDigit('5');
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      displayProvider.inputDigit('6');
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      displayProvider.inputDigit('7');
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      displayProvider.inputDigit('8');
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      displayProvider.inputDigit('9');
    }
    // Decimal point
    else if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      displayProvider.inputDecimal();
    }
    // Operations
    else if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      displayProvider.performOperation('+');
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      displayProvider.performOperation('-');
    } else if (key == LogicalKeyboardKey.asterisk ||
        key == LogicalKeyboardKey.numpadMultiply) {
      displayProvider.performOperation('x');
    } else if (key == LogicalKeyboardKey.slash ||
        key == LogicalKeyboardKey.numpadDivide) {
      displayProvider.performOperation('/');
    }
    // Equals
    else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.equal) {
      displayProvider.calculateResult();
    }
    // Clear
    else if (key == LogicalKeyboardKey.escape) {
      displayProvider.clearAll();
      calculatorProvider.clearAll();
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      displayProvider.backspace();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check layout preference - if Modern, return ModernCalculator
    final layoutPref = context.watch<LayoutPreferenceProvider>();
    if (layoutPref.isModern) {
      return const ModernCalculator();
    }

    // Classic layout below
    // Use context.read() for actions - doesn't trigger rebuilds
    final calculatorProvider = context.read<CalculatorProvider>();
    final displayProvider = context.read<CalculatorDisplayNotifier>();

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
          // Display Screen - Rebuilds when display-related values change in either provider
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer2<CalculatorProvider, CalculatorDisplayNotifier>(
                builder: (context, calc, display, _) {
                  return AnimatedDisplay(
                    key: const ValueKey('display'),
                    displayValue: display.displayValue,
                    subtitle: display.inputError ?? calc.inputError,
                    isError: display.displayValue == 'Error' ||
                        display.inputError != null ||
                        calc.inputError != null,
                  );
                },
              ),
            ),
          ),

          // Calculator Buttons
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                children: [
                  // Row 1: Price, L/A, Term, Pmt
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: 'Price',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setPrice(value: value);
                            }
                          },
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'L/A',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setLoanAmount(value: value);
                            }
                          },
                          onDoubleTap: () => _clearField(context, 'Loan Amount', calculatorProvider.clearLoanAmount),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Term',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setTermYears(value: value);
                            }
                          },
                          onDoubleTap: () => _clearField(context, 'Term', calculatorProvider.clearTermYears),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        Selector<CalculatorProvider, bool>(
                          selector: (_, calc) => calc.isInterestOnly,
                          builder: (context, isInterestOnly, _) {
                            return CalculatorButton(
                              text: isInterestOnly ? 'I/O' : 'Pmt',
                              onPressed: () {
                                final value = double.tryParse(displayProvider.displayValue);
                                // Skip if value is same as current payment (avoid reset)
                                if (value != null && value != 0 && value != calculatorProvider.payment) {
                                  displayProvider.clear();
                                  calculatorProvider.setPayment(value: value);
                                }
                              },
                              onLongPress: () => _showPaymentOptions(context, calculatorProvider),
                              onDoubleTap: () => _clearField(context, 'Payment', calculatorProvider.clearPayment),
                              backgroundColor: isInterestOnly ? const Color(0xFF7B68EE) : const Color(0xFF3A5062),
                              foregroundColor: Colors.white,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Row 2: DnPmt, Int, Tax, Ins
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: 'DnPmt',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setDownPayment(value: value);
                            }
                          },
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Int',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setInterestRate(value: value);
                            }
                          },
                          onDoubleTap: () => _clearField(context, 'Rate', calculatorProvider.clearInterestRate),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Tax',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setPropertyTax(value: value);
                            }
                          },
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Ins',
                          onPressed: () {
                            final value = double.tryParse(displayProvider.displayValue);
                            if (value != null && value != 0) {
                              displayProvider.clear();
                              calculatorProvider.setHomeInsurance(value: value);
                            }
                          },
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 3: AC, Backspace, %, ÷
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: 'AC',
                          onPressed: () {
                            calculatorProvider.clearAll();
                            displayProvider.clearAll();
                          },
                          backgroundColor: const Color(0xFF8B3A3A),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: 'Backspace',
                          icon: Icons.backspace_outlined,
                          onPressed: () => displayProvider.backspace(),
                          onLongPress: () {
                            displayProvider.clear();
                          },
                          backgroundColor: AppConstants.backspaceNormalColor,
                          foregroundColor: Colors.white,
                          animationType: ButtonAnimationType.wiggle,
                        ),
                        CalculatorButton(
                          text: '%',
                          onPressed: () => displayProvider.calculatePercent(),
                          backgroundColor: const Color(0xFF3A5062),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '÷',
                          onPressed: () =>
                              displayProvider.performOperation('/'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 4: 7, 8, 9, x
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: '7',
                          onPressed: () => displayProvider.inputDigit('7'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '8',
                          onPressed: () => displayProvider.inputDigit('8'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '9',
                          onPressed: () => displayProvider.inputDigit('9'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '×',
                          onPressed: () =>
                              displayProvider.performOperation('x'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 5: 4, 5, 6, -
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: '4',
                          onPressed: () => displayProvider.inputDigit('4'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '5',
                          onPressed: () => displayProvider.inputDigit('5'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '6',
                          onPressed: () => displayProvider.inputDigit('6'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '−',
                          onPressed: () =>
                              displayProvider.performOperation('-'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 6: 1, 2, 3, +
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CalculatorButton(
                          text: '1',
                          onPressed: () => displayProvider.inputDigit('1'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '2',
                          onPressed: () => displayProvider.inputDigit('2'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '3',
                          onPressed: () => displayProvider.inputDigit('3'),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '+',
                          onPressed: () =>
                              displayProvider.performOperation('+'),
                          backgroundColor: const Color(0xFF4A6278),
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  // Row 7: M, 0 (long-press for 000), ., =
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Memory button with long-press popup
                        _MemoryButton(provider: displayProvider),
                        _ZeroButton(
                          key: const Key('btn_0'),
                          provider: displayProvider,
                        ),
                        CalculatorButton(
                          text: '.',
                          onPressed: () => displayProvider.inputDecimal(),
                          backgroundColor: const Color(0xFF34495E),
                          foregroundColor: Colors.white,
                        ),
                        CalculatorButton(
                          text: '=',
                          onPressed: () => displayProvider.calculateResult(),
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
            onKeyEvent: (event) => _handleKeyPress(event, displayProvider, calculatorProvider),
            child: calculatorUI,
          )
        : calculatorUI;
  }

  void _clearField(BuildContext context, String label, VoidCallback clearAction) {
    clearAction();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label cleared'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, CalculatorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Payment Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Interest Only Payment'),
              subtitle: Text(
                provider.isInterestOnly 
                  ? 'Calculating interest-only payment'
                  : 'Standard P&I payment',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: provider.isInterestOnly,
              onChanged: (value) {
                provider.toggleInterestOnly();
              },
              activeTrackColor: const Color(0xFF7B68EE),
            ),
            const Divider(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text('View PITI Breakdown'),
              onPressed: () {
                Navigator.pop(context);
                _showPitiBreakdown(context, provider);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPitiBreakdown(BuildContext context, CalculatorProvider provider) {
    final payment = provider.payment;
    final propertyTax = provider.propertyTax;
    final homeInsurance = provider.homeInsurance;
    final mortgageInsurance = provider.mortgageInsurance;
    final monthlyExpenses = provider.monthlyExpenses;

    // Calculate monthly amounts
    final monthlyTax = (propertyTax ?? 0) / 12;
    final monthlyIns = (homeInsurance ?? 0) / 12;
    final monthlyPmi = (mortgageInsurance ?? 0) / 12;
    final monthlyHoa = monthlyExpenses ?? 0;
    final totalPiti = (payment ?? 0) + monthlyTax + monthlyIns + monthlyPmi + monthlyHoa;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PITI Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildPitiRow(context, 'Principal & Interest', payment, isTotal: false),
            _buildPitiRow(context, 'Property Tax', monthlyTax, isTotal: false),
            _buildPitiRow(context, 'Home Insurance', monthlyIns, isTotal: false),
            if (monthlyPmi > 0)
              _buildPitiRow(context, 'Mortgage Insurance', monthlyPmi, isTotal: false),
            if (monthlyHoa > 0)
              _buildPitiRow(context, 'HOA/Expenses', monthlyHoa, isTotal: false),
            const Divider(height: 24),
            _buildPitiRow(context, 'Total Monthly', totalPiti, isTotal: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPitiRow(BuildContext context, String label, double? value, {required bool isTotal}) {
    final formatted = value != null && value > 0
        ? '\$${value.toStringAsFixed(2)}'
        : '--';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            formatted,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Memory button with long-press popup for M+, M-, MR, MC
/// Uses Selector to only rebuild when memory changes
class _MemoryButton extends StatelessWidget {
  final CalculatorDisplayNotifier provider;
  
  const _MemoryButton({required this.provider});
  
  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when memory changes
    return Selector<CalculatorDisplayNotifier, (bool, double?)>(
      selector: (_, p) => (p.hasMemory, p.memory),
      builder: (context, memoryState, _) {
        final (hasMemory, memory) = memoryState;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Material(
              color: hasMemory ? const Color(0xFF2E7D32) : const Color(0xFF3A5062),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  // Tap: Memory Recall if memory exists, otherwise show menu
                  if (hasMemory) {
                    provider.memoryRecall();
                  } else {
                    _showMemoryMenu(context, provider, hasMemory, memory);
                  }
                },
                onLongPress: () => _showMemoryMenu(context, provider, hasMemory, memory),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'M',
                        style: TextStyle(
                          color: hasMemory ? Colors.white : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasMemory)
                        Text(
                          _formatMemory(memory),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _formatMemory(double? value) {
    if (value == null) return '';
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
  
  void _showMemoryMenu(BuildContext context, CalculatorDisplayNotifier provider, bool hasMemory, double? memory) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 180, // Show above the button
        position.dx + button.size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'M+',
          child: Row(
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 12),
              const Text('M+'),
              const Spacer(),
              Text('Add to memory', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'M-',
          child: Row(
            children: [
              const Icon(Icons.remove, size: 20),
              const SizedBox(width: 12),
              const Text('M−'),
              const Spacer(),
              Text('Subtract from memory', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        if (hasMemory) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'MR',
            child: Row(
              children: [
                const Icon(Icons.output, size: 20),
                const SizedBox(width: 12),
                const Text('MR'),
                const Spacer(),
                Text('Recall: ${_formatMemory(memory)}', 
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'MC',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                const SizedBox(width: 12),
                Text('MC', style: TextStyle(color: Colors.red[400])),
                const Spacer(),
                Text('Clear memory', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'M+':
          provider.memoryAdd();
          break;
        case 'M-':
          provider.memorySubtract();
          break;
        case 'MR':
          provider.memoryRecall();
          break;
        case 'MC':
          provider.memoryClear();
          break;
      }
    });
  }
}

/// Zero button with long-press popup for 00, 000
class _ZeroButton extends StatelessWidget {
  final CalculatorDisplayNotifier provider;
  
  const _ZeroButton({
    super.key,
    required this.provider,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          color: const Color(0xFF34495E),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => provider.inputDigit('0'),
            onLongPress: () => _showZeroMenu(context),
            child: const Center(
              child: Text(
                '0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showZeroMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 120, // Show above the button
        position.dx + button.size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: '00',
          child: Row(
            children: [
              const Text('00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text('Add two zeros', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: '000',
          child: Row(
            children: [
              const Text('000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text('Add three zeros', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case '00':
          provider.inputDoubleZero();
          break;
        case '000':
          provider.inputTripleZero();
          break;
      }
    });
  }
}
