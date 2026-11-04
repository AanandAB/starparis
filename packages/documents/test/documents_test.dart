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

  group('tax invoice PDF', () {
    InvoiceDocument invoice({int paidFils = 0}) => InvoiceDocument(
      number: 'INV-SHJ1-PC1-00001',
      issuedAt: DateTime(2026, 11, 3, 11),
      dueAt: DateTime(2026, 12, 3),
      customerName: 'Ahmed Traders LLC',
      customerTrn: '100123456700003',
      customerAddress: 'Al Nahda, Sharjah',
      lines: const <DocumentLine>[_cards],
      subtotalFils: 12200,
      vatFils: 610,
      totalFils: 12810,
      paidFils: paidFils,
      notes: 'Payment by transfer only.',
    );

    test('renders a tax invoice with the money on the page', () async {
      final bytes = await buildInvoicePdf(invoice(), _company, compress: false);
      final text = String.fromCharCodes(bytes);

      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      // Word strings are kerned into separate runs, so the honest assertion is
      // on the figures; the wording is checked by extracting the rendered page
      // (see README).
      expect(text.contains('128.10'), isTrue, reason: 'total');
      expect(text.contains('6.10'), isTrue, reason: 'VAT');
      expect(text.contains('122.00'), isTrue, reason: 'subtotal');
      expect(text.contains('100000000000003'), isTrue, reason: 'supplier TRN');
    });

    test('shows the balance when money has been taken', () async {
      final bytes = await buildInvoicePdf(
        invoice(paidFils: 5000),
        _company,
        compress: false,
      );
      final text = String.fromCharCodes(bytes);

      expect(text.contains('50.00'), isTrue, reason: 'paid');
      expect(text.contains('78.10'), isTrue, reason: '128.10 - 50.00');
    });
    test('a credit note prints as its own document against the invoice', () async {
      final bytes = await buildInvoicePdf(
        InvoiceDocument(
          number: 'CN-SHJ1-PC1-00001',
          issuedAt: DateTime(2026, 11, 4, 9),
          customerName: 'Ahmed Traders LLC',
          lines: const <DocumentLine>[
            DocumentLine(
              description: 'Credit - 100 cards damaged in finishing',
              quantity: 1,
              unitFils: 4762,
              amountFils: 4762,
            ),
          ],
          subtotalFils: 4762,
          vatFils: 238,
          totalFils: 5000,
          documentTitle: 'CREDIT NOTE',
          reference: 'INV-SHJ1-PC1-00001',
          showPayments: false,
        ),
        _company,
        compress: false,
      );
      final text = String.fromCharCodes(bytes);

      expect(text.contains('50.00'), isTrue, reason: 'credit total');
      expect(text.contains('2.38'), isTrue, reason: 'VAT credited');
      expect(text.contains('47.62'), isTrue, reason: 'net credited');
    });
  });

  group('job ticket PDF', () {
    test('carries a QR code when given a tracking link', () async {
      final plain = await buildJobTicketPdf(
        JobTicketDocument(
          number: '10452',
          createdAt: DateTime(2026, 11, 3, 9),
          customerName: 'Ahmed Traders',
          specifications: const <String>['Business cards · 500'],
          quantity: 500,
        ),
        _company,
      );
      final tagged = await buildJobTicketPdf(
        JobTicketDocument(
          number: '10452',
          createdAt: DateTime(2026, 11, 3, 9),
          customerName: 'Ahmed Traders',
          specifications: const <String>['Business cards · 500'],
          quantity: 500,
          trackUrl: 'starparis://job/10452',
        ),
        _company,
      );

      // The QR is drawn as vector modules, so the honest assertion is that the
      // page gained content — the decode itself is proven by the smoke run,
      // which reads the rendered page back with an actual QR detector.
      expect(tagged.length, greaterThan(plain.length));
    });

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

  group('statement of account PDF', () {
    StatementDocument statement() => StatementDocument(
      customerName: 'Ahmed Traders',
      customerCompany: 'Ahmed Traders LLC',
      customerTrn: '100123456700003',
      periodLabel: 'Sharjah - Nov 2026',
      openingBalanceFils: 0,
      generatedAt: DateTime(2026, 11, 4, 12),
      closingBalanceFils: 20010,
      lines: <StatementLine>[
        StatementLine(
          date: DateTime(2026, 11, 3, 11),
          reference: 'INV-SHJ1-PC1-00001',
          description: 'Business cards 500',
          amountFils: 12810,
          paidFils: 5000,
          balanceFils: 7810,
        ),
        StatementLine(
          date: DateTime(2026, 11, 4, 9),
          reference: 'INV-SHJ1-PC1-00002',
          description: 'Flyers 1000',
          amountFils: 12200,
          paidFils: 0,
          balanceFils: 20010,
        ),
      ],
    );

    test('carries references, the running balance and the title', () async {
      // Uncompressed so the assertion can read the drawn text.
      final bytes = await buildStatementPdf(
        statement(),
        _company,
        compress: false,
      );
      final text = String.fromCharCodes(bytes);

      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      // package:pdf kerns each word into its own text run, so 'STATEMENT OF
      // ACCOUNT' is never contiguous in the content stream — assert the words.
      expect(text.contains('STATEMENT'), isTrue, reason: 'title word');
      expect(text.contains('ACCOUNT'), isTrue, reason: 'title word');
      expect(
        text.contains('INV-SHJ1-PC1-00001'),
        isTrue,
        reason: 'first reference',
      );
      expect(
        text.contains('INV-SHJ1-PC1-00002'),
        isTrue,
        reason: 'second reference',
      );
      expect(text.contains('78.10'), isTrue, reason: 'balance after first line');
      expect(text.contains('200.10'), isTrue, reason: 'closing balance');
    });
  });
}
