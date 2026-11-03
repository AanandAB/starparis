import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';

import '../providers.dart';

/// Records money the shop paid out.
///
/// Cash is the default because that is what most of these are — a courier, a
/// taxi, paper from the shop next door — and cash is the only method that
/// affects the drawer. The server attaches it to the open shift, so the cash-up
/// subtracts it without anyone having to remember.
Future<void> showExpenseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _ExpenseSheet(),
  );
}

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet();

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  static const List<String> _categories = <String>[
    'Courier',
    'Taxi',
    'Materials',
    'Refreshments',
    'Rent',
    'Other',
  ];

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _vat = TextEditingController();
  final TextEditingController _receipt = TextEditingController();

  String _category = _categories.first;
  String _method = 'cash';
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _supplier.dispose();
    _vat.dispose();
    _receipt.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _say('Enter what you paid.');
      return;
    }
    if (_description.text.trim().isEmpty) {
      _say('Say what the money was spent on.');
      return;
    }

    final vat = double.tryParse(_vat.text.trim()) ?? 0;
    if (vat < 0) {
      _say('VAT cannot be negative.');
      return;
    }

    setState(() => _busy = true);
    try {
      final bootstrap = ref.read(bootstrapProvider);
      final session = ref.read(sessionProvider);
      if (session == null) throw StateError('Session expired');

      await bootstrap.db.addExpenseLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        category: _category,
        description: _description.text,
        amountFils: (amount * 100).round(),
        vatFils: (vat * 100).round(),
        method: _method,
        supplier: _supplier.text,
        receiptUrl: _receipt.text.trim().isEmpty ? null : _receipt.text.trim(),
      );
      unawaited(bootstrap.engine?.syncNow());

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorded $_category — ${_money(amount)}')),
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

  static String _money(double value) => 'AED ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        StarSpace.lg,
        StarSpace.sm,
        StarSpace.lg,
        StarSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Record an expense', style: theme.textTheme.titleLarge),
            const SizedBox(height: StarSpace.xs),
            Text(
              'Cash comes out of the open drawer; card and transfer do not.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StarSpace.lg),

            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                prefixText: 'AED ',
              ),
            ),
            const SizedBox(height: StarSpace.md),

            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'What was it for',
                hintText: 'Proof delivery to Dubai',
              ),
            ),
            const SizedBox(height: StarSpace.md),

            Wrap(
              spacing: StarSpace.sm,
              runSpacing: StarSpace.sm,
              children: <Widget>[
                for (final category in _categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: StarSpace.md),

            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _supplier,
                    decoration: const InputDecoration(
                      labelText: 'Paid to (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: StarSpace.md),
                Expanded(
                  child: TextField(
                    controller: _vat,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'VAT in the amount',
                      prefixText: 'AED ',
                      hintText: '0.00',
                    ),
                  ),
                ),
              ],
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
              controller: _receipt,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Receipt link (optional)',
                hintText: 'Drive or WhatsApp photo',
              ),
            ),
            const SizedBox(height: StarSpace.lg),

            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Record expense'),
            ),
          ],
        ),
      ),
    );
  }
}
