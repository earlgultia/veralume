import 'package:flutter/material.dart';

class AppTheme {
  static const gold = Color(0xFFD9B86C),
      navy = Color(0xFF111827),
      cream = Color(0xFFFFFBF2);
  static ThemeData light() => _theme(
    Brightness.light,
    const Color(0xFFF7F0E4),
    const Color(0xFF252119),
  );
  static ThemeData dark() =>
      _theme(Brightness.dark, const Color(0xFF0E1420), const Color(0xFFF5EEDC));
  static ThemeData _theme(Brightness brightness, Color surface, Color ink) {
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: ink, displayColor: ink),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: .9),
        indicatorColor: gold.withValues(alpha: .22),
        height: 72,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
