import 'package:flutter/material.dart';

/// A key-cap for a keyboard shortcut, so it is visible instead of
/// discoverable-by-accident. Sits beside a field or in a top bar; the hint
/// teaches the shortcut to someone who never reads documentation.
class ShortcutChip extends StatelessWidget {
  const ShortcutChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          letterSpacing: 0,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
