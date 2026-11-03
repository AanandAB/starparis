import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:starparis_domain/starparis_domain.dart';

import 'models.dart';
import 'style.dart';

/// One tax invoice, printable and reproducible.
///
/// Everything printed here is a snapshot taken at issue: the numbers, the
/// customer's name and TRN, the VAT rate. Nothing is looked up again, which is
/// why an invoice printed in 2026 still reads the same in 2031.
class InvoiceDocument {
  const InvoiceDocument({
    required this.number,
    required this.issuedAt,
    required this.customerName,
    required this.lines,
    required this.subtotalFils,
    required this.vatFils,
    required this.totalFils,
    this.vatBps = 500,
    this.discountFils = 0,
    this.paidFils = 0,
    this.dueAt,
    this.customerTrn,
    this.customerAddress,
    this.notes = '',
  });

  final String number;
  final DateTime issuedAt;
  final DateTime? dueAt;
  final String customerName;
  final String? customerTrn;
  final String? customerAddress;
  final List<DocumentLine> lines;
  final int subtotalFils;
  final int discountFils;
  final int vatBps;
  final int vatFils;
  final int totalFils;
  final int paidFils;
  final String notes;
}

Future<Uint8List> buildInvoicePdf(
  InvoiceDocument invoice,
  CompanyProfile company, {
  bool compress = true,
}) async {
  final document = pw.Document(
    title: 'Tax Invoice ${invoice.number}',
    author: company.name,
    creator: 'Star Paris',
    compress: compress,
  );

  final theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
      theme: theme,
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                asciiText('Tax invoice ${invoice.number}'),
                style: const pw.TextStyle(fontSize: 8, color: muted),
              ),
            ),
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: ruleLine, width: 0.6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              asciiText(company.name),
              style: const pw.TextStyle(fontSize: 7, color: muted),
            ),
            pw.Text(
              asciiText('Page ${context.pageNumber} of ${context.pagesCount}'),
              style: const pw.TextStyle(fontSize: 7, color: muted),
            ),
          ],
        ),
      ),
      build: (context) => <pw.Widget>[
        _header(invoice, company),
        pw.SizedBox(height: 16),
        _parties(invoice),
        pw.SizedBox(height: 16),
        _table(invoice),
        pw.SizedBox(height: 12),
        _totals(invoice),
        if (invoice.notes.trim().isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 14),
          pw.Text('Notes', style: _labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(asciiText(invoice.notes.trim()), style: const pw.TextStyle(fontSize: 9)),
        ],
        pw.SizedBox(height: 18),
        _declaration(company, invoice),
      ],
    ),
  );

  return document.save();
}

const pw.TextStyle _labelStyle = pw.TextStyle(
  fontSize: 8,
  color: muted,
  letterSpacing: 1.1,
);

pw.Widget _header(InvoiceDocument invoice, CompanyProfile company) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: const pw.BoxDecoration(color: brandPetrol),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                asciiText(company.name),
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                asciiText(company.address),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300),
              ),
              pw.Text(
                asciiText('Tel ${company.phone}  |  TRN ${company.trn}'),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(
              'TAX INVOICE',
              style: const pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: brandSand,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              asciiText(invoice.number),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _parties(InvoiceDocument invoice) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Expanded(
        flex: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text('BILLED TO', style: _labelStyle),
            pw.SizedBox(height: 4),
            pw.Text(
              asciiText(invoice.customerName),
              style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            if (invoice.customerAddress != null)
              pw.Text(
                asciiText(invoice.customerAddress!),
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
            if (invoice.customerTrn != null)
              pw.Text(
                asciiText('TRN ${invoice.customerTrn}'),
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
          ],
        ),
      ),
      pw.SizedBox(width: 16),
      pw.Expanded(
        flex: 2,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            _meta('Issued', _date(invoice.issuedAt)),
            if (invoice.dueAt != null) _meta('Due', _date(invoice.dueAt!)),
            _meta('Currency', 'AED'),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _meta(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: <pw.Widget>[
        pw.Text('$label  ', style: const pw.TextStyle(fontSize: 8, color: muted)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
}

pw.Widget _table(InvoiceDocument invoice) {
  return pw.TableHelper.fromTextArray(
    border: pw.TableBorder.symmetric(
      inside: const pw.BorderSide(color: ruleLine, width: 0.5),
      outside: const pw.BorderSide(color: ruleLine, width: 0.5),
    ),
    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE4)),
    headerStyle: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    headers: <String>['Description', 'Qty', 'Unit AED', 'Amount AED'],
    data: <List<String>>[
      for (final line in invoice.lines)
        <String>[
          asciiText(line.description),
          '${line.quantity}',
          unitPriceText(line.amountFils, line.quantity),
          Fils(line.amountFils).aedText,
        ],
    ],
    columnWidths: <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(5),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1.6),
      3: const pw.FlexColumnWidth(1.8),
    },
    cellAlignments: <int, pw.Alignment>{
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerRight,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
    },
  );
}

pw.Widget _totals(InvoiceDocument invoice) {
  final balance = invoice.totalFils - invoice.paidFils;
  final vatPercent = (invoice.vatBps / 100).toStringAsFixed(0);

  pw.Widget row(String label, String value, {bool bold = false, PdfColor? colour}) {
    final style = pw.TextStyle(
      fontSize: bold ? 11 : 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: colour,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  return pw.Row(
    children: <pw.Widget>[
      pw.Expanded(child: pw.SizedBox()),
      pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: <pw.Widget>[
            row('Subtotal', Fils(invoice.subtotalFils).aedText),
            if (invoice.discountFils > 0)
              row('Discount', '-${Fils(invoice.discountFils).aedText}'),
            row('VAT $vatPercent%', Fils(invoice.vatFils).aedText),
            pw.Divider(color: ruleLine, height: 8),
            row('Total', Fils(invoice.totalFils).aedText, bold: true),
            if (invoice.paidFils > 0) ...<pw.Widget>[
              row('Paid', Fils(invoice.paidFils).aedText),
              row(
                'Balance due',
                Fils(balance).aedText,
                bold: true,
                colour: balance > 0 ? const PdfColor.fromInt(0xFFC4552D) : brandPetrol,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

pw.Widget _declaration(CompanyProfile company, InvoiceDocument invoice) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: ruleLine, width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          asciiText(
            'VAT invoice issued under the VAT legislation of the United Arab Emirates. '
            'Supplier TRN ${company.trn}.',
          ),
          style: const pw.TextStyle(fontSize: 8, color: muted),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          asciiText(
            'Goods remain the property of ${company.name} until paid in full. '
            'Please quote ${invoice.number} with any payment or query.',
          ),
          style: const pw.TextStyle(fontSize: 8, color: muted),
        ),
      ],
    ),
  );
}

String _date(DateTime value) {
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
