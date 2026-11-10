import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:starparis_design/starparis_design.dart';

/// One step of a guided tour.
///
/// [anchor] names an element to spotlight (null shows a centred card instead —
/// welcome and closing steps). The anchor name is resolved through the owner's
/// `anchorFor` callback, so the same step type drives both the global
/// get-started tour and every per-section tour.
class TourStep {
  const TourStep({
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
    this.anchor,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? anchor;
}

/// A coach-mark spotlight: dims the whole area, punches a hole over the target
/// element, draws a highlight border around it, and anchors a small tooltip
/// beside it. The element being described stays visible.
///
/// Controlled rather than self-navigating: the owner supplies the current
/// [index] and the navigation callbacks, so the global tour can also switch
/// the shell tab when a step changes, while a section tour only advances.
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({
    super.key,
    required this.steps,
    required this.index,
    required this.anchorFor,
    required this.onNext,
    required this.onBack,
    required this.onDone,
  });

  final List<TourStep> steps;
  final int index;

  /// Resolves a step's anchor name to the GlobalKey of the element to
  /// spotlight. May return null for anchor-less steps.
  final GlobalKey? Function(String? anchor) anchorFor;

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay> {
  Rect? _targetRect;
  GlobalKey? _key;

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[widget.index];
    final key = widget.anchorFor(step.anchor);

    if (key != _key) {
      _key = key;
      _targetRect = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(key));

    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final isLast = widget.index >= widget.steps.length - 1;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: SpotlightPainter(_targetRect)),
          ),
        ),
        if (_targetRect != null)
          AnimatedPositioned.fromRect(
            duration: StarMotion.standard,
            curve: StarMotion.easeOut,
            rect: _targetRect!.inflate(6),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(StarRadius.card),
                  border: Border.all(color: StarColors.petrol, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: StarColors.petrol.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_targetRect != null)
          _anchoredTip(step, isLast, theme, screen)
        else
          _centeredTip(step, isLast, theme),
      ],
    );
  }

  void _measure(GlobalKey? key) {
    if (key == null) {
      if (_targetRect != null) setState(() => _targetRect = null);
      return;
    }
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect != _targetRect) setState(() => _targetRect = rect);
  }

  Widget _anchoredTip(
    TourStep step,
    bool isLast,
    ThemeData theme,
    Size screen,
  ) {
    const double maxWidth = 320;
    const double gap = 12;
    // The card is capped at this height (see _tip), so the placement math is
    // exact rather than a guess — which keeps the Next button on screen.
    const double cardHeight = 240;
    final target = _targetRect!;
    final spaceBelow = screen.height - target.bottom - gap - 8;
    final spaceAbove = target.top - gap - 8;
    final placeBelow = spaceBelow >= cardHeight || spaceBelow >= spaceAbove;
    final double top = (placeBelow
            ? target.bottom + gap
            : target.top - gap - cardHeight)
        .clamp(8.0, math.max(8.0, screen.height - cardHeight - 8.0))
        .toDouble();
    final double left = (target.center.dx - maxWidth / 2)
        .clamp(8.0, math.max(8.0, screen.width - maxWidth - 8.0))
        .toDouble();

    return AnimatedPositioned(
      duration: StarMotion.standard,
      curve: StarMotion.easeOut,
      top: top,
      left: left,
      width: maxWidth,
      child: _tip(step, isLast, theme),
    );
  }

  Widget _centeredTip(TourStep step, bool isLast, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: _tip(step, isLast, theme),
      ),
    );
  }

  Widget _tip(TourStep step, bool isLast, ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: AnimatedSwitcher(
        duration: StarMotion.fast,
        switchInCurve: StarMotion.easeOut,
        switchOutCurve: StarMotion.easeInOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: TourTipCard(
          key: ValueKey<int>(widget.index),
          step: step,
          index: widget.index,
          total: widget.steps.length,
          isLast: isLast,
          onBack: widget.index == 0 ? null : widget.onBack,
          onNext: widget.onNext,
          onSkip: widget.onDone,
          theme: theme,
        ),
      ),
    );
  }
}

/// A compact glass card: icon + title + body, then Back / dots / Next. Kept
/// small on purpose — it is a hint beside the spotlight, not the whole screen.
class TourTipCard extends StatelessWidget {
  const TourTipCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.theme,
  });

  final TourStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(StarRadius.card),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StarSpace.md,
          StarSpace.md,
          StarSpace.md,
          StarSpace.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(StarSpace.sm),
                  decoration: BoxDecoration(
                    color: StarColors.petrol.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StarRadius.chip),
                  ),
                  child: Icon(step.icon, size: 20, color: StarColors.petrol),
                ),
                const SizedBox(width: StarSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StarSpace.sm),
            Row(
              children: <Widget>[
                if (onBack != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                  )
                else
                  TextButton(
                    onPressed: onSkip,
                    child: Text(isLast ? 'Done' : 'Skip'),
                  ),
                const Spacer(),
                TourDots(index: index, total: total),
                const Spacer(),
                IconButton.filled(
                  tooltip: 'Next',
                  onPressed: onNext,
                  icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The little progress dots between Back and Next.
class TourDots extends StatelessWidget {
  const TourDots({super.key, required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: StarMotion.fast,
            curve: StarMotion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? StarColors.petrol
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(StarRadius.chip),
            ),
          ),
      ],
    );
  }
}

/// Dims the whole screen except a rounded hole over [hole]. When [hole] is
/// null (the welcome / closing cards) it dims evenly, with no cutout.
class SpotlightPainter extends CustomPainter {
  SpotlightPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final full = Offset.zero & size;

    if (hole == null) {
      canvas.drawRect(full, dim);
      return;
    }

    final cutout = RRect.fromRectAndRadius(
      hole!.inflate(8),
      const Radius.circular(12),
    );
    final fullPath = Path()..addRect(full);
    final holePath = Path()..addRRect(cutout);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, holePath),
      dim,
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
