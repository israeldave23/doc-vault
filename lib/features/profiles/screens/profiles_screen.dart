import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../documents/providers/document_providers.dart';
import '../../pro/models/free_tier.dart';
import '../../pro/widgets/free_tier_gate.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/profile.dart';
import '../providers/profile_providers.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('People'),
          trailing: [
            Button.primary(
              onPressed: () => _showProfileDialog(context: context, ref: ref),
              leading: const Icon(LucideIcons.userPlus),
              child: const Text('Add person'),
            ),
          ],
        ),
      ],
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final count =
              documents.where((d) => d.profileId == profile.id).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Row(
                children: [
                  Expanded(
                    child: Button.ghost(
                      alignment: Alignment.centerLeft,
                      leading: Text(profile.avatarEmoji ??
                          (profile.name.isEmpty
                              ? '?'
                              : profile.name.substring(0, 1))),
                      onPressed: () => _showProfileDialog(
                        context: context,
                        ref: ref,
                        existing: profile,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name),
                          Text(count == 1 ? '1 document' : '$count documents')
                              .small()
                              .muted(),
                        ],
                      ),
                    ),
                  ),
                  if (profile.id != Profile.selfId)
                    Semantics(
                      label: 'Delete ${profile.name}',
                      child: Button.ghost(
                        onPressed: () => _confirmDelete(
                          context: context,
                          ref: ref,
                          profile: profile,
                          documentCount: count,
                        ),
                        child: const Icon(LucideIcons.trash2),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
    final emojiController =
        TextEditingController(text: existing?.avatarEmoji ?? '');
    final saved = await const DialogConfiguration()
        .show<bool>(
          context,
          (ctx) => AlertDialog(
            title: Text(existing == null ? 'Add person' : 'Edit person'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name'),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    placeholder: const Text('Spouse, Child, Parent...'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Emoji (optional)'),
                  TextField(controller: emojiController, maxLength: 2),
                ],
              ),
            ),
            actions: [
              Button.ghost(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              Button.primary(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        )
        .future;
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
    final confirmed = await const DialogConfiguration()
        .show<bool>(
          context,
          (ctx) => AlertDialog(
            title: const Text('Delete person'),
            content: Text(message),
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
        )
        .future;
    if (confirmed != true) return;
    await ref
        .read(documentsProvider.notifier)
        .reassignProfile(profile.id, Profile.selfId);
    await ref.read(profilesProvider.notifier).remove(profile.id);
    if (ref.read(selectedProfileIdProvider) == profile.id) {
      ref.read(selectedProfileIdProvider.notifier).select(null);
    }
  }
}
