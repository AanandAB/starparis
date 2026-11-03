/// Proves the owner can change a price from the app and that the change is real.
///
/// Signs in as the owner, prices 500 business cards, edits the lamination rate
/// through the same endpoint the price-book screen uses, re-fetches the
/// catalogue, prices again, then restores the original rate and confirms the
/// price comes back. Leaves the dev database exactly as it found it.
///
/// Usage: dart run tool/live_price_book_smoke.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:starparis_pricing/pricing_engine.dart';

const String base = 'https://starparis-api.theblacklightstudio.workers.dev';
const String phone = '+971500000001';
const String password = 'starparis-demo';

late final http.Client client;
late String token;

Future<Map<String, Object?>> request(
  String method,
  String path, {
  Object? body,
  bool auth = true,
}) async {
  final request = http.Request(method, Uri.parse('$base$path'));
  if (auth) request.headers['authorization'] = 'Bearer $token';
  if (body != null) {
    request.headers['content-type'] = 'application/json';
    request.body = jsonEncode(body);
  }
  final response = await http.Response.fromStream(await client.send(request));
  final decoded = response.body.isEmpty
      ? <String, Object?>{}
      : (jsonDecode(response.body) as Map).cast<String, Object?>();
  if (response.statusCode >= 400) {
    throw StateError('$method $path -> ${response.statusCode}: ${response.body}');
  }
  return decoded;
}

Future<Map<String, Object?>> fetchCatalogue() => request('GET', '/v1/catalogue');

/// Prices 500 cards, 90×55, double sided, matt lamination, from a catalogue map.
PriceBreakdown priceCards(Map<String, Object?> catalogue) {
  final products = (catalogue['products'] as List<Object?>)
      .cast<Map<String, Object?>>();
  final materials = (catalogue['materials'] as List<Object?>)
      .cast<Map<String, Object?>>();
  final rules = (catalogue['rules'] as List<Object?>).cast<Map<String, Object?>>();

  final product = products.firstWhere((row) => row['code'] == 'business_cards');
  final material = materials.firstWhere(
    (row) => row['code'] == product['material_code'],
  );
  final productRules = rules.where(
    (row) => row['product_id'] == null || row['product_id'] == product['id'],
  );

  return PricingEngine.price(
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
      priceBookVersion: (catalogue['price_book_version'] as num).toInt(),
      mode: PricingMode.costPlus,
      rules: <PriceRule>[
        for (final row in productRules)
          PriceRule(
            id: row['id'] as String,
            label: row['label'] as String,
            phase: RulePhase.fromWire(row['phase'] as String),
            basis: RuleBasis.fromWire(row['basis'] as String),
            rateFils: (row['rate_fils'] as num).toInt(),
            minChargeFils: (row['min_charge_fils'] as num?)?.toInt() ?? 0,
            priority: (row['priority'] as num?)?.toInt() ?? 100,
            when: <RuleCondition>[
              for (final condition in (jsonDecode(row['when_json'] as String) as List<Object?>))
                RuleCondition.fromJson((condition! as Map).cast<String, Object?>()),
            ],
          ),
      ],
      sheet: SheetSpec(
        widthMm: (product['sheet_width_mm'] as num).toInt(),
        heightMm: (product['sheet_height_mm'] as num).toInt(),
        bleedMm: (product['bleed_mm'] as num?)?.toInt() ?? 3,
        gutterMm: (product['gutter_mm'] as num?)?.toInt() ?? 3,
      ),
      setupSheets: (product['setup_sheets'] as num?)?.toInt() ?? 2,
      spoilageBps: (product['spoilage_bps'] as num?)?.toInt() ?? 500,
      materialCostPerSheetFils: (material['cost_per_sheet_fils'] as num).toInt(),
      printRatePerSheetSideFils: (product['print_rate_fils'] as num).toInt(),
      markupBps: (product['markup_bps'] as num).toInt(),
      minOrderFils: (product['min_order_fils'] as num?)?.toInt() ?? 0,
      roundingStepFils: (product['rounding_step_fils'] as num?)?.toInt() ?? 100,
      vatBps: ((catalogue['tax'] as Map?)?['vat_bps'] as num?)?.toInt() ?? 500,
    ),
  );
}

double rateOf(Map<String, Object?> catalogue, String ruleId) {
  final rules = (catalogue['rules'] as List<Object?>).cast<Map<String, Object?>>();
  return ((rules.firstWhere((row) => row['id'] == ruleId)['rate_fils'] as num)).toDouble();
}

Future<void> main() async {
  client = http.Client();

  final login = await request(
    'POST',
    '/v1/auth/login',
    auth: false,
    body: <String, Object?>{
      'phone': phone,
      'password': password,
      'device': <String, Object?>{'name': 'Price smoke', 'platform': 'windows'},
    },
  );
  token = login['access_token']! as String;
  final role = (login['user']! as Map)['role'];
  stdout.writeln('login            ok  role=$role');
  if (role != 'owner') {
    stderr.writeln('this test needs the owner account');
    exit(1);
  }

  final before = await fetchCatalogue();
  final original = rateOf(before, 'rule_lamination_matt');
  final baseline = priceCards(before);
  stdout.writeln(
    'baseline         rate=${original.toStringAsFixed(0)} fils '
    'total=${baseline.total.aedLabel}',
  );

  if (baseline.total.raw != 12200) {
    stderr.writeln(
      'baseline is not the golden vector (${baseline.total.raw}) — run '
      'tools/seed_catalogue.py first',
    );
    exit(1);
  }

  await request(
    'PATCH',
    '/v1/price-book/rules/rule_lamination_matt',
    body: <String, Object?>{'rate_fils': 100},
  );

  final after = await fetchCatalogue();
  final raised = priceCards(after);
  stdout.writeln(
    'edit             ok  rate=100 fils total=${raised.total.aedLabel} '
    '(+${raised.total.raw - baseline.total.raw} fils)',
  );
  if (raised.total.raw <= baseline.total.raw) {
    stderr.writeln('raising the lamination rate did not raise the price');
    exit(1);
  }

  await request(
    'PATCH',
    '/v1/price-book/rules/rule_lamination_matt',
    body: <String, Object?>{'rate_fils': original.toInt()},
  );
  final restored = await fetchCatalogue();
  final again = priceCards(restored);
  stdout.writeln('restore          ok  total=${again.total.aedLabel}');
  if (again.total.raw != 12200) {
    stderr.writeln('restoring the rate did not restore the price');
    exit(1);
  }

  client.close();
  stdout.writeln('OK — the owner can change a price and the quote follows immediately.');
}
