import 'package:flutter/material.dart';

import 'temdas_colors.dart';
import 'temdas_semantic_colors.dart';

/// Tokens de identidade compartilhados. Densidade do board fica na apresentação.
abstract final class TemdasTokens {
  static const cardRadius = 10.0;
  static const controlRadius = 8.0;
  static const dialogRadius = 12.0;
  static const borderWidth = 1.0;
  static const smallGap = 8.0;
  static const contentGap = 16.0;
  static const pagePadding = 24.0;
}

/// Toda tela usa este tema; cores de domínio vêm de TemdasSemanticColors.
abstract final class AppTheme {
  static final light = _build(TemdasColors.light, TemdasSemanticColors.light);
  static final dark = _build(TemdasColors.dark, TemdasSemanticColors.dark);

  static ThemeData _build(ColorScheme colors, TemdasSemanticColors semantic) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'IBM Plex Sans',
    );
    final text = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.35,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );
    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(TemdasTokens.controlRadius),
      ),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TemdasTokens.cardRadius),
      side: BorderSide(
        color: colors.outlineVariant,
        width: TemdasTokens.borderWidth,
      ),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
      borderSide: BorderSide(
        color: colors.outline,
        width: TemdasTokens.borderWidth,
      ),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    const buttonSize = Size(0, 36);

    return base.copyWith(
      textTheme: text,
      extensions: [semantic],
      scaffoldBackgroundColor: colors.surfaceContainerLow,
      canvasColor: colors.surface,
      disabledColor: colors.onSurface.withValues(alpha: 0.38),
      hintColor: colors.brightness == Brightness.dark
          ? TemdasColors.darkMuted
          : TemdasColors.lightMuted,
      hoverColor: colors.primary.withValues(alpha: 0.05),
      focusColor: colors.primary.withValues(alpha: 0.12),
      iconTheme: IconThemeData(color: colors.onSurfaceVariant, size: 20),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TemdasTokens.dialogRadius),
          side: BorderSide(color: colors.outlineVariant),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: text.labelLarge,
          shape: controlShape,
          elevation: 0,
          padding: buttonPadding,
          minimumSize: buttonSize,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
          textStyle: text.labelLarge,
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: buttonSize,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: text.labelLarge,
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: buttonSize,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurfaceVariant,
          shape: controlShape,
          iconSize: 20,
          minimumSize: const Size(36, 36),
          padding: const EdgeInsets.all(8),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        elevation: 4,
        shape: controlShape.copyWith(
          side: BorderSide(color: colors.outlineVariant),
        ),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
        ),
        textStyle: text.bodySmall?.copyWith(color: colors.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: TemdasTokens.borderWidth,
        space: 16,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.dragged)
              ? 9
              : 4,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => colors.onSurfaceVariant.withValues(
            alpha: states.contains(WidgetState.dragged)
                ? 0.75
                : states.contains(WidgetState.hovered)
                ? 0.60
                : 0.28,
          ),
        ),
        crossAxisMargin: 4,
        radius: const Radius.circular(TemdasTokens.controlRadius),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainer,
        selectedColor: colors.primaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        shape: controlShape,
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.inversePrimary,
        elevation: 0,
        shape: controlShape,
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        indicatorShape: controlShape,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: colors.onSurfaceVariant,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: colors.onSurface,
        collapsedTextColor: colors.onSurface,
        iconColor: colors.onSurfaceVariant,
        collapsedIconColor: colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: cardShape.borderRadius),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: cardShape.borderRadius,
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: colors.onSurfaceVariant,
        selectedColor: colors.onPrimaryContainer,
        fillColor: colors.primaryContainer,
        borderColor: colors.outline,
        selectedBorderColor: colors.primary,
        borderWidth: TemdasTokens.borderWidth,
        borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
      ),
    );
  }
}
