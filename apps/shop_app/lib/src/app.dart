import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import 'auth_gate.dart';
import 'providers.dart';
import 'theme_provider.dart';

/// The app shell above the shell.
///
/// Locale is a choice, not a system guess: a shop in Sharjah may run one counter
/// in Arabic and the office in English on the same day. Direction follows the
/// locale, so with Arabic set Flutter mirrors the layout — rail on the right,
/// padding from the right — which the screens already support because they use
/// directional padding and rows rather than hard-coded left/right values.
///
/// What this does NOT do yet: translate the labels. The switch proves the
/// mirroring, not the language; Arabic strings and Arabic PDF shaping are the
/// next decision.

class StarParisApp extends ConsumerWidget {
  const StarParisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Star Paris',
      debugShowCheckedModeBanner: false,
      theme: StarTheme.light(desktop: desktop),
      darkTheme: StarTheme.dark(desktop: desktop),
      themeMode: ref.watch(themeModeProvider),
      // The shop's dense screens — screen headers, the board, price grids — break
      // under a very large device font scale: a header button grows until it
      // starves the title beside it, which then wraps one character per line.
      // Cap the scale so the layout stays usable while still honouring a
      // moderate accessibility bump (the design document asks for scalable text,
      // so we never fully disable scaling — only its catastrophic tail).
      builder: (context, child) {
        const double maxScale = 1.3;
        final media = MediaQuery.of(context);
        if (media.textScaler.scale(1.0) <= maxScale) return child!;
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(maxScale)),
          child: child!,
        );
      },
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('ar', 'AE')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
