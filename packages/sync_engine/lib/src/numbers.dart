/// Human-friendly numbers: job numbers, quote numbers, invoice numbers.
///
/// A device leases a block of 100 from the server and spends it offline. When
/// the block runs out the next order gets a temporary `T-0007`, which a manager
/// swaps when the device reconnects — a counter clerk must never be blocked by
/// the network, and gaps in job numbers are acceptable.
///
/// Invoice series are per device on purpose (PLAN.md §7): gaplessness and
/// uniqueness both require the series to belong to exactly one device.
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
  final String display;
  final bool isTemporary;
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
    required this.series,
    this.blockSize = 100,
  });

  final LocalDatabase db;

  /// Null when the device has never signed in; the series then issues
  /// temporary numbers, which is better than blocking the counter.
  final SyncApi? api;

  /// For example `JOB`, `QT-SHJ1-PC1`, `INV-SHJ1-PC1`.
  final String series;
  final int blockSize;

  String get _cursorKey => '$series.cursor';
  String get _endKey => '$series.end';
  String get _tempKey => '$series.temp';

  /// The next number, leased or temporary. Never throws: a shop with no
  /// internet still gets an order number, it just says `T-0007`.
  Future<IssuedNumber> next() async {
    final cursor = int.tryParse(await db.meta(_cursorKey) ?? '0') ?? 0;
    final end = int.tryParse(await db.meta(_endKey) ?? '0') ?? 0;

    if (cursor > 0 && cursor < end) {
      final next = cursor + 1;
      await db.setMeta(_cursorKey, '$next');
      return IssuedNumber(number: next, display: '$next', isTemporary: false);
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
        display: '${range.start}',
        isTemporary: false,
      );
    } on SyncException {
      final temp = (int.tryParse(await db.meta(_tempKey) ?? '0') ?? 0) + 1;
      await db.setMeta(_tempKey, '$temp');
      return IssuedNumber(
        number: null,
        display: 'T-${temp.toString().padLeft(4, '0')}',
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
