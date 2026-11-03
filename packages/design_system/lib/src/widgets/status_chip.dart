import 'package:flutter/material.dart';

import '../tokens.dart';

/// Tone of a status chip. Colour is never the only signal — every chip carries
/// an icon and a word as well, per the accessibility rule in design §3.9.
enum StatusTone { neutral, active, paused, done, problem }

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colour = switch (tone) {
      StatusTone.neutral => StarColors.statusWaiting,
      StatusTone.active => StarColors.statusActive,
      StatusTone.paused => StarColors.statusPaused,
      StatusTone.done => StarColors.statusDone,
      StatusTone.problem => StarColors.statusProblem,
    };
    final resolvedIcon =
        icon ??
        switch (tone) {
          StatusTone.neutral => Icons.circle_outlined,
          StatusTone.active => Icons.play_circle_outline,
          StatusTone.paused => Icons.pause_circle_outline,
          StatusTone.done => Icons.check_circle_outline,
          StatusTone.problem => Icons.error_outline,
        };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StarSpace.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(StarRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(resolvedIcon, size: 14, color: colour),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colour, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
