import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';
import '../providers/auth_providers.dart';
import 'lock_screen.dart';

/// Wraps the app and shows [LockScreen] whenever the app lock is enabled —
/// on launch and every time the app returns to the foreground.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _evaluate();
  }

  Future<void> _evaluate() async {
    if (_authenticating || !mounted) return;

    final settings = ref.read(settingsProvider);
    if (!settings.appLockEnabled) {
      if (_locked) setState(() => _locked = false);
      return;
    }

    // Fail open when nothing can unlock the app (e.g. a restored backup that
    // enabled the lock on a device with no PIN yet) — never brick the vault.
    final auth = ref.read(authServiceProvider);
    final canUnlock = await auth.isPinSet() || settings.biometricsEnabled;
    if (!canUnlock) {
      if (_locked && mounted) setState(() => _locked = false);
      return;
    }

    if (!_locked) setState(() => _locked = true);

    if (settings.biometricsEnabled) {
      _authenticating = true;
      final ok = await auth.unlockWithBiometrics('Unlock Document Vault');
      _authenticating = false;
      if (ok && mounted) setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(settingsProvider).appLockEnabled;
    if (!enabled || !_locked) return widget.child;
    return LockScreen(
      onUnlocked: () {
        if (mounted) setState(() => _locked = false);
      },
    );
  }
}
