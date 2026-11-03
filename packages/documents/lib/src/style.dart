import 'package:pdf/pdf.dart';
import 'package:starparis_domain/starparis_domain.dart';

/// Unit price for one line, computed from the line amount so the printed
/// numbers reconcile: 2 decimals when the division is exact, 3 when a print
/// unit is a fraction of a fils (AED 122.00 for 500 cards is 0.244 each).
String unitPriceText(int amountFils, int quantity) {
  if (quantity <= 0) return Fils(amountFils).aedText;
  final exactFils = amountFils / quantity;
  final rounded = (exactFils * 100).round();
  if (rounded * quantity == amountFils) return Fils(rounded).aedText;
  return (exactFils / 100).toStringAsFixed(3);
}

/// Shared document styling. Colours match the app's brand tokens, duplicated as
/// integers because this package must not depend on Flutter's `Color`.
const PdfColor brandPetrol = PdfColor.fromInt(0xFF0E3B43);
const PdfColor brandSand = PdfColor.fromInt(0xFFD9C7A7);
const PdfColor ink = PdfColor.fromInt(0xFF1A2023);
const PdfColor muted = PdfColor.fromInt(0xFF6B7280);
const PdfColor ruleLine = PdfColor.fromInt(0xFFD8D3C8);

/// The built-in PDF fonts are WinAnsi, not Unicode, so typographic punctuation
/// renders as a blank box or logs a warning. Transliterate the handful of
/// characters shop data actually contains, and leave Arabic to the shaping
/// decision (PLAN.md ADR-009) rather than silently printing broken glyphs.
String asciiText(String value) {
  if (value.isEmpty) return value;
  return value
      .replaceAll('\u00D7', 'x') // ×
      .replaceAll('\u2014', '-') // em dash
      .replaceAll('\u2013', '-') // en dash
      .replaceAll('\u2019', "'") // right single quote
      .replaceAll('\u2018', "'") // left single quote
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"')
      .replaceAll('\u2026', '...')
      .replaceAll('\u00B7', '|') // middle dot
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[^\x20-\x7E\n]'), '');
}
