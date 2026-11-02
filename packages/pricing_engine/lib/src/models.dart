/// Inputs, rules and the breakdown the engine returns.
///
/// Everything here is data. Nothing in this file knows how to price anything;
/// that is [PricingEngine]'s job, and it is driven entirely by the rule list in
/// [PricingContext] — which is why the owner can change a price without a
/// developer.
library;

import 'package:starparis_domain/starparis_domain.dart';

import 'layout.dart';

/// How a product is priced. Mirrors the design's §7.2 table.
enum ProductKind {
  /// Business cards, flyers, brochures — priced by sheets consumed.
  sheet('sheet'),

  /// Banners, stickers, vinyl — priced by square metre with a minimum charge.
  area('area'),

  /// T-shirts, mugs, notebooks — unit price with quantity tiers.
  perUnit('per_unit'),

  /// Design, logo, artwork revisions — fixed fee or hourly.
  service('service'),

  /// Made by a vendor — cost plus markup or commission.
  outsourced('outsourced');

  const ProductKind(this.wire);

  final String wire;

  static ProductKind fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () =>
            throw ArgumentError.value(wire, 'wire', 'unknown ProductKind'),
      );
}

/// How the selling price is derived from the cost.
enum PricingMode {
  /// Cost of material, print and finishing, plus a markup.
  costPlus('cost_plus'),

  /// A direct price matrix — "500 cards, matt, double sided = AED 85".
  priceTable('price_table'),

  /// Vendor cost plus markup or fixed commission.
  vendorMarkup('vendor_markup');

  const PricingMode(this.wire);

  final String wire;

  static PricingMode fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () =>
            throw ArgumentError.value(wire, 'wire', 'unknown PricingMode'),
      );
}

/// Where a rule sits in the calculation pipeline.
enum RulePhase {
  material('material'),
  print('print'),
  finishing('finishing'),
  setup('setup'),

  /// Applied after the selling price is known: rush, same-day, delivery.
  surcharge('surcharge');

  const RulePhase(this.wire);

  final String wire;

  static RulePhase fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () =>
            throw ArgumentError.value(wire, 'wire', 'unknown RulePhase'),
      );
}

/// What a rule multiplies its rate by.
enum RuleBasis {
  flat('flat'),
  perSheet('per_sheet'),
  perSheetSide('per_sheet_side'),
  perPiece('per_piece'),
  perSqm('per_sqm'),
  perHour('per_hour'),
  percentOfSubtotal('percent_of_subtotal');

  const RuleBasis(this.wire);

  final String wire;

  static RuleBasis fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () =>
            throw ArgumentError.value(wire, 'wire', 'unknown RuleBasis'),
      );
}

/// Comparison operators a rule condition may use. Deliberately tiny: a pricing
/// rule is a price list, not a programming language.
enum ConditionOp {
  eq('eq'),
  neq('neq'),
  gte('gte'),
  lte('lte'),
  inList('in'),
  notInList('not_in'),
  contains('contains'),
  truthy('truthy');

  const ConditionOp(this.wire);

  final String wire;

  static ConditionOp fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () =>
            throw ArgumentError.value(wire, 'wire', 'unknown ConditionOp'),
      );
}

/// One test against the request facts, for example
/// `finish contains matt_lamination`.
final class RuleCondition {
  const RuleCondition(this.field, this.op, [this.value]);

  /// A key from the fact map: `quantity`, `sides`, `priority`, `customerTier`,
  /// `material`, `finish`, `widthMm`, `heightMm`, `sheets`, `areaMilliSqm`.
  final String field;
  final ConditionOp op;
  final Object? value;

  bool matches(Map<String, Object?> facts) {
    final actual = facts[field];
    return switch (op) {
      ConditionOp.eq => actual == value,
      ConditionOp.neq => actual != value,
      ConditionOp.gte => _compare(actual, value) >= 0,
      ConditionOp.lte => _compare(actual, value) <= 0,
      ConditionOp.inList => _asList(value).contains(actual),
      ConditionOp.notInList => !_asList(value).contains(actual),
      ConditionOp.contains => _contains(actual, value),
      ConditionOp.truthy => actual == true,
    };
  }

  factory RuleCondition.fromJson(Map<String, Object?> json) => RuleCondition(
        json['field']! as String,
        ConditionOp.fromWire(json['op']! as String),
        json['value'],
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'field': field,
        'op': op.wire,
        if (value != null) 'value': value,
      };

  static int _compare(Object? a, Object? b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    throw ArgumentError('Cannot compare $a with $b');
  }

  static List<Object?> _asList(Object? value) =>
      value is List ? value.cast<Object?>() : <Object?>[value];

  static bool _contains(Object? actual, Object? needle) {
    if (actual is List) {
      return actual.contains(needle);
    }
    if (actual is String && needle is String) {
      return actual.contains(needle);
    }
    return false;
  }
}

/// One line of the price book, as data.
///
/// A rule that applies to nothing is harmless; a rule that applies to
/// everything is a bug waiting to happen, so [productKinds] and [productIds]
/// default to empty meaning "any".
final class PriceRule {
  const PriceRule({
    required this.id,
    required this.label,
    required this.phase,
    required this.basis,
    required this.rateFils,
    this.productKinds = const <ProductKind>{},
    this.productIds = const <String>{},
    this.when = const <RuleCondition>[],
    this.minChargeFils = 0,
    this.priority = 100,
    this.quantityFrom,
    this.quantityTo,
  });

  /// Stable identifier, e.g. `rule_lamination_matt`. Appears in the breakdown
  /// so a quote line can be traced back to the rule that produced it.
  final String id;
  final String label;
  final RulePhase phase;
  final RuleBasis basis;

  /// Rate in fils, or basis points for [RuleBasis.percentOfSubtotal].
  final int rateFils;

  final Set<ProductKind> productKinds;
  final Set<String> productIds;
  final List<RuleCondition> when;

  /// A floor for this line: "lamination minimum AED 10".
  final int minChargeFils;

  /// Lower runs first. Material 10, print 20, finishing 40–90, setup 95.
  final int priority;

  final int? quantityFrom;
  final int? quantityTo;

  /// True when this rule's conditions are met for [request] at [facts].
  bool appliesTo(PriceRequest request, Map<String, Object?> facts) {
    if (productIds.isNotEmpty && !productIds.contains(request.productId)) {
      return false;
    }
    if (productKinds.isNotEmpty && !productKinds.contains(request.kind)) {
      return false;
    }
    if (quantityFrom != null && request.quantity < quantityFrom!) {
      return false;
    }
    if (quantityTo != null && request.quantity > quantityTo!) {
      return false;
    }
    for (final condition in when) {
      if (!condition.matches(facts)) {
        return false;
      }
    }
    return true;
  }

  factory PriceRule.fromJson(Map<String, Object?> json) => PriceRule(
        id: json['id']! as String,
        label: (json['label'] as String?) ?? json['id']! as String,
        phase: RulePhase.fromWire(json['phase']! as String),
        basis: RuleBasis.fromWire(json['basis']! as String),
        rateFils: (json['rate_fils']! as num).toInt(),
        productKinds: <ProductKind>{
          for (final kind in (json['product_kinds'] as List<Object?>? ?? const []))
            ProductKind.fromWire(kind! as String),
        },
        productIds: <String>{
          for (final id in (json['product_ids'] as List<Object?>? ?? const []))
            id! as String,
        },
        when: <RuleCondition>[
          for (final condition
              in (json['when'] as List<Object?>? ?? const <Object?>[]))
            RuleCondition.fromJson((condition! as Map).cast<String, Object?>()),
        ],
        minChargeFils: ((json['min_charge_fils'] as num?) ?? 0).toInt(),
        priority: ((json['priority'] as num?) ?? 100).toInt(),
        quantityFrom: (json['quantity_from'] as num?)?.toInt(),
        quantityTo: (json['quantity_to'] as num?)?.toInt(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'phase': phase.wire,
        'basis': basis.wire,
        'rate_fils': rateFils,
        if (productKinds.isNotEmpty)
          'product_kinds': <String>[for (final k in productKinds) k.wire],
        if (productIds.isNotEmpty) 'product_ids': productIds.toList(),
        if (when.isNotEmpty)
          'when': <Map<String, Object?>>[for (final c in when) c.toJson()],
        if (minChargeFils != 0) 'min_charge_fils': minChargeFils,
        'priority': priority,
        if (quantityFrom != null) 'quantity_from': quantityFrom,
        if (quantityTo != null) 'quantity_to': quantityTo,
      };
}

/// A quantity break for table pricing: 500–999 cards at 17 fils each.
final class PriceTier {
  const PriceTier({required this.qtyFrom, this.qtyTo, required this.unitPriceFils});

  final int qtyFrom;
  final int? qtyTo;
  final int unitPriceFils;

  bool contains(int quantity) =>
      quantity >= qtyFrom && (qtyTo == null || quantity <= qtyTo!);

  factory PriceTier.fromJson(Map<String, Object?> json) => PriceTier(
        qtyFrom: (json['qty_from']! as num).toInt(),
        qtyTo: (json['qty_to'] as num?)?.toInt(),
        unitPriceFils: (json['unit_price_fils']! as num).toInt(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'qty_from': qtyFrom,
        if (qtyTo != null) 'qty_to': qtyTo,
        'unit_price_fils': unitPriceFils,
      };
}

/// What the counter asked for. This is the whole input surface for pricing.
final class PriceRequest {
  const PriceRequest({
    required this.productId,
    required this.kind,
    required this.quantity,
    this.widthMm,
    this.heightMm,
    this.sides = 1,
    this.materialCode,
    this.finishCodes = const <String>[],
    this.priority = Priority.normal,
    this.customerTier = 'retail',
    this.discountBps = 0,
    this.discountFils = 0,
    this.hours = 0,
  });

  final String productId;
  final ProductKind kind;
  final int quantity;

  /// Finished size. Required for [ProductKind.sheet] and [ProductKind.area].
  final int? widthMm;
  final int? heightMm;

  /// 1 or 2 in practice; kept as an int because perfecting presses exist.
  final int sides;

  final String? materialCode;
  final List<String> finishCodes;
  final Priority priority;
  final String customerTier;

  /// Discount as basis points of the selling price, plus a fixed amount.
  /// Approval limits are a permission concern, not a pricing concern — by the
  /// time a Discount reaches this level it has already been approved.
  final int discountBps;
  final int discountFils;

  /// For [ProductKind.service] and [RuleBasis.perHour].
  final int hours;

  factory PriceRequest.fromJson(Map<String, Object?> json) => PriceRequest(
        productId: json['product_id']! as String,
        kind: ProductKind.fromWire(json['kind']! as String),
        quantity: (json['quantity']! as num).toInt(),
        widthMm: (json['width_mm'] as num?)?.toInt(),
        heightMm: (json['height_mm'] as num?)?.toInt(),
        sides: ((json['sides'] as num?) ?? 1).toInt(),
        materialCode: json['material'] as String?,
        finishCodes: <String>[
          for (final code in (json['finish'] as List<Object?>? ?? const []))
            code! as String,
        ],
        priority: json['priority'] == null
            ? Priority.normal
            : Priority.values.firstWhere(
                (p) => p.wire == json['priority'],
                orElse: () => Priority.normal,
              ),
        customerTier: (json['customer_tier'] as String?) ?? 'retail',
        discountBps: ((json['discount_bps'] as num?) ?? 0).toInt(),
        discountFils: ((json['discount_fils'] as num?) ?? 0).toInt(),
        hours: ((json['hours'] as num?) ?? 0).toInt(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'product_id': productId,
        'kind': kind.wire,
        'quantity': quantity,
        if (widthMm != null) 'width_mm': widthMm,
        if (heightMm != null) 'height_mm': heightMm,
        'sides': sides,
        if (materialCode != null) 'material': materialCode,
        if (finishCodes.isNotEmpty) 'finish': finishCodes,
        'priority': priority.wire,
        'customer_tier': customerTier,
        if (discountBps != 0) 'discount_bps': discountBps,
        if (discountFils != 0) 'discount_fils': discountFils,
        if (hours != 0) 'hours': hours,
      };
}

/// The price book snapshot the engine works against. Versioned and immutable:
/// an old quote must be reproducible from the version it was priced with.
final class PricingContext {
  const PricingContext({
    required this.priceBookVersion,
    required this.mode,
    this.rules = const <PriceRule>[],
    this.sheet,
    this.setupSheets = 2,
    this.spoilageBps = 500,
    this.materialCostPerSheetFils,
    this.printRatePerSheetSideFils,
    this.areaRateFilsPerSqm,
    this.vendorCostFils,
    this.tiers = const <PriceTier>[],
    this.markupBps = 0,
    this.minOrderFils = 0,
    this.roundingStepFils = 100,
    this.vatBps = 500,
  });

  final int priceBookVersion;
  final PricingMode mode;
  final List<PriceRule> rules;

  /// Required when a [ProductKind.sheet] product is priced.
  final SheetSpec? sheet;

  final int setupSheets;
  final int spoilageBps;

  /// From the materials table: cost of one sheet of the chosen stock.
  final int? materialCostPerSheetFils;

  /// From the machines table: cost per sheet per side, colour or mono.
  final int? printRatePerSheetSideFils;

  /// For [ProductKind.area].
  final int? areaRateFilsPerSqm;

  /// For [ProductKind.outsourced] — what the vendor charges.
  final int? vendorCostFils;

  /// Quantity breaks for [PricingMode.priceTable].
  final List<PriceTier> tiers;

  /// Markup in basis points, already resolved for the customer tier.
  final int markupBps;

  /// Floor for the whole quote, after discount.
  final int minOrderFils;

  /// 25 fils, 100 fils… whatever the owner configured.
  final int roundingStepFils;

  /// 500 bps = 5% UAE VAT. Zero for exports.
  final int vatBps;

  factory PricingContext.fromJson(Map<String, Object?> json) => PricingContext(
        priceBookVersion: (json['price_book_version']! as num).toInt(),
        mode: PricingMode.fromWire(json['mode']! as String),
        rules: <PriceRule>[
          for (final rule in (json['rules'] as List<Object?>? ?? const []))
            PriceRule.fromJson((rule! as Map).cast<String, Object?>()),
        ],
        sheet: json['sheet'] == null
            ? null
            : SheetSpec.fromJson((json['sheet']! as Map).cast<String, Object?>()),
        setupSheets: ((json['setup_sheets'] as num?) ?? 2).toInt(),
        spoilageBps: ((json['spoilage_bps'] as num?) ?? 500).toInt(),
        materialCostPerSheetFils:
            (json['material_cost_per_sheet_fils'] as num?)?.toInt(),
        printRatePerSheetSideFils:
            (json['print_rate_per_sheet_side_fils'] as num?)?.toInt(),
        areaRateFilsPerSqm: (json['area_rate_fils_per_sqm'] as num?)?.toInt(),
        vendorCostFils: (json['vendor_cost_fils'] as num?)?.toInt(),
        tiers: <PriceTier>[
          for (final tier in (json['tiers'] as List<Object?>? ?? const []))
            PriceTier.fromJson((tier! as Map).cast<String, Object?>()),
        ],
        markupBps: ((json['markup_bps'] as num?) ?? 0).toInt(),
        minOrderFils: ((json['min_order_fils'] as num?) ?? 0).toInt(),
        roundingStepFils: ((json['rounding_step_fils'] as num?) ?? 100).toInt(),
        vatBps: ((json['vat_bps'] as num?) ?? 500).toInt(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'price_book_version': priceBookVersion,
        'mode': mode.wire,
        'rules': <Map<String, Object?>>[for (final r in rules) r.toJson()],
        if (sheet != null) 'sheet': sheet!.toJson(),
        'setup_sheets': setupSheets,
        'spoilage_bps': spoilageBps,
        if (materialCostPerSheetFils != null)
          'material_cost_per_sheet_fils': materialCostPerSheetFils,
        if (printRatePerSheetSideFils != null)
          'print_rate_per_sheet_side_fils': printRatePerSheetSideFils,
        if (areaRateFilsPerSqm != null) 'area_rate_fils_per_sqm': areaRateFilsPerSqm,
        if (vendorCostFils != null) 'vendor_cost_fils': vendorCostFils,
        if (tiers.isNotEmpty)
          'tiers': <Map<String, Object?>>[for (final t in tiers) t.toJson()],
        'markup_bps': markupBps,
        'min_order_fils': minOrderFils,
        'rounding_step_fils': roundingStepFils,
        'vat_bps': vatBps,
      };
}

enum PriceLineKind {
  cost('cost'),
  addOn('add_on'),
  tablePrice('table_price'),
  surcharge('surcharge'),
  discount('discount');

  const PriceLineKind(this.wire);

  final String wire;
}

/// One row of the breakdown the counter sees and the customer can be shown.
///
/// [explain] is generated from the basis — "28 sheets × 2 sides × AED 0.35" —
/// because the owner will ask "why is this 122?" on the first day, and the
/// answer has to be on screen, not in a developer's head.
final class PriceLine {
  const PriceLine({
    required this.code,
    required this.label,
    required this.kind,
    required this.quantity,
    required this.rateFils,
    required this.amount,
    required this.explain,
  });

  final String code;
  final String label;
  final PriceLineKind kind;

  /// Units at the basis (sheets, pieces, square metres, 1 for flat).
  final int quantity;
  final int rateFils;
  final Fils amount;
  final String explain;

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code,
        'label': label,
        'kind': kind.wire,
        'quantity': quantity,
        'rate_fils': rateFils,
        'amount_fils': amount.raw,
        'explain': explain,
      };
}

/// The complete, reproducible answer.
final class PriceBreakdown {
  const PriceBreakdown({
    required this.priceBookVersion,
    required this.lines,
    required this.costSubtotal,
    required this.addOns,
    required this.priceBeforeSurcharges,
    required this.surcharges,
    required this.priceBeforeDiscount,
    required this.discount,
    required this.netBeforeRounding,
    required this.roundingAdjustment,
    required this.total,
    required this.vat,
    required this.grandTotal,
    required this.vatBps,
    required this.roundingStepFils,
    this.warnings = const <String>[],
  });

  final int priceBookVersion;
  final List<PriceLine> lines;

  /// Cost of goods: material, print, finishing.
  final Fils costSubtotal;

  /// Charges added on top of a table price (foil, spot UV, die-cut).
  final Fils addOns;

  final Fils priceBeforeSurcharges;
  final Fils surcharges;
  final Fils priceBeforeDiscount;
  final Fils discount;

  /// Selling price after discount, before rounding.
  final Fils netBeforeRounding;

  /// Signed: the amount added (or removed) by rounding to the configured step.
  final Fils roundingAdjustment;

  /// Rounded, pre-VAT total. This is what the invoice shows as taxable amount.
  final Fils total;

  final Fils vat;
  final Fils grandTotal;
  final int vatBps;
  final int roundingStepFils;
  final List<String> warnings;

  /// Gross margin as basis points of [total], for the margin guard. Returns
  /// null when there is no cost to compare against (pure table pricing).
  int? get marginBps {
    if (costSubtotal.raw <= 0) {
      return null;
    }
    return mulDivRoundHalfUp(total.raw - costSubtotal.raw, 10000, total.raw);
  }

  /// The snapshot stored with every quote and order line. Changing the price
  /// book later cannot alter this document.
  Map<String, Object?> toJson() => <String, Object?>{
        'price_book_version': priceBookVersion,
        'lines': <Map<String, Object?>>[for (final l in lines) l.toJson()],
        'cost_subtotal_fils': costSubtotal.raw,
        'add_ons_fils': addOns.raw,
        'price_before_surcharges_fils': priceBeforeSurcharges.raw,
        'surcharges_fils': surcharges.raw,
        'price_before_discount_fils': priceBeforeDiscount.raw,
        'discount_fils': discount.raw,
        'net_before_rounding_fils': netBeforeRounding.raw,
        'rounding_adjustment_fils': roundingAdjustment.raw,
        'total_fils': total.raw,
        'vat_bps': vatBps,
        'vat_fils': vat.raw,
        'grand_total_fils': grandTotal.raw,
        'rounding_step_fils': roundingStepFils,
        if (warnings.isNotEmpty) 'warnings': warnings,
      };

  @override
  String toString() =>
      'PriceBreakdown(total ${total.aedLabel}, VAT ${vat.aedLabel}, '
      'grand ${grandTotal.aedLabel}, book v$priceBookVersion)';
}
