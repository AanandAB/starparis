import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/src/sales/pricer.dart';

void main() {
  test('retail is priced at the full selling price', () {
    expect(tierAdjustmentBpsFor('retail'), 0);
  });

  test('trade gets the ten percent discount', () {
    expect(tierAdjustmentBpsFor('trade'), -1000);
  });

  test('an uncategorised tier prices at retail, never discounted', () {
    expect(tierAdjustmentBpsFor('corporate'), 0);
    expect(tierAdjustmentBpsFor('wholesale'), 0);
    expect(tierAdjustmentBpsFor(''), 0);
  });
}
