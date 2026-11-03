import 'dart:convert';
import 'dart:io';

import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:test/test.dart';

/// Finds the repository root by walking up until `shared_test_vectors` appears.
/// Keeps the vectors usable from `dart test`, from CI and from an IDE runner,
/// without hard-coding a machine-specific path.
Directory _repositoryRoot() {
  var current = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${current.path}/shared_test_vectors').existsSync() ||
        Directory('${current.path}/packages/shared_test_vectors')
            .existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  throw StateError(
    'Could not find shared_test_vectors from ${Directory.current}',
  );
}

Directory _vectorsDirectory() {
  final root = _repositoryRoot();
  final direct = Directory('${root.path}/shared_test_vectors/pricing');
  if (direct.existsSync()) {
    return direct;
  }
  return Directory('${root.path}/packages/shared_test_vectors/pricing');
}

void main() {
  group('shared pricing vectors', () {
    final files =
        _vectorsDirectory()
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('the vector directory is not empty', () {
      expect(
        files,
        isNotEmpty,
        reason:
            'golden vectors are the contract with the shop; do not '
            'delete them to make a test pass',
      );
    });

    for (final file in files) {
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final vector = PricingVector.fromJson(raw);

      test('${file.uri.pathSegments.last}: ${vector.name}', () {
        final actual = vector.actualJson();
        expect(
          vector.note,
          isNotEmpty,
          reason: 'every vector must explain its arithmetic in plain English',
        );
        expect(actual, vector.expectedJson);
      });
    }
  });

  group('layout', () {
    test('90×55 mm cards are 21-up on SRA3', () {
      final fit = fitOnSheet(
        pieceWidthMm: 90,
        pieceHeightMm: 55,
        sheet: const SheetSpec(widthMm: 320, heightMm: 450),
        quantity: 500,
      );
      expect(fit.piecesPerSheet, 21);
      expect(fit.piecesAcross, 3);
      expect(fit.piecesDown, 7);
      expect(fit.isRotated, isFalse);
      expect(fit.trimSheets, 24, reason: 'ceil(500 / 21)');
      expect(fit.spoilageSheets, 2, reason: 'ceil(24 × 5%)');
      expect(fit.billableSheets, 28);
    });

    test('turns the piece when that is the only way it fits', () {
      // 400 mm is wider than the 320 mm sheet, so the only option is to turn
      // the piece and pack three of them down the long edge.
      final fit = fitOnSheet(
        pieceWidthMm: 400,
        pieceHeightMm: 100,
        sheet: const SheetSpec(
          widthMm: 320,
          heightMm: 450,
          bleedMm: 0,
          gutterMm: 0,
        ),
        quantity: 3,
      );
      expect(fit.isRotated, isTrue);
      expect(fit.piecesPerSheet, 3);
      expect(fit.trimSheets, 1);
    });

    test('a single copy still costs the make-ready sheets', () {
      final fit = fitOnSheet(
        pieceWidthMm: 90,
        pieceHeightMm: 55,
        sheet: const SheetSpec(widthMm: 320, heightMm: 450),
        quantity: 1,
        setupSheets: 2,
        spoilageBps: 0,
      );
      expect(fit.trimSheets, 1);
      expect(fit.billableSheets, 3);
    });

    test('refuses a size that cannot fit rather than quoting zero', () {
      expect(
        () => fitOnSheet(
          pieceWidthMm: 1200,
          pieceHeightMm: 800,
          sheet: const SheetSpec(widthMm: 320, heightMm: 450),
          quantity: 1,
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

    test('rejects a zero quantity', () {
      expect(
        () => fitOnSheet(
          pieceWidthMm: 90,
          pieceHeightMm: 55,
          sheet: const SheetSpec(widthMm: 320, heightMm: 450),
          quantity: 0,
        ),
        throwsA(
          isA<PricingException>().having(
            (e) => e.code,
            'code',
            'QUANTITY_INVALID',
          ),
        ),
      );
    });
  });

  group('engine behaviour', () {
    const cardsContext = PricingContext(
      priceBookVersion: 1,
      mode: PricingMode.costPlus,
      sheet: SheetSpec(widthMm: 320, heightMm: 450),
      setupSheets: 2,
      spoilageBps: 500,
      materialCostPerSheetFils: 60,
      printRatePerSheetSideFils: 35,
      markupBps: 6500,
      roundingStepFils: 100,
    );

    const cardsRequest = PriceRequest(
      productId: 'p1',
      kind: ProductKind.sheet,
      quantity: 500,
      widthMm: 90,
      heightMm: 55,
      sides: 2,
    );

    test('is deterministic — the same input twice gives the same fils', () {
      final first = PricingEngine.price(cardsRequest, cardsContext);
      final second = PricingEngine.price(cardsRequest, cardsContext);
      expect(first.toJson(), second.toJson());
    });

    test('reports margin from the cost it actually used', () {
      final breakdown = PricingEngine.price(cardsRequest, cardsContext);
      // Cost AED 36.40 (28 sheets of material + 56 sheet-sides of print),
      // marked up 65% to 60.06 and rounded to AED 60.00 → 39.3% margin.
      expect(breakdown.costSubtotal.raw, 3640);
      expect(breakdown.total.raw, 6000);
      expect(breakdown.marginBps, isNotNull);
    });

    test('caps a discount that is larger than the price and says so', () {
      final breakdown = PricingEngine.price(
        const PriceRequest(
          productId: 'p1',
          kind: ProductKind.sheet,
          quantity: 500,
          widthMm: 90,
          heightMm: 55,
          sides: 2,
          discountFils: 999999,
        ),
        cardsContext,
      );
      expect(breakdown.discount.raw, breakdown.priceBeforeDiscount.raw);
      expect(breakdown.netBeforeRounding.raw, 0);
      expect(breakdown.warnings, isNotEmpty);
    });

    test('applies the minimum order charge after the discount', () {
      const context = PricingContext(
        priceBookVersion: 1,
        mode: PricingMode.costPlus,
        sheet: SheetSpec(widthMm: 320, heightMm: 450),
        materialCostPerSheetFils: 60,
        minOrderFils: 10000,
        roundingStepFils: 100,
      );
      final breakdown = PricingEngine.price(
        const PriceRequest(
          productId: 'p1',
          kind: ProductKind.sheet,
          quantity: 50,
          widthMm: 90,
          heightMm: 55,
        ),
        context,
      );
      expect(breakdown.total.raw, greaterThanOrEqualTo(10000));
      expect(breakdown.warnings.join(), contains('minimum order'));
    });

    test('fails loudly when a table product has no price breaks', () {
      expect(
        () => PricingEngine.price(
          const PriceRequest(
            productId: 'p1',
            kind: ProductKind.perUnit,
            quantity: 10,
          ),
          const PricingContext(
            priceBookVersion: 1,
            mode: PricingMode.priceTable,
          ),
        ),
        throwsA(
          isA<PricingException>().having(
            (e) => e.code,
            'code',
            'PRICE_TABLE_MISSING',
          ),
        ),
      );
    });

    test('fails loudly when a sheet product has no sheet size', () {
      expect(
        () => PricingEngine.price(
          cardsRequest,
          const PricingContext(priceBookVersion: 1, mode: PricingMode.costPlus),
        ),
        throwsA(
          isA<PricingException>().having(
            (e) => e.code,
            'code',
            'SHEET_MISSING',
          ),
        ),
      );
    });

    test('rounding is recorded, not silently absorbed', () {
      final breakdown = PricingEngine.price(cardsRequest, cardsContext);
      expect(
        breakdown.netBeforeRounding.raw + breakdown.roundingAdjustment.raw,
        breakdown.total.raw,
      );
    });

    test('VAT is charged on the rounded total, never on the unrounded one', () {
      final breakdown = PricingEngine.price(cardsRequest, cardsContext);
      expect(breakdown.vat.raw, Fils(breakdown.total.raw).timesBps(500).raw);
      expect(breakdown.grandTotal.raw, breakdown.total.raw + breakdown.vat.raw);
    });
  });
}
