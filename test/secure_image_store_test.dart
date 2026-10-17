import 'dart:io';
import 'dart:typed_data';

import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _FakeKeyStore implements ImageKeyStore {
  _FakeKeyStore(this._key);
  final Uint8List _key;

  @override
  Future<Uint8List> loadOrCreateKey() async => _key;
}

void main() {
  late Directory tempDir;
  late SecureImageStore store;
  final testKey = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('doc_vault_image_test_');
    store = SecureImageStore(
      keyStore: _FakeKeyStore(testKey),
      directoryResolver: () async => Directory(p.join(tempDir.path, 'vault')),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('encryptBytes and decryptBytes round-trip original image bytes', () async {
    final original = Uint8List.fromList(
      List<int>.generate(1024, (i) => (i * 37) & 0xFF),
    );
    final encrypted = await store.encryptBytes(original);

    expect(encrypted, isNot(equals(original)));
    expect(encrypted.length, greaterThan(original.length));

    final decrypted = await store.decryptBytes(encrypted);
    expect(decrypted, equals(original));
  });

  test('encryptBytes uses a fresh random IV every time', () async {
    final sample = Uint8List.fromList(List<int>.filled(64, 42));
    final first = await store.encryptBytes(sample);
    final second = await store.encryptBytes(sample);

    expect(first, isNot(equals(second)));
    expect(await store.decryptBytes(first), equals(sample));
    expect(await store.decryptBytes(second), equals(sample));
  });

  test('saveFile encrypts to disk, deletes source, and load decrypts', () async {
    final rawBytes = Uint8List.fromList(<int>[137, 80, 78, 71, 1, 2, 3, 4, 5]);
    final sourceFile = File(p.join(tempDir.path, 'picked.jpg'));
    await sourceFile.writeAsBytes(rawBytes);

    final storedName = await store.saveFile(sourceFile);
    expect(storedName.endsWith('.enc'), isTrue);
    expect(await sourceFile.exists(), isFalse);

    final vaultFile = File(p.join(tempDir.path, 'vault', storedName));
    expect(await vaultFile.exists(), isTrue);
    final diskBytes = await vaultFile.readAsBytes();
    expect(diskBytes, isNot(equals(rawBytes)));

    final loaded = await store.load(storedName);
    expect(loaded, equals(rawBytes));

    await store.delete(storedName);
    expect(await vaultFile.exists(), isFalse);
  });

  test('decryptBytes throws FormatException on truncated payload', () async {
    expect(
      () => store.decryptBytes(Uint8List.fromList(<int>[1, 2, 3])),
      throwsFormatException,
    );
  });
}
