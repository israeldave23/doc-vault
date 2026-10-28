import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_provider.dart';
import '../models/free_tier.dart';
import '../services/pro_service.dart';

/// One screen, one price — the paywall from the product spec.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// Optional context shown above the bullets (e.g. "limit reached").
  final String? reason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(proServiceProvider).init();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pro = ref.read(proServiceProvider);
    final message = ref.watch(purchaseMessageProvider);

    // Close automatically once the entitlement lands.
    ref.listen(settingsProvider, (previous, next) {
      if (next.isPro && mounted) Navigator.of(context).maybePop();
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Document Vault Pro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.workspace_premium, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Unlock Pro forever',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'One payment, no subscription. Your data never leaves the device '
            'either way.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (widget.reason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(widget.reason!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
            ),
          ],
          const SizedBox(height: 24),
          for (final feature in const [
            'Unlimited documents',
            'Unlimited people and profiles',
            'No banner ads',
            'Support an independent offline-first app',
          ])
            ListTile(
              leading: Icon(Icons.check_circle,
                  color: theme.colorScheme.primary),
              title: Text(feature),
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: pro.storeAvailable ? () => pro.buyPro() : null,
            icon: const Icon(Icons.lock_open),
            label: Text(
              pro.storeAvailable
                  ? 'Unlock Pro — ${pro.priceLabel ?? ''}'
                  : 'Purchases unavailable',
            ),
          ),
          if (!pro.storeAvailable) ...[
            const SizedBox(height: 8),
            Text(
              'The Play Store is not available on this device, so the price '
              'cannot be shown right now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          TextButton(
            onPressed: () => pro.restorePurchases(),
            child: const Text('Restore purchase'),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Text(
            'Free tier: up to ${FreeTier.maxDocuments} documents and '
            '${FreeTier.maxProfiles} people. Reminders, encryption and app '
            'lock are always free.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
