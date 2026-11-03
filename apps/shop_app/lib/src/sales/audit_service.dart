import 'dart:convert';

import 'package:http/http.dart' as http;

/// One thing that happened, as the server recorded it.
///
/// Nothing here is stored on the device: the trail is append-only on the
/// server, and a local copy that could be edited between two people reading it
/// would stop being evidence.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.at,
    required this.actorId,
    required this.action,
    this.actorName,
    this.deviceId,
    this.entity,
    this.rowId,
  });

  factory AuditEntry.fromJson(Map<String, Object?> json) {
    return AuditEntry(
      id: json['id'] as String? ?? '',
      // The server writes UTC. The screen shows the clock the reader is
      // standing next to, because "07:12" is the time the person remembers.
      at: DateTime.parse(json['at']! as String).toLocal(),
      actorId: json['actor_id'] as String? ?? '',
      // Null once the person's row has been deleted. The screen falls back to
      // the id rather than dropping the event: they still did it.
      actorName: json['actor_name'] as String?,
      deviceId: json['device_id'] as String?,
      action: json['action'] as String? ?? '',
      entity: json['entity'] as String?,
      rowId: json['row_id'] as String?,
    );
  }

  final String id;
  final DateTime at;
  final String actorId;
  final String? actorName;
  final String? deviceId;

  /// The action code, e.g. `auth.login_failed` — the same string the Worker
  /// filters on, so a query and a row never disagree about what happened.
  final String action;
  final String? entity;
  final String? rowId;

  String get actorLabel => actorName ?? actorId;
}

/// The audit trail needs the network — deliberately.
///
/// It is the record of who signed in on the counter tablet and who changed a
/// price from the office. Cached on one device it would answer only for that
/// device, which is the opposite of the question being asked.
class AuditService {
  AuditService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  /// The newest [limit] entries, optionally narrowed to one exact [action].
  ///
  /// The caller usually asks for the whole page and groups it on the device:
  /// "sign-ins" is three action codes, "price changes" is five, and "everything
  /// else" is the complement of both — none of which one `?action=` can say.
  /// [action] is kept because a drill-down ("what else failed at 07:12?") wants
  /// the server to do the narrowing.
  Future<List<AuditEntry>> recent({String? action, int limit = 100}) async {
    final query = <String, String>{
      'limit': '$limit',
      if (action != null && action.isNotEmpty) 'action': action,
    };
    final body = await _get('/v1/audit?${Uri(queryParameters: query).query}');
    final rows = (body['entries'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();
    return rows.map(AuditEntry.fromJson).toList(growable: false);
  }

  Future<Map<String, Object?>> _get(String path) async {
    final token = await tokenProvider();
    if (token == null) throw StateError('Sign in again to read the audit log.');

    final response = await _client
        .get(
          Uri.parse('$baseUrl$path'),
          headers: <String, String>{'authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 403) {
      throw StateError('Only a manager or the owner can read the audit log.');
    }
    if (response.statusCode >= 400) {
      // The server's own words: "Only a manager or the owner…" is more use than
      // "request failed", and a permission change mid-session says so here.
      final decoded = jsonDecode(response.body) as Map;
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw StateError(
        error?['message'] as String? ??
            'Audit log failed (${response.statusCode}).',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  void dispose() => _client.close();
}
