/// How many pieces fit on a press sheet, and how many sheets to charge for.
///
/// This is the part of the engine that decides whether a quote makes money.
/// A one-millimetre error in the bleed allowance can change a 21-up card layout
/// into a 20-up one, which is a 5% material loss on every job of that product.
/// So the arithmetic here is integer-only, explicit, and covered by tests
/// against the shop's real sheet sizes.
library;

import 'errors.dart';

/// A press sheet: SRA3, SRA2, a roll width, whatever the shop actually loads.
final class SheetSpec {
  const SheetSpec({
    required this.widthMm,
    required this.heightMm,
    this.bleedMm = 3,
    this.gutterMm = 3,
    this.label = '',
  });

  final int widthMm;
  final int heightMm;

  /// Trim bleed added to each side of a piece (3 mm is the GCC norm).
  final int bleedMm;

  /// Space between pieces so the guillotine has something to cut through.
  final int gutterMm;

  final String label;

  /// Printable area of one sheet in square millimetres.
  int get areaSqMm => widthMm * heightMm;

  factory SheetSpec.fromJson(Map<String, Object?> json) => SheetSpec(
    widthMm: (json['width_mm']! as num).toInt(),
    heightMm: (json['height_mm']! as num).toInt(),
    bleedMm: ((json['bleed_mm'] as num?) ?? 3).toInt(),
    gutterMm: ((json['gutter_mm'] as num?) ?? 3).toInt(),
    label: (json['label'] as String?) ?? '',
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'width_mm': widthMm,
    'height_mm': heightMm,
    'bleed_mm': bleedMm,
    'gutter_mm': gutterMm,
    if (label.isNotEmpty) 'label': label,
  };
}

/// The result of fitting one finished size onto one sheet size.
final class SheetFit {
  const SheetFit({
    required this.piecesPerSheet,
    required this.piecesAcross,
    required this.piecesDown,
    required this.isRotated,
    required this.trimSheets,
    required this.setupSheets,
    required this.spoilageSheets,
  });

  /// How many finished pieces come off one printed sheet.
  final int piecesPerSheet;
  final int piecesAcross;
  final int piecesDown;

  /// True when the piece had to be turned 90° to fit better — the operator
  /// needs to know, because the grain direction changes.
  final bool isRotated;

  /// Sheets needed for the ordered quantity alone.
  final int trimSheets;

  /// Make-ready sheets: plate setup, colour draw-down, first-off checks.
  final int setupSheets;

  /// Sheets lost to spoilage (mis-register, jam, knife marks).
  final int spoilageSheets;

  /// Everything the job is charged for: trim + setup + spoilage.
  int get billableSheets => trimSheets + setupSheets + spoilageSheets;

  int get wasteSheets => setupSheets + spoilageSheets;

  /// Pieces actually produced, before spoilage is deducted.
  int get producedPieces => trimSheets * piecesPerSheet;

  Map<String, Object?> toJson() => <String, Object?>{
    'pieces_per_sheet': piecesPerSheet,
    'pieces_across': piecesAcross,
    'pieces_down': piecesDown,
    'is_rotated': isRotated,
    'trim_sheets': trimSheets,
    'setup_sheets': setupSheets,
    'spoilage_sheets': spoilageSheets,
    'billable_sheets': billableSheets,
  };
}

/// Fits a finished size onto a sheet and returns the sheet count to charge for.
///
/// [spoilageBps] is the spoilage allowance in basis points applied to the trim
/// sheets (500 bps = 5%), rounded up: you cannot lose half a sheet.
SheetFit fitOnSheet({
  required int pieceWidthMm,
  required int pieceHeightMm,
  required SheetSpec sheet,
  required int quantity,
  int setupSheets = 2,
  int spoilageBps = 500,
}) {
  if (pieceWidthMm <= 0 || pieceHeightMm <= 0) {
    throw const PricingException(
      'SIZE_INVALID',
      'Finished size must be greater than zero on both sides.',
    );
  }
  if (quantity <= 0) {
    throw const PricingException(
      'QUANTITY_INVALID',
      'Quantity must be greater than zero.',
    );
  }
  if (setupSheets < 0 || spoilageBps < 0) {
    throw const PricingException(
      'SETTINGS_INVALID',
      'Setup sheets and spoilage cannot be negative.',
    );
  }

  // Add the bleed to the piece, then pack with gutters between pieces.
  final pieceW = pieceWidthMm + sheet.bleedMm * 2;
  final pieceH = pieceHeightMm + sheet.bleedMm * 2;

  final upright = _pack(
    sheet.widthMm,
    sheet.heightMm,
    pieceW,
    pieceH,
    sheet.gutterMm,
  );
  final rotated = _pack(
    sheet.widthMm,
    sheet.heightMm,
    pieceH,
    pieceW,
    sheet.gutterMm,
  );

  final useRotated = rotated.$1 > upright.$1;
  final width = useRotated ? pieceH : pieceW;
  final height = useRotated ? pieceW : pieceH;
  final packed = useRotated ? rotated : upright;

  if (packed.$1 == 0) {
    throw PricingException(
      'SIZE_DOES_NOT_FIT',
      'A $pieceWidthMm×$pieceHeightMm mm piece does not fit on a '
          '${sheet.widthMm}×${sheet.heightMm} mm sheet'
          '${sheet.label.isEmpty ? '' : ' (${sheet.label})'}.',
    );
  }

  // Recompute across/down for the orientation actually chosen, so the operator
  // instructions are not silently swapped.
  final across = (sheet.widthMm + sheet.gutterMm) ~/ (width + sheet.gutterMm);
  final down = (sheet.heightMm + sheet.gutterMm) ~/ (height + sheet.gutterMm);
  final perSheet = across * down;

  final trimSheets = _ceilDiv(quantity, perSheet);
  final spoilage = _ceilDiv(trimSheets * spoilageBps, 10000);

  return SheetFit(
    piecesPerSheet: perSheet,
    piecesAcross: across,
    piecesDown: down,
    isRotated: useRotated,
    trimSheets: trimSheets,
    setupSheets: setupSheets,
    spoilageSheets: spoilage,
  );
}

/// (count, across, down) for one orientation.
(int, int, int) _pack(
  int sheetW,
  int sheetH,
  int pieceW,
  int pieceH,
  int gutter,
) {
  final across = (sheetW + gutter) ~/ (pieceW + gutter);
  final down = (sheetH + gutter) ~/ (pieceH + gutter);
  return (across * down, across, down);
}

int _ceilDiv(int value, int divisor) => (value + divisor - 1) ~/ divisor;
