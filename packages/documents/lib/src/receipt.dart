import 'dart:typed_data';

import 'models.dart';

/// An 80 mm (or 58 mm) thermal receipt as ESC/POS bytes.
///
/// Pure Dart on purpose: this produces the byte stream a thermal printer
/// consumes, with no Flutter engine and no printer driver. The transport — a
/// raw spooler write on Windows, ESC/POS over Bluetooth or USB on Android — is
/// a separate layer that ships the same bytes, so it can be built and tested
/// independently of any hardware.
///
/// The stream is ASCII (code page 437): every text value is sanitised, because
/// a thermal printer has no font fallback and a stray em-dash in a customer
/// name would otherwise print as garbage.
const int _esc = 0x1B;
const int _gs = 0x1D;

/// The default line width in characters. 42 fits an 80 mm printer at the
/// common 12x24 font; pass 32 for a 58 mm printer.
const int defaultReceiptWidth = 42;

Uint8List buildReceiptBytes(
  ReceiptDocument doc, {
  int width = defaultReceiptWidth,
}) {
  final out = BytesBuilder();

  void raw(List<int> bytes) => out.add(bytes);
  void text(String value) => raw(_ascii(value).codeUnits);
  void line([String value = '']) {
    text(value);
    raw(const [10]); // LF
  }

  void centered(String value) {
    raw(const [_esc, 0x61, 0x01]); // ESC a 1 = centre
    line(value);
    raw(const [_esc, 0x61, 0x00]); // ESC a 0 = left
  }

  void bold(String value) {
    raw(const [_esc, 0x45, 0x01]); // ESC E 1 = bold on
    line(value);
    raw(const [_esc, 0x45, 0x00]); // ESC E 0 = bold off
  }

  String separator() => '-' * width;
  String padTwo(String left, String right) {
    final gap = width - left.length - right.length;
    if (gap < 1) return _clip('$left$right', width);
    return left + (' ' * gap) + right;
  }

  // --- Header ---------------------------------------------------------------
  raw(const [_esc, 0x40]); // ESC @ = initialise
  raw(const [_gs, 0x21, 0x11]); // double width + height for the shop name
  centered(_clip(doc.shopName, width ~/ 2));
  raw(const [_gs, 0x21, 0x00]); // back to single
  if (doc.branchName != null && doc.branchName!.isNotEmpty) {
    centered(doc.branchName!);
  }
  if (doc.address != null && doc.address!.isNotEmpty) {
    centered(doc.address!);
  }
  if (doc.phone != null && doc.phone!.isNotEmpty) {
    centered(doc.phone!);
  }
  line(separator());

  // --- The sale -------------------------------------------------------------
  bold(doc.number);
  line('Date ${_stamp(doc.issuedAt)}');
  line(separator());

  for (final item in doc.lines) {
    line(_clip(item.description, width));
    line(
      padTwo(
        '  ${item.quantity} x ${_aed(_unit(item))}',
        _aed(item.amountFils),
      ),
    );
  }
  line(separator());

  line(padTwo('Subtotal', _aed(doc.subtotalFils)));
  line(padTwo('VAT', _aed(doc.vatFils)));
  bold(padTwo('TOTAL', _aed(doc.totalFils)));

  // --- Payment --------------------------------------------------------------
  final method = switch (doc.paymentMethod) {
    'card' => 'Card',
    'transfer' => 'Bank transfer',
    _ => 'Cash',
  };
  line(padTwo(method, _aed(doc.totalFils)));
  if (doc.tenderedFils != null) {
    final change = doc.tenderedFils! - doc.totalFils;
    line(padTwo('Tendered', _aed(doc.tenderedFils!)));
    line(padTwo('Change', _aed(change < 0 ? 0 : change)));
  }
  line(separator());

  centered(doc.thankYou);

  // --- Cut ------------------------------------------------------------------
  raw(const [_gs, 0x56, 0x42, 0x00]); // GS V 66 0 = partial cut
  raw(const [10, 10]);

  return out.toBytes();
}

/// Unit price shown next to the quantity, derived the same way the invoice
/// does: the rounded line amount over the quantity, so the printed arithmetic
/// always adds up even when a discount was applied per line.
int _unit(ReceiptLine item) {
  if (item.quantity <= 0) return item.amountFils;
  return (item.amountFils / item.quantity).round();
}

String _aed(int fils) {
  final negative = fils < 0;
  final magnitude = fils.abs();
  final whole = magnitude ~/ 100;
  final cents = (magnitude % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$whole.$cents';
}

String _stamp(DateTime at) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} '
      '${two(at.hour)}:${two(at.minute)}';
}

/// Code page 437 has no font fallback: strip to printable ASCII and collapse
/// the rest to a space so a long name does not turn into a run of question
/// marks.
String _ascii(String value) {
  final buffer = StringBuffer();
  for (final code in value.runes) {
    if (code >= 32 && code <= 126) {
      buffer.writeCharCode(code);
    } else {
      buffer.write(' ');
    }
  }
  return buffer.toString();
}

String _clip(String value, int width) =>
    value.length <= width ? value : value.substring(0, width);
