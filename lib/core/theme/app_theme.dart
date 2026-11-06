import 'package:flutter/material.dart';

/// Central place for colors and theme. Status colors are shared by chips,
/// cards and the detail screen so the meaning stays consistent.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF6F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFF5F7FF);
  static const secondaryContainer = Color(0xFFFAFAFA);
  static const primaryText = Color(0xFF10152B);
  static const secondaryText = Color(0xFF69718B);
  static const border = Color(0xFFE7E9F5);
  static const borderLight = Color(0xFFF0F2FA);

  // Premium Brand Tokens
  static const deepNavy = Color(0xFF151E56);
  static const brandIndigo = Color(0xFF3546C8);
  static const primaryViolet = Color(0xFF563CF5);
  static const electricPurple = Color(0xFF7457FF);
  static const accentViolet = Color(0xFF4932E8);

  // Semantic Status Tokens
  static const success = Color(0xFF1DB77B);
  static const warning = Color(0xFFE9900B);
  static const danger = Color(0xFFE13D52);

  // Status mapping
  static const statusExpired = danger;
  static const statusCritical = warning;
  static const statusWarning = Color(0xFFF1C40F);
  static const statusOk = success;

  // Gradients
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepNavy, brandIndigo, primaryViolet],
  );

  static const primaryActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricPurple, accentViolet],
  );

  static const summaryCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF293AAB), Color(0xFF5C43EA)],
  );

  static const seed = primaryViolet;
  static const darkPrimary = electricPurple;
  static const darkPrimaryContainer = Color(0xFF211D4F);
  static const darkBackground = Color(0xFF0D1026);
  static const darkSurface = Color(0xFF161B3D);
  static const darkPrimaryText = Color(0xFFF6F7FF);
  static const darkSecondaryText = Color(0xFFA5ACCE);
  static const darkBorder = Color(0xFF242A56);

  static const statusExpiredLight = danger;
  static const statusCriticalLight = warning;
  static const statusWarningLight = Color(0xFFF1C40F);
  static const statusOkLight = success;
  static const statusExpiredDark = Color(0xFFFF6B7D);
  static const statusCriticalDark = Color(0xFFFFB347);
  static const statusWarningDark = Color(0xFFFFD15C);
  static const statusOkDark = Color(0xFF3CD08E);
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
  static const button = 14.0;
  static const card = 20.0;
  static const heroCard = 26.0;
  static const sheet = 24.0;
  static const input = 16.0;
  static const chip = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimary : AppColors.seed,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? AppColors.darkPrimaryContainer
          : AppColors.primaryContainer,
      onPrimaryContainer: isDark
          ? AppColors.darkPrimaryText
          : AppColors.deepNavy,
      secondary: isDark
          ? AppColors.darkSecondaryText
          : AppColors.secondaryText,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? AppColors.darkSurface
          : AppColors.secondaryContainer,
      onSecondaryContainer: isDark
          ? AppColors.darkPrimaryText
          : AppColors.primaryText,
      tertiary: AppColors.brandIndigo,
      onTertiary: Colors.white,
      tertiaryContainer: isDark
          ? const Color(0xFF2D368C)
          : const Color(0xFFDDE6FF),
      onTertiaryContainer: isDark
          ? AppColors.darkPrimaryText
          : const Color(0xFF001B3D),
      error: isDark ? AppColors.statusExpiredDark : AppColors.statusExpired,
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF4A2027)
          : const Color(0xFFFBE9EC),
      onErrorContainer: isDark
          ? AppColors.darkPrimaryText
          : const Color(0xFF410002),
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      surfaceContainerHighest: isDark
          ? const Color(0xFF242A56)
          : const Color(0xFFEBEBEB),
      onSurfaceVariant: isDark
          ? AppColors.darkSecondaryText
          : const Color(0xFF434343),
      outline: isDark ? AppColors.darkBorder : AppColors.border,
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.borderLight,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface:
          isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2D2D2D),
      onInverseSurface:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2D2D2D),
      inversePrimary: isDark
          ? AppColors.darkPrimary
          : const Color(0xFF4C9EFF),
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
        shadowColor: const Color(0x10000000),
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
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
          shadowColor: const Color(0x0C000000),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
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
      navigationBarTheme: const NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFF0F0F0),
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
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
        backgroundColor: Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sheet)),
      ),
      appBarTheme: const AppBarTheme(
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
        inactiveTrackColor: const Color(0xFFF5F5F7),
        thumbColor: scheme.primary,
        overlayColor: const Color(0x20FF5722),
        valueIndicatorColor: scheme.primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: const Color(0xFFF5F5F7),
      ),
    );
  }
}
