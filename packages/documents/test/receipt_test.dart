import 'dart:convert';

import 'package:starparis_documents/starparis_documents.dart';
import 'package:test/test.dart';

/// The receipt is a byte stream, so the test reads the bytes back and asserts
/// on what the printer would actually receive — not on an intermediate model.
void main() {
  final doc = ReceiptDocument(
    shopName: 'Star Paris Graphic',
    branchName: 'Sharjah',
    number: 'QS-SHJ1-PC1-00001',
    issuedAt: DateTime(2026, 11, 4, 14, 30),
    lines: const <ReceiptLine>[
      ReceiptLine(description: 'Colour copy A4', quantity: 2, amountFils: 200),
      ReceiptLine(description: 'Lamination A4', quantity: 1, amountFils: 400),
    ],
    subtotalFils: 600,
    vatFils: 30,
    totalFils: 630,
    paymentMethod: 'cash',
    tenderedFils: 1000,
    thankYou: 'Thank you',
  );

  test('emits the sale, the total and the change', () {
    final bytes = buildReceiptBytes(doc);
    final text = latin1.decode(bytes, allowInvalid: false);

    expect(text, contains('Star Paris Graphic'));
    expect(text, contains('QS-SHJ1-PC1-00001'));
    expect(text, contains('Colour copy A4'));
    expect(text, contains('TOTAL'));
    expect(text, contains('6.30'));
    // 10.00 tendered, 6.30 due -> 3.70 change.
    expect(text, contains('10.00'));
    expect(text, contains('3.70'));
  });

  test('derives the unit price so the arithmetic adds up', () {
    final bytes = buildReceiptBytes(doc);
    final text = latin1.decode(bytes);
    // 2 x 1.00 = 2.00 — the unit is the rounded line amount over quantity.
    expect(text, contains('2 x 1.00'));
    expect(text, contains('2.00'));
  });

  test('is ASCII-only and ends with a cut', () {
    final bytes = buildReceiptBytes(doc);

    // Code page 437 has no font fallback: nothing above printable ASCII.
    expect(bytes.any((byte) => byte > 126), isFalse);

    // GS V 66 0 — the partial-cut command every thermal printer uses.
    const cut = <int>[0x1D, 0x56, 0x42, 0x00];
    final tail = bytes.sublist(bytes.length - 6);
    expect(tail.sublist(0, 4), cut);
  });

  test('sanitises a non-ASCII shop name instead of printing garbage', () {
    final exotic = ReceiptDocument(
      shopName: 'Star—Paris\u2014Graphic', // em-dash and a non-ASCII char
      number: 'QS-SHJ1-PC1-00002',
      issuedAt: DateTime(2026),
      lines: const <ReceiptLine>[],
      subtotalFils: 0,
      vatFils: 0,
      totalFils: 0,
      paymentMethod: 'cash',
    );

    final bytes = buildReceiptBytes(exotic);
    expect(bytes.any((byte) => byte > 126), isFalse);
  });
}
