
import 'package:material_ui/material_ui.dart';

/// Central design tokens.
///
/// The palette is deliberately warm and low-chroma: a paper-toned canvas, ink
/// text, and a single deep navy accent. Status colours are desaturated earth
/// tones that stay legible as text on their own 12% tints, which is how they
/// are used in chips, rails and countdowns.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------- light
  static const background = Color(0xFFF4F2ED);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEDEAE3);
  static const surfaceSunken = Color(0xFFE5E1D8);
  static const primaryText = Color(0xFF14161A);
  static const secondaryText = Color(0xFF6B6E75);
  static const border = Color(0xFFE4E0D6);
  static const borderLight = Color(0xFFEFECE4);

  /// Deep navy. Deliberately darker than a stock M3 blue so the interface
  /// reads as stationery rather than as a default Flutter app.
  static const seed = Color(0xFF243A5E);
  static const primaryContainer = Color(0xFFE5EBF4);
  static const secondaryContainer = Color(0xFFE9E6DE);

  // ----------------------------------------------------------------- dark
  static const darkPrimary = Color(0xFF9DB9DF);
  static const darkPrimaryContainer = Color(0xFF1B2C42);
  static const darkBackground = Color(0xFF101214);
  static const darkSurface = Color(0xFF17191C);
  static const darkSurfaceMuted = Color(0xFF1F2226);
  static const darkSurfaceSunken = Color(0xFF272B30);
  static const darkPrimaryText = Color(0xFFF0EFEB);
  static const darkSecondaryText = Color(0xFFA3A7AE);
  static const darkBorder = Color(0xFF2A2D32);

  // --------------------------------------------------------------- status
  static const statusExpired = Color(0xFFB23B2E);
  static const statusCritical = Color(0xFF9C6415);
  static const statusWarning = Color(0xFF77651F);
  static const statusOk = Color(0xFF2D6A4F);

  static const statusExpiredDark = Color(0xFFF0917F);
  static const statusCriticalDark = Color(0xFFE0A45C);
  static const statusWarningDark = Color(0xFFD2BC76);
  static const statusOkDark = Color(0xFF7FC7A1);

  // Legacy aliases kept so non-widget code can stay theme-agnostic.
  static const statusExpiredLight = statusExpired;
  static const statusCriticalLight = statusCritical;
  static const statusWarningLight = statusWarning;
  static const statusOkLight = statusOk;
}

/// Shared geometry. Screen-specific layout belongs in the screens.
class AppSpacing {
  AppSpacing._();

  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// Standard horizontal page gutter.
  static const gutter = 20.0;
}

class AppRadii {
  AppRadii._();

  static const control = 10.0;
  static const button = 12.0;
  static const card = 18.0;
  static const sheet = 24.0;
}

/// Field treatments shared across screens.
class AppInputStyles {
  AppInputStyles._();

  /// Quiet search field: no outline, filled with the muted surface.
  static InputDecoration search(
    BuildContext context, {
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.button),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: border,
      enabledBorder: border,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
    );
  }
}

/// Motion tokens. Keep durations short enough to feel like a tool.
class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const enter = Duration(milliseconds: 320);
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
      onPrimary: isDark ? const Color(0xFF0B1B2E) : Colors.white,
      primaryContainer:
          isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer,
      onPrimaryContainer:
          isDark ? const Color(0xFFD6E4F7) : const Color(0xFF16273D),
      secondary: isDark ? const Color(0xFFC2C6CD) : const Color(0xFF5B6573),
      onSecondary: isDark ? const Color(0xFF2A2E33) : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF31353A) : AppColors.secondaryContainer,
      onSecondaryContainer:
          isDark ? const Color(0xFFE6E7EA) : const Color(0xFF3A3B38),
      tertiary: isDark ? const Color(0xFFD8B894) : const Color(0xFF7A5730),
      onTertiary: isDark ? const Color(0xFF3B2610) : Colors.white,
      tertiaryContainer:
          isDark ? const Color(0xFF4A3521) : const Color(0xFFF1E6D8),
      onTertiaryContainer:
          isDark ? const Color(0xFFF3E2CD) : const Color(0xFF2E1F0E),
      error: isDark ? const Color(0xFFF0917F) : AppColors.statusExpired,
      onError: isDark ? const Color(0xFF4A0F08) : Colors.white,
      errorContainer:
          isDark ? const Color(0xFF4C1A13) : const Color(0xFFF7E4E0),
      onErrorContainer:
          isDark ? const Color(0xFFFAD5CE) : const Color(0xFF5A1B12),
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      surfaceContainerHighest: isDark
          ? AppColors.darkSurfaceSunken
          : AppColors.surfaceMuted,
      onSurfaceVariant:
          isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
      outline: isDark ? const Color(0xFF8B9097) : const Color(0xFF75787F),
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.border,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: isDark ? const Color(0xFFE4E2DC) : const Color(0xFF23262B),
      onInverseSurface: isDark ? const Color(0xFF1A1C1F) : const Color(0xFFF3F1EC),
      inversePrimary: isDark ? const Color(0xFF243A5E) : const Color(0xFF9DB9DF),
    );

    final surface = scheme.surface;
    final canvas = isDark ? AppColors.darkBackground : AppColors.background;
    final hairline = isDark ? AppColors.darkBorder : AppColors.border;
    final hairlineSoft = isDark ? const Color(0xFF23262A) : AppColors.borderLight;
    final mutedSurface =
        isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
    final sunken =
        isDark ? AppColors.darkSurfaceSunken : AppColors.surfaceSunken;

    const tabular = <FontFeature>[FontFeature.tabularFigures()];

    final base = Typography.material2021(platform: TargetPlatform.android);
    final textTheme = (isDark ? base.white : base.black)
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          // Hero numeral: the vault's headline metric.
          displayLarge: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
            height: 1.0,
            fontFeatures: tabular,
            color: scheme.onSurface,
          ),
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
            height: 1.05,
            fontFeatures: tabular,
            color: scheme.onSurface,
          ),
          headlineLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1.15,
            color: scheme.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.35,
            height: 1.2,
            color: scheme.onSurface,
          ),
          headlineSmall: TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            height: 1.3,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            height: 1.3,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            height: 1.35,
            color: scheme.onSurface,
          ),
          titleSmall: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: scheme.onSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: scheme.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: scheme.onSurface,
          ),
          bodySmall: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
          labelLarge: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: scheme.onSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: scheme.onSurfaceVariant,
          ),
          // Reserved for uppercase eyebrow labels.
          labelSmall: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            height: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        );

    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button));
    final buttonText = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14.5,
      letterSpacing: 0.1,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: hairline),
        ),
      ),
      // Form fields are hairline outlines so floating labels have a notch to
      // sit in. Search fields opt out with [AppInputStyles.search].
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.5),
        floatingLabelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mutedSurface,
        // A tint, not a fill: chip labels inherit one colour for both states.
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        disabledColor: sunken,
        surfaceTintColor: Colors.transparent,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelPadding: EdgeInsets.zero,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: hairline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: buttonText,
          foregroundColor: scheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: buttonText,
        extendedSizeConstraints: const BoxConstraints(minHeight: 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 12.5,
          height: 1.35,
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: hairlineSoft,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.5,
          height: 1.45,
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppSpacing.gutter,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 17.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: mutedSurface,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: scheme.primary,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        side: BorderSide(color: scheme.outline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : (isDark ? const Color(0xFFB9BDC4) : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : sunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outlineVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2C3035) : const Color(0xFF23262B),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF3F1EC),
          fontSize: 14,
          height: 1.4,
        ),
        actionTextColor: isDark ? const Color(0xFF9DB9DF) : const Color(0xFFB7CBE8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        elevation: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: mutedSurface,
        circularTrackColor: mutedSurface,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.18),
        selectionHandleColor: scheme.primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C3035) : const Color(0xFF23262B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Color(0xFFF3F1EC), fontSize: 12),
      ),
    );
  }
}
