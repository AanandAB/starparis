/// The sheet that travels with the job through the shop.
///
/// Read at arm's length, under a press light, sometimes with wet hands: so the
/// job number is the largest thing on the page, the specification lines are
/// short, and the stage checkboxes are big enough to tick with a marker.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';
import 'style.dart';

Future<Uint8List> buildJobTicketPdf(
  JobTicketDocument ticket,
  CompanyProfile company, {
  bool compress = true,
}) async {
  final document = pw.Document(
    title: '${ticket.isQuote ? 'Quote' : 'Job'} ${ticket.number}',
    author: company.name,
    creator: 'Star Paris',
    compress: compress,
  );

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(22),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _topBand(ticket),
          pw.SizedBox(height: 12),
          _customerRow(ticket),
          pw.SizedBox(height: 10),
          pw.Text('SPECIFICATION', style: _tinyLabel),
          pw.SizedBox(height: 4),
          for (final line in ticket.specifications)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Container(
                    width: 3,
                    height: 3,
                    margin: const pw.EdgeInsets.only(top: 5, right: 6),
                    decoration: const pw.BoxDecoration(color: brandPetrol, shape: pw.BoxShape.circle),
                  ),
                  pw.Expanded(
                    child: pw.Text(asciiText(line), style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 8),
          _quantityBand(ticket),
          if (ticket.notes.trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 10),
            pw.Text('NOTES', style: _tinyLabel),
            pw.SizedBox(height: 3),
            pw.Text(asciiText(ticket.notes.trim()), style: const pw.TextStyle(fontSize: 9)),
          ],
          pw.Spacer(),
          pw.Text('STAGES', style: _tinyLabel),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              for (final stage in <String>['Design', 'Prepress', 'Print', 'Finish', 'QC'])
                _stageBox(stage),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                asciiText('${company.name} | ${company.phone}'),
                style: const pw.TextStyle(fontSize: 7, color: muted),
              ),
              pw.Text(
                ticket.isQuote ? 'QUOTATION COPY' : 'Job ticket',
                style: const pw.TextStyle(fontSize: 7, color: muted),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return document.save();
}

const pw.TextStyle _tinyLabel = pw.TextStyle(
  fontSize: 7,
  color: muted,
  letterSpacing: 1.2,
);

pw.Widget _topBand(JobTicketDocument ticket) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: const pw.BoxDecoration(color: brandPetrol),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              ticket.isQuote ? 'QUOTE' : 'JOB',
              style: const pw.TextStyle(fontSize: 8, color: brandSand, letterSpacing: 2),
            ),
            pw.Text(
              asciiText(ticket.number),
              style: const pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(
              'DUE',
              style: const pw.TextStyle(fontSize: 7, color: brandSand, letterSpacing: 1.5),
            ),
            pw.Text(
              ticket.dueAt == null ? '-' : _date(ticket.dueAt!),
              style: const pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            if (ticket.priority != 'normal')
              pw.Text(
                ticket.priority.toUpperCase(),
                style: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _customerRow(JobTicketDocument ticket) {
  return pw.Row(
    children: <pw.Widget>[
      pw.Expanded(
        flex: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text('CUSTOMER', style: _tinyLabel),
            pw.Text(
              asciiText(ticket.customerName),
              style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
      pw.Expanded(
        flex: 2,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text('RECEIVED', style: _tinyLabel),
            pw.Text(_date(ticket.createdAt), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _quantityBand(JobTicketDocument ticket) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFFF7F4EE),
      border: pw.Border.all(color: ruleLine, width: 0.5),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text('QUANTITY', style: _tinyLabel),
        pw.Text(
          '${ticket.quantity}',
          style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

pw.Widget _stageBox(String label) {
  return pw.Column(
    children: <pw.Widget>[
      pw.Container(
        width: 14,
        height: 14,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: ink, width: 0.8)),
      ),
      pw.SizedBox(height: 3),
      pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
    ],
  );
}

String _date(DateTime value) {
  final local = value.toLocal();
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
