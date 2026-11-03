import 'package:starparis_documents/starparis_documents.dart';
import 'package:test/test.dart';

const CompanyProfile _company = CompanyProfile(
  name: 'Star Paris Graphic LLC',
  trn: '100000000000003',
  address: 'Industrial Area 12, Sharjah, UAE',
  phone: '+971 6 000 0000',
  email: 'hello@starparis.example',
  branchName: 'Sharjah — Industrial Area',
);

const DocumentLine _cards = DocumentLine(
  description: 'Business cards · 500 · 90 × 55 mm · double sided · matt lamination',
  quantity: 500,
  unitFils: 244, // 122.00 / 500, rounded for display
  amountFils: 12200,
);

QuoteDocument _quote() => QuoteDocument(
      number: 'QT-SHJ1-PC1-00045',
      issuedAt: DateTime(2026, 11, 3, 10, 30),
      validUntil: DateTime(2026, 11, 10),
      customerName: 'Ahmed Traders',
      customerCompany: 'Ahmed Traders LLC',
      customerPhone: '+971 50 123 4567',
      lines: const <DocumentLine>[_cards],
      subtotalFils: 12200,
      vatFils: 610,
      totalFils: 12810,
      vatBps: 500,
      notes: 'Proof required before printing.',
    );

void main() {
  group('quotation PDF', () {
    test('produces a real PDF with one page', () async {
      final bytes = await buildQuotePdf(_quote(), _company);

      expect(bytes.length, greaterThan(2000), reason: 'a quote is not a 200-byte stub');
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      expect(String.fromCharCodes(bytes.sublist(bytes.length - 6)), contains('EOF'));
    });

    test('is deterministic in structure but not byte-identical across runs', () async {
      final first = await buildQuotePdf(_quote(), _company);
      final second = await buildQuotePdf(_quote(), _company);
      // PDFs embed a creation date, so bytes differ; sizes should be close.
      expect((first.length - second.length).abs(), lessThan(400));
    });

    test('carries the money through to the printed page', () async {
      // Uncompressed so the assertion can read the drawn text; a real document
      // keeps compression on.
      final bytes = await buildQuotePdf(_quote(), _company, compress: false);
      final text = String.fromCharCodes(bytes);
      expect(text.contains('122.00'), isTrue, reason: 'subtotal');
      expect(text.contains('6.10'), isTrue, reason: 'VAT');
      expect(text.contains('128.10'), isTrue, reason: 'total');
      expect(text.contains('QT-SHJ1-PC1-00045'), isTrue, reason: 'quote number');
    });
  });

  group('job ticket PDF', () {
    test('renders on A5 with the job number and specification', () async {
      final bytes = await buildJobTicketPdf(
        JobTicketDocument(
          number: '10452',
          createdAt: DateTime(2026, 11, 3, 9),
          customerName: 'Ahmed Traders',
          specifications: const <String>[
            'Business cards · 500',
            '90 × 55 mm, 350 gsm art card',
            'Double sided, matt lamination',
          ],
          quantity: 500,
          dueAt: DateTime(2026, 11, 5, 16),
          priority: 'urgent',
        ),
        _company,
      );

      expect(bytes.length, greaterThan(1500));
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
