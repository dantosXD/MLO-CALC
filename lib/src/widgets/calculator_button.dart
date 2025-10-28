import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/calculator_palette.dart';

class CalculatorButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final CalculatorButtonVariant variant;
  final int flex;
  final TextAlign textAlign;

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = CalculatorButtonVariant.primary,
    this.flex = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!kIsWeb) {
      HapticFeedback.lightImpact();
    }
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<CalculatorPalette>() ??
        CalculatorPalette.light(Theme.of(context).colorScheme);
    final variantColors = palette.colorsForVariant(widget.variant);
    final overlayColor = MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.disabled)) {
        return variantColors.background.withOpacity(0.5);
      }
      if (states.contains(MaterialState.pressed)) {
        return variantColors.foreground.withOpacity(0.14);
      }
      if (states.contains(MaterialState.hovered)) {
        return variantColors.foreground.withOpacity(0.06);
      }
      return null;
    });

    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );

    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: palette.keyShadow,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            borderRadius: BorderRadius.circular(18),
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedButton(
              onPressed: _handleTap,
              style:
                  ElevatedButton.styleFrom(
                    backgroundColor: variantColors.background,
                    foregroundColor: variantColors.foreground,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: palette.keyOutline.withOpacity(0.2),
                      ),
                    ),
                    textStyle: textStyle,
                  ).merge(
                    ButtonStyle(
                      overlayColor: overlayColor,
                      elevation: MaterialStateProperty.resolveWith<double>((
                        states,
                      ) {
                        if (states.contains(MaterialState.pressed)) {
                          return 1;
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return 5;
                        }
                        return 3;
                      }),
                    ),
                  ),
              child: _ButtonContent(
                text: widget.text,
                icon: widget.icon,
                textAlign: widget.textAlign,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String text;
  final IconData? icon;
  final TextAlign textAlign;

  const _ButtonContent({
    required this.text,
    this.icon,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: textAlign,
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, textAlign: textAlign),
    );
  }
}
