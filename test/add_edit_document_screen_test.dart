import 'dart:async';
import 'dart:typed_data';

import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/documents/providers/document_providers.dart';
import 'package:doc_vault/features/documents/screens/add_edit_document_screen.dart';
import 'package:doc_vault/features/documents/services/photo_capture_service.dart';
import 'package:doc_vault/features/profiles/models/profile.dart';
import 'package:doc_vault/features/profiles/providers/profile_providers.dart';
import 'package:doc_vault/features/reminders/services/reminder_service.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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
  }) async => const PhotoCaptureResult(storedPath: 'new.enc');
}

class _ReminderService extends ReminderService {
  @override
  Future<void> syncAll(Iterable<Document> docs, {DateTime? now}) async {}

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
      remindersEnabled: false,
    );

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _DocumentsNotifier documents,
  required _ImageStore imageStore,
  Document? existing,
}) async {
  final container = ProviderContainer(
    overrides: [
      documentsProvider.overrideWith(() => documents),
      profilesProvider.overrideWith(_ProfilesNotifier.new),
      settingsProvider.overrideWith(_SettingsNotifier.new),
      secureImageStoreProvider.overrideWithValue(imageStore),
      photoCaptureServiceProvider.overrideWithValue(
        _PhotoCaptureService(imageStore),
      ),
      reminderServiceProvider.overrideWithValue(_ReminderService()),
    ],
  );
  addTearDown(container.dispose);
  container.read(documentsProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
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
    await tester.scrollUntilVisible(find.text('Save changes'), 300,
        scrollable: find.byType(Scrollable).first);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save document. Please try again.'), findsOneWidget);
    expect(imageStore.deleted, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(imageStore.deleted, ['new.enc']);
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

    await tester.tap(find.byTooltip('Remove photo'));
    await tester.pump();
    expect(imageStore.deleted, isEmpty);
    await tester.scrollUntilVisible(find.text('Save changes'), 300,
        scrollable: find.byType(Scrollable).first);

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

    await tester.tap(find.byTooltip('Remove photo'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(imageStore.deleted, isEmpty);
    expect(documents.state.single.imagePaths, ['existing.enc']);
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
    await tester.scrollUntilVisible(save, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();

    expect(documents.upsertCalls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
    expect(documents.upsertCalls, 1);
  });
}
