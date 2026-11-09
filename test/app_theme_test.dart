import 'package:doc_vault/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  test('light theme uses zinc palette and compact radius', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme, ColorSchemes.zinc(ThemeMode.light));
    expect(theme.radius, 0.75);
  });

  test('dark theme uses zinc palette and compact radius', () {
    final theme = AppTheme.dark;
    expect(theme.colorScheme, ColorSchemes.zinc(ThemeMode.dark));
    expect(theme.radius, 0.75);
  });
}
