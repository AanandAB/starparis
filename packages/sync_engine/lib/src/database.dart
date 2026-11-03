/// The local database: the app's source of truth.
///
/// Every screen reads from here, never from the network, so a list opens in
/// milliseconds and the counter keeps working when the internet does not.
/// Rows arrive by pull (server) or are written locally and queued in the
/// outbox; both paths go through this file so there is one place that knows
/// what a row looks like.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:starparis_domain/starparis_domain.dart';

part 'database.g.dart';

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get company => text().nullable()();
  TextColumn get trn => text().nullable()();
  TextColumn get tier => text().withDefault(const Constant('retail'))();
  IntColumn get creditLimitFils => integer().withDefault(const Constant(0))();
  IntColumn get paymentTermsDays => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get whatsappOptIn => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  /// Server tombstone. Rows are never hard-deleted, so a deletion can sync.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class CustomerPhones extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get customerId => text()();

  /// Normalised `+9715…` and the last nine digits, which is what the search
  /// box matches against (people type 050…, 971…, or just the last digits).
  TextColumn get e164 => text()();
  TextColumn get phoneLast9 => text()();
  TextColumn get label => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// One pending change, exactly as the Worker expects it.
class OutboxMutations extends Table {
  TextColumn get mutationId => text()();
  TextColumn get entity => text()();
  TextColumn get rowId => text()();
  TextColumn get op => text()();
  TextColumn get payloadJson => text()();
  IntColumn get baseVersion => integer()();
  DateTimeColumn get deviceTs => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{mutationId};
}

/// Sync bookkeeping: cursor, last sync, last head.
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(
  tables: <Type>[Customers, CustomerPhones, OutboxMutations, SyncMeta],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );

  // -------------------------------------------------------------------------
  // Reads
  // -------------------------------------------------------------------------

  /// Live customer list for the current tenant, tombstones excluded.
  Stream<List<Customer>> watchCustomers({int limit = 500}) {
    return (select(customers)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$CustomersTable>>[
            (t) => OrderingTerm(expression: t.name),
          ])
          ..limit(limit))
        .watch();
  }

  /// Phone-first search: the counter types a number, not a name.
  Stream<List<Customer>> searchCustomers(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return watchCustomers();
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    final like = '%${trimmed.replaceAll('%', '')}%';
    final phoneLike = digits.isEmpty
        ? null
        : '%${digits.length > 9 ? digits.substring(digits.length - 9) : digits}%';

    final statement =
        select(customers).join(<Join<HasResultSet, dynamic>>[
            leftOuterJoin(
              customerPhones,
              customerPhones.customerId.equalsExp(customers.id) &
                  customerPhones.deletedAt.isNull(),
            ),
          ])
          ..where(customers.deletedAt.isNull())
          ..where(
            customers.name.like(like) |
                customers.company.like(like) |
                (phoneLike == null
                    ? const Constant(false)
                    : customerPhones.phoneLast9.like(phoneLike)),
          )
          ..limit(200);

    return statement.watch().map((rows) {
      final seen = <String>{};
      return <Customer>[
        for (final row in rows)
          if (seen.add(row.readTable(customers).id)) row.readTable(customers),
      ];
    });
  }

  Future<Customer?> customerById(String id) =>
      (select(customers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<int> watchPendingCount() {
    final query = selectOnly(outboxMutations)
      ..addColumns(<Expression<Object>>[countAll()]);
    return query.watchSingle().map((row) => row.read(countAll()) ?? 0);
  }

  Future<int> pendingCount() async {
    final query = selectOnly(outboxMutations)
      ..addColumns(<Expression<Object>>[countAll()]);
    final row = await query.getSingle();
    return row.read(countAll()) ?? 0;
  }

  // -------------------------------------------------------------------------
  // Writes from the device
  // -------------------------------------------------------------------------

  /// Creates a customer offline: the row is written and the mutation queued in
  /// one transaction, so a crash mid-save cannot produce one without the other.
  Future<String> createCustomerLocal({
    required String tenantId,
    required String? branchId,
    required String name,
    String? company,
    String? phoneE164,
    String? notes,
    required String userId,
  }) async {
    final id = Uuid7.generate();
    final phoneId = phoneE164 == null ? null : Uuid7.generate();
    final now = DateTime.now().toUtc();
    final normalised = phoneE164 == null ? null : _normalise(phoneE164);

    await transaction(() async {
      await into(customers).insert(
        CustomersCompanion.insert(
          id: id,
          tenantId: tenantId,
          branchId: Value(branchId),
          name: name,
          company: Value(company),
          notes: Value(notes),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await _enqueue(
        entity: 'customers',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'name': name,
          'company': ?company,
          'notes': ?notes,
        },
      );

      if (phoneId != null && normalised != null) {
        await into(customerPhones).insert(
          CustomerPhonesCompanion.insert(
            id: phoneId,
            tenantId: tenantId,
            customerId: id,
            e164: normalised.e164,
            phoneLast9: normalised.last9,
            isPrimary: const Value(true),
          ),
        );
        await _enqueue(
          entity: 'customer_phones',
          rowId: phoneId,
          op: 'insert',
          baseVersion: 0,
          fields: <String, Object?>{
            'customer_id': id,
            'e164': normalised.e164,
            'phone_last9': normalised.last9,
            'is_primary': 1,
          },
        );
      }
    });

    return id;
  }

  /// Edits a customer locally and queues a patch. Two edits in a row become one
  /// mutation: the counter typing a note character by character must not cost
  /// one API call per keystroke.
  Future<void> updateCustomerLocal({
    required String id,
    required Map<String, Object?> fields,
  }) async {
    final row = await customerById(id);
    if (row == null) {
      throw StateError('Customer $id not found');
    }

    final companion = CustomersCompanion(
      name: fields.containsKey('name')
          ? Value(fields['name']! as String)
          : const Value.absent(),
      company: fields.containsKey('company')
          ? Value(fields['company'] as String?)
          : const Value.absent(),
      notes: fields.containsKey('notes')
          ? Value(fields['notes'] as String?)
          : const Value.absent(),
      tier: fields.containsKey('tier')
          ? Value(fields['tier']! as String)
          : const Value.absent(),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    await transaction(() async {
      await (update(customers)..where((t) => t.id.equals(id))).write(companion);
      await _enqueue(
        entity: 'customers',
        rowId: id,
        op: 'patch',
        baseVersion: row.version,
        fields: fields,
      );
    });
  }

  // -------------------------------------------------------------------------
  // Writes from the server
  // -------------------------------------------------------------------------

  /// Applies one row from a pull. Unknown entities are ignored on purpose: an
  /// older device must not crash because the server learned a new table.
  Future<void> applyServerRow(String entity, Map<String, Object?> data) async {
    switch (entity) {
      case 'customers':
        await _upsertCustomer(data);
      case 'customer_phones':
        await _upsertPhone(data);
      default:
        break;
    }
  }

  Future<void> _upsertCustomer(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(customers).insertOnConflictUpdate(
      CustomersCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        name: Value(data['name'] as String? ?? ''),
        company: Value(data['company'] as String?),
        trn: Value(data['trn'] as String?),
        tier: Value(data['tier'] as String? ?? 'retail'),
        creditLimitFils: Value(
          (data['credit_limit_fils'] as num?)?.toInt() ?? 0,
        ),
        paymentTermsDays: Value(
          (data['payment_terms_days'] as num?)?.toInt() ?? 0,
        ),
        notes: Value(data['notes'] as String?),
        whatsappOptIn: Value(_asBool(data['whatsapp_opt_in'])),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertPhone(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    final e164 = data['e164'] as String? ?? '';
    await into(customerPhones).insertOnConflictUpdate(
      CustomerPhonesCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        customerId: Value(data['customer_id'] as String? ?? ''),
        e164: Value(e164),
        phoneLast9: Value(
          data['phone_last9'] as String? ?? _normalise(e164).last9,
        ),
        label: Value(data['label'] as String?),
        isPrimary: Value(_asBool(data['is_primary'])),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Outbox
  // -------------------------------------------------------------------------

  Future<void> _enqueue({
    required String entity,
    required String rowId,
    required String op,
    required int baseVersion,
    required Map<String, Object?> fields,
  }) async {
    final existingQuery = select(outboxMutations)
      ..where(
        (t) =>
            t.entity.equals(entity) &
            t.rowId.equals(rowId) &
            t.op.isNotValue('delete'),
      )
      ..limit(1);
    final existing = await existingQuery.getSingleOrNull();

    if (existing != null &&
        (existing.op == 'insert' || existing.op == 'patch')) {
      final merged = <String, Object?>{
        ...jsonDecode(existing.payloadJson) as Map<String, Object?>,
        ...fields,
      };
      await (update(
        outboxMutations,
      )..where((t) => t.mutationId.equals(existing.mutationId))).write(
        OutboxMutationsCompanion(
          payloadJson: Value(jsonEncode(merged)),
          deviceTs: Value(DateTime.now().toUtc()),
        ),
      );
      return;
    }

    await into(outboxMutations).insert(
      OutboxMutationsCompanion.insert(
        mutationId: Uuid7.generate(),
        entity: entity,
        rowId: rowId,
        op: op,
        payloadJson: jsonEncode(fields),
        baseVersion: baseVersion,
        deviceTs: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<OutboxMutation>> nextBatch({int limit = 100}) {
    return (select(outboxMutations)
          ..orderBy(<OrderClauseGenerator<$OutboxMutationsTable>>[
            (t) => OrderingTerm(expression: t.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> markApplied(List<String> mutationIds) async {
    if (mutationIds.isEmpty) return;
    await (delete(
      outboxMutations,
    )..where((t) => t.mutationId.isIn(mutationIds))).go();
  }

  Future<void> markUnsyncedEdit({
    required String mutationId,
    required int baseVersion,
  }) async {
    await (update(outboxMutations)
          ..where((t) => t.mutationId.equals(mutationId)))
        .write(OutboxMutationsCompanion(baseVersion: Value(baseVersion)));
  }

  Future<void> recordFailure(String mutationId, String error) async {
    final row = await (select(
      outboxMutations,
    )..where((t) => t.mutationId.equals(mutationId))).getSingleOrNull();
    if (row == null) return;
    await (update(
      outboxMutations,
    )..where((t) => t.mutationId.equals(mutationId))).write(
      OutboxMutationsCompanion(
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Meta
  // -------------------------------------------------------------------------

  Future<String?> meta(String key) async {
    final row = await (select(
      syncMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) async {
    await into(
      syncMeta,
    ).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
  }

  Future<int> cursor() async => int.tryParse(await meta('cursor') ?? '0') ?? 0;

  Future<void> setCursor(int value) => setMeta('cursor', '$value');

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static ({String e164, String last9}) _normalise(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return (
      e164: '+$digits',
      last9: digits.length > 9 ? digits.substring(digits.length - 9) : digits,
    );
  }

  static bool _asBool(Object? value) => switch (value) {
    final bool b => b,
    final num n => n != 0,
    final String s => s == '1' || s.toLowerCase() == 'true',
    _ => false,
  };

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
