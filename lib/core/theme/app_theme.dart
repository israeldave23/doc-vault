import 'package:flutter/material.dart';

/// Central place for colors and theme. Status colors are shared by chips,
/// cards and the detail screen so the meaning stays consistent.
class AppColors {
  AppColors._();

  /// Indigo “secure vault” palette.
  static const seed = Color(0xFF5148D8);
  static const primaryContainer = Color(0xFFE8E6FF);
  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const primaryText = Color(0xFF1B2333);
  static const secondaryText = Color(0xFF626B7C);
  static const border = Color(0xFFE9ECF2);

  static const darkPrimary = Color(0xFFAAB4FF);
  static const darkPrimaryContainer = Color(0xFF23284D);
  static const darkBackground = Color(0xFF0F1118);
  static const darkSurface = Color(0xFF181B25);
  static const darkPrimaryText = Color(0xFFE8EAF2);
  static const darkSecondaryText = Color(0xFFA2A8B5);
  static const darkBorder = Color(0xFF313544);

  static const statusExpiredLight = Color(0xFFE35260);
  static const statusCriticalLight = Color(0xFFE59A23);
  static const statusWarningLight = Color(0xFFC89A2B);
  static const statusOkLight = Color(0xFF169B72);
  static const statusExpiredDark = Color(0xFFF2797F);
  static const statusCriticalDark = Color(0xFFF5A46A);
  static const statusWarningDark = Color(0xFFE6C46C);
  static const statusOkDark = Color(0xFF5BD0A8);

  // Compatibility aliases used by expiry_status.dart. Presentation widgets
  // can select dark variants in later phases without changing model logic.
  static const statusExpired = statusExpiredLight;
  static const statusCritical = statusCriticalLight;
  static const statusWarning = statusWarningLight;
  static const statusOk = statusOkLight;
}

/// Shared geometry; keep screen-specific layout out of component themes.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadii {
  AppRadii._();

  static const control = 12.0;
  static const button = 16.0;
  static const card = 18.0;
  static const sheet = 24.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: isDark ? AppColors.darkPrimary : AppColors.seed,
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.seed,
      onPrimary: isDark ? Colors.black : Colors.white,
      primaryContainer:
          isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer,
      onPrimaryContainer:
          isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      secondary: isDark ? AppColors.darkPrimary : AppColors.seed,
      onSecondary: isDark ? Colors.black : Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface:
          isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      onSurfaceVariant:
          isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
      outline: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.border,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      visualDensity: VisualDensity.standard,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          )
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: scheme.onSurface,
            ),
            bodySmall: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        color: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sheet)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
