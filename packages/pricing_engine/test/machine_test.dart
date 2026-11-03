import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:test/test.dart';

/// Machine time and finishing operations.
///
/// These tests exist because the two most expensive things a print shop does —
/// running a press and finishing the job — used to be a per-sheet guess and a
/// list of bespoke rules. A machine's hourly rate, make-ready time and run speed
/// now move the price by arithmetic a shop recognises, and every operation is a
/// row with its own basis.
void main() {
  const sheet = SheetSpec(widthMm: 320, heightMm: 450);

  /// 500 business cards, 90 × 55, one side, on an 320 × 450 sheet: 24 up.
  const request = PriceRequest(
    productId: 'prod_business_cards',
    kind: ProductKind.sheet,
    quantity: 500,
    widthMm: 90,
    heightMm: 55,
    sides: 1,
    materialCode: 'art_card_350',
  );

  PricingContext contextWith({
    MachineSpec? machine,
    List<FinishingOperation> operations = const <FinishingOperation>[],
  }) {
    return PricingContext(
      priceBookVersion: 1,
      mode: PricingMode.costPlus,
      sheet: sheet,
      setupSheets: 2,
      spoilageBps: 500,
      materialCostPerSheetFils: 700,
      printRatePerSheetSideFils: 300,
      machine: machine,
      operations: operations,
      markupBps: 4000,
      roundingStepFils: 100,
      vatBps: 500,
    );
  }

  test('a machine adds make-ready and run time at its own rate', () {
    final without = PricingEngine.price(request, contextWith());
    final withMachine = PricingEngine.price(
      request,
      contextWith(
        machine: const MachineSpec(
          name: 'Heidelberg SM 74',
          hourlyRateFils: 45000, // AED 450 an hour
          setupMinutes: 25,
          sheetsPerHour: 10000,
        ),
      ),
    );

    // 25 minutes of make-ready is 450.00 × 25/60 = 187.50.
    final setupLine = withMachine.lines.firstWhere(
      (line) => line.code == 'machine_setup',
    );
    expect(setupLine.amount.raw, 18750);

    // And the run is priced from sheets ÷ speed, never from a guess.
    final runLine = withMachine.lines.firstWhere(
      (line) => line.code == 'machine_run',
    );
    final sheets = runLine.quantity;
    expect(
      runLine.amount.raw,
      (45000 * sheets / 10000).round(),
      reason: 'run cost must follow the machine speed',
    );

    expect(
      withMachine.costSubtotal.raw,
      greaterThan(without.costSubtotal.raw),
      reason: 'press time is a real cost and must raise the cost subtotal',
    );
    expect(withMachine.grandTotal.raw, greaterThan(without.grandTotal.raw));
  });

  test('a digital click charge replaces the hourly run', () {
    final click = PricingEngine.price(
      request,
      contextWith(
        machine: const MachineSpec(
          name: 'AccurioPress',
          hourlyRateFils: 15000,
          setupMinutes: 5,
          sheetsPerHour: 3000,
          clickFils: 45,
        ),
      ),
    );

    expect(
      click.lines.any((line) => line.code == 'machine_clicks'),
      isTrue,
      reason: 'a click-priced machine must be costed per impression',
    );
    expect(click.lines.any((line) => line.code == 'machine_run'), isFalse);
  });

  test('but there is no machine line on a job that has no machine', () {
    final plain = PricingEngine.price(request, contextWith());
    expect(plain.lines.any((line) => line.code.startsWith('machine')), isFalse);
  });

  test('operations are priced at their own basis and never below a minimum', () {
    final priced = PricingEngine.price(
      request,
      contextWith(
        operations: const <FinishingOperation>[
          FinishingOperation(
            code: 'lam_matt',
            name: 'Matt lamination',
            basis: OperationBasis.perSide,
            rateFils: 40,
          ),
          FinishingOperation(
            code: 'crease',
            name: 'Creasing',
            basis: OperationBasis.per1000,
            rateFils: 6000, // AED 60 per 1000
            setupFils: 2000,
            minChargeFils: 6000,
          ),
        ],
      ),
    );

    // 500 pieces, one side, 40 fils a side = 20.00
    final lamination = priced.lines.firstWhere(
      (line) => line.code == 'op_lam_matt',
    );
    expect(lamination.amount.raw, 500 * 40);

    // 500 pieces at 60.00/1000 = 30.00 plus 20.00 setup = 50.00, but the
    // operation's own minimum is 60.00, so the minimum is what a shop charges.
    final crease = priced.lines.firstWhere((line) => line.code == 'op_crease');
    expect(crease.amount.raw, 6000);
  });

  test('a minimum charge is applied when the run is tiny', () {
    final priced = PricingEngine.price(
      const PriceRequest(
        productId: 'prod_business_cards',
        kind: ProductKind.sheet,
        quantity: 20,
        widthMm: 90,
        heightMm: 55,
        sides: 1,
      ),
      contextWith(
        operations: const <FinishingOperation>[
          FinishingOperation(
            code: 'saddle',
            name: 'Saddle stitch',
            basis: OperationBasis.perCopy,
            rateFils: 150,
            minChargeFils: 15000, // AED 150 minimum
          ),
        ],
      ),
    );

    final line = priced.lines.firstWhere((row) => row.code == 'op_saddle');
    expect(line.amount.raw, 15000, reason: 'the minimum wins on a tiny run');
  });
}
