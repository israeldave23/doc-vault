import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.heroCard),
        ),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Document Vault',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Premium Digital Wallet',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined,
                        color: Colors.white),
                    onPressed: onNotificationTap,
                    tooltip: 'Notifications',
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, color: Colors.white),
                    onPressed: onSettingsTap,
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                profileName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search your documents...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  onPressed: onFilterTap,
                  tooltip: 'Filter',
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                  tooltip: 'Clear search',
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
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
        gradient: AppColors.summaryCardGradient,
        borderRadius: BorderRadius.circular(AppRadii.heroCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandIndigo.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR DOCUMENTS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$total Documents',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$valid valid • $expiring expiring • $expired expired',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
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
        ? (isExpired ? AppColors.statusExpiredDark : AppColors.statusCriticalDark)
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline, size: 20),
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
          gradient: selected
              ? AppColors.primaryActionGradient
              : null,
          color: selected
              ? null
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : scheme.outline.withValues(alpha: 0.3),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.electricPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          displayLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : scheme.onSurface,
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
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.15),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Expires $expiryDate',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right,
                color: scheme.outline.withValues(alpha: 0.5), size: 20),
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
            onTap: () => ref
                .read(selectedProfileIdProvider.notifier)
                .select(null),
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
            icon: Icons.manage_accounts_outlined,
            selected: false,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon == null ? null : Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
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
                onSelected: () => ref
                    .read(statusFilterProvider.notifier)
                    .select(option.$2),
              ),
            ),
        ],
      ),
    );
  }
}
