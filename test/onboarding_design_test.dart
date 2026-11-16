import 'package:doc_vault/core/theme/app_theme.dart';
import 'package:doc_vault/features/onboarding/screens/onboarding_screen.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySettings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  @override
  Future<void> update(AppSettings next) async => state = next;
}

void main() {
  testWidgets('archive onboarding supports large text and all three steps',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsProvider.overrideWith(_MemorySettings.new)],
          child: MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: const OnboardingScreen(),
          ),
        ),
      );
      expect(find.text('DOCUMENT VAULT / 01'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var step = 2; step <= 3; step++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('DOCUMENT VAULT / 0$step'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Set up app lock now'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    }
  });
}
