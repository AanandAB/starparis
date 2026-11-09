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
import '../sales/invoice_section.dart';
import '../sales/number_prefixes.dart';
import '../sales/proofs_section.dart';
import '../sales/whatsapp.dart';
import 'order_builder_screen.dart';

/// Today's work, newest first. The job number is the biggest thing on the row
/// because it is the only thing a customer ever says on the phone.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _selecting = false;
  final Set<String> _selected = <String>{};
  bool _busy = false;

  void _toggleSelected(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _toggleSelectAll(List<Order> rows) {
    setState(() {
      if (_selected.length == rows.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(rows.map((order) => order.id));
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _bulkStatus(List<Order> rows, String status) async {
    final ids = rows
        .where((order) => _selected.contains(order.id))
        .map((order) => order.id)
        .toList();
    if (ids.isEmpty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final label = _orderStatus(status).label;
    try {
      final db = ref.read(bootstrapProvider).db;
      for (final id in ids) {
        await db.setOrderStatus(id: id, status: status);
      }
      unawaited(
        ref.read(bootstrapProvider).engine?.syncNow() ?? Future<void>.value(),
      );
      if (!mounted) return;
      _exitSelection();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Moved ${ids.length} ${ids.length == 1 ? 'order' : 'orders'} to $label.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bulkDelete(List<Order> rows) async {
    final ids = rows
        .where((order) => _selected.contains(order.id))
        .map((order) => order.id)
        .toList();
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete these orders?'),
        content: Text(
          '${ids.length} ${ids.length == 1 ? 'order' : 'orders'} will be removed from '
          'this device and the server. A mistake is not recoverable from the counter.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bootstrapProvider).db.deleteOrders(ids: ids);
      unawaited(
        ref.read(bootstrapProvider).engine?.syncNow() ?? Future<void>.value(),
      );
      if (!mounted) return;
      _exitSelection();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Deleted ${ids.length} ${ids.length == 1 ? 'order' : 'orders'}.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final rows = orders.value ?? const <Order>[];
    final allSelected = rows.isNotEmpty && _selected.length == rows.length;

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
          child: ScreenHeader(
            title: 'Orders',
            subtitle: _selecting
                ? '${_selected.length} of ${rows.length} selected'
                : 'Everything saved on this device, including work still waiting to upload.',
            actions: _selecting
                ? <Widget>[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _exitSelection,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                    ),
                  ]
                : <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _selecting = true),
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Select'),
                    ),
                    FilledButton.icon(
                      onPressed: () => openOrderBuilder(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New order'),
                    ),
                  ],
          ),
        ),
        if (_selecting) ...<Widget>[
          _SelectionBar(
            selectedCount: _selected.length,
            totalCount: rows.length,
            allSelected: allSelected,
            busy: _busy,
            onToggleSelectAll: () => _toggleSelectAll(rows),
            onStatus: (status) => _bulkStatus(rows, status),
            onDelete: () => _bulkDelete(rows),
          ),
          const Divider(height: 1),
        ],
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
                separatorBuilder: (_, index) =>
                    const SizedBox(height: StarSpace.sm),
                itemBuilder: (context, index) {
                  final order = rows[index];
                  return _OrderRow(
                    order: order,
                    selecting: _selecting,
                    selected: _selected.contains(order.id),
                    onToggle: () => _toggleSelected(order.id),
                  );
                },
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
  const _OrderRow({
    required this.order,
    this.selecting = false,
    this.selected = false,
    this.onToggle,
  });

  final Order order;
  final bool selecting;
  final bool selected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingNumber = order.numberDisplay.startsWith('T-');
    final pendingUpload = order.version == 0;
    final status = _orderStatus(order.status);
    final details = <String>[
      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
      order.priority == 'normal' ? 'standard' : order.priority,
      if (order.dueAt != null) 'due ${order.dueAt!.day}/${order.dueAt!.month}',
    ].join(' · ');

    // A hand-rolled row rather than a ListTile: the number block and the
    // status chip each have a real width, and on a phone a ListTile's fixed
    // leading + trailing squeeze the name down to nothing. Three stacked
    // lines — name + total, number + status, details — never fight for room.
    return PressableCard(
      onTap: selecting ? onToggle : () => showOrderSheet(context, order),
      padding: const EdgeInsets.all(StarSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (selecting)
            Padding(
              padding: const EdgeInsets.only(right: StarSpace.xs),
              child: Checkbox(
                value: selected,
                onChanged: (_) => onToggle?.call(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        order.customerName ?? 'Customer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: StarSpace.sm),
                    MoneyText(Fils(order.totalFils), emphasise: true),
                  ],
                ),
                const SizedBox(height: StarSpace.xs),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        order.numberDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (pendingNumber) ...<Widget>[
                      const SizedBox(width: StarSpace.xs),
                      Text(
                        'pending',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: StarColors.statusPaused,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (pendingUpload)
                      const StatusChip(
                        label: 'Waiting to upload',
                        tone: StatusTone.paused,
                        icon: Icons.cloud_upload_outlined,
                      )
                    else
                      StatusChip(
                        label: status.label,
                        tone: status.tone,
                        icon: status.icon,
                      ),
                  ],
                ),
                const SizedBox(height: StarSpace.xs),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How an order status is shown: a word, a tone and an icon. Colour is never
/// the only signal, so the chip carries all three.
typedef _OrderStatus = ({String label, StatusTone tone, IconData icon});

_OrderStatus _orderStatus(String status) => switch (status) {
  'draft' => (label: 'Draft', tone: StatusTone.neutral, icon: Icons.edit_note),
  'confirmed' => (
    label: 'Confirmed',
    tone: StatusTone.active,
    icon: Icons.check_circle_outline,
  ),
  'in_production' => (
    label: 'In production',
    tone: StatusTone.active,
    icon: Icons.play_circle_outline,
  ),
  'ready' => (
    label: 'Ready',
    tone: StatusTone.done,
    icon: Icons.inventory_2_outlined,
  ),
  'delivered' => (
    label: 'Delivered',
    tone: StatusTone.done,
    icon: Icons.local_shipping_outlined,
  ),
  'converted' => (
    label: 'Converted',
    tone: StatusTone.paused,
    icon: Icons.swap_horiz,
  ),
  _ => (label: status, tone: StatusTone.neutral, icon: Icons.circle_outlined),
};

/// The statuses the bulk menu offers, in the order the shop moves through them.
const List<String> _bulkStatuses = <String>[
  'draft',
  'confirmed',
  'in_production',
  'ready',
  'delivered',
];

/// The bar shown while orders are selected: select-all, a status menu and
/// delete. The destructive actions stay disabled until something is selected,
/// so a tap can never act on an empty set.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.allSelected,
    required this.busy,
    required this.onToggleSelectAll,
    required this.onStatus,
    required this.onDelete,
  });

  final int selectedCount;
  final int totalCount;
  final bool allSelected;
  final bool busy;
  final VoidCallback onToggleSelectAll;
  final ValueChanged<String> onStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = selectedCount > 0 && !busy;

    final selectAll = TextButton.icon(
      onPressed: busy ? null : onToggleSelectAll,
      icon: Icon(
        allSelected ? Icons.check_box : Icons.check_box_outline_blank,
        size: 18,
      ),
      label: Text(allSelected ? 'Clear' : 'Select all'),
    );
    final count = Text(
      '$selectedCount of $totalCount selected',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final delete = OutlinedButton.icon(
      onPressed: enabled ? onDelete : null,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.error,
        side: enabled
            ? BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              )
            : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StarSpace.lg,
        StarSpace.xs,
        StarSpace.lg,
        StarSpace.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < StarBreakpoints.compact) {
            // On a phone these five controls cannot share one line; the
            // Delete button on the far right was the one getting cut off.
            // Wrap them so every control stays fully visible.
            return Wrap(
              spacing: StarSpace.sm,
              runSpacing: StarSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                selectAll,
                count,
                _StatusMenu(enabled: enabled, onStatus: onStatus),
                delete,
              ],
            );
          }
          return Row(
            children: <Widget>[
              selectAll,
              const SizedBox(width: StarSpace.sm),
              count,
              const Spacer(),
              _StatusMenu(enabled: enabled, onStatus: onStatus),
              const SizedBox(width: StarSpace.sm),
              delete,
            ],
          );
        },
      ),
    );
  }
}

/// The "Set status" popup. Its trigger is a hand-rolled pill rather than a
/// button because a button inside [PopupMenuButton.child] swallows the tap and
/// the menu never opens.
class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.enabled, required this.onStatus});

  final bool enabled;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: 'Set status',
      onSelected: onStatus,
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        for (final status in _bulkStatuses)
          PopupMenuItem<String>(
            value: status,
            child: StatusChip(
              label: _orderStatus(status).label,
              tone: _orderStatus(status).tone,
              icon: _orderStatus(status).icon,
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StarSpace.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(StarRadius.field),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.swap_horiz, size: 18, color: foreground),
            const SizedBox(width: StarSpace.sm),
            Text(
              'Set status',
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      final service = DocumentsService(
        db: ref.read(bootstrapProvider).db,
        company: ref.read(companyProvider),
      );
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
        kind: NumberKind.job,
        branchCode: AppConfig.branchCode,
        deviceCode: AppConfig.deviceCode,
        prefixes:
            ref.read(shopSettingsProvider).value?.numberPrefixes ??
            const NumberPrefixes(),
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
          _SummaryRow(label: 'Status', value: _orderStatus(order.status).label),
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
          InvoiceSection(order: order),
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
