import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:doc_vault/core/security/passphrase.dart';
import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/profiles/models/profile.dart';
import 'package:doc_vault/features/settings/models/app_settings.dart';
import 'package:doc_vault/features/settings/services/backup_service.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

class _FakeKeyStore implements ImageKeyStore {
  _FakeKeyStore(this._key);
  final Uint8List _key;

  @override
  Future<Uint8List> loadOrCreateKey() async => _key;
}

final class _FailingPhotoWrites extends IOOverrides {
  @override
  File createFile(String path) {
    final file = super.createFile(path);
    return p.basename(path) == 'photo2.enc' ? _UnwritablePhoto(file) : file;
  }
}

class _UnwritablePhoto implements File {
  _UnwritablePhoto(this.file);
  final File file;

  @override
  String get path => file.path;

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    // Leave a partial file, as a full disk can do, before reporting failure.
    await file.writeAsBytes(bytes.take(5).toList(), mode: mode, flush: flush);
    throw FileSystemException('Simulated disk full', file.path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingSettingsBox implements Box<AppSettings> {
  _FailingSettingsBox(this.box);
  final Box<AppSettings> box;
  var failNextPut = true;

  @override
  Map<dynamic, AppSettings> toMap() => box.toMap();

  @override
  Future<int> clear() => box.clear();

  @override
  Future<void> put(dynamic key, AppSettings value) async {
    if (failNextPut) {
      failNextPut = false;
      throw const FileSystemException('Simulated metadata write failure');
    }
    await box.put(key, value);
  }

  @override
  Future<void> putAll(Map<dynamic, AppSettings> entries) => box.putAll(entries);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;
  late Box<Document> documentsBox;
  late Box<Profile> profilesBox;
  late Box<AppSettings> settingsBox;
  late SecureImageStore images;
  late BackupService service;

  final testKey = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  final photoBytes = Uint8List.fromList(
    'private photo bytes that must survive a device change'.codeUnits,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('doc_vault_backup_');
    Hive.init(p.join(tempDir.path, 'hive'));
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

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
      await images.encryptBytes(photoBytes),
    );
  }

  // Build pre-fix archives independently, so compatibility tests do not rely
  // on the current exporter to reproduce the old photo representation.
  Future<Uint8List> makeLegacyArchive({
    int version = 1,
    String? imageName,
  }) async {
    final payload = BytesBuilder();
    void writeChunk(List<int> bytes) {
      payload
          .add((ByteData(4)..setUint32(0, bytes.length)).buffer.asUint8List());
      payload.add(bytes);
    }

    writeChunk(utf8.encode(jsonEncode({
      'version': version,
      'documents': documentsBox.values.map((d) {
        final map = d.toMap();
        if (imageName != null && d.imagePaths.isNotEmpty) {
          map['imagePaths'] = [imageName];
        }
        return map;
      }).toList(),
      'profiles': profilesBox.values.map((p) => p.toMap()).toList(),
      'settings': const AppSettings().toMap(),
    })));
    final names = await images.listStored();
    payload.add((ByteData(4)..setUint32(0, names.length)).buffer.asUint8List());
    for (final name in names) {
      writeChunk(utf8.encode(imageName ?? name));
      writeChunk(await images.readEncrypted(name));
    }
    final salt = Uint8List.fromList(List<int>.filled(16, 17));
    final iv = enc.IV(Uint8List.fromList(List<int>.filled(16, 23)));
    final encrypted = enc.Encrypter(enc.AES(
      enc.Key(deriveKey('legacy passphrase', salt)),
      mode: enc.AESMode.cbc,
    )).encryptBytes(payload.toBytes(), iv: iv);
    return (BytesBuilder()
          ..add(utf8.encode('DVBACK1\n'))
          ..add(salt)
          ..add(iv.bytes)
          ..add((ByteData(4)..setUint32(0, encrypted.bytes.length))
              .buffer
              .asUint8List())
          ..add(encrypted.bytes))
        .toBytes();
  }

  group('exportArchive', () {
    test('produces a self-describing encrypted file', () async {
      await seedVault();
      final archive =
          await service.exportArchive(passphrase: 'super secret passphrase');

      expect(archive.sublist(0, 8), 'DVBACK2\n'.codeUnits);
      expect(archive.length, greaterThan(48));

      // The passphrase and document contents must not be readable in the clear.
      final asText = String.fromCharCodes(
        archive.map((b) => b < 127 && b >= 32 ? b : 46),
      );
      expect(asText, isNot(contains('super secret')));
      expect(asText, isNot(contains('Passport')));
      expect(asText, isNot(contains('photo1.enc')));
      expect(asText, isNot(contains(String.fromCharCodes(photoBytes))));

      // Only the backup passphrase, not the source image key, is needed to
      // recover photo plaintext from the encrypted payload.
      final payload = Uint8List.fromList(enc.Encrypter(enc.AES(
        enc.Key(deriveKey('super secret passphrase', archive.sublist(8, 24))),
        mode: enc.AESMode.cbc,
      )).decryptBytes(
        enc.Encrypted(archive.sublist(44)),
        iv: enc.IV(archive.sublist(24, 40)),
      ));
      final jsonLength = ByteData.sublistView(payload).getUint32(0);
      final metadata =
          jsonDecode(utf8.decode(payload.sublist(4, 4 + jsonLength)))
              as Map<String, dynamic>;
      expect(metadata['version'], 2);
      expect(String.fromCharCodes(payload),
          contains(String.fromCharCodes(photoBytes)));
    });

    test('different passphrases produce different bytes', () async {
      await seedVault();
      final first =
          await service.exportArchive(passphrase: 'passphrase-one-long');
      final second =
          await service.exportArchive(passphrase: 'passphrase-two-long');
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
      expect(await images.load('photo1.enc'), photoBytes);
    });

    test('rejects a non-enc photo name without modifying the vault', () async {
      await seedVault();
      final before = await images.readEncrypted('photo1.enc');
      final archive = await makeLegacyArchive(imageName: 'photo.jpg');

      await expectLater(
        service.importArchive(bytes: archive, passphrase: 'legacy passphrase'),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('Invalid image filename'),
        )),
      );

      expect(await images.readEncrypted('photo1.enc'), before);
      expect(documentsBox.get('a')!.imagePaths, ['photo1.enc']);
      expect(profilesBox.containsKey('spouse'), isTrue);
      expect(settingsBox.get(AppSettings.storageKey)!.appLockEnabled, isTrue);
    });

    test('partial photo write leaves existing vault untouched', () async {
      await seedVault();
      await images.writeEncrypted(
        'photo2.enc',
        await images.encryptBytes(photoBytes),
      );
      final archive = await service.exportArchive(passphrase: 'restore test');
      final existingBytes = Uint8List.fromList([2, 4, 6, 8]);
      await images.writeEncrypted(
        'photo1.enc',
        await images.encryptBytes(existingBytes),
      );
      await images.delete('photo2.enc');
      await documentsBox.put('keep', makeDoc('keep', image: 'photo1.enc'));
      final before = await images.readEncrypted('photo1.enc');

      await IOOverrides.runWithIOOverrides(() async {
        await expectLater(
          service.importArchive(bytes: archive, passphrase: 'restore test'),
          throwsA(isA<BackupException>()),
        );
      }, _FailingPhotoWrites());

      expect(await images.readEncrypted('photo1.enc'), before);
      expect(await images.load('photo1.enc'), existingBytes);
      expect(await images.listStored(), ['photo1.enc']);
      expect(documentsBox.containsKey('keep'), isTrue);
      expect(profilesBox.containsKey('spouse'), isTrue);
      expect(settingsBox.get(AppSettings.storageKey)!.appLockEnabled, isTrue);
      expect(
        (await tempDir.list().toList()).map((entry) => p.basename(entry.path)),
        unorderedEquals(['hive', 'vault']),
        reason: 'failed staging must be cleaned up',
      );
    });

    test('metadata failure rolls back photos and all boxes', () async {
      await seedVault();
      final archive = await service.exportArchive(passphrase: 'restore test');
      await documentsBox.put('keep', makeDoc('keep'));
      await images.writeEncrypted(
        'photo1.enc',
        await images.encryptBytes(Uint8List.fromList([7, 7, 7])),
      );
      final before = await images.readEncrypted('photo1.enc');
      final failingService = BackupService(
        documentsBox: documentsBox,
        profilesBox: profilesBox,
        settingsBox: _FailingSettingsBox(settingsBox),
        images: images,
      );

      await expectLater(
        failingService.importArchive(
            bytes: archive, passphrase: 'restore test'),
        throwsA(isA<BackupException>()),
      );

      expect(await images.readEncrypted('photo1.enc'), before);
      expect(documentsBox.containsKey('keep'), isTrue);
      expect(profilesBox.keys, ['spouse']);
      expect(settingsBox.get(AppSettings.storageKey)!.appLockEnabled, isTrue);
      expect(
        (await tempDir.list().toList()).map((entry) => p.basename(entry.path)),
        unorderedEquals(['hive', 'vault']),
      );
    });

    test('successful restore replaces old photos and removes staging',
        () async {
      await seedVault();
      final archive = await service.exportArchive(passphrase: 'restore test');
      await images.writeEncrypted(
        'obsolete.enc',
        await images.encryptBytes(photoBytes),
      );

      await service.importArchive(bytes: archive, passphrase: 'restore test');

      expect(await images.listStored(), ['photo1.enc']);
      expect(await images.load('photo1.enc'), photoBytes);
      expect(
        (await tempDir.list().toList()).map((entry) => p.basename(entry.path)),
        unorderedEquals(['hive', 'vault']),
      );
    });

    test('restores photos using a different device key', () async {
      await seedVault();
      final sourceCiphertext = await images.readEncrypted('photo1.enc');
      final archive =
          await service.exportArchive(passphrase: 'cross-device passphrase');
      final destination = SecureImageStore(
        keyStore: _FakeKeyStore(Uint8List.fromList(
          List<int>.generate(32, (i) => 255 - i),
        )),
        directoryResolver: () async =>
            Directory(p.join(tempDir.path, 'destination_vault')),
      );
      final destinationService = BackupService(
        documentsBox: documentsBox,
        profilesBox: profilesBox,
        settingsBox: settingsBox,
        images: destination,
      );

      // Simulate loss of the source vault after export (new device/reinstall).
      await images.clearAll();
      await documentsBox.clear();
      await profilesBox.clear();
      await settingsBox.clear();
      final summary = await destinationService.importArchive(
        bytes: archive,
        passphrase: 'cross-device passphrase',
      );

      expect(summary.images, 1);
      expect(documentsBox.get('a')!.imagePaths, ['photo1.enc']);
      expect(await destination.load('photo1.enc'), photoBytes);
      final restoredCiphertext = await destination.readEncrypted('photo1.enc');
      expect(restoredCiphertext, isNot(equals(sourceCiphertext)));
      await expectLater(
        images.decryptBytes(restoredCiphertext),
        throwsA(isA<FormatException>()),
      );
    });

    test('restores legacy photos with the original device key', () async {
      await seedVault();
      final archive = await makeLegacyArchive();
      await images.clearAll();
      await documentsBox.clear();

      await service.importArchive(
        bytes: archive,
        passphrase: 'legacy passphrase',
      );

      expect(documentsBox.get('a')!.imagePaths, ['photo1.enc']);
      expect(await images.load('photo1.enc'), photoBytes);
    });

    test('rejects legacy photos with a different key before changing the vault',
        () async {
      await seedVault();
      final archive = await makeLegacyArchive();
      final destination = SecureImageStore(
        keyStore: _FakeKeyStore(Uint8List(32)),
        directoryResolver: () async =>
            Directory(p.join(tempDir.path, 'destination_vault')),
      );
      await destination.writeEncrypted(
        'existing.enc',
        await destination.encryptBytes(photoBytes),
      );
      final destinationService = BackupService(
        documentsBox: documentsBox,
        profilesBox: profilesBox,
        settingsBox: settingsBox,
        images: destination,
      );
      await documentsBox.put('keep', makeDoc('keep'));

      await expectLater(
        destinationService.importArchive(
          bytes: archive,
          passphrase: 'legacy passphrase',
        ),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('original device key'),
        )),
      );

      expect(documentsBox.containsKey('keep'), isTrue);
      expect(profilesBox.containsKey('spouse'), isTrue);
      expect(settingsBox.get(AppSettings.storageKey)!.appLockEnabled, isTrue);
      expect(await destination.listStored(), ['existing.enc']);
      expect(await destination.load('existing.enc'), photoBytes);
    });

    test('restores legacy backups without photos on another device', () async {
      await documentsBox.put('a', makeDoc('a'));
      final archive = await makeLegacyArchive();
      await documentsBox.clear();

      final summary = await service.importArchive(
        bytes: archive,
        passphrase: 'legacy passphrase',
      );

      expect(summary.images, 0);
      expect(documentsBox.get('a')!.title, 'Passport');
    });

    test('rejects unknown versions before changing the vault', () async {
      await seedVault();
      final archive = await makeLegacyArchive(version: 99);

      await expectLater(
        service.importArchive(bytes: archive, passphrase: 'legacy passphrase'),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported backup version'),
        )),
      );

      expect(documentsBox.length, 2);
      expect(await images.load('photo1.enc'), photoBytes);
    });

    test('rejects a wrong passphrase without touching the vault', () async {
      await seedVault();
      final archive =
          await service.exportArchive(passphrase: 'right-passphrase');

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
      final archive =
          await service.exportArchive(passphrase: 'some passphrase');
      final truncated = Uint8List.fromList(archive.sublist(0, 40));

      await expectLater(
        service.importArchive(bytes: truncated, passphrase: 'some passphrase'),
        throwsA(isA<BackupException>()),
      );
    });

    test('guarantees the default "Me" profile exists after restore', () async {
      await seedVault();
      final archive =
          await service.exportArchive(passphrase: 'some passphrase');

      // A backup from a device whose default profile was somehow removed.
      await profilesBox.clear();
      await profilesBox.put(
        'only',
        const Profile(id: 'only', name: 'Only child'),
      );
      await profilesBox.delete('only');

      await service.importArchive(
          bytes: archive, passphrase: 'some passphrase');
      // The archive contained profiles (spouse, me) — me comes back with it.
      expect(profilesBox.containsKey(Profile.selfId), isTrue);

      // And even an archive without "me" gets one injected: build one by hand.
      await profilesBox.clear();
      await profilesBox.put(
        'solo',
        const Profile(id: 'solo', name: 'Solo'),
      );
      final minimal =
          await service.exportArchive(passphrase: 'some passphrase');
      await profilesBox.clear();
      await service.importArchive(
          bytes: minimal, passphrase: 'some passphrase');
      expect(profilesBox.containsKey(Profile.selfId), isTrue);
      expect(profilesBox.containsKey('solo'), isTrue);
    });

    test('rejects backup where document references missing profile', () async {
      // Create a document with a nonexistent profileId, export it.
      await documentsBox.clear();
      await documentsBox.put(
        'orphan',
        Document(
          id: 'orphan',
          title: 'Orphan',
          category: 'passport',
          expiryDate: DateTime(2030, 1, 1),
          profileId: 'nonexistent',
        ),
      );
      final archive = await service.exportArchive(passphrase: 'test');

      await documentsBox.clear();
      await profilesBox.clear();
      await expectLater(
        service.importArchive(bytes: archive, passphrase: 'test'),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('Invalid document or profile relationships'),
          ),
        ),
      );
    });

    test('rejects backup with missing image referenced by document', () async {
      await documentsBox.clear();
      await documentsBox.put(
        'doc',
        Document(
          id: 'doc',
          title: 'Doc',
          category: 'passport',
          expiryDate: DateTime(2030, 1, 1),
          profileId: Profile.selfId,
          imagePaths: const ['missing.enc'],
        ),
      );
      final archive = await service.exportArchive(passphrase: 'test');

      await documentsBox.clear();
      await images.clearAll();
      await expectLater(
        service.importArchive(bytes: archive, passphrase: 'test'),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('Document references missing image'),
          ),
        ),
      );
    });
  });
}
