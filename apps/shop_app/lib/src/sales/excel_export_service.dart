import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:starparis_excel_export/starparis_excel_export.dart';
import 'package:starparis_sync/starparis_sync.dart';

/// Writes the customer list to
/// `Documents/StarParis/StarParis_Customers_<YYYYMMDD_HHMM>.xlsx` and returns
/// the file so the caller can tell the counter where it went.
///
/// The balance is computed the same way the customer sheet computes it (total
/// minus paid minus credited, voided invoices skipped) so the file agrees with
/// the screen. It is fetched per customer because there is no whole-shop
/// rollup, and it is stored in fils until the very last step, where it becomes
/// an AED decimal for the number cell.
Future<File> exportCustomersToXlsx(
  LocalDatabase db,
  List<Customer> customers,
) async {
  final generatedAt = DateTime.now();
  final rows = <List<CellValue>>[];
  for (final customer in customers) {
    final phone = await db.primaryPhoneFor(customer.id);
    final invoices = await db.watchInvoicesForCustomer(customer.id).first;
    var balanceFils = 0;
    for (final invoice in invoices) {
      // A voided invoice is not a real charge, so it never moves the balance.
      if (invoice.voidReason != null) continue;
      balanceFils += (invoice.totalFils - invoice.paidFils - invoice.creditedFils)
          .clamp(0, invoice.totalFils);
    }
    rows.add(<CellValue>[
      CellText(customer.name),
      CellText(customer.company ?? ''),
      CellText(phone ?? ''),
      CellText(customer.tier),
      CellNumber(balanceFils / 100.0),
    ]);
  }

  final bytes = exportXlsx(
    sheetName: 'Customers',
    headers: const <String>[
      'Name',
      'Company',
      'Phone',
      'Tier',
      'Balance (AED)',
    ],
    rows: rows,
    info: const <String, String>{'Exported by': 'Star Paris'},
    generatedAt: generatedAt,
  );

  final base = await getApplicationDocumentsDirectory();
  final directory = Directory(p.join(base.path, 'StarParis'));
  await directory.create(recursive: true);
  final file = File(
    p.join(directory.path, 'StarParis_Customers_${_stamp(generatedAt)}.xlsx'),
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

String _stamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}${two(time.month)}${two(time.day)}_'
      '${two(time.hour)}${two(time.minute)}';
}
