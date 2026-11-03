import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:starparis_design/starparis_design.dart';

import '../logging/app_log.dart';

/// The activity log: what the app did in the last few hundred events.
///
/// This is the screen support asks for by name. It is deliberately plain — a
/// list of timestamped lines and a copy button — because the only thing anyone
/// does with it is paste it into a message.
Future<void> showLogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _LogSheet(),
  );
}

class _LogSheet extends StatelessWidget {
  const _LogSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return StreamBuilder<List<LogEntry>>(
          stream: AppLog.updates,
          initialData: AppLog.entries,
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const <LogEntry>[];

            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(StarSpace.lg),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Activity log',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '${entries.length} events, newest last. Nothing leaves '
                            'this device unless you copy it.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: AppLog.export()),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Last 100 events copied.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_all_outlined, size: 18),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
                const SizedBox(height: StarSpace.lg),
                if (entries.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nothing logged yet',
                    message:
                        'Start-up, sync failures and unhandled errors appear here '
                        'as they happen.',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(StarSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final entry in entries.reversed.take(200))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                entry.line,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: switch (entry.level) {
                                    LogLevel.error => theme.colorScheme.error,
                                    LogLevel.warn => StarColors.statusPaused,
                                    LogLevel.info =>
                                      theme.colorScheme.onSurface,
                                    LogLevel.debug =>
                                      theme.colorScheme.onSurfaceVariant,
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: StarSpace.xxl),
              ],
            );
          },
        );
      },
    );
  }
}
