import 'dart:convert';

import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:starparis_sync/starparis_sync.dart';

/// Bridges the local catalogue rows to the pure pricing engine.
///
/// This is the only place that knows both shapes. Keeping the conversion here
/// means the engine stays free of drift and the database stays free of pricing
/// rules, which is what makes the engine testable in milliseconds.
class ProductPricer {
  const ProductPricer._();

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
      areaRateFilsPerSqm: product.areaRateFilsPerSqm,
      markupBps: product.markupBps,
      minOrderFils: product.minOrderFils,
      roundingStepFils: product.roundingStepFils,
      vatBps: vatBps,
    );
  }

  static PriceBreakdown price({
    required Product product,
    required List<PriceRuleRow> rules,
    MaterialRow? material,
    required int priceBookVersion,
    required int vatBps,
    required int quantity,
    PriceOption? size,
    int sides = 1,
    List<String> finishes = const <String>[],
    Priority priority = Priority.normal,
  }) {
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
