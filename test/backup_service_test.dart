import 'dart:io';
import 'dart:typed_data';

import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/profiles/models/profile.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

class _FakeKeyStore implements ImageKeyStore {
  _FakeKeyStore(this._key);
  final Uint8List _key;

  @override
  Future<Uint8List> loadOrCreateKey() async => _key;
}

void main() {
  late Directory tempDir;
  late Box<Document> documentsBox;
  late Box<Profile> profilesBox;
  late Box<AppSettings> settingsBox;
  late SecureImageStore images;
  late BackupService service;

  final testKey =
      Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('doc_vault_backup_');
    Hive.init(p.join(tempDir.path, 'hive'));
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(DocumentAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AppSettingsAdapter());

    documentsBox = await Hive.openBox<Document>('documents');
    profilesBox = await Hive.openBox<Profile>('profiles');
    settingsBox = await Hive.openBox<AppSettings>('settings');

    images = SecureImageStore(
      keyStore: _FakeKeyStore(testKey),
      directoryResolver: () async => Directory(p.join(tempDir.path, 'vault')),
    );
    service = BackupService(
      documentsBox: documentsBox,
      profilesBox: profilesBox,
      settingsBox: settingsBox,
      images: images,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Document makeDoc(String id, {String title = 'Passport', String? image}) =>
      Document(
        id: id,
        title: title,
        category: 'passport',
        idNumber: 'P1234567A',
        issueDate: DateTime(2020, 5, 1),
        expiryDate: DateTime(2030, 11, 3),
        profileId: Profile.selfId,
        imagePaths: image == null ? <String>[] : <String>[image],
        notes: 'Renew at DFA',
        reminderDaysBefore: const [90, 30, 7, 1],
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
        updatedAt: DateTime(2026, 6, 7, 8, 9, 10),
      );

  Future<void> seedVault() async {
    await documentsBox.put('a', makeDoc('a', image: 'photo1.enc'));
    await documentsBox.put('b', makeDoc('b', title: "Driver's License"));
    await profilesBox.put(
      'spouse',
      const Profile(id: 'spouse', name: 'Spouse', avatarEmoji: '❤️'),
    );
    await settingsBox.put(
      AppSettings.storageKey,
      const AppSettings(
        appLockEnabled: true,
        themeMode: AppSettings.themeDark,
        defaultReminderDays: [30, 7],
      ),
    );
    await images.writeEncrypted(
      'photo1.enc',
      Uint8List.fromList([9, 8, 7, 6, 5]),
    );
  }

  group('exportArchive', () {
    test('produces a self-describing encrypted file', () async {
      await seedVault();
      final archive = await service.exportArchive(passphrase: 'super secret passphrase');

      expect(archive.sublist(0, 8), 'DVBACK1\n'.codeUnits);
      expect(archive.length, greaterThan(48));

      // The passphrase and document contents must not be readable in the clear.
      final asText = String.fromCharCodes(
        archive.map((b) => b < 127 && b >= 32 ? b : 46),
      );
      expect(asText, isNot(contains('super secret')));
      expect(asText, isNot(contains('Passport')));
      expect(asText, isNot(contains('photo1.enc')));
    });

    test('different passphrases produce different bytes', () async {
      await seedVault();
      final first = await service.exportArchive(passphrase: 'passphrase-one-long');
      final second = await service.exportArchive(passphrase: 'passphrase-two-long');
      expect(first, isNot(equals(second)));
    });
  });

  group('importArchive', () {
    test('round-trips documents, profiles, settings and photos', () async {
      await seedVault();
      final archive =
          await service.exportArchive(passphrase: 'correct horse battery');

      // Wipe the vault, then restore.
      await documentsBox.clear();
      await profilesBox.clear();
      await settingsBox.clear();
      await images.clearAll();
      expect(documentsBox.isEmpty, isTrue);
      expect(await images.listStored(), isEmpty);

      final summary = await service.importArchive(
        bytes: archive,
        passphrase: 'correct horse battery',
      );

      expect(summary.documents, 2);
      expect(summary.images, 1);

      final restored = documentsBox.get('a')!;
      expect(restored.title, 'Passport');
      expect(restored.idNumber, 'P1234567A');
      expect(restored.expiryDate, DateTime(2030, 11, 3));
      expect(restored.issueDate, DateTime(2020, 5, 1));
      expect(restored.reminderDaysBefore, [90, 30, 7, 1]);
      expect(restored.createdAt, DateTime(2026, 1, 2, 3, 4, 5));
      expect(restored.imagePaths, ['photo1.enc']);
      expect(restored.notes, 'Renew at DFA');

      final spouse = profilesBox.get('spouse')!;
      expect(spouse.name, 'Spouse');
      expect(spouse.avatarEmoji, '❤️');

      final settings = settingsBox.get(AppSettings.storageKey)!;
      expect(settings.themeMode, AppSettings.themeDark);
      expect(settings.appLockEnabled, isTrue);
      expect(settings.defaultReminderDays, [30, 7]);

      expect(await images.listStored(), ['photo1.enc']);
      expect(
        await images.readEncrypted('photo1.enc'),
        Uint8List.fromList([9, 8, 7, 6, 5]),
      );
    });

    test('rejects a wrong passphrase without touching the vault', () async {
      await seedVault();
      final archive = await service.exportArchive(passphrase: 'right-passphrase');

      await expectLater(
        service.importArchive(bytes: archive, passphrase: 'wrong-passphrase'),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('Wrong passphrase'),
          ),
        ),
      );
      expect(documentsBox.length, 2, reason: 'vault must stay untouched');
      expect(await images.listStored(), ['photo1.enc']);
    });

    test('rejects a file that is not a backup', () async {
      await expectLater(
        service.importArchive(
          bytes: Uint8List.fromList(List<int>.filled(80, 7)),
          passphrase: 'whatever',
        ),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('not a Document Vault backup'),
          ),
        ),
      );
    });

    test('rejects a truncated backup', () async {
      await seedVault();
      final archive = await service.exportArchive(passphrase: 'some passphrase');
      final truncated = Uint8List.fromList(archive.sublist(0, 40));

      await expectLater(
        service.importArchive(bytes: truncated, passphrase: 'some passphrase'),
        throwsA(isA<BackupException>()),
      );
    });

    test('guarantees the default "Me" profile exists after restore', () async {
      await seedVault();
      final archive = await service.exportArchive(passphrase: 'some passphrase');

      // A backup from a device whose default profile was somehow removed.
      await profilesBox.clear();
      await profilesBox.put(
        'only',
        const Profile(id: 'only', name: 'Only child'),
      );
      await profilesBox.delete('only');

      await service.importArchive(bytes: archive, passphrase: 'some passphrase');
      // The archive contained profiles (spouse, me) — me comes back with it.
      expect(profilesBox.containsKey(Profile.selfId), isTrue);

      // And even an archive without "me" gets one injected: build one by hand.
      await profilesBox.clear();
      await profilesBox.put(
        'solo',
        const Profile(id: 'solo', name: 'Solo'),
      );
      final minimal = await service.exportArchive(passphrase: 'some passphrase');
      await profilesBox.clear();
      await service.importArchive(bytes: minimal, passphrase: 'some passphrase');
      expect(profilesBox.containsKey(Profile.selfId), isTrue);
      expect(profilesBox.containsKey('solo'), isTrue);
    });
  });
}
