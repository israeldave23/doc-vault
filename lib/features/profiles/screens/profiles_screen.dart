import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/providers/document_providers.dart';
import '../../pro/models/free_tier.dart';
import '../../pro/widgets/free_tier_gate.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/profile.dart';
import '../providers/profile_providers.dart';

/// Manage the people whose documents are tracked (Me, Spouse, Child, ...).
/// Deleting a person moves their documents to "Me" so nothing is ever orphaned.
class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: profiles.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final count = documents.where((d) => d.profileId == profile.id).length;
          final isDefault = profile.id == Profile.selfId;

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                profile.avatarEmoji ??
                    (profile.name.isEmpty ? '?' : profile.name.substring(0, 1)),
              ),
            ),
            title: Text(profile.name),
            subtitle: Text(count == 1 ? '1 document' : '$count documents'),
            trailing: PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (action) async {
                switch (action) {
                  case 'rename':
                    await _showProfileDialog(
                      context: context,
                      ref: ref,
                      existing: profile,
                    );
                  case 'delete':
                    await _confirmDelete(
                      context: context,
                      ref: ref,
                      profile: profile,
                      documentCount: count,
                    );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                if (!isDefault)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () => _showProfileDialog(context: context, ref: ref, existing: profile),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProfileDialog(context: context, ref: ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add person'),
      ),
    );
  }

  Future<void> _showProfileDialog({
    required BuildContext context,
    required WidgetRef ref,
    Profile? existing,
  }) async {
    if (existing == null) {
      final isPro = ref.read(settingsProvider).isPro;
      final count = ref.read(profilesProvider).length;
      final withinLimit = await ensureWithinFreeTier(
        context,
        allowed: isPro || count < FreeTier.maxProfiles,
        message: FreeTier.profileLimitMessage(count),
      );
      if (!withinLimit || !context.mounted) return;
    }
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emojiController = TextEditingController(text: existing?.avatarEmoji ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add person' : 'Edit person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Spouse, Child, Parent...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Emoji (optional)',
                hintText: '🙂',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    final emoji = emojiController.text.trim();
    nameController.dispose();
    emojiController.dispose();

    if (saved != true || name.isEmpty || !context.mounted) return;

    final notifier = ref.read(profilesProvider.notifier);
    if (existing == null) {
      await notifier.add(name, avatarEmoji: emoji.isEmpty ? null : emoji);
    } else {
      await notifier.rename(existing.id, name);
      if (emoji != (existing.avatarEmoji ?? '')) {
        await notifier.setAvatar(existing.id, emoji.isEmpty ? null : emoji);
      }
    }
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required WidgetRef ref,
    required Profile profile,
    required int documentCount,
  }) async {
    final message = documentCount == 0
        ? 'Delete ${profile.name}?'
        : documentCount == 1
            ? 'Delete ${profile.name}? Their 1 document moves to Me.'
            : 'Delete ${profile.name}? Their $documentCount documents move to Me.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete person'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(documentsProvider.notifier)
        .reassignProfile(profile.id, Profile.selfId);
    await ref.read(profilesProvider.notifier).remove(profile.id);

    // Clear the dashboard filter if it pointed at the deleted person.
    if (ref.read(selectedProfileIdProvider) == profile.id) {
      ref.read(selectedProfileIdProvider.notifier).select(null);
    }
  }
}
