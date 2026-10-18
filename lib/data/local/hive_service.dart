import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/documents/models/document.dart';
import '../../features/profiles/models/profile.dart';
import '../../features/settings/models/app_settings.dart';

/// Opens the encrypted local database. The AES key lives in the platform
/// keystore via flutter_secure_storage, so the Hive files on disk are useless
/// without the device.
class HiveService {
  HiveService._();

  static const documentsBox = 'documents';
  static const profilesBox = 'profiles';
  static const settingsBox = 'settings';
  static const _encryptionKeyName = 'doc_vault_hive_key';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(DocumentAdapter())
      ..registerAdapter(ProfileAdapter())
      ..registerAdapter(AppSettingsAdapter());

    final cipher = HiveAesCipher(await _loadOrCreateKey());

    await Hive.openBox<Document>(documentsBox, encryptionCipher: cipher);
    await Hive.openBox<Profile>(profilesBox, encryptionCipher: cipher);
    await Hive.openBox<AppSettings>(settingsBox, encryptionCipher: cipher);

    await _ensureDefaults();
  }

  static Future<List<int>> _loadOrCreateKey() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final existing = await storage.read(key: _encryptionKeyName);
    if (existing != null) return base64Url.decode(existing);

    final key = Hive.generateSecureKey();
    await storage.write(key: _encryptionKeyName, value: base64Url.encode(key));
    return key;
  }

  static Future<void> _ensureDefaults() async {
    final profiles = Hive.box<Profile>(profilesBox);
    final isFirstLaunch = profiles.isEmpty;
    if (isFirstLaunch) {
      await profiles.put(
        Profile.selfId,
        const Profile(id: Profile.selfId, name: 'Me', avatarEmoji: '🙂'),
      );
    }

    final settings = Hive.box<AppSettings>(settingsBox);
    if (!settings.containsKey(AppSettings.storageKey)) {
      await settings.put(AppSettings.storageKey, const AppSettings());
    }

    // Seed sample documents once on first install so the dashboard is ready to explore.
    final documents = Hive.box<Document>(documentsBox);
    if (isFirstLaunch && documents.isEmpty) {
      await _seedSampleDocuments(documents);
    }
  }

  static Future<void> _seedSampleDocuments(Box<Document> box) async {
    final now = DateTime.now();
    final samples = <Document>[
      Document(
        id: 'sample-passport',
        title: 'Philippine Passport',
        category: 'passport',
        idNumber: 'P1234567A',
        issueDate: DateTime(now.year - 9, now.month, now.day),
        expiryDate: now.add(const Duration(days: 200)),
        profileId: Profile.selfId,
        notes: 'Sample data — delete me.',
      ),
      Document(
        id: 'sample-license',
        title: "Driver's License",
        category: 'drivers_license',
        idNumber: 'N01-23-456789',
        expiryDate: now.add(const Duration(days: 45)),
        profileId: Profile.selfId,
        notes: 'Sample data — delete me.',
      ),
      Document(
        id: 'sample-registration',
        title: 'Motorcycle LTO Registration',
        category: 'vehicle_registration',
        expiryDate: now.add(const Duration(days: 12)),
        profileId: Profile.selfId,
        notes: 'Sample data — delete me.',
      ),
      Document(
        id: 'sample-insurance',
        title: 'Health Insurance Card',
        category: 'insurance',
        expiryDate: now.subtract(const Duration(days: 5)),
        profileId: Profile.selfId,
        notes: 'Sample data — delete me.',
      ),
    ];
    for (final doc in samples) {
      await box.put(doc.id, doc);
    }
  }
}
