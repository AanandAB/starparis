/// Opens the encrypted local database.
///
/// SQLCipher via SQLite3MultipleCiphers (the `sqlite3mc` build hook in the
/// workspace root). The key is set before drift touches the file, and a debug
/// check asserts the build really is encrypted — this is the failure that
/// otherwise only shows up when someone copies the file off a shop PC.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:starparis_sync/starparis_sync.dart';

Future<LocalDatabase> openLocalDatabase(String key) async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'starparis.db'));
  await file.parent.create(recursive: true);

  final executor = NativeDatabase.createInBackground(
    file,
    setup: (raw) {
      final escaped = key.replaceAll("'", "''");
      raw.execute("PRAGMA key = '$escaped';");
      raw.execute('PRAGMA journal_mode = WAL;');
      raw.execute('PRAGMA synchronous = NORMAL;');
      raw.execute('PRAGMA foreign_keys = ON;');
    },
  );

  final database = LocalDatabase(executor);
  return database;
}
