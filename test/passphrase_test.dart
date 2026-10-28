import 'dart:convert';

import 'package:doc_vault/core/security/passphrase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deriveKey', () {
    test('matches the published PBKDF2-HMAC-SHA256 vector', () {
      // P="password", S="salt", c=1, dkLen=32.
      final key = deriveKey('password', utf8.encode('salt'), iterations: 1, length: 32);
      expect(
        key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('is deterministic for the same passphrase and salt', () {
      final a = deriveKey('correct horse battery staple', [1, 2, 3]);
      final b = deriveKey('correct horse battery staple', [1, 2, 3]);
      expect(a, equals(b));
      expect(a, hasLength(32));
    });

    test('changes with the passphrase, salt, iterations and length', () {
      final base = deriveKey('secret', [1, 2, 3]);
      expect(deriveKey('secret2', [1, 2, 3]), isNot(equals(base)));
      expect(deriveKey('secret', [1, 2, 4]), isNot(equals(base)));
      expect(deriveKey('secret', [1, 2, 3], iterations: 1000),
          isNot(equals(base)));
      expect(
          deriveKey('secret', [1, 2, 3], length: 16), hasLength(16));
    });
  });

  group('randomSalt', () {
    test('produces unique salts of the requested length', () {
      final first = randomSalt();
      final second = randomSalt();
      expect(first, hasLength(16));
      expect(second, hasLength(16));
      expect(first, isNot(equals(second)));
    });
  });
}
