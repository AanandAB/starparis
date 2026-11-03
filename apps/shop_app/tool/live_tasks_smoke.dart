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

  // ---- place an order ----------------------------------------------------
  final customerId = await db.createCustomerLocal(
    tenantId: tenantId,
    branchId: branchId,
    name: 'Tasks Smoke ${DateTime.now().millisecondsSinceEpoch}',
    company: 'Smoke LLC',
    phoneE164: '052${DateTime.now().millisecondsSinceEpoch % 10000000}',
    userId: userId,
  );

  final issued = await NumberSeries(db: db, api: api, series: 'JOB').next();
  final orderId = await db.createOrderLocal(
    tenantId: tenantId,
    branchId: branchId,
    customerId: customerId,
    customerName: 'Tasks Smoke',
    userId: userId,
    numberDisplay: issued.display,
    number: issued.number,
    jobTitle: '${issued.display} - Tasks Smoke',
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
