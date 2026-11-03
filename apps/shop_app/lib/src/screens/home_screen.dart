import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import 'orders_screen.dart';

/// The role-shaped home screen.
///
/// Phase 1B ships the frame and the customer directory; the order builder,
/// queues and boards arrive with their own phases. The screen says so plainly
/// instead of showing fake numbers — a manager who sees a dashboard that does
/// not work yet stops trusting the ones that do.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final customers =
        ref.watch(allCustomersProvider).value ?? const <Customer>[];
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    final sync = ref.watch(syncStateProvider).value;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(StarSpace.lg),
      children: <Widget>[
        Text(
          'Good ${_partOfDay()}, ${session?.name ?? ''}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: StarSpace.xs),
        Text(
          '${session?.role.replaceAll('_', ' ') ?? ''} · '
          '${sync?.phase == SyncPhase.offline ? 'offline — everything is saved locally' : 'connected and syncing'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StarSpace.lg),
        Wrap(
          spacing: StarSpace.md,
          runSpacing: StarSpace.md,
          children: <Widget>[
            _StatCard(
              label: 'Customers',
              value: '${customers.length}',
              icon: Icons.people_outline,
            ),
            _StatCard(
              label: 'Waiting to upload',
              value: '$pending',
              icon: Icons.cloud_upload_outlined,
              tone: pending > 0
                  ? StarColors.statusPaused
                  : StarColors.statusDone,
            ),
            _StatCard(
              label: 'Last sync',
              value: sync?.lastSync == null
                  ? '—'
                  : TimeOfDay.fromDateTime(sync!.lastSync!).format(context),
              icon: Icons.schedule,
            ),
          ],
        ),
        const SizedBox(height: StarSpace.xl),
        Text('Your next step', style: theme.textTheme.titleMedium),
        const SizedBox(height: StarSpace.md),
        _ActionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Add a customer',
          subtitle:
              'Phone number first — the counter can do it in ten seconds.',
          onTap: () => ref.read(shellTabProvider.notifier).select(1),
        ),
        const SizedBox(height: StarSpace.md),
        _ActionCard(
          icon: Icons.receipt_long_outlined,
          title: 'New order',
          subtitle: 'Pick a product, see the price, confirm. Works offline.',
          onTap: () => openOrderBuilder(context),
        ),
        const SizedBox(height: StarSpace.md),
        const _ActionCard(
          icon: Icons.view_kanban_outlined,
          title: 'Live board',
          subtitle: 'Phase 3, once tasks and workflows exist.',
          enabled: false,
        ),
      ],
    );
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
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = enabled ? theme.colorScheme.primary : theme.disabledColor;
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(StarRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(StarSpace.lg),
          child: Row(
            children: <Widget>[
              Icon(icon, color: colour),
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
              if (enabled) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
