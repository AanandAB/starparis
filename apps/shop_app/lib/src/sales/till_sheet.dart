import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';

/// The cash drawer: start a shift with a float, close it with a count.
///
/// The expected figure here is a local preview — float plus the cash this device
/// has recorded since the till opened. The server recomputes it from the
/// payments and refunds attached to the session and its number is the one that
/// stands; if the two disagree, the server is right and the difference shows as
/// the variance.
Future<void> showTillSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _TillSheet(),
  );
}

class _TillSheet extends ConsumerStatefulWidget {
  const _TillSheet();

  @override
  ConsumerState<_TillSheet> createState() => _TillSheetState();
}

class _TillSheetState extends ConsumerState<_TillSheet> {
  final TextEditingController _float = TextEditingController(text: '0.00');
  bool _busy = false;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final parsed = double.tryParse(_float.text.trim());
    final messenger = ScaffoldMessenger.of(context);
    if (parsed == null || parsed < 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter the float in the drawer.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      await bootstrap.db.openTillLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        deviceId: session.deviceId,
        userId: session.userId,
        openingFloatFils: (parsed * 100).round(),
      );
      unawaited(bootstrap.engine?.syncNow());
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(TillSession till, int previewExpected) async {
    final draft = await showDialog<_CloseDraft>(
      context: context,
      builder: (_) => _CloseTillDialog(expectedFils: previewExpected),
    );
    if (draft == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      await bootstrap.db.closeTillLocal(
        session: till,
        countedFils: draft.countedFils,
        userId: session.userId,
        notes: draft.notes,
      );
      unawaited(bootstrap.engine?.syncNow());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Till closed. Expected ${Fils(previewExpected).aedLabel}, '
            'counted ${Fils(draft.countedFils).aedLabel}.',
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return StreamBuilder<TillSession?>(
      stream: db.watchOpenTill(),
      builder: (context, snapshot) {
        final till = snapshot.data;

        if (till == null) {
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
                Text('The till is closed', style: theme.textTheme.titleLarge),
                const SizedBox(height: StarSpace.xs),
                Text(
                  'Count what is in the drawer and open the shift. Every cash '
                  'payment from here is attached to it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: StarSpace.lg),
                TextField(
                  controller: _float,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Opening float',
                    prefixText: 'AED ',
                  ),
                ),
                const SizedBox(height: StarSpace.lg),
                FilledButton.icon(
                  onPressed: _busy ? null : _open,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Open the till'),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<int>(
          future: db.cashTakenSince(till.openedAt),
          builder: (context, cashSnapshot) {
            final cash = cashSnapshot.data ?? 0;
            final expected = till.openingFloatFils + cash;

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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Till open',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const StatusChip(label: 'Open', tone: StatusTone.active),
                    ],
                  ),
                  const SizedBox(height: StarSpace.xs),
                  Text(
                    'Since ${_time(till.openedAt)} · float '
                    '${Fils(till.openingFloatFils).aedLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: StarSpace.lg),
                  Row(
                    children: <Widget>[
                      _figure(theme, 'Cash taken', Fils(cash).aedLabel),
                      const SizedBox(width: StarSpace.xl),
                      _figure(
                        theme,
                        'Should be in the drawer',
                        Fils(expected).aedLabel,
                        emphasise: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: StarSpace.lg),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _close(till, expected),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Close the till'),
                  ),
                  const SizedBox(height: StarSpace.sm),
                  Text(
                    'The server recomputes the expected amount from the payments '
                    'attached to this shift; a difference is recorded as the variance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _figure(
    ThemeData theme,
    String label,
    String value, {
    bool emphasise = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: (emphasise
              ? theme.textTheme.headlineSmall
              : theme.textTheme.titleMedium),
        ),
      ],
    );
  }

  static String _time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _CloseDraft {
  const _CloseDraft({required this.countedFils, this.notes});

  final int countedFils;
  final String? notes;
}

class _CloseTillDialog extends StatefulWidget {
  const _CloseTillDialog({required this.expectedFils});

  final int expectedFils;

  @override
  State<_CloseTillDialog> createState() => _CloseTillDialogState();
}

class _CloseTillDialogState extends State<_CloseTillDialog> {
  late final TextEditingController _counted = TextEditingController(
    text: (widget.expectedFils / 100).toStringAsFixed(2),
  );
  final TextEditingController _notes = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _counted.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_counted.text.trim());
    if (parsed == null || parsed < 0) {
      setState(() => _error = 'Enter the cash you counted.');
      return;
    }
    Navigator.of(context).pop(
      _CloseDraft(
        countedFils: (parsed * 100).round(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countedFils = ((double.tryParse(_counted.text.trim()) ?? 0) * 100)
        .round();
    final difference = countedFils - widget.expectedFils;

    return AlertDialog(
      title: const Text('Close the till'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _counted,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Counted in the drawer',
                prefixText: 'AED ',
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            Text(
              difference == 0
                  ? 'Matches the expected ${Fils(widget.expectedFils).aedLabel}.'
                  : '${difference > 0 ? 'Over' : 'Short'} by '
                        '${Fils(difference.abs()).aedLabel}.',
              style: TextStyle(
                fontSize: 12,
                color: difference == 0
                    ? StarColors.statusDone
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Paid a supplier from the drawer',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: StarSpace.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Close')),
      ],
    );
  }
}
