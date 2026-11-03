import 'package:starparis_pricing/pricing_engine.dart';
import 'package:test/test.dart';

/// The four print parameters the shop argues about at the counter.
///
/// Grain direction, what the press cannot print on, how much ink the job lays
/// down, and the stock a finishing step loses on its own. Each one is a number
/// a pressman already knows; until it is in the engine it lives in somebody's
/// head, and a quote is only as good as the head it came from.
///
/// 90 × 55 mm cards with 3 mm bleed pack 3 across and 7 down on SRA3
/// (320 × 450) — 21 up — which is the layout every test here starts from.
void main() {
  const sra3 = SheetSpec(widthMm: 320, heightMm: 450);

  const cards = PriceRequest(
    productId: 'prod_business_cards',
    kind: ProductKind.sheet,
    quantity: 500,
    widthMm: 90,
    heightMm: 55,
    sides: 2,
    materialCode: 'art_card_350',
    finishCodes: <String>['matt_lamination'],
  );

  PricingContext contextWith({
    SheetSpec sheet = sra3,
    int spoilageBps = 500,
    int grainWasteBps = 0,
    int? colours,
    int? inkCoverageBps,
    int extraColourFils = 0,
    List<FinishingOperation> operations = const <FinishingOperation>[],
    List<PriceRule> rules = const <PriceRule>[],
  }) => PricingContext(
    priceBookVersion: 7,
    mode: PricingMode.costPlus,
    sheet: sheet,
    setupSheets: 2,
    spoilageBps: spoilageBps,
    materialCostPerSheetFils: 60,
    printRatePerSheetSideFils: 35,
    operations: operations,
    rules: rules,
    markupBps: 6500,
    roundingStepFils: 100,
    vatBps: 500,
    grainWasteBps: grainWasteBps,
    colours: colours,
    inkCoverageBps: inkCoverageBps,
    extraColourFils: extraColourFils,
  );

  group('grain direction', () {
    test('turns the piece onto the grain when that resolves the conflict', () {
      // Long-grain stock on a 450 mm-high sheet runs down the sheet, and a card
      // wants its fibres along its own 90 mm side. Laying the card across the
      // sheet puts the grain along the 55 mm side, so the layout has to turn
      // it — 5 across × 4 down instead of 3 across × 7 down, 20 up not 21.
      final turned = fitOnSheet(
        pieceWidthMm: 90,
        pieceHeightMm: 55,
        sheet: const SheetSpec(
          widthMm: 320,
          heightMm: 450,
          grain: GrainDirection.long,
        ),
        quantity: 500,
        requiredGrain: GrainDirection.long,
        grainWasteBps: 1000,
      );

      expect(turned.isRotated, isTrue);
      expect(turned.isGrainCompromised, isFalse);
      expect(turned.grainWasteSheets, 0, reason: 'turning it is free');
      expect(turned.piecesPerSheet, 20);
      expect(turned.piecesAcross, 5);
      expect(turned.piecesDown, 4);

      final priced = PricingEngine.price(
        cards,
        contextWith(
          sheet: const SheetSpec(
            widthMm: 320,
            heightMm: 450,
            grain: GrainDirection.long,
          ),
          grainWasteBps: 1000,
        ),
      );
      expect(
        priced.lines.any((line) => line.code == 'grain'),
        isFalse,
        reason: 'the conflict was resolved, so there is nothing to allow for',
      );
    });

    test('allows for the stock when turning cannot save the grain', () {
      // 150 × 420 mm pieces: the only way this size fits SRA3 at all is with
      // the 420 mm side down the sheet. On short-grain stock that is across the
      // grain, and turning it the other way fits nothing — the job has to run
      // the wrong way and lose stock doing it.
      const tall = SheetSpec(
        widthMm: 320,
        heightMm: 450,
        bleedMm: 0,
        gutterMm: 0,
      );
      final crossGrain = fitOnSheet(
        pieceWidthMm: 150,
        pieceHeightMm: 420,
        sheet: tall.copyWithGrain(GrainDirection.short),
        quantity: 40,
        requiredGrain: GrainDirection.long,
        grainWasteBps: 1000,
      );

      // 40 pieces ÷ 2 up = 20 trim + 1 spoilage + 2 make-ready = 23 sheets,
      // and 10% of 23 sheets is 2.3, rounded up to 3.
      expect(crossGrain.piecesPerSheet, 2);
      expect(crossGrain.billableSheets, 23);
      expect(crossGrain.isGrainCompromised, isTrue);
      expect(crossGrain.grainWasteSheets, 3);
    });

    test('a conflict costs more than the same job on the right stock', () {
      const request = PriceRequest(
        productId: 'prod_tall_menu',
        kind: ProductKind.sheet,
        quantity: 40,
        widthMm: 150,
        heightMm: 420,
        sides: 1,
        requiredGrain: GrainDirection.long,
      );
      const tall = SheetSpec(
        widthMm: 320,
        heightMm: 450,
        bleedMm: 0,
        gutterMm: 0,
      );

      final rightStock = PricingEngine.price(
        request,
        contextWith(
          sheet: tall.copyWithGrain(GrainDirection.long),
          grainWasteBps: 1000,
        ),
      );
      final wrongStock = PricingEngine.price(
        request,
        contextWith(
          sheet: tall.copyWithGrain(GrainDirection.short),
          grainWasteBps: 1000,
        ),
      );

      final line = wrongStock.lines.firstWhere((row) => row.code == 'grain');
      expect(line.quantity, 3, reason: 'three sheets of waste at 10%');
      expect(line.amount.raw, 180, reason: '3 sheets × AED 0.60');
      expect(line.explain, contains('grain'));

      expect(
        wrongStock.costSubtotal.raw,
        greaterThan(rightStock.costSubtotal.raw),
      );
      expect(wrongStock.total.raw, greaterThan(rightStock.total.raw));
    });

    test('an unrecorded grain is not a conflict', () {
      // The shop has not said which way its stock runs. That is ignorance, not
      // a mismatch, so the engine must not invent a penalty for it.
      final fit = fitOnSheet(
        pieceWidthMm: 90,
        pieceHeightMm: 55,
        sheet: sra3,
        quantity: 500,
        requiredGrain: GrainDirection.long,
        grainWasteBps: 1000,
      );
      expect(fit.piecesPerSheet, 21);
      expect(fit.isGrainCompromised, isFalse);
      expect(fit.grainWasteSheets, 0);
    });
  });

  group('gripper and trim', () {
    test('the printable area decides the layout, not the bare sheet', () {
      // 10 mm of gripper and 3 mm of trim leave 314 × 434 mm printable, which
      // drops the card layout from 21 up to 18 up: 3 across, 6 down.
      const pinned = SheetSpec(
        widthMm: 320,
        heightMm: 450,
        gripperMm: 10,
        trimMm: 3,
      );
      expect(pinned.printableWidthMm, 314);
      expect(pinned.printableHeightMm, 434);

      final loose = fitOnSheet(
        pieceWidthMm: 90,
        pieceHeightMm: 55,
        sheet: sra3,
        quantity: 500,
      );
      final tight = fitOnSheet(
        pieceWidthMm: 90,
        pieceHeightMm: 55,
        sheet: pinned,
        quantity: 500,
      );

      expect(loose.piecesPerSheet, 21);
      expect(tight.piecesPerSheet, 18);

      // 500 ÷ 18 = 28 trim sheets, + 2 spoilage + 2 make-ready = 32, against
      // 28 sheets on the bare sheet.
      expect(tight.billableSheets, greaterThan(loose.billableSheets));
      expect(tight.trimSheets, 28);
      expect(tight.billableSheets, 32);
    });

    test('and the sheets the job is charged for follow the layout', () {
      final priced = PricingEngine.price(
        cards,
        contextWith(
          sheet: const SheetSpec(
            widthMm: 320,
            heightMm: 450,
            gripperMm: 10,
            trimMm: 3,
          ),
        ),
      );
      final material = priced.lines.firstWhere((row) => row.code == 'material');
      final print = priced.lines.firstWhere((row) => row.code == 'print');

      expect(
        material.quantity,
        32,
        reason: 'gripper and trim raise the sheets',
      );
      expect(material.amount.raw, 32 * 60);
      expect(print.quantity, 32 * 2);
    });

    test('refuses to quote when the allowances leave nothing to print on', () {
      expect(
        () => fitOnSheet(
          pieceWidthMm: 90,
          pieceHeightMm: 55,
          sheet: const SheetSpec(widthMm: 320, heightMm: 450, gripperMm: 450),
          quantity: 10,
        ),
        throwsA(
          isA<PricingException>().having(
            (e) => e.code,
            'code',
            'SIZE_DOES_NOT_FIT',
          ),
        ),
      );
    });
  });

  group('ink coverage and colour count', () {
    test('four colours at full coverage costs more than at half', () {
      final full = PricingEngine.price(
        cards,
        contextWith(colours: 4, inkCoverageBps: 10000, extraColourFils: 15),
      );
      final half = PricingEngine.price(
        cards,
        contextWith(colours: 4, inkCoverageBps: 5000, extraColourFils: 15),
      );

      // AED 0.35 a side plus 15 fils for each of the three extra colours is
      // AED 0.80 a side; half coverage is AED 0.40 a side. 28 sheets × 2 sides.
      final fullPrint = full.lines.firstWhere((row) => row.code == 'print');
      final halfPrint = half.lines.firstWhere((row) => row.code == 'print');
      expect(fullPrint.rateFils, 80);
      expect(halfPrint.rateFils, 40);
      expect(fullPrint.amount.raw, 80 * 56);
      expect(halfPrint.amount.raw, 40 * 56);
      expect(fullPrint.explain, contains('4 colours at 100% ink coverage'));

      expect(full.total.raw, greaterThan(half.total.raw));
    });

    test('mono is priced by the click, not by the ink on the sheet', () {
      // A black click costs the shop the same whether the page is 5% or 95%
      // black, so one colour must price exactly as the job did before these
      // settings existed — all the way down to the breakdown JSON.
      final before = PricingEngine.price(cards, contextWith());

      for (final coverage in <int>[0, 5000, 10000]) {
        final mono = PricingEngine.price(
          cards,
          contextWith(
            colours: 1,
            inkCoverageBps: coverage,
            extraColourFils: 15,
          ),
        );
        expect(
          mono.toJson(),
          before.toJson(),
          reason: 'mono at $coverage bps coverage must not move the price',
        );
      }
    });

    test('a colour count the press cannot run is refused', () {
      expect(
        () => PricingEngine.price(cards, contextWith(colours: 5)),
        throwsA(
          isA<PricingException>().having(
            (e) => e.code,
            'code',
            'PRINT_SETTINGS_INVALID',
          ),
        ),
      );
      expect(
        () => PricingEngine.price(cards, contextWith(inkCoverageBps: 12000)),
        throwsA(
          isA<PricingException>().having(
            (e) => e.code,
            'code',
            'PRINT_SETTINGS_INVALID',
          ),
        ),
      );
    });
  });

  group('operation waste', () {
    // 798 cards at 21 up is exactly 38 trim sheets; with 2 make-ready sheets and
    // no spoilage that is 40 sheets, so 5% waste is exactly 2 sheets and the
    // arithmetic can be checked without a rounding argument.
    const job = PriceRequest(
      productId: 'prod_business_cards',
      kind: ProductKind.sheet,
      quantity: 798,
      widthMm: 90,
      heightMm: 55,
      sides: 1,
    );

    test('a sheet-fed step is charged on the sheets plus its own waste', () {
      final priced = PricingEngine.price(
        job,
        contextWith(
          spoilageBps: 0,
          operations: const <FinishingOperation>[
            FinishingOperation(
              code: 'lam_matt',
              name: 'Matt lamination',
              basis: OperationBasis.perSheet,
              rateFils: 80,
              wasteBps: 500,
            ),
          ],
        ),
      );

      final run = priced.lines.firstWhere((row) => row.code == 'op_lam_matt');
      expect(run.quantity, 40, reason: 'the job consumes 40 billable sheets');
      expect(run.amount.raw, 40 * 80);

      final waste = priced.lines.firstWhere(
        (row) => row.code == 'op_lam_matt_waste',
      );
      expect(waste.quantity, 2, reason: 'exactly 5% of 40 sheets');
      expect(waste.amount.raw, 2 * 80);
      expect(waste.label, contains('Matt lamination'));
      expect(waste.explain, contains('2 extra sheets'));
      expect(waste.explain, contains('5%'));
    });

    test('a step without waste carries no waste line', () {
      final priced = PricingEngine.price(
        job,
        contextWith(
          spoilageBps: 0,
          operations: const <FinishingOperation>[
            FinishingOperation(
              code: 'lam_matt',
              name: 'Matt lamination',
              basis: OperationBasis.perSheet,
              rateFils: 80,
            ),
          ],
        ),
      );

      expect(
        priced.lines.any((row) => row.code == 'op_lam_matt_waste'),
        isFalse,
      );
      expect(priced.costSubtotal.raw, 40 * 60 + 40 * 35 + 40 * 80);
    });

    test('a piece-rated step loses pieces, not sheets', () {
      final priced = PricingEngine.price(
        cards,
        contextWith(
          operations: const <FinishingOperation>[
            FinishingOperation(
              code: 'foil',
              name: 'Foil stamping',
              basis: OperationBasis.perPiece,
              rateFils: 40,
              wasteBps: 500,
            ),
          ],
        ),
      );

      final waste = priced.lines.firstWhere(
        (row) => row.code == 'op_foil_waste',
      );
      expect(waste.quantity, 25, reason: '5% of 500 pieces');
      expect(waste.amount.raw, 25 * 40);
      expect(waste.explain, contains('25 extra pieces'));
    });
  });

  test('the shop\'s 500-card vector still prices at 122.00 + 6.10', () {
    // The number the owner signed off on, priced from the parameters this file
    // exercises: if the grain, gripper, ink or waste work moves this, it moves
    // the shop's headline price and the vector file has to say so first.
    final priced = PricingEngine.price(
      cards,
      contextWith(
        rules: const <PriceRule>[
          PriceRule(
            id: 'rule_lamination_matt',
            label: 'Matt lamination (both sides)',
            phase: RulePhase.finishing,
            basis: RuleBasis.perSheet,
            rateFils: 80,
            productKinds: <ProductKind>{ProductKind.sheet},
            when: <RuleCondition>[
              RuleCondition('finish', ConditionOp.contains, 'matt_lamination'),
            ],
            priority: 40,
          ),
          PriceRule(
            id: 'rule_cutting',
            label: 'Cutting',
            phase: RulePhase.finishing,
            basis: RuleBasis.flat,
            rateFils: 500,
            productKinds: <ProductKind>{ProductKind.sheet},
            priority: 60,
          ),
          PriceRule(
            id: 'rule_file_check',
            label: 'File check and setup',
            phase: RulePhase.setup,
            basis: RuleBasis.flat,
            rateFils: 1000,
            productKinds: <ProductKind>{ProductKind.sheet},
            priority: 95,
          ),
        ],
      ),
    );

    expect(priced.costSubtotal.raw, 7380);
    expect(priced.total.raw, 12200);
    expect(priced.vat.raw, 610);
    expect(priced.grandTotal.raw, 12810);
  });
}

/// A copy of a sheet with a different grain, so a test can price the same job
/// on the right stock and on the wrong stock and compare the two.
extension on SheetSpec {
  SheetSpec copyWithGrain(GrainDirection grain) => SheetSpec(
    widthMm: widthMm,
    heightMm: heightMm,
    bleedMm: bleedMm,
    gutterMm: gutterMm,
    label: label,
    grain: grain,
    gripperMm: gripperMm,
    trimMm: trimMm,
  );
}
