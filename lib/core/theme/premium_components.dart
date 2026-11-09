import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../features/profiles/models/profile.dart';
import '../../features/profiles/providers/profile_providers.dart';
import '../../features/profiles/screens/profiles_screen.dart';
import '../../features/documents/models/document.dart';
import '../../features/documents/providers/document_providers.dart';
import '../utils/expiry_status.dart';
import 'app_theme.dart';

class PremiumHeader extends StatelessWidget {
  const PremiumHeader({
    super.key,
    required this.greeting,
    required this.profileName,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  final String greeting;
  final String profileName;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadii.heroCard)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.muted,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: Icon(LucideIcons.shield, color: scheme.foreground),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Document Vault',
                          style: theme.typography.h4.copyWith(
                            color: scheme.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Premium Digital Wallet',
                          style: theme.typography.xSmall.copyWith(
                            color: scheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.bell),
                    onPressed: onNotificationTap,
                  ),
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.slidersHorizontal),
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                greeting,
                style: theme.typography.base.copyWith(
                  color: scheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profileName,
                style: theme.typography.h3.copyWith(
                  color: scheme.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      borderRadius: BorderRadius.circular(AppRadii.input),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        hintText: 'Search your documents...',
        features: [
          const InputLeadingFeature(Icon(LucideIcons.search)),
          controller.text.isEmpty
              ? InputTrailingFeature(
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.slidersHorizontal),
                    onPressed: onFilterTap,
                  ),
                )
              : InputTrailingFeature(
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.x),
                    onPressed: onClear,
                  ),
                ),
        ],
      ),
    );
  }
}

class DocumentOverviewCard extends StatelessWidget {
  const DocumentOverviewCard({
    super.key,
    required this.total,
    required this.valid,
    required this.expiring,
    required this.expired,
    required this.onStatusTap,
  });

  final int total;
  final int valid;
  final int expiring;
  final int expired;
  final void Function(ExpiryStatus?) onStatusTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        borderRadius: BorderRadius.circular(AppRadii.heroCard),
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR DOCUMENTS',
              style: Theme.of(context).typography.xSmall.copyWith(
                    color: Theme.of(context).colorScheme.mutedForeground,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$total Documents',
              style: Theme.of(context).typography.h3.copyWith(
                    color: Theme.of(context).colorScheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$valid valid • $expiring expiring • $expired expired',
              style: Theme.of(context).typography.small.copyWith(
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _StatusIndicator(
                  label: 'Valid',
                  count: valid,
                  color: AppColors.success,
                  status: ExpiryStatus.ok,
                  onTap: () => onStatusTap(ExpiryStatus.ok),
                ),
                const SizedBox(width: AppSpacing.md),
                _StatusIndicator(
                  label: 'Expiring',
                  count: expiring,
                  color: AppColors.warning,
                  status: ExpiryStatus.critical,
                  onTap: () => onStatusTap(ExpiryStatus.critical),
                ),
                const SizedBox(width: AppSpacing.md),
                _StatusIndicator(
                  label: 'Expired',
                  count: expired,
                  color: AppColors.danger,
                  status: ExpiryStatus.expired,
                  onTap: () => onStatusTap(ExpiryStatus.expired),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.label,
    required this.count,
    required this.color,
    required this.status,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final ExpiryStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: Theme.of(context).typography.medium.copyWith(
                      color: Theme.of(context).colorScheme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).typography.xSmall.copyWith(
                      color: Theme.of(context).colorScheme.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpiryAlertCard extends StatelessWidget {
  const ExpiryAlertCard({
    super.key,
    required this.title,
    required this.daysLabel,
    required this.status,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String daysLabel;
  final ExpiryStatus status;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpired = status == ExpiryStatus.expired;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = isDark
        ? (isExpired
            ? AppColors.statusExpiredDark
            : AppColors.statusCriticalDark)
        : (isExpired ? AppColors.danger : AppColors.warning);
    final bgColor = statusColor.withValues(alpha: isDark ? 0.12 : 0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: statusColor.withValues(alpha: isDark ? 0.35 : 0.2),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).typography.medium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysLabel,
                    style: Theme.of(context).typography.xSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                color: Theme.of(context).colorScheme.border, size: 20),
          ],
        ),
      ),
    );
  }
}

class PremiumFilterChip extends StatelessWidget {
  const PremiumFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayLabel = count != null ? '$label ($count)' : label;

    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.card,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: selected ? scheme.primary : scheme.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          displayLabel,
          style: Theme.of(context).typography.xSmall.copyWith(
                color: selected ? scheme.primaryForeground : scheme.foreground,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class PremiumDocumentCard extends StatelessWidget {
  const PremiumDocumentCard({
    super.key,
    required this.title,
    required this.category,
    required this.expiryDate,
    required this.status,
    required this.daysRemaining,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String category;
  final String expiryDate;
  final ExpiryStatus status;
  final String daysRemaining;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = status.colorFor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: scheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).typography.medium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category,
                          style: Theme.of(context).typography.xSmall.copyWith(
                                color: scheme.mutedForeground,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Expires $expiryDate',
                          style: Theme.of(context).typography.xSmall.copyWith(
                                color: scheme.mutedForeground,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    daysRemaining,
                    style: Theme.of(context).typography.xSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(LucideIcons.chevronRight,
                color: scheme.border.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

class VaultProfileSelector extends ConsumerWidget {
  const VaultProfileSelector({
    super.key,
    required this.profiles,
    required this.selectedProfile,
  });

  final List<Profile> profiles;
  final String? selectedProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 32 + MediaQuery.textScalerOf(context).scale(20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ProfileChip(
            label: 'Everyone',
            selected: selectedProfile == null,
            onTap: () =>
                ref.read(selectedProfileIdProvider.notifier).select(null),
          ),
          for (final profile in profiles)
            _ProfileChip(
              label: '${profile.avatarEmoji ?? ''} ${profile.name}'.trim(),
              selected: selectedProfile == profile.id,
              onTap: () => ref
                  .read(selectedProfileIdProvider.notifier)
                  .select(profile.id),
            ),
          _ProfileChip(
            label: 'Manage',
            icon: LucideIcons.users,
            selected: false,
            onTap: () => Navigator.of(context).push(
              ShadcnPageRoute<void>(
                builder: (_) => const ProfilesScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        leading: icon == null ? null : Icon(icon, size: 18),
        onPressed: onTap,
        style: selected
            ? const ButtonStyle.primary()
            : const ButtonStyle.outline(),
        child: Text(label),
      ),
    );
  }
}

class VaultStatusFilters extends ConsumerWidget {
  const VaultStatusFilters({
    super.key,
    required this.selectedStatus,
    required this.documents,
    required this.selectedProfile,
  });

  final ExpiryStatus? selectedStatus;
  final List<Document> documents;
  final String? selectedProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = documents.where(
      (document) =>
          selectedProfile == null || document.profileId == selectedProfile,
    );
    final counts = <ExpiryStatus, int>{
      for (final status in ExpiryStatus.values)
        status: filtered.where((document) => document.status == status).length,
    };
    final options = <(String, ExpiryStatus?, int)>[
      ('All', null, filtered.length),
      ('Expired', ExpiryStatus.expired, counts[ExpiryStatus.expired]!),
      ('Expiring soon', ExpiryStatus.critical, counts[ExpiryStatus.critical]!),
      ('Renew soon', ExpiryStatus.warning, counts[ExpiryStatus.warning]!),
      ('Valid', ExpiryStatus.ok, counts[ExpiryStatus.ok]!),
    ];
    return SizedBox(
      height: 40 + MediaQuery.textScalerOf(context).scale(14),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: PremiumFilterChip(
                label: option.$1,
                count: option.$3 > 0 ? option.$3 : null,
                selected: selectedStatus == option.$2,
                onSelected: () =>
                    ref.read(statusFilterProvider.notifier).select(option.$2),
              ),
            ),
        ],
      ),
    );
  }
}
