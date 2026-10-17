import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../data/local/hive_service.dart';
import '../../../data/repositories/document_repository.dart';
import '../../profiles/providers/profile_providers.dart';
import '../models/document.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(Hive.box<Document>(HiveService.documentsBox));
});

/// All documents, soonest expiry first.
final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<Document>>(DocumentsNotifier.new);

class DocumentsNotifier extends Notifier<List<Document>> {
  @override
  List<Document> build() => _sorted(ref.watch(documentRepositoryProvider).getAll());

  Future<void> upsert(Document document) async {
    await ref.read(documentRepositoryProvider).upsert(document);
    _reload();
  }

  Future<void> remove(String id) async {
    await ref.read(documentRepositoryProvider).delete(id);
    _reload();
  }

  void _reload() => state = _sorted(ref.read(documentRepositoryProvider).getAll());

  static List<Document> _sorted(List<Document> docs) {
    final copy = List<Document>.of(docs);
    copy.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return copy;
  }
}

/// Documents filtered by the selected profile and the search query.
final visibleDocumentsProvider = Provider<List<Document>>((ref) {
  final all = ref.watch(documentsProvider);
  final profileId = ref.watch(selectedProfileIdProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return all.where((d) {
    final matchesProfile = profileId == null || d.profileId == profileId;
    final matchesQuery = query.isEmpty ||
        d.title.toLowerCase().contains(query) ||
        d.category.toLowerCase().contains(query) ||
        (d.notes?.toLowerCase().contains(query) ?? false);
    return matchesProfile && matchesQuery;
  }).toList(growable: false);
});

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

/// Single document lookup for the detail screen; re-evaluates on edits.
final documentByIdProvider = Provider.family<Document?, String>((ref, id) {
  final docs = ref.watch(documentsProvider);
  for (final d in docs) {
    if (d.id == id) return d;
  }
  return null;
});
