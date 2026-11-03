/// Writes sample documents to docs/samples/ so a human can open them.
///
///   dart run tool/make_samples.dart
///
/// The numbers are the golden vector: 500 cards at AED 122.00 + 6.10 VAT.
library;

import 'dart:io';

import 'package:starparis_documents/starparis_documents.dart';

const CompanyProfile company = CompanyProfile(
  name: 'Star Paris Graphic LLC',
  trn: '100000000000003',
  address: 'Industrial Area 12, Sharjah, United Arab Emirates',
  phone: '+971 6 000 0000',
  email: 'hello@starparis.example',
  branchName: 'Sharjah — Industrial Area',
);

Future<void> main() async {
  final directory = Directory('../../docs/samples');
  await directory.create(recursive: true);

  final quote = await buildQuotePdf(
    QuoteDocument(
      number: 'QT-SHJ1-PC1-00045',
      issuedAt: DateTime(2026, 11, 3, 10, 30),
      validUntil: DateTime(2026, 11, 10),
      customerName: 'Ahmed Traders',
      customerCompany: 'Ahmed Traders LLC',
      customerPhone: '+971 50 123 4567',
      lines: const <DocumentLine>[
        DocumentLine(
          description: 'Business cards · 500 · 90 × 55 mm · double sided · matt lamination',
          quantity: 500,
          unitFils: 244,
          amountFils: 12200,
        ),
      ],
      subtotalFils: 12200,
      vatFils: 610,
      totalFils: 12810,
      vatBps: 500,
      notes: 'Proof required before printing. Artwork received by WhatsApp.',
    ),
    company,
  );
  await File('${directory.path}/sample-quote.pdf').writeAsBytes(quote);

  final ticket = await buildJobTicketPdf(
    JobTicketDocument(
      number: '10452',
      createdAt: DateTime(2026, 11, 3, 9),
      customerName: 'Ahmed Traders',
      specifications: const <String>[
        'Business cards · 500',
        '90 × 55 mm, 350 gsm art card',
        'Double sided, full colour',
        'Matt lamination both sides',
        'Cut to size, packed in 100s',
      ],
      quantity: 500,
      dueAt: DateTime(2026, 11, 5, 16),
      priority: 'urgent',
      notes: 'Customer approved proof v2 at 09:40.',
    ),
    company,
  );
  await File('${directory.path}/sample-job-ticket.pdf').writeAsBytes(ticket);

  stdout.writeln('quote      ${quote.length} bytes');
  stdout.writeln('job ticket ${ticket.length} bytes');
  stdout.writeln('written to ${directory.absolute.path}');
}
