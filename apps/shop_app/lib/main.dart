import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/bootstrap.dart';
import 'src/logging/app_log.dart';
import 'src/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start logging before anything else can fail: the first thing support asks
  // for is what the app was doing in the seconds before it went wrong.
  await AppLog.start();
  AppLog.info('Star Paris starting');

  // Open the encrypted database and restore the session before the first
  // frame: a half-drawn counter screen that then jumps to login reads as a bug.
  final bootstrap = await Bootstrap.create();
  AppLog.info('Database open, session restored');

  runApp(
    ProviderScope(
      overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
      child: const StarParisApp(),
    ),
  );
}
