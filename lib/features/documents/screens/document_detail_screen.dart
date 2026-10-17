import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/utils/expiry_status.dart';
import '../../profiles/providers/profile_providers.dart';
import '../providers/document_providers.dart';
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
    final profile = ref.watch(profilesProvider).where((p) => p.id == document.profileId).firstOrNull;
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
          // Photo viewer placeholder until Week 2.
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(category.icon, size: 72, color: status.color),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              StatusChip(status: status),
              const SizedBox(width: 12),
              Text(
                daysRemainingLabel(document.daysRemaining),
                style: theme.textTheme.titleMedium?.copyWith(color: status.color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoTile(icon: Icons.category_outlined, label: 'Category', value: category.label),
          _InfoTile(icon: Icons.event_busy, label: 'Expires', value: dateFormat.format(document.expiryDate)),
          if (document.issueDate != null)
            _InfoTile(icon: Icons.event_available, label: 'Issued', value: dateFormat.format(document.issueDate!)),
          if (profile != null)
            _InfoTile(icon: Icons.person_outline, label: 'Belongs to', value: profile.name),
          if (document.idNumber != null)
            _InfoTile(icon: Icons.numbers, label: 'ID number', value: document.idNumber!),
          _InfoTile(
            icon: Icons.notifications_outlined,
            label: 'Reminders',
            value: document.remindersEnabled
                ? '${document.reminderDaysBefore.join(', ')} days before'
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
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop(); // leave detail first so it does not rebuild with null
    await ref.read(documentsProvider.notifier).remove(documentId);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}
