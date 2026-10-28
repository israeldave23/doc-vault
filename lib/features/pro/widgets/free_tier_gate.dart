import 'package:flutter/material.dart';

import '../screens/paywall_screen.dart';

/// Returns whether the action may proceed. When it may not, shows the free
/// tier limit dialog and — on "Unlock Pro" — the paywall.
Future<bool> ensureWithinFreeTier(
  BuildContext context, {
  required bool allowed,
  required String message,
}) async {
  if (allowed) return true;

  final upgrade = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Free tier limit'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Unlock Pro'),
        ),
      ],
    ),
  );

  if (upgrade == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(reason: message),
      ),
    );
  }
  return false;
}
