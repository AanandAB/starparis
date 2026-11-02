/// UUIDv7 generation.
///
/// Every row in the system gets its identifier **on the device**, before it is
/// ever synced. UUIDv7 (RFC 9562) puts a 48-bit millisecond timestamp at the
/// front, so identifiers sort by creation time — which keeps SQLite B-tree
/// inserts sequential instead of scattering them, and makes `ORDER BY id` a
/// usable "oldest first".
///
/// The generator is monotonic: two identifiers created in the same millisecond,
/// or even with a clock that stepped backwards, still sort in creation order.
/// That property is what lets the sync engine use ids as tie-breakers.
library;

import 'dart:math';

final class Uuid7 {
  Uuid7._();

  static final Random _random = Random.secure();

  /// Last millisecond timestamp used, and the 12-bit sequence within it.
  static int _lastMillis = 0;
  static int _sequence = 0;

  /// Set by tests to make generation deterministic.
  static void debugReset({int millis = 0, int sequence = 0}) {
    _lastMillis = millis;
    _sequence = sequence;
  }

  /// Generates a new identifier in canonical 8-4-4-4-12 form.
  static String generate() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now > _lastMillis) {
      _lastMillis = now;
      _sequence = 0;
    } else {
      // Same millisecond, or the clock moved backwards: keep time monotonic
      // and burn sequence numbers instead.
      _sequence++;
      if (_sequence > 0xFFF) {
        _lastMillis++;
        _sequence = 0;
      }
    }

    final bytes = List<int>.filled(16, 0);
    final millis = _lastMillis;

    // Bytes 0..5 — 48-bit big-endian timestamp.
    bytes[0] = (millis >> 40) & 0xFF;
    bytes[1] = (millis >> 32) & 0xFF;
    bytes[2] = (millis >> 24) & 0xFF;
    bytes[3] = (millis >> 16) & 0xFF;
    bytes[4] = (millis >> 8) & 0xFF;
    bytes[5] = millis & 0xFF;

    // Bytes 6..7 — version 7 in the top nibble, then 12 bits of sequence.
    bytes[6] = 0x70 | ((_sequence >> 8) & 0x0F);
    bytes[7] = _sequence & 0xFF;

    // Bytes 8..15 — variant `10` in the top two bits, 62 random bits.
    final random = _random.nextInt(1 << 32);
    final random2 = _random.nextInt(1 << 32);
    bytes[8] = 0x80 | ((random >> 24) & 0x3F);
    bytes[9] = (random >> 16) & 0xFF;
    bytes[10] = (random >> 8) & 0xFF;
    bytes[11] = random & 0xFF;
    bytes[12] = (random2 >> 24) & 0xFF;
    bytes[13] = (random2 >> 16) & 0xFF;
    bytes[14] = (random2 >> 8) & 0xFF;
    bytes[15] = random2 & 0xFF;

    return _format(bytes);
  }

  /// True if [value] is a canonical lowercase UUID of any version.
  static bool isValid(String value) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
          .hasMatch(value);

  /// The creation time encoded in a v7 identifier, or `null` if [value] is not
  /// a v7 identifier. Used by the sync engine to explain ordering, never to
  /// decide it.
  static DateTime? timestampOf(String value) {
    if (!isValid(value)) {
      return null;
    }
    final hex = value.replaceAll('-', '');
    if (hex[12] != '7') {
      return null;
    }
    final millis = int.parse(hex.substring(0, 12), radix: 16);
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static String _format(List<int> b) {
    final hex = StringBuffer();
    for (final byte in b) {
      hex.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    final s = hex.toString();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}'
        '-${s.substring(16, 20)}-${s.substring(20, 32)}';
  }
}
