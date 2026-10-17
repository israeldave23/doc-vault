import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Reads or persists the 32-byte AES-256 key used to encrypt document images.
abstract class ImageKeyStore {
  Future<Uint8List> loadOrCreateKey();
}

/// Production key store backed by Android Keystore / iOS Keychain.
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

/// Encrypts document photos with AES-256-CBC (PKCS7 padding) and a fresh
/// 16-byte random IV prepended to each file. Plaintext images never sit in the
/// vault folder on disk; decryption happens in memory only when displaying.
class SecureImageStore {
  SecureImageStore({
    ImageKeyStore? keyStore,
    Future<Directory> Function()? directoryResolver,
  })  : _keyStore = keyStore ?? const SecureStorageImageKeyStore(),
        _directoryResolver = directoryResolver ?? _defaultVaultDirectory;

  static const int _ivLength = 16;
  static const String _subDir = 'encrypted_photos';

  final ImageKeyStore _keyStore;
  final Future<Directory> Function() _directoryResolver;
  Uint8List? _cachedKey;

  static Future<Directory> _defaultVaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<enc.Encrypter> _encrypter() async {
    _cachedKey ??= await _keyStore.loadOrCreateKey();
    return enc.Encrypter(enc.AES(enc.Key(_cachedKey!), mode: enc.AESMode.cbc));
  }

  /// Pure byte-level encryption helper (16-byte random IV + ciphertext).
  Future<Uint8List> encryptBytes(Uint8List plainBytes) async {
    final encrypter = await _encrypter();
    final iv = enc.IV.fromSecureRandom(_ivLength);
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);
    final builder = BytesBuilder(copy: false)
      ..add(iv.bytes)
      ..add(encrypted.bytes);
    return builder.toBytes();
  }

  /// Pure byte-level decryption helper.
  Future<Uint8List> decryptBytes(Uint8List payload) async {
    if (payload.length <= _ivLength) {
      throw const FormatException('Encrypted image payload is truncated.');
    }
    final encrypter = await _encrypter();
    final iv = enc.IV(Uint8List.sublistView(payload, 0, _ivLength));
    final cipherBytes = Uint8List.sublistView(payload, _ivLength);
    final decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  /// Encrypts [sourceFile], writes `.enc` inside the app's vault folder,
  /// deletes the temporary unencrypted source file if requested, and returns
  /// the stored relative file name.
  Future<String> saveFile(
    File sourceFile, {
    bool deleteSource = true,
  }) async {
    final plainBytes = await sourceFile.readAsBytes();
    final encryptedPayload = await encryptBytes(plainBytes);
    final dir = await _directoryResolver();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final fileName = '${const Uuid().v4()}.enc';
    final target = File(p.join(dir.path, fileName));
    await target.writeAsBytes(encryptedPayload, flush: true);

    if (deleteSource) {
      try {
        if (await sourceFile.exists()) {
          await sourceFile.delete();
        }
      } catch (_) {
        // Ignore cleanup failures on read-only cache paths.
      }
    }
    return fileName;
  }

  /// Loads and decrypts an image in memory by its stored [storedPath] (either a
  /// relative file name inside the vault folder or a full path).
  Future<Uint8List> load(String storedPath) async {
    final file = await _resolveFile(storedPath);
    final payload = await file.readAsBytes();
    return decryptBytes(payload);
  }

  /// Deletes the encrypted file from disk if it exists.
  Future<void> delete(String storedPath) async {
    try {
      final file = await _resolveFile(storedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore missing-file errors so document deletion never blocks.
    }
  }

  Future<void> deleteAll(Iterable<String> storedPaths) async {
    for (final path in storedPaths) {
      await delete(path);
    }
  }

  Future<File> _resolveFile(String storedPath) async {
    if (p.isAbsolute(storedPath)) {
      return File(storedPath);
    }
    final dir = await _directoryResolver();
    return File(p.join(dir.path, storedPath));
  }
}
