/// A shared pricing test vector.
///
/// Vectors live in `packages/shared_test_vectors/pricing/*.json` and are the
/// contract between the client and the shop: the owner signs off the numbers,
/// and from then on any change that moves one of them is visible in a diff.
/// When the TypeScript port lands, it runs the same files.
library;

import 'engine.dart';
import 'models.dart';

final class PricingVector {
  const PricingVector({
    required this.name,
    required this.note,
    required this.requestJson,
    required this.contextJson,
    required this.expectedJson,
  });

  final String name;

  /// Plain-English explanation of the arithmetic, written for the owner.
  final String note;

  final Map<String, Object?> requestJson;
  final Map<String, Object?> contextJson;
  final Map<String, Object?> expectedJson;

  factory PricingVector.fromJson(Map<String, Object?> json) => PricingVector(
        name: json['name']! as String,
        note: (json['note'] as String?) ?? '',
        requestJson: (json['request']! as Map).cast<String, Object?>(),
        contextJson: (json['context']! as Map).cast<String, Object?>(),
        expectedJson: (json['expected']! as Map).cast<String, Object?>(),
      );

  PriceBreakdown run() => PricingEngine.price(
        PriceRequest.fromJson(requestJson),
        PricingContext.fromJson(contextJson),
      );

  Map<String, Object?> actualJson() => run().toJson();
}
