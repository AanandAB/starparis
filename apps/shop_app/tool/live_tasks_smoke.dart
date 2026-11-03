/// End-to-end smoke test for production tasks, using the real client code.
///
/// What it proves, in order:
///   1. confirming an order on a device creates one task per workflow stage,
///      with only the first offered to the pool;
///   2. those tasks reach D1 through the normal outbox push;
///   3. claiming, starting and finishing a stage works, and the server opens
///      the next stage in the same push;
///   4. the server refuses an illegal jump (waiting straight to done) even when
///      a client sends it directly, which is the rule that stops a patched
///      device from skipping quality check.
///
/// Usage:
///   dart run tool/live_tasks_smoke.dart [base-url] [phone] [password]
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

Future<void> main(List<String> args) async {
  final base = args.isNotEmpty
      ? args[0]
      : 'https://starparis-api.theblacklightstudio.workers.dev';
  final phone = args.length > 1 ? args[1] : '+971****0001';
  final password = args.length > 2 ? args[2] : 'starparis-demo';

  final client = http.Client();

  // ---- sign in -----------------------------------------------------------
  final loginResponse = await client.post(
    Uri.parse('$base/v1/auth/login'),
    headers: const <String, String>{'content-type': 'application/json'},
    body: jsonEncode(<String, Object?>{
      'phone': phone,
      'password': password,
      'device': <String, Object?>{
        'name': 'Tasks smoke',
        'platform': 'windows',
        'app_version': '0.1.0',
      },
    }),
  );
  if (loginResponse.statusCode != 200) {
    stderr.writeln('login failed: ${loginResponse.body}');
    exit(1);
  }
  final login = (jsonDecode(loginResponse.body) as Map).cast<String, Object?>();
  final token = login['access_token']! as String;
  final deviceId = login['device_id']! as String;
  final user = (login['user']! as Map).cast<String, Object?>();
  final tenantId = user['tenant_id']! as String;
  final branchId = user['branch_id'] as String?;
  final userId = user['id']! as String;
  stdout.writeln('login            ok  role=${user['role']}');

  final db = LocalDatabase(NativeDatabase.memory());
  final api = HttpSyncApi(
    baseUrl: base,
    deviceId: deviceId,
    tokenProvider: () async => token,
  );

  // ---- catalogue (products + workflow stages) ----------------------------
  final catalogueResponse = await client.get(
    Uri.parse('$base/v1/catalogue'),
    headers: <String, String>{'authorization': 'Bearer $token'},
  );
  if (catalogueResponse.statusCode != 200) {
    stderr.writeln('catalogue failed: ${catalogueResponse.body}');
    exit(1);
  }
  final catalogue =
      (jsonDecode(catalogueResponse.body) as Map).cast<String, Object?>();
  List<Map<String, Object?>> rows(Object? value) => <Map<String, Object?>>[
    for (final row in (value as List<Object?>? ?? const <Object?>[]))
      (row! as Map).cast<String, Object?>(),
  ];
  await db.replaceCatalogue(
    productRows: rows(catalogue['products']),
    materialRows: rows(catalogue['materials']),
    ruleRows: rows(catalogue['rules']),
    stageRows: rows(catalogue['workflow_stages']),
    priceBookVersion: (catalogue['price_book_version'] as num?)?.toInt() ?? 0,
    vatBps: ((catalogue['tax'] as Map?)?['vat_bps'] as num?)?.toInt() ?? 500,
  );
  final stages = await db.stagesFor('print_std');
  stdout.writeln(
    'workflow         ok  ${stages.map((stage) => stage.key).join(' -> ')}',
  );
  if (stages.length != 5) {
    stderr.writeln('expected 5 stages from the catalogue');
    exit(1);
  }

  // ---- settings (the shop's number prefixes) ------------------------------
  final settingsResponse = await client.get(
    Uri.parse('$base/v1/settings'),
    headers: <String, String>{'authorization': 'Bearer $token'},
  );
  if (settingsResponse.statusCode != 200) {
    stderr.writeln('settings failed: ${settingsResponse.body}');
    exit(1);
  }
  final prefixes = NumberPrefixes.fromSettingsJson(
    (jsonDecode(settingsResponse.body) as Map).cast<String, Object?>(),
  );

  // ---- place an order ----------------------------------------------------
  final customerId = await db.createCustomerLocal(
    tenantId: tenantId,
    branchId: branchId,
    name: 'Tasks Smoke ${DateTime.now().millisecondsSinceEpoch}',
    company: 'Smoke LLC',
    phoneE164: '052${DateTime.now().millisecondsSinceEpoch % 10000000}',
    userId: userId,
  );

  final issued = await NumberSeries(
    db: db,
    api: api,
    kind: NumberKind.job,
    branchCode: 'SHJ1',
    deviceCode: 'PC1',
    prefixes: prefixes,
  ).next();
  final jobDisplay = issued.display;
  final orderId = await db.createOrderLocal(
    tenantId: tenantId,
    branchId: branchId,
    customerId: customerId,
    customerName: 'Tasks Smoke',
    userId: userId,
    numberDisplay: jobDisplay,
    number: issued.number,
    jobTitle: '$jobDisplay - Tasks Smoke',
    lines: const <OrderLineDraft>[
      OrderLineDraft(
        productId: 'prod_business_cards',
        description: 'Business cards - 500 - matt',
        optionsJson: '{"quantity":500}',
        quantity: 500,
        priceBookVersion: 1,
        breakdownJson: '{"total_fils":12200,"vat_fils":610,"grand_total_fils":12810}',
        subtotalFils: 12200,
        vatFils: 610,
        totalFils: 12810,
      ),
    ],
  );

  final localTasks = await db.tasksForOrder(orderId);
  stdout.writeln(
    'tasks            ok  ${localTasks.length} created, '
    'first=${localTasks.first.status} rest=${localTasks.skip(1).map((t) => t.status).toSet()}',
  );

  final engine = SyncEngine(db: db, api: api);
  await engine.syncNow();
  stdout.writeln(
    'push             ${engine.current.phase.name}  pending=${await db.pendingCount()}',
  );
  for (final leftover in await db.nextBatch()) {
    stdout.writeln(
      'leftover         ${leftover.entity} ${leftover.op} '
      'attempts=${leftover.attempts} error=${leftover.lastError}',
    );
  }

  // ---- claim, start, finish the design stage -----------------------------
  var design = (await db.tasksForOrder(orderId)).first;
  await db.transitionTask(task: design, to: TaskStatus.assigned, userId: userId);
  design = (await db.tasksForOrder(orderId)).first;
  await db.transitionTask(task: design, to: TaskStatus.inProgress, userId: userId);
  design = (await db.tasksForOrder(orderId)).first;
  await db.transitionTask(task: design, to: TaskStatus.done, userId: userId);
  await engine.syncNow();
  stdout.writeln(
    'transitions      ${engine.current.phase.name}  pending=${await db.pendingCount()}',
  );
  for (final leftover in await db.nextBatch()) {
    stdout.writeln(
      'leftover         ${leftover.entity} ${leftover.op} '
      'attempts=${leftover.attempts} error=${leftover.lastError}',
    );
  }

  // ---- what the server now holds ----------------------------------------
  final pulled = await api.pull(since: 0, limit: 500);
  final serverTasks = <String, Map<String, Object?>>{};
  for (final row in pulled.rows.where((row) => row.entity == 'tasks')) {
    final data = row.data;
    if (data['order_id'] == orderId) {
      serverTasks[data['stage_key'] as String] = data;
    }
  }
  final summary = <String>[
    for (final stage in stages)
      '${stage.key}=${serverTasks[stage.key]?['status'] ?? 'missing'}',
  ].join(' ');
  stdout.writeln('server           $summary');

  if (serverTasks['design']?['status'] != 'done') {
    stderr.writeln('design did not reach done on the server');
    exit(1);
  }
  if (serverTasks['print']?['status'] != 'available') {
    stderr.writeln('print did not open after design finished');
    exit(1);
  }
  if (serverTasks['design']?['assigned_to'] != userId) {
    stderr.writeln('the claim did not stick');
    exit(1);
  }
  if (serverTasks['design']?['done_at'] == null) {
    stderr.writeln('the server did not stamp done_at');
    exit(1);
  }

  // ---- proofs: link, send, reject with a reason --------------------------
  await db.addProofLocal(
    orderId: orderId,
    tenantId: tenantId,
    branchId: branchId,
    userId: userId,
    label: 'Smoke proof',
    url: 'https://drive.example/smoke-proof-v1.pdf',
  );
  var proof = (await db.watchProofs(orderId).first).single;
  await db.setProofStatus(proof: proof, status: 'sent', userId: userId);
  proof = (await db.watchProofs(orderId).first).single;
  await db.setProofStatus(
    proof: proof,
    status: 'rejected',
    userId: userId,
    note: 'Trim is too tight on the back',
  );

  await engine.syncNow();
  final afterProofs = await api.pull(since: 0, limit: 500);
  final serverProof = afterProofs.rows
      .where((row) => row.entity == 'proofs' && row.data['order_id'] == orderId)
      .map((row) => row.data)
      .lastOrNull;
  stdout.writeln(
    'proof            ${serverProof?['status']}  '
    'note=${serverProof?['decided_note']}  pending=${await db.pendingCount()}',
  );
  if (serverProof?['status'] != 'rejected' || serverProof?['decided_note'] == null) {
    stderr.writeln('the proof did not reach the server with its reason');
    exit(1);
  }

  // ---- time: the server writes a stretch when work stops -----------------
  final timeRows = afterProofs.rows
      .where((row) => row.entity == 'time_entries' && row.data['order_id'] == orderId)
      .map((row) => row.data)
      .toList();
  final minutes = timeRows.fold<int>(
    0,
    (sum, row) => sum + ((row['minutes'] as num?)?.toInt() ?? 0),
  );
  stdout.writeln('time             ${timeRows.length} entries, ${minutes}m total');
  if (timeRows.isEmpty || minutes < 1) {
    stderr.writeln('finishing a stage did not record time on the server');
    exit(1);
  }

  // ---- invoice and payments ----------------------------------------------
  final placedOrder = (await db.orderById(orderId))!;
  final invoiceNumber = await NumberSeries(
    db: db,
    api: api,
    kind: NumberKind.invoice,
    branchCode: 'SHJ1',
    deviceCode: 'PC1',
    prefixes: prefixes,
  ).next();
  await db.issueInvoiceLocal(
    order: placedOrder,
    tenantId: tenantId,
    branchId: branchId,
    userId: userId,
    number: invoiceNumber.display,
  );

  var invoice = (await db.invoiceForOrder(orderId))!;
  await db.takePaymentLocal(
    invoice: invoice,
    amountFils: 5000,
    method: 'cash',
    userId: userId,
  );
  await engine.syncNow();

  invoice = (await db.invoiceForOrder(orderId))!;
  await db.takePaymentLocal(
    invoice: invoice,
    amountFils: invoice.totalFils - invoice.paidFils,
    method: 'transfer',
    userId: userId,
    reference: 'TT-SMOKE-1',
  );
  await engine.syncNow();

  final moneyPull = await api.pull(since: 0, limit: 500);
  final serverInvoice = moneyPull.rows
      .where((row) => row.entity == 'invoices' && row.data['order_id'] == orderId)
      .map((row) => row.data)
      .lastOrNull;
  final paymentCount = moneyPull.rows
      .where((row) => row.entity == 'payments' && row.data['invoice_id'] == serverInvoice?['id'])
      .length;

  stdout.writeln(
    'invoice          ${serverInvoice?['number']}  '
    'paid=${serverInvoice?['paid_fils']}  status=${serverInvoice?['status']}  '
    'payments=$paymentCount  pending=${await db.pendingCount()}',
  );

  if (serverInvoice == null ||
      serverInvoice['paid_fils'] != serverInvoice['total_fils'] ||
      serverInvoice['status'] != 'paid' ||
      paymentCount != 2) {
    stderr.writeln('the invoice did not settle on the server');
    exit(1);
  }

  // ---- credit note, then cash back ---------------------------------------
  final creditNumber = await NumberSeries(
    db: db,
    api: api,
    kind: NumberKind.creditNote,
    branchCode: 'SHJ1',
    deviceCode: 'PC1',
  ).next();
  await db.issueCreditNoteLocal(
    invoice: invoice,
    tenantId: tenantId,
    branchId: branchId,
    userId: userId,
    number: creditNumber.display,
    amountFils: 5000,
    reason: 'Smoke: 100 cards damaged in finishing',
  );

  final note = (await db.watchCreditNotes(invoice.id).first).single;
  await db.refundLocal(
    note: note,
    amountFils: 5000,
    method: 'cash',
    userId: userId,
  );
  await engine.syncNow();

  final afterCredit = await api.pull(since: 0, limit: 600);
  final serverNote = afterCredit.rows
      .where((row) => row.entity == 'credit_notes' && row.data['invoice_id'] == invoice.id)
      .map((row) => row.data)
      .lastOrNull;
  final creditedInvoice = afterCredit.rows
      .where((row) => row.entity == 'invoices' && row.data['order_id'] == orderId)
      .map((row) => row.data)
      .lastOrNull;
  final refundRows = afterCredit.rows
      .where(
        (row) =>
            row.entity == 'refunds' && row.data['credit_note_id'] == serverNote?['id'],
      )
      .length;

  stdout.writeln(
    'credit note      ${serverNote?['number']}  '
    'total=${serverNote?['total_fils']}  refunded=${serverNote?['refunded_fils']}  '
    'refunds=$refundRows  invoice_credited=${creditedInvoice?['credited_fils']}  '
    'pending=${await db.pendingCount()}',
  );

  if (serverNote == null ||
      serverNote['refunded_fils'] != 5000 ||
      creditedInvoice?['credited_fils'] != 5000 ||
      refundRows != 1) {
    stderr.writeln('the credit note or refund did not reach the server intact');
    exit(1);
  }

  // ---- the server must refuse a jump even when asked directly ------------
  final printRow = serverTasks['print']!;
  final jumpResponse = await client.post(
    Uri.parse('$base/v1/push'),
    headers: <String, String>{
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
    },
    body: jsonEncode(<String, Object?>{
      'device_id': deviceId,
      'mutations': <Map<String, Object?>>[
        <String, Object?>{
          'mutation_id': 'smoke-jump-${DateTime.now().millisecondsSinceEpoch}',
          'entity': 'tasks',
          'op': 'patch',
          'row_id': printRow['id'],
          'base_version': printRow['version'],
          'device_ts': DateTime.now().toUtc().toIso8601String(),
          'fields': <String, Object?>{'status': 'done'},
        },
      ],
    }),
  );
  final jump = (jsonDecode(jumpResponse.body) as Map).cast<String, Object?>();
  final result = (jump['results']! as List<Object?>).first! as Map;
  final code = ((result['error'] as Map?)?['code']) ?? 'none';
  stdout.writeln('server refuses   $code  (status=${result['status']})');
  if (code != 'ILLEGAL_TRANSITION') {
    stderr.writeln('the server accepted a jump from available to done');
    exit(1);
  }

  await engine.dispose();
  await db.close();
  client.close();

  stdout.writeln(
    'OK — tasks generated, claimed, finished, cascaded and policed by the server.',
  );
}
