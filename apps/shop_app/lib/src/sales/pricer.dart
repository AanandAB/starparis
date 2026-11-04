import 'dart:convert';

import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:starparis_sync/starparis_sync.dart';

/// Per-tier basis-point adjustments applied to the selling price. Negative is a
/// discount (-1000 = 10% off), so a trade customer is quoted less than retail
/// for the identical job. These rates belong in Settings later; the map is
/// hardcoded for now so the counter keeps working until then.
const Map<String, int> _tierAdjustmentBps = <String, int>{
  'retail': 0,
  'trade': -1000,
};

/// The basis-point adjustment for a customer tier. Unknown tiers price at
/// retail, so an uncategorised customer is never silently discounted.
int tierAdjustmentBpsFor(String tier) => _tierAdjustmentBps[tier] ?? 0;

/// Bridges the local catalogue rows to the pure pricing engine.
///
/// This is the only place that knows both shapes. Keeping the conversion here
/// means the engine stays free of drift and the database stays free of pricing
/// rules, which is what makes the engine testable in milliseconds.
class ProductPricer {
  const ProductPricer._();

  /// The press this product names, if the catalogue has it. A product with no
  /// machine is priced on its per-sheet print rate, exactly as before.
  static MachineSpec? _machineFor(Product product, List<Machine> machines) {
    final id = product.machineId;
    if (id == null) return null;
    for (final machine in machines) {
      if (machine.id == id) {
        return MachineSpec(
          name: machine.name,
          hourlyRateFils: machine.hourlyRateFils,
          setupMinutes: machine.setupMinutes,
          sheetsPerHour: machine.sheetsPerHour,
          clickFils: machine.clickFils,
        );
      }
    }
    return null;
  }

  /// The finishing steps this product includes, in the order the shop lists them.
  static List<FinishingOperation> _operationsFor(
    Product product,
    List<Operation> operations,
  ) {
    List<String> codes;
    try {
      codes = <String>[
        for (final value
            in jsonDecode(product.operationCodesJson) as List<Object?>)
          value! as String,
      ];
    } catch (_) {
      return const <FinishingOperation>[];
    }
    if (codes.isEmpty) return const <FinishingOperation>[];

    final byCode = <String, Operation>{
      for (final op in operations) op.code: op,
    };
    return <FinishingOperation>[
      for (final code in codes)
        if (byCode[code] != null)
          FinishingOperation(
            code: code,
            name: byCode[code]!.nameEn,
            basis: _basis(byCode[code]!.basis),
            rateFils: byCode[code]!.rateFils,
            setupFils: byCode[code]!.setupFils,
            minChargeFils: byCode[code]!.minChargeFils,
          ),
    ];
  }

  static OperationBasis _basis(String wire) => switch (wire) {
    'per_1000' => OperationBasis.per1000,
    'per_side' => OperationBasis.perSide,
    'per_sqm' => OperationBasis.perSqm,
    'per_copy' => OperationBasis.perCopy,
    'per_hour' => OperationBasis.perHour,
    _ => OperationBasis.perPiece,
  };

  static List<PriceOption> sizes(Product product) =>
      _options(product.sizesJson);

  static List<PriceOption> finishes(Product product) =>
      _options(product.finishesJson);

  static List<int> quantityPresets(Product product) {
    try {
      final decoded = jsonDecode(product.quantityPresetsJson) as List<Object?>;
      return <int>[for (final value in decoded) (value! as num).toInt()];
    } catch (_) {
      return const <int>[100, 250, 500, 1000];
    }
  }

  static PricingContext contextFor({
    required Product product,
    required List<PriceRuleRow> rules,
    MaterialRow? material,
    required int priceBookVersion,
    required int vatBps,
    MachineSpec? machine,
    List<FinishingOperation> operations = const <FinishingOperation>[],
    List<PriceBreak> priceBreaks = const <PriceBreak>[],
    String customerTier = 'retail',
  }) {
    return PricingContext(
      priceBookVersion: priceBookVersion,
      mode: PricingMode.fromWire(product.pricingMode),
      rules: <PriceRule>[for (final rule in rules) _rule(rule)],
      sheet: product.kind == 'sheet' && product.sheetWidthMm != null
          ? SheetSpec(
              widthMm: product.sheetWidthMm!,
              heightMm: product.sheetHeightMm!,
              bleedMm: product.bleedMm,
              gutterMm: product.gutterMm,
              label: 'press sheet',
            )
          : null,
      setupSheets: product.setupSheets,
      spoilageBps: product.spoilageBps,
      materialCostPerSheetFils: material?.costPerSheetFils,
      printRatePerSheetSideFils: product.printRateFils,
      machine: machine,
      operations: operations,
      priceBreaks: <QuantityBreak>[
        for (final row in priceBreaks)
          QuantityBreak(quantity: row.quantity, amountFils: row.amountFils),
      ],
      areaRateFilsPerSqm: product.areaRateFilsPerSqm,
      markupBps: product.markupBps,
      minOrderFils: product.minOrderFils,
      roundingStepFils: product.roundingStepFils,
      vatBps: vatBps,
      tierAdjustmentBps: tierAdjustmentBpsFor(customerTier),
    );
  }

  static PriceBreakdown price({
    required Product product,
    required List<PriceRuleRow> rules,
    MaterialRow? material,
    required int priceBookVersion,
    required int vatBps,
    required int quantity,

    /// The shop's machines and finishing catalogue, so the engine prices the
    /// press the product actually runs on and the steps it actually includes.
    List<Machine> machines = const <Machine>[],
    List<Operation> operations = const <Operation>[],
    List<PriceBreak> priceBreaks = const <PriceBreak>[],
    PriceOption? size,
    int sides = 1,
    List<String> finishes = const <String>[],
    Priority priority = Priority.normal,
    String customerTier = 'retail',
  }) {
    final machine = _machineFor(product, machines);
    final chosenOperations = _operationsFor(product, operations);

    final request = PriceRequest(
      productId: product.id,
      kind: ProductKind.fromWire(product.kind),
      quantity: quantity,
      widthMm: size?.widthMm,
      heightMm: size?.heightMm,
      sides: sides,
      materialCode: product.materialCode,
      finishCodes: finishes,
      priority: priority,
    );

    return PricingEngine.price(
      request,
      contextFor(
        product: product,
        rules: rules,
        material: material,
        priceBookVersion: priceBookVersion,
        vatBps: vatBps,
        machine: machine,
        operations: chosenOperations,
        priceBreaks: priceBreaks,
        customerTier: customerTier,
      ),
    );
  }

  /// The one line a customer sees on the quote: product, quantity, size,
  /// finishes. Generated rather than typed, so it cannot drift from the price.
  static String describe({
    required Product product,
    required int quantity,
    PriceOption? size,
    int sides = 1,
    List<String> finishes = const <String>[],
  }) {
    final parts = <String>[product.nameEn, '$quantity'];
    if (size != null) parts.add(size.label);
    if (product.kind == 'sheet' && sides > 0) {
      parts.add(sides == 2 ? 'double sided' : 'single sided');
    }
    final labels = <String>{
      for (final finish in finishes)
        for (final option in finishesOf(product))
          if (option.code == finish) option.label,
    };
    parts.addAll(labels);
    return parts.join(' · ');
  }

  static List<PriceOption> finishesOf(Product product) => finishes(product);

  static PriceRule _rule(PriceRuleRow row) {
    List<RuleCondition> conditions = const <RuleCondition>[];
    try {
      final decoded = jsonDecode(row.whenJson) as List<Object?>;
      conditions = <RuleCondition>[
        for (final condition in decoded)
          RuleCondition.fromJson((condition! as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      conditions = const <RuleCondition>[];
    }

    return PriceRule(
      id: row.id,
      label: row.label,
      phase: RulePhase.fromWire(row.phase),
      basis: RuleBasis.fromWire(row.basis),
      rateFils: row.rateFils,
      minChargeFils: row.minChargeFils,
      priority: row.priority,
      when: conditions,
      productIds: row.productId == null
          ? const <String>{}
          : <String>{row.productId!},
    );
  }

  static List<PriceOption> _options(String json) {
    try {
      final decoded = jsonDecode(json) as List<Object?>;
      return <PriceOption>[
        for (final item in decoded)
          PriceOption.fromJson((item! as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      return const <PriceOption>[];
    }
  }
}

/// A choice the counter can make: a finished size, or a finishing process.
class PriceOption {
  const PriceOption({
    required this.code,
    required this.label,
    this.widthMm,
    this.heightMm,
  });

  final String code;
  final String label;
  final int? widthMm;
  final int? heightMm;

  factory PriceOption.fromJson(Map<String, Object?> json) => PriceOption(
    code: json['code'] as String? ?? '',
    label: json['label'] as String? ?? json['code'] as String? ?? '',
    widthMm: (json['width_mm'] as num?)?.toInt(),
    heightMm: (json['height_mm'] as num?)?.toInt(),
  );
}
