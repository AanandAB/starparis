import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:starparis_documents/starparis_documents.dart';

/// What the shop says about itself, and the rate it charges VAT at.
///
/// These are the values printed on every document, so they come from the server
/// and nowhere else: two devices that disagree about the TRN is a compliance
/// problem, not a display bug.
class ShopSettings {
  const ShopSettings({
    required this.company,
    required this.vatBps,
    required this.orderPrefix,
    required this.invoicePrefix,
    required this.quotePrefix,
  });

  factory ShopSettings.fromJson(Map<String, Object?> json) {
    final company =
        (json['company'] as Map?)?.cast<String, Object?>() ?? const {};
    final numbers =
        (json['numbers'] as Map?)?.cast<String, Object?>() ?? const {};
    return ShopSettings(
      company: CompanyProfile(
        name: company['name'] as String? ?? 'Star Paris',
        trn: company['trn'] as String? ?? '',
        address: company['address'] as String? ?? '',
        phone: company['phone'] as String? ?? '',
        email: company['email'] as String? ?? '',
        branchName: company['branch'] as String? ?? '',
      ),
      vatBps: (json['vat_bps'] as num?)?.toInt() ?? 500,
      orderPrefix: numbers['order_prefix'] as String? ?? 'JOB',
      invoicePrefix: numbers['invoice_prefix'] as String? ?? 'INV',
      quotePrefix: numbers['quote_prefix'] as String? ?? 'QT',
    );
  }

  final CompanyProfile company;
  final int vatBps;
  final String orderPrefix;
  final String invoicePrefix;
  final String quotePrefix;

  /// 5.00% reads better than 500 on a settings screen.
  String get vatPercent => (vatBps / 100).toStringAsFixed(2);
}

class SettingsService {
  SettingsService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Future<ShopSettings> load() async {
    final body = await _send('GET', '/v1/settings');
    return ShopSettings.fromJson(body);
  }

  Future<ShopSettings> save({
    String? name,
    String? trn,
    String? address,
    String? phone,
    String? email,
    int? vatBps,
    String? orderPrefix,
    String? invoicePrefix,
    String? quotePrefix,
  }) async {
    final body = await _send('PUT', '/v1/settings', <String, Object?>{
      'company': <String, Object?>{
        'name': ?name,
        'trn': ?trn,
        'address': ?address,
        'phone': ?phone,
        'email': ?email,
      },
      'vat_bps': ?vatBps,
      'numbers': <String, Object?>{
        'order_prefix': ?orderPrefix,
        'invoice_prefix': ?invoicePrefix,
        'quote_prefix': ?quotePrefix,
      },
    });
    return ShopSettings.fromJson(body);
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final token = await tokenProvider();
    if (token == null) throw StateError('Sign in again to change settings.');

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['content-type'] = 'application/json'
      ..headers['authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    );

    if (response.statusCode == 403) {
      throw StateError('Only an owner can change the shop settings.');
    }
    if (response.statusCode >= 400) {
      final decoded = jsonDecode(response.body) as Map;
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw StateError(
        error?['message'] as String? ??
            'Settings request failed (${response.statusCode}).',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  void dispose() => _client.close();
}
