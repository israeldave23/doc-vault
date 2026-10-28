import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/constants/categories.dart';
import '../../../core/utils/expiry_status.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/local/secure_image_store.dart';
import '../../../data/repositories/document_repository.dart';
import '../../reminders/services/reminder_service.dart';
import '../../profiles/providers/profile_providers.dart';
import '../models/document.dart';
import '../services/photo_capture_service.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(Hive.box<Document>(HiveService.documentsBox));
});

final secureImageStoreProvider = Provider<SecureImageStore>((ref) {
  return SecureImageStore();
});

final photoCaptureServiceProvider = Provider<PhotoCaptureService>((ref) {
  return PhotoCaptureService(imageStore: ref.watch(secureImageStoreProvider));
});

/// Decrypts an image on demand in memory; auto-disposes when off screen so
/// decrypted bytes do not linger in RAM.
final decryptedImageProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, storedPath) {
  return ref.watch(secureImageStoreProvider).load(storedPath);
});

/// All documents, soonest expiry first.
final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<Document>>(DocumentsNotifier.new);

class DocumentsNotifier extends Notifier<List<Document>> {
  @override
  List<Document> build() =>
      _sorted(ref.watch(documentRepositoryProvider).getAll());

  Future<void> upsert(Document document) async {
    final existing = ref.read(documentRepositoryProvider).getById(document.id);
    if (existing != null) {
      final removedImages = existing.imagePaths
          .where((p) => !document.imagePaths.contains(p))
          .toList();
      if (removedImages.isNotEmpty) {
        await ref.read(secureImageStoreProvider).deleteAll(removedImages);
      }
    }
    await ref.read(documentRepositoryProvider).upsert(document);
    _reload();
    await _resyncReminders();
  }

  /// Moves every document tagged [fromProfileId] to [toProfileId], used when a
  /// profile is deleted so its documents are never orphaned.
  Future<void> reassignProfile(String fromProfileId, String toProfileId) async {
    final repository = ref.read(documentRepositoryProvider);
    final affected = repository
        .getAll()
        .where((d) => d.profileId == fromProfileId)
        .toList(growable: false);
    for (final document in affected) {
      await repository.upsert(document.copyWith(profileId: toProfileId));
    }
    _reload();
    await _resyncReminders();
  }

  Future<void> remove(String id) async {
    final existing = ref.read(documentRepositoryProvider).getById(id);
    if (existing != null && existing.imagePaths.isNotEmpty) {
      await ref.read(secureImageStoreProvider).deleteAll(existing.imagePaths);
    }
    await ref.read(documentRepositoryProvider).delete(id);
    _reload();
    await _resyncReminders();
  }

  /// Rebuilds the pending notifications after any document change so edited
  /// and deleted documents never leave stale reminders behind.
  Future<void> _resyncReminders() => ref
      .read(reminderServiceProvider)
      .syncAll(ref.read(documentRepositoryProvider).getAll());

  void _reload() =>
      state = _sorted(ref.read(documentRepositoryProvider).getAll());

  /// Re-reads from storage — used after a backup restore replaces the box.
  void refresh() => _reload();

  static List<Document> _sorted(List<Document> docs) {
    final copy = List<Document>.of(docs);
    copy.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return copy;
  }
}

/// Documents filtered by the selected profile, status, and search query.
final visibleDocumentsProvider = Provider<List<Document>>((ref) {
  final all = ref.watch(documentsProvider);
  final profileId = ref.watch(selectedProfileIdProvider);
  final status = ref.watch(statusFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return all.where((d) {
    final matchesProfile = profileId == null || d.profileId == profileId;
    final matchesStatus = status == null || d.status == status;
    final matchesQuery = query.isEmpty || _matchesQuery(d, query);
    return matchesProfile && matchesStatus && matchesQuery;
  }).toList(growable: false);
});

/// Matches title, category key *and* its human label, ID number, and notes.
bool _matchesQuery(Document d, String query) {
  final label = DocumentCategory.byKey(d.category).label.toLowerCase();
  return d.title.toLowerCase().contains(query) ||
      label.contains(query) ||
      d.category.toLowerCase().contains(query) ||
      (d.idNumber?.toLowerCase().contains(query) ?? false) ||
      (d.notes?.toLowerCase().contains(query) ?? false);
}

/// Selected status chip on the dashboard; `null` = show everything.
final statusFilterProvider =
    NotifierProvider<StatusFilterNotifier, ExpiryStatus?>(
        StatusFilterNotifier.new);

class StatusFilterNotifier extends Notifier<ExpiryStatus?> {
  @override
  ExpiryStatus? build() => null;

  void select(ExpiryStatus? status) => state = status;
}

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
