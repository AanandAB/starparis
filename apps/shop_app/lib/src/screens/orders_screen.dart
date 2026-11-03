import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/documents_service.dart';
import '../sales/proofs_section.dart';
import '../sales/whatsapp.dart';
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
      onTap: () => showOrderSheet(context, order),
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

Future<void> showOrderSheet(BuildContext context, Order order) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _OrderSheet(order: order),
  );
}

class _OrderSheet extends ConsumerStatefulWidget {
  const _OrderSheet({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<_OrderSheet> {
  bool _busy = false;

  Future<void> _makeDocument({required bool quote}) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = DocumentsService(db: ref.read(bootstrapProvider).db);
      final file = quote
          ? await service.quoteFor(widget.order)
          : await service.jobTicketFor(widget.order);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${file.path.split(Platform.pathSeparator).last}',
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openPath(file.path),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not build the PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(bootstrapProvider).db;
    final phone = await db.primaryPhoneFor(widget.order.customerId);
    if (phone == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No phone number saved for this customer.'),
        ),
      );
      return;
    }

    final order = widget.order;
    final message = order.isQuote
        ? WhatsApp.quoteMessage(
            customerName: order.customerName ?? 'there',
            quoteNumber: order.numberDisplay,
            total: Fils(order.totalFils).aedLabel,
            shopName: AppConfig.company.name,
            validUntil: _formatDate(
              order.createdAt.add(const Duration(days: 7)),
            ),
          )
        : WhatsApp.readyMessage(
            customerName: order.customerName ?? 'there',
            jobNumber: order.numberDisplay,
            total: Fils(order.totalFils).aedLabel,
            shopName: AppConfig.company.name,
          );

    final opened = await WhatsApp.open(phoneE164: phone, message: message);
    if (!opened && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('WhatsApp did not open. Is it installed?'),
        ),
      );
    }
  }

  Future<void> _convert() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert quote to order'),
        content: Text(
          'This creates a job from quote ${widget.order.numberDisplay} and locks '
          'the prices exactly as quoted. The quote is marked converted.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      final issued = await NumberSeries(
        db: bootstrap.db,
        api: bootstrap.api,
        series: 'JOB',
      ).next();

      await bootstrap.db.convertQuoteToOrder(
        quoteId: widget.order.id,
        numberDisplay: issued.display,
        number: issued.number,
        userId: session.userId,
      );
      unawaited(bootstrap.engine?.syncNow() ?? Future<void>.value());

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Order ${issued.display} created from quote ${widget.order.numberDisplay}.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not convert: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static Future<void> _openPath(String path) async {
    if (Platform.isWindows) {
      await Process.run('cmd', <String>['/c', 'start', '', path]);
    } else {
      await launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);
    }
  }

  static String _formatDate(DateTime value) {
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

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
                  '${order.isQuote ? 'Quote' : 'Job'} ${order.numberDisplay}',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (order.isQuote)
                const StatusChip(label: 'Quote', tone: StatusTone.paused),
            ],
          ),
          const SizedBox(height: StarSpace.md),
          _SummaryRow(label: 'Customer', value: order.customerName ?? '-'),
          _SummaryRow(
            label: 'Status',
            value: _OrderRow._statusLabel(order.status),
          ),
          _SummaryRow(label: 'Priority', value: order.priority),
          if (order.dueAt != null)
            _SummaryRow(
              label: 'Due',
              value:
                  '${order.dueAt!.day}/${order.dueAt!.month}/${order.dueAt!.year}',
            ),
          const Divider(height: StarSpace.lg),
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
          const Divider(height: StarSpace.lg),
          ProofsSection(order: order),
          const Divider(height: StarSpace.lg),
          _TimeLogged(order: order),
          const SizedBox(height: StarSpace.lg),
          Wrap(
            spacing: StarSpace.sm,
            runSpacing: StarSpace.sm,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _makeDocument(quote: true),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Quote PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _makeDocument(quote: false),
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('Job ticket'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _openWhatsApp,
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('WhatsApp'),
              ),
              if (order.isQuote)
                FilledButton.icon(
                  onPressed: _busy ? null : _convert,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Convert to order'),
                ),
            ],
          ),
          const SizedBox(height: StarSpace.sm),
          Text(
            'Documents are saved to Documents/StarParis. WhatsApp opens with the '
            'message written; you review and send it yourself.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minutes the server recorded for this job, from time_entries.
class _TimeLogged extends ConsumerWidget {
  const _TimeLogged({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(bootstrapProvider).db;
    return FutureBuilder<int>(
      future: db.minutesForOrder(order.id),
      builder: (context, snapshot) {
        final minutes = snapshot.data ?? 0;
        if (minutes == 0) return const SizedBox.shrink();
        final hours = minutes ~/ 60;
        final rest = minutes % 60;
        return _SummaryRow(
          label: 'Time logged',
          value: hours > 0 ? '${hours}h ${rest}m' : '${minutes}m',
        );
      },
    );
  }
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
