import 'package:url_launcher/url_launcher.dart';

/// WhatsApp click-to-chat, by design (PLAN.md §12): no API, no business
/// verification, no per-message fee. The staff member reviews the message in
/// WhatsApp and taps Send themselves, which is also why delivery status is
/// unknowable and never claimed.
class WhatsApp {
  const WhatsApp._();

  static Uri chatUri({required String phoneE164, required String message}) {
    final digits = phoneE164.replaceAll(RegExp(r'\D'), '');
    return Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );
  }

  static Future<bool> open({
    required String phoneE164,
    required String message,
  }) {
    return launchUrl(
      chatUri(phoneE164: phoneE164, message: message),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Ready-for-collection message. Amounts come from the stored order, never
  /// typed, so the customer never sees a number the shop did not agree.
  static String readyMessage({
    required String customerName,
    required String jobNumber,
    required String total,
    required String shopName,
    String? branchAddress,
  }) {
    final buffer = StringBuffer()
      ..writeln('Hello $customerName,')
      ..writeln()
      ..writeln('Your order $jobNumber is ready for collection.')
      ..writeln('Total: $total');

    if (branchAddress != null && branchAddress.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(branchAddress);
    }

    buffer
      ..writeln()
      ..writeln(shopName);
    return buffer.toString().trim();
  }

  static String quoteMessage({
    required String customerName,
    required String quoteNumber,
    required String total,
    required String shopName,
    required String validUntil,
  }) {
    return <String>[
      'Hello $customerName,',
      '',
      'Quotation $quoteNumber is ready: $total including VAT.',
      'It is valid until $validUntil.',
      '',
      'Let us know if you would like to go ahead.',
      shopName,
    ].join('\n');
  }
}
