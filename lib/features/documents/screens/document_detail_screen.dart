
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/expiry_status.dart';
import '../../../core/widgets/section_label.dart';
import '../../profiles/providers/profile_providers.dart';
import '../providers/document_providers.dart';
import '../widgets/encrypted_image_view.dart';
import '../widgets/status_chip.dart';
import 'add_edit_document_screen.dart';

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(documentByIdProvider(documentId));
    if (document == null) {
      // Deleted while open; go back gracefully.
      return const Scaffold(body: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = DocumentCategory.byKey(document.category);
    final status = document.status;
    final profile = ref
        .watch(profilesProvider)
        .where((p) => p.id == document.profileId)
        .firstOrNull;
    final dateFormat = DateFormat.yMMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddEditDocumentScreen(existing: document),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xl + AppSpacing.md,
        ),
        children: [
          if (document.imagePaths.isEmpty)
            Container(
              height: 156,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    size: 30,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No photo on file',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AddEditDocumentScreen(existing: document),
                      ),
                    ),
                    child: const Text('Add a photo'),
                  ),
                ],
              ),
            )
          else
            _DocumentPhotosCarousel(
              title: document.title,
              imagePaths: document.imagePaths,
            ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label:
                '${status.label}. ${daysRemainingLabel(document.daysRemaining)}',
            child: ExcludeSemantics(
              child: _StatusPanel(
                status: status,
                daysRemaining: document.daysRemaining,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Document'),
          const SizedBox(height: AppSpacing.sm + 2),
          Card(
            child: Column(
              children: [
                _SpecRow(label: 'Category', value: category.label),
                const _SpecDivider(),
                _SpecRow(
                  label: 'Expires',
                  value: dateFormat.format(document.expiryDate),
                ),
                if (document.issueDate != null) ...[
                  const _SpecDivider(),
                  _SpecRow(
                    label: 'Issued',
                    value: dateFormat.format(document.issueDate!),
                  ),
                ],
                if (document.idNumber != null) ...[
                  const _SpecDivider(),
                  _SpecRow(label: 'ID number', value: document.idNumber!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Owner and reminders'),
          const SizedBox(height: AppSpacing.sm + 2),
          Card(
            child: Column(
              children: [
                if (profile != null) ...[
                  _SpecRow(
                    label: 'Belongs to',
                    value:
                        '${profile.avatarEmoji == null ? '' : '${profile.avatarEmoji} '}${profile.name}',
                  ),
                  const _SpecDivider(),
                ],
                _SpecRow(
                  label: 'Reminders',
                  value: document.remindersEnabled
                      ? document.reminderDaysBefore
                          .map((d) => d == 1 ? '1 day' : '$d days')
                          .join(' · ')
                      : 'Off',
                ),
              ],
            ),
          ),
          if (document.notes != null && document.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Notes'),
            const SizedBox(height: AppSpacing.sm + 2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  document.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text(
          'This removes the document and its encrypted photos from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await ref.read(documentsProvider.notifier).remove(documentId);
  }
}

/// Status and countdown in one quiet band.
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.status,
    required this.daysRemaining,
  });

  final ExpiryStatus status;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status.colorFor(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md - 2,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          StatusChip(status: status),
          Text(
            daysRemainingLabel(daysRemaining),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label, $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecDivider extends StatelessWidget {
  const _SpecDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
      );
}

class _DocumentPhotosCarousel extends StatefulWidget {
  const _DocumentPhotosCarousel({
    required this.title,
    required this.imagePaths,
  });

  final String title;
  final List<String> imagePaths;

  @override
  State<_DocumentPhotosCarousel> createState() =>
      _DocumentPhotosCarouselState();
}

class _DocumentPhotosCarouselState extends State<_DocumentPhotosCarousel> {
  static const List<String> _slotLabels = <String>['Front', 'Back', 'Page 3'];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final paths = widget.imagePaths;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            itemCount: paths.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final slot = index < _slotLabels.length
                  ? _slotLabels[index]
                  : 'Page ${index + 1}';
              return Semantics(
                button: true,
                label: '$slot, encrypted photo. Tap to zoom',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EncryptedPhotoViewerScreen(
                        title: widget.title,
                        imagePaths: paths,
                        initialIndex: index,
                      ),
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        EncryptedImageView(
                          storedPath: paths[index],
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC101214),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  paths.length > 1
                                      ? '$slot · ${index + 1}/${paths.length}'
                                      : 'Encrypted · Tap to zoom',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (paths.length > 1) ...[
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < paths.length; i++)
                AnimatedContainer(
                  duration: AppMotion.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == i
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
