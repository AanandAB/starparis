import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../sales/till_sheet.dart';
import 'orders_screen.dart';

/// Tab indices in the shell: Today, Customers, Orders, Production, [Prices],
/// [Reports]. Constants, so a screen can send the user somewhere without
/// knowing how the navigation is drawn.
abstract final class HomeTabs {
  static const int home = 0;
  static const int customers = 1;
  static const int orders = 2;
  static const int production = 3;

  /// The quick-sale (POS) tab. It is always the first optional page, so its
  /// index is stable at 4 for every role that has it — a counter lands here on
  /// sign-in. Keep it first among the optional destinations in `shell.dart`.
  static const int pos = 4;
}

/// Today — the screen the shop opens in the morning.
///
/// Every figure here is a door: a number the owner cannot act on is decoration.
/// All of it is read from the local database, so the dashboard is right on a
/// dead connection — which is the point of the whole product.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final db = ref.watch(bootstrapProvider).db;
    final t = ref.watch(stringsProvider);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    bool isOpen(Task task) =>
        task.status != 'done' && task.status != 'cancelled';

    return StreamBuilder<List<Task>>(
      stream: db.watchActiveTasks(),
      builder: (context, taskSnapshot) {
        final tasks = taskSnapshot.data ?? const <Task>[];
        final loading = taskSnapshot.connectionState == ConnectionState.waiting;

        return StreamBuilder<List<Order>>(
          stream: db.watchOrders(),
          builder: (context, orderSnapshot) {
            final orders = orderSnapshot.data ?? const <Order>[];

            final overdue = tasks
                .where(
                  (task) =>
                      isOpen(task) &&
                      task.dueAt != null &&
                      task.dueAt!.isBefore(now),
                )
                .toList(growable: false);

            final dueToday = tasks
                .where(
                  (task) =>
                      isOpen(task) &&
                      task.dueAt != null &&
                      !task.dueAt!.isBefore(startOfToday) &&
                      task.dueAt!.isBefore(endOfToday),
                )
                .toList(growable: false);

            final inProgress = tasks
                .where((task) => task.status == 'in_progress')
                .toList(growable: false);

            // Work nobody has picked up, filtered to what this person may take.
            final unclaimed = tasks
                .where(
                  (task) =>
                      task.status == 'available' &&
                      (session.isOwner ||
                          session.role == 'manager' ||
                          task.requiredRole == session.role),
                )
                .toList(growable: false);

            final ordersDueToday = orders
                .where(
                  (order) =>
                      order.dueAt != null &&
                      !order.dueAt!.isBefore(startOfToday) &&
                      order.dueAt!.isBefore(endOfToday) &&
                      order.status != 'delivered' &&
                      order.status != 'cancelled',
                )
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.all(StarSpace.lg),
              children: <Widget>[
                _Greeting(
                  name: session.name,
                  role: session.role,
                  onNewOrder: session.canCreateOrders
                      ? () => openOrderBuilder(context)
                      : null,
                  newOrderLabel: t('today.newOrder'),
                ),
                const SizedBox(height: StarSpace.lg),
                if (loading)
                  const StarSkeletonList(rows: 2, rowHeight: 84)
                else
                  _StatGrid(
                    stats: <Widget>[
                      _AnimatedStat(
                        label: t('today.inProduction'),
                        value: inProgress.length,
                        format: _count,
                        hint: inProgress.isEmpty
                            ? t('today.nothingOnMachine')
                            : t('today.onMachine'),
                        icon: Icons.precision_manufacturing_outlined,
                        onTap: () => ref
                            .read(shellTabProvider.notifier)
                            .select(HomeTabs.production),
                      ),
                      _AnimatedStat(
                        label: t('today.overdue'),
                        value: overdue.length,
                        format: _count,
                        hint: overdue.isEmpty
                            ? t('today.nothingLate')
                            : t('today.overdueHint'),
                        icon: Icons.warning_amber_outlined,
                        tone: overdue.isEmpty
                            ? StarStatTone.positive
                            : StarStatTone.danger,
                        onTap: () => ref
                            .read(shellTabProvider.notifier)
                            .select(HomeTabs.production),
                      ),
                      _AnimatedStat(
                        label: t('today.dueToday'),
                        value: ordersDueToday.length,
                        format: _count,
                        hint: ordersDueToday.isEmpty
                            ? t('today.noPromiseToday')
                            : t('today.promisedToday'),
                        icon: Icons.event_available_outlined,
                        tone: ordersDueToday.isEmpty
                            ? StarStatTone.neutral
                            : StarStatTone.warning,
                        onTap: () => ref
                            .read(shellTabProvider.notifier)
                            .select(HomeTabs.orders),
                      ),
                      _AnimatedStat(
                        label: t('today.waitingForYou'),
                        value: unclaimed.length,
                        format: _count,
                        hint: unclaimed.isEmpty
                            ? t('today.queueClear')
                            : t('today.unclaimed'),
                        icon: Icons.pan_tool_outlined,
                        onTap: () => ref
                            .read(shellTabProvider.notifier)
                            .select(HomeTabs.production),
                      ),
                    ],
                  ),
                const SizedBox(height: StarSpace.xl),
                if (overdue.isNotEmpty) ...<Widget>[
                  StarSectionHeader(
                    title: t('today.overdueTitle'),
                    subtitle: t('today.overdueSubtitle'),
                    count: overdue.length,
                    trailing: _seeAll(
                      t('common.board'),
                      () => ref
                          .read(shellTabProvider.notifier)
                          .select(HomeTabs.production),
                    ),
                  ),
                  _TaskList(tasks: overdue.take(4).toList(growable: false)),
                  const SizedBox(height: StarSpace.xl),
                ],
                if (dueToday.isNotEmpty) ...<Widget>[
                  StarSectionHeader(
                    title: t('today.dueTodayTitle'),
                    count: dueToday.length,
                    trailing: _seeAll(
                      'Board',
                      () => ref
                          .read(shellTabProvider.notifier)
                          .select(HomeTabs.production),
                    ),
                  ),
                  _TaskList(tasks: dueToday.take(4).toList(growable: false)),
                  const SizedBox(height: StarSpace.xl),
                ],
                if (unclaimed.isNotEmpty) ...<Widget>[
                  StarSectionHeader(
                    title: t('today.waitingTitle'),
                    subtitle: session.isOwner || session.role == 'manager'
                        ? t('today.waitingSubtitleAll')
                        : t('today.waitingSubtitle'),
                    count: unclaimed.length,
                    trailing: _seeAll(
                      t('common.myWork'),
                      () => ref
                          .read(shellTabProvider.notifier)
                          .select(HomeTabs.production),
                    ),
                  ),
                  _TaskList(tasks: unclaimed.take(4).toList(growable: false)),
                  const SizedBox(height: StarSpace.xl),
                ],
                const _ProofsWaiting(),
                const _CashToday(),
                const SizedBox(height: StarSpace.lg),
                if (!loading &&
                    overdue.isEmpty &&
                    dueToday.isEmpty &&
                    unclaimed.isEmpty &&
                    inProgress.isEmpty)
                  EmptyState(
                    icon: Icons.check_circle_outline,
                    title: t('today.nothingNeedsYou'),
                    message: t('today.nothingNeedsYouBody'),
                  ),
                const SizedBox(height: StarSpace.xxl),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _seeAll(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: StarSpace.sm),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 12)),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.role,
    required this.newOrderLabel,
    this.onNewOrder,
  });

  final String name;
  final String role;
  final String newOrderLabel;
  final VoidCallback? onNewOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$greeting, ${name.split(' ').first}',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${_date(DateTime.now())} · ${role.replaceAll('_', ' ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onNewOrder != null)
          FilledButton.icon(
            onPressed: onNewOrder,
            icon: const Icon(Icons.add, size: 18),
            label: Text(newOrderLabel),
          ),
      ],
    );
  }

  static String _date(DateTime value) {
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    return '${days[value.weekday - 1]} ${value.day} ${months[value.month - 1]}';
  }
}

/// The tiles share the width rather than scrolling sideways: a counter PC is
/// wide, and the owner should see all four figures without moving anything.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<Widget> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const gap = StarSpace.md;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final stat in stats) SizedBox(width: width, child: stat),
          ],
        );
      },
    );
  }
}

/// A count is a plain integer; money (the cash figure) supplies its own fils
/// formatter through [AnimatedCount.format] instead.
String _count(int value) => '$value';

/// A door with a live number: the value counts from its old self to the new one
/// ([AnimatedCount]) and the tile lifts on hover ([PressableCard]) so a clerk
/// sees it is a door before clicking. Same anatomy as the design system's
/// StarStat, but the value is animated and set in the display scale, so it
/// cannot reuse StarStat directly.
class _AnimatedStat extends StatelessWidget {
  const _AnimatedStat({
    required this.label,
    required this.value,
    required this.format,
    this.hint,
    this.icon,
    this.tone = StarStatTone.neutral,
    this.onTap,
  });

  final String label;
  final int value;
  final String Function(int value) format;
  final String? hint;
  final IconData? icon;
  final StarStatTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tone) {
      StarStatTone.neutral => theme.colorScheme.primary,
      StarStatTone.positive => StarColors.statusDone,
      StarStatTone.warning => StarColors.statusPaused,
      StarStatTone.danger => StarColors.statusProblem,
    };

    return PressableCard(
      onTap: onTap,
      enabled: onTap != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StarRadius.field),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
              if (icon != null) const SizedBox(width: StarSpace.sm),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StarSpace.sm),
          AnimatedCount(
            value: value,
            format: format,
            style: theme.textTheme.displayMedium?.copyWith(
              color: tone == StarStatTone.neutral
                  ? theme.colorScheme.onSurface
                  : accent,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hint!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < tasks.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1),
            _TaskRow(task: tasks[i]),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final late =
        task.dueAt != null &&
        task.dueAt!.isBefore(DateTime.now()) &&
        task.status != 'done';

    return ListTile(
      dense: true,
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        task.dueAt == null
            ? task.stageName
            : '${task.stageName} · ${_dueLabel(task.dueAt!, late)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: late
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: late ? FontWeight.w600 : null,
        ),
      ),
      trailing: StatusChip(
        label: _statusLabel(task.status),
        tone: _tone(task.status),
      ),
    );
  }

  static String _dueLabel(DateTime due, bool late) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final days = day.difference(today).inDays;
    if (days == 0) return late ? 'due earlier today' : 'due today';
    if (days == 1) return 'due tomorrow';
    if (days < 0) return '${-days} ${-days == 1 ? 'day' : 'days'} late';
    return 'in $days days';
  }

  static String _statusLabel(String status) => switch (status) {
    'available' => 'Open',
    'assigned' => 'Claimed',
    'in_progress' => 'Running',
    'paused' => 'Paused',
    'rework' => 'Rework',
    'waiting' => 'Waiting',
    'done' => 'Done',
    'cancelled' => 'Cancelled',
    _ => status,
  };

  static StatusTone _tone(String status) => switch (status) {
    'assigned' || 'in_progress' => StatusTone.active,
    'paused' => StatusTone.paused,
    'rework' => StatusTone.problem,
    'done' => StatusTone.done,
    _ => StatusTone.neutral,
  };
}

/// Proofs that went out and have not come back: the jobs that stall silently,
/// which is why they get their own block rather than a filter on the board.
class _ProofsWaiting extends ConsumerWidget {
  const _ProofsWaiting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bootstrapProvider).db;
    final t = ref.watch(stringsProvider);

    return StreamBuilder<List<Proof>>(
      stream: db.watchProofsAwaitingDecision(),
      builder: (context, snapshot) {
        final proofs = snapshot.data ?? const <Proof>[];
        if (proofs.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: StarSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StarSectionHeader(
                title: t('today.onCustomer'),
                subtitle: t('today.onCustomerSubtitle'),
                count: proofs.length,
              ),
              Card(
                child: Column(
                  children: <Widget>[
                    for (
                      var i = 0;
                      i < proofs.length && i < 4;
                      i++
                    ) ...<Widget>[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.draw_outlined, size: 18),
                        title: Text(
                          '${proofs[i].label} · v${proofs[i].revision}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          proofs[i].sentAt == null
                              ? 'not sent yet'
                              : 'sent ${_ago(proofs[i].sentAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => ref
                              .read(shellTabProvider.notifier)
                              .select(HomeTabs.orders),
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _ago(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Cash in the drawer, today. Only shown while a shift is open, because a
/// figure nobody can act on is noise.
class _CashToday extends ConsumerWidget {
  const _CashToday();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bootstrapProvider).db;
    final t = ref.watch(stringsProvider);

    return StreamBuilder<TillSession?>(
      stream: db.watchOpenTill(),
      builder: (context, snapshot) {
        final till = snapshot.data;
        if (till == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: StarSpace.xl),
          child: FutureBuilder<int>(
            future: db.cashTakenSince(till.openedAt),
            builder: (context, cashSnapshot) {
              final cash = cashSnapshot.data ?? 0;
              return _AnimatedStat(
                label: t('today.cashToday'),
                value: cash,
                // Money formats through the fils formatter so the animated
                // count shows the same AED label the rest of the app uses.
                format: (value) => Fils(value).aedLabel,
                hint:
                    'in the drawer since the shift opened · should be '
                    '${Fils(till.openingFloatFils + cash).aedLabel} with the float',
                icon: Icons.point_of_sale_outlined,
                onTap: () => showTillSheet(context),
              );
            },
          ),
        );
      },
    );
  }
}
