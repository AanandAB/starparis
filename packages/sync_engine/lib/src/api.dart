/// The wire between the device and the Worker.
///
/// Three calls only — head, push, pull — because everything else the app needs
/// is already in the local database. The interface exists so tests can drive
/// the engine with a fake that fails on demand: sync bugs appear when the
/// network drops mid-batch, and that is impossible to test against a real
/// server.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'database.dart';

class SyncException implements Exception {
  const SyncException(this.code, this.message, {this.status});

  final String code;
  final String message;
  final int? status;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'SyncException($code): $message';
}

class HeadResult {
  const HeadResult({
    required this.head,
    required this.permissionVersion,
    required this.minAppVersion,
  });

  final int head;
  final int permissionVersion;
  final String minAppVersion;
}

class MutationOutcome {
  const MutationOutcome({
    required this.mutationId,
    required this.status,
    this.serverVersion,
    this.row,
    this.errorCode,
    this.errorMessage,
  });

  /// applied, merged, rejected or duplicate.
  final String status;
  final String mutationId;
  final int? serverVersion;
  final Map<String, Object?>? row;
  final String? errorCode;
  final String? errorMessage;

  bool get isAccepted =>
      status == 'applied' || status == 'merged' || status == 'duplicate';
  bool get isRejected => status == 'rejected';
}

class PushResult {
  const PushResult({required this.head, required this.outcomes});

  final int head;
  final List<MutationOutcome> outcomes;
}

class PullRow {
  const PullRow({
    required this.seq,
    required this.entity,
    required this.rowId,
    required this.op,
    required this.version,
    required this.data,
  });

  final int seq;
  final String entity;
  final String rowId;
  final String op;
  final int version;
  final Map<String, Object?> data;
}

class PullResult {
  const PullResult({
    required this.rows,
    required this.nextCursor,
    required this.head,
  });

  final List<PullRow> rows;
  final int nextCursor;
  final int head;
}

abstract interface class SyncApi {
  Future<HeadResult> head();

  Future<PushResult> push({required List<OutboxMutation> mutations});

  Future<PullResult> pull({required int since, int limit = 200});
}

/// Real implementation against the Worker.
class HttpSyncApi implements SyncApi {
  HttpSyncApi({
    required String baseUrl,
    required this.deviceId,
    required this.tokenProvider,
    http.Client? client,
    this._timeout = const Duration(seconds: 20),
  }) : baseUrl = baseUrl.replaceAll(RegExp(r'/$'), ''),
       _client = client ?? http.Client();

  final String baseUrl;
  final String deviceId;

  /// Called on every request: an access token lives 15 minutes, so caching one
  /// here would guarantee an expiry bug.
  final Future<String?> Function() tokenProvider;

  final http.Client _client;
  final Duration _timeout;

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    if (token == null) {
      throw const SyncException('UNAUTHORIZED', 'Sign in again.');
    }
    return <String, String>{
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
    };
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    http.Response response;
    try {
      response =
          await (method == 'GET'
                  ? _client.get(uri, headers: headers)
                  : _client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(_timeout);
    } on SocketException catch (error) {
      throw SyncException('OFFLINE', error.message);
    } on HttpException catch (error) {
      throw SyncException('OFFLINE', error.message);
    }

    final decoded = response.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(response.body) as Map<String, Object?>;

    if (response.statusCode >= 400) {
      final error = decoded['error'] as Map<String, Object?>?;
      throw SyncException(
        (error?['code'] as String?) ?? 'HTTP_${response.statusCode}',
        (error?['message'] as String?) ?? 'The server refused the request.',
        status: response.statusCode,
      );
    }
    return decoded;
  }

  @override
  Future<HeadResult> head() async {
    final body = await _send('GET', '/v1/head');
    return HeadResult(
      head: (body['head'] as num?)?.toInt() ?? 0,
      permissionVersion: (body['pv'] as num?)?.toInt() ?? 0,
      minAppVersion: body['min_app_version'] as String? ?? '0.0.0',
    );
  }

  @override
  Future<PushResult> push({required List<OutboxMutation> mutations}) async {
    final body = await _send(
      'POST',
      '/v1/push',
      body: <String, Object?>{
        'device_id': deviceId,
        'mutations': <Map<String, Object?>>[
          for (final mutation in mutations)
            <String, Object?>{
              'mutation_id': mutation.mutationId,
              'entity': mutation.entity,
              'row_id': mutation.rowId,
              'op': mutation.op,
              'fields': jsonDecode(mutation.payloadJson),
              'base_version': mutation.baseVersion,
              'device_ts': mutation.deviceTs.toUtc().toIso8601String(),
            },
        ],
      },
    );

    final results = (body['results'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();

    return PushResult(
      head: (body['head'] as num?)?.toInt() ?? 0,
      outcomes: <MutationOutcome>[
        for (final result in results)
          MutationOutcome(
            mutationId: result['mutation_id'] as String? ?? '',
            status: result['status'] as String? ?? 'rejected',
            serverVersion: (result['server_version'] as num?)?.toInt(),
            row: (result['row'] as Map?)?.cast<String, Object?>(),
            errorCode: (result['error'] as Map?)?['code'] as String?,
            errorMessage: (result['error'] as Map?)?['message'] as String?,
          ),
      ],
    );
  }

  @override
  Future<PullResult> pull({required int since, int limit = 200}) async {
    final body = await _send('GET', '/v1/pull?since=$since&limit=$limit');
    final rows = (body['rows'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();

    return PullResult(
      nextCursor: (body['next_cursor'] as num?)?.toInt() ?? since,
      head: (body['head'] as num?)?.toInt() ?? since,
      rows: <PullRow>[
        for (final row in rows)
          PullRow(
            seq: (row['seq'] as num?)?.toInt() ?? 0,
            entity: row['entity'] as String? ?? '',
            rowId: row['row_id'] as String? ?? '',
            op: row['op'] as String? ?? 'patch',
            version: (row['version'] as num?)?.toInt() ?? 0,
            data:
                (row['data'] as Map?)?.cast<String, Object?>() ??
                <String, Object?>{},
          ),
      ],
    );
  }
}
