import 'package:flutter/material.dart';

/// Semantic colors approved in the FocusFlow V2 Figma design (Warm Minimal).
///
/// Separate palettes keep dark surfaces and accessible text intentional,
/// rather than algorithmically inverting the light theme.
@immutable
class FocusPalette {
  const FocusPalette({
    required this.canvas,
    required this.panel,
    required this.panelAlt,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.accentText,
    required this.primaryText,
    required this.success,
  });

  final Color canvas;
  final Color panel;
  final Color panelAlt;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color accentText;
  final Color primaryText;
  final Color success;

  static const light = FocusPalette(
    canvas: Color(0xFFF7F6F2),
    panel: Color(0xFFFFFFFF),
    panelAlt: Color(0xFFF0EEE9),
    ink: Color(0xFF292B29),
    muted: Color(0xFF706F69),
    faint: Color(0xFF85857E),
    border: Color(0xFFE5E1D9),
    accent: Color(0xFF87704F),
    accentSoft: Color(0xFFF0E9DE),
    accentText: Color(0xFF695233),
    primaryText: Color(0xFFFFFFFF),
    success: Color(0xFF387664),
  );

  static const dark = FocusPalette(
    canvas: Color(0xFF171918),
    panel: Color(0xFF222422),
    panelAlt: Color(0xFF2C2F2C),
    ink: Color(0xFFF2F0E9),
    muted: Color(0xFFA7A8A1),
    faint: Color(0xFF999B93),
    border: Color(0xFF3B3D38),
    accent: Color(0xFFBFA582),
    accentSoft: Color(0xFF373126),
    accentText: Color(0xFFDAC5A5),
    primaryText: Color(0xFF171918),
    success: Color(0xFF8DC8AC),
  );

  static FocusPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static ThemeData theme(Brightness brightness) {
    final colors = brightness == Brightness.dark ? dark : light;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    ).copyWith(
      primary: colors.accent,
      onPrimary: colors.primaryText,
      surface: colors.panel,
      onSurface: colors.ink,
      outline: colors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      dividerColor: colors.border,
      textTheme: const TextTheme().apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.panelAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}
