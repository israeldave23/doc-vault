import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:uuid/uuid.dart';

abstract class ImageKeyStore {
  Future<Uint8List> loadOrCreateKey();
}

class SecureStorageImageKeyStore implements ImageKeyStore {
  const SecureStorageImageKeyStore([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  static const _keyName = 'doc_vault_image_aes_key';
  final FlutterSecureStorage _storage;

  @override
  Future<Uint8List> loadOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return Uint8List.fromList(base64Url.decode(existing));
    }
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _keyName, value: base64Url.encode(bytes));
    return bytes;
  }
}

class SecureImageStore {
  SecureImageStore({
    ImageKeyStore? keyStore,
    Future<Directory> Function()? directoryResolver,
  })  : _keyStore = keyStore ?? const SecureStorageImageKeyStore(),
        _directoryResolver = directoryResolver ?? _defaultVaultDirectory;

  static const int _ivLength = 12;
  static const int _tagLength = 16;
  static const String _magic = 'DVIG';
  static const int _version = 1;

  final ImageKeyStore _keyStore;
  final Future<Directory> Function() _directoryResolver;
  Uint8List? _cachedKey;

  static Future<Directory> _defaultVaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'encrypted_photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Uint8List> _key() async => _cachedKey ??= await _keyStore.loadOrCreateKey();

  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    final key = await _key();
    final nonce = Uint8List.fromList(List<int>.generate(12, (_) => Random.secure().nextInt(256)));
    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(true, pc.AEADParameters(pc.KeyParameter(key), _tagLength * 8, nonce, Uint8List(0)));
    final encrypted = cipher.process(plainBytes);
    return Uint8List.fromList(<int>[
      ...ascii.encode(_magic), _version, ...nonce, ...encrypted,
    ]);
  }

  Future<Uint8List> decryptBytes(Uint8List payload) async {
    if (payload.length >= 5 && ascii.decode(payload.sublist(0, 4), allowInvalid: true) == _magic) {
      if (payload[4] != _version || payload.length < 5 + _ivLength + _tagLength) {
        throw const FormatException('Encrypted image payload is truncated or unsupported.');
      }
      final key = await _key();
      final nonce = Uint8List.sublistView(payload, 5, 5 + _ivLength);
      final cipher = pc.GCMBlockCipher(pc.AESEngine())
        ..init(false, pc.AEADParameters(pc.KeyParameter(key), _tagLength * 8, nonce, Uint8List(0)));
      try {
        return Uint8List.fromList(cipher.process(Uint8List.sublistView(payload, 5 + _ivLength)));
      } on pc.InvalidCipherTextException {
        throw const FormatException('Encrypted image authentication failed.');
      }
    }
    if (payload.length <= 16) throw const FormatException('Encrypted image payload is truncated.');
    final key = await _key();
    final legacy = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    try {
      return Uint8List.fromList(legacy.decryptBytes(enc.Encrypted(Uint8List.sublistView(payload, 16)), iv: enc.IV(Uint8List.sublistView(payload, 0, 16))));
    } on Exception {
      throw const FormatException('Invalid legacy encrypted image payload.');
    }
  }

  Future<String> saveFile(File sourceFile, {bool deleteSource = true}) async {
    final encryptedPayload = await encryptBytes(await sourceFile.readAsBytes());
    final dir = await _directoryResolver();
    if (!await dir.exists()) await dir.create(recursive: true);
    final fileName = '${const Uuid().v4()}.enc';
    await File(p.join(dir.path, fileName)).writeAsBytes(encryptedPayload, flush: true);
    if (deleteSource) {
      try { if (await sourceFile.exists()) await sourceFile.delete(); } catch (_) {}
    }
    return fileName;
  }

  Future<Uint8List> load(String storedPath) async => decryptBytes(await (await _resolveFile(storedPath)).readAsBytes());

  Future<void> delete(String storedPath) async {
    try { final file = await _resolveFile(storedPath); if (await file.exists()) await file.delete(); } catch (_) {}
  }

  Future<void> deleteAll(Iterable<String> storedPaths) async {
    for (final path in storedPaths) { await delete(path); }
  }

  Future<File> _resolveFile(String storedPath) async {
    if (storedPath.isEmpty || storedPath.contains('/') || storedPath.contains('\\') ||
        p.isAbsolute(storedPath) || p.basename(storedPath) != storedPath ||
        !storedPath.endsWith('.enc')) {
      throw ArgumentError.value(storedPath, 'storedPath', 'Expected .enc basename only');
    }
    final dir = await _directoryResolver();
    final file = File(p.join(dir.path, storedPath));
    try {
      if (await Link(file.path).exists()) {
        throw ArgumentError.value(storedPath, 'storedPath', 'Symlinks not allowed');
      }
    } catch (e) {
      if (e is ArgumentError) rethrow;
    }
    return file;
  }

  Future<List<String>> listStored() async {
    final dir = await _directoryResolver();
    if (!await dir.exists()) return const <String>[];
    return (await dir.list(followLinks: false).toList())
        .cast<File>().map((entry) => p.basename(entry.path))
        .where((name) => name.endsWith('.enc')).toList();
  }

  Future<Uint8List> readEncrypted(String storedPath) async {
    final file = await _resolveFile(storedPath);
    if (!await file.exists()) throw FileSystemException('Encrypted image is missing', storedPath);
    return file.readAsBytes();
  }

  Future<void> writeEncrypted(String storedPath, Uint8List payload) async {
    final dir = await _directoryResolver();
    if (!await dir.exists()) await dir.create(recursive: true);
    await (await _resolveFile(storedPath)).writeAsBytes(payload, flush: true);
  }

  Future<void> clearAll() async {
    final dir = await _directoryResolver();
    if (!await dir.exists()) return;
    for (final name in await listStored()) { await delete(name); }
  }
}
