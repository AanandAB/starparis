import 'package:flutter/material.dart';

import '../tokens.dart';

/// The four states a device can be in. The words matter more than the colour:
/// "Offline, 12 changes waiting" tells a clerk nothing is lost, "Error" does not.
enum SyncChipState { synced, syncing, offline, attention }

/// Always-visible sync indicator (design §5.10).
///
/// Sits in the app bar on every screen. Tapping opens the diagnostics panel
/// with the last sync time and a Sync now button.
class SyncChip extends StatelessWidget {
  const SyncChip({
    required this.state,
    required this.onTap,
    this.pendingChanges = 0,
    super.key,
  });

  final SyncChipState state;
  final int pendingChanges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color colour, IconData icon, String label) = switch (state) {
      SyncChipState.synced => (
        StarColors.statusDone,
        Icons.cloud_done_outlined,
        'Synced',
      ),
      SyncChipState.syncing => (
        StarColors.statusActive,
        Icons.sync,
        pendingChanges == 1
            ? 'Syncing 1 change'
            : 'Syncing $pendingChanges changes',
      ),
      SyncChipState.offline => (
        StarColors.statusWaiting,
        Icons.cloud_off_outlined,
        pendingChanges == 1
            ? 'Offline, 1 change waiting'
            : 'Offline, $pendingChanges changes waiting',
      ),
      SyncChipState.attention => (
        StarColors.statusProblem,
        Icons.error_outline,
        'Needs attention',
      ),
    };

    return Tooltip(
      message: 'Sync status — tap for details',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StarRadius.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: StarSpace.md,
            vertical: StarSpace.sm,
          ),
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(StarRadius.chip),
            border: Border.all(color: colour.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: colour),
              const SizedBox(width: StarSpace.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
