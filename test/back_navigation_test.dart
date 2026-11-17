import 'dart:typed_data';

import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/documents/providers/document_providers.dart';
import 'package:doc_vault/features/documents/screens/add_edit_document_screen.dart';
import 'package:doc_vault/features/documents/screens/document_detail_screen.dart';
import 'package:doc_vault/features/documents/widgets/encrypted_image_view.dart';
import 'package:doc_vault/features/pro/screens/paywall_screen.dart';
import 'package:doc_vault/features/pro/services/pro_service.dart';
import 'package:doc_vault/features/profiles/models/profile.dart';
import 'package:doc_vault/features/profiles/providers/profile_providers.dart';
import 'package:doc_vault/features/profiles/screens/profiles_screen.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/providers/settings_provider.dart';
import 'package:doc_vault/features/settings/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

final _document = Document(
  id: 'passport',
  title: 'Passport',
  category: 'passport',
  profileId: Profile.selfId,
  expiryDate: DateTime(2030),
  imagePaths: const ['photo.enc'],
);

class _Documents extends DocumentsNotifier {
  @override
  List<Document> build() => [_document];
}

class _Profiles extends ProfilesNotifier {
  @override
  List<Profile> build() => const [Profile(id: Profile.selfId, name: 'Me')];
}

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _Images extends SecureImageStore {
  final deleted = <String>[];

  @override
  Future<Uint8List> load(String path) async => Uint8List(0);

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

class _Pro implements ProService {
  @override
  Future<void> init() async {}

  @override
  bool get storeAvailable => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final screens = <String, Widget>{
    'add document': const AddEditDocumentScreen(),
    'edit document': AddEditDocumentScreen(existing: _document),
    'document details': const DocumentDetailScreen(documentId: 'passport'),
    'missing document': const DocumentDetailScreen(documentId: 'missing'),
    'photo preview': const EncryptedPhotoViewerScreen(
      title: 'Passport',
      imagePaths: ['photo.enc'],
    ),
    'People': const ProfilesScreen(),
    'Settings': const SettingsScreen(),
    'paywall': const PaywallScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} has accessible back control that pops route',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final images = _Images();
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          documentsProvider.overrideWith(_Documents.new),
          profilesProvider.overrideWith(_Profiles.new),
          settingsProvider.overrideWith(_Settings.new),
          secureImageStoreProvider.overrideWithValue(images),
          proServiceProvider.overrideWithValue(_Pro()),
        ],
        child: ShadcnApp(
          home: Builder(
              builder: (context) => Scaffold(
                    child: Button.primary(
                      onPressed: () => Navigator.of(context).push(
                        ShadcnPageRoute<void>(builder: (_) => entry.value),
                      ),
                      child: const Text('Open screen'),
                    ),
                  )),
        ),
      ));
      await tester.tap(find.text('Open screen'));
      await tester.pumpAndSettle();

      final back = find.bySemanticsLabel('Back');
      expect(back, findsOneWidget);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('Open screen'), findsOneWidget);
      expect(find.byType(entry.value.runtimeType), findsNothing);
      expect(images.deleted, isEmpty);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('root Settings has no back control', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [settingsProvider.overrideWith(_Settings.new)],
      child: const ShadcnApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Back'), findsNothing);
    expect(find.text('Back'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
