import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profiles/providers/profile_providers.dart';
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
    final allDocuments = ref.watch(documentsProvider);

    final expiringSoon = allDocuments.where((d) => d.daysRemaining < 30).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings arrive in Week 5')),
              );
            },
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
                ? const _EmptyState()
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
    );
  }
}

class _ProfileFilterChip extends StatelessWidget {
  const _ProfileFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
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
