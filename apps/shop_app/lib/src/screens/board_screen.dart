import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../auth/session.dart';
import '../providers.dart';

/// Everything still in the shop, by stage.
///
/// Two ways to look at the same rows: the board answers "what is where", My
/// work answers "what is mine". Both read the local database, so the screen is
/// instant and works with no internet — which is the point of the whole app.
final StreamProvider<List<Task>> activeTasksProvider =
    StreamProvider<List<Task>>((ref) {
      final db = ref.watch(bootstrapProvider).db;
      final branchId = ref.watch(sessionProvider)?.branchId;
      return db.watchActiveTasks(branchId: branchId);
    });

final StreamProvider<List<Task>> myTasksProvider = StreamProvider<List<Task>>((
  ref,
) {
  final db = ref.watch(bootstrapProvider).db;
  final session = ref.watch(sessionProvider);
  if (session == null) return Stream<List<Task>>.value(const <Task>[]);
  return db.watchMyTasks(userId: session.userId, role: session.role);
});

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  bool _mineOnly = false;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(_mineOnly ? myTasksProvider : activeTasksProvider);
    final session = ref.watch(sessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StarSpace.lg,
            StarSpace.md,
            StarSpace.lg,
            StarSpace.sm,
          ),
          child: Row(
            children: <Widget>[
              Text(
                'Production',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: StarSpace.md),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(value: false, label: Text('Board')),
                  ButtonSegment<bool>(value: true, label: Text('My work')),
                ],
                selected: <bool>{_mineOnly},
                onSelectionChanged: (selection) =>
                    setState(() => _mineOnly = selection.first),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const Spacer(),
              tasks.maybeWhen(
                data: (rows) => Text(
                  '${rows.length} open',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Could not read tasks: $error')),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyState(
                  icon: Icons.checklist_rtl,
                  title: _mineOnly
                      ? 'Nothing on your plate'
                      : 'Nothing in production',
                  message: _mineOnly
                      ? 'Work assigned to you, or waiting for your role, appears here.'
                      : 'Confirm an order and its stages appear here, one column each.',
                );
              }
              return _mineOnly
                  ? _MyWorkList(tasks: rows, session: session)
                  : _Board(tasks: rows, session: session);
            },
          ),
        ),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.tasks, required this.session});

  final List<Task> tasks;
  final Session? session;

  @override
  Widget build(BuildContext context) {
    // Columns follow the sequence the workflow defines, not the order rows
    // happened to arrive in.
    final columns = <String, List<Task>>{};
    final names = <String, String>{};
    final sequences = <String, int>{};
    for (final task in tasks) {
      columns.putIfAbsent(task.stageKey, () => <Task>[]).add(task);
      names[task.stageKey] = task.stageName;
      sequences[task.stageKey] = task.sequence;
    }
    final keys = columns.keys.toList()
      ..sort((a, b) => (sequences[a] ?? 0).compareTo(sequences[b] ?? 0));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(StarSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final key in keys)
            _StageColumn(
              key: ValueKey<String>(key),
              title: names[key] ?? key,
              tasks: columns[key]!,
              session: session,
            ),
        ],
      ),
    );
  }
}

class _StageColumn extends StatelessWidget {
  const _StageColumn({
    required this.title,
    required this.tasks,
    required this.session,
    super.key,
  });

  final String title;
  final List<Task> tasks;
  final Session? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 296,
      margin: const EdgeInsets.only(right: StarSpace.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(StarRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StarSpace.md,
              StarSpace.md,
              StarSpace.sm,
              StarSpace.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusChip(label: '${tasks.length}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StarSpace.sm,
              0,
              StarSpace.sm,
              StarSpace.sm,
            ),
            child: Column(
              children: <Widget>[
                for (final task in tasks)
                  _TaskCard(task: task, session: session),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyWorkList extends StatelessWidget {
  const _MyWorkList({required this.tasks, required this.session});

  final List<Task> tasks;
  final Session? session;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(StarSpace.lg),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: StarSpace.sm),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: EdgeInsets.zero,
            child: _TaskCard(task: task, session: session, flat: true),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.session,
    this.flat = false,
  });

  final Task task;
  final Session? session;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.dueAt != null && task.dueAt!.isBefore(DateTime.now());
    final status = TaskStatus.fromWire(task.status);

    final card = InkWell(
      onTap: () => showTaskSheet(context, task, session),
      borderRadius: BorderRadius.circular(StarRadius.field),
      child: Padding(
        padding: const EdgeInsets.all(StarSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: StarSpace.xs),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: StarSpace.xs),
            Row(
              children: <Widget>[
                if (task.qty > 0) ...<Widget>[
                  Text('${task.qty} pcs', style: theme.textTheme.bodySmall),
                  const SizedBox(width: StarSpace.sm),
                ],
                if (task.dueAt != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        overdue ? Icons.warning_amber_rounded : Icons.schedule,
                        size: 13,
                        color: overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _dueLabel(task.dueAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overdue ? theme.colorScheme.error : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (task.reason != null && task.reason!.isNotEmpty) ...<Widget>[
              const SizedBox(height: StarSpace.xs),
              Text(
                task.reason!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (flat) return card;

    return Container(
      margin: const EdgeInsets.only(bottom: StarSpace.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(StarRadius.field),
        border: Border.all(
          color: status == TaskStatus.inProgress
              ? StarColors.ember.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: card,
    );
  }

  static Widget _statusChip(TaskStatus status) => switch (status) {
    TaskStatus.available => const StatusChip(
      label: 'Pool',
      tone: StatusTone.neutral,
    ),
    TaskStatus.assigned => const StatusChip(
      label: 'Assigned',
      tone: StatusTone.active,
    ),
    TaskStatus.inProgress => const StatusChip(
      label: 'Working',
      tone: StatusTone.active,
    ),
    TaskStatus.paused => const StatusChip(
      label: 'Paused',
      tone: StatusTone.paused,
    ),
    TaskStatus.rework => const StatusChip(
      label: 'Rework',
      tone: StatusTone.problem,
    ),
    TaskStatus.done => const StatusChip(label: 'Done', tone: StatusTone.done),
    TaskStatus.cancelled => const StatusChip(
      label: 'Cancelled',
      tone: StatusTone.neutral,
    ),
    TaskStatus.waiting => const StatusChip(label: 'Waiting'),
  };

  static String _dueLabel(DateTime due) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${due.day} ${months[due.month - 1]}';
  }
}

/// The actions a task offers, and the reason prompt the risky ones need.
Future<void> showTaskSheet(BuildContext context, Task task, Session? session) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _TaskSheet(task: task, session: session),
  );
}

class _TaskSheet extends ConsumerStatefulWidget {
  const _TaskSheet({required this.task, required this.session});

  final Task task;
  final Session? session;

  @override
  ConsumerState<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends ConsumerState<_TaskSheet> {
  bool _busy = false;

  bool get _manager =>
      widget.session?.isOwner == true || widget.session?.role == 'manager';

  /// Who may touch this task: its assignee, the pool's role owner, or a manager.
  bool get _mayAct {
    final session = widget.session;
    if (session == null) return false;
    if (_manager) return true;
    if (widget.task.assignedTo == session.userId) return true;
    return widget.task.assignedTo == null &&
        widget.task.requiredRole == session.role;
  }

  Future<void> _move(TaskStatus to) async {
    final from = TaskStatus.fromWire(widget.task.status);
    final transition = TaskStateMachine.transition(from, to);
    if (transition == null) return;

    String? reason;
    if (transition.requiresReason) {
      reason = await _askReason(to);
      if (reason == null || !mounted) return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      await bootstrap.db.transitionTask(
        task: widget.task,
        to: to,
        userId: widget.session!.userId,
        reason: reason,
      );
      unawaited(bootstrap.engine?.syncNow() ?? Future<void>.value());
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(_confirmation(to))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _confirmation(TaskStatus to) => switch (to) {
    TaskStatus.assigned => 'Task claimed.',
    TaskStatus.inProgress => 'Started.',
    TaskStatus.paused => 'Paused. The reason is on the card.',
    TaskStatus.done => 'Finished. The next stage is open.',
    TaskStatus.rework => 'Sent back for rework.',
    TaskStatus.available => 'Released back to the pool.',
    TaskStatus.cancelled => 'Task cancelled.',
    TaskStatus.waiting => 'Task returned to waiting.',
  };

  Future<String?> _askReason(TaskStatus to) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(switch (to) {
          TaskStatus.rework => 'Why is this going back?',
          TaskStatus.paused => 'Why are you pausing?',
          _ => 'Why is this being cancelled?',
        }),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Customer changed the artwork, paper ran out…',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length < 3) return;
              Navigator.of(context).pop(text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final status = TaskStatus.fromWire(task.status);
    final nextStates = TaskStateMachine.nextStates(status).where((to) {
      final transition = TaskStateMachine.transition(status, to);
      if (transition == null) return false;
      if (transition.managerOnly && !_manager) return false;
      return true;
    }).toList();

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
          Text(task.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: StarSpace.xs),
          Text(
            '${task.stageName} · ${task.requiredRole} · v${task.version}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: StarSpace.md),
          Wrap(
            spacing: StarSpace.sm,
            runSpacing: StarSpace.sm,
            children: <Widget>[
              for (final to in nextStates)
                _mayAct
                    ? (to == TaskStatus.done
                          ? FilledButton.icon(
                              onPressed: _busy ? null : () => _move(to),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(_actionLabel(to)),
                            )
                          : OutlinedButton(
                              onPressed: _busy ? null : () => _move(to),
                              child: Text(_actionLabel(to)),
                            ))
                    : const SizedBox.shrink(),
            ],
          ),
          if (!_mayAct) ...<Widget>[
            const SizedBox(height: StarSpace.md),
            Text(
              'This task belongs to ${task.requiredRole}. Ask a manager to assign you.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: StarSpace.md),
          Text(
            'Every move is recorded with who did it and when, and syncs as soon '
            'as there is a connection.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _actionLabel(TaskStatus to) => switch (to) {
    TaskStatus.assigned => 'Claim',
    TaskStatus.inProgress => 'Start',
    TaskStatus.paused => 'Pause',
    TaskStatus.done => 'Finish',
    TaskStatus.rework => 'Send back',
    TaskStatus.available => 'Release',
    TaskStatus.cancelled => 'Cancel task',
    TaskStatus.waiting => 'Return to waiting',
  };
}
