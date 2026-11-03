/// Money, as integers.
///
/// Every amount in Star Paris is a whole number of **fils** (1 AED = 100
/// fils). There is no `double` anywhere in the money path: floating point
/// cannot represent 0.10 exactly, and a VAT return that is one fil off is a
/// VAT return that gets queried.
///
/// Use [Fils] for storage, arithmetic and comparison. Convert to a decimal
/// string only at the very edge, for display or PDF output.
library;

/// Rounds `value * mul / div` to the nearest integer, halves away from zero.
///
/// This is the only rounding primitive in the codebase. Everything else —
/// percentages, square-metre rates, VAT — is expressed through it so that the
/// device and the server can never disagree by a fil.
int mulDivRoundHalfUp(int value, int mul, int div) {
  if (div <= 0) {
    throw ArgumentError.value(div, 'div', 'must be positive');
  }
  if (value == 0 || mul == 0) {
    return 0;
  }
  final negative = (value < 0) != (mul < 0);
  final numerator = value.abs() * mul.abs();
  // (n + div/2) / div, computed without floating point.
  final rounded = (numerator * 2 + div) ~/ (div * 2);
  return negative ? -rounded : rounded;
}

/// An amount of money, stored as an integer number of fils.
final class Fils implements Comparable<Fils> {
  const Fils(this.raw);

  /// The amount in fils. 1 AED = 100 fils.
  final int raw;

  static const Fils zero = Fils(0);

  /// Boundary helper for literals in tests and fixtures. Never call this on a
  /// value that came from user input or an API — parse the string instead.
  factory Fils.fromAed(num aed) => Fils((aed * 100).round());

  /// Parses `"122"`, `"122.5"`, `"122.50"`, `"-3.25"`. Rejects anything else,
  /// including thousands separators and currency symbols, so that a typo in an
  /// import file fails loudly instead of silently becoming 1.22.
  factory Fils.parse(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Not a money value', text);
    }
    final sign = match.group(1) == '-' ? -1 : 1;
    final dirhams = int.parse(match.group(2)!);
    final fraction = match.group(3) ?? '';
    final fils = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
    return Fils(sign * (dirhams * 100 + fils));
  }

  bool get isZero => raw == 0;
  bool get isNegative => raw < 0;
  bool get isPositive => raw > 0;

  Fils operator +(Fils other) => Fils(raw + other.raw);
  Fils operator -(Fils other) => Fils(raw - other.raw);
  Fils operator -() => Fils(-raw);
  Fils operator *(int factor) => Fils(raw * factor);
  bool operator >(Fils other) => raw > other.raw;
  bool operator <(Fils other) => raw < other.raw;
  bool operator >=(Fils other) => raw >= other.raw;
  bool operator <=(Fils other) => raw <= other.raw;

  /// Applies a rate expressed in basis points (1% = 100 bps).
  Fils timesBps(int bps) => Fils(mulDivRoundHalfUp(raw, bps, 10000));

  /// Splits this amount across [parts] without losing or inventing a fil.
  /// The remainder is distributed one fil at a time from the first part.
  List<Fils> splitAcross(int parts) {
    if (parts <= 0) {
      throw ArgumentError.value(parts, 'parts', 'must be positive');
    }
    final base = raw ~/ parts;
    var remainder = raw - base * parts;
    return <Fils>[
      for (var i = 0; i < parts; i++) Fils(base + (remainder-- > 0 ? 1 : 0)),
    ];
  }

  /// Rounds to the nearest [stepFils] (for example 25 fils or 100 fils),
  /// halves away from zero.
  Fils roundToStep(int stepFils) {
    if (stepFils <= 0) {
      throw ArgumentError.value(stepFils, 'stepFils', 'must be positive');
    }
    final negative = raw < 0;
    final magnitude = raw.abs();
    final rounded = ((magnitude * 2 + stepFils) ~/ (stepFils * 2)) * stepFils;
    return Fils(negative ? -rounded : rounded);
  }

  /// Floor at zero: used where a computed amount must never go negative
  /// (a discount larger than the price is a bug, not a refund).
  Fils clampNonNegative() => raw < 0 ? zero : this;

  /// `"122.00"` — no currency label, no grouping. For CSV and PDF columns.
  String get aedText {
    final sign = raw < 0 ? '-' : '';
    final magnitude = raw.abs();
    final dirhams = magnitude ~/ 100;
    final fils = (magnitude % 100).toString().padLeft(2, '0');
    return '$sign$dirhams.$fils';
  }

  /// `"1,234.50"` — grouped, for screens and documents.
  String get aedDisplay => _group(aedText);

  /// `"AED 122.00"` — the label every customer-facing document uses.
  String get aedLabel => 'AED $aedDisplay';

  /// For logs and `toString`. Never for user-facing text.
  @override
  String toString() => 'Fils($raw)';

  @override
  int compareTo(Fils other) => raw.compareTo(other.raw);

  @override
  bool operator ==(Object other) => other is Fils && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  static String _group(String plain) {
    final negative = plain.startsWith('-');
    final body = negative ? plain.substring(1) : plain;
    final parts = body.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
    }
    final grouped = '$buffer.${parts.last}';
    return negative ? '-$grouped' : grouped;
  }
}
