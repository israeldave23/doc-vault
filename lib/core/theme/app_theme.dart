import 'package:flutter/material.dart';

/// Central place for colors and theme. Status colors are shared by chips,
/// cards and the detail screen so the meaning stays consistent.
class AppColors {
  AppColors._();

  static const seed = Color(0xFF1E5EFF);

  static const statusExpired = Color(0xFFD32F2F);
  static const statusCritical = Color(0xFFE64A19);
  static const statusWarning = Color(0xFFF9A825);
  static const statusOk = Color(0xFF2E7D32);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: scheme.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
