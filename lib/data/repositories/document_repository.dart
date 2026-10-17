import 'package:hive_ce/hive.dart';

import '../../features/documents/models/document.dart';

/// Thin wrapper around the Hive box so the rest of the app never touches
/// Hive directly. Swapping storage later means changing only this file.
class DocumentRepository {
  DocumentRepository(this._box);

  final Box<Document> _box;

  List<Document> getAll() => _box.values.toList(growable: false);

  Document? getById(String id) => _box.get(id);

  Future<void> upsert(Document document) => _box.put(document.id, document);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> deleteAllForProfile(String profileId) async {
    final ids = _box.values
        .where((d) => d.profileId == profileId)
        .map((d) => d.id)
        .toList();
    await _box.deleteAll(ids);
  }
}
