import 'package:hive_ce/hive.dart';

import '../../features/profiles/models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._box);

  final Box<Profile> _box;

  List<Profile> getAll() => _box.values.toList(growable: false);

  Profile? getById(String id) => _box.get(id);

  Future<void> upsert(Profile profile) => _box.put(profile.id, profile);

  Future<void> delete(String id) => _box.delete(id);
}
