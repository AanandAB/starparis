// Writes a sample 80 mm receipt to docs/samples/receipt_sample.bin.
//
// Run from packages/documents:
//     dart run tool/receipt_sample.dart
//
// Open the .bin with a hex editor or pipe it straight to a thermal printer to
// see the layout. The bytes are ESC/POS; there is nothing Flutter-specific.

import 'dart:io';

import 'package:starparis_documents/starparis_documents.dart';

void main() {
  final doc = ReceiptDocument(
    shopName: 'Star Paris Graphic',
    branchName: 'Industrial Area 12, Sharjah',
    address: '+971 6 000 0000',
    number: 'QS-SHJ1-PC1-00042',
    issuedAt: DateTime.now(),
    lines: const <ReceiptLine>[
      ReceiptLine(description: 'Colour copy A4', quantity: 2, amountFils: 200),
      ReceiptLine(description: 'Lamination A4', quantity: 1, amountFils: 400),
      ReceiptLine(
        description: 'Binding (spiral)',
        quantity: 1,
        amountFils: 350,
      ),
    ],
    subtotalFils: 950,
    vatFils: 48,
    totalFils: 998,
    paymentMethod: 'cash',
    tenderedFils: 1000,
  );

  final bytes = buildReceiptBytes(doc);
  final output = File('../../docs/samples/receipt_sample.bin');
  output.writeAsBytesSync(bytes);
  stdout.writeln('wrote ${bytes.length} bytes to ${output.path}');
}
