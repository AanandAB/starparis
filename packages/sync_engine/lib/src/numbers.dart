/// Human-friendly numbers: job numbers, quote numbers, invoice numbers.
///
/// A device leases a block of 100 from the server and spends it offline. When
/// the block runs out the next order gets a temporary `T-0007`, which a manager
/// swaps when the device reconnects — a counter clerk must never be blocked by
/// the network, and gaps in job numbers are acceptable.
///
/// Invoice series are per device on purpose (PLAN.md §7): gaplessness and
/// uniqueness both require the series to belong to exactly one device.
///
/// The prefix in front of a number (`INV`, `QT`, `JOB`) is shop data, not code:
/// the owner renames it in Settings. So the caller passes the saved prefixes in,
/// and a document already issued is never rewritten — it keeps the string it was
/// printed with, and only numbers issued after the change carry the new prefix.
library;

import 'api.dart';
import 'database.dart';

class IssuedNumber {
  const IssuedNumber({
    required this.number,
    required this.display,
    required this.isTemporary,
  });

  /// Null when the number is temporary and has not been allocated yet.
  final int? number;

  /// What goes on the document, prefix and all (`BILL-SHJ1-PC1-00123`), or
  /// `BILL-T-0007` while the device is offline. The caller stores this string
  /// verbatim and never rebuilds it, so a later rename cannot change history.
  final String display;
  final bool isTemporary;
}

/// The kinds of number the shop issues.
///
/// The app reasons about the *kind*; the prefix is only how that kind happens to
/// be spelled today. Passing a kind rather than a prefix is what stops `INV`
/// creeping back into call sites after a shop renames it.
enum NumberKind {
  job,
  quote,
  invoice,
  creditNote,
  delivery;

  /// The key this kind's prefix has in the `numbers` block of `GET /v1/settings`.
  /// Credit notes and delivery notes have no key yet: Settings cannot show a
  /// field that does not exist, so their prefixes stay fixed.
  String? get settingsKey => switch (this) {
    NumberKind.job => 'order_prefix',
    NumberKind.quote => 'quote_prefix',
    NumberKind.invoice => 'invoice_prefix',
    NumberKind.creditNote => null,
    NumberKind.delivery => null,
  };
}

/// The shop's chosen prefixes, from `GET /v1/settings` (`numbers`).
///
/// The defaults match the worker's, so a device that has never reached the
/// server still prints `INV-SHJ1-PC1-00001` instead of nothing. A device that
/// has reached it passes the saved values instead — that is the whole point:
/// renaming `INV` to `BILL` in Settings changes the next invoice number.
class NumberPrefixes {
  const NumberPrefixes({
    this.job = 'JOB',
    this.quote = 'QT',
    this.invoice = 'INV',
    this.creditNote = 'CN',
    this.delivery = 'DN',
  });

  /// Reads the settings payload the app already loads for the settings screen.
  ///
  /// A blank value falls back to the default rather than being used: a series
  /// starting with `-` would be unreadable on a document and unguessable when
  /// someone quotes the number back over the phone.
  factory NumberPrefixes.fromSettingsJson(Map<String, Object?> json) {
    final numbers =
        (json['numbers'] as Map?)?.cast<String, Object?>() ??
        const <String, Object?>{};
    const fallback = NumberPrefixes();

    return NumberPrefixes(
      job: _pick(numbers, NumberKind.job, fallback),
      quote: _pick(numbers, NumberKind.quote, fallback),
      invoice: _pick(numbers, NumberKind.invoice, fallback),
    );
  }

  /// One live prefix, or the default when the payload has nothing usable.
  static String _pick(
    Map<String, Object?> numbers,
    NumberKind kind,
    NumberPrefixes fallback,
  ) {
    final key = kind.settingsKey;
    final value = key == null ? null : (numbers[key] as String?)?.trim();
    return (value == null || value.isEmpty) ? fallback.of(kind) : value;
  }

  final String job;
  final String quote;
  final String invoice;

  /// Not configurable yet — Settings has no field for these, and inventing one
  /// here would let the app print a prefix the owner cannot see.
  final String creditNote;
  final String delivery;

  String of(NumberKind kind) => switch (kind) {
    NumberKind.job => job,
    NumberKind.quote => quote,
    NumberKind.invoice => invoice,
    NumberKind.creditNote => creditNote,
    NumberKind.delivery => delivery,
  };
}

/// The number a customer sees, e.g. `INV-SHJ1-PC1-00123`.
///
/// The series carries the branch and the device (see [seriesKey] in
/// backend/worker/src/numbers.ts), so two counters in one branch cannot both
/// issue 00123. A bare series such as `JOB` keeps the plain number, which is
/// what the pilot used before series codes existed.
String formatNumber(String series, int number) {
  if (!series.contains('-')) return '$number';
  return '$series-${number.toString().padLeft(5, '0')}';
}

class NumberSeries {
  NumberSeries({
    required this.db,
    required this.api,
    required this.kind,
    required this.branchCode,
    required this.deviceCode,
    this.prefixes = const NumberPrefixes(),
    this.blockSize = 100,
  });

  final LocalDatabase db;

  /// Null when the device has never signed in; the series then issues
  /// temporary numbers, which is better than blocking the counter.
  final SyncApi? api;

  /// Which number this is: job, quote, invoice…
  final NumberKind kind;

  /// Branch and device codes. They are device identity, not shop data, so they
  /// stay in the build config; the prefix in front of them comes from Settings.
  final String branchCode;
  final String deviceCode;

  /// Prefixes read from `GET /v1/settings` by the caller. The defaults hold
  /// until the first settings read, and they are the worker's own defaults.
  final NumberPrefixes prefixes;

  final int blockSize;

  /// The prefix this series prints today, e.g. `BILL`.
  String get prefix => prefixes.of(kind);

  /// The series the server leases under: prefix + branch + device.
  String get series =>
      '$prefix-${branchCode.toUpperCase()}-${deviceCode.toUpperCase()}';

  // The cursor keys include the series, and therefore the prefix. That is
  // deliberate: after a rename the server keeps the new prefix as its own
  // series, so this device must lease fresh numbers for it instead of spending
  // the tail of a block whose prefix nobody prints any more.
  String get _cursorKey => '$series.cursor';
  String get _endKey => '$series.end';
  String get _tempKey => '$series.temp';

  String _display(int number) => formatNumber(series, number);

  /// The next number, leased or temporary. Never throws: a shop with no
  /// internet still gets an order number, it just says `BILL-T-0007`.
  Future<IssuedNumber> next() async {
    final cursor = int.tryParse(await db.meta(_cursorKey) ?? '0') ?? 0;
    final end = int.tryParse(await db.meta(_endKey) ?? '0') ?? 0;

    if (cursor > 0 && cursor < end) {
      final next = cursor + 1;
      await db.setMeta(_cursorKey, '$next');
      return IssuedNumber(
        number: next,
        display: _display(next),
        isTemporary: false,
      );
    }

    try {
      final api = this.api;
      if (api == null) {
        throw const SyncException('OFFLINE', 'No sync client yet');
      }
      final range = await api.leaseNumbers(series: series, size: blockSize);
      await db.setMeta(_cursorKey, '${range.start}');
      await db.setMeta(_endKey, '${range.end}');
      return IssuedNumber(
        number: range.start,
        display: _display(range.start),
        isTemporary: false,
      );
    } on SyncException {
      final temp = (int.tryParse(await db.meta(_tempKey) ?? '0') ?? 0) + 1;
      await db.setMeta(_tempKey, '$temp');
      // A temporary number keeps the prefix but drops branch and device: it is
      // swapped for a real one on sync, so the shorter string is the easier one
      // to read out while the counter waits for the network.
      return IssuedNumber(
        number: null,
        display: '$prefix-T-${temp.toString().padLeft(4, '0')}',
        isTemporary: true,
      );
    }
  }

  /// How many numbers remain in the leased block, so the app can top up before
  /// the counter runs dry rather than after.
  Future<int> remaining() async {
    final cursor = int.tryParse(await db.meta(_cursorKey) ?? '0') ?? 0;
    final end = int.tryParse(await db.meta(_endKey) ?? '0') ?? 0;
    return end > cursor ? end - cursor : 0;
  }
}
