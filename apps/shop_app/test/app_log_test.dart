import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/src/logging/app_log.dart';

/// The log is the thing support reads first, so its contract is pinned here:
/// bounded, ordered, and copyable without a device attached.
void main() {
  setUp(AppLog.clear);

  test('records events in order with their level', () {
    AppLog.info('sync started');
    AppLog.warn('push rejected', error: 'VERSION_CONFLICT');

    final text = AppLog.export();
    expect(text, contains('INFO  sync started'));
    expect(text, contains('WARN  push rejected — VERSION_CONFLICT'));
  });

  test('keeps a bounded buffer rather than growing forever', () {
    for (var i = 0; i < 400; i++) {
      AppLog.debug('event $i');
    }

    expect(AppLog.entries, hasLength(300));
    expect(AppLog.entries.first.message, 'event 100');
    expect(AppLog.entries.last.message, 'event 399');
  });

  test('export takes the tail, newest last', () {
    for (var i = 0; i < 10; i++) {
      AppLog.info('line $i');
    }

    final text = AppLog.export(count: 3);
    expect(text.split('\n'), hasLength(3));
    expect(text, contains('line 9'));
    expect(text, isNot(contains('line 6')));
  });
}
