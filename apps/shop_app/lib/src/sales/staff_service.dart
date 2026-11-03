import 'dart:convert';

import 'package:http/http.dart' as http;

/// One person who can sign in.
///
/// A hash never reaches this class: the server does not return one, and the app
/// has no use for it. `hasPin` is enough to show whether the till is unlocked by
/// a PIN or a password.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.active,
    required this.hasPin,
    this.branchName,
  });

  factory StaffMember.fromJson(Map<String, Object?> json) {
    return StaffMember(
      id: json['id']! as String,
      name: json['name'] as String? ?? '',
      phone: json['phone_e164'] as String? ?? '',
      role: json['role_key'] as String? ?? 'counter',
      active: (json['active'] as num?)?.toInt() == 1,
      hasPin: (json['has_pin'] as num?)?.toInt() == 1,
      branchName: json['branch_name'] as String?,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String role;
  final bool active;
  final bool hasPin;
  final String? branchName;

  String get roleLabel => switch (role) {
    'owner' => 'Owner',
    'manager' => 'Manager',
    'counter' => 'Sales / Counter',
    'designer' => 'Designer',
    'operator' => 'Operator',
    'accountant' => 'Accountant',
    'vendor_coordinator' => 'Vendor coordinator',
    'driver' => 'Driver',
    _ => role,
  };
}

/// Staff management needs the network — deliberately.
///
/// People and their rights are a shop-wide fact, and a tablet that has been
/// offline for a week must not be able to create an owner. The screen says so
/// instead of pretending.
class StaffService {
  StaffService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  Future<List<StaffMember>> list() async {
    final body = await _send('GET', '/v1/staff');
    final rows = (body['staff'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<String, Object?>>();
    return rows.map(StaffMember.fromJson).toList(growable: false);
  }

  Future<StaffMember> create({
    required String name,
    required String phone,
    required String role,
    required String password,
    String? pin,
  }) async {
    final body = await _send('POST', '/v1/staff', <String, Object?>{
      'name': name,
      'phone': phone,
      'role': role,
      'password': password,
      'pin': pin,
    });
    return StaffMember.fromJson(
      (body['staff']! as Map).cast<String, Object?>(),
    );
  }

  Future<StaffMember> update(
    String id, {
    String? role,
    bool? active,
    String? password,
    String? pin,
    bool clearPin = false,
  }) async {
    final body = await _send('PATCH', '/v1/staff/$id', <String, Object?>{
      'role': ?role,
      'active': ?active,
      'password': ?password,
      'pin': ?pin,
      if (clearPin) 'pin': null,
    });
    return StaffMember.fromJson(
      (body['staff']! as Map).cast<String, Object?>(),
    );
  }

  Future<Map<String, Object?>> _send(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final token = await tokenProvider();
    if (token == null) throw StateError('Sign in again to manage staff.');

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['content-type'] = 'application/json'
      ..headers['authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    );

    if (response.statusCode == 403) {
      throw StateError('Only an owner can manage staff.');
    }
    if (response.statusCode >= 400) {
      // The server's own words: "That phone number already has an account." is
      // more use to the owner than "request failed".
      final decoded = jsonDecode(response.body) as Map;
      final error = (decoded['error'] as Map?)?.cast<String, Object?>();
      throw StateError(
        error?['message'] as String? ??
            'Staff request failed (${response.statusCode}).',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  void dispose() => _client.close();
}
