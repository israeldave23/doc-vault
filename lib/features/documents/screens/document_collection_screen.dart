import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/premium_components.dart'
    show
        PremiumSearchBar,
        VaultProfileSelector,
        VaultStatusFilters;
import '../../../core/utils/expiry_status.dart';
import '../providers/document_providers.dart';
import '../../profiles/providers/profile_providers.dart';
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
    ref.listen(searchQueryProvider, (_, value) {
      if (_searchController.text != value) _searchController.text = value;
    });
    final visible = ref.watch(visibleDocumentsProvider);
    final documents = widget.alertsOnly
        ? visible.where((document) =>
            document.status == ExpiryStatus.expired ||
            document.status == ExpiryStatus.critical).toList(growable: false)
        : visible;
    return Scaffold(
      headers: [
        AppBar(
          title: Text(widget.alertsOnly ? 'Alerts' : 'All Documents'),
        ),
      ],
      child: CustomScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
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
                onChanged: (value) => ref
                    .read(searchQueryProvider.notifier)
                    .update(value),
                onClear: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).update('');
                },
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
                profiles: ref.watch(profilesProvider),
                selectedProfile: ref.watch(selectedProfileIdProvider),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: VaultStatusFilters(
                selectedStatus: ref.watch(statusFilterProvider),
                documents: ref.watch(documentsProvider),
                selectedProfile: ref.watch(selectedProfileIdProvider),
              ),
            ),
          ),
          if (documents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                topIcon: widget.alertsOnly
                    ? LucideIcons.bell
                    : LucideIcons.folderOpen,
                title: widget.alertsOnly ? 'No active alerts' : 'No documents found',
                message: widget.alertsOnly
                    ? 'No expired or expiring-soon documents match your filters.'
                    : 'Try a different search.',
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
                      ShadcnPageRoute<void>(
                        builder: (_) => DocumentDetailScreen(
                          documentId: document.id,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.topIcon,
    required this.title,
    required this.message,
  });

  final IconData topIcon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(topIcon, size: 64, color: theme.colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: theme.typography.large),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
