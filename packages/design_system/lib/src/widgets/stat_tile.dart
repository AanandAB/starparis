import 'package:flutter/material.dart';

import '../tokens.dart';

/// What a number means, not just what colour it is. Every tone also carries an
/// icon and a word in the tile, so a colour-blind clerk reads the same thing a
/// colour-sighted one does.
enum StarStatTone { neutral, positive, warning, danger }

/// One figure with a label, for the top of a working screen.
///
/// Deliberately a card rather than a bare number: the owner reads these while
/// walking past a screen, so the value has to be large and the label has to sit
/// directly under it.
class StarStat extends StatelessWidget {
  const StarStat({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.icon,
    this.tone = StarStatTone.neutral,
    this.onTap,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData? icon;
  final StarStatTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tone) {
      StarStatTone.neutral => theme.colorScheme.primary,
      StarStatTone.positive => StarColors.statusDone,
      StarStatTone.warning => StarColors.statusPaused,
      StarStatTone.danger => StarColors.statusProblem,
    };

    final content = Padding(
      padding: const EdgeInsets.all(StarSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StarRadius.field),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
              if (icon != null) const SizedBox(width: StarSpace.sm),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StarSpace.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: tone == StarStatTone.neutral
                  ? theme.colorScheme.onSurface
                  : accent,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hint!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
