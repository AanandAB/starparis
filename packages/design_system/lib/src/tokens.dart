import 'package:flutter/material.dart';

/// Brand tokens.
///
/// Placeholder palette until the client supplies the logo: a deep petrol blue
/// (ink, trust, the colour of a press room) and warm sand (paper stock). Both
/// are swappable here and nowhere else — no widget hard-codes a hex value.
abstract final class StarColors {
  /// Primary — deep petrol.
  static const Color petrol = Color(0xFF0E3B43);
  static const Color petrolDark = Color(0xFF08262C);

  /// Secondary — warm sand, the colour of uncoated card stock.
  static const Color sand = Color(0xFFD9C7A7);

  /// Accent used sparingly: rush jobs, overdue, money due.
  static const Color ember = Color(0xFFC4552D);

  /// Status colours. Never used alone — always with an icon and a label.
  static const Color statusWaiting = Color(0xFF6B7280);
  static const Color statusActive = Color(0xFF1565C0);
  static const Color statusPaused = Color(0xFF8A6D3B);
  static const Color statusDone = Color(0xFF2E7D32);
  static const Color statusProblem = Color(0xFFB3261E);

  /// Surfaces.
  static const Color canvasLight = Color(0xFFF7F4EE);
  static const Color canvasDark = Color(0xFF101416);
  static const Color surfaceDark = Color(0xFF1A2023);
}

/// An 8-point spacing grid. Named so a reviewer can say "that gap is a
/// [StarSpace.sm], not 12 pixels" and mean something.
abstract final class StarSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii. Cards are soft; inputs are not, so a field never looks like a
/// button.
abstract final class StarRadius {
  static const double card = 14;
  static const double field = 10;
  static const double chip = 999;
}

/// Breakpoints from the design document §16.2, in logical pixels.
abstract final class StarBreakpoints {
  static const double compact = 600;
  static const double medium = 1000;
}
