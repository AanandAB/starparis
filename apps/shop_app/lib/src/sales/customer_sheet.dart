import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_documents/starparis_documents.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';
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
            // Over the limit means more than a non-zero limit: a zero limit is
            // a cash customer with no credit to exceed, so they are never
            // "over limit".
            final overLimit =
                customer.creditLimitFils > 0 &&
                outstanding > customer.creditLimitFils;

            return StreamBuilder<List<Order>>(
              stream: db.watchOrdersForCustomer(customer.id),
              builder: (context, orderSnapshot) {
                final orders = orderSnapshot.data ?? const <Order>[];

                return StreamBuilder<List<CustomerDeposit>>(
                  stream: db.watchDepositsForCustomer(customer.id),
                  builder: (context, depositSnapshot) {
                    final deposits =
                        depositSnapshot.data ?? const <CustomerDeposit>[];
                    final depositBalance = deposits.fold<int>(
                      0,
                      (sum, deposit) =>
                          sum + (deposit.amountFils - deposit.allocatedFils),
                    );

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
                            tone: overLimit
                                ? StarStatTone.danger
                                : StarStatTone.neutral,
                            icon: overLimit
                                ? Icons.warning_amber_rounded
                                : null,
                            hint: overLimit ? 'Over limit' : null,
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
                        _fact(
                          theme,
                          'Credit limit',
                          customer.creditLimitFils == 0
                              ? 'no credit'
                              : Fils(customer.creditLimitFils).aedLabel,
                        ),
                        if (depositBalance > 0)
                          _fact(
                            theme,
                            'Deposit balance',
                            Fils(depositBalance).aedLabel,
                          ),
                      ],
                    ),
                    const SizedBox(height: StarSpace.lg),
                    Wrap(
                      spacing: StarSpace.md,
                      runSpacing: StarSpace.sm,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: () => _takeDeposit(context, customer),
                          icon: const Icon(Icons.savings_outlined, size: 18),
                          label: const Text('Take deposit'),
                        ),
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
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Capture before the await so the snackbar is shown
                            // through a messenger that is still mounted.
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final file = await _writeStatementPdf(
                                customer,
                                invoices,
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Statement saved: ${file.path}'),
                                ),
                              );
                            } catch (error) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('$error')),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                          ),
                          label: const Text('Statement PDF'),
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

/// Writes a statement of account for [customer] from [invoices] — the same
/// rows the sheet already shows, not a fresh fetch — to the shop's documents
/// folder, and returns the file so the caller can tell the user where it went.
Future<File> _writeStatementPdf(
  Customer customer,
  List<Invoice> invoices,
) async {
  final lines = <StatementLine>[];
  var running = 0;
  for (final invoice in invoices) {
    // A voided invoice is not a real charge, so it carries no balance and is
    // left off the statement; the "owed" figure skips it the same way.
    if (invoice.voidReason != null) continue;
    final paid = invoice.paidFils + invoice.creditedFils;
    running += invoice.totalFils - paid;
    lines.add(
      StatementLine(
        date: invoice.issuedAt,
        reference: invoice.number,
        description: 'Invoice',
        amountFils: invoice.totalFils,
        paidFils: paid,
        balanceFils: running,
      ),
    );
  }

  final bytes = await buildStatementPdf(
    StatementDocument(
      customerName: customer.name,
      customerCompany: customer.company,
      customerTrn: customer.trn,
      periodLabel: AppConfig.company.branchName ?? '',
      openingBalanceFils: 0,
      lines: lines,
      closingBalanceFils: running,
      generatedAt: DateTime.now(),
    ),
    AppConfig.company,
  );

  final base = await getApplicationDocumentsDirectory();
  final directory = Directory(p.join(base.path, 'StarParis'));
  await directory.create(recursive: true);
  final file = File(
    p.join(directory.path, 'StarParis_Statement_${customer.name}.pdf'),
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Asks for an amount, a method and an optional note, then records a deposit
/// against [customer] with a local write that also queues the outbox insert.
/// Nothing here touches an invoice: applying the deposit to one is a separate,
/// later step (allocation), not part of taking it.
Future<void> _takeDeposit(BuildContext context, Customer customer) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DepositDialog(customer: customer),
  );
}

class _DepositDialog extends ConsumerStatefulWidget {
  const _DepositDialog({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends ConsumerState<_DepositDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _method = 'cash';
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _say('Enter how much was deposited.');
      return;
    }

    setState(() => _busy = true);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      await bootstrap.db.createDepositLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        customerId: widget.customer.id,
        amountFils: (amount * 100).round(),
        method: _method,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      unawaited(bootstrap.engine?.syncNow());

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deposit recorded — AED ${amount.toStringAsFixed(2)}'),
        ),
      );
    } catch (error) {
      _say('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Take deposit — ${widget.customer.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'AED ',
            ),
          ),
          const SizedBox(height: StarSpace.md),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'cash', label: Text('Cash')),
              ButtonSegment<String>(value: 'card', label: Text('Card')),
              ButtonSegment<String>(
                value: 'transfer',
                label: Text('Transfer'),
              ),
            ],
            selected: <String>{_method},
            onSelectionChanged: (selection) =>
                setState(() => _method = selection.first),
          ),
          const SizedBox(height: StarSpace.md),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Advance for business cards',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Record deposit'),
        ),
      ],
    );
  }
}
