import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Thrown when the receipt bytes cannot be delivered to a printer.
class ReceiptPrintException implements Exception {
  final String message;
  const ReceiptPrintException(this.message);

  @override
  String toString() => message;
}

/// Ships a receipt's ESC/POS bytes to a printer.
///
/// The formatter (`buildReceiptBytes` in packages/documents) produces the byte
/// stream; this layer is only the transport, so it can be swapped without
/// touching the layout. [WindowsReceiptPrinter] writes raw bytes to a named
/// Windows printer through winspool; [FileReceiptPrinter] writes the bytes to
/// a file so the whole path is testable with no printer attached (Android's
/// Bluetooth/USB transport will be a third implementation).
abstract class ReceiptPrinter {
  Future<void> printBytes(Uint8List bytes, {String? printerName});

  bool get isAvailable;

  static ReceiptPrinter forPlatform() =>
      Platform.isWindows ? WindowsReceiptPrinter() : FileReceiptPrinter();
}

/// Writes the raw ESC/POS bytes to a Windows printer via winspool, forcing RAW
/// (pass-through) mode so the printer receives the bytes unchanged.
class WindowsReceiptPrinter implements ReceiptPrinter {
  @override
  bool get isAvailable => Platform.isWindows;

  @override
  Future<void> printBytes(Uint8List bytes, {String? printerName}) async {
    final name = (printerName ?? _defaultPrinter())?.trim() ?? '';
    if (name.isEmpty) {
      throw const ReceiptPrintException(
          'No printer: set one in Settings, or make the till printer the '
          'Windows default.');
    }
    _rawPrint(name, bytes);
  }

  void _rawPrint(String name, Uint8List bytes) {
    final arena = Arena();
    try {
      final namePtr = name.toNativeUtf16(allocator: arena);
      final hPrinter = arena<Pointer>();
      final defaults = arena<PRINTER_DEFAULTS>();
      // PRINTER_ACCESS_USE (0x08) is enough to write; win32 has no named
      // constant for it, so the value is spelled out.
      defaults.ref.DesiredAccess = PRINTER_ACCESS_RIGHTS(0x00000008);
      defaults.ref.pDatatype = PWSTR('RAW'.toNativeUtf16(allocator: arena));

      final open = OpenPrinter(PCWSTR(namePtr), hPrinter, defaults);
      if (!open.value) {
        throw ReceiptPrintException(
            'Could not open printer "$name" (error ${open.error}).');
      }
      final printer = PRINTER_HANDLE(hPrinter.value);
      try {
        final doc = arena<DOC_INFO_1>();
        doc.ref.pDocName =
            PWSTR('Star Paris receipt'.toNativeUtf16(allocator: arena));
        doc.ref.pDatatype = PWSTR('RAW'.toNativeUtf16(allocator: arena));

        final jobId = StartDocPrinter(printer, 1, doc);
        if (jobId == 0) {
          throw ReceiptPrintException(
              'StartDocPrinter failed (error ${GetLastError()}).');
        }
        try {
          StartPagePrinter(printer);
          final buf = arena<Uint8>(bytes.length);
          buf.asTypedList(bytes.length).setAll(0, bytes);
          final written = arena<Uint32>();
          if (!WritePrinter(printer, buf.cast(), bytes.length, written)) {
            throw ReceiptPrintException(
                'WritePrinter failed (error ${GetLastError()}).');
          }
          EndPagePrinter(printer);
        } finally {
          EndDocPrinter(printer);
        }
      } finally {
        printer.close();
      }
    } finally {
      arena.releaseAll();
    }
  }

  /// The system default printer name, or null when there is none. Two calls:
  /// first with a null buffer to learn the length, then with a sized buffer.
  String? _defaultPrinter() {
    final arena = Arena();
    try {
      final needed = arena<Uint32>();
      GetDefaultPrinter(null, needed);
      if (needed.value == 0) return null;
      // Utf16 is an Opaque type (not SizedNativeType), so allocate Uint16
      // code units and reinterpret — both are 2 bytes wide.
      final buf = arena<Uint16>(needed.value);
      if (!GetDefaultPrinter(PWSTR(buf.cast()), needed)) return null;
      return PWSTR(buf.cast()).toDartString();
    } finally {
      arena.releaseAll();
    }
  }
}

/// Fallback / test transport: writes the bytes to a `.bin` file. Used on
/// Android (until the Bluetooth/USB transport lands) and whenever there is no
/// printer configured, so a sale can always produce its slip bytes for review.
class FileReceiptPrinter implements ReceiptPrinter {
  final String directory;

  FileReceiptPrinter({String? directory}) : directory = directory ?? 'receipts';

  @override
  bool get isAvailable => true;

  @override
  Future<void> printBytes(Uint8List bytes, {String? printerName}) async {
    final dir = Directory(directory);
    if (!await dir.exists()) await dir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await File('${dir.path}${Platform.pathSeparator}receipt-$stamp.bin')
        .writeAsBytes(bytes, flush: true);
  }
}
