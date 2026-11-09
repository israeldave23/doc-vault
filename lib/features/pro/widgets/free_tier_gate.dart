import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../screens/paywall_screen.dart';

Future<bool> ensureWithinFreeTier(
  BuildContext context, {
  required bool allowed,
  required String message,
}) async {
  if (allowed) return true;

  final upgrade = await const DialogConfiguration()
      .show<bool>(
        context,
        (ctx) => AlertDialog(
          title: const Text('Free tier limit'),
          content: Text(message),
          actions: [
            Button.ghost(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not now'),
            ),
            Button.primary(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Unlock Pro'),
            ),
          ],
        ),
      )
      .future;

  if (upgrade == true && context.mounted) {
    await Navigator.of(context).push(
      ShadcnPageRoute<void>(
        builder: (_) => PaywallScreen(reason: message),
      ),
    );
  }
  return false;
}
