import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/expiry_status.dart';
import '../providers/document_providers.dart';
import '../widgets/document_card.dart';
import 'document_detail_screen.dart';

/// Complete document collection and alert view used by app-level navigation.
class DocumentCollectionScreen extends ConsumerStatefulWidget {
  const DocumentCollectionScreen({super.key, this.alertsOnly = false});

  final bool alertsOnly;

  @override
  ConsumerState<DocumentCollectionScreen> createState() =>
      _DocumentCollectionScreenState();
}

class _DocumentCollectionScreenState
    extends ConsumerState<DocumentCollectionScreen> {
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

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    ref.listen(searchQueryProvider, (_, value) {
      if (_searchController.text != value) _searchController.text = value;
    });
    final visible = ref.watch(visibleDocumentsProvider);
    final documents = widget.alertsOnly
        ? visible.where((document) =>
            document.status == ExpiryStatus.expired ||
            document.status == ExpiryStatus.critical).toList(growable: false)
        : visible;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alertsOnly ? 'Alerts' : 'All Documents'),
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(searchQueryProvider.notifier)
                    .update(value),
                decoration: InputDecoration(
                  hintText: widget.alertsOnly
                      ? 'Search alerts...'
                      : 'Search your documents...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).update('');
                          },
                        ),
                ),
              ),
            ),
          ),
          if (documents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.alertsOnly
                            ? Icons.notifications_none_outlined
                            : Icons.folder_open_outlined,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.alertsOnly
                            ? 'No active alerts'
                            : 'No documents found',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.alertsOnly
                            ? 'You are all caught up.'
                            : 'Try a different search.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
