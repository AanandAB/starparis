/// End-to-end smoke test against the deployed API, using the real client code.
///
/// This is not a unit test: it signs in, downloads the price book, prices a real
/// product with the real engine, creates an order with a leased job number,
/// pushes it to D1, pulls it back and prints what the server stored. If this
/// script says OK, the whole Phase 2 path works outside Flutter.
///
/// Usage:
///   dart run tool/live_order_smoke.dart [base-url] [phone] [password]
///
/// The numbers are the golden vector: 500 business cards, 90×55 mm, 350 gsm,
/// double sided, matt lamination = AED 122.00 + 6.10 VAT = 128.10.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:starparis_sync/starparis_sync.dart';

Future<void> main(List<String> args) async {
  final base = args.isNotEmpty
      ? args[0]
      : 'https://starparis-api.theblacklightstudio.workers.dev';
  final phone = args.length > 1 ? args[1] : '+971500000001';
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
        'name': 'Live smoke',
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
  stdout.writeln('login            ok  role=${user['role']} device=$deviceId');

  // ---- local database + api ---------------------------------------------
  final db = LocalDatabase(NativeDatabase.memory());
  final api = HttpSyncApi(
    baseUrl: base,
    deviceId: deviceId,
    tokenProvider: () async => token,
  );

  // ---- catalogue ---------------------------------------------------------
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
    priceBookVersion: (catalogue['price_book_version'] as num?)?.toInt() ?? 0,
    vatBps: ((catalogue['tax'] as Map?)?['vat_bps'] as num?)?.toInt() ?? 500,
  );
  stdout.writeln(
    'catalogue        ok  products=${rows(catalogue['products']).length} '
    'rules=${rows(catalogue['rules']).length} '
    'book v${catalogue['price_book_version']}',
  );

  // ---- price the golden vector on real catalogue data --------------------
  final products = await db.watchProducts().first;
  final product = products.firstWhere((p) => p.code == 'business_cards');
  final version = await db.priceBookVersion();
  final rules = await db.rulesForProduct(product.id, version);
  final material = await db.materialByCode(product.materialCode!);
  final vat = await db.vatBps();

  final price = PricingEngine.price(
    const PriceRequest(
      productId: 'prod_business_cards',
      kind: ProductKind.sheet,
      quantity: 500,
      widthMm: 90,
      heightMm: 55,
      sides: 2,
      materialCode: 'art_card_350',
      finishCodes: <String>['matt_lamination'],
    ),
    PricingContext(
      priceBookVersion: version,
      mode: PricingMode.costPlus,
      rules: <PriceRule>[
        for (final row in rules)
          PriceRule(
            id: row.id,
            label: row.label,
            phase: RulePhase.fromWire(row.phase),
            basis: RuleBasis.fromWire(row.basis),
            rateFils: row.rateFils,
            minChargeFils: row.minChargeFils,
            priority: row.priority,
            when: <RuleCondition>[
              for (final condition in (jsonDecode(row.whenJson) as List<Object?>))
                RuleCondition.fromJson((condition! as Map).cast<String, Object?>()),
            ],
            productIds: <String>{product.id},
          ),
      ],
      sheet: SheetSpec(
        widthMm: product.sheetWidthMm!,
        heightMm: product.sheetHeightMm!,
        bleedMm: product.bleedMm,
        gutterMm: product.gutterMm,
      ),
      setupSheets: product.setupSheets,
      spoilageBps: product.spoilageBps,
      materialCostPerSheetFils: material?.costPerSheetFils,
      printRatePerSheetSideFils: product.printRateFils,
      markupBps: product.markupBps,
      minOrderFils: product.minOrderFils,
      roundingStepFils: product.roundingStepFils,
      vatBps: vat,
    ),
  );

  stdout.writeln(
    'price            ok  total=${price.total.aedLabel} '
    'vat=${price.vat.aedLabel} grand=${price.grandTotal.aedLabel}',
  );
  if (price.total.raw != 12200 || price.vat.raw != 610) {
    stderr.writeln('price does not match the golden vector — stopping');
    exit(1);
  }

  // ---- create an order offline-style ------------------------------------
  final customerId = await db.createCustomerLocal(
    tenantId: tenantId,
    branchId: branchId,
    name: 'Live Smoke Customer ${DateTime.now().millisecondsSinceEpoch}',
    company: 'Smoke LLC',
    phoneE164: '050${DateTime.now().millisecondsSinceEpoch % 10000000}',
    userId: userId,
  );

  final issued = await NumberSeries(db: db, api: api, series: 'JOB').next();
  stdout.writeln('job number       ok  ${issued.display}');

  final orderId = await db.createOrderLocal(
    tenantId: tenantId,
    branchId: branchId,
    customerId: customerId,
    customerName: 'Live Smoke Customer',
    userId: userId,
    numberDisplay: issued.display,
    number: issued.number,
    lines: <OrderLineDraft>[
      OrderLineDraft(
        productId: product.id,
        description: 'Business cards · 500 · 90 × 55 mm · double sided · matt lamination',
        optionsJson: jsonEncode(<String, Object?>{
          'size': '90x55',
          'sides': 2,
          'finish': <String>['matt_lamination'],
          'quantity': 500,
        }),
        quantity: 500,
        priceBookVersion: price.priceBookVersion,
        breakdownJson: jsonEncode(price.toJson()),
        subtotalFils: price.total.raw,
        vatFils: price.vat.raw,
        totalFils: price.grandTotal.raw,
      ),
    ],
  );

  // ---- push, then pull ---------------------------------------------------
  final engine = SyncEngine(db: db, api: api);
  await engine.syncNow();
  stdout.writeln('push             ${engine.current.phase.name}  pending=${await db.pendingCount()}');
  for (final leftover in await db.nextBatch()) {
    stdout.writeln(
      'leftover         ${leftover.entity} ${leftover.op} '
      'attempts=${leftover.attempts} error=${leftover.lastError}',
    );
  }

  final pulled = await api.pull(since: 0, limit: 200);
  final serverOrder = pulled.rows.where((row) => row.rowId == orderId).toList();
  if (serverOrder.isEmpty) {
    stderr.writeln('order did not come back from the server');
    exit(1);
  }
  final data = serverOrder.first.data;
  stdout.writeln(
    'pull             ok  job=${data['number_display']} '
    'total_fils=${data['total_fils']} branch=${data['branch_id']}',
  );

  final items = await db.itemsFor(orderId);
  stdout.writeln(
    'stored           ok  items=${items.length} '
    'breakdown_bytes=${items.first.breakdownJson.length}',
  );

  await engine.dispose();
  await db.close();
  client.close();

  stdout.writeln('OK — catalogue, pricing, numbering, order push and pull all work live.');
}
