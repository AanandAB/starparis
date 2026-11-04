import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:starparis_excel_export/starparis_excel_export.dart';
import 'package:test/test.dart';

void main() {
  test('builds a valid xlsx that round-trips through a zip decoder', () {
    final bytes = exportXlsx(
      sheetName: 'Customers',
      headers: const <String>[
        'Name',
        'Company',
        'Phone',
        'Tier',
        'Balance',
        'Active',
      ],
      rows: <List<CellValue>>[
        <CellValue>[
          const CellText('Ahmed Al Mansouri'),
          const CellText('Al Noor Printing'),
          const CellText('+971 50 123 4567'),
          const CellText('retail'),
          const CellNumber(123.45),
          const CellBool(true),
        ],
        <CellValue>[
          const CellText('Fatima'),
          const CellEmpty(),
          const CellText('+971 55 000 1111'),
          const CellText('trade'),
          const CellNumber(0),
          const CellBool(false),
        ],
        <CellValue>[
          const CellText('Empty row'),
          const CellEmpty(),
          const CellEmpty(),
          const CellEmpty(),
          const CellEmpty(),
          const CellEmpty(),
        ],
      ],
      info: const <String, String>{
        'Branch': 'Al Quoz',
        'Exported by': 'counter',
      },
      generatedAt: DateTime(2026, 1, 15, 9, 30),
    );

    // Genuine round-trip: decode the zip and read the XML parts back out.
    final archive = ZipDecoder().decodeBytes(bytes);
    final parts = <String, String>{};
    for (final file in archive.files) {
      parts[file.name] = utf8.decode(file.content);
    }

    // (a) every required part is present.
    expect(
      parts.keys,
      containsAll(<String>[
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/worksheets/sheet1.xml',
        'xl/worksheets/sheet2.xml',
      ]),
    );

    final sheet1 = parts['xl/worksheets/sheet1.xml']!;
    final sheet2 = parts['xl/worksheets/sheet2.xml']!;

    // (b) the frozen header pane, verbatim.
    expect(
      sheet1,
      contains(
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>',
      ),
    );

    // (c) the auto-filter spans A1:F{rows+1} — three data rows -> A1:F4.
    expect(sheet1, contains('<autoFilter ref="A1:F4"/>'));

    // (d) a number cell carries the AED style and its value.
    expect(sheet1, contains('<c r="E2" s="1"><v>123.45</v></c>'));

    // (e) an empty cell became a bare <c/>.
    expect(sheet1, contains('<c r="B3"/>'));

    // (f) the Info sheet holds a generated-at string.
    expect(sheet2, contains('Generated at'));
    expect(sheet2, contains('2026-01-15T09:30:00.000'));
  });

  test('escapes XML-significant characters in text and the sheet name', () {
    final bytes = exportXlsx(
      sheetName: 'A & B <Copies>',
      headers: const <String>['Note'],
      rows: <List<CellValue>>[
        <CellValue>[const CellText('5 < 6 & "quoted" \'apos\'')],
      ],
    );

    final archive = ZipDecoder().decodeBytes(bytes);
    final workbook = archive.files
        .firstWhere((file) => file.name == 'xl/workbook.xml')
        .content;
    final sheet1 = archive.files
        .firstWhere((file) => file.name == 'xl/worksheets/sheet1.xml')
        .content;

    expect(utf8.decode(workbook), contains('A &amp; B &lt;Copies&gt;'));
    expect(
      utf8.decode(sheet1),
      contains('5 &lt; 6 &amp; &quot;quoted&quot; &apos;apos&apos;'),
    );
  });
}
