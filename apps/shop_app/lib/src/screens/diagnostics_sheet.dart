import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';

Future<void> showDiagnosticsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _DiagnosticsSheet(),
  );
}

/// What the sync chip opens: the truth about what has and has not reached the
/// server, in words a shop manager can act on.
class _DiagnosticsSheet extends ConsumerWidget {
  const _DiagnosticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapProvider);
    final state = ref.watch(syncStateProvider).value;
    final pending = ref.watch(pendingCountProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StarSpace.lg,
        StarSpace.sm,
        StarSpace.lg,
        StarSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Sync', style: theme.textTheme.titleLarge),
          const SizedBox(height: StarSpace.lg),
          _Row(
            label: 'Status',
            value: switch (state?.phase) {
              SyncPhase.syncing => 'Syncing…',
              SyncPhase.offline => 'Offline — working locally',
              SyncPhase.attention => 'Needs attention',
              SyncPhase.synced => 'Synced',
              _ => 'Waiting for the first sync',
            },
            tone: switch (state?.phase) {
              SyncPhase.attention => StarColors.statusProblem,
              SyncPhase.offline => StarColors.statusPaused,
              SyncPhase.synced => StarColors.statusDone,
              _ => null,
            },
          ),
          _Row(label: 'Waiting to upload', value: '$pending'),
          _Row(
            label: 'Last sync',
            value: state?.lastSync == null
                ? '—'
                : TimeOfDay.fromDateTime(state!.lastSync!).format(context),
          ),
          _Row(
            label: 'Database',
            value: bootstrap.isEncrypted
                ? 'Encrypted (SQLCipher)'
                : 'NOT ENCRYPTED',
            tone: bootstrap.isEncrypted
                ? StarColors.statusDone
                : StarColors.statusProblem,
          ),
          if (state?.message != null) ...<Widget>[
            const SizedBox(height: StarSpace.md),
            Text(
              state!.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: StarSpace.lg),
          FutureBuilder<List<String?>>(
            future: Future.wait(<Future<String?>>[
              bootstrap.db.meta('head'),
              bootstrap.db.cursor().then((value) => '$value'),
            ]),
            builder: (context, snapshot) {
              final values = snapshot.data;
              if (values == null) return const SizedBox.shrink();
              return Column(
                children: <Widget>[
                  _Row(label: 'Server head', value: values[0] ?? '0'),
                  _Row(label: 'Local cursor', value: values[1] ?? '0'),
                ],
              );
            },
          ),
          const SizedBox(height: StarSpace.lg),
          FilledButton.icon(
            onPressed: () async {
              await bootstrap.engine?.syncNow();
            },
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Sync now'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StarSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: StarSpace.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
