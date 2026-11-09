import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../documents/providers/document_providers.dart';
import '../../lock/providers/auth_providers.dart';
import '../../profiles/providers/profile_providers.dart';
import '../../reminders/services/reminder_service.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      headers: const [AppBar(title: Text('Settings'))],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const _SectionHeader('Appearance'),
          for (final option in const [
            (AppSettings.themeSystem, 'Follow system'),
            (AppSettings.themeLight, 'Light'),
            (AppSettings.themeDark, 'Dark'),
          ])
            _SettingsTile(
              title: option.$2,
              trailing: settings.themeMode == option.$1
                  ? const Icon(LucideIcons.check)
                  : null,
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(themeMode: option.$1)),
            ),
          const _SectionHeader('Reminders'),
          _SettingsTile(
            title: 'Default reminder schedule',
            subtitle: _formatDays(settings.defaultReminderDays),
            onPressed: () => _editDefaultReminders(context, ref),
          ),
          const _SectionHeader('Security'),
          _SettingsTile(
            title: 'Lock the app',
            subtitle: 'Ask for a PIN when the app opens or resumes',
            trailing: Switch(
              value: settings.appLockEnabled,
              onChanged: (enable) =>
                  _toggleAppLock(context, ref, enable: enable),
            ),
          ),
          _SettingsTile(
            title: 'Unlock with fingerprint or face',
            subtitle: 'Available after the PIN is set up',
            trailing: Switch(
              value: settings.biometricsEnabled,
              enabled: settings.appLockEnabled,
              onChanged: (enable) =>
                  _toggleBiometrics(context, ref, enable: enable),
            ),
          ),
          _SettingsTile(
            title: 'Change PIN',
            enabled: settings.appLockEnabled,
            onPressed: () => _changePin(context, ref),
          ),
          const _SectionHeader('Backup'),
          _SettingsTile(
            leading: const Icon(LucideIcons.share),
            title: 'Export encrypted backup',
            subtitle: 'Documents, people, settings and photos in one file',
            onPressed: () => _exportBackup(context, ref),
          ),
          _SettingsTile(
            leading: const Icon(LucideIcons.archiveRestore),
            title: 'Restore from backup',
            subtitle: 'Replaces everything currently in the vault',
            onPressed: () => _restoreBackup(context, ref),
          ),
          const _SectionHeader('Privacy'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Your documents never leave this device: no accounts, no '
              'servers, no uploads. The only file that leaves the phone is a '
              'backup you export yourself. The free tier shows one banner ad '
              '(Google AdMob), which collects the advertising ID for '
              'targeting; upgrading to Pro removes ads entirely.',
            ),
          ),
          const _SettingsTile(
            title: 'Document Vault',
            subtitle: 'Version 0.1.0 · by DGA Studios',
          ),
        ],
      ),
    );
  }

  String _formatDays(List<int> days) {
    final sorted = List<int>.of(days)..sort((a, b) => b.compareTo(a));
    return sorted.map((d) => d == 1 ? '1 day' : '$d days').join(', ');
  }

  // ------------------------------------------------------------- appearance

  Future<void> _editDefaultReminders(
      BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    var selected = List<int>.of(settings.defaultReminderDays);

    final saved = await const DialogConfiguration()
        .show<bool>(
          context,
          (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Default reminders'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in const [90, 60, 30, 14, 7, 3, 1])
                    Button(
                      style: selected.contains(days)
                          ? const ButtonStyle.primary()
                          : const ButtonStyle.outline(),
                      onPressed: () => setState(() {
                        if (selected.contains(days)) {
                          if (selected.length > 1) selected.remove(days);
                        } else {
                          selected.add(days);
                        }
                      }),
                      child: Text(days == 1 ? '1 day' : '$days days'),
                    ),
                ],
              ),
              actions: [
                Button.ghost(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                Button.primary(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        )
        .future;
    if (saved != true) return;

    selected = selected.toSet().toList()..sort((a, b) => b.compareTo(a));
    await ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(defaultReminderDays: selected));
  }

  // -------------------------------------------------------------- app lock

  Future<void> _toggleAppLock(
    BuildContext context,
    WidgetRef ref, {
    required bool enable,
  }) async {
    final auth = ref.read(authServiceProvider);
    final settings = ref.read(settingsProvider);

    if (enable) {
      final pin = await _showPinSetup(context, title: 'Choose a PIN');
      if (pin == null) return;
      await auth.setPin(pin);
      await ref
          .read(settingsProvider.notifier)
          .update(settings.copyWith(appLockEnabled: true));
      if (!context.mounted) return;
      _snack(context, 'App lock is on');
      return;
    }

    final verified = await _showPinPrompt(
      context,
      ref,
      title: 'Enter your PIN to turn the lock off',
    );
    if (verified != true) return;
    await ref.read(settingsProvider.notifier).update(
          settings.copyWith(appLockEnabled: false, biometricsEnabled: false),
        );
    if (!context.mounted) return;
    _snack(context, 'App lock is off');
  }

  Future<void> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref, {
    required bool enable,
  }) async {
    final auth = ref.read(authServiceProvider);
    final settings = ref.read(settingsProvider);

    if (enable) {
      if (!await auth.canUseBiometrics()) {
        if (!context.mounted) return;
        _snack(context, 'No fingerprint or face data is set up on this device');
        return;
      }
      // Prove it actually works before switching it on.
      final ok = await auth.unlockWithBiometrics('Confirm biometric unlock');
      if (!ok) {
        if (!context.mounted) return;
        _snack(context, 'Biometric unlock was not confirmed');
        return;
      }
      await ref
          .read(settingsProvider.notifier)
          .update(settings.copyWith(biometricsEnabled: true));
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .update(settings.copyWith(biometricsEnabled: false));
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);
    final currentOk = await _showPinPrompt(
      context,
      ref,
      title: 'Enter current PIN',
    );
    if (currentOk != true) return;
    if (!context.mounted) return;

    final pin = await _showPinSetup(context, title: 'Choose a new PIN');
    if (pin == null) return;
    await auth.setPin(pin);
    if (!context.mounted) return;
    _snack(context, 'PIN updated');
  }

  // ---------------------------------------------------------------- backup

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final passphrase = await _showPassphraseDialog(context, confirm: true);
    if (passphrase == null || !context.mounted) return;

    showProgress(context);
    Uint8List? archive;
    try {
      archive = await ref
          .read(backupServiceProvider)
          .exportArchive(passphrase: passphrase);
    } on BackupException catch (e) {
      if (context.mounted) hideProgress(context);
      if (context.mounted) _snack(context, e.message);
      return;
    } catch (e) {
      if (context.mounted) hideProgress(context);
      if (context.mounted) _snack(context, 'Backup failed: $e');
      return;
    }
    if (context.mounted) hideProgress(context);

    final stamp =
        DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save encrypted backup',
      fileName: 'doc-vault-$stamp.dvault',
      bytes: archive,
    );
    if (!context.mounted) return;
    _snack(context, path == null ? 'Backup cancelled' : 'Backup saved');
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await const DialogConfiguration()
        .show<bool>(
          context,
          (ctx) => AlertDialog(
            title: const Text('Restore from backup?'),
            content: const Text(
              'This replaces every document, person, setting and photo currently '
              'in the vault. This cannot be undone.',
            ),
            actions: [
              Button.ghost(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              Button.destructive(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        )
        .future;
    if (confirmed != true || !context.mounted) return;

    final result = await FilePicker.platform.pickFiles(withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null || !context.mounted) return;

    final passphrase = await _showPassphraseDialog(context, confirm: false);
    if (passphrase == null || !context.mounted) return;

    showProgress(context);
    BackupSummary? summary;
    try {
      summary = await ref
          .read(backupServiceProvider)
          .importArchive(bytes: bytes, passphrase: passphrase);
    } on BackupException catch (e) {
      if (context.mounted) hideProgress(context);
      if (context.mounted) _snack(context, e.message);
      return;
    } catch (e) {
      if (context.mounted) hideProgress(context);
      if (context.mounted) _snack(context, 'Restore failed: $e');
      return;
    }
    if (context.mounted) hideProgress(context);

    // Bring every provider back in sync with the replaced boxes.
    ref.read(documentsProvider.notifier).refresh();
    ref.read(profilesProvider.notifier).refresh();
    ref.read(settingsProvider.notifier).refresh();

    // A backup can enable the lock while this device has no PIN yet — never
    // let that lock the user out of their own vault.
    var note = '';
    final settings = ref.read(settingsProvider);
    if (settings.appLockEnabled &&
        !await ref.read(authServiceProvider).isPinSet()) {
      await ref.read(settingsProvider.notifier).update(
            settings.copyWith(appLockEnabled: false, biometricsEnabled: false),
          );
      note = ' · App lock turned off (set a PIN to re-enable)';
    }

    await ref
        .read(reminderServiceProvider)
        .syncAll(ref.read(documentsProvider));

    if (!context.mounted) return;
    _snack(context, 'Restored $summary$note');
  }

  // ----------------------------------------------------------------- misc

  void showProgress(BuildContext context) {
    const DialogConfiguration(barrierDismissible: false).show<void>(
      context,
      (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void hideProgress(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _snack(BuildContext context, String message) {
    showToast(
      context: context,
      builder: (context, overlay) => Alert(
        content: Text(message),
      ),
    );
  }

  /// Returns the chosen PIN, or `null` if cancelled.
  Future<String?> _showPinSetup(
    BuildContext context, {
    required String title,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    final result = await const DialogConfiguration()
        .show<String>(
          context,
          (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: AuthService.maxPinLength,
                    placeholder: const Text(
                        'PIN (${AuthService.minPinLength}–${AuthService.maxPinLength} digits)'),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.destructive),
                    ).xSmall,
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: AuthService.maxPinLength,
                    placeholder: const Text('Repeat PIN'),
                  ),
                ],
              ),
              actions: [
                Button.ghost(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                Button.primary(
                  onPressed: () {
                    final pin = controller.text.trim();
                    if (!AuthService.isValidPin(pin)) {
                      setState(() => error =
                          'Use ${AuthService.minPinLength}–${AuthService.maxPinLength} digits');
                      return;
                    }
                    if (pin != confirmController.text.trim()) {
                      setState(() => error = 'PINs do not match');
                      return;
                    }
                    Navigator.of(ctx).pop(pin);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        )
        .future;
    controller.dispose();
    confirmController.dispose();
    return result;
  }

  /// Returns `true` when the current PIN was entered correctly.
  Future<bool?> _showPinPrompt(
    BuildContext context,
    WidgetRef ref, {
    required String title,
  }) {
    final controller = TextEditingController();
    final auth = ref.read(authServiceProvider);

    return const DialogConfiguration()
        .show<bool>(
          context,
          (ctx) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: AuthService.maxPinLength,
              onSubmitted: (_) async {
                final ok = await auth.verifyPin(controller.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop(ok);
              },
            ),
            actions: [
              Button.ghost(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              Button.primary(
                onPressed: () async {
                  final ok = await auth.verifyPin(controller.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop(ok);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        )
        .future;
  }

  /// Returns the passphrase, or `null` if cancelled.
  Future<String?> _showPassphraseDialog(
    BuildContext context, {
    required bool confirm,
  }) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    return const DialogConfiguration()
        .show<String>(
          context,
          (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(
                  confirm ? 'Set a backup passphrase' : 'Enter passphrase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'There is no way to recover this passphrase. Store it somewhere '
                    'safe — without it the backup cannot be opened.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    placeholder: const Text('Passphrase (min 8 characters)'),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.destructive),
                    ).xSmall,
                  if (confirm) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      placeholder: const Text('Repeat passphrase'),
                    ),
                  ],
                ],
              ),
              actions: [
                Button.ghost(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                Button.primary(
                  onPressed: () {
                    final pass = controller.text;
                    if (pass.length < 8) {
                      setState(() => error = 'Use at least 8 characters');
                      return;
                    }
                    if (confirm && pass != confirmController.text) {
                      setState(() => error = 'Passphrases do not match');
                      return;
                    }
                    Navigator.of(ctx).pop(pass);
                  },
                  child: Text(confirm ? 'Export' : 'Unlock'),
                ),
              ],
            ),
          ),
        )
        .future;
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onPressed,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Button.ghost(
      enabled: enabled,
      alignment: Alignment.centerLeft,
      onPressed: onPressed,
      leading: leading,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (subtitle != null) Text(subtitle!).small().muted(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ).xSmall.semiBold,
    );
  }
}
