/// The pricing pipeline, in the order the design document defines it:
/// layout → material → print → finishing → setup → cost → markup or table →
/// surcharges → discount → minimum → rounding → VAT.
///
/// Every step is integer arithmetic over [Fils]. The engine never reads the
/// clock, the network or a database, so the same request against the same
/// price-book version always produces the same breakdown — which is what makes
/// a five-year-old invoice reproducible during a VAT audit.
library;

import 'package:starparis_domain/starparis_domain.dart';

import 'errors.dart';
import 'layout.dart';
import 'models.dart';
import 'rules.dart';

final class PricingEngine {
  const PricingEngine._();

  /// Prices [request] against [context]. Throws [PricingException] with a
  /// stable code when the inputs are impossible — never returns a wrong number.
  static PriceBreakdown price(PriceRequest request, PricingContext context) {
    if (request.quantity <= 0) {
      throw const PricingException(
        'QUANTITY_INVALID',
        'Quantity must be greater than zero.',
      );
    }
    if (request.sides <= 0) {
      throw const PricingException(
        'SIDES_INVALID',
        'Sides must be 1 or 2.',
      );
    }

    final warnings = <String>[];

    // --- 1. Layout -------------------------------------------------------
    SheetFit? fit;
    var sheets = 0;
    var areaMilliSqm = 0;

    switch (request.kind) {
      case ProductKind.sheet:
        final sheet = context.sheet;
        if (sheet == null) {
          throw const PricingException(
            'SHEET_MISSING',
            'This product needs a sheet size before it can be priced.',
          );
        }
        final width = request.widthMm;
        final height = request.heightMm;
        if (width == null || height == null) {
          throw const PricingException(
            'SIZE_MISSING',
            'Finished width and height are required for sheet products.',
          );
        }
        fit = fitOnSheet(
          pieceWidthMm: width,
          pieceHeightMm: height,
          sheet: sheet,
          quantity: request.quantity,
          setupSheets: context.setupSheets,
          spoilageBps: context.spoilageBps,
        );
        sheets = fit.billableSheets;

      case ProductKind.area:
        final width = request.widthMm;
        final height = request.heightMm;
        if (width == null || height == null) {
          throw const PricingException(
            'SIZE_MISSING',
            'Finished width and height are required for area products.',
          );
        }
        // mm² × qty / 1000 = thousandths of a square metre.
        areaMilliSqm = mulDivRoundHalfUp(width * height, request.quantity, 1000);

      case ProductKind.perUnit:
      case ProductKind.service:
      case ProductKind.outsourced:
        break;
    }

    final facts = <String, Object?>{
      'kind': request.kind.wire,
      'product_id': request.productId,
      'quantity': request.quantity,
      'sides': request.sides,
      'priority': request.priority.wire,
      'customerTier': request.customerTier,
      'material': request.materialCode,
      'finish': request.finishCodes,
      'widthMm': request.widthMm,
      'heightMm': request.heightMm,
      'sheets': sheets,
      'areaMilliSqm': areaMilliSqm,
      'hours': request.hours,
    };

    // In table mode, finishing is charged on top of the table price as an
    // add-on; in cost-plus mode it is part of the cost that gets marked up.
    final isTable = context.mode == PricingMode.priceTable;
    final lines = <PriceLine>[];
    var costSubtotal = Fils.zero;
    var addOns = Fils.zero;

    // --- 2. Material -----------------------------------------------------
    final materialRate = context.materialCostPerSheetFils;
    if (request.kind == ProductKind.sheet && materialRate != null && materialRate > 0) {
      if (sheets > 0) {
        final amount = Fils(materialRate * sheets);
        costSubtotal += amount;
        lines.add(
          PriceLine(
            code: 'material',
            label: request.materialCode == null
                ? 'Material'
                : 'Material — ${request.materialCode}',
            kind: PriceLineKind.cost,
            quantity: sheets,
            rateFils: materialRate,
            amount: amount,
            explain: '$sheets sheets × ${Fils(materialRate).aedLabel}',
          ),
        );
      }
    }

    // --- 3. Print --------------------------------------------------------
    final printRate = context.printRatePerSheetSideFils;
    if (request.kind == ProductKind.sheet && printRate != null && printRate > 0) {
      final units = sheets * request.sides;
      if (units > 0) {
        final amount = Fils(printRate * units);
        costSubtotal += amount;
        lines.add(
          PriceLine(
            code: 'print',
            label: 'Printing',
            kind: PriceLineKind.cost,
            quantity: units,
            rateFils: printRate,
            amount: amount,
            explain: '$sheets sheets × ${request.sides} '
                '${request.sides == 1 ? 'side' : 'sides'} × '
                '${Fils(printRate).aedLabel}',
          ),
        );
      }
    }

    // --- 4. Area material ------------------------------------------------
    final areaRate = context.areaRateFilsPerSqm;
    if (request.kind == ProductKind.area && areaRate != null && areaRate > 0) {
      final amount = Fils(mulDivRoundHalfUp(areaRate, areaMilliSqm, 1000));
      costSubtotal += amount;
      lines.add(
        PriceLine(
          code: 'area',
          label: 'Material — ${_sqmText(areaMilliSqm)} m²',
          kind: PriceLineKind.cost,
          quantity: areaMilliSqm,
          rateFils: areaRate,
          amount: amount,
          explain: '${_sqmText(areaMilliSqm)} m² × ${Fils(areaRate).aedLabel}',
        ),
      );
    }

    // --- 5. Finishing, setup and any other cost rule ---------------------
    final sortedRules = List<PriceRule>.of(context.rules)
      ..sort((a, b) {
        final byPriority = a.priority.compareTo(b.priority);
        return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
      });

    for (final rule in sortedRules) {
      if (rule.phase == RulePhase.surcharge) {
        continue; // handled after the selling price is known
      }
      if (!rule.appliesTo(request, facts)) {
        continue;
      }
      final evaluation = RuleEvaluator(
        sheets: sheets,
        sides: request.sides,
        quantity: request.quantity,
        areaMilliSqm: areaMilliSqm,
        hours: request.hours,
        runningSubtotal: isTable ? addOns : costSubtotal,
      ).evaluate(rule);

      if (evaluation.amount.isZero) {
        continue;
      }

      final kind = isTable ? PriceLineKind.addOn : PriceLineKind.cost;
      lines.add(
        PriceLine(
          code: rule.id,
          label: rule.label,
          kind: kind,
          quantity: evaluation.quantity,
          rateFils: rule.rateFils,
          amount: evaluation.amount,
          explain: evaluation.explain,
        ),
      );
      if (isTable) {
        addOns += evaluation.amount;
      } else {
        costSubtotal += evaluation.amount;
      }
    }

    // --- 6. Selling price ------------------------------------------------
    // Outsourced work carries the vendor invoice as its cost, so the margin on
    // brokered jobs is visible in the same place as everything else.
    if (context.mode == PricingMode.vendorMarkup) {
      final vendorCost = context.vendorCostFils;
      if (vendorCost == null || vendorCost <= 0) {
        throw const PricingException(
          'VENDOR_COST_MISSING',
          'An outsourced item needs the vendor cost before it can be priced.',
        );
      }
      lines.add(
        PriceLine(
          code: 'vendor_cost',
          label: 'Vendor cost',
          kind: PriceLineKind.cost,
          quantity: 1,
          rateFils: vendorCost,
          amount: Fils(vendorCost),
          explain: 'vendor invoice',
        ),
      );
      costSubtotal += Fils(vendorCost);
    }

    final Fils priceBeforeSurcharges;
    switch (context.mode) {
      case PricingMode.costPlus:
        priceBeforeSurcharges = costSubtotal + costSubtotal.timesBps(context.markupBps);
      case PricingMode.priceTable:
        final tier = _tierFor(request, context);
        final tableAmount = Fils(tier.unitPriceFils * request.quantity);
        lines.insert(
          0,
          PriceLine(
            code: 'table_price',
            label: 'Table price',
            kind: PriceLineKind.tablePrice,
            quantity: request.quantity,
            rateFils: tier.unitPriceFils,
            amount: tableAmount,
            explain: '${request.quantity} pieces × ${Fils(tier.unitPriceFils).aedLabel}',
          ),
        );
        priceBeforeSurcharges = tableAmount + addOns;
      case PricingMode.vendorMarkup:
        final vendorCost = context.vendorCostFils!;
        priceBeforeSurcharges =
            Fils(vendorCost) + Fils(vendorCost).timesBps(context.markupBps);
    }

    // --- 7. Surcharges (rush, same day, delivery) ------------------------
    var running = priceBeforeSurcharges;
    var surcharges = Fils.zero;
    for (final rule in sortedRules) {
      if (rule.phase != RulePhase.surcharge || !rule.appliesTo(request, facts)) {
        continue;
      }
      final evaluation = RuleEvaluator(
        sheets: sheets,
        sides: request.sides,
        quantity: request.quantity,
        areaMilliSqm: areaMilliSqm,
        hours: request.hours,
        runningSubtotal: running,
      ).evaluate(rule);
      if (evaluation.amount.isZero) {
        continue;
      }
      lines.add(
        PriceLine(
          code: rule.id,
          label: rule.label,
          kind: PriceLineKind.surcharge,
          quantity: evaluation.quantity,
          rateFils: rule.rateFils,
          amount: evaluation.amount,
          explain: evaluation.explain,
        ),
      );
      running += evaluation.amount;
      surcharges += evaluation.amount;
    }
    final priceBeforeDiscount = running;

    // --- 8. Discount -----------------------------------------------------
    var discount = priceBeforeDiscount.timesBps(request.discountBps) +
        Fils(request.discountFils);
    if (discount > priceBeforeDiscount) {
      warnings.add('Discount was larger than the price and has been capped.');
      discount = priceBeforeDiscount;
    }
    if (discount.isPositive) {
      lines.add(
        PriceLine(
          code: 'discount',
          label: 'Discount',
          kind: PriceLineKind.discount,
          quantity: 1,
          rateFils: request.discountBps,
          amount: discount,
          explain: _discountExplain(request, discount),
        ),
      );
    }

    var net = (priceBeforeDiscount - discount).clampNonNegative();

    // --- 9. Minimum order ------------------------------------------------
    final minimum = Fils(context.minOrderFils);
    if (minimum.isPositive && net < minimum) {
      warnings.add('Raised to the minimum order charge of ${minimum.aedLabel}.');
      net = minimum;
    }

    // --- 10. Rounding ----------------------------------------------------
    final rounded = net.roundToStep(context.roundingStepFils);
    final adjustment = rounded - net;

    // --- 11. VAT ---------------------------------------------------------
    final vat = rounded.timesBps(context.vatBps);

    return PriceBreakdown(
      priceBookVersion: context.priceBookVersion,
      lines: List<PriceLine>.unmodifiable(lines),
      costSubtotal: costSubtotal,
      addOns: addOns,
      priceBeforeSurcharges: priceBeforeSurcharges,
      surcharges: surcharges,
      priceBeforeDiscount: priceBeforeDiscount,
      discount: discount,
      netBeforeRounding: net,
      roundingAdjustment: adjustment,
      total: rounded,
      vat: vat,
      grandTotal: rounded + vat,
      vatBps: context.vatBps,
      roundingStepFils: context.roundingStepFils,
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  /// Convenience for the JSON contract used by the shared test vectors and,
  /// later, by the TypeScript port.
  static Map<String, Object?> priceJson(
    Map<String, Object?> requestJson,
    Map<String, Object?> contextJson,
  ) =>
      price(
        PriceRequest.fromJson(requestJson),
        PricingContext.fromJson(contextJson),
      ).toJson();

  static PriceTier _tierFor(PriceRequest request, PricingContext context) {
    if (context.tiers.isEmpty) {
      throw const PricingException(
        'PRICE_TABLE_MISSING',
        'This product is priced from a table, but no price breaks are set up.',
      );
    }
    for (final tier in context.tiers) {
      if (tier.contains(request.quantity)) {
        return tier;
      }
    }
    throw PricingException(
      'PRICE_TIER_NOT_FOUND',
      'No price break covers a quantity of ${request.quantity}.',
      details: <String, Object?>{'quantity': request.quantity},
    );
  }

  static String _discountExplain(PriceRequest request, Fils amount) {
    if (request.discountBps > 0 && request.discountFils > 0) {
      return '${_percentText(request.discountBps)} plus '
          '${Fils(request.discountFils).aedLabel}';
    }
    if (request.discountBps > 0) {
      return _percentText(request.discountBps);
    }
    return 'fixed ${amount.aedLabel}';
  }

  static String _percentText(int bps) {
    final whole = bps ~/ 100;
    final fraction = bps % 100;
    return fraction == 0 ? '$whole%' : '$whole.${fraction.toString().padLeft(2, '0')}%';
  }

  static String _sqmText(int milliSqm) {
    final whole = milliSqm ~/ 1000;
    final fraction = (milliSqm % 1000).toString().padLeft(3, '0');
    return '$whole.$fraction';
  }
}
