import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
      headers: const [AppBar(title: Text('Document Vault Pro'))],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      LucideIcons.gem,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock Pro forever',
                    textAlign: TextAlign.center,
                    style: theme.typography.h3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One payment, no subscription. Your data never leaves the '
                    'device either way.',
                    textAlign: TextAlign.center,
                    style: theme.typography.p
                        .copyWith(color: theme.colorScheme.mutedForeground),
                  ),
                  if (widget.reason != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.reason!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.secondaryForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  for (final feature in const [
                    'Unlimited documents',
                    'Unlimited people and profiles',
                    'No banner ads',
                    'Support an independent offline-first app',
                  ])
                    Button.ghost(
                      alignment: Alignment.centerLeft,
                      leading: Icon(
                        LucideIcons.circleCheck,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: null,
                      child: Text(feature),
                    ),
                  const SizedBox(height: 16),
                  Button.primary(
                    onPressed: pro.storeAvailable ? () => pro.buyPro() : null,
                    leading: const Icon(LucideIcons.lockKeyholeOpen),
                    child: Text(
                      pro.storeAvailable
                          ? 'Unlock Pro — ${pro.priceLabel ?? ''}'
                          : 'Purchases unavailable',
                    ),
                  ),
                  if (!pro.storeAvailable) ...[
                    const SizedBox(height: 8),
                    Text(
                      'The Play Store is not available on this device, so the '
                      'price cannot be shown right now.',
                      textAlign: TextAlign.center,
                      style: theme.typography.small,
                    ),
                  ],
                  Button.link(
                    onPressed: () => pro.restorePurchases(),
                    child: const Text('Restore purchase'),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.typography.small
                            .copyWith(color: theme.colorScheme.mutedForeground),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Free tier: up to ${FreeTier.maxDocuments} documents and '
                    '${FreeTier.maxProfiles} people. Reminders, encryption and '
                    'app lock are always free.',
                    textAlign: TextAlign.center,
                    style: theme.typography.xSmall
                        .copyWith(color: theme.colorScheme.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
