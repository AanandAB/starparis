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

/// The three lenses on the same production floor: every stage (board), what I
/// can touch (mine), and work out with other shops (vendors).
enum _BoardMode { board, mine, vendors }

/// Open vendor jobs — the Vendors lens of the board. Reads the same local
/// table the vendors screen does, so the view works with no internet like the
/// rest of the board. Kept here (not providers.dart) because the board owns
/// this view end to end.
final StreamProvider<List<VendorJob>> vendorJobsProvider =
    StreamProvider<List<VendorJob>>((ref) {
      final db = ref.watch(bootstrapProvider).db;
      return db.watchOpenVendorJobs();
    });

/// Vendor rows, so a job card can print the vendor's name (the job row only
/// carries the id). Kept beside the jobs provider for the same reason.
final StreamProvider<List<Vendor>> boardVendorsProvider =
    StreamProvider<List<Vendor>>((ref) {
      final db = ref.watch(bootstrapProvider).db;
      return db.watchVendors();
    });

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  _BoardMode _mode = _BoardMode.board;

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    final session = ref.watch(sessionProvider);

    // Board and My work read the task tables; Vendors reads the vendor-job
    // table. Every stream is local, so switching modes is instant and offline.
    final tasks = ref.watch(
      mode == _BoardMode.mine ? myTasksProvider : activeTasksProvider,
    );
    final vendorJobs = ref.watch(vendorJobsProvider);

    // One "N open" figure beside the mode switch, whatever the lens: the eye
    // sees "Board — 14 open" in one place.
    final openCount = mode == _BoardMode.vendors
        ? vendorJobs.value?.length
        : tasks.value?.length;

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
          child: ScreenHeader(
            title: 'Production',
            subtitle: 'Everything still in the shop, by stage — or out with a vendor.',
            actions: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SegmentedButton<_BoardMode>(
                    segments: const <ButtonSegment<_BoardMode>>[
                      ButtonSegment<_BoardMode>(
                        value: _BoardMode.board,
                        label: Text('Board'),
                      ),
                      ButtonSegment<_BoardMode>(
                        value: _BoardMode.mine,
                        label: Text('My work'),
                      ),
                      ButtonSegment<_BoardMode>(
                        value: _BoardMode.vendors,
                        label: Text('Vendors'),
                      ),
                    ],
                    selected: <_BoardMode>{mode},
                    onSelectionChanged: (selection) =>
                        setState(() => _mode = selection.first),
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (openCount != null) ...<Widget>[
                    const SizedBox(width: StarSpace.md),
                    Text(
                      '$openCount open',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: mode == _BoardMode.vendors
              ? _VendorsView(
                  jobs: vendorJobs,
                  vendors: ref.watch(boardVendorsProvider),
                  orders: ref.watch(ordersProvider),
                )
              : tasks.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('Could not read tasks: $error')),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return EmptyState(
                        icon: Icons.checklist_rtl,
                        title: mode == _BoardMode.mine
                            ? 'Nothing on your plate'
                            : 'Nothing in production',
                        message: mode == _BoardMode.mine
                            ? 'Work assigned to you, or waiting for your role, appears here.'
                            : 'Confirm an order and its stages appear here, one column each.',
                      );
                    }
                    return mode == _BoardMode.mine
                        ? _MyWorkList(tasks: rows, session: session)
                        : _Board(tasks: rows, session: session);
                  },
                ),
        ),
      ],
    );
  }
}

/// The presentation order for open vendor jobs: what is out first, then what
/// has come back, then what has not left yet — the order a coordinator actually
/// works in.
const List<String> _vendorStatusOrder = <String>['sent', 'received', 'draft'];

/// How a vendor-job status is shown: a word, a tone and an icon. Colour is
/// never the only signal (the chip carries all three), so the record holds all
/// three together.
typedef _VendorStatus = ({String label, StatusTone tone, IconData icon});

_VendorStatus _vendorStatus(String status) => switch (status) {
  'draft' => (label: 'Draft', tone: StatusTone.neutral, icon: Icons.edit_note),
  'sent' => (
    label: 'With vendor',
    tone: StatusTone.active,
    icon: Icons.outbox_outlined,
  ),
  'received' => (
    label: 'Back',
    tone: StatusTone.paused,
    icon: Icons.inbox_outlined,
  ),
  'closed' => (
    label: 'Closed',
    tone: StatusTone.done,
    icon: Icons.check_circle_outline,
  ),
  'cancelled' => (
    label: 'Cancelled',
    tone: StatusTone.problem,
    icon: Icons.cancel_outlined,
  ),
  _ => (label: status, tone: StatusTone.neutral, icon: Icons.circle_outlined),
};

/// The Vendors lens of the board: open vendor jobs grouped by how far they have
/// got. Read-only and local — actions (send / back / close) stay in the vendors
/// screen, this view only makes the work visible beside in-house work.
class _VendorsView extends StatelessWidget {
  const _VendorsView({
    required this.jobs,
    required this.vendors,
    required this.orders,
  });

  final AsyncValue<List<VendorJob>> jobs;
  final AsyncValue<List<Vendor>> vendors;
  final AsyncValue<List<Order>> orders;

  @override
  Widget build(BuildContext context) {
    return jobs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Could not read vendor jobs: $error')),
      data: (rows) {
        if (rows.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Nothing out with vendors',
            message: 'Out-sourced jobs appear here once an item is sent to a vendor.',
          );
        }

        // Name and order are separate tables keyed by id; resolve once so each
        // card only looks up, never queries.
        final vendorById = <String, Vendor>{
          for (final vendor in vendors.value ?? const <Vendor>[])
            vendor.id: vendor,
        };
        final orderById = <String, Order>{
          for (final order in orders.value ?? const <Order>[]) order.id: order,
        };

        // Fixed order first, then any status the query returns that we did not
        // anticipate — so a job is never silently hidden.
        final statuses = <String>[..._vendorStatusOrder];
        for (final job in rows) {
          if (!statuses.contains(job.status)) statuses.add(job.status);
        }
        final groups = <String, List<VendorJob>>{
          for (final status in statuses) status: <VendorJob>[],
        };
        for (final job in rows) {
          groups[job.status]!.add(job);
        }

        return ListView(
          padding: const EdgeInsets.all(StarSpace.lg),
          children: <Widget>[
            for (final status in statuses)
              if (groups[status]!.isNotEmpty) ...<Widget>[
                StarSectionHeader(
                  title: _vendorStatus(status).label,
                  count: groups[status]!.length,
                ),
                for (final job in groups[status]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: StarSpace.sm),
                    child: _VendorJobCard(
                      job: job,
                      vendor: vendorById[job.vendorId],
                      order: orderById[job.orderId],
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }
}

class _VendorJobCard extends StatelessWidget {
  const _VendorJobCard({
    required this.job,
    required this.vendor,
    required this.order,
  });

  final VendorJob job;
  final Vendor? vendor;
  final Order? order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _vendorStatus(job.status);

    return PressableCard(
      // Actions live in the vendors screen; here the card only reports, so it
      // is deliberately not tappable.
      onTap: null,
      padding: const EdgeInsets.all(StarSpace.sm),
      borderRadius: StarRadius.field,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.storefront_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: StarSpace.xs),
              Expanded(
                child: Text(
                  vendor?.name ?? 'Vendor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: StarSpace.xs),
              StatusChip(
                label: status.label,
                tone: status.tone,
                icon: status.icon,
              ),
            ],
          ),
          const SizedBox(height: StarSpace.xs),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          // The order this work belongs to, when the row is still around to
          // name it — older jobs whose order has gone keep the card, not the
          // broken line.
          if (order != null) ...<Widget>[
            const SizedBox(height: StarSpace.xs),
            Row(
              children: <Widget>[
                Icon(
                  Icons.receipt_long_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${order!.numberDisplay} · ${order!.customerName ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: StarSpace.sm),
          Row(
            children: <Widget>[
              Text(
                'Costs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: StarSpace.xs),
              MoneyText(Fils(job.costFils), emphasise: true),
            ],
          ),
        ],
      ),
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

/// A column with more open tasks than this is a bottleneck, not a queue. There
/// is no per-stage WIP limit in the schema yet (adding one is a backend
/// change), so the board owns a single threshold; the day the limit becomes a
/// stage field, this constant moves there.
const int _stageCapacity = 6;

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
    final overCapacity = tasks.length > _stageCapacity;

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
          Container(
            decoration: BoxDecoration(
              // Over capacity, the header carries a subtle ember wash AND the
              // count in words ("12 waiting") — colour never stands alone.
              color: overCapacity
                  ? StarColors.ember.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(StarRadius.card),
              ),
            ),
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
                if (overCapacity)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: StarColors.ember,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tasks.length} waiting',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: StarColors.ember,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
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
          // PressableCard is the surface now — no Card wrapper, so the row
          // lifts on hover and settles on press like every other door.
          child: _TaskCard(task: task, session: session, flat: true),
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

    final card = PressableCard(
      onTap: () => showTaskSheet(context, task, session),
      padding: const EdgeInsets.all(StarSpace.sm),
      borderRadius: StarRadius.field,
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
    );

    if (flat) return card;

    // A card someone is working on right now carries an ember ring; the word
    // "Working" is on the status chip, so colour is never the only signal.
    final inProgress = status == TaskStatus.inProgress;
    return Container(
      margin: const EdgeInsets.only(bottom: StarSpace.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StarRadius.field),
        border: inProgress
            ? Border.all(
                color: StarColors.ember.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
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
