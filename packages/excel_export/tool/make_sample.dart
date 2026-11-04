// Generates docs/samples/customers_sample.xlsx so a human can open it in Excel
// and confirm, by hand, that the header row is frozen and the columns are
// filterable. Run from the repo root:
//   dart run packages/excel_export/tool/make_sample.dart
import 'dart:io';

import 'package:starparis_excel_export/starparis_excel_export.dart';

Future<void> main() async {
  final bytes = exportXlsx(
    sheetName: 'Customers',
    headers: const <String>[
      'Name',
      'Company',
      'Phone',
      'Tier',
      'Balance (AED)',
    ],
    rows: <List<CellValue>>[
      <CellValue>[
        const CellText('Ahmed Al Mansouri'),
        const CellText('Al Noor Printing & Ads'),
        const CellText('+971 50 123 4567'),
        const CellText('trade'),
        const CellNumber(1250.50),
      ],
      <CellValue>[
        const CellText('Fatima K.'),
        const CellEmpty(),
        const CellText('+971 55 987 6543'),
        const CellText('retail'),
        const CellNumber(0),
      ],
      <CellValue>[
        const CellText('Bilal Traders'),
        const CellText('Bilal Est.'),
        const CellText('+971 4 338 2211'),
        const CellText('trade'),
        const CellNumber(8720.25),
      ],
      <CellValue>[
        const CellText('Rashid'),
        const CellEmpty(),
        const CellText('+971 52 000 0001'),
        const CellText('retail'),
        const CellNumber(45.00),
      ],
    ],
    info: const <String, String>{
      'Exported by': 'Star Paris',
      'Branch': 'Al Quoz',
    },
    generatedAt: DateTime.now(),
  );

  final file = File('docs/samples/customers_sample.xlsx');
  await file.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  stdout.writeln('Wrote ${file.absolute.path} (${bytes.length} bytes)');
}
