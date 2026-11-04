import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';
import 'package:test/test.dart';

/// A fake server that can fail on purpose, so the interesting cases — a batch
/// that never arrives, a mutation the server refuses — are testable.
class FakeApi implements SyncApi {
  FakeApi();

  final List<List<OutboxMutation>> pushedBatches = <List<OutboxMutation>>[];
  List<OutboxMutation>? pendingServerRows;
  bool failNextPush = false;
  bool failEverything = false;
  String? rejectNextWith;

  int headValue = 0;
  int pullCursor = 0;
  final List<PullRow> serverRows = <PullRow>[];

  /// When set, the next mutation is refused as a stale write and the server's
  /// current row is handed back — exactly what D1 does on a version mismatch.
  Map<String, Object?>? conflictWithRow;

  @override
  Future<HeadResult> head() async {
    if (failEverything) {
      throw const SyncException('OFFLINE', 'No network');
    }
    return HeadResult(
      head: headValue,
      permissionVersion: 1,
      minAppVersion: '0.1.0',
    );
  }

  @override
  Future<PushResult> push({required List<OutboxMutation> mutations}) async {
    if (failEverything || failNextPush) {
      failNextPush = false;
      throw const SyncException('OFFLINE', 'No network');
    }
    pushedBatches.add(mutations);

    final outcomes = <MutationOutcome>[];
    for (final mutation in mutations) {
      headValue += 1;
      if (rejectNextWith != null) {
        outcomes.add(
          MutationOutcome(
            mutationId: mutation.mutationId,
            status: 'rejected',
            errorCode: rejectNextWith,
            errorMessage: 'refused',
          ),
        );
        rejectNextWith = null;
        continue;
      }
      if (conflictWithRow != null) {
        outcomes.add(
          MutationOutcome(
            mutationId: mutation.mutationId,
            status: 'rejected',
            errorCode: 'VERSION_CONFLICT',
            errorMessage: 'This record changed on another device.',
            row: conflictWithRow,
          ),
        );
        conflictWithRow = null;
        continue;
      }
      outcomes.add(
        MutationOutcome(
          mutationId: mutation.mutationId,
          status: 'applied',
          serverVersion: 1,
          row: <String, Object?>{
            'id': mutation.rowId,
            'tenant_id': 't1',
            'branch_id': 'b1',
            'name': 'Ahmed Traders',
            'version': 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        ),
      );
    }
    return PushResult(head: headValue, outcomes: outcomes);
  }

  int _nextNumber = 1;
  bool failLeases = false;

  @override
  Future<NumberRange> leaseNumbers({
    required String series,
    int size = 100,
  }) async {
    if (failEverything || failLeases) {
      throw const SyncException('OFFLINE', 'No network');
    }
    final start = _nextNumber;
    _nextNumber += size;
    return NumberRange(start: start, end: start + size - 1);
  }

  @override
  Future<PullResult> pull({required int since, int limit = 200}) async {
    if (failEverything) {
      throw const SyncException('OFFLINE', 'No network');
    }
    final rows = serverRows
        .where((row) => row.seq > since)
        .take(limit)
        .toList();
    final cursor = rows.isEmpty ? since : rows.last.seq;
    return PullResult(rows: rows, nextCursor: cursor, head: headValue);
  }
}

PullRow row(int seq, String name) => PullRow(
  seq: seq,
  entity: 'customers',
  rowId: 'c-$seq',
  op: 'insert',
  version: 1,
  data: <String, Object?>{
    'id': 'c-$seq',
    'tenant_id': 't1',
    'branch_id': 'b1',
    'name': name,
    'version': 1,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  },
);

void main() {
  late LocalDatabase db;
  late FakeApi api;
  late SyncEngine engine;

  setUp(() {
    db = LocalDatabase(NativeDatabase.memory());
    api = FakeApi();
    engine = SyncEngine(db: db, api: api);
  });

  tearDown(() async {
    await engine.dispose();
    await db.close();
  });

  group('local writes', () {
    test('create writes the row and queues exactly one insert', () async {
      final id = await db.createCustomerLocal(
        tenantId: 't1',
        branchId: 'b1',
        name: 'Ahmed Traders',
        company: 'Ahmed Traders LLC',
        phoneE164: '0501234567',
        userId: 'u1',
      );

      final customer = await db.customerById(id);
      expect(customer, isNotNull);
      expect(customer!.name, 'Ahmed Traders');
      expect(customer.version, 0, reason: 'the server has not seen it yet');

      final batch = await db.nextBatch();
      expect(batch, hasLength(2), reason: 'customer plus its phone number');
      expect(batch.first.op, 'insert');
      expect(batch.first.payloadJson, contains('Ahmed Traders'));
    });

    test('two edits to the same row coalesce into one mutation', () async {
      final id = await db.createCustomerLocal(
        tenantId: 't1',
        branchId: 'b1',
        name: 'Ahmed',
        userId: 'u1',
      );
      await db.updateCustomerLocal(
        id: id,
        fields: <String, Object?>{'notes': 'called'},
      );
      await db.updateCustomerLocal(
        id: id,
        fields: <String, Object?>{'notes': 'called twice'},
      );

      final batch = await db.nextBatch();
      final customerMutations = batch
          .where((mutation) => mutation.rowId == id)
          .toList();
      expect(
        customerMutations,
        hasLength(1),
        reason: 'typing must not queue one API call per keystroke',
      );
      expect(customerMutations.single.op, 'insert');
      expect(customerMutations.single.payloadJson, contains('called twice'));
    });

    test('pending count drops to zero as mutations leave the outbox', () async {
      await db.createCustomerLocal(
        tenantId: 't1',
        branchId: 'b1',
        name: 'Ahmed',
        userId: 'u1',
      );
      expect(await db.pendingCount(), 1);

      await engine.syncNow();
      expect(await db.pendingCount(), 0);
    });
  });

  group('push', () {
    test('sends the queued mutations and adopts the server version', () async {
      final id = await db.createCustomerLocal(
        tenantId: 't1',
        branchId: 'b1',
        name: 'Ahmed Traders',
        userId: 'u1',
      );

      await engine.syncNow();

      expect(api.pushedBatches, hasLength(1));
      final customer = await db.customerById(id);
      expect(
        customer!.version,
        1,
        reason: 'server version replaces the local 0',
      );
      expect(await db.pendingCount(), 0);
    });

    test(
      'a dropped connection keeps every mutation and reports offline',
      () async {
        await db.createCustomerLocal(
          tenantId: 't1',
          branchId: 'b1',
          name: 'Ahmed Traders',
          userId: 'u1',
        );
        api.failNextPush = true;

        await engine.syncNow();

        expect(await db.pendingCount(), 1, reason: 'work is never discarded');
        expect(engine.current.phase, SyncPhase.offline);
        expect(engine.current.message, contains('No network'));
      },
    );

    test('a rejected mutation stays queued with its reason', () async {
      await db.createCustomerLocal(
        tenantId: 't1',
        branchId: 'b1',
        name: 'Ahmed Traders',
        userId: 'u1',
      );
      api.rejectNextWith = 'PERMISSION_DENIED';

      await engine.syncNow();

      final batch = await db.nextBatch();
      expect(batch, hasLength(1));
      expect(batch.single.lastError, contains('PERMISSION_DENIED'));
      expect(engine.current.phase, SyncPhase.attention);
    });
  });

  group('pull', () {
    test('applies server rows and advances the cursor', () async {
      api.serverRows.addAll(<PullRow>[row(1, 'First'), row(2, 'Second')]);

      await engine.syncNow();

      final customers = await db.watchCustomers().first;
      expect(
        customers.map((c) => c.name),
        containsAll(<String>['First', 'Second']),
      );
      expect(await db.cursor(), 2);

      // A second run must not duplicate anything.
      await engine.syncNow();
      expect(await db.watchCustomers().first, hasLength(2));
    });

    test('a tombstone hides the row without deleting it', () async {
      api.serverRows.add(row(1, 'Deleted Customer'));
      await engine.syncNow();
      expect(await db.watchCustomers().first, hasLength(1));

      api.serverRows.add(
        PullRow(
          seq: 2,
          entity: 'customers',
          rowId: 'c-1',
          op: 'delete',
          version: 2,
          data: <String, Object?>{
            'id': 'c-1',
            'tenant_id': 't1',
            'name': 'Deleted Customer',
            'version': 2,
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          },
        ),
      );
      await engine.syncNow();

      expect(await db.watchCustomers().first, isEmpty);
      final raw = await db.customerById('c-1');
      expect(
        raw,
        isNotNull,
        reason: 'soft delete, so the deletion can sync onwards',
      );
    });

    test(
      'search finds a customer by the last digits of a phone number',
      () async {
        api.serverRows.add(row(1, 'Ahmed Traders'));
        await engine.syncNow();

        await db
            .into(db.customerPhones)
            .insert(
              CustomerPhonesCompanion.insert(
                id: 'p1',
                tenantId: 't1',
                customerId: 'c-1',
                e164: '+971501234567',
                phoneLast9: '501234567',
                isPrimary: const Value(true),
              ),
            );

        final matches = await db.searchCustomers('501234567').first;
        expect(matches, hasLength(1));
        expect(matches.single.name, 'Ahmed Traders');
      },
    );
  });

  group('number series', () {
    test('leases a block and spends it in order', () async {
      final series = NumberSeries(
        db: db,
        api: api,
        kind: NumberKind.job,
        branchCode: 'SHJ1',
        deviceCode: 'PC1',
        blockSize: 100,
      );
      final first = await series.next();
      final second = await series.next();
      expect(first.display, 'JOB-SHJ1-PC1-00001');
      expect(second.display, 'JOB-SHJ1-PC1-00002');
      expect(await series.remaining(), 98);
    });

    test(
      'falls back to a temporary number when there is no connection',
      () async {
        api.failLeases = true;
        final series = NumberSeries(
          db: db,
          api: api,
          kind: NumberKind.job,
          branchCode: 'SHJ1',
          deviceCode: 'PC1',
        );
        final issued = await series.next();
        expect(issued.isTemporary, isTrue);
        expect(issued.number, isNull);
        expect(issued.display, 'JOB-T-0001');
      },
    );

    test('prints the prefix Settings has saved, not a constant', () async {
      // What the device receives from `GET /v1/settings` after the owner typed
      // BILL into the invoice prefix field. The numbering code must use it —
      // that is the bug the settings screen could not fix on its own.
      final prefixes = NumberPrefixes.fromSettingsJson(<String, Object?>{
        'numbers': <String, Object?>{
          'invoice_prefix': 'BILL',
          'quote_prefix': 'QUO',
          'order_prefix': 'ORD',
        },
      });

      final invoice = NumberSeries(
        db: db,
        api: api,
        kind: NumberKind.invoice,
        branchCode: 'SHJ1',
        deviceCode: 'PC1',
        prefixes: prefixes,
      );

      // The leased series key carries the prefix too, so the server counts the
      // numbers under the name the customer reads.
      expect(invoice.series, 'BILL-SHJ1-PC1');
      expect((await invoice.next()).display, 'BILL-SHJ1-PC1-00001');

      // The same payload renames the other series independently.
      final job = NumberSeries(
        db: db,
        api: api,
        kind: NumberKind.job,
        branchCode: 'SHJ1',
        deviceCode: 'PC1',
        prefixes: prefixes,
      );
      expect(job.series, 'ORD-SHJ1-PC1');
    });

    test('a blank or missing payload falls back to the worker defaults', () {
      final prefixes = NumberPrefixes.fromSettingsJson(<String, Object?>{
        'numbers': <String, Object?>{'invoice_prefix': '  '},
      });
      expect(prefixes.invoice, 'INV', reason: 'a blank prefix is not a prefix');
      expect(prefixes.quote, 'QT');
      expect(prefixes.job, 'JOB');
    });
  });

  group('catalogue', () {
    test(
      'replaces the price book atomically and exposes product rules',
      () async {
        await db.replaceCatalogue(
          productRows: <Map<String, Object?>>[
            <String, Object?>{
              'id': 'prod_cards',
              'tenant_id': 't1',
              'code': 'business_cards',
              'name_en': 'Business cards',
              'kind': 'sheet',
              'pricing_mode': 'cost_plus',
              'sheet_width_mm': 320,
              'sheet_height_mm': 450,
              'material_code': 'art_card_350',
              'print_rate_fils': 35,
              'markup_bps': 6500,
              'sizes_json': '[]',
              'finishes_json': '[]',
              'quantity_presets_json': '[100,500]',
              'active': 1,
            },
          ],
          materialRows: <Map<String, Object?>>[
            <String, Object?>{
              'id': 'mat1',
              'tenant_id': 't1',
              'code': 'art_card_350',
              'name': 'Art card 350',
              'cost_per_sheet_fils': 60,
              'active': 1,
            },
          ],
          ruleRows: <Map<String, Object?>>[
            <String, Object?>{
              'id': 'rule1',
              'tenant_id': 't1',
              'price_book_version': 1,
              'label': 'Cutting',
              'phase': 'finishing',
              'basis': 'flat',
              'rate_fils': 500,
              'priority': 60,
              'when_json': '[]',
              'active': 1,
            },
          ],
          priceBookVersion: 1,
          vatBps: 500,
        );

        final products = await db.watchProducts().first;
        expect(products, hasLength(1));
        expect(await db.materialByCode('art_card_350'), isNotNull);
        expect(await db.rulesForProduct('prod_cards', 1), hasLength(1));
        expect(await db.vatBps(), 500);
      },
    );
  });

  group('orders', () {
    test('writes the order, its lines and the outbox in one go', () async {
      final orderId = await db.createOrderLocal(
        tenantId: 't1',
        branchId: 'b1',
        customerId: 'c1',
        customerName: 'Ahmed Traders',
        userId: 'u1',
        numberDisplay: '10452',
        number: 10452,
        lines: <OrderLineDraft>[
          const OrderLineDraft(
            productId: 'prod_cards',
            description: 'Business cards · 500 · 90×55 mm · matt lamination',
            optionsJson: '{"quantity":500}',
            quantity: 500,
            priceBookVersion: 7,
            breakdownJson:
                '{"total_fils":12200,"vat_fils":610,"grand_total_fils":12810}',
            subtotalFils: 12200,
            vatFils: 610,
            totalFils: 12810,
          ),
        ],
      );

      final order = await db.orderById(orderId);
      expect(order, isNotNull);
      expect(order!.totalFils, 12810);
      expect(order.numberDisplay, '10452');
      expect(order.itemCount, 1);

      final items = await db.itemsFor(orderId);
      expect(items, hasLength(1));
      expect(items.single.breakdownJson, contains('grand_total_fils'));

      final batch = await db.nextBatch();
      expect(
        batch.map((mutation) => mutation.entity),
        containsAll(<String>['orders', 'order_items']),
      );
    });
  });

  group('quick sales', () {
    test('writes the sale, its lines and the outbox in one go', () async {
      final saleId = await db.createQuickSaleLocal(
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        number: 1,
        numberDisplay: 'QS-SHJ1-PC1-00001',
        customerId: null,
        customerName: 'Walk-in',
        paymentMethod: 'cash',
        subtotalFils: 1000,
        vatFils: 50,
        totalFils: 1050,
        paidFils: 1050,
        lines: const <QuickSaleLineDraft>[
          QuickSaleLineDraft(
            productId: null,
            description: 'Black & white copies',
            quantity: 10,
            unitFils: 100,
            amountFils: 1000,
          ),
        ],
      );

      final sale = await (db.select(db.quickSales)
            ..where((t) => t.id.equals(saleId)))
          .getSingle();
      expect(sale.numberDisplay, 'QS-SHJ1-PC1-00001');
      expect(sale.totalFils, 1050);
      expect(sale.paidFils, 1050);

      final lines = await (db.select(db.quickSaleLines)
            ..where((t) => t.quickSaleId.equals(saleId)))
          .get();
      expect(lines, hasLength(1));
      expect(lines.single.amountFils, 1000);

      final batch = await db.nextBatch();
      final entities = batch.map((mutation) => mutation.entity).toList();
      expect(entities, containsAll(<String>['quick_sales', 'quick_sale_lines']));
      // The parent travels before its lines, so the server sees the sale exist
      // before the line that points at it.
      expect(entities.indexOf('quick_sales'), lessThan(entities.indexOf('quick_sale_lines')));
    });
  });

  group('quotes', () {
    test(
      'converting a quote copies the frozen lines and marks it converted',
      () async {
        const breakdown =
            '{"total_fils":12200,"vat_fils":610,"grand_total_fils":12810}';
        final quoteId = await db.createOrderLocal(
          tenantId: 't1',
          branchId: 'b1',
          customerId: 'c1',
          customerName: 'Ahmed Traders',
          userId: 'u1',
          numberDisplay: 'QT-00001',
          number: 1,
          isQuote: true,
          status: 'draft',
          lines: const <OrderLineDraft>[
            OrderLineDraft(
              productId: 'prod_cards',
              description: 'Business cards | 500 | 90x55 | matt',
              optionsJson: '{"quantity":500}',
              quantity: 500,
              priceBookVersion: 7,
              breakdownJson: breakdown,
              subtotalFils: 12200,
              vatFils: 610,
              totalFils: 12810,
            ),
          ],
        );

        final orderId = await db.convertQuoteToOrder(
          quoteId: quoteId,
          numberDisplay: '10452',
          number: 10452,
          userId: 'u1',
        );

        final order = await db.orderById(orderId);
        expect(order, isNotNull);
        expect(order!.isQuote, isFalse);
        expect(order.numberDisplay, '10452');
        expect(order.totalFils, 12810);

        final quote = await db.orderById(quoteId);
        expect(quote!.status, 'converted');

        final convertedItems = await db.itemsFor(orderId);
        expect(convertedItems, hasLength(1));
        expect(convertedItems.single.breakdownJson, breakdown);
      },
    );
  });

  group('production', () {
    Future<String> placedOrder() => db.createOrderLocal(
      tenantId: 't1',
      branchId: 'b1',
      customerId: 'c1',
      customerName: 'Ahmed Traders',
      userId: 'u1',
      numberDisplay: '10452',
      number: 10452,
      jobTitle: '10452 - Ahmed Traders',
      lines: const <OrderLineDraft>[
        OrderLineDraft(
          productId: 'prod_cards',
          description: 'Business cards - 500',
          optionsJson: '{"quantity":500}',
          quantity: 500,
          priceBookVersion: 7,
          breakdownJson: '{"total_fils":12200}',
          subtotalFils: 12200,
          vatFils: 610,
          totalFils: 12810,
        ),
      ],
    );

    test(
      'an order opens one task per stage; only the first is offered',
      () async {
        final orderId = await placedOrder();
        final tasks = await db.tasksForOrder(orderId);

        expect(tasks, hasLength(5));
        expect(tasks.map((task) => task.stageKey).toList(), <String>[
          'design',
          'print',
          'finish',
          'qc',
          'delivery',
        ]);
        expect(tasks.map((task) => task.sequence).toList(), <int>[
          10,
          20,
          30,
          40,
          50,
        ]);
        expect(tasks.first.status, 'available');
        expect(
          tasks.skip(1).every((task) => task.status == 'waiting'),
          isTrue,
          reason: 'later stages must not pretend to be startable',
        );
        expect(tasks.first.requiredRole, 'designer');
      },
    );

    test('finishing a stage opens the next one locally', () async {
      final orderId = await placedOrder();
      var design = (await db.tasksForOrder(orderId)).first;

      await db.transitionTask(
        task: design,
        to: TaskStatus.assigned,
        userId: 'u1',
      );
      design = (await db.tasksForOrder(orderId)).first;
      expect(design.status, 'assigned');

      await db.transitionTask(
        task: design,
        to: TaskStatus.inProgress,
        userId: 'u1',
      );
      design = (await db.tasksForOrder(orderId)).first;
      expect(design.startedAt, isNotNull);

      await db.transitionTask(task: design, to: TaskStatus.done, userId: 'u1');

      final after = await db.tasksForOrder(orderId);
      expect(after.first.status, 'done');
      expect(after.first.doneAt, isNotNull);
      expect(
        after[1].status,
        'available',
        reason: 'print opens when design is done',
      );
      expect(after[2].status, 'waiting');
    });

    test('an illegal jump is refused before it reaches the outbox', () async {
      final orderId = await placedOrder();
      final tasks = await db.tasksForOrder(orderId);

      await expectLater(
        db.transitionTask(task: tasks[3], to: TaskStatus.done, userId: 'u1'),
        throwsA(isA<StateError>()),
      );
      expect((await db.tasksForOrder(orderId))[3].status, 'waiting');
    });

    test('sending work back needs a reason', () async {
      final orderId = await placedOrder();
      var task = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(
        task: task,
        to: TaskStatus.assigned,
        userId: 'u1',
      );
      task = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(
        task: task,
        to: TaskStatus.inProgress,
        userId: 'u1',
      );
      task = (await db.tasksForOrder(orderId)).first;

      await expectLater(
        db.transitionTask(task: task, to: TaskStatus.rework, userId: 'u1'),
        throwsA(isA<StateError>()),
      );

      await db.transitionTask(
        task: task,
        to: TaskStatus.rework,
        userId: 'u1',
        reason: 'Customer changed the artwork',
      );
      final after = (await db.tasksForOrder(orderId)).first;
      expect(after.status, 'rework');
      expect(after.reworkCount, 1);
      expect(after.reason, contains('artwork'));
    });
    test('each status change travels as its own mutation, in order', () async {
      final orderId = await placedOrder();

      // The inserts must be on their way before the moves make sense: a status
      // patch merged into a pending insert is correct, a patch merged into
      // another patch is not.
      await db.markApplied(<String>[
        for (final mutation in await db.nextBatch()) mutation.mutationId,
      ]);

      var task = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(
        task: task,
        to: TaskStatus.assigned,
        userId: 'u1',
      );
      task = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(
        task: task,
        to: TaskStatus.inProgress,
        userId: 'u1',
      );
      task = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(task: task, to: TaskStatus.done, userId: 'u1');

      final batch = await db.nextBatch();
      final patches = batch
          .where((m) => m.entity == 'tasks' && m.op == 'patch')
          .toList();

      // claim, start, done, then the cascade that opens print.
      expect(patches, hasLength(4));
      expect(
        <Object?>[
          for (final mutation in patches)
            (jsonDecode(mutation.payloadJson)
                as Map<String, Object?>)['status'],
        ],
        <String>['assigned', 'in_progress', 'done', 'available'],
        reason: 'coalescing a state machine would present the server a jump',
      );
      expect(patches.map((m) => m.baseVersion).toList(), <int>[0, 1, 2, 0]);
    });
    test('a duplicate cascade the server already applied is dropped, not queued', () async {
      final orderId = await placedOrder();
      await db.markApplied(<String>[
        for (final mutation in await db.nextBatch()) mutation.mutationId,
      ]);

      var design = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(
        task: design,
        to: TaskStatus.assigned,
        userId: 'u1',
      );
      design = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(
        task: design,
        to: TaskStatus.inProgress,
        userId: 'u1',
      );
      design = (await db.tasksForOrder(orderId)).first;
      await db.transitionTask(task: design, to: TaskStatus.done, userId: 'u1');

      // Keep only the cascade patch in the outbox: the moves themselves are not
      // what this test is about.
      final batch = await db.nextBatch();
      final cascade = batch.firstWhere((mutation) {
        if (mutation.entity != 'tasks') return false;
        final payload = (jsonDecode(mutation.payloadJson) as Map)
            .cast<String, Object?>();
        return payload['status'] == 'available';
      });
      await db.markApplied(<String>[
        for (final mutation in batch)
          if (mutation.mutationId != cascade.mutationId) mutation.mutationId,
      ]);
      expect(await db.pendingCount(), 1);

      // The device cascaded print to available; so did the server. The device's
      // copy comes back as a stale write, but the row already says what it
      // wanted — that is a duplicate, not a conflict.
      api.conflictWithRow = <String, Object?>{
        'id': 'print-task',
        'tenant_id': 't1',
        'branch_id': 'b1',
        'order_id': orderId,
        'stage_key': 'print',
        'stage_name': 'Print',
        'sequence': 20,
        'title': 'Print',
        'status': 'available',
        'required_role': 'operator',
        'version': 2,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await engine.syncNow();
      expect(
        await db.pendingCount(),
        0,
        reason: 'a duplicate must not leave a permanent pending badge',
      );
    });
  });

  group('proofs', () {
    test(
      'a proof link becomes the next version and travels as a draft',
      () async {
        final orderId = await db.createOrderLocal(
          tenantId: 't1',
          branchId: 'b1',
          customerId: 'c1',
          customerName: 'Ahmed Traders',
          userId: 'u1',
          numberDisplay: '10452',
          lines: const <OrderLineDraft>[
            OrderLineDraft(
              productId: 'prod_cards',
              description: 'Business cards',
              optionsJson: '{}',
              quantity: 500,
              priceBookVersion: 1,
              breakdownJson: '{}',
              subtotalFils: 12200,
              vatFils: 610,
              totalFils: 12810,
            ),
          ],
        );

        await db.addProofLocal(
          orderId: orderId,
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          label: 'Front',
          url: 'https://drive.example/front.pdf',
        );
        await db.addProofLocal(
          orderId: orderId,
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          label: 'Back',
          url: 'https://drive.example/back.pdf',
        );

        final proofs = await db.watchProofs(orderId).first;
        expect(proofs.map((proof) => proof.revision).toList(), <int>[1, 2]);
        expect(proofs.first.status, 'draft');
      },
    );

    test('a rejection needs a note and records it', () async {
      final orderId = await db.createOrderLocal(
        tenantId: 't1',
        branchId: 'b1',
        customerId: 'c1',
        customerName: 'Ahmed Traders',
        userId: 'u1',
        numberDisplay: '10453',
        lines: const <OrderLineDraft>[
          OrderLineDraft(
            productId: 'prod_cards',
            description: 'Business cards',
            optionsJson: '{}',
            quantity: 500,
            priceBookVersion: 1,
            breakdownJson: '{}',
            subtotalFils: 12200,
            vatFils: 610,
            totalFils: 12810,
          ),
        ],
      );
      await db.addProofLocal(
        orderId: orderId,
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        label: 'Front',
        url: 'https://drive.example/front.pdf',
      );
      var proof = (await db.watchProofs(orderId).first).single;

      await expectLater(
        db.setProofStatus(proof: proof, status: 'approved', userId: 'u1'),
        throwsA(isA<StateError>()),
        reason: 'nothing is approved before it was sent',
      );

      await db.setProofStatus(proof: proof, status: 'sent', userId: 'u1');
      proof = (await db.watchProofs(orderId).first).single;
      expect(proof.sentAt, isNotNull);

      await expectLater(
        db.setProofStatus(proof: proof, status: 'rejected', userId: 'u1'),
        throwsA(isA<StateError>()),
      );

      await db.setProofStatus(
        proof: proof,
        status: 'rejected',
        userId: 'u1',
        note: 'Logo too close to the trim',
      );
      proof = (await db.watchProofs(orderId).first).single;
      expect(proof.status, 'rejected');
      expect(proof.decidedNote, contains('trim'));
      expect(proof.decidedAt, isNotNull);
    });
  });

  group('money', () {
    Future<Order> order() async {
      final id = await db.createOrderLocal(
        tenantId: 't1',
        branchId: 'b1',
        customerId: 'c1',
        customerName: 'Ahmed Traders',
        userId: 'u1',
        numberDisplay: '10452',
        lines: const <OrderLineDraft>[
          OrderLineDraft(
            productId: 'prod_cards',
            description: 'Business cards - 500',
            optionsJson: '{"quantity":500}',
            quantity: 500,
            priceBookVersion: 7,
            breakdownJson: '{"total_fils":12200}',
            subtotalFils: 12200,
            vatFils: 610,
            totalFils: 12810,
          ),
        ],
      );
      return (await db.orderById(id))!;
    }

    test('an invoice snapshots the order and refuses a second one', () async {
      final placed = await order();
      final invoiceId = await db.issueInvoiceLocal(
        order: placed,
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        number: 'INV-SHJ1-PC1-00001',
      );

      final invoice = await db.invoiceForOrder(placed.id);
      expect(invoice, isNotNull);
      expect(invoice!.number, 'INV-SHJ1-PC1-00001');
      expect(invoice.subtotalFils, 12200);
      expect(invoice.vatFils, 610);
      expect(invoice.totalFils, 12810);
      expect(invoice.paidFils, 0);
      expect(invoice.status, 'issued');

      final lines = await db.linesFor(invoiceId);
      expect(lines, hasLength(1));
      expect(lines.single.amountFils, 12200);
      expect(lines.single.unitFils, 24);

      await expectLater(
        db.issueInvoiceLocal(
          order: placed,
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          number: 'INV-SHJ1-PC1-00002',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a renamed prefix changes the next number, never an issued one', () async {
      final placed = await order();
      const issuedBefore = 'INV-SHJ1-PC1-00042';
      await db.issueInvoiceLocal(
        order: placed,
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        number: issuedBefore,
      );

      // The owner renames INV to BILL in Settings, and this device has pulled
      // the new payload. Only numbers issued from now on use it.
      final series = NumberSeries(
        db: db,
        api: api,
        kind: NumberKind.invoice,
        branchCode: 'SHJ1',
        deviceCode: 'PC1',
        prefixes: const NumberPrefixes(invoice: 'BILL'),
      );
      final next = await series.next();
      expect(
        next.display,
        'BILL-SHJ1-PC1-00001',
        reason: 'the next invoice carries the prefix Settings has today',
      );

      final invoice = await db.invoiceForOrder(placed.id);
      expect(
        invoice!.number,
        issuedBefore,
        reason: 'an issued number is history — it is stored, not rebuilt',
      );
    });

    test('vendor work is queued with its cost and moves only where allowed', () async {
      final vendorId = await db.createVendorLocal(
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        name: 'Al Nahda Embroidery',
        trade: 'embroidery',
      );

      final placed = await order();
      final jobId = await db.createVendorJobLocal(
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        orderId: placed.id,
        vendorId: vendorId,
        description: 'Embroidered logos',
        costFils: 45000,
        qty: 50,
      );

      final job = await (db.select(
        db.vendorJobs,
      )..where((t) => t.id.equals(jobId))).getSingle();
      expect(job.status, 'draft');
      expect(job.costFils, 45000);

      final batch = await db.nextBatch();
      expect(batch.where((m) => m.entity == 'vendors'), hasLength(1));
      expect(batch.where((m) => m.entity == 'vendor_jobs'), hasLength(1));

      await db.markApplied(<String>[for (final mutation in batch) mutation.mutationId]);

      await db.transitionVendorJob(job: job, to: 'sent');
      final sent = await (db.select(
        db.vendorJobs,
      )..where((t) => t.id.equals(jobId))).getSingle();
      expect(sent.status, 'sent');
      expect(sent.sentAt, isNotNull);

      await expectLater(
        db.transitionVendorJob(job: sent, to: 'closed'),
        throwsA(isA<StateError>()),
        reason: 'work that has not come back cannot be costed',
      );
    });

    test('a job is found by its number and an invoice by its own', () async {
      final placed = await order();
      await db.issueInvoiceLocal(
        order: placed,
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        number: 'INV-SHJ1-PC1-00077',
      );

      final byJob = await db.searchOrders(placed.numberDisplay).first;
      expect(byJob.map((row) => row.id), contains(placed.id));

      final byInvoice = await db.searchInvoices('INV-SHJ1-PC1-00077').first;
      expect(byInvoice, hasLength(1));
      expect(byInvoice.single.orderId, placed.id);

      expect(await db.searchOrders('nothing-like-this').first, isEmpty);
      expect(await db.searchInvoices('nothing-like-this').first, isEmpty);
    });

    test('an expense is queued as a whole insert with its method', () async {
      final id = await db.addExpenseLocal(
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        category: 'Courier',
        description: 'Proof delivery to Dubai',
        amountFils: 4500,
        method: 'cash',
      );

      final row = await (db.select(
        db.expenses,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.amountFils, 4500);
      expect(row.method, 'cash');
      expect(row.category, 'Courier');

      final batch = await db.nextBatch();
      expect(batch, hasLength(1));
      expect(batch.single.entity, 'expenses');
      expect(batch.single.op, 'insert');

      await expectLater(
        db.addExpenseLocal(
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          category: 'Courier',
          description: 'Nothing',
          amountFils: 0,
        ),
        throwsA(isA<StateError>()),
        reason: 'money that was not paid is not an expense',
      );
    });

    test('a deposit is queued as a whole insert with its method and note', () async {
      final id = await db.createDepositLocal(
        tenantId: 't1',
        branchId: 'b1',
        userId: 'u1',
        customerId: 'c1',
        amountFils: 5000,
        method: 'cash',
        note: 'Advance for business cards',
      );

      final row = await (db.select(
        db.customerDeposits,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.amountFils, 5000);
      expect(row.method, 'cash');
      expect(row.allocatedFils, 0);
      expect(row.customerId, 'c1');

      final batch = await db.nextBatch();
      expect(batch, hasLength(1));
      expect(batch.single.entity, 'customer_deposits');
      expect(batch.single.op, 'insert');
      final payload =
          jsonDecode(batch.single.payloadJson) as Map<String, dynamic>;
      expect(payload['customer_id'], 'c1');
      expect(payload['amount_fils'], 5000);
      expect(payload['method'], 'cash');
      expect(payload['note'], 'Advance for business cards');

      await expectLater(
        db.createDepositLocal(
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          customerId: 'c1',
          amountFils: 0,
          method: 'cash',
        ),
        throwsA(isA<StateError>()),
        reason: 'money that was not handed over is not a deposit',
      );
    });

    test(
      'a payment moves the balance but only the payment is queued',
      () async {
        final placed = await order();
        await db.issueInvoiceLocal(
          order: placed,
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          number: 'INV-SHJ1-PC1-00003',
        );
        await db.markApplied(<String>[
          for (final mutation in await db.nextBatch()) mutation.mutationId,
        ]);

        var invoice = (await db.invoiceForOrder(placed.id))!;
        await db.takePaymentLocal(
          invoice: invoice,
          amountFils: 5000,
          method: 'cash',
          userId: 'u1',
        );

        invoice = (await db.invoiceForOrder(placed.id))!;
        expect(invoice.paidFils, 5000);
        expect(invoice.status, 'part_paid');

        final batch = await db.nextBatch();
        expect(batch.where((m) => m.entity == 'payments'), hasLength(1));
        expect(
          batch.where((m) => m.entity == 'invoices' && m.op == 'patch'),
          isEmpty,
          reason: 'the paid cache belongs to the server',
        );

        await expectLater(
          db.takePaymentLocal(
            invoice: invoice,
            amountFils: 99999,
            method: 'cash',
            userId: 'u1',
          ),
          throwsA(isA<StateError>()),
        );

        await db.takePaymentLocal(
          invoice: invoice,
          amountFils: 7810,
          method: 'transfer',
          userId: 'u1',
          reference: 'TT-7788',
        );
        invoice = (await db.invoiceForOrder(placed.id))!;
        expect(invoice.paidFils, 12810);
        expect(invoice.status, 'paid');
      },
    );
    test(
      'a credit note reduces what is owed and a refund pays it back',
      () async {
        final placed = await order();
        await db.issueInvoiceLocal(
          order: placed,
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          number: 'INV-SHJ1-PC1-00004',
        );
        final invoice = (await db.invoiceForOrder(placed.id))!;

        await db.issueCreditNoteLocal(
          invoice: invoice,
          tenantId: 't1',
          branchId: 'b1',
          userId: 'u1',
          number: 'CN-SHJ1-PC1-00001',
          amountFils: 5000,
          reason: 'Customer returned 100 cards damaged in finishing',
        );

        final updated = (await db.invoiceForOrder(placed.id))!;
        expect(updated.creditedFils, 5000);
        expect(updated.paidFils, 0, reason: 'crediting is not payment');

        final notes = await db.watchCreditNotes(invoice.id).first;
        expect(notes, hasLength(1));
        expect(notes.single.totalFils, 5000);
        expect(notes.single.subtotalFils, 4762, reason: '50.00 at 5% VAT');
        expect(notes.single.vatFils, 238);

        await expectLater(
          db.issueCreditNoteLocal(
            invoice: updated,
            tenantId: 't1',
            branchId: 'b1',
            userId: 'u1',
            number: 'CN-SHJ1-PC1-00002',
            amountFils: 99999,
            reason: 'Trying to credit more than the invoice',
          ),
          throwsA(isA<StateError>()),
        );

        await db.refundLocal(
          note: notes.single,
          amountFils: 5000,
          method: 'cash',
          userId: 'u1',
        );
        final refunded = (await db.watchCreditNotes(invoice.id).first).single;
        expect(refunded.refundedFils, 5000);

        await expectLater(
          db.refundLocal(
            note: refunded,
            amountFils: 100,
            method: 'cash',
            userId: 'u1',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('state', () {
    test('emits syncing then synced', () async {
      final phases = <SyncPhase>[];
      final subscription = engine.states.listen(
        (state) => phases.add(state.phase),
      );

      await engine.syncNow();
      await Future<void>.delayed(Duration.zero);

      expect(phases.first, SyncPhase.syncing);
      expect(phases.last, SyncPhase.synced);
      await subscription.cancel();
    });
  });
}
