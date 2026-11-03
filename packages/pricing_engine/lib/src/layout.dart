/// How many pieces fit on a press sheet, and how many sheets to charge for.
///
/// This is the part of the engine that decides whether a quote makes money.
/// A one-millimetre error in the bleed allowance can change a 21-up card layout
/// into a 20-up one, which is a 5% material loss on every job of that product.
/// So the arithmetic here is integer-only, explicit, and covered by tests
/// against the shop's real sheet sizes.
library;

import 'errors.dart';

/// Which way the paper's fibres run.
///
/// The trade cares because paper folds and tears along the grain: a card cut
/// across it snaps, a cover folded across it cracks down the spine. A product
/// can therefore demand a direction, and the stock can only offer one.
enum GrainDirection {
  /// Fibres run along the sheet's shorter edge.
  short('short'),

  /// Fibres run along the sheet's longer edge.
  long('long');

  const GrainDirection(this.wire);

  final String wire;

  static GrainDirection fromWire(String wire) => values.firstWhere(
    (value) => value.wire == wire,
    orElse: () =>
        throw ArgumentError.value(wire, 'wire', 'unknown GrainDirection'),
  );
}

/// A press sheet: SRA3, SRA2, a roll width, whatever the shop actually loads.
final class SheetSpec {
  const SheetSpec({
    required this.widthMm,
    required this.heightMm,
    this.bleedMm = 3,
    this.gutterMm = 3,
    this.label = '',
    this.grain,
    this.gripperMm = 0,
    this.trimMm = 0,
  });

  final int widthMm;
  final int heightMm;

  /// Trim bleed added to each side of a piece (3 mm is the GCC norm).
  final int bleedMm;

  /// Space between pieces so the guillotine has something to cut through.
  final int gutterMm;

  final String label;

  /// Which way this stock's fibres run. Null when the shop has not recorded
  /// it, and then no grain logic runs at all: an unrecorded grain is not the
  /// same thing as a conflicting one.
  final GrainDirection? grain;

  /// The band along the leading edge that the press's grippers hold, so the
  /// press cannot print there. Taken off one edge only.
  final int gripperMm;

  /// Clean margin the guillotine needs on every edge of the sheet.
  final int trimMm;

  /// Area of one sheet in square millimetres.
  int get areaSqMm => widthMm * heightMm;

  /// Width the press can actually put ink on: the trim margin comes off both
  /// side edges.
  int get printableWidthMm => widthMm - trimMm * 2;

  /// Height the press can actually put ink on. The sheet is fed short edge
  /// first, so the gripper band comes off the height on top of the trim.
  int get printableHeightMm => heightMm - trimMm * 2 - gripperMm;

  /// True when the long edge of this sheet is the horizontal one, which is
  /// what decides whether "long grain" runs across or down the sheet.
  bool get isLandscape => widthMm >= heightMm;

  factory SheetSpec.fromJson(Map<String, Object?> json) => SheetSpec(
    widthMm: (json['width_mm']! as num).toInt(),
    heightMm: (json['height_mm']! as num).toInt(),
    bleedMm: ((json['bleed_mm'] as num?) ?? 3).toInt(),
    gutterMm: ((json['gutter_mm'] as num?) ?? 3).toInt(),
    label: (json['label'] as String?) ?? '',
    grain: json['grain'] == null
        ? null
        : GrainDirection.fromWire(json['grain']! as String),
    gripperMm: ((json['gripper_mm'] as num?) ?? 0).toInt(),
    trimMm: ((json['trim_mm'] as num?) ?? 0).toInt(),
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'width_mm': widthMm,
    'height_mm': heightMm,
    'bleed_mm': bleedMm,
    'gutter_mm': gutterMm,
    if (label.isNotEmpty) 'label': label,
    if (grain != null) 'grain': grain!.wire,
    if (gripperMm != 0) 'gripper_mm': gripperMm,
    if (trimMm != 0) 'trim_mm': trimMm,
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
    this.isGrainCompromised = false,
    this.grainWasteSheets = 0,
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

  /// True when the stock's grain and the product's grain disagree in both
  /// orientations, so the job has to run across the grain.
  final bool isGrainCompromised;

  /// Extra sheets allowed for running across the grain, rounded up.
  ///
  /// Deliberately *not* part of [billableSheets]: the engine bills these on
  /// their own breakdown line at the stock's own price, and folding them into
  /// the sheet count as well would charge for them twice.
  final int grainWasteSheets;

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
    if (isGrainCompromised) 'grain_compromised': true,
    if (grainWasteSheets != 0) 'grain_waste_sheets': grainWasteSheets,
  };
}

/// Fits a finished size onto a sheet and returns the sheet count to charge for.
///
/// [spoilageBps] is the spoilage allowance in basis points applied to the trim
/// sheets (500 bps = 5%), rounded up: you cannot lose half a sheet.
///
/// [requiredGrain] is what the product asks for, and it is only compared with
/// [SheetSpec.grain] when the shop has recorded the stock's direction. When
/// the two disagree the piece is turned first — turning it is free — and only
/// when that still does not line the fibres up does the job run across the
/// grain and pay [grainWasteBps] of its sheets in waste.
SheetFit fitOnSheet({
  required int pieceWidthMm,
  required int pieceHeightMm,
  required SheetSpec sheet,
  required int quantity,
  int setupSheets = 2,
  int spoilageBps = 500,
  GrainDirection? requiredGrain,
  int grainWasteBps = 0,
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
  if (setupSheets < 0 || spoilageBps < 0 || grainWasteBps < 0) {
    throw const PricingException(
      'SETTINGS_INVALID',
      'Setup sheets, spoilage and grain waste cannot be negative.',
    );
  }
  if (sheet.gripperMm < 0 || sheet.trimMm < 0) {
    throw const PricingException(
      'SETTINGS_INVALID',
      'Gripper and trim allowances cannot be negative.',
    );
  }

  // Add the bleed to the piece, then pack with gutters between pieces.
  final pieceW = pieceWidthMm + sheet.bleedMm * 2;
  final pieceH = pieceHeightMm + sheet.bleedMm * 2;

  // Pack into the printable area, never the bare sheet: a piece laid over the
  // gripper band or the trim margin is a piece that has to be reprinted.
  final printableW = sheet.printableWidthMm;
  final printableH = sheet.printableHeightMm;

  final upright = _pack(
    printableW,
    printableH,
    pieceW,
    pieceH,
    sheet.gutterMm,
  );
  final rotated = _pack(
    printableW,
    printableH,
    pieceH,
    pieceW,
    sheet.gutterMm,
  );

  // Grain decides the orientation whenever it can, because a job run across
  // the grain comes back as a complaint. Fitting more pieces only decides when
  // both orientations run the same way — or when neither runs the right way.
  final wantsGrain = sheet.grain != null && requiredGrain != null;
  final uprightFollowsGrain =
      !wantsGrain ||
      _grainMatches(
        sheet: sheet,
        required: requiredGrain,
        placedW: pieceW,
        placedH: pieceH,
      );
  final rotatedFollowsGrain =
      !wantsGrain ||
      _grainMatches(
        sheet: sheet,
        required: requiredGrain,
        placedW: pieceH,
        placedH: pieceW,
      );

  var useRotated = rotated.$1 > upright.$1;
  if (uprightFollowsGrain && !rotatedFollowsGrain && upright.$1 > 0) {
    useRotated = false;
  }
  if (rotatedFollowsGrain && !uprightFollowsGrain && rotated.$1 > 0) {
    useRotated = true;
  }

  final width = useRotated ? pieceH : pieceW;
  final height = useRotated ? pieceW : pieceH;
  final packed = useRotated ? rotated : upright;

  if (packed.$1 == 0) {
    if (printableW <= 0 || printableH <= 0) {
      throw PricingException(
        'SIZE_DOES_NOT_FIT',
        'A ${sheet.gripperMm} mm gripper and ${sheet.trimMm} mm trim leave '
            'no printable area on a ${sheet.widthMm}×${sheet.heightMm} mm '
            'sheet${sheet.label.isEmpty ? '' : ' (${sheet.label})'}.',
      );
    }
    throw PricingException(
      'SIZE_DOES_NOT_FIT',
      'A $pieceWidthMm×$pieceHeightMm mm piece does not fit on a '
          '${sheet.widthMm}×${sheet.heightMm} mm sheet'
          '${sheet.label.isEmpty ? '' : ' (${sheet.label})'}.',
    );
  }

  // Recompute across/down for the orientation actually chosen, so the operator
  // instructions are not silently swapped.
  final across = (printableW + sheet.gutterMm) ~/ (width + sheet.gutterMm);
  final down = (printableH + sheet.gutterMm) ~/ (height + sheet.gutterMm);
  final perSheet = across * down;

  final trimSheets = _ceilDiv(quantity, perSheet);
  final spoilage = _ceilDiv(trimSheets * spoilageBps, 10000);
  final billable = trimSheets + setupSheets + spoilage;

  // Running across the grain costs stock at the guillotine and the folder, so
  // the allowance is a percentage of the sheets the job consumes rather than a
  // fixed number: a long run loses proportionally more.
  final compromised =
      wantsGrain &&
      (useRotated ? !rotatedFollowsGrain : !uprightFollowsGrain);
  final grainWaste = compromised
      ? _ceilDiv(billable * grainWasteBps, 10000)
      : 0;

  return SheetFit(
    piecesPerSheet: perSheet,
    piecesAcross: across,
    piecesDown: down,
    isRotated: useRotated,
    trimSheets: trimSheets,
    setupSheets: setupSheets,
    spoilageSheets: spoilage,
    isGrainCompromised: compromised,
    grainWasteSheets: grainWaste,
  );
}

/// True when a piece placed [placedW] × [placedH] on [sheet] has its fibres
/// running the way [required] asks for.
///
/// The stock's fibres run along one axis of the sheet — its long edge or its
/// short one — and the product asks for the grain along either its own long
/// side or its own short side. Either the two line up or they do not.
bool _grainMatches({
  required SheetSpec sheet,
  required GrainDirection required,
  required int placedW,
  required int placedH,
}) {
  final grainRunsAlongWidth = sheet.grain == GrainDirection.long
      ? sheet.isLandscape
      : !sheet.isLandscape;
  final pieceLongSideRunsAlongWidth = placedW >= placedH;
  final wanted = required == GrainDirection.long
      ? grainRunsAlongWidth
      : !grainRunsAlongWidth;
  return pieceLongSideRunsAlongWidth == wanted;
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
