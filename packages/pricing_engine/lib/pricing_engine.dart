/// Star Paris pricing engine.
///
/// Pure Dart: no Flutter, no database, no network, no clock, no randomness.
/// The same inputs and the same price-book version always produce the same
/// breakdown, on a Windows counter PC, on an Android phone with no signal, and
/// (in a later TypeScript port) on the Worker.
library;

export 'src/engine.dart' show PricingEngine;
export 'src/errors.dart' show PricingException;
export 'src/layout.dart' show SheetFit, SheetSpec, fitOnSheet;
export 'src/models.dart';
export 'src/rules.dart';
export 'src/vector.dart' show PricingVector;
