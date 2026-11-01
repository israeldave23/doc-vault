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
    final profileDocuments = allDocuments.where(
      (document) => selectedProfile == null || document.profileId == selectedProfile,
    );
    final expiredCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.expired)
        .length;
    final expiringCount = profileDocuments
        .where((document) => document.status == ExpiryStatus.critical)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Document Vault', style: theme.textTheme.titleLarge),
            Text(
              'Everything important, in one place.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
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
          if (expiredCount + expiringCount > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _AttentionCard(
                  expiredCount: expiredCount,
                  expiringCount: expiringCount,
                  onTap: () {
                    ref.read(searchQueryProvider.notifier).update('');
                    _searchController.clear();
                    ref.read(statusFilterProvider.notifier).select(
                          expiredCount > 0
                              ? ExpiryStatus.expired
                              : ExpiryStatus.critical,
                        );
                  },
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Your Documents',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _viewAll,
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 4, bottom: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddEditDocumentScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
      height: 48,
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

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.expiredCount,
    required this.expiringCount,
    required this.onTap,
  });

  final int expiredCount;
  final int expiringCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = expiredCount + expiringCount;
    final parts = <String>[
      if (expiredCount > 0) '$expiredCount expired',
      if (expiringCount > 0) '$expiringCount expiring soon',
    ];
    return Semantics(
      button: true,
      label: 'Needs your attention. $count documents. ${parts.join(', ')}.',
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Needs your attention',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      Text(
                        '$count documents · ${parts.join(' · ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ],
            ),
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
          AppColors.statusExpiredLight),
      ('Expiring soon', ExpiryStatus.critical, counts[ExpiryStatus.critical]!,
          AppColors.statusCriticalLight),
      ('Renew soon', ExpiryStatus.warning, counts[ExpiryStatus.warning]!,
          AppColors.statusWarningLight),
      ('Valid', ExpiryStatus.ok, counts[ExpiryStatus.ok]!,
          AppColors.statusOkLight),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
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
    final title = isEmpty
        ? 'No documents yet'
        : hasSearch
            ? 'No matching documents'
            : selectedProfile != null
                ? 'No documents for this person'
                : 'No ${selectedStatus?.label.toLowerCase() ?? 'matching'} documents';
    final message = isEmpty
        ? 'Add a passport, license or ID and get reminders before it expires. Your documents stay on this device.'
        : hasSearch
            ? 'Try another search or clear it to see your documents.'
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
                : selectedProfile != null
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
              isEmpty ? Icons.folder_open : Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
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
