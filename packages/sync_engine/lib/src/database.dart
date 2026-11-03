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

/// Catalogue: reference data fetched from `/v1/catalogue`, not synced through
/// the change log. It changes when the owner edits the price book, which is
/// rare compared to the number of orders.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get code => text()();
  TextColumn get nameEn => text()();
  TextColumn get nameAr => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get kind => text()();

  /// `cost_plus`, `price_table` or `vendor_markup`.
  TextColumn get pricingMode => text()();

  IntColumn get sheetWidthMm => integer().nullable()();
  IntColumn get sheetHeightMm => integer().nullable()();
  IntColumn get bleedMm => integer().withDefault(const Constant(3))();
  IntColumn get gutterMm => integer().withDefault(const Constant(3))();
  IntColumn get setupSheets => integer().withDefault(const Constant(2))();
  IntColumn get spoilageBps => integer().withDefault(const Constant(500))();

  TextColumn get materialCode => text().nullable()();
  IntColumn get printRateFils => integer().nullable()();
  IntColumn get areaRateFilsPerSqm => integer().nullable()();

  IntColumn get markupBps => integer().withDefault(const Constant(0))();
  IntColumn get minOrderFils => integer().withDefault(const Constant(0))();
  IntColumn get roundingStepFils =>
      integer().withDefault(const Constant(100))();

  TextColumn get sizesJson => text().withDefault(const Constant('[]'))();
  TextColumn get finishesJson => text().withDefault(const Constant('[]'))();
  TextColumn get quantityPresetsJson =>
      text().withDefault(const Constant('[]'))();

  IntColumn get sort => integer().withDefault(const Constant(100))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('MaterialRow')
class Materials extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();
  IntColumn get gsm => integer().nullable()();
  IntColumn get costPerSheetFils => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('PriceRuleRow')
class PriceRules extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  IntColumn get priceBookVersion => integer()();
  TextColumn get productId => text().nullable()();
  TextColumn get label => text()();
  TextColumn get phase => text()();
  TextColumn get basis => text()();
  IntColumn get rateFils => integer()();
  IntColumn get minChargeFils => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer().withDefault(const Constant(100))();
  TextColumn get whenJson => text().withDefault(const Constant('[]'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();

  /// Null while a device is offline and using a temporary `T-0007` display.
  IntColumn get number => integer().nullable()();
  TextColumn get numberDisplay => text()();
  BoolColumn get isQuote => boolean().withDefault(const Constant(false))();

  TextColumn get customerId => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  TextColumn get deliveryMethod =>
      text().withDefault(const Constant('collect'))();
  TextColumn get notes => text().nullable()();

  IntColumn get subtotalFils => integer().withDefault(const Constant(0))();
  IntColumn get vatFils => integer().withDefault(const Constant(0))();
  IntColumn get totalFils => integer().withDefault(const Constant(0))();
  IntColumn get itemCount => integer().withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get description => text()();
  TextColumn get optionsJson => text().withDefault(const Constant('{}'))();
  IntColumn get quantity => integer()();
  IntColumn get priceBookVersion => integer()();

  /// The full pricing breakdown, frozen at the moment of sale. Changing the
  /// price book later must not be able to rewrite this line.
  TextColumn get breakdownJson => text()();

  IntColumn get subtotalFils => integer()();
  IntColumn get vatFils => integer()();
  IntColumn get totalFils => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Sync bookkeeping: cursor, last sync, last head.
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(
  tables: <Type>[
    Customers,
    CustomerPhones,
    Products,
    Materials,
    PriceRules,
    Orders,
    OrderItems,
    OutboxMutations,
    SyncMeta,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(products);
        await m.createTable(materials);
        await m.createTable(priceRules);
        await m.createTable(orders);
        await m.createTable(orderItems);
      }
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
      case 'orders':
        await _upsertOrder(data);
      case 'order_items':
        await _upsertOrderItem(data);
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

  // --- catalogue rows ------------------------------------------------------

  ProductsCompanion _productFromServer(
    Map<String, Object?> row,
  ) => ProductsCompanion.insert(
    id: row['id']! as String,
    tenantId: row['tenant_id']! as String,
    code: row['code']! as String,
    nameEn: row['name_en']! as String,
    nameAr: Value(row['name_ar'] as String?),
    category: Value(row['category'] as String?),
    kind: row['kind']! as String,
    pricingMode: row['pricing_mode']! as String,
    sheetWidthMm: Value((row['sheet_width_mm'] as num?)?.toInt()),
    sheetHeightMm: Value((row['sheet_height_mm'] as num?)?.toInt()),
    bleedMm: Value((row['bleed_mm'] as num?)?.toInt() ?? 3),
    gutterMm: Value((row['gutter_mm'] as num?)?.toInt() ?? 3),
    setupSheets: Value((row['setup_sheets'] as num?)?.toInt() ?? 2),
    spoilageBps: Value((row['spoilage_bps'] as num?)?.toInt() ?? 500),
    materialCode: Value(row['material_code'] as String?),
    printRateFils: Value((row['print_rate_fils'] as num?)?.toInt()),
    areaRateFilsPerSqm: Value((row['area_rate_fils_per_sqm'] as num?)?.toInt()),
    markupBps: Value((row['markup_bps'] as num?)?.toInt() ?? 0),
    minOrderFils: Value((row['min_order_fils'] as num?)?.toInt() ?? 0),
    roundingStepFils: Value(
      (row['rounding_step_fils'] as num?)?.toInt() ?? 100,
    ),
    sizesJson: Value(row['sizes_json'] as String? ?? '[]'),
    finishesJson: Value(row['finishes_json'] as String? ?? '[]'),
    quantityPresetsJson: Value(row['quantity_presets_json'] as String? ?? '[]'),
    sort: Value((row['sort'] as num?)?.toInt() ?? 100),
    active: Value((row['active'] as num?)?.toInt() != 0),
    updatedAt: Value(_asDate(row['updated_at'])),
  );

  MaterialsCompanion _materialFromServer(Map<String, Object?> row) =>
      MaterialsCompanion.insert(
        id: row['id']! as String,
        tenantId: row['tenant_id']! as String,
        code: row['code']! as String,
        name: row['name']! as String,
        type: Value(row['type'] as String?),
        gsm: Value((row['gsm'] as num?)?.toInt()),
        costPerSheetFils: Value(
          (row['cost_per_sheet_fils'] as num?)?.toInt() ?? 0,
        ),
      );

  PriceRulesCompanion _ruleFromServer(Map<String, Object?> row) =>
      PriceRulesCompanion.insert(
        id: row['id']! as String,
        tenantId: row['tenant_id']! as String,
        priceBookVersion: (row['price_book_version']! as num).toInt(),
        productId: Value(row['product_id'] as String?),
        label: row['label']! as String,
        phase: row['phase']! as String,
        basis: row['basis']! as String,
        rateFils: (row['rate_fils']! as num).toInt(),
        minChargeFils: Value((row['min_charge_fils'] as num?)?.toInt() ?? 0),
        priority: Value((row['priority'] as num?)?.toInt() ?? 100),
        whenJson: Value(row['when_json'] as String? ?? '[]'),
        active: Value((row['active'] as num?)?.toInt() != 0),
      );

  // --- order rows ----------------------------------------------------------

  Future<void> _upsertOrder(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(orders).insertOnConflictUpdate(
      OrdersCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        number: Value((data['number'] as num?)?.toInt()),
        numberDisplay: Value(data['number_display'] as String? ?? ''),
        isQuote: Value(_asBool(data['is_quote'])),
        customerId: Value(data['customer_id'] as String? ?? ''),
        customerName: Value(data['customer_name'] as String?),
        status: Value(data['status'] as String? ?? 'confirmed'),
        priority: Value(data['priority'] as String? ?? 'normal'),
        dueAt: Value(_asDate(data['due_at'])),
        deliveryMethod: Value(data['delivery_method'] as String? ?? 'collect'),
        notes: Value(data['notes'] as String?),
        subtotalFils: Value((data['subtotal_fils'] as num?)?.toInt() ?? 0),
        vatFils: Value((data['vat_fils'] as num?)?.toInt() ?? 0),
        totalFils: Value((data['total_fils'] as num?)?.toInt() ?? 0),
        itemCount: Value((data['item_count'] as num?)?.toInt() ?? 1),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertOrderItem(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(orderItems).insertOnConflictUpdate(
      OrderItemsCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        orderId: Value(data['order_id'] as String? ?? ''),
        productId: Value(data['product_id'] as String? ?? ''),
        description: Value(data['description'] as String? ?? ''),
        optionsJson: Value(data['options_json'] as String? ?? '{}'),
        quantity: Value((data['quantity'] as num?)?.toInt() ?? 0),
        priceBookVersion: Value(
          (data['price_book_version'] as num?)?.toInt() ?? 0,
        ),
        breakdownJson: Value(data['breakdown_json'] as String? ?? '{}'),
        subtotalFils: Value((data['subtotal_fils'] as num?)?.toInt() ?? 0),
        vatFils: Value((data['vat_fils'] as num?)?.toInt() ?? 0),
        totalFils: Value((data['total_fils'] as num?)?.toInt() ?? 0),
        status: Value(data['status'] as String? ?? 'pending'),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

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

  /// Live meta value, for screens that must follow a value changing underneath
  /// them (the price-book version after an edit).
  Stream<String?> watchMeta(String key) {
    return (select(syncMeta)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> setMeta(String key, String value) async {
    await into(
      syncMeta,
    ).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
  }

  Future<int> cursor() async => int.tryParse(await meta('cursor') ?? '0') ?? 0;

  Future<void> setCursor(int value) => setMeta('cursor', '$value');

  // -------------------------------------------------------------------------
  // Catalogue
  // -------------------------------------------------------------------------

  /// Replaces the local catalogue atomically. A half-applied price book would
  /// quote yesterday's price on one product and today's on another.
  Future<void> replaceCatalogue({
    required List<Map<String, Object?>> productRows,
    required List<Map<String, Object?>> materialRows,
    required List<Map<String, Object?>> ruleRows,
    required int priceBookVersion,
    required int vatBps,
  }) async {
    await transaction(() async {
      await delete(products).go();
      await delete(materials).go();
      await delete(priceRules).go();

      for (final row in productRows) {
        await into(products).insert(_productFromServer(row));
      }
      for (final row in materialRows) {
        await into(materials).insert(_materialFromServer(row));
      }
      for (final row in ruleRows) {
        await into(priceRules).insert(_ruleFromServer(row));
      }
      await setMeta('price_book_version', '$priceBookVersion');
      await setMeta('vat_bps', '$vatBps');
      await setMeta(
        'catalogue_synced_at',
        DateTime.now().toUtc().toIso8601String(),
      );
    });
  }

  Stream<List<Product>> watchProducts() {
    return (select(products)
          ..where((t) => t.active.equals(true))
          ..orderBy(<OrderClauseGenerator<$ProductsTable>>[
            (t) => OrderingTerm(expression: t.sort),
            (t) => OrderingTerm(expression: t.nameEn),
          ]))
        .watch();
  }

  /// Every price rule in the local book, for the price book editor.
  Stream<List<PriceRuleRow>> watchAllRules() {
    return (select(priceRules)
          ..orderBy(<OrderClauseGenerator<$PriceRulesTable>>[
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.label),
          ]))
        .watch();
  }

  Future<Product?> productById(String id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<MaterialRow?> materialByCode(String code) =>
      (select(materials)..where((t) => t.code.equals(code))).getSingleOrNull();

  Future<List<PriceRuleRow>> rulesForProduct(String productId, int version) {
    return (select(priceRules)
          ..where(
            (t) =>
                t.priceBookVersion.equals(version) &
                t.active.equals(true) &
                (t.productId.isNull() | t.productId.equals(productId)),
          )
          ..orderBy(<OrderClauseGenerator<$PriceRulesTable>>[
            (t) => OrderingTerm(expression: t.priority),
          ]))
        .get();
  }

  Future<int> priceBookVersion() async =>
      int.tryParse(await meta('price_book_version') ?? '0') ?? 0;

  Future<int> vatBps() async =>
      int.tryParse(await meta('vat_bps') ?? '500') ?? 500;

  // -------------------------------------------------------------------------
  // Orders
  // -------------------------------------------------------------------------

  /// Writes an order and its lines, and queues the mutations, in one local
  /// transaction. A crash cannot leave an order without its items, and the
  /// counter never waits for the network.
  Future<String> createOrderLocal({
    required String tenantId,
    required String? branchId,
    required String customerId,
    required String? customerName,
    required String userId,
    required String numberDisplay,
    required List<OrderLineDraft> lines,
    int? number,
    DateTime? dueAt,
    String status = 'confirmed',
    String priority = 'normal',
    String deliveryMethod = 'collect',
    String notes = '',
    bool isQuote = false,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('An order needs at least one line');
    }

    final orderId = Uuid7.generate();
    final now = DateTime.now().toUtc();
    var subtotal = 0;
    var vat = 0;
    var total = 0;
    for (final line in lines) {
      subtotal += line.subtotalFils;
      vat += line.vatFils;
      total += line.totalFils;
    }

    await transaction(() async {
      await into(orders).insert(
        OrdersCompanion.insert(
          id: orderId,
          tenantId: tenantId,
          branchId: Value(branchId),
          number: Value(number),
          numberDisplay: numberDisplay,
          isQuote: Value(isQuote),
          customerId: customerId,
          customerName: Value(customerName),
          status: Value(status),
          priority: Value(priority),
          dueAt: Value(dueAt),
          deliveryMethod: Value(deliveryMethod),
          notes: Value(notes),
          subtotalFils: Value(subtotal),
          vatFils: Value(vat),
          totalFils: Value(total),
          itemCount: Value(lines.length),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await _enqueue(
        entity: 'orders',
        rowId: orderId,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'number': number,
          'number_display': numberDisplay,
          'is_quote': isQuote ? 1 : 0,
          'customer_id': customerId,
          'customer_name': customerName,
          'status': status,
          'priority': priority,
          'due_at': dueAt?.toIso8601String(),
          'delivery_method': deliveryMethod,
          'notes': notes,
          'subtotal_fils': subtotal,
          'vat_fils': vat,
          'total_fils': total,
          'item_count': lines.length,
        },
      );

      for (final line in lines) {
        final itemId = Uuid7.generate();
        await into(orderItems).insert(
          OrderItemsCompanion.insert(
            id: itemId,
            tenantId: tenantId,
            branchId: Value(branchId),
            orderId: orderId,
            productId: line.productId,
            description: line.description,
            optionsJson: Value(line.optionsJson),
            quantity: line.quantity,
            priceBookVersion: line.priceBookVersion,
            breakdownJson: line.breakdownJson,
            subtotalFils: line.subtotalFils,
            vatFils: line.vatFils,
            totalFils: line.totalFils,
            createdAt: now,
            updatedAt: now,
            createdBy: Value(userId),
          ),
        );

        await _enqueue(
          entity: 'order_items',
          rowId: itemId,
          op: 'insert',
          baseVersion: 0,
          fields: <String, Object?>{
            'order_id': orderId,
            'product_id': line.productId,
            'description': line.description,
            'options_json': line.optionsJson,
            'quantity': line.quantity,
            'price_book_version': line.priceBookVersion,
            'breakdown_json': line.breakdownJson,
            'subtotal_fils': line.subtotalFils,
            'vat_fils': line.vatFils,
            'total_fils': line.totalFils,
            'status': 'pending',
          },
        );
      }
    });

    return orderId;
  }

  Stream<List<Order>> watchOrders({int limit = 200}) {
    return (select(orders)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$OrdersTable>>[
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Future<List<OrderItem>> itemsFor(String orderId) =>
      (select(orderItems)..where((t) => t.orderId.equals(orderId))).get();

  /// The number to WhatsApp or call: the primary one, else any live number.
  Future<String?> primaryPhoneFor(String customerId) async {
    final row =
        await (select(customerPhones)
              ..where(
                (t) => t.customerId.equals(customerId) & t.deletedAt.isNull(),
              )
              ..orderBy(<OrderClauseGenerator<$CustomerPhonesTable>>[
                (t) => OrderingTerm(
                  expression: t.isPrimary,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.e164;
  }

  Future<Order?> orderById(String id) =>
      (select(orders)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Turns a quote into an order: copies the lines with their frozen
  /// breakdowns (never re-prices them), marks the quote converted, and queues
  /// everything so the server sees both changes in the next push.
  Future<String> convertQuoteToOrder({
    required String quoteId,
    required String numberDisplay,
    required int? number,
    required String userId,
  }) async {
    final quote = await orderById(quoteId);
    if (quote == null) {
      throw StateError('Quote $quoteId not found');
    }
    if (!quote.isQuote) {
      throw StateError('Order ${quote.numberDisplay} is not a quote');
    }

    final items = await itemsFor(quoteId);
    final now = DateTime.now().toUtc();
    final orderId = Uuid7.generate();

    await transaction(() async {
      await into(orders).insert(
        OrdersCompanion.insert(
          id: orderId,
          tenantId: quote.tenantId,
          branchId: Value(quote.branchId),
          number: Value(number),
          numberDisplay: numberDisplay,
          isQuote: const Value(false),
          customerId: quote.customerId,
          customerName: Value(quote.customerName),
          status: const Value('confirmed'),
          priority: Value(quote.priority),
          dueAt: Value(quote.dueAt),
          deliveryMethod: Value(quote.deliveryMethod),
          notes: Value(quote.notes),
          subtotalFils: Value(quote.subtotalFils),
          vatFils: Value(quote.vatFils),
          totalFils: Value(quote.totalFils),
          itemCount: Value(items.length),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );
      await _enqueue(
        entity: 'orders',
        rowId: orderId,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'number': number,
          'number_display': numberDisplay,
          'is_quote': 0,
          'customer_id': quote.customerId,
          'customer_name': quote.customerName,
          'status': 'confirmed',
          'priority': quote.priority,
          'due_at': quote.dueAt?.toIso8601String(),
          'delivery_method': quote.deliveryMethod,
          'notes': quote.notes,
          'subtotal_fils': quote.subtotalFils,
          'vat_fils': quote.vatFils,
          'total_fils': quote.totalFils,
          'item_count': items.length,
        },
      );

      for (final item in items) {
        final itemId = Uuid7.generate();
        await into(orderItems).insert(
          OrderItemsCompanion.insert(
            id: itemId,
            tenantId: item.tenantId,
            branchId: Value(item.branchId),
            orderId: orderId,
            productId: item.productId,
            description: item.description,
            optionsJson: Value(item.optionsJson),
            quantity: item.quantity,
            priceBookVersion: item.priceBookVersion,
            breakdownJson: item.breakdownJson,
            subtotalFils: item.subtotalFils,
            vatFils: item.vatFils,
            totalFils: item.totalFils,
            createdAt: now,
            updatedAt: now,
            createdBy: Value(userId),
          ),
        );
        await _enqueue(
          entity: 'order_items',
          rowId: itemId,
          op: 'insert',
          baseVersion: 0,
          fields: <String, Object?>{
            'order_id': orderId,
            'product_id': item.productId,
            'description': item.description,
            'options_json': item.optionsJson,
            'quantity': item.quantity,
            'price_book_version': item.priceBookVersion,
            'breakdown_json': item.breakdownJson,
            'subtotal_fils': item.subtotalFils,
            'vat_fils': item.vatFils,
            'total_fils': item.totalFils,
            'status': 'pending',
          },
        );
      }

      await (update(orders)..where((t) => t.id.equals(quoteId))).write(
        OrdersCompanion(
          status: const Value('converted'),
          updatedAt: Value(now),
        ),
      );
      await _enqueue(
        entity: 'orders',
        rowId: quoteId,
        op: 'patch',
        baseVersion: quote.version,
        fields: <String, Object?>{'status': 'converted'},
      );
    });

    return orderId;
  }

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

/// One line the counter is about to sell, already priced and frozen.
///
/// The breakdown JSON travels with the order rather than being recomputed, so a
/// price-book edit at 3pm cannot change what a customer agreed to at 10am.
class OrderLineDraft {
  const OrderLineDraft({
    required this.productId,
    required this.description,
    required this.optionsJson,
    required this.quantity,
    required this.priceBookVersion,
    required this.breakdownJson,
    required this.subtotalFils,
    required this.vatFils,
    required this.totalFils,
  });

  final String productId;
  final String description;
  final String optionsJson;
  final int quantity;
  final int priceBookVersion;
  final String breakdownJson;
  final int subtotalFils;
  final int vatFils;
  final int totalFils;
}
