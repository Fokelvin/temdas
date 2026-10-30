import 'package:flutter/material.dart';
import '../ui/theme/tokens.dart';

abstract final class TemdasColors {
  static const lightRed = AppTokens.high, darkRed = AppTokens.high;
  static const lightAmber = AppTokens.medium, darkAmber = AppTokens.medium;
  static const lightGreen = AppTokens.low, darkGreen = AppTokens.low;
  static final lightMuted = AppTokens.light.text3,
      darkMuted = AppTokens.dark.text3;
  static final lightRedContainer = AppTokens.light.surface2,
      darkRedContainer = AppTokens.dark.surface2;
  static final lightAmberContainer = AppTokens.light.surface2,
      darkAmberContainer = AppTokens.dark.surface2;
  static final lightGreenContainer = AppTokens.light.surface2,
      darkGreenContainer = AppTokens.dark.surface2;
  static final light = _scheme(AppTokens.light, Brightness.light);
  static final dark = _scheme(AppTokens.dark, Brightness.dark);
  static ColorScheme _scheme(AppTokens t, Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: AppTokens.accent,
        brightness: brightness,
      ).copyWith(
        primary: AppTokens.accent,
        onPrimary: AppTokens.dark.bg,
        primaryContainer: Color.alphaBlend(t.accentSoft, t.bg),
        onPrimaryContainer: t.text,
        secondary: t.text2,
        onSecondary: t.bg,
        secondaryContainer: t.surface2,
        onSecondaryContainer: t.text,
        tertiary: AppTokens.accent,
        onTertiary: AppTokens.dark.bg,
        tertiaryContainer: t.surface2,
        onTertiaryContainer: t.text,
        surface: t.surface,
        onSurface: t.text,
        onSurfaceVariant: t.text2,
        surfaceContainerLowest: t.bg,
        surfaceContainerLow: t.bg,
        surfaceContainer: t.surface2,
        surfaceContainerHigh: t.hover,
        surfaceContainerHighest: t.hover,
        surfaceTint: Colors.transparent,
        outline: t.borderStrong,
        outlineVariant: t.border,
        error: brightness == Brightness.light
            ? const Color(0xFFB3261E)
            : AppTokens.high,
        errorContainer: t.surface2,
        onErrorContainer: t.text,
        inverseSurface: brightness == Brightness.light
            ? AppTokens.dark.surface
            : AppTokens.light.surface,
        onInverseSurface: brightness == Brightness.light
            ? AppTokens.dark.text
            : AppTokens.light.text,
      );
}
