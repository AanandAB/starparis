import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import 'board_screen.dart';
import 'orders_screen.dart';

final StreamProvider<List<Order>> _ordersProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(bootstrapProvider).db.watchOrders(limit: 400),
);

final StreamProvider<List<Proof>> _proofsAwaitingProvider =
    StreamProvider<List<Proof>>(
      (ref) => ref.watch(bootstrapProvider).db.watchProofsAwaitingDecision(),
    );

/// Tab indices in the shell: Home, Customers, Orders, Production, [Prices].
abstract final class HomeTabs {
  static const int home = 0;
  static const int customers = 1;
  static const int orders = 2;
  static const int production = 3;
}

/// The role-shaped home screen.
///
/// Every number here comes from the local database, so it is right offline and
/// updates the moment work moves. Nothing is a placeholder: a manager who sees a
/// dashboard that does not work stops trusting the parts that do.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    final sync = ref.watch(syncStateProvider).value;

    final myTasks = (ref.watch(myTasksProvider).value ?? const <Task>[])
        .where((task) => task.status != 'done')
        .toList();
    final orders = ref.watch(_ordersProvider).value ?? const <Order>[];
    final proofs = ref.watch(_proofsAwaitingProvider).value ?? const <Proof>[];
    final customers =
        ref.watch(allCustomersProvider).value ?? const <Customer>[];

    final today = DateUtils.dateOnly(DateTime.now());
    final dueToday = myTasks
        .where(
          (task) =>
              task.dueAt != null && DateUtils.isSameDay(task.dueAt, today),
        )
        .length;
    final overdue = myTasks
        .where((task) => task.dueAt != null && task.dueAt!.isBefore(today))
        .length;
    final rework = myTasks.where((task) => task.status == 'rework').length;
    final ready = orders.where((order) => order.status == 'ready').length;
    final open = myTasks.length;

    final role = session?.role ?? 'counter';
    final isManager = role == 'owner' || role == 'manager';

    final stats = <Widget>[
      if (isManager || role == 'vendor_coordinator')
        _StatCard(
          label: 'Open tasks',
          value: '$open',
          icon: Icons.checklist_rtl,
        ),
      if (isManager || role == 'operator' || role == 'designer')
        _StatCard(
          label: 'Due today',
          value: '$dueToday',
          icon: Icons.today,
          tone: dueToday > 0 ? StarColors.statusActive : null,
        ),
      if (isManager || role == 'designer' || role == 'counter')
        _StatCard(
          label: 'Proofs waiting',
          value: '${proofs.length}',
          icon: Icons.fact_check_outlined,
          tone: proofs.isEmpty ? null : StarColors.statusPaused,
        ),
      if (isManager ||
          role == 'driver' ||
          role == 'accountant' ||
          role == 'counter')
        _StatCard(
          label: 'Ready to collect',
          value: '$ready',
          icon: Icons.shopping_bag_outlined,
          tone: ready > 0 ? StarColors.statusDone : null,
        ),
      if (role == 'designer')
        _StatCard(
          label: 'Sent back',
          value: '$rework',
          icon: Icons.replay,
          tone: rework > 0 ? StarColors.statusProblem : null,
        ),
      if (overdue > 0)
        _StatCard(
          label: 'Overdue',
          value: '$overdue',
          icon: Icons.warning_amber_rounded,
          tone: StarColors.statusProblem,
        ),
      if (role == 'counter' || role == 'accountant')
        _StatCard(
          label: 'Customers',
          value: '${customers.length}',
          icon: Icons.people_outline,
        ),
      _StatCard(
        label: pending == 0 ? 'All changes sent' : 'Waiting to upload',
        value: '$pending',
        icon: pending == 0
            ? Icons.cloud_done_outlined
            : Icons.cloud_upload_outlined,
        tone: pending > 0 ? StarColors.statusPaused : StarColors.statusDone,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(StarSpace.lg),
      children: <Widget>[
        Text(
          'Good ${_partOfDay()}, ${session?.name ?? ''}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: StarSpace.xs),
        Text(
          '${role.replaceAll('_', ' ')} · '
          '${sync?.phase == SyncPhase.offline ? 'offline — everything is saved locally' : 'connected and syncing'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StarSpace.lg),
        Wrap(spacing: StarSpace.md, runSpacing: StarSpace.md, children: stats),
        const SizedBox(height: StarSpace.xl),
        Text('Your next step', style: theme.textTheme.titleMedium),
        const SizedBox(height: StarSpace.md),
        _primaryAction(context, ref, role),
        const SizedBox(height: StarSpace.lg),
        Text('Go to', style: theme.textTheme.titleMedium),
        const SizedBox(height: StarSpace.md),
        _ActionCard(
          icon: Icons.view_kanban_outlined,
          title: 'Production board',
          subtitle: open == 0
              ? 'Nothing in the shop right now.'
              : '$open task${open == 1 ? '' : 's'} open, $dueToday due today.',
          onTap: () =>
              ref.read(shellTabProvider.notifier).select(HomeTabs.production),
        ),
        const SizedBox(height: StarSpace.md),
        _ActionCard(
          icon: Icons.receipt_long_outlined,
          title: 'Orders and quotes',
          subtitle: '${orders.length} in view, $ready ready to collect.',
          onTap: () =>
              ref.read(shellTabProvider.notifier).select(HomeTabs.orders),
        ),
        const SizedBox(height: StarSpace.md),
        _ActionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Customers',
          subtitle: 'Find by phone number; ${customers.length} saved.',
          onTap: () =>
              ref.read(shellTabProvider.notifier).select(HomeTabs.customers),
        ),
      ],
    );
  }

  /// One obvious thing to do next, chosen by what the person does all day.
  /// A designer starts from their queue, never from "new order".
  Widget _primaryAction(BuildContext context, WidgetRef ref, String role) {
    switch (role) {
      case 'designer':
      case 'operator':
        return _ActionCard(
          icon: Icons.play_circle_outline,
          title: 'Open my work',
          subtitle: 'Claim the next job from the pool and start it.',
          onTap: () =>
              ref.read(shellTabProvider.notifier).select(HomeTabs.production),
        );
      case 'manager':
      case 'owner':
        return _ActionCard(
          icon: Icons.view_kanban_outlined,
          title: 'Watch the board',
          subtitle: 'What is where, and who is holding it up.',
          onTap: () =>
              ref.read(shellTabProvider.notifier).select(HomeTabs.production),
        );
      case 'driver':
        return _ActionCard(
          icon: Icons.local_shipping_outlined,
          title: 'Deliveries ready',
          subtitle: 'Jobs finished and waiting to go out.',
          onTap: () =>
              ref.read(shellTabProvider.notifier).select(HomeTabs.orders),
        );
      default:
        return _ActionCard(
          icon: Icons.add_shopping_cart,
          title: 'New order',
          subtitle: 'Pick a product, see the price, confirm. Works offline.',
          onTap: () => openOrderBuilder(context),
        );
    }
  }

  static String _partOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(StarSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 18, color: tone ?? theme.colorScheme.primary),
              const SizedBox(height: StarSpace.md),
              Text(value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: StarSpace.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StarRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(StarSpace.lg),
          child: Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: StarSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
