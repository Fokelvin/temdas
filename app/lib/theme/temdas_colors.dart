import 'package:flutter/material.dart';

/// Paleta central. Widgets consomem ColorScheme e TemdasSemanticColors.
abstract final class TemdasColors {
  static const lightRed = Color(0xFFC1392B);
  static const lightRedContainer = Color(0xFFFBEBE9);
  // Um pouco mais escuro para o rótulo manter contraste no container suave.
  static const lightAmber = Color(0xFF955F0B);
  static const lightAmberContainer = Color(0xFFFAF0DC);
  static const lightGreen = Color(0xFF1C7A5A);
  static const lightGreenContainer = Color(0xFFE3F2EC);
  static const lightMuted = Color(0xFF8D95A3);

  static const darkRed = Color(0xFFE37F70);
  static const darkRedContainer = Color(0xFF3A2220);
  static const darkAmber = Color(0xFFD9A441);
  static const darkAmberContainer = Color(0xFF352B18);
  static const darkGreen = Color(0xFF4FBE97);
  static const darkGreenContainer = Color(0xFF1B3029);
  static const darkMuted = Color(0xFF71809A);

  static final light = ColorScheme.fromSeed(seedColor: const Color(0xFF346CC1))
      .copyWith(
        primary: const Color(0xFF346CC1),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFE7EEFA),
        onPrimaryContainer: const Color(0xFF24559B),
        secondary: const Color(0xFF5C6779),
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFEDF0F5),
        onSecondaryContainer: const Color(0xFF182639),
        tertiary: lightGreen,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: lightGreenContainer,
        onTertiaryContainer: lightGreen,
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF182639),
        onSurfaceVariant: const Color(0xFF5C6779),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFF4F6F9),
        surfaceContainer: const Color(0xFFEDF0F5),
        surfaceContainerHigh: const Color(0xFFE7EBF1),
        surfaceContainerHighest: const Color(0xFFE1E5EC),
        surfaceTint: Colors.transparent,
        outline: const Color(0xFFCBD1DC),
        outlineVariant: const Color(0xFFE1E5EC),
        error: lightRed,
        onError: const Color(0xFFFFFFFF),
        errorContainer: lightRedContainer,
        onErrorContainer: lightRed,
        inverseSurface: const Color(0xFF182233),
        onInverseSurface: const Color(0xFFEBEFF5),
        inversePrimary: const Color(0xFF6C9BE0),
      );

  static final dark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C9BE0),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF6C9BE0),
        onPrimary: const Color(0xFF0E1420),
        primaryContainer: const Color(0xFF20304A),
        onPrimaryContainer: const Color(0xFF6C9BE0),
        secondary: const Color(0xFF9CA9BC),
        onSecondary: const Color(0xFF0E1420),
        secondaryContainer: const Color(0xFF1F2B3E),
        onSecondaryContainer: const Color(0xFFEBEFF5),
        tertiary: darkGreen,
        onTertiary: const Color(0xFF0E1420),
        tertiaryContainer: darkGreenContainer,
        onTertiaryContainer: darkGreen,
        surface: const Color(0xFF182233),
        onSurface: const Color(0xFFEBEFF5),
        onSurfaceVariant: const Color(0xFF9CA9BC),
        surfaceContainerLowest: const Color(0xFF0E1420),
        surfaceContainerLow: const Color(0xFF0E1420),
        surfaceContainer: const Color(0xFF1F2B3E),
        surfaceContainerHigh: const Color(0xFF253249),
        surfaceContainerHighest: const Color(0xFF2C3A50),
        surfaceTint: Colors.transparent,
        outline: const Color(0xFF3D4E68),
        outlineVariant: const Color(0xFF2C3A50),
        error: darkRed,
        onError: const Color(0xFF0E1420),
        errorContainer: darkRedContainer,
        onErrorContainer: darkRed,
        inverseSurface: const Color(0xFFEBEFF5),
        onInverseSurface: const Color(0xFF182639),
        inversePrimary: const Color(0xFF346CC1),
      );
}
