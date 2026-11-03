import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/bootstrap.dart';
import 'src/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the encrypted database and restore the session before the first
  // frame: a half-drawn counter screen that then jumps to login reads as a bug.
  final bootstrap = await Bootstrap.create();

  runApp(
    ProviderScope(
      overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
      child: const StarParisApp(),
    ),
  );
}
