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

  // --- materials ----------------------------------------------------------

  /// Materials as the server stores them — full rows, so the editor can show
  /// sheet size and supplier, which the local Material model does not carry.
  Future<List<Map<String, Object?>>> listMaterials() =>
      _list('/v1/catalogue/materials', 'materials');

  Future<void> createMaterial({
    required String code,
    required String name,
    String? type,
    int? gsm,
    int? sheetWidthMm,
    int? sheetHeightMm,
    int costPerSheetFils = 0,
    String? supplierId,
  }) async {
    await _send('POST', '/v1/catalogue/materials', <String, Object?>{
      'code': code,
      'name': name,
      'type': ?type,
      'gsm': ?gsm,
      'sheet_width_mm': ?sheetWidthMm,
      'sheet_height_mm': ?sheetHeightMm,
      'cost_per_sheet_fils': costPerSheetFils,
      'supplier_id': ?supplierId,
    });
  }

  Future<void> updateMaterial(
    String id, {
    String? name,
    String? type,
    int? gsm,
    int? sheetWidthMm,
    int? sheetHeightMm,
    int? costPerSheetFils,
    String? supplierId,
  }) async {
    await _send('PATCH', '/v1/catalogue/materials/$id', <String, Object?>{
      'name': ?name,
      'type': ?type,
      'gsm': ?gsm,
      'sheet_width_mm': ?sheetWidthMm,
      'sheet_height_mm': ?sheetHeightMm,
      'cost_per_sheet_fils': ?costPerSheetFils,
      'supplier_id': ?supplierId,
    });
  }

  Future<void> deleteMaterial(String id) =>
      _send('DELETE', '/v1/catalogue/materials/$id');

  // --- machines -----------------------------------------------------------

  Future<List<Map<String, Object?>>> listMachines() =>
      _list('/v1/catalogue/machines', 'machines');

  Future<void> createMachine({
    required String name,
    String type = 'digital',
    int hourlyRateFils = 0,
    int setupMinutes = 0,
    int sheetsPerHour = 0,
    int plateCostFils = 0,
    int clickFils = 0,
  }) async {
    await _send('POST', '/v1/catalogue/machines', <String, Object?>{
      'name': name,
      'type': type,
      'hourly_rate_fils': hourlyRateFils,
      'setup_minutes': setupMinutes,
      'sheets_per_hour': sheetsPerHour,
      'plate_cost_fils': plateCostFils,
      'click_fils': clickFils,
    });
  }

  Future<void> updateMachine(
    String id, {
    String? name,
    String? type,
    int? hourlyRateFils,
    int? setupMinutes,
    int? sheetsPerHour,
    int? plateCostFils,
    int? clickFils,
  }) async {
    await _send('PATCH', '/v1/catalogue/machines/$id', <String, Object?>{
      'name': ?name,
      'type': ?type,
      'hourly_rate_fils': ?hourlyRateFils,
      'setup_minutes': ?setupMinutes,
      'sheets_per_hour': ?sheetsPerHour,
      'plate_cost_fils': ?plateCostFils,
      'click_fils': ?clickFils,
    });
  }

  Future<void> deleteMachine(String id) =>
      _send('DELETE', '/v1/catalogue/machines/$id');

  // --- operations ---------------------------------------------------------

  Future<List<Map<String, Object?>>> listOperations() =>
      _list('/v1/catalogue/operations', 'operations');

  Future<void> createOperation({
    required String code,
    required String nameEn,
    String phase = 'finishing',
    required String basis,
    int rateFils = 0,
    int setupFils = 0,
    int wasteBps = 0,
    int minChargeFils = 0,
  }) async {
    await _send('POST', '/v1/catalogue/operations', <String, Object?>{
      'code': code,
      'name_en': nameEn,
      'phase': phase,
      'basis': basis,
      'rate_fils': rateFils,
      'setup_fils': setupFils,
      'waste_bps': wasteBps,
      'min_charge_fils': minChargeFils,
    });
  }

  Future<void> updateOperation(
    String id, {
    String? nameEn,
    String? phase,
    String? basis,
    int? rateFils,
    int? setupFils,
    int? wasteBps,
    int? minChargeFils,
  }) async {
    await _send('PATCH', '/v1/catalogue/operations/$id', <String, Object?>{
      'name_en': ?nameEn,
      'phase': ?phase,
      'basis': ?basis,
      'rate_fils': ?rateFils,
      'setup_fils': ?setupFils,
      'waste_bps': ?wasteBps,
      'min_charge_fils': ?minChargeFils,
    });
  }

  Future<void> deleteOperation(String id) =>
      _send('DELETE', '/v1/catalogue/operations/$id');

  /// The `rows` key of a list endpoint, as decoded maps (or empty when absent).
  Future<List<Map<String, Object?>>> _list(String path, String key) async {
    final body = await _send('GET', path);
    final rows = body[key];
    if (rows is! List) return const <Map<String, Object?>>[];
    return <Map<String, Object?>>[
      for (final row in rows) (row! as Map).cast<String, Object?>(),
    ];
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final token = await tokenProvider();
    if (token == null) {
      throw StateError('Sign in again to change the rate card.');
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['content-type'] = 'application/json'
      ..headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.body = jsonEncode(body);
    }

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
