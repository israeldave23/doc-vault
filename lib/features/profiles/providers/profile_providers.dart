import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/hive_service.dart';
import '../../../data/repositories/profile_repository.dart';
import '../models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Hive.box<Profile>(HiveService.profilesBox));
});

final profilesProvider =
    NotifierProvider<ProfilesNotifier, List<Profile>>(ProfilesNotifier.new);

class ProfilesNotifier extends Notifier<List<Profile>> {
  @override
  List<Profile> build() => ref.watch(profileRepositoryProvider).getAll();

  Future<void> add(String name, {String? avatarEmoji}) async {
    final profile = Profile(
      id: const Uuid().v4(),
      name: name.trim(),
      avatarEmoji: avatarEmoji,
    );
    await ref.read(profileRepositoryProvider).upsert(profile);
    _reload();
  }

  Future<void> rename(String id, String name) async {
    final existing = ref.read(profileRepositoryProvider).getById(id);
    if (existing == null) return;
    await ref.read(profileRepositoryProvider).upsert(existing.copyWith(name: name.trim()));
    _reload();
  }

  Future<void> setAvatar(String id, String? avatarEmoji) async {
    final existing = ref.read(profileRepositoryProvider).getById(id);
    if (existing == null) return;
    await ref
        .read(profileRepositoryProvider)
        .upsert(existing.copyWith(avatarEmoji: avatarEmoji));
    _reload();
  }

  Future<void> remove(String id) async {
    if (id == Profile.selfId) return; // the default profile cannot be removed
    await ref.read(profileRepositoryProvider).delete(id);
    _reload();
  }

  void _reload() => state = ref.read(profileRepositoryProvider).getAll();

  /// Re-reads from storage — used after a backup restore replaces the box.
  void refresh() => _reload();
}

/// Currently selected profile filter on the dashboard. `null` = everyone.
final selectedProfileIdProvider =
    NotifierProvider<SelectedProfileNotifier, String?>(SelectedProfileNotifier.new);

class SelectedProfileNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}
