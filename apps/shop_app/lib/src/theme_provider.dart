import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which theme the shop runs in.
///
/// A counter under fluorescent light wants the light theme; the office at 9 pm
/// wants the dark one, on the same device. It lives in its own file rather than
/// in `main.dart` so screens can read it without importing the entry point.
class ThemeModeChoice extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) => state = mode;
}

final NotifierProvider<ThemeModeChoice, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeChoice, ThemeMode>(ThemeModeChoice.new);
