import 'dart:async';
import 'dart:typed_data';

import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:doc_vault/data/repositories/document_repository.dart';
import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/documents/providers/document_providers.dart';
import 'package:doc_vault/features/documents/screens/add_edit_document_screen.dart';
import 'package:doc_vault/features/documents/services/photo_capture_service.dart';
import 'package:doc_vault/features/profiles/models/profile.dart';
import 'package:doc_vault/features/profiles/providers/profile_providers.dart';
import 'package:doc_vault/features/reminders/services/reminder_service.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/providers/settings_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_ce/hive.dart';

class _DocumentsNotifier extends DocumentsNotifier {
  _DocumentsNotifier(this.documents, {this.upsertCompleter, this.fail = false});

  final List<Document> documents;
  final Completer<void>? upsertCompleter;
  final bool fail;
  int upsertCalls = 0;

  @override
  List<Document> build() => documents;

  @override
  Future<void> upsert(Document document) async {
    upsertCalls++;
    await upsertCompleter?.future;
    if (fail) throw StateError('upsert failed');
    state = [
      for (final current in state)
        if (current.id != document.id) current,
      document,
    ];
  }
}

class _DocumentBox implements Box<Document> {
  _DocumentBox(Document document) : documents = {document.id: document};
  final Map<String, Document> documents;
  bool failWrites = false;

  @override
  Iterable<Document> get values => documents.values;

  @override
  Document? get(dynamic key, {Document? defaultValue}) =>
      documents[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, Document value) async {
    if (failWrites) throw StateError('persistence failed');
    documents[key as String] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfilesNotifier extends ProfilesNotifier {
  @override
  List<Profile> build() => const [Profile(id: Profile.selfId, name: 'Me')];
}

class _SettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _ImageStore extends SecureImageStore {
  final List<String> deleted = [];

  @override
  Future<void> delete(String storedPath) async => deleted.add(storedPath);

  @override
  Future<void> deleteAll(Iterable<String> storedPaths) async {
    for (final path in storedPaths) {
      await delete(path);
    }
  }

  @override
  Future<Uint8List> load(String storedPath) async => Uint8List(0);
}

class _PhotoCaptureService extends PhotoCaptureService {
  _PhotoCaptureService(SecureImageStore imageStore)
      : super(imageStore: imageStore);

  @override
  Future<PhotoCaptureResult?> pickCropAndSave({
    required ImageSource source,
    Color? toolbarColor,
  }) async =>
      const PhotoCaptureResult(storedPath: 'new.enc');
}

class _ReminderService extends ReminderService {
  _ReminderService({this.failSync = false, this.syncCompleter});
  final bool failSync;
  final Completer<void>? syncCompleter;
  int syncCalls = 0;

  @override
  Future<void> syncAll(Iterable<Document> docs, {DateTime? now}) async {
    syncCalls++;
    await syncCompleter?.future;
    if (failSync) throw StateError('notification scheduling failed');
  }

  @override
  Future<bool> ensurePermission(BuildContext context) async => true;
}

Document _document({List<String> imagePaths = const []}) => Document(
      id: 'document-id',
      title: 'Passport',
      category: 'passport',
      expiryDate: DateTime(2030, 1, 1),
      profileId: Profile.selfId,
      imagePaths: imagePaths,
      remindersEnabled: true,
    );

Future<void> _pumpScreen(
  WidgetTester tester, {
  _DocumentsNotifier? documents,
  DocumentRepository? repository,
  _ReminderService? reminders,
  required _ImageStore imageStore,
  Document? existing,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (documents != null) documentsProvider.overrideWith(() => documents),
        if (repository != null)
          documentRepositoryProvider.overrideWithValue(repository),
        profilesProvider.overrideWith(_ProfilesNotifier.new),
        settingsProvider.overrideWith(_SettingsNotifier.new),
        secureImageStoreProvider.overrideWithValue(imageStore),
        photoCaptureServiceProvider.overrideWithValue(
          _PhotoCaptureService(imageStore),
        ),
        reminderServiceProvider
            .overrideWithValue(reminders ?? _ReminderService()),
      ],
      child: ShadcnApp(
        home: AddEditDocumentScreen(existing: existing),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('failed upsert keeps new photo unsaved and deletes it on exit',
      (tester) async {
    final imageStore = _ImageStore();
    final existing = _document();
    final documents = _DocumentsNotifier([existing], fail: true);
    await _pumpScreen(
      tester,
      documents: documents,
      imageStore: imageStore,
      existing: existing,
    );

    await tester.tap(find.textContaining('Scan or upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Photos (1/3)'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save document. Please try again.'),
        findsOneWidget);
    expect(imageStore.deleted, isEmpty);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(imageStore.deleted, ['new.enc']);
  });

  testWidgets('reminder failure preserves saved photo after closing form',
      (tester) async {
    final existing = _document();
    final box = _DocumentBox(existing);
    final images = _ImageStore();
    final reminders = _ReminderService(failSync: true);
    await _pumpScreen(tester,
        repository: DocumentRepository(box),
        reminders: reminders,
        imageStore: images,
        existing: existing);

    await tester.tap(find.textContaining('Scan or upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(box.documents[existing.id]!.imagePaths, ['new.enc']);
    expect(reminders.syncCalls, 1);
    expect(find.text('Document saved, but reminder setup failed.'),
        findsOneWidget);
    expect(
        find.text('Could not save document. Please try again.'), findsNothing);
    await tester.tap(find.text('Save changes'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(reminders.syncCalls, 1, reason: 'saved form must not save twice');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(images.deleted, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing form during reminder sync preserves persisted photo',
      (tester) async {
    final existing = _document();
    final box = _DocumentBox(existing);
    final images = _ImageStore();
    final completer = Completer<void>();
    final reminders = _ReminderService(syncCompleter: completer);
    await _pumpScreen(tester,
        repository: DocumentRepository(box),
        reminders: reminders,
        imageStore: images,
        existing: existing);

    await tester.tap(find.textContaining('Scan or upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(box.documents[existing.id]!.imagePaths, ['new.enc']);
    expect(reminders.syncCalls, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    completer.complete();
    await tester.pumpAndSettle();
    expect(images.deleted, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('persistence failure preserves old photo and skips reminders',
      (tester) async {
    final existing = _document(imagePaths: ['existing.enc']);
    final box = _DocumentBox(existing)..failWrites = true;
    final images = _ImageStore();
    final reminders = _ReminderService();
    await _pumpScreen(tester,
        repository: DocumentRepository(box),
        reminders: reminders,
        imageStore: images,
        existing: existing);

    await tester.tap(find.bySemanticsLabel('Remove photo'));
    await tester.pump();
    await tester.tap(find.textContaining('Scan or upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save document. Please try again.'),
        findsOneWidget);
    expect(box.documents[existing.id]!.imagePaths, ['existing.enc']);
    expect(images.deleted, isEmpty);
    expect(reminders.syncCalls, 0);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(images.deleted, ['new.enc']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reminder chip updates selected state and summary',
      (tester) async {
    final imageStore = _ImageStore();
    final existing = _document();
    final documents = _DocumentsNotifier([existing]);
    await _pumpScreen(
      tester,
      documents: documents,
      imageStore: imageStore,
      existing: existing,
    );

    final summary = find.textContaining('before expiry');
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(summary, findsOneWidget);
    expect(find.textContaining('90 days, 30 days, 7 days and 1 day'),
        findsOneWidget);

    await tester.tap(find.text('90 days'));
    await tester.pump();

    expect(find.textContaining('30 days, 7 days and 1 day'), findsOneWidget);
    expect(find.text('90 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing ID number and notes removes stored values',
      (tester) async {
    final imageStore = _ImageStore();
    final existing = Document(
      id: 'document-id',
      title: 'Passport',
      category: 'passport',
      idNumber: 'PRIVATE-123',
      expiryDate: DateTime(2030, 1, 1),
      profileId: Profile.selfId,
      notes: 'Private note',
      remindersEnabled: false,
    );
    final documents = _DocumentsNotifier([existing]);
    await _pumpScreen(
      tester,
      documents: documents,
      imageStore: imageStore,
      existing: existing,
    );

    final scrollable = find.byType(ListView).first;
    await tester.drag(scrollable, const Offset(0, -700));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '');
    await tester.enterText(fields.at(1), '');
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(documents.state.single.idNumber, isNull);
    expect(documents.state.single.notes, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving after removing existing photo deletes its file',
      (tester) async {
    final imageStore = _ImageStore();
    final existing = _document(imagePaths: ['existing.enc']);
    final documents = _DocumentsNotifier([existing]);
    await _pumpScreen(
      tester,
      documents: documents,
      imageStore: imageStore,
      existing: existing,
    );

    await tester.tap(find.bySemanticsLabel('Remove photo'));
    await tester.pump();
    expect(imageStore.deleted, isEmpty);

    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(imageStore.deleted, ['existing.enc']);
    expect(documents.state.single.imagePaths, isEmpty);
  });

  testWidgets('cancel after removing existing photo preserves its file',
      (tester) async {
    final imageStore = _ImageStore();
    final existing = _document(imagePaths: ['existing.enc']);
    final documents = _DocumentsNotifier([existing]);
    await _pumpScreen(
      tester,
      documents: documents,
      imageStore: imageStore,
      existing: existing,
    );

    await tester.tap(find.bySemanticsLabel('Remove photo'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(imageStore.deleted, isEmpty);
    expect(documents.documents.single.imagePaths, ['existing.enc']);
  });

  testWidgets('repeated save taps start only one upsert', (tester) async {
    final imageStore = _ImageStore();
    final existing = _document();
    final completer = Completer<void>();
    final documents = _DocumentsNotifier(
      [existing],
      upsertCompleter: completer,
    );
    await _pumpScreen(
      tester,
      documents: documents,
      imageStore: imageStore,
      existing: existing,
    );

    final save = find.text('Save changes');
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();

    expect(documents.upsertCalls, 1);
    expect(
      tester.widget<Button>(find.byType(Button).last).onPressed,
      isNull,
    );

    completer.complete();
    await tester.pumpAndSettle();
    expect(documents.upsertCalls, 1);
  });
}
