
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/expiry_status.dart';
import '../../../core/widgets/section_label.dart';
import '../../ads/widgets/ad_banner.dart';
import '../../profiles/models/profile.dart';
import '../../profiles/providers/profile_providers.dart';
import '../../profiles/screens/profiles_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/document.dart';
import '../providers/document_providers.dart';
import '../widgets/document_card.dart';
import 'add_edit_document_screen.dart';
import 'document_detail_screen.dart';

const _tabular = <FontFeature>[FontFeature.tabularFigures()];

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).update('');
    setState(() {});
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Welcome back';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (_, value) {
      if (_searchController.text != value) _searchController.text = value;
    });
    final documents = ref.watch(visibleDocumentsProvider);
    final allDocuments = ref.watch(documentsProvider);
    final profiles = ref.watch(profilesProvider);
    final selectedProfile = ref.watch(selectedProfileIdProvider);
    final selectedStatus = ref.watch(statusFilterProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final profileDocuments = allDocuments
        .where(
          (document) =>
              selectedProfile == null || document.profileId == selectedProfile,
        )
        .toList(growable: false);
    final expiredCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.expired)
        .length;
    final criticalCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.critical)
        .length;
    final warningCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.warning)
        .length;
    final validCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.ok)
        .length;
    final needsAttention = expiredCount + criticalCount;

    return Scaffold(
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM')
                        .format(DateTime.now())
                        .toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_greeting, style: theme.textTheme.headlineLarge),
                ],
              ),
            ),
          ),
          if (profileDocuments.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _VaultHealthCard(
                  total: profileDocuments.length,
                  needsAttention: needsAttention,
                  valid: validCount,
                  parts: [
                    (
                      expiredCount,
                      ExpiryStatus.expired.colorFor(context),
                      'expired',
                    ),
                    (
                      criticalCount,
                      ExpiryStatus.critical.colorFor(context),
                      'expiring soon',
                    ),
                    (
                      warningCount,
                      ExpiryStatus.warning.colorFor(context),
                      'renew soon',
                    ),
                    (validCount, ExpiryStatus.ok.colorFor(context), 'valid'),
                  ],
                ),
              ),
            ),
          if (allDocuments.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm + 4,
                AppSpacing.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).update(value);
                  setState(() {});
                },
                decoration: AppInputStyles.search(
                  context,
                  hint: 'Search documents',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
          ),
          if (allDocuments.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.gutter,
                  top: AppSpacing.sm + 4,
                ),
                child: VaultStatusFilters(
                selectedStatus: selectedStatus,
                documents: allDocuments,
                selectedProfile: selectedProfile,
              ),
            ),
          ),
          if (allDocuments.isNotEmpty && profiles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm + 4,
                  AppSpacing.gutter,
                  0,
                ),
                child: VaultProfileSelector(
                  profiles: profiles,
                  selectedProfile: selectedProfile,
                ),
              ),
            ),
          if (allDocuments.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md + 4,
                AppSpacing.gutter,
                AppSpacing.sm + 2,
              ),
              sliver: SliverToBoxAdapter(
                child: SectionLabel(
                'Documents',
                trailing: Text(
                  '${profileDocuments.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
            ),
          ),
          if (documents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                allDocuments: allDocuments,
                selectedProfile: selectedProfile,
                selectedStatus: selectedStatus,
                hasSearch: _searchController.text.trim().isNotEmpty,
                onClearSearch: _clearSearch,
                onClearProfile: () =>
                    ref.read(selectedProfileIdProvider.notifier).select(null),
                onClearStatus: () =>
                    ref.read(statusFilterProvider.notifier).select(null),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              sliver: SliverList.separated(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];
                  return DocumentCard(
                    document: document,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DocumentDetailScreen(
                          documentId: document.id,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      // On a brand-new vault the empty state owns the single call to action.
      floatingActionButton: allDocuments.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddEditDocumentScreen(),
                ),
              ),
              tooltip: 'Add document',
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add document'),
            ),
      bottomNavigationBar: settings.isPro ? null : const AdBanner(),
    );
  }
}

/// One object that answers "how is my vault doing?" and doubles as the status
/// filter, replacing the four-tile counter grid and the separate chip row.
class _VaultHealthCard extends StatelessWidget {
  const _VaultHealthCard({
    required this.total,
    required this.needsAttention,
    required this.valid,
    required this.parts,
  });

  /// (count, colour, spoken label) in severity order.
  final List<(int, Color, String)> parts;
  final int total;
  final int needsAttention;
  final int valid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ok = needsAttention == 0;
    final headline = ok
        ? 'All current'
        : needsAttention == 1
            ? 'Needs attention'
            : 'Need attention';
    final detail = ok
        ? '$total ${total == 1 ? 'document' : 'documents'} in the vault'
        : '$total in the vault · $valid valid';
    final spoken = parts
        .where((part) => part.$1 > 0)
        .map((part) => '${part.$1} ${part.$3}')
        .join(', ');

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: spoken.isEmpty ? 'No documents yet' : spoken,
            child: _HealthBar(parts: parts),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 6,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Vault status'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '$needsAttention',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: ok
                            ? ExpiryStatus.ok.colorFor(context)
                            : ExpiryStatus.expired.colorFor(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(headline, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            detail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Proportional status bar that forms the top edge of the vault card.
class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.parts});

  final List<(int, Color, String)> parts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = parts.where((part) => part.$1 > 0).toList(growable: false);
    return SizedBox(
      height: 6,
      child: visible.isEmpty
          ? ColoredBox(color: scheme.surfaceContainerHighest)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visible.length; i++)
                  Expanded(
                    flex: visible[i].$1,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == visible.length - 1 ? 0 : 3,
                      ),
                      child: ColoredBox(color: visible[i].$2),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Scope selector: "Everyone" plus one pill per person.
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ProfilePill(
            label: 'Everyone',
            selected: selectedProfile == null,
            onTap: () =>
                ref.read(selectedProfileIdProvider.notifier).select(null),
          ),
          for (final profile in profiles)
            _ProfilePill(
              label: '${profile.avatarEmoji ?? ''} ${profile.name}'.trim(),
              selected: selectedProfile == profile.id,
              onTap: () => ref
                  .read(selectedProfileIdProvider.notifier)
                  .select(profile.id),
            ),
          _ProfilePill(
            label: 'Manage',
            icon: Icons.people_outline,
            selected: false,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfilesScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              icon == null ? 14 : 10,
              9,
              14,
              9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status filter rendered as legend pills. It sits inside the vault-status card
/// so the legend and the filter are the same object.
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
    final scheme = Theme.of(context).colorScheme;
    final filtered = documents.where(
      (document) =>
          selectedProfile == null || document.profileId == selectedProfile,
    );
    final counts = <ExpiryStatus, int>{
      for (final status in ExpiryStatus.values)
        status: filtered.where((document) => document.status == status).length,
    };
    final options = <(String, ExpiryStatus?, int, Color)>[
      ('All', null, filtered.length, scheme.primary),
      (
        'Expired',
        ExpiryStatus.expired,
        counts[ExpiryStatus.expired]!,
        ExpiryStatus.expired.colorFor(context),
      ),
      (
        'Expiring',
        ExpiryStatus.critical,
        counts[ExpiryStatus.critical]!,
        ExpiryStatus.critical.colorFor(context),
      ),
      (
        'Renew',
        ExpiryStatus.warning,
        counts[ExpiryStatus.warning]!,
        ExpiryStatus.warning.colorFor(context),
      ),
      (
        'Valid',
        ExpiryStatus.ok,
        counts[ExpiryStatus.ok]!,
        ExpiryStatus.ok.colorFor(context),
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _FilterPill(
                label: option.$1,
                count: option.$3,
                color: option.$4,
                selected: selectedStatus == option.$2,
                onTap: () =>
                    ref.read(statusFilterProvider.notifier).select(option.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? color : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      child: Material(
        color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.38)
                : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground.withValues(alpha: 0.62),
                    fontSize: 12.5,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.allDocuments,
    required this.selectedProfile,
    required this.selectedStatus,
    required this.hasSearch,
    required this.onClearSearch,
    required this.onClearProfile,
    required this.onClearStatus,
  });

  final List<Document> allDocuments;
  final String? selectedProfile;
  final ExpiryStatus? selectedStatus;
  final bool hasSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onClearProfile;
  final VoidCallback onClearStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEmpty = allDocuments.isEmpty;
    final profileEmpty = selectedProfile != null &&
        !allDocuments.any((document) => document.profileId == selectedProfile);
    final title = isEmpty
        ? 'No documents yet'
        : hasSearch
            ? 'No matching documents'
            : profileEmpty
                ? 'No documents for this person'
                : 'No ${selectedStatus?.label.toLowerCase() ?? 'matching'} documents';
    final message = isEmpty
        ? 'Add your first ID, licence or permit and this vault starts '
            'keeping time for you.'
        : hasSearch
            ? 'Try another keyword, or clear the search.'
            : profileEmpty
                ? 'Add a document for this person to track their renewal dates.'
                : 'Try a different status or scope.';
    final action = isEmpty
        ? FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AddEditDocumentScreen(),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add your first document'),
          )
        : OutlinedButton.icon(
            onPressed: hasSearch
                ? onClearSearch
                : profileEmpty
                    ? onClearProfile
                    : onClearStatus,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: Text(hasSearch
                ? 'Clear search'
                : selectedProfile != null
                    ? 'Show everyone'
                    : 'Show all statuses'),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEmpty
                  ? Icons.folder_outlined
                  : profileEmpty && !hasSearch
                      ? Icons.person_outline
                      : Icons.search_off,
              size: 24,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          action,
        ],
      ),
    );
  }
}
