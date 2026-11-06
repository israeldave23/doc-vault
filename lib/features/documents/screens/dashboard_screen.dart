import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium_components.dart'
    show
        PremiumHeader,
        PremiumSearchBar,
        DocumentOverviewCard,
        ExpiryAlertCard,
        VaultProfileSelector,
        VaultStatusFilters;
import '../../../core/utils/expiry_status.dart';
import '../../ads/widgets/ad_banner.dart';
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
        .where((document) =>
            document.status == ExpiryStatus.ok ||
            document.status == ExpiryStatus.warning)
        .length;

    final selectedProfileObj = selectedProfile == null
        ? null
        : profiles.where((p) => p.id == selectedProfile).firstOrNull;
    final profileDisplayName = selectedProfileObj?.name ?? 'Everyone';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: true,
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  background: PremiumHeader(
                    greeting: _greeting,
                    profileName: profileDisplayName,
                    onNotificationTap: () {},
                    onSettingsTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: PremiumSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).update(value);
                      setState(() {});
                    },
                    onClear: _clearSearch,
                    onFilterTap: () {},
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
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
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: DocumentOverviewCard(
                        total: profileDocuments.length,
                        valid: validCount,
                        expiring: expiringCount,
                        expired: expiredCount,
                        onStatusTap: (status) {
                          _clearSearch();
                          ref
                              .read(statusFilterProvider.notifier)
                              .select(status);
                        },
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      child: expiredCount + expiringCount > 0
                          ? _PriorityAlerts(
                              key: const ValueKey('priority'),
                              documents: (profileDocuments
                                    .where((document) =>
                                        document.status ==
                                            ExpiryStatus.expired ||
                                        document.status ==
                                            ExpiryStatus.critical)
                                    .toList()
                                  ..sort((a, b) =>
                                      a.expiryDate.compareTo(b.expiryDate)))
                                  .take(3)
                                  .toList(growable: false),
                              onDocumentTap: (id) =>
                                  Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      DocumentDetailScreen(documentId: id),
                                ),
                              ),
                            )
                          : const _AllCaughtUpCard(
                              key: ValueKey('caught-up'),
                            ),
                    ),
                  ),
                ),
              ],
              if (allDocuments.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
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
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.sm)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  0,
                ),
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
                    bottom: AppSpacing.md,
                  ),
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
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AddEditDocumentScreen(),
          ),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: settings.isPro ? null : const AdBanner(),
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

class _PriorityAlerts extends StatelessWidget {
  const _PriorityAlerts({
    super.key,
    required this.documents,
    required this.onDocumentTap,
  });

  final List<Document> documents;
  final ValueChanged<String> onDocumentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final alertColor = isDark
        ? AppColors.statusExpiredDark
        : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: alertColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Needs your attention',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: alertColor,
                ),
              ),
            ],
          ),
        ),
        for (final doc in documents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ExpiryAlertCard(
              title: doc.title,
              daysLabel: daysRemainingLabel(doc.daysRemaining),
              status: doc.status,
              icon: doc.status == ExpiryStatus.expired
                  ? Icons.error_outline
                  : Icons.schedule_outlined,
              onTap: () => onDocumentTap(doc.id),
            ),
          ),
      ],
    );
  }
}

class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark
        ? AppColors.statusOkDark
        : AppColors.success;
    return Container(
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: successColor.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: successColor,
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
                  'All caught up!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No documents need your attention right now.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
