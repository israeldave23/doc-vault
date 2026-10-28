import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/security/passphrase.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/local/secure_image_store.dart';
import '../../documents/models/document.dart';
import '../../documents/providers/document_providers.dart';
import '../../profiles/models/profile.dart';
import '../models/app_settings.dart';

/// Reads the currently open (encrypted) boxes, so export and import always
/// operate on live data.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    documentsBox: Hive.box<Document>(HiveService.documentsBox),
    profilesBox: Hive.box<Profile>(HiveService.profilesBox),
    settingsBox: Hive.box<AppSettings>(HiveService.settingsBox),
    images: ref.watch(secureImageStoreProvider),
  );
});

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BackupSummary {
  const BackupSummary({
    required this.documents,
    required this.profiles,
    required this.images,
  });

  final int documents;
  final int profiles;
  final int images;

  @override
  String toString() => '$documents documents, $profiles people, $images photos';
}

/// One encrypted `.dvault` file holding every box plus the photo vault.
///
/// Layout: `magic(8) | salt(16) | iv(16) | length(4) | AES-256-CBC payload`.
/// The passphrase is stretched with PBKDF2 to form the key. The payload holds
/// a JSON snapshot followed by the still-encrypted image files, so a stolen
/// backup is useless without the passphrase and photos are never decrypted on
/// the way in or out.
class BackupService {
  BackupService({
    required this.documentsBox,
    required this.profilesBox,
    required this.settingsBox,
    required this.images,
  });

  final Box<Document> documentsBox;
  final Box<Profile> profilesBox;
  final Box<AppSettings> settingsBox;
  final SecureImageStore images;

  static const _magic = 'DVBACK1\n';
  static const _saltLength = 16;
  static const _ivLength = 16;
  static const _headerLength = 8 + 16 + 16 + 4;
  static const _version = 1;

  /// Builds the encrypted archive, ready to be written to a file.
  Future<Uint8List> exportArchive({required String passphrase}) async {
    final salt = randomSalt(_saltLength);
    final iv = enc.IV.fromSecureRandom(_ivLength);
    final payload = await _buildPayload();
    final encrypted =
        _encrypter(passphrase, salt).encryptBytes(payload, iv: iv);

    final header = BytesBuilder(copy: false)
      ..add(utf8.encode(_magic))
      ..add(salt)
      ..add(iv.bytes)
      ..add(_intBytes(encrypted.bytes.length));
    header.add(encrypted.bytes);
    return header.toBytes();
  }

  /// Restores an archive, replacing current documents, profiles, settings and
  /// photos. Throws [BackupException] for a damaged file or wrong passphrase;
  /// nothing is modified unless the payload decrypts and parses cleanly.
  Future<BackupSummary> importArchive({
    required Uint8List bytes,
    required String passphrase,
  }) async {
    final decoded = _decodeAll(bytes, passphrase);

    final docs = (decoded.json['documents'] as List? ?? const [])
        .map((e) => Document.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final profiles = (decoded.json['profiles'] as List? ?? const [])
        .map((e) => Profile.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    final settings = AppSettings.fromMap(
      Map<String, dynamic>.from(decoded.json['settings'] as Map? ?? const {}),
    );

    // Everything parsed — commit the restore.
    await images.clearAll();
    for (final entry in decoded.images) {
      await images.writeEncrypted(entry.key, entry.value);
    }

    await documentsBox.clear();
    await documentsBox.putAll({for (final d in docs) d.id: d});

    await profilesBox.clear();
    await profilesBox.putAll({for (final p in profiles) p.id: p});
    if (!profilesBox.containsKey(Profile.selfId)) {
      // The app assumes a default person always exists.
      await profilesBox.put(
        Profile.selfId,
        const Profile(id: Profile.selfId, name: 'Me', avatarEmoji: '🙂'),
      );
    }

    await settingsBox.clear();
    await settingsBox.put(AppSettings.storageKey, settings);

    return BackupSummary(
      documents: docs.length,
      profiles: profilesBox.length,
      images: decoded.images.length,
    );
  }

  // ---------------------------------------------------------------- internal

  enc.Encrypter _encrypter(String passphrase, List<int> salt) {
    final key = enc.Key(deriveKey(passphrase, salt));
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  _DecodedArchive _decodeAll(Uint8List bytes, String passphrase) {
    if (bytes.length < _headerLength ||
        utf8.decode(bytes.sublist(0, 8), allowMalformed: true) != _magic) {
      throw BackupException('This file is not a Document Vault backup.');
    }

    final salt = bytes.sublist(8, 8 + _saltLength);
    final iv =
        enc.IV(bytes.sublist(8 + _saltLength, 8 + _saltLength + _ivLength));
    final payloadOffset = _headerLength;
    final length = _readInt(bytes, payloadOffset - 4);
    final payloadEnd = payloadOffset + length;
    if (bytes.length < payloadEnd) {
      throw BackupException('The backup file is truncated.');
    }

    final Uint8List decrypted;
    try {
      decrypted = Uint8List.fromList(
        _encrypter(passphrase, salt).decryptBytes(
          enc.Encrypted(bytes.sublist(payloadOffset, payloadEnd)),
          iv: iv,
        ),
      );
    } catch (_) {
      throw BackupException('Wrong passphrase, or the backup file is damaged.');
    }

    if (decrypted.length < 4) {
      throw BackupException('The backup file is damaged.');
    }
    final jsonLength = _readInt(decrypted, 0);
    if (decrypted.length < 4 + jsonLength) {
      throw BackupException('The backup file is damaged.');
    }

    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(utf8.decode(decrypted.sublist(4, 4 + jsonLength)));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not a JSON object');
      }
      json = decoded;
    } catch (_) {
      throw BackupException('The backup file is damaged.');
    }

    var cursor = 4 + jsonLength;
    final count = _readInt(decrypted, cursor);
    cursor += 4;
    final imageEntries = <MapEntry<String, Uint8List>>[];
    for (var i = 0; i < count; i++) {
      if (cursor + 4 > decrypted.length) {
        throw BackupException('The backup file is damaged.');
      }
      final nameLength = _readInt(decrypted, cursor);
      cursor += 4;
      final name =
          utf8.decode(decrypted.sublist(cursor, cursor + nameLength));
      cursor += nameLength;
      final dataLength = _readInt(decrypted, cursor);
      cursor += 4;
      imageEntries.add(MapEntry(
        name,
        Uint8List.fromList(decrypted.sublist(cursor, cursor + dataLength)),
      ));
      cursor += dataLength;
    }

    return _DecodedArchive(json: json, images: imageEntries);
  }

  Future<Uint8List> _buildPayload() async {
    final jsonBytes = utf8.encode(
      jsonEncode(<String, dynamic>{
        'version': _version,
        'exportedAt': DateTime.now().toIso8601String(),
        'documents': documentsBox.values.map((d) => d.toMap()).toList(),
        'profiles': profilesBox.values.map((p) => p.toMap()).toList(),
        'settings':
            (settingsBox.get(AppSettings.storageKey) ?? const AppSettings())
                .toMap(),
      }),
    );

    final names = await images.listStored();
    final builder = BytesBuilder(copy: false);
    _writeChunk(builder, jsonBytes);
    _writeInt(builder, names.length);
    for (final name in names) {
      _writeChunk(builder, utf8.encode(name));
      _writeChunk(builder, await images.readEncrypted(name));
    }
    return builder.toBytes();
  }

  static void _writeChunk(BytesBuilder builder, List<int> bytes) {
    _writeInt(builder, bytes.length);
    builder.add(bytes);
  }

  static void _writeInt(BytesBuilder builder, int value) {
    builder.add(_intBytes(value));
  }

  static List<int> _intBytes(int value) => <int>[
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  static int _readInt(Uint8List bytes, int offset) =>
      ((bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3]) &
      0xFFFFFFFF;
}

class _DecodedArchive {
  const _DecodedArchive({required this.json, required this.images});

  final Map<String, dynamic> json;
  final List<MapEntry<String, Uint8List>> images;
}
