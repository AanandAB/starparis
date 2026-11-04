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

  /// The surface ramp, light and dark. A card, a dialog and a sheet must read
  /// as three distinct depths, not one — this is what gives them figure/ground.
  static const Color surfaceContainerLight = Color(0xFFEFEAE0);
  static const Color surfaceContainerHighLight = Color(0xFFE9E3D7);
  static const Color surfaceContainerDark = Color(0xFF161C1F);
  static const Color surfaceContainerHighDark = Color(0xFF20282C);

  /// Text on the brand surface, and the ink used for the strongest text.
  static const Color onPetrol = Color(0xFFF3F7F8);
  static const Color inkLight = Color(0xFF1B2023);
  static const Color inkDark = Color(0xFFE7ECEE);
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

/// Motion, named so the whole app shares one rhythm instead of scattering
/// `Duration(milliseconds: …)` everywhere. A counter clerk never waits for
/// motion; it announces a change and is gone.
abstract final class StarMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
}
