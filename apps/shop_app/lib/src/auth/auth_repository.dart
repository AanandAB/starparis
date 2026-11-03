/// Sign-in, token refresh, offline PIN and the database key.
///
/// All secrets live in the OS secure store: DPAPI on Windows, Keystore on
/// Android. Nothing here is written to the database, a log or a file.
///
/// The access token is short-lived (15 minutes) by design, so it is refreshed
/// lazily rather than cached for the session — a cached token is how "it worked
/// yesterday" bugs happen.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'pin.dart';
import 'session.dart';

class AuthException implements Exception {
  const AuthException(this.code, this.message);

  final String code;
  final String message;

  bool get needsLogin => code == 'SESSION_EXPIRED' || code == 'UNAUTHORIZED';

  @override
  String toString() => message;
}

enum PinCheck { ok, wrong, locked }

class AuthRepository {
  AuthRepository({
    required this.baseUrl,
    FlutterSecureStorage? storage,
    http.Client? client,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client();

  final String baseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _client;

  static const String _sessionKey = 'session_json';
  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _expiryKey = 'token_expiry_ms';
  static const String _pinKey = 'pin_hash';
  static const String _failKey = 'pin_failures';
  static const String _lockKey = 'pin_lock_until_ms';
  static const String _dbKeyName = 'db_key';

  // -------------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------------

  Future<Session> login({
    required String phone,
    required String password,
    required String deviceName,
    String? deviceId,
  }) async {
    final body = await _post('/v1/auth/login', <String, Object?>{
      'phone': phone,
      'password': password,
      'device': <String, Object?>{
        'name': deviceName,
        'platform': Platform.isWindows ? 'windows' : 'android',
        'app_version': '0.1.0',
        'id': ?deviceId,
      },
    });

    final session = Session.fromLoginResponse(body);
    await _storeTokens(body);
    await _storage.write(key: _sessionKey, value: session.encode());
    return session;
  }

  Future<Session?> restore() async {
    final raw = await _storage.read(key: _sessionKey);
    return Session.decode(raw);
  }

  /// Returns a valid access token, refreshing it when it is about to expire.
  Future<String?> accessToken() async {
    final token = await _storage.read(key: _accessKey);
    if (token == null) return null;

    final expiryMs = int.tryParse(await _storage.read(key: _expiryKey) ?? '');
    if (expiryMs != null &&
        DateTime.now().millisecondsSinceEpoch > expiryMs - 90000) {
      await refresh();
      return _storage.read(key: _accessKey);
    }
    return token;
  }

  Future<void> refresh() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null) {
      throw const AuthException('SESSION_EXPIRED', 'Please sign in again.');
    }
    try {
      final body = await _post('/v1/auth/refresh', <String, Object?>{
        'refresh_token': refreshToken,
      });
      await _storeTokens(body);
    } on AuthException {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _accessKey);
    if (token != null) {
      try {
        await _client
            .post(
              Uri.parse('$baseUrl/v1/auth/logout'),
              headers: <String, String>{'authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Signing out must work with no connection: the local wipe matters
        // more than telling the server.
      }
    }
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiryKey);
  }

  Future<void> _storeTokens(Map<String, Object?> body) async {
    await _storage.write(
      key: _accessKey,
      value: body['access_token'] as String?,
    );
    await _storage.write(
      key: _refreshKey,
      value: body['refresh_token'] as String?,
    );
    final expiresIn = (body['expires_in'] as num?)?.toInt() ?? 900;
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));
    await _storage.write(
      key: _expiryKey,
      value: expiry.millisecondsSinceEpoch.toString(),
    );
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw const AuthException(
        'OFFLINE',
        'No internet. Check the connection and try again.',
      );
    }

    final decoded = response.body.isEmpty
        ? <String, Object?>{}
        : (jsonDecode(response.body) as Map).cast<String, Object?>();

    if (response.statusCode >= 400) {
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw AuthException(
        error?['code'] as String? ?? 'HTTP_${response.statusCode}',
        error?['message'] as String? ?? 'Sign-in failed.',
      );
    }
    return decoded;
  }

  // -------------------------------------------------------------------------
  // Offline PIN
  // -------------------------------------------------------------------------

  Future<bool> hasPin() async => (await _storage.read(key: _pinKey)) != null;

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: hashPin(pin));
    await _storage.write(key: _failKey, value: '0');
    await _storage.delete(key: _lockKey);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _failKey);
    await _storage.delete(key: _lockKey);
  }

  Future<PinCheck> checkPin(String pin) async {
    final lockedUntil = int.tryParse(await _storage.read(key: _lockKey) ?? '');
    if (lockedUntil != null &&
        DateTime.now().millisecondsSinceEpoch < lockedUntil) {
      return PinCheck.locked;
    }

    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return PinCheck.wrong;

    if (verifyPin(pin, stored)) {
      await _storage.write(key: _failKey, value: '0');
      await _storage.delete(key: _lockKey);
      return PinCheck.ok;
    }

    final failures =
        (int.tryParse(await _storage.read(key: _failKey) ?? '0') ?? 0) + 1;
    await _storage.write(key: _failKey, value: '$failures');
    if (failures >= 5) {
      // Lockout grows: 60s after the fifth failure, 120s after the sixth…
      final seconds = 60 * (failures - 4);
      final until = DateTime.now().add(Duration(seconds: seconds));
      await _storage.write(
        key: _lockKey,
        value: until.millisecondsSinceEpoch.toString(),
      );
      return PinCheck.locked;
    }
    return PinCheck.wrong;
  }

  Future<int> pinFailures() async =>
      int.tryParse(await _storage.read(key: _failKey) ?? '0') ?? 0;

  // -------------------------------------------------------------------------
  // Database key
  // -------------------------------------------------------------------------

  /// The SQLCipher passphrase. Generated once per installation and kept in the
  /// OS keychain; losing it means losing the local cache, never the server data.
  Future<String> databaseKey() async {
    final existing = await _storage.read(key: _dbKeyName);
    if (existing != null) return existing;
    final key = newSalt() + newSalt();
    await _storage.write(key: _dbKeyName, value: key);
    return key;
  }
}
