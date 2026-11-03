import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import 'auth_gate.dart';

class StarParisApp extends ConsumerWidget {
  const StarParisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return MaterialApp(
      title: 'Star Paris',
      debugShowCheckedModeBanner: false,
      theme: StarTheme.light(desktop: desktop),
      darkTheme: StarTheme.dark(desktop: desktop),
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
