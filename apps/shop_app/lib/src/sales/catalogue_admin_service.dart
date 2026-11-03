import 'dart:convert';

import 'package:http/http.dart' as http;

/// Writing the rate card: adding products and changing what they cost.
///
/// Reading the catalogue is the sync engine's job; this class only does the two
/// writes an owner makes. It needs the network, and says so: a device that has
/// been offline for a week must not be able to invent a product that every other
/// counter will then price with.
class CatalogueAdminService {
  CatalogueAdminService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Future<void> createProduct({
    required String code,
    required String nameEn,
    String? nameAr,
    required String kind,
    required String pricingMode,
    int markupBps = 0,
    int? printRateFils,
    int? areaRateFilsPerSqm,
    int minOrderFils = 0,
    int roundingStepFils = 100,
    String? materialCode,
    String workflowKey = 'print_std',
    String? machineId,
    List<String> operationCodes = const <String>[],
    int? sheetWidthMm,
    int? sheetHeightMm,
  }) async {
    await _send('POST', '/v1/catalogue/products', <String, Object?>{
      'code': code,
      'name_en': nameEn,
      'name_ar': ?nameAr,
      'kind': kind,
      'pricing_mode': pricingMode,
      'markup_bps': markupBps,
      'print_rate_fils': ?printRateFils,
      'area_rate_fils_per_sqm': ?areaRateFilsPerSqm,
      'min_order_fils': minOrderFils,
      'rounding_step_fils': roundingStepFils,
      'material_code': ?materialCode,
      'workflow_key': workflowKey,
      'machine_id': ?machineId,
      'operation_codes_json': operationCodes,
      'sheet_width_mm': ?sheetWidthMm,
      'sheet_height_mm': ?sheetHeightMm,
    });
  }

  /// Changes the numbers that already exist on a product.
  Future<void> updateProduct(
    String id, {
    int? markupBps,
    int? printRateFils,
    int? areaRateFilsPerSqm,
    int? minOrderFils,
    int? roundingStepFils,
    int? spoilageBps,
    String? machineId,
    List<String>? operationCodes,
  }) async {
    await _send('PATCH', '/v1/price-book/products/$id', <String, Object?>{
      'markup_bps': ?markupBps,
      'print_rate_fils': ?printRateFils,
      'area_rate_fils_per_sqm': ?areaRateFilsPerSqm,
      'min_order_fils': ?minOrderFils,
      'rounding_step_fils': ?roundingStepFils,
      'spoilage_bps': ?spoilageBps,
      'machine_id': ?machineId,
      'operation_codes_json': ?operationCodes,
    });
  }

  /// Sets the sell price at one quantity. The same quantity is an edit.
  Future<void> setPriceBreak({
    required String productId,
    required int quantity,
    required int amountFils,
  }) async {
    await _send('POST', '/v1/catalogue/price-breaks', <String, Object?>{
      'product_id': productId,
      'quantity': quantity,
      'amount_fils': amountFils,
    });
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await tokenProvider();
    if (token == null) {
      throw StateError('Sign in again to change the rate card.');
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['content-type'] = 'application/json'
      ..headers['authorization'] = 'Bearer $token'
      ..body = jsonEncode(body);

    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    );

    if (response.statusCode == 403) {
      throw StateError('Only an owner can change the rate card.');
    }
    if (response.statusCode >= 400) {
      final decoded = jsonDecode(response.body) as Map;
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw StateError(
        error?['message'] as String? ??
            'That change was refused (${response.statusCode}).',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  void dispose() => _client.close();
}
