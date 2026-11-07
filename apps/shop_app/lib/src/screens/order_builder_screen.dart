import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_pricing/pricing_engine.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/number_prefixes.dart';
import '../sales/pricer.dart';

/// The order builder — the screen the whole product is judged by.
///
/// Design target: a repeat order in under 60 seconds, a new one in about two
/// minutes. Everything is priced locally, so it works with the internet
/// unplugged, and the price panel is pinned so the clerk never scrolls to see
/// what the customer will pay.
class OrderBuilderScreen extends ConsumerStatefulWidget {
  const OrderBuilderScreen({super.key});

  @override
  ConsumerState<OrderBuilderScreen> createState() => _OrderBuilderScreenState();
}

class _OrderBuilderScreenState extends ConsumerState<OrderBuilderScreen> {
  Product? _product;
  PriceOption? _size;
  int _sides = 1;
  final Set<String> _finishes = <String>{};
  int _quantity = 500;
  Priority _priority = Priority.normal;
  DateTime? _dueAt;
  String? _customerId;
  String? _error;

  final TextEditingController _notes = TextEditingController();

  PriceBreakdown? _price;
  bool _saving = false;
  int _pricingToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bootstrap = ref.read(bootstrapProvider);
      final products = await bootstrap.db.watchProducts().first;
      if (products.isEmpty) {
        await bootstrap.catalogue.refresh(force: true);
      }
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _selectProduct(Product product) async {
    setState(() {
      _product = product;
      final sizes = ProductPricer.sizes(product);
      _size = sizes.isEmpty ? null : sizes.first;
      final presets = ProductPricer.quantityPresets(product);
      _quantity = presets.contains(500)
          ? 500
          : (presets.isEmpty ? 1 : presets.first);
      _finishes.clear();
      _sides = 1;
      _error = null;
    });
    await _recalculate();
  }

  Future<void> _recalculate() async {
    final product = _product;
    if (product == null) {
      setState(() => _price = null);
      return;
    }

    final token = ++_pricingToken;
    final bootstrap = ref.read(bootstrapProvider);
    final version = await bootstrap.db.priceBookVersion();
    final rules = await bootstrap.db.rulesForProduct(product.id, version);
    final material = product.materialCode == null
        ? null
        : await bootstrap.db.materialByCode(product.materialCode!);
    final vat = await bootstrap.db.vatBps();
    // A trade customer is quoted less than retail for the identical job. If no
    // customer is chosen yet — or one with an uncategorised tier — the price
    // stays at retail, so attaching a retail customer later never moves it.
    final customers =
        ref.read(allCustomersProvider).value ?? const <Customer>[];
    var customerTier = 'retail';
    for (final customer in customers) {
      if (customer.id == _customerId) {
        customerTier = customer.tier;
        break;
      }
    }

    try {
      final price = ProductPricer.price(
        machines: ref.watch(machinesProvider).value ?? const <Machine>[],
        operations: ref.watch(operationsProvider).value ?? const <Operation>[],
        priceBreaks:
            ref.watch(priceBreaksProvider(_product?.id ?? '')).value ??
            const <PriceBreak>[],
        product: product,
        rules: rules,
        material: material,
        priceBookVersion: version,
        vatBps: vat,
        quantity: _quantity,
        size: _size,
        sides: _sides,
        finishes: _finishes.toList(),
        priority: _priority,
        customerTier: customerTier,
      );
      if (!mounted || token != _pricingToken) return;
      setState(() {
        _price = price;
        _error = null;
      });
    } on PricingException catch (error) {
      if (!mounted || token != _pricingToken) return;
      setState(() {
        _price = null;
        _error = error.message;
      });
    }
  }

  Future<void> _confirm({bool asQuote = false}) async {
    final session = ref.read(sessionProvider);
    final product = _product;
    final price = _price;
    final customerId = _customerId;

    if (session == null ||
        product == null ||
        price == null ||
        customerId == null) {
      setState(() => _error = 'Choose a customer, a product and a size first.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final bootstrap = ref.read(bootstrapProvider);
      // Quote or job: the kind decides which prefix Settings supplies, so a
      // shop that calls its jobs "ORD" gets ORD-… without a code change.
      final issued = await NumberSeries(
        db: bootstrap.db,
        api: bootstrap.api,
        kind: asQuote ? NumberKind.quote : NumberKind.job,
        branchCode: AppConfig.branchCode,
        deviceCode: AppConfig.deviceCode,
        prefixes:
            ref.read(shopSettingsProvider).value?.numberPrefixes ??
            const NumberPrefixes(),
      ).next();
      // Already prefixed and padded by the series; the string is stored as-is
      // below so a later Settings change cannot rewrite it.
      final display = issued.display;

      final description = ProductPricer.describe(
        product: product,
        quantity: _quantity,
        size: _size,
        sides: _sides,
        finishes: _finishes.toList(),
      );

      final customerList =
          ref.read(allCustomersProvider).value ?? const <Customer>[];
      String customerName = '';
      for (final customer in customerList) {
        if (customer.id == customerId) {
          customerName = customer.name;
          break;
        }
      }

      await bootstrap.db.createOrderLocal(
        tenantId: session.tenantId,
        branchId: session.branchId,
        customerId: customerId,
        customerName: customerName,
        userId: session.userId,
        numberDisplay: display,
        number: issued.number,
        dueAt: _dueAt,
        priority: _priority.wire,
        status: asQuote ? 'draft' : 'confirmed',
        isQuote: asQuote,
        notes: _notes.text.trim(),
        workflowKey: product.workflowKey,
        jobTitle: '$display · $customerName',
        lines: <OrderLineDraft>[
          OrderLineDraft(
            productId: product.id,
            description: description,
            optionsJson: jsonEncode(<String, Object?>{
              'size': _size?.code,
              'width_mm': _size?.widthMm,
              'height_mm': _size?.heightMm,
              'sides': _sides,
              'finish': _finishes.toList(),
              'quantity': _quantity,
              'material': product.materialCode,
            }),
            quantity: _quantity,
            priceBookVersion: price.priceBookVersion,
            breakdownJson: jsonEncode(price.toJson()),
            subtotalFils: price.total.raw,
            vatFils: price.vat.raw,
            totalFils: price.grandTotal.raw,
          ),
        ],
      );

      unawaited(bootstrap.engine?.syncNow() ?? Future<void>.value());

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asQuote
                ? 'Quote $display saved. Send it from the order sheet.'
                : issued.isTemporary
                ? 'Order $display saved. It gets a real number when the internet returns.'
                : 'Order $display saved.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the order: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers =
        ref.watch(allCustomersProvider).value ?? const <Customer>[];
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final price = _price;

    if (_customerId == null && customers.isNotEmpty) {
      _customerId = customers.first.id;
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(StarSpace.lg),
          children: <Widget>[
            ScreenHeader(
              title: 'New order',
              subtitle:
                  'Priced on this device — a repeat order in under a minute.',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            _Section(
              title: 'Customer',
              child: customers.isEmpty
                  ? Text(
                      'Add a customer first — the counter finds them by phone number next time.',
                      style: theme.textTheme.bodySmall,
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _customerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: <DropdownMenuItem<String>>[
                        for (final customer in customers)
                          DropdownMenuItem<String>(
                            value: customer.id,
                            child: Text(
                              customer.company == null ||
                                      customer.company!.isEmpty
                                  ? customer.name
                                  : '${customer.name} · ${customer.company}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _customerId = value);
                        _recalculate();
                      },
                    ),
            ),
            _Section(
              title: 'Product',
              child: products.isEmpty
                  ? Text(
                      'No price book on this device yet. Connect once and it downloads automatically.',
                      style: theme.textTheme.bodySmall,
                    )
                  : Wrap(
                      spacing: StarSpace.sm,
                      runSpacing: StarSpace.sm,
                      children: <Widget>[
                        for (final product in products)
                          ChoiceChip(
                            label: Text(product.nameEn),
                            selected: _product?.id == product.id,
                            onSelected: (_) => _selectProduct(product),
                          ),
                      ],
                    ),
            ),
            if (_product != null) ...<Widget>[
              if (ProductPricer.sizes(_product!).isNotEmpty)
                _Section(
                  title: 'Finished size',
                  child: Wrap(
                    spacing: StarSpace.sm,
                    runSpacing: StarSpace.sm,
                    children: <Widget>[
                      for (final size in ProductPricer.sizes(_product!))
                        ChoiceChip(
                          label: Text(size.label),
                          selected: _size?.code == size.code,
                          onSelected: (_) {
                            setState(() => _size = size);
                            _recalculate();
                          },
                        ),
                    ],
                  ),
                ),
              if (_product!.kind == 'sheet')
                _Section(
                  title: 'Sides',
                  child: SegmentedButton<int>(
                    segments: const <ButtonSegment<int>>[
                      ButtonSegment<int>(value: 1, label: Text('Single')),
                      ButtonSegment<int>(value: 2, label: Text('Double')),
                    ],
                    selected: <int>{_sides},
                    onSelectionChanged: (selection) {
                      setState(() => _sides = selection.first);
                      _recalculate();
                    },
                  ),
                ),
              if (ProductPricer.finishes(_product!).isNotEmpty)
                _Section(
                  title: 'Finishing',
                  child: Wrap(
                    spacing: StarSpace.sm,
                    runSpacing: StarSpace.sm,
                    children: <Widget>[
                      for (final finish in ProductPricer.finishes(_product!))
                        FilterChip(
                          label: Text(finish.label),
                          selected: _finishes.contains(finish.code),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _finishes.add(finish.code);
                              } else {
                                _finishes.remove(finish.code);
                              }
                            });
                            _recalculate();
                          },
                        ),
                    ],
                  ),
                ),
              _Section(
                title: 'Quantity',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: StarSpace.sm,
                      children: <Widget>[
                        for (final preset in ProductPricer.quantityPresets(
                          _product!,
                        ))
                          ChoiceChip(
                            label: Text('$preset'),
                            selected: _quantity == preset,
                            onSelected: (_) {
                              setState(() => _quantity = preset);
                              _recalculate();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: StarSpace.md),
                    Row(
                      children: <Widget>[
                        IconButton.outlined(
                          onPressed: () {
                            setState(
                              () => _quantity = (_quantity - 50).clamp(
                                1,
                                1000000,
                              ),
                            );
                            _recalculate();
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: StarSpace.sm),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            key: ValueKey<int>(_quantity),
                            initialValue: '$_quantity',
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _quantity = parsed);
                                _recalculate();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: StarSpace.sm),
                        IconButton.outlined(
                          onPressed: () {
                            setState(() => _quantity += 50);
                            _recalculate();
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Due and priority',
                child: Row(
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 120),
                          ),
                          initialDate:
                              _dueAt ??
                              DateTime.now().add(const Duration(days: 2)),
                        );
                        if (picked != null) setState(() => _dueAt = picked);
                      },
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        _dueAt == null
                            ? 'Set a due date'
                            : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year}',
                      ),
                    ),
                    const SizedBox(width: StarSpace.md),
                    SegmentedButton<Priority>(
                      segments: const <ButtonSegment<Priority>>[
                        ButtonSegment<Priority>(
                          value: Priority.normal,
                          label: Text('Normal'),
                        ),
                        ButtonSegment<Priority>(
                          value: Priority.urgent,
                          label: Text('Urgent'),
                        ),
                        ButtonSegment<Priority>(
                          value: Priority.rush,
                          label: Text('Rush'),
                        ),
                      ],
                      selected: <Priority>{_priority},
                      onSelectionChanged: (selection) {
                        setState(() => _priority = selection.first);
                        _recalculate();
                      },
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Notes for the shop',
                child: TextField(
                  controller: _notes,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Artwork coming by WhatsApp, delivery after 4pm…',
                  ),
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: StarSpace.md),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: StarColors.statusProblem,
                  ),
                ),
              ),
            if (price != null) ...<Widget>[
              const SizedBox(height: StarSpace.lg),
              _PricePanel(price: price),
            ],
            const SizedBox(height: StarSpace.xxl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(StarSpace.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: price == null
                    ? Text(
                        'Pick a product to see the price',
                        style: theme.textTheme.bodySmall,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Total incl. VAT',
                            style: theme.textTheme.labelSmall,
                          ),
                          // The running total counts up when a size, finish or
                          // quantity changes, so a repricing is felt, not read.
                          AnimatedCount(
                            value: price.grandTotal.raw,
                            format: (fils) => Fils(fils).aedLabel,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                              color: price.grandTotal.isNegative
                                  ? theme.colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: StarSpace.md),
              OutlinedButton(
                onPressed: _saving || price == null || _customerId == null
                    ? null
                    : () => _confirm(asQuote: true),
                child: const Text('Save as quote'),
              ),
              const SizedBox(width: StarSpace.sm),
              FilledButton.icon(
                onPressed: _saving || price == null || _customerId == null
                    ? null
                    : _confirm,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Confirm order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StarSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: StarSpace.sm),
          child,
        ],
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.price});

  final PriceBreakdown price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StarSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Price breakdown', style: theme.textTheme.titleSmall),
            const SizedBox(height: StarSpace.md),
            for (final line in price.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(line.label, style: theme.textTheme.bodyMedium),
                          Text(
                            line.explain,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: StarSpace.md),
                    MoneyText(line.amount),
                  ],
                ),
              ),
            const Divider(height: StarSpace.lg),
            _TotalRow(label: 'Subtotal', amount: price.total),
            _TotalRow(label: 'VAT', amount: price.vat),
            _TotalRow(label: 'Total', amount: price.grandTotal, emphatic: true),
            if (price.warnings.isNotEmpty) ...<Widget>[
              const SizedBox(height: StarSpace.sm),
              for (final warning in price.warnings)
                Text(
                  warning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: StarColors.statusPaused,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.emphatic = false,
  });

  final String label;
  final Fils amount;
  final bool emphatic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The emphatic row is the order total: it counts up like the live price
    // bar and uses the display scale, so the number the customer pays is the
    // biggest thing on the summary.
    final Widget value;
    if (emphatic) {
      value = AnimatedCount(
        value: amount.raw,
        format: (fils) => Fils(fils).aedLabel,
        style: theme.textTheme.displaySmall?.copyWith(
          color: amount.isNegative ? theme.colorScheme.error : null,
        ),
      );
    } else {
      value = MoneyText(amount);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: emphatic
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
          value,
        ],
      ),
    );
  }
}
