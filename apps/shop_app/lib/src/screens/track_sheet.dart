import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import 'orders_screen.dart';

/// Track — one box for "where is this job".
///
/// The customer at the counter has either a job number, an invoice, or their own
/// phone number. All three work here, and the answer comes from the local
/// database, so it is instant and it works with the internet down.
Future<void> showTrackSheet(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _TrackDialog(),
  );
}

class _TrackDialog extends ConsumerStatefulWidget {
  const _TrackDialog();

  @override
  ConsumerState<_TrackDialog> createState() => _TrackDialogState();
}

class _TrackDialogState extends ConsumerState<_TrackDialog> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  String _active = '';

  @override
  void initState() {
    super.initState();
    // The box is the point of the dialog: put the cursor in it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _active = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: StarSpace.lg,
        vertical: StarSpace.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                StarSpace.md,
                StarSpace.md,
                StarSpace.sm,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _query,
                      focusNode: _focus,
                      onChanged: _changed,
                      textInputAction: TextInputAction.search,
                      style: theme.textTheme.titleMedium,
                      decoration: const InputDecoration(
                        hintText: 'Job number, invoice, phone or customer',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _active.isEmpty
                  ? _Hint(theme: theme)
                  : _Results(
                      query: _active,
                      db: db,
                      onOpenOrder: (order) {
                        Navigator.of(context).pop();
                        showOrderSheet(context, order);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StarSpace.md,
                vertical: StarSpace.sm,
              ),
              child: Text(
                'Everything here is on this device — nothing is sent to the server to answer it.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StarSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.travel_explore,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: StarSpace.md),
            Text('Type any of these', style: theme.textTheme.titleSmall),
            const SizedBox(height: StarSpace.sm),
            Text(
              'JOB-SHJ1-PC1-00012  ·  INV-SHJ1-PC1-00101\n'
              '050 123 4567  ·  Ahmed Traders',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.query,
    required this.db,
    required this.onOpenOrder,
  });

  final String query;
  final LocalDatabase db;
  final void Function(Order order) onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Order>>(
      stream: db.searchOrders(query),
      builder: (context, orderSnapshot) {
        return StreamBuilder<List<Invoice>>(
          stream: db.searchInvoices(query),
          builder: (context, invoiceSnapshot) {
            return StreamBuilder<List<Customer>>(
              stream: db.searchCustomers(query),
              builder: (context, customerSnapshot) {
                final orders = orderSnapshot.data ?? const <Order>[];
                final invoices = invoiceSnapshot.data ?? const <Invoice>[];
                final customers = customerSnapshot.data ?? const <Customer>[];

                if (orders.isEmpty && invoices.isEmpty && customers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(StarSpace.xl),
                      child: Text(
                        'Nothing matches "$query".',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: StarSpace.sm),
                  children: <Widget>[
                    if (orders.isNotEmpty) ...<Widget>[
                      _Label(text: 'Jobs', theme: theme),
                      for (final order in orders)
                        _OrderResult(
                          order: order,
                          onTap: () => onOpenOrder(order),
                        ),
                    ],
                    if (invoices.isNotEmpty) ...<Widget>[
                      _Label(text: 'Invoices', theme: theme),
                      for (final invoice in invoices)
                        _InvoiceResult(
                          invoice: invoice,
                          theme: theme,
                          onTap: () => _openInvoiceOrder(context, invoice),
                        ),
                    ],
                    if (customers.isNotEmpty) ...<Widget>[
                      _Label(text: 'Customers', theme: theme),
                      for (final customer in customers)
                        _CustomerResult(customer: customer, theme: theme),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// An invoice number is a promise about money; the useful next screen is the
  /// job it belongs to, where the payments and the stage both live.
  Future<void> _openInvoiceOrder(BuildContext context, Invoice invoice) async {
    final order = await db.orderById(invoice.orderId);
    if (order == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That invoice\'s job is not on this device yet.'),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showOrderSheet(context, order);
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StarSpace.md,
        StarSpace.md,
        StarSpace.md,
        StarSpace.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OrderResult extends StatelessWidget {
  const _OrderResult({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.receipt_long_outlined, size: 20),
      title: Row(
        children: <Widget>[
          Text(
            order.numberDisplay,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: StarSpace.sm),
          Expanded(
            child: Text(
              order.customerName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      subtitle: Text(
        <String>[
          order.status.replaceAll('_', ' '),
          if (order.dueAt != null)
            'due ${order.dueAt!.day}/${order.dueAt!.month}',
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: MoneyText(Fils(order.totalFils)),
    );
  }
}

class _InvoiceResult extends StatelessWidget {
  const _InvoiceResult({
    required this.invoice,
    required this.theme,
    required this.onTap,
  });

  final Invoice invoice;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outstanding =
        invoice.totalFils - invoice.paidFils - invoice.creditedFils;
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.description_outlined, size: 20),
      title: Row(
        children: <Widget>[
          Text(
            invoice.number,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: StarSpace.sm),
          Expanded(
            child: Text(
              invoice.customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      subtitle: Text(
        outstanding <= 0
            ? 'settled'
            : '${Fils(outstanding).aedLabel} outstanding · ${invoice.status.replaceAll('_', ' ')}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: outstanding > 0
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: MoneyText(Fils(invoice.totalFils)),
    );
  }
}

class _CustomerResult extends StatelessWidget {
  const _CustomerResult({required this.customer, required this.theme});

  final Customer customer;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person_outline, size: 20),
      title: Text(customer.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        (customer.company ?? '').isEmpty ? 'customer' : customer.company!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
