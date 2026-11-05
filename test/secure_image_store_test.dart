import 'dart:io';
import 'dart:typed_data';

import 'package:doc_vault/data/local/secure_image_store.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _FakeKeyStore implements ImageKeyStore {
  _FakeKeyStore(this.key);
  final Uint8List key;

  @override
  Future<Uint8List> loadOrCreateKey() async => key;
}

void main() {
  late Directory tempDir;
  late SecureImageStore store;
  final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('secure_image_store_');
    store = SecureImageStore(
      keyStore: _FakeKeyStore(key),
      directoryResolver: () async => Directory(p.join(tempDir.path, 'vault')),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('versioned GCM encrypt/decrypt round-trip and unique nonce', () async {
    final plain = Uint8List.fromList(List<int>.generate(1024, (i) => i & 255));
    final first = await store.encryptBytes(plain);
    final second = await store.encryptBytes(plain);
    expect(first.sublist(0, 5), <int>[68, 86, 73, 71, 1]);
    expect(first, isNot(second));
    expect(await store.decryptBytes(first), plain);
  });

  test('GCM tampering fails authentication', () async {
    final payload = await store.encryptBytes(Uint8List.fromList([1, 2, 3]));
    payload[payload.length - 1] ^= 1;
    await expectLater(store.decryptBytes(payload), throwsFormatException);
  });

  test('legacy CBC payload remains readable', () async {
    final plain = Uint8List.fromList(List<int>.generate(64, (i) => i));
    final iv = Uint8List.fromList(List<int>.generate(16, (i) => i + 10));
    final legacy = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final encrypted = legacy.encryptBytes(plain, iv: enc.IV(iv));
    expect(await store.decryptBytes(Uint8List.fromList([...iv, ...encrypted.bytes])), plain);
  });

  test('save and load only use encrypted basename', () async {
    final source = File(p.join(tempDir.path, 'source.jpg'));
    final plain = Uint8List.fromList([1, 2, 3, 4]);
    await source.writeAsBytes(plain);
    final name = await store.saveFile(source);
    expect(name.endsWith('.enc'), isTrue);
    expect(await store.load(name), plain);
    await expectLater(store.load('../outside.enc'), throwsArgumentError);
    await expectLater(store.readEncrypted('..\\outside.enc'), throwsArgumentError);
    await expectLater(store.readEncrypted(p.join(tempDir.path, 'outside.enc')), throwsArgumentError);
  });

  test('writeEncrypted rejects traversal and non-enc basename', () async {
    await expectLater(store.writeEncrypted('../outside.enc', Uint8List(0)), throwsArgumentError);
    await expectLater(store.writeEncrypted('photo.jpg', Uint8List(0)), throwsArgumentError);
    await expectLater(store.writeEncrypted('sub\\photo.enc', Uint8List(0)), throwsArgumentError);
  });

  test('truncated payload fails', () async {
    await expectLater(store.decryptBytes(Uint8List.fromList([1, 2, 3])), throwsFormatException);
  });
}
