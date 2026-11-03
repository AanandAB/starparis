import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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
