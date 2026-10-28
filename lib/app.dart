import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/documents/providers/document_providers.dart';
import 'features/documents/screens/dashboard_screen.dart';
import 'features/lock/widgets/lock_gate.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/pro/services/pro_service.dart';
import 'features/reminders/services/reminder_service.dart';
import 'features/settings/models/app_settings.dart';
import 'features/settings/providers/settings_provider.dart';

class DocVaultApp extends ConsumerStatefulWidget {
  const DocVaultApp({super.key});

  @override
  ConsumerState<DocVaultApp> createState() => _DocVaultAppState();
}

class _DocVaultAppState extends ConsumerState<DocVaultApp> {
  @override
  void initState() {
    super.initState();
    // Re-arm every reminder on each launch. This covers edits from a previous
    // session, clock/timezone changes, and alarms the OS dropped. The store is
    // warmed up at the same time so pending purchases complete on startup.
    Future.microtask(() async {
      final reminders = ref.read(reminderServiceProvider);
      await reminders.syncAll(ref.read(documentsProvider));
      await ref.read(proServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode) {
      AppSettings.themeLight => ThemeMode.light,
      AppSettings.themeDark => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Document Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: settings.onboardingCompleted
          ? const DashboardScreen()
          : const OnboardingScreen(),
      // Wraps every route (home, pushed screens, dialogs) so the lock shows
      // even when the app is backgrounded on a sub-screen.
      builder: (context, child) => LockGate(child: child ?? const SizedBox()),
    );
  }
}
