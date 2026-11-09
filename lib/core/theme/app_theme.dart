import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFF4F4F5);
  static const secondaryContainer = Color(0xFFF4F4F5);
  static const primaryText = Color(0xFF18181B);
  static const secondaryText = Color(0xFF71717A);
  static const border = Color(0xFFE4E4E7);
  static const borderLight = Color(0xFFF4F4F5);

  static const deepNavy = primaryText;
  static const brandIndigo = Color(0xFF52525B);
  static const primaryViolet = Color(0xFF3F3F46);
  static const electricPurple = Color(0xFF3F3F46);
  static const accentViolet = Color(0xFF52525B);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const statusExpired = danger;
  static const statusCritical = warning;
  static const statusWarning = Color(0xFFCA8A04);
  static const statusOk = success;
  static const seed = Color(0xFF3F3F46);
  static const darkPrimary = Color(0xFFD4D4D8);
  static const darkPrimaryContainer = Color(0xFF27272A);
  static const darkBackground = Color(0xFF09090B);
  static const darkSurface = Color(0xFF18181B);
  static const darkPrimaryText = Color(0xFFFAFAFA);
  static const darkSecondaryText = Color(0xFFA1A1AA);
  static const darkBorder = Color(0xFF27272A);
  static const statusExpiredLight = danger;
  static const statusCriticalLight = warning;
  static const statusWarningLight = statusWarning;
  static const statusOkLight = success;
  static const statusExpiredDark = Color(0xFFF87171);
  static const statusCriticalDark = Color(0xFFFBBF24);
  static const statusWarningDark = Color(0xFFFACC15);
  static const statusOkDark = Color(0xFF4ADE80);
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
  static const button = 8.0;
  static const card = 12.0;
  static const heroCard = 12.0;
  static const sheet = 16.0;
  static const input = 8.0;
  static const chip = 999.0;
}

class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    colorScheme: ColorSchemes.zinc(ThemeMode.light),
    radius: 0.75,
  );
  static final ThemeData dark = ThemeData(
    colorScheme: ColorSchemes.zinc(ThemeMode.dark),
    radius: 0.75,
  );
}
