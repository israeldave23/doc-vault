import 'package:doc_vault/features/lock/providers/auth_providers.dart';
import 'package:doc_vault/features/lock/widgets/lock_screen.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/providers/settings_provider.dart';
import 'package:doc_vault/features/settings/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _Auth extends AuthService {
  @override
  Future<bool> verifyPin(String pin) async => pin == '123456';
}

void main() {
  testWidgets('six-digit PIN unlocks only after submission', (tester) async {
    var unlocked = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_Settings.new),
        authServiceProvider.overrideWith((ref) => _Auth()),
      ],
      child: MaterialApp(home: LockScreen(onUnlocked: () => unlocked = true)),
    ));
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(unlocked, isFalse);
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(unlocked, isTrue);
    expect(find.byTooltip('Unlock with biometrics'), findsNothing);
  });
}
