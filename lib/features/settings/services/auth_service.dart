import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/security/passphrase.dart';

/// Storage for small secrets (PIN hash, salts). Abstracted so tests can run
/// against an in-memory fake instead of the platform keystore.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// PIN + biometric app lock.
///
/// The PIN is never stored — only a PBKDF2-HMAC-SHA256 hash with a random
/// salt, both inside the platform keystore, so it never appears in the
/// encrypted Hive boxes a backup would export.
class AuthService {
  AuthService({SecretStore? secretStore, LocalAuthentication? localAuth})
      : _store = secretStore ?? const SecureSecretStore(),
        _localAuth = localAuth ?? LocalAuthentication();

  static const _pinKey = 'doc_vault_pin_hash';
  static const _saltKey = 'doc_vault_pin_salt';
  static const int minPinLength = 4;
  static const int maxPinLength = 8;

  final SecretStore _store;
  final LocalAuthentication _localAuth;

  static bool isValidPin(String pin) =>
      pin.length >= minPinLength &&
      pin.length <= maxPinLength &&
      RegExp(r'^\d+$').hasMatch(pin);

  Future<bool> isPinSet() async => await _store.read(_pinKey) != null;

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError(
        'PIN must be $minPinLength-$maxPinLength digits',
      );
    }
    final salt = randomSalt();
    final hash = _hashPin(pin, salt);
    await _store.write(_saltKey, bytesToHex(salt));
    await _store.write(_pinKey, bytesToHex(hash));
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _store.read(_pinKey);
    final storedSalt = await _store.read(_saltKey);
    if (storedHash == null || storedSalt == null) return false;
    if (!isValidPin(pin)) return false;

    final candidate = _hashPin(pin, hexToBytes(storedSalt));
    return constantTimeEquals(bytesToHex(candidate), storedHash);
  }

  Future<void> clearPin() async {
    await _store.delete(_pinKey);
    await _store.delete(_saltKey);
  }

  Future<bool> canUseBiometrics() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Attempts a biometric/credential unlock. Never throws.
  Future<bool> unlockWithBiometrics(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  List<int> _hashPin(String pin, List<int> salt) =>
      deriveKey(pin, salt, iterations: pbkdf2Iterations, length: 32);
}

/// Compares two strings without leaking timing about how far they matched.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> hexToBytes(String hex) {
  final result = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}
