import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Writing the price book back to the server.
///
/// Only the owner (or a role granted `price.edit`) can call these; the Worker
/// refuses everyone else, so a modified client gains nothing.
class PriceBookException implements Exception {
  const PriceBookException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class BulkChange {
  const BulkChange({
    required this.id,
    required this.label,
    required this.rateFils,
    required this.newRateFils,
  });

  final String id;
  final String label;
  final int rateFils;
  final int newRateFils;
}

class BulkResult {
  const BulkResult({required this.applied, required this.changes});

  final bool applied;
  final List<BulkChange> changes;
}

class PriceBookApi {
  PriceBookApi({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Future<void> updateRule(
    String id, {
    int? rateFils,
    int? minChargeFils,
    bool? active,
  }) async {
    await _send('PATCH', '/v1/price-book/rules/$id', <String, Object?>{
      'rate_fils': ?rateFils,
      'min_charge_fils': ?minChargeFils,
      'active': ?active,
    });
  }

  Future<void> updateProduct(
    String id, {
    int? markupBps,
    int? roundingStepFils,
    int? minOrderFils,
    int? printRateFils,
    int? areaRateFilsPerSqm,
  }) async {
    await _send('PATCH', '/v1/price-book/products/$id', <String, Object?>{
      'markup_bps': ?markupBps,
      'rounding_step_fils': ?roundingStepFils,
      'min_order_fils': ?minOrderFils,
      'print_rate_fils': ?printRateFils,
      'area_rate_fils_per_sqm': ?areaRateFilsPerSqm,
    });
  }

  Future<BulkResult> bulkAdjust({
    String? productId,
    required int percentBps,
    required bool dryRun,
  }) async {
    final body = await _send(
      'POST',
      '/v1/price-book/bulk-adjust',
      <String, Object?>{
        'product_id': ?productId,
        'percent_bps': percentBps,
        'dry_run': dryRun,
      },
    );

    final changes = (body['changes'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();

    return BulkResult(
      applied: body['applied'] as bool? ?? false,
      changes: <BulkChange>[
        for (final change in changes)
          BulkChange(
            id: change['id'] as String? ?? '',
            label: change['label'] as String? ?? '',
            rateFils: (change['rate_fils'] as num?)?.toInt() ?? 0,
            newRateFils: (change['new_rate_fils'] as num?)?.toInt() ?? 0,
          ),
      ],
    );
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await tokenProvider();
    if (token == null) {
      throw const PriceBookException('UNAUTHORIZED', 'Sign in again.');
    }

    late http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll(<String, String>{
          'authorization': 'Bearer $token',
          'content-type': 'application/json',
        })
        ..body = jsonEncode(body);
      response = await http.Response.fromStream(await _client.send(request))
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw const PriceBookException(
        'OFFLINE',
        'No internet. Price changes need a connection so every device sees them.',
      );
    }

    final decoded = response.body.isEmpty
        ? <String, Object?>{}
        : (jsonDecode(response.body) as Map).cast<String, Object?>();

    if (response.statusCode >= 400) {
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw PriceBookException(
        error?['code'] as String? ?? 'HTTP_${response.statusCode}',
        error?['message'] as String? ?? 'The server refused the change.',
      );
    }
    return decoded;
  }
}
