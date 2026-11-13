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
  static const darkPrimary = Color(0xFF8AA9FF);
  static const darkPrimaryContainer = Color(0xFF002875);
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkPrimaryText = Color(0xFFF2F2F2);
  static const darkSecondaryText = Color(0xFFB3B3B8);
  static const darkBorder = Color(0xFF2E2E32);

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
      primary: isDark ? const Color(0xFF8AA9FF) : const Color(0xFF2E5CFF),
      onPrimary: isDark ? const Color(0xFF002875) : Colors.white,
      primaryContainer:
          isDark ? const Color(0xFF002875) : const Color(0xFFF5F7FF),
      onPrimaryContainer:
          isDark ? const Color(0xFFD8E2FF) : const Color(0xFF002875),
      secondary: isDark ? const Color(0xFFC3C6CF) : const Color(0xFF5F6368),
      onSecondary: isDark ? const Color(0xFF2E3038) : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF3A3D45) : const Color(0xFFE8EAF4),
      onSecondaryContainer:
          isDark ? const Color(0xFFE2E2E9) : const Color(0xFF101935),
      tertiary: isDark ? const Color(0xFF9FC8FF) : const Color(0xFF2C70B6),
      onTertiary: isDark ? const Color(0xFF00315F) : Colors.white,
      tertiaryContainer:
          isDark ? const Color(0xFF1E4976) : const Color(0xFFDDE6FF),
      onTertiaryContainer:
          isDark ? const Color(0xFFD5E3FF) : const Color(0xFF001B3D),
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      errorContainer:
          isDark ? const Color(0xFF93000A) : const Color(0xFFF9DEDC),
      onErrorContainer:
          isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      surfaceContainerHighest:
          isDark ? const Color(0xFF2A2A2E) : const Color(0xFFEBEBEB),
      onSurfaceVariant:
          isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
      outline: isDark ? const Color(0xFF8E8E93) : const Color(0xFF737373),
      outlineVariant:
          isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7C7),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface:
          isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2D2D2D),
      onInverseSurface:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      inversePrimary: const Color(0xFF4C9EFF),
    );
    final surface = scheme.surface;
    final appbarTitle = isDark ? const Color(0xFF1A1A1A) : scheme.onSurface;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
        shadowColor: const Color(0x10000000),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
          side: BorderSide(color: AppColors.border),
        ),
        color: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: const BorderSide(color: AppColors.border),
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
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.control))),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
          shadowColor: const Color(0x0C000000),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll<Size>(Size(48, 48)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: AppColors.secondaryContainer,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sheet)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: appbarTitle,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: appbarTitle),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: const Color(0xFFF5F5F7),
        thumbColor: scheme.primary,
        overlayColor: const Color(0x20FF5722),
        valueIndicatorColor: scheme.primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4))),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: const Color(0xFFF5F5F7),
      ),
    );
  }
}
