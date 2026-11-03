import 'dart:io';

import 'package:starparis_sync/starparis_sync.dart';

import 'app_config.dart';
import 'auth/auth_repository.dart';
import 'auth/session.dart';
import 'db/open_database.dart';

/// Everything the app needs before the first frame: secure storage, the
/// encrypted database, and — if a session exists — a running sync loop.
///
/// Built once in `main()` and injected through a ProviderScope override rather
/// than created inside a provider: the database must not be reopened because a
/// widget rebuilt.
class Bootstrap {
  Bootstrap({
    required this.auth,
    required this.db,
    required this.initialSession,
  });

  final AuthRepository auth;
  final LocalDatabase db;
  final Session? initialSession;

  SyncEngine? _engine;

  SyncEngine? get engine => _engine;

  bool _cipherVerified = false;
  bool get isEncrypted => _cipherVerified;

  static Future<Bootstrap> create() async {
    final auth = AuthRepository(baseUrl: AppConfig.apiBaseUrl);
    final session = await auth.restore();
    final key = await auth.databaseKey();
    final db = await openLocalDatabase(key);

    final bootstrap = Bootstrap(auth: auth, db: db, initialSession: session);
    await bootstrap._verifyCipher();
    if (session != null) {
      await bootstrap.startSync();
    }
    return bootstrap;
  }

  /// Confirms SQLite3MultipleCiphers is really active. If it is not, the file on
  /// disk is plain SQLite and nobody would notice until a laptop is lost.
  Future<void> _verifyCipher() async {
    try {
      final rows = await db.customSelect('PRAGMA cipher;').get();
      _cipherVerified = rows.isNotEmpty;
    } catch (_) {
      _cipherVerified = false;
    }
  }

  Future<void> startSync() async {
    await _engine?.dispose();
    _engine = null;

    final session = await auth.restore();
    if (session == null) return;

    final api = HttpSyncApi(
      baseUrl: AppConfig.apiBaseUrl,
      deviceId: session.deviceId,
      tokenProvider: auth.accessToken,
    );

    _engine = SyncEngine(db: db, api: api);
    _engine!.start(
      interval: Platform.isWindows
          ? AppConfig.windowsPollInterval
          : AppConfig.androidPollInterval,
    );
  }

  Future<void> signOut() async {
    await _engine?.dispose();
    _engine = null;
    await auth.logout();
    await auth.clearPin();
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    await db.close();
  }
}
