import 'package:flutter/material.dart';

import '../tokens.dart';

/// A card that responds to the pointer — the desktop half of the feel.
///
/// Cards are the app's main interactive surface, and a counter PC is driven by
/// a mouse, so a tile must lift on hover and settle on press. This wraps both
/// in one widget so every tappable tile, stat and list card behaves the same
/// way, with the same rhythm, everywhere.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.onTap,
    this.onLongPress,
    this.child,
    this.padding,
    this.color,
    this.borderRadius = StarRadius.card,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double borderRadius;
  final bool enabled;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(widget.borderRadius);
    final baseColor = widget.color ?? scheme.surface;

    // Hover lifts the card with a soft shadow; press pulls it back down. Both
    // are cheap container tweaks, not a repaint of the whole screen, so the
    // effect is free at a counter PC's refresh rate.
    final hovered = _hovered && widget.enabled;
    final boxShadow = hovered
        ? <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ]
        : const <BoxShadow>[];

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: StarMotion.fast,
        curve: StarMotion.easeOut,
        transform: _pressed
            ? (Matrix4.identity()..scaleByDouble(0.985, 0.985, 0.985, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: hovered
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.04),
                  baseColor,
                )
              : baseColor,
          borderRadius: radius,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: boxShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            onHighlightChanged: (value) {
              if (_pressed != value) setState(() => _pressed = value);
            },
            borderRadius: radius,
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(StarSpace.md),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
