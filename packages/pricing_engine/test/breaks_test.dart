import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:test/test.dart';

/// Price breaks: the owner's own answer for a quantity.
void main() {
  const product = PriceRequest(
    productId: 'prod_business_cards',
    kind: ProductKind.service,
    quantity: 500,
    sides: 1,
  );

  PricingContext contextWith(List<QuantityBreak> breaks) => PricingContext(
    priceBookVersion: 1,
    mode: PricingMode.priceTable,
    priceBreaks: breaks,
    tiers: const <PriceTier>[PriceTier(qtyFrom: 1, unitPriceFils: 30)],
    roundingStepFils: 100,
    vatBps: 500,
  );

  test('a break for exactly this quantity is the price', () {
    final priced = PricingEngine.price(
      product,
      contextWith(const <QuantityBreak>[
        QuantityBreak(quantity: 500, amountFils: 12200),
      ]),
    );

    expect(priced.total.raw, 12200);
    expect(priced.vat.raw, 610);
    expect(priced.grandTotal.raw, 12810);
    expect(
      priced.lines.any((line) => line.code == 'break_price'),
      isTrue,
      reason: 'the breakdown must say the price came from a break',
    );
  });

  test('a trade customer pays a different price for the same work', () {
    final retail = PricingEngine.price(
      product,
      contextWith(const <QuantityBreak>[QuantityBreak(quantity: 500, amountFils: 12200)]),
    );

    final trade = PricingEngine.price(
      product,
      PricingContext(
        priceBookVersion: 1,
        mode: PricingMode.priceTable,
        priceBreaks: const <QuantityBreak>[QuantityBreak(quantity: 500, amountFils: 12200)],
        tierAdjustmentBps: -1000, // 10% off for trade
        roundingStepFils: 100,
        vatBps: 500,
      ),
    );

    expect(retail.total.raw, 12200);
    // 122.00 less 10% is 109.80, which the shop rounds to 110.00 — the same one
    // rounding rule as every other price, applied after the tier.
    expect(trade.total.raw, 11000);
    expect(
      trade.lines.any((line) => line.code == 'tier_adjustment'),
      isTrue,
      reason: 'the trade discount must appear in the breakdown',
    );
    expect(trade.grandTotal.raw, 11550);
  });

  test('a quantity with no break falls back to the table tier', () {
    final priced = PricingEngine.price(
      product,
      contextWith(const <QuantityBreak>[
        QuantityBreak(quantity: 1000, amountFils: 22000),
      ]),
    );

    // 500 × 0.30 from the tier, not the 1000 break.
    expect(priced.total.raw, 15000);
    expect(priced.lines.any((line) => line.code == 'break_price'), isFalse);
  });
}
