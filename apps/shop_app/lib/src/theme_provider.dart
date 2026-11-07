import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Which theme the shop runs in.
///
/// A counter under fluorescent light wants the light theme; the office at 9 pm
/// wants the dark one, on the same device. It lives in its own file rather than
/// in `main.dart` so screens can read it without importing the entry point.
///
/// The choice is persisted in the local database's meta table — the same store
/// the app already uses for the price-book version — rather than a new
/// preferences dependency, so it survives a restart without adding a package.
class ThemeModeChoice extends Notifier<ThemeMode> {
  static const String _metaKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Build must return synchronously; the persisted value (if any) is loaded
    // afterwards and replaces the default without a frame of flicker mattering
    // before the first paint.
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final saved = await ref.read(bootstrapProvider).db.meta(_metaKey);
    final mode = _fromString(saved);
    if (mode != null && state != mode) state = mode;
  }

  /// Cycles system → light → dark, so one menu item covers all three choices.
  void toggle() => set(_next(state));

  void set(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
    unawaited(_persist(mode));
  }

  static ThemeMode _next(ThemeMode mode) => switch (mode) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };

  Future<void> _persist(ThemeMode mode) async {
    await ref.read(bootstrapProvider).db.setMeta(_metaKey, _toString(mode));
  }

  static ThemeMode? _fromString(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };

  static String _toString(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

final NotifierProvider<ThemeModeChoice, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeChoice, ThemeMode>(ThemeModeChoice.new);
