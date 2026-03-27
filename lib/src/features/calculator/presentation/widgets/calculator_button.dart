import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ButtonAnimationType { none, pulse, wiggle }

class CalculatorButton extends StatefulWidget {
  final String text;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final ButtonAnimationType animationType;
  final bool isActive;
  final double iconSize;

  const CalculatorButton({
    super.key,
    required this.text,
    this.semanticLabel,
    required this.onPressed,
    this.onLongPress,
    this.onDoubleTap,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.animationType = ButtonAnimationType.none,
    this.isActive = false,
    this.iconSize = 32.0,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _wiggleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for press effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Pulse animation for active state (mic listening)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wiggle animation for backspace
    _wiggleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _wiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.087), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.087, end: 0.087), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.087, end: 0.0), weight: 1),
    ]).animate(_wiggleController);

    _updateAnimations();
  }

  @override
  void didUpdateWidget(CalculatorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.animationType != widget.animationType) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.animationType == ButtonAnimationType.pulse && widget.isActive) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!kIsWeb) {
      HapticFeedback.lightImpact();
    }

    if (widget.animationType == ButtonAnimationType.wiggle) {
      _wiggleController.forward().then((_) => _wiggleController.reset());
    }

    _scaleController.forward().then((_) => _scaleController.reverse());
    widget.onPressed();
  }

  void _handleLongPress() {
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }
    widget.onLongPress?.call();
  }

  bool get _usesImmediateTap =>
      widget.onLongPress == null && widget.onDoubleTap == null;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = widget.semanticLabel ?? widget.text;

    Widget buttonChild = widget.icon != null
        ? Icon(widget.icon, size: widget.iconSize)
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          );

    // Apply wiggle animation if needed
    if (widget.animationType == ButtonAnimationType.wiggle) {
      buttonChild = AnimatedBuilder(
        animation: _wiggleAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _wiggleAnimation.value,
            child: child,
          );
        },
        child: buttonChild,
      );
    }

    Widget button = ElevatedButton(
      onPressed: () {},
      onLongPress: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ??
            Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: widget.foregroundColor ??
            Theme.of(context).colorScheme.onSecondaryContainer,
        elevation: widget.isActive ? 6 : 2,
        shadowColor: widget.isActive
            ? (widget.backgroundColor ?? Colors.black26).withValues(alpha: 0.5)
            : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      child: buttonChild,
    );

    // Apply pulse animation if active
    if (widget.animationType == ButtonAnimationType.pulse && widget.isActive) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? Colors.blue)
                      .withValues(alpha: 0.4 * _pulseAnimation.value),
                  blurRadius: 12 * _pulseAnimation.value,
                  spreadRadius: 2 * (_pulseAnimation.value - 1),
                ),
              ],
            ),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
          );
        },
        child: button,
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Semantics(
                button: true,
                enabled: true,
                label: semanticLabel,
                onTap: widget.onPressed,
                onLongPress: widget.onLongPress,
                child: ExcludeSemantics(child: button),
              ),
            ),
            if (_usesImmediateTap)
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _handleTap(),
                child: const SizedBox.expand(),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                onTap: _handleTap,
                onLongPress: widget.onLongPress != null ? _handleLongPress : null,
                onDoubleTap: widget.onDoubleTap,
                child: const SizedBox.expand(),
              ),
          ],
        ),
      ),
    );
  }
}
