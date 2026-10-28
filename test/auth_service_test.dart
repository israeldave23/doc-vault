import 'package:doc_vault/features/settings/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  late _FakeSecretStore store;
  late AuthService auth;

  setUp(() {
    store = _FakeSecretStore();
    // LocalAuthentication is never reached in these tests.
    auth = AuthService(secretStore: store);
  });

  group('PIN validation', () {
    test('accepts 4-8 digit PINs only', () {
      expect(AuthService.isValidPin('1234'), isTrue);
      expect(AuthService.isValidPin('12345678'), isTrue);
      expect(AuthService.isValidPin('123'), isFalse);
      expect(AuthService.isValidPin('123456789'), isFalse);
      expect(AuthService.isValidPin('12ab'), isFalse);
      expect(AuthService.isValidPin(''), isFalse);
    });
  });

  group('PIN storage', () {
    test('no PIN is set initially', () async {
      expect(await auth.isPinSet(), isFalse);
      expect(await auth.verifyPin('1234'), isFalse);
    });

    test('setPin then verifyPin succeeds', () async {
      await auth.setPin('4321');
      expect(await auth.isPinSet(), isTrue);
      expect(await auth.verifyPin('4321'), isTrue);
      expect(await auth.verifyPin('1111'), isFalse);
    });

    test('stores a hash and salt, never the PIN itself', () async {
      await auth.setPin('9876');
      expect(store.values.values.any((v) => v.contains('9876')), isFalse);
      expect(store.values.keys, contains('doc_vault_pin_salt'));
      expect(store.values.keys, contains('doc_vault_pin_hash'));
    });

    test('rejects an invalid PIN at set time', () async {
      expect(() => auth.setPin('12'), throwsArgumentError);
      expect(await auth.isPinSet(), isFalse);
    });

    test('different salts are used across PINs', () async {
      await auth.setPin('1111');
      final firstSalt = store.values['doc_vault_pin_salt'];
      await auth.setPin('1111');
      final secondSalt = store.values['doc_vault_pin_salt'];
      expect(firstSalt, isNot(equals(secondSalt)));
      expect(await auth.verifyPin('1111'), isTrue);
    });

    test('clearPin removes the stored secret', () async {
      await auth.setPin('5678');
      await auth.clearPin();
      expect(await auth.isPinSet(), isFalse);
      expect(await auth.verifyPin('5678'), isFalse);
    });
  });

  group('helpers', () {
    test('constantTimeEquals compares whole strings', () {
      expect(constantTimeEquals('abc', 'abc'), isTrue);
      expect(constantTimeEquals('abc', 'abd'), isFalse);
      expect(constantTimeEquals('abc', 'abcd'), isFalse);
      expect(constantTimeEquals('', ''), isTrue);
    });

    test('hex round trip', () {
      final bytes = [0, 1, 15, 16, 255];
      expect(hexToBytes(bytesToHex(bytes)), equals(bytes));
      expect(bytesToHex([0xab, 0x0c]), 'ab0c');
    });
  });
}
