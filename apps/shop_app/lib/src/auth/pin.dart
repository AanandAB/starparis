/// PIN hashing, in pure Dart.
///
/// A 4–6 digit PIN is weak by construction, so the defence is not the hash
/// alone: it is PBKDF2 with a per-device salt, a hard attempt counter and a
/// lockout that grows with each failure. The PIN never leaves the device and is
/// never sent to the server.
///
/// PBKDF2-HMAC-SHA256, implemented here so the app has no crypto dependency
/// beyond `package:crypto` and the algorithm is auditable in one screen.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const int _pinIterations = 20000;
const int _keyLength = 32;

Uint8List pbkdf2({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  int length = _keyLength,
}) {
  final hmac = Hmac(sha256, password);
  final blocks = (length / 32).ceil();
  final output = BytesBuilder();

  for (var block = 1; block <= blocks; block++) {
    final blockIndex = <int>[
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ];
    var u = hmac.convert(<int>[...salt, ...blockIndex]).bytes;
    final accumulator = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < accumulator.length; j++) {
        accumulator[j] ^= u[j];
      }
    }
    output.add(accumulator);
  }

  return Uint8List.sublistView(output.takeBytes(), 0, length);
}

String newSalt() {
  final random = Random.secure();
  final salt = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  return base64.encode(salt);
}

/// `pbkdf2$sha256$<iterations>$<saltB64>$<hashB64>` — the same envelope the
/// Worker uses for passwords, so a security review has one format to read.
String hashPin(String pin, {String? saltBase64}) {
  final salt = base64.decode(saltBase64 ?? newSalt());
  final hash = pbkdf2(
    password: utf8.encode(pin),
    salt: salt,
    iterations: _pinIterations,
  );
  return 'pbkdf2\$sha256\$$_pinIterations\$${base64.encode(salt)}\$${base64.encode(hash)}';
}

bool verifyPin(String pin, String stored) {
  final parts = stored.split(r'$');
  if (parts.length != 5 || parts[0] != 'pbkdf2') return false;
  final iterations = int.tryParse(parts[2]);
  if (iterations == null || iterations <= 0) return false;
  final salt = base64.decode(parts[3]);
  final expected = base64.decode(parts[4]);
  final actual = pbkdf2(
    password: utf8.encode(pin),
    salt: salt,
    iterations: iterations,
    length: expected.length,
  );
  return _constantTimeEquals(actual, expected);
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
