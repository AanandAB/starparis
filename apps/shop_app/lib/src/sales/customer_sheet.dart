import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../providers.dart';
import '../sales/whatsapp.dart';

/// One customer, and what they owe.
///
/// The counter question is "what does Ahmed owe and for what", so this is a
/// statement rather than a profile: every invoice with what is still outstanding,
/// then the jobs behind them. Address, TRN and notes are here because they are
/// what an invoice needs, not because a CRM asked for them.
Future<void> showCustomerSheet(BuildContext context, Customer customer) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CustomerSheet(customer: customer),
  );
}

class _CustomerSheet extends ConsumerWidget {
  const _CustomerSheet({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return StreamBuilder<List<Invoice>>(
          stream: db.watchInvoicesForCustomer(customer.id),
          builder: (context, invoiceSnapshot) {
            final invoices = invoiceSnapshot.data ?? const <Invoice>[];
            final outstanding = invoices.fold<int>(
              0,
              (sum, invoice) =>
                  sum +
                  (invoice.voidReason == null
                          ? (invoice.totalFils -
                                invoice.paidFils -
                                invoice.creditedFils)
                          : 0)
                      .clamp(0, invoice.totalFils),
            );
            final billed = invoices.fold<int>(
              0,
              (sum, invoice) => sum + invoice.totalFils,
            );

            return StreamBuilder<List<Order>>(
              stream: db.watchOrdersForCustomer(customer.id),
              builder: (context, orderSnapshot) {
                final orders = orderSnapshot.data ?? const <Order>[];

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(StarSpace.lg),
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                customer.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if ((customer.company ?? '').isNotEmpty)
                                Text(
                                  customer.company!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (outstanding > 0)
                          StarStat(
                            label: 'Owed',
                            value: Fils(outstanding).aedLabel,
                            tone: StarStatTone.danger,
                          ),
                      ],
                    ),
                    const SizedBox(height: StarSpace.md),
                    Wrap(
                      spacing: StarSpace.lg,
                      runSpacing: StarSpace.sm,
                      children: <Widget>[
                        if ((customer.trn ?? '').isNotEmpty)
                          _fact(theme, 'TRN', customer.trn!),
                        if ((customer.address ?? '').isNotEmpty)
                          _fact(theme, 'Address', customer.address!),
                        _fact(
                          theme,
                          'Terms',
                          customer.paymentTermsDays == 0
                              ? 'on delivery'
                              : '${customer.paymentTermsDays} days',
                        ),
                      ],
                    ),
                    const SizedBox(height: StarSpace.lg),
                    Row(
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: () async {
                            final phone = await db.primaryPhoneFor(customer.id);
                            if (phone == null) return;
                            await WhatsApp.open(
                              phoneE164: phone,
                              message:
                                  'Hello ${customer.name}, this is Star Paris.',
                            );
                          },
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ],
                    ),
                    const SizedBox(height: StarSpace.xl),
                    StarSectionHeader(
                      title: 'Statement',
                      subtitle: invoices.isEmpty
                          ? 'Nothing invoiced yet. A quote or a job is not a bill.'
                          : '${invoices.length} invoice${invoices.length == 1 ? '' : 's'}, '
                                '${Fils(billed).aedLabel} billed, '
                                '${Fils(outstanding).aedLabel} still owed.',
                    ),
                    if (invoices.isNotEmpty)
                      Card(
                        child: Column(
                          children: <Widget>[
                            for (
                              var i = 0;
                              i < invoices.length;
                              i++
                            ) ...<Widget>[
                              if (i > 0) const Divider(height: 1),
                              _InvoiceRow(invoice: invoices[i]),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: StarSpace.xl),
                    StarSectionHeader(
                      title: 'Jobs',
                      count: orders.length,
                      subtitle: orders.isEmpty
                          ? 'No work recorded for this customer.'
                          : 'Every job, newest first.',
                    ),
                    if (orders.isNotEmpty)
                      Card(
                        child: Column(
                          children: <Widget>[
                            for (var i = 0; i < orders.length; i++) ...<Widget>[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                dense: true,
                                title: Text(orders[i].numberDisplay),
                                subtitle: Text(
                                  <String>[
                                    orders[i].status.replaceAll('_', ' '),
                                    if (orders[i].dueAt != null)
                                      'due ${orders[i].dueAt!.day}/${orders[i].dueAt!.month}',
                                  ].join(' · '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: MoneyText(Fils(orders[i].totalFils)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if ((customer.notes ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: StarSpace.xl),
                      StarSectionHeader(title: 'Notes'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(StarSpace.md),
                          child: Text(customer.notes!),
                        ),
                      ),
                    ],
                    const SizedBox(height: StarSpace.xxl),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget _fact(ThemeData theme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voided = invoice.voidReason != null;
    final outstanding =
        (invoice.totalFils - invoice.paidFils - invoice.creditedFils).clamp(
          0,
          invoice.totalFils,
        );

    return ListTile(
      dense: true,
      title: Text(
        invoice.number,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: voided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        voided
            ? 'voided — ${invoice.voidReason}'
            : outstanding == 0
            ? 'settled'
            : '${Fils(outstanding).aedLabel} outstanding',
        style: theme.textTheme.bodySmall?.copyWith(
          color: voided
              ? theme.colorScheme.onSurfaceVariant
              : outstanding == 0
              ? StarColors.statusDone
              : theme.colorScheme.error,
        ),
      ),
      trailing: MoneyText(Fils(invoice.totalFils)),
    );
  }
}
