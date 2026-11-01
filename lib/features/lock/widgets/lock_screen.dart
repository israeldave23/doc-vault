import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';
import '../../settings/services/auth_service.dart';
import '../providers/auth_providers.dart';

/// Full-screen PIN pad shown while the vault is locked. Calls [onUnlocked]
/// once the PIN or biometrics check out.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entered = '';
  String? _error;
  bool _busy = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final enabled = ref.read(settingsProvider).biometricsEnabled;
    final available =
        enabled && await ref.read(authServiceProvider).canUseBiometrics();
    if (!mounted) return;
    setState(() => _biometricAvailable =
        available && ref.read(settingsProvider).biometricsEnabled);
  }

  void _tap(String digit) {
    if (_busy) return;
    setState(() {
      _error = null;
      if (_entered.length < AuthService.maxPinLength) _entered += digit;
    });
  }

  void _backspace() {
    if (_busy || _entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref.read(authServiceProvider).verifyPin(_entered);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _busy = false;
        _entered = '';
      });
      widget.onUnlocked();
      return;
    }
    setState(() {
      _busy = false;
      _entered = '';
      _error = 'Wrong PIN. Try again.';
    });
  }

  Future<void> _biometricUnlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(authServiceProvider)
        .unlockWithBiometrics('Unlock Document Vault');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.lock_outline,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Document Vault is locked',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _PinDots(filled: _entered.length),
                  SizedBox(
                    height: 40,
                    child: _error == null
                        ? null
                        : Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _Keypad(
                    onDigit: _tap,
                    onBackspace: _backspace,
                    onSubmit:
                        _entered.length >= AuthService.minPinLength && !_busy
                            ? _verify
                            : null,
                    trailing: _biometricAvailable
                        ? IconButton(
                            iconSize: 34,
                            tooltip: 'Unlock with biometrics',
                            icon: const Icon(Icons.fingerprint),
                            onPressed: _biometricUnlock,
                          )
                        : const SizedBox(width: 48, height: 48),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$filled of ${AuthService.maxPinLength} PIN digits entered',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < AuthService.maxPinLength; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  i < filled ? Icons.circle : Icons.circle_outlined,
                  size: 18,
                  color: i < filled ? scheme.primary : scheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.trailing,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmit;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    Widget key(String label) => Semantics(
          label: 'Digit $label',
          button: true,
          excludeSemantics: true,
          child: SizedBox(
            width: 72,
            height: 64,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: const CircleBorder(),
              ),
              onPressed: () => onDigit(label),
              child: Text(label, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [key('1'), key('2'), key('3')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [key('4'), key('5'), key('6')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [key('7'), key('8'), key('9')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 72, height: 64, child: trailing),
            key('0'),
            SizedBox(
              width: 72,
              height: 64,
              child: IconButton(
                tooltip: 'Delete digit',
                onPressed: onBackspace,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 216,
          child: FilledButton(
            onPressed: onSubmit,
            child: const Text('Unlock'),
          ),
        ),
      ],
    );
  }
}
