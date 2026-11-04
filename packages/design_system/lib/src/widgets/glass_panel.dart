import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// A translucent, blurred panel for the top bar and the side panel.
///
/// Glass is used only where it costs no legibility: content scrolls *beneath*
/// it and the clerk reads what is *on* it. When blur is off or reduce-motion is
/// set, the panel falls back to an opaque surface so nothing is ever hard to
/// read through a haze.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.color,
    this.fallbackColor,
    this.borderRadius,
    this.enableBlur = true,
  });

  final Widget child;

  /// The translucent fill when blurring. Defaults to the surface at 72 % alpha.
  final Color? color;

  /// The opaque fill when blur is off (reduce-motion or [enableBlur] false).
  final Color? fallbackColor;

  final BorderRadius? borderRadius;

  /// Set false on low-end hardware where the backdrop filter is a real cost.
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final useBlur = enableBlur && !reduce;
    final radius = borderRadius ?? BorderRadius.circular(StarRadius.card);
    final fill = useBlur
        ? (color ?? scheme.surface.withValues(alpha: 0.72))
        : (fallbackColor ?? scheme.surface);

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );

    // Without blur the backdrop filter is pure cost, so it is skipped.
    if (!useBlur) return ClipRRect(borderRadius: radius, child: content);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: content,
      ),
    );
  }
}
