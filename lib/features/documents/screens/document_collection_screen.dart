import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/expiry_status.dart';
import '../../../core/widgets/section_label.dart';
import '../providers/document_providers.dart';
import '../../profiles/providers/profile_providers.dart';
import 'dashboard_screen.dart';
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
        ? visible
            .where((document) =>
                document.status == ExpiryStatus.expired ||
                document.status == ExpiryStatus.critical)
            .toList(growable: false)
        : visible;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alertsOnly ? 'Alerts' : 'Documents'),
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.xs,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).update(value),
                decoration: AppInputStyles.search(
                  context,
                  hint: widget.alertsOnly
                      ? 'Search alerts'
                      : 'Search documents',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).update('');
                          },
                        ),
                ),
              ),
            ),
          ),
          if (!widget.alertsOnly)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.gutter),
                child: VaultStatusFilters(
                  selectedStatus: ref.watch(statusFilterProvider),
                  documents: ref.watch(documentsProvider),
                  selectedProfile: ref.watch(selectedProfileIdProvider),
                ),
              ),
            ),
          if (profiles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  widget.alertsOnly ? 0 : AppSpacing.sm + 4,
                  AppSpacing.gutter,
                  AppSpacing.md,
                ),
                child: VaultProfileSelector(
                  profiles: profiles,
                  selectedProfile: ref.watch(selectedProfileIdProvider),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Text(
                  'Expired, or expiring within 30 days.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.sm + 2,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionLabel(
                widget.alertsOnly ? 'Needs attention' : 'All documents',
                trailing: Text(
                  '${documents.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.alertsOnly
                              ? Icons.notifications_none_rounded
                              : Icons.folder_outlined,
                          size: 24,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.alertsOnly
                            ? 'No active alerts'
                            : 'No documents found',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          widget.alertsOnly
                              ? 'Nothing is expired or expiring soon in this scope.'
                              : 'Try a different search or status.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}
