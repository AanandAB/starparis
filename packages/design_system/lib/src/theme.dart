import 'package:flutter/material.dart';

import 'tokens.dart';

/// The shop's theme, built from tokens.
///
/// Density is a first-class parameter: Windows gets [VisualDensity.compact]
/// because a counter PC is a mouse and a keyboard, Android gets comfortable
/// targets because it is a thumb.
abstract final class StarTheme {
  static ThemeData light({bool desktop = false}) =>
      _build(Brightness.light, desktop);

  static ThemeData dark({bool desktop = false}) =>
      _build(Brightness.dark, desktop);

  static ThemeData _build(Brightness brightness, bool desktop) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: StarColors.petrol,
          brightness: brightness,
        ).copyWith(
          secondary: StarColors.sand,
          error: StarColors.statusProblem,
          surface: isDark ? StarColors.surfaceDark : Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark
          ? StarColors.canvasDark
          : StarColors.canvasLight,
      visualDensity: desktop ? VisualDensity.compact : VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StarRadius.card),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        color: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: StarSpace.md,
          vertical: StarSpace.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StarRadius.field),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StarRadius.field),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StarRadius.field),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(desktop ? 0 : double.infinity, desktop ? 44 : 52),
          padding: const EdgeInsets.symmetric(
            horizontal: StarSpace.lg,
            vertical: StarSpace.md,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StarRadius.field),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(desktop ? 0 : double.infinity, desktop ? 44 : 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StarRadius.field),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StarRadius.chip),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: StarSpace.md,
          vertical: StarSpace.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StarRadius.field),
        ),
      ),
      // The bottom bar is a surface, not a shadow: flat, with a tinted pill
      // behind the current item.
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  /// Inter is bundled with the app; the fallback keeps a fresh checkout
  /// readable before fonts are added to assets.
  static TextTheme _textTheme(TextTheme base) {
    final family = base.bodyMedium?.fontFamily;
    return base
        .apply(fontFamily: family)
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          // Section headings and card titles sit one step below the page title,
          // so a screen reads as: page, section, row.
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.35),
          bodySmall: base.bodySmall?.copyWith(height: 1.35),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.2),
        );
  }
}
