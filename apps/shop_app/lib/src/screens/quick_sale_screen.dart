import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_documents/starparis_documents.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/number_prefixes.dart';
import '../sales/receipt_transport.dart';
import '../tour/section_tour.dart';

/// One line the counter is ringing up. The unit price starts at a chip's
/// default and stays editable — a walk-in sale has no price engine, so the
/// price is whatever the clerk and the customer just agreed.
class _BasketLine {
  _BasketLine(this.description, this.unitFils);

  final String description;
  int unitFils;
  int quantity = 1;

  int get amountFils => unitFils * quantity;
}

/// The counter's quick sale: ring up a basket of quick-service lines, take the
/// money, and the sale is done. There is no order, no production and no
/// invoice — the sale is the whole record, and it syncs offline-first like
/// everything else.
class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();

  /// The first-visit guide for the Quick sale screen.
  static const List<TourStep> tourSteps = <TourStep>[
    TourStep(
      icon: Icons.point_of_sale_outlined,
      title: 'Quick sale',
      body: 'Sell walk-in items fast — tap a service chip, then confirm.',
    ),
    TourStep(
      anchor: 'header',
      icon: Icons.shopping_basket_outlined,
      title: 'Basket and total',
      body: 'Your basket lists every line; the running total and payment '
          'method live here.',
    ),
    TourStep(
      anchor: 'new',
      icon: Icons.check_circle_outline,
      title: 'Take payment',
      body: 'Confirm records the sale and prints a receipt.',
    ),
  ];

  /// Resolves an anchor name to the element it spotlights.
  static GlobalKey? tourAnchorFor(String? name) => switch (name) {
        'header' => const GlobalObjectKey('pos-header'),
        'new' => const GlobalObjectKey('pos-new'),
        _ => null,
      };
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final List<_BasketLine> _lines = <_BasketLine>[];
  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _cashReceived = TextEditingController();
  final TextEditingController _customDescription = TextEditingController();

  String _paymentMethod = 'cash';
  bool _busy = false;
  String? _error;

  // A quick-service line is a fixed menu of what a copy shop does all day.
  // Prices are editable starting points, not a rate card.
  static const List<(String, IconData, int)> _services =
      <(String, IconData, int)>[
        ('Copy', Icons.copy_outlined, 100),
        ('Print', Icons.print_outlined, 150),
        ('Scan', Icons.document_scanner_outlined, 200),
        ('Laminate', Icons.layers_outlined, 300),
        ('Binding', Icons.auto_stories_outlined, 500),
      ];

  @override
  void dispose() {
    _customerName.dispose();
    _cashReceived.dispose();
    _customDescription.dispose();
    super.dispose();
  }

  void _addService(String description, int unitFils) {
    setState(() => _lines.add(_BasketLine(description, unitFils)));
  }

  void _addCustomLine() {
    final description = _customDescription.text.trim();
    if (description.isEmpty) return;
    // A custom line starts unpriced; the clerk fills the unit price in.
    setState(() {
      _lines.add(_BasketLine(description, 0));
      _customDescription.clear();
    });
  }

  Future<void> _editUnitPrice(_BasketLine line) async {
    final controller = TextEditingController(
      text: (line.unitFils / 100).toStringAsFixed(2),
    );
    final parsed = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Price for ${line.description}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Unit price',
            prefixText: 'AED ',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(
                dialogContext,
              ).pop(value == null || value < 0 ? null : (value * 100).round());
            },
            child: const Text('Set price'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (parsed != null && mounted) {
      setState(() => line.unitFils = parsed);
    }
  }

  int _subtotalFils() =>
      _lines.fold<int>(0, (sum, line) => sum + line.amountFils);

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_lines.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a line before you take the money.')),
      );
      return;
    }

    final subtotal = _subtotalFils();
    final vat = Fils(subtotal)
        .timesBps(ref.read(shopSettingsProvider).value?.vatBps ?? 500)
        .raw;
    final total = subtotal + vat;
    if (_paymentMethod == 'cash') {
      final received = double.tryParse(_cashReceived.text.trim());
      if (received == null || (received * 100).round() < total) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cash received is less than the total.'),
          ),
        );
        return;
      }
    }

    final session = ref.read(sessionProvider);
    final bootstrap = ref.read(bootstrapProvider);
    if (session == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in again before selling.')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // The quick-sale number is leased and allocated exactly like an order's —
      // the same prefix-from-Settings, branch-and-device series, and a
      // temporary `QS-T-0007` when the device is offline.
      final issued = await NumberSeries(
        db: bootstrap.db,
        api: bootstrap.api,
        kind: NumberKind.quickSale,
        branchCode: AppConfig.branchCode,
        deviceCode: AppConfig.deviceCode,
        prefixes:
            ref.read(shopSettingsProvider).value?.numberPrefixes ??
            const NumberPrefixes(),
      ).next();

      final customerName = _customerName.text.trim();
      await bootstrap.db.createQuickSaleLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        userId: session.userId,
        number: issued.number,
        numberDisplay: issued.display,
        customerId: null,
        customerName: customerName.isEmpty ? null : customerName,
        paymentMethod: _paymentMethod,
        subtotalFils: subtotal,
        vatFils: vat,
        totalFils: total,
        paidFils: total,
        lines: <QuickSaleLineDraft>[
          for (final line in _lines)
            QuickSaleLineDraft(
              productId: null,
              description: line.description,
              quantity: line.quantity,
              unitFils: line.unitFils,
              amountFils: line.amountFils,
            ),
        ],
      );

      // The sale leaves on the next sync; a prompt attempt now, and the chip in
      // the top bar shows it waiting while offline.
      unawaited(bootstrap.engine?.syncNow());

      // Build the 80 mm slip from what was rung, before the basket clears, so
      // the printed arithmetic always matches the recorded sale.
      final receiptBytes = _receiptBytes(issued.display, subtotal, vat, total);

      if (!mounted) return;
      setState(() {
        _lines.clear();
        _customerName.clear();
        _cashReceived.clear();
        _paymentMethod = 'cash';
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Sale ${issued.display} recorded.')),
      );

      // Printing must never un-record a sale: a failed print is reported and
      // the sale stands.
      unawaited(_printReceipt(receiptBytes, messenger));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The receipt for the sale just rung, as ESC/POS bytes. Built from the same
  /// values that were saved, so a later price change can never alter a slip.
  Uint8List _receiptBytes(String number, int subtotal, int vat, int total) {
    final received = double.tryParse(_cashReceived.text.trim());
    final tendered = _paymentMethod == 'cash' && received != null
        ? (received * 100).round()
        : null;
    final doc = ReceiptDocument(
      shopName: AppConfig.company.name,
      branchName: AppConfig.company.branchName,
      address: AppConfig.company.address,
      phone: AppConfig.company.phone,
      number: number,
      issuedAt: DateTime.now(),
      lines: [
        for (final line in _lines)
          ReceiptLine(
            description: line.description,
            quantity: line.quantity,
            amountFils: line.amountFils,
          ),
      ],
      subtotalFils: subtotal,
      vatFils: vat,
      totalFils: total,
      paymentMethod: _paymentMethod,
      tenderedFils: tendered,
    );
    return buildReceiptBytes(doc);
  }

  Future<void> _printReceipt(
      Uint8List bytes, ScaffoldMessengerState messenger) async {
    try {
      await ReceiptPrinter.forPlatform().printBytes(bytes);
    } on ReceiptPrintException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Receipt failed to print: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vatBps = ref.watch(shopSettingsProvider).value?.vatBps ?? 500;
    final subtotal = _subtotalFils();
    final vat = Fils(subtotal).timesBps(vatBps);
    final total = subtotal + vat.raw;

    final received = double.tryParse(_cashReceived.text.trim());
    final receivedFils = received == null ? 0 : (received * 100).round();
    final change = receivedFils > total ? receivedFils - total : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(StarSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ScreenHeader(
            key: const GlobalObjectKey('pos-header'),
            title: 'Quick sale',
            subtitle: 'Walk-in sale — paid now, no invoice.',
          ),
          const SizedBox(height: StarSpace.sm),
          Wrap(
            spacing: StarSpace.sm,
            runSpacing: StarSpace.sm,
            children: <Widget>[
              for (final (label, icon, price) in _services)
                ActionChip(
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                  onPressed: _busy ? null : () => _addService(label, price),
                ),
            ],
          ),
          const SizedBox(height: StarSpace.md),
          if (_lines.isEmpty)
            SizedBox(height: 140, child: _EmptyBasket())
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lines.length,
              separatorBuilder: (_, _) => const SizedBox(height: StarSpace.sm),
              itemBuilder: (context, index) {
                final line = _lines[index];
                return _BasketLineTile(
                  line: line,
                  onQuantity: (delta) => setState(() {
                    line.quantity = (line.quantity + delta).clamp(1, 999);
                  }),
                  onEditPrice: () => _editUnitPrice(line),
                  onRemove: () => setState(() => _lines.removeAt(index)),
                );
              },
            ),
          const SizedBox(height: StarSpace.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _customerName,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Customer name (optional — walk-in if blank)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StarSpace.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _customDescription,
                  enabled: !_busy,
                  onSubmitted: (_) => _addCustomLine(),
                  decoration: const InputDecoration(
                    labelText: 'Other line (e.g. "500 flyers")',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: StarSpace.sm),
              IconButton.filledTonal(
                onPressed: _busy ? null : _addCustomLine,
                icon: const Icon(Icons.add),
                tooltip: 'Add line',
              ),
            ],
          ),
          const SizedBox(height: StarSpace.md),
          _TotalsPanel(
            subtotalFils: subtotal,
            vatBps: vatBps,
            vatFils: vat.raw,
            totalFils: total,
            paymentMethod: _paymentMethod,
            onPaymentMethod: _busy
                ? null
                : (method) => setState(() => _paymentMethod = method),
            cashReceived: _cashReceived,
            changeFils: change,
            onCashChanged: () => setState(() {}),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: StarSpace.sm),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: StarSpace.md),
          FilledButton.icon(
            key: const GlobalObjectKey('pos-new'),
            onPressed: _busy || _lines.isEmpty ? null : _confirm,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _busy ? 'Recording…' : 'Confirm · ${Fils(total).aedLabel}',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.point_of_sale_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: StarSpace.sm),
          Text('Nothing in the basket yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Tap a quick-service chip, or add another line.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketLineTile extends StatelessWidget {
  const _BasketLineTile({
    required this.line,
    required this.onQuantity,
    required this.onEditPrice,
    required this.onRemove,
  });

  final _BasketLine line;
  final ValueChanged<int> onQuantity;
  final VoidCallback onEditPrice;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = Text(
      line.description,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final unit = Text(
      '${line.quantity} × ${Fils(line.unitFils).aedLabel}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final nameColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        name,
        const SizedBox(height: 2),
        unit,
      ],
    );
    final stepper = <Widget>[
      IconButton(
        onPressed: () => onQuantity(-1),
        icon: const Icon(Icons.remove_circle_outline, size: 20),
        tooltip: 'One fewer',
      ),
      SizedBox(
        width: 28,
        child: Text(
          '${line.quantity}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ),
      IconButton(
        onPressed: () => onQuantity(1),
        icon: const Icon(Icons.add_circle_outline, size: 20),
        tooltip: 'One more',
      ),
    ];
    final editPrice = TextButton(
      onPressed: onEditPrice,
      child: Text(Fils(line.unitFils).aedLabel),
    );
    final amount = SizedBox(
      width: 96,
      child: MoneyText(Fils(line.amountFils), emphasise: true),
    );
    final remove = IconButton(
      onPressed: onRemove,
      icon: const Icon(Icons.close, size: 20),
      tooltip: 'Remove',
    );

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(StarRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StarSpace.md,
          vertical: StarSpace.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On a phone the single row is too wide: the name, two stepper
            // buttons, the unit-price button and the amount all compete, and
            // the name collapses into vertical letters. Stack instead — name
            // and amount on top, the stepper and unit price underneath.
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: nameColumn),
                      const SizedBox(width: StarSpace.sm),
                      amount,
                      remove,
                    ],
                  ),
                  const SizedBox(height: StarSpace.xs),
                  Row(
                    children: <Widget>[
                      ...stepper,
                      const SizedBox(width: StarSpace.sm),
                      editPrice,
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: nameColumn),
                ...stepper,
                editPrice,
                amount,
                remove,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({
    required this.subtotalFils,
    required this.vatBps,
    required this.vatFils,
    required this.totalFils,
    required this.paymentMethod,
    required this.onPaymentMethod,
    required this.cashReceived,
    required this.changeFils,
    required this.onCashChanged,
  });

  final int subtotalFils;
  final int vatBps;
  final int vatFils;
  final int totalFils;
  final String paymentMethod;
  final ValueChanged<String>? onPaymentMethod;
  final TextEditingController cashReceived;
  final int changeFils;
  final VoidCallback onCashChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vatPercent = (vatBps / 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _row(theme, 'Subtotal', Fils(subtotalFils)),
        _row(theme, 'VAT ($vatPercent%)', Fils(vatFils)),
        const Divider(height: StarSpace.lg),
        Row(
          children: <Widget>[
            Expanded(child: Text('Total', style: theme.textTheme.titleLarge)),
            MoneyText(Fils(totalFils), emphasise: true),
          ],
        ),
        const SizedBox(height: StarSpace.md),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'cash',
              icon: Icon(Icons.payments_outlined),
              label: Text('Cash'),
            ),
            ButtonSegment<String>(
              value: 'card',
              icon: Icon(Icons.credit_card_outlined),
              label: Text('Card'),
            ),
            ButtonSegment<String>(
              value: 'transfer',
              icon: Icon(Icons.account_balance_outlined),
              label: Text('Transfer'),
            ),
          ],
          selected: <String>{paymentMethod},
          onSelectionChanged: onPaymentMethod == null
              ? null
              : (selection) => onPaymentMethod!(selection.first),
        ),
        if (paymentMethod == 'cash') ...<Widget>[
          const SizedBox(height: StarSpace.md),
          TextField(
            controller: cashReceived,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onCashChanged(),
            decoration: const InputDecoration(
              labelText: 'Cash received',
              prefixText: 'AED ',
              border: OutlineInputBorder(),
            ),
          ),
          if (changeFils > 0)
            Padding(
              padding: const EdgeInsets.only(top: StarSpace.sm),
              child: Text(
                'Change: ${Fils(changeFils).aedLabel}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: StarColors.statusDone,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _row(ThemeData theme, String label, Fils value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
          MoneyText(value),
        ],
      ),
    );
  }
}
