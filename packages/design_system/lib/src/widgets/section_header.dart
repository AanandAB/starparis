import 'package:flutter/material.dart';

import '../tokens.dart';

/// A heading with an optional line of explanation and a trailing action.
///
/// Screens were previously a flat list of cards with no hierarchy: every label
/// competed with every other. A section header gives the eye somewhere to stop
/// and tells the reader what the group below it is for.
class StarSectionHeader extends StatelessWidget {
  const StarSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.count,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Shown as a small pill beside the title: "4" reads as "four of these".
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: StarSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium),
                    if (count != null && count! > 0) ...<Widget>[
                      const SizedBox(width: StarSpace.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: StarSpace.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(StarRadius.chip),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: StarSpace.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
