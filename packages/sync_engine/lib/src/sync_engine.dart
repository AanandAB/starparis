/// The sync loop.
///
/// Order matters and is not negotiable: push first, then pull. A device that
/// pulls before it pushes would overwrite its own unsent work with the
/// server's older copy.
///
/// Failure policy: nothing is ever discarded. A rejected mutation stays in the
/// outbox with its error until a human resolves it, and the UI shows "Needs
/// attention" rather than a lie about being synced.
library;

import 'dart:async';

import 'api.dart';
import 'database.dart';

enum SyncPhase {
  /// Never synced yet, or the app just started.
  idle,

  syncing,

  /// Everything on the device has reached the server.
  synced,

  /// No connection. Work is safe locally.
  offline,

  /// The server received changes but refused some of them. A human must look.
  attention,
}

class SyncState {
  const SyncState({
    required this.phase,
    required this.pending,
    this.lastSync,
    this.message,
  });

  final SyncPhase phase;
  final int pending;
  final DateTime? lastSync;
  final String? message;

  SyncState copyWith({
    SyncPhase? phase,
    int? pending,
    DateTime? lastSync,
    String? message,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      pending: pending ?? this.pending,
      lastSync: lastSync ?? this.lastSync,
      message: message ?? this.message,
    );
  }

  @override
  String toString() => 'SyncState(${phase.name}, pending: $pending)';
}

class SyncEngine {
  SyncEngine({
    required this.db,
    required this.api,
    this.pageSize = 200,
    this.maxPagesPerRun = 10,
  });

  final LocalDatabase db;
  final SyncApi api;
  final int pageSize;
  final int maxPagesPerRun;

  final StreamController<SyncState> _states =
      StreamController<SyncState>.broadcast();

  Timer? _timer;
  bool _running = false;
  SyncState _current = const SyncState(phase: SyncPhase.idle, pending: 0);

  Stream<SyncState> get states => _states.stream;
  SyncState get current => _current;

  /// Polling cadence: 30 seconds in the foreground on Android, 15 on Windows is
  /// the design target. The caller owns the timer interval so the app can slow
  /// it down when the window is in the background.
  void start({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(syncNow()));
    unawaited(syncNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    final pending = await db.pendingCount();
    _emit(
      _current.copyWith(
        phase: SyncPhase.syncing,
        pending: pending,
        message: null,
      ),
    );

    try {
      await _push();
      await _pull();
      final remaining = await db.pendingCount();
      _emit(
        SyncState(
          phase: remaining == 0 ? SyncPhase.synced : SyncPhase.attention,
          pending: remaining,
          lastSync: DateTime.now(),
          message: remaining == 0
              ? null
              : 'Some changes were refused by the server.',
        ),
      );
    } on SyncException catch (error) {
      final remaining = await db.pendingCount();
      _emit(
        SyncState(
          phase: error.code == 'OFFLINE' || error.code == 'UNAUTHORIZED'
              ? SyncPhase.offline
              : SyncPhase.attention,
          pending: remaining,
          lastSync: _current.lastSync,
          message: error.message,
        ),
      );
      if (error.isUnauthorized) {
        rethrow;
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _push() async {
    final batch = await db.nextBatch(limit: 100);
    if (batch.isEmpty) return;

    final result = await api.push(mutations: batch);

    final applied = <String>[];
    for (final outcome in result.outcomes) {
      if (outcome.isAccepted) {
        if (outcome.row != null) {
          final mutation = batch.firstWhere(
            (candidate) => candidate.mutationId == outcome.mutationId,
            orElse: () => batch.first,
          );
          await db.applyServerRow(mutation.entity, outcome.row!);
        }
        applied.add(outcome.mutationId);
        continue;
      }
      if (outcome.isRejected) {
        await db.recordFailure(
          outcome.mutationId,
          '${outcome.errorCode ?? 'REJECTED'}: ${outcome.errorMessage ?? ''}'
              .trim(),
        );
        // A version conflict is not fatal: the next pull brings the server's
        // row, and the engineer re-applies the edit on top of it. For now the
        // mutation stays queued and visible.
      }
    }
    await db.markApplied(applied);
  }

  Future<void> _pull() async {
    var cursor = await db.cursor();
    for (var page = 0; page < maxPagesPerRun; page++) {
      final result = await api.pull(since: cursor, limit: pageSize);
      if (result.rows.isEmpty) {
        await db.setMeta('head', '${result.head}');
        return;
      }
      for (final row in result.rows) {
        await db.applyServerRow(row.entity, row.data);
      }
      cursor = result.nextCursor;
      await db.setCursor(cursor);
      await db.setMeta('head', '${result.head}');
      if (result.rows.length < pageSize) return;
    }
  }

  void _emit(SyncState state) {
    _current = state;
    if (!_states.isClosed) {
      _states.add(state);
    }
  }

  Future<void> dispose() async {
    stop();
    await _states.close();
  }
}
