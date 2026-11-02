import 'package:doc_vault/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses semantic brand palette and surface hierarchy', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary, AppColors.seed);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.cardTheme.elevation, 0);
  });

  test('dark theme uses distinct readable semantic surfaces', () {
    final theme = AppTheme.dark;
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppColors.darkPrimary);
    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(theme.colorScheme.surface, AppColors.darkSurface);
    expect(theme.colorScheme.onSurface, AppColors.darkPrimaryText);
  });

  test('interactive controls retain minimum comfortable sizes', () {
    final theme = AppTheme.light;
    expect(theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48));
    expect(theme.textButtonTheme.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48));
  });
}
