import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../theme/calculator_palette.dart';
import '../widgets/calculator_button.dart';
import '../widgets/animated_display.dart';

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

  void _handleKeyPress(KeyEvent event, CalculatorProvider provider) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Numbers 0-9 (main keyboard)
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      provider.inputDigit('0');
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      provider.inputDigit('1');
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      provider.inputDigit('2');
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      provider.inputDigit('3');
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      provider.inputDigit('4');
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      provider.inputDigit('5');
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      provider.inputDigit('6');
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      provider.inputDigit('7');
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      provider.inputDigit('8');
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      provider.inputDigit('9');
    }
    // Decimal point
    else if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
      provider.inputDecimal();
    }
    // Operations
    else if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      provider.performOperation('+');
    } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      provider.performOperation('-');
    } else if (key == LogicalKeyboardKey.asterisk || key == LogicalKeyboardKey.numpadMultiply) {
      provider.performOperation('x');
    } else if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.numpadDivide) {
      provider.performOperation('/');
    }
    // Equals
    else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.equal) {
      provider.calculateResult();
    }
    // Clear
    else if (key == LogicalKeyboardKey.escape) {
      provider.clearAll();
    } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      provider.backspace();
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatorProvider = Provider.of<CalculatorProvider>(context);
    final palette = Theme.of(context).extension<CalculatorPalette>();

    // Only use keyboard listener on desktop platforms
    final bool isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final Widget calculatorUI = LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 900
            ? 36.0
            : constraints.maxWidth > 600
                ? 24.0
                : 12.0;
        final verticalPadding = constraints.maxHeight > 800 ? 28.0 : 16.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: palette?.backgroundGradient,
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    12,
                  ),
                  child: _buildDisplayCard(context, calculatorProvider, palette),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    verticalPadding,
                  ),
                  child: _buildKeypadCard(context, calculatorProvider, palette),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildDisplayCard(
    BuildContext context,
    CalculatorProvider provider,
    CalculatorPalette? palette,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(28);
    final outlineColor = palette?.keyOutline.withOpacity(0.25) ??
        colorScheme.outlineVariant.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: palette?.displayBackground ?? colorScheme.surfaceVariant,
        borderRadius: borderRadius,
        border: Border.all(color: outlineColor),
        boxShadow: [
          BoxShadow(
            color: palette?.keyShadow ?? Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedDisplay(
          key: const ValueKey('display'),
          displayValue: provider.displayValue,
          subtitle:
              provider.displayMode == 'piti' && provider.payment != null
                  ? 'PITI'
                  : null,
          isError: provider.displayValue == 'Error',
        ),
      ),
    );
  }

  Widget _buildKeypadCard(
    BuildContext context,
    CalculatorProvider provider,
    CalculatorPalette? palette,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final outlineColor = palette?.keyOutline.withOpacity(0.25) ??
        colorScheme.outlineVariant.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: palette?.surface ?? colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: outlineColor),
        boxShadow: [
          BoxShadow(
            color: palette?.keyShadow ?? Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildKeypadRows(context, provider),
      ),
    );
  }

  List<Widget> _buildKeypadRows(
    BuildContext context,
    CalculatorProvider provider,
  ) {
    final rows = <List<_ButtonConfig>>[
      [
        _ButtonConfig(
          label: 'Price',
          onPressed: provider.setPrice,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'L/A',
          onPressed: provider.setLoanAmount,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'Term',
          onPressed: provider.setTermYears,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'Pmt',
          onPressed: provider.setPayment,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'AC',
          onPressed: provider.clearAll,
          variant: CalculatorButtonVariant.destructive,
        ),
      ],
      [
        _ButtonConfig(
          label: 'DnPmt',
          onPressed: provider.setDownPayment,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'Int',
          onPressed: provider.setInterestRate,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'Tax',
          onPressed: provider.setPropertyTax,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: 'Ins',
          onPressed: provider.setHomeInsurance,
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: '÷',
          onPressed: () => provider.performOperation('/'),
          variant: CalculatorButtonVariant.secondary,
        ),
      ],
      [
        _ButtonConfig(
          label: '7',
          onPressed: () => provider.inputDigit('7'),
        ),
        _ButtonConfig(
          label: '8',
          onPressed: () => provider.inputDigit('8'),
        ),
        _ButtonConfig(
          label: '9',
          onPressed: () => provider.inputDigit('9'),
        ),
        _ButtonConfig(
          label: 'Back',
          icon: Icons.backspace_outlined,
          onPressed: provider.backspace,
          variant: CalculatorButtonVariant.destructive,
        ),
        _ButtonConfig(
          label: '×',
          onPressed: () => provider.performOperation('x'),
          variant: CalculatorButtonVariant.secondary,
        ),
      ],
      [
        _ButtonConfig(
          label: '4',
          onPressed: () => provider.inputDigit('4'),
        ),
        _ButtonConfig(
          label: '5',
          onPressed: () => provider.inputDigit('5'),
        ),
        _ButtonConfig(
          label: '6',
          onPressed: () => provider.inputDigit('6'),
        ),
        _ButtonConfig(
          label: 'Info',
          icon: Icons.help_outline,
          onPressed: () => _showHelpSheet(context),
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: '−',
          onPressed: () => provider.performOperation('-'),
          variant: CalculatorButtonVariant.secondary,
        ),
      ],
      [
        _ButtonConfig(
          label: '1',
          onPressed: () => provider.inputDigit('1'),
        ),
        _ButtonConfig(
          label: '2',
          onPressed: () => provider.inputDigit('2'),
        ),
        _ButtonConfig(
          label: '3',
          onPressed: () => provider.inputDigit('3'),
        ),
        _ButtonConfig(
          label: 'Voice',
          icon: Icons.mic_none_outlined,
          onPressed: () => _showVoicePreview(context),
          variant: CalculatorButtonVariant.utility,
        ),
        _ButtonConfig(
          label: '+',
          onPressed: () => provider.performOperation('+'),
          variant: CalculatorButtonVariant.secondary,
        ),
      ],
      [
        _ButtonConfig(
          label: '0',
          onPressed: () => provider.inputDigit('0'),
          flex: 2,
        ),
        _ButtonConfig(
          label: '.',
          onPressed: provider.inputDecimal,
        ),
        _ButtonConfig(
          label: '=',
          onPressed: provider.calculateResult,
          variant: CalculatorButtonVariant.accent,
        ),
      ],
    ];

    final keypadRows = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      keypadRows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final config in rows[i])
                CalculatorButton(
                  text: config.label,
                  onPressed: config.onPressed,
                  icon: config.icon,
                  variant: config.variant,
                  flex: config.flex,
                  textAlign: config.textAlign,
                ),
            ],
          ),
        ),
      );

      if (i != rows.length - 1) {
        keypadRows.add(const SizedBox(height: 8));
      }
    }

    return keypadRows;
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculator shortcuts',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                '• Assign PITI inputs with the first row of buttons.\n'
                '• Tap “Pmt” twice after entering taxes or insurance to toggle P&I vs. PITI.\n'
                '• Desktop users can type digits and operators directly from the keyboard.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoicePreview(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input is coming soon. Stay tuned!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _ButtonConfig {
  final String label;
  final VoidCallback onPressed;
  final CalculatorButtonVariant variant;
  final IconData? icon;
  final int flex;
  final TextAlign textAlign;

  const _ButtonConfig({
    required this.label,
    required this.onPressed,
    this.variant = CalculatorButtonVariant.primary,
    this.icon,
    this.flex = 1,
    this.textAlign = TextAlign.center,
  });
}
