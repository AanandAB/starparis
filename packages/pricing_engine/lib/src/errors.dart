/// The one exception type the pricing engine throws.
///
/// Every failure carries a stable [code] because the app shows the message and
/// logs the code; the Worker stores the code in the audit trail. "Something
/// went wrong" is not an acceptable answer for a counter clerk with a customer
/// waiting.
library;

final class PricingException implements Exception {
  const PricingException(this.code, this.message, {this.details});

  final String code;
  final String message;
  final Map<String, Object?>? details;

  @override
  String toString() => 'PricingException($code): $message';
}
