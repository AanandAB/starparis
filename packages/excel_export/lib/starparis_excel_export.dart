/// Offline Excel export for Star Paris: real `.xlsx` files from tabular data.
///
/// Pure Dart on top of `package:archive`, so a workbook can be generated in an
/// isolate, in a test, or on a server without a Flutter engine. The app wraps
/// `exportXlsx` and decides where the bytes go.
library;

export 'src/xlsx.dart';
