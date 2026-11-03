/// Checks the reports client against the live API.
///
/// The screen is only as good as the parsing: this logs in, calls the same
/// `ReportsService` the UI uses, and prints what the client understood.
///
///   dart run tool/reports_smoke.dart [base-url] [phone] [password]
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:starparis_domain/starparis_domain.dart';
import 'package:shop_app/src/sales/reports_service.dart';

Future<void> main(List<String> args) async {
  final base = args.isNotEmpty
      ? args[0]
      : 'https://starparis-api.theblacklightstudio.workers.dev';
  final phone = args.length > 1 ? args[1] : '';
  final password = args.length > 2 ? args[2] : 'starparis-demo';

  final client = http.Client();
  final loginResponse = await client.post(
    Uri.parse('$base/v1/auth/login'),
    headers: const <String, String>{'content-type': 'application/json'},
    body: jsonEncode(<String, Object?>{
      'phone': phone,
      'password': password,
      'device': <String, Object?>{
        'name': 'Reports smoke',
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

  final reports = ReportsService(
    baseUrl: base,
    tokenProvider: () async => token,
  );

  final now = DateTime.now();
  final vat = await reports.vat(
    from: DateTime(now.year, now.month),
    to: DateTime(now.year, now.month + 1),
  );
  stdout.writeln(
    'vat        ${Fils(vat.salesNetFils).aedLabel} sales · '
    '${Fils(vat.outputVatFils).aedLabel} output · '
    '${Fils(vat.creditedVatFils).aedLabel} credited · '
    '${Fils(vat.netVatDueFils).aedLabel} due · '
    '${Fils(vat.collectedFils).aedLabel} collected',
  );

  final ageing = await reports.ageing();
  stdout.writeln(
    'ageing     ${Fils(ageing.totals.totalFils).aedLabel} outstanding across '
    '${ageing.rows.length} customer(s) '
    '(current ${Fils(ageing.totals.currentFils).aedText}, '
    '31-60 ${Fils(ageing.totals.days3160Fils).aedText}, '
    '61-90 ${Fils(ageing.totals.days6190Fils).aedText}, '
    '90+ ${Fils(ageing.totals.over90Fils).aedText})',
  );
  for (final row in ageing.rows) {
    stdout.writeln('           ${row.customerName} · ${Fils(row.totalFils).aedLabel}');
  }

  reports.dispose();
  client.close();

  if (vat.netVatDueFils != vat.outputVatFils - vat.creditedVatFils) {
    stderr.writeln('VAT due does not equal output less credits');
    exit(1);
  }
  stdout.writeln('OK — reports parse and reconcile through the client.');
}
