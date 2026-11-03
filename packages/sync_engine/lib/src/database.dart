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

  /// Which production workflow this product creates (see WorkflowStages).
  TextColumn get workflowKey =>
      text().withDefault(const Constant('print_std'))();

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

/// Production stages per workflow key. Reference data from `/v1/catalogue`;
/// the device needs it offline because tasks are generated on the device.
class WorkflowStages extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get workflowKey =>
      text().withDefault(const Constant('print_std'))();
  TextColumn get stageKey => text()();
  TextColumn get nameEn => text()();
  TextColumn get nameAr => text().nullable()();
  IntColumn get sequence => integer()();
  TextColumn get requiredRole => text()();
  BoolColumn get waitsForPrevious =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// One piece of work in the shop: one stage of one order.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get orderId => text()();
  TextColumn get orderItemId => text().nullable()();
  TextColumn get stageKey => text()();
  TextColumn get stageName => text()();
  IntColumn get sequence => integer()();
  TextColumn get title => text()();

  /// waiting, available, assigned, in_progress, paused, done, rework, cancelled
  TextColumn get status => text().withDefault(const Constant('waiting'))();
  TextColumn get assignedTo => text().nullable()();
  TextColumn get requiredRole => text()();
  IntColumn get qty => integer().withDefault(const Constant(0))();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get doneAt => dateTime().nullable()();
  TextColumn get reason => text().nullable()();
  IntColumn get reworkCount => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Proofs are links plus a decision, not files (see migration 0004).
class Proofs extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get orderId => text()();

  /// The version the customer sees: v1, v2, …
  IntColumn get revision => integer().withDefault(const Constant(1))();
  TextColumn get kind => text().withDefault(const Constant('proof'))();
  TextColumn get label => text()();
  TextColumn get url => text()();
  TextColumn get note => text().nullable()();

  /// draft, sent, approved, rejected, superseded
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  TextColumn get decidedNote => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Worked minutes, written by the server when a task leaves in_progress.
class TimeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get taskId => text()();
  TextColumn get orderId => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get minutes => integer()();
  BoolColumn get auto => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// An issued invoice. Immutable by design: only the server's paid cache and the
/// void transition ever change, and corrections are credit notes.
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get orderId => text()();
  TextColumn get number => text()();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text()();
  TextColumn get customerTrn => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  IntColumn get subtotalFils => integer()();
  IntColumn get discountFils => integer().withDefault(const Constant(0))();
  IntColumn get vatBps => integer().withDefault(const Constant(500))();
  IntColumn get vatFils => integer()();
  IntColumn get totalFils => integer()();
  IntColumn get paidFils => integer().withDefault(const Constant(0))();

  /// Credit notes issued against this invoice, mirrored from the server.
  IntColumn get creditedFils => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('issued'))();
  TextColumn get notes => text().nullable()();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class InvoiceLines extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get invoiceId => text()();
  IntColumn get lineNo => integer()();
  TextColumn get description => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitFils => integer()();
  IntColumn get amountFils => integer()();
  IntColumn get vatBps => integer().withDefault(const Constant(500))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get invoiceId => text()();
  IntColumn get amountFils => integer()();
  TextColumn get method => text()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get takenBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// A credit note against an invoice. The only way money is given back: the
/// invoice itself never changes.
class CreditNotes extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get invoiceId => text()();
  TextColumn get number => text()();
  DateTimeColumn get issuedAt => dateTime()();
  TextColumn get reason => text()();
  IntColumn get subtotalFils => integer()();
  IntColumn get vatBps => integer().withDefault(const Constant(500))();
  IntColumn get vatFils => integer()();
  IntColumn get totalFils => integer()();
  IntColumn get refundedFils => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Refunds extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get creditNoteId => text()();
  TextColumn get invoiceId => text()();
  IntColumn get amountFils => integer()();
  TextColumn get method => text()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get refundedAt => dateTime()();
  TextColumn get refundedBy => text().nullable()();
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
    WorkflowStages,
    Tasks,
    Proofs,
    TimeEntries,
    Invoices,
    InvoiceLines,
    Payments,
    CreditNotes,
    Refunds,
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
  int get schemaVersion => 6;

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
      if (from < 3) {
        // Products gained a workflow pointer; a database created at version 2
        // has the table but not the column.
        if (from >= 2) {
          await m.addColumn(products, products.workflowKey);
        }
        await m.createTable(workflowStages);
        await m.createTable(tasks);
      }
      if (from < 4) {
        await m.createTable(proofs);
        await m.createTable(timeEntries);
      }
      if (from < 5) {
        await m.createTable(invoices);
        await m.createTable(invoiceLines);
        await m.createTable(payments);
      }
      if (from < 6) {
        await m.createTable(creditNotes);
        await m.createTable(refunds);
        if (from >= 5) {
          await m.addColumn(invoices, invoices.creditedFils);
        }
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
      case 'tasks':
        await _upsertTask(data);
      case 'proofs':
        await _upsertProof(data);
      case 'time_entries':
        await _upsertTimeEntry(data);
      case 'invoices':
        await _upsertInvoice(data);
      case 'invoice_lines':
        await _upsertInvoiceLine(data);
      case 'payments':
        await _upsertPayment(data);
      case 'credit_notes':
        await _upsertCreditNote(data);
      case 'refunds':
        await _upsertRefund(data);
      default:
        break;
    }
  }

  Future<void> _upsertCreditNote(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(creditNotes).insertOnConflictUpdate(
      CreditNotesCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        invoiceId: Value(data['invoice_id'] as String? ?? ''),
        number: Value(data['number'] as String? ?? ''),
        issuedAt: Value(_asDate(data['issued_at']) ?? DateTime.now().toUtc()),
        reason: Value(data['reason'] as String? ?? ''),
        subtotalFils: Value((data['subtotal_fils'] as num?)?.toInt() ?? 0),
        vatBps: Value((data['vat_bps'] as num?)?.toInt() ?? 500),
        vatFils: Value((data['vat_fils'] as num?)?.toInt() ?? 0),
        totalFils: Value((data['total_fils'] as num?)?.toInt() ?? 0),
        refundedFils: Value((data['refunded_fils'] as num?)?.toInt() ?? 0),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertRefund(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(refunds).insertOnConflictUpdate(
      RefundsCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        creditNoteId: Value(data['credit_note_id'] as String? ?? ''),
        invoiceId: Value(data['invoice_id'] as String? ?? ''),
        amountFils: Value((data['amount_fils'] as num?)?.toInt() ?? 0),
        method: Value(data['method'] as String? ?? 'cash'),
        reference: Value(data['reference'] as String?),
        refundedAt: Value(
          _asDate(data['refunded_at']) ?? DateTime.now().toUtc(),
        ),
        refundedBy: Value(data['refunded_by'] as String?),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertInvoice(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(invoices).insertOnConflictUpdate(
      InvoicesCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        orderId: Value(data['order_id'] as String? ?? ''),
        number: Value(data['number'] as String? ?? ''),
        issuedAt: Value(_asDate(data['issued_at']) ?? DateTime.now().toUtc()),
        dueAt: Value(_asDate(data['due_at'])),
        customerId: Value(data['customer_id'] as String? ?? ''),
        customerName: Value(data['customer_name'] as String? ?? ''),
        customerTrn: Value(data['customer_trn'] as String?),
        customerAddress: Value(data['customer_address'] as String?),
        subtotalFils: Value((data['subtotal_fils'] as num?)?.toInt() ?? 0),
        discountFils: Value((data['discount_fils'] as num?)?.toInt() ?? 0),
        vatBps: Value((data['vat_bps'] as num?)?.toInt() ?? 500),
        vatFils: Value((data['vat_fils'] as num?)?.toInt() ?? 0),
        totalFils: Value((data['total_fils'] as num?)?.toInt() ?? 0),
        paidFils: Value((data['paid_fils'] as num?)?.toInt() ?? 0),
        creditedFils: Value((data['credited_fils'] as num?)?.toInt() ?? 0),
        status: Value(data['status'] as String? ?? 'issued'),
        notes: Value(data['notes'] as String?),
        voidReason: Value(data['void_reason'] as String?),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertInvoiceLine(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(invoiceLines).insertOnConflictUpdate(
      InvoiceLinesCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        invoiceId: Value(data['invoice_id'] as String? ?? ''),
        lineNo: Value((data['line_no'] as num?)?.toInt() ?? 0),
        description: Value(data['description'] as String? ?? ''),
        quantity: Value((data['quantity'] as num?)?.toInt() ?? 0),
        unitFils: Value((data['unit_fils'] as num?)?.toInt() ?? 0),
        amountFils: Value((data['amount_fils'] as num?)?.toInt() ?? 0),
        vatBps: Value((data['vat_bps'] as num?)?.toInt() ?? 500),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertPayment(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(payments).insertOnConflictUpdate(
      PaymentsCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        invoiceId: Value(data['invoice_id'] as String? ?? ''),
        amountFils: Value((data['amount_fils'] as num?)?.toInt() ?? 0),
        method: Value(data['method'] as String? ?? 'cash'),
        reference: Value(data['reference'] as String?),
        takenAt: Value(_asDate(data['taken_at']) ?? DateTime.now().toUtc()),
        takenBy: Value(data['taken_by'] as String?),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertProof(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(proofs).insertOnConflictUpdate(
      ProofsCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        orderId: Value(data['order_id'] as String? ?? ''),
        revision: Value((data['revision'] as num?)?.toInt() ?? 1),
        kind: Value(data['kind'] as String? ?? 'proof'),
        label: Value(data['label'] as String? ?? ''),
        url: Value(data['url'] as String? ?? ''),
        note: Value(data['note'] as String?),
        status: Value(data['status'] as String? ?? 'draft'),
        sentAt: Value(_asDate(data['sent_at'])),
        decidedAt: Value(_asDate(data['decided_at'])),
        decidedNote: Value(data['decided_note'] as String?),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertTimeEntry(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(timeEntries).insertOnConflictUpdate(
      TimeEntriesCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        taskId: Value(data['task_id'] as String? ?? ''),
        orderId: Value(data['order_id'] as String? ?? ''),
        userId: Value(data['user_id'] as String?),
        startedAt: Value(_asDate(data['started_at']) ?? DateTime.now().toUtc()),
        endedAt: Value(_asDate(data['ended_at']) ?? DateTime.now().toUtc()),
        minutes: Value((data['minutes'] as num?)?.toInt() ?? 0),
        auto: Value(_asBool(data['auto'])),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
  }

  Future<void> _upsertTask(Map<String, Object?> data) async {
    final id = data['id'] as String?;
    if (id == null) return;
    await into(tasks).insertOnConflictUpdate(
      TasksCompanion(
        id: Value(id),
        tenantId: Value(data['tenant_id'] as String? ?? ''),
        branchId: Value(data['branch_id'] as String?),
        orderId: Value(data['order_id'] as String? ?? ''),
        orderItemId: Value(data['order_item_id'] as String?),
        stageKey: Value(data['stage_key'] as String? ?? ''),
        stageName: Value(data['stage_name'] as String? ?? ''),
        sequence: Value((data['sequence'] as num?)?.toInt() ?? 0),
        title: Value(data['title'] as String? ?? ''),
        status: Value(data['status'] as String? ?? 'waiting'),
        assignedTo: Value(data['assigned_to'] as String?),
        requiredRole: Value(data['required_role'] as String? ?? 'operator'),
        qty: Value((data['qty'] as num?)?.toInt() ?? 0),
        priority: Value(data['priority'] as String? ?? 'normal'),
        dueAt: Value(_asDate(data['due_at'])),
        startedAt: Value(_asDate(data['started_at'])),
        doneAt: Value(_asDate(data['done_at'])),
        reason: Value(data['reason'] as String?),
        reworkCount: Value((data['rework_count'] as num?)?.toInt() ?? 0),
        notes: Value(data['notes'] as String?),
        createdAt: Value(_asDate(data['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(_asDate(data['updated_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(data['created_by'] as String?),
        version: Value((data['version'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_asDate(data['deleted_at'])),
      ),
    );
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
    workflowKey: Value(row['workflow_key'] as String? ?? 'print_std'),
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

    if (existing != null) {
      final existingPayload = (jsonDecode(existing.payloadJson) as Map)
          .cast<String, Object?>();

      // A patch that moves a state machine is never coalesced. Merging
      // available -> assigned -> in_progress -> done into one patch would
      // present the server with available -> done, which it correctly rejects
      // as an illegal transition. Each move travels as its own mutation, in
      // order, each with the version the previous one produced.
      final touchesStatus =
          fields.containsKey('status') || existingPayload.containsKey('status');
      final canMerge =
          existing.op == 'insert' || (existing.op == 'patch' && !touchesStatus);

      if (canMerge) {
        final merged = <String, Object?>{...existingPayload, ...fields};
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
            // UUIDv7 ids are monotonic, so this is the tie-breaker that keeps
            // two patches written in the same millisecond in the order they
            // were made — which matters when the second one depends on the
            // version the first produced.
            (t) => OrderingTerm(expression: t.mutationId),
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
    List<Map<String, Object?>> stageRows = const <Map<String, Object?>>[],
  }) async {
    await transaction(() async {
      await delete(products).go();
      await delete(materials).go();
      await delete(priceRules).go();
      if (stageRows.isNotEmpty) {
        await delete(workflowStages).go();
      }

      for (final row in productRows) {
        await into(products).insert(_productFromServer(row));
      }
      for (final row in materialRows) {
        await into(materials).insert(_materialFromServer(row));
      }
      for (final row in ruleRows) {
        await into(priceRules).insert(_ruleFromServer(row));
      }
      for (final row in stageRows) {
        await into(workflowStages).insert(
          WorkflowStagesCompanion.insert(
            id:
                (row['id'] as String?) ??
                '${row['workflow_key']}_${row['stage_key']}',
            tenantId: (row['tenant_id'] as String?) ?? '',
            workflowKey: Value(row['workflow_key'] as String? ?? 'print_std'),
            stageKey: row['stage_key'] as String? ?? '',
            nameEn: row['name_en'] as String? ?? '',
            nameAr: Value(row['name_ar'] as String?),
            sequence: (row['sequence'] as num?)?.toInt() ?? 0,
            requiredRole: row['required_role'] as String? ?? 'operator',
            waitsForPrevious: Value(
              (row['waits_for_previous'] as num?)?.toInt() != 0,
            ),
          ),
        );
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
    String workflowKey = 'print_std',
    String jobTitle = '',
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

      // Quotes do not go into production; an order does, immediately, so the
      // board has work the second the counter confirms.
      if (!isQuote) {
        await createTasksForOrder(
          orderId: orderId,
          tenantId: tenantId,
          branchId: branchId,
          userId: userId,
          workflowKey: workflowKey,
          jobTitle: jobTitle.trim().isEmpty ? numberDisplay : jobTitle.trim(),
          qty: lines.fold<int>(0, (sum, line) => sum + line.quantity),
          dueAt: dueAt,
          priority: priority,
          notes: notes.trim().isEmpty ? null : notes.trim(),
        );
      }
    });

    return orderId;
  }

  // -------------------------------------------------------------------------
  // Production
  // -------------------------------------------------------------------------

  /// Stages for one workflow. Falls back to the built-in list so a device that
  /// has never synced still produces a sane job rather than no tasks at all.
  Future<List<StageTemplate>> stagesFor(String workflowKey) async {
    final rows =
        await (select(workflowStages)
              ..where((t) => t.workflowKey.equals(workflowKey))
              ..orderBy(<OrderClauseGenerator<$WorkflowStagesTable>>[
                (t) => OrderingTerm(expression: t.sequence),
              ]))
            .get();
    if (rows.isEmpty) return defaultStages;
    return <StageTemplate>[
      for (final row in rows)
        StageTemplate(
          key: row.stageKey,
          name: row.nameEn,
          sequence: row.sequence,
          role: row.requiredRole,
          waitsForPrevious: row.waitsForPrevious,
        ),
    ];
  }

  /// Generates one task per stage of the workflow. Stage one is offered to the
  /// pool; the rest wait, so the board shows the future of a job without
  /// pretending it is work somebody can start now.
  Future<void> createTasksForOrder({
    required String orderId,
    required String tenantId,
    required String? branchId,
    required String userId,
    required String workflowKey,
    required String jobTitle,
    required int qty,
    DateTime? dueAt,
    String priority = 'normal',
    String? notes,
  }) async {
    final stages = await stagesFor(workflowKey);
    final now = DateTime.now().toUtc();

    for (var index = 0; index < stages.length; index++) {
      final stage = stages[index];
      final isFirst = index == 0;
      final id = Uuid7.generate();

      await into(tasks).insert(
        TasksCompanion.insert(
          id: id,
          tenantId: tenantId,
          branchId: Value(branchId),
          orderId: orderId,
          stageKey: stage.key,
          stageName: stage.name,
          sequence: stage.sequence,
          title: '$jobTitle - ${stage.name}',
          status: Value(isFirst ? 'available' : 'waiting'),
          requiredRole: stage.role,
          qty: Value(qty),
          priority: Value(priority),
          dueAt: Value(dueAt),
          notes: Value(notes),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await _enqueue(
        entity: 'tasks',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'order_id': orderId,
          'stage_key': stage.key,
          'stage_name': stage.name,
          'sequence': stage.sequence,
          'title': '$jobTitle - ${stage.name}',
          'status': isFirst ? 'available' : 'waiting',
          'required_role': stage.role,
          'qty': qty,
          'priority': priority,
          'due_at': dueAt?.toIso8601String(),
          'notes': notes,
        },
      );
    }
  }

  /// Live tasks for the board: everything still occupying a slot.
  Stream<List<Task>> watchActiveTasks({String? branchId, int limit = 300}) {
    final query = select(tasks)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.status.isNotIn(const <String>['done', 'cancelled']),
      )
      ..orderBy(<OrderClauseGenerator<$TasksTable>>[
        (t) => OrderingTerm(expression: t.sequence),
        (t) => OrderingTerm(expression: t.dueAt),
      ])
      ..limit(limit);
    if (branchId != null) {
      query.where((t) => t.branchId.equals(branchId));
    }
    return query.watch();
  }

  /// "My work": assigned to me, plus whatever my role may pick up from the pool.
  Stream<List<Task>> watchMyTasks({
    required String userId,
    required String role,
  }) {
    return (select(tasks)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                t.status.isNotIn(const <String>['done', 'cancelled']) &
                (t.assignedTo.equals(userId) |
                    (t.assignedTo.isNull() & t.requiredRole.equals(role))),
          )
          ..orderBy(<OrderClauseGenerator<$TasksTable>>[
            (t) => OrderingTerm(expression: t.status),
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.dueAt),
          ]))
        .watch();
  }

  Future<List<Task>> tasksForOrder(String orderId) =>
      (select(tasks)..where((t) => t.orderId.equals(orderId))).get();

  /// Applies a legal transition locally and queues it.
  ///
  /// The same state machine the Worker enforces runs here, so a button that
  /// cannot work is never offered. Timestamps are set locally for an instant
  /// board and overwritten by the server's copy on the next pull, which is the
  /// only clock both devices agree on.
  Future<void> transitionTask({
    required Task task,
    required TaskStatus to,
    required String userId,
    String? reason,
  }) async {
    final from = TaskStatus.fromWire(task.status);
    final transition = TaskStateMachine.transition(from, to);
    if (transition == null) {
      throw StateError('A task cannot move from ${from.wire} to ${to.wire}');
    }
    final cleanReason = reason?.trim();
    if (transition.requiresReason &&
        (cleanReason == null || cleanReason.length < 3)) {
      throw StateError('Explain why before moving this task to ${to.wire}');
    }

    final now = DateTime.now().toUtc();
    final fields = <String, Object?>{'status': to.wire};
    if (cleanReason != null && cleanReason.isNotEmpty) {
      fields['reason'] = cleanReason;
    }

    DateTime? startedAt = task.startedAt;
    DateTime? doneAt = task.doneAt;
    var reworkCount = task.reworkCount;
    String? assignedTo = task.assignedTo;

    switch (to) {
      case TaskStatus.inProgress:
        startedAt ??= now;
        fields['started_at'] = startedAt.toIso8601String();
        assignedTo ??= userId;
      case TaskStatus.done:
        startedAt ??= now;
        doneAt = now;
        fields['started_at'] = startedAt.toIso8601String();
        fields['done_at'] = doneAt.toIso8601String();
      case TaskStatus.rework:
        doneAt = null;
        reworkCount += 1;
        fields['done_at'] = null;
        fields['rework_count'] = reworkCount;
      case TaskStatus.available:
        assignedTo = null;
        fields['assigned_to'] = null;
      default:
        break;
    }
    if (assignedTo != null && fields['assigned_to'] == null) {
      fields['assigned_to'] = assignedTo;
    }

    await transaction(() async {
      await (update(tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          status: Value(to.wire),
          assignedTo: Value(assignedTo),
          startedAt: Value(startedAt),
          doneAt: Value(doneAt),
          reworkCount: Value(reworkCount),
          reason: Value(fields['reason'] as String? ?? task.reason),
          updatedAt: Value(now),
          version: Value(task.version + 1),
        ),
      );

      await _enqueue(
        entity: 'tasks',
        rowId: task.id,
        op: 'patch',
        baseVersion: task.version,
        fields: fields,
      );

      await _cascadeStage(
        orderId: task.orderId,
        sequence: task.sequence,
        toStatus: to.wire,
        userId: userId,
      );
    });
  }

  /// Mirrors `cascadeStage` on the Worker: finishing a stage opens the next.
  Future<void> _cascadeStage({
    required String orderId,
    required int sequence,
    required String toStatus,
    required String userId,
  }) async {
    if (toStatus != 'done' && toStatus != 'rework') return;
    final wanted = toStatus == 'done' ? 'available' : 'waiting';

    final next =
        await (select(tasks)
              ..where(
                (t) =>
                    t.orderId.equals(orderId) &
                    t.sequence.isBiggerThanValue(sequence) &
                    t.deletedAt.isNull() &
                    t.status.isIn(const <String>['waiting', 'available']),
              )
              ..orderBy(<OrderClauseGenerator<$TasksTable>>[
                (t) => OrderingTerm(expression: t.sequence),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (next == null || next.status == wanted) return;

    final now = DateTime.now().toUtc();
    await (update(tasks)..where((t) => t.id.equals(next.id))).write(
      TasksCompanion(
        status: Value(wanted),
        updatedAt: Value(now),
        version: Value(next.version + 1),
      ),
    );
    await _enqueue(
      entity: 'tasks',
      rowId: next.id,
      op: 'patch',
      baseVersion: next.version,
      fields: <String, Object?>{'status': wanted},
    );
  }

  // -------------------------------------------------------------------------
  // Proofs and time
  // -------------------------------------------------------------------------

  /// Legal proof moves, mirroring PROOF_TRANSITIONS in src/proofs.ts.
  static const Map<String, List<String>> _proofMoves = <String, List<String>>{
    'draft': <String>['sent', 'superseded'],
    'sent': <String>['approved', 'rejected', 'superseded'],
    'approved': <String>['superseded'],
    'rejected': <String>['superseded'],
    'superseded': <String>[],
  };

  Stream<List<Proof>> watchProofs(String orderId) {
    return (select(proofs)
          ..where((t) => t.orderId.equals(orderId) & t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$ProofsTable>>[
            (t) => OrderingTerm(expression: t.revision),
          ]))
        .watch();
  }

  /// Proofs the customer has but has not answered yet — the queue someone has
  /// to chase, and the one thing that silently stalls a job.
  Stream<List<Proof>> watchProofsAwaitingDecision() {
    return (select(proofs)
          ..where((t) => t.status.equals('sent') & t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$ProofsTable>>[
            (t) => OrderingTerm(expression: t.updatedAt),
          ]))
        .watch();
  }

  /// Adds the next version of the proof for an order. The link is the proof —
  /// the file stays wherever the shop already keeps it.
  Future<String> addProofLocal({
    required String orderId,
    required String tenantId,
    required String? branchId,
    required String userId,
    required String label,
    required String url,
    String kind = 'proof',
    String? note,
  }) async {
    final existing = await (select(
      proofs,
    )..where((t) => t.orderId.equals(orderId))).get();
    final revision =
        existing.fold<int>(
          0,
          (highest, proof) =>
              proof.revision > highest ? proof.revision : highest,
        ) +
        1;

    final id = Uuid7.generate();
    final now = DateTime.now().toUtc();

    await transaction(() async {
      await into(proofs).insert(
        ProofsCompanion.insert(
          id: id,
          tenantId: tenantId,
          branchId: Value(branchId),
          orderId: orderId,
          revision: Value(revision),
          kind: Value(kind),
          label: label,
          url: url,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await _enqueue(
        entity: 'proofs',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'order_id': orderId,
          'revision': revision,
          'kind': kind,
          'label': label,
          'url': url,
          'note': note,
          'status': 'draft',
        },
      );
    });

    return id;
  }

  /// Moves a proof along its own small state machine. Same rules as the
  /// server: nothing is approved before it was sent, and a rejection carries
  /// the reason the designer needs.
  Future<void> setProofStatus({
    required Proof proof,
    required String status,
    required String userId,
    String? note,
  }) async {
    final allowed = _proofMoves[proof.status] ?? const <String>[];
    if (!allowed.contains(status)) {
      throw StateError('A proof cannot move from ${proof.status} to $status');
    }
    final cleanNote = note?.trim();
    if (status == 'rejected' && (cleanNote == null || cleanNote.length < 3)) {
      throw StateError('Write what the customer asked to change');
    }

    final now = DateTime.now().toUtc();
    final fields = <String, Object?>{'status': status};
    if (status == 'sent') fields['sent_at'] = now.toIso8601String();
    if (status == 'approved' || status == 'rejected') {
      fields['decided_at'] = now.toIso8601String();
      if (cleanNote != null && cleanNote.isNotEmpty) {
        fields['decided_note'] = cleanNote;
      }
    }

    await transaction(() async {
      await (update(proofs)..where((t) => t.id.equals(proof.id))).write(
        ProofsCompanion(
          status: Value(status),
          sentAt: Value(status == 'sent' ? now : proof.sentAt),
          decidedAt: Value(
            status == 'approved' || status == 'rejected'
                ? now
                : proof.decidedAt,
          ),
          decidedNote: Value(
            cleanNote == null || cleanNote.isEmpty
                ? proof.decidedNote
                : cleanNote,
          ),
          updatedAt: Value(now),
          version: Value(proof.version + 1),
        ),
      );

      await _enqueue(
        entity: 'proofs',
        rowId: proof.id,
        op: 'patch',
        baseVersion: proof.version,
        fields: fields,
      );
    });
  }

  /// Minutes recorded against a task, straight from the server's entries.
  Future<int> minutesForTask(String taskId) async {
    final rows = await (select(
      timeEntries,
    )..where((t) => t.taskId.equals(taskId))).get();
    return rows.fold<int>(0, (sum, entry) => sum + entry.minutes);
  }

  Future<int> minutesForOrder(String orderId) async {
    final rows = await (select(
      timeEntries,
    )..where((t) => t.orderId.equals(orderId))).get();
    return rows.fold<int>(0, (sum, entry) => sum + entry.minutes);
  }

  // -------------------------------------------------------------------------
  // Money
  // -------------------------------------------------------------------------

  /// The live invoice for an order (a void one does not count).
  Stream<Invoice?> watchInvoiceForOrder(String orderId) {
    return (select(invoices)..where(
          (t) =>
              t.orderId.equals(orderId) &
              t.deletedAt.isNull() &
              t.status.isNotValue('void'),
        ))
        .watchSingleOrNull();
  }

  Future<Invoice?> invoiceForOrder(String orderId) {
    return (select(invoices)..where(
          (t) =>
              t.orderId.equals(orderId) &
              t.deletedAt.isNull() &
              t.status.isNotValue('void'),
        ))
        .getSingleOrNull();
  }

  Future<List<InvoiceLine>> linesFor(String invoiceId) {
    return (select(invoiceLines)
          ..where((t) => t.invoiceId.equals(invoiceId) & t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$InvoiceLinesTable>>[
            (t) => OrderingTerm(expression: t.lineNo),
          ]))
        .get();
  }

  Stream<List<Payment>> watchPayments(String invoiceId) {
    return (select(payments)
          ..where((t) => t.invoiceId.equals(invoiceId) & t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$PaymentsTable>>[
            (t) => OrderingTerm(expression: t.takenAt),
          ]))
        .watch();
  }

  /// Issues the invoice for an order, snapshotting every number that will be
  /// printed. Refuses a second one: a duplicate invoice is a tax problem, not a
  /// UI annoyance, and the server would refuse it anyway.
  Future<String> issueInvoiceLocal({
    required Order order,
    required String tenantId,
    required String? branchId,
    required String userId,
    required String number,
    DateTime? dueAt,
    String? customerTrn,
    String? customerAddress,
    String? notes,
  }) async {
    final existing = await invoiceForOrder(order.id);
    if (existing != null) {
      throw StateError(
        'Order ${order.numberDisplay} already has invoice ${existing.number}.',
      );
    }

    final items = await itemsFor(order.id);
    final vatRate = await vatBps();
    final id = Uuid7.generate();
    final now = DateTime.now().toUtc();

    await transaction(() async {
      await into(invoices).insert(
        InvoicesCompanion.insert(
          id: id,
          tenantId: tenantId,
          branchId: Value(branchId),
          orderId: order.id,
          number: number,
          issuedAt: now,
          dueAt: Value(dueAt),
          customerId: order.customerId,
          customerName: order.customerName ?? 'Customer',
          customerTrn: Value(customerTrn),
          customerAddress: Value(customerAddress),
          subtotalFils: order.subtotalFils,
          vatBps: Value(vatRate),
          vatFils: order.vatFils,
          totalFils: order.totalFils,
          notes: Value(notes),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await _enqueue(
        entity: 'invoices',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'order_id': order.id,
          'number': number,
          'issued_at': now.toIso8601String(),
          'due_at': dueAt?.toIso8601String(),
          'customer_id': order.customerId,
          'customer_name': order.customerName ?? 'Customer',
          'customer_trn': customerTrn,
          'customer_address': customerAddress,
          'subtotal_fils': order.subtotalFils,
          'discount_fils': 0,
          'vat_bps': vatRate,
          'vat_fils': order.vatFils,
          'total_fils': order.totalFils,
          'notes': notes,
          'status': 'issued',
        },
      );

      var lineNo = 0;
      for (final item in items) {
        lineNo += 1;
        final lineId = Uuid7.generate();
        final unit = item.quantity <= 0
            ? item.subtotalFils
            : (item.subtotalFils / item.quantity).round();

        await into(invoiceLines).insert(
          InvoiceLinesCompanion.insert(
            id: lineId,
            tenantId: tenantId,
            invoiceId: id,
            lineNo: lineNo,
            description: item.description,
            quantity: item.quantity,
            unitFils: unit,
            amountFils: item.subtotalFils,
            vatBps: Value(vatRate),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await _enqueue(
          entity: 'invoice_lines',
          rowId: lineId,
          op: 'insert',
          baseVersion: 0,
          fields: <String, Object?>{
            'invoice_id': id,
            'line_no': lineNo,
            'description': item.description,
            'quantity': item.quantity,
            'unit_fils': unit,
            'amount_fils': item.subtotalFils,
            'vat_bps': vatRate,
          },
        );
      }
    });

    return id;
  }

  /// Takes money against an invoice. Only the payment is queued: `paid_fils` and
  /// the paid/part-paid status are the server's to compute, so a device cannot
  /// declare an invoice settled.
  Future<void> takePaymentLocal({
    required Invoice invoice,
    required int amountFils,
    required String method,
    required String userId,
    String? reference,
  }) async {
    const methods = <String>['cash', 'card', 'transfer', 'cheque'];
    if (!methods.contains(method)) {
      throw StateError('Unknown payment method: $method');
    }
    if (amountFils <= 0) {
      throw StateError('A payment must be more than zero.');
    }
    final outstanding = invoice.totalFils - invoice.paidFils;
    if (amountFils > outstanding) {
      throw StateError(
        'Only ${(outstanding / 100).toStringAsFixed(2)} AED is outstanding.',
      );
    }

    final paidAfter = invoice.paidFils + amountFils;
    final status = paidAfter >= invoice.totalFils
        ? 'paid'
        : (paidAfter > 0 ? 'part_paid' : 'issued');
    final id = Uuid7.generate();
    final now = DateTime.now().toUtc();

    await transaction(() async {
      await into(payments).insert(
        PaymentsCompanion.insert(
          id: id,
          tenantId: invoice.tenantId,
          branchId: Value(invoice.branchId),
          invoiceId: invoice.id,
          amountFils: amountFils,
          method: method,
          reference: Value(reference),
          takenAt: now,
          takenBy: Value(userId),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await (update(invoices)..where((t) => t.id.equals(invoice.id))).write(
        InvoicesCompanion(
          paidFils: Value(paidAfter),
          status: Value(status),
          updatedAt: Value(now),
        ),
      );

      await _enqueue(
        entity: 'payments',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'invoice_id': invoice.id,
          'amount_fils': amountFils,
          'method': method,
          'reference': reference,
          'taken_at': now.toIso8601String(),
          'taken_by': userId,
        },
      );
    });
  }

  Stream<List<CreditNote>> watchCreditNotes(String invoiceId) {
    return (select(creditNotes)
          ..where((t) => t.invoiceId.equals(invoiceId) & t.deletedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$CreditNotesTable>>[
            (t) => OrderingTerm(expression: t.issuedAt),
          ]))
        .watch();
  }

  /// Issues a credit note and mirrors the credit onto the invoice. The VAT is
  /// split back out of the gross at the invoice's own rate, so a credited
  /// invoice and its notes always add up.
  Future<String> issueCreditNoteLocal({
    required Invoice invoice,
    required String tenantId,
    required String? branchId,
    required String userId,
    required String number,
    required int amountFils,
    required String reason,
  }) async {
    if (amountFils <= 0) {
      throw StateError('A credit note must be more than zero.');
    }
    if (reason.trim().length < 3) {
      throw StateError('Say why the credit note is being issued.');
    }
    final creditable = invoice.totalFils - invoice.creditedFils;
    if (amountFils > creditable) {
      throw StateError(
        'Only ${(creditable / 100).toStringAsFixed(2)} AED can still be credited.',
      );
    }

    final id = Uuid7.generate();
    final now = DateTime.now().toUtc();
    final subtotal = (amountFils * 10000 / (10000 + invoice.vatBps)).round();
    final vat = amountFils - subtotal;

    await transaction(() async {
      await into(creditNotes).insert(
        CreditNotesCompanion.insert(
          id: id,
          tenantId: tenantId,
          branchId: Value(branchId),
          invoiceId: invoice.id,
          number: number,
          issuedAt: now,
          reason: reason.trim(),
          subtotalFils: subtotal,
          vatBps: Value(invoice.vatBps),
          vatFils: vat,
          totalFils: amountFils,
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await (update(invoices)..where((t) => t.id.equals(invoice.id))).write(
        InvoicesCompanion(
          creditedFils: Value(invoice.creditedFils + amountFils),
          updatedAt: Value(now),
        ),
      );

      await _enqueue(
        entity: 'credit_notes',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'invoice_id': invoice.id,
          'number': number,
          'issued_at': now.toIso8601String(),
          'reason': reason.trim(),
          'subtotal_fils': subtotal,
          'vat_bps': invoice.vatBps,
          'vat_fils': vat,
          'total_fils': amountFils,
        },
      );
    });

    return id;
  }

  Stream<List<Refund>> watchRefunds(String creditNoteId) {
    return (select(refunds)
          ..where(
            (t) => t.creditNoteId.equals(creditNoteId) & t.deletedAt.isNull(),
          )
          ..orderBy(<OrderClauseGenerator<$RefundsTable>>[
            (t) => OrderingTerm(expression: t.refundedAt),
          ]))
        .watch();
  }

  /// Cash back to the customer against a credit note. Managers only, and never
  /// more than the note still has left.
  Future<void> refundLocal({
    required CreditNote note,
    required int amountFils,
    required String method,
    required String userId,
    String? reference,
  }) async {
    const methods = <String>['cash', 'card', 'transfer', 'cheque'];
    if (!methods.contains(method)) {
      throw StateError('Unknown refund method: $method');
    }
    if (amountFils <= 0) {
      throw StateError('A refund must be more than zero.');
    }
    final refundable = note.totalFils - note.refundedFils;
    if (amountFils > refundable) {
      throw StateError(
        'Only ${(refundable / 100).toStringAsFixed(2)} AED is left to refund.',
      );
    }

    final id = Uuid7.generate();
    final now = DateTime.now().toUtc();

    await transaction(() async {
      await into(refunds).insert(
        RefundsCompanion.insert(
          id: id,
          tenantId: note.tenantId,
          branchId: Value(note.branchId),
          creditNoteId: note.id,
          invoiceId: note.invoiceId,
          amountFils: amountFils,
          method: method,
          reference: Value(reference),
          refundedAt: now,
          refundedBy: Value(userId),
          createdAt: now,
          updatedAt: now,
          createdBy: Value(userId),
        ),
      );

      await (update(creditNotes)..where((t) => t.id.equals(note.id))).write(
        CreditNotesCompanion(
          refundedFils: Value(note.refundedFils + amountFils),
          updatedAt: Value(now),
        ),
      );

      await _enqueue(
        entity: 'refunds',
        rowId: id,
        op: 'insert',
        baseVersion: 0,
        fields: <String, Object?>{
          'credit_note_id': note.id,
          'invoice_id': note.invoiceId,
          'amount_fils': amountFils,
          'method': method,
          'reference': reference,
          'refunded_at': now.toIso8601String(),
          'refunded_by': userId,
        },
      );
    });
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

      // A converted quote becomes real work, with the same stages an order
      // placed at the counter would get.
      final firstProduct = items.isEmpty
          ? null
          : await (select(products)
                  ..where((p) => p.id.equals(items.first.productId)))
                .getSingleOrNull();
      await createTasksForOrder(
        orderId: orderId,
        tenantId: quote.tenantId,
        branchId: quote.branchId,
        userId: userId,
        workflowKey: firstProduct?.workflowKey ?? 'print_std',
        jobTitle: '${quote.customerName ?? 'Job'} $numberDisplay',
        qty: items.fold<int>(0, (sum, item) => sum + item.quantity),
        dueAt: quote.dueAt,
        priority: quote.priority,
        notes: quote.notes,
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

/// A stage definition as the app uses it: from the catalogue when it has one,
/// from [defaultStages] when the device has never synced a workflow.
class StageTemplate {
  const StageTemplate({
    required this.key,
    required this.name,
    required this.sequence,
    required this.role,
    this.waitsForPrevious = true,
  });

  final String key;
  final String name;
  final int sequence;
  final String role;
  final bool waitsForPrevious;
}

/// Mirrors DEFAULT_WORKFLOW in backend/worker/src/catalogue.ts and the rows in
/// seeds/catalogue.sql. Server and device must agree, because the device
/// generates tasks while offline and the server validates their transitions.
const List<StageTemplate> defaultStages = <StageTemplate>[
  StageTemplate(key: 'design', name: 'Design', sequence: 10, role: 'designer'),
  StageTemplate(key: 'print', name: 'Print', sequence: 20, role: 'operator'),
  StageTemplate(
    key: 'finish',
    name: 'Finishing',
    sequence: 30,
    role: 'operator',
  ),
  StageTemplate(
    key: 'qc',
    name: 'Quality check',
    sequence: 40,
    role: 'manager',
  ),
  StageTemplate(
    key: 'delivery',
    name: 'Delivery',
    sequence: 50,
    role: 'driver',
  ),
];
