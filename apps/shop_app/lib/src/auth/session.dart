import 'dart:convert';

/// The signed-in staff member, as the app needs them on every screen.
class Session {
  const Session({
    required this.userId,
    required this.tenantId,
    required this.role,
    required this.name,
    required this.deviceId,
    required this.permissionVersion,
    this.branchId,
  });

  final String userId;
  final String tenantId;
  final String? branchId;
  final String role;
  final String name;
  final String deviceId;
  final int permissionVersion;

  bool get isOwner => role == 'owner';
  bool get canCreateOrders => role != 'designer' && role != 'operator';

  /// What the home screen opens to, per design §16.3.
  String get homeTitle => switch (role) {
    'owner' => 'Today',
    'manager' => 'Live board',
    'counter' => 'New order',
    'designer' => 'Design queue',
    'operator' => 'My work',
    'accountant' => 'Receivables',
    'vendor_coordinator' => 'Vendor jobs',
    'driver' => 'Deliveries',
    _ => 'Home',
  };

  factory Session.fromLoginResponse(Map<String, Object?> json) {
    final user = (json['user']! as Map).cast<String, Object?>();
    return Session(
      userId: user['id']! as String,
      tenantId: user['tenant_id']! as String,
      branchId: user['branch_id'] as String?,
      role: user['role']! as String,
      name: user['name']! as String,
      deviceId: json['device_id']! as String,
      permissionVersion: (user['permission_version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'user_id': userId,
    'tenant_id': tenantId,
    'branch_id': branchId,
    'role': role,
    'name': name,
    'device_id': deviceId,
    'permission_version': permissionVersion,
  };

  factory Session.fromJson(Map<String, Object?> json) => Session(
    userId: json['user_id']! as String,
    tenantId: json['tenant_id']! as String,
    branchId: json['branch_id'] as String?,
    role: json['role']! as String,
    name: json['name']! as String,
    deviceId: json['device_id']! as String,
    permissionVersion: (json['permission_version'] as num?)?.toInt() ?? 1,
  );

  String encode() => jsonEncode(toJson());

  static Session? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Session.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }
}
