/// A minimal, standards-correct `.xlsx` writer.
///
/// An `.xlsx` is a zip of XML parts. This library builds every part as a Dart
/// string and zips them with `package:archive`, so there is no `excel` or `xml`
/// dependency and nothing to drift out of sync with the OOXML spec.
///
/// Why hand-rolled: `excel` conflicts with `pdf` (disjoint `xml` ranges) and
/// does not expose freeze panes or auto-filter — the two things the shop wants
/// (a frozen header and a filterable list). The handful of parts below is small
/// and entirely under our control.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Excel counts days from 1899-12-30: serial 1 is 1900-01-01, and the epoch is
/// pushed back a day because Excel keeps its phantom 1900-02-29 in the count.
final DateTime _excelEpoch = DateTime.utc(1899, 12, 30);

/// One value in a spreadsheet cell.
///
/// A sealed union so the writer switches exhaustively and can never mistake one
/// kind for another. [CellValue.empty] is the null case: it is written as a
/// bare `<c/>` and the writer never throws on it.
sealed class CellValue {
  const CellValue();

  const factory CellValue.text(String value) = CellText;
  const factory CellValue.number(num value) = CellNumber;
  const factory CellValue.date(DateTime value) = CellDate;
  const factory CellValue.boolean(bool value) = CellBool;
  const factory CellValue.empty() = CellEmpty;
}

/// Free text, written as an inline string so Excel keeps it verbatim.
final class CellText extends CellValue {
  const CellText(this.value);

  final String value;
}

/// A number, written with style 1 (the AED `#,##0.00` format).
final class CellNumber extends CellValue {
  const CellNumber(this.value);

  final num value;
}

/// A date, written with style 2 (the short-date format) as an Excel serial.
final class CellDate extends CellValue {
  const CellDate(this.value);

  final DateTime value;
}

/// A boolean, written as `t="b"`.
final class CellBool extends CellValue {
  const CellBool(this.value);

  final bool value;
}

/// Nothing. Written as an empty `<c r=".."/>`.
final class CellEmpty extends CellValue {
  const CellEmpty();
}

/// Writes a workbook as a `.xlsx` (a zip of OOXML parts) and returns the bytes.
///
/// [sheetName] names the data sheet; a second "Info" sheet carries [info] as
/// key/value rows plus a "Generated at" stamp. Text becomes inline strings,
/// numbers use the AED `#,##0.00` format, dates become serials with the
/// short-date format, booleans become `t="b"`, and empty cells become `<c/>`.
Uint8List exportXlsx({
  required String sheetName,
  required List<String> headers,
  required List<List<CellValue>> rows,
  Map<String, String> info = const <String, String>{},
  DateTime? generatedAt,
}) {
  final dataXml = _worksheetXml(
    headers: headers,
    rows: rows,
    freezeHeader: true,
    addAutoFilter: true,
  );
  final infoXml = _worksheetXml(
    headers: const <String>['Key', 'Value'],
    rows: _infoRows(sheetName, rows.length, info, generatedAt),
    freezeHeader: false,
    addAutoFilter: false,
  );

  final archive = Archive();
  void addPart(String path, String xml) {
    final bytes = Uint8List.fromList(utf8.encode(xml));
    // ArchiveFile.bytes sets the entry's uncompressed size from the UTF-8 byte
    // length, so the size is never a character count (which would be wrong the
    // moment any non-ASCII text appears).
    archive.addFile(ArchiveFile.bytes(path, bytes));
  }

  addPart('[Content_Types].xml', _contentTypes());
  addPart('_rels/.rels', _rootRels());
  addPart('xl/workbook.xml', _workbookXml(sheetName));
  addPart('xl/_rels/workbook.xml.rels', _workbookRels());
  addPart('xl/styles.xml', _stylesXml());
  addPart('xl/worksheets/sheet1.xml', dataXml);
  addPart('xl/worksheets/sheet2.xml', infoXml);

  return ZipEncoder().encodeBytes(archive);
}

/// The Info sheet's key/value rows: the sheet name, a row count, the caller's
/// [info], then the generation stamp (as both a readable string and a real date
/// cell, so the short-date format is exercised).
List<List<CellValue>> _infoRows(
  String sheetName,
  int rowCount,
  Map<String, String> info,
  DateTime? generatedAt,
) {
  return <List<CellValue>>[
    <CellValue>[const CellText('Sheet'), CellText(sheetName)],
    <CellValue>[const CellText('Rows'), CellText('$rowCount')],
    for (final MapEntry<String, String> entry in info.entries)
      <CellValue>[CellText(entry.key), CellText(entry.value)],
    if (generatedAt != null) ...<List<CellValue>>[
      <CellValue>[
        const CellText('Generated at'),
        CellText(generatedAt.toIso8601String()),
      ],
      <CellValue>[const CellText('Generated on'), CellDate(generatedAt)],
    ],
  ];
}

String _worksheetXml({
  required List<String> headers,
  required List<List<CellValue>> rows,
  required bool freezeHeader,
  required bool addAutoFilter,
}) {
  final lastColumn = _columnName(max(headers.length, 1) - 1);
  final lastRow = rows.length + 1; // header row plus the data rows

  final buffer = StringBuffer();
  buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  buffer.write(
    '<worksheet '
    'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
  );
  buffer.write('<dimension ref="A1:$lastColumn$lastRow"/>');

  // The frozen header is the whole reason the file exists; the pane must sit
  // inside a sheetView with workbookViewId="0" and point at A2.
  buffer.write('<sheetViews><sheetView workbookViewId="0">');
  if (freezeHeader) {
    buffer.write(
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>',
    );
  }
  buffer.write('</sheetView></sheetViews>');

  buffer.write('<sheetFormatPr defaultRowHeight="15"/>');
  buffer.write(_colsXml(_columnWidths(headers, rows)));

  buffer.write('<sheetData>');
  buffer.write('<row r="1">');
  for (var c = 0; c < headers.length; c++) {
    buffer.write(_inlineStrCell(_cellRef(c, 1), headers[c]));
  }
  buffer.write('</row>');
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    buffer.write('<row r="${r + 2}">');
    for (var c = 0; c < headers.length; c++) {
      // A short row is padded with empty cells, so a missing value never throws
      // and the grid stays rectangular.
      final cell = c < row.length ? row[c] : const CellEmpty();
      buffer.write(_cellXml(_cellRef(c, r + 2), cell));
    }
    buffer.write('</row>');
  }
  buffer.write('</sheetData>');

  // Auto-filter must come after sheetData and spans the header through the last
  // data row so every row is filterable.
  if (addAutoFilter) {
    final lastFilterRow = rows.length + 1;
    buffer.write('<autoFilter ref="A1:$lastColumn$lastFilterRow"/>');
  }

  buffer.write('</worksheet>');
  return buffer.toString();
}

String _contentTypes() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
    '</Types>';

String _rootRels() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
    '</Relationships>';

String _workbookXml(String sheetName) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets>'
    '<sheet name="${_xmlEscape(sheetName)}" sheetId="1" r:id="rId1"/>'
    '<sheet name="Info" sheetId="2" r:id="rId2"/>'
    '</sheets>'
    '</workbook>';

String _workbookRels() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>'
    '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '</Relationships>';

/// Two custom number formats (AED currency, short date) referenced by cellXf
/// indices 1 and 2, so number cells use `s="1"` and date cells use `s="2"`.
String _stylesXml() =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<numFmts count="2">'
    '<numFmt numFmtId="164" formatCode="#,##0.00"/>'
    '<numFmt numFmtId="165" formatCode="DD/MM/YYYY"/>'
    '</numFmts>'
    '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>'
    '<fills count="2">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '</fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="3">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

String _cellXml(String ref, CellValue cell) => switch (cell) {
  CellText(:final value) => _inlineStrCell(ref, value),
  CellNumber(:final value) => '<c r="$ref" s="1"><v>${_numberText(value)}</v></c>',
  CellDate(:final value) => '<c r="$ref" s="2"><v>${_serialText(value)}</v></c>',
  CellBool(:final value) => '<c r="$ref" t="b"><v>${value ? '1' : '0'}</v></c>',
  CellEmpty() => '<c r="$ref"/>',
};

String _inlineStrCell(String ref, String text) =>
    '<c r="$ref" t="inlineStr"><is><t xml:space="preserve">${_xmlEscape(text)}</t></is></c>';

String _cellRef(int columnIndex, int rowNumber) =>
    '${_columnName(columnIndex)}$rowNumber';

/// 0 -> "A", 25 -> "Z", 26 -> "AA", and so on.
String _columnName(int index) {
  final buffer = StringBuffer();
  var n = index + 1;
  while (n > 0) {
    n -= 1;
    buffer.write(String.fromCharCode(65 + n % 26));
    n ~/= 26;
  }
  return buffer.toString().split('').reversed.join();
}

/// Dart's shortest round-trip printing keeps `12345 / 100.0` as "123.45" and an
/// int as "5", which is exactly what a numeric `<v>` wants.
String _numberText(num value) => value.toString();

/// Excel serial = days (and fraction of a day) since 1899-12-30. Rounded to 5
/// decimals, then trailing zeros trimmed so a midnight date is "46000", not
/// "46000.00000".
String _serialText(DateTime date) {
  final serial = date.difference(_excelEpoch).inMicroseconds /
      Duration.microsecondsPerDay;
  var text = serial.toStringAsFixed(5);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

/// Escapes the five XML-significant characters so any name, note or number can
/// pass through without corrupting the part.
String _xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String _colsXml(List<int> widths) {
  final buffer = StringBuffer('<cols>');
  for (var i = 0; i < widths.length; i++) {
    final oneBased = i + 1;
    buffer.write(
      '<col min="$oneBased" max="$oneBased" width="${widths[i]}" customWidth="1"/>',
    );
  }
  buffer.write('</cols>');
  return buffer.toString();
}

/// A width per column, sized to its longest value plus padding, clamped so a
/// one-word header is not absurdly wide and a long address does not dominate.
List<int> _columnWidths(List<String> headers, List<List<CellValue>> rows) {
  final widths = <int>[];
  for (var c = 0; c < headers.length; c++) {
    var longest = headers[c].length;
    for (final row in rows) {
      final cell = c < row.length ? row[c] : const CellEmpty();
      longest = max(longest, _displayLength(cell));
    }
    widths.add(min(40, max(10, longest + 2)));
  }
  return widths;
}

int _displayLength(CellValue cell) => switch (cell) {
  CellText(:final value) => value.length,
  CellNumber(:final value) => value.toString().length,
  CellDate() => 10, // "DD/MM/YYYY"
  CellBool() => 5, // "FALSE"
  CellEmpty() => 0,
};
