import 'package:flutter/material.dart';

/// Central place for colors and theme. Status colors are shared by chips,
/// cards and the detail screen so the meaning stays consistent.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFF5F7FF);
  static const secondaryContainer = Color(0xFFFAFAFA);
  static const primaryText = Color(0xFF1A1A1A);
  static const secondaryText = Color(0xFF666666);
  static const border = Color(0xFFEDEDED);
  static const borderLight = Color(0xFFF0F0F0);
  static const seed = Color(0xFF2E5CFF);
  static const darkPrimary = seed;
  static const darkPrimaryContainer = primaryContainer;
  static const darkBackground = background;
  static const darkSurface = surface;
  static const darkPrimaryText = primaryText;
  static const darkSecondaryText = secondaryText;
  static const darkBorder = border;

  static const statusExpired = Color(0xFFE74C3C);
  static const statusCritical = Color(0xFFF39C12);
  static const statusWarning = Color(0xFFF1C40F);
  static const statusOk = Color(0xFF27AE60);
  static const statusExpiredLight = statusExpired;
  static const statusCriticalLight = statusCritical;
  static const statusWarningLight = statusWarning;
  static const statusOkLight = statusOk;
  static const statusExpiredDark = statusExpired;
  static const statusCriticalDark = statusCritical;
  static const statusWarningDark = statusWarning;
  static const statusOkDark = statusOk;
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

  static const control = 10.0;
  static const button = 12.0;
  static const card = 16.0;
  static const sheet = 20.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: Color(0xFF2E5CFF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF5F7FF),
      onPrimaryContainer: Color(0xFF002875),
      secondary: Color(0xFF5F6368),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8EAF4),
      onSecondaryContainer: Color(0xFF101935),
      tertiary: Color(0xFF2C70B6),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDDE6FF),
      onTertiaryContainer: Color(0xFF001B3D),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410002),
      background: Color(0xFFF5F5F7),
      onBackground: Color(0xFF1A1A1A),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A1A),
      surfaceVariant: Color(0xFFEBEBEB),
      onSurfaceVariant: Color(0xFF434343),
      outline: Color(0xFF737373),
      outlineVariant: Color(0xFFC7C7C7),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: isDark ? Color(0xFFE0E0E0) : Color(0xFF2D2D2D),
      onInverseSurface: isDark ? Color(0xFF1A1A1A) : Color(0xFF2D2D2D),
      inversePrimary: Color(0xFF4C9EFF),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          )
          .copyWith(
            headlineLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.2,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              height: 1.25,
            ),
            headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: scheme.onSurface,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: scheme.onSurface,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Color(0x10000000),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        color: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
          shadowColor: Color(0x0C000000),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFF0F0F0),
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sheet)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: Color(0xFFF5F5F7),
        thumbColor: scheme.primary,
        overlayColor: Color(0x20FF5722),
        valueIndicatorColor: scheme.primary,
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: Color(0xFFF5F5F7),
      ),
    );
  }
}
