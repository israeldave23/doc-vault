import 'package:flutter/material.dart';

/// Paper, pine and brass: the vault's shared palette.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF4F1E9);
  static const surface = Color(0xFFFFFDF7);
  static const primaryContainer = Color(0xFFE3EBE1);
  static const secondaryContainer = Color(0xFFEDE7D9);
  static const primaryText = Color(0xFF202D28);
  static const secondaryText = Color(0xFF626B61);
  static const border = Color(0xFFDADBCF);
  static const borderLight = Color(0xFFE8E6DC);
  static const seed = Color(0xFF244F42);
  static const darkPrimary = Color(0xFFB4D2B5);
  static const darkPrimaryContainer = Color(0xFF284A3C);
  static const darkBackground = Color(0xFF141D19);
  static const darkSurface = Color(0xFF1C2821);
  static const darkPrimaryText = Color(0xFFF2F0E6);
  static const darkSecondaryText = Color(0xFFBAC5B8);
  static const darkBorder = Color(0xFF3A493F);
  static const brass = Color(0xFFBCA16D);

  static const statusExpired = Color(0xFFAD4138);
  static const statusCritical = Color(0xFF95551B);
  static const statusWarning = Color(0xFF786115);
  static const statusOk = Color(0xFF28674B);
  static const statusExpiredLight = statusExpired;
  static const statusCriticalLight = statusCritical;
  static const statusWarningLight = statusWarning;
  static const statusOkLight = statusOk;
  static const statusExpiredDark = Color(0xFFFFB4A7);
  static const statusCriticalDark = Color(0xFFF2BD83);
  static const statusWarningDark = Color(0xFFE5D186);
  static const statusOkDark = Color(0xFFA9D8B6);
}

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
  static const control = 8.0;
  static const button = 12.0;
  static const card = 18.0;
  static const sheet = 24.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.darkPrimary : AppColors.seed,
      onPrimary: isDark ? AppColors.darkBackground : AppColors.surface,
      primaryContainer:
          isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer,
      onPrimaryContainer: isDark ? AppColors.darkPrimaryText : AppColors.seed,
      secondary: isDark ? const Color(0xFFE1C692) : const Color(0xFF775D30),
      secondaryContainer:
          isDark ? const Color(0xFF393426) : AppColors.secondaryContainer,
      onSecondaryContainer:
          isDark ? const Color(0xFFF0DFC0) : const Color(0xFF4C3C21),
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      onSurfaceVariant:
          isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
      surfaceContainerHighest:
          isDark ? const Color(0xFF2B382E) : AppColors.secondaryContainer,
      outline: isDark ? const Color(0xFF8A9B89) : const Color(0xFF747D70),
      outlineVariant: border,
      error: isDark ? AppColors.statusExpiredDark : AppColors.statusExpired,
      errorContainer:
          isDark ? const Color(0xFF482823) : const Color(0xFFF6E6DE),
      onErrorContainer:
          isDark ? const Color(0xFFFFDAD0) : const Color(0xFF70332B),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    TextStyle editorial(double size) => TextStyle(
          fontFamily: 'Georgia',
          fontFamilyFallback: const ['Noto Serif', 'serif'],
          fontSize: size,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.8,
          height: 1.15,
          color: scheme.onSurface,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(color: border),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text.copyWith(
        displaySmall: editorial(42),
        headlineLarge: editorial(34),
        headlineMedium: editorial(28),
        headlineSmall: editorial(24),
        titleLarge: editorial(22),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
        bodySmall: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        labelSmall: text.labelSmall?.copyWith(letterSpacing: 1.6),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.all(18),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 64,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: shape,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: 24,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: editorial(26),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
