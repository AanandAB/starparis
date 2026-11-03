import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// What the shop's support actually needs: a short, timestamped trail of what the
/// app was doing when something went wrong.
///
/// Three deliberate choices:
///  * **In memory first.** A crash on a dead network must still be readable, so the
///    ring buffer is the source of truth and the file is a copy.
///  * **Bounded.** 300 lines, oldest dropped: a shop that runs for months does not
///    grow a log that fills the disk of a counter PC.
///  * **Pasted, not uploaded.** There is no telemetry endpoint, so nothing leaves
///    the device unless a person copies it out of Diagnostics.
enum LogLevel { debug, info, warn, error }

class LogEntry {
  LogEntry(this.level, this.message, {this.error, DateTime? at})
    : at = at ?? DateTime.now();

  final LogLevel level;
  final String message;
  final String? error;
  final DateTime at;

  String get line {
    final stamp = at.toIso8601String().substring(11, 19);
    final tag = level.name.toUpperCase().padRight(5);
    return '$stamp $tag $message${error == null ? '' : ' — $error'}';
  }
}

class AppLog {
  AppLog._();

  static const int _capacity = 300;
  static final List<LogEntry> _entries = <LogEntry>[];
  static final StreamController<List<LogEntry>> _updates =
      StreamController<List<LogEntry>>.broadcast();
  static File? _sink;

  static List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);
  static Stream<List<LogEntry>> get updates => _updates.stream;

  /// Called once at start-up. Opens the log file next to the database and
  /// captures framework errors from that moment on.
  static Future<void> start() async {
    try {
      final base = await getApplicationSupportDirectory();
      final directory = Directory(p.join(base.path, 'logs'));
      await directory.create(recursive: true);
      _sink = File(p.join(directory.path, 'app.log'));
    } catch (_) {
      // No writable directory: the ring buffer still works, which is the part
      // that matters when someone is standing at the counter.
    }

    FlutterError.onError = (details) {
      record(
        LogLevel.error,
        'Flutter error: ${details.exceptionAsString()}',
        error: details.informationCollector?.call().join(' · '),
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      record(LogLevel.error, 'Uncaught in the platform', error: '$error');
      return false;
    };
  }

  static void debug(String message) => record(LogLevel.debug, message);
  static void info(String message) => record(LogLevel.info, message);
  static void warn(String message, {Object? error}) =>
      record(LogLevel.warn, message, error: error);
  static void failure(String message, {Object? error}) =>
      record(LogLevel.error, message, error: error);

  static void record(LogLevel level, String message, {Object? error}) {
    final entry = LogEntry(
      level,
      message,
      error: error == null ? null : '$error',
    );
    _entries.add(entry);
    if (_entries.length > _capacity) _entries.removeAt(0);
    _updates.add(entries);
    unawaited(_append(entry));
  }

  /// Appends one line to the file, best effort. A failed write is never allowed
  /// to take the app down, so its own failure is silent by design.
  static Future<void> _append(LogEntry entry) async {
    final sink = _sink;
    if (sink == null) return;
    try {
      await sink.writeAsString(
        '${entry.line}\n',
        mode: FileMode.append,
        flush: false,
      );
    } catch (_) {
      // Deliberately ignored: logging must never be the reason a sale fails.
    }
  }

  /// The last [count] lines as text, for the copy button in Diagnostics.
  static String export({int count = 100}) {
    final start = _entries.length <= count ? 0 : _entries.length - count;
    return <String>[for (final entry in _entries.sublist(start)) entry.line]
        .join('\n');
  }

  /// Test hook: clears the buffer without touching the file.
  @visibleForTesting
  static void clear() {
    _entries.clear();
    _updates.add(entries);
  }
}
