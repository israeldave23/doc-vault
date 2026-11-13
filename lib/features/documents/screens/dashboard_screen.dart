import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/expiry_status.dart';
import '../../ads/widgets/ad_banner.dart';
import '../../profiles/models/profile.dart';
import '../../profiles/providers/profile_providers.dart';
import '../../profiles/screens/profiles_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/document.dart';
import '../providers/document_providers.dart';
import '../widgets/document_card.dart';
import 'add_edit_document_screen.dart';
import 'document_detail_screen.dart';

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

  void _viewAll() {
    _clearSearch();
    ref.read(selectedProfileIdProvider.notifier).select(null);
    ref.read(statusFilterProvider.notifier).select(null);
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
    final expiringCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.critical)
        .length;
    final validCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.ok)
        .length;

    return Scaffold(
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
           SliverAppBar(
             backgroundColor: Colors.transparent,
             elevation: 0,
             scrolledUnderElevation: 0,
             pinned: false,
             titleSpacing: 0,
             title: Padding(
               padding: const EdgeInsets.only(left: AppSpacing.md),
               child: Row(
                 children: [
                   Container(
                     width: 44,
                     height: 44,
                     decoration: BoxDecoration(
                       color: scheme.primary.withValues(alpha: 0.08),
                       borderRadius: BorderRadius.circular(AppRadii.control),
                     ),
                     child: Icon(
                       Icons.shield_outlined,
                       color: scheme.primary,
                       size: 22,
                     ),
                   ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _greeting,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Document Vault',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                   IconButton(
                     tooltip: 'Settings',
                     icon: const Icon(Icons.tune_outlined),
                     onPressed: () => Navigator.of(context).push(
                       MaterialPageRoute<void>(
                         builder: (_) => const SettingsScreen(),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
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
                decoration: InputDecoration(
                  hintText: 'Search your documents...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: VaultProfileSelector(
                profiles: profiles,
                selectedProfile: selectedProfile,
              ),
            ),
          ),
          if (allDocuments.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
               child: _AnimatedHealthOverview(
                   total: profileDocuments.length,
                   valid: validCount,
                   expired: expiredCount,
                   expiring: expiringCount,
                   onTap: (status) {
                     _clearSearch();
                     ref.read(statusFilterProvider.notifier).select(status);
                   },
                 ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  child: expiredCount + expiringCount > 0
                      ? _PriorityAlerts(
                          key: const ValueKey('priority'),
                          documents: profileDocuments
                              .where((document) =>
                                  document.status == ExpiryStatus.expired ||
                                  document.status == ExpiryStatus.critical)
                              .take(3)
                              .toList(growable: false),
                          onDocumentTap: (id) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DocumentDetailScreen(documentId: id),
                            ),
                          ),
                        )
                      : const _AllCaughtUpCard(key: ValueKey('caught-up')),
                ),
              ),
            ),
          ],
          if (allDocuments.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                   OutlinedButton.icon(
                     onPressed: _viewAll,
                     icon: const Icon(Icons.grid_3x3_outlined),
                     label: const Text('Browse all'),
                   ),
                   OutlinedButton.icon(
                     onPressed: () => Navigator.of(context).push(
                       MaterialPageRoute<void>(
                         builder: (_) => const ProfilesScreen(),
                       ),
                     ),
                     icon: const Icon(Icons.people_outline),
                     label: const Text('Manage profiles'),
                   ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Your Documents',
                action: TextButton(
                  onPressed: _viewAll,
                  child: const Text('View all'),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.md),
              child: VaultStatusFilters(
                selectedStatus: selectedStatus,
                documents: allDocuments,
                selectedProfile: selectedProfile,
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
                onClearProfile: () => ref
                    .read(selectedProfileIdProvider.notifier)
                    .select(null),
                onClearStatus: () => ref
                    .read(statusFilterProvider.notifier)
                    .select(null),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddEditDocumentScreen()),
        ),
        tooltip: 'Add document',
        icon: const Icon(Icons.add),
        label: const Text('Add document'),
      ),
      bottomNavigationBar: settings.isPro ? null : const AdBanner(),
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

class _AnimatedHealthOverview extends StatefulWidget {
  const _AnimatedHealthOverview({
    required this.total,
    required this.valid,
    required this.expired,
    required this.expiring,
    required this.onTap,
  });

  final int total;
  final int valid;
  final int expired;
  final int expiring;
  final void Function(ExpiryStatus?) onTap;

  @override
  State<_AnimatedHealthOverview> createState() => _AnimatedHealthOverviewState();
}

class _AnimatedHealthOverviewState extends State<_AnimatedHealthOverview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tiles = <(String, int, Color, ExpiryStatus?)>[
      ('Total', widget.total, scheme.primary, null),
      ('Valid', widget.valid, ExpiryStatus.ok.colorFor(context), ExpiryStatus.ok),
      ('Expiring', widget.expiring,
          ExpiryStatus.critical.colorFor(context), ExpiryStatus.critical),
      ('Expired', widget.expired,
          ExpiryStatus.expired.colorFor(context), ExpiryStatus.expired),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++)
              Expanded(
                child: _AnimatedHealthTile(
                  label: tiles[i].$1,
                  count: tiles[i].$2,
                  color: tiles[i].$3,
                  onTap: tiles[i].$4 == null ? null : () => widget.onTap(tiles[i].$4),
                  animation: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval(i * 0.1, 0.4 + i * 0.1, curve: Curves.easeOut),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHealthTile extends AnimatedWidget {
  const _AnimatedHealthTile({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
    required Animation<double> animation,
  }) : super(listenable: animation);

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = animation.value;
    final scale = 0.8 + (animation.value * 0.2);
    final child = Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$count', style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
        ]),
      ),
    );
    if (onTap == null) return child;
    return Semantics(button: true, onTap: onTap, label: '$count $label', child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadii.control), child: child));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _PriorityAlerts extends StatelessWidget {
  const _PriorityAlerts({super.key, required this.documents, required this.onDocumentTap});
  final List<Document> documents;
  final ValueChanged<String> onDocumentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer), const SizedBox(width: AppSpacing.sm), Text('Needs your attention', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.onErrorContainer))]),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < documents.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.md),
            _PriorityRow(document: documents[i], onTap: () => onDocumentTap(documents[i].id)),
          ],
        ]),
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.document, required this.onTap});
  final Document document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = document.status.colorFor(context);
    return Semantics(
      button: true,
      onTap: onTap,
      label: '${document.title}, ${document.status.label}, ${daysRemainingLabel(document.daysRemaining)}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(children: [
              Icon(document.status == ExpiryStatus.expired ? Icons.error_outline : Icons.schedule, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(daysRemainingLabel(document.daysRemaining), style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ])),
              Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
            ]),
          ),
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
    final options = <(String, ExpiryStatus?, int, Color)>[
      ('All', null, filtered.length, Theme.of(context).colorScheme.primary),
      ('Expired', ExpiryStatus.expired, counts[ExpiryStatus.expired]!,
          ExpiryStatus.expired.colorFor(context)),
      ('Expiring soon', ExpiryStatus.critical, counts[ExpiryStatus.critical]!,
          ExpiryStatus.critical.colorFor(context)),
      ('Renew soon', ExpiryStatus.warning, counts[ExpiryStatus.warning]!,
          ExpiryStatus.warning.colorFor(context)),
      ('Valid', ExpiryStatus.ok, counts[ExpiryStatus.ok]!,
          ExpiryStatus.ok.colorFor(context)),
    ];
    return SizedBox(
      height: 32 + MediaQuery.textScalerOf(context).scale(20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
               child: Semantics(
                 label: option.$2?.label ?? 'All documents',
                 child: FilterChip(
                   label: Text(option.$3 == 0
                       ? option.$1
                       : '${option.$1} (${option.$3})'),
                   selected: selectedStatus == option.$2,
                   showCheckmark: false,
                   selectedColor: option.$4.withValues(alpha: 0.14),
                   labelStyle: TextStyle(
                     color: selectedStatus == option.$2
                         ? option.$4
                         : Theme.of(context).colorScheme.onSurface,
                   ),
                   onSelected: (_) => ref
                       .read(statusFilterProvider.notifier)
                       .select(option.$2),
                 ),
               ),
            ),
        ],
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
    final isEmpty = allDocuments.isEmpty;
    final profileEmpty = selectedProfile != null &&
        !allDocuments.any((document) => document.profileId == selectedProfile);
    final title = isEmpty
        ? 'No documents yet'
        : hasSearch
            ? 'No matching documents'
            : profileEmpty
                ? 'No documents for this profile'
                : 'No ${selectedStatus?.label.toLowerCase() ?? 'matching'} documents';
    final message = isEmpty
        ? 'Add your first document to keep everything organized.'
        : hasSearch
            ? 'Try another keyword or adjust your filters.'
            : profileEmpty
                ? 'Add a document for this person to keep their important dates organized.'
                : 'Try changing the selected profile or status filter.';
    final action = isEmpty
        ? FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AddEditDocumentScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add your first document'),
          )
        : OutlinedButton.icon(
            onPressed: hasSearch
                ? onClearSearch
                : profileEmpty
                    ? onClearProfile
                    : onClearStatus,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: Text(hasSearch
                ? 'Clear search'
                : selectedProfile != null
                    ? 'Show everyone'
                    : 'Show all statuses'),
          );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEmpty
                  ? Icons.folder_open
                  : profileEmpty && !hasSearch
                      ? Icons.person_outline
                      : Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }
}

class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(Icons.check_circle_outline,
              color: ExpiryStatus.ok.colorFor(context)),
          title: const Text('All caught up!'),
          subtitle: const Text('No documents need your attention right now.'),
        ),
      );
}
