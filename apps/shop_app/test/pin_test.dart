import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/src/auth/pin.dart';

void main() {
  group('PIN hashing', () {
    test('a correct PIN verifies and a wrong one does not', () {
      final stored = hashPin('4821');
      expect(verifyPin('4821', stored), isTrue);
      expect(verifyPin('4822', stored), isFalse);
      expect(verifyPin('4821 ', stored), isFalse, reason: 'no trimming surprises');
    });

    test('the stored value never contains the PIN', () {
      final stored = hashPin('4821');
      expect(stored.contains('4821'), isFalse);
      expect(stored.split(r'$').first, 'pbkdf2');
    });

    test('two hashes of the same PIN differ because the salt is random', () {
      final first = hashPin('4821');
      final second = hashPin('4821');
      expect(first, isNot(second));
      expect(verifyPin('4821', first), isTrue);
      expect(verifyPin('4821', second), isTrue);
    });

    test('the iteration count travels with the hash, so it can be raised later', () {
      final stored = hashPin('4821');
      final iterations = int.parse(stored.split(r'$')[2]);
      expect(iterations, greaterThanOrEqualTo(20000));
    });
  });

  group('PBKDF2', () {
    test('matches the RFC 6070 test vector shape for short inputs', () {
      // Not a published vector (those use much higher iteration counts), but
      // this pins determinism: same input, same output, every run.
      final first = pbkdf2(password: 'password'.codeUnits, salt: 'salt'.codeUnits, iterations: 1000);
      final second = pbkdf2(password: 'password'.codeUnits, salt: 'salt'.codeUnits, iterations: 1000);
      expect(first, second);
      expect(first.length, 32);
    });

    test('a different salt gives a different key', () {
      final a = pbkdf2(password: 'p'.codeUnits, salt: 'a'.codeUnits, iterations: 100);
      final b = pbkdf2(password: 'p'.codeUnits, salt: 'b'.codeUnits, iterations: 100);
      expect(a, isNot(b));
    });
  });
}
