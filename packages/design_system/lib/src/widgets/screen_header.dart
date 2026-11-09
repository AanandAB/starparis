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
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Sits on the opposite edge from the title, for a search field or a count.
  final Widget? trailing;

  /// When set, a back button is drawn before the title — the pushed screens
  /// (the order builder) need one, the tab screens do not, and both must keep
  /// the same title weight and padding.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < StarBreakpoints.compact;

    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
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
    );

    final back = onBack == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: StarSpace.xs, top: 2),
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          );

    final hasExtras = trailing != null || actions.isNotEmpty;

    if (narrow) {
      // On a phone the trailing/actions move to their own line so a wide
      // control (a mode selector, a month stepper, a New-customer button) can
      // never starve the title into one character per line.
      return Padding(
        padding: const EdgeInsets.only(bottom: StarSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ?back,
                Expanded(child: titleBlock),
              ],
            ),
            if (hasExtras) ...<Widget>[
              const SizedBox(height: StarSpace.sm),
              Wrap(
                spacing: StarSpace.sm,
                runSpacing: StarSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ?trailing,
                  ...actions,
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: StarSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ?back,
          Expanded(child: titleBlock),
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
