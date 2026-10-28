import 'package:flutter/material.dart';
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
      return const Scaffold(body: SizedBox.shrink());
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
      appBar: AppBar(
        title: Text(document.title),
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
        ],
      ),
      body: ListView(
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
          Row(
            children: [
              StatusChip(status: status),
              const SizedBox(width: 12),
              Text(
                daysRemainingLabel(document.daysRemaining),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoTile(
            icon: Icons.category_outlined,
            label: 'Category',
            value: category.label,
          ),
          _InfoTile(
            icon: Icons.event_busy,
            label: 'Expires',
            value: dateFormat.format(document.expiryDate),
          ),
          if (document.issueDate != null)
            _InfoTile(
              icon: Icons.event_available,
              label: 'Issued',
              value: dateFormat.format(document.issueDate!),
            ),
          if (profile != null)
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Belongs to',
              value: profile.name,
            ),
          if (document.idNumber != null)
            _InfoTile(
              icon: Icons.numbers,
              label: 'ID number',
              value: document.idNumber!,
            ),
          _InfoTile(
            icon: Icons.notifications_outlined,
            label: 'Reminders',
            value: document.remindersEnabled
                ? '${document.reminderDaysBefore.map((d) => d == 1 ? '1 day' : '$d days').join(', ')} before expiry'
                : 'Off',
          ),
          if (document.notes != null && document.notes!.isNotEmpty)
            _InfoTile(icon: Icons.notes, label: 'Notes', value: document.notes!),
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
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EncryptedPhotoViewerScreen(
                      title: widget.title,
                      imagePaths: paths,
                      initialIndex: index,
                    ),
                  ),
                ),
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
                              Icons.lock_outline,
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
                        : Theme.of(context).colorScheme.outlineVariant,
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}
