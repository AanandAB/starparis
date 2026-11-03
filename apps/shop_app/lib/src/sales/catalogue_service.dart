import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:starparis_sync/starparis_sync.dart';

/// Pulls the price book down to the device and stores it atomically.
///
/// The catalogue is reference data, not user data: it has its own version
/// (`catalogue_version`) so the app refetches only when something actually
/// changed, rather than on every poll.
class CatalogueService {
  CatalogueService({
    required this.baseUrl,
    required this.db,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final LocalDatabase db;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  static const String _versionKey = 'catalogue_version';

  /// Returns true when the local catalogue changed.
  Future<bool> refresh({bool force = false}) async {
    final token = await tokenProvider();
    if (token == null) return false;

    late http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$baseUrl/v1/catalogue'),
            headers: <String, String>{'authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      return false;
    }

    if (response.statusCode != 200) return false;

    final body = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final version = body['catalogue_version'] as String? ?? '0';
    final known = await db.meta(_versionKey);
    if (!force && known == version) return false;

    final tax = (body['tax'] as Map?)?.cast<String, Object?>();
    await db.replaceCatalogue(
      productRows: _rows(body['products']),
      materialRows: _rows(body['materials']),
      ruleRows: _rows(body['rules']),
      stageRows: _rows(body['workflow_stages']),
      machineRows: _rows(body['machines']),
      operationRows: _rows(body['operations']),
      breakRows: _rows(body['price_breaks']),
      priceBookVersion: (body['price_book_version'] as num?)?.toInt() ?? 0,
      vatBps: (tax?['vat_bps'] as num?)?.toInt() ?? 500,
    );
    await db.setMeta(_versionKey, version);
    return true;
  }

  static List<Map<String, Object?>> _rows(Object? value) {
    if (value is! List) return <Map<String, Object?>>[];
    return <Map<String, Object?>>[
      for (final row in value) (row! as Map).cast<String, Object?>(),
    ];
  }
}
