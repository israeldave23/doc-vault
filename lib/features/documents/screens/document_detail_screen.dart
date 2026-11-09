import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/utils/expiry_status.dart';
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
      return const Scaffold(child: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final category = DocumentCategory.byKey(document.category);
    final status = document.status;
    final profile = ref
        .watch(profilesProvider)
        .where((p) => p.id == document.profileId)
        .firstOrNull;
    final dateFormat = DateFormat.yMMMMd();

    return Scaffold(
      headers: [
        AppBar(
          title: Text(document.title),
          trailing: [
            IconButton.ghost(
              icon: const Icon(LucideIcons.pencil),
              onPressed: () => Navigator.of(context).push(
                ShadcnPageRoute<void>(
                  builder: (_) => AddEditDocumentScreen(existing: document),
                ),
              ),
            ),
            IconButton.ghost(
              icon: const Icon(LucideIcons.trash2),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (document.imagePaths.isEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category.icon, size: 64, color: status.color),
                  const SizedBox(height: 8),
                  Text(
                    'No photo attached · tap Edit to scan',
                    style: theme.typography.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            )
          else
            _DocumentPhotosCarousel(
              title: document.title,
              imagePaths: document.imagePaths,
            ),
          const SizedBox(height: 20),
          Semantics(
            label:
                '${status.label}. ${daysRemainingLabel(document.daysRemaining)}',
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    StatusChip(status: status),
                    Text(
                      daysRemainingLabel(document.daysRemaining),
                      style: theme.typography.medium.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DetailSection(
            title: 'Document details',
            children: [
              _InfoTile(
                icon: LucideIcons.tags,
                label: 'Category',
                value: category.label,
              ),
              _InfoTile(
                icon: LucideIcons.calendarOff,
                label: 'Expires',
                value: dateFormat.format(document.expiryDate),
              ),
              if (document.issueDate != null)
                _InfoTile(
                  icon: LucideIcons.calendarCheck,
                  label: 'Issued',
                  value: dateFormat.format(document.issueDate!),
                ),
              if (document.idNumber != null)
                _InfoTile(
                  icon: LucideIcons.hash,
                  label: 'ID number',
                  value: document.idNumber!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Ownership & reminders',
            children: [
              if (profile != null)
                _InfoTile(
                  icon: LucideIcons.user,
                  label: 'Belongs to',
                  value:
                      '${profile.avatarEmoji == null ? '' : '${profile.avatarEmoji} '}${profile.name}',
                ),
              _InfoTile(
                icon: document.remindersEnabled
                    ? LucideIcons.bellRing
                    : LucideIcons.bellOff,
                label: 'Reminders',
                value: document.remindersEnabled
                    ? '${document.reminderDaysBefore.map((d) => d == 1 ? '1 day' : '$d days').join(', ')} before expiry'
                    : 'Off',
              ),
            ],
          ),
          if (document.notes != null && document.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'Notes',
              children: [
                _InfoTile(
                  icon: LucideIcons.fileText,
                  label: 'Notes',
                  value: document.notes!,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await const DialogConfiguration().show<bool>(
      context,
      (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text(
          'This removes the document and its encrypted photos from this device.',
        ),
        actions: [
          Button.ghost(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          Button.destructive(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).future;
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await ref.read(documentsProvider.notifier).remove(documentId);
  }
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
    return Column(
      children: [
        SizedBox(
          height: 220,
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
                    ShadcnPageRoute<void>(
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
                          borderRadius: BorderRadius.circular(20),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 const Icon(
                                   LucideIcons.lock,
                                   size: 13,
                                   color: Colors.white,
                                 ),
                                const SizedBox(width: 4),
                                Text(
                                  paths.length > 1
                                      ? '$slot (${index + 1}/${paths.length}) · Tap to zoom'
                                      : 'Encrypted · Tap to zoom',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < paths.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentIndex == i
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.muted,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: theme.typography.medium),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label, $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.typography.xSmall.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: theme.typography.base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
