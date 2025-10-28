import 'package:flutter/material.dart';

/// Variants that map calculator buttons to semantic colors provided by
/// [CalculatorPalette].
enum CalculatorButtonVariant {
  primary,
  secondary,
  accent,
  destructive,
  utility,
}

@immutable
class CalculatorPalette extends ThemeExtension<CalculatorPalette> {
  final LinearGradient backgroundGradient;
  final Color surface;
  final Color displayBackground;
  final Color displayForeground;
  final Color displaySecondary;
  final Color keyShadow;
  final Color keyOutline;
  final Color primaryKey;
  final Color onPrimaryKey;
  final Color secondaryKey;
  final Color onSecondaryKey;
  final Color accentKey;
  final Color onAccentKey;
  final Color destructiveKey;
  final Color onDestructiveKey;
  final Color utilityKey;
  final Color onUtilityKey;

  const CalculatorPalette({
    required this.backgroundGradient,
    required this.surface,
    required this.displayBackground,
    required this.displayForeground,
    required this.displaySecondary,
    required this.keyShadow,
    required this.keyOutline,
    required this.primaryKey,
    required this.onPrimaryKey,
    required this.secondaryKey,
    required this.onSecondaryKey,
    required this.accentKey,
    required this.onAccentKey,
    required this.destructiveKey,
    required this.onDestructiveKey,
    required this.utilityKey,
    required this.onUtilityKey,
  });

  factory CalculatorPalette.light(ColorScheme scheme) {
    return CalculatorPalette(
      backgroundGradient: LinearGradient(
        colors: [
          Color.alphaBlend(scheme.primary.withOpacity(0.04), scheme.surface),
          scheme.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      surface: scheme.surface,
      displayBackground: Color.alphaBlend(
        scheme.primary.withOpacity(0.05),
        scheme.surface,
      ),
      displayForeground: scheme.onSurface,
      displaySecondary: scheme.onSurfaceVariant,
      keyShadow: Colors.black.withOpacity(0.08),
      keyOutline: scheme.outlineVariant,
      primaryKey: scheme.primaryContainer,
      onPrimaryKey: scheme.onPrimaryContainer,
      secondaryKey: scheme.surfaceVariant,
      onSecondaryKey: scheme.onSurfaceVariant,
      accentKey: scheme.secondaryContainer,
      onAccentKey: scheme.onSecondaryContainer,
      destructiveKey: scheme.errorContainer,
      onDestructiveKey: scheme.onErrorContainer,
      utilityKey: scheme.tertiaryContainer,
      onUtilityKey: scheme.onTertiaryContainer,
    );
  }

  factory CalculatorPalette.dark(ColorScheme scheme) {
    return CalculatorPalette(
      backgroundGradient: LinearGradient(
        colors: [
          Color.alphaBlend(scheme.primary.withOpacity(0.12), scheme.surface),
          scheme.surfaceContainerHighest,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      surface: scheme.surfaceContainerHighest,
      displayBackground: Color.alphaBlend(
        scheme.primary.withOpacity(0.18),
        scheme.surfaceContainerHighest,
      ),
      displayForeground: scheme.onSurface,
      displaySecondary: scheme.onSurfaceVariant,
      keyShadow: Colors.black.withOpacity(0.35),
      keyOutline: scheme.outlineVariant,
      primaryKey: scheme.primaryContainer,
      onPrimaryKey: scheme.onPrimaryContainer,
      secondaryKey: scheme.surfaceVariant,
      onSecondaryKey: scheme.onSurfaceVariant,
      accentKey: scheme.secondaryContainer,
      onAccentKey: scheme.onSecondaryContainer,
      destructiveKey: scheme.errorContainer,
      onDestructiveKey: scheme.onErrorContainer,
      utilityKey: scheme.tertiaryContainer,
      onUtilityKey: scheme.onTertiaryContainer,
    );
  }

  @override
  CalculatorPalette copyWith({
    LinearGradient? backgroundGradient,
    Color? surface,
    Color? displayBackground,
    Color? displayForeground,
    Color? displaySecondary,
    Color? keyShadow,
    Color? keyOutline,
    Color? primaryKey,
    Color? onPrimaryKey,
    Color? secondaryKey,
    Color? onSecondaryKey,
    Color? accentKey,
    Color? onAccentKey,
    Color? destructiveKey,
    Color? onDestructiveKey,
    Color? utilityKey,
    Color? onUtilityKey,
  }) {
    return CalculatorPalette(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surface: surface ?? this.surface,
      displayBackground: displayBackground ?? this.displayBackground,
      displayForeground: displayForeground ?? this.displayForeground,
      displaySecondary: displaySecondary ?? this.displaySecondary,
      keyShadow: keyShadow ?? this.keyShadow,
      keyOutline: keyOutline ?? this.keyOutline,
      primaryKey: primaryKey ?? this.primaryKey,
      onPrimaryKey: onPrimaryKey ?? this.onPrimaryKey,
      secondaryKey: secondaryKey ?? this.secondaryKey,
      onSecondaryKey: onSecondaryKey ?? this.onSecondaryKey,
      accentKey: accentKey ?? this.accentKey,
      onAccentKey: onAccentKey ?? this.onAccentKey,
      destructiveKey: destructiveKey ?? this.destructiveKey,
      onDestructiveKey: onDestructiveKey ?? this.onDestructiveKey,
      utilityKey: utilityKey ?? this.utilityKey,
      onUtilityKey: onUtilityKey ?? this.onUtilityKey,
    );
  }

  @override
  CalculatorPalette lerp(ThemeExtension<CalculatorPalette>? other, double t) {
    if (other is! CalculatorPalette) {
      return this;
    }
    return CalculatorPalette(
      backgroundGradient:
          LinearGradient.lerp(
            backgroundGradient,
            other.backgroundGradient,
            t,
          ) ??
          other.backgroundGradient,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      displayBackground:
          Color.lerp(displayBackground, other.displayBackground, t) ??
          displayBackground,
      displayForeground:
          Color.lerp(displayForeground, other.displayForeground, t) ??
          displayForeground,
      displaySecondary:
          Color.lerp(displaySecondary, other.displaySecondary, t) ??
          displaySecondary,
      keyShadow: Color.lerp(keyShadow, other.keyShadow, t) ?? keyShadow,
      keyOutline: Color.lerp(keyOutline, other.keyOutline, t) ?? keyOutline,
      primaryKey: Color.lerp(primaryKey, other.primaryKey, t) ?? primaryKey,
      onPrimaryKey:
          Color.lerp(onPrimaryKey, other.onPrimaryKey, t) ?? onPrimaryKey,
      secondaryKey:
          Color.lerp(secondaryKey, other.secondaryKey, t) ?? secondaryKey,
      onSecondaryKey:
          Color.lerp(onSecondaryKey, other.onSecondaryKey, t) ?? onSecondaryKey,
      accentKey: Color.lerp(accentKey, other.accentKey, t) ?? accentKey,
      onAccentKey: Color.lerp(onAccentKey, other.onAccentKey, t) ?? onAccentKey,
      destructiveKey:
          Color.lerp(destructiveKey, other.destructiveKey, t) ?? destructiveKey,
      onDestructiveKey:
          Color.lerp(onDestructiveKey, other.onDestructiveKey, t) ??
          onDestructiveKey,
      utilityKey: Color.lerp(utilityKey, other.utilityKey, t) ?? utilityKey,
      onUtilityKey:
          Color.lerp(onUtilityKey, other.onUtilityKey, t) ?? onUtilityKey,
    );
  }

  ({Color background, Color foreground}) colorsForVariant(
    CalculatorButtonVariant variant,
  ) {
    switch (variant) {
      case CalculatorButtonVariant.secondary:
        return (background: secondaryKey, foreground: onSecondaryKey);
      case CalculatorButtonVariant.accent:
        return (background: accentKey, foreground: onAccentKey);
      case CalculatorButtonVariant.destructive:
        return (background: destructiveKey, foreground: onDestructiveKey);
      case CalculatorButtonVariant.utility:
        return (background: utilityKey, foreground: onUtilityKey);
      case CalculatorButtonVariant.primary:
      default:
        return (background: primaryKey, foreground: onPrimaryKey);
    }
  }
}
