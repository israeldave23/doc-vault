import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('defaults are the spec defaults', () {
      const settings = AppSettings();
      expect(settings.defaultReminderDays, [90, 30, 7, 1]);
      expect(settings.appLockEnabled, isFalse);
      expect(settings.biometricsEnabled, isFalse);
      expect(settings.isPro, isFalse);
      expect(settings.themeMode, AppSettings.themeSystem);
      expect(settings.onboardingCompleted, isFalse);
    });

    test('copyWith only changes what is asked', () {
      const settings = AppSettings();
      final unlocked = settings.copyWith(isPro: true, onboardingCompleted: true);
      expect(unlocked.isPro, isTrue);
      expect(unlocked.onboardingCompleted, isTrue);
      expect(unlocked.appLockEnabled, isFalse);
      expect(unlocked.defaultReminderDays, settings.defaultReminderDays);
    });

    test('toMap/fromMap round-trips every field', () {
      const settings = AppSettings(
        defaultReminderDays: [60, 14],
        appLockEnabled: true,
        biometricsEnabled: true,
        isPro: true,
        darkMode: true,
        themeMode: AppSettings.themeDark,
        onboardingCompleted: true,
      );

      final restored = AppSettings.fromMap(settings.toMap());
      expect(restored.defaultReminderDays, [60, 14]);
      expect(restored.appLockEnabled, isTrue);
      expect(restored.biometricsEnabled, isTrue);
      expect(restored.isPro, isTrue);
      expect(restored.darkMode, isTrue);
      expect(restored.themeMode, AppSettings.themeDark);
      expect(restored.onboardingCompleted, isTrue);
    });

    test('fromMap tolerates a partial (older) payload', () {
      final restored = AppSettings.fromMap(const {});
      expect(restored, isA<AppSettings>());
      expect(restored.themeMode, AppSettings.themeSystem);
      expect(restored.onboardingCompleted, isFalse);
      expect(restored.defaultReminderDays, [90, 30, 7, 1]);
    });
  });
}
