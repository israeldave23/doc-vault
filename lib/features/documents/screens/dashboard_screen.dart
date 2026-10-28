import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/expiry_status.dart';
import '../../profiles/providers/profile_providers.dart';
import '../../profiles/screens/profiles_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../../ads/widgets/ad_banner.dart';
import '../providers/document_providers.dart';
import '../widgets/document_card.dart';
import 'add_edit_document_screen.dart';
import 'document_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(visibleDocumentsProvider);
    final profiles = ref.watch(profilesProvider);
    final selectedProfile = ref.watch(selectedProfileIdProvider);
    final selectedStatus = ref.watch(statusFilterProvider);
    final allDocuments = ref.watch(documentsProvider);
    final settings = ref.watch(settingsProvider);

    final expiringSoon = allDocuments.where((d) => d.daysRemaining < 30).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
              decoration: const InputDecoration(
                hintText: 'Search documents',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _ProfileFilterChip(
                  label: 'Everyone',
                  selected: selectedProfile == null,
                  onSelected: () => ref.read(selectedProfileIdProvider.notifier).select(null),
                ),
                for (final p in profiles)
                  _ProfileFilterChip(
                    label: '${p.avatarEmoji ?? ''} ${p.name}'.trim(),
                    selected: selectedProfile == p.id,
                    onSelected: () => ref.read(selectedProfileIdProvider.notifier).select(p.id),
                  ),
                _ProfileFilterChip(
                  label: 'Manage',
                  icon: Icons.people_outline,
                  selected: false,
                  onSelected: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ProfilesScreen()),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              children: [
                _StatusFilterChip(
                  label: 'All statuses',
                  color: Theme.of(context).colorScheme.outline,
                  selected: selectedStatus == null,
                  onSelected: () =>
                      ref.read(statusFilterProvider.notifier).select(null),
                ),
                for (final status in ExpiryStatus.values)
                  _StatusFilterChip(
                    label: status.label,
                    color: status.color,
                    selected: selectedStatus == status,
                    onSelected: () => ref
                        .read(statusFilterProvider.notifier)
                        .select(status),
                  ),
              ],
            ),
          ),
          if (expiringSoon > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _AlertBanner(count: expiringSoon),
            ),
          Expanded(
            child: documents.isEmpty
                ? (allDocuments.isEmpty
                    ? const _EmptyState()
                    : _NoMatches(
                        onClear: () {
                          ref.read(searchQueryProvider.notifier).update('');
                          ref.read(selectedProfileIdProvider.notifier)
                              .select(null);
                          ref.read(statusFilterProvider.notifier).select(null);
                        },
                      ))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: documents.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return DocumentCard(
                        document: doc,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DocumentDetailScreen(documentId: doc.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddEditDocumentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      // Free tier carries one banner; Pro removes it entirely.
      bottomNavigationBar:
          settings.isPro ? null : const AdBanner(),
    );
  }
}

class _ProfileFilterChip extends StatelessWidget {
  const _ProfileFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon == null ? null : Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? '1 document is expired or expiring within 30 days'
                  : '$count documents are expired or expiring within 30 days',
              style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No matching documents', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Nothing matches the current search and filters.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No documents yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add your passport, license or any ID and we will remind you before it expires. Everything stays on this phone.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
