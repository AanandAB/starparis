import 'package:flutter/material.dart';

import '../tokens.dart';

/// The header every list screen shares: what this is, what it is for, and the
/// one action worth putting here.
///
/// It exists because a screen with its own hand-rolled title row drifts — a
/// different gap, a different weight, a button on the other side — and a user
/// notices that drift long before they can name it.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Sits on the opposite edge from the title, for a search field or a count.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: StarSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
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
          for (final action in actions) ...<Widget>[
            const SizedBox(width: StarSpace.sm),
            action,
          ],
        ],
      ),
    );
  }
}
