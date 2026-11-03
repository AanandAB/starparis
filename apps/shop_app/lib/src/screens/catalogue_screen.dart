import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starparis_design/starparis_design.dart';
import 'package:starparis_domain/starparis_domain.dart';
import 'package:starparis_sync/starparis_sync.dart';

import '../app_config.dart';
import '../providers.dart';
import '../sales/catalogue_admin_service.dart';

/// The Catalogue — what the shop sells, and what it charges.
///
/// Two halves, because they answer different questions: **Products** (what exists,
/// on which press, with which finishing steps) and the numbers on each product
/// (markup, rate, rounding). Creating requires the network — a product is
/// shop-wide, so a tablet that has been offline for a week must not invent one.
class CatalogueScreen extends ConsumerWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final machines = ref.watch(machinesProvider).value ?? const <Machine>[];
    final operations =
        ref.watch(operationsProvider).value ?? const <Operation>[];
    final machineById = <String, String>{
      for (final m in machines) m.id: m.name,
    };

    return ListView(
      padding: const EdgeInsets.all(StarSpace.lg),
      children: <Widget>[
        ScreenHeader(
          title: 'Catalogue',
          subtitle:
              'What the shop sells. A product names its press and its finishing '
              'steps, so the price follows the work rather than a guess.',
          actions: <Widget>[
            FilledButton.icon(
              onPressed: () => _add(context, ref, machines, operations),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add product'),
            ),
          ],
        ),
        if (products.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Nothing in the catalogue yet',
            message:
                'Add the first product or service: business cards, a banner, a '
                'design hour. Each one carries its own price.',
          )
        else
          Card(
            child: Column(
              children: <Widget>[
                for (var i = 0; i < products.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    onTap: () => _edit(context, ref, products[i], machines),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          products[i].markupBps == 0
                              ? 'no markup'
                              : '${(products[i].markupBps / 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Price breaks',
                          onPressed: () =>
                              showPriceBreaks(context, products[i]),
                          icon: const Icon(Icons.stairs_outlined, size: 18),
                        ),
                      ],
                    ),
                    leading: Icon(switch (products[i].kind) {
                      'service' => Icons.support_agent_outlined,
                      'area' => Icons.crop_landscape_outlined,
                      'outsourced' => Icons.storefront_outlined,
                      _ => Icons.print_outlined,
                    }, size: 20),
                    title: Text(products[i].nameEn),
                    subtitle: Text(
                      <String>[
                        products[i].code,
                        products[i].pricingMode.replaceAll('_', ' '),
                        if (products[i].machineId != null)
                          machineById[products[i].machineId] ?? 'press',
                        if (_codes(products[i]).isNotEmpty)
                          '${_codes(products[i]).length} finishing steps',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: StarSpace.lg),
        Text(
          'Prices themselves are set on the Prices screen; this is what the work '
          'is made of. Quantity breaks arrive with the price-table pricing mode.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: StarSpace.xxl),
      ],
    );
  }

  static List<String> _codes(Product product) {
    try {
      return <String>[
        for (final value in (jsonDecodeList(product.operationCodesJson))) value,
      ];
    } catch (_) {
      return const <String>[];
    }
  }

  static List<String> jsonDecodeList(String raw) {
    if (raw.isEmpty) return const <String>[];
    final decoded = raw.replaceAll(RegExp(r'[\[\]"\s]'), '');
    if (decoded.isEmpty) return const <String>[];
    return decoded.split(',');
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<Machine> machines,
    List<Operation> operations,
  ) async {
    final draft = await showDialog<_ProductDraft>(
      context: context,
      builder: (_) =>
          _ProductDialog(machines: machines, operations: operations),
    );
    if (draft == null || !context.mounted) return;

    final bootstrap = ref.read(bootstrapProvider);
    final service = CatalogueAdminService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.createProduct(
        code: draft.code,
        nameEn: draft.nameEn,
        kind: draft.kind,
        pricingMode: draft.pricingMode,
        markupBps: draft.markupBps,
        printRateFils: draft.printRateFils,
        machineId: draft.machineId,
        operationCodes: draft.operationCodes,
        sheetWidthMm: draft.sheetWidthMm,
        sheetHeightMm: draft.sheetHeightMm,
      );
      // Pull the catalogue again so the new product reaches every screen.
      await bootstrap.catalogue.refresh(force: true);
      messenger.showSnackBar(SnackBar(content: Text('${draft.nameEn} added.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      service.dispose();
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Product product,
    List<Machine> machines,
  ) async {
    final change = await showDialog<_ProductChange>(
      context: context,
      builder: (_) => _NumbersDialog(product: product, machines: machines),
    );
    if (change == null || !context.mounted) return;

    final bootstrap = ref.read(bootstrapProvider);
    final service = CatalogueAdminService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.updateProduct(
        product.id,
        markupBps: change.markupBps,
        printRateFils: change.printRateFils,
        machineId: change.machineId,
      );
      await bootstrap.catalogue.refresh(force: true);
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      service.dispose();
    }
  }
}

class _ProductDraft {
  const _ProductDraft({
    required this.code,
    required this.nameEn,
    required this.kind,
    required this.pricingMode,
    required this.markupBps,
    this.printRateFils,
    this.machineId,
    this.operationCodes = const <String>[],
    this.sheetWidthMm,
    this.sheetHeightMm,
  });

  final String code;
  final String nameEn;
  final String kind;
  final String pricingMode;
  final int markupBps;
  final int? printRateFils;
  final String? machineId;
  final List<String> operationCodes;
  final int? sheetWidthMm;
  final int? sheetHeightMm;
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({required this.machines, required this.operations});

  final List<Machine> machines;
  final List<Operation> operations;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _rate = TextEditingController();
  final TextEditingController _markup = TextEditingController(text: '40');
  final TextEditingController _width = TextEditingController(text: '320');
  final TextEditingController _height = TextEditingController(text: '450');
  String _kind = 'sheet';
  String _mode = 'cost_plus';
  String? _machineId;
  final Set<String> _operations = <String>{};
  String? _error;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _code,
      _name,
      _rate,
      _markup,
      _width,
      _height,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_code.text.trim().length < 2) {
      setState(() => _error = 'Give the product a short code.');
      return;
    }
    if (_name.text.trim().length < 2) {
      setState(
        () => _error = 'Give the product a name the counter recognises.',
      );
      return;
    }
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    final markup = double.tryParse(_markup.text.trim()) ?? 0;

    Navigator.of(context).pop(
      _ProductDraft(
        code: _code.text.trim().toLowerCase().replaceAll(' ', '_'),
        nameEn: _name.text.trim(),
        kind: _kind,
        pricingMode: _mode,
        markupBps: (markup * 100).round(),
        printRateFils: rate > 0 ? (rate * 100).round() : null,
        machineId: _machineId,
        operationCodes: _operations.toList(growable: false),
        sheetWidthMm: _kind == 'sheet'
            ? int.tryParse(_width.text.trim())
            : null,
        sheetHeightMm: _kind == 'sheet'
            ? int.tryParse(_height.text.trim())
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add a product or service'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _code,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        hintText: 'banner_3x1',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Banner 3 × 1 m',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: const InputDecoration(labelText: 'Kind'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'sheet',
                          child: Text('Sheet (imposed)'),
                        ),
                        DropdownMenuItem(
                          value: 'area',
                          child: Text('Area (per m²)'),
                        ),
                        DropdownMenuItem(
                          value: 'per_unit',
                          child: Text('Per unit'),
                        ),
                        DropdownMenuItem(
                          value: 'service',
                          child: Text('Service'),
                        ),
                        DropdownMenuItem(
                          value: 'outsourced',
                          child: Text('Outsourced'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _kind = value ?? _kind),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(labelText: 'Pricing'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'cost_plus',
                          child: Text('Cost plus'),
                        ),
                        DropdownMenuItem(
                          value: 'price_table',
                          child: Text('Fixed price table'),
                        ),
                        DropdownMenuItem(
                          value: 'vendor_markup',
                          child: Text('Vendor plus margin'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _mode = value ?? _mode),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StarSpace.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Print per sheet (AED)',
                        hintText: '3.00',
                      ),
                    ),
                  ),
                  const SizedBox(width: StarSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _markup,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Markup %',
                        suffixText: '%',
                      ),
                    ),
                  ),
                ],
              ),
              if (_kind == 'sheet') ...<Widget>[
                const SizedBox(height: StarSpace.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _width,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sheet width (mm)',
                        ),
                      ),
                    ),
                    const SizedBox(width: StarSpace.md),
                    Expanded(
                      child: TextField(
                        controller: _height,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sheet height (mm)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: StarSpace.sm),
              if (widget.machines.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _machineId,
                  decoration: const InputDecoration(labelText: 'Press'),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No press (priced per sheet)'),
                    ),
                    for (final machine in widget.machines)
                      DropdownMenuItem(
                        value: machine.id,
                        child: Text(machine.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _machineId = value),
                ),
              if (widget.operations.isNotEmpty) ...<Widget>[
                const SizedBox(height: StarSpace.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'Finishing steps',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Wrap(
                  spacing: StarSpace.sm,
                  children: <Widget>[
                    for (final operation in widget.operations)
                      FilterChip(
                        label: Text(operation.nameEn),
                        selected: _operations.contains(operation.code),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _operations.add(operation.code);
                          } else {
                            _operations.remove(operation.code);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StarSpace.sm),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}

class _ProductChange {
  const _ProductChange({this.markupBps, this.printRateFils, this.machineId});

  final int? markupBps;
  final int? printRateFils;
  final String? machineId;
}

/// The numbers on one product. Prices for the rules themselves live on the
/// Prices screen; this is the markup and the press.
class _NumbersDialog extends StatefulWidget {
  const _NumbersDialog({required this.product, required this.machines});

  final Product product;
  final List<Machine> machines;

  @override
  State<_NumbersDialog> createState() => _NumbersDialogState();
}

class _NumbersDialogState extends State<_NumbersDialog> {
  late final TextEditingController _markup = TextEditingController(
    text: (widget.product.markupBps / 100).toStringAsFixed(1),
  );
  late final TextEditingController _rate = TextEditingController(
    text: widget.product.printRateFils == null
        ? ''
        : Fils(widget.product.printRateFils!).aedText,
  );
  late String? _machineId = widget.product.machineId;

  @override
  void dispose() {
    _markup.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.product.nameEn),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              widget.product.code,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: StarSpace.md),
            TextField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Print per sheet (AED)',
                helperText: 'Leave empty to let the press price the run.',
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            TextField(
              controller: _markup,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Markup',
                suffixText: '%',
              ),
            ),
            const SizedBox(height: StarSpace.sm),
            DropdownButtonFormField<String>(
              initialValue: _machineId,
              decoration: const InputDecoration(labelText: 'Press'),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem(value: null, child: Text('No press')),
                for (final machine in widget.machines)
                  DropdownMenuItem(
                    value: machine.id,
                    child: Text(machine.name),
                  ),
              ],
              onChanged: (value) => setState(() => _machineId = value),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final markup = double.tryParse(_markup.text.trim());
            final rate = double.tryParse(_rate.text.trim());
            Navigator.of(context).pop(
              _ProductChange(
                markupBps: markup == null ? null : (markup * 100).round(),
                printRateFils: rate == null ? null : (rate * 100).round(),
                machineId: _machineId,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Price breaks: what this product costs at 100, 500, 1000.
///
/// The rungs are what the counter quotes from, and what the price-table pricing
/// mode prices with. Same quantity twice is an edit, never a second row.
Future<void> showPriceBreaks(BuildContext context, Product product) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BreaksDialog(product: product),
  );
}

class _BreaksDialog extends ConsumerStatefulWidget {
  const _BreaksDialog({required this.product});

  final Product product;

  @override
  ConsumerState<_BreaksDialog> createState() => _BreaksDialogState();
}

class _BreaksDialogState extends ConsumerState<_BreaksDialog> {
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text.trim());
    final amount = double.tryParse(_amount.text.trim());
    final messenger = ScaffoldMessenger.of(context);

    if (quantity == null || quantity <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Give a quantity.')));
      return;
    }
    if (amount == null || amount < 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Give a price.')));
      return;
    }

    setState(() => _busy = true);
    final bootstrap = ref.read(bootstrapProvider);
    final service = CatalogueAdminService(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: bootstrap.auth.accessToken,
    );
    try {
      await service.setPriceBreak(
        productId: widget.product.id,
        quantity: quantity,
        amountFils: (amount * 100).round(),
      );
      await bootstrap.catalogue.refresh(force: true);
      _quantity.clear();
      _amount.clear();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      service.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(bootstrapProvider).db;

    return AlertDialog(
      title: Text('Price breaks — ${widget.product.nameEn}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StreamBuilder<List<PriceBreak>>(
              stream: db.watchBreaksFor(widget.product.id),
              builder: (context, snapshot) {
                final breaks = snapshot.data ?? const <PriceBreak>[];
                if (breaks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(StarSpace.md),
                    child: Text(
                      'No rungs yet. Add what 100, 500 or 1000 cost and the '
                      'counter quotes from these instead of a formula.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final row in breaks)
                      ListTile(
                        dense: true,
                        title: Text('${row.quantity} pcs'),
                        trailing: MoneyText(Fils(row.amountFils)),
                      ),
                  ],
                );
              },
            ),
            const Divider(),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(width: StarSpace.md),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: 'AED ',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Set')),
      ],
    );
  }
}
