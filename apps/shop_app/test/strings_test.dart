import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/src/l10n/strings.dart';

/// The words are data, so they can be tested without pumping a widget.
void main() {
  test('Arabic is Arabic and English is English', () {
    final en = AppStrings.of(const Locale('en'));
    final ar = AppStrings.of(const Locale('ar', 'AE'));

    expect(en('nav.today'), 'Today');
    expect(ar('nav.today'), 'اليوم');

    expect(en('today.overdue'), 'Overdue');
    expect(ar('today.overdue'), 'متأخر');

    expect(ar('menu.signout'), 'تسجيل الخروج');
  });

  test('a locale we do not ship stays English rather than blank', () {
    final french = AppStrings.of(const Locale('fr'));
    expect(french('nav.orders'), 'Orders');
  });

  test('a missing key shows itself, never an empty string', () {
    final ar = AppStrings.of(const Locale('ar'));
    expect(ar('nothing.here'), 'nothing.here');
  });
}
