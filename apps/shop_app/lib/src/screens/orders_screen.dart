import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import 'order_builder_screen.dart';

/// Today's work, newest first. The job number is the biggest thing on the row
/// because it is the only thing a customer ever says on the phone.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orders = ref.watch(ordersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.lg,
            StarSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Orders', style: theme.textTheme.titleLarge),
                    Text(
                      'Everything saved on this device, including work still waiting to upload.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: StarSpace.md),
              FilledButton.icon(
                onPressed: () => openOrderBuilder(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New order'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: orders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Could not read orders',
              message: '$error',
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'A repeat order takes under a minute; a new one about two.',
                  actionLabel: 'Create the first order',
                  onAction: () => openOrderBuilder(context),
                );
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _OrderRow(order: rows[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> openOrderBuilder(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const OrderBuilderScreen()),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingNumber = order.numberDisplay.startsWith('T-');
    final pendingUpload = order.version == 0;

    return ListTile(
      leading: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              order.numberDisplay,
              style: theme.textTheme.titleSmall?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            if (pendingNumber)
              Text(
                'pending',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: StarColors.statusPaused,
                ),
              ),
          ],
        ),
      ),
      title: Text(order.customerName ?? 'Customer'),
      subtitle: Text(
        <String>[
          '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
          order.priority == 'normal' ? 'standard' : order.priority,
          if (order.dueAt != null)
            'due ${order.dueAt!.day}/${order.dueAt!.month}',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          MoneyText(Fils(order.totalFils), emphasise: true),
          const SizedBox(height: 4),
          if (pendingUpload)
            const StatusChip(
              label: 'Waiting to upload',
              tone: StatusTone.paused,
              icon: Icons.cloud_upload_outlined,
            )
          else
            StatusChip(
              label: _statusLabel(order.status),
              tone: _statusTone(order.status),
            ),
        ],
      ),
      onTap: () => _showSummary(context, order),
    );
  }

  static void _showSummary(BuildContext context, Order order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
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
            Text(
              'Job ${order.numberDisplay}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: StarSpace.md),
            _SummaryRow(label: 'Customer', value: order.customerName ?? '—'),
            _SummaryRow(label: 'Status', value: _statusLabel(order.status)),
            _SummaryRow(label: 'Priority', value: order.priority),
            _SummaryRow(
              label: 'Subtotal',
              value: Fils(order.subtotalFils).aedLabel,
            ),
            _SummaryRow(label: 'VAT', value: Fils(order.vatFils).aedLabel),
            _SummaryRow(
              label: 'Total',
              value: Fils(order.totalFils).aedLabel,
              emphatic: true,
            ),
            const SizedBox(height: StarSpace.md),
            Text(
              'The job ticket, tasks and production stages arrive in Phase 3.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
    'draft' => 'Draft',
    'confirmed' => 'Confirmed',
    'in_production' => 'In production',
    'ready' => 'Ready',
    'delivered' => 'Delivered',
    _ => status,
  };

  static StatusTone _statusTone(String status) => switch (status) {
    'ready' => StatusTone.done,
    'in_production' => StatusTone.active,
    'delivered' => StatusTone.done,
    _ => StatusTone.neutral,
  };
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphatic = false,
  });

  final String label;
  final String value;
  final bool emphatic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: emphatic
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
