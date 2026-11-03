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
import 'documents_service.dart';
import 'number_prefixes.dart';
import 'whatsapp.dart';

/// The invoice for one order: issue it, take money against it, print it.
///
/// An invoice is issued once and never edited — the server refuses anything else
/// — so this widget only ever offers three things: issue (when there is none),
/// take a payment (when there is a balance), and print.
class InvoiceSection extends ConsumerStatefulWidget {
  const InvoiceSection({required this.order, super.key});

  final Order order;

  @override
  ConsumerState<InvoiceSection> createState() => _InvoiceSectionState();
}

class _InvoiceSectionState extends ConsumerState<InvoiceSection> {
  bool _busy = false;

  Future<void> _issue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue the tax invoice?'),
        content: Text(
          'This locks ${Fils(widget.order.totalFils).aedLabel} including VAT for '
          'order ${widget.order.numberDisplay}. It cannot be edited afterwards — '
          'only voided before any money is taken.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Issue invoice'),
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
        kind: NumberKind.invoice,
        branchCode: AppConfig.branchCode,
        deviceCode: AppConfig.deviceCode,
        // The prefix is the shop's, read from Settings: a shop that renames
        // `INV` to `BILL` prints BILL-… on the very next invoice. Before the
        // first settings read this is the worker's default, which is what the
        // server would have used anyway.
        prefixes:
            ref.read(shopSettingsProvider).value?.numberPrefixes ??
            const NumberPrefixes(),
      ).next();

      await bootstrap.db.issueInvoiceLocal(
        order: widget.order,
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        // The issued string is stored exactly as printed. Rebuilding it from a
        // prefix later would let a Settings change rewrite an old invoice, and
        // a tax invoice number must never move.
        number: issued.display,
        dueAt: DateTime.now().add(const Duration(days: 30)),
      );
      unawaited(bootstrap.engine?.syncNow());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Invoice ${issued.display} issued.'
            '${issued.isTemporary ? ' It gets a server number when the internet returns.' : ''}',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePayment(Invoice invoice) async {
    final payment = await showDialog<_PaymentDraft>(
      context: context,
      builder: (_) =>
          _PaymentDialog(outstanding: invoice.totalFils - invoice.paidFils),
    );
    if (payment == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      await bootstrap.db.takePaymentLocal(
        invoice: invoice,
        amountFils: payment.amountFils,
        method: payment.method,
        userId: session.userId,
        reference: payment.reference,
      );
      unawaited(bootstrap.engine?.syncNow());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${Fils(payment.amountFils).aedLabel} received by ${payment.method}.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _isManager {
    final session = ref.read(sessionProvider);
    return session?.isOwner == true || session?.role == 'manager';
  }

  Future<void> _creditNote(Invoice invoice) async {
    final draft = await showDialog<_CreditDraft>(
      context: context,
      builder: (_) => _CreditNoteDialog(
        creditable: invoice.totalFils - invoice.creditedFils,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      final issued = await NumberSeries(
        db: bootstrap.db,
        api: bootstrap.api,
        kind: NumberKind.creditNote,
        branchCode: AppConfig.branchCode,
        deviceCode: AppConfig.deviceCode,
      ).next();

      await bootstrap.db.issueCreditNoteLocal(
        invoice: invoice,
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        number: issued.display,
        amountFils: draft.amountFils,
        reason: draft.reason,
      );
      unawaited(bootstrap.engine?.syncNow());
      messenger.showSnackBar(
        const SnackBar(content: Text('Credit note issued.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refund(CreditNote note) async {
    final draft = await showDialog<_CreditDraft>(
      context: context,
      builder: (_) => _CreditNoteDialog(
        creditable: note.totalFils - note.refundedFils,
        title: 'Refund money',
        amountLabel: 'Amount to refund (AED)',
        confirmLabel: 'Refund',
        reasonLabel: 'Reference (optional)',
        reasonOptional: true,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      await bootstrap.db.refundLocal(
        note: note,
        amountFils: draft.amountFils,
        method: 'cash',
        userId: session.userId,
        reference: draft.reason.isEmpty ? null : draft.reason,
      );
      unawaited(bootstrap.engine?.syncNow());
      messenger.showSnackBar(
        SnackBar(content: Text('${Fils(draft.amountFils).aedLabel} refunded.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print(Invoice invoice) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = DocumentsService(
        db: ref.read(bootstrapProvider).db,
        company: ref.read(companyProvider),
      );
      final file = await service.invoiceFor(invoice);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${file.path.split(Platform.pathSeparator).last}',
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              if (Platform.isWindows) {
                await Process.run('cmd', <String>[
                  '/c',
                  'start',
                  '',
                  file.path,
                ]);
              } else {
                await launchUrl(
                  Uri.file(file.path),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
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

  Future<void> _printCreditNote(CreditNote note, Invoice invoice) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = DocumentsService(
        db: ref.read(bootstrapProvider).db,
        company: ref.read(companyProvider),
      );
      final file = await service.creditNoteFor(note, invoice);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${file.path.split(Platform.pathSeparator).last}',
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              if (Platform.isWindows) {
                await Process.run('cmd', <String>[
                  '/c',
                  'start',
                  '',
                  file.path,
                ]);
              } else {
                await launchUrl(
                  Uri.file(file.path),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
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

  Future<void> _send(Invoice invoice) async {
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
    final balance = invoice.totalFils - invoice.paidFils;
    await WhatsApp.open(
      phoneE164: phone,
      message:
          'Hello ${widget.order.customerName ?? 'there'},\n\n'
          'Invoice ${invoice.number} for ${Fils(invoice.totalFils).aedLabel} '
          '(${Fils(balance).aedLabel} outstanding).\n\n'
          '${AppConfig.company.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return StreamBuilder<Invoice?>(
      stream: db.watchInvoiceForOrder(widget.order.id),
      builder: (context, snapshot) {
        final invoice = snapshot.data;

        if (invoice == null) {
          return Row(
            children: <Widget>[
              Expanded(
                child: Text('Invoice', style: theme.textTheme.titleSmall),
              ),
              FilledButton.icon(
                onPressed: _busy || widget.order.isQuote ? null : _issue,
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Issue invoice'),
              ),
            ],
          );
        }

        final outstanding =
            (invoice.totalFils - invoice.paidFils - invoice.creditedFils).clamp(
              0,
              invoice.totalFils,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    invoice.number,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _statusChip(invoice.status),
              ],
            ),
            const SizedBox(height: StarSpace.xs),
            Row(
              children: <Widget>[
                Text(
                  'Total ${Fils(invoice.totalFils).aedLabel}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: StarSpace.md),
                Text(
                  'Paid ${Fils(invoice.paidFils).aedLabel}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: StarSpace.md),
                Text(
                  'Outstanding ${Fils(outstanding).aedLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: outstanding > 0
                        ? theme.colorScheme.error
                        : StarColors.statusDone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: StarSpace.sm),
            StreamBuilder<List<Payment>>(
              stream: db.watchPayments(invoice.id),
              builder: (context, paymentsSnapshot) {
                final payments = paymentsSnapshot.data ?? const <Payment>[];
                if (payments.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: StarSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final payment in payments)
                        Text(
                          '${Fils(payment.amountFils).aedLabel} · ${payment.method}'
                          '${payment.reference == null ? '' : ' · ${payment.reference}'}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                );
              },
            ),
            if (invoice.creditedFils > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: StarSpace.sm),
                child: Text(
                  'Credited ${Fils(invoice.creditedFils).aedLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            StreamBuilder<List<CreditNote>>(
              stream: db.watchCreditNotes(invoice.id),
              builder: (context, notesSnapshot) {
                final notes = notesSnapshot.data ?? const <CreditNote>[];
                if (notes.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: StarSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final note in notes)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${note.number} · ${Fils(note.totalFils).aedLabel} · ${note.reason}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            if (_isManager &&
                                note.refundedFils < note.totalFils)
                              TextButton(
                                onPressed: _busy ? null : () => _refund(note),
                                child: const Text('Refund'),
                              )
                            else
                              Text(
                                'refunded ${Fils(note.refundedFils).aedLabel}',
                                style: theme.textTheme.bodySmall,
                              ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _printCreditNote(note, invoice),
                              child: const Text('PDF'),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
            Wrap(
              spacing: StarSpace.sm,
              runSpacing: StarSpace.sm,
              children: <Widget>[
                if (outstanding > 0 && invoice.status != 'void')
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _takePayment(invoice),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Take payment'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _print(invoice),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Invoice PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _send(invoice),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Send'),
                ),
                if (_isManager &&
                    invoice.creditedFils < invoice.totalFils &&
                    invoice.status != 'void')
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _creditNote(invoice),
                    icon: const Icon(
                      Icons.assignment_return_outlined,
                      size: 18,
                    ),
                    label: const Text('Credit note'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Widget _statusChip(String status) => switch (status) {
    'paid' => const StatusChip(label: 'Paid', tone: StatusTone.done),
    'part_paid' => const StatusChip(
      label: 'Part paid',
      tone: StatusTone.active,
    ),
    'void' => const StatusChip(label: 'Void', tone: StatusTone.problem),
    _ => const StatusChip(label: 'Issued'),
  };
}

class _PaymentDraft {
  const _PaymentDraft({
    required this.amountFils,
    required this.method,
    this.reference,
  });

  final int amountFils;
  final String method;
  final String? reference;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.outstanding});

  final int outstanding;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: (widget.outstanding / 100).toStringAsFixed(2),
  );
  final TextEditingController _reference = TextEditingController();
  String _method = 'cash';
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter an amount.');
      return;
    }
    final fils = (parsed * 100).round();
    if (fils > widget.outstanding) {
      setState(
        () => _error =
            'Only ${(widget.outstanding / 100).toStringAsFixed(2)} is outstanding.',
      );
      return;
    }
    Navigator.of(context).pop(
      _PaymentDraft(
        amountFils: fils,
        method: _method,
        reference: _reference.text.trim().isEmpty
            ? null
            : _reference.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Take a payment'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (AED)',
                prefixText: 'AED ',
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'cash', child: Text('Cash')),
                DropdownMenuItem<String>(value: 'card', child: Text('Card')),
                DropdownMenuItem<String>(
                  value: 'transfer',
                  child: Text('Bank transfer'),
                ),
                DropdownMenuItem<String>(
                  value: 'cheque',
                  child: Text('Cheque'),
                ),
              ],
              onChanged: (value) => setState(() => _method = value ?? 'cash'),
            ),
            const SizedBox(height: StarSpace.sm),
            TextField(
              controller: _reference,
              decoration: const InputDecoration(
                labelText: 'Reference (optional)',
                hintText: 'Cheque no, transfer ref',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: StarSpace.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Record')),
      ],
    );
  }
}

class _CreditDraft {
  const _CreditDraft({required this.amountFils, required this.reason});

  final int amountFils;
  final String reason;
}

/// One dialog for both crediting and refunding: same shape, different words.
class _CreditNoteDialog extends StatefulWidget {
  const _CreditNoteDialog({
    required this.creditable,
    this.title = 'Issue a credit note',
    this.amountLabel = 'Amount to credit (AED)',
    this.confirmLabel = 'Issue',
    this.reasonLabel = 'Why?',
    this.reasonOptional = false,
  });

  final int creditable;
  final String title;
  final String amountLabel;
  final String confirmLabel;
  final String reasonLabel;
  final bool reasonOptional;

  @override
  State<_CreditNoteDialog> createState() => _CreditNoteDialogState();
}

class _CreditNoteDialogState extends State<_CreditNoteDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: (widget.creditable / 100).toStringAsFixed(2),
  );
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = double.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter an amount.');
      return;
    }
    final fils = (parsed * 100).round();
    if (fils > widget.creditable) {
      setState(
        () => _error =
            'Only ${(widget.creditable / 100).toStringAsFixed(2)} is available.',
      );
      return;
    }
    final reason = _reason.text.trim();
    if (!widget.reasonOptional && reason.length < 3) {
      setState(
        () => _error =
            'Say why — a credit note without a reason is a problem later.',
      );
      return;
    }
    Navigator.of(context).pop(_CreditDraft(amountFils: fils, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.amountLabel,
                prefixText: 'AED ',
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            TextField(
              controller: _reason,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.reasonLabel,
                hintText: widget.reasonOptional
                    ? 'Cheque no, transfer ref'
                    : 'Damaged in finishing, wrong paper, short delivery',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: StarSpace.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
