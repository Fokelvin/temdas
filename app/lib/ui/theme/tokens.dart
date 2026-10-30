import 'package:flutter/material.dart';

/// Papéis compartilhados entre todas as telas, sem cores de negócio no layout.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.hover,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.text3,
  });
  final Color bg,
      surface,
      surface2,
      hover,
      border,
      borderStrong,
      text,
      text2,
      text3;
  static const accent = Color(0xFF4C8DFF);
  static const high = Color(0xFFF2555A),
      medium = Color(0xFFE8B33C),
      low = Color(0xFF3FBF8A);
  static const open = Color(0xFF9AA7BF), cancelled = Color(0xFF66748F);
  static const controlRadius = 6.0, cardRadius = 8.0, pillRadius = 999.0;
  static const numbers = [FontFeature.tabularFigures()];
  static const curve = Cubic(0.23, 1, 0.32, 1);
  Color get accentSoft => accent.withValues(alpha: .12);
  static const dark = AppTokens(
    bg: Color(0xFF0B1220),
    surface: Color(0xFF111A2B),
    surface2: Color(0xFF16213A),
    hover: Color(0xFF1A2742),
    border: Color(0xFF1F2B44),
    borderStrong: Color(0xFF2A3857),
    text: Color(0xFFE6EBF5),
    text2: Color(0xFF9AA7BF),
    text3: Color(0xFF66748F),
  );
  static const light = AppTokens(
    bg: Color(0xFFF7F9FC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF2F8),
    hover: Color(0xFFF0F4FA),
    border: Color(0xFFE3E8F0),
    borderStrong: Color(0xFFCBD3E1),
    text: Color(0xFF0F172A),
    text2: Color(0xFF475569),
    text3: Color(0xFF94A3B8),
  );
  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);
  static Duration motion(BuildContext context, [int ms = 150]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: ms);
  @override
  AppTokens copyWith() => this;
  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      hover: mix(hover, other.hover),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      text: mix(text, other.text),
      text2: mix(text2, other.text2),
      text3: mix(text3, other.text3),
    );
  }
}
