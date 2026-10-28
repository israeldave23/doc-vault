import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// PBKDF2-HMAC-SHA256 iterations for turning a user passphrase into an AES
/// key. High enough to make offline guessing expensive, low enough to stay
/// comfortably interactive on a phone (~0.2s).
const pbkdf2Iterations = 120000;

/// Derives a [length]-byte key from a [secret] and salt using PBKDF2.
///
/// Used both for the backup passphrase and for PIN verification, so a stolen
/// vault file or keystore blob cannot be brute-forced cheaply.
Uint8List deriveKey(
  String secret,
  List<int> salt, {
  int iterations = pbkdf2Iterations,
  int length = 32,
}) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(Uint8List.fromList(salt), iterations, length));
  return derivator.process(Uint8List.fromList(utf8.encode(secret)));
}

/// Random salt for [deriveKey].
List<int> randomSalt([int length = 16]) {
  final rng = Random.secure();
  return List<int>.generate(length, (_) => rng.nextInt(256));
}
